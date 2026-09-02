// lib/services/receipt_pdf_service.dart
//
// HISTORY LOGGING PASS (this update): generateAndSharePDF and
// printReceipt now accept an optional [historyProvider], mirroring
// invoice_pdf_service.dart's own HISTORY LOGGING PASS. Share logs a
// `shared` event with the shared file attached (Share.shareXFiles
// doesn't return a path, so this is the only place that can attach the
// real file); print logs a `printed` event (no file attached — printing
// doesn't produce a reusable artifact the way share/download do).
// Omitted (null) is a no-op on both.
//
// FIELD VISIBILITY PASS (earlier update): _buildExecutivePdf (the A4 export
// path) now checks the same pre-existing ReceiptData show* toggles the
// thermal export (_buildThermalPdf, below) already checked — showLogo,
// showBusinessDetails, showReceiptNumber, showDateTime,
// showPaymentMethod, showCustomerDetails, showTaxLine, showDiscountLine.
// Previously this builder rendered every one of those unconditionally,
// so an A4 receipt saved with e.g. showTaxLine = false would still print
// its tax line in the actual downloaded/shared PDF even though the
// toggle existed, was persisted, and already worked correctly for
// thermal receipts. Matches the identical fix just applied to the A4
// live-preview/edit-canvas layout in
// executive_receipt_stationary_layout.dart — see that file's header
// comment for the fuller rationale.
//
// FIELD VERIFICATION PASS (earlier): cross-checked every ReceiptData
// field reference in this file against the real receipt_data.dart model,
// InvoiceData/QuoteData for consistency, and pdf_doc_adapter.dart for the
// styled-template path -- confirmed clean, no drift. Also fixed a stale
// doc comment on printReceipt() that still described the thermal PDF
// builder as not-yet-existing ("a place to branch once a real
// thermal-width PDF builder exists") even though _buildThermalPdf() was
// added and wired into _buildPdf() in an earlier pass. No functional
// changes in this pass -- comment-only fix, confirming existing behaviour
// is correct.
//
// STRUCTURAL SANITY PASS (earlier): cross-checked every ReceiptData
// field reference in this file against the real receipt_data.dart model
// -- all ~15 flagged fields (showLogo, compactThermalLayout, cashierName,
// posId, taxId, paymentReference, authCode, cardLast4, showDiscountLine,
// showTaxLine, showPaymentMethod, showCustomerDetails,
// businessLogoDisplaySize, businessLogoShape, showFacebook/Instagram/
// Twitter, showWebsite, businessWebsite, qrData) exist with matching
// types, and the ReceiptColor/PaymentMethod switches in _pdfColor /
// _paymentMethodLabel are exhaustive against the real enums. The only
// change made here: _thermalPageFormat() used PdfPageFormat(...,
// marginAll: ...), which isn't guaranteed to exist on the constructor
// across every pdf-package version -- swapped for the four explicit
// marginLeft/Top/Right/Bottom params, which are guaranteed stable. No
// behavioural change, just removes a version-dependent risk.
//
// THERMAL PDF PASS (earlier): _buildPdf now branches on
// receiptPaperFormatFromString(d.paperFormat).isThermal. Thermal formats
// (58mm/80mm) route to the new _buildThermalPdf(), which renders a
// dedicated narrow-roll layout at the real physical width from
// receipt_paper_format.dart's widthMm — NOT the Executive/styled A4
// layouts, which assume fixed A4-proportioned elements and would not fit
// or read correctly on a 58/80mm roll. A4 format is unchanged and still
// goes through _buildExecutivePdf / styled.buildStyledDocument as before.
// This applies uniformly to generateAndDownloadPDF, generateAndSharePDF,
// generatePdfBytes, and printReceipt, so a thermal-format receipt renders
// as an actual narrow-roll document everywhere, not just when printing.
//
// NOTE: this thermal layout is a standard functional receipt design
// (centered header, dashed dividers, item list, totals, footer) built
// from ReceiptData directly — it has not been visually matched against
// ThermalReceiptLivePreview (the on-screen thermal preview widget), which
// wasn't available when this was written. If the live preview's exact
// styling needs to match the printed/exported thermal PDF, send that
// file and this can be aligned to it.
//
// PRINT ACTION PASS (earlier): added printReceipt(), routed through
// the `printing` package's Printing.layoutPdf(), which opens the OS print
// dialog (and on most platforms lets the user pick a connected printer,
// including thermal/POS printers over Bluetooth/USB where the OS driver
// supports it). Reuses the existing _buildPdf dispatcher for the actual
// document bytes — same Executive/styled-template/thermal logic as
// generateAndDownloadPDF / generateAndSharePDF above. The print dialog's
// page format is also set to match (A4 vs the real thermal roll width),
// not left at the printing package's default.
//
// LOGO PARITY PASS (earlier): mirrors invoice_pdf_service.dart's own
// LOGO PARITY PASS exactly — the Executive builder's logo was hardcoded
// to pw.ClipOval on a solid white background regardless of what LogoShape
// the user actually picked via the Logo Sizer. Now clips to the real
// shape (circle/square/roundedSquare, mirroring LogoShape.radiusFor() on
// the Flutter side) and sits on a very light neutral background with
// BoxFit.contain, matching pdf_templates.dart's _logoWidget (used by
// styles 2-10 for receipts too, via buildStyledDocument) and the
// Flutter-side DocLogoAvatar's own contain-fit treatment.
//
// CURRENCY DISPLAY PASS (earlier): _fmtMoney(d, v) uses ReceiptData's own
// currency/currencySymbol/currencyDisplayMode fields directly — mirrors
// DocTemplateAdapter.fmtMoney() (Flutter preview side) and
// PdfDocData.fmtMoney() (styled-template path), so exported PDFs respect
// whatever the user actually typed for currency symbol/format.
//
// REWRITE: built directly against the real ReceiptData model (flat
// fields: businessName, businessEmail, clientName, lineItems, etc.), same
// as invoice_pdf_service.dart's own rewrite — see that file's header
// comment for the full rationale, which applies identically here. Total
// is amountPaid rather than grandTotal (receipts record what was actually
// paid, mirroring ReceiptData's own field), and the meta row shows
// payment date + payment method rather than issue/due dates.
//
// Layout dispatcher: layoutTemplateId selects the visual style (1 =
// Executive, built directly below; 2-10 route through
// pdf_templates.dart's buildStyledDocument, shared with invoice/quote).

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:barcode/barcode.dart' as bc;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../create_receipt/receipt_paper_format.dart';
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

  /// [historyProvider], when passed, logs a `shared` History event with
  /// the shared file attached as sourceFile — mirrors
  /// invoice_pdf_service.dart's identical treatment. Omitted (null) is a
  /// no-op, so every existing call site behaves exactly as before.
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

  /// Opens the OS print dialog for this receipt via the `printing`
  /// package. [paperFormat] lets callers (receipt_full_preview_screen.dart)
  /// override the format explicitly; when omitted, falls back to
  /// receipt.data.paperFormat. Routes through the same _buildPdf
  /// dispatcher as generateAndDownloadPDF/generateAndSharePDF, so a
  /// thermal-format receipt gets the real _buildThermalPdf narrow-roll
  /// layout here too, not the A4 Executive/styled layouts — and the print
  /// dialog's page format below is set to match (real thermal roll width
  /// vs A4), not left at the printing package's default.
  /// [historyProvider], when passed, logs a `printed` History event —
  /// no file attached, since printing doesn't leave behind a reusable
  /// artifact the way share/download do.
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

  // STRUCTURAL SANITY PASS: previously used PdfPageFormat(..., marginAll:
  // ...), which isn't guaranteed to exist on the constructor across every
  // pdf-package version. Swapped for the four explicit margin params,
  // which are stable across versions -- same 3mm margin on all sides,
  // just spelled out instead of relying on a convenience param.
  static PdfPageFormat _thermalPageFormat(ReceiptPaperFormat format) {
    final widthPt = format.widthMm * PdfPageFormat.mm;
    final marginPt = 3 * PdfPageFormat.mm;
    // Thermal rolls are continuous-feed, not a fixed page height — a tall
    // page keeps the printed content on one continuous strip rather than
    // paginating like an A4 document would.
    return PdfPageFormat(
      widthPt,
      1400 * PdfPageFormat.mm,
      marginLeft: marginPt,
      marginTop: marginPt,
      marginRight: marginPt,
      marginBottom: marginPt,
    );
  }

  // ── PDF builder: Thermal (58mm / 80mm roll) ─────────────────────────────────
  //
  // Mirrors ThermalReceiptLivePreview (receipt_thermal_live_preview.dart)
  // field-for-field: same show*/compactThermalLayout toggles, same meta
  // rows (receipt #, date, cashier, POS ID), same payment-method detail
  // rows, same barcode/QR handling (real scannable codes keyed off
  // qrData, falling back to receiptNumber), same footer (notes, footer
  // message, social badges, website). Deliberately separate from
  // _buildExecutivePdf — A4's two-column header and boxed cards don't fit
  // a 48-72mm printable width.
  //
  // Known gap vs. the live preview: the on-screen logo renders through a
  // grayscale ColorFilter (forcing black & white for a monochrome
  // thermal look) — the `pdf` package widgets used here don't expose an
  // equivalent color-matrix filter, so the logo prints in its original
  // colors instead. Everything else follows the same toggles/data.
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
            // ── Business header ─────────────────────────────────────
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

            // ── Meta ──────────────────────────────────────────────────
            if (d.showReceiptNumber && d.receiptNumber.isNotEmpty)
              _thermalMetaRow('Receipt No:', d.receiptNumber),
            if (d.showDateTime && d.paymentDate.isNotEmpty)
              _thermalMetaRow('Date:', d.paymentDate),
            if (d.cashierName.isNotEmpty) _thermalMetaRow('Cashier:', d.cashierName),
            if (d.posId.isNotEmpty) _thermalMetaRow('POS ID:', d.posId),
            pw.SizedBox(height: 2),
            _thermalDivider(),
            pw.SizedBox(height: gap),

            // ── Items ─────────────────────────────────────────────────
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
                        child: pw.Text('$sym${item.total.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: gap),
                ]),
            _thermalDivider(),
            pw.SizedBox(height: gap),

            // ── Totals ────────────────────────────────────────────────
            _thermalMetaRow('Subtotal', '$sym${subtotal.toStringAsFixed(2)}'),
            if (d.showDiscountLine && d.discountRate > 0)
              _thermalMetaRow('Discount (${_fmtPct(d.discountRate)}%)',
                  '-$sym${discountAmount.toStringAsFixed(2)}'),
            if (d.showTaxLine && d.taxRate > 0)
              _thermalMetaRow(
                  'Tax (${_fmtPct(d.taxRate)}%)', '$sym${taxAmount.toStringAsFixed(2)}'),
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

            // ── Payment ───────────────────────────────────────────────
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

            // ── Customer ──────────────────────────────────────────────
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

            // ── Barcode / QR — real scannable codes, same value logic as
            // the live preview: qrData if set, else the receipt number.
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

            // ── Footer ────────────────────────────────────────────────
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

  /// Small filled-circle badge with a letter/initials label, standing in
  /// for the live preview's FontAwesome social icons — the `pdf` package
  /// doesn't have a FontAwesome equivalent available here, so this uses
  /// plain text glyphs on a black circle instead of the actual brand
  /// icons the live preview shows.
  static pw.Widget _socialBadge(String label) => pw.Container(
        width: 20,
        height: 20,
        decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle),
        alignment: pw.Alignment.center,
        child: pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
      );

  /// Legacy hardcoded code -> symbol lookup, mirrored from
  /// receipt_thermal_live_preview.dart's identical helper — used as a
  /// fallback for 'symbol'/'both' display modes when currencySymbol
  /// hasn't been explicitly set.
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

  /// Mirrors ThermalReceiptLivePreview._currencyPrefix exactly, so the
  /// thermal PDF's amount prefixes match what the live preview shows.
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

  // ── PDF builder: Executive (layout id 1) ────────────────────────────────────
  //
  // FIELD VISIBILITY PASS: this A4 builder now gates on the same show*
  // toggles as the thermal builder above and the live A4 preview
  // (executive_receipt_stationary_layout.dart) — see this file's
  // top-of-file header comment for the full rationale.

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
                  if (d.showTaxLine && d.taxRate > 0)
                    _totalRow('Tax (${_fmtPct(d.taxRate)}%)',
                        '+${_fmtMoney(d, taxAmount)}'),
                  if (d.showDiscountLine && d.discountRate > 0)
                    _totalRow('Discount (${_fmtPct(d.discountRate)}%)',
                        '-${_fmtMoney(d, discountAmount)}'),
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

  /// Formats money using ReceiptData's own currency/currencySymbol/
  /// currencyDisplayMode fields — mirrors invoice_pdf_service.dart's
  /// identical helper exactly.
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