// emerald_template.dart
// lib/document_layout_templates/10_emerald/emerald_template.dart
//
// FIELD ORDER / COMPACTNESS PASS (this update): in the field stack
// (_EmeraldFieldStack), "Doc No." previously trailed at the very bottom
// of the column, after Billed To and both date fields. Moved to lead the
// stack instead — Doc No. now shows first, above Billed To — per
// request. Issue Date and Due Date (metaLabel1/metaLabel2) were also two
// separate stacked fields, each on its own line; they're now placed side
// by side in a single Row (each in an Expanded half) for compactness, so
// the column takes up one less line's worth of vertical space. Nothing
// else in the field stack (labels, bold treatment on the client name,
// address/email plain lines) changed.
//
// TEN-TEMPLATE UNIQUENESS PASS (earlier): reworked as a compact
// single-column FORM — every field (business, client, dates, status) a
// stacked label-above-value pair in one narrow column, logo centered
// above the business name, doc type as a small corner tag rather than a
// masthead heading. This header shape is unique in the set of 10 — no
// other template uses a single-column stacked-field pattern — and is
// KEPT UNCHANGED below, on purpose (see next note).
//
// REFERENCE-IMAGE TABLE/TOTALS PASS (earlier): asked to match a reference
// invoice image already used for Editorial (colored item-table header,
// striped rows, a colored Grand Total bar, a colored footer strip).
// Copying that reference wholesale — including its header — would have
// made Emerald render identically to Editorial, since color always comes
// from the document's own accent rather than a fixed per-template hue.
// Split the difference instead: Emerald's single-column form header (its
// one genuinely distinct feature) is UNCHANGED — identity and client/meta
// fields only, no totals data mixed in; only the item table, totals
// block, and footer below the header use the reference's colored-header/
// striped-rows/colored-bar treatment, via the same optional
// buildLineItemRow/buildTotalsSection/buildFooterContent hooks Editorial
// and Pastel Soft already use on TemplateDocument (see the PER-TEMPLATE
// OVERRIDES PASS note in shared_doc_widgets.dart).
//
// HEADER-DATA-IN-HEADER PASS (earlier): an earlier version of this pass
// added a "TOTAL DUE" callout under the field stack to mirror the
// reference more closely, but that put totals data inside the header —
// a mismatch with what the header is for. Removed; the total appears
// exactly once, in the totals block after the table.
//
// BILLED-TO-IN-HEADER PASS (earlier): the client/meta field stack
// (Billed To, Issue Date, Doc No.) was sitting in its own single narrow
// column BELOW the business identity block. Moved up into the same top
// row as the business name/address instead — identity left, field stack
// right — so all header-level data (business AND client/doc info) reads
// together at the top of the page rather than being split across two
// vertically stacked sections. The field stack itself (_EmeraldFieldStack)
// is unchanged — same label-over-value pattern, same fields — just
// repositioned.
//
// COMPACT HEADER PASS (earlier): with three stacked meta fields
// (Billed To block, Issue Date, Due Date, Doc No.) now living in the
// right-hand column, that column ran taller than the business-identity
// column beside it, and the Row's shared inter-section spacing (22/22/20)
// was sized for the old single, shorter layout — together this made the
// whole header noticeably tall with dead white space under the left
// column. Tightened the inter-section spacing (14/16/14 instead of
// 22/22/20) and the field stack's own internal rhythm (7px between field
// groups instead of 12px, 1px instead of 2-3px around each label/value
// pair) so the header reads as a compact block instead of a tall one,
// without dropping any field.
// Column order (Description / Unit Price / Qty / Total) matches the
// reference and MUST stay in sync between _emeraldLineItemsHeaderRow and
// _emeraldLineItemRow, since they're two halves of the same table.
//
// Class names and signatures (EmeraldInvoicePreview/EmeraldQuotePreview/
// EmeraldReceiptPreview) are unchanged, so preview_registry.dart files
// need no changes.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData, LineItem;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

// ─────────────────────────────────────────────────────────────────────────
// Header design — UNCHANGED single-column form (see note above): doc type
// is a small corner tag, logo centered above the business name, every
// field below a tight label-over-value stack in one column. Only new
// addition is the "TOTAL DUE" callout at the end, ahead of the table.
// ─────────────────────────────────────────────────────────────────────────

