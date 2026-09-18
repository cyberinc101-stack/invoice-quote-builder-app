// doc_header.dart
// lib/document_layout_templates/document_template_layout_data/doc_header.dart
//
// VERTICAL-CONTAINMENT PASS (this update): the freeform Wide logo was
// only ever capped against the header's available WIDTH (via
// kWideLogoMinTravelRange / wideMaxWidth below) — nothing capped it
// against the header's actual rendered HEIGHT. At larger "Logo Size in
// Header" values the logo's height could exceed the header row's real
// height, and since the vertical clamp (_symmetricOffset) has nowhere
// to move a child that's already taller than its container (maxOffset
// clamps to 0), the logo rendered flush against the top and simply
// overflowed downward past the header into the FROM/BILLED-TO block
// underneath — and vertical dragging did nothing, which is exactly
// what "staticky" drag looks like. Fixed by capping the logo's
// rendered height (and, via the fixed aspect ratio, its width) to the
// header's real runtime height — see kWideLogoMinVerticalTravelRange
// and _cappedFreeformLogoSize below, used by both the static render
// and the interactive drag branch so the logo can never again render
// outside the header box, and so vertical drag always has real travel
// room to work with.
//
// RESERVED-ZONE + TRAVEL-RANGE DRAG FIX (earlier): replaces the old
// kWideLogoPanHeadroomFraction approach. That approach only ever capped
// the logo's width against the FULL content width (kContentW) — it had
// no idea the doc-type/number/status column on the right exists at all,
// so a large-enough Wide logo could be dragged right until it visually
// sat on top of the invoice/quote/receipt number. It also fed that same
// width cap into the drag-delta math (see
// _DraggableHeaderLogoState.onScaleUpdate), which normalised drag
// distance against the header's FULL width rather than the logo's
// actual remaining travel room — for anything but small logos this
// meant a full physical drag across the header could never reach the
// true -1.0/+1.0 clamp, which is exactly what "only drags slightly,
// never reaches the edge, gets stuck at a certain size" looks like.
//
// Fixed with two constants instead of one fraction — see
// kHeaderRightReservedWidth / kWideLogoMinTravelRange / kWideLogoAspectRatio
// and the _wideLogoLeftOffset / _symmetricOffset helpers just above
// buildSharedHeaderIdentity for the actual math. The same travel-range
// formula now drives BOTH the rendered position (static and live-drag)
// AND the drag-delta sensitivity, so they can never disagree with each
// other again.
//
// WIDE-WIDTH-CAP + PAN-HEADROOM FIX (earlier, now superseded by the
// pass above): the previous cap let a Wide logo's rendered box grow to
// EXACTLY kContentW wide at high "Logo Size in Header" values.
// Flutter's Alignment math computes a child's position as
// (parentSize - childSize) * (alignment + 1) / 2 — when childSize
// equals parentSize exactly, that expression is zero for EVERY
// alignment value, so the drag clamp (-1.0..1.0) had nowhere left to
// actually move the logo to. Fixed (at the time) by capping Wide's
// effective width at 88% of kContentW instead of 100% — this left a
// margin, but still didn't know about the doc-number column, and still
// fed the drag-delta normalisation from the full container width — see
// the pass above for the actual fix to both of those gaps.
//
// SIZE-INDEPENDENT FREEFORM LOGO PASS (earlier): the floating header
// logo's rendered size used to be businessLogoDisplaySize * headerLogoFreeformScale
// — which meant the small "Logo Size" slider (24-96px, meant for the
// normal inline logo box) silently capped how big the freeform/draggable
// logo could ever get, and having BOTH that slider and the "Logo Size in
// Header" slider visible at once let them fight over the same value. The
// freeform logo now scales off its own fixed, generous base
// (kHeaderLogoFreeformBaseSize) instead of businessLogoDisplaySize, so it
// can grow much larger under pinch/slider without being limited by that
// other control. kHeaderLogoFreeformMaxScale raised 3.0 -> 5.0 to match.
// This never changes the header ROW's own height, because the floating
// logo already renders inside Positioned.fill within a Stack whose size
// is driven only by its non-positioned child (`row`) — enlarging the logo
// only lets it visually overflow (Clip.none), never pushes the header
// taller.
//
// PAN + PINCH HEADER LOGO PASS (earlier): buildSharedHeaderIdentity()
// gains a third optional param — onFreeformLogoScaleChanged — alongside
// onFreeformLogoOffsetChanged and onFreeformLogoDragEnd. _DraggableHeaderLogo
// now uses a single onScaleStart/onScaleUpdate/onScaleEnd GestureDetector
// instead of onPan*. Flutter's scale gesture reports BOTH the pan delta
// (details.focalPointDelta, per-frame movement of the touch/pinch midpoint)
// and the cumulative pinch ratio (details.scale, 1.0 at gesture start) on
// every callback — with a single finger, scale stays 1.0 and
// focalPointDelta behaves exactly like onPanUpdate's delta always did, so
// one-finger drag keeps working unchanged. With two fingers, both position
// and size update together in the same gesture — no separate mode to
// choose. Leaving onFreeformLogoScaleChanged null (every call site until
// updated) means pinch is simply not wired up there; drag alone continues
// to work exactly as it did in the previous pass.
//
// DRAG RANGE NOTE: the floating logo's position is stored as a normalised
// -1..1 offset. As of the RESERVED-ZONE + TRAVEL-RANGE DRAG FIX above,
// that offset is no longer rendered via Flutter's own `Alignment` widget —
// it's converted to an explicit pixel position via _wideLogoLeftOffset /
// _symmetricOffset, which apply the same -1..1 normalisation but stop the
// horizontal range short of the reserved doc-number zone on the right.
// alignment -1.0 still always puts the logo's own left edge flush with
// the box's left edge, matching the FROM block underneath it in
// buildSharedMetaRow — see that file for why the two line up.
//
// SCREEN-TO-LOCAL DRAG FIX (earlier): an earlier version of this comment
// claimed details.focalPointDelta was "already in this widget's own local
// coordinate space" — that was wrong, and was a real cause of drag
// feeling blocked before reaching the true left/right edge on a phone
// screen. focalPointDelta is a GLOBAL/screen-pixel delta, not adjusted
// for any ancestor transform at all. box.size (from _boxKey) is in this
// Stack's own LOCAL/native page-unit space (~499 units for the content
// width, regardless of how zoomed-out the on-screen preview currently
// is via ScaledPageStack's FittedBox, typically ~0.5-0.6x on a phone).
// Fixed by converting the global focal point into the Stack's own local
// space via RenderBox.globalToLocal — this fix is independent of, and
// still needed alongside, the RESERVED-ZONE + TRAVEL-RANGE fix above
// (that one fixes the NORMALISATION of the already-correctly-scaled
// local delta; this one fixes getting a correctly-scaled local delta in
// the first place).
//
// DRAG-ON-HEADER PASS (earlier): buildSharedHeaderIdentity() gained
// onFreeformLogoOffsetChanged and onFreeformLogoDragEnd. When the caller
// supplies onFreeformLogoOffsetChanged (only the live Customise-screen
// preview should do this — the real PDF render and the static Full Preview
// screen should NOT), the floating logo (freeform mode — see the pass
// below this one) is wrapped in a real GestureDetector via the private
// _DraggableHeaderLogo widget, so the person can drag the logo around
// directly on top of the rendered header instead of through a separate
// "Position in Header" dialog. Leaving both callbacks null renders
// byte-for-byte identical to the static branch — the floating logo is
// still positioned via a.headerLogoFreeformOffsetDx/Dy, just not
// interactively.
//
// Why no manual scale compensation is needed for drag: the live preview
// renders the whole document at its native size (kPageW) and then visually
// shrinks it with ScaledPageStack's Transform.scale to fit the phone
// screen. Flutter's gesture system reports gesture deltas already adjusted
// for that ancestor transform — i.e. in the GestureDetector's own LOCAL
// coordinate space — and _DraggableHeaderLogo measures its own RenderBox
// size in that same local space (via GlobalKey), so the delta/box-size
// ratio used to update the normalised offset is correct regardless of how
// small the on-screen preview currently is.
//
// FREEFORM HEADER LOGO DRAG PASS (earlier): buildSharedHeaderIdentity()
// now has a second rendering path for when Business Name and Tagline are
// BOTH hidden. In that state there's nothing anchoring the logo to its
// small fixed box on the left any more, so the whole header row becomes
// free real estate — the logo is rendered as a free-floating layer instead,
// positioned via a.headerLogoFreeformOffsetDx/Dy (normalised -1..1,
// matching Alignment's own coordinate space) and sized via
// a.headerLogoFreeformScale (a free multiplier — see the pass above for
// what it's now a multiplier OF). The doc-type/number block on the right
// renders exactly as before either way. See step_customise.dart's
// "Position in Header" hint (in the logo section) for where
// headerLogoFreeformScale gets set via a resize slider (and now also via
// pinch, see above), and this file's drag layer for where offsetDx/Dy get
// set.
//
// When Business Name or Tagline is shown, nothing about this file's
// behaviour changes from before this pass — the logo renders inline in its
// normal fixed box exactly as it always has.
//
// WIDE LOGO SHAPE PASS (earlier): buildSharedLogo() and
// buildSharedHeaderIdentity() now size the logo box via
// LogoShapeX.boxSizeFor() (shared_logo_picker.dart) instead of always
// assuming a square box. Every existing shape (circle/square/
// roundedSquare) renders at exactly the same square size as before —
// only the new `wide` shape changes anything, widening the box so a
// logo that already has its wordmark baked into the image (e.g. a
// mountain icon + "Summit Solutions" flattened into one PNG) renders
// in full via BoxFit.contain instead of being cropped into a square
// and losing most of its text. The fallback "no logo, show a letter
// mark" box (bottom of buildSharedLogo) is unaffected — that always
// stays a square regardless of the chosen shape, since a single-letter
// mark has no meaningful "wide" version; `wide` only changes anything
// once a real logo image is uploaded.
//
// NO-TRUNCATION / MAX-14PT PASS (earlier): every place in this file
// that used `maxLines: 1, overflow: TextOverflow.ellipsis` (tagline,
// the "INVOICE"/"QUOTE"/"RECEIPT" label, and both sides of each
// metaDateRow — label + value) has been switched to the new shared
// autoFitText() helper below. Ellipsis HIDES content — the actual
// requirement is that every string always renders in full. autoFitText
// wraps the text in a FittedBox(fit: BoxFit.scaleDown), so when a
// string is too wide for its column it shrinks down to fit instead of
// getting cut off, and never exceeds kMaxAutoFitFontSize (14pt) to
// begin with. This is exported (no leading underscore, no `show`
// filtering it out downstream) so doc_line_items.dart / doc_totals.dart
// / doc_footer.dart can use the exact same helper — one behavior,
// applied uniformly everywhere text used to truncate.
//
// META-COLUMN TITLE PASS (earlier): the third column of
// buildSharedMetaRow() (dates + status badge) now has its own title —
// "DETAILS" — rendered in the exact same style as the FROM / BILLED-TO
// labels beside it (fontSize 9, w700, accent color, letterSpacing 1.6),
// so all three columns in that row read consistently as labeled blocks.
// Nothing else in the column changed — Issue Date, Due Date, and the
// status badge still stack underneath it exactly as before.
//
// META-ROW OVERFLOW FIX (earlier): buildSharedMetaRow()'s inner
// metaDateRow() helper laid the label ("Issue Date") and the value+edit
// -icon group directly in a Row. In the narrow flex:2 meta column, a
// label+value combination like "Issue Date" + "14 Sep 2026" genuinely
// doesn't fit side by side at that column width. Previously this was
// handled with Flexible + ellipsis (hard truncation); it's now handled
// by autoFitText, which shrinks instead of cutting text off.
//
// FROM / BILLED-TO RESTRUCTURE PASS (earlier): the business
// address/email/phone block has been REMOVED from
// buildSharedHeaderIdentity() — the header now only shows the logo,
// business name, and (new) a short tagline underneath the name, plus
// the doc type label/number on the right, same as every reference
// invoice-template design (logo-top-left + colored/plain header, no
// address crammed into it). The business's contact details move down
// into buildSharedMetaRow(), which is now a THREE-column row:
//   FROM (business name + structured address lines + email + phone)
//   <recipientLabel> (client name + structured address lines + email + phone)
//   DETAILS (dates + status badge)
// Both address blocks render via AddressInfo.formattedLines — one
// Text widget per address line (Line 1, Line 2, City/State/Zip,
// Country) — instead of the old single wrap-prone string.
//
// EDIT-MODE NOTE: name/email/phone remain individually tappable
// DocFields when `edit` is supplied, matching the previous behavior.
// The address itself renders as static text (AddressInfo.formattedLines)
// even in edit mode — editing a structured six-field address inline on
// the canvas isn't practical; that editing happens via the proper
// AddressFieldGroup sheet elsewhere (shared_address_field_group.dart).
//
// ALL-BLACK-TEXT PASS (earlier): kGrey and kGreyLight are now the
// same near-black value as kInk, instead of the mid/light grey they
// were before (0xFF6B7280 / 0xFF9CA3AF). Every template in the set
// imports these two constants from HERE — some via a bare import, some
// via an explicit `show` — and uses them throughout for "secondary" text
// (addresses, contact lines, meta labels, item sub-text, etc.), so
// changing the two values in this single file makes every template's
// text render in black without touching any of the 10 template files
// individually.
//
// ENGINE FOLDER SPLIT PASS (earlier): split out of the former
// shared_doc_widgets.dart (which has been broken into doc_header.dart /
// doc_line_items.dart / doc_totals.dart / template_document.dart, all
// now living together in document_template_layout_data/ instead of
// shared/).
//
// This file holds:
//   - Page geometry constants (kPageW/H, kPagePadH/V, kContentW) and the
//     palette (kInk, kGrey, kGreyLight, kRule, kPanelBg) — the base
//     values every other file in this folder imports from here.
//   - Common formatting helpers (fmtMoney, fmtQty, withGaps, kColGap,
//     abbreviateRateName, sharedLineItemColumnFlags) used by both the
//     line-items file and the totals file.
//   - NO-TRUNCATION PASS: autoFitText / kMaxAutoFitFontSize — the
//     shared shrink-to-fit text helper used across every template file.
//   - The actual header-identity widgets: buildSharedLogo,
//     buildSharedHeaderIdentity (business logo/name/tagline block +
//     doc-type label/number), buildSharedMetaRow (FROM block +
//     recipient block + meta dates + status badge).
//
// Every doc-identity function here handles both read-only (edit: null)
// and editable (edit: non-null, tap-to-edit via DocField) rendering —
// see doc_edit_bundle.dart for the DocEditBundle shape.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/shared_logo_picker.dart'
    show SharedLogoPicker, SharedLogoThumbnail, LogoShape, LogoShapeX, logoShapeFromString;
