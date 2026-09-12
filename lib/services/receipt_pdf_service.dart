// lib/services/receipt_pdf_service.dart
//
// OFFLINE SIGNATURE FONT PARITY PASS (this update): mirrors the fix
// already applied to invoice_pdf_extra_sections.dart's and (this same
// pass) quote_pdf_service.dart's _pdfSignatureFont() — this file's own
// _pdfSignatureFont() still called PdfGoogleFonts.xRegular() for the six
// script fonts, which always hits the network regardless of
// GoogleFonts.config and fails silently (falls back to the plain
// bold-italic style) with no connection. The six fonts are already
// bundled locally in assets/signature_fonts/ and registered in
// pubspec.yaml (that's what let Invoice's own fix work), so this now
// loads each one via rootBundle + pw.Font.ttf() instead, exactly like
// Invoice and Quote. No behavior change when signatureFontFamily is ''
// or unrecognized — still falls back to the original bold-italic
// pw.TextStyle look. printing.dart's import is kept (still needed for
// Printing.layoutPdf in printReceipt()) — only the PdfGoogleFonts calls
// are gone.
//
// SIGNATURE LINE WIDTH PDF PARITY PASS (earlier): mirrors the
// identical fix applied to invoice_pdf_extra_sections.dart's
// buildPdfSignatureBlock and quote_pdf_service.dart's
// _buildQuoteSignatureBlock — the live preview's signing line under a
// typed signature (executive_receipt_stationary_layout.dart's
// buildSignatureBlock) was fixed in an earlier pass to measure the
// actual rendered name width and size the line to match it, clamped to
// [70, 220], but that fix never reached this file's exported PDF, which
// still drew a fixed 160pt line regardless of name length.
//
// Fixed by adding _measureSignatureWidth(), which uses the pdf
// package's own PdfFont.stringMetrics() (the same call pw.Text itself
// uses internally to lay out a string) instead of Flutter's
// TextPainter, since this file has no Flutter widget tree to measure
// against. This measures the ACTUAL font about to be drawn — the
// bundled signature font, or the built-in Helvetica-BoldOblique
// fallback when no signature font resolves — which guarantees the line
// matches what's actually on the page. _buildReceiptSignatureBlock's
// local line() now takes an optional width parameter (default 160,
// unchanged for 'image'/'blank' — only 'typed' passes a measured
// width), mirroring the Flutter side's line({double width = 160})
// exactly. _buildThermalPdf is UNCHANGED — thermal receipts have no
// signature block at all.
//
// NOTE: same as Invoice's/Quote's PDF fallback — the no-font-resolved
// branch hardcodes fontSize: 20, not d.signatureFontSize the way the
// Flutter fallback does. Pre-existing, out of scope here; the
// measurement below always uses whichever size is actually applied so
// the line stays matched to its own text either way.
//
// SIGNATURE PASS (earlier): _buildExecutivePdf (the A4 export path
// only — thermal receipts have no signature block, same as Invoice's
// own Signature feature never applying to a non-A4 layout) now renders
// a signature block after Notes, gated by ReceiptData.showSignature and
// signatureMode being non-empty (mirrors
// executive_receipt_stationary_layout.dart's buildSignatureBlock gating
// exactly). New _buildReceiptSignatureBlock() helper mirrors
// invoice_pdf_extra_sections.dart's buildPdfSignatureBlock /
// quote_pdf_service.dart's _buildQuoteSignatureBlock: 'image' reads the
// file off disk, 'typed' loads a bundled signature font when
// ReceiptData.signatureFontFamily names one of the six offered families
// (falls back to the original bold-italic pw.TextStyle when it's ''),
// 'blank' reserves a signing line, '' (deselected) renders nothing.
// _buildExecutivePdf is already async, so no new async plumbing was
// needed at the call site. _buildThermalPdf is UNCHANGED.
//
// All earlier passes (PER-ITEM TAX/DISCOUNT, TAX/DISCOUNT TOGGLE +
// NAME, CASHIER NAME TOGGLE, HISTORY LOGGING, FIELD VISIBILITY, THERMAL
// PDF, PRINT ACTION, LOGO PARITY, CURRENCY DISPLAY) — see prior header
// comments; unaffected by this update.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:barcode/barcode.dart' as bc;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/create_receipt_section/receipt_paper_format.dart';
import '../models/receipt_data.dart';
import '../models/history_event.dart' show HistoryDocType;
import '../providers/history_provider.dart';
import 'pdf_doc_adapter.dart';
import 'pdf_templates.dart' as styled;

