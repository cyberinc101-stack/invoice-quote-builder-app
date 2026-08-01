// filter_logic.dart
// lib/filters/filter_logic.dart
//
// "Needs Action" / "Overdue" (+ aging buckets) / "Drafts" logic, plus
// search, date-range, amount-range, and sort helpers for the full filter
// bar. Kept out of home_screen.dart so that file doesn't grow every time a
// new filter is added.

import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';
import 'filter_date_utils.dart';
import 'filter_types.dart';

// How many days ahead of expiry a sent quote counts as "expiring soon".
const int kExpiringSoonWindowDays = 3;

// ── Predicates ────────────────────────────────────────────────────────────

bool invoiceIsOverdue(SavedInvoice inv) {
  if (inv.data.paymentStatus == PaymentStatus.paid) return false;
  if (inv.data.paymentStatus == PaymentStatus.overdue) return true;
  return isPastDate(parseDocDate(inv.data.dueDate));
}

bool quoteIsExpiringSoon(SavedQuote q) {
  if (q.data.quoteStatus != QuoteStatus.sent) return false;
  return isWithinDays(parseDocDate(q.data.expiryDate), kExpiringSoonWindowDays);
}

bool invoiceIsDraft(SavedInvoice inv) => inv.completionPercent < 100;
bool quoteIsDraft(SavedQuote q) => q.completionPercent < 100;
bool receiptIsDraft(SavedReceipt r) => r.completionPercent < 100;

// How many days overdue an invoice is. Null if it isn't overdue or has no
// parseable due date (fails safe into "not in any bucket" rather than
// guessing).
int? _daysOverdue(SavedInvoice inv) {
  if (!invoiceIsOverdue(inv)) return null;
  final due = parseDocDate(inv.data.dueDate);
  if (due == null) return null;
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dueOnly = DateTime(due.year, due.month, due.day);
  return todayOnly.difference(dueOnly).inDays;
}

bool invoiceInAgingBucket(SavedInvoice inv, QuickFilter bucket) {
  final days = _daysOverdue(inv);
  if (days == null) return false;
  switch (bucket) {
    case QuickFilter.overdue1to30:
      return days >= 1 && days <= 30;
    case QuickFilter.overdue31to60:
      return days >= 31 && days <= 60;
    case QuickFilter.overdue61plus:
      return days >= 61;
    default:
      return false;
  }
}

// ── Apply a quick filter to an already type/status-filtered list ──────────

List<SavedInvoice> applyQuickFilterToInvoices(
  List<SavedInvoice> invoices,
  QuickFilter filter,
) {
  switch (filter) {
    case QuickFilter.none:
      return invoices;
    case QuickFilter.drafts:
      return invoices.where(invoiceIsDraft).toList();
    case QuickFilter.overdue:
      return invoices.where(invoiceIsOverdue).toList();
    case QuickFilter.needsAction:
      return invoices.where(invoiceIsOverdue).toList();
    case QuickFilter.overdue1to30:
    case QuickFilter.overdue31to60:
    case QuickFilter.overdue61plus:
      return invoices.where((inv) => invoiceInAgingBucket(inv, filter)).toList();
  }
}

List<SavedQuote> applyQuickFilterToQuotes(
  List<SavedQuote> quotes,
  QuickFilter filter,
) {
  switch (filter) {
    case QuickFilter.none:
      return quotes;
    case QuickFilter.drafts:
      return quotes.where(quoteIsDraft).toList();
    case QuickFilter.needsAction:
      return quotes.where(quoteIsExpiringSoon).toList();
    case QuickFilter.overdue:
    case QuickFilter.overdue1to30:
    case QuickFilter.overdue31to60:
    case QuickFilter.overdue61plus:
      // Overdue / aging buckets are a money-owed concept — invoices only.
      return const [];
  }
}

List<SavedReceipt> applyQuickFilterToReceipts(
  List<SavedReceipt> receipts,
  QuickFilter filter,
) {
  switch (filter) {
    case QuickFilter.none:
      return receipts;
    case QuickFilter.drafts:
      return receipts.where(receiptIsDraft).toList();
    case QuickFilter.needsAction:
    case QuickFilter.overdue:
    case QuickFilter.overdue1to30:
    case QuickFilter.overdue31to60:
    case QuickFilter.overdue61plus:
      // Receipts are already-settled records — none of these apply.
      return const [];
  }
}

// ── Badge counts (computed from the full, unfiltered lists) ───────────────

int countNeedsAction({
  required List<SavedInvoice> invoices,
  required List<SavedQuote> quotes,
}) {
  return invoices.where(invoiceIsOverdue).length +
      quotes.where(quoteIsExpiringSoon).length;
}

int countOverdue(List<SavedInvoice> invoices) =>
    invoices.where(invoiceIsOverdue).length;

int countAgingBucket(List<SavedInvoice> invoices, QuickFilter bucket) =>
    invoices.where((inv) => invoiceInAgingBucket(inv, bucket)).length;

int countDrafts({
  required List<SavedInvoice> invoices,
  required List<SavedQuote> quotes,
  required List<SavedReceipt> receipts,
}) {
  return invoices.where(invoiceIsDraft).length +
      quotes.where(quoteIsDraft).length +
      receipts.where(receiptIsDraft).length;
}

// ── Search ──────────────────────────────────────────────────────────────
//
// Matches against title + client name + the doc's own number field.
// Case-insensitive, substring match.

