// lib/export/bulk_document_export_service.dart
//
// Combines a mixed selection of invoices, quotes, receipts — and now,
// this pass, EXPENSES — into ONE named CSV file.
//
// EXPENSES PASS (this update): expenses were previously entirely absent
// from every combined/folder export — FolderDownloadService's own header
// comment flagged this explicitly as a known gap. Expenses are not real
// billable documents (no PDF, no client-facing template) — they exist
// purely so the accounting/export numbers are accurate when a user
// uploads a folder's documents into Excel or accounting software like
// Xero. So they're folded into this same combined CSV as plain data rows,
// never as a document type with its own PDF path.
//
// Two schema additions to support this, both backward compatible with
// every existing row:
//   - A trailing 'Category' column, empty for Invoice/Quote/Receipt rows,
//     populated with the expense's category name for Expense rows.
//   - Expense rows use the existing 'Total' column, but as a NEGATIVE
//     number (money OUT), while invoice/quote/receipt rows keep their
//     existing positive Total (money IN). This is the actual point of
//     including expenses at all — a plain SUM() over the Total column in
//     Excel/Xero now nets out to real profit/loss, instead of only ever
//     summing income. Client Name holds the expense's vendor (the
//     counterpart party, same role Client Name plays for the other three
//     types); Document Number holds the expense's reference number, if
//     any.
//
// expenses/categoryNameOf are optional (default: no expenses, identity
// lookup) so every existing call site that doesn't pass them compiles and
// behaves exactly as before this pass.
//
// Mirrors invoice_export_service.dart's conventions exactly:
//  - exportToDownloads() writes to the same Downloads directory helper
//    (Android: /storage/emulated/0/Download, else: app documents dir)
//  - share() writes to getTemporaryDirectory() and calls
//    Share.shareXFiles(...)
//  - Same minimal CSV field-escaping helper (quote-wrap + double internal
//    quotes whenever a value contains a comma, quote, or newline)
//
// Column layout — one shared row shape so all four types can live in a
// single sheet:
//   Type | Document Number | Client Name | Client Email | Issue Date |
//   Due / Expiry / Payment Date | Payment Method | Currency | Subtotal |
//   Tax | Discount | Total | Status | Category
//
// Field mapping per type (nothing here is guessed beyond what's already
// defined on InvoiceData / QuoteData / ReceiptData / ExpenseEntry):
//   Invoice  -> invoiceNumber, issueDate, dueDate,    paymentStatus.name
//   Quote    -> quoteNumber,   issueDate, expiryDate, quoteStatus.name
//   Receipt  -> receiptNumber, paymentDate (as Issue Date), '' (no second
//               date), paymentMethod.name, status.name
//   Expense  -> referenceNumber (Document Number), vendor (Client Name),
//               date (as Issue Date), '' (no second date), amount (as
//               Subtotal AND as -amount in Total), category name
//               (Category column)
//
// Rows are emitted in a stable order — invoices, then quotes, then
// receipts, then expenses — same grouping the saved-documents list
// already uses, with expenses last since they're the newest addition and
// structurally different (money out, not a sent/received document).

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense_data.dart';
import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';

class BulkDocumentExportService {
  // ── Public API ─────────────────────────────────────────────────────────

