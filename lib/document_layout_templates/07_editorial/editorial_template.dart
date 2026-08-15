// editorial_template.dart
// lib/doc_templates/07_editorial/editorial_template.dart
//
// Editorial: newspaper-masthead influenced but kept business-appropriate -
// a bold doc-type banner sits above a colored double rule (thick + thin,
// like a letterhead band rather than a magazine cover), with the business
// name in small-caps type underneath. Decoration is restrained: the
// accent color appears only in the rule and a couple of small labels,
// not as a fill or panel. Distinct from Nordic (quiet, no banner),
// Vibrant (solid fill), Tech Dark (dark panel), and Gradient Modern
// (soft gradient panel) - this one is typography-led.
//
// Everything below the header (line items, totals, notes, footer) comes
// from shared_doc_widgets.dart unchanged.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// -----------------------------------------------------------------------
// Header design
// -----------------------------------------------------------------------

Widget _editorialFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 28,
              fontWeight: FontWeight.w900, color: kInk, letterSpacing: 0.5, fontFamily: a.fontFamily)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No. ${a.docNumber.isEmpty ? '-' : a.docNumber}',
                  style: TextStyle(fontSize: 11, color: kGrey, fontWeight: FontWeight.w600, fontFamily: a.fontFamily)),
              const SizedBox(height: 2),
              Text(a.metaValue1, style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: a.fontFamily)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      // Double rule: thick accent line + thin grey line, like a letterhead band.
      Container(height: 3, color: a.accent),
      const SizedBox(height: 3),
      Container(height: 0.75, color: kRule),
      const SizedBox(height: 16),
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: kInk, letterSpacing: 1.6, fontFamily: a.fontFamily),
                ),
                const SizedBox(height: 4),
                if (a.businessAddress.isNotEmpty)
                  Text(a.businessAddress, style: TextStyle(fontSize: 9, color: kGrey,
                      height: 1.4, fontFamily: a.fontFamily)),
                if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                  Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                      style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: a.statusColor.withValues(alpha: 0.5), width: 1)),
            child: Text(a.statusLabel.toUpperCase(), style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                letterSpacing: 1.0, color: a.statusColor, fontFamily: a.fontFamily)),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _EditorialMetaRow(a: a),
      const SizedBox(height: 24),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _editorialContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text((a.businessName.isEmpty ? 'YOUR BUSINESS' : a.businessName).toUpperCase(),
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: kInk, letterSpacing: 1.2, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} No. ${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 6),
      Container(height: 2, color: a.accent),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _EditorialMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _EditorialMetaRow({required this.a});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.recipientLabel.toUpperCase(), style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                  color: kGrey, letterSpacing: 1.8, fontFamily: a.fontFamily)),
              const SizedBox(height: 8),
              Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
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
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _metaRow(a.metaLabel1, a.metaValue1, a.fontFamily),
              const SizedBox(height: 6),
              _metaRow(a.metaLabel2, a.metaValue2, a.fontFamily),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value, String ff) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
      Text(value.isEmpty ? '-' : value,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff)),
    ],
  );
}

// -----------------------------------------------------------------------
// Preview wrappers - one per doc type, each ~5 lines: convert to the
// adapter, hand off to TemplateDocument. These are what preview_registry
// files (invoice / quote / receipt) import and wire into their id switch.
// -----------------------------------------------------------------------

class EditorialInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const EditorialInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _editorialFullHeader,
        buildContinuationHeader: _editorialContinuationHeader,
        onPageCount: onPageCount,
      );
}

class EditorialQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const EditorialQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _editorialFullHeader,
        buildContinuationHeader: _editorialContinuationHeader,
        onPageCount: onPageCount,
      );
}

class EditorialReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const EditorialReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _editorialFullHeader,
        buildContinuationHeader: _editorialContinuationHeader,
        onPageCount: onPageCount,
      );
}
