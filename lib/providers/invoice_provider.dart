// invoice_provider.dart
// lib/providers/invoice_provider.dart
//
// TEMPLATE + LOGO SIZER PASS (this update): two new methods —
// updateLayoutTemplateId() and updateBusinessLogo() — mirror the pattern
// every other data-mutation method here already uses (copyWith the active
// draft, notifyListeners). See invoice_data.dart for the new fields these
// write to.
//
// PUSH ALERTS (earlier pass): every mutation that can change whether an
// invoice is overdue-eligible or a draft now calls into
// DocumentAlertScheduler right after persisting, mirroring the pattern
// ReminderProvider already uses for custom reminders. Specifically:
//  - saveCurrentInvoice / addConvertedInvoice / updateSavedInvoice: sync
//    both the overdue alert and the draft nudge (a save can change either
//    condition — a newly-added due date, a completed field pushing
//    completionPercent to 100, etc).
//  - updateSavedInvoiceStatus: sync just the overdue alert (status is the
//    only thing that changes here, but a status flip can also affect
//    invoiceIsDraft() if your app ever ties completion to status — sync's
//    included defensively, it's a cheap no-op cancel+reschedule if nothing
//    changed).
//  - deleteInvoice: cancel everything scheduled for that id so a deleted
//    invoice can never still push a notification later.
// All calls are fire-and-forget (unawaited) — scheduling a local
// notification should never block the UI or fail loudly; failures are
// already swallowed/logged inside NotificationService.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_data.dart';
import '../alerts/notifications/document_alert_scheduler.dart';

const String _kSavedInvoicesKey = 'saved_invoices_v1';

class InvoiceProvider extends ChangeNotifier {
  InvoiceData _invoiceData = InvoiceData();

  final List<SavedInvoice> _savedInvoices = [];
  String? _activeInvoiceId;

  bool _loading = true;
  bool get isLoading => _loading;

  InvoiceData        get invoiceData      => _invoiceData;
  List<SavedInvoice> get savedInvoices    => List.unmodifiable(_savedInvoices);
  String?            get activeInvoiceId  => _activeInvoiceId;

