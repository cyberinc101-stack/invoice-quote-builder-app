// pastel_soft_template.dart
// lib/doc_templates/08_pastel_soft/pastel_soft_template.dart
//
// Pastel Soft: a flat soft-tint panel (accent color blended lightly into
// white — NOT a gradient, that's Gradient Modern's move) sits behind the
// identity block, with rounded corners and a thin matching rule beneath.
// Business name and totals stay in dark ink for readability; the accent
// only shows up as the tint, the rule, and small label text. Quiet and
// minimal, in the same restrained spirit as Nordic, just warmer.
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

Color _pastelTint(Color accent) => Color.alphaBlend(accent.withValues(alpha: 0.10), Colors.white);

Widget _pastelSoftFullHeader(DocTemplateAdapter a) {
  final tint = _pastelTint(a.accent);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(10),
        ),
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
                    a.businessName.isEmpty ? 'Your Business' : a.businessName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: kInk, fontFamily: a.fontFamily),
                  ),
                  const SizedBox(height: 4),
                  if (a.businessAddress.isNotEmpty)
                    Text(a.businessAddress, style: TextStyle(fontSize: 9, color: kGrey,
                        height: 1.4, fontFamily: a.fontFamily)),
                  if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                    Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   Â·   '),
                        style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: a.accent, letterSpacing: 1.0, fontFamily: a.fontFamily)),
                const SizedBox(height: 4),
                Text('No. ${a.docNumber.isEmpty ? '-' : a.docNumber}',
                    style: TextStyle(fontSize: 10, color: kGrey, fontFamily: a.fontFamily)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Container(height: 1.5, color: a.accent.withValues(alpha: 0.35)),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PastelSoftMetaRow(a: a),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: a.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(a.statusLabel.toUpperCase(), style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                letterSpacing: 0.6, color: a.statusColor, fontFamily: a.fontFamily)),
          ),
        ],
      ),
      const SizedBox(height: 24),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _pastelSoftContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: kInk, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} No. ${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 6),
      Container(height: 1.5, color: a.accent.withValues(alpha: 0.35)),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _PastelSoftMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _PastelSoftMetaRow({required this.a});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(a.recipientLabel.toUpperCase(), style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
              color: kGrey, letterSpacing: 1.4, fontFamily: a.fontFamily)),
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
          const SizedBox(height: 10),
          Row(
            children: [
              _metaChip(a.metaLabel1, a.metaValue1, a.fontFamily),
              const SizedBox(width: 16),
              _metaChip(a.metaLabel2, a.metaValue2, a.fontFamily),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String label, String value, String ff) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: TextStyle(fontSize: 8.5, color: kGrey, fontFamily: ff)),
      const SizedBox(height: 2),
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

class PastelSoftInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const PastelSoftInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _pastelSoftFullHeader,
        buildContinuationHeader: _pastelSoftContinuationHeader,
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
        onPageCount: onPageCount,
      );
}