  /// Writes the combined CSV to Downloads and returns the file path.
  Future<String> exportToDownloads({
    required String fileName,
    required List<SavedInvoice> invoices,
    required List<SavedQuote> quotes,
    required List<SavedReceipt> receipts,
    List<ExpenseEntry> expenses = const [],
    String Function(String categoryId)? categoryNameOf,
  }) async {
    final csv = _buildCsvString(
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
      expenses: expenses,
      categoryNameOf: categoryNameOf ?? (id) => id,
    );
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_sanitize(fileName)}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Writes the combined CSV to a temp dir and opens the share sheet.
  Future<void> share({
    required String fileName,
    required List<SavedInvoice> invoices,
    required List<SavedQuote> quotes,
    required List<SavedReceipt> receipts,
    List<ExpenseEntry> expenses = const [],
    String Function(String categoryId)? categoryNameOf,
  }) async {
    final csv = _buildCsvString(
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
      expenses: expenses,
      categoryNameOf: categoryNameOf ?? (id) => id,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_sanitize(fileName)}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: fileName,
    );
  }

  // ── CSV builder ────────────────────────────────────────────────────────

  String _buildCsvString({
    required List<SavedInvoice> invoices,
    required List<SavedQuote> quotes,
    required List<SavedReceipt> receipts,
    required List<ExpenseEntry> expenses,
    required String Function(String categoryId) categoryNameOf,
  }) {
    final buf = StringBuffer();

    buf.writeln([
      'Type',
      'Document Number',
      'Client Name',
      'Client Email',
      'Issue Date',
      'Due / Expiry Date',
      'Payment Method',
      'Currency',
      'Subtotal',
      'Tax',
      'Discount',
      'Total',
      'Status',
      'Category',
    ].join(','));

    for (final inv in invoices) {
      final d = inv.data;
      buf.writeln([
        _csv('Invoice'),
        _csv(d.invoiceNumber),
        _csv(d.clientName),
        _csv(d.clientEmail),
        _csv(d.issueDate),
        _csv(d.dueDate),
        _csv(''),
        _csv(d.currency),
        d.subtotal,
        d.taxAmount,
        d.discountAmount,
        d.grandTotal,
        _csv(d.paymentStatus.name),
        _csv(''),
      ].join(','));
    }

    for (final q in quotes) {
      final d = q.data;
      buf.writeln([
        _csv('Quote'),
        _csv(d.quoteNumber),
        _csv(d.clientName),
        _csv(d.clientEmail),
        _csv(d.issueDate),
        _csv(d.expiryDate),
        _csv(''),
        _csv(d.currency),
        d.subtotal,
        d.taxAmount,
        d.discountAmount,
        d.grandTotal,
        _csv(d.quoteStatus.name),
        _csv(''),
      ].join(','));
    }

    for (final r in receipts) {
      final d = r.data;
      buf.writeln([
        _csv('Receipt'),
        _csv(d.receiptNumber),
        _csv(d.clientName),
        _csv(d.clientEmail),
        _csv(d.paymentDate),
        _csv(''),
        _csv(d.paymentMethod.name),
        _csv(d.currency),
        d.subtotal,
        d.taxAmount,
        d.discountAmount,
        d.amountPaid,
        _csv(d.status.name),
        _csv(''),
      ].join(','));
    }

    // Expense rows -- money OUT, so Total is negative. This is the whole
    // point of including expenses here: a plain SUM() over the Total
    // column in Excel/Xero now nets income against expenses instead of
    // only ever summing income.
    for (final e in expenses) {
      buf.writeln([
        _csv('Expense'),
        _csv(e.referenceNumber ?? ''),
        _csv(e.vendor.isEmpty ? '(No vendor)' : e.vendor),
        _csv(''),
        _csv(_formatDate(e.date)),
        _csv(''),
        _csv(''),
        _csv(e.currency),
        e.amount,
        0,
        0,
        -e.amount,
        _csv(''),
        _csv(categoryNameOf(e.categoryId)),
      ].join(','));
    }

    return buf.toString();
  }

  /// Minimal CSV field escaping: wraps in quotes and doubles internal quotes
  /// whenever the value contains a comma, quote, or newline.
  static String _csv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  static String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Shared helpers ─────────────────────────────────────────────────────

  /// Strips characters that are unsafe in filenames but keeps the name the
  /// user typed otherwise recognisable (spaces are fine on both platforms).
  static String _sanitize(String name) {
    final trimmed = name.trim();
    final safe = trimmed.isEmpty ? 'Documents_Export' : trimmed;
    return safe.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Future<Directory> _downloadsDir() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    final docs = await getApplicationDocumentsDirectory();
    return docs;
  }
}
