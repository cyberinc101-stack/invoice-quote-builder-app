// reminder_provider.dart
// lib/alerts/custom_reminders/reminder_provider.dart
//
// RESTORE (earlier pass): restoreReminder() puts a deleted reminder back
// exactly as it was (same id, same remindAt) for the delete-snackbar Undo
// action — addReminder() always mints a fresh id/createdAt, which would
// silently break Undo by creating a second, different reminder.
//
// TAP PAYLOAD (earlier pass): scheduled notifications carry the reminder's
// id as their payload so NotificationService can route a tap back to the
// right reminder via onReminderTapped.
//
// RESCHEDULE-ON-LAUNCH (this pass): some OEM Android builds (MIUI, Huawei,
// aggressive battery-optimization modes on Samsung) kill the boot receiver
// that's supposed to re-arm scheduled alarms after a restart, even with
// AndroidManifest.xml wired correctly. As a safety net, every normal app
// launch re-syncs every future notifyPush reminder against the OS
// scheduler via resyncScheduledNotifications() — cheap (cancel + schedule,
// a no-op if already correct) and guarantees that simply opening the app
// once repairs a device that dropped its alarms.
//
// EDIT (this pass): updateReminder() changes an existing reminder in place
// (same id/createdAt) so fixing a typo or nudging a time doesn't lose the
// original creation history the way delete+recreate would.
//
// RECURRENCE (this pass): addReminder/updateReminder accept a
// ReminderRecurrence. advanceRecurringReminder() is what a swipe-dismiss
// calls on a recurring reminder instead of deleting it outright — moves
// remindAt to the next occurrence and reschedules under the same id, so
// the series continues. snoozeReminder() pushes remindAt back by a fixed
// amount (used by the Snooze buttons on due alert cards) without touching
// recurrence — it only shifts the current occurrence.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reminder_model.dart';
import '../notifications/notification_service.dart';

const String _kRemindersKey = 'custom_reminders_v1';

class ReminderProvider extends ChangeNotifier {
  List<CustomReminder> _reminders = [];

  List<CustomReminder> get reminders => List.unmodifiable(_reminders);

  // Reminders whose time has already passed — these are what feed into the
  // Alerts screen / bell badge alongside overdue invoices etc.
  List<CustomReminder> get dueReminders =>
      _reminders.where((r) => r.isDue).toList();

