// background_render.dart
// lib/document_layout_templates/document_backgrounds/background_render.dart
//
// DOCUMENT BACKGROUNDS FOUNDATION PASS: the one function every
// background render site (header, footer, mid-page body) now calls,
// instead of each having its own copy of this logic. Bugs that kept
// recurring are fixed HERE, once, instead of in three places that drift
// apart every time one gets patched:
//
// 1. FULL-BLEED WITHOUT THE UNBOUNDED-HEIGHT CRASH: an earlier header
//    fix used OverflowBox to bleed the background past its own bounds
//    to reach the true page edge — but OverflowBox inherits the
//    PARENT's constraint for any axis it doesn't explicitly override,
//    and the live Customise preview renders the whole page inside a
//    FittedBox (to scale it down to fit the phone screen), which by
//    design gives its child UNBOUNDED height. That crashed with
//    "RenderConstrainedOverflowBox object was given an infinite size".
//    Fixed by using Stack + Positioned instead: a Stack sizes itself
//    ONLY from its non-positioned child (`child` below, always a
//    normal finite size, regardless of any ambient unbounded
//    constraint upstream) — a Positioned child with all four insets
//    (or an explicit height) set always resolves to a TIGHT, finite
//    size derived from that resolved Stack size, never an unbounded
//    one. This is what actually makes bleeding safe under any ambient
//    constraint, not OverflowBox.
//
// 2. OPACITY DRIVES THE FADE, NOT THE IMAGE'S OWN VISIBILITY
//    (OPACITY-INVERSION FIX): earlier versions of this function (and
//    the doc_header.dart original this was extracted from) tied
//    `opacity` to the IMAGE's own alpha, with a separate scrim rendered
//    at a fixed strength regardless of that value. That meant opacity
//    0 showed nothing at all (image invisible, but the fixed scrim
//    still sat there too) and any opacity above 0 always showed the
//    same heavily-washed image, since the scrim itself never changed —
//    the exact opposite of what a "fade/wash" slider should do. Fixed:
//    the image now ALWAYS renders at full strength, and `opacity`
//    instead scales how much of `scrimOpacity` is applied (0 = none,
//    i.e. the raw undimmed photo; 1 = the full authored scrimOpacity).
//    BackgroundSpec.hasVisibleImage no longer requires opacity > 0 —
//    opacity 0 is a normal, visible state now (see BackgroundSpec's own
//    opacity doc comment).
//
// Height-capping (the `height` param) is what fixes "background
// overflows past its container" for header/footer: those bands used to
// derive their painted height from measuring the actual header/footer
// CONTENT, which meant the band grew every time the content did (e.g.
// an enlarged logo, a long tagline). A background band should have its
// own sensible fixed cap, independent of what the content currently
// measures.
//
// PER-PAGE BACKGROUND PASS (this update): adds
// renderFullPageBackgroundLayer, used by A4Paginator to paint ONE
// continuous image behind an ENTIRE page (header + meta row + items +
// footer all sit on top of this as the page's normal content flow)
// instead of the zone-by-zone (header/body/footer) approach
// renderDocumentBackground above is for. It reuses the exact same
// _imageScrimStack helper the zone-based path uses — same image
// rendering, same opacity/scrim math, same containment — just without
// a foreground baked in, since the caller composes its own content on
// top separately. See page_background_spec.dart for the per-page data
// model (PageBackgroundSpec / PageBackgroundScope / resolvePageBackground)
// that feeds this.

import 'dart:io';
import 'package:flutter/material.dart';
import 'background_spec.dart';

