// emerald_template.dart
// lib/document_layout_templates/10_emerald/emerald_template.dart
//
// ITEMS-HEADER-ROW PASS (this update): _emeraldFullHeader and
// _emeraldContinuationHeader no longer call _emeraldLineItemsHeaderRow()
// themselves — that custom accent row is now supplied via
// buildLineItemsHeaderRow on every Preview class below, and A4Paginator
// decides per page whether to actually show it. See a4_paginator.dart's
// header comment for the bug this fixes.
//
// UNUSED-IMPORT CLEANUP PASS (earlier): doc_line_items.dart removed.
//
// PAYMENT/TERMS/SIGNATURE PARITY PASS (earlier): _emeraldTotalsSection
// calls the same three shared panel functions every other template uses.
//
// SHARED/EXECUTIVE PARITY PASS — PHASE 2 (earlier): Emerald keeps its
// own single-column field-stack header AND its colored item-table look
// entirely, with the underlying data matching Executive's real logic.

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
// _emeraldLineItemsHeaderRow(...) — supplied via this file's Preview
// classes instead.
Widget _emeraldFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: a.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: a.accent, letterSpacing: 1.6, fontFamily: a.fontFamily)),
          ),
          Text(a.statusLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600,
              color: a.statusColor, letterSpacing: 0.4, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildSharedLogo(a, size: 26.0),
                const SizedBox(height: 8),
                Text(
                  a.businessName.isEmpty ? 'Your Business' : a.businessName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                ),
                if (a.businessAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(a.businessAddress, style: TextStyle(fontSize: 9, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
                ],
                if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                      style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _EmeraldFieldStack(a: a),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(height: 1, color: kRule),
    ],
  );
}

// ITEMS-HEADER-ROW PASS: no longer ends with
// _emeraldLineItemsHeaderRow(...) — supplied via this file's Preview
// classes instead.
Widget _emeraldContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 12),
      Container(height: 1, color: kRule),
    ],
  );
}

class _EmeraldFieldStack extends StatelessWidget {
  final DocTemplateAdapter a;
  const _EmeraldFieldStack({required this.a});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _field('Doc No.', a.docNumber.isEmpty ? '—' : a.docNumber),
        const SizedBox(height: 7),
        _field(a.recipientLabel, a.clientName.isEmpty ? 'Client name' : a.clientName, bold: true),
        if (a.clientAddress.isNotEmpty) _fieldPlain(a.clientAddress),
        if (a.clientEmail.isNotEmpty) _fieldPlain(a.clientEmail),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field(a.metaLabel1, a.metaValue1.isEmpty ? '—' : a.metaValue1)),
            const SizedBox(width: 12),
            Expanded(child: _field(a.metaLabel2, a.metaValue2.isEmpty ? '—' : a.metaValue2)),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
            color: kGreyLight, letterSpacing: 1.0, fontFamily: a.fontFamily)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: bold ? 12.5 : 10.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: kInk, fontFamily: a.fontFamily),
            softWrap: true, overflow: TextOverflow.visible),
      ],
    ),
  );

  Widget _fieldPlain(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 1),
    child: Text(value, style: TextStyle(fontSize: 9.5, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
  );
}

Widget _emeraldLineItemsHeaderRow(DocTemplateAdapter a) {
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: Colors.white, letterSpacing: 0.8, fontFamily: a.fontFamily);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
    color: a.accent,
    child: Row(children: [
      Expanded(flex: 5, child: Text('ITEM DESCRIPTION', style: hdr)),
      Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: hdr)),
      Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
      Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
    ]),
  );
}

Widget _emeraldLineItemRow({
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
// Totals block — plain Subtotal/Discount/Tax rows, then a Grand Total row
// on a solid accent bar with white text, then the NOTES panel. Payment
// Details / Terms & Conditions / Signature appended via the same shared
// functions every other template calls.
// ─────────────────────────────────────────────────────────────────────────
Widget _emeraldTotalsSection(DocTemplateAdapter a) {
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
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: a.fontFamily),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(a.fmtMoney(a.total),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: a.fontFamily),
                      textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
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

Widget _emeraldFooterContent(DocTemplateAdapter a) {
  final contact = [a.businessPhone, a.businessEmail, a.businessAddress]
      .where((s) => s.isNotEmpty)
      .join('   •   ');
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    color: a.accent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            contact.isEmpty ? a.thankYouLabel : contact,
            style: TextStyle(fontSize: 8.5, color: Colors.white.withValues(alpha: 0.9), fontFamily: a.fontFamily),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        buildSharedLogo(a, size: 20.0, fallbackMarkColor: Colors.white, fallbackMarkTextColor: a.accent),
        const SizedBox(width: 8),
        Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: a.fontFamily)),
      ],
    ),
  );
}

class EmeraldInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const EmeraldInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _emeraldFullHeader,
        buildContinuationHeader: _emeraldContinuationHeader,
        buildLineItemsHeaderRow: _emeraldLineItemsHeaderRow,
        buildLineItemRow: _emeraldLineItemRow,
        buildTotalsSection: _emeraldTotalsSection,
        buildFooterContent: _emeraldFooterContent,
        onPageCount: onPageCount,
      );
}

class EmeraldQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const EmeraldQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _emeraldFullHeader,
        buildContinuationHeader: _emeraldContinuationHeader,
        buildLineItemsHeaderRow: _emeraldLineItemsHeaderRow,
        buildLineItemRow: _emeraldLineItemRow,
        buildTotalsSection: _emeraldTotalsSection,
        buildFooterContent: _emeraldFooterContent,
        onPageCount: onPageCount,
      );
}

class EmeraldReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const EmeraldReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _emeraldFullHeader,
        buildContinuationHeader: _emeraldContinuationHeader,
        buildLineItemsHeaderRow: _emeraldLineItemsHeaderRow,
        buildLineItemRow: _emeraldLineItemRow,
        buildTotalsSection: _emeraldTotalsSection,
        buildFooterContent: _emeraldFooterContent,
        onPageCount: onPageCount,
      );
}
