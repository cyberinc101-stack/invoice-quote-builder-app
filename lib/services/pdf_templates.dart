// pdf_templates.dart
// lib/services/pdf_templates.dart
//
// pw (PDF widgets) equivalents of the 9 Flutter designs in
// lib/document_layout_templates/. Each header builder here is a direct port of its
// matching *_template.dart file's _xxxFullHeader/_xxxContinuationHeader —
// same layout decisions (panel vs no panel, rule style, meta row shape),
// translated into pw widgets where the pdf package's API differs from
// Flutter's. buildStyledDocument() is the single entry point every PDF
// service calls for styleId 2-10; styleId 1 (Executive) keeps using each
// service's existing hand-built _buildExecutivePdf, unchanged.
//
// TEN-TEMPLATE PARITY PASS (this update): five Flutter templates (Nordic,
// Editorial, Pastel Soft, Brutalist, Emerald) were reworked in an earlier
// pass to be structurally distinct from one another (see each *_template.
// dart file's own "TEN-TEMPLATE UNIQUENESS PASS" header comment), but this
// file was never updated to match — it was still rendering each of those
// five templates' OLD pre-rework designs. That meant a user picking any
// of those five saw one design in the app's live preview/editor and a
// completely different one in the actual exported PDF. _nordicHeader,
// _editorialHeader, _pastelSoftHeader, _brutalistHeader, and
// _emeraldHeader are all replaced below with direct ports of each
// template's current Flutter header, closing that gap. _vibrantHeader,
// _techDarkHeader, _classicHeader, and _gradientModernHeader are
// untouched — those four Flutter templates haven't been reworked yet, so
// their existing PDF headers still match.
//
// KNOWN LIMITATION: Brutalist's Flutter header uses a diagonal ClipPath
// (an angular "ribbon" cut on the recipient block). The `pdf` package has
// no equivalent path-clipping widget, so _brutalistHeader below renders
// the same content (dark reversed-type recipient block, business +
// doc-type block) as a plain rectangle instead of the angled ribbon
// shape — visually close, not pixel-identical to the Flutter preview.
//
// BRUTALIST DOUBLE-HEADER FIX (this update): _brutalistHeader has always
// rendered its own dark, reversed-type line-items header row inline (SL./
// ITEM DESCRIPTION/QTY/PRICE/TOTAL on a black bar) — but buildStyledDocument's
// needsOwnTable only ever excluded style 5 (Classic) from also getting the
// generic accent-underline _sharedLineItemsHeaderRow appended afterward.
// For Brutalist (style 9) that meant two header rows stacked on top of
// each other: the dark bar this header already draws, then a second,
// different-looking thin-underline row from _sharedLineItemsTable. Fixed
// by adding style 9 to the needsOwnTable exclusion, same pattern Classic
// already uses, so Brutalist's table body renders once, under its own
// header row only.
//
// LOGO PARITY PASS (earlier): the exported PDF and the Flutter preview
// had drifted apart on logos. _logoWidget was defined but only ever CALLED
// from _vibrantHeader — every other header (Nordic, Tech Dark, Classic,
// Gradient Modern, Editorial, Pastel Soft, Brutalist, Emerald) rendered no
// logo at all, even when the user had uploaded one and could see it in
// every one of those templates' Flutter previews and on every saved-
// document card. A user picking any style except Vibrant (or Executive,
// which has its own separate builder in each *_pdf_service.dart) would
// get a logo-less PDF despite the app showing them a logo everywhere else.
// Fixed by adding a _logoWidget(d) + spacing call to the identity-block
// Row in all 8 of the previously-missing headers, matching each header's
// own existing layout shape (some are a plain Row with the business name
// starting the line, some already have other content to the left) —
// same left-of-business-name placement Vibrant already used.
//
// _logoWidget itself also changed: previously a hardcoded pw.ClipOval
// (always a circle, regardless of what LogoShape the user actually
// picked via the Logo Sizer) on a bare white background with
// BoxFit.contain -- now clips to the document's real logoShape (circle /
// square / roundedSquare, from PdfDocData.logoShape, mirroring
// LogoShape.radiusFor() on the Flutter side) and sits on a very light
// neutral background rather than solid white, so a non-square logo on a
// colored header panel (Vibrant, Tech Dark) doesn't read as a stray white
// rectangle. This mirrors the Flutter-side DocLogoAvatar's own LOGO FIT
// PASS (contain-fit, no cropping, letterboxed on a soft background)
// closely, short of threading the pan/zoom offset through (contain-fit
// has nothing for a crop offset to apply to — same reasoning used on the
// Flutter side).
//
// CURRENCY DISPLAY PASS (earlier): the hardcoded _kCurrencySymbols
// lookup + _fmtMoney(currency, v) helper are gone — every call site now
// uses d.fmtMoney(v) (PdfDocData's own method, added in pdf_doc_adapter.dart)
// which respects the document's free-text currency symbol + display mode
// instead of a fixed currency list, matching the Flutter preview exactly.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_doc_adapter.dart';

