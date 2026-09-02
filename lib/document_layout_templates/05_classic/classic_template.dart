// classic_template.dart
// lib/document_layout_templates/05_classic/classic_template.dart
//
// TEN-TEMPLATE UNIQUENESS PASS (this update): Classic previously shared
// the exact same Row(logo | business identity | doc-type+number, right-
// aligned) → rule → two-column meta row skeleton as Vibrant, Tech Dark,
// and Gradient Modern — the only thing distinguishing it from those three
// was the absence of a colored panel. Rebuilt around a genuinely
// different device instead: a CENTERED FORMAL LETTERHEAD (business name
// and contact info centered at the top of the page, like a traditional
// printed letterhead) with a thin double rule beneath, and — where every
// other template uses a borderless label/value meta row — a real BOXED
// MINI-TABLE (bordered box, its own header strip for doc type + number,
// divided rows for the two meta fields and status) sitting to the right
// of the client block. No other template in the set uses a bordered box
// as its meta device or centers its identity block.
//
// The shaded grey line-items header row (buildSharedLineItemsHeaderRow
// wrapped in a light grey Container) is unchanged from before this pass
// — still the one template using that treatment.
//
// Everything below the header (line items, totals, notes, footer) comes
// from shared_doc_widgets.dart unchanged.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────
// Header design — centered business identity block, thin double rule,
// then a client block on the left paired with a bordered mini-table box
// on the right (doc type/number header strip, two meta rows, a status
// row) — the box is the device this template is now built around.
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
      const SizedBox(height: 24),
      Container(
        color: const Color(0xFFF3F4F6),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
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
      const SizedBox(height: 16),
      Container(
        color: const Color(0xFFF3F4F6),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
      ),
    ],
  );
}

// Bordered mini-table box — the device this template is built around.
// Header strip (doc type + number on a light accent tint), two divided
// meta rows, and a status row — a real bordered box rather than the
// borderless label/value meta row every other template uses.
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
// Preview wrappers - one per doc type, each ~5 lines: convert to the
// adapter, hand off to TemplateDocument. These are what preview_registry
// files (invoice / quote / receipt) import and wire into their id switch.
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
        onPageCount: onPageCount,
      );
}
