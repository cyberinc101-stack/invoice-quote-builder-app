import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote_data.dart';
import '../models/footer_tagline.dart';
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

  void updateSavedQuoteStatus(String id, QuoteStatus status) {
    final index = _savedQuotes.indexWhere((q) => q.id == id);
    if (index == -1) return;
    _savedQuotes[index] = _savedQuotes[index].copyWith(
      data: _savedQuotes[index].data.copyWith(quoteStatus: status, statusHidden: false),
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.syncQuoteExpiringAlert(_savedQuotes[index]));
  }

  void updateSavedQuoteStatusHidden(String id, bool hidden) {
    final index = _savedQuotes.indexWhere((q) => q.id == id);
    if (index == -1) return;
    _savedQuotes[index] = _savedQuotes[index].copyWith(
      data: _savedQuotes[index].data.copyWith(statusHidden: hidden),
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

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

  // BACKGROUND-IMAGE PASS: mirrors InvoiceProvider's identical two
  // methods exactly.
  void updateHeaderBackgroundImage({
    required String? path,
    required bool enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
  }) {
    _quoteData = _quoteData.copyWith(
      headerBackgroundImagePath: path,
      clearHeaderBackgroundImage: path == null,
      headerBackgroundEnabled: enabled,
      headerBackgroundOpacity: opacity,
      headerBackgroundOffsetDx: offsetDx,
      headerBackgroundOffsetDy: offsetDy,
      headerBackgroundScale: scale,
    );
    notifyListeners();
  }

  void updateFooterBackgroundImage({
    required String? path,
    required bool enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
  }) {
    _quoteData = _quoteData.copyWith(
      footerBackgroundImagePath: path,
      clearFooterBackgroundImage: path == null,
      footerBackgroundEnabled: enabled,
      footerBackgroundOpacity: opacity,
      footerBackgroundOffsetDx: offsetDx,
      footerBackgroundOffsetDy: offsetDy,
      footerBackgroundScale: scale,
    );
    notifyListeners();
  }

  void updateBodyBackgroundImage({
    required String? path,
    required bool enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
  }) {
    _quoteData = _quoteData.copyWith(
      bodyBackgroundImagePath: path,
      clearBodyBackgroundImage: path == null,
      bodyBackgroundEnabled: enabled,
      bodyBackgroundOpacity: opacity,
      bodyBackgroundOffsetDx: offsetDx,
      bodyBackgroundOffsetDy: offsetDy,
      bodyBackgroundScale: scale,
    );
    notifyListeners();
  }

  void updateBusinessTaglineEnabled(bool enabled) {
    _quoteData = _quoteData.copyWith(businessTaglineEnabled: enabled);
    notifyListeners();
  }

  void updateFooterTaglinesEnabled(bool enabled) {
    _quoteData = _quoteData.copyWith(footerTaglinesEnabled: enabled);
    notifyListeners();
  }

  // TAGLINE SIZE PASS: font size (pt) for footer tagline text.
  void updateFooterTaglinesFontSize(double size) {
    _quoteData = _quoteData.copyWith(footerTaglinesFontSize: size);
    notifyListeners();
  }

  void updateFooterTaglines(List<FooterTaglineItem> items) {
    _quoteData = _quoteData.copyWith(
      footerTaglines: items.map((i) => i.copyWith()).toList(),
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