// ── Palette (mirrors document_layout_templates/shared/shared_doc_widgets.dart) ─────────
const PdfColor kPdfInk = PdfColors.grey900;
const PdfColor kPdfGrey = PdfColors.grey600;
const PdfColor kPdfGreyLight = PdfColors.grey400;
const PdfColor kPdfRule = PdfColors.grey300;
const PdfColor kPdfPanelBg = PdfColors.grey100;

PdfColor _tint(PdfColor c, double towardWhite) => PdfColor(
      c.red + (1 - c.red) * towardWhite,
      c.green + (1 - c.green) * towardWhite,
      c.blue + (1 - c.blue) * towardWhite,
    );

PdfColor _alpha(PdfColor c, double alpha) => PdfColor(c.red, c.green, c.blue, alpha);

String _fmtQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);
String _fmtPct(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

// ── Shared line items header row / rows / totals / notes / footer ──────────

pw.Widget _sharedLineItemsHeaderRow(PdfColor accent) {
  final hdr = pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: kPdfGrey);
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 8),
    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: accent, width: 1.5))),
    child: pw.Row(children: [
      pw.Expanded(flex: 5, child: pw.Text('DESCRIPTION', style: hdr)),
      pw.Expanded(flex: 1, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: hdr)),
      pw.Expanded(flex: 2, child: pw.Text('UNIT PRICE', textAlign: pw.TextAlign.right, style: hdr)),
      pw.Expanded(flex: 2, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: hdr)),
    ]),
  );
}

pw.Widget _sharedLineItemsTable(PdfDocData d) {
  return pw.Column(children: [
    _sharedLineItemsHeaderRow(d.accent),
    for (final item in d.lineItems)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 9),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: kPdfRule, width: 0.75))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(flex: 5, child: pw.Text(
              item.description.isEmpty ? 'Item description' : item.description,
              style: const pw.TextStyle(fontSize: 10, color: kPdfInk))),
          pw.Expanded(flex: 1, child: pw.Text(_fmtQty(item.quantity), textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10, color: kPdfGrey))),
          pw.Expanded(flex: 2, child: pw.Text(d.fmtMoney(item.unitPrice), textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 10, color: kPdfGrey))),
          pw.Expanded(flex: 2, child: pw.Text(d.fmtMoney(item.total), textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfInk))),
        ]),
      ),
  ]);
}

pw.Widget _sharedTotalsAndNotes(PdfDocData d) {
  // OVERFLOW SAFETY PASS: mirrors the identical fix in
  // shared_doc_widgets.dart's buildSharedTotalsAndNotesSection — label
  // and value now wrap in pw.Flexible instead of plain pw.Text, so a long
  // translated label or an unusually large formatted total can shrink to
  // fit instead of throwing a layout overflow. This one function backs
  // every one of the 10 templates' totals sections in the exported PDF,
  // so this single fix protects all of them at once.
  //
  // Deliberately NOT using pw.Text's maxLines/overflow params here — the
  // `pdf` package's exact API surface for text truncation isn't something
  // this file can verify without an actual build, and guessing at an
  // unconfirmed member name risks a compile error worse than the overflow
  // this is meant to fix. pw.Flexible alone (allowing the text to shrink
  // within the available space rather than demanding its full intrinsic
  // width) is the structurally safe fix; if truncation with an ellipsis
  // is also wanted, confirm the correct pw.Text overflow API against the
  // actual installed `pdf` package version first.
  pw.Widget row(String label, double v, {bool bold = false, bool negative = false}) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Flexible(
        child: pw.Text(label,
            style: pw.TextStyle(fontSize: bold ? 11 : 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: bold ? kPdfInk : kPdfGrey)),
      ),
      pw.SizedBox(width: 8),
      pw.Flexible(
        child: pw.Text('${negative ? '-' : ''}${d.fmtMoney(v)}',
            style: pw.TextStyle(fontSize: bold ? 13 : 10.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.bold,
                color: bold ? d.accent : kPdfInk),
            textAlign: pw.TextAlign.right),
      ),
    ]),
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 16),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 230,
          child: pw.Column(children: [
            row('Subtotal', d.subtotal),
            if (d.discountRate > 0) row('Discount (${_fmtPct(d.discountRate)}%)', d.discountAmount, negative: true),
            if (d.taxRate > 0) row('Tax (${_fmtPct(d.taxRate)}%)', d.taxAmount),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Divider(color: kPdfRule)),
            row(d.totalLabel, d.total, bold: true),
          ]),
        ),
      ),
      if (d.notes.trim().isNotEmpty) ...[
        pw.SizedBox(height: 24),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(color: kPdfPanelBg, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('NOTES', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: kPdfGrey)),
            pw.SizedBox(height: 6),
            pw.Text(d.notes, style: const pw.TextStyle(fontSize: 9.5, color: kPdfInk)),
          ]),
        ),
      ],
      pw.SizedBox(height: 28),
      pw.Container(height: 0.75, color: kPdfRule),
      pw.SizedBox(height: 10),
      pw.Text(d.thankYouLabel, style: const pw.TextStyle(fontSize: 8.5, color: kPdfGreyLight)),
    ],
  );
}

