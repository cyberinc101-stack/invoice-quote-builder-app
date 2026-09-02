// executive_template.dart
// lib/document_layout_templates/01_executive/executive_template.dart
//
// Consolidated, read-only Executive design in the same one-file-per-
// template shape as every other design in document_layout_templates/
// (nordic_template.dart, vibrant_template.dart, etc.) — built against the
// shared DocTemplateAdapter/TemplateDocument plumbing in
// document_layout_templates/shared/ instead of Executive's own bespoke
// pagination-measuring code.
//
// This file is for CHOOSER THUMBNAILS AND PREVIEW REGISTRIES ONLY. It
// does not replace executive_invoice_stationary_layout.dart /
// executive_invoice_logic_data.dart, which remain in use by:
//   - invoice_editable_canvas_screen.dart (WYSIWYG editing — this design
//     supports tappable/editable fields via InvoiceEditBundle; the other
//     designs, and this consolidated file, are preview-only)
//   - step_customise.dart's live preview (which needs the exact same
//     editable-capable widget for continuity with the edit canvas)
//
// Quote and receipt have no editable-canvas equivalent, so their exports
// here fully replace their old separate logic_data/stationary_layout
// pairs for preview purposes — those two old file-pairs can be considered
// legacy/unused once this file is wired into the preview registries,
// though they haven't been deleted here to keep this change low-risk.
//
// TEMPLATE FIELD VISIBILITY PASS (this update): _executiveFullHeader and
// _ExecutiveMetaRow now gate every field that has a matching toggle in
// step_templates.dart's "Invoice Fields"/"Customer Fields" sheet, via the
// new docFieldOn() helper (doc_template_adapter.dart) — businessName,
// businessEmail, businessPhone, businessAddress, invoiceNumber (the doc
// number line), customerName/Email/Phone/Address, date, dueDate. This is
// the file that actually renders in the template chooser grid and the
// "Preview" screen (via preview_registry.dart -> buildInvoicePreview),
// which is why toggling a field off in the template sheet previously had
// no visible effect there even after InvoiceData.enabledFields and the
// separate WYSIWYG-canvas path (executive_invoice_stationary_layout.dart)
// were fixed — this file, and the DocTemplateAdapter/shared_doc_widgets.
// dart plumbing it's built on, were never wired to read that map at all.
// Missing keys default to true, so quote/receipt (whose adapters don't
// populate enabledFields yet — see doc_template_adapter.dart) and any
// invoice saved before this field existed render exactly as before.
//
// SHARED LOGO PASS: _ExecutiveLogo now delegates to buildSharedLogo()
// (shared_doc_widgets.dart) instead of its own plain ClipOval +
// BoxFit.cover render.
//
// LOGO SIZE WIRING FIX (earlier update): the header logo was calling
// buildSharedLogo(a, size: 44.0) -- a hardcoded override that ignored
// whatever the user actually set via the Logo Size slider on the
// Customise step (a.businessLogoDisplaySize). buildSharedLogo() already
// falls back to a.businessLogoDisplaySize when no explicit `size` is
// passed (see shared_doc_widgets.dart), so the fix is simply to stop
// passing size at all here. No changes were needed in
// doc_template_adapter.dart or shared_doc_widgets.dart -- both already
// carried/consumed businessLogoDisplaySize correctly; this was purely an
// unnecessary override sitting in this one template file.
//
// DOC NUMBER WRAP/ALIGNMENT FIX (earlier update): the "#INV-..." text in
// the header's trailing Column previously had no width constraint and
// no textAlign. When the number was long enough to wrap, the wrapped
// second line defaulted to left-alignment inside the block (the block
// itself was pushed right by CrossAxisAlignment.end), producing the
// orphaned "#" visual bug reported: first line flush right, "#" and the
// tail of the number appearing to float on their own line to the left.
// Fixed by wrapping the trailing header column in a ConstrainedBox and
// giving both header texts explicit textAlign: TextAlign.right, plus
// capping the doc-number line to a single line with ellipsis overflow so
// an unusually long number truncates cleanly instead of wrapping badly.
// This is paired with a shorter default invoice-number format and a
// lower max character cap on the Invoice Number field itself (see
// step_create_invoice.dart) so truncation should now be rare in practice.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────
// Header design — diamond logo mark, generous whitespace, single page in
// spirit (though now paginates properly via A4Paginator like every other
// design, instead of Executive's old Transform.scale-to-fit approach).
// ─────────────────────────────────────────────────────────────────────────