import '../../models/address_info.dart';
import 'doc_template_adapter.dart';
import 'doc_edit_bundle.dart';
import '../pagination/doc_field.dart';

// ── Page geometry ────────────────────────────────────────────────────────
const double kPageW    = 595.0;
const double kPageH    = 842.0;
const double kPagePadH = 48.0;
const double kPagePadV = 48.0;
const double kContentW = kPageW - kPagePadH * 2;

// LOGO-INDEPENDENT HEADER HEIGHT PASS: buildSharedHeaderIdentity's Row
// used to size the logo box directly (SizedBox(width: logoBoxSize.width,
// height: logoBoxSize.height)) sitting right next to the business
// name/tagline Column — and a Row's own height is always its tallest
// child's height. So raising the Logo Size slider (any shape — Circle,
// Square, Rounded, and Wide included, since this is a height-only
// wrapper that doesn't touch shape/width logic at all) directly grew
// the whole header taller. This constant is the header's own row
// height target, independent of whatever logo size is chosen — see
// _fixedHeightLogoBox below for how a larger logo still renders at its
// real size without affecting this.
const double kHeaderLogoLayoutHeight = 32.0;

// ── Palette ──────────────────────────────────────────────────────────────
// ALL-BLACK-TEXT PASS: kGrey and kGreyLight now match kInk. Kept as
// separate named constants (rather than removed) so every template's
// existing `color: kGrey` / `color: kGreyLight` references keep
// compiling unchanged — only the VALUE changed, not the API.
const Color kInk       = Color(0xFF16181D);
const Color kGrey      = Color(0xFF16181D);
const Color kGreyLight = Color(0xFF16181D);
const Color kRule      = Color(0xFFE5E7EB);
const Color kPanelBg   = Color(0xFFF9FAFB);

