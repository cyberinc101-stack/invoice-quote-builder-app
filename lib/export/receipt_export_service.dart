// lib/export/receipt_export_service.dart
//
// Generates and exports receipts as XLSX and CSV — single-document and bulk.
// Mirrors invoice_export_service.dart exactly, built against the real
// ReceiptData fields confirmed in models/receipt_data.dart: receiptNumber,
// paymentDate + paymentMethod (no dueDate/expiryDate),
// businessName/Email/Phone/Address, clientName/Email/Phone/Address,
// currency, lineItems, subtotal, taxRate, taxAmount, discountRate,
// discountAmount, amountPaid (the final total getter — NOT grandTotal),
// notes.
//
// Same conventions as InvoiceExportService:
//  - "download" methods write to the same Downloads directory helper
//    (Android: /storage/emulated/0/Download, else: app documents dir)
//  - "share" methods write to getTemporaryDirectory() and call
//    Share.shareXFiles(...)
//  - Filenames follow the same Receipt_<number-with-non-word-chars-stripped>
//    pattern used for invoice/quote PDFs/exports.
//
// Uses the same `excel` package dependency already added for
// InvoiceExportService — no new pubspec entry needed.

import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/receipt_data.dart';

class ReceiptExportService {
  // ── Public API: single document ─────────────────────────────────────────

  /// Writes a single receipt as an .xlsx file to Downloads and returns the path.
  Future<String> exportSingleXlsxToDownloads(SavedReceipt receipt) async {
    final bytes = _buildSingleXlsxBytes(receipt);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_baseFileName(receipt)}.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Writes a single receipt as an .xlsx file to a temp dir and shares it.
  Future<void> shareSingleXlsx(SavedReceipt receipt) async {
    final bytes = _buildSingleXlsxBytes(receipt);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_baseFileName(receipt)}.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Receipt ${receipt.data.receiptNumber}',
    );
  }

  /// Writes a single receipt as a .csv file to Downloads and returns the path.
  Future<String> exportSingleCsvToDownloads(SavedReceipt receipt) async {
    final csv = _buildSingleCsvString(receipt);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_baseFileName(receipt)}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Writes a single receipt as a .csv file to a temp dir and shares it.
  Future<void> shareSingleCsv(SavedReceipt receipt) async {
    final csv = _buildSingleCsvString(receipt);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_baseFileName(receipt)}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Receipt ${receipt.data.receiptNumber}',
    );
  }

  // ── Public API: bulk export ─────────────────────────────────────────────

  /// Writes one row per receipt (summary totals, no line-item breakdown)
  /// as an .xlsx file to Downloads and returns the path.
  Future<String> exportBulkXlsxToDownloads(List<SavedReceipt> receipts) async {
    final bytes = _buildBulkXlsxBytes(receipts);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/Receipts_Export_${_timestamp()}.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> shareBulkXlsx(List<SavedReceipt> receipts) async {
    final bytes = _buildBulkXlsxBytes(receipts);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Receipts_Export_${_timestamp()}.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Receipts Export',
    );
  }

  Future<String> exportBulkCsvToDownloads(List<SavedReceipt> receipts) async {
    final csv = _buildBulkCsvString(receipts);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/Receipts_Export_${_timestamp()}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  Future<void> shareBulkCsv(List<SavedReceipt> receipts) async {
    final csv = _buildBulkCsvString(receipts);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Receipts_Export_${_timestamp()}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Receipts Export',
    );
  }

  // ── XLSX builders ────────────────────────────────────────────────────────

  List<int> _buildSingleXlsxBytes(SavedReceipt receipt) {
    final d = receipt.data;
    final workbook = xls.Excel.createExcel();
    const sheetName = 'Receipt';
    final sheet = workbook[sheetName];
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

    header('Receipt Number', d.receiptNumber);
    header('Payment Date', d.paymentDate);
    header('Payment Method', _paymentMethodLabel(d.paymentMethod));
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
    totalRow('AMOUNT PAID', d.amountPaid);

    if (d.notes.isNotEmpty) {
      r++;
      header('Notes', d.notes);
    }

    final saved = workbook.save();
    if (saved == null) {
      throw Exception('Failed to generate XLSX bytes for receipt export');
    }
    return saved;
  }

  List<int> _buildBulkXlsxBytes(List<SavedReceipt> receipts) {
    final workbook = xls.Excel.createExcel();
    const sheetName = 'Receipts';
    final sheet = workbook[sheetName];
    if (workbook.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      workbook.delete('Sheet1');
    }

    const cols = [
      'Receipt Number',
      'Payment Date',
      'Payment Method',
      'Client Name',
      'Client Email',
      'Currency',
      'Subtotal',
      'Tax',
      'Discount',
      'Amount Paid',
    ];
    for (int c = 0; c < cols.length; c++) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = xls.TextCellValue(cols[c]);
    }

    for (int i = 0; i < receipts.length; i++) {
      final d = receipts[i].data;
      final r = i + 1;
      final values = <xls.CellValue>[
        xls.TextCellValue(d.receiptNumber),
        xls.TextCellValue(d.paymentDate),
        xls.TextCellValue(_paymentMethodLabel(d.paymentMethod)),
        xls.TextCellValue(d.clientName),
        xls.TextCellValue(d.clientEmail),
        xls.TextCellValue(d.currency),
        xls.DoubleCellValue(d.subtotal),
        xls.DoubleCellValue(d.taxAmount),
        xls.DoubleCellValue(d.discountAmount),
        xls.DoubleCellValue(d.amountPaid),
      ];
      for (int c = 0; c < values.length; c++) {
        sheet
            .cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .value = values[c];
      }
    }

    final saved = workbook.save();
    if (saved == null) {
      throw Exception('Failed to generate bulk XLSX bytes for receipt export');
    }
    return saved;
  }

  // ── CSV builders ─────────────────────────────────────────────────────────

  String _buildSingleCsvString(SavedReceipt receipt) {
    final d = receipt.data;
    final buf = StringBuffer();

    void kv(String label, String value) =>
        buf.writeln('${_csv(label)},${_csv(value)}');

    kv('Receipt Number', d.receiptNumber);
    kv('Payment Date', d.paymentDate);
    kv('Payment Method', _paymentMethodLabel(d.paymentMethod));
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
    buf.writeln(',,AMOUNT PAID,${d.amountPaid}');

    if (d.notes.isNotEmpty) {
      buf.writeln();
      kv('Notes', d.notes);
    }

    return buf.toString();
  }

  String _buildBulkCsvString(List<SavedReceipt> receipts) {
    final buf = StringBuffer();
    buf.writeln(
        'Receipt Number,Payment Date,Payment Method,Client Name,Client Email,Currency,Subtotal,Tax,Discount,Amount Paid');
    for (final rc in receipts) {
      final d = rc.data;
      buf.writeln([
        _csv(d.receiptNumber),
        _csv(d.paymentDate),
        _csv(_paymentMethodLabel(d.paymentMethod)),
        _csv(d.clientName),
        _csv(d.clientEmail),
        _csv(d.currency),
        d.subtotal,
        d.taxAmount,
        d.discountAmount,
        d.amountPaid,
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

  static String _paymentMethodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:         return 'Cash';
      case PaymentMethod.card:         return 'Card';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
      case PaymentMethod.other:        return 'Other';
    }
  }

  static String _baseFileName(SavedReceipt receipt) =>
      'Receipt_${receipt.data.receiptNumber.replaceAll(RegExp(r'[^\w]'), '_')}';

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