Widget _executiveFullHeader(DocTemplateAdapter a) {
  final showBusinessName = docFieldOn(a, 'businessName');
  final showBusinessAddress = docFieldOn(a, 'businessAddress');
  final showBusinessEmail = docFieldOn(a, 'businessEmail');
  final showBusinessPhone = docFieldOn(a, 'businessPhone');
  final showDocNumber = docFieldOn(a, 'invoiceNumber');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LOGO SIZE WIRING FIX: no `size:` override -- buildSharedLogo()
          // falls back to a.businessLogoDisplaySize on its own, so this
          // now actually reflects the Logo Size slider on Customise.
          // TEMPLATE FIELD VISIBILITY PASS: buildSharedLogo() itself now
          // checks the businessLogo toggle internally.
          buildSharedLogo(a),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBusinessName) ...[
                  Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: kInk, fontFamily: a.fontFamily),
                      softWrap: true, overflow: TextOverflow.visible),
                  const SizedBox(height: 4),
                ],
                if (showBusinessAddress && a.businessAddress.isNotEmpty)
                  Text(a.businessAddress, style: TextStyle(fontSize: 9, color: kGrey,
                      height: 1.4, fontFamily: a.fontFamily), softWrap: true),
                if ((showBusinessEmail && a.businessEmail.isNotEmpty) ||
                    (showBusinessPhone && a.businessPhone.isNotEmpty))
                  Text(
                    [
                      if (showBusinessEmail) a.businessEmail,
                      if (showBusinessPhone) a.businessPhone,
                    ].where((s) => s.isNotEmpty).join('   ·   '),
                    style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily),
                  ),
              ],
            ),
          ),
          // DOC NUMBER WRAP/ALIGNMENT FIX: constrained width + right
          // textAlign on both lines so a wrapped/truncated number never
          // produces the orphaned "#" artifact.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.docTypeLabel,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: kInk, letterSpacing: 3.0, fontFamily: a.fontFamily),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (showDocNumber) ...[
                  const SizedBox(height: 6),
                  Text('#${a.docNumber.isEmpty ? '—' : a.docNumber}',
                      style: TextStyle(fontSize: 10.5, color: a.accent,
                          fontWeight: FontWeight.w600, fontFamily: a.fontFamily),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
      Container(height: 1, color: kRule),
      const SizedBox(height: 24),
      _ExecutiveMetaRow(a: a),
      const SizedBox(height: 28),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _executiveContinuationHeader(DocTemplateAdapter a) {
  final showDocNumber = docFieldOn(a, 'invoiceNumber');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
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
      ),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _ExecutiveMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _ExecutiveMetaRow({required this.a});

  @override
  Widget build(BuildContext context) {
    final showClientName = docFieldOn(a, 'customerName');
    final showClientAddress = docFieldOn(a, 'customerAddress');
    final showClientEmail = docFieldOn(a, 'customerEmail');
    final showClientPhone = docFieldOn(a, 'customerPhone');
    // Adapter's metaLabel1/metaValue1 and metaLabel2/metaValue2 carry
    // different semantics per doc type (invoice: issue/due date; quote:
    // issue date/valid-until; receipt: payment date/method) but the
    // toggle keys 'date'/'dueDate' only really apply to invoices — for
    // quote/receipt adapters enabledFields is unpopulated (see
    // doc_template_adapter.dart), so docFieldOn defaults true there and
    // this stays a no-op for those doc types.
    final showMeta1 = docFieldOn(a, 'date');
    final showMeta2 = docFieldOn(a, 'dueDate');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.recipientLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: a.accent, letterSpacing: 1.6, fontFamily: a.fontFamily)),
              const SizedBox(height: 8),
              if (showClientName)
                Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInk, fontFamily: a.fontFamily),
                    softWrap: true, overflow: TextOverflow.visible),
              if (showClientAddress && a.clientAddress.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(a.clientAddress, style: TextStyle(fontSize: 9.5, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
              ],
              if (showClientEmail && a.clientEmail.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(a.clientEmail, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
              ],
              if (showClientPhone && a.clientPhone.isNotEmpty) ...[
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
              if (showMeta1) ...[
                _metaRow(a.metaLabel1, a.metaValue1, a.fontFamily),
                const SizedBox(height: 6),
              ],
              if (showMeta2) ...[
                _metaRow(a.metaLabel2, a.metaValue2, a.fontFamily),
                const SizedBox(height: 10),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: a.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(a.statusLabel,
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
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
      Text(value.isEmpty ? '—' : value,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Preview wrappers — one per doc type, same shape every other template's
// file exposes. These are what preview_registry.dart files (invoice /
// quote / receipt) should import for id == 1 going forward.
// ─────────────────────────────────────────────────────────────────────────

class ExecutiveInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _executiveFullHeader,
        buildContinuationHeader: _executiveContinuationHeader,
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
        buildFullHeader: _executiveFullHeader,
        buildContinuationHeader: _executiveContinuationHeader,
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
        buildFullHeader: _executiveFullHeader,
        buildContinuationHeader: _executiveContinuationHeader,
        onPageCount: onPageCount,
      );
}
