// lib/services/invoice_pdf_extra_sections.dart
//
// SIGNATURE LINE WIDTH PDF PARITY PASS (BUILD FIX, this update): the
// previous version of this measured against pw.Font.stringMetrics() —
// but that method lives on the low-level PdfFont object (package:pdf/
// pdf.dart), not on pw.Font (the widgets-layer wrapper used everywhere
// else in this file), and pw.Font has no way to reach it without a
// build Context. That doesn't compile ("The method 'stringMetrics'
// isn't defined for the type 'Font'"). Fixed by dropping the exact-
// metrics approach entirely and using a simple per-character width
// estimate instead: 0.55em per character is a reasonable average
// advance width for both the bundled script fonts and the bold-italic
// Helvetica fallback, for the mixed-case names typed into a signature
// field. This is an approximation, not exact glyph metrics — but it's
// only used to size a cosmetic clamp ([70, 220]), so exactness isn't
// required. _measureSignatureWidth() no longer takes a font parameter
// at all, since the estimate doesn't depend on which font is loaded.
//
// SIGNATURE LINE WIDTH PDF PARITY PASS (earlier): the live preview's
// signing line under a typed signature (executive_invoice_payment_terms_
// signature.dart's buildSignatureBlock) was fixed in an earlier pass to
// measure the actual rendered name width (Flutter's TextPainter) and
// size the line to match it, clamped to [70, 220] — but that fix never
// reached the exported PDF, which still drew a fixed 160pt line
// regardless of name length. Same "preview lied about what's real" shape
// as the earlier line-width-vs-text-width bugs found in this app.
// line() now takes an optional width parameter (default 160, unchanged
// for 'image'/'blank' modes — only 'typed' passes a measured width),
// mirroring the Flutter side's line({double width = 160}) exactly.
//
// NOTE: the fallback style (no signature font family chosen) hardcodes
// fontSize: 20 here, not d.signatureFontSize the way the Flutter
// fallback does — that's a pre-existing PDF/preview mismatch, unrelated
// to and out of scope for this fix. The measurement below always uses
// whatever font size the PDF is actually about to draw with, so the
// line stays correctly matched to its own text either way.
//
// SIGNATURE FONT FAMILY PASS (earlier): _pdfSignatureFont() no longer
// calls PdfGoogleFonts (which always hits the network regardless of
// GoogleFonts.config, and fails silently with no connection). The six
// script fonts are now bundled locally in assets/signature_fonts/ and
// registered in pubspec.yaml, so this loads each one via rootBundle +
// pw.Font.ttf() instead, matching the live preview's plain
// TextStyle(fontFamily: ...) fix in
// executive_invoice_payment_terms_signature.dart. signatureFontFamily
// == '' (no chip picked) still falls back to the original bold-italic
// pw.TextStyle look — unchanged behaviour for existing invoices.
//
// Everything below this point (PAYMENT TERMS REMOVAL PASS, PAYMENT
// INFO / TERMS & SIGNATURE PDF RENDER PASS, DESELECT PASS, etc.) is
// unchanged from before — see prior header comments for those.

import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_data.dart';

bool _on(InvoiceData d, String key) => d.enabledFields[key] ?? true;

// ─────────────────────────────────────────────────────────────────────────
// Payment Info panel — Bank Name / Account Name / Account Number / Other
// Payment Details. Returns null (render nothing) when no enabled row has
// text, matching the Flutter side's SizedBox.shrink().
// ─────────────────────────────────────────────────────────────────────────

pw.Widget? buildPdfPaymentInfoPanel(InvoiceData d) {
  final rows = <MapEntry<String, String>>[
    if (_on(d, 'bankName') && d.bankName.trim().isNotEmpty)
      MapEntry('Bank Name', d.bankName.trim()),
    if (_on(d, 'accountName') && d.accountName.trim().isNotEmpty)
      MapEntry('Account Name', d.accountName.trim()),
    if (_on(d, 'accountNumber') && d.accountNumber.trim().isNotEmpty)
      MapEntry('Account Number', d.accountNumber.trim()),
    if (_on(d, 'otherPaymentDetails') && d.otherPaymentDetails.trim().isNotEmpty)
      MapEntry('Other Details', d.otherPaymentDetails.trim()),
  ];
  if (rows.isEmpty) return null;

  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 16),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PAYMENT DETAILS',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
                letterSpacing: 1)),
        pw.SizedBox(height: 6),
        for (final entry in rows)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 100,
                  child: pw.Text(entry.key,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ),
                pw.Expanded(
                  child: pw.Text(entry.value,
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Terms & Conditions panel — plain text block, same boxed-panel look.
// ─────────────────────────────────────────────────────────────────────────

pw.Widget? buildPdfTermsPanel(InvoiceData d) {
  if (!_on(d, 'termsAndConditions')) return null;
  final text = d.termsAndConditions.trim();
  if (text.isEmpty) return null;

  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 16),
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
                letterSpacing: 1)),
        pw.SizedBox(height: 5),
        pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// SIGNATURE FONT FAMILY PASS: maps one of
