// lib/export/expense_export_service.dart
//
// Generates and exports expenses as XLSX and CSV — single-entry and bulk.
// Mirrors invoice_export_service.dart's conventions exactly:
//  - "download" methods write to the same Downloads directory helper
//    (Android: /storage/emulated/0/Download, else: app documents dir)
//  - "share" methods write to getTemporaryDirectory() and call
//    Share.shareXFiles(...)
//  - Filenames follow an analogous Expense_<id-with-non-word-chars-stripped>
//    pattern for single entries, and Expenses_Export_<timestamp> for bulk.
//
// Field usage (vendor, amount, currency, categoryId, date, notes, id on
// ExpenseEntry) is taken directly from lib/models/expense_data.dart.
// categoryId is resolved to a human-readable name via CategoryProvider —
// pass it in rather than having this service depend on CategoryProvider
// directly, so it stays a pure data-in/file-out service like its invoice
// counterpart.
//
// DEPENDENCY: same as invoice_export_service.dart — uses the `excel`
// package (already a dependency once invoice export was added) for XLSX,
// and plain string joining for CSV. No new pubspec.yaml entries needed.

import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense_data.dart';

class ExpenseExportService {
  // ── Public API: single entry ─────────────────────────────────────────────

  /// Writes a single expense as an .xlsx file to Downloads and returns the path.
  Future<String> exportSingleXlsxToDownloads(
    ExpenseEntry expense, {
    required String categoryName,
  }) async {
    final bytes = _buildSingleXlsxBytes(expense, categoryName: categoryName);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_baseFileName(expense)}.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Writes a single expense as an .xlsx file to a temp dir and shares it.
  Future<void> shareSingleXlsx(
    ExpenseEntry expense, {
    required String categoryName,
  }) async {
    final bytes = _buildSingleXlsxBytes(expense, categoryName: categoryName);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_baseFileName(expense)}.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Expense — ${expense.vendor.isEmpty ? "(No vendor)" : expense.vendor}',
    );
  }

  /// Writes a single expense as a .csv file to Downloads and returns the path.
  Future<String> exportSingleCsvToDownloads(
    ExpenseEntry expense, {
    required String categoryName,
  }) async {
    final csv = _buildSingleCsvString(expense, categoryName: categoryName);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_baseFileName(expense)}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Writes a single expense as a .csv file to a temp dir and shares it.
  Future<void> shareSingleCsv(
    ExpenseEntry expense, {
    required String categoryName,
  }) async {
    final csv = _buildSingleCsvString(expense, categoryName: categoryName);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_baseFileName(expense)}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Expense — ${expense.vendor.isEmpty ? "(No vendor)" : expense.vendor}',
    );
  }

  // ── Public API: bulk export ─────────────────────────────────────────────
  //
  // categoryNameOf resolves a categoryId to a display name (pass
  // categories.byId(id).name from CategoryProvider at the call site) so
  // this service has no direct dependency on CategoryProvider.

  Future<String> exportBulkXlsxToDownloads(
    List<ExpenseEntry> expenses, {
    required String Function(String categoryId) categoryNameOf,
  }) async {
    final bytes = _buildBulkXlsxBytes(expenses, categoryNameOf: categoryNameOf);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/Expenses_Export_${_timestamp()}.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> shareBulkXlsx(
    List<ExpenseEntry> expenses, {
    required String Function(String categoryId) categoryNameOf,
  }) async {
    final bytes = _buildBulkXlsxBytes(expenses, categoryNameOf: categoryNameOf);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Expenses_Export_${_timestamp()}.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Expenses Export',
    );
  }

  Future<String> exportBulkCsvToDownloads(
    List<ExpenseEntry> expenses, {
    required String Function(String categoryId) categoryNameOf,
  }) async {
    final csv = _buildBulkCsvString(expenses, categoryNameOf: categoryNameOf);
    final dir = await _downloadsDir();
    final file = File('${dir.path}/Expenses_Export_${_timestamp()}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  Future<void> shareBulkCsv(
    List<ExpenseEntry> expenses, {
    required String Function(String categoryId) categoryNameOf,
  }) async {
    final csv = _buildBulkCsvString(expenses, categoryNameOf: categoryNameOf);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Expenses_Export_${_timestamp()}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Expenses Export',
    );
  }

  // ── XLSX builders ────────────────────────────────────────────────────────

  List<int> _buildSingleXlsxBytes(
    ExpenseEntry expense, {
    required String categoryName,
  }) {
    final workbook = xls.Excel.createExcel();
    const sheetName = 'Expense';
    final sheet = workbook[sheetName];
    if (workbook.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      workbook.delete('Sheet1');
    }

    int r = 0;
    void row(String label, String value) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
          .value = xls.TextCellValue(label);
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
          .value = xls.TextCellValue(value);
      r++;
    }

    row('Vendor', expense.vendor.isEmpty ? '(No vendor)' : expense.vendor);
    row('Date', _formatDate(expense.date));
    row('Category', categoryName);
    row('Currency', expense.currency);
    sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
        .value = xls.TextCellValue('Amount');
    sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
        .value = xls.DoubleCellValue(expense.amount);
    r++;
    if (expense.notes.isNotEmpty) row('Notes', expense.notes);

    final saved = workbook.save();
    if (saved == null) {
      throw Exception('Failed to generate XLSX bytes for expense export');
    }
    return saved;
  }

  List<int> _buildBulkXlsxBytes(
    List<ExpenseEntry> expenses, {
    required String Function(String categoryId) categoryNameOf,
  }) {
    final workbook = xls.Excel.createExcel();
    const sheetName = 'Expenses';
    final sheet = workbook[sheetName];
    if (workbook.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      workbook.delete('Sheet1');
    }

    const cols = ['Date', 'Vendor', 'Category', 'Currency', 'Amount', 'Notes'];
    for (int c = 0; c < cols.length; c++) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = xls.TextCellValue(cols[c]);
    }

    for (int i = 0; i < expenses.length; i++) {
      final e = expenses[i];
      final r = i + 1;
      final values = <xls.CellValue>[
        xls.TextCellValue(_formatDate(e.date)),
        xls.TextCellValue(e.vendor.isEmpty ? '(No vendor)' : e.vendor),
        xls.TextCellValue(categoryNameOf(e.categoryId)),
        xls.TextCellValue(e.currency),
        xls.DoubleCellValue(e.amount),
        xls.TextCellValue(e.notes),
      ];
      for (int c = 0; c < values.length; c++) {
        sheet
            .cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .value = values[c];
      }
    }

    // Running total row.
    final total = expenses.fold<double>(0.0, (s, e) => s + e.amount);
    final totalRow = expenses.length + 2;
    sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRow))
        .value = xls.TextCellValue('TOTAL');
    sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow))
        .value = xls.DoubleCellValue(total);

    final saved = workbook.save();
    if (saved == null) {
      throw Exception('Failed to generate bulk XLSX bytes for expense export');
    }
    return saved;
  }

  // ── CSV builders ─────────────────────────────────────────────────────────

  String _buildSingleCsvString(
    ExpenseEntry expense, {
    required String categoryName,
  }) {
    final buf = StringBuffer();
    void kv(String label, String value) =>
        buf.writeln('${_csv(label)},${_csv(value)}');

    kv('Vendor', expense.vendor.isEmpty ? '(No vendor)' : expense.vendor);
    kv('Date', _formatDate(expense.date));
    kv('Category', categoryName);
    kv('Currency', expense.currency);
    buf.writeln('Amount,${expense.amount}');
    if (expense.notes.isNotEmpty) kv('Notes', expense.notes);

    return buf.toString();
  }

  String _buildBulkCsvString(
    List<ExpenseEntry> expenses, {
    required String Function(String categoryId) categoryNameOf,
  }) {
    final buf = StringBuffer();
    buf.writeln('Date,Vendor,Category,Currency,Amount,Notes');
    for (final e in expenses) {
      buf.writeln([
        _csv(_formatDate(e.date)),
        _csv(e.vendor.isEmpty ? '(No vendor)' : e.vendor),
        _csv(categoryNameOf(e.categoryId)),
        _csv(e.currency),
        e.amount,
        _csv(e.notes),
      ].join(','));
    }
    buf.writeln();
    final total = expenses.fold<double>(0.0, (s, e) => s + e.amount);
    buf.writeln(',,,TOTAL,$total');
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

  // ── Shared helpers ───────────────────────────────────────────────────────

  static String _baseFileName(ExpenseEntry expense) =>
      'Expense_${expense.id.replaceAll(RegExp(r'[^\w]'), '_')}';

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
