import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt_data.dart';
import '../models/footer_tagline.dart';
import '../models/history_event.dart' show HistoryDocType;
import '../filters/filter_logic.dart' show receiptIsDraft;
import '../alerts/notifications/document_alert_scheduler.dart';
import 'history_provider.dart';

class ReceiptProvider extends ChangeNotifier {
  static const _storageKey = 'saved_receipts';

  ReceiptData _currentReceiptData = ReceiptData();
  String? _currentReceiptId;

  final List<SavedReceipt> _savedReceipts = [];

  ReceiptData get currentReceiptData => _currentReceiptData;
  List<SavedReceipt> get savedReceipts => List.unmodifiable(_savedReceipts);

  String? get currentReceiptId => _currentReceiptId;

  void resetReceiptData() {
    _currentReceiptData = ReceiptData();
    _currentReceiptId = null;
    notifyListeners();
  }

  void updateReceiptData(ReceiptData data) {
    _currentReceiptData = data;
    notifyListeners();
  }

  // BACKGROUND-IMAGE PASS: mirrors InvoiceProvider's/QuoteProvider's
  // identical two methods exactly, writing onto the active editor draft
  // (_currentReceiptData) via copyWith.
  void updateHeaderBackgroundImage({
    required String? path,
    required bool enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
  }) {
    _currentReceiptData = _currentReceiptData.copyWith(
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
    _currentReceiptData = _currentReceiptData.copyWith(
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
    _currentReceiptData = _currentReceiptData.copyWith(
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
    _currentReceiptData = _currentReceiptData.copyWith(businessTaglineEnabled: enabled);
    notifyListeners();
  }

  void updateFooterTaglinesEnabled(bool enabled) {
    _currentReceiptData = _currentReceiptData.copyWith(footerTaglinesEnabled: enabled);
    notifyListeners();
  }

  // TAGLINE SIZE PASS: font size (pt) for footer tagline text.
  void updateFooterTaglinesFontSize(double size) {
    _currentReceiptData = _currentReceiptData.copyWith(footerTaglinesFontSize: size);
    notifyListeners();
  }

  void updateFooterTaglines(List<FooterTaglineItem> items) {
    _currentReceiptData = _currentReceiptData.copyWith(
      footerTaglines: items.map((i) => i.copyWith()).toList(),
    );
    notifyListeners();
  }

  void updateShowSignature(bool show) {
    _currentReceiptData = _currentReceiptData.copyWith(showSignature: show);
    notifyListeners();
  }

  void updateSignatureMode(String mode) {
    _currentReceiptData = _currentReceiptData.copyWith(signatureMode: mode);
    notifyListeners();
  }

  void updateSignatureName(String name) {
    _currentReceiptData = _currentReceiptData.copyWith(signatureName: name);
    notifyListeners();
  }

  void updateSignatureImagePath(String? path) {
    _currentReceiptData = _currentReceiptData.copyWith(
      signatureImagePath: path,
      clearSignatureImage: path == null,
    );
    notifyListeners();
  }

  void updateSignatureFontSize(double size) {
    _currentReceiptData = _currentReceiptData.copyWith(signatureFontSize: size);
    notifyListeners();
  }

  void updateSignatureFontFamily(String family) {
    _currentReceiptData = _currentReceiptData.copyWith(signatureFontFamily: family);
    notifyListeners();
  }

  int _calcCompletionPercent(ReceiptData d) {
    final fields = [
      d.businessName.isNotEmpty,
      d.businessEmail.isNotEmpty,
      d.clientName.isNotEmpty,
      d.receiptNumber.isNotEmpty,
      d.paymentDate.isNotEmpty,
      d.lineItems.isNotEmpty && d.lineItems.any((i) => i.description.isNotEmpty),
    ];
    final filled = fields.where((f) => f).length;
    return ((filled / fields.length) * 100).round();
  }

  Future<void> _syncDraftNudge(SavedReceipt receipt) {
    return DocumentAlertScheduler.instance.syncReceiptDraftNudge(
      receiptId: receipt.id,
      title: receipt.title,
      isDraft: receiptIsDraft(receipt),
    );
  }

  void _logCreated(HistoryProvider? historyProvider, SavedReceipt receipt) {
    if (historyProvider == null) return;
    unawaited(historyProvider.logCreated(
      docType: HistoryDocType.receipt,
      docId: receipt.id,
      docNumber: receipt.data.receiptNumber,
      clientName: receipt.data.clientName.isEmpty ? null : receipt.data.clientName,
      amount: receipt.data.amountPaid,
      currency: receipt.data.currency,
    ));
  }

  Future<void> applyDraftAlertsEnabled(bool enabled) async {
    for (final r in _savedReceipts) {
      try {
        if (enabled) {
          await _syncDraftNudge(r);
        } else {
          await DocumentAlertScheduler.instance.cancelReceiptDraftNudge(r.id);
        }
      } catch (_) {}
    }
  }

  Future<void> saveCurrentReceipt({
    required String title,
    required String templateName,
    HistoryProvider? historyProvider,
  }) async {
    final now = DateTime.now();
    final percent = _calcCompletionPercent(_currentReceiptData);

    if (_currentReceiptId != null) {
      final index = _savedReceipts.indexWhere((r) => r.id == _currentReceiptId);
      if (index != -1) {
        _savedReceipts[index] = _savedReceipts[index].copyWith(
          title: title,
          templateName: templateName,
          data: _currentReceiptData.deepCopy(),
          lastEditedAt: now,
          completionPercent: percent,
        );
        await _persist();
        notifyListeners();
        unawaited(_syncDraftNudge(_savedReceipts[index]));
        return;
      }
    }

    final id = 'receipt_${now.millisecondsSinceEpoch}';
    final saved = SavedReceipt(
      id: id,
      title: title,
      templateName: templateName,
      data: _currentReceiptData.deepCopy(),
      createdAt: now,
      lastEditedAt: now,
      completionPercent: percent,
    );

    _savedReceipts.insert(0, saved);
    _currentReceiptId = id;

    await _persist();
    notifyListeners();
    unawaited(_syncDraftNudge(saved));
    _logCreated(historyProvider, saved);
  }

  Future<SavedReceipt> addConvertedReceipt({
    required ReceiptData data,
    required String title,
    required String templateName,
    HistoryProvider? historyProvider,
  }) async {
    final now = DateTime.now();
    final saved = SavedReceipt(
      id: 'receipt_${now.millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Receipt' : title.trim(),
      templateName: templateName,
      data: data.deepCopy(),
      createdAt: now,
      lastEditedAt: now,
      completionPercent: _calcCompletionPercent(data),
    );

    _savedReceipts.insert(0, saved);
    await _persist();
    notifyListeners();
    unawaited(_syncDraftNudge(saved));
    _logCreated(historyProvider, saved);
    return saved;
  }

  void loadSavedReceipt(String id) {
    final match = _savedReceipts.where((r) => r.id == id);
    if (match.isEmpty) return;

    final saved = match.first;
    _currentReceiptId = saved.id;
    _currentReceiptData = saved.data.deepCopy();
    notifyListeners();
  }

  Future<void> renameSavedReceipt(String id, String newTitle) async {
    final index = _savedReceipts.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    _savedReceipts[index] = _savedReceipts[index].copyWith(title: trimmed);
    await _persist();
    notifyListeners();
    unawaited(_syncDraftNudge(_savedReceipts[index]));
  }

  Future<void> updateSavedReceiptStatus(String id, ReceiptStatus status) async {
    final index = _savedReceipts.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _savedReceipts[index] = _savedReceipts[index].copyWith(
      data: _savedReceipts[index].data.copyWith(status: status, statusHidden: false),
      lastEditedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> updateSavedReceiptStatusHidden(String id, bool hidden) async {
    final index = _savedReceipts.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _savedReceipts[index] = _savedReceipts[index].copyWith(
      data: _savedReceipts[index].data.copyWith(statusHidden: hidden),
      lastEditedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> updateSavedReceiptFormat(
    String id, {
    required int layoutTemplateId,
    required String paperFormat,
  }) async {
    final index = _savedReceipts.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _savedReceipts[index] = _savedReceipts[index].copyWith(
      data: _savedReceipts[index].data.copyWith(
        layoutTemplateId: layoutTemplateId,
        paperFormat: paperFormat,
      ),
      lastEditedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> updateReceiptFolder(String id, String? folderName) async {
    final index = _savedReceipts.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _savedReceipts[index] = _savedReceipts[index].copyWith(
      folderName: folderName,
      clearFolderName: folderName == null,
      lastEditedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> updateReceiptExcludeFromReports(String id, bool exclude) async {
    final index = _savedReceipts.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _savedReceipts[index] = _savedReceipts[index].copyWith(
      data: _savedReceipts[index].data.copyWith(excludeFromReports: exclude),
      lastEditedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> deleteSavedReceipt(String id, {HistoryProvider? historyProvider}) async {
    SavedReceipt? deleted;
    try {
      deleted = _savedReceipts.firstWhere((r) => r.id == id);
    } catch (_) {
      deleted = null;
    }
    _savedReceipts.removeWhere((r) => r.id == id);
    if (_currentReceiptId == id) {
      _currentReceiptId = null;
    }
    await _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.syncReceiptDraftNudge(
      receiptId: id,
      title: '',
      isDraft: false,
    ));
    if (historyProvider != null && deleted != null) {
      unawaited(historyProvider.logDeleted(
        docType: HistoryDocType.receipt,
        docId: deleted.id,
        docNumber: deleted.data.receiptNumber,
        clientName: deleted.data.clientName.isEmpty ? null : deleted.data.clientName,
      ));
    }
  }

  Future<void> loadPersistedReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw) as List<dynamic>;
      _savedReceipts
        ..clear()
        ..addAll(decoded.map(
          (e) => SavedReceipt.fromJson(e as Map<String, dynamic>),
        ));
    } catch (e) {
      debugPrint('ReceiptProvider: failed to load persisted receipts: $e');
    } finally {
      unawaited(_resyncDocumentAlerts());
    }
  }

  Future<void> _resyncDocumentAlerts() async {
    for (final r in _savedReceipts) {
      try {
        await _syncDraftNudge(r);
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_savedReceipts.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('ReceiptProvider: failed to persist receipts: $e');
    }
  }
}
