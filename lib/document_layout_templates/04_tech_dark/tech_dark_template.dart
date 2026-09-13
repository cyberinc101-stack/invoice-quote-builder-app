// tech_dark_template.dart
// lib/document_layout_templates/04_tech_dark/tech_dark_template.dart
//
// ITEMS-HEADER-ROW PASS (this update): _techDarkFullHeader and
// _techDarkContinuationHeader no longer call buildSharedLineItemsHeaderRow()
// themselves — supplied instead via buildLineItemsHeaderRow on every
// Preview class below. See a4_paginator.dart's header comment for the
// bug this fixes.
//
// UNUSED-IMPORT CLEANUP PASS (earlier): doc_totals.dart removed.
//
// DIAGONAL RIBBON REDESIGN PASS (earlier): Tech Dark's header uses a
// two-tone diagonal ribbon banner in the top-right corner carrying the
// doc type label, plain left-aligned business identity block, and a
// two-column client/meta row below.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../document_template_layout_data/doc_template_adapter.dart';
import '../document_template_layout_data/doc_header.dart';
import '../document_template_layout_data/doc_line_items.dart';
import '../document_template_layout_data/template_document.dart';

const Color _kTechInk = Color(0xFF14171C);

// -----------------------------------------------------------------------
// Ribbon clip shape — a parallelogram that's full-width at the top and
// cut in by `slant` px at the bottom-left.
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
// Two-tone diagonal ribbon.
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
//
// ITEMS-HEADER-ROW PASS: no longer ends with
// buildSharedLineItemsHeaderRow(adapter: a) — supplied via this file's
// Preview classes instead.
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
    ],
  );
}

// -----------------------------------------------------------------------
// Preview wrappers.
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
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
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
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
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
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}
