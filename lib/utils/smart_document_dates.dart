// smart_document_dates.dart
// lib/utils/smart_document_dates.dart
//
// Produces a status-aware "smart" date string for saved invoices, quotes,
// and receipts — e.g. "Due in 4d" for an unpaid invoice, "Due 3d ago" for
// an overdue one, "Issued yesterday" for a receipt — instead of always
// showing a generic "last edited" time.
//
// ASSUMPTION #1: none of InvoiceData/QuoteData/ReceiptData currently store
// a dedicated "date the status changed" field (no paidDate, sentDate,
// acceptedDate, declinedDate, refundedDate). Where a status implies an
// event with no matching stored field, this falls back to the document's
// lastEditedAt as the best available proxy. If you want these exact
// instead of a proxy, add explicit fields (e.g. `paidDate`) set at the
// moment the status changes — say the word and I'll wire that up.
//
// ASSUMPTION #2: issueDate/dueDate/expiryDate/paymentDate are free-text
// Strings (per the models). This tries ISO 8601 first, then a list of
// common formats. If parsing fails, it silently falls back to
// lastEditedAt. If dates look wrong, send me one real dueDate string and
// I'll add the exact format to _kKnownDateFormats.

import 'package:intl/intl.dart';
import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';

const List<String> _kKnownDateFormats = [
  'd MMM yyyy',
  'dd MMM yyyy',
  'MMM d, yyyy',
  'dd/MM/yyyy',
  'MM/dd/yyyy',
  'yyyy-MM-dd',
];

DateTime? _parseFlexibleDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return iso;

  for (final pattern in _kKnownDateFormats) {
    try {
      return DateFormat(pattern).parseStrict(trimmed);
    } catch (_) {
      continue;
    }
  }
  return null;
}

int _daysBetween(DateTime from, DateTime to) {
  final fromDay = DateTime(from.year, from.month, from.day);
  final toDay = DateTime(to.year, to.month, to.day);
  return toDay.difference(fromDay).inDays;
}

String _relativePast(DateTime past) {
  final days = _daysBetween(past, DateTime.now());
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 7) return '${days}d ago';
  if (days < 30) return '${(days / 7).floor()}w ago';
  return '${(days / 30).floor()}mo ago';
}

String _relativeFuture(DateTime future) {
  final days = _daysBetween(DateTime.now(), future);
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days < 7) return 'in ${days}d';
  if (days < 30) return 'in ${(days / 7).floor()}w';
  return 'in ${(days / 30).floor()}mo';
}

/// Generic fallback matching the style of lastEditedDisplay(), used
/// whenever a status-relevant date can't be resolved at all.
String _lastEditedFallback(DateTime lastEditedAt) {
  final diff = DateTime.now().difference(lastEditedAt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

// ── Invoice ──────────────────────────────────────────────────────────────

String smartInvoiceDate(SavedInvoice inv) {
  final due = _parseFlexibleDate(inv.data.dueDate);

  switch (inv.data.paymentStatus) {
    case PaymentStatus.overdue:
      if (due != null) return 'Due ${_relativePast(due)}';
      return _lastEditedFallback(inv.lastEditedAt);

    case PaymentStatus.unpaid:
    case PaymentStatus.partial:
      if (due != null) {
        final days = _daysBetween(DateTime.now(), due);
        return days < 0 ? 'Due ${_relativePast(due)}' : 'Due ${_relativeFuture(due)}';
      }
      return _lastEditedFallback(inv.lastEditedAt);

    case PaymentStatus.paid:
      // No dedicated paidDate — lastEditedAt is the best proxy.
      return 'Paid ${_relativePast(inv.lastEditedAt)}';
  }
}

// ── Quote ────────────────────────────────────────────────────────────────

String smartQuoteDate(SavedQuote q) {
  final expiry = _parseFlexibleDate(q.data.expiryDate);

  switch (q.data.quoteStatus) {
    case QuoteStatus.draft:
      return 'Edited ${_relativePast(q.lastEditedAt)}';

    case QuoteStatus.sent:
      // No dedicated sentDate — show expiry countdown if known, else
      // fall back to lastEditedAt as a "sent" proxy.
      if (expiry != null) {
        final days = _daysBetween(DateTime.now(), expiry);
        return days < 0 ? 'Expired ${_relativePast(expiry)}' : 'Expires ${_relativeFuture(expiry)}';
      }
      return 'Sent ${_relativePast(q.lastEditedAt)}';

    case QuoteStatus.accepted:
      return 'Accepted ${_relativePast(q.lastEditedAt)}';

    case QuoteStatus.declined:
      return 'Declined ${_relativePast(q.lastEditedAt)}';

    case QuoteStatus.expired:
      if (expiry != null) return 'Expired ${_relativePast(expiry)}';
      return 'Expired ${_relativePast(q.lastEditedAt)}';
  }
}

// ── Receipt ──────────────────────────────────────────────────────────────

String smartReceiptDate(SavedReceipt r) {
  final paymentDate = _parseFlexibleDate(r.data.paymentDate);

  switch (r.data.status) {
    case ReceiptStatus.issued:
      if (paymentDate != null) return 'Issued ${_relativePast(paymentDate)}';
      return 'Issued ${_relativePast(r.lastEditedAt)}';

    case ReceiptStatus.refunded:
      // No dedicated refundedDate — lastEditedAt proxy.
      return 'Refunded ${_relativePast(r.lastEditedAt)}';
  }
}