// customise_logo_section.dart
// lib/screens/invoice_create_section/step_customize/customise_logo_section.dart
//
// PERCENTAGE-DISPLAY REMAP PASS (this update): the "Logo Size in
// Header" readout used to show headerLogoFreeformScale directly as a
// percentage (e.g. 900% at the max of 9.0) — technically correct but a
// strange number for anyone not thinking in raw multipliers. The
// slider's actual min/max (kHeaderLogoFreeformMinScale..
// kHeaderLogoFreeformMaxScale) and the real on-canvas maximum logo
// size are UNCHANGED by this pass — only the number shown under the
// slider is remapped so the min reads 0% and the max reads 100%,
// linearly across the same range the slider already covers. See
// doc_header.dart's own WIDE-WIDTH-CAP + PAN-HEADROOM FIX for the
// separate (functional) fix to the "doesn't move left-right at max
// size" bug — that fix is unrelated to this cosmetic one and lives
// entirely in doc_header.dart.
//
// SHAPE-GATES-FREEFORM RULE PASS (earlier): freeform header-logo
// positioning (drag/pinch across the whole header) is now tied
// EXCLUSIVELY to the Wide shape — Circle/Square/Rounded can never
// enter freeform mode at all, regardless of what Business Name/Tagline
// are set to. Concretely:
//   - freeformEligible now also requires `currentShape ==
//     LogoShape.wide`, on top of the existing "Business Name + Tagline
//     both hidden" check.
//   - Selecting Circle/Square/Rounded now forces Business Name back ON
//     (mirrors the existing WIDE AUTO-HIDE PASS, which forces it OFF
//     when Wide is selected) — so a person can never end up with a
//     non-Wide shape and Business Name hidden at the same time.
//   - A defensive re-sync runs on every build: if the shape is
//     non-Wide but Business Name is somehow off anyway (e.g. toggled
//     from the Fields section on Customise, a different screen from
//     this one), it's corrected back to visible on the next frame.
//     This is what actually guarantees the rule holds regardless of
//     which screen last touched enabledFields — this card can't see or
//     block that other screen's toggle directly, so it corrects after
//     the fact instead.
// This sidesteps the "Logo Size in Header only stretches width" report
// entirely for Circle/Square/Rounded, since those shapes can no longer
// reach the freeform code path where that control lives at all — only
// Wide can, and Wide is being addressed separately.
//
// FILE-SPLIT PASS: pulled out of the former monolithic step_customise.dart
// (was `_LogoSection`, now public `LogoSection`).
//
// SINGLE-SIZER FIX (earlier): previously this card showed BOTH the
// "Logo Size" slider (businessLogoDisplaySize, 24-96px — meant for the
// small inline logo box used when Business Name/Tagline are visible) AND,
// once freeform-eligible, the separate "Logo Size in Header" slider
// (headerLogoFreeformScale). Since the freeform logo's rendered size in
// doc_header.dart used to be businessLogoDisplaySize * headerLogoFreeformScale,
// having both sliders visible let them fight over the same on-screen
// size. Now: once freeform is eligible, the "Logo Size" slider is hidden
// entirely — "Logo Size in Header" (plus pinch, on the live preview) is
// the ONLY sizer. doc_header.dart's freeform logo size is also now based
// on a fixed independent constant (kHeaderLogoFreeformBaseSize) rather
// than businessLogoDisplaySize, so hiding this slider doesn't leave the
// freeform logo with no base size to scale from.
//
// The freeform "Logo Size in Header" slider's range is widened to match
// doc_header.dart's raised ceiling (kHeaderLogoFreeformMaxScale = 5.0, was
// 3.0) — the logo can now grow substantially larger without ever changing
// the header row's own height (see doc_header.dart's header comment for
// why: the floating logo is a Positioned.fill layer, out of the row's own
// flow).
//
// The instruction copy in the "Position in Header" hint now explicitly
// states both that dragging works directly from the header in the live
// preview above, and that enlarging never changes the header's height.
//
// WIDE AUTO-HIDE PASS (earlier): selecting the "Wide" logo shape now
// automatically turns off Business Name and Business Tagline (Invoice
// Fields → Header & Meta) instead of requiring the user to do it by
// hand. A Wide logo is meant to stand in for that text in the header,
// and turning both off is exactly the condition (see freeformEligible
// below) that unlocks freeform drag/resize positioning across the whole
// header — so choosing Wide now gets you there in one tap. See the
// shape-button onTap below.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/invoice_provider.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../../../document_layout_templates/document_template_layout_data/doc_header.dart'
    show kHeaderLogoFreeformMinScale, kHeaderLogoFreeformMaxScale;
