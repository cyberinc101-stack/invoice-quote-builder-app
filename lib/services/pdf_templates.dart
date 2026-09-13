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
// SHARED/EXECUTIVE PARITY PASS — PDF SIDE (this update): brings the
// shared line-item table and totals block (used by ALL 9 non-Executive
// PDF exports) up to full parity with what invoice_pdf_service.dart's
// _buildExecutivePdf already does, and with the Flutter preview side's
// shared_doc_widgets.dart (Phase 1/2 of that same parity work). Four
// changes:
//   1. UNIT column — _sharedLineItemsHeaderRow/_sharedLineItemsTable/
//      _sharedLineItemsTableBodyOnly now compute the same
//      showDiscountCol/showTaxCol/showUnitCol flags (via the new
//      _pdfColumnFlags helper) and add matching columns, gated on
//      whether any line item actually uses that data — mirrors
//      lineItemColumnFlags()/sharedLineItemColumnFlags() on the Flutter
//      side.
//   2. Signed + named tax/discount — _itemBadges now shows a minus sign
//      for a withholding-style item tax (itemTaxIsAddition == false) and
//      includes the item's own itemTaxName/itemDiscountName (abbreviated
//      via a local port of the same _kRateNameAbbreviations table
//      Executive/the Flutter shared widgets use), instead of always
//      reading as a plain unnamed addition.
//   3. Correct net total — every line-item row's Total cell now shows
//      netTotal (item.total, minus its own discount, plus/minus its own
//      signed tax) instead of the plain item.total (qty x price) figure.
//      This was the same bug invoice_pdf_service.dart's Executive builder
//      already fixed for itself; the other 9 styles never got the fix.
//   4. Grouped-by-name totals — _sharedTotalsAndNotes' "Item Discounts"/
//      "Item Tax" rows now loop over PdfDocData.itemDiscountExtraByName/
//      itemTaxExtraByName (see pdf_doc_adapter.dart's matching pass)
//      instead of showing one lumped flat figure.
//
// KNOWN LIMITATION (carried forward, now more relevant): PdfDocData has
// no enabledFields-equivalent map, so unlike the Flutter preview side
// (docFieldOn()) or Executive's own PDF builder (_on()), the UNIT/
// DISCOUNT/TAX columns here are gated purely on "does any line item
// actually carry this data" — there is no way at this layer to also
// respect a user's "hide discount column" template toggle the way the
// Flutter preview does. Closing that gap fully would mean adding an
// enabledFields map to PdfDocData and threading a docFieldOn-equivalent
// through every one of the 9 header builders below, which is a larger,
// separate change from the data-correctness fix this pass makes.
//
// PER-ITEM TAX/DISCOUNT TOTALS PASS (earlier): _sharedTotalsAndNotes
// gained two conditional rows — "Item Discounts" and "Item Tax" — sourced
// from PdfDocData.itemDiscountExtra/itemTaxExtra. SUPERSEDED by the
// grouped-by-name version above.
//
// TEN-TEMPLATE PARITY PASS (earlier): five Flutter templates (Nordic,
// Editorial, Pastel Soft, Brutalist, Emerald) were reworked in an earlier
// pass to be structurally distinct from one another, but this file was
// never updated to match — it was still rendering each of those five
// templates' OLD pre-rework designs. _nordicHeader, _editorialHeader,
// _pastelSoftHeader, _brutalistHeader, and _emeraldHeader are all direct
// ports of each template's current Flutter header. _vibrantHeader,
// _techDarkHeader, _classicHeader, and _gradientModernHeader are
// untouched — those four Flutter templates haven't been reworked, so
// their existing PDF headers still match.
//
// KNOWN LIMITATION: Brutalist's Flutter header uses a diagonal ClipPath.
// The `pdf` package has no equivalent path-clipping widget, so
// _brutalistHeader below renders the same content as a plain rectangle
// instead of the angled ribbon shape.
//
// BRUTALIST DOUBLE-HEADER FIX (earlier): style 9 was added to the
// needsOwnTable exclusion, same pattern Classic already uses, so
// Brutalist's table body renders once, under its own header row only.
//
// LOGO PARITY PASS (earlier): _logoWidget is now called from every
// header (not just Vibrant), clips to the document's real logoShape, and
// sits on a very light neutral background rather than solid white.
//
// CURRENCY DISPLAY PASS (earlier): every call site uses d.fmtMoney(v)
// (PdfDocData's own method) instead of a hardcoded currency lookup.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice_data.dart' show LineItem, unitDisplayLabel;
import 'pdf_doc_adapter.dart';

