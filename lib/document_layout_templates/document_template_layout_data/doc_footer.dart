// doc_footer.dart
// lib/document_layout_templates/document_template_layout_data/doc_footer.dart
//
// TAGLINE ICON SIZE PASS (this update): the footer tagline icon was a
// fixed size: 10 regardless of the Customise-step size slider — only
// the text next to it actually grew/shrank with
// footerTaglinesFontSize. The icon now scales with it too, at the same
// ratio the old fixed values implied (8pt default text : 10pt icon =
// 1.25x), so a 6pt or 12pt tagline gets a proportionally smaller/larger
// icon instead of a static one. Clamped to the same 6.0-12.0 range the
// text uses before the ratio is applied, so this can't runaway past
// what the footer band was already sized to handle.
//
// NO-TRUNCATION / MAX-14PT PASS (earlier): each footer tagline's
// text used `maxLines: 1, overflow: TextOverflow.ellipsis` — a longer
// tagline (up to 6 of these can share the row) could get cut with "…".
// Now uses the shared autoFitText() helper from doc_header.dart, which
// shrinks that one tagline's text down to fit its slice of the row
// instead of hiding part of it, and never exceeds kMaxAutoFitFontSize
// (14pt). A slightly lower floor (minScale 0.45) is used here since up
// to 6 items share the row width evenly — a long tagline in a 6-item
// row has very little room and needs more shrink headroom than a
// single-column label elsewhere on the page.
//
// DIVIDER-MOVE PASS (earlier): the divider that used to sit above the
// thank-you line (in doc_totals.dart's buildSharedThankYouFooter) has
// moved down to sit here instead — directly above the footer taglines
// row. Visual order in _defaultFooterContent (template_document.dart)
// is now: thank-you text, divider, taglines row. buildSharedThankYouFooter
// no longer draws a divider at all; this function now owns the one
// divider for the whole footer block.
//
// FOOTER REORDER PASS (earlier): this row renders AFTER
// buildSharedThankYouFooter (see template_document.dart's
// _defaultFooterContent).
//
// FOOTER TAGLINES PASS (original): renders the footer taglines row — up
// to 6, minimum 3, icon+text items laid out horizontally and evenly
// spaced across the content width regardless of whether there are 3, 4,
// 5, or 6 of them (a Row with MainAxisAlignment.spaceEvenly does this
// automatically — no per-count layout branching needed).
//
// Gated on TWO things, same pattern as every other optional block on
// this document: footerTaglinesEnabled (the Customise-step switch) AND
// having at least kFooterTaglinesMin items — a template sheet enforces
// 3–6 at authoring time, but this render side stays defensive rather
// than trusting that invariant blindly (e.g. an old persisted document
// saved with fewer, or a future bug elsewhere). Note this means the
// divider only appears when the taglines row itself is actually
// showing — a document with the thank-you message but taglines turned
// off (or below the 3-item minimum) gets no divider at all, which is
// correct: there'd be nothing below it to divide from.

import 'package:flutter/material.dart';
import '../../models/footer_tagline.dart';
import 'doc_template_adapter.dart';
import 'doc_header.dart' show kGrey, kRule, autoFitText;

Widget buildSharedFooterTaglines(DocTemplateAdapter a) {
  if (!a.footerTaglinesEnabled) return const SizedBox.shrink();

  final items = a.footerTaglines
      .where((t) => t.text.trim().isNotEmpty)
      .toList();
  if (items.length < kFooterTaglinesMin) return const SizedBox.shrink();

  final shown = items.length > kFooterTaglinesMax
      ? items.sublist(0, kFooterTaglinesMax)
      : items;

  final ff = a.fontFamily;

  // TAGLINE ICON SIZE PASS: same clamp the text applies, then scaled by
  // the 1.25x ratio the old fixed 8pt-text/10pt-icon pairing implied —
  // so the icon now tracks the slider exactly like the text does.
  final taglineFontSize = a.footerTaglinesFontSize.clamp(6.0, 12.0);
  final taglineIconSize = taglineFontSize * 1.25;

  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 0.75, color: kRule),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final item in shown)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon.icon, size: taglineIconSize, color: a.accent),
                      const SizedBox(width: 4),
                      // NO-TRUNCATION PASS: was maxLines:1 + ellipsis.
                      Flexible(
                        child: autoFitText(
                          item.text.trim(),
                          // TAGLINE SIZE PASS: was a fixed 8 — now
                          // reads adapter.footerTaglinesFontSize (the
                          // Customise-step slider), clamped to a range
                          // that combined with autoFitText's own
                          // shrink-to-fit (minScale 0.45 below) cannot
                          // overflow the footer band even at max size
                          // with 6 items sharing the row.
                          TextStyle(
                            fontSize: taglineFontSize,
                            color: kGrey,
                            fontFamily: ff,
                          ),
                          minScale: 0.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}