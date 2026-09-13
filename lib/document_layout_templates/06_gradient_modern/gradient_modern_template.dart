// gradient_modern_template.dart
// lib/document_layout_templates/06_gradient_modern/gradient_modern_template.dart
//
// ITEMS-HEADER-ROW PASS (this update): _gradientModernFullHeader and
// _gradientModernContinuationHeader no longer call
// _gradientWaveHeaderRow() themselves — that custom banner row is now
// supplied via buildLineItemsHeaderRow on every Preview class below, and
// A4Paginator decides per page whether to actually show it (skipped on a
// totals-only overflow page with zero items). See a4_paginator.dart's
// header comment for the bug this fixes.
//
// UNUSED-IMPORT CLEANUP PASS (earlier): doc_line_items.dart and
// doc_totals.dart removed — sharedLineItemColumnFlags/kInk/kGrey etc all
// come from the bare doc_header.dart import below; nothing here was ever
// actually used from either removed import.
//
// SHARED/EXECUTIVE PARITY PASS — PHASE 2 (earlier): _gradientWaveHeaderRow
// now takes the adapter and builds its trailing columns from
// sharedLineItemColumnFlags(a) so DESCRIPTION/QTY/[UNIT]/UNIT PRICE/
// [DISCOUNT]/[TAX]/TOTAL always land exactly where the real data row
// (the shared default — Gradient Modern supplies no buildLineItemRow
// override) places them.
//
// CODESO REFERENCE REDESIGN PASS (earlier): two-column header — left:
// logo + business name, doc-type heading, doc number + both meta fields;
// right: recipient block.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../document_template_layout_data/doc_template_adapter.dart';
import '../document_template_layout_data/doc_header.dart';
import '../document_template_layout_data/template_document.dart';

// SHARED/EXECUTIVE PARITY PASS: matches shared_doc_widgets.dart's private
// kColGap value exactly (10.0) — kept as a local copy since that constant
// isn't exported, and this banner needs the identical gap so its columns
// land at the same x-positions as the real data row beneath it.
const double _kGapW = 10.0;

List<Widget> _withGaps(List<Widget> columns) {
  final out = <Widget>[];
  for (var i = 0; i < columns.length; i++) {
    if (i > 0) out.add(const SizedBox(width: _kGapW));
    out.add(columns[i]);
  }
  return out;
}

// -----------------------------------------------------------------------
// Small accent-caption / dark-value line, used for the recipient block's
// address/email/phone rows.
// -----------------------------------------------------------------------
Widget _clientDetailLine(String label, String value, Color accent, String ff) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 7.5, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.8, fontFamily: ff)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );

// -----------------------------------------------------------------------
// Signature device: gradient banner (near-black -> accent) with a fully
// rounded right end, carrying the line-item column labels in white.
// -----------------------------------------------------------------------
Widget _gradientWaveHeaderRow({required DocTemplateAdapter adapter}) {
  final ff = adapter.fontFamily;
  final accent = adapter.accent;
  final flags = sharedLineItemColumnFlags(adapter);
  final hdr = TextStyle(
      fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0, fontFamily: ff);

  final trailingCols = <Widget>[
    Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
    if (flags.showUnitCol)
      Expanded(flex: 2, child: Text('UNIT', textAlign: TextAlign.center, style: hdr)),
    Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: hdr)),
    if (flags.showDiscountCol)
      Expanded(flex: 2, child: Text('DISCOUNT', textAlign: TextAlign.right, style: hdr)),
    if (flags.showTaxCol)
      Expanded(flex: 2, child: Text('TAX', textAlign: TextAlign.right, style: hdr)),
    Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
  ];

  return Container(
    constraints: const BoxConstraints(minHeight: 34),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [kInk, accent], begin: Alignment.centerLeft, end: Alignment.centerRight),
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(17)),
    ),
    child: Row(children: [
      Expanded(flex: 5, child: Text('DESCRIPTION', style: hdr)),
      const SizedBox(width: _kGapW),
      ..._withGaps(trailingCols),
    ]),
  );
}

// -----------------------------------------------------------------------
// Header design
//
// ITEMS-HEADER-ROW PASS: no longer ends with
// _gradientWaveHeaderRow(adapter: a) — supplied via this file's Preview
// classes instead.
// -----------------------------------------------------------------------

Widget _gradientModernFullHeader(DocTemplateAdapter a) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left column — logo/identity, then the big doc-type heading
      // with doc number and meta fields stacked underneath.
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildSharedLogo(a, size: 34),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    a.businessName.isEmpty ? 'Your Business' : a.businessName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                        letterSpacing: 0.3,
                        fontFamily: a.fontFamily),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (a.businessAddress.isNotEmpty || a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty) ...[
              const SizedBox(height: 6),
              if (a.businessAddress.isNotEmpty)
                Text(a.businessAddress,
                    style: TextStyle(fontSize: 8, color: kGrey, fontFamily: a.fontFamily),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                Text(
                  [a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                  style: TextStyle(fontSize: 8, color: kGrey, fontFamily: a.fontFamily),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
            const SizedBox(height: 10),
            Text(
              a.docTypeLabel,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kInk,
                  letterSpacing: 0.5,
                  fontFamily: a.fontFamily),
            ),
            const SizedBox(height: 6),
            Text('${a.docTypeLabel} # ${a.docNumber.isEmpty ? '-' : a.docNumber}',
                style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
            const SizedBox(height: 2),
            Text('${a.metaLabel1}: ${a.metaValue1.isEmpty ? '-' : a.metaValue1}',
                style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
            const SizedBox(height: 2),
            Text('${a.metaLabel2}: ${a.metaValue2.isEmpty ? '-' : a.metaValue2}',
                style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
          ],
        ),
      ),
      const SizedBox(width: 20),
      // Right column — recipient block.
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(a.recipientLabel.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: a.accent,
                    letterSpacing: 0.8,
                    fontFamily: a.fontFamily)),
            const SizedBox(height: 6),
            Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            if (a.clientAddress.isNotEmpty) _clientDetailLine('Address', a.clientAddress, a.accent, a.fontFamily),
            if (a.clientEmail.isNotEmpty) _clientDetailLine('Email', a.clientEmail, a.accent, a.fontFamily),
            if (a.clientPhone.isNotEmpty) _clientDetailLine('Phone', a.clientPhone, a.accent, a.fontFamily),
          ],
        ),
      ),
    ],
  );
}

Widget _gradientModernContinuationHeader(DocTemplateAdapter a) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
      Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
          style: TextStyle(fontSize: 9.5, color: a.accent, fontFamily: a.fontFamily)),
    ],
  );
}

// -----------------------------------------------------------------------
// Preview wrappers - no buildLineItemRow/buildTotalsSection/
// buildFooterContent overrides — Gradient Modern intentionally relies on
// the shared defaults, which is exactly why _gradientWaveHeaderRow above
// had to be rebuilt to match them.
// -----------------------------------------------------------------------

class GradientModernInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        buildLineItemsHeaderRow: (a) => _gradientWaveHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class GradientModernQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        buildLineItemsHeaderRow: (a) => _gradientWaveHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class GradientModernReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        buildLineItemsHeaderRow: (a) => _gradientWaveHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}
