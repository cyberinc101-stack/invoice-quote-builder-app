// receipt_provider.dart
// lib/providers/receipt_provider.dart
//
// CONVERT FORMAT PASS (this update): added updateSavedReceiptFormat() —
// writes a new layoutTemplateId/paperFormat onto an already-SAVED
// receipt's data, same pattern as updateSavedReceiptStatus/
// updateReceiptFolder (find index, copyWith the data, persist,
// notifyListeners). Backs the new "Convert Format (A4 ↔ Thermal)" option
// in saved_document_detail_screen.dart's options sheet, which reuses
// ReceiptTemplateChooserScreen (via its onTemplateChosen callback,
// already used by the invoice→receipt conversion flow) as a plain
// paper-format/design picker for an EXISTING receipt rather than a new
// one.
//
// ALERTPREFS PUSH WIRING (earlier pass): added applyDraftAlertsEnabled() —
// called from alert_type_toggles.dart's "Drafts" switch and
// settings_screen.dart's master Alerts switch whenever the effective
// enabled state (alertsEnabled && draftsEnabled) changes, so turning
// drafts off actually cancels every saved receipt's pending draft-nudge
// push instead of only hiding it from the in-app Alerts screen/bell
// badge. Mirrors InvoiceProvider.applyDraftAlertsEnabled /
// QuoteProvider.applyDraftAlertsEnabled — see invoice_provider.dart's
// header comment for the full rationale.
//
// PUSH ALERTS (earlier pass): receipts now get real push notifications
// for stale drafts, the same way InvoiceProvider/QuoteProvider already
// do. Receipts have no overdue/expiring concept (they're already-settled
// records — see filter_logic.dart's comment on
// applyQuickFilterToReceipts), so drafts are the only category that
// applies here. Uses filter_logic.dart's receiptIsDraft() predicate
// directly, same single-source-of-truth pattern as the other two
// providers.
//
// ADDED (earlier pass): currentReceiptId getter, exposing the private
// _currentReceiptId so CreateReceiptScreen can look up the SavedReceipt
// it just created/updated after calling saveCurrentReceipt() (which
// returns Future<void>, not the saved object itself — unlike
// QuoteProvider.saveCurrentQuote()).

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt_data.dart';
import '../filters/filter_logic.dart' show receiptIsDraft;
import '../alerts/notifications/document_alert_scheduler.dart';

class ReceiptProvider extends ChangeNotifier {
  static const _storageKey = 'saved_receipts';

  ReceiptData _currentReceiptData = ReceiptData();
  String? _currentReceiptId;

  final List<SavedReceipt> _savedReceipts = [];

  ReceiptData get currentReceiptData => _currentReceiptData;
  List<SavedReceipt> get savedReceipts => List.unmodifiable(_savedReceipts);

  // Exposes the id of whatever's currently loaded in the editor (or the id
  // just assigned by the most recent saveCurrentReceipt() call). Null if
  // nothing's been saved yet this session.
  String? get currentReceiptId => _currentReceiptId;

  // -- Reset / update current draft ------------------------------------------

  void resetReceiptData() {
    _currentReceiptData = ReceiptData();
    _currentReceiptId = null;
    notifyListeners();
  }

  void updateReceiptData(ReceiptData data) {
    _currentReceiptData = data;
    notifyListeners();
  }

  // -- Completion percent (simple heuristic) ---------------------------------

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

  // ── AlertPrefs push wiring ─────────────────────────────────────────────────
  // Called from alert_type_toggles.dart / settings_screen.dart whenever the
  // EFFECTIVE enabled state for drafts (alertsEnabled && draftsEnabled)
  // changes. Mirrors InvoiceProvider.applyDraftAlertsEnabled /
  // QuoteProvider.applyDraftAlertsEnabled.

  Future<void> applyDraftAlertsEnabled(bool enabled) async {
    for (final r in _savedReceipts) {
      try {
        if (enabled) {
          await _syncDraftNudge(r);
        } else {
          await DocumentAlertScheduler.instance.cancelReceiptDraftNudge(r.id);
        }
      } catch (_) {
        // Best-effort — one bad receipt shouldn't stop the rest applying.
      }
    }
  }

