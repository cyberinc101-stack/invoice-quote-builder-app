// alert_types.dart
// lib/alerts/alert_types.dart

import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';
import '../widgets/saved_documents_containers.dart' show DocType;
import 'custom_reminders/reminder_model.dart';

enum AlertType { overdueInvoice, quoteExpiringSoon, draftInProgress, customReminder }

// Ordered so a plain index compare sorts high-priority first.
enum AlertPriority { high, medium }

class AlertItem {
  final AlertType type;
  final AlertPriority priority;
  final String title;
  final String subtitle;
  final DocType? docType;
  final SavedInvoice? invoice;
  final SavedQuote? quote;
  final SavedReceipt? receipt;
  final CustomReminder? reminder;

  const AlertItem({
    required this.type,
    required this.priority,
    required this.title,
    required this.subtitle,
    this.docType,
    this.invoice,
    this.quote,
    this.receipt,
    this.reminder,
  });
}
