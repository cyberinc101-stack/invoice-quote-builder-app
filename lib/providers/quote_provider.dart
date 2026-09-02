// quote_provider.dart
// lib/providers/quote_provider.dart
//
// HISTORY LOGGING PASS (this update): saveCurrentQuote() and
// deleteQuote() each gained an optional [historyProvider] param, mirroring
// InvoiceProvider's identical pass — see that file's header comment for
// the full rationale. saveCurrentQuote logs `created`; deleteQuote logs
// `deleted` using the quote's data captured BEFORE removal. Omitted
// (null) is a no-op on both, so every existing call site behaves exactly
// as before this pass. Quotes have no addConverted* method (nothing in
// this app converts INTO a quote — only invoice/receipt are conversion
// targets), so this is the only creation path that needs wiring here.
//
// FONT SIZE PASS (earlier update): added updateFontSize(), mirroring
// updateFontFamily()'s shape exactly — a thin pass-through to
// QuoteData.copyWith's new fontSize field. Called from the new Text Size
// slider on quote_step_customise.dart via quote_editor_screen.dart's
// _syncToProvider().
//
// TEMPLATE/CLIENT RESTORE-ON-EDIT PASS (earlier): updateBusinessInfo()
// and updateClientInfo() each gained a source*Id param plus a matching
// clearSource*Id flag (same explicit-clear pattern clearBusinessLogo
// already uses) — passes straight through to QuoteData.copyWith's new
// sourceTemplateId/sourceClientId fields. See quote_data.dart's doc
// comment for the full rationale. quote_editor_screen.dart's
// _syncToProvider() now passes _selectedTemplate?.id /
// _selectedClient?.id alongside the existing business/client fields on
// every sync, with the matching clear flag set whenever nothing is
// selected — so deselecting a template/client actually clears the
// stored id instead of leaving a stale one behind.
//
// TEMPLATE FIELD VISIBILITY PASS (earlier): added
// updateEnabledFields(), mirroring updateBusinessInfo()/
// updateClientInfo()'s shape — writes straight onto QuoteData.
// enabledFields via copyWith. Called from the new "Template" step in
// quote_editor_screen.dart's _syncToProvider().
//
// CURRENCY DISPLAY PASS (earlier): updateQuoteDetails() gained
// optional currencySymbol/currencyDisplayMode params, passed straight
// through to QuoteData.copyWith (same as the plain currency field
// already there). Written from quote_editor_screen.dart's new free-text
// currency code/symbol fields + Code/Symbol/Both selector on the
// Client & Details step, replacing the old fixed-list dropdown.
//
// ALERTPREFS PUSH WIRING (earlier pass): added applyExpiringAlertsEnabled()
// and applyDraftAlertsEnabled() — mirrors InvoiceProvider's own version;
// see that file's header comment for the full rationale. Called from
// alert_type_toggles.dart's "Expiring Quotes"/"Drafts" switches and
// settings_screen.dart's master Alerts switch.
//
// NO-DUPLICATE-PUSH FIX (earlier pass): _resyncDocumentAlerts(),
// updateSavedQuote(), and renameQuote() now pass
// allowImmediateFire: false to syncQuoteExpiringAlert() — same fix as
// InvoiceProvider's, for the same reason: a quote already inside its
// expiring-soon window was re-pushing a duplicate notification on every
// app launch and every unrelated edit. See document_alert_scheduler.dart
// for the actual fix.
//
// TEMPLATE + LOGO SIZER PASS (earlier update): updateBusinessInfo() gained
// optional businessLogoOffsetDx/Dy/Scale/Shape params (all pass straight
// through to QuoteData.copyWith, same as the plain fields already there),
// and a new updateLayoutTemplateId() mirrors InvoiceProvider's own
// version. See quote_data.dart for the new fields these write to.
//
// PUSH ALERTS (earlier pass): same treatment as InvoiceProvider — every
// mutation that can change whether a quote is expiring-eligible or a
// draft now calls into DocumentAlertScheduler right after persisting.
// See invoice_provider.dart's header comment for the full rationale; the
// pattern here is identical, just for quotes.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote_data.dart';
import '../models/invoice_data.dart' show LineItem;
import '../models/history_event.dart' show HistoryDocType;
import '../alerts/notifications/document_alert_scheduler.dart';
import 'history_provider.dart';

