// lib/services/quote_pdf_service.dart
//
// Generates and exports quote PDFs.
//
// HISTORY LOGGING PASS (this update): generateAndSharePDF now accepts an
// optional [historyProvider], mirroring invoice_pdf_service.dart's own
// HISTORY LOGGING PASS exactly — when provided, logs a
// HistoryEventType.shared event with the just-shared file attached as
// sourceFile, since Share.shareXFiles doesn't hand a path back to the
// caller the way the download flow does. Omitted (null) is a no-op.
//
// LOGO PARITY PASS (earlier): mirrors invoice_pdf_service.dart's own
// LOGO PARITY PASS exactly — the Executive builder's logo was hardcoded
// to pw.ClipOval on a solid white background regardless of what LogoShape
// the user actually picked via the Logo Sizer. Now clips to the real
// shape (circle/square/roundedSquare, mirroring LogoShape.radiusFor() on
// the Flutter side) and sits on a very light neutral background with
// BoxFit.contain, matching pdf_templates.dart's _logoWidget (used by
// styles 2-10 for quotes too, via buildStyledDocument) and the
// Flutter-side DocLogoAvatar's own contain-fit treatment.
//
// CURRENCY DISPLAY PASS (earlier): _fmtMoney(d, v) uses QuoteData's own
// currency/currencySymbol/currencyDisplayMode fields directly — mirrors
// DocTemplateAdapter.fmtMoney() (Flutter preview side) and
// PdfDocData.fmtMoney() (styled-template path), so exported PDFs respect
// whatever the user actually typed for currency symbol/format.
//
// REWRITE: built directly against the real QuoteData model (flat fields:
// businessName, businessEmail, clientName, lineItems, etc.), same as
// invoice_pdf_service.dart's own rewrite — see that file's header comment
// for the full rationale, which applies identically here.
//
// Layout dispatcher: layoutTemplateId selects the visual style (1 =
// Executive, built directly below; 2-10 route through
// pdf_templates.dart's buildStyledDocument, shared with invoice/receipt).

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/quote_data.dart';
import '../models/history_event.dart' show HistoryDocType;
import '../providers/history_provider.dart';
import 'pdf_doc_adapter.dart';
import 'pdf_templates.dart' as styled;

class QuotePdfService {
  // ── Public API ─────────────────────────────────────────────────────────────

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

  /// [historyProvider], when passed, logs a `shared` History event with
  /// the shared file attached as sourceFile — mirrors
  /// invoice_pdf_service.dart's identical treatment. Omitted (null) is a
  /// no-op, so every existing call site behaves exactly as before.
  Future<void> generateAndSharePDF(
    SavedQuote quote, {
    int? layoutTemplateId,
    String? shareText,
    HistoryProvider? historyProvider,
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
    if (historyProvider != null) {
      final d = quote.data;
      unawaited(historyProvider.logShared(
        docType: HistoryDocType.quote,
        docId: quote.id,
        docNumber: d.quoteNumber,
        clientName: d.clientName.isEmpty ? null : d.clientName,
        amount: d.grandTotal,
        currency: d.currency,
        sourceFile: file,
      ));
    }
  }

  Future<Uint8List> generatePdfBytes(
    SavedQuote quote, {
    int? layoutTemplateId,
  }) {
    return _buildPdf(quote, layoutTemplateId: layoutTemplateId);
  }

  // ── Layout dispatcher ───────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(
    SavedQuote quote, {
    int? layoutTemplateId,
  }) async {
    final id = layoutTemplateId ?? 1;
    if (id == 1) return _buildExecutivePdf(quote);
    final data = await quoteToPdfData(quote.data);
    final bytes = await styled.buildStyledDocument(data, id);
    return Uint8List.fromList(bytes);
  }

  // ── PDF builder: Executive (layout id 1) ────────────────────────────────────

  Future<Uint8List> _buildExecutivePdf(SavedQuote quote) async {
    final pdf   = pw.Document();
    final d     = quote.data;
    final color = _pdfColor(d.colorScheme);

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
                  _executiveLogoWidget(logoImage, d.businessLogoShape),
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

          // ── Prepared For ──────────────────────────────────────────────
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
                    _td(_fmtMoney(d, item.unitPrice), align: pw.TextAlign.right),
                    _td(_fmtMoney(d, item.total), align: pw.TextAlign.right),
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
                  _totalRow('Subtotal', _fmtMoney(d, subtotal)),
                  if (d.taxRate > 0)
                    _totalRow('Tax (${_fmtPct(d.taxRate)}%)',
                        '+${_fmtMoney(d, taxAmount)}'),
                  if (d.discountRate > 0)
                    _totalRow('Discount (${_fmtPct(d.discountRate)}%)',
                        '-${_fmtMoney(d, discountAmount)}'),
                  pw.Divider(color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text(_fmtMoney(d, grandTotal),
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

  /// Renders the Executive header logo respecting the document's real
  /// LogoShape instead of a hardcoded ClipOval — mirrors
  /// invoice_pdf_service.dart's identical helper exactly.
  static pw.Widget _executiveLogoWidget(pw.MemoryImage logoImage, String logoShape, {double size = 64}) {
    final radius = switch (logoShape) {
      'circle' => size / 2,
      'square' => 0.0,
      _ => size * 0.22, // roundedSquare + fallback
    };
    return pw.ClipRRect(
      horizontalRadius: radius,
      verticalRadius: radius,
      child: pw.Container(
        width: size,
        height: size,
        color: PdfColors.grey50,
        alignment: pw.Alignment.center,
        padding: pw.EdgeInsets.all(size * 0.08),
        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
      ),
    );
  }

  /// Formats money using QuoteData's own currency/currencySymbol/
  /// currencyDisplayMode fields — mirrors invoice_pdf_service.dart's
  /// identical helper exactly.
  static String _fmtMoney(QuoteData d, double v) {
    final amount = _fmt(v);
    final hasSymbol = d.currencySymbol.trim().isNotEmpty;
    final hasCode = d.currency.trim().isNotEmpty;

    switch (d.currencyDisplayMode) {
      case 'symbol':
        if (hasSymbol) return '${d.currencySymbol}$amount';
        return hasCode ? '${d.currency} $amount' : amount;
      case 'both':
        if (hasSymbol && hasCode) return '${d.currency} ${d.currencySymbol}$amount';
        if (hasSymbol) return '${d.currencySymbol}$amount';
        if (hasCode) return '${d.currency} $amount';
        return amount;
      case 'code':
      default:
        if (hasCode) return '${d.currency} $amount';
        return hasSymbol ? '${d.currencySymbol}$amount' : amount;
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