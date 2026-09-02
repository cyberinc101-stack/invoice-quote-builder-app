// document_alert_scheduler.dart
// lib/alerts/notifications/document_alert_scheduler.dart
//
// Schedules real OS push notifications for the three doc-driven alert
// categories that buildAlerts() (alert_engine.dart) already computes
// LIVE, IN-APP ONLY: overdue invoices, quotes expiring soon, stale
// drafts. Custom reminders already get real push treatment via
// NotificationService + ReminderProvider — this is the same plumbing for
// the other three AlertTypes, so a user who isn't in the app still gets
// notified.
//
// WHY THIS IS NEEDED: buildAlerts() re-derives its list from scratch every
// time it's called (each provider notifyListeners()). That's correct for
// the bell badge / Alerts screen, but there is no timer running while the
// app is closed to ever call it again — the only way to reach a closed
// app's user is to pre-schedule a real OS notification for the exact
// future moment the condition becomes true, exactly like
// ReminderProvider.addReminder() already does.
//
// SINGLE SOURCE OF TRUTH: the sync*() methods below call straight into
// filter_logic.dart's existing invoiceIsDraft / quoteIsDraft predicates and
// kExpiringSoonWindowDays constant, instead of duplicating that logic — so
// the push notification fires under exactly the same conditions the bell
// badge/Alerts screen already show, never a different threshold.
//
// NO-DUPLICATE-PUSH FIX (this pass): syncOverdueInvoiceAlert() and
// syncQuoteExpiringAlert() used to unconditionally fall back to "fire in
// 5 seconds" any time the natural due/expiry-derived fire time had
// already passed — which is correct the FIRST time a doc genuinely
// becomes overdue/expiring, but was also being hit by
// InvoiceProvider/QuoteProvider's every-app-launch resync safety net,
// and by routine edits/renames of an ALREADY-overdue/expiring doc. Net
// effect: any invoice that's already overdue, or any quote already
// inside its expiring-soon window, re-pushed a duplicate notification
// ~5 seconds after every single app open, and after every unrelated
// edit. Both methods now take an `allowImmediateFire` flag (default
// true, matching the old behavior) — callers that represent a genuine
// NEW transition into overdue/expiring (first save, an explicit status
// change) leave it true; callers that are just repairing/re-confirming
// existing state (the launch-time resync, routine content edits,
// renames, and the new AlertPrefs-toggle apply methods below) pass
// false, which means "if the natural fire time already passed, leave
// whatever's scheduled alone rather than inventing a new one."
//
// ALERTPREFS WIRING (this pass): InvoiceProvider.applyOverdueAlertsEnabled
// / applyDraftAlertsEnabled, QuoteProvider.applyExpiringAlertsEnabled /
// applyDraftAlertsEnabled, ReceiptProvider.applyDraftAlertsEnabled, and
// ReminderProvider.applyRemindersPushEnabled now let a toggle flip in
// alert_type_toggles.dart / settings_screen.dart cancel or re-arm real
// push notifications for that category, not just hide it from the
// in-app list — see those files for the actual wiring. This scheduler
// exposes cancelInvoiceDraftNudge / cancelQuoteDraftNudge /
// cancelReceiptDraftNudge (public wrappers around the existing private
// _cancelDraftNudge) so those provider methods have something to call
// when a toggle turns a category off.
//
// ALERTPREFS NOTE: the sync*() methods themselves still don't read
// AlertPrefs directly — they're called (or not called) by the providers,
// which are the ones that know both the current AlertPrefs state and the
// full list of saved documents. Keeps this class a pure "given a doc,
// make its notification match its current eligibility" scheduler, with
// no dependency on the prefs/provider layer above it.
//
// ID NAMESPACING: reuses NotificationService (same plugin/channel as
// custom reminders). Doc-based notification ids are hashed from a
// "category:docId" string, so they can never collide with a
// CustomReminder's id.hashCode-based notificationId.

import '../../filters/filter_date_utils.dart';
import '../../filters/filter_logic.dart' show kExpiringSoonWindowDays, invoiceIsDraft, quoteIsDraft;
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../notifications/notification_service.dart';

/// How long a draft sits untouched before we nudge the user about it.
/// Resets on every save (the sync method always cancels + reschedules), so
/// in practice this fires 24h after the LAST edit, not the original
/// creation — which is the more useful "gone stale" signal for a draft.
const Duration kDraftNudgeDelay = Duration(hours: 24);

enum DocAlertCategory { overdueInvoice, quoteExpiring, draftInvoice, draftQuote, draftReceipt }

enum DraftKind { invoice, quote, receipt }

