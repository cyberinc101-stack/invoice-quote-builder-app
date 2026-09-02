// invoice_step_template_chooser_registry.dart
// lib/screens/invoice_create_section/invoice_step_template_chooser_registry.dart
//
// Scales the real invoice layout widget down to fit a grid card, using the
// same OverflowBox + Transform.scale technique as the CV app's
// StepChooserScaledPreview — except here it scales the actual
// ExecutiveInvoicePreview (via buildInvoicePreview) instead of a bespoke
// mini-illustration widget, since invoice layouts are already single-page
// and cheap to render at design size.
//
// PAGE-HEIGHT OVERFLOW FIX (this update): previously wrapped `content` in
// a SizedBox(width: kPageW, height: kPageH) — a TIGHT height constraint of
// exactly one A4 page, forced directly onto the A4Paginator tree inside
// it. A4Paginator's own outer Column (mainAxisSize: MainAxisSize.min)
// naturally sizes itself to (842 * real page count) + gaps; for every
// template up to now, the fixed 3-item sample invoice happened to fit on
// one page, so that tight 842px constraint never actually conflicted with
// what the Column needed and the bug stayed invisible. Emerald's header
// (a single-column stacked form listing every field vertically, instead
// of the two-column layout every other template uses) is tall enough
// that the same sample data now genuinely paginates to 2 pages — and the
// instant A4Paginator needs ~1708px (842*2 + 24 gap) but is forced into a
// tight 842px box, Flutter throws a RenderFlex overflow. The overflow
// amount seen in testing (866px) is exactly one extra page height (842)
// plus the paginator's own pageGap (24), confirming this as the root
// cause rather than a guess.
//
// This wasn't really an Emerald-specific bug — it was a latent assumption
// ("every template's sample-data preview always fits on exactly one A4
// page") baked into this thumbnail widget, which Emerald's legitimate
// design change happened to be the first to expose. Any future template,
// or even Emerald with a longer sample business name/address, could have
// triggered the same crash.
//
// Fixed by no longer forcing a tight height on `content` at all — it now
// gets a fixed WIDTH (kPageW) but an UNBOUNDED height via OverflowBox's
// maxHeight: double.infinity, so A4Paginator can size itself to whatever
// its real (possibly multi-page) height actually is without ever
// violating a layout constraint. The visual crop down to "one page's
// worth" — which is what a thumbnail should show anyway, since a grid
// card obviously can't show every page of a multi-page invoice — now
// happens from the OUTSIDE via a ClipRect + SizedBox(kPageW, kPageH)
// wrapping the OverflowBox, instead of being baked in as a tight
// constraint on the content itself. OverflowBox already supports a
// child larger than its own reported size (that's its whole purpose);
// the previous code was just using the wrong tool (a tight SizedBox on
// the child) to get the crop instead of relying on OverflowBox's actual
// mechanism for it.
//
// FILL-CONTAINER PASS (earlier): previously scaled to fit the card's
// WIDTH only (scale = maxWidth / kPageW), which meant whenever the card's
// height/width ratio didn't exactly match the A4 page's own ratio, the
// scaled page left visible blank space at the bottom of the card instead
// of filling it. Now scales by whichever of width/height needs the LARGER
// scale factor to fully cover the card (same idea as BoxFit.cover) —
// content fills the entire card with no gaps, at the cost of a small crop
// on whichever axis has room to spare. The card's own ClipRRect (in each
// screen's _TemplateCard) already clips anything outside its rounded
// bounds, so the crop is invisible/clean, not a visible overflow. This
// scale calculation is unaffected by the page-height fix above — it still
// governs how much the (now correctly unconstrained-height) content gets
// shrunk to cover the card.

import 'package:flutter/material.dart';
import '../../document_layout_templates/01_executive/executive_invoice_stationary_layout.dart'
    show kPageW, kPageH;
import 'invoice_template_previews/preview_registry.dart';

class InvoiceStepChooserScaledPreview extends StatelessWidget {
  final int templateId;
  const InvoiceStepChooserScaledPreview({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final content = buildInvoicePreview(templateId, sampleInvoiceData());

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
        // the available card area — matches BoxFit.cover, so the card has
        // no leftover blank space on either axis. The card's ClipRRect
        // handles cropping whatever spills past the rounded corners.
        // Unaffected by the page-height fix below — Transform.scale only
        // affects painting, not the layout constraints content is given.
        final scaleW = constraints.maxWidth / kPageW;
        final scaleH = constraints.maxHeight / kPageH;
        final scale = scaleW > scaleH ? scaleW : scaleH;

        // Outer ClipRect + SizedBox(kPageW, kPageH): this is now the ONLY
        // place a page-sized box is enforced, and it's a visual clip, not
        // a layout constraint — it trims whatever content paints outside
        // a one-page-tall region without telling content's own layout
        // that it MUST fit inside that height. This is what fixes the
        // overflow: content underneath is free to be as tall as it
        // genuinely needs (1, 2, or more real A4Paginator pages) without
        // ever hitting a tight constraint it can't satisfy.
        return ClipRect(
          child: SizedBox(
            width: kPageW,
            height: kPageH,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxWidth: kPageW,
              minWidth: kPageW,
              // The actual fix: height is unbounded (0..infinity) for the
              // child, instead of being pinned to exactly kPageH the way
              // the old code's inner SizedBox did. A4Paginator can now
              // report its true multi-page height with zero risk of a
              // RenderFlex overflow assertion, regardless of how tall any
              // given template's header makes the sample invoice.
              minHeight: 0,
              maxHeight: double.infinity,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  // Width-only SizedBox now — no height constraint passed
                  // to content at all; it's free to size itself to
                  // whatever its real content demands.
                  child: SizedBox(width: kPageW, child: content),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}