List<SavedInvoice> searchInvoices(List<SavedInvoice> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items
      .where((i) =>
          i.title.toLowerCase().contains(q) ||
          i.data.clientName.toLowerCase().contains(q) ||
          i.data.invoiceNumber.toLowerCase().contains(q))
      .toList();
}

List<SavedQuote> searchQuotes(List<SavedQuote> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items
      .where((i) =>
          i.title.toLowerCase().contains(q) ||
          i.data.clientName.toLowerCase().contains(q) ||
          i.data.quoteNumber.toLowerCase().contains(q))
      .toList();
}

List<SavedReceipt> searchReceipts(List<SavedReceipt> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items
      .where((i) =>
          i.title.toLowerCase().contains(q) ||
          i.data.clientName.toLowerCase().contains(q) ||
          i.data.receiptNumber.toLowerCase().contains(q))
      .toList();
}

// ── Date range ──────────────────────────────────────────────────────────
//
// ASSUMPTION: keys off lastEditedAt (a real DateTime on every saved doc)
// rather than dueDate/issueDate/expiryDate/paymentDate, which are free-text
// Strings of inconsistent format.

List<SavedInvoice> filterInvoicesByDateRange(
  List<SavedInvoice> items,
  DateRangePreset preset, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  if (preset == DateRangePreset.all) return items;
  return items
      .where((i) => isInDateRange(i.lastEditedAt, preset,
          customStart: customStart, customEnd: customEnd))
      .toList();
}

List<SavedQuote> filterQuotesByDateRange(
  List<SavedQuote> items,
  DateRangePreset preset, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  if (preset == DateRangePreset.all) return items;
  return items
      .where((i) => isInDateRange(i.lastEditedAt, preset,
          customStart: customStart, customEnd: customEnd))
      .toList();
}

List<SavedReceipt> filterReceiptsByDateRange(
  List<SavedReceipt> items,
  DateRangePreset preset, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  if (preset == DateRangePreset.all) return items;
  return items
      .where((i) => isInDateRange(i.lastEditedAt, preset,
          customStart: customStart, customEnd: customEnd))
      .toList();
}

// ── Amount range ────────────────────────────────────────────────────────

List<SavedInvoice> filterInvoicesByAmountRange(
    List<SavedInvoice> items, double? min, double? max) {
  return items.where((i) {
    final amt = i.data.grandTotal;
    if (min != null && amt < min) return false;
    if (max != null && amt > max) return false;
    return true;
  }).toList();
}

List<SavedQuote> filterQuotesByAmountRange(
    List<SavedQuote> items, double? min, double? max) {
  return items.where((i) {
    final amt = i.data.grandTotal;
    if (min != null && amt < min) return false;
    if (max != null && amt > max) return false;
    return true;
  }).toList();
}

List<SavedReceipt> filterReceiptsByAmountRange(
    List<SavedReceipt> items, double? min, double? max) {
  return items.where((i) {
    final amt = i.data.amountPaid;
    if (min != null && amt < min) return false;
    if (max != null && amt > max) return false;
    return true;
  }).toList();
}

// ── Sort ────────────────────────────────────────────────────────────────

List<SavedInvoice> sortInvoices(List<SavedInvoice> items, SortOption sort) {
  final sorted = List<SavedInvoice>.from(items);
  switch (sort) {
    case SortOption.recentFirst:
      sorted.sort((a, b) => b.lastEditedAt.compareTo(a.lastEditedAt));
      break;
    case SortOption.oldestFirst:
      sorted.sort((a, b) => a.lastEditedAt.compareTo(b.lastEditedAt));
      break;
    case SortOption.alphabetical:
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case SortOption.amountHighLow:
      sorted.sort((a, b) => b.data.grandTotal.compareTo(a.data.grandTotal));
      break;
    case SortOption.amountLowHigh:
      sorted.sort((a, b) => a.data.grandTotal.compareTo(b.data.grandTotal));
      break;
  }
  return sorted;
}

List<SavedQuote> sortQuotes(List<SavedQuote> items, SortOption sort) {
  final sorted = List<SavedQuote>.from(items);
  switch (sort) {
    case SortOption.recentFirst:
      sorted.sort((a, b) => b.lastEditedAt.compareTo(a.lastEditedAt));
      break;
    case SortOption.oldestFirst:
      sorted.sort((a, b) => a.lastEditedAt.compareTo(b.lastEditedAt));
      break;
    case SortOption.alphabetical:
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case SortOption.amountHighLow:
      sorted.sort((a, b) => b.data.grandTotal.compareTo(a.data.grandTotal));
      break;
    case SortOption.amountLowHigh:
      sorted.sort((a, b) => a.data.grandTotal.compareTo(b.data.grandTotal));
      break;
  }
  return sorted;
}

List<SavedReceipt> sortReceipts(List<SavedReceipt> items, SortOption sort) {
  final sorted = List<SavedReceipt>.from(items);
  switch (sort) {
    case SortOption.recentFirst:
      sorted.sort((a, b) => b.lastEditedAt.compareTo(a.lastEditedAt));
      break;
    case SortOption.oldestFirst:
      sorted.sort((a, b) => a.lastEditedAt.compareTo(b.lastEditedAt));
      break;
    case SortOption.alphabetical:
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case SortOption.amountHighLow:
      sorted.sort((a, b) => b.data.amountPaid.compareTo(a.data.amountPaid));
      break;
    case SortOption.amountLowHigh:
      sorted.sort((a, b) => a.data.amountPaid.compareTo(b.data.amountPaid));
      break;
  }
  return sorted;
}