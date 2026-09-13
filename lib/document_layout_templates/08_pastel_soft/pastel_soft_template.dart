// pastel_soft_template.dart
// lib/document_layout_templates/08_pastel_soft/pastel_soft_template.dart
//
// ITEMS-HEADER-ROW PASS (this update): _pastelSoftFullHeader and
// _pastelSoftContinuationHeader no longer call
// _pastelSoftLineItemsHeaderRow() themselves — that custom dark-header
// row is now supplied via buildLineItemsHeaderRow on every Preview class
// below, and A4Paginator decides per page whether to actually show it.
// See a4_paginator.dart's header comment for the bug this fixes.
//
// UNUSED-IMPORT CLEANUP PASS (earlier): doc_line_items.dart removed.
//
// PAYMENT/TERMS/SIGNATURE PARITY PASS (earlier): _pastelSoftTotalsSection
// calls the same three shared panel functions every other template uses,
// appended at the end of the right-hand totals column, after the
// existing "Authorised Sign" line.
//
// SHARED/EXECUTIVE PARITY PASS — PHASE 2 (earlier): Pastel Soft keeps
// its own visual style (badge-chip discount/tax indicators, the
// SL./Item Description/Price/Qty/Total dark-header table, striped rows)
// but the underlying DATA matches Executive's real logic exactly.

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

String _qtyWithUnit(LineItem item) {
  final qty = _fmtQty(item.quantity);
  final unit = item.unit.trim();
  if (unit.isEmpty) return qty;
  return '$qty ${unitDisplayLabel(item.unit, customUnitLabel: item.customUnitLabel)}';
}

const Color _kTaxChipBg  = Color(0xFFE3F2FD);
const Color _kTaxChipFg  = Color(0xFF1565C0);
const Color _kDiscChipBg = Color(0xFFFFF3E0);
const Color _kDiscChipFg = Color(0xFFEF6C00);

Widget _itemBadgeChip(String label, {required Color bg, required Color fg, required String ff}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
  child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: fg, fontFamily: ff)),
);

Widget _itemBadges(LineItem item, String ff) {
  if (!item.taxEnabled && !item.discountEnabled) return const SizedBox.shrink();

  String taxLabel = '';
  if (item.taxEnabled) {
    final sign = item.itemTaxIsAddition ? '' : '-';
    final rateText = '$sign${item.itemTaxRate.toStringAsFixed(item.itemTaxRate % 1 == 0 ? 0 : 1)}%';
    final name = item.itemTaxName.trim();
    taxLabel = name.isEmpty ? 'Tax $rateText' : '${abbreviateRateName(name)} $rateText';
  }
  String discLabel = '';
  if (item.discountEnabled) {
    final rateText = '-${item.itemDiscountRate.toStringAsFixed(item.itemDiscountRate % 1 == 0 ? 0 : 1)}%';
    final name = item.itemDiscountName.trim();
    discLabel = name.isEmpty ? rateText : '${abbreviateRateName(name)} $rateText';
  }

  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Wrap(spacing: 6, runSpacing: 4, children: [
      if (item.taxEnabled) _itemBadgeChip(taxLabel, bg: _kTaxChipBg, fg: _kTaxChipFg, ff: ff),
      if (item.discountEnabled) _itemBadgeChip(discLabel, bg: _kDiscChipBg, fg: _kDiscChipFg, ff: ff),
    ]),
  );
}

// ITEMS-HEADER-ROW PASS: no longer ends with
// _pastelSoftLineItemsHeaderRow(...) — supplied via this file's Preview
// classes instead.
Widget _pastelSoftFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildSharedLogo(a, size: 34.0),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (a.businessAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(a.businessAddress,
                            style: TextStyle(fontSize: 7.5, color: kGreyLight, letterSpacing: 0.6, fontFamily: a.fontFamily),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(a.docTypeLabel.toUpperCase(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kInk, letterSpacing: 1.2, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 14),
      Container(height: 9, color: a.accent),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.recipientLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                    color: kGreyLight, letterSpacing: 1.2, fontFamily: a.fontFamily)),
                const SizedBox(height: 6),
                Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
                if (a.clientAddress.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(a.clientAddress, style: TextStyle(fontSize: 9, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
                ],
                if (a.clientPhone.isNotEmpty || a.clientEmail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text([a.clientPhone, a.clientEmail].where((s) => s.isNotEmpty).join('   •   '),
                      style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _metaRow('${a.docTypeLabel}#', a.docNumber.isEmpty ? '-' : a.docNumber, a.fontFamily),
                const SizedBox(height: 6),
                _metaRow(a.metaLabel1, a.metaValue1.isEmpty ? '-' : a.metaValue1, a.fontFamily),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _metaRow(String label, String value, String ff) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('$label:  ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kGrey, fontFamily: ff)),
    Text(value, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
  ],
);

// ITEMS-HEADER-ROW PASS: no longer ends with
// _pastelSoftLineItemsHeaderRow(...) — supplied via this file's Preview
// classes instead.
Widget _pastelSoftContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
          const Spacer(),
          Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 6),
      Container(height: 4, color: a.accent),
    ],
  );
}

Widget _pastelSoftLineItemsHeaderRow(DocTemplateAdapter a) {
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: Colors.white, letterSpacing: 0.6, fontFamily: a.fontFamily);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
    color: kInk,
    child: Row(children: [
      SizedBox(width: 22, child: Text('SL.', style: hdr)),
      Expanded(flex: 5, child: Text('ITEM DESCRIPTION', style: hdr)),
      Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: hdr)),
      Expanded(flex: 1, child: Text('QTY.', textAlign: TextAlign.center, style: hdr)),
      Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
    ]),
  );
}