/// Business logo widget shared by every header below. Respects the
/// document's real logoShape (circle/square/roundedSquare) instead of a
/// hardcoded circle, and uses BoxFit.contain on a very light neutral
/// background so a non-square logo is shown in full rather than cropped
/// -- see this file's LOGO PARITY PASS header comment for the full
/// rationale. Returns an empty SizedBox when there's no logo, so every
/// call site can include it unconditionally without its own null check.
pw.Widget _logoWidget(PdfDocData d, {double size = 56}) {
  if (d.logoImage == null) return pw.SizedBox();

  // Plain double radius (not a full BorderRadius object) since
  // pw.ClipRRect takes horizontalRadius/verticalRadius directly — mirrors
  // LogoShape.radiusFor() on the Flutter side (shared_logo_picker.dart)
  // without depending on a BorderRadius.topLeft accessor that may not
  // exist the same way in the pdf package as it does in Flutter.
  final radius = switch (d.logoShape) {
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
      child: pw.Image(d.logoImage!, fit: pw.BoxFit.contain),
    ),
  );
}

pw.Widget _metaValueRow(String label, String value, {PdfColor color = kPdfGrey, PdfColor valueColor = kPdfInk}) => pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Text(label, style: pw.TextStyle(fontSize: 9.5, color: color)),
    pw.Text(value.isEmpty ? '-' : value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: valueColor)),
  ],
);

pw.Widget _clientBlock(PdfDocData d, {PdfColor labelColor = kPdfGrey}) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(d.recipientLabel.toUpperCase(), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: labelColor)),
    pw.SizedBox(height: 8),
    pw.Text(d.clientName.isEmpty ? 'Client name' : d.clientName,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
    if (d.clientAddress.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(d.clientAddress, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey))],
    if (d.clientEmail.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(d.clientEmail, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey))],
    if (d.clientPhone.isNotEmpty) ...[pw.SizedBox(height: 2), pw.Text(d.clientPhone, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey))],
  ],
);

// ═════════════════════════════════════════════════════════════════════════
// 2. NORDIC — right-aligned wordmark, no logo, no rule, mirrored client
// block on the opposite (left) side. Direct port of nordic_template.dart's
// reworked _nordicFullHeader — this template deliberately has NO logo in
// the header and NO decorative rule of any kind, so unlike every other
// header in this file, _logoWidget is never called here.
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _nordicMetaStack(PdfDocData d) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(d.recipientLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: kPdfGreyLight, letterSpacing: 1.2)),
        pw.SizedBox(height: 7),
        pw.Text(d.clientName.isEmpty ? 'Client name' : d.clientName,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
        if (d.clientAddress.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(d.clientAddress, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGreyLight))],
        if (d.clientEmail.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(d.clientEmail, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGreyLight))],
        pw.SizedBox(height: 16),
        pw.Row(children: [
          _nordicInlineMeta(d.metaLabel1, d.metaValue1),
          pw.SizedBox(width: 28),
          _nordicInlineMeta(d.metaLabel2, d.metaValue2),
        ]),
      ],
    );

pw.Widget _nordicInlineMeta(String label, String value) => pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label ', style: pw.TextStyle(fontSize: 9, color: kPdfGreyLight)),
        pw.Text(value.isEmpty ? '-' : value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
      ],
    );

