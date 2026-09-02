// brutalist_template.dart
// lib/document_layout_templates/09_brutalist/brutalist_template.dart
//
// REPLACED (this update): Brutalist's raw-border/thick-black-rule design
// is retired in favor of an angular ribbon-block letterhead, per Jesse's
// reference image — a dark, diagonally-clipped block behind the
// recipient info sits top-left, with a big "INVOICE" heading and doc
// number/date rows top-right. This is the one template in the set that
// uses a genuinely angular (non-rectangular) shape as its identity
// device, distinct from every panel/rule/column used elsewhere.
//
// Class names/signatures (BrutalistInvoicePreview/BrutalistQuotePreview/
// BrutalistReceiptPreview) and the file path are unchanged, so
// preview_registry.dart files need no further edits beyond the
// description/tag text update — this is a drop-in replacement under the
// same template slot.
//
// Everything below the header (line items, totals, notes, footer) still
// comes from shared_doc_widgets.dart unchanged, same as every other
// template.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────
// Ribbon clipper — a flat left/top/bottom edge with a single diagonal cut
// on the right side, giving the block an angular "ribbon" silhouette
// instead of a plain rectangle.
// ─────────────────────────────────────────────────────────────────────────
class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper();

  @override
  Path getClip(Size size) {
    final cut = size.width * 0.16;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────
// Header design
// ─────────────────────────────────────────────────────────────────────────

Widget _brutalistFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Angular ribbon block — recipient info in reversed
            // (white-on-dark) type, diagonally clipped on the right.
            Expanded(
              flex: 3,
              child: ClipPath(
                clipper: const _RibbonClipper(),
                child: Container(
                  color: kInk,
                  padding: const EdgeInsets.fromLTRB(16, 18, 28, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.recipientLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white70, letterSpacing: 0.6, fontFamily: a.fontFamily)),
                      const SizedBox(height: 8),
                      Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: a.fontFamily),
                          softWrap: true, overflow: TextOverflow.visible),
                      if (a.clientAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(a.clientAddress, style: TextStyle(fontSize: 9, color: Colors.white60, height: 1.4, fontFamily: a.fontFamily)),
                      ],
                      if (a.clientEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(a.clientEmail, style: TextStyle(fontSize: 9, color: Colors.white60, fontFamily: a.fontFamily)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Business identity + doc heading, plain white background.
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildSharedLogo(a, size: 26.0),
                        const SizedBox(width: 8),
                        Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                            color: a.accent, letterSpacing: 1.0, fontFamily: a.fontFamily)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _kv('${a.docTypeLabel.substring(0, 3)}#', a.docNumber.isEmpty ? '-' : a.docNumber, a.fontFamily),
                    const SizedBox(height: 3),
                    _kv('Date', a.metaValue1.isEmpty ? '-' : a.metaValue1, a.fontFamily),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: a.statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(3)),
                      child: Text(a.statusLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                          letterSpacing: 0.6, color: a.statusColor, fontFamily: a.fontFamily)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Container(
        color: kInk,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            SizedBox(width: 20, child: Text('SL.', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: a.fontFamily))),
            Expanded(flex: 5, child: Text('ITEM DESCRIPTION', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.6, fontFamily: a.fontFamily))),
            Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: a.fontFamily))),
            Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: a.fontFamily))),
            Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: a.fontFamily))),
          ],
        ),
      ),
    ],
  );
}

Widget _kv(String k, String v, String ff) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('$k  ', style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
    Text(v, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff)),
  ],
);

Widget _brutalistContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kInk, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        color: kInk,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            SizedBox(width: 20, child: Text('SL.', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: a.fontFamily))),
            Expanded(flex: 5, child: Text('ITEM DESCRIPTION', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.6, fontFamily: a.fontFamily))),
            Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: a.fontFamily))),
            Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: a.fontFamily))),
            Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: a.fontFamily))),
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Preview wrappers — unchanged signatures.
// ─────────────────────────────────────────────────────────────────────────

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