// ── FREEFORM HEADER LOGO — shared clamp range ───────────────────────────
// PAN + PINCH HEADER LOGO PASS: pulled out as named constants (rather than
// inline magic numbers) since both _DraggableHeaderLogoState's pinch clamp
// and step_customise.dart's "Logo Size in Header" slider need to agree on
// the same min/max — a pinch that could push the value past what the
// slider allows (or vice versa) would fight with itself as soon as the
// two are used together.
//
// SIZE-INDEPENDENT FREEFORM LOGO PASS: max raised 3.0 -> 5.0 now that the
// multiplier applies to kHeaderLogoFreeformBaseSize (a fixed, generous
// base) instead of the small businessLogoDisplaySize slider value, so the
// same multiplier range now produces a much bigger real ceiling in pixels.
const double kHeaderLogoFreeformMinScale = 0.4;
const double kHeaderLogoFreeformMaxScale = 9.0;

// SIZE-INDEPENDENT FREEFORM LOGO PASS: the floating/draggable header logo
// scales off THIS fixed base, not businessLogoDisplaySize (which only
// controls the small inline logo box used when Business Name/Tagline are
// shown). This is what lets the freeform logo grow well past the old
// 24-96px inline range under pinch or the "Logo Size in Header" slider,
// without the header row's own height ever changing (the logo is a
// Positioned.fill layer inside a Stack sized only by its non-positioned
// sibling — see buildSharedHeaderIdentity below).
//
// LARGER-DEFAULT-SIZE PASS: raised 60.0 -> 110.0. At 100% on the "Logo
// Size in Header" slider the logo was rendering noticeably smaller than
// the header actually had room for — the VERTICAL-CONTAINMENT PASS
// above stops the logo from ever overflowing PAST the header, but it
// doesn't make the logo fill the header more at the default size; that's
// purely this base value. Safe to raise well past what most headers can
// actually fit, because _cappedFreeformLogoSize (see
// VERTICAL-CONTAINMENT PASS) automatically clamps the final rendered
// size down to the header's real runtime height regardless of this
// constant — so a header with less vertical room (e.g. status badge
// hidden) still can't overflow, it just clamps sooner.
const double kHeaderLogoFreeformBaseSize = 110.0;

// RESERVED-ZONE + TRAVEL-RANGE DRAG FIX: replaces the old
// kWideLogoPanHeadroomFraction. See this file's top comment for the full
// rationale — in short, the old single-fraction cap had no concept of
// the doc-type/number/status column on the right, and fed the same
// (wrong) width into the drag-delta normalisation, which together
// produced both bugs Jesse reported (logo covering the invoice number,
// and drag getting "stuck"/only moving slightly at larger sizes).
//
// kHeaderRightReservedWidth: a fixed no-go zone on the right side of the
// header the logo's box may never enter — sized to comfortably fit the
// doc-type label / "#<number>" row / status badge column at typical
// Text-Size-slider settings. This is a conservative ESTIMATE, not a
// live measurement of that column's actual rendered width. If an
// unusually long invoice/quote/receipt number at the largest Text Size
// setting ever gets uncomfortably close to it, the next step is
// measuring that column's real width via its own GlobalKey instead of
// estimating it here — not something this pass attempts.
const double kHeaderRightReservedWidth = 165.0;

// kWideLogoMinTravelRange: guarantees a minimum number of pixels of real
// left-right drag room even at the largest allowed logo size, so the
// size ceiling (see wideMaxWidth in buildSharedHeaderIdentity below) and
// the drag range can never fight each other into a locked/near-locked
// state the way the old fraction-based cap eventually did.
const double kWideLogoMinTravelRange = 30.0;

// VERTICAL-CONTAINMENT PASS: same idea as kWideLogoMinTravelRange but for
// the vertical axis. Guarantees the freeform logo's rendered height is
// always at least this many pixels shorter than the header's own real
// runtime height, so there's always a sliver of real up/down drag room
// and the logo can never render flush against both the top AND bottom of
// the header at once (which is what "taller than its own container"
// looks like — see _cappedFreeformLogoSize below).
const double kWideLogoMinVerticalTravelRange = 6.0;

// The Wide shape's own width:height ratio isn't available to this file
// directly (it lives in shared_logo_picker.dart's boxSizeFor) — this is
// the same approximation the old cap already relied on (previously an
// inline "2.6"), pulled out as a named constant so the size-cap math and
// the position math below are guaranteed to agree on the same number.
const double kWideLogoAspectRatio = 2.6;

// STATUS-TO-DETAILS PASS: the freeform logo's Stack used to be sized
// purely by the doc-type/number/status column's own natural height (see
// `row` in buildSharedHeaderIdentity) — so once the status badge moved
// out of that column into buildSharedMetaRow's DETAILS block (to shorten
// the header), the remaining doc-type/number text alone is noticeably
// shorter, which would have shrunk the logo's available room even
// further, not grown it. This constant decouples the two: it's a fixed
// minimum vertical budget for the freeform logo area, independent of
// however tall the doc-type/number text currently happens to be. Still
// fully respected by _cappedFreeformLogoSize — a shorter real header
// (this value, or the text column, whichever is taller) is always the
// true ceiling, so the logo still can never overflow past it.
const double kHeaderMinLogoAreaHeight = 84.0;

// ── NO-TRUNCATION / MAX-14PT PASS ───────────────────────────────────────
// Hard ceiling on any font size run through autoFitText(). Whatever
// TextStyle is passed in, its fontSize is clamped down to this before
// rendering — nothing on the document should ever render larger than
// this, regardless of the "Text Size" slider's textScale multiplier
// (see template_document.dart) or any hardcoded style.
const double kMaxAutoFitFontSize = 14.0;

/// Renders `text` in `style` (fontSize clamped to kMaxAutoFitFontSize),
/// wrapped in a FittedBox(fit: BoxFit.scaleDown) so that when the
/// available width is too narrow to fit the FULL string at that font
/// size, Flutter shrinks the whole line down until it fits — instead of
/// ellipsizing / hiding part of it. Every character the user typed
/// stays visible; only the rendered size changes. Use this in place of
/// any `Text(..., maxLines: 1, overflow: TextOverflow.ellipsis)`.
///
/// `minScale` puts a floor under how far a single line will shrink
/// (default 0.55×) so a wildly long string doesn't collapse to
/// unreadably tiny text — callers that need a smaller floor for a very
/// tight column (e.g. table cells) can pass one explicitly.
Widget autoFitText(
  String text,
  TextStyle style, {
  TextAlign textAlign = TextAlign.left,
  double minScale = 0.55,
}) {
  final rawSize = style.fontSize ?? 12.0;
  final cappedSize = rawSize > kMaxAutoFitFontSize ? kMaxAutoFitFontSize : rawSize;
  final alignment = switch (textAlign) {
    TextAlign.right => Alignment.centerRight,
    TextAlign.center => Alignment.center,
    _ => Alignment.centerLeft,
  };
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
      style: style.copyWith(fontSize: cappedSize),
    ),
  );
}