class ReceiptPdfService {
  // ── Public API ─────────────────────────────────────────────────────────────

  Future<String> generateAndDownloadPDF(
    SavedReceipt receipt, {
    int? layoutTemplateId,
  }) async {
    final bytes = await _buildPdf(receipt, layoutTemplateId: layoutTemplateId);
    final dir   = await _downloadsDir();
    final file  = File(
        '${dir.path}/Receipt_${receipt.data.receiptNumber.replaceAll(RegExp(r'[^\w]'), '_')}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> generateAndSharePDF(
    SavedReceipt receipt, {
    int? layoutTemplateId,
    String? shareText,
    HistoryProvider? historyProvider,
  }) async {
    final bytes = await _buildPdf(receipt, layoutTemplateId: layoutTemplateId);
    final dir   = await getTemporaryDirectory();
    final file  = File(
        '${dir.path}/Receipt_${receipt.data.receiptNumber.replaceAll(RegExp(r'[^\w]'), '_')}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Receipt ${receipt.data.receiptNumber}',
      text: shareText,
    );
    if (historyProvider != null) {
      final d = receipt.data;
      unawaited(historyProvider.logShared(
        docType: HistoryDocType.receipt,
        docId: receipt.id,
        docNumber: d.receiptNumber,
        clientName: d.clientName.isEmpty ? null : d.clientName,
        amount: d.amountPaid,
        currency: d.currency,
        sourceFile: file,
      ));
    }
  }

  Future<Uint8List> generatePdfBytes(
    SavedReceipt receipt, {
    int? layoutTemplateId,
  }) {
    return _buildPdf(receipt, layoutTemplateId: layoutTemplateId);
  }

  Future<void> printReceipt(
    SavedReceipt receipt, {
    int? layoutTemplateId,
    String? paperFormat,
    HistoryProvider? historyProvider,
  }) async {
    final bytes = await _buildPdf(receipt, layoutTemplateId: layoutTemplateId);
    final format = receiptPaperFormatFromString(paperFormat ?? receipt.data.paperFormat);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name:
          'Receipt_${receipt.data.receiptNumber.replaceAll(RegExp(r'[^\w]'), '_')}.pdf',
      format: format.isThermal ? _thermalPageFormat(format) : PdfPageFormat.a4,
    );
    if (historyProvider != null) {
      final d = receipt.data;
      unawaited(historyProvider.logPrinted(
        docType: HistoryDocType.receipt,
        docId: receipt.id,
        docNumber: d.receiptNumber,
        clientName: d.clientName.isEmpty ? null : d.clientName,
        amount: d.amountPaid,
        currency: d.currency,
      ));
    }
  }

