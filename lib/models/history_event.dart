// lib/models/history_event.dart
//
// A single logged action against a saved document — created, shared,
// downloaded, sent, printed, or deleted. HistoryProvider persists a list
// of these and HistoryScreen renders them as an activity feed, newest
// first, with a "do it again" action per row where a cached file exists.

enum HistoryEventType { created, shared, downloaded, sent, printed, deleted }

enum HistoryDocType { invoice, quote, receipt }

class HistoryEvent {
  final String id;
  final HistoryEventType type;
  final HistoryDocType docType;
  final String docId;
  final String docNumber;
  final String? clientName;
  final double? amount;
  final String? currency;
  final DateTime timestamp;

  /// Path to a cached copy of the file involved (PDF/XLSX/CSV) at the time
  /// this event was logged, if any. Powers "send again" without
  /// regenerating the document. May point to a file that no longer exists
  /// if the user cleared app storage — callers should check before use.
  final String? filePath;
  final String? note;

  const HistoryEvent({
    required this.id,
    required this.type,
    required this.docType,
    required this.docId,
    required this.docNumber,
    this.clientName,
    this.amount,
    this.currency,
    required this.timestamp,
    this.filePath,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'docType': docType.name,
        'docId': docId,
        'docNumber': docNumber,
        'clientName': clientName,
        'amount': amount,
        'currency': currency,
        'timestamp': timestamp.toIso8601String(),
        'filePath': filePath,
        'note': note,
      };

  factory HistoryEvent.fromJson(Map<String, dynamic> j) {
    return HistoryEvent(
      id: j['id'] as String? ?? '',
      type: HistoryEventType.values.firstWhere(
        (t) => t.name == j['type'],
        orElse: () => HistoryEventType.created,
      ),
      docType: HistoryDocType.values.firstWhere(
        (t) => t.name == j['docType'],
        orElse: () => HistoryDocType.invoice,
      ),
      docId: j['docId'] as String? ?? '',
      docNumber: j['docNumber'] as String? ?? '',
      clientName: j['clientName'] as String?,
      amount: (j['amount'] as num?)?.toDouble(),
      currency: j['currency'] as String?,
      timestamp:
          DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
      filePath: j['filePath'] as String?,
      note: j['note'] as String?,
    );
  }
}