// ── BACKGROUND-IMAGE PASS ───────────────────────────────────────────────
// Shared header/mid-page/footer background-image treatment. Rather than
// adding a text-color picker (more UI surface than this needs) or
// auto-sampling the image's brightness to flip text color (unreliable —
// a single image can have both light and dark regions, so one chosen
// color often ends up unreadable over part of it), this renders the
// image behind the content with a translucent white scrim on top — the
// same "frosted glass over a photo" pattern most polished template
// systems use. Every existing text color on the document (kInk, kGrey,
// accent, etc) stays exactly as-is and remains legible regardless of
// what's in the image, with zero new color settings and zero
// pixel-analysis code.
//
// REPOSITION/OPACITY/OVERFLOW PASS (earlier): adds `opacity`
// (overall image strength, independent of the fixed text-contrast
// scrim), and `offsetDx`/`offsetDy`/`scale` for panning/zooming the
// image within its box — normalised -1..1 for offset (matching
// Alignment's own coordinate space) and 1.0..3.0 for scale, the exact
// same representation SharedLogoPicker's reposition dialog already
// produces (see shared_logo_picker.dart's _normOffset), so the
// reposition dialog built for this feature can share that math and
// just feed its result straight in here.
//
// Implementation: instead of SharedLogoPicker's OverflowBox +
// Transform.translate approach (which needs to know the box's exact
// pixel size up front to compute a clamped pixel travel distance — fine
// for that widget's fixed-size logo box, but header/mid-page/footer
// boxes have variable, content-dependent height that isn't known until
// layout resolves), this uses Image's own `alignment` for panning
// (Flutter positions the cropped image within whatever box it's given,
// no size pre-computation needed) plus Transform.scale anchored at that
// same alignment point for zoom. Wrapped in ClipRect so panning/
// zooming can never bleed past the header/mid-page/footer box's own
// edges — this is the fix for images overflowing their container.
// BoxFit.cover on the Image itself is what makes it always span the
// full width (and height) of its box regardless of the source image's
// own aspect ratio.
//
// Returns `child` completely untouched when there's no enabled image —
// so every document without a background renders byte-for-byte as it
// did before this pass existed.
const double kBackgroundScrimOpacity = 0.82;

Widget withOptionalBackgroundImage({
  required Widget child,
  String? imagePath,
  required bool enabled,
  double opacity = 1.0,
  double offsetDx = 0.0,
  double offsetDy = 0.0,
  double scale = 1.0,
  double scrimOpacity = kBackgroundScrimOpacity,
  // FULL-IMAGE HEADER PASS: optional fit override. Every existing
  // caller (footer, body) omits this and keeps the original
  // BoxFit.cover crop-to-fill behaviour unchanged. The header caller
  // (executive_template.dart's _fullBleedHeaderBackground) passes
  // BoxFit.contain instead, so the whole uploaded image shows
  // letterboxed rather than being cropped to fill the band.
  BoxFit fit = BoxFit.cover,
}) {
  final hasImage = enabled &&
      imagePath != null &&
      imagePath.isNotEmpty &&
      File(imagePath).existsSync();
  if (!hasImage) return child;

  final alignment = Alignment(offsetDx.clamp(-1.0, 1.0), offsetDy.clamp(-1.0, 1.0));
  final clampedScale = scale.clamp(1.0, 3.0);
  final clampedOpacity = opacity.clamp(0.0, 1.0);

  // OPACITY-ZERO FIX: previously only the IMAGE itself was hidden at
  // opacity 0 — the scrim (a separate, fixed-alpha white overlay,
  // independent of this opacity value) still rendered unconditionally
  // any time hasImage was true. That meant "opacity 0" was never
  // guaranteed pixel-identical to "no background at all" — it was an
  // invisible image plus a translucent white rectangle still sitting
  // over the content. Bypass the entire image+scrim construct at
  // opacity 0, returning `child` completely untouched — same as the
  // hasImage-false branch above, so the two states are indistinguishable.
  if (clampedOpacity <= 0.0) return child;

  // OVERFLOW FIX: ClipRect is the actual containment — everything
  // inside it (the zoomed/panned image) is cut off at this box's own
  // bounds, no matter how far Transform.scale/alignment push it.
  return ClipRect(
    child: Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: clampedOpacity,
            child: Transform.scale(
              scale: clampedScale,
              alignment: alignment,
              // FULL-WIDTH PASS: BoxFit.cover (the default) always
              // fills the entire assigned box regardless of the source
              // image's own aspect ratio. FULL-IMAGE HEADER PASS:
              // BoxFit.contain instead shows the whole image
              // letterboxed — see `fit` param doc comment above.
              child: Image.file(File(imagePath), fit: fit, alignment: alignment),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.white.withValues(alpha: scrimOpacity)),
        ),
        child,
      ],
    ),
  );
}

String fmtMoney(String currency, double v) =>
    '${currency.toUpperCase()} ${v.toStringAsFixed(2)}';

// Public (no leading underscore) since doc_line_items.dart also needs
// this — was private when everything lived in one file.
String fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

const double kColGap = 10.0;

// Public — shared by doc_line_items.dart's row layout.
List<Widget> withGaps(List<Widget> columns) {
  final out = <Widget>[];
  for (var i = 0; i < columns.length; i++) {
    if (i > 0) out.add(const SizedBox(width: kColGap));
    out.add(columns[i]);
  }
  return out;
}

const Map<String, String> _kRateNameAbbreviations = {
  'gst': 'GST',
  'vat': 'VAT',
  'sales tax': 'ST',
  'hst': 'HST',
  'pst': 'PST',
  'withholding tax': 'WHT',
  'trade discount': 'TD',
  'early payment discount': 'EPD',
  'bulk discount': 'BD',
  'loyalty discount': 'LD',
};

String abbreviateRateName(String name) =>
    _kRateNameAbbreviations[name.trim().toLowerCase()] ?? name.trim();

({bool showDiscountCol, bool showTaxCol, bool showUnitCol}) sharedLineItemColumnFlags(DocTemplateAdapter a) => (
  showDiscountCol: docFieldOn(a, 'discount') && a.lineItems.any((i) => i.discountEnabled),
  showTaxCol: docFieldOn(a, 'tax') && a.lineItems.any((i) => i.taxEnabled),
  showUnitCol: a.lineItems.any((i) => i.unit.trim().isNotEmpty),
);

// RESERVED-ZONE + TRAVEL-RANGE DRAG FIX: computes the floating logo's
// LEFT pixel position from a normalised -1..1 offset, the same way
// Alignment's own formula would — EXCEPT the right-hand bound stops
// `kHeaderRightReservedWidth` short of the container's right edge
// instead of running flush against it. normalizedDx: 1.0 now always
// lines the logo's right edge up with the start of the reserved zone,
// never past it, regardless of how big the logo currently is. When the
// logo is wide enough that there's no room left to move (maxLeft clamps
// to 0), it renders flush against the left edge for every normalizedDx
// value — kWideLogoMinTravelRange (used when computing wideMaxWidth in
// buildSharedHeaderIdentity below) is what keeps the slider/pinch
// ceiling from ever actually reaching that point.
double _wideLogoLeftOffset({
  required double containerWidth,
  required double logoWidth,
  required double normalizedDx,
}) {
  final maxLeft = (containerWidth - kHeaderRightReservedWidth - logoWidth)
      .clamp(0.0, double.infinity);
  return maxLeft * ((normalizedDx.clamp(-1.0, 1.0) + 1) / 2);
}

// Same formula as _wideLogoLeftOffset but symmetric (no reserved zone) —
// used for the logo's vertical position, where nothing else in the
// header competes for space.
double _symmetricOffset(double containerSize, double childSize, double normalized) {
  final maxOffset = (containerSize - childSize).clamp(0.0, double.infinity);
  return maxOffset * ((normalized.clamp(-1.0, 1.0) + 1) / 2);
}

// VERTICAL-CONTAINMENT PASS: caps the freeform logo's height (and its
// paired width, via kWideLogoAspectRatio) so it can never exceed the
// header's actual rendered height at runtime — this is what previously
// let a large Wide logo droop out of the header and overlap the
// FROM/BILLED-TO block underneath it. `desiredHeight` is the size the
// user's slider/pinch is currently asking for (already capped against
// the WIDTH constraint by the caller); this applies the matching HEIGHT
// constraint on top of that. Both the static render and the
// interactive drag branch call this every layout pass so the logo is
// re-clamped live if the header's own height ever changes (e.g. the
// status badge or a meta row toggling on/off).
({double width, double height}) _cappedFreeformLogoSize({
  required double desiredHeight,
  required double containerHeight,
}) {
  final maxHeight = (containerHeight - kWideLogoMinVerticalTravelRange)
      .clamp(16.0, double.infinity);
  final height = desiredHeight > maxHeight ? maxHeight : desiredHeight;
  return (width: height * kWideLogoAspectRatio, height: height);
}