import 'customise_shared_widgets.dart';

// =============================================================================
// Business logo section
//
// COLLAPSIBLE SECTIONS + MERGE PASS (earlier): this card is collapsible
// (chevron in the header — tap to expand/collapse, state persisted
// independently of every other collapsible card on this screen; see
// SectionCard). The Logo Size slider lives inside this same card, after
// the shape picker, separated by a thin divider — but see SINGLE-SIZER
// FIX above: it's now hidden once freeform is eligible.
//
// WIDE FILL-CONTAINER PASS (earlier): the shape picker box is now
// wrapped in a LayoutBuilder. When the "Wide" shape is selected, the
// available width from that LayoutBuilder is passed to SharedLogoPicker
// as wideWidthOverride, so the box actually stretches to fill the
// card's width instead of being capped at previewSize*2.6 (which could
// be far narrower than the card, especially at smaller Logo Size
// values). Every other shape is unaffected — wideWidthOverride is
// simply null for them, same as before this pass.
//
// PAN + PINCH HEADER LOGO PASS (earlier): the instruction copy below
// mentions pinching as well as dragging, since both gestures work
// directly on the live preview now. The slider still exists alongside
// pinch — it's more precise for fine adjustments and works for anyone on
// a desktop/trackpad preview where pinch isn't available.
//
// DRAG-ON-HEADER PASS (earlier): the old "Position in Header" row with
// its "Adjust" button — which opened a separate popup dialog for
// drag/resize — is gone. Once eligible (Business Name + Tagline both
// hidden AND shape is Wide — see SHAPE-GATES-FREEFORM RULE PASS above),
// this card now shows:
//   1. A short instruction to drag/pinch the logo directly on the live
//      preview above (that's where the actual GestureDetector lives now
//      — see customise_preview.dart / doc_header.dart's
//      _DraggableHeaderLogo), and that enlarging it never changes the
//      header's own height.
//   2. A "Logo Size in Header" slider, controlling
//      headerLogoFreeformScale directly (also settable via pinch) — the
//      ONLY size control once freeform is active.
//   3. A "Reset to centre" button that zeroes the offset and scale
//      back to defaults.
// =============================================================================

class LogoSection extends StatelessWidget {
  const LogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final data     = provider.invoiceData;
    final colorScheme = Theme.of(context).colorScheme;
    final accent   = colorForScheme(data.colorScheme);
    final hasLogo  = data.businessLogoPath != null && data.businessLogoPath!.isNotEmpty;
    final currentShape = logoShapeFromString(data.businessLogoShape);
    final previewSize = (90.0 + (data.businessLogoDisplaySize - 40.0) * 3.0).clamp(90.0, 260.0);

    // SHAPE-GATES-FREEFORM RULE PASS: same eligibility check
    // doc_header.dart's buildSharedHeaderIdentity uses at render time
    // (kept in sync deliberately), now ALSO requiring the Wide shape —
    // Circle/Square/Rounded can never reach freeform, no matter what
    // Business Name/Tagline are set to.
    final showBusinessNameField = data.enabledFields['businessName'] ?? true;
    final effectiveTagline = data.businessTaglineEnabled ? data.businessTagline.trim() : '';
    final isWideShape = currentShape == LogoShape.wide;
    final freeformEligible =
        hasLogo && isWideShape && !showBusinessNameField && effectiveTagline.isEmpty;

