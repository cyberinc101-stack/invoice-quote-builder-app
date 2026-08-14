// lib/services/quote_pdf_service.dart
//
// Generates and exports quote PDFs. Mirrors InvoicePdfService exactly,
// built directly against the real QuoteData/SavedQuote model (businessName,
// clientName, lineItems, subtotal/discountAmount/taxAmount/grandTotal
// getters, QuoteColor scheme).
//
// FIX (this pass): generateAndDownloadPDF / generateAndSharePDF /
// generatePdfBytes now accept an optional [layoutTemplateId] parameter,
// matching InvoicePdfService's signature exactly (previously missing —
// caused a "No named parameter" build error at every call site that
// passed it). _buildPdf is now a small dispatcher, mirroring
// InvoicePdfService's _buildPdf: the original single-layout body is
// renamed to _buildExecutivePdf and is the default/only case for now.
// Adding a second quote layout later is: write _buildXxxPdf() + add a
// case to the switch below — identical pattern to InvoicePdfService.
//
// FOLLOW UP (earlier pass): generateAndSharePDF gained an optional
// [shareText] parameter — pre-filled message body used by the Alerts
// screen's "Follow Up" action. Omitted (null) for every other caller.
//
// NEW (earlier pass): generatePdfBytes() — same purpose as the identically-named
// method added to InvoicePdfService: raw bytes for FolderDownloadService's
// ZIP bundling, no file written.

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/quote_data.dart';