/// Business logo + name/tagline block, with the doc-type label
/// ("INVOICE"/"QUOTE"/"RECEIPT") and doc number on the trailing side.
/// Read-only unless `edit` is supplied.
///
/// FROM / BILLED-TO RESTRUCTURE PASS: business address/email/phone no
/// longer render here — see buildSharedMetaRow() below, which now
/// carries the full "FROM" block (name + structured address + email +
/// phone) alongside the recipient's own equivalent block.
///
/// FREEFORM HEADER LOGO DRAG PASS: once Business Name and Tagline are
/// both hidden, this switches to a Stack-based layout where the logo
/// floats freely (position + size driven by
/// a.headerLogoFreeformOffsetDx/Dy/Scale) instead of sitting inline in
/// its normal fixed box. See this file's header comment for the full
/// rationale.
///
/// SIZE-INDEPENDENT FREEFORM LOGO PASS: the floating logo's rendered
/// height is now kHeaderLogoFreeformBaseSize * a.headerLogoFreeformScale
/// — no longer tied to a.businessLogoDisplaySize — so it can grow far
/// larger than the small inline logo box ever could, without changing
/// this row's own height (the logo is a Positioned.fill layer; the
/// Stack's size comes only from `row`, its one non-positioned child).
///
/// VERTICAL-CONTAINMENT PASS: that desired height is now ALSO capped
/// against the header's real runtime height (see
/// _cappedFreeformLogoSize) so the logo can never render taller than
/// the header itself, regardless of how big the slider/pinch value
/// asks for — see this file's top comment for the bug this fixes.
///
/// DRAG-ON-HEADER / PAN + PINCH PASS: pass [onFreeformLogoOffsetChanged]
/// to make that floating logo draggable in place, and
/// [onFreeformLogoScaleChanged] to make it pinch-resizable at the same
/// time (used by the live Customise-screen preview only — leave all
/// three new params null anywhere the header is rendered statically,
/// e.g. PDF export / Full Preview).
// LOGO-INDEPENDENT HEADER HEIGHT PASS: wraps the logo widget so it
// reports a FIXED height (kHeaderLogoLayoutHeight) to whatever Row it
// sits in, regardless of the logo's own actual size — the same
// Stack + Positioned pattern used throughout this app for "paint
// outside my own bounds without affecting layout size" (see
// background_render.dart's own doc comment for the full explanation of
// why this pattern, not OverflowBox, is what's safe here). The first,
// non-positioned SizedBox is what the Stack sizes itself from — always
// kHeaderLogoLayoutHeight tall, never the logo's real height. The
// actual logo is the Positioned child: full real size, vertically
// centered via `top`, simply overflowing above/below when it's taller
// than the layout height, with zero effect on the Row's own height.
Widget _fixedHeightLogoBox({
  required Size logoBoxSize,
  required Widget child,
}) {
  final verticalInset = (kHeaderLogoLayoutHeight - logoBoxSize.height) / 2;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      SizedBox(width: logoBoxSize.width, height: kHeaderLogoLayoutHeight),
      Positioned(
        top: verticalInset,
        width: logoBoxSize.width,
        height: logoBoxSize.height,
        child: child,
      ),
    ],
  );
}

