// lib/export/invoice_export_service.dart
//
// Generates and exports invoices as XLSX and CSV — single-document and bulk.
//
// Built to match invoice_pdf_service.dart's existing conventions exactly:
//  - "download" methods write to the same Downloads directory helper
//    (Android: /storage/emulated/0/Download, else: app documents dir)
//  - "share" methods write to getTemporaryDirectory() and call
//    Share.shareXFiles(...), same as generateAndSharePDF()
//  - Filenames follow the same Invoice_<number-with-non-word-chars-stripped>
//    pattern used for PDFs.
//
// Field usage (description, quantity, unitPrice, total on line items;
// businessName/Email/Phone/Address, clientName/Email/Phone/Address,
// invoiceNumber, issueDate, dueDate, currency, subtotal, taxRate, taxAmount,
// discountRate, discountAmount, grandTotal, notes on InvoiceData) is taken
// directly from what invoice_pdf_service.dart reads off SavedInvoice.data —
// nothing here is guessed beyond that.
//
// NEW DEPENDENCY: this file needs the `excel` package for XLSX generation.
// Add one line to pubspec.yaml under dependencies:
//   excel: ^4.0.6
// CSV needs no package — it's built with plain string joining below.
// I haven't seen the invoice/quote app's actual pubspec.yaml, so if `excel`
// is already pinned there at a different version, just keep the existing
// pin; nothing in this file depends on a specific excel version beyond the
// basic Workbook/Sheet API used below.

import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/invoice_data.dart';

class InvoiceExportService {
  // ── Public API: single document ─────────────────────────────────────────

