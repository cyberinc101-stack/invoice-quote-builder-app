// reminder_model.dart
// lib/alerts/custom_reminders/reminder_model.dart
//
// A manually-created reminder — not derived from an invoice/quote's
// due/expiry date like the automatic alerts. The user picks the title,
// note, and exact date/time themselves. Optionally links to a real saved
// invoice or quote so tapping it can jump straight to that document.
//
// RECURRENCE (this pass): a reminder can now repeat daily/weekly/monthly.
// A recurring reminder is never hard-deleted by a swipe or a snooze —
// ReminderProvider.advanceRecurringReminder() moves it to its next
// occurrence instead. Only an explicit delete ends the series. Existing
// persisted reminders with no 'recurrence' key deserialize to `none`, so
// this is fully backward compatible with data saved before this pass.

enum LinkedDocumentType { invoice, quote }

enum ReminderRecurrence { none, daily, weekly, monthly }

extension ReminderRecurrenceLabel on ReminderRecurrence {
  String get label {
    switch (this) {
      case ReminderRecurrence.none:
        return 'Does not repeat';
      case ReminderRecurrence.daily:
        return 'Repeats daily';
      case ReminderRecurrence.weekly:
        return 'Repeats weekly';
      case ReminderRecurrence.monthly:
        return 'Repeats monthly';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReminderRecurrence.none:
        return 'Once';
      case ReminderRecurrence.daily:
        return 'Daily';
      case ReminderRecurrence.weekly:
        return 'Weekly';
      case ReminderRecurrence.monthly:
        return 'Monthly';
    }
  }
}

class CustomReminder {
  final String id;
  final String title;
  final String note;
  final DateTime remindAt;
  final DateTime createdAt;
  final bool notifyPush;
  final String? linkedDocumentId;
  final LinkedDocumentType? linkedDocumentType;
  final ReminderRecurrence recurrence;

  const CustomReminder({
    required this.id,
    required this.title,
    required this.note,
    required this.remindAt,
    required this.createdAt,
    this.notifyPush = true,
    this.linkedDocumentId,
    this.linkedDocumentType,
    this.recurrence = ReminderRecurrence.none,
  });

  bool get isDue => !remindAt.isAfter(DateTime.now());

  bool get hasLinkedDocument => linkedDocumentId != null && linkedDocumentType != null;

  bool get isRecurring => recurrence != ReminderRecurrence.none;

  // Notification IDs must be plain ints. Derived from the string id so it's
  // stable across app restarts (same reminder always maps to the same
  // notification id, so re-scheduling/cancelling targets the right one).
  int get notificationId => id.hashCode & 0x7fffffff;

  /// The next time this reminder should fire, strictly after [from]. For a
  /// reminder that's been due for a while (app was closed past one or more
  /// cycles), this steps forward repeatedly rather than landing back in
  /// the past. Returns [remindAt] unchanged for a non-recurring reminder —
  /// callers should check [isRecurring] first, this is just a safe default.
  DateTime nextOccurrenceAfter(DateTime from) {
    if (recurrence == ReminderRecurrence.none) return remindAt;
    DateTime next = remindAt;
    switch (recurrence) {
      case ReminderRecurrence.none:
        break;
      case ReminderRecurrence.daily:
        while (!next.isAfter(from)) {
          next = next.add(const Duration(days: 1));
        }
        break;
      case ReminderRecurrence.weekly:
        while (!next.isAfter(from)) {
          next = next.add(const Duration(days: 7));
        }
        break;
      case ReminderRecurrence.monthly:
        while (!next.isAfter(from)) {
          next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
        }
        break;
    }
    return next;
  }

  CustomReminder copyWith({
    String? title,
    String? note,
    DateTime? remindAt,
    bool? notifyPush,
    String? linkedDocumentId,
    LinkedDocumentType? linkedDocumentType,
    ReminderRecurrence? recurrence,
    bool clearLinkedDocument = false,
  }) {
    return CustomReminder(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      remindAt: remindAt ?? this.remindAt,
      createdAt: createdAt,
      notifyPush: notifyPush ?? this.notifyPush,
      linkedDocumentId: clearLinkedDocument ? null : (linkedDocumentId ?? this.linkedDocumentId),
      linkedDocumentType: clearLinkedDocument ? null : (linkedDocumentType ?? this.linkedDocumentType),
      recurrence: recurrence ?? this.recurrence,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'remindAt': remindAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'notifyPush': notifyPush,
        'linkedDocumentId': linkedDocumentId,
        'linkedDocumentType': linkedDocumentType?.name,
        'recurrence': recurrence.name,
      };

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    return CustomReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String? ?? '',
      remindAt: DateTime.parse(json['remindAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notifyPush: json['notifyPush'] as bool? ?? true,
      linkedDocumentId: json['linkedDocumentId'] as String?,
      linkedDocumentType: (json['linkedDocumentType'] as String?) == null
          ? null
          : LinkedDocumentType.values.firstWhere(
              (t) => t.name == json['linkedDocumentType'],
              orElse: () => LinkedDocumentType.invoice,
            ),
      recurrence: (json['recurrence'] as String?) == null
          ? ReminderRecurrence.none
          : ReminderRecurrence.values.firstWhere(
              (r) => r.name == json['recurrence'],
              orElse: () => ReminderRecurrence.none,
            ),
    );
  }
}
