// tech_dark_template.dart
// lib/doc_templates/04_tech_dark/tech_dark_template.dart
//
// Tech Dark: near-black panel behind the identity block with a thin
// accent-colored top rule, and the doc number rendered as a bracketed
// monospace-style tag ([ INV-1042 ]). Distinct from Nordic (quiet,
// monochrome, no panel) and Vibrant (solid accent-color fill) - this one
// uses dark ink as the panel fill and the accent only as a rule/accent,
// keeping the "Bold" tag distinct from "Creative".
//
// Everything below the header (line items, totals, notes, footer) comes
// from shared_doc_widgets.dart unchanged.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

const Color _kTechPanel = Color(0xFF14171C);

// -----------------------------------------------------------------------
// Header design
// -----------------------------------------------------------------------

Widget _techDarkFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _kTechPanel,
          borderRadius: BorderRadius.circular(6),
          border: Border(top: BorderSide(color: a.accent, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
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
                        color: Colors.white, letterSpacing: 2.0, fontFamily: a.fontFamily),
                  ),
                  const SizedBox(height: 7),
                  if (a.businessAddress.isNotEmpty)
                    Text(a.businessAddress, style: TextStyle(fontSize: 9,
                        color: const Color(0xFF9AA4B2), height: 1.4, fontFamily: a.fontFamily)),
                  if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                    Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('  //  '),
                        style: TextStyle(fontSize: 9, color: const Color(0xFF9AA4B2), fontFamily: a.fontFamily)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: a.accent, letterSpacing: 3.0, fontFamily: a.fontFamily)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: a.accent.withValues(alpha: 0.55), width: 1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('[ ${a.docNumber.isEmpty ? '----' : a.docNumber} ]',
                      style: TextStyle(fontSize: 9.5, color: a.accent,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: a.fontFamily)),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _TechDarkMetaRow(a: a),
      const SizedBox(height: 24),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _techDarkContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kTechPanel,
          borderRadius: BorderRadius.circular(5),
          border: Border(top: BorderSide(color: a.accent, width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text((a.businessName.isEmpty ? 'YOUR BUSINESS' : a.businessName).toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 1.4, fontFamily: a.fontFamily)),
            Text('[ ${a.docTypeLabel} #${a.docNumber.isEmpty ? '----' : a.docNumber} ] ${a.continuationSuffix}',
                style: TextStyle(fontSize: 9, color: a.accent, fontFamily: a.fontFamily)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _TechDarkMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _TechDarkMetaRow({required this.a});

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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _kTechPanel, borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: a.statusColor.withValues(alpha: 0.6), width: 1)),
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
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff)),
    ],
  );
}

// -----------------------------------------------------------------------
// Preview wrappers - one per doc type, each ~5 lines: convert to the
// adapter, hand off to TemplateDocument. These are what preview_registry
// files (invoice / quote / receipt) import and wire into their id switch.
// -----------------------------------------------------------------------

class TechDarkInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const TechDarkInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _techDarkFullHeader,
        buildContinuationHeader: _techDarkContinuationHeader,
        onPageCount: onPageCount,
      );
}

class TechDarkQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const TechDarkQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _techDarkFullHeader,
        buildContinuationHeader: _techDarkContinuationHeader,
        onPageCount: onPageCount,
      );
}

class TechDarkReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const TechDarkReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _techDarkFullHeader,
        buildContinuationHeader: _techDarkContinuationHeader,
        onPageCount: onPageCount,
      );
}
