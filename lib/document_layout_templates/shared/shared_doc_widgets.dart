// shared_doc_widgets.dart
// lib/document_layout_templates/shared/shared_doc_widgets.dart
//
// The parts of a document that are visually identical across every
// template design (line-item row, totals/notes block, thank-you footer,
// and now the business logo) plus the generic A4Paginator wiring, written
// once here instead of once per template per doc type. A template design
// file only needs to supply buildFullHeader/buildContinuationHeader (the
// part that's actually supposed to look different) and hand everything
// else to TemplateDocument below.
//
// Geometry and palette values match executive_invoice_stationary_layout.dart
// exactly (confirmed identical across invoice/quote/receipt's Executive
// copies) so new templates sit at the same size/proportions as Executive.
//
// Totals/notes vs. thank-you footer split:
//   The Subtotal/Discount/Tax/Total block (and the Notes panel, if any)
//   is appended as the LAST ITEM in A4Paginator's items list, so it flows
//   immediately after the last line item — this matches standard invoicing
//   platform conventions (Stripe, QuickBooks, etc.) and reads as more
//   precise/professional than floating totals with a gap beneath them.
//   Only the thin "Thank you for your business" strip is passed as the
//   actual footerBuilder, which A4Paginator pins to the bottom of the last
//   page via an Expanded spacer — so that strip sits at a consistent page
//   position regardless of how many items are on the page, while totals
//   stay tightly attached to the table above them.
//
// TEMPLATE FIELD VISIBILITY PASS (this update): buildSharedLogo(),
// buildSharedTotalsAndNotesSection(), and buildSharedThankYouFooter() now
// gate on DocTemplateAdapter.enabledFields (via the new docFieldOn()
// helper in doc_template_adapter.dart) — businessLogo, tax, discount,
// notes, and thankYouMessage respectively. This is the piece that was
// missing from the whole adapter-based template path (used by
// executive_template.dart and every other *_template.dart design, and by
// the template chooser / PDF-preview screens): InvoiceData.enabledFields
// existed, and invoiceToAdapter() now carries it onto the adapter (see
// doc_template_adapter.dart), but nothing in this file read it yet, so a
// toggle switched off in the template sheet had no visible effect here.
// Missing keys default to true (`?? true` inside docFieldOn), so quote/
// receipt documents (whose adapters don't populate enabledFields yet) and
// any invoice saved before this field existed render exactly as before.
//
// LOGO FALLBACK MARK PASS (earlier): buildSharedLogo() now reads two
// new DocTemplateAdapter fields — businessLogoShowInitial and
// businessLogoInitialLetter (see the LOGO FALLBACK MARK PASS note in
// doc_template_adapter.dart / the InvoiceData/QuoteData/ReceiptData model
// files). When no real logo is set:
//   - businessLogoShowInitial == false -> the rotated-square mark ("the
//     blue diamond") is skipped entirely. The function still returns a
//     SizedBox at the same boxSize as before, just empty/transparent —
//     every template's header lays the logo out inside a Row alongside
//     the business name via a fixed-width slot + SizedBox gap, so
//     returning an empty box of the same size keeps that layout stable
//     across all 10 templates without needing to touch each one
//     individually to conditionally collapse the gap. (If a fully
//     collapsed no-logo header — no reserved space at all — is wanted for
//     a specific template later, that's a per-template header change,
//     not a change to this shared function.)
//   - businessLogoInitialLetter, when non-empty, is shown instead of the
//     auto-derived first letter of businessName. Only its first character
//     is used (uppercased) — the mark is a single-letter monogram, not a
//     multi-character label — so a user typing more than one character
//     still gets a clean mark rather than overflowing text.
// Both fields default to "on" / auto-letter (true / ''), so every
// existing document — nothing has these fields set differently yet —
// renders exactly as before this pass.
//
// SHARED LOGO PASS (earlier): added buildSharedLogo(), a template-
// agnostic business-logo widget driven entirely by DocTemplateAdapter's
// businessLogoPath/Offset/Scale/Shape/DisplaySize fields (see the LOGO
// FIELDS PASS in doc_template_adapter.dart). Mirrors executive_template.
// dart's _ExecutiveLogo/_ExecutiveLogoFallback pattern (SharedLogoThumbnail
// when a logo is set, a rotated-square initial-letter mark when it isn't)
// but actually respects the user's saved reposition/zoom/shape instead of
// ignoring them, and is written once here so every template design —
// Nordic, Vibrant, Tech Dark, Classic, Gradient Modern, Editorial, Pastel
// Soft, Brutalist, Emerald, and Executive itself — renders the logo
// identically rather than each maintaining its own copy that can drift.
// Templates with a colored/dark header panel (Vibrant, Tech Dark, etc.)
// should pass an explicit initialColor so the no-logo fallback square
// reads correctly against that background (e.g. white-on-accent instead
// of accent-on-white) — see each template file's own header for the value
// it passes.
//
// CURRENCY DISPLAY PASS (earlier): money formatting moved off this file's
// own fmtMoney() (a hardcoded currency->symbol lookup) and onto
// DocTemplateAdapter.fmtMoney(), which uses the document's own free-text
// currencySymbol + currencyDisplayMode instead of a fixed list — so any
// currency can be entered, not just ones on a hardcoded table. This
// file's line-item row and totals section now call adapter.fmtMoney(v)
// directly. The plain fmtMoney(currency, v) top-level function stays for
// any call sites that only have a currency code, not a full adapter, but
// its output is now only the code-form fallback, not a symbol lookup.
//
// OVERFLOW SAFETY PASS (earlier): buildSharedTotalsAndNotesSection's
// row() helper previously used plain Text widgets (no Flexible/Expanded)
// for both the label and the formatted amount in a spaceBetween Row —
// this rendered fine for short, known-length English labels ("Subtotal",
// "Tax (10%)") but had no protection against a translated label running
// longer (many languages run 30-50% longer than English for the same
// word — this app is adding translations, and none of the status/label
// strings sourced from doc_template_adapter.dart are localization-ready
// yet, which is a separate follow-up) or an unusually large formatted
// total. Both sides now wrap in Flexible with maxLines:1 + ellipsis, so
// either side shrinks/truncates instead of throwing a render overflow.
// This is the single highest-leverage fix for this class of bug in the
// whole template system, since every one of the 10 templates' totals
// sections routes through this one function via
// buildSharedTotalsAndNotesSection — one fix protects all of them at
// once, rather than needing a matching fix duplicated in each template.
//
// PER-TEMPLATE OVERRIDES PASS (earlier): matching the reference-image
// flat/colored table look meant Editorial's item rows, totals bar, and
// footer could no longer come from the one-look-for-everyone shared
// widgets above. TemplateDocument now exposes three optional hooks —
// buildLineItemRow / buildTotalsSection / buildFooterContent — that
// default to the exact previous shared behaviour when left null, so
// Editorial is the only template opting into a different look for those
// three pieces; the other 9 templates render identically to before this
// pass.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show LineItem;
import '../../widgets/shared_logo_picker.dart'
    show SharedLogoThumbnail, LogoShapeX, logoShapeFromString;
