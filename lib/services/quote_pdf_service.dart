// lib/services/quote_pdf_service.dart
//
// OFFLINE SIGNATURE FONT PARITY PASS (this update): mirrors the fix
// already applied to invoice_pdf_extra_sections.dart's
// _pdfSignatureFont() — this file's own _pdfSignatureFont() still
// called PdfGoogleFonts.xRegular() for the six script fonts, which
// always hits the network regardless of GoogleFonts.config and fails
// silently (falls back to the plain bold-italic style) with no
// connection. The six fonts are already bundled locally in
// assets/signature_fonts/ and registered in pubspec.yaml (that's what
// let Invoice's own fix work), so this now loads each one via
// rootBundle + pw.Font.ttf() instead, exactly like Invoice. No behavior
// change when signatureFontFamily is '' or unrecognized — still falls
// back to the original bold-italic pw.TextStyle look.
//
// SIGNATURE LINE WIDTH PDF PARITY PASS (earlier): mirrors the
// identical fix applied to invoice_pdf_extra_sections.dart's
// buildPdfSignatureBlock — the live preview's signing line under a
// typed signature (executive_quote_payment_terms_signature.dart's
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
// matches what's actually on the page. _buildQuoteSignatureBlock's
// local line() now takes an optional width parameter (default 160,
// unchanged for 'image'/'blank' — only 'typed' passes a measured
// width), mirroring the Flutter side's line({double width = 160})
// exactly.
//
// NOTE: same as Invoice's PDF fallback — the no-font-resolved branch
// hardcodes fontSize: 20, not d.signatureFontSize the way the Flutter
// fallback does. Pre-existing, out of scope here; the measurement below
// always uses whichever size is actually applied so the line stays
// matched to its own text either way.
//
// TERMS & SIGNATURE GATING FIX (earlier): two real bugs fixed
// together, found while tracking down why Terms & Conditions and the
// Signature block weren't showing up anywhere for Quote:
//
//   1. Terms & Conditions text was NEVER rendered in the exported PDF at
//      all. The only text block after the totals table was a "Notes /
//      Terms" heading that printed d.notes — QuoteData.termsAndConditions
//      was never referenced anywhere in this file. Someone typing real
//      terms into the template sheet had it correctly reach QuoteData
//      (this part always worked), but the PDF builder simply never read
//      that field. Fixed by adding a real Terms & Conditions panel,
//      gated the same way the on-screen render is gated in
//      executive_quote_stationary_layout.dart's buildTermsPanel — the
//      'termsAndConditions' enabledFields toggle AND non-empty text —
//      rendered as its own block, separate from Notes.
//
//   2. _buildQuoteSignatureBlock() only checked
//      `d.signatureMode.trim().isEmpty` — it never checked
//      `d.enabledFields['signature']`. So turning the Signature toggle
//      off on Customise had no effect on the exported PDF; the signature
//      would still print as long as a mode had ever been set. Fixed to
//      match the on-screen buildSignatureBlock() gate exactly: skip
//      entirely when the 'signature' field is toggled off, in addition
//      to the existing empty-mode check.
//
// SIGNATURE PASS (earlier): _buildExecutivePdf renders a signature block
// after Notes, gated by QuoteData.signatureMode being non-empty (mirrors
// executive_quote_stationary_layout.dart's buildSignatureBlock gating —
// now ALSO the enabledFields check, see fix #2 above).
// New _buildQuoteSignatureBlock() helper mirrors
// invoice_pdf_extra_sections.dart's buildPdfSignatureBlock: 'image'
// reads the file off disk, 'typed' loads a bundled signature font when
// QuoteData.signatureFontFamily names one of the six offered families
// (falls back to the original bold-italic pw.TextStyle when it's ''),
// 'blank' reserves a signing line, '' (deselected) renders nothing.
// _buildExecutivePdf is already async, so no new async plumbing was
// needed at the call site.
//
// PARITY FIX (earlier): _buildExecutivePdf brought up to the same
// data-correctness level invoice_pdf_service.dart's and
// receipt_pdf_service.dart's own Executive builders already have.
//
// HISTORY LOGGING PASS, LOGO PARITY PASS, CURRENCY DISPLAY PASS (all
// earlier) — see prior header comments; unaffected by this update.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
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

  // TERMS & SIGNATURE GATING FIX: small helper mirroring
  // executive_quote_stationary_layout.dart's private _on() — reads a
  // QuoteData.enabledFields flag, defaulting to true when the key is
  // absent (matches every other enabledFields read site in this app).
  static bool _on(QuoteData d, String key) => d.enabledFields[key] ?? true;

  // TERMS & SIGNATURE GATING FIX: new — mirrors
  // executive_quote_stationary_layout.dart's buildTermsPanel() gating
  // exactly (the 'termsAndConditions' toggle AND non-empty text), but as
  // a pw.Widget for the exported PDF. Previously this text was never
  // read anywhere in this file at all.
  static pw.Widget _buildQuoteTermsPanel(QuoteData d) {
    if (!_on(d, 'termsAndConditions')) return pw.SizedBox();
    final text = d.termsAndConditions.trim();
    if (text.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TERMS & CONDITIONS',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
                letterSpacing: 1,
              )),
          pw.SizedBox(height: 5),
          pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // OFFLINE SIGNATURE FONT PARITY PASS: maps one of
  // executive_invoice_payment_terms_signature.dart's kSignatureFonts to
  // its locally-bundled .ttf asset (see pubspec.yaml's
  // assets/signature_fonts/ entries), loaded via rootBundle +
  // pw.Font.ttf — exactly like invoice_pdf_extra_sections.dart's
  // _pdfSignatureFont(). Returns null for '' (no family chosen) or an
  // unrecognized name, so the caller falls back to the original
  // bold-italic pw.TextStyle look. No network involved at all, unlike
  // the old PdfGoogleFonts.xRegular() calls this replaces.
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
  // buildPdfSignatureBlock exactly (three modes + deselected ''), built
  // directly against QuoteData since Quote has no separate payment/
  // terms/signature PDF file the way Invoice does.
  //
  // TERMS & SIGNATURE GATING FIX: now ALSO checks the 'signature'
  // enabledFields toggle first — previously only signatureMode being
  // non-empty was checked, so toggling Signature off on Customise had no
  // effect on the exported PDF. Matches
  // executive_quote_stationary_layout.dart's buildSignatureBlock() gate
  // exactly: `!_on(data, 'signature')` short-circuits before the mode
  // check.
  static Future<pw.Widget> _buildQuoteSignatureBlock(QuoteData d) async {
    if (!_on(d, 'signature')) return pw.SizedBox();
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

    // TERMS & SIGNATURE GATING FIX: built up front alongside the
    // signature block — pure/synchronous, but kept next to it since both
    // feed the same tail of the page.
    final termsPanel = _buildQuoteTermsPanel(d);

    // SIGNATURE PASS: built up front (needs an awaited disk read for
    // 'image' mode / a font load for 'typed') since a pw.Widget tree
    // must be fully assembled before pdf.addPage() below.
    final signatureBlock = await _buildQuoteSignatureBlock(d);

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
                  if (d.taxEnabled && d.taxRate > 0)
                    _totalRow(
                        '${d.taxName.trim().isEmpty ? 'Tax' : d.taxName.trim()} (${_fmtPct(d.taxRate)}%)',
                        '+${_fmtMoney(d, taxAmount)}'),
                  if (d.discountEnabled && d.discountRate > 0)
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
            pw.Text('Notes',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: color)),
            pw.SizedBox(height: 4),
            pw.Text(d.notes, style: const pw.TextStyle(fontSize: 10)),
          ],

          // TERMS & SIGNATURE GATING FIX: Terms & Conditions now
          // actually renders — previously this text was never read
          // anywhere in this file (only d.notes was, mislabeled "Notes /
          // Terms" above). Kept as its own labeled block, separate from
          // Notes, matching the on-screen layout.
          termsPanel,

          // SIGNATURE PASS: rendered last, after Notes/Terms. Now
          // correctly gated by the 'signature' enabledFields toggle too
          // (see TERMS & SIGNATURE GATING FIX above).
          signatureBlock,
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