pw.Widget _nordicHeader(PdfDocData d) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
    pw.Text((d.businessName.isEmpty ? 'YOUR BUSINESS' : d.businessName).toUpperCase(),
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.normal, color: kPdfInk, letterSpacing: 4.0)),
    pw.SizedBox(height: 10),
    pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
      pw.Text(d.docTypeLabel, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfGrey, letterSpacing: 2.0)),
      pw.Text('  ·  ', style: const pw.TextStyle(fontSize: 10, color: kPdfGreyLight)),
      pw.Text(d.docNumber.isEmpty ? '-' : d.docNumber, style: pw.TextStyle(fontSize: 10, color: kPdfGrey, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(width: 10),
      pw.Text(d.statusLabel, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: d.statusColor, letterSpacing: 0.4)),
    ]),
    pw.SizedBox(height: 6),
    if (d.businessAddress.isNotEmpty)
      pw.Text(d.businessAddress, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9, color: kPdfGreyLight)),
    if (d.businessEmail.isNotEmpty || d.businessPhone.isNotEmpty)
      pw.Text([d.businessEmail, d.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
          textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9, color: kPdfGreyLight)),
    pw.SizedBox(height: 38),
    pw.Align(alignment: pw.Alignment.centerLeft, child: _nordicMetaStack(d)),
    pw.SizedBox(height: 32),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// 3. VIBRANT — solid accent panel, reversed white type
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _vibrantHeader(PdfDocData d) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: pw.BoxDecoration(color: d.accent, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        if (d.logoImage != null) ...[_logoWidget(d), pw.SizedBox(width: 14)],
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(d.businessName.isEmpty ? 'Your Business' : d.businessName,
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 6),
          if (d.businessAddress.isNotEmpty) pw.Text(d.businessAddress, style: pw.TextStyle(fontSize: 9, color: _alpha(PdfColors.white, 0.85))),
          if (d.businessEmail.isNotEmpty || d.businessPhone.isNotEmpty)
            pw.Text([d.businessEmail, d.businessPhone].where((s) => s.isNotEmpty).join('  -  '), style: pw.TextStyle(fontSize: 9, color: _alpha(PdfColors.white, 0.85))),
        ])),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(d.docTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.0)),
          pw.SizedBox(height: 6),
          pw.Text('#${d.docNumber.isEmpty ? '-' : d.docNumber}', style: pw.TextStyle(fontSize: 10, color: _alpha(PdfColors.white, 0.85), fontWeight: pw.FontWeight.bold)),
        ]),
      ]),
    ),
    pw.SizedBox(height: 24),
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Expanded(flex: 3, child: _clientBlock(d, labelColor: d.accent)),
      pw.SizedBox(width: 24),
      pw.Expanded(flex: 2, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _metaValueRow(d.metaLabel1, d.metaValue1),
        pw.SizedBox(height: 6),
        _metaValueRow(d.metaLabel2, d.metaValue2),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(color: d.statusColor, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Text(d.statusLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        ),
      ])),
    ]),
    pw.SizedBox(height: 24),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// 4. TECH DARK — terminal/console window chrome. Direct port of
// tech_dark_template.dart's reworked _techDarkFullHeader — replaces the
// old solid-dark-panel skeleton it used to share with Vibrant/Classic/
// Gradient Modern with a bordered "window" box: a dark title-bar strip
// (window-control dots + filename-style doc label), then a plain white
// body with a thin accent rail on the left and console-style "> label
// value" lines for client/meta info.
// ═════════════════════════════════════════════════════════════════════════

const PdfColor _kTechPanel = PdfColor.fromInt(0xFF14171C);
const PdfColor _kTechGrey = PdfColor.fromInt(0xFF9AA4B2);

pw.Widget _techDot(PdfColor c) => pw.Container(width: 9, height: 9, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: c));

pw.Widget _consoleLine(String label, String value, {bool bold = false}) => pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label  ', style: pw.TextStyle(fontSize: 9, color: _kTechGrey, letterSpacing: 0.3)),
        pw.Text(value, style: pw.TextStyle(fontSize: bold ? 11 : 9.5, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
      ],
    );

pw.Widget _techDarkHeader(PdfDocData d) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _alpha(kPdfInk, 0.14), width: 1.2), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          width: double.infinity,
          color: _kTechPanel,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: pw.Row(children: [
            _techDot(const PdfColor.fromInt(0xFFFF5F56)),
            pw.SizedBox(width: 6),
            _techDot(const PdfColor.fromInt(0xFFFFBD2E)),
            pw.SizedBox(width: 6),
            _techDot(const PdfColor.fromInt(0xFF27C93F)),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Text('${d.docTypeLabel.toLowerCase()}_${d.docNumber.isEmpty ? 'draft' : d.docNumber}.pdf',
                  style: const pw.TextStyle(fontSize: 9.5, color: _kTechGrey, letterSpacing: 0.4)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(color: _alpha(d.accent, 0.18), borderRadius: pw.BorderRadius.circular(3)),
              child: pw.Text(d.statusLabel.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: d.accent, letterSpacing: 0.6)),
            ),
          ]),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(14, 16, 16, 16),
          decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: d.accent, width: 3))),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              if (d.logoImage != null) ...[_logoWidget(d, size: 34), pw.SizedBox(width: 12)],
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text((d.businessName.isEmpty ? 'YOUR BUSINESS' : d.businessName).toUpperCase(),
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: kPdfInk, letterSpacing: 1.6)),
                pw.SizedBox(height: 4),
                if (d.businessAddress.isNotEmpty) pw.Text(d.businessAddress, style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
                if (d.businessEmail.isNotEmpty || d.businessPhone.isNotEmpty)
                  pw.Text([d.businessEmail, d.businessPhone].where((s) => s.isNotEmpty).join('  //  '), style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
              ])),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text(d.docTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: d.accent, letterSpacing: 2.0)),
                pw.SizedBox(height: 4),
                pw.Text('[ ${d.docNumber.isEmpty ? '----' : d.docNumber} ]', style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
              ]),
            ]),
            pw.SizedBox(height: 14),
            pw.Container(height: 1, color: _alpha(kPdfInk, 0.08)),
            pw.SizedBox(height: 12),
            _consoleLine('>', d.clientName.isEmpty ? 'Client name' : d.clientName, bold: true),
            if (d.clientEmail.isNotEmpty) ...[pw.SizedBox(height: 3), _consoleLine('>', d.clientEmail)],
            pw.SizedBox(height: 10),
            pw.Row(children: [
              _consoleLine(d.metaLabel1.toUpperCase(), d.metaValue1.isEmpty ? '-' : d.metaValue1),
              pw.SizedBox(width: 24),
              _consoleLine(d.metaLabel2.toUpperCase(), d.metaValue2.isEmpty ? '-' : d.metaValue2),
            ]),
          ]),
        ),
      ]),
    ),
    pw.SizedBox(height: 24),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// 5. CLASSIC — centered letterhead identity block + bordered mini-table
