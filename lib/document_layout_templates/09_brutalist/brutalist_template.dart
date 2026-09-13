// brutalist_template.dart
// lib/document_layout_templates/09_brutalist/brutalist_template.dart
//
// ITEMS-HEADER-ROW PASS (this update): _brutalistFullHeader and
// _brutalistContinuationHeader no longer call
// _brutalistLineItemsHeaderRow() themselves — that custom dark-bar row
// is now supplied via buildLineItemsHeaderRow on every Preview class
// below, and A4Paginator decides per page whether to actually show it.
// See a4_paginator.dart's header comment for the bug this fixes.
//
// UNUSED-IMPORT CLEANUP PASS (earlier): doc_line_items.dart removed
// (sharedLineItemColumnFlags comes from the bare doc_header.dart
// import); the dead _qtyWithUnit helper removed too (the real row
// builder calls _fmtQty directly and never used it).
//
// PAYMENT/TERMS/SIGNATURE PARITY PASS (earlier): _brutalistTotalsSection
// calls the same three shared panel functions every other template uses.
//
// SHARED/EXECUTIVE PARITY PASS — PHASE 2 (earlier): Brutalist supplies
// its own full set of overrides (buildLineItemRow / buildTotalsSection /
// buildFooterContent) so the SL.-numbered dark-bar table look is
// preserved exactly, while the underlying data matches Executive (UNIT
// column, DISCOUNT/TAX columns with signed withholding-tax handling and
// abbreviated rate names, correctly discount/tax-adjusted per-row TOTAL,
// grouped-by-name totals rows).

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData, LineItem, unitDisplayLabel;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../document_template_layout_data/doc_template_adapter.dart';
import '../document_template_layout_data/doc_header.dart';
import '../document_template_layout_data/doc_totals.dart';
import '../document_template_layout_data/template_document.dart';

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

const double _kGapW = 10.0;

List<Widget> _withGaps(List<Widget> columns) {
  final out = <Widget>[];
  for (var i = 0; i < columns.length; i++) {
    if (i > 0) out.add(const SizedBox(width: _kGapW));
    out.add(columns[i]);
  }
  return out;
}

Widget _rateCell({
  required bool enabled,
  required double amount,
  required double rate,
  required bool negative,
  required String name,
  required String currency,
  required DocTemplateAdapter adapter,
  required String ff,
}) {
  if (!enabled) return const SizedBox.shrink();
  final trimmedName = name.trim();
  final displayName = abbreviateRateName(trimmedName);
  final rateText = '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('${negative ? '−' : ''}${adapter.fmtMoney(amount)}',
          textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
      Text(trimmedName.isEmpty ? rateText : '$displayName ($rateText)',
          textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 7.5, color: kInk, fontFamily: ff)),
    ],
  );
}

class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper();

  @override
  Path getClip(Size size) {
    final cut = size.width * 0.16;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ITEMS-HEADER-ROW PASS: no longer ends with
// _brutalistLineItemsHeaderRow(...) — supplied via this file's Preview
// classes instead.
Widget _brutalistFullHeader(DocTemplateAdapter a) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: ClipPath(
            clipper: const _RibbonClipper(),
            child: Container(
              color: kInk,
              padding: const EdgeInsets.fromLTRB(16, 18, 28, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(a.recipientLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white70, letterSpacing: 0.6, fontFamily: a.fontFamily)),
                  const SizedBox(height: 8),
                  Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: a.fontFamily),
                      softWrap: true, overflow: TextOverflow.visible),
                  if (a.clientAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(a.clientAddress, style: TextStyle(fontSize: 9, color: Colors.white60, height: 1.4, fontFamily: a.fontFamily)),
                  ],
                  if (a.clientEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(a.clientEmail, style: TextStyle(fontSize: 9, color: Colors.white60, fontFamily: a.fontFamily)),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildSharedLogo(a, size: 26.0),
                    const SizedBox(width: 8),
                    Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                        color: a.accent, letterSpacing: 1.0, fontFamily: a.fontFamily)),
                  ],
                ),
                const SizedBox(height: 10),
                _kv('${a.docTypeLabel.substring(0, 3)}#', a.docNumber.isEmpty ? '-' : a.docNumber, a.fontFamily),
                const SizedBox(height: 3),
                _kv('Date', a.metaValue1.isEmpty ? '-' : a.metaValue1, a.fontFamily),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: a.statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(3)),
                  child: Text(a.statusLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                      letterSpacing: 0.6, color: a.statusColor, fontFamily: a.fontFamily)),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _kv(String k, String v, String ff) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('$k  ', style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
    Text(v, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff)),
  ],
);

