// lib/services/invoice_pdf_service.dart
//
// PRINT ACTION PASS (this update): added printInvoice(), mirroring
// ReceiptPdfService.printReceipt() exactly — builds the same PDF bytes
// _buildPdf() already produces for Download/Share, then hands them to
// Printing.layoutPdf() so the OS print dialog opens directly (a
// connected office/POS printer can be used without going through
// Download -> open file -> print). Always PdfPageFormat.a4 — Invoice
// has no thermal/paper-format concept the way Receipt does, so there's
// no format branch here. Optional [historyProvider] logs a `printed`
// History event on success, same pattern as generateAndSharePDF's
// [historyProvider] param elsewhere in this file. Wired up by
// invoice_full_preview_screen.dart's new Print button
// (invoice_preview_bottom_bar.dart), matching Receipt's identical
// button.
//
// BODY FONT FAMILY PDF PASS (earlier): _buildExecutivePdf() never
// referenced InvoiceData.fontFamily anywhere — every pw.TextStyle in
// this file was built with no `font:` parameter at all, so the
// exported PDF always ignored the Customise step's "Font Family"
// selection, even for a plain body font like Roboto or Lato that
// resolves correctly in the live Flutter preview
// (executive_invoice_stationary_layout.dart). Root cause is the same
// shape as the earlier SIGNATURE FONT FAMILY PASS fix: the pdf/widgets
// package doesn't know about Flutter's pubspec.yaml-registered fonts at
// all — it needs its own pw.Font loaded explicitly.
//
// Fix: _pdfBodyFont() maps d.fontFamily to the SAME local .ttf asset
// pubspec.yaml already bundles for the Flutter side (no new assets
// needed — these were already shipped for the live preview/other body
// text), loaded via rootBundle + pw.Font.ttf(). The loaded font is set
// as the PDF's default theme (pw.ThemeData.withFont(base: ..., bold:
// ...)) when building the pw.Document, so every pw.Text in the tree
// below picks it up automatically without touching each individual
// TextStyle call site. 'Default' (the sentinel that deliberately
// matches no registered family) and any unrecognized string return
// null, leaving the pdf package's own built-in default font — same
// "empty/unrecognized means unchanged" rule the signature font fix
// uses.
//
// NOTE: the bundled body fonts only include a Regular weight (no bold
// .ttf shipped in pubspec.yaml) — pdf/widgets can't synthesize bold the
// way Flutter's Text widget can, so bold text (headings, totals, table
// header) will render in the chosen family but not visibly bolder.
// That's a font-file limitation, not a bug; if true bold weights are
// wanted later, bundle a matching *-Bold.ttf per family and load it as
// the theme's `bold:` font instead of reusing the regular one.
//
// This fix only covers the Executive layout (id 1, this file). The
// other 9 template styles route through pdf_templates.dart via
// styled.buildStyledDocument() — a separate file not covered here.
//
// STRUCTURED ADDRESS PDF RENDER PASS (earlier): the header's business
// address block and the Bill To panel's client address block now render
// InvoiceData.businessAddressInfo/clientAddressInfo (the six-field
// AddressInfo, see invoice_data.dart's STRUCTURED ADDRESS PASS and
// address_info.dart's formattedLines getter) as one pw.Text per postal
// line, instead of the single flat businessAddress/clientAddress string
// wrapping as one paragraph. New _addressLines() helper builds the list
// of pw.Text widgets for either block, falling back to the flat string
// when the structured AddressInfo is empty (a template/customer saved
// before this pass existed and never had its AddressInfo populated) so
// older data still exports something sensible. Nothing else in either
// block changed.
//
// LINE ITEM TOTAL + GST/TAX BREAKDOWN PDF FIX (earlier): this file
// is a separate pw.Widget implementation from the Flutter preview
// (executive_invoice_stationary_layout.dart) — Material widgets can't be
// handed to the pdf/printing packages — so the earlier LINE NET TOTAL
// FIX applied there never reached the actual exported PDF. Two changes:
//   1. The line-item table's Total column now applies that row's own
//      discount/tax the same way LineItem.lineNetTotal does (item.total
//      minus its discount amount, plus/minus its signed tax amount),
//      instead of the plain qty × price base figure.
//   2. The totals block now also loops over InvoiceData's
//      itemDiscountExtraByName / itemTaxExtraByName maps — same source
//      the Flutter footer already reads — to render "Item Discounts
//      (name)" / "Item Tax (name)" rows (GST, VAT, withholding, etc.)
//      beneath the existing flat document-level Tax/Discount rows.
//      Signed the same way: a withholding-style tax renders with a
//      minus sign instead of always being added.
// Nothing else in this file changed.
//
// PAYMENT INFO / TERMS & SIGNATURE PDF RENDER PASS (earlier): the
// same fields executive_invoice_stationary_layout.dart's live preview
// now renders are rendered here too, so the exported PDF actually
// matches what the preview shows. PO / Reference Number is added to the
// header meta column (below Due Date). Bank Name/Account Name/Account
// Number/Other Payment Details/Payment Terms, Terms & Conditions, and
// the Signature block (image/typed/blank) are built via three new calls
// into invoice_pdf_extra_sections.dart (split out to its own file rather
// than growing this one further) and inserted after the Notes section.
// All gated by the same enabledFields toggles as everything else here,
// so a PDF with none of this set exports exactly as before this pass.
//
// HISTORY LOGGING PASS (earlier): generateAndSharePDF now accepts an
// optional [historyProvider]. Share doesn't return a file path the way
// download does, so this is the one call site where the PDF service
// itself — not the caller — is what actually has the freshly-written
// file in hand. When provided, logs a HistoryEventType.shared event
// (via HistoryProvider.logShared) with the just-shared file as
// sourceFile, so "send again" from the History screen has a real,
// reshare-able copy instead of a metadata-only log entry. Omitted (null)
// is a no-op — every existing call site that doesn't pass it behaves
// exactly as before this pass.
//
// TEMPLATE FIELD VISIBILITY FIX (earlier update): _buildExecutivePdf now
// gates the same fields as the live preview/edit canvas
// (executive_invoice_stationary_layout.dart) behind
// InvoiceData.enabledFields via the _on() helper — business logo/
// name/email/phone/address, invoice number, issue/due dates, Bill To
// block (client name/email/phone/address), tax row, discount row, and
// notes. Previously the exported PDF ignored enabledFields entirely (it
// didn't exist on InvoiceData at all), so toggling a field off in the
// template sheet never affected what actually printed. Missing keys
// default to true, so invoices saved before this field existed still
// export exactly as before.
//
// LOGO PARITY PASS (earlier): the Executive builder's logo was
// already present (unlike the other 9 styles — see pdf_templates.dart's
// own LOGO PARITY PASS for that fix) but hardcoded to pw.ClipOval on a
// solid white background regardless of what LogoShape the user actually
// picked via the Logo Sizer. Now clips to the real shape (circle/square/
// roundedSquare, mirroring LogoShape.radiusFor() on the Flutter side) and
// sits on a very light neutral background with BoxFit.contain, matching
// pdf_templates.dart's _logoWidget and the Flutter-side DocLogoAvatar's
// own contain-fit treatment, so a non-square logo isn't stretched/cropped
// to fill a circle it was never meant to fill.
//
// CURRENCY DISPLAY PASS (earlier): _currencySymbol()'s hardcoded
// switch-based lookup is gone. The Executive builder now uses
// InvoiceData's own currency/currencySymbol/currencyDisplayMode fields
// directly via a small _fmtMoney(d, v) helper (mirrors
// DocTemplateAdapter.fmtMoney() on the Flutter preview side, and
// PdfDocData.fmtMoney() used by the styled-template path below) — so
// exported PDFs respect whatever the user actually typed for currency
// symbol/format, not a fixed 8-currency list.
//
// FOLLOW UP (earlier pass): generateAndSharePDF gained an optional
// [shareText] parameter — a pre-filled message body passed straight
// through to Share.shareXFiles' `text` field. Used by the Alerts screen's
// "Follow Up" action (alerts_screen.dart) to open the OS share sheet with
// a friendly "this invoice is overdue" nudge already typed out, so the
// user just picks email/WhatsApp/SMS and hits send. Omitted (null) for
// every other caller, so normal shares are unchanged from before this
// pass.
//
// REWRITE (earlier pass): threads the visual layout chosen in
// InvoiceTemplateChooserScreen through to PDF generation. `layoutTemplateId`
// is a plain optional parameter on the public methods — deliberately NOT a
// field on SavedInvoice/InvoiceData, so nothing about those models needs to
// change. _buildPdf() is now a small dispatcher; the design that used to be
// the only implementation is renamed to _buildExecutivePdf and is the
// default case, since Executive (id 1) is the only layout actually built.
// Adding template #2 later is: write its own _buildXxxPdf() method, add one
// case to the switch below — no other file in this chain needs to change.
//
// NEW (earlier pass): generatePdfBytes() is a thin public wrapper around the
// existing private _buildPdf() dispatcher — it hands back raw PDF bytes
// without writing a named file to Downloads or a temp dir. Added for
// FolderDownloadService, which bundles several invoices' PDFs into one ZIP
// and needs the bytes in memory rather than a file per invoice already
// written under its own name. generateAndDownloadPDF below is unchanged.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/invoice_data.dart';
import '../models/address_info.dart';
import '../models/history_event.dart' show HistoryDocType;
import '../providers/history_provider.dart';
import 'pdf_doc_adapter.dart';
import 'pdf_templates.dart' as styled;
import 'invoice_pdf_extra_sections.dart';