Widget _emeraldFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: a.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(a.docTypeLabel.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: a.accent, letterSpacing: 1.6, fontFamily: a.fontFamily)),
          ),
          Text(a.statusLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600,
              color: a.statusColor, letterSpacing: 0.4, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo centered above the name, not beside it — a form's
                // letterhead mark rather than a masthead row.
                buildSharedLogo(a, size: 26.0),
                const SizedBox(height: 8),
                Text(
                  a.businessName.isEmpty ? 'Your Business' : a.businessName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                ),
                if (a.businessAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(a.businessAddress, style: TextStyle(fontSize: 9, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
                ],
                if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                      style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _EmeraldFieldStack(a: a),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(height: 1, color: kRule),
      const SizedBox(height: 14),
      _emeraldLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
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
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily)),
          Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
              style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
        ],
      ),
      const SizedBox(height: 12),
      Container(height: 1, color: kRule),
      const SizedBox(height: 16),
      _emeraldLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

// Every field as its own tight label-above-value block, stacked in one
// column — a plain filled-in form rather than a two-column layout.
//
// FIELD ORDER PASS (this update): doc number now leads the stack (above
// Billed To) instead of trailing at the bottom, per request. Issue Date
// and Due Date (metaLabel1/metaLabel2) are now placed side by side in a
// single Row instead of two separate stacked fields, for compactness —
// each takes half the column width via Expanded.
class _EmeraldFieldStack extends StatelessWidget {
  final DocTemplateAdapter a;
  const _EmeraldFieldStack({required this.a});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _field('Doc No.', a.docNumber.isEmpty ? '—' : a.docNumber),
        const SizedBox(height: 7),
        _field(a.recipientLabel, a.clientName.isEmpty ? 'Client name' : a.clientName, bold: true),
        if (a.clientAddress.isNotEmpty) _fieldPlain(a.clientAddress),
        if (a.clientEmail.isNotEmpty) _fieldPlain(a.clientEmail),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field(a.metaLabel1, a.metaValue1.isEmpty ? '—' : a.metaValue1)),
            const SizedBox(width: 12),
            Expanded(child: _field(a.metaLabel2, a.metaValue2.isEmpty ? '—' : a.metaValue2)),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
            color: kGreyLight, letterSpacing: 1.0, fontFamily: a.fontFamily)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: bold ? 12.5 : 10.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: kInk, fontFamily: a.fontFamily),
            softWrap: true, overflow: TextOverflow.visible),
      ],
    ),
  );

  Widget _fieldPlain(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 1),
    child: Text(value, style: TextStyle(fontSize: 9.5, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Colored item-table header row — Description / Unit Price / Qty / Total,
// solid accent background, white labels, matching the reference image.
// MUST stay in sync with _emeraldLineItemRow below.
// ─────────────────────────────────────────────────────────────────────────
Widget _emeraldLineItemsHeaderRow({required Color accent, required String ff}) {
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
// Striped item row (index.isEven = white, odd = a faint tint), same
// Description / Unit Price / Qty / Total order as the header row above.
// Passed to TemplateDocument as buildLineItemRow — see the PER-TEMPLATE
// OVERRIDES PASS note in shared_doc_widgets.dart.
// ─────────────────────────────────────────────────────────────────────────
Widget _emeraldLineItemRow({
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
// panel (if any) kept so that data isn't silently dropped for this
// template.
// ─────────────────────────────────────────────────────────────────────────
Widget _emeraldTotalsSection(DocTemplateAdapter a) {
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
Widget _emeraldFooterContent(DocTemplateAdapter a) {
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
// Preview wrappers — unchanged signatures, so preview_registry.dart files
// (invoice / quote / receipt) need no changes.
// ─────────────────────────────────────────────────────────────────────────

class EmeraldInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const EmeraldInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _emeraldFullHeader,
        buildContinuationHeader: _emeraldContinuationHeader,
        buildLineItemRow: _emeraldLineItemRow,
        buildTotalsSection: _emeraldTotalsSection,
        buildFooterContent: _emeraldFooterContent,
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
        buildLineItemRow: _emeraldLineItemRow,
        buildTotalsSection: _emeraldTotalsSection,
        buildFooterContent: _emeraldFooterContent,
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
        buildLineItemRow: _emeraldLineItemRow,
        buildTotalsSection: _emeraldTotalsSection,
        buildFooterContent: _emeraldFooterContent,
        onPageCount: onPageCount,
      );
}