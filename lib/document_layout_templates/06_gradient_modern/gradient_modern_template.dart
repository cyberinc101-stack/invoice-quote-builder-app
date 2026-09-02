// gradient_modern_template.dart
// lib/document_layout_templates/06_gradient_modern/gradient_modern_template.dart
//
// SPACING TIGHTEN PASS (this update): the two-column header had generous
// vertical gaps stacking up in a few spots — 16px between the business
// contact block and the "INVOICE" heading, 8px between that heading and
// the doc-number line, 7px of bottom padding under every client detail
// line on the right, and 22px before the gradient line-items banner.
// Those add up fast in a header that's otherwise fairly compact content,
// leaving visible dead space (especially once the right column runs out
// of client detail lines before the left column runs out of meta rows).
// Trimmed to 10/6/5/16 respectively — same structure, same content, just
// less air between each line. Nothing else changed.
//
// CODESO REFERENCE REDESIGN PASS (earlier): the stat-card dashboard
// row (every meta field as its own small elevated white card in a Wrap)
// is replaced with a two-column header — left column: logo + business
// name, then a big doc-type heading ("INVOICE") with doc number and both
// meta fields stacked underneath it; right column: the recipient block,
// with each client detail (address/email/phone) as a small accent-
// colored caption over a dark value line. Below that, the line-items
// header row is no longer the shared plain-rule row — this template now
// draws its own gradient banner (near-black fading into the document's
// accent colour, left to right) with a fully rounded right end, holding
// the same DESCRIPTION/QTY/UNIT PRICE/TOTAL labels in white. It keeps the
// exact same column flex proportions (5/1/2/2) as
// buildSharedLineItemsHeaderRow so the line items rendered underneath by
// shared_doc_widgets.dart still line up correctly — only the container
// styling changes, not the column layout contract.
//
// This is a structurally different device from every other template's
// skeleton (not a Row(logo | identity | doc-type), not a stat-card Wrap,
// not a flat pill cluster) — a genuine two-column split with a signature
// gradient banner carried through into the continuation header too.
//
// NOTE on the reference design's dark wavy footer band (with the phone/
// email/location contact badges): like Tech Dark's page-corner wedge,
// that sits at the physical bottom of the page, which is owned by
// TemplateDocument's shared footerBuilder (the thin "thank you" strip),
// not by this file's header builders. Reproducing it would mean editing
// shared pagination code used by all 10 templates, so it's out of scope
// here — business contact details are instead kept as a compact line
// under the business name up top, so that data isn't dropped entirely.
//
// Everything below the header (line items, totals, notes, footer) still
// comes from shared_doc_widgets.dart unchanged.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// -----------------------------------------------------------------------
// Small accent-caption / dark-value line, used for the recipient block's
// address/email/phone rows.
// -----------------------------------------------------------------------
Widget _clientDetailLine(String label, String value, Color accent, String ff) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 7.5, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.8, fontFamily: ff)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );

// -----------------------------------------------------------------------
// Signature device: gradient banner (near-black -> accent) with a fully
// rounded right end, carrying the line-item column labels in white.
// Same flex proportions as buildSharedLineItemsHeaderRow (5/1/2/2) so the
// shared item rows underneath still align.
// -----------------------------------------------------------------------
Widget _gradientWaveHeaderRow({required Color accent, required String ff}) {
  final hdr = TextStyle(
      fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0, fontFamily: ff);
  return Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [kInk, accent], begin: Alignment.centerLeft, end: Alignment.centerRight),
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(17)),
    ),
    child: Row(
      children: [
        Expanded(flex: 5, child: Text('DESCRIPTION', style: hdr)),
        Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
        Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: hdr)),
        Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
      ],
    ),
  );
}

// -----------------------------------------------------------------------
// Header design
// -----------------------------------------------------------------------

Widget _gradientModernFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column — logo/identity, then the big doc-type heading
          // with doc number and meta fields stacked underneath.
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildSharedLogo(a, size: 34),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        a.businessName.isEmpty ? 'Your Business' : a.businessName,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: kInk,
                            letterSpacing: 0.3,
                            fontFamily: a.fontFamily),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (a.businessAddress.isNotEmpty || a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  if (a.businessAddress.isNotEmpty)
                    Text(a.businessAddress,
                        style: TextStyle(fontSize: 8, color: kGrey, fontFamily: a.fontFamily),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                    Text(
                      [a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                      style: TextStyle(fontSize: 8, color: kGrey, fontFamily: a.fontFamily),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                const SizedBox(height: 10),
                Text(
                  a.docTypeLabel,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                      letterSpacing: 0.5,
                      fontFamily: a.fontFamily),
                ),
                const SizedBox(height: 6),
                Text('${a.docTypeLabel} # ${a.docNumber.isEmpty ? '-' : a.docNumber}',
                    style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
                const SizedBox(height: 2),
                Text('${a.metaLabel1}: ${a.metaValue1.isEmpty ? '-' : a.metaValue1}',
                    style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
                const SizedBox(height: 2),
                Text('${a.metaLabel2}: ${a.metaValue2.isEmpty ? '-' : a.metaValue2}',
                    style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right column — recipient block, accent-caption / dark-value
          // detail lines (mirrors the reference's "Invoice To" panel).
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.recipientLabel.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: a.accent,
                        letterSpacing: 0.8,
                        fontFamily: a.fontFamily)),
                const SizedBox(height: 6),
                Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                if (a.clientAddress.isNotEmpty) _clientDetailLine('Address', a.clientAddress, a.accent, a.fontFamily),
                if (a.clientEmail.isNotEmpty) _clientDetailLine('Email', a.clientEmail, a.accent, a.fontFamily),
                if (a.clientPhone.isNotEmpty) _clientDetailLine('Phone', a.clientPhone, a.accent, a.fontFamily),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _gradientWaveHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _gradientModernContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: a.accent, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 14),
      _gradientWaveHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

// -----------------------------------------------------------------------
// Preview wrappers - one per doc type, each ~5 lines: convert to the
// adapter, hand off to TemplateDocument. These are what preview_registry
// files (invoice / quote / receipt) import and wire into their id switch.
// -----------------------------------------------------------------------

class GradientModernInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        onPageCount: onPageCount,
      );
}

class GradientModernQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        onPageCount: onPageCount,
      );
}

class GradientModernReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        onPageCount: onPageCount,
      );
}