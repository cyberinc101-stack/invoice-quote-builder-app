// digest_scheduler.dart
// lib/alerts/notifications/digest_scheduler.dart
//
// Schedules (or cancels) the single recurring weekly-summary notification
// — a lightweight sibling to DocumentAlertScheduler, but for exactly one
// notification slot rather than one per document. Deliberately generic
// body text: see notification_service.dart's scheduleWeeklyDigest() doc
// comment for why this doesn't (and can't reliably) embed actual numbers.
//
// USAGE:
//   - Call WeeklyDigestScheduler.instance.sync(alertPrefs.weeklyDigestEnabled)
//     once at app startup, right after AlertPrefs.load() resolves — same
//     spot InvoiceProvider/QuoteProvider/ReceiptProvider already resync
//     their own document alerts.
//   - Call it again any time the user flips the "Weekly Summary" toggle
//     in Settings (see settings_screen.dart), passing the new value.
//
// sync(true) is safe to call repeatedly — scheduleWeeklyDigest() replaces
// the existing schedule by id rather than duplicating it, so re-syncing
// the same "on" state on every launch is a cheap no-op in practice, not a
// pile-up of duplicate notifications.

import 'notification_service.dart';

class WeeklyDigestScheduler {
  WeeklyDigestScheduler._();
  static final WeeklyDigestScheduler instance = WeeklyDigestScheduler._();

  // Fixed id — there is only ever one weekly digest slot, unlike document
  // alerts which hash a per-document id. Chosen well outside the range
  // DocumentAlertScheduler's hashCode-based ids or CustomReminder's own
  // ids are likely to produce, to avoid any accidental collision.
  static const int _notificationId = 999001;

  Future<void> sync(bool enabled) async {
    if (!enabled) {
      await NotificationService.instance.cancelReminder(_notificationId);
      return;
    }
    await NotificationService.instance.scheduleWeeklyDigest(
      id: _notificationId,
      title: 'Your weekly summary is ready',
      body: "See what you've invoiced and what's still outstanding this week.",
      weekday: DateTime.monday,
      hour: 9,
      minute: 0,
      payload: 'digest:weekly',
    );
  }
}

// NOTE for main.dart wiring: set
//   NotificationService.instance.onDigestTapped = () {
//     navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
//   };
// using whatever import path your project already uses for ReportsScreen
// (lib/screens/reports/reports_screen.dart) and however main.dart already
// navigates for onDocumentAlertTapped — same pattern, new callback.