  /// Writes a single invoice as an .xlsx file to Downloads and returns the path.
  Future<String> exportSingleXlsxToDownloads(SavedInvoice invoice) async {
    final bytes = _buildSingleXlsxBytes(invoice);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_baseFileName(invoice)}.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Writes a single invoice as an .xlsx file to a temp dir and shares it.
  Future<void> shareSingleXlsx(SavedInvoice invoice) async {
    final bytes = _buildSingleXlsxBytes(invoice);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_baseFileName(invoice)}.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Invoice ${invoice.data.invoiceNumber}',
    );
  }

  /// Writes a single invoice as a .csv file to Downloads and returns the path.
  Future<String> exportSingleCsvToDownloads(SavedInvoice invoice) async {
    final csv = _buildSingleCsvString(invoice);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_baseFileName(invoice)}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Writes a single invoice as a .csv file to a temp dir and shares it.
  Future<void> shareSingleCsv(SavedInvoice invoice) async {
    final csv = _buildSingleCsvString(invoice);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_baseFileName(invoice)}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Invoice ${invoice.data.invoiceNumber}',
    );
  }

  // ── Public API: bulk export ─────────────────────────────────────────────

  /// Writes one row per invoice (summary totals, no line-item breakdown)
  /// as an .xlsx file to Downloads and returns the path.
  Future<String> exportBulkXlsxToDownloads(List<SavedInvoice> invoices) async {
    final bytes = _buildBulkXlsxBytes(invoices);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/Invoices_Export_${_timestamp()}.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> shareBulkXlsx(List<SavedInvoice> invoices) async {
    final bytes = _buildBulkXlsxBytes(invoices);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Invoices_Export_${_timestamp()}.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Invoices Export',
    );
  }

  Future<String> exportBulkCsvToDownloads(List<SavedInvoice> invoices) async {
    final csv = _buildBulkCsvString(invoices);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/Invoices_Export_${_timestamp()}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  Future<void> shareBulkCsv(List<SavedInvoice> invoices) async {
    final csv = _buildBulkCsvString(invoices);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Invoices_Export_${_timestamp()}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Invoices Export',
    );
  }

  // ── XLSX builders ────────────────────────────────────────────────────────

  List<int> _buildSingleXlsxBytes(SavedInvoice invoice) {
    final d = invoice.data;
    final workbook = xls.Excel.createExcel();
    final sheetName = 'Invoice';
    final sheet = workbook[sheetName];
    // The excel package creates a default 'Sheet1' — remove it once our
    // named sheet exists so the file doesn't ship an empty extra tab.
    if (workbook.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      workbook.delete('Sheet1');
    }

    int r = 0;
    void header(String label, String value) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
          .value = xls.TextCellValue(label);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
          .value = xls.TextCellValue(value);
      r++;
    }

    header('Invoice Number', d.invoiceNumber);
    header('Issue Date', d.issueDate);
    header('Due Date', d.dueDate);
    header('Business Name', d.businessName);
    header('Business Email', d.businessEmail);
    header('Business Phone', d.businessPhone);
    header('Business Address', d.businessAddress);
    header('Client Name', d.clientName);
    header('Client Email', d.clientEmail);
    header('Client Phone', d.clientPhone);
    header('Client Address', d.clientAddress);
    header('Currency', d.currency);
    r++; // blank row

    // Line items table
    const cols = ['Description', 'Quantity', 'Unit Price', 'Total'];
    for (int c = 0; c < cols.length; c++) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
          .value = xls.TextCellValue(cols[c]);
    }
    r++;
    for (final item in d.lineItems) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
          .value = xls.TextCellValue(item.description);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
          .value = xls.DoubleCellValue(item.quantity);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r))
          .value = xls.DoubleCellValue(item.unitPrice);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r))
          .value = xls.DoubleCellValue(item.total);
      r++;
    }
    r++; // blank row

    void totalRow(String label, double value) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r))
          .value = xls.TextCellValue(label);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r))
          .value = xls.DoubleCellValue(value);
      r++;
    }

    totalRow('Subtotal', d.subtotal);
    if (d.taxRate > 0) totalRow('Tax (${d.taxRate}%)', d.taxAmount);
    if (d.discountRate > 0) {
      totalRow('Discount (${d.discountRate}%)', -d.discountAmount);
    }
    totalRow('TOTAL', d.grandTotal);

    if (d.notes.isNotEmpty) {
      r++;
      header('Notes', d.notes);
    }

    final saved = workbook.save();
    if (saved == null) {
      throw Exception('Failed to generate XLSX bytes for invoice export');
    }
    return saved;
  }

  List<int> _buildBulkXlsxBytes(List<SavedInvoice> invoices) {
    final workbook = xls.Excel.createExcel();
    const sheetName = 'Invoices';
    final sheet = workbook[sheetName];
    if (workbook.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      workbook.delete('Sheet1');
    }

    const cols = [
      'Invoice Number',
      'Issue Date',
      'Due Date',
      'Client Name',
      'Client Email',
      'Currency',
      'Subtotal',
      'Tax',
      'Discount',
      'Total',
    ];
    for (int c = 0; c < cols.length; c++) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = xls.TextCellValue(cols[c]);
    }

    for (int i = 0; i < invoices.length; i++) {
      final d = invoices[i].data;
      final r = i + 1;
      final values = <xls.CellValue>[
        xls.TextCellValue(d.invoiceNumber),
        xls.TextCellValue(d.issueDate),
        xls.TextCellValue(d.dueDate),
        xls.TextCellValue(d.clientName),
        xls.TextCellValue(d.clientEmail),
        xls.TextCellValue(d.currency),
        xls.DoubleCellValue(d.subtotal),
        xls.DoubleCellValue(d.taxAmount),
        xls.DoubleCellValue(d.discountAmount),
        xls.DoubleCellValue(d.grandTotal),
      ];
      for (int c = 0; c < values.length; c++) {
        sheet
            .cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .value = values[c];
      }
    }

    final saved = workbook.save();
    if (saved == null) {
      throw Exception('Failed to generate bulk XLSX bytes for invoice export');
    }
    return saved;
  }

  // ── CSV builders ─────────────────────────────────────────────────────────

  String _buildSingleCsvString(SavedInvoice invoice) {
    final d = invoice.data;
    final buf = StringBuffer();

    void kv(String label, String value) =>
        buf.writeln('${_csv(label)},${_csv(value)}');

    kv('Invoice Number', d.invoiceNumber);
    kv('Issue Date', d.issueDate);
    kv('Due Date', d.dueDate);
    kv('Business Name', d.businessName);
    kv('Business Email', d.businessEmail);
    kv('Business Phone', d.businessPhone);
    kv('Business Address', d.businessAddress);
    kv('Client Name', d.clientName);
    kv('Client Email', d.clientEmail);
    kv('Client Phone', d.clientPhone);
    kv('Client Address', d.clientAddress);
    kv('Currency', d.currency);
    buf.writeln();

    buf.writeln('Description,Quantity,Unit Price,Total');
    for (final item in d.lineItems) {
      buf.writeln(
          '${_csv(item.description)},${item.quantity},${item.unitPrice},${item.total}');
    }
    buf.writeln();

    buf.writeln(',,Subtotal,${d.subtotal}');
    if (d.taxRate > 0) buf.writeln(',,Tax (${d.taxRate}%),${d.taxAmount}');
    if (d.discountRate > 0) {
      buf.writeln(',,Discount (${d.discountRate}%),-${d.discountAmount}');
    }
    buf.writeln(',,TOTAL,${d.grandTotal}');

    if (d.notes.isNotEmpty) {
      buf.writeln();
      kv('Notes', d.notes);
    }

    return buf.toString();
  }

  String _buildBulkCsvString(List<SavedInvoice> invoices) {
    final buf = StringBuffer();
    buf.writeln(
        'Invoice Number,Issue Date,Due Date,Client Name,Client Email,Currency,Subtotal,Tax,Discount,Total');
    for (final inv in invoices) {
      final d = inv.data;
      buf.writeln([
        _csv(d.invoiceNumber),
        _csv(d.issueDate),
        _csv(d.dueDate),
        _csv(d.clientName),
        _csv(d.clientEmail),
        _csv(d.currency),
        d.subtotal,
        d.taxAmount,
        d.discountAmount,
        d.grandTotal,
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

  // ── Shared helpers ───────────────────────────────────────────────────────

  static String _baseFileName(SavedInvoice invoice) =>
      'Invoice_${invoice.data.invoiceNumber.replaceAll(RegExp(r'[^\w]'), '_')}';

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static Future<Directory> _downloadsDir() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    final docs = await getApplicationDocumentsDirectory();
    return docs;
  }
}