// ── Palette (mirrors document_layout_templates/document_template_layout_data/doc_header.dart) ─────────
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

// SHARED/EXECUTIVE PARITY PASS — PDF SIDE: local port of the same
// preset-name -> abbreviation table used by Executive and the Flutter
// shared widgets (shared_doc_widgets.dart's now-public
// abbreviateRateName()). Duplicated here rather than shared across
// packages, since this file has no import path into the Flutter widget
// tree's shared file.
const Map<String, String> _kRateNameAbbreviations = {
  'gst': 'GST',
  'vat': 'VAT',
  'sales tax': 'ST',
  'hst': 'HST',
  'pst': 'PST',
  'withholding tax': 'WHT',
  'trade discount': 'TD',
  'early payment discount': 'EPD',
  'bulk discount': 'BD',
  'loyalty discount': 'LD',
};

String _abbreviateRateName(String name) =>
    _kRateNameAbbreviations[name.trim().toLowerCase()] ?? name.trim();

// SHARED/EXECUTIVE PARITY PASS — PDF SIDE: whether the Discount/Tax/Unit
// columns should render at all — gated purely on "does any line item
// actually carry this data" (see this file's KNOWN LIMITATION note above
// for why there's no enabledFields toggle check here, unlike the Flutter
// side). Computed once per document so header and every row show/hide
// the same columns.
({bool showDiscountCol, bool showTaxCol, bool showUnitCol}) _pdfColumnFlags(PdfDocData d) => (
  showDiscountCol: d.lineItems.any((i) => i.discountEnabled),
  showTaxCol: d.lineItems.any((i) => i.taxEnabled),
  showUnitCol: d.lineItems.any((i) => i.unit.trim().isNotEmpty),
);

// SHARED/EXECUTIVE PARITY PASS — PDF SIDE: small pill badges under a
// line item's description when that item carries its own tax/discount
// rate. Now shows the item's own rate name (abbreviated) when set, and
// the tax badge shows a minus sign for a withholding-style rate instead
// of always reading as a plain addition — mirrors the identical fix
// applied to the Flutter side's Editorial/Pastel Soft/Emerald/Brutalist
// badge rendering.
const PdfColor _kTaxChipBg  = PdfColor.fromInt(0xFFE3F2FD);
const PdfColor _kTaxChipFg  = PdfColor.fromInt(0xFF1565C0);
const PdfColor _kDiscChipBg = PdfColor.fromInt(0xFFFFF3E0);
const PdfColor _kDiscChipFg = PdfColor.fromInt(0xFFEF6C00);

pw.Widget _itemBadgeChip(String label, {required PdfColor bg, required PdfColor fg}) => pw.Container(
  margin: const pw.EdgeInsets.only(right: 6),
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(8)),
  child: pw.Text(label, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: fg)),
);

pw.Widget _itemBadges(LineItem item) {
  if (!item.taxEnabled && !item.discountEnabled) return pw.SizedBox();

  String taxLabel = '';
  if (item.taxEnabled) {
    final sign = item.itemTaxIsAddition ? '' : '-';
    final rateText = '$sign${_fmtPct(item.itemTaxRate)}%';
    final name = item.itemTaxName.trim();
    taxLabel = name.isEmpty ? 'Tax $rateText' : '${_abbreviateRateName(name)} $rateText';
  }
  String discLabel = '';
  if (item.discountEnabled) {
    final rateText = '-${_fmtPct(item.itemDiscountRate)}%';
    final name = item.itemDiscountName.trim();
    discLabel = name.isEmpty ? rateText : '${_abbreviateRateName(name)} $rateText';
  }

  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 4),
    child: pw.Wrap(children: [
      if (item.taxEnabled) _itemBadgeChip(taxLabel, bg: _kTaxChipBg, fg: _kTaxChipFg),
      if (item.discountEnabled) _itemBadgeChip(discLabel, bg: _kDiscChipBg, fg: _kDiscChipFg),
    ]),
  );
}

