// reminder_provider.dart
// lib/alerts/custom_reminders/reminder_provider.dart

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
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kRemindersKey,
      _reminders.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<void> addReminder({
    required String title,
    required String note,
    required DateTime remindAt,
    bool notifyPush = true,
    String? linkedDocumentId,
    LinkedDocumentType? linkedDocumentType,
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
}
