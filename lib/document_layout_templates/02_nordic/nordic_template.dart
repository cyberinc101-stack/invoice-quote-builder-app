// nordic_template.dart
// lib/document_layout_templates/02_nordic/nordic_template.dart
//
// ITEMS-HEADER-ROW PASS (this update): _nordicFullHeader and
// _nordicContinuationHeader no longer call buildSharedLineItemsHeaderRow()
// themselves — supplied instead via the new buildLineItemsHeaderRow
// param on every Preview class below. See a4_paginator.dart's header
// comment for the bug this fixes (a floating column-header row on a
// totals-only overflow page).
//
// UNUSED-IMPORT CLEANUP PASS (earlier): doc_totals.dart removed — Nordic
// never calls anything from it.
//
// TEN-TEMPLATE UNIQUENESS PASS / SIDE-BY-SIDE HEADER PASS (earlier):
// see prior header comments for the full history of this design's
// left-aligned wordmark + right-aligned client/meta band layout.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../document_template_layout_data/doc_template_adapter.dart';
import '../document_template_layout_data/doc_header.dart';
import '../document_template_layout_data/doc_line_items.dart';
import '../document_template_layout_data/template_document.dart';

// ─────────────────────────────────────────────────────────────────────────
// Header design — LEFT-ALIGNED WORDMARK, no logo mark in the header at
// all. Client/meta info sits on the opposite (right) side, top-aligned
// with it.
//
// ITEMS-HEADER-ROW PASS: no longer ends with
// buildSharedLineItemsHeaderRow(adapter: a) — see this file's Preview
// classes for where it's supplied instead.
// ─────────────────────────────────────────────────────────────────────────

Widget _nordicFullHeader(DocTemplateAdapter a) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (a.businessName.isEmpty ? 'YOUR BUSINESS' : a.businessName).toUpperCase(),
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w300,
                  color: kInk, letterSpacing: 4.0, fontFamily: a.fontFamily),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.docTypeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: kGrey, letterSpacing: 2.0, fontFamily: a.fontFamily)),
                Text('  ·  ', style: TextStyle(fontSize: 10, color: kGreyLight, fontFamily: a.fontFamily)),
                Text(a.docNumber.isEmpty ? '—' : a.docNumber,
                    style: TextStyle(fontSize: 10, color: kGrey, fontWeight: FontWeight.w600, fontFamily: a.fontFamily)),
                const SizedBox(width: 10),
                Text(a.statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                    color: a.statusColor, letterSpacing: 0.4, fontFamily: a.fontFamily)),
              ],
            ),
            const SizedBox(height: 6),
            if (a.businessAddress.isNotEmpty)
              Text(a.businessAddress, textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 9, color: kGreyLight, height: 1.5, fontFamily: a.fontFamily)),
            if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
              Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 9, color: kGreyLight, fontFamily: a.fontFamily)),
          ],
        ),
      ),
      const SizedBox(width: 24),
      _NordicMetaStack(a: a),
    ],
  );
}

Widget _nordicContinuationHeader(DocTemplateAdapter a) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kGrey, fontFamily: a.fontFamily)),
      Text('${a.docTypeLabel} ${a.docNumber.isEmpty ? '—' : a.docNumber} ${a.continuationSuffix}',
          style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: a.fontFamily)),
    ],
  );
}

// Stacked meta list — right-aligned, sits beside the left-aligned
// business wordmark, top-anchored with it via the parent Row.
class _NordicMetaStack extends StatelessWidget {
  final DocTemplateAdapter a;
  const _NordicMetaStack({required this.a});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(a.recipientLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600,
            color: kGreyLight, letterSpacing: 1.2, fontFamily: a.fontFamily)),
        const SizedBox(height: 7),
        Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk, fontFamily: a.fontFamily),
            softWrap: true, overflow: TextOverflow.visible),
        if (a.clientAddress.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(a.clientAddress, textAlign: TextAlign.right,
              style: TextStyle(fontSize: 9.5, color: kGreyLight, height: 1.5, fontFamily: a.fontFamily)),
        ],
        if (a.clientEmail.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(a.clientEmail, textAlign: TextAlign.right,
              style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: a.fontFamily)),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inlineMeta(a.metaLabel1, a.metaValue1, a.fontFamily),
            const SizedBox(width: 28),
            _inlineMeta(a.metaLabel2, a.metaValue2, a.fontFamily),
          ],
        ),
      ],
    );
  }

  Widget _inlineMeta(String label, String value, String ff) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label ', style: TextStyle(fontSize: 9, color: kGreyLight, fontFamily: ff)),
      Text(value.isEmpty ? '—' : value,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Preview wrappers.
// ─────────────────────────────────────────────────────────────────────────

class NordicInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const NordicInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _nordicFullHeader,
        buildContinuationHeader: _nordicContinuationHeader,
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class NordicQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const NordicQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _nordicFullHeader,
        buildContinuationHeader: _nordicContinuationHeader,
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class NordicReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const NordicReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _nordicFullHeader,
        buildContinuationHeader: _nordicContinuationHeader,
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}
