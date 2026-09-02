// lib/services/invoice_pdf_service.dart
//
// Generates and exports invoice PDFs.
//
// HISTORY LOGGING PASS (this update): generateAndSharePDF now accepts an
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
// InvoiceData.enabledFields via the new _on() helper — business logo/
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
// REWRITE: previously built against an `Invoice`/`BusinessInfo`/`ClientInfo`
// shape (businessInfo.name, customer.email, enabledFields map, items cast
// from dynamic) that does not match the app's real data model. Confirmed
// against invoice_provider.dart + models/invoice_data.dart: the real model
// is InvoiceData, with flat fields (businessName, businessEmail, clientName,
// lineItems, etc.) set via InvoiceProvider.updateBusinessInfo/updateClientInfo/
// updateInvoiceDetails, and saved as SavedInvoice.data. This version builds
// directly from that real InvoiceData, nothing else.
//
// The existing pdf_service.dart (CV/resume PDFs) is untouched — this is the
// invoice-only PDF path.
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

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/invoice_data.dart';
import '../models/history_event.dart' show HistoryDocType;
import '../providers/history_provider.dart';
import 'pdf_doc_adapter.dart';
import 'pdf_templates.dart' as styled;

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

  // ── PDF builder: Executive (layout id 1) ────────────────────────────────────

  Future<Uint8List> _buildExecutivePdf(SavedInvoice invoice) async {
    final pdf   = pw.Document();
    final d     = invoice.data;
    final color = _pdfColor(d.colorScheme);

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
    final showClientName = _on(d, 'customerName');
    final showClientEmail = _on(d, 'customerEmail');
    final showClientPhone = _on(d, 'customerPhone');
    final showClientAddress = _on(d, 'customerAddress');
    final showTax = _on(d, 'tax');
    final showDiscount = _on(d, 'discount');
    final showNotes = _on(d, 'notes');

    final hasCustomer = (showClientName && d.clientName.isNotEmpty) ||
        (showClientEmail && d.clientEmail.isNotEmpty) ||
        (showClientPhone && d.clientPhone.isNotEmpty) ||
        (showClientAddress && d.clientAddress.isNotEmpty);

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
                      if (showBusinessAddress && d.businessAddress.isNotEmpty)
                        pw.Text(d.businessAddress,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.white)),
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
                  if (showClientAddress && d.clientAddress.isNotEmpty)
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
                  if (showTax && d.taxRate > 0)
                    _totalRow('Tax (${_fmtPct(d.taxRate)}%)',
                        '+${_fmtMoney(d, taxAmount)}'),
                  if (showDiscount && d.discountRate > 0)
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