// executive_invoice_payment_terms_signature.dart's kSignatureFonts to
// its locally-bundled .ttf asset (see pubspec.yaml's
// assets/signature_fonts/ entries), loaded via rootBundle + pw.Font.ttf.
// Returns null for '' (no family chosen) or an unrecognized name, so
// the caller falls back to the original bold-italic pw.TextStyle look —
// same "empty means unchanged" rule every other new field in this
// pass/its siblings follows. No network involved at all, unlike the
// old PdfGoogleFonts.xRegular() calls this replaces.
// ─────────────────────────────────────────────────────────────────────────

Future<pw.Font?> _pdfSignatureFont(String family) async {
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

// ─────────────────────────────────────────────────────────────────────────
// SIGNATURE LINE WIDTH PDF PARITY PASS (BUILD FIX): see header comment
// at the top of this file for why this no longer calls
// pw.Font.stringMetrics() (that method doesn't exist on pw.Font — it's
// only on the low-level PdfFont, unreachable here without a build
// Context). Uses a flat per-character estimate instead. No longer takes
// a font parameter since the estimate doesn't depend on it.
// ─────────────────────────────────────────────────────────────────────────

double _measureSignatureWidth(String text, double fontSize) {
  const avgCharWidthFactor = 0.55;
  return text.length * fontSize * avgCharWidthFactor;
}

// ─────────────────────────────────────────────────────────────────────────
// Signature block — matches InvoiceData.signatureMode exactly:
// 'image' | 'typed' | 'blank' | '' (deselected). Always returns a widget
// (never null) when the toggle is on and a real mode is set, since
// 'blank' still reserves a signing line — an empty pw.SizedBox() is
// returned when the toggle itself is off OR when signatureMode is empty
// (deselected on the template — see DESELECT PASS above).
//
// Async because 'image' mode needs to read the signature file off disk,
// and 'typed' mode now needs to load the bundled font asset — mirrors
// how _buildExecutivePdf already loads the business logo bytes before
// pdf.addPage() is called, since a pw.Widget tree must be fully built by
// the time MultiPage's build() runs.
// ─────────────────────────────────────────────────────────────────────────

Future<pw.Widget> buildPdfSignatureBlock(InvoiceData d) async {
  if (!_on(d, 'signature')) return pw.SizedBox();

  // DESELECT PASS: '' means no mode was ever picked (or was explicitly
  // deselected) on the template — render nothing at all, not even the
  // reserved line 'blank' would show. Mirrors the identical early-return
  // in executive_invoice_payment_terms_signature.dart's
  // buildSignatureBlock, so the PDF matches the live preview.
  if (d.signatureMode.trim().isEmpty) return pw.SizedBox();

  // SIGNATURE LINE WIDTH PDF PARITY PASS: line() now takes an optional
  // width, defaulting to the original fixed 160pt — 'image' and 'blank'
  // modes below still call line() with no argument (nothing to measure
  // against), only 'typed' passes a measured width. Mirrors the Flutter
  // side's line({double width = 160}) exactly.
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
      // SIGNATURE FONT FAMILY PASS: load the matching bundled font when
      // d.signatureFontFamily names one of the six offered families;
      // null (unset, or an unrecognized string) keeps the original
      // bold-italic pw.TextStyle look.
      final pdfFont = await _pdfSignatureFont(d.signatureFontFamily);
      // NOTE: fallback fontSize is hardcoded 20 here (pre-existing,
      // unrelated to this fix) — not d.signatureFontSize the way the
      // Flutter fallback uses. Kept as-is; the measurement below uses
      // whichever size is actually applied so the line still matches.
      final effectiveFontSize = pdfFont != null ? d.signatureFontSize : 20.0;
      final style = pdfFont != null
          ? pw.TextStyle(font: pdfFont, fontSize: d.signatureFontSize)
          : pw.TextStyle(
              fontSize: 20,
              fontStyle: pw.FontStyle.italic,
              fontWeight: pw.FontWeight.bold,
            );
      // SIGNATURE LINE WIDTH PDF PARITY PASS: estimated per-character
      // width, clamped to the same [70, 220] range the Flutter preview
      // uses.
      final lineWidth = name.isEmpty
          ? 70.0
          : _measureSignatureWidth(name, effectiveFontSize).clamp(70.0, 220.0);
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
