// shared_doc_widgets.dart
// lib/doc_templates/shared/shared_doc_widgets.dart
//
// The parts of a document that are visually identical across every
// template design (line-item row, totals/notes/footer block) plus the
// generic A4Paginator wiring, written once here instead of once per
// template per doc type. A template design file only needs to supply
// buildFullHeader/buildContinuationHeader (the part that's actually
// supposed to look different) and hand everything else to
// TemplateDocument below.
//
// Geometry and palette values match executive_page_stationary_layout.dart
// exactly (confirmed identical across invoice/quote/receipt's Executive
// copies) so new templates sit at the same size/proportions as Executive.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show LineItem;
import 'doc_template_adapter.dart';
import '../../invoice_layout_templates/pagination/a4_paginator.dart';
import '../../invoice_layout_templates/pagination/doc_field.dart';

// â”€â”€ Page geometry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const double kPageW    = 595.0;
const double kPageH    = 842.0;
const double kPagePadH = 48.0;
const double kPagePadV = 48.0;
const double kContentW = kPageW - kPagePadH * 2;

// â”€â”€ Palette â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const Color kInk       = Color(0xFF16181D);
const Color kGrey      = Color(0xFF6B7280);
const Color kGreyLight = Color(0xFF9CA3AF);
const Color kRule      = Color(0xFFE5E7EB);
const Color kPanelBg   = Color(0xFFF9FAFB);

const Map<String, String> _kCurrencySymbols = {
  'USD': '\$', 'NZD': '\$', 'AUD': '\$', 'CAD': '\$',
  'GBP': 'Â£', 'EUR': 'â‚¬', 'JPY': 'Â¥',
};

String fmtMoney(String currency, double v) {
  final sym = _kCurrencySymbols[currency.toUpperCase()];
  final prefix = sym ?? '${currency.toUpperCase()} ';
  return '$prefix${v.toStringAsFixed(2)}';
}

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Column header row above line items â€” shared, since it only needs accent.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Widget buildSharedLineItemsHeaderRow({required Color accent, required String ff}) {
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: kGrey, letterSpacing: 1.0, fontFamily: ff);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: accent, width: 1.5))),
    child: Row(children: [
      Expanded(flex: 5, child: Text('DESCRIPTION', style: hdr)),
      Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
      Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: hdr)),
      Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
    ]),
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// One line-item row â€” fed into A4Paginator's `items` list. Read-only only
// (no edit bundle) â€” this whole shared path is for preview/chooser
// rendering, not the WYSIWYG edit canvas.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Widget buildSharedLineItemRow({
  required LineItem item,
  required String currency,
  required String ff,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kRule, width: 0.75))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: Text(
          item.description.isEmpty ? 'Item description' : item.description,
          style: TextStyle(fontSize: 10, color: kInk, height: 1.4, fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible)),
      Expanded(flex: 1, child: Text(_fmtQty(item.quantity), textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 2, child: Text(fmtMoney(currency, item.unitPrice), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 2, child: Text(fmtMoney(currency, item.total), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff))),
    ]),
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Footer (last page only): totals block, notes panel, thank-you line.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Widget buildSharedFooterSection(DocTemplateAdapter a) {
  Widget row(String label, double v, {bool bold = false, bool negative = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: bold ? 11 : 10,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: bold ? kInk : kGrey, fontFamily: a.fontFamily)),
      Text('${negative ? 'âˆ’' : ''}${fmtMoney(a.currency, v)}',
          style: TextStyle(fontSize: bold ? 13 : 10.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? a.accent : kInk, fontFamily: a.fontFamily)),
    ]),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: kContentW * 0.42,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            row('Subtotal', a.subtotal),
            if (a.discountRate > 0)
              row('Discount (${a.discountRate.toStringAsFixed(0)}%)', a.discountAmount, negative: true),
            if (a.taxRate > 0)
              row('Tax (${a.taxRate.toStringAsFixed(0)}%)', a.taxAmount),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, color: kRule)),
            row(a.totalLabel, a.total, bold: true),
          ]),
        ),
      ),
      if (a.notes.trim().isNotEmpty) ...[
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kPanelBg, borderRadius: BorderRadius.circular(6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('NOTES', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                color: kGrey, letterSpacing: 1.2, fontFamily: a.fontFamily)),
            const SizedBox(height: 6),
            Text(a.notes, style: TextStyle(fontSize: 9.5, color: kInk, height: 1.5, fontFamily: a.fontFamily),
                softWrap: true, overflow: TextOverflow.visible),
          ]),
        ),
      ],
      const SizedBox(height: 32),
      Container(height: 0.75, color: kRule),
      const SizedBox(height: 10),
      Text(a.thankYouLabel, style: TextStyle(fontSize: 8.5, color: kGreyLight, fontFamily: a.fontFamily)),
    ],
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// TemplateDocument â€” generic A4Paginator wiring. Every new template design
// hands its buildFullHeader/buildContinuationHeader to this instead of
// re-wiring A4Paginator itself (matches how executive_cv_logic_data.dart
// wires A4Paginator, just parameterised over the header builders).
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
typedef HeaderBuilder = Widget Function(DocTemplateAdapter adapter);

class TemplateDocument extends StatelessWidget {
  final DocTemplateAdapter adapter;
  final HeaderBuilder buildFullHeader;
  final HeaderBuilder buildContinuationHeader;
  final void Function(int pageCount)? onPageCount;

  const TemplateDocument({
    super.key,
    required this.adapter,
    required this.buildFullHeader,
    required this.buildContinuationHeader,
    this.onPageCount,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final item in adapter.lineItems)
        buildSharedLineItemRow(item: item, currency: adapter.currency, ff: adapter.fontFamily),
    ];

    return A4Paginator(
      pageWidth: kPageW,
      pageHeight: kPageH,
      contentWidth: kContentW,
      pagePadding: const EdgeInsets.symmetric(horizontal: kPagePadH, vertical: kPagePadV),
      items: items,
      onPageCount: onPageCount,
      headerBuilder: (pageIndex, pageCount) =>
          pageIndex == 0 ? buildFullHeader(adapter) : buildContinuationHeader(adapter),
      footerBuilder: (pageIndex, pageCount) =>
          pageIndex == pageCount - 1 ? buildSharedFooterSection(adapter) : const SizedBox.shrink(),
    );
  }
}