Widget _pastelSoftLineItemRow({
  required LineItem item,
  required DocTemplateAdapter adapter,
  required String ff,
  required int index,
}) {
  final bg = index.isEven ? Colors.white : kPanelBg;

  final itemDiscountAmt = item.discountEnabled ? item.total * item.itemDiscountRate / 100 : 0.0;
  final itemTaxAmt      = item.taxEnabled      ? item.total * item.itemTaxRate      / 100 : 0.0;
  final signedTaxAmt = item.taxEnabled
      ? (item.itemTaxIsAddition ? itemTaxAmt : -itemTaxAmt)
      : 0.0;
  final netTotal = item.total - itemDiscountAmt + signedTaxAmt;

  return Container(
    color: bg,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 22, child: Text('${index + 1}',
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 5, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              item.description.isEmpty ? 'Item description' : item.description,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, height: 1.4, fontFamily: ff),
              softWrap: true, overflow: TextOverflow.visible),
          _itemBadges(item, ff),
        ],
      )),
      Expanded(flex: 2, child: Text(adapter.fmtMoney(item.unitPrice), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 1, child: Text(_qtyWithUnit(item), textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 2, child: Text(adapter.fmtMoney(netTotal), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Totals block — left column keeps the thank-you line and NOTES panel;
// right column is plain Subtotal/Discount/Tax rows, then a solid accent
// Total callout, then a signature rule and static "Authorised Sign"
// label, then Payment Details / Terms & Conditions / a real Signature
// block appended via the same shared functions every other template
// calls.
// ─────────────────────────────────────────────────────────────────────────
Widget _pastelSoftTotalsSection(DocTemplateAdapter a) {
  Widget plainRow(String label, double v, {bool negative = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: Text(label,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: a.fontFamily),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8),
      Flexible(child: Text('${negative ? '−' : ''}${a.fmtMoney(v)}',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: a.fontFamily),
          textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );

  return Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(a.thankYouLabel,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
                  if (a.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('NOTES', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                        color: kGreyLight, letterSpacing: 1.2, fontFamily: a.fontFamily)),
                    const SizedBox(height: 6),
                    Text(a.notes, style: TextStyle(fontSize: 9, color: kGrey, height: 1.5, fontFamily: a.fontFamily),
                        softWrap: true, overflow: TextOverflow.visible),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  plainRow('Sub Total', a.subtotal),
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    color: a.accent,
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Flexible(child: Text(a.totalLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(a.fmtMoney(a.total),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: kInk, fontFamily: a.fontFamily),
                          textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                  const SizedBox(height: 42),
                  Container(height: 1, color: kRule),
                  const SizedBox(height: 6),
                  Text('Authorised Sign', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ),
            ),
          ],
        ),
        buildSharedPaymentInfoPanel(a),
        buildSharedTermsPanel(a),
        buildSharedSignatureBlock(a),
      ],
    ),
  );
}

Widget _pastelSoftFooterContent(DocTemplateAdapter a) {
  final contact = [a.businessPhone, a.businessAddress, a.businessEmail]
      .where((s) => s.isNotEmpty)
      .join('   |   ');
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(height: 3, color: a.accent),
      const SizedBox(height: 10),
      if (contact.isNotEmpty)
        Text(contact, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8.5, color: kGrey, fontFamily: a.fontFamily),
            maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}

class PastelSoftInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const PastelSoftInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _pastelSoftFullHeader,
        buildContinuationHeader: _pastelSoftContinuationHeader,
        buildLineItemsHeaderRow: _pastelSoftLineItemsHeaderRow,
        buildLineItemRow: _pastelSoftLineItemRow,
        buildTotalsSection: _pastelSoftTotalsSection,
        buildFooterContent: _pastelSoftFooterContent,
        onPageCount: onPageCount,
      );
}

class PastelSoftQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const PastelSoftQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _pastelSoftFullHeader,
        buildContinuationHeader: _pastelSoftContinuationHeader,
        buildLineItemsHeaderRow: _pastelSoftLineItemsHeaderRow,
        buildLineItemRow: _pastelSoftLineItemRow,
        buildTotalsSection: _pastelSoftTotalsSection,
        buildFooterContent: _pastelSoftFooterContent,
        onPageCount: onPageCount,
      );
}

class PastelSoftReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const PastelSoftReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _pastelSoftFullHeader,
        buildContinuationHeader: _pastelSoftContinuationHeader,
        buildLineItemsHeaderRow: _pastelSoftLineItemsHeaderRow,
        buildLineItemRow: _pastelSoftLineItemRow,
        buildTotalsSection: _pastelSoftTotalsSection,
        buildFooterContent: _pastelSoftFooterContent,
        onPageCount: onPageCount,
      );
}
