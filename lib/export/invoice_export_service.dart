// lib/export/invoice_export_service.dart
//
// PARITY FIX (this update): brings the single-document XLSX/CSV export
// up to the same data-correctness level the PDF/preview rendering
// already has (see shared_doc_widgets.dart / invoice_pdf_service.dart's
// own earlier fixes for the identical bug in those pipelines). Three
// changes, both builders (_buildSingleXlsxBytes and
// _buildSingleCsvString):
//   1. The line-item table's Total column now uses item.lineNetTotal
//      (this row's own discount/tax applied) instead of the plain
//      item.total (qty x price) figure — same LINE ITEM TOTAL FIX
//      already made to the PDF export and Flutter preview. Two extra
//      columns (Discount, Tax) show each row's own rate label/amount
//      when it has one, so the exported sheet doesn't just show a
//      total that mysteriously differs from qty x price with no
//      explanation.
//   2. The whole-invoice Tax/Discount rows now also gate on
//      d.taxEnabled/d.discountEnabled — previously only checked
//      d.taxRate/d.discountRate > 0, so a disabled tax with a leftover
//      nonzero rate would still print a Tax row here even though it's
//      switched off and contributing nothing to the total.
//   3. Added "Item Tax"/"Item Discounts" breakdown rows — one per
//      distinct itemTaxName/itemDiscountName in use, sourced from
//      InvoiceData.itemTaxExtraByName/itemDiscountExtraByName (the same
//      getters the PDF/preview totals sections already read). Without
//      these, Subtotal + Tax - Discount never actually summed to the
//      TOTAL row whenever a line item had its own tax/discount rate —
//      TOTAL itself was always correct (it reads d.grandTotal directly),
//      but the visible breakdown above it didn't reconcile.
// The bulk sheet's TOTAL column was already correct (reads d.grandTotal
// directly per invoice), but its Tax/Discount columns had the same
// reconciliation gap — added two more columns, "Item Tax Extra" and
// "Item Discount Extra" (flat totals, not grouped by name — a summary
// sheet has one row per invoice, so a per-name breakdown doesn't fit a
// fixed column layout the way it does on the single-document sheet),
// so Subtotal + Tax - Discount + Item Tax Extra - Item Discount Extra
// now reconciles to Total on every row.
//
// HISTORY LOGGING PASS (earlier): every public share/download method
// takes an optional `historyProvider` param.
//
// Built to match invoice_pdf_service.dart's existing conventions.
//
// NEW DEPENDENCY: this file needs the `excel` package for XLSX
// generation (excel: ^4.0.6 in pubspec.yaml). CSV needs no package.

import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/history_event.dart';
import '../models/invoice_data.dart';
import '../providers/history_provider.dart';

class InvoiceExportService {
  // ── Public API: single document ─────────────────────────────────────────