// ITEMS-HEADER-ROW PASS: no longer ends with
// _brutalistLineItemsHeaderRow(...) — supplied via this file's Preview
// classes instead.
Widget _brutalistContinuationHeader(DocTemplateAdapter a) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kInk, fontFamily: a.fontFamily)),
      Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kGrey, fontFamily: a.fontFamily)),
    ],
  );
}

Widget _brutalistLineItemsHeaderRow(DocTemplateAdapter a) {
  final flags = sharedLineItemColumnFlags(a);
  final ff = a.fontFamily;
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: ff);
  final trailingCols = <Widget>[
    Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
    if (flags.showUnitCol)
      Expanded(flex: 2, child: Text('UNIT', textAlign: TextAlign.center, style: hdr)),
    Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: hdr)),
    if (flags.showDiscountCol)
      Expanded(flex: 2, child: Text('DISCOUNT', textAlign: TextAlign.right, style: hdr)),
    if (flags.showTaxCol)
      Expanded(flex: 2, child: Text('TAX', textAlign: TextAlign.right, style: hdr)),
    Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
  ];
  return Container(
    color: kInk,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Row(children: [
      SizedBox(width: 20, child: Text('SL.', style: hdr)),
      Expanded(flex: 5, child: Text('ITEM DESCRIPTION', style: hdr.copyWith(letterSpacing: 0.6))),
      const SizedBox(width: _kGapW),
      ..._withGaps(trailingCols),
    ]),
  );
}