// box for doc type/number/meta/status. Direct port of classic_template.
// dart's reworked _classicFullHeader — replaces the old Row(logo|business
// |doctype) skeleton it used to share with Vibrant/Tech Dark/Gradient
// Modern. The shaded grey line-items header row below is unchanged.
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _classicBoxRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey)),
        pw.Text(value.isEmpty ? '-' : value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
      ]),
    );

pw.Widget _classicMetaBox(PdfDocData d) => pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: kPdfRule, width: 1), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _alpha(d.accent, 0.08),
            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(5)),
          ),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(d.docTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfInk, letterSpacing: 1.0)),
            pw.Text('#${d.docNumber.isEmpty ? '-' : d.docNumber}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: kPdfGrey)),
          ]),
        ),
        _classicBoxRow(d.metaLabel1, d.metaValue1),
        pw.Divider(height: 1, color: _alpha(kPdfRule, 0.6)),
        _classicBoxRow(d.metaLabel2, d.metaValue2),
        pw.Divider(height: 1, color: _alpha(kPdfRule, 0.6)),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Status', style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey)),
            pw.Text(d.statusLabel, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: d.statusColor)),
          ]),
        ),
      ]),
    );

pw.Widget _classicHeader(PdfDocData d) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Center(
      child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
        if (d.logoImage != null) ...[_logoWidget(d, size: 38), pw.SizedBox(height: 10)],
        pw.Text(d.businessName.isEmpty ? 'Your Business' : d.businessName,
            textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
        pw.SizedBox(height: 5),
        if (d.businessAddress.isNotEmpty)
          pw.Text(d.businessAddress, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
        if (d.businessEmail.isNotEmpty || d.businessPhone.isNotEmpty)
          pw.Text([d.businessEmail, d.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
              textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
      ]),
    ),
    pw.SizedBox(height: 18),
    pw.Container(height: 1, color: d.accent),
    pw.SizedBox(height: 2),
    pw.Container(height: 1, color: kPdfRule),
    pw.SizedBox(height: 24),
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Expanded(flex: 3, child: _clientBlock(d)),
      pw.SizedBox(width: 20),
      pw.Expanded(flex: 3, child: _classicMetaBox(d)),
    ]),
    pw.SizedBox(height: 24),
  ]);
}

pw.Widget _classicShadedLineHeader(PdfDocData d) => pw.Container(
      color: const PdfColor.fromInt(0xFFF3F4F6),
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: _sharedLineItemsHeaderRow(d.accent),
    );

// ═════════════════════════════════════════════════════════════════════════
// 6. GRADIENT MODERN — stat-card dashboard row. Direct port of
// gradient_modern_template.dart's reworked _gradientModernFullHeader —
// the gradient panel is gone; the identity block sits on plain white and
// every meta field (doc number, the two meta fields, status) renders as
// its own small elevated card in a horizontal wrap, like a dashboard
// summary strip.
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _statCard(String label, String value, {PdfColor? valueColor}) => pw.Container(
      margin: const pw.EdgeInsets.only(right: 10, bottom: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      constraints: const pw.BoxConstraints(minWidth: 88),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: kPdfRule),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: kPdfGreyLight, letterSpacing: 0.8)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: valueColor ?? kPdfInk)),
      ]),
    );

