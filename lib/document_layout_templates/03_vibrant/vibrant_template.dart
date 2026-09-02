// vibrant_template.dart
// lib/document_layout_templates/03_vibrant/vibrant_template.dart
//
// Vibrant: bold accent-color panel behind the identity block - business
// name and address sit in reversed (white-on-accent) type inside a solid
// color panel, with doc type/number right-aligned in the same panel.
// Everything below the header (line items, totals, notes, footer) comes
// from shared_doc_widgets.dart unchanged.
//
// This follows the same pattern as nordic_template.dart: one file, one
// design, driven entirely by DocTemplateAdapter so it renders correctly
// for invoice, quote, and receipt alike.
//
// LOGO PASS (this update): added the business logo inside the accent
// panel, left of the business name, via the shared buildSharedLogo()
// widget (shared_doc_widgets.dart). Because this header sits on a solid
// accent-colored background, the no-logo fallback mark is told to render
// white-on-transparent (fallbackMarkColor: Colors.white) with the accent
// color as the initial letter (fallbackMarkTextColor: a.accent) instead
// of buildSharedLogo()'s default accent-on-white — matching how the rest
// of this header already flips to reversed/white type against the panel.
// A real uploaded logo renders via SharedLogoThumbnail exactly as set by
// the user regardless of background, same as every other template.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// -----------------------------------------------------------------------
// Header design
// -----------------------------------------------------------------------

Widget _vibrantFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: a.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSharedLogo(
              a,
              size: 42.0,
              fallbackMarkColor: Colors.white,
              fallbackMarkTextColor: a.accent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a.businessName.isEmpty ? 'Your Business' : a.businessName,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.2, fontFamily: a.fontFamily),
                  ),
                  const SizedBox(height: 6),
                  if (a.businessAddress.isNotEmpty)
                    Text(a.businessAddress, style: TextStyle(fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.85), height: 1.4, fontFamily: a.fontFamily)),
                  if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                    Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   -   '),
                        style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.85), fontFamily: a.fontFamily)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 1.0, fontFamily: a.fontFamily)),
                const SizedBox(height: 6),
                Text('#${a.docNumber.isEmpty ? '-' : a.docNumber}',
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600, fontFamily: a.fontFamily)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _VibrantMetaRow(a: a),
      const SizedBox(height: 24),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _vibrantContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: a.accent, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: a.fontFamily)),
            Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
                style: TextStyle(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.85), fontFamily: a.fontFamily)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _VibrantMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _VibrantMetaRow({required this.a});

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
                  color: a.accent, letterSpacing: 1.4, fontFamily: a.fontFamily)),
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
                decoration: BoxDecoration(color: a.statusColor, borderRadius: BorderRadius.circular(4)),
                child: Text(a.statusLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                    letterSpacing: 1.0, color: Colors.white, fontFamily: a.fontFamily)),
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

class VibrantInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const VibrantInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _vibrantFullHeader,
        buildContinuationHeader: _vibrantContinuationHeader,
        onPageCount: onPageCount,
      );
}

class VibrantQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const VibrantQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _vibrantFullHeader,
        buildContinuationHeader: _vibrantContinuationHeader,
        onPageCount: onPageCount,
      );
}

class VibrantReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const VibrantReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _vibrantFullHeader,
        buildContinuationHeader: _vibrantContinuationHeader,
        onPageCount: onPageCount,
      );
}
