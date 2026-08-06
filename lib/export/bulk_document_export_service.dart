// lib/export/bulk_document_export_service.dart
//
// Combines a mixed selection of invoices, quotes, and receipts into ONE
// named CSV file — used by the "Export" action added to the selection bar
// in saved_documents_section.dart.
//
// Mirrors invoice_export_service.dart's conventions exactly:
//  - exportToDownloads() writes to the same Downloads directory helper
//    (Android: /storage/emulated/0/Download, else: app documents dir)
//  - share() writes to getTemporaryDirectory() and calls
//    Share.shareXFiles(...)
//  - Same minimal CSV field-escaping helper (quote-wrap + double internal
//    quotes whenever a value contains a comma, quote, or newline)
//
// Column layout — one shared row shape so all three document types can
// live in a single sheet:
//   Type | Document Number | Client Name | Client Email | Issue Date |
//   Due / Expiry / Payment Date | Payment Method | Currency | Subtotal |
//   Tax | Discount | Total | Status
//
// Field mapping per type (nothing here is guessed beyond what's already
// defined on InvoiceData / QuoteData / ReceiptData):
//   Invoice  -> invoiceNumber, issueDate, dueDate,    paymentStatus.name
//   Quote    -> quoteNumber,   issueDate, expiryDate, quoteStatus.name
//   Receipt  -> receiptNumber, paymentDate (as Issue Date), '' (no second
//               date), paymentMethod.name, status.name
//
// Rows are emitted in a stable order — invoices first, then quotes, then
// receipts — same grouping the saved-documents list already uses.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  }) async {
    final csv = _buildCsvString(
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
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
  }) async {
    final csv = _buildCsvString(
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
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