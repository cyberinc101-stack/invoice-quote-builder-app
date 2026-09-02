// quote_step_template_chooser_registry.dart
// lib/screens/create_quote_section/quote_step_template_chooser_registry.dart
//
// Scales the real quote layout widget down to fit a grid card — same
// OverflowBox + Transform.scale technique as
// invoice_create_section/invoice_step_template_chooser_registry.dart.
//
// Since no quote layout is built yet, buildQuotePreview() always returns
// null right now, so every card falls through to the "Coming Soon"
// placeholder icon below. Once a real quote layout exists, this file
// doesn't need any changes — it already renders whatever
// buildQuotePreview() returns.
//
// PARITY PASS (this update): brought this in line with the two fixes
// already applied to InvoiceStepChooserScaledPreview, ahead of a real
// quote layout landing — rather than shipping the exact bug that layout
// would immediately hit:
//
// 1. PAGE-HEIGHT OVERFLOW FIX — previously forced a tight
//    SizedBox(width: kQuotePageW, height: kQuotePageH) onto `content`
//    inside an OverflowBox capped at maxHeight: kQuotePageH. That's the
//    same shape as the invoice file's pre-fix bug: any future quote
//    layout whose sample data paginates to more than one page (a tall
//    single-column header design, same as Emerald's invoice case) would
//    hit a RenderFlex overflow the instant it was wired up here. `content`
//    now gets a fixed WIDTH only; height is unbounded via
//    maxHeight: double.infinity, and the one-page-tall thumbnail crop
//    happens from the OUTSIDE via ClipRect + SizedBox(kQuotePageW,
//    kQuotePageH), same as the invoice version.
//
// 2. FILL-CONTAINER (cover-fit) FIX — previously scaled by width only
//    (scale = maxWidth / kQuotePageW), which leaves blank space at the
//    bottom of the card whenever the card's aspect ratio doesn't exactly
//    match the quote page's own ratio. Now scales by whichever of
//    width/height needs the LARGER factor to fully cover the card (same
//    as BoxFit.cover), matching the invoice version. The card's own
//    ClipRRect (in quote_template_chooser_screen.dart's _TemplateCard)
//    clips anything outside its rounded bounds, so the crop is clean.

import 'package:flutter/material.dart';
import 'quote_template_chooser_01/preview_registry.dart';

class QuoteStepChooserScaledPreview extends StatelessWidget {
  final int templateId;
  const QuoteStepChooserScaledPreview({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final content = buildQuotePreview(templateId, sampleQuoteData());

    if (content == null) {
      // Stub template — no layout built yet.
      return Container(
        color: const Color(0xFFF3F4F6),
        alignment: Alignment.center,
        child: const Icon(Icons.hourglass_empty_rounded,
            color: Color(0xFFB0B7C3), size: 28),
      );
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        // Scale by whichever axis needs the larger factor to fully cover
        // the available card area — matches BoxFit.cover, mirroring
        // InvoiceStepChooserScaledPreview. Unaffected by the page-height
        // fix below — Transform.scale only affects painting, not the
        // layout constraints content is given.
        final scaleW = constraints.maxWidth / kQuotePageW;
        final scaleH = constraints.maxHeight / kQuotePageH;
        final scale = scaleW > scaleH ? scaleW : scaleH;

        // Outer ClipRect + SizedBox(kQuotePageW, kQuotePageH): the ONLY
        // place a page-sized box is enforced, and it's a visual clip, not
        // a layout constraint — it trims whatever content paints outside
        // a one-page-tall region without telling content's own layout
        // that it MUST fit inside that height.
        return ClipRect(
          child: SizedBox(
            width: kQuotePageW,
            height: kQuotePageH,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxWidth: kQuotePageW,
              minWidth: kQuotePageW,
              // Height unbounded for the child, instead of pinned to
              // exactly kQuotePageH — a future multi-page quote layout
              // can report its true height with zero risk of a
              // RenderFlex overflow assertion.
              minHeight: 0,
              maxHeight: double.infinity,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  // Width-only SizedBox — no height constraint passed to
                  // content at all; it's free to size itself to whatever
                  // its real content demands.
                  child: SizedBox(width: kQuotePageW, child: content),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}