pw.Widget _gradientModernHeader(PdfDocData d) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      if (d.logoImage != null) ...[_logoWidget(d), pw.SizedBox(width: 14)],
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(d.businessName.isEmpty ? 'Your Business' : d.businessName, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
        pw.SizedBox(height: 6),
        if (d.businessAddress.isNotEmpty) pw.Text(d.businessAddress, style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
        if (d.businessEmail.isNotEmpty || d.businessPhone.isNotEmpty)
          pw.Text([d.businessEmail, d.businessPhone].where((s) => s.isNotEmpty).join('   ·   '), style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
      ])),
      pw.Text(d.docTypeLabel, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: d.accent, letterSpacing: 0.6)),
    ]),
    pw.SizedBox(height: 18),
    pw.Wrap(children: [
      _statCard('#', d.docNumber.isEmpty ? '-' : d.docNumber),
      _statCard(d.metaLabel1, d.metaValue1.isEmpty ? '-' : d.metaValue1),
      _statCard(d.metaLabel2, d.metaValue2.isEmpty ? '-' : d.metaValue2),
      _statCard('Status', d.statusLabel, valueColor: d.statusColor),
    ]),
    pw.SizedBox(height: 16),
    pw.Text(d.recipientLabel.toUpperCase(), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: kPdfGreyLight, letterSpacing: 1.2)),
    pw.SizedBox(height: 6),
    pw.Text(d.clientName.isEmpty ? 'Client name' : d.clientName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
    if (d.clientAddress.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(d.clientAddress, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey))],
    if (d.clientEmail.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(d.clientEmail, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey))],
    pw.SizedBox(height: 22),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// 7. EDITORIAL — two-column letterhead grid with a left spine bar. Direct
// port of editorial_template.dart's reworked _editorialFullHeader: a
// full-height accent bar down the left of the header, business identity
// in a left column, client + meta in a right column beside it (a genuine
// side-by-side grid, not stacked) — replaces the old big-heading masthead
// design.
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _editorialMetaLine(String label, String value) => pw.Row(children: [
      pw.Text('$label: ', style: const pw.TextStyle(fontSize: 9, color: kPdfGreyLight)),
      pw.Text(value.isEmpty ? '-' : value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
    ]);

pw.Widget _editorialHeader(PdfDocData d) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(d.docTypeLabel, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: d.accent, letterSpacing: 2.4)),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('No. ${d.docNumber.isEmpty ? '-' : d.docNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
        pw.SizedBox(height: 3),
        pw.Text(d.statusLabel, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: d.statusColor, letterSpacing: 0.4)),
      ]),
    ]),
    pw.SizedBox(height: 18),
    // Letterhead spine — a full-height bar beside the two-column grid,
    // not a rule under a line of text. crossAxisAlignment.stretch makes
    // the Container fill the Row's height, same as the Flutter version's
    // IntrinsicHeight+stretch combination.
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Container(width: 3, color: d.accent),
      pw.SizedBox(width: 18),
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        if (d.logoImage != null) ...[_logoWidget(d, size: 30), pw.SizedBox(height: 10)],
        pw.Text(d.businessName.isEmpty ? 'Your Business' : d.businessName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
        pw.SizedBox(height: 4),
        if (d.businessAddress.isNotEmpty) pw.Text(d.businessAddress, style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
        if (d.businessEmail.isNotEmpty || d.businessPhone.isNotEmpty)
          pw.Text([d.businessEmail, d.businessPhone].where((s) => s.isNotEmpty).join('\n'), style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
      ])),
      pw.SizedBox(width: 20),
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(d.recipientLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: kPdfGreyLight, letterSpacing: 1.4)),
        pw.SizedBox(height: 6),
        pw.Text(d.clientName.isEmpty ? 'Client name' : d.clientName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
        if (d.clientAddress.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(d.clientAddress, style: const pw.TextStyle(fontSize: 9, color: kPdfGrey))],
        pw.SizedBox(height: 12),
        _editorialMetaLine(d.metaLabel1, d.metaValue1),
        pw.SizedBox(height: 4),
        _editorialMetaLine(d.metaLabel2, d.metaValue2),
      ])),
    ]),
    pw.SizedBox(height: 26),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// 8. PASTEL SOFT — floating rounded pill/chip cluster, no panel anywhere.
// Direct port of pastel_soft_template.dart's reworked _pastelSoftFullHeader:
// every meta field (doc number, dates, status) is its own small rounded
// chip on a plain white background instead of one shared tinted panel.
//
// One deviation from the Flutter version: the chips there include small
// leading icons (tag/calendar/event). The `pdf` package doesn't have a
// matching built-in icon set for those glyphs, so the PDF chips are
// text-only — same chip shape and spacing, no icon.
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _pastelSoftHeader(PdfDocData d) {
  final chipBg = _tint(d.accent, 0.86); // approximates Color.alphaBlend(accent 14%, white)

  pw.Widget chip(String label) => pw.Container(
        margin: const pw.EdgeInsets.only(right: 8, bottom: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: pw.BoxDecoration(color: chipBg, borderRadius: pw.BorderRadius.circular(20)),
        child: pw.Text(label, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
      );

  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      if (d.logoImage != null) ...[_logoWidget(d, size: 36), pw.SizedBox(width: 12)],
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(d.businessName.isEmpty ? 'Your Business' : d.businessName, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
        pw.SizedBox(height: 3),
        if (d.businessAddress.isNotEmpty) pw.Text(d.businessAddress, style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
      ])),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(color: d.accent, borderRadius: pw.BorderRadius.circular(20)),
        child: pw.Text(d.docTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.8)),
      ),
    ]),
    pw.SizedBox(height: 20),
    pw.Wrap(children: [
      chip('#${d.docNumber.isEmpty ? '-' : d.docNumber}'),
      chip('${d.metaLabel1}: ${d.metaValue1.isEmpty ? '-' : d.metaValue1}'),
      chip('${d.metaLabel2}: ${d.metaValue2.isEmpty ? '-' : d.metaValue2}'),
      pw.Container(
        margin: const pw.EdgeInsets.only(right: 8, bottom: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: pw.BoxDecoration(color: _alpha(d.statusColor, 0.14), borderRadius: pw.BorderRadius.circular(20)),
        child: pw.Text(d.statusLabel, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: d.statusColor)),
      ),
    ]),
    pw.SizedBox(height: 16),
    pw.Text(d.recipientLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: kPdfGreyLight, letterSpacing: 1.2)),
    pw.SizedBox(height: 5),
    pw.Text(d.clientName.isEmpty ? 'Client name' : d.clientName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
    if (d.clientEmail.isNotEmpty) ...[pw.SizedBox(height: 2), pw.Text(d.clientEmail, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey))],
    pw.SizedBox(height: 22),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// 9. BRUTALIST — dark reversed-type recipient block + business/doc-type
