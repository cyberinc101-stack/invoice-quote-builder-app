// brutalist_template.dart
// lib/doc_templates/09_brutalist/brutalist_template.dart
//
// Brutalist: raw, high-contrast, no soft edges anywhere - thick black
// rules and borders (no gradients, no tints, no rounded corners), with
// the accent color used as a single hard-edged block behind the doc-type
// label. Business identity sits in a black-bordered box. Everything reads
// as deliberately blunt rather than decorative - the opposite end of the
// spectrum from Pastel Soft's soft tint panel.
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

Widget _brutalistFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: a.accent,
            child: Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.w900, color: kInk, letterSpacing: 0.5, fontFamily: a.fontFamily)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: kInk, width: 1.5)),
            child: Text(a.statusLabel.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                letterSpacing: 0.8, color: kInk, fontFamily: a.fontFamily)),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Container(height: 4, color: kInk),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: kInk, width: 1.5)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (a.businessName.isEmpty ? 'YOUR BUSINESS' : a.businessName).toUpperCase(),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                        color: kInk, letterSpacing: 0.4, fontFamily: a.fontFamily),
                  ),
                  const SizedBox(height: 4),
                  if (a.businessAddress.isNotEmpty)
                    Text(a.businessAddress, style: TextStyle(fontSize: 9, color: kGrey,
                        height: 1.4, fontFamily: a.fontFamily)),
                  if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                    Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   /   '),
                        style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('NO. ${a.docNumber.isEmpty ? '-' : a.docNumber}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kInk, fontFamily: a.fontFamily)),
                const SizedBox(height: 2),
                Text(a.metaValue1, style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _BrutalistMetaRow(a: a),
      const SizedBox(height: 20),
      Container(height: 2, color: kInk),
      const SizedBox(height: 4),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _brutalistContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text((a.businessName.isEmpty ? 'YOUR BUSINESS' : a.businessName).toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                  color: kInk, letterSpacing: 0.4, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel.toUpperCase()} NO. ${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 8),
      Container(height: 3, color: kInk),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _BrutalistMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _BrutalistMetaRow({required this.a});

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
              Text(a.recipientLabel.toUpperCase(), style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800,
                  color: kInk, letterSpacing: 1.2, fontFamily: a.fontFamily)),
              const SizedBox(height: 6),
              Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kInk, fontFamily: a.fontFamily),
                  softWrap: true, overflow: TextOverflow.visible),
              if (a.clientAddress.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(a.clientAddress, style: TextStyle(fontSize: 9.5, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
              ],
              if (a.clientEmail.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(a.clientEmail, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
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
      Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kGrey, fontFamily: ff)),
      Text(value.isEmpty ? '-' : value,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: kInk, fontFamily: ff)),
    ],
  );
}

// -----------------------------------------------------------------------
// Preview wrappers - one per doc type, each ~5 lines: convert to the
// adapter, hand off to TemplateDocument. These are what preview_registry
// files (invoice / quote / receipt) import and wire into their id switch.
// -----------------------------------------------------------------------

class BrutalistInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const BrutalistInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _brutalistFullHeader,
        buildContinuationHeader: _brutalistContinuationHeader,
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
        onPageCount: onPageCount,
      );
}