  Future<String> exportSingleXlsxToDownloads(
    SavedInvoice invoice, {
    HistoryProvider? historyProvider,
  }) async {
    final bytes = _buildSingleXlsxBytes(invoice);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_baseFileName(invoice)}.xlsx');
    await file.writeAsBytes(bytes);
    await _logSingle(invoice, HistoryEventType.downloaded, file, historyProvider);
    return file.path;
  }

  Future<void> shareSingleXlsx(
    SavedInvoice invoice, {
    HistoryProvider? historyProvider,
  }) async {
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
    await _logSingle(invoice, HistoryEventType.shared, file, historyProvider);
  }

  Future<String> exportSingleCsvToDownloads(
    SavedInvoice invoice, {
    HistoryProvider? historyProvider,
  }) async {
    final csv = _buildSingleCsvString(invoice);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_baseFileName(invoice)}.csv');
    await file.writeAsString(csv);
    await _logSingle(invoice, HistoryEventType.downloaded, file, historyProvider);
    return file.path;
  }

  Future<void> shareSingleCsv(
    SavedInvoice invoice, {
    HistoryProvider? historyProvider,
  }) async {
    final csv = _buildSingleCsvString(invoice);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_baseFileName(invoice)}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Invoice ${invoice.data.invoiceNumber}',
    );
    await _logSingle(invoice, HistoryEventType.shared, file, historyProvider);
  }

  // ── Public API: bulk export ─────────────────────────────────────────────

  Future<String> exportBulkXlsxToDownloads(
    List<SavedInvoice> invoices, {
    HistoryProvider? historyProvider,
  }) async {
    final bytes = _buildBulkXlsxBytes(invoices);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/Invoices_Export_${_timestamp()}.xlsx');
    await file.writeAsBytes(bytes);
    await _logBulk(invoices, HistoryEventType.downloaded, file, historyProvider);
    return file.path;
  }

  Future<void> shareBulkXlsx(
    List<SavedInvoice> invoices, {
    HistoryProvider? historyProvider,
  }) async {
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
    await _logBulk(invoices, HistoryEventType.shared, file, historyProvider);
  }

  Future<String> exportBulkCsvToDownloads(
    List<SavedInvoice> invoices, {
    HistoryProvider? historyProvider,
  }) async {
    final csv = _buildBulkCsvString(invoices);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/Invoices_Export_${_timestamp()}.csv');
    await file.writeAsString(csv);
    await _logBulk(invoices, HistoryEventType.downloaded, file, historyProvider);
    return file.path;
  }

  Future<void> shareBulkCsv(
    List<SavedInvoice> invoices, {
    HistoryProvider? historyProvider,
  }) async {
    final csv = _buildBulkCsvString(invoices);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Invoices_Export_${_timestamp()}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Invoices Export',
    );
    await _logBulk(invoices, HistoryEventType.shared, file, historyProvider);
  }

  // ── History logging helpers ─────────────────────────────────────────────

  Future<void> _logSingle(
    SavedInvoice invoice,
    HistoryEventType type,
    File file,
    HistoryProvider? historyProvider,
  ) async {
    if (historyProvider == null) return;
    final d = invoice.data;
    await historyProvider.logEvent(
      type: type,
      docType: HistoryDocType.invoice,
      docId: d.invoiceNumber,
      docNumber: d.invoiceNumber,
      clientName: d.clientName,
      amount: d.grandTotal,
      currency: d.currency,
      sourceFile: file,
    );
  }

  Future<void> _logBulk(
    List<SavedInvoice> invoices,
    HistoryEventType type,
    File file,
    HistoryProvider? historyProvider,
  ) async {
    if (historyProvider == null) return;
    await historyProvider.logEvent(
      type: type,
      docType: HistoryDocType.invoice,
      docId: 'bulk_${_timestamp()}',
      docNumber: 'Bulk export (${invoices.length})',
      sourceFile: file,
    );
  }

  // ── XLSX builders ────────────────────────────────────────────────────────

  List<int> _buildSingleXlsxBytes(SavedInvoice invoice) {
    final d = invoice.data;
    final workbook = xls.Excel.createExcel();
    final sheetName = 'Invoice';
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
    r++;

    // PARITY FIX: two extra columns (Discount, Tax) show each row's own
    // rate label/amount when set — Total now uses lineNetTotal, so these
    // columns explain why a row's Total differs from qty x Unit Price.
    const cols = ['Description', 'Quantity', 'Unit Price', 'Discount', 'Tax', 'Total'];
    for (int c = 0; c < cols.length; c++) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
          .value = xls.TextCellValue(cols[c]);
    }
    r++;
    for (final item in d.lineItems) {
      final discountAmt = item.discountEnabled ? item.total * item.itemDiscountRate / 100 : 0.0;
      final taxAmt = item.taxEnabled ? item.total * item.itemTaxRate / 100 : 0.0;
      final signedTaxAmt = item.taxEnabled
          ? (item.itemTaxIsAddition ? taxAmt : -taxAmt)
          : 0.0;

      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
          .value = xls.TextCellValue(item.description);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
          .value = xls.DoubleCellValue(item.quantity);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r))
          .value = xls.DoubleCellValue(item.unitPrice);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r))
          .value = item.discountEnabled
              ? xls.TextCellValue(
                  '-${discountAmt.toStringAsFixed(2)}${item.itemDiscountName.trim().isEmpty ? '' : ' (${item.itemDiscountName.trim()})'}')
              : xls.TextCellValue('');
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r))
          .value = item.taxEnabled
              ? xls.TextCellValue(
                  '${signedTaxAmt < 0 ? '-' : ''}${signedTaxAmt.abs().toStringAsFixed(2)}${item.itemTaxName.trim().isEmpty ? '' : ' (${item.itemTaxName.trim()})'}')
              : xls.TextCellValue('');
      // PARITY FIX: lineNetTotal instead of the plain qty x price total.
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r))
          .value = xls.DoubleCellValue(item.lineNetTotal);
      r++;
    }
    r++;

    void totalRow(String label, double value) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r))
          .value = xls.TextCellValue(label);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r))
          .value = xls.DoubleCellValue(value);
      r++;
    }

    totalRow('Subtotal', d.subtotal);
    // PARITY FIX: gated on taxEnabled/discountEnabled, not just rate > 0.
    if (d.taxEnabled && d.taxRate > 0) {
      totalRow('${d.taxName.trim().isEmpty ? 'Tax' : d.taxName.trim()} (${d.taxRate}%)', d.taxAmount);
    }
    if (d.discountEnabled && d.discountRate > 0) {
      totalRow('${d.discountName.trim().isEmpty ? 'Discount' : d.discountName.trim()} (${d.discountRate}%)', -d.discountAmount);
    }
    // PARITY FIX: grouped-by-name per-item breakdown rows — without
    // these, Subtotal + Tax - Discount never actually summed to TOTAL
    // whenever a line item used its own discount/tax rate.
    for (final entry in d.itemDiscountExtraByName.entries) {
      if (entry.value > 0) {
        totalRow(entry.key.isEmpty ? 'Item Discounts' : 'Item Discounts (${entry.key})', -entry.value);
      }
    }
    for (final entry in d.itemTaxExtraByName.entries) {
      if (entry.value != 0) {
        totalRow(entry.key.isEmpty ? 'Item Tax' : 'Item Tax (${entry.key})', entry.value);
      }
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

    // PARITY FIX: added "Item Tax Extra"/"Item Discount Extra" flat
    // columns (not grouped by name — a summary row per invoice doesn't
    // fit a per-name breakdown into a fixed column layout the way the
    // single-document sheet does) so Subtotal + Tax - Discount +
    // Item Tax Extra - Item Discount Extra reconciles to Total on every
    // row. Total itself was already correct (reads d.grandTotal
    // directly), so no change to that column.
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
      'Item Tax Extra',
      'Item Discount Extra',
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
        xls.DoubleCellValue(d.itemTaxExtra),
        xls.DoubleCellValue(d.itemDiscountExtra),
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

    // PARITY FIX: Discount/Tax columns added; Total column now uses
    // lineNetTotal instead of the plain qty x price total.
    buf.writeln('Description,Quantity,Unit Price,Discount,Tax,Total');
    for (final item in d.lineItems) {
      final discountAmt = item.discountEnabled ? item.total * item.itemDiscountRate / 100 : 0.0;
      final taxAmt = item.taxEnabled ? item.total * item.itemTaxRate / 100 : 0.0;
      final signedTaxAmt = item.taxEnabled
          ? (item.itemTaxIsAddition ? taxAmt : -taxAmt)
          : 0.0;
      final discountCell = item.discountEnabled
          ? '-${discountAmt.toStringAsFixed(2)}${item.itemDiscountName.trim().isEmpty ? '' : ' (${item.itemDiscountName.trim()})'}'
          : '';
      final taxCell = item.taxEnabled
          ? '${signedTaxAmt < 0 ? '-' : ''}${signedTaxAmt.abs().toStringAsFixed(2)}${item.itemTaxName.trim().isEmpty ? '' : ' (${item.itemTaxName.trim()})'}'
          : '';
      buf.writeln(
          '${_csv(item.description)},${item.quantity},${item.unitPrice},${_csv(discountCell)},${_csv(taxCell)},${item.lineNetTotal}');
    }
    buf.writeln();

    buf.writeln(',,,,Subtotal,${d.subtotal}');
    // PARITY FIX: gated on taxEnabled/discountEnabled, not just rate > 0;
    // uses taxName/discountName when set.
    if (d.taxEnabled && d.taxRate > 0) {
      buf.writeln(',,,,${_csv('${d.taxName.trim().isEmpty ? 'Tax' : d.taxName.trim()} (${d.taxRate}%)')},${d.taxAmount}');
    }
    if (d.discountEnabled && d.discountRate > 0) {
      buf.writeln(',,,,${_csv('${d.discountName.trim().isEmpty ? 'Discount' : d.discountName.trim()} (${d.discountRate}%)')},-${d.discountAmount}');
    }
    // PARITY FIX: grouped-by-name per-item breakdown rows.
    for (final entry in d.itemDiscountExtraByName.entries) {
      if (entry.value > 0) {
        buf.writeln(',,,,${_csv(entry.key.isEmpty ? 'Item Discounts' : 'Item Discounts (${entry.key})')},-${entry.value}');
      }
    }
    for (final entry in d.itemTaxExtraByName.entries) {
      if (entry.value != 0) {
        buf.writeln(',,,,${_csv(entry.key.isEmpty ? 'Item Tax' : 'Item Tax (${entry.key})')},${entry.value}');
      }
    }
    buf.writeln(',,,,TOTAL,${d.grandTotal}');

    if (d.notes.isNotEmpty) {
      buf.writeln();
      kv('Notes', d.notes);
    }

    return buf.toString();
  }

  String _buildBulkCsvString(List<SavedInvoice> invoices) {
    final buf = StringBuffer();
    // PARITY FIX: added Item Tax Extra/Item Discount Extra columns —
    // same reconciliation fix as the bulk XLSX sheet above.
    buf.writeln(
        'Invoice Number,Issue Date,Due Date,Client Name,Client Email,Currency,Subtotal,Tax,Discount,Item Tax Extra,Item Discount Extra,Total');
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
        d.itemTaxExtra,
        d.itemDiscountExtra,
        d.grandTotal,
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