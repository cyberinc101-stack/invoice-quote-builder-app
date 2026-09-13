// executive_template.dart
// lib/document_layout_templates/01_executive/executive_template.dart
//
// ITEMS-HEADER-ROW PASS (this update): _executiveFullHeader and
// _executiveContinuationHeader no longer call
// buildSharedLineItemsHeaderRow() themselves — that row is now supplied
// to TemplateDocument via the new `buildLineItemsHeaderRow` param on
// every Preview/Editor class below, and A4Paginator decides per page
// whether to actually show it (skipped on a totals-only overflow page
// with zero items). See a4_paginator.dart's header comment for the bug
// this fixes: a floating column-header row above nothing whenever the
// totals block overflowed to its own page.
//
// MERGE PASS (earlier): this file does everything the three deleted
// files did — executive_invoice_stationary_layout.dart, executive_quote_
// stationary_layout.dart, executive_receipt_stationary_layout.dart, and
// their matching *_payment_terms_signature.dart / *_logic_data.dart
// files. Both Preview (read-only) AND Editor (WYSIWYG tap-to-edit) run
// through the same DocTemplateAdapter/TemplateDocument plumbing.
//
// What changed to make the merge possible:
//   1. invoiceAccent()/quoteAccent()/receiptAccent() now live HERE.
//   2. _executiveFullHeader / _executiveContinuationHeader take an
//      optional `edit` param and build via buildSharedHeaderIdentity() /
//      buildSharedMetaRow() (doc_header.dart) instead of composing their
//      own Text widgets.
//   3. Three Editor wrapper widgets — ExecutiveInvoiceEditor,
//      ExecutiveQuoteEditor, ExecutiveReceiptEditor — mirror the
//      existing Preview wrappers exactly, but require a DocEditBundle
//      and pass it through to TemplateDocument.
//
// ENGINE FOLDER SPLIT PASS (earlier): imports redirected off shared/
// (now removed) to document_template_layout_data/.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData, InvoiceColor;
import '../../models/quote_data.dart' show QuoteData, QuoteColor;
import '../../models/receipt_data.dart' show ReceiptData, ReceiptColor;
import '../document_template_layout_data/doc_template_adapter.dart';
import '../document_template_layout_data/doc_edit_bundle.dart';
import '../document_template_layout_data/doc_header.dart'
    show buildSharedHeaderIdentity, buildSharedMetaRow, kRule, kGrey, kGreyLight;
import '../document_template_layout_data/doc_line_items.dart'
    show buildSharedLineItemsHeaderRow;
import '../document_template_layout_data/template_document.dart';

// ─────────────────────────────────────────────────────────────────────────
// MERGE PASS: the six script-font families offered for a typed
// signature, moved here from the now-deleted
// executive_invoice_payment_terms_signature.dart.
// ─────────────────────────────────────────────────────────────────────────

const List<String> kSignatureFonts = [
  'Dancing Script',
  'Great Vibes',
  'Sacramento',
  'Pacifico',
  'Alex Brush',
  'Caveat',
];

// ─────────────────────────────────────────────────────────────────────────
// MERGE PASS: accent-color functions, moved here from the three deleted
// *_stationary_layout.dart files. doc_template_adapter.dart's
// invoiceToAdapter()/quoteToAdapter()/receiptToAdapter() import these
// three from this file.
// ─────────────────────────────────────────────────────────────────────────

Color invoiceAccent(InvoiceData d) {
  switch (d.colorScheme) {
    case InvoiceColor.blue:   return const Color(0xFF2563EB);
    case InvoiceColor.green:  return const Color(0xFF16A34A);
    case InvoiceColor.purple: return const Color(0xFF7C3AED);
    case InvoiceColor.orange: return const Color(0xFFEA580C);
    case InvoiceColor.red:    return const Color(0xFFDC2626);
    case InvoiceColor.teal:   return const Color(0xFF0D9488);
    case InvoiceColor.black:  return const Color(0xFF1A1A1A);
    case InvoiceColor.indigo: return const Color(0xFF4F46E5);
  }
}