// block. Direct port of brutalist_template.dart's reworked
// _brutalistFullHeader's content, minus the diagonal ribbon clip (the pdf
// package has no ClipPath equivalent — see this file's KNOWN LIMITATION
// note at the top). This header renders its OWN line-items header row
// (the dark SL./ITEM DESCRIPTION/QTY/PRICE/TOTAL bar below) — see the
// BRUTALIST DOUBLE-HEADER FIX note at the top for why buildStyledDocument
// must not also append the generic shared header row for this style.
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _brutalistKv(String k, String v) => pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
      pw.Text('$k  ', style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey)),
      pw.Text(v, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
    ]);

pw.Widget _brutalistLineItemsBar() => pw.Container(
      color: kPdfInk,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Row(children: [
        pw.SizedBox(width: 20, child: pw.Text('SL.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400))),
        pw.Expanded(flex: 5, child: pw.Text('ITEM DESCRIPTION', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400, letterSpacing: 0.6))),
        pw.Expanded(flex: 1, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400))),
        pw.Expanded(flex: 2, child: pw.Text('PRICE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400))),
        pw.Expanded(flex: 2, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400))),
      ]),
    );

pw.Widget _brutalistHeader(PdfDocData d) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      // Recipient block — reversed (white-on-dark) type. Flat rectangle
      // here rather than the Flutter version's diagonally-clipped ribbon
      // shape (see KNOWN LIMITATION note at top of file).
      pw.Expanded(
        flex: 3,
        child: pw.Container(
          color: kPdfInk,
          padding: const pw.EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(d.recipientLabel, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400, letterSpacing: 0.6)),
            pw.SizedBox(height: 8),
            pw.Text(d.clientName.isEmpty ? 'Client name' : d.clientName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            if (d.clientAddress.isNotEmpty) ...[pw.SizedBox(height: 4), pw.Text(d.clientAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300))],
            if (d.clientEmail.isNotEmpty) ...[pw.SizedBox(height: 2), pw.Text(d.clientEmail, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300))],
          ]),
        ),
      ),
      pw.SizedBox(width: 4),
      // Business identity + doc heading, plain white background.
      pw.Expanded(
        flex: 4,
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              if (d.logoImage != null) ...[_logoWidget(d, size: 26), pw.SizedBox(width: 8)],
              pw.Text(d.docTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: d.accent, letterSpacing: 1.0)),
            ]),
            pw.SizedBox(height: 10),
            _brutalistKv(
              '${d.docTypeLabel.length >= 3 ? d.docTypeLabel.substring(0, 3) : d.docTypeLabel}#',
              d.docNumber.isEmpty ? '-' : d.docNumber,
            ),
            pw.SizedBox(height: 3),
            _brutalistKv('Date', d.metaValue1.isEmpty ? '-' : d.metaValue1),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(color: _alpha(d.statusColor, 0.12), borderRadius: pw.BorderRadius.circular(3)),
              child: pw.Text(d.statusLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: d.statusColor, letterSpacing: 0.6)),
            ),
          ]),
        ),
      ),
    ]),
    pw.SizedBox(height: 20),
    _brutalistLineItemsBar(),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// 10. EMERALD — compact single-column stacked form. Direct port of
// emerald_template.dart's reworked _emeraldFullHeader: every field
// (business, client, dates, doc number) is a tight label-over-value
// stack in ONE narrow column — no left/right split, no logo-beside-name
// row (the logo sits above the business name instead).
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _emeraldField(String label, String value, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: kPdfGreyLight, letterSpacing: 1.0)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: bold ? 12.5 : 10.5, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
      ]),
    );

pw.Widget _emeraldFieldPlain(String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(value, style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey)),
    );

