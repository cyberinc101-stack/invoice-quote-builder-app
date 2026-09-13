// lib/export/bulk_document_export_service.dart
//
// PARITY FIX (this update): the combined sheet's Total column was
// already correct for every row type (it reads grandTotal/amountPaid
// directly, which already fold in each document's per-item discount/tax
// at the model level), but the Tax/Discount columns only ever showed
// the whole-document rate contribution — so Subtotal + Tax - Discount
// never actually summed to Total for an invoice/quote/receipt that used
// any line item's own discount/tax rate. Added two columns —
// 'Item Tax Extra' and 'Item Discount Extra' — sourced from
// InvoiceData/QuoteData/ReceiptData's own itemTaxExtra/itemDiscountExtra
// getters (all three models carry these; see each export service's own
// identical PARITY FIX pass for the single-document sheets). Expense
// rows fill both with 0, since an expense has no line items or per-item
// rates at all. Not grouped by name here (unlike the single-document
// sheets) — a combined summary row per document doesn't fit a per-name
// breakdown into a fixed column layout the same way.
//
// EXPENSES PASS (earlier): expenses were previously entirely absent
// from every combined/folder export. Expenses are not real billable
// documents (no PDF, no client-facing template) — they exist purely so
// the accounting/export numbers are accurate when a user uploads a
// folder's documents into Excel or accounting software like Xero. So
// they're folded into this same combined CSV as plain data rows, never
// as a document type with its own PDF path.
//
// Two schema additions to support this, both backward compatible with
// every existing row:
//   - A trailing 'Category' column, empty for Invoice/Quote/Receipt rows,
//     populated with the expense's category name for Expense rows.
//   - Expense rows use the existing 'Total' column, but as a NEGATIVE
//     number (money OUT), while invoice/quote/receipt rows keep their
//     existing positive Total (money IN).
//
// expenses/categoryNameOf are optional (default: no expenses, identity
// lookup) so every existing call site that doesn't pass them compiles and
// behaves exactly as before this pass.
//
// Mirrors invoice_export_service.dart's conventions exactly.
//
// Column layout — one shared row shape so all four types can live in a
// single sheet:
//   Type | Document Number | Client Name | Client Email | Issue Date |
//   Due / Expiry / Payment Date | Payment Method | Currency | Subtotal |
//   Tax | Discount | Item Tax Extra | Item Discount Extra | Total |
//   Status | Category

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense_data.dart';
import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';

class BulkDocumentExportService {
  // ── Public API ─────────────────────────────────────────────────────────

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

    // PARITY FIX: added 'Item Tax Extra'/'Item Discount Extra' columns
    // between Discount and Total.
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
      'Item Tax Extra',
      'Item Discount Extra',
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
        d.itemTaxExtra,
        d.itemDiscountExtra,
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
        d.itemTaxExtra,
        d.itemDiscountExtra,
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
        d.itemTaxExtra,
        d.itemDiscountExtra,
        d.amountPaid,
        _csv(d.status.name),
        _csv(''),
      ].join(','));
    }

    // Expense rows -- money OUT, so Total is negative. No line items, so
    // Item Tax Extra/Item Discount Extra are always 0 for these rows.
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
        0,
        0,
        -e.amount,
        _csv(''),
        _csv(categoryNameOf(e.categoryId)),
      ].join(','));
    }

    return buf.toString();
  }

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