  // -- Save current draft as a SavedReceipt ----------------------------------

  Future<void> saveCurrentReceipt({
    required String title,
    required String templateName,
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
  }

  // Saves a converted ReceiptData (e.g. built from an invoice via
  // convertInvoiceDataToReceiptData) directly as a new saved receipt,
  // WITHOUT touching the active editor draft — unlike saveCurrentReceipt(),
  // which always saves/updates based on _currentReceiptData /
  // _currentReceiptId. Used by the "Convert to Receipt" action in
  // saved_document_detail_screen.dart.
  Future<SavedReceipt> addConvertedReceipt({
    required ReceiptData data,
    required String title,
    required String templateName,
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
    return saved;
  }

  // -- Load a saved receipt back into the editor -----------------------------

  void loadSavedReceipt(String id) {
    final match = _savedReceipts.where((r) => r.id == id);
    if (match.isEmpty) return;

    final saved = match.first;
    _currentReceiptId = saved.id;
    _currentReceiptData = saved.data.deepCopy();
    notifyListeners();
  }

  // -- Rename -----------------------------------------------------------------

  Future<void> renameSavedReceipt(String id, String newTitle) async {
    final index = _savedReceipts.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    _savedReceipts[index] = _savedReceipts[index].copyWith(title: trimmed);
    await _persist();
    notifyListeners();
    // Title changed -> re-sync so a pending draft nudge's body text (which
    // embeds the title) doesn't go stale.
    unawaited(_syncDraftNudge(_savedReceipts[index]));
  }

  // -- Status ------------------------------------------------------------
  // Powers the tappable status chip in saved_document_detail_screen.dart.

  Future<void> updateSavedReceiptStatus(String id, ReceiptStatus status) async {
    final index = _savedReceipts.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _savedReceipts[index] = _savedReceipts[index].copyWith(
      data: _savedReceipts[index].data.copyWith(status: status),
      lastEditedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  // -- Format (paper size / design) --------------------------------------
  // CONVERT FORMAT PASS: writes a new layoutTemplateId/paperFormat onto
  // an already-SAVED receipt's data directly — same pattern as
  // updateSavedReceiptStatus above. Powers the "Convert Format (A4 ↔
  // Thermal)" option in saved_document_detail_screen.dart, which opens
  // ReceiptTemplateChooserScreen as a plain picker (via its
  // onTemplateChosen callback) and hands the chosen (templateId,
  // paperFormat) straight here. Doesn't touch the active editor draft —
  // this updates the SAVED entry only, matching updateSavedReceiptStatus/
  // updateReceiptFolder/updateReceiptExcludeFromReports.
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

  // -- Folder --------------------------------------------------------------
  // Assigns or clears the organizational folder for a saved receipt.
  // Pass null to remove it from whatever folder it's currently in. Updates
  // the SAVED entry directly, same pattern as updateSavedReceiptStatus.

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

  // -- Reports exclusion ----------------------------------------------------
  // Same pattern as InvoiceProvider.updateInvoiceExcludeFromReports.

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

  // -- Delete -------------------------------------------------------------

  Future<void> deleteSavedReceipt(String id) async {
    _savedReceipts.removeWhere((r) => r.id == id);
    if (_currentReceiptId == id) {
      _currentReceiptId = null;
    }
    await _persist();
    notifyListeners();
    unawaited(DocumentAlertScheduler.instance.syncReceiptDraftNudge(
      receiptId: id,
      title: '',
      isDraft: false, // deleted -> always cancel, regardless of last-known draft state
    ));
  }

  // -- Persistence --------------------------------------------------------

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
      // Re-arms every saved receipt's draft-nudge push against the OS
      // scheduler on every launch — same safety net InvoiceProvider/
      // QuoteProvider/ReminderProvider use.
      unawaited(_resyncDocumentAlerts());
    }
  }

  Future<void> _resyncDocumentAlerts() async {
    for (final r in _savedReceipts) {
      try {
        await _syncDraftNudge(r);
      } catch (_) {
        // Best-effort — one bad receipt shouldn't stop the rest resyncing.
      }
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
