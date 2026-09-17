import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_data.dart';
import '../models/footer_tagline.dart';
import '../models/history_event.dart' show HistoryDocType;
import '../alerts/notifications/document_alert_scheduler.dart';
import 'history_provider.dart';

const String _kSavedInvoicesKey = 'saved_invoices_v1';

class InvoiceProvider extends ChangeNotifier {
  InvoiceData _invoiceData = InvoiceData();

  final List<SavedInvoice> _savedInvoices = [];
  String? _activeInvoiceId;

  // DRAFT-SYNC PASS: tracks which Create-Invoice "draft" (if any) the
  // current session originated from — set by
  // step_create_invoice.dart's _syncSelectedToProvider() when the user
  // continues from a selected draft into Customise. This is what lets
  // step_customise.dart's _handleSave() write Customise-only fields
  // (Footer Taglines, the business logo, etc.) back onto that draft
  // when saving — those fields are never touched by
  // CreateInvoiceBottomSheet itself, so without this the draft library
  // never learns about changes made further down the flow, and
  // re-selecting the same draft later silently reverts them. Cleared
  // whenever the session is no longer "coming from a draft" — a fresh
  // reset, or loading an already-finished saved invoice for editing.
  String? _sourceDraftId;
  String? get sourceDraftId => _sourceDraftId;
  void setSourceDraftId(String? id) => _sourceDraftId = id;

  bool _loading = true;
  bool get isLoading => _loading;

  InvoiceData        get invoiceData      => _invoiceData;
  List<SavedInvoice> get savedInvoices    => List.unmodifiable(_savedInvoices);
  String?            get activeInvoiceId  => _activeInvoiceId;