Color quoteAccent(QuoteData d) {
  switch (d.colorScheme) {
    case QuoteColor.blue:   return const Color(0xFF2563EB);
    case QuoteColor.green:  return const Color(0xFF16A34A);
    case QuoteColor.purple: return const Color(0xFF7C3AED);
    case QuoteColor.orange: return const Color(0xFFEA580C);
    case QuoteColor.red:    return const Color(0xFFDC2626);
    case QuoteColor.teal:   return const Color(0xFF0D9488);
    case QuoteColor.black:  return const Color(0xFF1A1A1A);
    case QuoteColor.indigo: return const Color(0xFF4F46E5);
  }
}

Color receiptAccent(ReceiptData d) {
  switch (d.colorScheme) {
    case ReceiptColor.blue:   return const Color(0xFF2563EB);
    case ReceiptColor.green:  return const Color(0xFF16A34A);
    case ReceiptColor.purple: return const Color(0xFF7C3AED);
    case ReceiptColor.orange: return const Color(0xFFEA580C);
    case ReceiptColor.red:    return const Color(0xFFDC2626);
    case ReceiptColor.teal:   return const Color(0xFF0D9488);
    case ReceiptColor.black:  return const Color(0xFF1A1A1A);
    case ReceiptColor.indigo: return const Color(0xFF4F46E5);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Header design — diamond logo mark, generous whitespace, single page in
// spirit (paginates via A4Paginator like every other design).
//
// ITEMS-HEADER-ROW PASS: no longer ends with
// buildSharedLineItemsHeaderRow(adapter: a) — A4Paginator renders that
// row itself now, per page, only when the page has items. See this
// file's own Preview/Editor classes for where it's supplied instead.
// ─────────────────────────────────────────────────────────────────────────

Widget _executiveFullHeader(DocTemplateAdapter a, {DocEditBundle? edit}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      buildSharedHeaderIdentity(a: a, edit: edit),
      const SizedBox(height: 28),
      Container(height: 1, color: kRule),
      const SizedBox(height: 24),
      buildSharedMetaRow(a: a, edit: edit),
    ],
  );
}

Widget _executiveContinuationHeader(DocTemplateAdapter a, {DocEditBundle? edit}) {
  final showDocNumber = docFieldOn(a, 'invoiceNumber');
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGrey, fontFamily: a.fontFamily)),
      Flexible(
        child: Text(
            showDocNumber
                ? '${a.docTypeLabel} #${a.docNumber.isEmpty ? '—' : a.docNumber} ${a.continuationSuffix}'
                : '${a.docTypeLabel} ${a.continuationSuffix}',
            style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: a.fontFamily),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Preview wrappers — read-only (edit bundle is null internally).
// ─────────────────────────────────────────────────────────────────────────

class ExecutiveInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(a),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class ExecutiveQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(a),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class ExecutiveReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(a),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// MERGE PASS: Editor wrappers — WYSIWYG editable, mirror the Preview
// wrappers exactly but require a DocEditBundle and pass it through to
// TemplateDocument.
// ─────────────────────────────────────────────────────────────────────────

class ExecutiveInvoiceEditor extends StatelessWidget {
  final InvoiceData data;
  final DocEditBundle edit;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveInvoiceEditor({super.key, required this.data, required this.edit, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(a, edit: edit),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a, edit: edit),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
        edit: edit,
      );
}

class ExecutiveQuoteEditor extends StatelessWidget {
  final QuoteData data;
  final DocEditBundle edit;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveQuoteEditor({super.key, required this.data, required this.edit, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(a, edit: edit),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a, edit: edit),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
        edit: edit,
      );
}

class ExecutiveReceiptEditor extends StatelessWidget {
  final ReceiptData data;
  final DocEditBundle edit;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveReceiptEditor({super.key, required this.data, required this.edit, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(a, edit: edit),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a, edit: edit),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
        edit: edit,
      );
}
