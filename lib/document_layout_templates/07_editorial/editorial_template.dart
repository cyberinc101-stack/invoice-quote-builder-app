// editorial_template.dart
// lib/document_layout_templates/07_editorial/editorial_template.dart
//
// META ROW SWAP PASS (this update): the meta row under the top rule
// previously had the doc-no/issue-date pair on the LEFT and the "billed
// to" block on the RIGHT (right-aligned). Swapped per request: "billed
// to" now sits on the LEFT (left-aligned, matching the reading order of
// the rest of the page), and the doc-no/issue-date pair moved to the
// RIGHT (its two _labelValue columns now right-aligned as a group, so it
// still hugs the right edge cleanly rather than sitting left-aligned in
// the middle of empty space). Nothing else in the row — the two
// _labelValue columns, their flex proportions, the recipient block's own
// internal layout — changed; only which side each occupies and the
// billed-to block's text alignment.
//
// TEN-TEMPLATE UNIQUENESS PASS (earlier): rebuilt as a formal two-column
// LETTERHEAD/PROPOSAL layout to stop overlapping Nordic/Emerald.
//
// REFERENCE-IMAGE WAVE-HEADER PASS (earlier): rebuilt again as a dark
// diagonal wave banner with a gold ribbon accent, matching a first
// reference image. Superseded below.
//
// FLAT ACCENT-BAND PASS (earlier): rebuilt a third time against a
// second, much clearer reference image — a plain, flat, minimalist
// corporate invoice (logo + business name left / big colored doc-type
// label right, a compact two-up meta row, a right-aligned "billed to"
// block, a prominent "TOTAL DUE" callout, then a colored item-table
// header, striped rows, and a colored Grand Total bar, closing with a
// colored contact-details footer strip). No custom painting this time —
// everything here is plain Containers/Rows, which also makes it far more
// robust across page breaks than the wave shape was.
//
// Matching the item rows / totals bar / footer strip meant those three
// pieces could no longer come from the shared, one-look-for-everyone
// versions in shared_doc_widgets.dart — TemplateDocument there now
// exposes optional buildLineItemRow/buildTotalsSection/buildFooterContent
// hooks (see the PER-TEMPLATE OVERRIDES PASS note in that file) that
// default to the exact previous shared behaviour, so this is the only
// template opting into a different look for those pieces; the other 9
// templates are unaffected. Column ORDER for items also changes here
// (Description / Unit Price / Qty / Total, matching the reference) —
// _editorialLineItemsHeaderRow and _editorialLineItemRow below must stay
// in sync with each other since they're two halves of the same table.
//
// Class names and signatures (EditorialInvoicePreview/EditorialQuotePreview/
// EditorialReceiptPreview) are unchanged, so preview_registry.dart files
// need no changes.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData, LineItem;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

String _properCase(String s) =>
    s.isEmpty ? s : '${s[0]}${s.substring(1).toLowerCase()}';

// ─────────────────────────────────────────────────────────────────────────
// Full header — logo/business left, big colored doc-type label right; a
// left-aligned "billed to" block, right-aligned "doc no. / date" pair
// opposite it; a prominent TOTAL DUE callout; then the colored item-table
// header row.
// ─────────────────────────────────────────────────────────────────────────

Widget _editorialFullHeader(DocTemplateAdapter a) {
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
                buildSharedLogo(a, size: 40.0, fallbackMarkColor: a.accent),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    a.businessName.isEmpty ? 'Your Business' : a.businessName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            a.docTypeLabel,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                color: a.accent, letterSpacing: 1.6, fontFamily: a.fontFamily),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Container(height: 1, color: kRule),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Billed to" block — now on the LEFT, left-aligned to match
          // the page's normal reading order.
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.recipientLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                    color: kGreyLight, letterSpacing: 1.2, fontFamily: a.fontFamily)),
                const SizedBox(height: 5),
                Text(a.clientName.isEmpty ? 'Client name' : a.clientName, textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                    softWrap: true, overflow: TextOverflow.visible),
                if (a.clientAddress.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(a.clientAddress, textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 9, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
                ],
                if (a.clientPhone.isNotEmpty || a.clientEmail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text([a.clientPhone, a.clientEmail].where((s) => s.isNotEmpty).join('   •   '),
                      textAlign: TextAlign.left, style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Doc no. / issue date pair — now on the RIGHT, each column
          // right-aligned as a group so it hugs the right edge instead of
          // sitting left-aligned in the middle of the row.
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _labelValue('${_properCase(a.docTypeLabel)} no.', a.docNumber, a.fontFamily, align: TextAlign.right),
                const SizedBox(width: 20),
                _labelValue(a.metaLabel1, a.metaValue1, a.fontFamily, align: TextAlign.right),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(height: 1, color: kRule),
      const SizedBox(height: 16),
      Text(a.totalLabel.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kGreyLight, letterSpacing: 1.4, fontFamily: a.fontFamily)),
      const SizedBox(height: 6),
      Text(a.fmtMoney(a.total),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kInk, fontFamily: a.fontFamily)),
      const SizedBox(height: 20),
      _editorialLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _labelValue(String label, String value, String ff, {TextAlign align = TextAlign.left}) => Column(
  crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(label, textAlign: align,
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: kGreyLight, letterSpacing: 1.0, fontFamily: ff)),
    const SizedBox(height: 4),
    Text(value.isEmpty ? '-' : value, textAlign: align,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
  ],
);

