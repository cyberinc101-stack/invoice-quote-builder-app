// pastel_soft_template.dart
// lib/document_layout_templates/08_pastel_soft/pastel_soft_template.dart
//
// TEN-TEMPLATE UNIQUENESS PASS (earlier): rebuilt around discrete rounded
// pill/chip badges for every meta field, floating on a plain white
// background, to stop overlapping Gradient Modern's tint-panel look at
// thumbnail scale. Superseded below.
//
// REFERENCE-IMAGE ACCENT-BAND PASS (this update): rebuilt a second time
// against a new reference image — a plain corporate invoice with a thin
// full-width accent bar under the header, a two-column "Invoice to /
// doc meta" row, a dark solid item-table header with a leading SL. (row
// number) column, striped rows, an accent-highlighted Total callout, an
// "Authorised Sign" line, and a thin accent line above a centered
// phone/address/email footer strip.
//
// The dark table header, striped rows, highlighted Total, and footer
// strip meant those pieces could no longer come from the shared,
// one-look-for-everyone versions in shared_doc_widgets.dart — same
// situation as Editorial. This template now supplies its own
// buildLineItemRow/buildTotalsSection/buildFooterContent to
// TemplateDocument (see the PER-TEMPLATE OVERRIDES PASS note in that
// file); Editorial and Pastel Soft are the only two templates opting
// into different looks for those three pieces, and they're independent
// of each other — the other 8 templates are unaffected either way.
//
// No dedicated "terms & conditions" or "payment info" adapter fields
// exist, so the notes panel keeps its existing "NOTES" heading/content
// rather than inventing data the adapter doesn't have; "Authorised Sign"
// is static boilerplate text, the same way "ITEM DESCRIPTION" and
// "NOTES" are already hardcoded chrome elsewhere in the shared widgets.
// The footer strip uses businessPhone/businessAddress/businessEmail —
// the same three contact fields Editorial's footer already draws on —
// in place of the reference's "Website" field, which the adapter doesn't
// have.
//
// Class names and signatures (PastelSoftInvoicePreview/PastelSoftQuote
// Preview/PastelSoftReceiptPreview) are unchanged, so preview_registry.
// dart files need no changes.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData, LineItem;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

// ─────────────────────────────────────────────────────────────────────────
// Full header — logo/business identity left, big doc-type label right; a
// thin full-width accent bar; a two-column "Invoice to" / doc-meta row;
// then the dark item-table header row.
// ─────────────────────────────────────────────────────────────────────────