  Future<void> loadPersistedInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kSavedInvoicesKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _savedInvoices.clear();
        for (final item in list) {
          try {
            _savedInvoices.add(
              SavedInvoice.fromJson(
                (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
              ),
            );
          } catch (e) {
            debugPrint('[InvoiceProvider] Skipped corrupt entry: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[InvoiceProvider] loadPersistedInvoices error: $e');
    } finally {
      _loading = false;
      notifyListeners();
      unawaited(_resyncDocumentAlerts());
    }
  }

  Future<void> _resyncDocumentAlerts() async {
    for (final inv in _savedInvoices) {
      try {
        await DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(inv, allowImmediateFire: false);
        await DocumentAlertScheduler.instance.syncInvoiceDraftNudge(inv);
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_savedInvoices.map((i) => i.toJson()).toList());
      await prefs.setString(_kSavedInvoicesKey, encoded);
    } catch (e) {
      debugPrint('[InvoiceProvider] _persist error: $e');
    }
  }

  void _logCreated(HistoryProvider? historyProvider, SavedInvoice inv) {
    if (historyProvider == null) return;
    unawaited(historyProvider.logCreated(
      docType: HistoryDocType.invoice,
      docId: inv.id,
      docNumber: inv.data.invoiceNumber,
      clientName: inv.data.clientName.isEmpty ? null : inv.data.clientName,
      amount: inv.data.grandTotal,
      currency: inv.data.currency,
    ));
  }

  Future<void> applyOverdueAlertsEnabled(bool enabled) async {
    for (final inv in _savedInvoices) {
      try {
        if (enabled) {
          await DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(inv, allowImmediateFire: false);
        } else {
          await DocumentAlertScheduler.instance.cancelOverdueInvoiceAlert(inv.id);
        }
      } catch (_) {}
    }
  }

  Future<void> applyDraftAlertsEnabled(bool enabled) async {
    for (final inv in _savedInvoices) {
      try {
        if (enabled) {
          await DocumentAlertScheduler.instance.syncInvoiceDraftNudge(inv);
        } else {
          await DocumentAlertScheduler.instance.cancelInvoiceDraftNudge(inv.id);
        }
      } catch (_) {}
    }
  }

  void resetInvoiceData() {
    _invoiceData    = InvoiceData();
    _activeInvoiceId = null;
    // DRAFT-SYNC PASS: a fresh session isn't "from" any draft any more.
    _sourceDraftId = null;
    notifyListeners();
  }

  void loadSavedInvoice(String id) {
    final inv = _savedInvoices.firstWhere((i) => i.id == id);
    _invoiceData     = inv.data.deepCopy();
    _activeInvoiceId = inv.id;
    // DRAFT-SYNC PASS: editing an already-finished saved invoice, not a
    // draft — nothing to write back to a draft library entry here.
    _sourceDraftId = null;
    notifyListeners();
  }

  void clearActiveSession() {
    _activeInvoiceId = null;
    notifyListeners();
  }

  // UPDATE-IN-PLACE FIX: this used to unconditionally insert a brand-new
  // SavedInvoice on every call, even when _activeInvoiceId was already
  // pointing at a real saved invoice (i.e. you opened an existing one via
  // Home -> tap card -> Edit). That meant re-saving an edit created a
  // duplicate with the new data, while the original entry — the one still
  // sitting on the Home screen, the one you'd tap next time — was never
  // touched. Now: if there's an active invoice and it still exists in
  // _savedInvoices, overwrite that entry (same id/createdAt) instead of
  // inserting a new one. Only a genuinely new invoice (no active id, or a
  // stale id that no longer exists) creates a fresh SavedInvoice.
  SavedInvoice saveCurrentInvoice({
    required String title,
    required String templateName,
    HistoryProvider? historyProvider,
  }) {
    final now = DateTime.now();
    final trimmedTitle = title.trim().isEmpty ? 'Invoice' : title.trim();

    final existingIndex = _activeInvoiceId == null
        ? -1
        : _savedInvoices.indexWhere((i) => i.id == _activeInvoiceId);

    if (existingIndex != -1) {
      final updated = _savedInvoices[existingIndex].copyWith(
        title:             trimmedTitle,
        templateName:      templateName,
        data:              _invoiceData.deepCopy(),
        lastEditedAt:      now,
        completionPercent: _calcCompletion(),
      );
      _savedInvoices[existingIndex] = updated;
      _persist();
      notifyListeners();
      unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(updated, allowImmediateFire: false));
      unawaited(DocumentAlertScheduler.instance.syncInvoiceDraftNudge(updated));
      return updated;
    }

    final inv = SavedInvoice(
      id:                '${now.millisecondsSinceEpoch}',
      title:             trimmedTitle,
      templateName:      templateName,
      data:              _invoiceData.deepCopy(),
      createdAt:         now,
      lastEditedAt:      now,
      completionPercent: _calcCompletion(),
    );
    _savedInvoices.insert(0, inv);
    _activeInvoiceId = inv.id;
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(inv));
    unawaited(DocumentAlertScheduler.instance.syncInvoiceDraftNudge(inv));
    _logCreated(historyProvider, inv);
    return inv;
  }

  SavedInvoice addConvertedInvoice({
    required InvoiceData data,
    required String title,
    required String templateName,
    HistoryProvider? historyProvider,
  }) {
    final now = DateTime.now();
    final inv = SavedInvoice(
      id:                '${now.millisecondsSinceEpoch}',
      title:             title.trim().isEmpty ? 'Invoice' : title.trim(),
      templateName:      templateName,
      data:              data.deepCopy(),
      createdAt:         now,
      lastEditedAt:      now,
      completionPercent: _calcCompletionFor(data),
    );
    _savedInvoices.insert(0, inv);
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(inv));
    unawaited(DocumentAlertScheduler.instance.syncInvoiceDraftNudge(inv));
    _logCreated(historyProvider, inv);
    return inv;
  }

  void updateSavedInvoice(String id) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _savedInvoices[index] = _savedInvoices[index].copyWith(
      data:              _invoiceData.deepCopy(),
      lastEditedAt:      DateTime.now(),
      completionPercent: _calcCompletion(),
    );
    _persist();
    notifyListeners();
    final updated = _savedInvoices[index];
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(updated, allowImmediateFire: false));
    unawaited(DocumentAlertScheduler.instance.syncInvoiceDraftNudge(updated));
  }

  void renameInvoice(String id, String newTitle) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    _savedInvoices[index] = _savedInvoices[index].copyWith(title: trimmed);
    _persist();
    notifyListeners();
    final updated = _savedInvoices[index];
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(updated, allowImmediateFire: false));
    unawaited(DocumentAlertScheduler.instance.syncInvoiceDraftNudge(updated));
  }

  void deleteInvoice(String id, {HistoryProvider? historyProvider}) {
    final deleted = getInvoiceById(id);
    _savedInvoices.removeWhere((i) => i.id == id);
    if (_activeInvoiceId == id) _activeInvoiceId = null;
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.cancelAllForInvoice(id));
    if (historyProvider != null && deleted != null) {
      unawaited(historyProvider.logDeleted(
        docType: HistoryDocType.invoice,
        docId: deleted.id,
        docNumber: deleted.data.invoiceNumber,
        clientName: deleted.data.clientName.isEmpty ? null : deleted.data.clientName,
      ));
    }
  }

  SavedInvoice? getInvoiceById(String id) {
    try {
      return _savedInvoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateSavedInvoiceStatus(String id, PaymentStatus status) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final current  = _savedInvoices[index];
    final wasPaid  = current.data.paymentStatus == PaymentStatus.paid;
    final isNowPaid = status == PaymentStatus.paid;

    InvoiceData updatedData;
    if (isNowPaid && !wasPaid) {
      updatedData = current.data.copyWith(
        paymentStatus: status,
        paidDate: DateTime.now(),
        statusHidden: false,
      );
    } else if (!isNowPaid) {
      updatedData = current.data.copyWith(
        paymentStatus: status,
        clearPaidDate: true,
        statusHidden: false,
      );
    } else {
      updatedData = current.data.copyWith(paymentStatus: status, statusHidden: false);
    }

    _savedInvoices[index] = current.copyWith(
      data: updatedData,
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(_savedInvoices[index]));
  }

  void updateSavedInvoiceStatusHidden(String id, bool hidden) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _savedInvoices[index] = _savedInvoices[index].copyWith(
      data: _savedInvoices[index].data.copyWith(statusHidden: hidden),
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  void updateInvoiceFolder(String id, String? folderName) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _savedInvoices[index] = _savedInvoices[index].copyWith(
      folderName: folderName,
      clearFolderName: folderName == null,
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  void updateInvoiceExcludeFromReports(String id, bool exclude) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _savedInvoices[index] = _savedInvoices[index].copyWith(
      data: _savedInvoices[index].data.copyWith(excludeFromReports: exclude),
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  void updateInvoiceData(InvoiceData data) {
    _invoiceData = data;
    notifyListeners();
  }

  void updateBusinessInfo({
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? businessLogoPath,
  }) {
    _invoiceData = _invoiceData.copyWith(
      businessName:     businessName,
      businessEmail:    businessEmail,
      businessPhone:    businessPhone,
      businessAddress:  businessAddress,
      businessLogoPath: businessLogoPath,
    );
    notifyListeners();
  }

  void updateBusinessLogo({
    required String? path,
    required Offset offset,
    required double scale,
    required String shape,
  }) {
    _invoiceData = _invoiceData.copyWith(
      businessLogoPath: path,
      clearBusinessLogo: path == null,
      businessLogoOffsetDx: offset.dx,
      businessLogoOffsetDy: offset.dy,
      businessLogoScale: scale,
      businessLogoShape: shape,
    );
    notifyListeners();
  }

  void updateBusinessLogoSize(double size) {
    _invoiceData = _invoiceData.copyWith(businessLogoDisplaySize: size);
    notifyListeners();
  }

  // FREEFORM HEADER LOGO PASS: position/scale for the logo when it's
  // rendered freely across the header (Business Name + Tagline both
  // off) instead of the normal fixed logo box. Same thin
  // pass-through-to-copyWith shape as every other update* method here
  // — any param left null keeps its current stored value.
  void updateHeaderLogoFreeform({
    double? offsetDx,
    double? offsetDy,
    double? scale,
  }) {
    _invoiceData = _invoiceData.copyWith(
      headerLogoFreeformOffsetDx: offsetDx,
      headerLogoFreeformOffsetDy: offsetDy,
      headerLogoFreeformScale: scale,
    );
    notifyListeners();
  }

  // BACKGROUND-IMAGE PASS: thin pass-throughs to InvoiceData.copyWith,
  // same shape as updateBusinessLogo above. `path: null` clears the
  // image (via clearHeaderBackgroundImage/clearFooterBackgroundImage)
  // rather than leaving a stale path behind while enabled is false.
  void updateHeaderBackgroundImage({
    required String? path,
    required bool enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
  }) {
    _invoiceData = _invoiceData.copyWith(
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
    _invoiceData = _invoiceData.copyWith(
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

  // MID-PAGE BACKGROUND PASS: mirrors the two methods above, for the
  // page's body content area (line items + totals).
  void updateBodyBackgroundImage({
    required String? path,
    required bool enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
  }) {
    _invoiceData = _invoiceData.copyWith(
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
    _invoiceData = _invoiceData.copyWith(businessTaglineEnabled: enabled);
    notifyListeners();
  }

  void updateFooterTaglinesEnabled(bool enabled) {
    _invoiceData = _invoiceData.copyWith(footerTaglinesEnabled: enabled);
    notifyListeners();
  }

  // TAGLINE SIZE PASS: font size (pt) for footer tagline text.
  void updateFooterTaglinesFontSize(double size) {
    _invoiceData = _invoiceData.copyWith(footerTaglinesFontSize: size);
    notifyListeners();
  }

  void updateFooterTaglines(List<FooterTaglineItem> items) {
    _invoiceData = _invoiceData.copyWith(
      footerTaglines: items.map((i) => i.copyWith()).toList(),
    );
    notifyListeners();
  }

  void updateClientInfo({
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
  }) {
    _invoiceData = _invoiceData.copyWith(
      clientName:    clientName,
      clientEmail:   clientEmail,
      clientPhone:   clientPhone,
      clientAddress: clientAddress,
    );
    notifyListeners();
  }

  void updateInvoiceDetails({
    String? invoiceNumber,
    String? issueDate,
    String? dueDate,
    String? notes,
    String? currency,
    double? taxRate,
    double? discountRate,
    String? taxName,
    String? discountName,
  }) {
    _invoiceData = _invoiceData.copyWith(
      invoiceNumber: invoiceNumber,
      issueDate:     issueDate,
      dueDate:       dueDate,
      notes:         notes,
      currency:      currency,
      taxRate:       taxRate,
      discountRate:  discountRate,
      taxName:       taxName,
      discountName:  discountName,
    );
    notifyListeners();
  }

  void addLineItem(LineItem item) {
    _invoiceData = _invoiceData.copyWith(
      lineItems: [..._invoiceData.lineItems, item],
    );
    notifyListeners();
  }

  void updateLineItem(int index, LineItem item) {
    final updated = List<LineItem>.from(_invoiceData.lineItems);
    updated[index] = item;
    _invoiceData = _invoiceData.copyWith(lineItems: updated);
    notifyListeners();
  }

  void removeLineItem(int index) {
    final updated = List<LineItem>.from(_invoiceData.lineItems)..removeAt(index);
    _invoiceData = _invoiceData.copyWith(lineItems: updated);
    notifyListeners();
  }

  void updatePaymentStatus(PaymentStatus status) {
    _invoiceData = _invoiceData.copyWith(paymentStatus: status);
    notifyListeners();
  }

  void updateColorScheme(InvoiceColor color) {
    _invoiceData = _invoiceData.copyWith(colorScheme: color);
    notifyListeners();
  }

  void updateFontFamily(String font) {
    _invoiceData = _invoiceData.copyWith(fontFamily: font);
    notifyListeners();
  }

  void updateEnabledFields(Map<String, bool> enabledFields) {
    _invoiceData = _invoiceData.copyWith(
      enabledFields: Map<String, bool>.from(enabledFields),
    );
    notifyListeners();
  }

  void updateLayoutTemplateId(int id) {
    _invoiceData = _invoiceData.copyWith(layoutTemplateId: id);
    notifyListeners();
  }

  void updateSignatureFontSize(double size) {
    _invoiceData = _invoiceData.copyWith(signatureFontSize: size);
    notifyListeners();
  }

  void updateSignatureFontFamily(String family) {
    _invoiceData = _invoiceData.copyWith(signatureFontFamily: family);
    notifyListeners();
  }

  double get fontSize => _invoiceData.fontSize;
  void updateFontSize(double size) {
    _invoiceData = _invoiceData.copyWith(fontSize: size);
    notifyListeners();
  }

  int _calcCompletion() => _calcCompletionFor(_invoiceData);

  int _calcCompletionFor(InvoiceData data) {
    int score = 0;
    if (data.businessName.isNotEmpty)  score++;
    if (data.clientName.isNotEmpty)    score++;
    if (data.invoiceNumber.isNotEmpty) score++;
    if (data.lineItems.isNotEmpty)     score++;
    if (data.dueDate.isNotEmpty)       score++;
    return ((score / 5) * 100).round();
  }
}