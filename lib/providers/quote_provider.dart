// quote_provider.dart
// lib/providers/quote_provider.dart
//
// PAYMENT INFO + TERMS PASS (this update): added updateBankName(),
// updateAccountName(), updateAccountNumber(),
// updateOtherPaymentDetails(), updateTermsAndConditions() — thin
// pass-throughs to QuoteData.copyWith's new fields (quote_data.dart's
// own PAYMENT INFO + TERMS PASS), mirroring updateSignatureMode's exact
// shape. Also added applyPaymentAndTermsFromTemplate() — a single
// bundled call meant for the still-missing template-select sync step
// (the Quote equivalent of Invoice's
// StepCreateInvoice._syncSelectedToProvider()) to call once that sync
// point is identified; until then nothing calls these new methods.
//
// SIGNATURE PASS (earlier): added updateSignatureMode(),
// updateSignatureName(), updateSignatureImagePath(),
// updateSignatureFontSize(), updateSignatureFontFamily() — thin
// pass-throughs to QuoteData.copyWith's new signature fields, mirroring
// InvoiceProvider's updateSignatureFontSize/updateSignatureFontFamily
// shape exactly. Backs the new Signature section on
// quote_step_customise.dart's Fields section.
//
// HISTORY LOGGING PASS (earlier): saveCurrentQuote() and
// deleteQuote() each gained an optional [historyProvider] param.
//
// FONT SIZE PASS, TEMPLATE/CLIENT RESTORE-ON-EDIT PASS, TEMPLATE FIELD
// VISIBILITY PASS, CURRENCY DISPLAY PASS, ALERTPREFS PUSH WIRING,
// NO-DUPLICATE-PUSH FIX, TEMPLATE + LOGO SIZER PASS, PUSH ALERTS (all
// earlier) — see prior header comments; unaffected by this update.

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
      unawaited(_resyncDocumentAlerts());
    }
  }

  Future<void> _resyncDocumentAlerts() async {
    for (final q in _savedQuotes) {
      try {
        await DocumentAlertScheduler.instance.syncQuoteExpiringAlert(q, allowImmediateFire: false);
        await DocumentAlertScheduler.instance.syncQuoteDraftNudge(q);
      } catch (_) {}
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

  Future<void> applyExpiringAlertsEnabled(bool enabled) async {
    for (final q in _savedQuotes) {
      try {
        if (enabled) {
          await DocumentAlertScheduler.instance.syncQuoteExpiringAlert(q, allowImmediateFire: false);
        } else {
          await DocumentAlertScheduler.instance.cancelQuoteExpiringAlert(q.id);
        }
      } catch (_) {}
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
      } catch (_) {}
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
    final updated = _savedQuotes[index];
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(updated, allowImmediateFire: false));
    unawaited(DocumentAlertScheduler.instance.syncQuoteDraftNudge(updated));
  }

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

  void updateSavedQuoteStatus(String id, QuoteStatus status) {
    final index = _savedQuotes.indexWhere((q) => q.id == id);
    if (index == -1) return;
    _savedQuotes[index] = _savedQuotes[index].copyWith(
      data: _savedQuotes[index].data.copyWith(quoteStatus: status),
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(_savedQuotes[index]));
  }

  // ── Folder ─────────────────────────────────────────────────────────────────

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

  void updateFontSize(double size) {
    _quoteData = _quoteData.copyWith(fontSize: size);
    notifyListeners();
  }

  void updateLayoutTemplateId(int id) {
    _quoteData = _quoteData.copyWith(layoutTemplateId: id);
    notifyListeners();
  }

  // SIGNATURE PASS: mirrors InvoiceProvider's updateSignatureFontSize/
  // updateSignatureFontFamily shape exactly, plus mode/name/imagePath
  // pass-throughs the same way Quote's own step_templates signature UI
  // (quote_step_template_signature.dart) already writes to
  // QuoteTemplate — these instead write onto the live QuoteData via
  // copyWith, driven by the Signature section on
  // quote_step_customise.dart's Fields section.
  void updateSignatureMode(String mode) {
    _quoteData = _quoteData.copyWith(signatureMode: mode);
    notifyListeners();
  }

  void updateSignatureName(String name) {
    _quoteData = _quoteData.copyWith(signatureName: name);
    notifyListeners();
  }

  void updateSignatureImagePath(String? path) {
    _quoteData = _quoteData.copyWith(
      signatureImagePath: path,
      clearSignatureImage: path == null,
    );
    notifyListeners();
  }

  void updateSignatureFontSize(double size) {
    _quoteData = _quoteData.copyWith(signatureFontSize: size);
    notifyListeners();
  }

  void updateSignatureFontFamily(String family) {
    _quoteData = _quoteData.copyWith(signatureFontFamily: family);
    notifyListeners();
  }

  // PAYMENT INFO + TERMS PASS: thin pass-throughs to QuoteData.copyWith,
  // same shape as updateSignatureMode/etc just above. Nothing calls
  // these yet in the app — see this file's header comment for the
  // still-missing template -> QuoteData sync step that would actually
  // drive them with real values from a selected QuoteTemplate.
  void updateBankName(String v) {
    _quoteData = _quoteData.copyWith(bankName: v);
    notifyListeners();
  }

  void updateAccountName(String v) {
    _quoteData = _quoteData.copyWith(accountName: v);
    notifyListeners();
  }

  void updateAccountNumber(String v) {
    _quoteData = _quoteData.copyWith(accountNumber: v);
    notifyListeners();
  }

  void updateOtherPaymentDetails(String v) {
    _quoteData = _quoteData.copyWith(otherPaymentDetails: v);
    notifyListeners();
  }

  void updateTermsAndConditions(String v) {
    _quoteData = _quoteData.copyWith(termsAndConditions: v);
    notifyListeners();
  }

  // Bundles all of the above plus signature into one call — the shape a
  // future template-select sync step should call once it exists,
  // rather than firing eight separate notifyListeners() rebuilds.
  void applyPaymentAndTermsFromTemplate({
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String otherPaymentDetails,
    required String termsAndConditions,
    required String signatureMode,
    required String signatureName,
    String? signatureImagePath,
  }) {
    _quoteData = _quoteData.copyWith(
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
      otherPaymentDetails: otherPaymentDetails,
      termsAndConditions: termsAndConditions,
      signatureMode: signatureMode,
      signatureName: signatureName,
      signatureImagePath: signatureImagePath,
      clearSignatureImage: signatureImagePath == null,
    );
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
