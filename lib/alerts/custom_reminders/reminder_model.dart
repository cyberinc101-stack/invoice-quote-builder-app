// reminder_model.dart
// lib/alerts/custom_reminders/reminder_model.dart
//
// A manually-created reminder — not derived from an invoice/quote's
// due/expiry date like the automatic alerts. The user picks the title,
// note, and exact date/time themselves. Optionally links to a real saved
// invoice or quote so tapping it can jump straight to that document.

enum LinkedDocumentType { invoice, quote }

class CustomReminder {
  final String id;
  final String title;
  final String note;
  final DateTime remindAt;
  final DateTime createdAt;
  final bool notifyPush;
  final String? linkedDocumentId;
  final LinkedDocumentType? linkedDocumentType;

  const CustomReminder({
    required this.id,
    required this.title,
    required this.note,
    required this.remindAt,
    required this.createdAt,
    this.notifyPush = true,
    this.linkedDocumentId,
    this.linkedDocumentType,
  });

  bool get isDue => !remindAt.isAfter(DateTime.now());

  bool get hasLinkedDocument => linkedDocumentId != null && linkedDocumentType != null;

  // Notification IDs must be plain ints. Derived from the string id so it's
  // stable across app restarts (same reminder always maps to the same
  // notification id, so re-scheduling/cancelling targets the right one).
  int get notificationId => id.hashCode & 0x7fffffff;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'remindAt': remindAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'notifyPush': notifyPush,
        'linkedDocumentId': linkedDocumentId,
        'linkedDocumentType': linkedDocumentType?.name,
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
    );
  }
}