// Per-row net total — item.total, minus its own discount, plus/minus its
// own signed tax. Mirrors LineItem.lineNetTotal / invoice_pdf_service.
// dart's Executive builder / shared_doc_widgets.dart's buildSharedLineItemRow
// exactly. This is the fix that makes a row's printed Total actually
// reflect its own per-item discount/tax instead of the plain qty*price
// base figure.
double _netTotal(LineItem item) {
  final itemDiscountAmt = item.discountEnabled ? item.total * item.itemDiscountRate / 100 : 0.0;
  final itemTaxAmt      = item.taxEnabled      ? item.total * item.itemTaxRate      / 100 : 0.0;
  final signedTaxAmt = item.taxEnabled
      ? (item.itemTaxIsAddition ? itemTaxAmt : -itemTaxAmt)
      : 0.0;
  return item.total - itemDiscountAmt + signedTaxAmt;
}

// ── Shared line items header row / rows / totals / notes / footer ──────────

// SHARED/EXECUTIVE PARITY PASS — PDF SIDE: now takes the document (was
// just the accent color) so it can compute _pdfColumnFlags(d) and add
// UNIT/DISCOUNT/TAX header cells matching whatever the data rows below
// actually render.
pw.Widget _sharedLineItemsHeaderRow(PdfDocData d) {
  final flags = _pdfColumnFlags(d);
  final hdr = pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: kPdfGrey);
  final trailing = <pw.Widget>[
    pw.Expanded(flex: 2, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: hdr)),
    if (flags.showUnitCol)
      pw.Expanded(flex: 2, child: pw.Text('UNIT', textAlign: pw.TextAlign.center, style: hdr)),
    pw.Expanded(flex: 2, child: pw.Text('UNIT PRICE', textAlign: pw.TextAlign.right, style: hdr)),
    if (flags.showDiscountCol)
      pw.Expanded(flex: 2, child: pw.Text('DISCOUNT', textAlign: pw.TextAlign.right, style: hdr)),
    if (flags.showTaxCol)
      pw.Expanded(flex: 2, child: pw.Text('TAX', textAlign: pw.TextAlign.right, style: hdr)),
    pw.Expanded(flex: 2, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: hdr)),
  ];
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 8),
    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: d.accent, width: 1.5))),
    child: pw.Row(children: [
      pw.Expanded(flex: 5, child: pw.Text('DESCRIPTION', style: hdr)),
      pw.SizedBox(width: 10),
      for (final (i, w) in trailing.indexed) ...[if (i > 0) pw.SizedBox(width: 10), w],
    ]),
  );
}

pw.Widget _rateCellPdf(PdfDocData d, {
  required bool enabled,
  required double amount,
  required double rate,
  required bool negative,
  required String name,
}) {
  if (!enabled) return pw.SizedBox();
  final trimmedName = name.trim();
  final displayName = _abbreviateRateName(trimmedName);
  final rateText = '${_fmtPct(rate)}%';
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Text('${negative ? '-' : ''}${d.fmtMoney(amount)}',
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
      pw.Text(trimmedName.isEmpty ? rateText : '$displayName ($rateText)',
          textAlign: pw.TextAlign.right,
          style: const pw.TextStyle(fontSize: 7.5, color: kPdfInk)),
    ],
  );
}

