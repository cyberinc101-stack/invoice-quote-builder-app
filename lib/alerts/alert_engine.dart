// alert_engine.dart
// lib/alerts/alert_engine.dart
//
// Turns the saved-document lists AND due custom reminders into a
// prioritized List<AlertItem>. Every doc rule here calls straight into
// filter_logic.dart's existing predicates (invoiceIsOverdue,
// quoteIsExpiringSoon, *IsDraft) so the alert bell can never disagree with
// the Overdue/Needs Action quick-filter chips — one source of truth.
//
// PER-TYPE GATING (this pass): four optional bool params
// (overdueInvoicesEnabled / quotesExpiringEnabled / draftsEnabled /
// remindersEnabled), all defaulting to true so existing call sites keep
// working unchanged. When a flag is false, that category's alerts are
// never generated in the first place — not filtered out after the fact —
// so a disabled type can never leak into the bell badge count, the Alerts
// screen list, or its filter-chip count.

import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';
import '../filters/filter_logic.dart';
import '../widgets/saved_documents_containers.dart' show DocType;
import 'alert_types.dart';
import 'custom_reminders/reminder_model.dart';

List<AlertItem> buildAlerts({
  required List<SavedInvoice> invoices,
  required List<SavedQuote> quotes,
  required List<SavedReceipt> receipts,
  List<CustomReminder> dueReminders = const [],
  bool overdueInvoicesEnabled = true,
  bool quotesExpiringEnabled = true,
  bool draftsEnabled = true,
  bool remindersEnabled = true,
}) {
  final alerts = <AlertItem>[];

  if (overdueInvoicesEnabled) {
    for (final inv in invoices) {
      if (invoiceIsOverdue(inv)) {
        alerts.add(AlertItem(
          type: AlertType.overdueInvoice,
          priority: AlertPriority.high,
          title: inv.title,
          subtitle: 'Overdue — ${inv.templateName}',
          docType: DocType.invoice,
          invoice: inv,
        ));
      }
    }
  }

  if (quotesExpiringEnabled) {
    for (final q in quotes) {
      if (quoteIsExpiringSoon(q)) {
        alerts.add(AlertItem(
          type: AlertType.quoteExpiringSoon,
          priority: AlertPriority.high,
          title: q.title,
          subtitle: 'Expiring soon — ${q.templateName}',
          docType: DocType.quote,
          quote: q,
        ));
      }
    }
  }

  // Custom reminders whose time has already passed — high priority, since
  // the user set this deadline themselves. If the reminder is linked to a
  // real invoice/quote, resolve it here so the alert card can jump straight
  // to that document instead of just opening the Reminders list (the
  // reminder itself might have gone stale if the document was since
  // deleted, hence the null-safe lookup rather than firstWhere).
  if (remindersEnabled) {
    for (final r in dueReminders) {
      SavedInvoice? linkedInvoice;
      SavedQuote? linkedQuote;

      if (r.hasLinkedDocument) {
        if (r.linkedDocumentType == LinkedDocumentType.invoice) {
          final matches = invoices.where((i) => i.id == r.linkedDocumentId);
          linkedInvoice = matches.isEmpty ? null : matches.first;
        } else if (r.linkedDocumentType == LinkedDocumentType.quote) {
          final matches = quotes.where((q) => q.id == r.linkedDocumentId);
          linkedQuote = matches.isEmpty ? null : matches.first;
        }
      }

      alerts.add(AlertItem(
        type: AlertType.customReminder,
        priority: AlertPriority.high,
        title: r.title,
        subtitle: r.note.isEmpty ? 'Reminder' : r.note,
        reminder: r,
        invoice: linkedInvoice,
        quote: linkedQuote,
      ));
    }
  }

  // Drafts: lower priority "come finish this" nudges. No staleness cutoff
  // yet — this would need a real DateTime lastEditedAt field on the saved
  // document models rather than the formatted display string they expose
  // today. Add that field and this can gate on ">7 days since edit".
  if (draftsEnabled) {
    for (final inv in invoices.where(invoiceIsDraft)) {
      alerts.add(AlertItem(
        type: AlertType.draftInProgress,
        priority: AlertPriority.medium,
        title: inv.title,
        subtitle: '${inv.completionPercent}% complete — ${inv.templateName}',
        docType: DocType.invoice,
        invoice: inv,
      ));
    }
    for (final q in quotes.where(quoteIsDraft)) {
      alerts.add(AlertItem(
        type: AlertType.draftInProgress,
        priority: AlertPriority.medium,
        title: q.title,
        subtitle: '${q.completionPercent}% complete — ${q.templateName}',
        docType: DocType.quote,
        quote: q,
      ));
    }
    for (final r in receipts.where(receiptIsDraft)) {
      alerts.add(AlertItem(
        type: AlertType.draftInProgress,
        priority: AlertPriority.medium,
        title: r.title,
        subtitle: '${r.completionPercent}% complete — ${r.templateName}',
        docType: DocType.receipt,
        receipt: r,
      ));
    }
  }

  alerts.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  return alerts;
}