import 'doc_template_adapter.dart';
import '../../document_layout_templates/pagination/a4_paginator.dart';
import '../../document_layout_templates/pagination/doc_field.dart';

// ── Page geometry ────────────────────────────────────────────────────────
const double kPageW    = 595.0;
const double kPageH    = 842.0;
const double kPagePadH = 48.0;
const double kPagePadV = 48.0;
const double kContentW = kPageW - kPagePadH * 2;

// ── Palette ──────────────────────────────────────────────────────────────
const Color kInk       = Color(0xFF16181D);
const Color kGrey      = Color(0xFF6B7280);
const Color kGreyLight = Color(0xFF9CA3AF);
const Color kRule      = Color(0xFFE5E7EB);
const Color kPanelBg   = Color(0xFFF9FAFB);

/// Legacy plain-code formatter — used where only a currency code (not a
/// full DocTemplateAdapter with symbol/display-mode) is available. Prefer
/// adapter.fmtMoney(v) wherever an adapter is in scope, since that
/// respects the document's chosen currency symbol and display mode.
String fmtMoney(String currency, double v) =>
    '${currency.toUpperCase()} ${v.toStringAsFixed(2)}';

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

// ─────────────────────────────────────────────────────────────────────────
// Shared logo — used by every template's header. Renders the business
// logo respecting the user's saved reposition/zoom/shape (via
// SharedLogoThumbnail), or an initial-letter fallback mark when no logo
// has been set — unless the user has turned that fallback mark off (see
// LOGO FALLBACK MARK PASS above), in which case an empty box of the same
// size is returned instead. This is the single source of truth for "what
// does the logo look like" across all 10 template designs.
//
// TEMPLATE FIELD VISIBILITY PASS: also returns an empty box of the same
// size when the document's businessLogo toggle is off (docFieldOn(a,
// 'businessLogo') == false) — checked first, before either the real-logo
// or fallback-mark branches, so turning the toggle off hides a real
// uploaded logo too, not just the fallback mark.
//
// [size] overrides adapter.businessLogoDisplaySize when a template needs
// a different on-page size than what the user picked on the Customise
// step (rare — most templates should just pass null and use the user's
// own size).
//
// [fallbackMarkColor] is the solid color of the rotated-square mark shown
// when no logo is set. Defaults to the document's accent — right for
// light/white headers (Nordic, Classic, Editorial, etc). Templates with a
// colored or dark header panel behind the logo (Vibrant, Tech Dark) should
// pass Colors.white (or similar) so the fallback mark stays visible
// against that background, matching how those templates already handle
// text contrast in the rest of their header.
//
// [fallbackMarkTextColor] is the initial letter's color inside the mark —
// defaults to white, right for a solid accent-colored mark. Flip this
// (e.g. to the accent color) if fallbackMarkColor is set to something
// light, so the letter stays legible.
Widget buildSharedLogo(
  DocTemplateAdapter a, {
  double? size,
  Color? fallbackMarkColor,
  Color? fallbackMarkTextColor,
}) {
  final boxSize = size ?? a.businessLogoDisplaySize;

  // TEMPLATE FIELD VISIBILITY PASS: logo toggle off — empty box, same
  // size, so header layout (Row + fixed-width slot + SizedBox gap) never
  // has to change per-template to account for this.
  if (!docFieldOn(a, 'businessLogo')) {
    return SizedBox(width: boxSize, height: boxSize);
  }

  final path = a.businessLogoPath;

  if (path != null && path.isNotEmpty && File(path).existsSync()) {
    final shape = logoShapeFromString(a.businessLogoShape);
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: ClipRRect(
        borderRadius: shape.radiusFor(boxSize),
        child: SharedLogoThumbnail(
          logoPath: path,
          logoOffset: Offset(a.businessLogoOffsetDx, a.businessLogoOffsetDy),
          logoScale: a.businessLogoScale,
          logoShape: shape,
          boxSize: boxSize,
        ),
      ),
    );
  }

  // No real logo set. If the user has turned the fallback mark off,
  // return an empty box at the same size rather than the rotated-square
  // mark — see the LOGO FALLBACK MARK PASS note above for why this stays
  // a same-size empty box rather than collapsing to zero size.
  if (!a.businessLogoShowInitial) {
    return SizedBox(width: boxSize, height: boxSize);
  }

  final markColor = fallbackMarkColor ?? a.accent;
  final textColor = fallbackMarkTextColor ?? Colors.white;
  final customLetter = a.businessLogoInitialLetter.trim();
  final initial = customLetter.isNotEmpty
      ? customLetter[0].toUpperCase()
      : (a.businessName.trim().isNotEmpty ? a.businessName.trim()[0].toUpperCase() : 'B');

  return SizedBox(
    width: boxSize,
    height: boxSize,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: boxSize * 0.72,
            height: boxSize * 0.72,
            decoration: BoxDecoration(color: markColor, borderRadius: BorderRadius.circular(5)),
          ),
        ),
        Text(initial,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: boxSize * 0.34)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Column header row above line items — shared, since it only needs accent.