  Future<void> loadPersistedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRemindersKey) ?? [];
    _reminders = raw
        .map((s) => CustomReminder.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    _reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    notifyListeners();

    // Safety net — see file header. Fire-and-forget; never blocks startup
    // and never surfaces an error to the user if a single reschedule fails.
    unawaited(resyncScheduledNotifications());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kRemindersKey,
      _reminders.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  /// Re-arms every future, push-enabled reminder with the OS notification
  /// scheduler. Safe to call as often as you like — flutter_local_notifications
  /// treats each call as cancel-then-schedule under the same id, so an
  /// already-correct alarm is just overwritten with itself. This is what
  /// protects against boot receivers killed by OEM battery managers: the
  /// fix isn't "survive the reboot," it's "repair itself the next time the
  /// app is opened."
  Future<void> resyncScheduledNotifications() async {
    final now = DateTime.now();
    final upcoming = _reminders.where(
      (r) => r.notifyPush && r.remindAt.isAfter(now),
    );

    for (final reminder in upcoming) {
      try {
        await NotificationService.instance.scheduleReminder(
          id: reminder.notificationId,
          title: reminder.title,
          body: reminder.note.isEmpty ? 'Reminder' : reminder.note,
          scheduledDate: reminder.remindAt,
          payload: reminder.id,
        );
      } catch (_) {
        // Best-effort — one bad reminder shouldn't stop the rest from
        // re-syncing, and this already runs silently in the background.
      }
    }
  }

  Future<void> addReminder({
    required String title,
    required String note,
    required DateTime remindAt,
    bool notifyPush = true,
    String? linkedDocumentId,
    LinkedDocumentType? linkedDocumentType,
    ReminderRecurrence recurrence = ReminderRecurrence.none,
  }) async {
    final reminder = CustomReminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      note: note,
      remindAt: remindAt,
      createdAt: DateTime.now(),
      notifyPush: notifyPush,
      linkedDocumentId: linkedDocumentId,
      linkedDocumentType: linkedDocumentType,
      recurrence: recurrence,
    );
    _reminders.add(reminder);
    _reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    notifyListeners();
    await _persist();

    if (notifyPush && remindAt.isAfter(DateTime.now())) {
      // Fails silently (caught inside NotificationService) if the platform
      // package isn't wired up yet — the reminder itself still gets saved
      // and will still show up in-app on the Alerts screen either way.
      await NotificationService.instance.scheduleReminder(
        id: reminder.notificationId,
        title: reminder.title,
        body: reminder.note.isEmpty ? 'Reminder' : reminder.note,
        scheduledDate: remindAt,
        payload: reminder.id,
      );
    }
  }

  /// Updates an existing reminder in place — used by the reminder-edit
  /// flow so fixing a typo or nudging a time doesn't lose the original
  /// creation history the way delete+recreate would. Always cancels the
  /// old alarm first and reschedules under the same id, so a changed time,
  /// a flipped notifyPush, or a changed recurrence all take effect
  /// immediately.
  Future<void> updateReminder(
    String id, {
    required String title,
    required String note,
    required DateTime remindAt,
    bool notifyPush = true,
    String? linkedDocumentId,
    LinkedDocumentType? linkedDocumentType,
    ReminderRecurrence recurrence = ReminderRecurrence.none,
  }) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final existing = _reminders[index];

    await NotificationService.instance.cancelReminder(existing.notificationId);

    final updated = existing.copyWith(
      title: title,
      note: note,
      remindAt: remindAt,
      notifyPush: notifyPush,
      linkedDocumentId: linkedDocumentId,
      linkedDocumentType: linkedDocumentType,
      recurrence: recurrence,
      clearLinkedDocument: linkedDocumentId == null,
    );

    _reminders[index] = updated;
    _reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    notifyListeners();
    await _persist();

    if (notifyPush && remindAt.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleReminder(
        id: updated.notificationId,
        title: updated.title,
        body: updated.note.isEmpty ? 'Reminder' : updated.note,
        scheduledDate: remindAt,
        payload: updated.id,
      );
    }
  }

  Future<void> deleteReminder(String id) async {
    final match = _reminders.where((r) => r.id == id).toList();
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await _persist();
    if (match.isNotEmpty) {
      await NotificationService.instance.cancelReminder(match.first.notificationId);
    }
  }

  /// Puts a previously-deleted reminder back exactly as it was (same id,
  /// same schedule) — used by the "Undo" action on the delete snackbar. If
  /// the reminder is already back in the list (e.g. Undo tapped twice),
  /// this is a no-op rather than creating a duplicate.
  Future<void> restoreReminder(CustomReminder reminder) async {
    if (_reminders.any((r) => r.id == reminder.id)) return;
    _reminders.add(reminder);
    _reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    notifyListeners();
    await _persist();

    if (reminder.notifyPush && reminder.remindAt.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleReminder(
        id: reminder.notificationId,
        title: reminder.title,
        body: reminder.note.isEmpty ? 'Reminder' : reminder.note,
        scheduledDate: reminder.remindAt,
        payload: reminder.id,
      );
    }
  }

  /// Moves a recurring reminder to its next occurrence instead of deleting
  /// it — called when a recurring reminder is swipe-dismissed, so the
  /// series continues rather than ending. A non-recurring reminder should
  /// never reach here (callers check isRecurring first); if one does, this
  /// is a safe no-op.
  Future<void> advanceRecurringReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final existing = _reminders[index];
    if (!existing.isRecurring) return;

    await NotificationService.instance.cancelReminder(existing.notificationId);

    final next = existing.copyWith(remindAt: existing.nextOccurrenceAfter(DateTime.now()));
    _reminders[index] = next;
    _reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    notifyListeners();
    await _persist();

    if (next.notifyPush) {
      await NotificationService.instance.scheduleReminder(
        id: next.notificationId,
        title: next.title,
        body: next.note.isEmpty ? 'Reminder' : next.note,
        scheduledDate: next.remindAt,
        payload: next.id,
      );
    }
  }

  /// Pushes a reminder's time back by [extra] — used by the Snooze buttons
  /// on due alert cards. Works for both recurring and one-off reminders;
  /// recurrence itself is untouched, only this one occurrence shifts.
  Future<void> snoozeReminder(String id, Duration extra) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final existing = _reminders[index];

    await NotificationService.instance.cancelReminder(existing.notificationId);

    final snoozed = existing.copyWith(remindAt: DateTime.now().add(extra));
    _reminders[index] = snoozed;
    _reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    notifyListeners();
    await _persist();

    if (snoozed.notifyPush) {
      await NotificationService.instance.scheduleReminder(
        id: snoozed.notificationId,
        title: snoozed.title,
        body: snoozed.note.isEmpty ? 'Reminder' : snoozed.note,
        scheduledDate: snoozed.remindAt,
        payload: snoozed.id,
      );
    }
  }
}