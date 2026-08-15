// nordic_template.dart
// lib/doc_templates/02_nordic/nordic_template.dart
//
// Nordic: monochrome minimal, thin double rule under the identity block,
// wide letter-spaced business name, no logo mark (initial-only wordmark
// keeps the header quiet). Everything below the header (line items,
// totals, notes, footer) comes from shared_doc_widgets.dart unchanged.
//
// This is the pattern every other new template follows: one file, one
// design, driven entirely by DocTemplateAdapter so it renders correctly
// for invoice, quote, and receipt alike.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Header design
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: kInk, letterSpacing: 2.4, fontFamily: a.fontFamily),
                ),
                const SizedBox(height: 6),
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
              Text(a.docTypeLabel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300,
                  color: kInk, letterSpacing: 5.0, fontFamily: a.fontFamily)),
              const SizedBox(height: 6),
              Text('#${a.docNumber.isEmpty ? 'â€”' : a.docNumber}',
                  style: TextStyle(fontSize: 10, color: kGrey, fontWeight: FontWeight.w500, fontFamily: a.fontFamily)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 22),
      // Thin double rule â€” Nordic's one signature flourish.
      Container(height: 1, color: kInk),
      const SizedBox(height: 2),
      Container(height: 1, color: kRule),
      const SizedBox(height: 24),
      _NordicMetaRow(a: a),
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
          Text((a.businessName.isEmpty ? 'YOUR BUSINESS' : a.businessName).toUpperCase(),
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: kGrey, letterSpacing: 1.6, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? 'â€”' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _NordicMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _NordicMetaRow({required this.a});

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
                  color: kGrey, letterSpacing: 1.8, fontFamily: a.fontFamily)),
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
                decoration: BoxDecoration(border: Border.all(color: a.statusColor.withValues(alpha: 0.5), width: 1)),
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
      Text(value.isEmpty ? 'â€”' : value,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
    ],
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Preview wrappers â€” one per doc type, each ~5 lines: convert to the
// adapter, hand off to TemplateDocument. These are what preview_registry
// files (invoice / quote / receipt) import and wire into their id switch.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