Widget _editorialContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Container(width: 10, height: 10, color: a.accent),
          const SizedBox(width: 10),
          Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
          const Spacer(),
          Text('${a.docTypeLabel} No. ${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 14),
      _editorialLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Colored item-table header row — Description / Unit Price / Qty / Total,
// solid accent background, white labels. Column order matches the
// reference image and MUST stay in sync with _editorialLineItemRow below.
// ─────────────────────────────────────────────────────────────────────────
Widget _editorialLineItemsHeaderRow({required Color accent, required String ff}) {
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: Colors.white, letterSpacing: 0.8, fontFamily: ff);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
    color: accent,
    child: Row(children: [
      Expanded(flex: 5, child: Text('ITEM DESCRIPTION', style: hdr)),
      Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: hdr)),
      Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
      Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Striped item row (index.isEven = white, odd = a faint tint) in the same
// Description / Unit Price / Qty / Total order as the header row above.
// Passed to TemplateDocument as buildLineItemRow — see the PER-TEMPLATE
// OVERRIDES PASS note in shared_doc_widgets.dart.
// ─────────────────────────────────────────────────────────────────────────
Widget _editorialLineItemRow({
  required LineItem item,
  required DocTemplateAdapter adapter,
  required String ff,
  required int index,
}) {
  final bg = index.isEven ? Colors.white : const Color(0xFFF7F5F6);
  return Container(
    color: bg,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
// Totals block — plain Subtotal/Discount/Tax rows, then a Grand Total row
// on a solid accent bar with white text, matching the reference. Notes
// panel (if any) kept identical to the shared version so that data isn't
// silently dropped for this template.
// ─────────────────────────────────────────────────────────────────────────
Widget _editorialTotalsSection(DocTemplateAdapter a) {
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
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: kContentW * 0.42,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: a.fontFamily),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(a.fmtMoney(a.total),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: a.fontFamily),
                      textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ]),
          ),
        ),
        if (a.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kPanelBg, borderRadius: BorderRadius.circular(6)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('NOTES', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                  color: kGrey, letterSpacing: 1.2, fontFamily: a.fontFamily)),
              const SizedBox(height: 6),
              Text(a.notes, style: TextStyle(fontSize: 9.5, color: kInk, height: 1.5, fontFamily: a.fontFamily),
                  softWrap: true, overflow: TextOverflow.visible),
            ]),
          ),
        ],
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Footer strip — solid accent bar, contact line (or thankYouLabel as a
// fallback if no business contact fields are set) on the left, logo +
// business name repeated on the right, matching the reference's bottom
// "contact details / logo" band.
// ─────────────────────────────────────────────────────────────────────────
Widget _editorialFooterContent(DocTemplateAdapter a) {
  final contact = [a.businessPhone, a.businessEmail, a.businessAddress]
      .where((s) => s.isNotEmpty)
      .join('   •   ');
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    color: a.accent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            contact.isEmpty ? a.thankYouLabel : contact,
            style: TextStyle(fontSize: 8.5, color: Colors.white.withValues(alpha: 0.9), fontFamily: a.fontFamily),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        buildSharedLogo(a, size: 20.0, fallbackMarkColor: Colors.white, fallbackMarkTextColor: a.accent),
        const SizedBox(width: 8),
        Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: a.fontFamily)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Preview wrappers — signatures unchanged; now also wire the three
// per-template overrides through to TemplateDocument.
// ─────────────────────────────────────────────────────────────────────────

class EditorialInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const EditorialInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _editorialFullHeader,
        buildContinuationHeader: _editorialContinuationHeader,
        buildLineItemRow: _editorialLineItemRow,
        buildTotalsSection: _editorialTotalsSection,
        buildFooterContent: _editorialFooterContent,
        onPageCount: onPageCount,
      );
}

class EditorialQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const EditorialQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _editorialFullHeader,
        buildContinuationHeader: _editorialContinuationHeader,
        buildLineItemRow: _editorialLineItemRow,
        buildTotalsSection: _editorialTotalsSection,
        buildFooterContent: _editorialFooterContent,
        onPageCount: onPageCount,
      );
}

class EditorialReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const EditorialReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _editorialFullHeader,
        buildContinuationHeader: _editorialContinuationHeader,
        buildLineItemRow: _editorialLineItemRow,
        buildTotalsSection: _editorialTotalsSection,
        buildFooterContent: _editorialFooterContent,
        onPageCount: onPageCount,
      );
}