Widget buildSharedHeaderIdentity({
  required DocTemplateAdapter a,
  DocEditBundle? edit,
  void Function(Offset normalizedOffset)? onFreeformLogoOffsetChanged,
  void Function(double scale)? onFreeformLogoScaleChanged,
  VoidCallback? onFreeformLogoDragEnd,
}) {
  final editable = edit != null;
  final ff = a.fontFamily;
  final showBusinessName = docFieldOn(a, 'businessName');
  final showDocNumber = docFieldOn(a, 'invoiceNumber');
  // FOOTER TAGLINES PASS: the header tagline now has its own on/off
  // switch (Customise step) independent of whether text was ever typed
  // — a template can have tagline text saved but temporarily hidden.
  final tagline = a.businessTaglineEnabled ? a.businessTagline.trim() : '';

  // WIDE LOGO SHAPE PASS: shape-aware box size — every existing shape
  // (circle/square/roundedSquare) still renders as a square of
  // businessLogoDisplaySize, unchanged; `wide` widens the box instead
  // (see LogoShapeX.boxSizeFor) so a logo+wordmark image renders in
  // full instead of being cropped into a square.
  final logoShape = logoShapeFromString(a.businessLogoShape);
  final logoBoxSize = logoShape.boxSizeFor(a.businessLogoDisplaySize);

  // FREEFORM HEADER LOGO DRAG PASS: eligible only once both Business
  // Name and Tagline are out of the picture — otherwise the logo stays
  // anchored to its normal spot beside that text.
  // SHAPE-GATES-FREEFORM RULE PASS: freeform now requires the Wide
  // shape specifically, on top of the existing Business Name +
  // Tagline both hidden check — matches customise_logo_section.dart's
  // identical rule (that file's own comment has the full rationale:
  // this sidesteps any Circle/Square/Rounded sizing ambiguity entirely
  // by ensuring only Wide can ever reach this code path).
  final freeformEligible = logoShape == LogoShape.wide && !showBusinessName && tagline.isEmpty;

  final row = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // FREEFORM HEADER LOGO DRAG PASS: the inline logo box (and its
      // trailing gap) is omitted entirely once freeform is eligible —
      // it's rendered instead as a floating layer in the Stack below,
      // so it isn't duplicated.
      if (!freeformEligible) ...[
        _fixedHeightLogoBox(
          logoBoxSize: logoBoxSize,
          child: editable
              ? SharedLogoPicker(
                  logoPath: a.businessLogoPath,
                  logoOffset: Offset(a.businessLogoOffsetDx, a.businessLogoOffsetDy),
                  logoScale: a.businessLogoScale,
                  logoShape: logoShape,
                  accent: a.accent,
                  compact: true,
                  compactBoxSize: a.businessLogoDisplaySize,
                  onChanged: (path, offset, scale, shape) => edit.onLogoChanged(path),
                )
              : buildSharedLogo(a),
        ),
        const SizedBox(width: 14),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBusinessName) ...[
              DocField(
                value: a.businessName,
                editable: editable,
                controller: edit?.businessNameCtrl,
                onChanged: edit?.onBusinessNameChanged,
                hint: 'Your Business',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff),
              ),
            ],
            // FROM / BILLED-TO RESTRUCTURE PASS: tagline sits directly
            // under the business name — small, muted, letter-spaced,
            // matching the reference design's "TECHNOLOGY | WEBSITES |
            // SUPPORT" style subtitle. Not editable inline here (the
            // tagline is authored once on the template, same as the
            // business name's source); it simply doesn't render at all
            // when empty.
            //
            // NO-TRUNCATION PASS: was maxLines:1 + ellipsis — a long
            // tagline used to get cut off mid-word. Now wrapped in
            // autoFitText so the whole tagline always renders, shrunk
            // to fit the header's available width if needed.
            if (tagline.isNotEmpty) ...[
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerLeft,
                child: autoFitText(
                  tagline.toUpperCase(),
                  TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: kGrey,
                    letterSpacing: 1.4,
                    fontFamily: ff,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ConstrainedBox(
        // DOC-NUMBER WIDTH FIX: widened from 150 — at the top of the
        // Text Size slider's range, a longer invoice/quote/receipt
        // number no longer fit in the old width and wrapped to a second
        // line (the last couple of characters left dangling below the
        // rest). Widening this box gives it room to stay on one line and
        // naturally shifts the whole block slightly left within the
        // header row, since it's still right-anchored via
        // crossAxisAlignment.end below.
        constraints: const BoxConstraints(maxWidth: 175),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // NO-TRUNCATION PASS: was maxLines:1 + ellipsis. The
            // "INVOICE"/"QUOTE"/"RECEIPT" label is short and fixed, but
            // is capped/shrunk via autoFitText for consistency and as a
            // safety net against any future longer label.
            Align(
              alignment: Alignment.centerRight,
              child: autoFitText(
                a.docTypeLabel,
                TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: kInk, letterSpacing: 3.0, fontFamily: ff),
                textAlign: TextAlign.right,
              ),
            ),
            if (showDocNumber) ...[
              const SizedBox(height: 6),
              // STATUS-TO-DETAILS PASS: the status badge previously
              // rendered here (stacked under the doc number, wrapped in
              // its own Column for left-alignment) has moved to
              // buildSharedMetaRow's DETAILS column, under GST/Tax ID —
              // it reads better grouped with the other document
              // metadata, and shortens this header block. Left as a
              // plain Row now that there's nothing else in this column
              // needing left-alignment coordination.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('#', style: TextStyle(fontSize: 10.5, color: a.accent, fontWeight: FontWeight.w600, fontFamily: ff)),
                  const SizedBox(width: 3),
                  ConstrainedBox(
                    // DOC-NUMBER WIDTH FIX: widened from 110 to match
                    // the outer box's increase above.
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: DocField(
                      value: a.docNumber,
                      editable: editable,
                      controller: edit?.docNumberCtrl,
                      onChanged: edit?.onDocNumberChanged,
                      hint: '—',
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      style: TextStyle(fontSize: 10.5, color: a.accent, fontWeight: FontWeight.w600, fontFamily: ff),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );

  if (!freeformEligible) return row;

  // FREEFORM HEADER LOGO DRAG PASS: `row` (with its inline logo slot
  // omitted above) still establishes the Stack's size — via the
  // doc-type/number column on the right, which always renders — so the
  // floating logo has a real box to be positioned within.
  //
  // SIZE-INDEPENDENT FREEFORM LOGO PASS: base size is the fixed
  // kHeaderLogoFreeformBaseSize, not a.businessLogoDisplaySize.
  //
  // RESERVED-ZONE + TRAVEL-RANGE DRAG FIX (earlier): wideMaxWidth is
  // derived from the space actually available OUTSIDE the reserved
  // doc-number zone (kContentW - kHeaderRightReservedWidth), minus a
  // guaranteed minimum travel range (kWideLogoMinTravelRange) — not from
  // a flat fraction of the full content width. This is necessarily a
  // SMALLER ceiling than the old 88%-of-kContentW cap, because that old
  // cap never accounted for the doc-number zone at all (that's exactly
  // how it was able to overlap it) — a correctly-constrained max size is
  // unavoidably more conservative than a max size that was allowed to
  // overlap other content.
  //
  // VERTICAL-CONTAINMENT PASS (this update): this width-based cap alone
  // is no longer the whole story — `desiredLogoHeightPx` /
  // `desiredLogoWidthPx` below are the size the WIDTH constraint alone
  // would allow. The actual rendered size is computed per-frame inside
  // the LayoutBuilder further down via _cappedFreeformLogoSize, once the
  // header's real runtime height is known, so the logo is additionally
  // clamped to whichever of the two (width cap or height cap) is
  // tighter.
  final rawFreeformHeight = kHeaderLogoFreeformBaseSize * a.headerLogoFreeformScale;
  final availableWidthForLogo = kContentW - kHeaderRightReservedWidth;
  final wideMaxWidth = (availableWidthForLogo - kWideLogoMinTravelRange)
      .clamp(40.0, double.infinity);
  final freeformHeight = (logoShape == LogoShape.wide && rawFreeformHeight * kWideLogoAspectRatio > wideMaxWidth)
      ? wideMaxWidth / kWideLogoAspectRatio
      : rawFreeformHeight;
  // VERTICAL-CONTAINMENT PASS: these are the WIDTH-capped desired size —
  // the height cap against the header's real runtime height is applied
  // on top of this, per-frame, inside the LayoutBuilder below (and
  // inside _DraggableHeaderLogoState.build for the interactive branch).
  final desiredLogoWidthPx = freeformHeight * kWideLogoAspectRatio;
  final desiredLogoHeightPx = freeformHeight;
  final initialOffset = Offset(
    a.headerLogoFreeformOffsetDx.clamp(-1.0, 1.0),
    a.headerLogoFreeformOffsetDy.clamp(-1.0, 1.0),
  );

  // DRAG-ON-HEADER PASS: no drag callback supplied — static render,
  // identical in spirit to every version of this file before this pass
  // (only the position math changed, per the RESERVED-ZONE fix above).
  if (onFreeformLogoOffsetChanged == null) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        row,
        // STATUS-TO-DETAILS PASS: zero-width spacer that only
        // contributes a height floor to this Stack's own bounding-box
        // sizing (Stack sizes itself to the union of its non-positioned
        // children) — see kHeaderMinLogoAreaHeight's doc comment for why
        // this exists independently of `row`'s own natural height.
        const SizedBox(height: kHeaderMinLogoAreaHeight, width: 0),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth;
              final containerHeight = constraints.maxHeight;
              // VERTICAL-CONTAINMENT PASS: apply the height cap now
              // that the header's real runtime height is known, and
              // rebuild the logo widget at that final, fully-capped
              // size — this is what guarantees it can never render
              // taller than the header itself.
              final capped = _cappedFreeformLogoSize(
                desiredHeight: desiredLogoHeightPx,
                containerHeight: containerHeight,
              );
              final logoWidget = buildSharedLogo(a, size: capped.height);
              final left = _wideLogoLeftOffset(
                containerWidth: containerWidth,
                logoWidth: capped.width,
                normalizedDx: initialOffset.dx,
              );
              final top = _symmetricOffset(containerHeight, capped.height, initialOffset.dy);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    width: capped.width,
                    height: capped.height,
                    child: logoWidget,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // DRAG-ON-HEADER / PAN + PINCH PASS: interactive render — used by the
  // live Customise-screen preview. See _DraggableHeaderLogo below.
  return _DraggableHeaderLogo(
    row: row,
    adapter: a,
    desiredLogoWidth: desiredLogoWidthPx,
    desiredLogoHeight: desiredLogoHeightPx,
    initialOffset: initialOffset,
    initialScale: a.headerLogoFreeformScale,
    onOffsetChanged: onFreeformLogoOffsetChanged,
    onScaleChanged: onFreeformLogoScaleChanged,
    onDragEnd: onFreeformLogoDragEnd,
  );
}

// =============================================================================
// PAN + PINCH HEADER LOGO PASS — _DraggableHeaderLogo
//
// Same visual result as the static branch above, but the floating logo
// is wrapped in a GestureDetector so it can be dragged AND pinch-resized
// directly on the rendered header, in a single combined gesture. A
// GlobalKey on the Stack itself gives us this row's real RenderBox size
// AFTER layout — needed to turn a screen drag into the -1..1 normalised
// offset buildSharedHeaderIdentity's static branch (and doc_header's
// PDF/Full Preview renders) already expect.
//
// VERTICAL-CONTAINMENT PASS (this update): the widget now takes the
// WIDTH-capped "desired" size (desiredLogoWidth/desiredLogoHeight) plus
// the adapter itself, instead of a pre-built logoWidget at a fixed
// size — the actual capped size (against the header's real runtime
// height) and the logo widget are both (re)computed every build, inside
// the same LayoutBuilder that measures the header, via
// _cappedFreeformLogoSize + buildSharedLogo. The capped size is cached
// in _cappedWidth/_cappedHeight so onScaleUpdate's drag-delta math uses
// the SAME numbers the render just used, rather than the uncapped
// desired size — that mismatch was the other half of why vertical drag
// used to do nothing once the logo was taller than the header.
//
// RESERVED-ZONE + TRAVEL-RANGE DRAG FIX (earlier): both the rendered
// position (build()) and the drag-delta normalisation (onScaleUpdate)
// go through the SAME width/height + kHeaderRightReservedWidth math as
// the static branch in buildSharedHeaderIdentity, via
// _wideLogoLeftOffset / _symmetricOffset. Position is still anchored to
// the logo's last COMMITTED size (derived from a.headerLogoFreeformScale)
// rather than the live in-gesture pinch size — Transform.scale below
// still supplies the live visual growth during a pinch, exactly as
// before, so nothing about the pinch FEEL changes, only the drag math.
//
// SCREEN-TO-LOCAL DRAG FIX (earlier, still needed): converts
// details.focalPoint from GLOBAL screen pixels into this Stack's own
// LOCAL/native page-unit space via RenderBox.globalToLocal, which
// correctly accounts for ScaledPageStack's FittedBox zoom — without
// this, drag distance would be off by roughly the preview's zoom factor
// regardless of the travel-range fix above.
//
// Using onScale* (instead of separate onPan*/onScale* detectors, which
// Flutter doesn't support cleanly on one widget — the scale recognizer
// subsumes pan) means:
//   - One finger: details.scale stays 1.0 for the whole gesture, so the
//     scale-resize branch below is a no-op and only the position-delta
//     branch does anything. Drag behaves like a plain one-finger pan.
//   - Two fingers: the focal point tracks the midpoint between the two
//     touches (so the logo still pans if the midpoint moves), and
//     details.scale carries the pinch ratio since gesture start — used
//     to resize headerLogoFreeformScale live.
//
// Keeps its own bit of local state (_offset, _scale) for buttery-smooth
// dragging/pinching, but stays in sync with the provider-driven values via
// didUpdateWidget — so if the Logo Size slider / Reset-to-centre changes a
// value from elsewhere (step_customise.dart), the on-canvas logo jumps to
// match immediately, same as any other Provider-driven field on this
// document.
// =============================================================================

class _DraggableHeaderLogo extends StatefulWidget {
  final Widget row;
  final DocTemplateAdapter adapter;
  final double desiredLogoWidth;
  final double desiredLogoHeight;
  final Offset initialOffset;
  final double initialScale;
  final void Function(Offset normalizedOffset) onOffsetChanged;
  final void Function(double scale)? onScaleChanged;
  final VoidCallback? onDragEnd;

  const _DraggableHeaderLogo({
    required this.row,
    required this.adapter,
    required this.desiredLogoWidth,
    required this.desiredLogoHeight,
    required this.initialOffset,
    required this.initialScale,
    required this.onOffsetChanged,
    this.onScaleChanged,
    this.onDragEnd,
  });

  @override
  State<_DraggableHeaderLogo> createState() => _DraggableHeaderLogoState();
}

class _DraggableHeaderLogoState extends State<_DraggableHeaderLogo> {
  final GlobalKey _boxKey = GlobalKey();
  late Offset _offset;
  late double _scale;
  double _scaleAtGestureStart = 1.0;
  // SCREEN-TO-LOCAL DRAG FIX: tracks the gesture's global focal point so
  // each update can convert it into the Stack's own LOCAL coordinate
  // space via RenderBox.globalToLocal — see the fix note on
  // onScaleUpdate below for why this replaces the old
  // details.focalPointDelta approach.
  Offset? _lastGlobalFocal;
  bool _dragging = false;

  // VERTICAL-CONTAINMENT PASS: the actual, fully-capped (width AND
  // height) size last used to render the logo — updated every build
  // inside the LayoutBuilder below, and read back by onScaleUpdate so
  // the drag-delta math always agrees with what's currently on screen.
  double _cappedWidth = 0;
  double _cappedHeight = 0;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialOffset;
    _scale = widget.initialScale;
  }

  @override
  void didUpdateWidget(covariant _DraggableHeaderLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't let an external rebuild fight an in-progress gesture — only
    // resync from the provider-driven values while the user's finger is
    // off the logo.
    if (!_dragging) {
      if (oldWidget.initialOffset != widget.initialOffset) {
        _offset = widget.initialOffset;
      }
      if (oldWidget.initialScale != widget.initialScale) {
        _scale = widget.initialScale;
      }
    }
  }

  RenderBox? _measuredBox() {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize) ? box : null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _boxKey,
      clipBehavior: Clip.none,
      children: [
        widget.row,
        // STATUS-TO-DETAILS PASS: same height-floor spacer as the
        // static branch above — see kHeaderMinLogoAreaHeight.
        const SizedBox(height: kHeaderMinLogoAreaHeight, width: 0),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth;
              final containerHeight = constraints.maxHeight;
              // VERTICAL-CONTAINMENT PASS: cap against the header's
              // real runtime height, cache the result for
              // onScaleUpdate, and rebuild the logo widget at that
              // final size.
              final capped = _cappedFreeformLogoSize(
                desiredHeight: widget.desiredLogoHeight,
                containerHeight: containerHeight,
              );
              _cappedWidth = capped.width;
              _cappedHeight = capped.height;
              final logoWidget = buildSharedLogo(widget.adapter, size: capped.height);
              final left = _wideLogoLeftOffset(
                containerWidth: containerWidth,
                logoWidth: capped.width,
                normalizedDx: _offset.dx,
              );
              final top = _symmetricOffset(containerHeight, capped.height, _offset.dy);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    width: capped.width,
                    height: capped.height,
                    child: Transform.scale(
                      // PAN + PINCH PASS: local _scale drives the on-screen
                      // size immediately during a pinch, without waiting on
                      // a Provider round-trip + rebuild every frame.
                      // logoWidget is already sized for the LAST committed
                      // scale (from a.headerLogoFreeformScale, subject to
                      // the same height cap every frame), so this
                      // Transform.scale only needs to account for the
                      // ratio between that committed size and the current
                      // in-gesture size.
                      scale: widget.initialScale == 0 ? 1.0 : _scale / widget.initialScale,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: (details) {
                          _dragging = true;
                          _scaleAtGestureStart = _scale;
                          // SCREEN-TO-LOCAL DRAG FIX: details.focalPoint is
                          // in GLOBAL (screen) pixels — record it as the
                          // baseline for the first update's delta.
                          _lastGlobalFocal = details.focalPoint;
                        },
                        onScaleUpdate: (details) {
                          final box = _measuredBox();
                          if (box != null && box.size.width > 0 && box.size.height > 0 && _lastGlobalFocal != null) {
                            // SCREEN-TO-LOCAL DRAG FIX: convert the global
                            // focal point into this Stack's own local
                            // coordinate space via RenderBox.globalToLocal,
                            // which accounts for the entire ancestor
                            // transform chain (including ScaledPageStack's
                            // FittedBox zoom).
                            final localNow = box.globalToLocal(details.focalPoint);
                            final localPrev = box.globalToLocal(_lastGlobalFocal!);
                            final localDelta = localNow - localPrev;
                            _lastGlobalFocal = details.focalPoint;

                            // RESERVED-ZONE + TRAVEL-RANGE DRAG FIX: divide
                            // by the SAME travel-range formula
                            // _wideLogoLeftOffset / _symmetricOffset use to
                            // render the position — so a full drag across
                            // the real available room always reaches both
                            // true edges. VERTICAL-CONTAINMENT PASS: uses
                            // _cappedWidth/_cappedHeight (the size actually
                            // on screen this frame) instead of the
                            // uncapped desired size, so vertical drag now
                            // always has real travel room once the logo is
                            // capped shorter than the header.
                            final maxLeft = (box.size.width - kHeaderRightReservedWidth - _cappedWidth)
                                .clamp(0.0, double.infinity);
                            final dxDelta = maxLeft > 0 ? localDelta.dx / (maxLeft / 2) : 0.0;
                            final maxTop = (box.size.height - _cappedHeight).clamp(0.0, double.infinity);
                            final dyDelta = maxTop > 0 ? localDelta.dy / (maxTop / 2) : 0.0;

                            final nextOffset = Offset(
                              (_offset.dx + dxDelta).clamp(-1.0, 1.0),
                              (_offset.dy + dyDelta).clamp(-1.0, 1.0),
                            );
                            setState(() => _offset = nextOffset);
                            widget.onOffsetChanged(nextOffset);
                          }

                          // PAN + PINCH PASS: details.scale is a cumulative
                          // RATIO since onScaleStart (1.0 for a one-finger
                          // drag), which is scale-invariant by construction
                          // — unlike the translation delta above, this
                          // needs no coordinate-space conversion.
                          if (widget.onScaleChanged != null) {
                            final nextScale = (_scaleAtGestureStart * details.scale)
                                .clamp(kHeaderLogoFreeformMinScale, kHeaderLogoFreeformMaxScale);
                            if ((nextScale - _scale).abs() > 0.001) {
                              setState(() => _scale = nextScale);
                              widget.onScaleChanged!(nextScale);
                            }
                          }
                        },
                        onScaleEnd: (_) {
                          _dragging = false;
                          _lastGlobalFocal = null;
                          widget.onDragEnd?.call();
                        },
                        child: logoWidget,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// FROM / BILLED-TO RESTRUCTURE PASS: one address block — a label
/// ("FROM" or the recipient label), the party's name, its structured
/// address rendered one line per entry (via AddressInfo.formattedLines
/// — Line 1, Line 2, City/State/Zip, Country), then email and phone.
/// Any piece that's empty (or toggled off via showX) is simply
/// skipped, same as every other field on this document.
Widget _addressBlock({
  required String label,
  required Color labelColor,
  required String name,
  required AddressInfo addressInfo,
  required String email,
  required String phone,
  required String ff,
  bool showName = true,
  bool showAddress = true,
  bool showEmail = true,
  bool showPhone = true,
}) {
  final lines = addressInfo.formattedLines;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: labelColor, letterSpacing: 1.6, fontFamily: ff)),
      const SizedBox(height: 8),
      // NO-TRUNCATION PASS: name/address/email/phone here already had
      // no maxLines/ellipsis (they wrap naturally, softWrap true by
      // default) — left as-is. Only single-line, ellipsis-prone spots
      // elsewhere in this file needed autoFitText.
      if (showName && name.trim().isNotEmpty) ...[
        Text(name,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
        const SizedBox(height: 3),
      ],
      if (showAddress)
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(line,
                style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff, height: 1.35)),
          ),
      if (showEmail && email.trim().isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(email, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
      ],
      if (showPhone && phone.trim().isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(phone, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
      ],
    ],
  );
}

/// FROM block + recipient block + meta dates + status badge.
/// Read-only unless `edit` is supplied (name/email/phone remain
/// individually tappable DocFields in edit mode — see this file's
/// header comment for why the address itself stays static text even
/// then).
Widget buildSharedMetaRow({
  required DocTemplateAdapter a,
  DocEditBundle? edit,
}) {
  final editable = edit != null;
  final ff = a.fontFamily;

  final showBusinessAddress = docFieldOn(a, 'businessAddress');
  final showBusinessEmail = docFieldOn(a, 'businessEmail');
  final showBusinessPhone = docFieldOn(a, 'businessPhone');

  final showClientName = docFieldOn(a, 'customerName');
  final showClientAddress = docFieldOn(a, 'customerAddress');
  final showClientEmail = docFieldOn(a, 'customerEmail');
  final showClientPhone = docFieldOn(a, 'customerPhone');
  final showMeta1 = docFieldOn(a, 'date');
  final showMeta2 = docFieldOn(a, 'dueDate');

  Widget metaDateRow(String label, String value, VoidCallback? onTap) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: autoFitText(
            label,
            TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: autoFitText(
                  value.isEmpty ? '—' : value,
                  TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff),
                  textAlign: TextAlign.right,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                Icon(Icons.edit_calendar_rounded, size: 11, color: a.accent.withValues(alpha: 0.6)),
              ],
            ],
          ),
        ),
      ],
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }

  Widget fromBlock = _addressBlock(
    label: 'FROM',
    labelColor: a.accent,
    name: a.businessName,
    addressInfo: a.businessAddressInfo,
    email: a.businessEmail,
    phone: a.businessPhone,
    ff: ff,
    showAddress: showBusinessAddress,
    showEmail: showBusinessEmail,
    showPhone: showBusinessPhone,
  );

  Widget recipientBlock;
  if (editable) {
    recipientBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(a.recipientLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: a.accent, letterSpacing: 1.6, fontFamily: ff)),
        const SizedBox(height: 8),
        if (showClientName) ...[
          DocField(
            value: a.clientName, editable: editable, controller: edit.clientNameCtrl,
            onChanged: edit.onClientNameChanged, hint: 'Client name',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff),
          ),
          const SizedBox(height: 3),
        ],
        if (showClientAddress)
          for (final line in a.clientAddressInfo.formattedLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(line,
                  style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff, height: 1.35)),
            ),
        if (showClientEmail) ...[
          const SizedBox(height: 2),
          DocField(
            value: a.clientEmail, editable: editable, controller: edit.clientEmailCtrl,
            onChanged: edit.onClientEmailChanged, hint: 'Client email',
            style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff),
          ),
        ],
        if (showClientPhone) ...[
          const SizedBox(height: 2),
          DocField(
            value: a.clientPhone, editable: editable, controller: edit.clientPhoneCtrl,
            onChanged: edit.onClientPhoneChanged, hint: 'Client phone',
            style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff),
          ),
        ],
      ],
    );
  } else {
    recipientBlock = _addressBlock(
      label: a.recipientLabel,
      labelColor: a.accent,
      name: a.clientName,
      addressInfo: a.clientAddressInfo,
      email: a.clientEmail,
      phone: a.clientPhone,
      ff: ff,
      showName: showClientName,
      showAddress: showClientAddress,
      showEmail: showClientEmail,
      showPhone: showClientPhone,
    );
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: fromBlock),
      const SizedBox(width: 20),
      Expanded(flex: 3, child: recipientBlock),
      const SizedBox(width: 20),
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DETAILS',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: a.accent, letterSpacing: 1.6, fontFamily: ff)),
            const SizedBox(height: 8),
            if (showMeta1) ...[
              metaDateRow(a.metaLabel1, a.metaValue1, editable ? edit.onTapMetaDate1 : null),
              const SizedBox(height: 6),
            ],
            if (showMeta2) ...[
              metaDateRow(a.metaLabel2, a.metaValue2, editable ? edit.onTapMetaDate2 : null),
              const SizedBox(height: 6),
            ],
            if (a.businessTaxId.trim().isNotEmpty) ...[
              metaDateRow('Tax ID', a.businessTaxId, null),
              const SizedBox(height: 6),
            ],
            if (a.businessGstNumber.trim().isNotEmpty) ...[
              metaDateRow('GST', a.businessGstNumber, null),
              const SizedBox(height: 6),
            ],
            // STATUS-TO-DETAILS PASS: relocated here (under GST/Tax ID)
            // from the header's doc-type/number column — see
            // kHeaderMinLogoAreaHeight's doc comment for why. Still
            // gated on the same 'status' enabledFields key, so the
            // Fields section on Customise can turn it off exactly as
            // before.
            if (docFieldOn(a, 'status')) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: a.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(a.statusLabel,
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                        letterSpacing: 1.0, color: a.statusColor, fontFamily: ff)),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