  // ── Persistence ────────────────────────────────────────────────────────────

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
      // Re-arms every saved invoice's overdue/draft push notifications
      // against the OS scheduler on every launch — same "repair itself on
      // open" safety net ReminderProvider.resyncScheduledNotifications()
      // uses, in case an OEM battery manager killed the scheduled alarms.
      unawaited(_resyncDocumentAlerts());
    }
  }

  Future<void> _resyncDocumentAlerts() async {
    for (final inv in _savedInvoices) {
      try {
        await DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(inv);
        await DocumentAlertScheduler.instance.syncInvoiceDraftNudge(inv);
      } catch (_) {
        // Best-effort — one bad invoice shouldn't stop the rest resyncing.
      }
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

  // ── Active session ─────────────────────────────────────────────────────────

  void resetInvoiceData() {
    _invoiceData    = InvoiceData();
    _activeInvoiceId = null;
    notifyListeners();
  }

  void loadSavedInvoice(String id) {
    final inv = _savedInvoices.firstWhere((i) => i.id == id);
    _invoiceData     = inv.data.deepCopy();
    _activeInvoiceId = inv.id;
    notifyListeners();
  }

  void clearActiveSession() {
    _activeInvoiceId = null;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  SavedInvoice saveCurrentInvoice({
    required String title,
    required String templateName,
  }) {
    final now = DateTime.now();
    final inv = SavedInvoice(
      id:                '${now.millisecondsSinceEpoch}',
      title:             title.trim().isEmpty ? 'Invoice' : title.trim(),
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
    return inv;
  }

  // Saves a converted InvoiceData (e.g. built from a quote via
  // convertQuoteDataToInvoiceData) directly as a new saved invoice, WITHOUT
  // touching the active editor draft — unlike saveCurrentInvoice(), which
  // always saves whatever's currently in _invoiceData. Used by the
  // "Convert to Invoice" action in saved_document_detail_screen.dart.
  SavedInvoice addConvertedInvoice({
    required InvoiceData data,
    required String title,
    required String templateName,
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
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(updated));
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
    // Title changed -> re-sync so a pending notification's body text
    // (which embeds the title) doesn't go stale.
    final updated = _savedInvoices[index];
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(updated));
    unawaited(DocumentAlertScheduler.instance.syncInvoiceDraftNudge(updated));
  }

  void deleteInvoice(String id) {
    _savedInvoices.removeWhere((i) => i.id == id);
    if (_activeInvoiceId == id) _activeInvoiceId = null;
    _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.cancelAllForInvoice(id));
  }

  SavedInvoice? getInvoiceById(String id) {
    try {
      return _savedInvoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Status ─────────────────────────────────────────────────────────────────
  // Powers the tappable status chip in saved_document_detail_screen.dart.
  // Updates the SAVED entry's status directly (not the active draft), same
  // pattern as ReceiptProvider.updateSavedReceiptStatus.
  //
  // Also stamps/clears InvoiceData.paidDate —
  //   - Freshly moved TO paid (wasn't paid before)   -> stamp paidDate = now
  //   - Moved AWAY from paid                          -> clear paidDate
  //   - Re-set to paid while already paid (no-op flip)-> leave existing
  //     paidDate untouched, so re-tapping the same status doesn't reset the
  //     original paid timestamp.

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
      );
    } else if (!isNowPaid) {
      updatedData = current.data.copyWith(
        paymentStatus: status,
        clearPaidDate: true,
      );
    } else {
      updatedData = current.data.copyWith(paymentStatus: status);
    }

    _savedInvoices[index] = current.copyWith(
      data: updatedData,
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
    // A status flip is exactly the case that most needs a resync — e.g.
    // marking paid must cancel a pending overdue push immediately, not
    // wait for the next app launch's resync pass.
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(_savedInvoices[index]));
  }

  // ── Folder ─────────────────────────────────────────────────────────────────
  // Assigns or clears the organizational folder for a saved invoice.
  // Pass null to remove it from whatever folder it's currently in. Updates
  // the SAVED entry directly, same pattern as updateSavedInvoiceStatus.

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

  // ── Reports exclusion ─────────────────────────────────────────────────────
  // Powers an "Exclude from Reports" action in saved_document_detail_screen.
  // dart. Updates the SAVED entry directly, same pattern as
  // updateInvoiceFolder — doesn't touch the active draft.

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

  // ── Data mutations ─────────────────────────────────────────────────────────

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

  // Business logo path + reposition/zoom/shape, all in one call so a
  // single SharedLogoPicker.onChanged callback (which always hands back
  // all four values together) maps directly onto one provider call. Pass
  // path: null to clear the logo entirely — that's the only way to
  // actually blank businessLogoPath, since InvoiceData.copyWith's plain
  // `?? this.x` pattern can't express "set to null" on its own.
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

  // Logo display size (box width/height in px, default 44.0) � separate
  // from updateBusinessLogo() so the "Logo Size" slider on the Customise
  // step can update just this one field.
  void updateBusinessLogoSize(double size) {
    _invoiceData = _invoiceData.copyWith(businessLogoDisplaySize: size);
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
  }) {
    _invoiceData = _invoiceData.copyWith(
      invoiceNumber: invoiceNumber,
      issueDate:     issueDate,
      dueDate:       dueDate,
      notes:         notes,
      currency:      currency,
      taxRate:       taxRate,
      discountRate:  discountRate,
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

  // Which visual design (Executive/Nordic/Vibrant/etc — see
  // preview_registry.dart) this invoice renders with. Set once from
  // InvoiceTemplateChooserScreen's selection (via StepCreateInvoice), and
  // changeable again later if a template picker is ever added to the
  // Customise step.
  void updateLayoutTemplateId(int id) {
    _invoiceData = _invoiceData.copyWith(layoutTemplateId: id);
    notifyListeners();
  }

  double _fontSize = 14.0;
  double get fontSize => _fontSize;
  void updateFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int _calcCompletion() => _calcCompletionFor(_invoiceData);

  // Pulled out of _calcCompletion() so addConvertedInvoice() can score
  // a converted InvoiceData that isn't the active draft.
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
