// filter_logic.dart
// lib/filters/filter_logic.dart
//
// "Needs Action" / "Overdue" (+ aging buckets) / "Drafts" / "Paid" /
// "Accepted" / "Declined" logic, plus search, date-range, amount-range,
// folder, and sort helpers for the full filter bar.
//
// UPDATED (this pass): added quoteIsDeclined predicate and countDeclined
// counter, wired into the three applyQuickFilterToX() switches (kept
// exhaustive — every QuickFilter case is handled per type, returning
// const [] where a filter doesn't apply to that doc type).
//
// UPDATED (earlier pass): added invoiceIsPaid / quoteIsAccepted predicates
// and countPaid / countAccepted counters, wired into the three
// applyQuickFilterToX() switches (kept exhaustive — every QuickFilter case
// is handled per type, returning const [] where a filter doesn't apply to
// that doc type).

import '../models/expense_data.dart';
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

bool invoiceIsPaid(SavedInvoice inv) => inv.data.paymentStatus == PaymentStatus.paid;

bool quoteIsExpiringSoon(SavedQuote q) {
  if (q.data.quoteStatus != QuoteStatus.sent) return false;
  return isWithinDays(parseDocDate(q.data.expiryDate), kExpiringSoonWindowDays);
}

bool quoteIsAccepted(SavedQuote q) => q.data.quoteStatus == QuoteStatus.accepted;

bool quoteIsDeclined(SavedQuote q) => q.data.quoteStatus == QuoteStatus.declined;

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
    case QuickFilter.paid:
      return invoices.where(invoiceIsPaid).toList();
    case QuickFilter.accepted:
    case QuickFilter.declined:
      // "Accepted" / "Declined" are quote-only concepts.
      return const [];
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
    case QuickFilter.accepted:
      return quotes.where(quoteIsAccepted).toList();
    case QuickFilter.declined:
      return quotes.where(quoteIsDeclined).toList();
    case QuickFilter.overdue:
    case QuickFilter.overdue1to30:
    case QuickFilter.overdue31to60:
    case QuickFilter.overdue61plus:
    case QuickFilter.paid:
      // Overdue / aging buckets / Paid are money-owed concepts — invoices only.
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
    case QuickFilter.paid:
    case QuickFilter.accepted:
    case QuickFilter.declined:
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

int countPaid(List<SavedInvoice> invoices) =>
    invoices.where(invoiceIsPaid).length;

int countAccepted(List<SavedQuote> quotes) =>
    quotes.where(quoteIsAccepted).length;

int countDeclined(List<SavedQuote> quotes) =>
    quotes.where(quoteIsDeclined).length;

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

// Expenses have no client/document-number field — search matches vendor
// and notes instead.
List<ExpenseEntry> searchExpenses(List<ExpenseEntry> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items
      .where((e) =>
          e.vendor.toLowerCase().contains(q) ||
          e.notes.toLowerCase().contains(q))
      .toList();
}

// ── Date range ──────────────────────────────────────────────────────────

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

// Same lastEditedAt-based windowing as the three document types above,
// kept consistent so "Date & Sort" behaves identically no matter which
// type pill is selected.
List<ExpenseEntry> filterExpensesByDateRange(
  List<ExpenseEntry> items,
  DateRangePreset preset, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  if (preset == DateRangePreset.all) return items;
  return items
      .where((e) => isInDateRange(e.lastEditedAt, preset,
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

// Expenses have no min/max-relevant "amount" naming collision with the
// doc types (all four use plain double amount fields already), so this
// mirrors filterInvoicesByAmountRange/etc. exactly against
// ExpenseEntry.amount.
List<ExpenseEntry> filterExpensesByAmountRange(
    List<ExpenseEntry> items, double? min, double? max) {
  return items.where((e) {
    final amt = e.amount;
    if (min != null && amt < min) return false;
    if (max != null && amt > max) return false;
    return true;
  }).toList();
}

// ── Folders ─────────────────────────────────────────────────────────────

// `expenses` defaults to an empty list so existing call sites (e.g.
// folders_overview_screen.dart, if it doesn't pass expenses) keep
// compiling and behaving exactly as before this pass.
List<String> collectFolderNames({
  required List<SavedInvoice> invoices,
  required List<SavedQuote> quotes,
  required List<SavedReceipt> receipts,
  List<ExpenseEntry> expenses = const [],
}) {
  final names = <String>{};
  for (final i in invoices) {
    if (i.folderName != null && i.folderName!.isNotEmpty) names.add(i.folderName!);
  }
  for (final q in quotes) {
    if (q.folderName != null && q.folderName!.isNotEmpty) names.add(q.folderName!);
  }
  for (final r in receipts) {
    if (r.folderName != null && r.folderName!.isNotEmpty) names.add(r.folderName!);
  }
  for (final e in expenses) {
    if (e.folderName != null && e.folderName!.isNotEmpty) names.add(e.folderName!);
  }
  final list = names.toList();
  list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}

List<SavedInvoice> filterInvoicesByFolder(List<SavedInvoice> items, String? folder) {
  if (folder == null) return items;
  return items.where((i) => i.folderName == folder).toList();
}

List<SavedQuote> filterQuotesByFolder(List<SavedQuote> items, String? folder) {
  if (folder == null) return items;
  return items.where((q) => q.folderName == folder).toList();
}

List<SavedReceipt> filterReceiptsByFolder(List<SavedReceipt> items, String? folder) {
  if (folder == null) return items;
  return items.where((r) => r.folderName == folder).toList();
}

List<ExpenseEntry> filterExpensesByFolder(List<ExpenseEntry> items, String? folder) {
  if (folder == null) return items;
  return items.where((e) => e.folderName == folder).toList();
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

// Expenses have no `title` — vendor stands in for the alphabetical sort,
// and `amount` stands in for grandTotal/amountPaid.
List<ExpenseEntry> sortExpenses(List<ExpenseEntry> items, SortOption sort) {
  final sorted = List<ExpenseEntry>.from(items);
  switch (sort) {
    case SortOption.recentFirst:
      sorted.sort((a, b) => b.lastEditedAt.compareTo(a.lastEditedAt));
      break;
    case SortOption.oldestFirst:
      sorted.sort((a, b) => a.lastEditedAt.compareTo(b.lastEditedAt));
      break;
    case SortOption.alphabetical:
      sorted.sort((a, b) => a.vendor.toLowerCase().compareTo(b.vendor.toLowerCase()));
      break;
    case SortOption.amountHighLow:
      sorted.sort((a, b) => b.amount.compareTo(a.amount));
      break;
    case SortOption.amountLowHigh:
      sorted.sort((a, b) => a.amount.compareTo(b.amount));
      break;
  }
  return sorted;
}
