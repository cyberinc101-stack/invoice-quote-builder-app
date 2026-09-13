// classic_template.dart
// lib/document_layout_templates/05_classic/classic_template.dart
//
// ITEMS-HEADER-ROW PASS (this update): _classicFullHeader and
// _classicContinuationHeader no longer wrap buildSharedLineItemsHeaderRow
// in the light-grey Container themselves — that whole styled row
// (Container + buildSharedLineItemsHeaderRow) is now supplied via
// buildLineItemsHeaderRow on every Preview class below, preserving
// Classic's shaded-row look exactly while letting A4Paginator decide,
// per page, whether to actually show it. See a4_paginator.dart's header
// comment for the bug this fixes.
//
// UNUSED-IMPORT CLEANUP PASS (earlier): doc_totals.dart removed.
//
// TEN-TEMPLATE UNIQUENESS PASS (earlier): centered formal letterhead
// with a thin double rule, and a real bordered mini-table box (doc
// type/number header strip, meta rows, status) instead of a borderless
// meta row.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../document_template_layout_data/doc_template_adapter.dart';
import '../document_template_layout_data/doc_header.dart';
import '../document_template_layout_data/doc_line_items.dart';
import '../document_template_layout_data/template_document.dart';

// Classic's shaded-row treatment for the item-table header — kept as its
// own function so it can be passed straight into buildLineItemsHeaderRow
// without duplicating the Container styling in three places.
Widget _classicLineItemsHeaderRow(DocTemplateAdapter a) => Container(
      color: const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: buildSharedLineItemsHeaderRow(adapter: a),
    );

// ─────────────────────────────────────────────────────────────────────────
// Header design — centered business identity block, thin double rule,
// then a client block on the left paired with a bordered mini-table box
// on the right.
//
// ITEMS-HEADER-ROW PASS: no longer ends with the shaded item-table
// header row — supplied via this file's Preview classes instead.
// ─────────────────────────────────────────────────────────────────────────

Widget _classicFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildSharedLogo(a, size: 38.0),
            const SizedBox(height: 10),
            Text(
              a.businessName.isEmpty ? 'Your Business' : a.businessName,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
            ),
            const SizedBox(height: 5),
            if (a.businessAddress.isNotEmpty)
              Text(a.businessAddress, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
            if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
              Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Container(height: 1, color: a.accent),
      const SizedBox(height: 2),
      Container(height: 1, color: kRule),
      const SizedBox(height: 24),
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
                    color: kGrey, letterSpacing: 1.2, fontFamily: a.fontFamily)),
                const SizedBox(height: 8),
                Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk, fontFamily: a.fontFamily),
                    softWrap: true, overflow: TextOverflow.visible),
                if (a.clientAddress.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(a.clientAddress, style: TextStyle(fontSize: 9.5, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
                ],
                if (a.clientEmail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(a.clientEmail, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
                ],
                if (a.clientPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(a.clientPhone, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: _ClassicMetaBox(a: a)),
        ],
      ),
    ],
  );
}

Widget _classicContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: kInk, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 8),
      Container(height: 1, color: a.accent),
    ],
  );
}

// Bordered mini-table box — the device this template is built around.
class _ClassicMetaBox extends StatelessWidget {
  final DocTemplateAdapter a;
  const _ClassicMetaBox({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kRule, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: a.accent.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: kInk, letterSpacing: 1.0, fontFamily: a.fontFamily)),
                Text('#${a.docNumber.isEmpty ? '-' : a.docNumber}',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kGrey, fontFamily: a.fontFamily)),
              ],
            ),
          ),
          _boxRow(a.metaLabel1, a.metaValue1, a.fontFamily),
          Divider(height: 1, color: kRule.withValues(alpha: 0.6)),
          _boxRow(a.metaLabel2, a.metaValue2, a.fontFamily),
          Divider(height: 1, color: kRule.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status', style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
                Text(a.statusLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: a.statusColor, fontFamily: a.fontFamily)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxRow(String label, String value, String ff) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
            Text(value.isEmpty ? '-' : value,
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
          ],
        ),
      );
}

// -----------------------------------------------------------------------
// Preview wrappers.
// -----------------------------------------------------------------------

class ClassicInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const ClassicInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _classicFullHeader,
        buildContinuationHeader: _classicContinuationHeader,
        buildLineItemsHeaderRow: _classicLineItemsHeaderRow,
        onPageCount: onPageCount,
      );
}

class ClassicQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const ClassicQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _classicFullHeader,
        buildContinuationHeader: _classicContinuationHeader,
        buildLineItemsHeaderRow: _classicLineItemsHeaderRow,
        onPageCount: onPageCount,
      );
}

class ClassicReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const ClassicReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _classicFullHeader,
        buildContinuationHeader: _classicContinuationHeader,
        buildLineItemsHeaderRow: _classicLineItemsHeaderRow,
        onPageCount: onPageCount,
      );
}
