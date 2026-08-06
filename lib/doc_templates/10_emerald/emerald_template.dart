// emerald_template.dart
// lib/doc_templates/10_emerald/emerald_template.dart
//
// Emerald: elegant and understated - no panel, no fill, no border. The
// business name sits in a refined, slightly wider-set weight, with a
// single thin emerald-accent hairline rule beneath the identity block
// (double-thin, echoing fine stationery rather than a corporate form).
// The doc type is set in small tracked-out caps rather than a big
// display size, keeping the whole header quiet and premium-feeling.
// Distinct from Nordic (grey/neutral, no color) and Classic (plain,
// utilitarian) - this one leans refined rather than merely restrained.
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

Widget _emeraldFullHeader(DocTemplateAdapter a) {
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: kInk, letterSpacing: 0.6, fontFamily: a.fontFamily),
                ),
                const SizedBox(height: 6),
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
              Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: a.accent, letterSpacing: 3.2, fontFamily: a.fontFamily)),
              const SizedBox(height: 8),
              Text('No. ${a.docNumber.isEmpty ? '-' : a.docNumber}',
                  style: TextStyle(fontSize: 10, color: kGrey, fontWeight: FontWeight.w500, fontFamily: a.fontFamily)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      // Thin double hairline, echoing fine stationery rather than a form.
      Container(height: 0.75, color: a.accent),
      const SizedBox(height: 2),
      Container(height: 0.75, color: a.accent.withOpacity(0.35)),
      const SizedBox(height: 26),
      _EmeraldMetaRow(a: a),
      const SizedBox(height: 26),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _emeraldContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
                  color: kInk, letterSpacing: 0.4, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} No. ${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 8),
      Container(height: 0.75, color: a.accent),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _EmeraldMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _EmeraldMetaRow({required this.a});

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
                  color: a.accent, letterSpacing: 1.8, fontFamily: a.fontFamily)),
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
                child: Text(a.statusLabel.toUpperCase(), style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
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

class EmeraldInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const EmeraldInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _emeraldFullHeader,
        buildContinuationHeader: _emeraldContinuationHeader,
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
        onPageCount: onPageCount,
      );
}