pw.Widget _emeraldFieldStack(PdfDocData d) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _emeraldField(d.recipientLabel, d.clientName.isEmpty ? 'Client name' : d.clientName, bold: true),
      if (d.clientAddress.isNotEmpty) _emeraldFieldPlain(d.clientAddress),
      if (d.clientEmail.isNotEmpty) _emeraldFieldPlain(d.clientEmail),
      pw.SizedBox(height: 12),
      _emeraldField(d.metaLabel1, d.metaValue1.isEmpty ? '—' : d.metaValue1),
      pw.SizedBox(height: 12),
      _emeraldField(d.metaLabel2, d.metaValue2.isEmpty ? '—' : d.metaValue2),
      pw.SizedBox(height: 12),
      _emeraldField('Doc No.', d.docNumber.isEmpty ? '—' : d.docNumber),
    ]);

pw.Widget _emeraldHeader(PdfDocData d) {
  // A4 page width is 595.28pt; buildStyledDocument uses 36pt margins on
  // each side, leaving ~523.28pt of content width. 62% of that mirrors
  // the Flutter template's kContentW * 0.62 field-column width. Written
  // as a plain literal rather than a PdfPageFormat constant reference,
  // since this file has no way to confirm that exact static member name
  // against the installed `pdf` package version without running the
  // build.
  const contentW = 523.28;
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(color: _alpha(d.accent, 0.10), borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Text(d.docTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: d.accent, letterSpacing: 1.6)),
      ),
      pw.Text(d.statusLabel, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: d.statusColor, letterSpacing: 0.4)),
    ]),
    pw.SizedBox(height: 22),
    if (d.logoImage != null) ...[_logoWidget(d, size: 30), pw.SizedBox(height: 10)],
    pw.Text(d.businessName.isEmpty ? 'Your Business' : d.businessName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
    if (d.businessAddress.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(d.businessAddress, style: const pw.TextStyle(fontSize: 9, color: kPdfGrey))],
    if (d.businessEmail.isNotEmpty || d.businessPhone.isNotEmpty) ...[
      pw.SizedBox(height: 2),
      pw.Text([d.businessEmail, d.businessPhone].where((s) => s.isNotEmpty).join('   ·   '), style: const pw.TextStyle(fontSize: 9, color: kPdfGrey)),
    ],
    pw.SizedBox(height: 22),
    pw.Container(height: 1, color: kPdfRule),
    pw.SizedBox(height: 20),
    pw.SizedBox(width: contentW * 0.62, child: _emeraldFieldStack(d)),
    pw.SizedBox(height: 26),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// Entry point — called by each PDF service's dispatcher for styleId 2-10.
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _headerFor(int styleId, PdfDocData d) {
  switch (styleId) {
    case 2: return _nordicHeader(d);
    case 3: return _vibrantHeader(d);
    case 4: return _techDarkHeader(d);
    case 5: return pw.Column(children: [_classicHeader(d), _classicShadedLineHeader(d)]);
    case 6: return _gradientModernHeader(d);
    case 7: return _editorialHeader(d);
    case 8: return _pastelSoftHeader(d);
    case 9: return _brutalistHeader(d);
    case 10: return _emeraldHeader(d);
    default: return _nordicHeader(d);
  }
}

Future<List<int>> buildStyledDocument(PdfDocData d, int styleId) async {
  final pdf = pw.Document();
  // Classic (5) and Brutalist (9) both render their own line-items header
  // row inline as part of the header widget itself, so the table body
  // below must skip re-rendering the generic shared header row on top of
  // it — see the BRUTALIST DOUBLE-HEADER FIX note at the top of this file
  // for why style 9 was added here.
  final needsOwnTable = styleId != 5 && styleId != 9;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => [
        _headerFor(styleId, d),
        if (needsOwnTable) _sharedLineItemsTable(d) else _sharedLineItemsTableBodyOnly(d),
        _sharedTotalsAndNotes(d),
      ],
    ),
  );

  return pdf.save();
}

// Classic/Brutalist's headers already render their own (shaded/dark) line
// items header row, so the table body here skips re-rendering another
// header row on top of it.
pw.Widget _sharedLineItemsTableBodyOnly(PdfDocData d) {
  return pw.Column(children: [
    for (final item in d.lineItems)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 9),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: kPdfRule, width: 0.75))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(flex: 5, child: pw.Text(
              item.description.isEmpty ? 'Item description' : item.description,
              style: const pw.TextStyle(fontSize: 10, color: kPdfInk))),
          pw.Expanded(flex: 1, child: pw.Text(_fmtQty(item.quantity), textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10, color: kPdfGrey))),
          pw.Expanded(flex: 2, child: pw.Text(d.fmtMoney(item.unitPrice), textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 10, color: kPdfGrey))),
          pw.Expanded(flex: 2, child: pw.Text(d.fmtMoney(item.total), textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfInk))),
        ]),
      ),
  ]);
}