Widget _brutalistLineItemRow({
  required LineItem item,
  required DocTemplateAdapter adapter,
  required String ff,
  required int index,
}) {
  final flags = sharedLineItemColumnFlags(adapter);

  final itemDiscountAmt = item.discountEnabled ? item.total * item.itemDiscountRate / 100 : 0.0;
  final itemTaxAmt      = item.taxEnabled      ? item.total * item.itemTaxRate      / 100 : 0.0;
  final signedTaxAmt = item.taxEnabled
      ? (item.itemTaxIsAddition ? itemTaxAmt : -itemTaxAmt)
      : 0.0;
  final netTotal = item.total - itemDiscountAmt + signedTaxAmt;

  final trailingCells = <Widget>[
    Expanded(flex: 2, child: Text(_fmtQty(item.quantity), textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: kInk, fontFamily: ff))),
    if (flags.showUnitCol)
      Expanded(flex: 2, child: Text(
          item.unit.isEmpty ? '' : unitDisplayLabel(item.unit, customUnitLabel: item.customUnitLabel),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9.5, color: kInk, fontFamily: ff))),
    Expanded(flex: 2, child: Text(adapter.fmtMoney(item.unitPrice), textAlign: TextAlign.right,
        style: TextStyle(fontSize: 10, color: kInk, fontFamily: ff))),
    if (flags.showDiscountCol)
      Expanded(flex: 2, child: _rateCell(
          enabled: item.discountEnabled, amount: itemDiscountAmt, rate: item.itemDiscountRate,
          negative: true, name: item.itemDiscountName, currency: adapter.currency, adapter: adapter, ff: ff)),
    if (flags.showTaxCol)
      Expanded(flex: 2, child: _rateCell(
          enabled: item.taxEnabled, amount: itemTaxAmt, rate: item.itemTaxRate,
          negative: !item.itemTaxIsAddition, name: item.itemTaxName, currency: adapter.currency, adapter: adapter, ff: ff)),
    Expanded(flex: 2, child: Text(adapter.fmtMoney(netTotal), textAlign: TextAlign.right,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff))),
  ];

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kRule, width: 0.75))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 20, child: Text('${index + 1}',
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 5, child: Text(
          item.description.isEmpty ? 'Item description' : item.description,
          style: TextStyle(fontSize: 10, color: kInk, height: 1.4, fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible)),
      const SizedBox(width: _kGapW),
      ..._withGaps(trailingCells),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Totals block — plain Subtotal/Discount/Tax rows, an accent-tinted
// Grand Total row, grouped-by-name totals rows, and the NOTES panel.
// Payment Details / Terms & Conditions / Signature appended via the same
// shared functions every other template calls.
// ─────────────────────────────────────────────────────────────────────────
Widget _brutalistTotalsSection(DocTemplateAdapter a) {
  Widget plainRow(String label, double v, {bool bold = false, bool negative = false}) => Padding(
    padding: EdgeInsets.only(bottom: bold ? 0 : 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: Text(label,
          style: TextStyle(fontSize: bold ? 11 : 10, fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              color: bold ? kInk : kGrey, fontFamily: a.fontFamily),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8),
      Flexible(child: Text('${negative ? '−' : ''}${a.fmtMoney(v)}',
          style: TextStyle(fontSize: bold ? 13 : 10.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? a.accent : kInk, fontFamily: a.fontFamily),
          textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );

  return Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: kContentW * 0.42,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              plainRow('Subtotal', a.subtotal),
              if (a.taxRate > 0) plainRow('Tax (${a.taxRate.toStringAsFixed(1)}%)', a.taxAmount),
              if (a.discountRate > 0)
                plainRow('Discount (${a.discountRate.toStringAsFixed(0)}%)', a.discountAmount, negative: true),
              for (final entry in a.itemDiscountExtraByName.entries)
                if (entry.value > 0)
                  plainRow(entry.key.isEmpty ? 'Item Discounts' : 'Item Discounts (${entry.key})',
                      entry.value, negative: true),
              for (final entry in a.itemTaxExtraByName.entries)
                if (entry.value != 0)
                  plainRow(entry.key.isEmpty ? 'Item Tax' : 'Item Tax (${entry.key})',
                      entry.value.abs(), negative: entry.value < 0),
              const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: kInk)),
              plainRow(a.totalLabel, a.total, bold: true),
            ]),
          ),
        ),
        if (a.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
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
        buildSharedPaymentInfoPanel(a),
        buildSharedTermsPanel(a),
        buildSharedSignatureBlock(a),
      ],
    ),
  );
}

Widget _brutalistFooterContent(DocTemplateAdapter a) {
  final contact = [a.businessPhone, a.businessEmail, a.businessAddress]
      .where((s) => s.isNotEmpty)
      .join('   •   ');
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(height: 2, color: kInk),
      const SizedBox(height: 10),
      Text(contact.isEmpty ? a.thankYouLabel : contact,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8.5, color: kGrey, fontFamily: a.fontFamily),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}

class BrutalistInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const BrutalistInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _brutalistFullHeader,
        buildContinuationHeader: _brutalistContinuationHeader,
        buildLineItemsHeaderRow: _brutalistLineItemsHeaderRow,
        buildLineItemRow: _brutalistLineItemRow,
        buildTotalsSection: _brutalistTotalsSection,
        buildFooterContent: _brutalistFooterContent,
        onPageCount: onPageCount,
      );
}

class BrutalistQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const BrutalistQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _brutalistFullHeader,
        buildContinuationHeader: _brutalistContinuationHeader,
        buildLineItemsHeaderRow: _brutalistLineItemsHeaderRow,
        buildLineItemRow: _brutalistLineItemRow,
        buildTotalsSection: _brutalistTotalsSection,
        buildFooterContent: _brutalistFooterContent,
        onPageCount: onPageCount,
      );
}

class BrutalistReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const BrutalistReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _brutalistFullHeader,
        buildContinuationHeader: _brutalistContinuationHeader,
        buildLineItemsHeaderRow: _brutalistLineItemsHeaderRow,
        buildLineItemRow: _brutalistLineItemRow,
        buildTotalsSection: _brutalistTotalsSection,
        buildFooterContent: _brutalistFooterContent,
        onPageCount: onPageCount,
      );
}