Widget _pastelSoftFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildSharedLogo(a, size: 34.0),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (a.businessAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(a.businessAddress,
                            style: TextStyle(fontSize: 7.5, color: kGreyLight, letterSpacing: 0.6, fontFamily: a.fontFamily),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(a.docTypeLabel.toUpperCase(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kInk, letterSpacing: 1.2, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 14),
      Container(height: 9, color: a.accent),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.recipientLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                    color: kGreyLight, letterSpacing: 1.2, fontFamily: a.fontFamily)),
                const SizedBox(height: 6),
                Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
                if (a.clientAddress.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(a.clientAddress, style: TextStyle(fontSize: 9, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
                ],
                if (a.clientPhone.isNotEmpty || a.clientEmail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text([a.clientPhone, a.clientEmail].where((s) => s.isNotEmpty).join('   •   '),
                      style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _metaRow('${a.docTypeLabel}#', a.docNumber.isEmpty ? '-' : a.docNumber, a.fontFamily),
                const SizedBox(height: 6),
                _metaRow(a.metaLabel1, a.metaValue1.isEmpty ? '-' : a.metaValue1, a.fontFamily),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _pastelSoftLineItemsHeaderRow(dark: kInk, ff: a.fontFamily),
    ],
  );
}

Widget _metaRow(String label, String value, String ff) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('$label:  ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kGrey, fontFamily: ff)),
    Text(value, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
  ],
);

Widget _pastelSoftContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
          const Spacer(),
          Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 6),
      Container(height: 4, color: a.accent),
      const SizedBox(height: 14),
      _pastelSoftLineItemsHeaderRow(dark: kInk, ff: a.fontFamily),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Dark solid item-table header row — SL. / Item Description / Price /
// Qty. / Total, white labels on a dark bar. MUST stay in sync with
// _pastelSoftLineItemRow below (same five-column split).
// ─────────────────────────────────────────────────────────────────────────
Widget _pastelSoftLineItemsHeaderRow({required Color dark, required String ff}) {
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: Colors.white, letterSpacing: 0.6, fontFamily: ff);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
    color: dark,
    child: Row(children: [
      SizedBox(width: 22, child: Text('SL.', style: hdr)),
      Expanded(flex: 5, child: Text('ITEM DESCRIPTION', style: hdr)),
      Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: hdr)),
      Expanded(flex: 1, child: Text('QTY.', textAlign: TextAlign.center, style: hdr)),
      Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Striped item row (index.isEven = white, odd = a faint grey tint) with a
// leading row-number column, in the same SL. / Description / Price / Qty
// / Total order as the header row above. Passed to TemplateDocument as
// buildLineItemRow — see the PER-TEMPLATE OVERRIDES PASS note in
// shared_doc_widgets.dart.
// ─────────────────────────────────────────────────────────────────────────
Widget _pastelSoftLineItemRow({
  required LineItem item,
  required DocTemplateAdapter adapter,
  required String ff,
  required int index,
}) {
  final bg = index.isEven ? Colors.white : kPanelBg;
  return Container(
    color: bg,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 22, child: Text('${index + 1}',
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 5, child: Text(
          item.description.isEmpty ? 'Item description' : item.description,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, height: 1.4, fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible)),
      Expanded(flex: 2, child: Text(adapter.fmtMoney(item.unitPrice), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 1, child: Text(_fmtQty(item.quantity), textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 2, child: Text(adapter.fmtMoney(item.total), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Totals block — left column keeps the thank-you line and the existing
// NOTES panel (no dedicated terms/payment-info field exists in the
// adapter); right column is plain Subtotal/Discount/Tax rows, then a
// solid accent-highlighted Total callout, then a signature rule and
// static "Authorised Sign" label, matching the reference's layout.
// ─────────────────────────────────────────────────────────────────────────
Widget _pastelSoftTotalsSection(DocTemplateAdapter a) {
  Widget plainRow(String label, double v, {bool negative = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: Text(label,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: a.fontFamily),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8),
      Flexible(child: Text('${negative ? '−' : ''}${a.fmtMoney(v)}',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: a.fontFamily),
          textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );

  return Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.thankYouLabel,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
              if (a.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('NOTES', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                    color: kGreyLight, letterSpacing: 1.2, fontFamily: a.fontFamily)),
                const SizedBox(height: 6),
                Text(a.notes, style: TextStyle(fontSize: 9, color: kGrey, height: 1.5, fontFamily: a.fontFamily),
                    softWrap: true, overflow: TextOverflow.visible),
              ],
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              plainRow('Sub Total', a.subtotal),
              if (a.taxRate > 0) plainRow('Tax (${a.taxRate.toStringAsFixed(1)}%)', a.taxAmount),
              if (a.discountRate > 0)
                plainRow('Discount (${a.discountRate.toStringAsFixed(0)}%)', a.discountAmount, negative: true),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                color: a.accent,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Text(a.totalLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(a.fmtMoney(a.total),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: kInk, fontFamily: a.fontFamily),
                      textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
              const SizedBox(height: 42),
              Container(height: 1, color: kRule),
              const SizedBox(height: 6),
              Text('Authorised Sign', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Footer strip — thin accent line, then a centered row of business
// contact details (phone / address / email — the adapter has no
// "website" field), matching the reference's bottom accent-line-plus-
// contact-row band.
// ─────────────────────────────────────────────────────────────────────────
Widget _pastelSoftFooterContent(DocTemplateAdapter a) {
  final contact = [a.businessPhone, a.businessAddress, a.businessEmail]
      .where((s) => s.isNotEmpty)
      .join('   |   ');
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(height: 3, color: a.accent),
      const SizedBox(height: 10),
      if (contact.isNotEmpty)
        Text(contact, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8.5, color: kGrey, fontFamily: a.fontFamily),
            maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Preview wrappers — signatures unchanged; now also wire the three
// per-template overrides through to TemplateDocument.
// ─────────────────────────────────────────────────────────────────────────

class PastelSoftInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const PastelSoftInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _pastelSoftFullHeader,
        buildContinuationHeader: _pastelSoftContinuationHeader,
        buildLineItemRow: _pastelSoftLineItemRow,
        buildTotalsSection: _pastelSoftTotalsSection,
        buildFooterContent: _pastelSoftFooterContent,
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
        buildLineItemRow: _pastelSoftLineItemRow,
        buildTotalsSection: _pastelSoftTotalsSection,
        buildFooterContent: _pastelSoftFooterContent,
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
        buildLineItemRow: _pastelSoftLineItemRow,
        buildTotalsSection: _pastelSoftTotalsSection,
        buildFooterContent: _pastelSoftFooterContent,
        onPageCount: onPageCount,
      );
}