// lib/export/folder_download_service.dart
//
// Bundles a folder's documents (invoices/quotes/receipts) into either:
//  - a ZIP of individual PDFs (one per document, generated via the three
//    PdfService.generatePdfBytes() methods added alongside this file), or
//  - a single combined CSV, by delegating straight to
//    BulkDocumentExportService (no duplicated CSV logic — same column
//    layout / escaping / Downloads-vs-share pattern it already has).
//
// EXPENSES PASS (this update): expenses are now threaded through to the
// CSV path ONLY — downloadFolderAsCsv/shareFolderAsCsv both gained
// optional `expenses`/`categoryNameOf` params, passed straight through to
// BulkDocumentExportService (see that file's own EXPENSES PASS comment
// for the accounting rationale — expenses show up as negative-Total rows
// so a folder's exported numbers actually net out). The PDF ZIP path
// (downloadFolderAsPdfZip/shareFolderAsPdfZip) is DELIBERATELY untouched
// — expenses have no PDF template and are not a real, sendable document,
// so they never appear in the PDF bundle, only in the accounting CSV.
// expenses/categoryNameOf both default to empty/identity so any existing
// call site that doesn't pass them compiles and behaves exactly as
// before this pass.
//
// Mirrors the save/share pattern used everywhere else in this app:
// downloadXxx() writes to Downloads and returns the path; shareXxx() writes
// to a temp dir and opens the OS share sheet.
//
// Uses the `archive` package for ZIP encoding — already resolved
// transitively via pdf/printing in pubspec.lock, so pin it directly:
//   flutter pub add archive

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense_data.dart';
import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';
import '../services/invoice_pdf_service.dart';
import '../services/quote_pdf_service.dart';
import '../services/receipt_pdf_service.dart';
import 'bulk_document_export_service.dart';

class FolderDownloadService {
  final InvoicePdfService _invoicePdf = InvoicePdfService();
  final QuotePdfService _quotePdf = QuotePdfService();
  final ReceiptPdfService _receiptPdf = ReceiptPdfService();
  final BulkDocumentExportService _csvService = BulkDocumentExportService();

  // ── PDF ZIP ────────────────────────────────────────────────────────────
  //
  // Documents only — no expenses. Expenses have no PDF template and
  // aren't a real, sendable document; including them here would mean
  // fabricating a fake "expense PDF" with no client-facing purpose, which
  // is exactly what this feature is meant to avoid. Expenses only ever
  // appear in the CSV path below.

  /// Writes a ZIP of every document's PDF to Downloads and returns the path.
  Future<String> downloadFolderAsPdfZip({
    required String folderName,
    required List<SavedInvoice> invoices,
    required List<SavedQuote> quotes,
    required List<SavedReceipt> receipts,
  }) async {
    final bytes = await _buildZipBytes(
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
    );
    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_sanitize(folderName)}_PDFs.zip');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Writes the ZIP to a temp dir and opens the OS share sheet.
  Future<void> shareFolderAsPdfZip({
    required String folderName,
    required List<SavedInvoice> invoices,
    required List<SavedQuote> quotes,
    required List<SavedReceipt> receipts,
  }) async {
    final bytes = await _buildZipBytes(
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_sanitize(folderName)}_PDFs.zip');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/zip')],
      subject: '$folderName — PDFs',
    );
  }

  Future<Uint8List> _buildZipBytes({
    required List<SavedInvoice> invoices,
    required List<SavedQuote> quotes,
    required List<SavedReceipt> receipts,
  }) async {
    final archive = Archive();
    final usedNames = <String, int>{};

    void addEntry(String baseName, Uint8List bytes) {
      var name = '$baseName.pdf';
      final count = usedNames[baseName] ?? 0;
      if (count > 0) {
        name = '${baseName}_$count.pdf';
      }
      usedNames[baseName] = count + 1;
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    for (final inv in invoices) {
      final bytes = await _invoicePdf.generatePdfBytes(inv);
      final base =
          'Invoice_${inv.data.invoiceNumber.replaceAll(RegExp(r'[^\w]'), '_')}';
      addEntry(base, bytes);
    }
    for (final q in quotes) {
      final bytes = await _quotePdf.generatePdfBytes(q);
      final base =
          'Quote_${q.data.quoteNumber.replaceAll(RegExp(r'[^\w]'), '_')}';
      addEntry(base, bytes);
    }
    for (final r in receipts) {
      final bytes = await _receiptPdf.generatePdfBytes(r);
      final base =
          'Receipt_${r.data.receiptNumber.replaceAll(RegExp(r'[^\w]'), '_')}';
      addEntry(base, bytes);
    }

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded ?? <int>[]);
  }

  // ── CSV (delegates to BulkDocumentExportService — no duplicated logic) ──
  //
  // expenses/categoryNameOf are the accounting-accuracy addition — see the
  // EXPENSES PASS comment at the top of this file. Optional, defaulting to
  // "no expenses", so a caller that hasn't been updated yet still compiles
  // and behaves exactly as before.

  Future<String> downloadFolderAsCsv({
    required String folderName,
    required List<SavedInvoice> invoices,
    required List<SavedQuote> quotes,
    required List<SavedReceipt> receipts,
    List<ExpenseEntry> expenses = const [],
    String Function(String categoryId)? categoryNameOf,
  }) {
    return _csvService.exportToDownloads(
      fileName: '${folderName}_Documents',
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
      expenses: expenses,
      categoryNameOf: categoryNameOf,
    );
  }

  Future<void> shareFolderAsCsv({
    required String folderName,
    required List<SavedInvoice> invoices,
    required List<SavedQuote> quotes,
    required List<SavedReceipt> receipts,
    List<ExpenseEntry> expenses = const [],
    String Function(String categoryId)? categoryNameOf,
  }) {
    return _csvService.share(
      fileName: '${folderName}_Documents',
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
      expenses: expenses,
      categoryNameOf: categoryNameOf,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static String _sanitize(String name) {
    final trimmed = name.trim();
    final safe = trimmed.isEmpty ? 'Folder' : trimmed;
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