// SHARED/EXECUTIVE PARITY PASS — PDF SIDE: builds each row's trailing
// cells from _pdfColumnFlags(d) — UNIT (when any item has one), DISCOUNT/
// TAX rate cells (signed, named), and a TOTAL cell showing _netTotal(item)
// instead of the plain item.total.
pw.Widget _sharedLineItemsTable(PdfDocData d) {
  final flags = _pdfColumnFlags(d);
  return pw.Column(children: [
    _sharedLineItemsHeaderRow(d),
    for (final item in d.lineItems)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 9),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: kPdfRule, width: 0.75))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(flex: 5, child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                  item.description.isEmpty ? 'Item description' : item.description,
                  style: const pw.TextStyle(fontSize: 10, color: kPdfInk)),
              _itemBadges(item),
            ],
          )),
          pw.SizedBox(width: 10),
          for (final (i, w) in <pw.Widget>[
            pw.Expanded(flex: 2, child: pw.Text(_fmtQty(item.quantity), textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10, color: kPdfGrey))),
            if (flags.showUnitCol)
              pw.Expanded(flex: 2, child: pw.Text(
                  item.unit.isEmpty ? '' : unitDisplayLabel(item.unit, customUnitLabel: item.customUnitLabel),
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 9.5, color: kPdfInk))),
            pw.Expanded(flex: 2, child: pw.Text(d.fmtMoney(item.unitPrice), textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 10, color: kPdfGrey))),
            if (flags.showDiscountCol)
              pw.Expanded(flex: 2, child: _rateCellPdf(d,
                  enabled: item.discountEnabled,
                  amount: item.discountEnabled ? item.total * item.itemDiscountRate / 100 : 0.0,
                  rate: item.itemDiscountRate, negative: true, name: item.itemDiscountName)),
            if (flags.showTaxCol)
              pw.Expanded(flex: 2, child: _rateCellPdf(d,
                  enabled: item.taxEnabled,
                  amount: item.taxEnabled ? item.total * item.itemTaxRate / 100 : 0.0,
                  rate: item.itemTaxRate, negative: !item.itemTaxIsAddition, name: item.itemTaxName)),
            pw.Expanded(flex: 2, child: pw.Text(d.fmtMoney(_netTotal(item)), textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfInk))),
          ].indexed) ...[
            if (i > 0) pw.SizedBox(width: 10),
            w,
          ],
        ]),
      ),
  ]);
}

pw.Widget _sharedTotalsAndNotes(PdfDocData d) {
  // OVERFLOW SAFETY PASS: label and value wrap in pw.Flexible instead of
  // plain pw.Text, so a long translated label or an unusually large
  // formatted total can shrink to fit instead of throwing a layout
  // overflow.
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
                fontWeight: pw.FontWeight.bold,
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
            // SHARED/EXECUTIVE PARITY PASS — PDF SIDE: grouped-by-name
            // rows, replacing the old single lumped itemDiscountExtra/
            // itemTaxExtra figure. Mirrors Executive's own PDF totals
            // (invoice_pdf_service.dart) and the Flutter shared widgets
            // exactly.
            for (final entry in d.itemDiscountExtraByName.entries)
              if (entry.value > 0)
                row(entry.key.isEmpty ? 'Item Discounts' : 'Item Discounts (${entry.key})',
                    entry.value, negative: true),
            for (final entry in d.itemTaxExtraByName.entries)
              if (entry.value != 0)
                row(entry.key.isEmpty ? 'Item Tax' : 'Item Tax (${entry.key})',
                    entry.value.abs(), negative: entry.value < 0),
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
/// background so a non-square logo is shown in full rather than cropped.
/// Returns an empty SizedBox when there's no logo, so every call site
/// can include it unconditionally without its own null check.
pw.Widget _logoWidget(PdfDocData d, {double size = 56}) {
  if (d.logoImage == null) return pw.SizedBox();

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
// block on the opposite (left) side.
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
// 4. TECH DARK — terminal/console window chrome.
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
// box for doc type/number/meta/status.
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
      child: _sharedLineItemsHeaderRow(d),
    );

// ═════════════════════════════════════════════════════════════════════════
// 6. GRADIENT MODERN — stat-card dashboard row.
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
// 7. EDITORIAL — two-column letterhead grid with a left spine bar.
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
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _pastelSoftHeader(PdfDocData d) {
  final chipBg = _tint(d.accent, 0.86);

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
// block. Renders its OWN line-items header row.
// ═════════════════════════════════════════════════════════════════════════

pw.Widget _brutalistKv(String k, String v) => pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
      pw.Text('$k  ', style: const pw.TextStyle(fontSize: 9.5, color: kPdfGrey)),
      pw.Text(v, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: kPdfInk)),
    ]);

