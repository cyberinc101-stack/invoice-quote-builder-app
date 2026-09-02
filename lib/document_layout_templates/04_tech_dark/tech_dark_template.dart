// tech_dark_template.dart
// lib/document_layout_templates/04_tech_dark/tech_dark_template.dart
//
// DIAGONAL RIBBON REDESIGN PASS (this update): Tech Dark's terminal/
// console-chrome header (title bar dots, "> LABEL value" monospace lines)
// is replaced with a two-tone diagonal ribbon banner in the top-right
// corner — a slanted accent-colored parallelogram carrying the doc type
// label, with a thin near-black parallelogram offset behind it as a
// layered "shadow" edge, echoing a red/black corner-wedge invoice design
// without needing to touch page-level chrome. Business identity moves to
// a plain left-aligned block (logo + name + address/contact, no bordered
// box), and client/meta info sits in a two-column row below (recipient
// block on the left, doc-no/date column right-aligned) instead of the old
// "> " console lines. Reads as a clean modern business invoice rather
// than a dev-tool skin — still structurally opposite to Vibrant/Classic/
// Gradient Modern's Row(logo | identity | doc-type) skeleton, just via a
// different visual language than the old terminal chrome.
//
// Only the header changes. Everything below it (line items, totals,
// footer) still comes from shared_doc_widgets.dart / TemplateDocument
// unchanged — this file only supplies buildFullHeader/
// buildContinuationHeader, same contract as before.
//
// NOTE on the reference design's page-corner wedge: that black triangle
// sits at the physical bottom-right corner of the whole page, which is
// outside what a per-template header can reach — A4Paginator only gives
// each template control over header/continuation-header, not a full-page
// background layer (that's shared across all 10 templates in
// TemplateDocument). Reproducing it exactly would mean editing shared
// pagination code, so instead that accent is echoed via the layered
// ribbon in the header. If you want the literal page-corner wedge too,
// that's a separate, deliberate change to TemplateDocument/A4Paginator —
// happy to do it, just flagging it's a shared-file change, not a
// Tech-Dark-only one.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

const Color _kTechInk = Color(0xFF14171C);

// -----------------------------------------------------------------------
// Ribbon clip shape — a parallelogram that's full-width at the top and
// cut in by `slant` px at the bottom-left, giving the "flag pointing
// down-right" diagonal edge seen in the reference design.
// -----------------------------------------------------------------------
class _RibbonClipper extends CustomClipper<Path> {
  final double slant;
  const _RibbonClipper({required this.slant});

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(slant, size.height)
    ..close();

  @override
  bool shouldReclip(covariant _RibbonClipper oldClipper) => oldClipper.slant != slant;
}

// -----------------------------------------------------------------------
// Two-tone diagonal ribbon — accent-colored banner with a thin dark
// parallelogram offset behind it as a layered edge (the red-over-black
// corner-wedge look from the reference, scoped to the header).
// -----------------------------------------------------------------------
class _TechRibbon extends StatelessWidget {
  final String label;
  final Color accent;
  final String ff;

  const _TechRibbon({required this.label, required this.accent, required this.ff});

  static const double _w = 176;
  static const double _h = 58;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _w + 6,
      height: _h + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dark backing sliver, offset down-right so a thin strip of it
          // shows past the accent ribbon's bottom/right edge.
          Positioned(
            left: 6,
            top: 6,
            width: _w,
            height: _h,
            child: ClipPath(
              clipper: const _RibbonClipper(slant: 22),
              child: Container(color: _kTechInk),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: _w,
            height: _h,
            child: ClipPath(
              clipper: const _RibbonClipper(slant: 22),
              child: Container(
                color: accent,
                padding: const EdgeInsets.fromLTRB(32, 16, 16, 10),
                alignment: Alignment.bottomRight,
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    fontFamily: ff,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _metaRow(String label, String value, String ff) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  ',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: kGrey, fontFamily: ff)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

// -----------------------------------------------------------------------
// Header design
// -----------------------------------------------------------------------

Widget _techDarkFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 82,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 2,
              right: 196,
              bottom: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSharedLogo(a, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.businessName.isEmpty ? 'Your Business' : a.businessName,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800, color: kInk, fontFamily: a.fontFamily),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (a.businessAddress.isNotEmpty)
                          Text(a.businessAddress,
                              style: TextStyle(fontSize: 8.5, color: kGrey, fontFamily: a.fontFamily),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                          Text(
                            [a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                            style: TextStyle(fontSize: 8.5, color: kGrey, fontFamily: a.fontFamily),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _TechRibbon(label: a.docTypeLabel, accent: a.accent, ff: a.fontFamily),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a.recipientLabel.toUpperCase(),
                  style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: a.accent,
                      letterSpacing: 1.2,
                      fontFamily: a.fontFamily),
                ),
                const SizedBox(height: 6),
                Text(
                  a.clientName.isEmpty ? 'Client name' : a.clientName,
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (a.clientEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(a.clientEmail,
                      style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _metaRow('${a.docTypeLabel} No.', a.docNumber.isEmpty ? '----' : a.docNumber, a.fontFamily),
              _metaRow(a.metaLabel1, a.metaValue1.isEmpty ? '-' : a.metaValue1, a.fontFamily),
              _metaRow(a.metaLabel2, a.metaValue2.isEmpty ? '-' : a.metaValue2, a.fontFamily),
            ],
          ),
        ],
      ),
      const SizedBox(height: 22),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _techDarkContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              (a.businessName.isEmpty ? 'Your Business' : a.businessName).toUpperCase(),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: kInk,
                  letterSpacing: 1.0,
                  fontFamily: a.fontFamily),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: a.accent, borderRadius: BorderRadius.circular(3)),
            child: Text(
              '${a.docTypeLabel} #${a.docNumber.isEmpty ? '----' : a.docNumber} ${a.continuationSuffix}',
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Container(height: 2, color: _kTechInk),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
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