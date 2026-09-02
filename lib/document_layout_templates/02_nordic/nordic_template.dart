// nordic_template.dart
// lib/document_layout_templates/02_nordic/nordic_template.dart
//
// TEN-TEMPLATE UNIQUENESS PASS (earlier): Nordic previously shared the
// same "quiet identity block + thin rule" structure as Classic/Emerald/
// Editorial/Pastel Soft — differing mostly by font weight and rule style
// rather than anything structurally distinct, which made it hard to tell
// apart from those at a glance. Reworked here as a true minimalist ledger:
// NO decorative rule of any kind (no single line, no double line), the
// business identity sits alone on the left with generous whitespace, and
// the doc type/number/status are laid out as a plain right-aligned
// numeric block — closer to a plain accounting ledger (QuickBooks-style)
// than a designed letterhead. This is now the most restrained of the 10
// by a clear margin, distinct from Classic's still-has-a-rule structure
// and Emerald's hairline-rule refinement.
//
// SIDE-BY-SIDE HEADER PASS (this update): business block and client/meta
// block previously sat in a single Column, stacked with a fixed 38px gap
// between them — since the business block's own content (name/doc-type
// row/address/contact) varies in height, that gap often left the client
// block sitting well below the business block's title line, with a slab
// of unused whitespace in between and the two blocks visually
// disconnected. Restructured as a Row instead: business block on the
// left (Expanded, so it still wraps long names/addresses the same way),
// client/meta block on the right, both anchored to
// crossAxisAlignment.start so the client block's top line ("BILLED TO")
// now lines up with the business name's top line instead of trailing far
// below it. This closes up the dead space in the middle and reads as one
// tidy header band rather than two staggered blocks.
//
// Everything below the header (line items, totals, notes, footer) still
// comes from shared_doc_widgets.dart unchanged. Class names and
// signatures (NordicInvoicePreview/NordicQuotePreview/NordicReceiptPreview)
// are unchanged, so preview_registry.dart files need no changes.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────
// Header design — LEFT-ALIGNED WORDMARK, no logo mark in the header at
// all. Executive's identity is built around its diamond logo sitting on
// the LEFT; every other template in the set also puts a logo mark
// somewhere in the top-left/top-center. Nordic drops the logo from the
// header entirely (large spaced-out capital lettering carries the
// identity instead) and keeps the business block at the LEFT edge of the
// page. Client/meta info sits on the opposite (right) side, top-aligned
// with it, so the header reads as one tidy two-column band — business on
// the left, client details on the right — rather than two staggered
// blocks with a gap of empty space between them.
// ─────────────────────────────────────────────────────────────────────────

Widget _nordicFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
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
          // Client/meta block — top-aligned with the business block via
          // the parent Row's crossAxisAlignment.start, so "BILLED TO"
          // lines up with the business name instead of sitting far below
          // it.
          _NordicMetaStack(a: a),
        ],
      ),
      const SizedBox(height: 28),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _nordicContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kGrey, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} ${a.docNumber.isEmpty ? '—' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 20),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
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
// Preview wrappers — unchanged signatures, so preview_registry.dart files
// (invoice / quote / receipt) need no changes for this rework.
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
        onPageCount: onPageCount,
      );
}