// SHARED/EXECUTIVE PARITY PASS — PDF SIDE: Brutalist's dark bar now
// takes the document and adds UNIT/DISCOUNT/TAX columns matching
// _pdfColumnFlags(d), same shape _sharedLineItemsTableBodyOnly's rows use
// below it.
pw.Widget _brutalistLineItemsBar(PdfDocData d) {
  final flags = _pdfColumnFlags(d);
  final hdr = pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400);
  final trailing = <pw.Widget>[
    pw.Expanded(flex: 2, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: hdr)),
    if (flags.showUnitCol)
      pw.Expanded(flex: 2, child: pw.Text('UNIT', textAlign: pw.TextAlign.center, style: hdr)),
    pw.Expanded(flex: 2, child: pw.Text('PRICE', textAlign: pw.TextAlign.right, style: hdr)),
    if (flags.showDiscountCol)
      pw.Expanded(flex: 2, child: pw.Text('DISCOUNT', textAlign: pw.TextAlign.right, style: hdr)),
    if (flags.showTaxCol)
      pw.Expanded(flex: 2, child: pw.Text('TAX', textAlign: pw.TextAlign.right, style: hdr)),
    pw.Expanded(flex: 2, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: hdr)),
  ];
  return pw.Container(
    color: kPdfInk,
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: pw.Row(children: [
      pw.SizedBox(width: 20, child: pw.Text('SL.', style: hdr)),
      pw.Expanded(flex: 5, child: pw.Text('ITEM DESCRIPTION', style: hdr.copyWith(letterSpacing: 0.6))),
      pw.SizedBox(width: 10),
      for (final (i, w) in trailing.indexed) ...[if (i > 0) pw.SizedBox(width: 10), w],
    ]),
  );
}

pw.Widget _brutalistHeader(PdfDocData d) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
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
    _brutalistLineItemsBar(d),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════
// 10. EMERALD — compact single-column stacked form.
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
  // it.
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
//
// SHARED/EXECUTIVE PARITY PASS — PDF SIDE: same four fixes as
// _sharedLineItemsTable above — UNIT/DISCOUNT/TAX columns via
// _pdfColumnFlags(d), signed+named rate cells, and netTotal instead of
// plain item.total.
pw.Widget _sharedLineItemsTableBodyOnly(PdfDocData d) {
  final flags = _pdfColumnFlags(d);
  return pw.Column(children: [
    for (final item in d.lineItems)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 9),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: kPdfRule, width: 0.75))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(flex: 5, child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                  item.description.isEmpty ? 'Item description' : item.description,
                  style: const pw.TextStyle(fontSize: 10, color: kPdfInk)),
              _itemBadges(item),
            ],
          )),
          pw.SizedBox(width: 10),
          for (final (i, w) in <pw.Widget>[
            pw.Expanded(flex: 2, child: pw.Text(_fmtQty(item.quantity), textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10, color: kPdfGrey))),
            if (flags.showUnitCol)
              pw.Expanded(flex: 2, child: pw.Text(
                  item.unit.isEmpty ? '' : unitDisplayLabel(item.unit, customUnitLabel: item.customUnitLabel),
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 9.5, color: kPdfInk))),
            pw.Expanded(flex: 2, child: pw.Text(d.fmtMoney(item.unitPrice), textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 10, color: kPdfGrey))),
            if (flags.showDiscountCol)
              pw.Expanded(flex: 2, child: _rateCellPdf(d,
                  enabled: item.discountEnabled,
                  amount: item.discountEnabled ? item.total * item.itemDiscountRate / 100 : 0.0,
                  rate: item.itemDiscountRate, negative: true, name: item.itemDiscountName)),
            if (flags.showTaxCol)
              pw.Expanded(flex: 2, child: _rateCellPdf(d,
                  enabled: item.taxEnabled,
                  amount: item.taxEnabled ? item.total * item.itemTaxRate / 100 : 0.0,
                  rate: item.itemTaxRate, negative: !item.itemTaxIsAddition, name: item.itemTaxName)),
            pw.Expanded(flex: 2, child: pw.Text(d.fmtMoney(_netTotal(item)), textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kPdfInk))),
          ].indexed) ...[
            if (i > 0) pw.SizedBox(width: 10),
            w,
          ],
        ]),
      ),
  ]);
}