  // ── Layout dispatcher ───────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(
    SavedReceipt receipt, {
    int? layoutTemplateId,
  }) async {
    final format = receiptPaperFormatFromString(receipt.data.paperFormat);
    if (format.isThermal) return _buildThermalPdf(receipt, format);

    final id = layoutTemplateId ?? 1;
    if (id == 1) return _buildExecutivePdf(receipt);
    final data = await receiptToPdfData(receipt.data);
    final bytes = await styled.buildStyledDocument(data, id);
    return Uint8List.fromList(bytes);
  }

  static PdfPageFormat _thermalPageFormat(ReceiptPaperFormat format) {
    final widthPt = format.widthMm * PdfPageFormat.mm;
    final marginPt = 3 * PdfPageFormat.mm;
    return PdfPageFormat(
      widthPt,
      1400 * PdfPageFormat.mm,
      marginLeft: marginPt,
      marginTop: marginPt,
      marginRight: marginPt,
      marginBottom: marginPt,
    );
  }

  // ── PDF builder: Thermal (58mm / 80mm roll) — UNCHANGED, no signature
  // block on thermal receipts.
  Future<Uint8List> _buildThermalPdf(
    SavedReceipt receipt,
    ReceiptPaperFormat format,
  ) async {
    final pdf = pw.Document();
    final d   = receipt.data;
    final sym = _currencyPrefix(d);
    final gap = d.compactThermalLayout ? 3.0 : 7.0;

    final subtotal       = d.subtotal;
    final discountAmount = d.discountAmount;
    final taxAmount      = d.taxAmount;
    final amountPaid     = d.amountPaid;

    final hasCustomer = d.showCustomerDetails &&
        (d.clientName.isNotEmpty ||
            d.clientEmail.isNotEmpty ||
            d.clientPhone.isNotEmpty ||
            d.clientAddress.isNotEmpty);

    final hasLogo =
        d.showLogo && d.businessLogoPath != null && d.businessLogoPath!.isNotEmpty;
    final hasSocial = d.showFacebook || d.showInstagram || d.showTwitter;

    pw.MemoryImage? logoImage;
    if (hasLogo) {
      final f = File(d.businessLogoPath!);
      if (await f.exists()) {
        logoImage = pw.MemoryImage(await f.readAsBytes());
      }
    }

    final logoHeight = d.businessLogoDisplaySize.clamp(20.0, 120.0);

    pdf.addPage(
      pw.Page(
        pageFormat: _thermalPageFormat(format),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (logoImage != null)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(logoImage, height: logoHeight, fit: pw.BoxFit.contain),
                ),
              ),
            if (d.businessName.isNotEmpty)
              pw.Text(d.businessName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            if (d.showBusinessDetails) ...[
              if (d.businessAddress.isNotEmpty)
                pw.Text(d.businessAddress,
                    textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              if (d.businessPhone.isNotEmpty)
                pw.Text('Ph: ${d.businessPhone}',
                    textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              if (d.businessEmail.isNotEmpty)
                pw.Text('Email: ${d.businessEmail}',
                    textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              if (d.taxId.isNotEmpty)
                pw.Text('Tax ID: ${d.taxId}',
                    textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
            ],
            pw.SizedBox(height: gap),
            _thermalDivider(),
            pw.SizedBox(height: gap),

            pw.Text('RECEIPT',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: gap),

            if (d.showReceiptNumber && d.receiptNumber.isNotEmpty)
              _thermalMetaRow('Receipt No:', d.receiptNumber),
            if (d.showDateTime && d.paymentDate.isNotEmpty)
              _thermalMetaRow('Date:', d.paymentDate),
            if (d.showCashierName && d.cashierName.isNotEmpty)
              _thermalMetaRow('Cashier:', d.cashierName),
            if (d.posId.isNotEmpty) _thermalMetaRow('POS ID:', d.posId),
            pw.SizedBox(height: 2),
            _thermalDivider(),
            pw.SizedBox(height: gap),

            pw.Row(
              children: [
                pw.Expanded(
                    flex: 5,
                    child: pw.Text('Item',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Qty',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(
                    flex: 3,
                    child: pw.Text('Price',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
              ],
            ),
            pw.SizedBox(height: 3),
            ...d.lineItems.expand((item) => [
                  pw.Row(
                    children: [
                      pw.Expanded(
                          flex: 5,
                          child: pw.Text(item.description,
                              style: const pw.TextStyle(fontSize: 8))),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.quantity % 1 == 0
                              ? item.quantity.toInt().toString()
                              : item.quantity.toStringAsFixed(2),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text('$sym${item.lineNetTotal.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: gap),
                ]),
            _thermalDivider(),
            pw.SizedBox(height: gap),

            _thermalMetaRow('Subtotal', '$sym${subtotal.toStringAsFixed(2)}'),
            if (d.showDiscountLine && d.discountEnabled && d.discountRate > 0)
              _thermalMetaRow(
                  '${d.discountName.trim().isEmpty ? 'Discount' : d.discountName.trim()} (${_fmtPct(d.discountRate)}%)',
                  '-$sym${discountAmount.toStringAsFixed(2)}'),
            if (d.showTaxLine && d.taxEnabled && d.taxRate > 0)
              _thermalMetaRow(
                  '${d.taxName.trim().isEmpty ? 'Tax' : d.taxName.trim()} (${_fmtPct(d.taxRate)}%)',
                  '$sym${taxAmount.toStringAsFixed(2)}'),
            for (final entry in d.itemTaxExtraByName.entries)
              if (entry.value != 0)
                _thermalMetaRow(
                    entry.key.isEmpty ? 'Item Tax' : 'Item Tax (${entry.key})',
                    '${entry.value >= 0 ? '' : '-'}$sym${entry.value.abs().toStringAsFixed(2)}'),
            for (final entry in d.itemDiscountExtraByName.entries)
              if (entry.value > 0)
                _thermalMetaRow(
                    entry.key.isEmpty ? 'Item Discounts' : 'Item Discounts (${entry.key})',
                    '-$sym${entry.value.toStringAsFixed(2)}'),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('$sym${amountPaid.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),

            if (d.showPaymentMethod) ...[
              pw.SizedBox(height: gap),
              _thermalDivider(),
              pw.SizedBox(height: gap),
              pw.Text('Payment Method:',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              _thermalMetaRow(
                  _paymentMethodLabel(d.paymentMethod), '$sym${amountPaid.toStringAsFixed(2)}'),
              if (d.paymentReference.isNotEmpty)
                _thermalMetaRow('Reference:', d.paymentReference),
              if (d.authCode.isNotEmpty) _thermalMetaRow('Auth Code:', d.authCode),
              if (d.cardLast4.isNotEmpty)
                _thermalMetaRow('Card:', '**** **** **** ${d.cardLast4}'),
            ],

            if (hasCustomer) ...[
              pw.SizedBox(height: gap),
              _thermalDivider(),
              pw.SizedBox(height: gap),
              pw.Text('Customer:',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              if (d.clientName.isNotEmpty)
                pw.Text(d.clientName, style: const pw.TextStyle(fontSize: 8)),
              if (d.clientEmail.isNotEmpty)
                pw.Text(d.clientEmail, style: const pw.TextStyle(fontSize: 8)),
              if (d.clientPhone.isNotEmpty)
                pw.Text(d.clientPhone, style: const pw.TextStyle(fontSize: 8)),
              if (d.clientAddress.isNotEmpty)
                pw.Text(d.clientAddress, style: const pw.TextStyle(fontSize: 8)),
            ],

            if (d.showBarcode || d.showQrCode) ...[
              pw.SizedBox(height: 12),
              pw.Builder(builder: (ctx2) {
                final codeValue = d.qrData.isNotEmpty
                    ? d.qrData
                    : (d.receiptNumber.isNotEmpty ? d.receiptNumber : 'RECEIPT');
                return pw.Column(
                  children: [
                    if (d.showBarcode)
                      pw.Center(
                        child: pw.BarcodeWidget(
                          barcode: bc.Barcode.code128(),
                          data: codeValue,
                          width: 130,
                          height: 42,
                          drawText: true,
                          textStyle: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                    if (d.showQrCode)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 10),
                        child: pw.Center(
                          child: pw.BarcodeWidget(
                            barcode: bc.Barcode.qrCode(),
                            data: codeValue,
                            width: 84,
                            height: 84,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],

            pw.SizedBox(height: 14),
            if (d.notes.isNotEmpty) ...[
              pw.Text(d.notes,
                  textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
            ],
            if (d.footerMessage.isNotEmpty)
              pw.Text(d.footerMessage,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),

            if (hasSocial) ...[
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    if (d.showFacebook) ...[
                      _socialBadge('f'),
                      pw.SizedBox(width: 8),
                    ],
                    if (d.showInstagram) ...[
                      _socialBadge('IG'),
                      pw.SizedBox(width: 8),
                    ],
                    if (d.showTwitter) _socialBadge('X'),
                  ],
                ),
              ),
            ],

            if (d.showWebsite && d.businessWebsite.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(d.businessWebsite,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _socialBadge(String label) => pw.Container(
        width: 20,
        height: 20,
        decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle),
        alignment: pw.Alignment.center,
        child: pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
      );

  static String _legacySymbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'NZD': return 'NZ\$';
      case 'AUD': return 'A\$';
      case 'CAD': return 'C\$';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      default:    return '';
    }
  }

  static String _currencyPrefix(ReceiptData d) {
    final code = d.currency.trim().toUpperCase();
    final customSymbol = d.currencySymbol.trim();
    final symbol = customSymbol.isNotEmpty ? customSymbol : _legacySymbolFor(code);

    switch (d.currencyDisplayMode) {
      case 'symbol':
        if (symbol.isNotEmpty) return symbol;
        return code.isNotEmpty ? '$code ' : '';
      case 'both':
        if (code.isNotEmpty && symbol.isNotEmpty) return '$code $symbol';
        if (symbol.isNotEmpty) return symbol;
        return code.isNotEmpty ? '$code ' : '';
      case 'code':
      default:
        if (code.isNotEmpty) return '$code ';
        return symbol;
    }
  }

  static pw.Widget _thermalDivider() => pw.Text(
        '- - - - - - - - - - - - - - - - - - - -',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      );

  static pw.Widget _thermalMetaRow(String label, String value) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Flexible(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
          ),
        ],
      );

  // OFFLINE SIGNATURE FONT PARITY PASS: maps one of
  // executive_invoice_payment_terms_signature.dart's kSignatureFonts to
  // its locally-bundled .ttf asset (see pubspec.yaml's
  // assets/signature_fonts/ entries), loaded via rootBundle +
  // pw.Font.ttf — exactly like invoice_pdf_extra_sections.dart's and
  // quote_pdf_service.dart's _pdfSignatureFont(). Returns null for ''
  // (no family chosen) or an unrecognized name, so the caller falls
  // back to the original bold-italic pw.TextStyle look. No network
  // involved at all, unlike the old PdfGoogleFonts.xRegular() calls
  // this replaces.
  static Future<pw.Font?> _pdfSignatureFont(String family) async {
    const assetMap = {
      'Dancing Script': 'assets/signature_fonts/DancingScript-Regular.ttf',
      'Great Vibes': 'assets/signature_fonts/GreatVibes-Regular.ttf',
      'Sacramento': 'assets/signature_fonts/Sacramento-Regular.ttf',
      'Pacifico': 'assets/signature_fonts/Pacifico-Regular.ttf',
      'Alex Brush': 'assets/signature_fonts/AlexBrush-Regular.ttf',
      'Caveat': 'assets/signature_fonts/Caveat-Regular.ttf',
    };
    final path = assetMap[family.trim()];
    if (path == null) return null;
    final data = await rootBundle.load(path);
    return pw.Font.ttf(data);
  }

  // SIGNATURE LINE WIDTH PDF PARITY PASS: measures a string against the
  // actual pw.Font about to draw it, via the pdf package's own
  // PdfFont.stringMetrics() — the same primitive pw.Text uses internally
  // to lay text out. Multiplying by fontSize (via PdfFontMetrics' own
  // `*` operator) converts the font's normalized glyph widths into
  // actual point widths at the size being rendered. Falls back to the
  // built-in Helvetica-BoldOblique font when no bundled signature font
  // resolved (font == null) — the closest built-in match to the
  // fallback bold-italic pw.TextStyle used in that case.
  static double _measureSignatureWidth(String text, pw.Font? font, double fontSize) {
    final measuringFont = font ?? pw.Font.helveticaBoldOblique();
    final metrics = measuringFont.stringMetrics(text) * fontSize;
    return metrics.width;
  }

  // SIGNATURE PASS: mirrors invoice_pdf_extra_sections.dart's
  // buildPdfSignatureBlock / quote_pdf_service.dart's
  // _buildQuoteSignatureBlock exactly (three modes + deselected ''),
  // built directly against ReceiptData, gated by showSignature (A4-only
  // — never called from _buildThermalPdf above).
  static Future<pw.Widget> _buildReceiptSignatureBlock(ReceiptData d) async {
    if (!d.showSignature) return pw.SizedBox();
    if (d.signatureMode.trim().isEmpty) return pw.SizedBox();

    // SIGNATURE LINE WIDTH PDF PARITY PASS: line() now takes an optional
    // width, defaulting to the original fixed 160pt — 'image' and
    // 'blank' modes below still call line() with no argument, only
    // 'typed' passes a measured width. Mirrors the Flutter side's
    // line({double width = 160}) exactly.
    pw.Widget line({double width = 160}) =>
        pw.Container(width: width, height: 0.75, color: PdfColors.grey500);

    pw.Widget content;
    switch (d.signatureMode) {
      case 'image':
        pw.MemoryImage? img;
        final path = d.signatureImagePath;
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (await f.exists()) img = pw.MemoryImage(await f.readAsBytes());
        }
        content = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              height: 40,
              child: img != null
                  ? pw.Image(img, fit: pw.BoxFit.contain, alignment: pw.Alignment.bottomLeft)
                  : pw.SizedBox(),
            ),
            pw.SizedBox(height: 4),
            line(),
          ],
        );
        break;
      case 'typed':
        final name = d.signatureName.trim();
        final pdfFont = await _pdfSignatureFont(d.signatureFontFamily);
        // NOTE: fallback fontSize is hardcoded 20 here (pre-existing,
        // unrelated to this fix) — not d.signatureFontSize the way the
        // Flutter fallback uses. Measurement below uses whichever size
        // is actually applied so the line still matches.
        final effectiveFontSize = pdfFont != null ? d.signatureFontSize : 20.0;
        final style = pdfFont != null
            ? pw.TextStyle(font: pdfFont, fontSize: d.signatureFontSize)
            : pw.TextStyle(
                fontSize: 20,
                fontStyle: pw.FontStyle.italic,
                fontWeight: pw.FontWeight.bold,
              );
        // SIGNATURE LINE WIDTH PDF PARITY PASS: measured against the
        // actual font/size about to be drawn, clamped to the same
        // [70, 220] range the Flutter preview uses.
        final lineWidth = name.isEmpty
            ? 70.0
            : _measureSignatureWidth(name, pdfFont, effectiveFontSize).clamp(70.0, 220.0);
        content = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              height: 40,
              child: pw.Align(
                alignment: pw.Alignment.bottomLeft,
                child: pw.Text(name.isEmpty ? ' ' : name, style: style),
              ),
            ),
            pw.SizedBox(height: 4),
            line(width: lineWidth),
          ],
        );
        break;
      case 'blank':
      default:
        content = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [pw.SizedBox(height: 40), line()],
        );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          content,
          pw.SizedBox(height: 4),
          pw.Text('Authorized Signature',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  // ── PDF builder: Executive (layout id 1) ────────────────────────────────────

  Future<Uint8List> _buildExecutivePdf(SavedReceipt receipt) async {
    final pdf   = pw.Document();
    final d     = receipt.data;
    final color = _pdfColor(d.colorScheme);

    final subtotal       = d.subtotal;
    final discountAmount = d.discountAmount;
    final taxAmount      = d.taxAmount;
    final amountPaid     = d.amountPaid;

    pw.MemoryImage? logoImage;
    final logoPath = d.businessLogoPath;
    if (d.showLogo && logoPath != null && logoPath.isNotEmpty) {
      final f = File(logoPath);
      if (await f.exists()) {
        logoImage = pw.MemoryImage(await f.readAsBytes());
      }
    }

    final hasCustomer = d.showCustomerDetails &&
        (d.clientName.isNotEmpty ||
            d.clientEmail.isNotEmpty ||
            d.clientPhone.isNotEmpty ||
            d.clientAddress.isNotEmpty);

    // SIGNATURE PASS: built up front, same reasoning as
    // quote_pdf_service.dart's identical treatment.
    final signatureBlock = await _buildReceiptSignatureBlock(d);

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
                      if (d.showBusinessDetails && d.businessEmail.isNotEmpty)
                        pw.Text(d.businessEmail,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
                      if (d.showBusinessDetails && d.businessPhone.isNotEmpty)
                        pw.Text(d.businessPhone,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
                      if (d.showBusinessDetails && d.businessAddress.isNotEmpty)
                        pw.Text(d.businessAddress,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                    if (d.showReceiptNumber && d.receiptNumber.isNotEmpty)
                      pw.Text('#${d.receiptNumber}',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.white)),
                    if (d.showDateTime && d.paymentDate.isNotEmpty)
                      pw.Text(d.paymentDate,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    if (d.showPaymentMethod)
                      pw.Text('Paid via: ${_paymentMethodLabel(d.paymentMethod)}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    if (d.showCashierName && d.cashierName.isNotEmpty)
                      pw.Text('Cashier: ${d.cashierName}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Received From ─────────────────────────────────────────────
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
                  pw.Text('RECEIVED FROM',
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
                    _td(_fmtMoney(d, item.lineNetTotal), align: pw.TextAlign.right),
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
                  if (d.showTaxLine && d.taxEnabled && d.taxRate > 0)
                    _totalRow(
                        '${d.taxName.trim().isEmpty ? 'Tax' : d.taxName.trim()} (${_fmtPct(d.taxRate)}%)',
                        '+${_fmtMoney(d, taxAmount)}'),
                  if (d.showDiscountLine && d.discountEnabled && d.discountRate > 0)
                    _totalRow(
                        '${d.discountName.trim().isEmpty ? 'Discount' : d.discountName.trim()} (${_fmtPct(d.discountRate)}%)',
                        '-${_fmtMoney(d, discountAmount)}'),
                  for (final entry in d.itemTaxExtraByName.entries)
                    if (entry.value != 0)
                      _totalRow(
                          entry.key.isEmpty ? 'Item Tax' : 'Item Tax (${entry.key})',
                          '${entry.value >= 0 ? '+' : '-'}${_fmtMoney(d, entry.value.abs())}'),
                  for (final entry in d.itemDiscountExtraByName.entries)
                    if (entry.value > 0)
                      _totalRow(
                          entry.key.isEmpty ? 'Item Discounts' : 'Item Discounts (${entry.key})',
                          '-${_fmtMoney(d, entry.value)}'),
                  pw.Divider(color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('AMOUNT PAID',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text(_fmtMoney(d, amountPaid),
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
            pw.Text('Notes',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: color)),
            pw.SizedBox(height: 4),
            pw.Text(d.notes, style: const pw.TextStyle(fontSize: 10)),
          ],

          // SIGNATURE PASS: new — rendered last, after Notes.
          signatureBlock,
        ],
      ),
    );

    return pdf.save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  PdfColor _pdfColor(ReceiptColor c) {
    switch (c) {
      case ReceiptColor.blue:   return PdfColors.blue800;
      case ReceiptColor.green:  return PdfColors.green800;
      case ReceiptColor.purple: return PdfColors.purple800;
      case ReceiptColor.orange: return PdfColors.orange800;
      case ReceiptColor.red:    return PdfColors.red800;
      case ReceiptColor.teal:   return PdfColors.teal800;
      case ReceiptColor.black:  return PdfColors.grey900;
      case ReceiptColor.indigo: return PdfColors.indigo800;
    }
  }

  static String _paymentMethodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:         return 'Cash';
      case PaymentMethod.card:         return 'Card';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
      case PaymentMethod.other:        return 'Other';
    }
  }

  static pw.Widget _executiveLogoWidget(pw.MemoryImage logoImage, String logoShape, {double size = 64}) {
    final radius = switch (logoShape) {
      'circle' => size / 2,
      'square' => 0.0,
      _ => size * 0.22,
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

  static String _fmtMoney(ReceiptData d, double v) {
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