Widget buildSharedLogo(
  DocTemplateAdapter a, {
  double? size,
  Color? fallbackMarkColor,
  Color? fallbackMarkTextColor,
}) {
  final boxHeight = size ?? a.businessLogoDisplaySize;

  if (!docFieldOn(a, 'businessLogo')) {
    return SizedBox(width: boxHeight, height: boxHeight);
  }

  final path = a.businessLogoPath;

  if (path != null && path.isNotEmpty && File(path).existsSync()) {
    final shape = logoShapeFromString(a.businessLogoShape);
    final boxSize = shape.boxSizeFor(boxHeight);
    return SizedBox(
      width: boxSize.width,
      height: boxSize.height,
      child: ClipRRect(
        borderRadius: shape.radiusFor(boxHeight),
        child: SharedLogoThumbnail(
          logoPath: path,
          logoOffset: Offset(a.businessLogoOffsetDx, a.businessLogoOffsetDy),
          logoScale: a.businessLogoScale,
          logoShape: shape,
          boxSize: boxHeight,
        ),
      ),
    );
  }

  if (!a.businessLogoShowInitial) {
    return SizedBox(width: boxHeight, height: boxHeight);
  }

  final markColor = fallbackMarkColor ?? a.accent;
  final textColor = fallbackMarkTextColor ?? Colors.white;
  final customLetter = a.businessLogoInitialLetter.trim();
  final initial = customLetter.isNotEmpty
      ? customLetter[0].toUpperCase()
      : (a.businessName.trim().isNotEmpty ? a.businessName.trim()[0].toUpperCase() : 'B');

  return SizedBox(
    width: boxHeight,
    height: boxHeight,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: boxHeight * 0.72,
            height: boxHeight * 0.72,
            decoration: BoxDecoration(color: markColor, borderRadius: BorderRadius.circular(5)),
          ),
        ),
        Text(initial,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: boxHeight * 0.34)),
      ],
    ),
  );
}