extension DraftKindLabel on DraftKind {
  String get label => switch (this) {
        DraftKind.invoice => 'invoice',
        DraftKind.quote => 'quote',
        DraftKind.receipt => 'receipt',
      };
}

class DocumentAlertScheduler {
  DocumentAlertScheduler._();
  static final DocumentAlertScheduler instance = DocumentAlertScheduler._();

  int _id(DocAlertCategory category, String docId) =>
      '${category.name}:$docId'.hashCode & 0x7fffffff;

  Future<void> _schedule({
    required DocAlertCategory category,
    required String docId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) {
    return NotificationService.instance.scheduleReminder(
      id: _id(category, docId),
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      // Prefixed so NotificationService's tap handler can tell a doc alert
      // apart from a plain reminder id.
      payload: 'doc:${category.name}:$docId',
    );
  }

  Future<void> _cancel(DocAlertCategory category, String docId) {
    return NotificationService.instance.cancelReminder(_id(category, docId));
  }

  // ── Overdue invoices ────────────────────────────────────────────────

  /// Call whenever an invoice is saved/edited/status-changed. Decides
  /// schedule vs. cancel itself:
  ///  - paid -> cancel (can't go overdue anymore)
  ///  - unpaid + parseable due date -> schedule for that due date (or fire
  ///    almost immediately if the due date's already passed AND
  ///    [allowImmediateFire] is true)
  ///  - unpaid + manually flagged PaymentStatus.overdue but no parseable
  ///    due date -> fire almost immediately (if [allowImmediateFire]),
  ///    since we can't know "when"
  ///  - unpaid + no due date + not manually flagged -> cancel, nothing to
  ///    schedule against
  ///
  /// [allowImmediateFire] controls what happens when the natural fire
  /// time has ALREADY passed (i.e. this invoice is already overdue, not
  /// just becoming overdue right now). When true (the default — a first
  /// save, or an explicit status change), a past-due target still fires
  /// almost immediately, since that's the one moment a fresh "heads up"
  /// notification is actually earned. When false (the launch-time
  /// resync, routine content edits, renames, and the AlertPrefs-toggle
  /// apply methods below), a past-due target is left untouched instead —
  /// otherwise every app open / every unrelated edit of an
  /// already-overdue invoice would re-push a duplicate notification.
  Future<void> syncOverdueInvoiceAlert(
    SavedInvoice invoice, {
    bool allowImmediateFire = true,
  }) async {
    final unpaid = invoice.data.paymentStatus != PaymentStatus.paid;
    final due = parseDocDate(invoice.data.dueDate);
    final manuallyOverdue = invoice.data.paymentStatus == PaymentStatus.overdue;

    if (!unpaid || (due == null && !manuallyOverdue)) {
      await cancelOverdueInvoiceAlert(invoice.id);
      return;
    }

    final hasFutureDueDate = due != null && due.isAfter(DateTime.now());
    if (!hasFutureDueDate && !allowImmediateFire) {
      // Already overdue and this call isn't allowed to invent a fresh
      // "notify right now" moment — leave whatever's already scheduled
      // (or not scheduled) alone rather than re-firing a duplicate push.
      return;
    }

    await _cancel(DocAlertCategory.overdueInvoice, invoice.id);
    final target = hasFutureDueDate ? due : DateTime.now().add(const Duration(seconds: 5));
    await _schedule(
      category: DocAlertCategory.overdueInvoice,
      docId: invoice.id,
      title: 'Invoice overdue',
      body: '"${invoice.title}" is now overdue.',
      scheduledDate: target,
    );
  }

  /// Call when an invoice is deleted. (Paid/no-due-date cases are already
  /// handled by syncOverdueInvoiceAlert — call that instead for saves.)
  Future<void> cancelOverdueInvoiceAlert(String invoiceId) =>
      _cancel(DocAlertCategory.overdueInvoice, invoiceId);

  // ── Expiring quotes ─────────────────────────────────────────────────

  /// Call whenever a quote is saved/edited/status-changed. Only a
  /// QuoteStatus.sent quote with a parseable expiry date gets a scheduled
  /// push, mirroring quoteIsExpiringSoon() exactly. Fires
  /// kExpiringSoonWindowDays before expiry — the same lead time the
  /// in-app alert uses.
  ///
  /// [allowImmediateFire] — see syncOverdueInvoiceAlert's doc comment;
  /// same rule, applied to the expiring-soon window's fire time instead
  /// of a due date.
  Future<void> syncQuoteExpiringAlert(
    SavedQuote quote, {
    bool allowImmediateFire = true,
  }) async {
    final sent = quote.data.quoteStatus == QuoteStatus.sent;
    final expiry = parseDocDate(quote.data.expiryDate);

    if (!sent || expiry == null || !expiry.isAfter(DateTime.now())) {
      await cancelQuoteExpiringAlert(quote.id);
      return;
    }

    final fireAt = expiry.subtract(const Duration(days: kExpiringSoonWindowDays));
    final hasFutureFireTime = fireAt.isAfter(DateTime.now());
    if (!hasFutureFireTime && !allowImmediateFire) {
      // Already inside the expiring-soon window and this call isn't
      // allowed to invent a fresh "notify right now" moment — leave
      // whatever's already scheduled alone.
      return;
    }

    await _cancel(DocAlertCategory.quoteExpiring, quote.id);
    final target = hasFutureFireTime ? fireAt : DateTime.now().add(const Duration(seconds: 5));
    await _schedule(
      category: DocAlertCategory.quoteExpiring,
      docId: quote.id,
      title: 'Quote expiring soon',
      body: '"${quote.title}" expires soon.',
      scheduledDate: target,
    );
  }

  /// Call when a quote is deleted. (Non-sent/no-expiry cases are already
  /// handled by syncQuoteExpiringAlert — call that instead for saves.)
  Future<void> cancelQuoteExpiringAlert(String quoteId) =>
      _cancel(DocAlertCategory.quoteExpiring, quoteId);

  // ── Draft nudges ────────────────────────────────────────────────────

  Future<void> syncInvoiceDraftNudge(SavedInvoice invoice) => invoiceIsDraft(invoice)
      ? _scheduleDraftNudge(DraftKind.invoice, invoice.id, invoice.title)
      : _cancelDraftNudge(DraftKind.invoice, invoice.id);

  Future<void> syncQuoteDraftNudge(SavedQuote quote) => quoteIsDraft(quote)
      ? _scheduleDraftNudge(DraftKind.quote, quote.id, quote.title)
      : _cancelDraftNudge(DraftKind.quote, quote.id);

  /// Used by ReceiptProvider's save/rename/delete/resync hooks — see
  /// receipt_provider.dart's _syncDraftNudge().
  Future<void> syncReceiptDraftNudge({
    required String receiptId,
    required String title,
    required bool isDraft,
  }) => isDraft
      ? _scheduleDraftNudge(DraftKind.receipt, receiptId, title)
      : _cancelDraftNudge(DraftKind.receipt, receiptId);

  Future<void> _scheduleDraftNudge(DraftKind kind, String docId, String title) async {
    final category = _categoryFor(kind);
    await _cancel(category, docId);
    await _schedule(
      category: category,
      docId: docId,
      title: 'Unfinished ${kind.label}',
      body: '"$title" is still a draft — want to finish it?',
      scheduledDate: DateTime.now().add(kDraftNudgeDelay),
    );
  }

  Future<void> _cancelDraftNudge(DraftKind kind, String docId) =>
      _cancel(_categoryFor(kind), docId);

  // Public wrappers around _cancelDraftNudge — used by
  // InvoiceProvider.applyDraftAlertsEnabled / QuoteProvider.
  // applyDraftAlertsEnabled / ReceiptProvider.applyDraftAlertsEnabled when
  // the "Drafts" AlertPrefs toggle turns off, so a disabled draft nudge
  // can be cancelled without going through the isDraft-gated sync*()
  // methods (which would just re-decide draft status instead of forcing
  // a cancel).
  Future<void> cancelInvoiceDraftNudge(String invoiceId) =>
      _cancelDraftNudge(DraftKind.invoice, invoiceId);
  Future<void> cancelQuoteDraftNudge(String quoteId) =>
      _cancelDraftNudge(DraftKind.quote, quoteId);
  Future<void> cancelReceiptDraftNudge(String receiptId) =>
      _cancelDraftNudge(DraftKind.receipt, receiptId);

  DocAlertCategory _categoryFor(DraftKind kind) => switch (kind) {
        DraftKind.invoice => DocAlertCategory.draftInvoice,
        DraftKind.quote => DocAlertCategory.draftQuote,
        DraftKind.receipt => DocAlertCategory.draftReceipt,
      };

  // ── Bulk delete-time cleanup ────────────────────────────────────────
  // Call both when a doc is deleted, so neither its overdue/expiring alert
  // nor a pending draft nudge outlives the document itself.

  Future<void> cancelAllForInvoice(String invoiceId) async {
    await cancelOverdueInvoiceAlert(invoiceId);
    await _cancelDraftNudge(DraftKind.invoice, invoiceId);
  }

  Future<void> cancelAllForQuote(String quoteId) async {
    await cancelQuoteExpiringAlert(quoteId);
    await _cancelDraftNudge(DraftKind.quote, quoteId);
  }
}