class InvoicePdfService {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// Generates the PDF, saves it to the Downloads folder, and returns the path.
  /// [layoutTemplateId] selects the visual layout (1 = Executive, the only
  /// one built so far). Null or unrecognized falls back to Executive.
  Future<String> generateAndDownloadPDF(
    SavedInvoice invoice, {
    int? layoutTemplateId,
  }) async {
    final bytes = await _buildPdf(invoice, layoutTemplateId: layoutTemplateId);
    final dir   = await _downloadsDir();
    final file  = File(
        '${dir.path}/Invoice_${invoice.data.invoiceNumber.replaceAll(RegExp(r'[^\w]'), '_')}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Generates the PDF and triggers the OS share sheet.
  /// [shareText] is an optional pre-filled message body (used by the
  /// Alerts screen's "Follow Up" action to prefill a friendly nudge about
  /// this invoice) — omitted entirely for normal shares, unchanged from
  /// before this pass.
  /// [historyProvider], when passed, logs a `shared` History event with
  /// the shared file attached as sourceFile — this is the one place that
  /// can do so, since Share.shareXFiles doesn't hand a path back to the
  /// caller the way the download flow does.
  Future<void> generateAndSharePDF(
    SavedInvoice invoice, {
    int? layoutTemplateId,
    String? shareText,
    HistoryProvider? historyProvider,
  }) async {
    final bytes = await _buildPdf(invoice, layoutTemplateId: layoutTemplateId);
    final dir   = await getTemporaryDirectory();
    final file  = File(
        '${dir.path}/Invoice_${invoice.data.invoiceNumber.replaceAll(RegExp(r'[^\w]'), '_')}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Invoice ${invoice.data.invoiceNumber}',
      text: shareText,
    );
    if (historyProvider != null) {
      final d = invoice.data;
      unawaited(historyProvider.logShared(
        docType: HistoryDocType.invoice,
        docId: invoice.id,
        docNumber: d.invoiceNumber,
        clientName: d.clientName.isEmpty ? null : d.clientName,
        amount: d.grandTotal,
        currency: d.currency,
        sourceFile: file,
      ));
    }
  }

  /// NEW: raw PDF bytes, no file written. Used by FolderDownloadService to
  /// bundle several invoices' PDFs into one ZIP without each one first
  /// landing under its own name in Downloads or a temp dir.
  Future<Uint8List> generatePdfBytes(
    SavedInvoice invoice, {
    int? layoutTemplateId,
  }) {
    return _buildPdf(invoice, layoutTemplateId: layoutTemplateId);
  }

  // PRINT ACTION PASS: builds the same bytes Download/Share already use
  // and hands them straight to the OS print dialog via
  // Printing.layoutPdf() — mirrors ReceiptPdfService.printReceipt()
  // exactly, minus the paper-format branch (Invoice is always A4).
  // [historyProvider], when passed, logs a `printed` History event on
  // success, same shape as generateAndSharePDF's logShared call above.
  Future<void> printInvoice(
    SavedInvoice invoice, {
    int? layoutTemplateId,
    HistoryProvider? historyProvider,
  }) async {
    final bytes = await _buildPdf(invoice, layoutTemplateId: layoutTemplateId);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name:
          'Invoice_${invoice.data.invoiceNumber.replaceAll(RegExp(r'[^\w]'), '_')}.pdf',
      format: PdfPageFormat.a4,
    );
    if (historyProvider != null) {
      final d = invoice.data;
      unawaited(historyProvider.logPrinted(
        docType: HistoryDocType.invoice,
        docId: invoice.id,
        docNumber: d.invoiceNumber,
        clientName: d.clientName.isEmpty ? null : d.clientName,
        amount: d.grandTotal,
        currency: d.currency,
      ));
    }
  }

  // ── Layout dispatcher ───────────────────────────────────────────────────────
  //
  // Add a case here + a new _buildXxxPdf() method for each future layout.
  // Everything below _buildExecutivePdf is unchanged from the original
  // single-layout implementation.
  Future<Uint8List> _buildPdf(
    SavedInvoice invoice, {
    int? layoutTemplateId,
  }) async {
    final id = layoutTemplateId ?? 1;
    if (id == 1) return _buildExecutivePdf(invoice);
    final data = await invoiceToPdfData(invoice.data);
    final bytes = await styled.buildStyledDocument(data, id);
    return Uint8List.fromList(bytes);
  }

  // TEMPLATE FIELD VISIBILITY FIX: single read helper for
  // InvoiceData.enabledFields, mirroring the identical helper in
  // executive_invoice_stationary_layout.dart — missing keys default to
  // true (shown), so this stays correct for invoices saved before this
  // field existed.
  static bool _on(InvoiceData d, String key) => d.enabledFields[key] ?? true;

  // BODY FONT FAMILY PDF PASS: maps InvoiceData.fontFamily (one of
  // step_customise.dart's _kFonts) to the SAME local .ttf asset already
  // bundled in pubspec.yaml for the Flutter side — no new assets, just
  // loading the existing file via rootBundle for pdf/widgets' own
  // pw.Font. Returns null for 'Default' (deliberately unmatched
  // sentinel) or any unrecognized name, so the caller falls back to the
  // pdf package's own built-in font — same "unset/unrecognized means
  // unchanged" rule the signature font fix in
  // invoice_pdf_extra_sections.dart already follows.
  static Future<pw.Font?> _pdfBodyFont(String family) async {
    const base = 'assets/Lato,Lora,Montserrat,Nunito,Open_Sans,etc';
    const assetMap = {
      'Roboto':           '$base/Roboto/static/Roboto-Regular.ttf',
      'Lato':             '$base/Lato/Lato-Regular.ttf',
      'Lora':             '$base/Lora/static/Lora-Regular.ttf',
      'Montserrat':       '$base/Montserrat/static/Montserrat-Regular.ttf',
      'Nunito':           '$base/Nunito/static/Nunito-Regular.ttf',
      'Open Sans':        '$base/Open_Sans/static/OpenSans-Regular.ttf',
      'Playfair Display': '$base/Playfair/static/Playfair_9pt-Regular.ttf',
      'Raleway':          '$base/Raleway/static/Raleway-Regular.ttf',
      'Space Grotesk':    '$base/Space_Grotesk/static/SpaceGrotesk-Regular.ttf',
    };
    final path = assetMap[family.trim()];
    if (path == null) return null;
    final data = await rootBundle.load(path);
    return pw.Font.ttf(data);
  }

  // STRUCTURED ADDRESS PDF RENDER PASS: builds one pw.Text per postal
  // line from an AddressInfo (via its formattedLines getter), falling
  // back to a single pw.Text of the legacy flat string when the
  // structured value is empty — mirrors the Flutter preview's
  // _addressBlock() helper in executive_invoice_stationary_layout.dart.
  // Returns an empty list when there's nothing to show at all, so call
  // sites can spread this straight into a pw.Column's children without
  // an extra null/empty check.
  static List<pw.Widget> _addressLines(
    AddressInfo info,
    String legacyFlat,
    pw.TextStyle style,
  ) {
    if (info.isNotEmpty) {
      return [
        for (final line in info.formattedLines) pw.Text(line, style: style),
      ];
    }
    if (legacyFlat.trim().isNotEmpty) {
      return [pw.Text(legacyFlat, style: style)];
    }
    return const [];
  }

  // ── PDF builder: Executive (layout id 1) ────────────────────────────────────

  Future<Uint8List> _buildExecutivePdf(SavedInvoice invoice) async {
    final d     = invoice.data;
    final color = _pdfColor(d.colorScheme);

    // BODY FONT FAMILY PDF PASS: loaded up front (before pw.Document is
    // constructed) since the font must be passed into the document's
    // theme at construction time. null (Default / unrecognized) leaves
    // pdf/widgets' own built-in font in place — nothing else changes.
    final bodyFont = await _pdfBodyFont(d.fontFamily);
    final pdf = pw.Document(
      theme: bodyFont != null
          ? pw.ThemeData.withFont(base: bodyFont, bold: bodyFont)
          : null,
    );

    final subtotal      = d.subtotal;
    final discountAmount = d.discountAmount;
    final taxAmount      = d.taxAmount;
    final grandTotal     = d.grandTotal;

    // Optionally load logo — gated by the businessLogo toggle same as the
    // live preview.
    pw.MemoryImage? logoImage;
    final logoPath = d.businessLogoPath;
    if (_on(d, 'businessLogo') && logoPath != null && logoPath.isNotEmpty) {
      final f = File(logoPath);
      if (await f.exists()) {
        logoImage = pw.MemoryImage(await f.readAsBytes());
      }
    }

    final showBusinessName = _on(d, 'businessName');
    final showBusinessEmail = _on(d, 'businessEmail');
    final showBusinessPhone = _on(d, 'businessPhone');
    final showBusinessAddress = _on(d, 'businessAddress');
    final showInvoiceNumber = _on(d, 'invoiceNumber');
    final showDate = _on(d, 'date');
    final showDueDate = _on(d, 'dueDate');
    // PAYMENT INFO / TERMS & SIGNATURE PDF RENDER PASS: PO / Reference
    // Number, rendered in the header meta column below Due Date.
    final showPoNumber = _on(d, 'poNumber');
    final showClientName = _on(d, 'customerName');
    final showClientEmail = _on(d, 'customerEmail');
    final showClientPhone = _on(d, 'customerPhone');
    final showClientAddress = _on(d, 'customerAddress');
    final showTax = _on(d, 'tax');
    final showDiscount = _on(d, 'discount');
    final showNotes = _on(d, 'notes');

    // STRUCTURED ADDRESS PDF RENDER PASS: "does this invoice actually have
    // a business/client address to show" now also checks the structured
    // AddressInfo (not just the legacy flat string), so a customer/
    // template whose address was only ever entered via the six-field
    // form (and never had a flat string set) still counts.
    final businessAddressLines = showBusinessAddress
        ? _addressLines(
            d.businessAddressInfo,
            d.businessAddress,
            const pw.TextStyle(fontSize: 10, color: PdfColors.white),
          )
        : const <pw.Widget>[];
    final clientAddressLines = showClientAddress
        ? _addressLines(
            d.clientAddressInfo,
            d.clientAddress,
            const pw.TextStyle(fontSize: 10),
          )
        : const <pw.Widget>[];

    final hasCustomer = (showClientName && d.clientName.isNotEmpty) ||
        (showClientEmail && d.clientEmail.isNotEmpty) ||
        (showClientPhone && d.clientPhone.isNotEmpty) ||
        clientAddressLines.isNotEmpty;

    // PAYMENT INFO / TERMS & SIGNATURE PDF RENDER PASS: built up front
    // (signature needs an awaited disk read for 'image' mode) since a
    // pw.Widget tree must be fully assembled before pdf.addPage() below.
    final paymentInfoPanel = buildPdfPaymentInfoPanel(d);
    final termsPanel = buildPdfTermsPanel(d);
    final signatureBlock = await buildPdfSignatureBlock(d);

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
                      if (showBusinessName && d.businessName.isNotEmpty)
                        pw.Text(d.businessName,
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            )),
                      if (showBusinessEmail && d.businessEmail.isNotEmpty)
                        pw.Text(d.businessEmail,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
                      if (showBusinessPhone && d.businessPhone.isNotEmpty)
                        pw.Text(d.businessPhone,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
                      // STRUCTURED ADDRESS PDF RENDER PASS: one pw.Text
                      // per postal line (Line 1 / Line 2 / City, State
                      // ZIP / Country) instead of the single flat
                      // businessAddress string wrapping as one paragraph.
                      ...businessAddressLines,
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                    if (showInvoiceNumber && d.invoiceNumber.isNotEmpty)
                      pw.Text('#${d.invoiceNumber}',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.white)),
                    if (showDate && d.issueDate.isNotEmpty)
                      pw.Text(d.issueDate,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    if (showDueDate && d.dueDate.isNotEmpty)
                      pw.Text('Due: ${d.dueDate}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    if (showPoNumber && d.poNumber.trim().isNotEmpty)
                      pw.Text('PO: ${d.poNumber.trim()}',
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
                  pw.Text('BILL TO',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                        letterSpacing: 1,
                      )),
                  pw.SizedBox(height: 4),
                  if (showClientName && d.clientName.isNotEmpty)
                    pw.Text(d.clientName,
                        style: pw.TextStyle(
                            fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  if (showClientEmail && d.clientEmail.isNotEmpty)
                    pw.Text(d.clientEmail,
                        style: const pw.TextStyle(fontSize: 10)),
                  if (showClientPhone && d.clientPhone.isNotEmpty)
                    pw.Text(d.clientPhone,
                        style: const pw.TextStyle(fontSize: 10)),
                  // STRUCTURED ADDRESS PDF RENDER PASS: one pw.Text per
                  // postal line instead of the single flat clientAddress
                  // string.
                  ...clientAddressLines,
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
              // LINE ITEM TOTAL FIX (this update): each row's Total now
              // subtracts its own discount amount and applies its own
              // (signed) tax amount, the same formula as
              // LineItem.lineNetTotal / the Flutter preview's
              // buildLineItemRow — previously this was plain
              // item.total (qty × price), so a row's own tax/discount
              // never actually came off its printed Total.
              ...d.lineItems.map((item) {
                final itemDiscountAmt = item.discountEnabled
                    ? item.total * item.itemDiscountRate / 100
                    : 0.0;
                final itemTaxAmt = item.taxEnabled
                    ? item.total * item.itemTaxRate / 100
                    : 0.0;
                final signedTaxAmt = item.taxEnabled
                    ? (item.itemTaxIsAddition ? itemTaxAmt : -itemTaxAmt)
                    : 0.0;
                final netTotal = item.total - itemDiscountAmt + signedTaxAmt;
                return pw.TableRow(
                  children: [
                    _td(item.description),
                    _td(
                      item.quantity % 1 == 0
                          ? item.quantity.toInt().toString()
                          : item.quantity.toStringAsFixed(2),
                      align: pw.TextAlign.center,
                    ),
                    _td(_fmtMoney(d, item.unitPrice), align: pw.TextAlign.right),
                    _td(_fmtMoney(d, netTotal), align: pw.TextAlign.right),
                  ],
                );
              }),
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
                  if (showTax && d.taxRate > 0)
                    _totalRow('Tax (${_fmtPct(d.taxRate)}%)',
                        '+${_fmtMoney(d, taxAmount)}'),
                  if (showDiscount && d.discountRate > 0)
                    _totalRow('Discount (${_fmtPct(d.discountRate)}%)',
                        '-${_fmtMoney(d, discountAmount)}'),
                  // GST/VAT BREAKDOWN PDF FIX (this update): named
                  // per-item discount/tax totals — same
                  // itemDiscountExtraByName / itemTaxExtraByName maps
                  // the Flutter footer already reads. A shared name (or
                  // no name) across every item renders as one row;
                  // genuinely different names each get their own row.
                  // Tax entries are signed (withholding-style items
                  // render with a minus instead of always being added).
                  if (showDiscount)
                    for (final entry in d.itemDiscountExtraByName.entries)
                      if (entry.value > 0)
                        _totalRow(
                          entry.key.isEmpty
                              ? 'Item Discounts'
                              : 'Item Discounts (${entry.key})',
                          '-${_fmtMoney(d, entry.value)}',
                        ),
                  if (showTax)
                    for (final entry in d.itemTaxExtraByName.entries)
                      if (entry.value != 0)
                        _totalRow(
                          entry.key.isEmpty
                              ? 'Item Tax'
                              : 'Item Tax (${entry.key})',
                          '${entry.value < 0 ? '-' : '+'}${_fmtMoney(d, entry.value.abs())}',
                        ),
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
          if (showNotes && d.notes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Notes / Payment Terms',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: color)),
            pw.SizedBox(height: 4),
            pw.Text(d.notes, style: const pw.TextStyle(fontSize: 10)),
          ],

          // ── Payment Info / Terms & Conditions / Signature ──────────────
          // PAYMENT INFO / TERMS & SIGNATURE PDF RENDER PASS: each panel
          // is null (Payment Info/Terms) or an empty pw.SizedBox()
          // (Signature) when its toggle is off or nothing's filled in,
          // so a PDF with none of this set exports exactly as before.
          if (paymentInfoPanel != null) paymentInfoPanel,
          if (termsPanel != null) termsPanel,
          signatureBlock,
        ],
      ),
    );

    return pdf.save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  PdfColor _pdfColor(InvoiceColor c) {
    switch (c) {
      case InvoiceColor.blue:   return PdfColors.blue800;
      case InvoiceColor.green:  return PdfColors.green800;
      case InvoiceColor.purple: return PdfColors.purple800;
      case InvoiceColor.orange: return PdfColors.orange800;
      case InvoiceColor.red:    return PdfColors.red800;
      case InvoiceColor.teal:   return PdfColors.teal800;
      case InvoiceColor.black:  return PdfColors.grey900;
      case InvoiceColor.indigo: return PdfColors.indigo800;
    }
  }

  /// Renders the Executive header logo respecting the document's real
  /// LogoShape (circle/square/roundedSquare) instead of a hardcoded
  /// ClipOval, with BoxFit.contain on a soft neutral background instead
  /// of solid white — mirrors pdf_templates.dart's own _logoWidget (used
  /// by the other 9 styles) and the Flutter-side DocLogoAvatar, so a
  /// non-square logo isn't stretched/cropped to fill a circle it was
  /// never meant to fill.
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

  /// Formats money using InvoiceData's own currency/currencySymbol/
  /// currencyDisplayMode fields — free text, no hardcoded currency list.
  /// Mirrors DocTemplateAdapter.fmtMoney() (Flutter preview side) exactly,
  /// so exported PDFs match what the user saw in the preview.
  static String _fmtMoney(InvoiceData d, double v) {
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
    // Simple 2-decimal formatting with thousands separators, no intl dependency.
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