    // SHAPE-GATES-FREEFORM RULE PASS: defensive re-sync — if the shape
    // is non-Wide but Business Name is somehow off anyway (e.g. it was
    // toggled from the Fields section on Customise, a different screen
    // from this card), force it back on. This runs every build, so it
    // self-heals regardless of which screen last touched enabledFields
    // — this card can't block that other screen's toggle directly, so
    // it corrects the state after the fact instead. Deferred to the
    // next frame since a Provider write during build() is unsafe.
    if (!isWideShape && !showBusinessNameField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latest = provider.invoiceData;
        if (logoShapeFromString(latest.businessLogoShape) == LogoShape.wide) return;
        if (latest.enabledFields['businessName'] ?? true) return;
        final updatedFields = Map<String, bool>.from(latest.enabledFields);
        updatedFields['businessName'] = true;
        provider.updateEnabledFields(updatedFields);
      });
    }

    return SectionCard(
      icon: Icons.image_rounded,
      title: 'Business Logo',
      sectionKey: 'business_logo',
      child: Column(
        children: [
          // WIDE FILL-CONTAINER PASS: LayoutBuilder gives us the card's
          // real available width so a Wide-shaped logo can stretch to
          // fill it instead of sitting undersized in the middle of the
          // card.
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = currentShape == LogoShape.wide;
              return Center(
                child: Opacity(
                  opacity: hasLogo ? 1.0 : 0.5,
                  child: SharedLogoPicker(
                    logoPath: data.businessLogoPath,
                    logoOffset: Offset(data.businessLogoOffsetDx, data.businessLogoOffsetDy),
                    logoScale: data.businessLogoScale,
                    logoShape: currentShape,
                    accent: accent,
                    compact: true,
                    compactBoxSize: previewSize,
                    wideWidthOverride: isWide ? constraints.maxWidth : null,
                    onChanged: (path, offset, scale, shape) {
                      provider.updateBusinessLogo(
                        path: path,
                        offset: offset,
                        scale: scale,
                        shape: shape.storageName,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            hasLogo ? 'Tap logo to change, reposition, or remove' : 'Tap to upload a logo',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 14),
          Opacity(
            opacity: hasLogo ? 1.0 : 0.4,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: LogoShape.values.map((s) {
                final selected = s == currentShape;
                return GestureDetector(
                  onTap: hasLogo
                      ? () {
                          provider.updateBusinessLogo(
                            path: data.businessLogoPath,
                            offset: Offset(data.businessLogoOffsetDx, data.businessLogoOffsetDy),
                            scale: data.businessLogoScale,
                            shape: s.storageName,
                          );
                          if (s == LogoShape.wide) {
                            // WIDE AUTO-HIDE PASS: a Wide logo stands in
                            // for the Business Name/Tagline text in the
                            // header, so selecting it turns both off
                            // automatically — which also happens to be
                            // exactly the condition that unlocks freeform
                            // drag/resize positioning (freeformEligible
                            // above), so Wide now gets the user there in
                            // one tap instead of two manual toggles.
                            final updatedFields =
                                Map<String, bool>.from(data.enabledFields);
                            updatedFields['businessName'] = false;
                            provider.updateEnabledFields(updatedFields);
                            provider.updateBusinessTaglineEnabled(false);
                          } else {
                            // SHAPE-GATES-FREEFORM RULE PASS: the
                            // mirror image of the Wide branch above —
                            // picking Circle/Square/Rounded forces
                            // Business Name back ON, since those three
                            // shapes may never enter freeform mode
                            // regardless of what Business Name/Tagline
                            // are set to. Tagline is deliberately left
                            // alone — the rule only concerns Business
                            // Name (that's what freeformEligible keys
                            // off of together with the shape check; a
                            // hidden tagline alone, with Business Name
                            // visible, was never freeform-eligible
                            // anyway).
                            if (!(data.enabledFields['businessName'] ?? true)) {
                              final updatedFields =
                                  Map<String, bool>.from(data.enabledFields);
                              updatedFields['businessName'] = true;
                              provider.updateEnabledFields(updatedFields);
                            }
                          }
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? accent : colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 16, color: selected ? accent : colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 5),
                        Text(s.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? accent : colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // SINGLE-SIZER FIX: the old standalone "Logo Size" slider
          // (businessLogoDisplaySize, for the small inline logo box) is
          // now shown ONLY when freeform is NOT eligible — i.e. only
          // when the logo is actually rendering in that small inline
          // box. Once freeform kicks in (Wide shape only — see
          // SHAPE-GATES-FREEFORM RULE PASS), "Logo Size in Header"
          // below is the sole size control, so the two can never fight
          // each other over the same on-screen size again.
          if (!freeformEligible) ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
            const SizedBox(height: 14),
            Opacity(
              opacity: hasLogo ? 1.0 : 0.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.photo_size_select_large_rounded, size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.55)),
                      const SizedBox(width: 6),
                      Text('Logo Size',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.image_outlined, size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor:   accent,
                            inactiveTrackColor: accent.withValues(alpha: 0.2),
                            thumbColor:         accent,
                            overlayColor:       accent.withValues(alpha: 0.15),
                            trackHeight:        4,
                          ),
                          child: Slider(
                            value: data.businessLogoDisplaySize,
                            min: 24,
                            max: 96,
                            divisions: 12,
                            onChanged: hasLogo ? (v) => provider.updateBusinessLogoSize(v) : null,
                          ),
                        ),
                      ),
                      Icon(Icons.image_outlined, size: 24,
                          color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    ],
                  ),
                  Center(
                    child: Text(
                      hasLogo ? '${data.businessLogoDisplaySize.toInt()}px' : 'Add a logo to enable',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: hasLogo ? accent : colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // DRAG-ON-HEADER / PAN + PINCH PASS: "Position in Header" —
          // only rendered at all once a logo exists (nothing to position
          // otherwise). Shows the drag+pinch hint + resize slider when
          // eligible, or a short explanatory hint when not.
          if (hasLogo) ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.open_with_rounded, size: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.55)),
                const SizedBox(width: 6),
                Text('Position in Header',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 10),
            if (!freeformEligible)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 8),
                    Expanded(
                      // SHAPE-GATES-FREEFORM RULE PASS: copy updated —
                      // freeform positioning now requires the Wide
                      // shape specifically, not just hiding the text.
                      child: Text(
                        isWideShape
                            ? 'Hide Business Name and Business Tagline (in Invoice Fields → Header & Meta) to freely drag and resize the logo across the header.'
                            : 'Select the Wide shape, then hide Business Name and Business Tagline (in Invoice Fields → Header & Meta), to freely drag and resize the logo across the header.',
                        style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      // SINGLE-SIZER FIX: copy now explicitly states
                      // that this is dragged FROM the header itself in
                      // the live preview above (not from this slider),
                      // and that enlarging it never changes the
                      // header's own height.
                      child: Text(
                        'Drag the logo directly from the header in the live preview above to move it — you can drag it all the way to either edge. Pinch with two fingers, or use the slider below, to resize it. Enlarging the logo never changes the header\'s height.',
                        style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.photo_size_select_large_outlined, size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.55)),
                  const SizedBox(width: 6),
                  Text('Logo Size in Header',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.zoom_out_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor:   accent,
                        inactiveTrackColor: accent.withValues(alpha: 0.2),
                        thumbColor:         accent,
                        overlayColor:       accent.withValues(alpha: 0.15),
                        trackHeight:        3,
                      ),
                      child: Slider(
                        // SINGLE-SIZER FIX: range still matches
                        // doc_header.dart's ceiling so the slider and
                        // pinch gesture always agree — the underlying
                        // stored value and its real min/max are
                        // UNCHANGED by the percentage-display remap
                        // below.
                        value: data.headerLogoFreeformScale.clamp(
                            kHeaderLogoFreeformMinScale, kHeaderLogoFreeformMaxScale),
                        min: kHeaderLogoFreeformMinScale,
                        max: kHeaderLogoFreeformMaxScale,
                        onChanged: (v) => provider.updateHeaderLogoFreeform(
                          offsetDx: data.headerLogoFreeformOffsetDx,
                          offsetDy: data.headerLogoFreeformOffsetDy,
                          scale: v,
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.zoom_in_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
              Center(
                child: Text(
                  // PERCENTAGE-DISPLAY REMAP PASS: linearly remaps the
                  // real stored scale (kHeaderLogoFreeformMinScale..Max)
                  // onto a 0-100% readout instead of showing the raw
                  // multiplier as a percentage (which topped out at
                  // 900%). The slider's own position, range, and the
                  // actual on-canvas logo size are all untouched — only
                  // this number's presentation changed.
                  '${(((data.headerLogoFreeformScale.clamp(kHeaderLogoFreeformMinScale, kHeaderLogoFreeformMaxScale) - kHeaderLogoFreeformMinScale) / (kHeaderLogoFreeformMaxScale - kHeaderLogoFreeformMinScale)) * 100).round()}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => provider.updateHeaderLogoFreeform(
                    offsetDx: 0.0,
                    offsetDy: 0.0,
                    scale: 1.0,
                  ),
                  icon: Icon(Icons.center_focus_strong_rounded, size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.45)),
                  label: Text('Reset to centre',
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.45))),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}