// ─────────────────────────────────────────────────────────────────────────
Widget buildSharedLineItemsHeaderRow({required Color accent, required String ff}) {
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: kGrey, letterSpacing: 1.0, fontFamily: ff);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: accent, width: 1.5))),
    child: Row(children: [
      Expanded(flex: 5, child: Text('DESCRIPTION', style: hdr)),
      Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
      Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: hdr)),
      Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// One line-item row — fed into A4Paginator's `items` list. Read-only only
// (no edit bundle) — this whole shared path is for preview/chooser
// rendering, not the WYSIWYG edit canvas.
//
// Now takes the full DocTemplateAdapter (rather than just a currency
// string) so it can call adapter.fmtMoney() and respect the document's
// chosen symbol/display mode.
// ─────────────────────────────────────────────────────────────────────────
Widget buildSharedLineItemRow({
  required LineItem item,
  required DocTemplateAdapter adapter,
  required String ff,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kRule, width: 0.75))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: Text(
          item.description.isEmpty ? 'Item description' : item.description,
          style: TextStyle(fontSize: 10, color: kInk, height: 1.4, fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible)),
      Expanded(flex: 1, child: Text(_fmtQty(item.quantity), textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 2, child: Text(adapter.fmtMoney(item.unitPrice), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
      Expanded(flex: 2, child: Text(adapter.fmtMoney(item.total), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Totals + notes block — appended as the LAST ITEM in A4Paginator's items
// list (not the footer), so it flows directly after the last line item
// with no gap, matching standard invoicing platform conventions.
//
// TEMPLATE FIELD VISIBILITY PASS: the discount row, tax row, and notes
// panel are each gated on their matching toggle (docFieldOn(a, 'discount'
// | 'tax' | 'notes')) in addition to their existing "only show if there's
// actually a value" condition — either check failing hides that piece.
// ─────────────────────────────────────────────────────────────────────────
Widget buildSharedTotalsAndNotesSection(DocTemplateAdapter a) {
  // OVERFLOW SAFETY PASS: label and value were previously plain Text
  // widgets in a spaceBetween Row with no Flexible/Expanded wrapper —
  // fine for short English labels ("Subtotal", "Tax (10%)") but not
  // guaranteed once translated labels are introduced (many languages run
  // 30-50% longer than English for the same word), and not guaranteed
  // for a very large formatted total either. Both sides now wrap in
  // Flexible with ellipsis, so a label or amount that's too long to fit
  // shrinks/truncates instead of throwing a render overflow. This is the
  // single highest-leverage fix in the app for this class of bug, since
  // every one of the 10 templates' totals sections routes through this
  // one function via buildSharedTotalsAndNotesSection.
  Widget row(String label, double v, {bool bold = false, bool negative = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
        child: Text(label,
            style: TextStyle(fontSize: bold ? 11 : 10,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold ? kInk : kGrey, fontFamily: a.fontFamily),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text('${negative ? '−' : ''}${a.fmtMoney(v)}',
            style: TextStyle(fontSize: bold ? 13 : 10.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? a.accent : kInk, fontFamily: a.fontFamily),
            textAlign: TextAlign.right,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ]),
  );

  final showDiscount = docFieldOn(a, 'discount');
  final showTax = docFieldOn(a, 'tax');
  final showNotes = docFieldOn(a, 'notes');

  return Padding(
    // Small top gap so the totals block doesn't touch the last item's
    // bottom rule — visually a touch of breathing room without floating
    // it away from the table the way a separate footer block would.
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: kContentW * 0.42,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              row('Subtotal', a.subtotal),
              if (showDiscount && a.discountRate > 0)
                row('Discount (${a.discountRate.toStringAsFixed(0)}%)', a.discountAmount, negative: true),
              if (showTax && a.taxRate > 0)
                row('Tax (${a.taxRate.toStringAsFixed(0)}%)', a.taxAmount),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, color: kRule)),
              row(a.totalLabel, a.total, bold: true),
            ]),
          ),
        ),
        if (showNotes && a.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 28),
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
// Thank-you footer — the default footer content when a template doesn't
// provide its own via TemplateDocument's buildFooterContent override.
// Deliberately thin, so it reads as a consistent page footer pinned to the
// bottom margin on the last page (via A4Paginator's Expanded spacer).
//
// TEMPLATE FIELD VISIBILITY PASS: hidden entirely (SizedBox.shrink())
// when docFieldOn(a, 'thankYouMessage') is false.
// ─────────────────────────────────────────────────────────────────────────
Widget buildSharedThankYouFooter(DocTemplateAdapter a) {
  if (!docFieldOn(a, 'thankYouMessage')) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(height: 0.75, color: kRule),
      const SizedBox(height: 10),
      Text(a.thankYouLabel,
          style: TextStyle(fontSize: 8.5, color: kGreyLight, fontFamily: a.fontFamily),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// TemplateDocument — generic A4Paginator wiring. Every new template design
// hands its buildFullHeader/buildContinuationHeader to this instead of
// re-wiring A4Paginator itself (matches how executive_invoice_logic_data.dart
// wires A4Paginator, just parameterised over the header builders).
//
// PER-TEMPLATE OVERRIDES PASS: three additional optional hooks —
// buildLineItemRow / buildTotalsSection / buildFooterContent — let a
// single template swap in its own look for those three pieces without
// touching the shared widgets every other template still uses. Each
// defaults to null, in which case build() below falls back to the
// original buildSharedLineItemRow / buildSharedTotalsAndNotesSection /
// buildSharedThankYouFooter — so every template that doesn't pass one of
// these renders exactly as it did before this pass.
// ─────────────────────────────────────────────────────────────────────────
typedef HeaderBuilder = Widget Function(DocTemplateAdapter adapter);

typedef LineItemRowBuilder = Widget Function({
  required LineItem item,
  required DocTemplateAdapter adapter,
  required String ff,
  required int index,
});
typedef TotalsSectionBuilder = Widget Function(DocTemplateAdapter adapter);
typedef FooterContentBuilder = Widget Function(DocTemplateAdapter adapter);

class TemplateDocument extends StatelessWidget {
  final DocTemplateAdapter adapter;
  final HeaderBuilder buildFullHeader;
  final HeaderBuilder buildContinuationHeader;
  final void Function(int pageCount)? onPageCount;

  // Optional per-template overrides — see the PER-TEMPLATE OVERRIDES PASS
  // note above. Leave all three null to get the original shared look.
  final LineItemRowBuilder? buildLineItemRow;
  final TotalsSectionBuilder? buildTotalsSection;
  final FooterContentBuilder? buildFooterContent;

  const TemplateDocument({
    super.key,
    required this.adapter,
    required this.buildFullHeader,
    required this.buildContinuationHeader,
    this.onPageCount,
    this.buildLineItemRow,
    this.buildTotalsSection,
    this.buildFooterContent,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final (index, item) in adapter.lineItems.indexed)
        buildLineItemRow != null
            ? buildLineItemRow!(item: item, adapter: adapter, ff: adapter.fontFamily, index: index)
            : buildSharedLineItemRow(item: item, adapter: adapter, ff: adapter.fontFamily),
      // Totals + notes appended as the final "item" — flows immediately
      // after the last line item, wherever that lands (same page or a
      // continuation page), exactly like any other item would.
      buildTotalsSection != null
          ? buildTotalsSection!(adapter)
          : buildSharedTotalsAndNotesSection(adapter),
    ];

    return A4Paginator(
      pageWidth: kPageW,
      pageHeight: kPageH,
      contentWidth: kContentW,
      pagePadding: const EdgeInsets.symmetric(horizontal: kPagePadH, vertical: kPagePadV),
      items: items,
      onPageCount: onPageCount,
      headerBuilder: (pageIndex, pageCount) =>
          pageIndex == 0 ? buildFullHeader(adapter) : buildContinuationHeader(adapter),
      // Only the final page gets the footer content — matches the
      // original behaviour (and A4Paginator's existing footer-reservation
      // logic, which only reserves space on the last page). Pinned to the
      // bottom of that page via A4Paginator's Expanded spacer.
      footerBuilder: (pageIndex, pageCount) => pageIndex == pageCount - 1
          ? (buildFooterContent != null ? buildFooterContent!(adapter) : buildSharedThankYouFooter(adapter))
          : const SizedBox.shrink(),
    );
  }
}
