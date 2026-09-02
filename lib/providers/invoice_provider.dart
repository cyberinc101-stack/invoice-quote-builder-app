// invoice_provider.dart
// lib/providers/invoice_provider.dart
//
// FIELD VISIBILITY RELOCATION PASS (this update): added
// updateEnabledFields(), mirroring updateColorScheme()/updateFontFamily()'s
// shape — a thin pass-through to InvoiceData.copyWith. Backs the new
// "Invoice Fields"/"Customer Fields" toggle section on the Customise step
// (step_customise.dart's _FieldVisibilitySection), which replaces the
// same toggles that used to live on the "New Template"/"Edit Template"
// sheet (step_templates.dart) and only ever wrote to
// InvoiceTemplate.enabledFields — a value that was copied onto the actual
// invoice once, on first template selection, and never again (see
// step_create_invoice.dart's own pass note). Field visibility is now a
// genuine per-invoice setting.
//
// ALERTPREFS PUSH WIRING (earlier pass): added applyOverdueAlertsEnabled()
// and applyDraftAlertsEnabled() — called from alert_type_toggles.dart's
// "Overdue Invoices"/"Drafts" switches and settings_screen.dart's master
// Alerts switch whenever the effective enabled state (alertsEnabled &&
// the per-type flag) changes, so turning a category off actually cancels
// its real push notifications instead of only hiding it from the in-app
// Alerts screen/bell badge. Both iterate every saved invoice and either
// resync (allowImmediateFire: false — see document_alert_scheduler.dart's
// header comment for why) or cancel that invoice's notification for the
// category.
//
// NO-DUPLICATE-PUSH FIX (earlier pass): _resyncDocumentAlerts(),
// updateSavedInvoice(), and renameInvoice() now pass
// allowImmediateFire: false to syncOverdueInvoiceAlert(). Previously an
// already-overdue invoice would get a fresh "Invoice overdue" push
// notification ~5 seconds after EVERY app launch (via the resync safety
// net below) and after every unrelated edit/rename — because the
// scheduler always substituted "fire in 5 seconds" whenever the due
// date had already passed. Only genuine new-transition moments (first
// save, an explicit status change via updateSavedInvoiceStatus) still
// allow that immediate fire — see document_alert_scheduler.dart for the
// actual fix.
//
// STATUS HIDDEN PASS (earlier update): updateSavedInvoiceStatus now also
// clears statusHidden back to false whenever a real status is selected
// (picking any of Unpaid/Partial/Paid/Overdue in the status menu implies
// "show the chip again"). New method updateSavedInvoiceStatusHidden(id,
// hidden) powers the "None" option in the status menu — it flips
// InvoiceData.statusHidden without touching paymentStatus, so aging/
// overdue/reports logic (all of which read paymentStatus) is completely
// unaffected; only the card-face chip in doc_cards.dart is gated on this.
//
// TEMPLATE + LOGO SIZER PASS (earlier): two new methods —
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
        // allowImmediateFire: false — this runs on every app launch, so an
        // invoice that's already overdue must NOT re-fire a fresh "notify
        // now" push every single time the app opens. Only re-arms alarms
        // whose natural due-date fire time is still in the future.
        await DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(inv, allowImmediateFire: false);
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

  // ── AlertPrefs push wiring ─────────────────────────────────────────────────
  // Called from alert_type_toggles.dart / settings_screen.dart whenever the
  // EFFECTIVE enabled state for a category (alertsEnabled && the per-type
  // flag) changes. `enabled: true` resyncs every saved invoice's push for
  // that category (allowImmediateFire: false — re-enabling isn't a fresh
  // "just became overdue" moment); `enabled: false` cancels it outright.
  // These never touch the in-app Alerts list — that's driven live by
  // buildAlerts() reading AlertPrefs directly on every rebuild.

  Future<void> applyOverdueAlertsEnabled(bool enabled) async {
    for (final inv in _savedInvoices) {
      try {
        if (enabled) {
          await DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(inv, allowImmediateFire: false);
        } else {
          await DocumentAlertScheduler.instance.cancelOverdueInvoiceAlert(inv.id);
        }
      } catch (_) {
        // Best-effort — one bad invoice shouldn't stop the rest applying.
      }
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
      } catch (_) {
        // Best-effort — one bad invoice shouldn't stop the rest applying.
      }
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
    // First save of this invoice — a genuine new-transition moment, so
    // an already-past due date is still allowed to fire almost
    // immediately (default allowImmediateFire: true).
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
    // First save of this invoice — see saveCurrentInvoice()'s comment.
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
    // Routine content edit, not a fresh "just became overdue" moment —
    // allowImmediateFire: false so editing e.g. a line item on an
    // already-overdue invoice doesn't re-push a duplicate notification.
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
    // Title changed -> re-sync so a pending notification's body text
    // (which embeds the title) doesn't go stale. Not a fresh transition —
    // allowImmediateFire: false, same reasoning as updateSavedInvoice.
    final updated = _savedInvoices[index];
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(updated, allowImmediateFire: false));
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
  //
  // Picking any real status here also clears statusHidden back to false —
  // choosing Unpaid/Partial/Paid/Overdue implies "show the chip again",
  // the opposite of the "None" option (see updateSavedInvoiceStatusHidden
  // below).

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
    // A status flip is exactly the case that most needs a resync — e.g.
    // marking paid must cancel a pending overdue push immediately, not
    // wait for the next app launch's resync pass. It's also a genuine
    // new transition (e.g. flipping to Overdue), so this keeps the
    // default allowImmediateFire: true.
    unawaited(DocumentAlertScheduler.instance.syncOverdueInvoiceAlert(_savedInvoices[index]));
  }

  // Toggles whether the status chip renders on this invoice's cards,
  // WITHOUT touching paymentStatus itself — powers the "None" option in
  // the status menu (document_status_menu.dart). paymentStatus keeps
  // whatever real value it already held, so aging/overdue/reports logic
  // (which all read paymentStatus, not this flag) is completely
  // unaffected; only the card-face chip in doc_cards.dart is gated on
  // statusHidden.
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

  // Logo display size (box width/height in px, default 44.0) — separate
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

  // FIELD VISIBILITY RELOCATION PASS: writes the Invoice Fields/Customer
  // Fields toggle selections onto InvoiceData.enabledFields. Mirrors
  // updateColorScheme/updateFontFamily's shape — a thin pass-through to
  // copyWith. Called from step_customise.dart's _FieldVisibilitySection,
  // which replaces the toggle sheet that used to live on
  // step_templates.dart (that sheet only ever wrote to
  // InvoiceTemplate.enabledFields, a value StepCreateInvoice copied onto
  // the actual invoice once and never again — see that file's own pass
  // note). This is the single place InvoiceData.enabledFields is now
  // written from user interaction.
  void updateEnabledFields(Map<String, bool> enabledFields) {
    _invoiceData = _invoiceData.copyWith(
      enabledFields: Map<String, bool>.from(enabledFields),
    );
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