class QuotePdfService {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// [layoutTemplateId] selects the visual layout (1 = Executive, the only
  /// one built so far). Null or unrecognized falls back to Executive.
  Future<String> generateAndDownloadPDF(
    SavedQuote quote, {
    int? layoutTemplateId,
  }) async {
    final bytes = await _buildPdf(quote, layoutTemplateId: layoutTemplateId);
    final dir   = await _downloadsDir();
    final file  = File(
        '${dir.path}/Quote_${quote.data.quoteNumber.replaceAll(RegExp(r'[^\w]'), '_')}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// [shareText] is an optional pre-filled message body (used by the
  /// Alerts screen's "Follow Up" action) — omitted entirely for normal
  /// shares, unchanged from before this pass.
  Future<void> generateAndSharePDF(
    SavedQuote quote, {
    int? layoutTemplateId,
    String? shareText,
  }) async {
    final bytes = await _buildPdf(quote, layoutTemplateId: layoutTemplateId);
    final dir   = await getTemporaryDirectory();
    final file  = File(
        '${dir.path}/Quote_${quote.data.quoteNumber.replaceAll(RegExp(r'[^\w]'), '_')}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Quote ${quote.data.quoteNumber}',
      text: shareText,
    );
  }

  /// NEW: raw PDF bytes, no file written. Used by FolderDownloadService.
  Future<Uint8List> generatePdfBytes(
    SavedQuote quote, {
    int? layoutTemplateId,
  }) {
    return _buildPdf(quote, layoutTemplateId: layoutTemplateId);
  }

  // ── Layout dispatcher ───────────────────────────────────────────────────────
  //
  // Add a case here + a new _buildXxxPdf() method for each future layout.
  // Mirrors InvoicePdfService._buildPdf exactly.
  Future<Uint8List> _buildPdf(
    SavedQuote quote, {
    int? layoutTemplateId,
  }) async {
    switch (layoutTemplateId) {
      case 1:
      default:
        return _buildExecutivePdf(quote);
    }
  }

  // ── PDF builder: Executive (layout id 1) ────────────────────────────────────

  Future<Uint8List> _buildExecutivePdf(SavedQuote quote) async {
    final pdf   = pw.Document();
    final d     = quote.data;
    final color = _pdfColor(d.colorScheme);
    final sym   = _currencySymbol(d.currency);

    final subtotal       = d.subtotal;
    final discountAmount = d.discountAmount;
    final taxAmount      = d.taxAmount;
    final grandTotal     = d.grandTotal;

    pw.MemoryImage? logoImage;
    final logoPath = d.businessLogoPath;
    if (logoPath != null && logoPath.isNotEmpty) {
      final f = File(logoPath);
      if (await f.exists()) {
        logoImage = pw.MemoryImage(await f.readAsBytes());
      }
    }

    final hasCustomer = d.clientName.isNotEmpty ||
        d.clientEmail.isNotEmpty ||
        d.clientPhone.isNotEmpty ||
        d.clientAddress.isNotEmpty;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          // ── Header ────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null) ...[
                  pw.ClipOval(
                    child: pw.Container(
                      width: 64,
                      height: 64,
                      color: PdfColors.white,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (d.businessName.isNotEmpty)
                        pw.Text(d.businessName,
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            )),
                      if (d.businessEmail.isNotEmpty)
                        pw.Text(d.businessEmail,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
                      if (d.businessPhone.isNotEmpty)
                        pw.Text(d.businessPhone,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
                      if (d.businessAddress.isNotEmpty)
                        pw.Text(d.businessAddress,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('QUOTE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                    if (d.quoteNumber.isNotEmpty)
                      pw.Text('#${d.quoteNumber}',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.white)),
                    if (d.issueDate.isNotEmpty)
                      pw.Text(d.issueDate,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    if (d.expiryDate.isNotEmpty)
                      pw.Text('Valid until: ${d.expiryDate}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Bill To ────────────────────────────────────────────────────
          if (hasCustomer)
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PREPARED FOR',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                        letterSpacing: 1,
                      )),
                  pw.SizedBox(height: 4),
                  if (d.clientName.isNotEmpty)
                    pw.Text(d.clientName,
                        style: pw.TextStyle(
                            fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  if (d.clientEmail.isNotEmpty)
                    pw.Text(d.clientEmail,
                        style: const pw.TextStyle(fontSize: 10)),
                  if (d.clientPhone.isNotEmpty)
                    pw.Text(d.clientPhone,
                        style: const pw.TextStyle(fontSize: 10)),
                  if (d.clientAddress.isNotEmpty)
                    pw.Text(d.clientAddress,
                        style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          pw.SizedBox(height: 20),

          // ── Line items table ───────────────────────────────────────────
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: color),
                children: [
                  _th('Description'),
                  _th('Qty', align: pw.TextAlign.center),
                  _th('Unit Price', align: pw.TextAlign.right),
                  _th('Total', align: pw.TextAlign.right),
                ],
              ),
              ...d.lineItems.map(
                (item) => pw.TableRow(
                  children: [
                    _td(item.description),
                    _td(
                      item.quantity % 1 == 0
                          ? item.quantity.toInt().toString()
                          : item.quantity.toStringAsFixed(2),
                      align: pw.TextAlign.center,
                    ),
                    _td('$sym${_fmt(item.unitPrice)}', align: pw.TextAlign.right),
                    _td('$sym${_fmt(item.total)}', align: pw.TextAlign.right),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // ── Totals ────────────────────────────────────────────────────
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', '$sym${_fmt(subtotal)}'),
                  if (d.taxRate > 0)
                    _totalRow('Tax (${_fmtPct(d.taxRate)}%)',
                        '+$sym${_fmt(taxAmount)}'),
                  if (d.discountRate > 0)
                    _totalRow('Discount (${_fmtPct(d.discountRate)}%)',
                        '-$sym${_fmt(discountAmount)}'),
                  pw.Divider(color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ESTIMATED TOTAL',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      pw.Text('$sym${_fmt(grandTotal)}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                              color: color)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Notes ──────────────────────────────────────────────────────
          if (d.notes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Notes / Terms',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: color)),
            pw.SizedBox(height: 4),
            pw.Text(d.notes, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  PdfColor _pdfColor(QuoteColor c) {
    switch (c) {
      case QuoteColor.blue:   return PdfColors.blue800;
      case QuoteColor.green:  return PdfColors.green800;
      case QuoteColor.purple: return PdfColors.purple800;
      case QuoteColor.orange: return PdfColors.orange800;
      case QuoteColor.red:    return PdfColors.red800;
      case QuoteColor.teal:   return PdfColors.teal800;
      case QuoteColor.black:  return PdfColors.grey900;
      case QuoteColor.indigo: return PdfColors.indigo800;
    }
  }

  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'NZD': return 'NZ\$';
      case 'AUD': return 'A\$';
      case 'CAD': return 'C\$';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      default:    return '$code ';
    }
  }

  static String _fmt(double v) {
    final fixed = v.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final sign  = whole.startsWith('-') ? '-' : '';
    final digits = sign.isEmpty ? whole : whole.substring(1);
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '$sign${buf.toString()}.${parts[1]}';
  }

  static String _fmtPct(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  static pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, textAlign: align, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static pw.Widget _totalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static Future<Directory> _downloadsDir() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    final docs = await getApplicationDocumentsDirectory();
    return docs;
  }
}