const String _kSavedQuotesKey = 'saved_quotes_v1';

class QuoteProvider extends ChangeNotifier {
  QuoteData _quoteData = QuoteData();

  final List<SavedQuote> _savedQuotes = [];
  String? _activeQuoteId;

  bool _loading = true;
  bool get isLoading => _loading;

  QuoteData        get quoteData     => _quoteData;
  List<SavedQuote> get savedQuotes   => List.unmodifiable(_savedQuotes);
  String?          get activeQuoteId => _activeQuoteId;

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> loadPersistedQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kSavedQuotesKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _savedQuotes.clear();
        for (final item in list) {
          try {
            _savedQuotes.add(
              SavedQuote.fromJson(
                (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
              ),
            );
          } catch (e) {
            debugPrint('[QuoteProvider] Skipped corrupt entry: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[QuoteProvider] loadPersistedQuotes error: $e');
    } finally {
      _loading = false;
      notifyListeners();
      // Re-arms every saved quote's expiring/draft push notifications
      // against the OS scheduler on every launch — same safety net
      // InvoiceProvider._resyncDocumentAlerts() / ReminderProvider use.
      unawaited(_resyncDocumentAlerts());
    }
  }

  Future<void> _resyncDocumentAlerts() async {
    for (final q in _savedQuotes) {
      try {
        // allowImmediateFire: false — this runs on every app launch, so a
        // quote already inside its expiring-soon window must NOT re-fire
        // a fresh "notify now" push every single time the app opens.
        await DocumentAlertScheduler.instance.syncQuoteExpiringAlert(q, allowImmediateFire: false);
        await DocumentAlertScheduler.instance.syncQuoteDraftNudge(q);
      } catch (_) {
        // Best-effort — one bad quote shouldn't stop the rest resyncing.
      }
    }
  }

  Future<void> _persist() async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_savedQuotes.map((q) => q.toJson()).toList());
      await prefs.setString(_kSavedQuotesKey, encoded);
    } catch (e) {
      debugPrint('[QuoteProvider] _persist error: $e');
    }
  }

  // ── AlertPrefs push wiring ─────────────────────────────────────────────────
  // Called from alert_type_toggles.dart / settings_screen.dart whenever the
  // EFFECTIVE enabled state for a category (alertsEnabled && the per-type
  // flag) changes. Mirrors InvoiceProvider.applyOverdueAlertsEnabled /
  // applyDraftAlertsEnabled — see that file's comment for the full
  // rationale.

  Future<void> applyExpiringAlertsEnabled(bool enabled) async {
    for (final q in _savedQuotes) {
      try {
        if (enabled) {
          await DocumentAlertScheduler.instance.syncQuoteExpiringAlert(q, allowImmediateFire: false);
        } else {
          await DocumentAlertScheduler.instance.cancelQuoteExpiringAlert(q.id);
        }
      } catch (_) {
        // Best-effort — one bad quote shouldn't stop the rest applying.
      }
    }
  }

  Future<void> applyDraftAlertsEnabled(bool enabled) async {
    for (final q in _savedQuotes) {
      try {
        if (enabled) {
          await DocumentAlertScheduler.instance.syncQuoteDraftNudge(q);
        } else {
          await DocumentAlertScheduler.instance.cancelQuoteDraftNudge(q.id);
        }
      } catch (_) {
        // Best-effort — one bad quote shouldn't stop the rest applying.
      }
    }
  }

  // ── Active session ─────────────────────────────────────────────────────────

  void resetQuoteData() {
    _quoteData     = QuoteData();
    _activeQuoteId = null;
    notifyListeners();
  }

  void loadSavedQuote(String id) {
    final quote = _savedQuotes.firstWhere((q) => q.id == id);
    _quoteData     = quote.data.deepCopy();
    _activeQuoteId = quote.id;
    notifyListeners();
  }

  void clearActiveSession() {
    _activeQuoteId = null;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  // HISTORY LOGGING PASS: [historyProvider] is optional so every existing
  // call site keeps working unchanged. Pass
  // historyProvider: context.read<HistoryProvider>() from a normal
  // "create new quote" save flow to log a `created` History event.
  SavedQuote saveCurrentQuote({
    required String title,
    required String templateName,
    HistoryProvider? historyProvider,
  }) {
    final now = DateTime.now();
    final quote = SavedQuote(
      id:                '${now.millisecondsSinceEpoch}',
      title:             title.trim().isEmpty ? 'Quote' : title.trim(),
      templateName:      templateName,
      data:              _quoteData.deepCopy(),
      createdAt:         now,
      lastEditedAt:      now,
      completionPercent: _calcCompletion(),
    );
    _savedQuotes.insert(0, quote);
    _activeQuoteId = quote.id;
    _persist();
    notifyListeners();
    // First save of this quote — a genuine new-transition moment, so an
    // already-past expiring window is still allowed to fire almost
    // immediately (default allowImmediateFire: true).
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(quote));
    unawaited(DocumentAlertScheduler.instance.syncQuoteDraftNudge(quote));
    if (historyProvider != null) {
      unawaited(historyProvider.logCreated(
        docType: HistoryDocType.quote,
        docId: quote.id,
        docNumber: quote.data.quoteNumber,
        clientName: quote.data.clientName.isEmpty ? null : quote.data.clientName,
        amount: quote.data.grandTotal,
        currency: quote.data.currency,
      ));
    }
    return quote;
  }

  void updateSavedQuote(String id) {
    final index = _savedQuotes.indexWhere((q) => q.id == id);
    if (index == -1) return;
    _savedQuotes[index] = _savedQuotes[index].copyWith(
      data:              _quoteData.deepCopy(),
      lastEditedAt:      DateTime.now(),
      completionPercent: _calcCompletion(),
    );
    _persist();
    notifyListeners();
    final updated = _savedQuotes[index];
    // Routine content edit, not a fresh transition — allowImmediateFire:
    // false so editing an already-expiring-soon quote doesn't re-push a
    // duplicate notification.
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(updated, allowImmediateFire: false));
    unawaited(DocumentAlertScheduler.instance.syncQuoteDraftNudge(updated));
  }

  void renameQuote(String id, String newTitle) {
    final index = _savedQuotes.indexWhere((q) => q.id == id);
    if (index == -1) return;
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    _savedQuotes[index] = _savedQuotes[index].copyWith(title: trimmed);
    _persist();
    notifyListeners();
    // Title changed -> re-sync so a pending notification's body text
    // (which embeds the title) doesn't go stale. Not a fresh transition —
    // allowImmediateFire: false, same reasoning as updateSavedQuote.
    final updated = _savedQuotes[index];
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(updated, allowImmediateFire: false));
    unawaited(DocumentAlertScheduler.instance.syncQuoteDraftNudge(updated));
  }

  // HISTORY LOGGING PASS: [historyProvider] is optional — logs a
  // `deleted` event using the quote's data captured BEFORE removal.
  // Omitted (null) is a no-op, so every existing call site behaves
  // exactly as before.
  void deleteQuote(String id, {HistoryProvider? historyProvider}) {
    final deleted = getQuoteById(id);
    _savedQuotes.removeWhere((q) => q.id == id);
    if (_activeQuoteId == id) _activeQuoteId = null;
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.cancelAllForQuote(id));
    if (historyProvider != null && deleted != null) {
      unawaited(historyProvider.logDeleted(
        docType: HistoryDocType.quote,
        docId: deleted.id,
        docNumber: deleted.data.quoteNumber,
        clientName: deleted.data.clientName.isEmpty ? null : deleted.data.clientName,
      ));
    }
  }

  SavedQuote? getQuoteById(String id) {
    try {
      return _savedQuotes.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Status ─────────────────────────────────────────────────────────────────
  // Powers the tappable status chip in saved_document_detail_screen.dart.
  // Updates the SAVED entry's status directly (not the active draft), same
  // pattern as ReceiptProvider.updateSavedReceiptStatus.

  void updateSavedQuoteStatus(String id, QuoteStatus status) {
    final index = _savedQuotes.indexWhere((q) => q.id == id);
    if (index == -1) return;
    _savedQuotes[index] = _savedQuotes[index].copyWith(
      data: _savedQuotes[index].data.copyWith(quoteStatus: status),
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
    // A status flip is exactly the case that most needs a resync — e.g.
    // moving to accepted/declined must cancel a pending expiring-soon push
    // immediately, and moving to sent is what makes one eligible at all.
    // It's also a genuine new transition, so this keeps the default
    // allowImmediateFire: true.
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(_savedQuotes[index]));
  }

  // ── Folder ─────────────────────────────────────────────────────────────────
  // Assigns or clears the organizational folder for a saved quote.
  // Pass null to remove it from whatever folder it's currently in. Updates
  // the SAVED entry directly, same pattern as updateSavedQuoteStatus.

  void updateQuoteFolder(String id, String? folderName) {
    final index = _savedQuotes.indexWhere((q) => q.id == id);
    if (index == -1) return;
    _savedQuotes[index] = _savedQuotes[index].copyWith(
      folderName: folderName,
      clearFolderName: folderName == null,
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  // ── Reports exclusion ─────────────────────────────────────────────────────
  // Same pattern as InvoiceProvider.updateInvoiceExcludeFromReports.

  void updateQuoteExcludeFromReports(String id, bool exclude) {
    final index = _savedQuotes.indexWhere((q) => q.id == id);
    if (index == -1) return;
    _savedQuotes[index] = _savedQuotes[index].copyWith(
      data: _savedQuotes[index].data.copyWith(excludeFromReports: exclude),
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  // ── Data mutations ─────────────────────────────────────────────────────────

  void updateQuoteData(QuoteData data) {
    _quoteData = data;
    notifyListeners();
  }

  // businessLogoOffsetDx/Dy/Scale/Shape are optional so every existing
  // call site (which only passes the plain business fields) keeps working
  // unchanged; pass them together when updating from a SharedLogoPicker
  // onChanged callback.
  //
  // TEMPLATE/CLIENT RESTORE-ON-EDIT PASS: sourceTemplateId/
  // clearSourceTemplateId are new — same explicit-clear pattern as
  // clearBusinessLogo. Pass sourceTemplateId when a template is selected;
  // pass clearSourceTemplateId: true (instead of just omitting
  // sourceTemplateId) when nothing is selected, since a plain omitted/
  // null value would leave whatever id was already stored untouched.
  void updateBusinessInfo({
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? businessLogoPath,
    bool clearBusinessLogo = false,
    double? businessLogoOffsetDx,
    double? businessLogoOffsetDy,
    double? businessLogoScale,
    String? businessLogoShape,
    double? businessLogoDisplaySize,
    String? sourceTemplateId,
    bool clearSourceTemplateId = false,
  }) {
    _quoteData = _quoteData.copyWith(
      businessName:     businessName,
      businessEmail:    businessEmail,
      businessPhone:    businessPhone,
      businessAddress:  businessAddress,
      businessLogoPath: businessLogoPath,
      clearBusinessLogo: clearBusinessLogo,
      businessLogoOffsetDx: businessLogoOffsetDx,
      businessLogoOffsetDy: businessLogoOffsetDy,
      businessLogoScale: businessLogoScale,
      businessLogoShape: businessLogoShape,
      businessLogoDisplaySize: businessLogoDisplaySize,
      sourceTemplateId: sourceTemplateId,
      clearSourceTemplateId: clearSourceTemplateId,
    );
    notifyListeners();
  }

  // TEMPLATE/CLIENT RESTORE-ON-EDIT PASS: sourceClientId/
  // clearSourceClientId are new — same shape/reasoning as
  // updateBusinessInfo's sourceTemplateId/clearSourceTemplateId above.
  void updateClientInfo({
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? sourceClientId,
    bool clearSourceClientId = false,
  }) {
    _quoteData = _quoteData.copyWith(
      clientName:    clientName,
      clientEmail:   clientEmail,
      clientPhone:   clientPhone,
      clientAddress: clientAddress,
      sourceClientId: sourceClientId,
      clearSourceClientId: clearSourceClientId,
    );
    notifyListeners();
  }

  // currencySymbol/currencyDisplayMode are new (CURRENCY DISPLAY PASS) —
  // optional so any older call site passing only `currency` keeps
  // working unchanged. quote_editor_screen.dart's Client & Details step
  // now passes all three from its free-text fields + Code/Symbol/Both
  // selector.
  void updateQuoteDetails({
    String? quoteNumber,
    String? issueDate,
    String? expiryDate,
    String? notes,
    String? currency,
    String? currencySymbol,
    String? currencyDisplayMode,
    double? taxRate,
    double? discountRate,
  }) {
    _quoteData = _quoteData.copyWith(
      quoteNumber:  quoteNumber,
      issueDate:    issueDate,
      expiryDate:   expiryDate,
      notes:        notes,
      currency:     currency,
      currencySymbol:      currencySymbol,
      currencyDisplayMode: currencyDisplayMode,
      taxRate:      taxRate,
      discountRate: discountRate,
    );
    notifyListeners();
  }

  // TEMPLATE FIELD VISIBILITY PASS: writes the Template step's toggle
  // selections onto QuoteData.enabledFields. Mirrors updateBusinessInfo/
  // updateClientInfo's shape — a thin pass-through to copyWith.
  void updateEnabledFields(Map<String, bool> enabledFields) {
    _quoteData = _quoteData.copyWith(
      enabledFields: Map<String, bool>.from(enabledFields),
    );
    notifyListeners();
  }

  void addLineItem(LineItem item) {
    _quoteData = _quoteData.copyWith(
      lineItems: [..._quoteData.lineItems, item],
    );
    notifyListeners();
  }

  void updateLineItem(int index, LineItem item) {
    final updated = List<LineItem>.from(_quoteData.lineItems);
    updated[index] = item;
    _quoteData = _quoteData.copyWith(lineItems: updated);
    notifyListeners();
  }

  void removeLineItem(int index) {
    final updated = List<LineItem>.from(_quoteData.lineItems)..removeAt(index);
    _quoteData = _quoteData.copyWith(lineItems: updated);
    notifyListeners();
  }

  void updateQuoteStatus(QuoteStatus status) {
    _quoteData = _quoteData.copyWith(quoteStatus: status);
    notifyListeners();
  }

  void updateColorScheme(QuoteColor color) {
    _quoteData = _quoteData.copyWith(colorScheme: color);
    notifyListeners();
  }

  void updateFontFamily(String font) {
    _quoteData = _quoteData.copyWith(fontFamily: font);
    notifyListeners();
  }

  // FONT SIZE PASS: mirrors updateFontFamily() exactly. Called from the
  // new Text Size slider on quote_step_customise.dart.
  void updateFontSize(double size) {
    _quoteData = _quoteData.copyWith(fontSize: size);
    notifyListeners();
  }

  // Which visual design (Executive/Nordic/Vibrant/etc — see the quote
  // preview_registry.dart) this quote renders with. Set once from
  // QuoteTemplateChooserScreen's selection (via QuoteEditorScreen).
  void updateLayoutTemplateId(int id) {
    _quoteData = _quoteData.copyWith(layoutTemplateId: id);
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int _calcCompletion() {
    int score = 0;
    if (_quoteData.businessName.isNotEmpty) score++;
    if (_quoteData.clientName.isNotEmpty)   score++;
    if (_quoteData.quoteNumber.isNotEmpty)  score++;
    if (_quoteData.lineItems.isNotEmpty)    score++;
    if (_quoteData.expiryDate.isNotEmpty)   score++;
    return ((score / 5) * 100).round();
  }
}