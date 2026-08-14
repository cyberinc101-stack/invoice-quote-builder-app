// quote_provider.dart
// lib/providers/quote_provider.dart
//
// TEMPLATE + LOGO SIZER PASS (this update): updateBusinessInfo() gained
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
import '../alerts/notifications/document_alert_scheduler.dart';

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
        await DocumentAlertScheduler.instance.syncQuoteExpiringAlert(q);
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

  SavedQuote saveCurrentQuote({
    required String title,
    required String templateName,
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
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(quote));
    unawaited(DocumentAlertScheduler.instance.syncQuoteDraftNudge(quote));
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
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(updated));
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
    // (which embeds the title) doesn't go stale.
    final updated = _savedQuotes[index];
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(updated));
    unawaited(DocumentAlertScheduler.instance.syncQuoteDraftNudge(updated));
  }

  void deleteQuote(String id) {
    _savedQuotes.removeWhere((q) => q.id == id);
    if (_activeQuoteId == id) _activeQuoteId = null;
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.cancelAllForQuote(id));
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
    );
    notifyListeners();
  }

  void updateClientInfo({
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
  }) {
    _quoteData = _quoteData.copyWith(
      clientName:    clientName,
      clientEmail:   clientEmail,
      clientPhone:   clientPhone,
      clientAddress: clientAddress,
    );
    notifyListeners();
  }

  void updateQuoteDetails({
    String? quoteNumber,
    String? issueDate,
    String? expiryDate,
    String? notes,
    String? currency,
    double? taxRate,
    double? discountRate,
  }) {
    _quoteData = _quoteData.copyWith(
      quoteNumber:  quoteNumber,
      issueDate:    issueDate,
      expiryDate:   expiryDate,
      notes:        notes,
      currency:     currency,
      taxRate:      taxRate,
      discountRate: discountRate,
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