/// Renders `child` with `spec`'s background image + scrim behind it.
///
/// - Returns `child` completely untouched whenever
///   `spec.hasVisibleImage` is false (covers: no image set, or
///   disabled — opacity 0 is now a normal VISIBLE state, see the
///   OPACITY-INVERSION note above, not a bypass condition). This is the
///   single source of truth for "is a background actually showing" —
///   callers should not re-derive that condition themselves.
///
/// - `bleedLeft`/`bleedRight`/`bleedTop`/`bleedBottom`: how far past
///   `child`'s own natural bounds the background PAINTS (not lays
///   out — `child`'s reported size to its own parent is unaffected).
///   Pass `kPagePadH` for left/right to reach the true page edge from
///   content that sits inside the page's own horizontal padding
///   (header, footer, and body all do). Zero (the default) draws the
///   background exactly within `child`'s own bounds — the plain inline
///   case, no bleed.
///
/// - `height`: when provided, caps the background band to this FIXED
///   height instead of matching `child`'s measured height. Use this
///   for header/footer, where the band should have a sensible
///   independent cap rather than growing with whatever the content
///   currently measures (see fix #1 above). Leave null for body/
///   mid-page, where the background should cover the full page height
///   naturally — mid-page usually wants to track its own actual
///   content region without an artificial cap.
///
/// - `bleedTop` is combined with `height` when both are given: the
///   band starts `bleedTop` above `child`'s top edge and extends
///   `height` further down from there — this is what lets a header
///   background reach a FIXED point (e.g. flush with the rule divider
///   below it) regardless of how tall the header content itself is.
Widget renderDocumentBackground({
  required BackgroundSpec spec,
  required Widget child,
  double bleedLeft = 0,
  double bleedRight = 0,
  double bleedTop = 0,
  double bleedBottom = 0,
  double? height,
}) {
  if (!spec.hasVisibleImage) return child;

  final hasBleed =
      bleedLeft > 0 || bleedRight > 0 || bleedTop > 0 || bleedBottom > 0 || height != null;

  if (!hasBleed) {
    // Plain inline case — background confined to exactly child's own
    // bounds, content painted on top. No Stack/Positioned needed.
    return _imageScrimStack(spec: spec, foreground: child);
  }

  // FULL-BLEED CASE: see fix #1 above for why Stack+Positioned (not
  // OverflowBox) is what makes this safe under any ambient constraint.
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: -bleedLeft,
        right: -bleedRight,
        top: -bleedTop,
        bottom: height == null ? -bleedBottom : null,
        height: height,
        child: _imageScrimStack(spec: spec, foreground: const SizedBox.expand()),
      ),
      // Non-positioned — this is what determines the Stack's own size,
      // identical to `child`'s natural size on its own (the background
      // layer above is purely a paint-time overlay, invisible to
      // layout).
      child,
    ],
  );
}

/// PER-PAGE BACKGROUND PASS: renders JUST the image+scrim layer (no
/// foreground) filling whatever box it's given — used by A4Paginator
/// to paint one continuous background behind an ENTIRE page, with the
/// page's real header/meta/items/footer content composed on top of it
/// separately as normal page flow. Returns a zero-cost SizedBox.shrink()
/// when spec.hasVisibleImage is false, matching every other "no
/// background" bypass in this file — safe to call unconditionally.
Widget renderFullPageBackgroundLayer(BackgroundSpec spec) {
  if (!spec.hasVisibleImage) return const SizedBox.shrink();
  return _imageScrimStack(spec: spec, foreground: const SizedBox.expand());
}

/// The actual image + scrim + foreground stack, shared by both the
/// plain-inline and full-bleed branches above. ClipRect is the real
/// containment for the zoomed/panned image — it can never paint past
/// this box's own resolved bounds, no matter how far
/// Transform.scale/alignment would otherwise push it.
Widget _imageScrimStack({
  required BackgroundSpec spec,
  required Widget foreground,
}) {
  return ClipRect(
    child: Stack(
      children: [
        // OPACITY-INVERSION FIX: the image is no longer wrapped in
        // Opacity — it always paints at full strength. Panning/zooming
        // (Transform.scale/alignment) still applies exactly as before.
        Positioned.fill(
          child: Transform.scale(
            // Only BoxFit.cover has anything meaningful to zoom past
            // fitting the box — BoxFit.contain already shows the
            // whole image, so a scale multiplier would just add
            // empty padding around it for no benefit.
            scale: spec.fit == BoxFit.cover ? spec.clampedScale : 1.0,
            alignment: spec.alignment,
            child: Image.file(
              File(spec.imagePath!),
              fit: spec.fit,
              alignment: spec.alignment,
            ),
          ),
        ),
        // OPACITY-INVERSION FIX: `spec.clampedOpacity` now scales how
        // much of the base `scrimOpacity` is applied — 0 = none (raw
        // image, no wash), 1 = the full scrimOpacity value. This is
        // what makes the slider read correctly as a fade/wash control
        // instead of an image-visibility control.
        if (spec.scrimOpacity > 0 && spec.clampedOpacity > 0)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: spec.scrimOpacity * spec.clampedOpacity),
            ),
          ),
        foreground,
      ],
    ),
  );
}
