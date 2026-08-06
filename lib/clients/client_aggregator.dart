// client_aggregator.dart
// lib/clients/client_aggregator.dart
//
// Aggregates saved invoices/quotes/receipts into a per-client summary for
// the Client Dashboard. Clients aren't a separate stored entity in this
// app -- clientName/clientEmail live directly on each document -- so
// grouping is done by clientName, trimmed and lowercased for matching (so
// "John Smith" and "john smith" are treated as the same client). If you'd
// rather match strictly on clientEmail instead, say so -- that's stricter
// but breaks for clients who never had an email on file.
//
// ASSUMPTION: there's no "paid on" date anywhere in InvoiceData -- only a
// paymentStatus enum and free-text issueDate/dueDate strings. Average
// days-to-pay is approximated as (lastEditedAt - createdAt) for invoices
// currently marked paid, on the assumption that marking an invoice paid is
// what most recently touched it.

import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';

class ClientSummary {
  final String clientName;
  final String clientEmail;

  final int invoiceCount;
  final double totalBilled;
  final double totalOutstanding;
  final double totalPaid;

  final int quoteCount;
  final double totalQuoted;
  final double acceptedQuoteValue;

  final int receiptCount;
  final double totalReceiptsPaid;

  final double? avgDaysToPay;
  final DateTime lastActivity;

  const ClientSummary({
    required this.clientName,
    required this.clientEmail,
    required this.invoiceCount,
    required this.totalBilled,
    required this.totalOutstanding,
    required this.totalPaid,
    required this.quoteCount,
    required this.totalQuoted,
    required this.acceptedQuoteValue,
    required this.receiptCount,
    required this.totalReceiptsPaid,
    required this.avgDaysToPay,
    required this.lastActivity,
  });

  int get totalDocuments => invoiceCount + quoteCount + receiptCount;
}

List<ClientSummary> buildClientSummaries({
  required List<SavedInvoice> invoices,
  required List<SavedQuote> quotes,
  required List<SavedReceipt> receipts,
}) {
  final Map<String, _MutableClientData> byKey = {};

  String keyOf(String name) => name.trim().toLowerCase();

  _MutableClientData bucketFor(String rawName) {
    final key = keyOf(rawName);
    return byKey.putIfAbsent(
      key,
      () => _MutableClientData(displayName: rawName.trim()),
    );
  }

  for (final inv in invoices) {
    final name = inv.data.clientName.trim();
    if (name.isEmpty) continue;
    final bucket = bucketFor(name);
    bucket.invoiceCount++;
    bucket.totalBilled += inv.data.grandTotal;
    if (inv.data.paymentStatus == PaymentStatus.paid) {
      bucket.totalPaid += inv.data.grandTotal;
      bucket.paidDaysToPay.add(inv.lastEditedAt.difference(inv.createdAt).inDays);
    } else {
      bucket.totalOutstanding += inv.data.grandTotal;
    }
    bucket.bumpActivity(inv.lastEditedAt);
    if (bucket.email.isEmpty && inv.data.clientEmail.isNotEmpty) {
      bucket.email = inv.data.clientEmail;
    }
  }

  for (final q in quotes) {
    final name = q.data.clientName.trim();
    if (name.isEmpty) continue;
    final bucket = bucketFor(name);
    bucket.quoteCount++;
    bucket.totalQuoted += q.data.grandTotal;
    if (q.data.quoteStatus == QuoteStatus.accepted) {
      bucket.acceptedQuoteValue += q.data.grandTotal;
    }
    bucket.bumpActivity(q.lastEditedAt);
    if (bucket.email.isEmpty && q.data.clientEmail.isNotEmpty) {
      bucket.email = q.data.clientEmail;
    }
  }

  for (final r in receipts) {
    final name = r.data.clientName.trim();
    if (name.isEmpty) continue;
    final bucket = bucketFor(name);
    bucket.receiptCount++;
    bucket.totalReceiptsPaid += r.data.amountPaid;
    bucket.bumpActivity(r.lastEditedAt);
    if (bucket.email.isEmpty && r.data.clientEmail.isNotEmpty) {
      bucket.email = r.data.clientEmail;
    }
  }

  return byKey.values.map((b) {
    final avgDays = b.paidDaysToPay.isEmpty
        ? null
        : b.paidDaysToPay.reduce((a, c) => a + c) / b.paidDaysToPay.length;
    return ClientSummary(
      clientName: b.displayName,
      clientEmail: b.email,
      invoiceCount: b.invoiceCount,
      totalBilled: b.totalBilled,
      totalOutstanding: b.totalOutstanding,
      totalPaid: b.totalPaid,
      quoteCount: b.quoteCount,
      totalQuoted: b.totalQuoted,
      acceptedQuoteValue: b.acceptedQuoteValue,
      receiptCount: b.receiptCount,
      totalReceiptsPaid: b.totalReceiptsPaid,
      avgDaysToPay: avgDays,
      lastActivity: b.lastActivity,
    );
  }).toList();
}

class _MutableClientData {
  String displayName;
  String email = '';
  int invoiceCount = 0;
  double totalBilled = 0;
  double totalOutstanding = 0;
  double totalPaid = 0;
  int quoteCount = 0;
  double totalQuoted = 0;
  double acceptedQuoteValue = 0;
  int receiptCount = 0;
  double totalReceiptsPaid = 0;
  List<int> paidDaysToPay = [];
  DateTime lastActivity = DateTime.fromMillisecondsSinceEpoch(0);

  _MutableClientData({required this.displayName});

  void bumpActivity(DateTime t) {
    if (t.isAfter(lastActivity)) lastActivity = t;
  }
}
