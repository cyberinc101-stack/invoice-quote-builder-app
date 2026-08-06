// classic_template.dart
// lib/doc_templates/05_classic/classic_template.dart
//
// Classic: the most universally-standard business document layout - a
// plain identity block (no panel, no tint, no border - just type), doc
// type/number right-aligned, one thin accent rule beneath, and a light
// grey shaded header row on the line items table. This is the format
// that's been the default on real invoices for decades - no decorative
// device at all, just clean structure. Fills the id 5 slot between
// Vibrant (3) and Tech Dark (4)/Gradient Modern (6) in the numbering.
//
// Everything below the header (line items, totals, notes, footer) comes
// from shared_doc_widgets.dart unchanged - the shaded header row is just
// the standard buildSharedLineItemsHeaderRow wrapped in a light grey
// Container, not a new shared-widget parameter.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// -----------------------------------------------------------------------
// Header design
// -----------------------------------------------------------------------

Widget _classicFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a.businessName.isEmpty ? 'Your Business' : a.businessName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: kInk, fontFamily: a.fontFamily),
                ),
                const SizedBox(height: 5),
                if (a.businessAddress.isNotEmpty)
                  Text(a.businessAddress, style: TextStyle(fontSize: 9, color: kGrey,
                      height: 1.4, fontFamily: a.fontFamily)),
                if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                  Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                      style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: kInk, letterSpacing: 1.2, fontFamily: a.fontFamily)),
              const SizedBox(height: 5),
              Text('#${a.docNumber.isEmpty ? '-' : a.docNumber}',
                  style: TextStyle(fontSize: 10, color: kGrey, fontWeight: FontWeight.w500, fontFamily: a.fontFamily)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(height: 1.5, color: a.accent),
      const SizedBox(height: 22),
      _ClassicMetaRow(a: a),
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

class _ClassicMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _ClassicMetaRow({required this.a});

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
              Text(a.recipientLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                  color: kGrey, letterSpacing: 1.2, fontFamily: a.fontFamily)),
              const SizedBox(height: 8),
              Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInk, fontFamily: a.fontFamily),
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: a.statusColor.withOpacity(0.5), width: 1)),
                child: Text(a.statusLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                    letterSpacing: 1.0, color: a.statusColor, fontFamily: a.fontFamily)),
              ),
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
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
    ],
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
