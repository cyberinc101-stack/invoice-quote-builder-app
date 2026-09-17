// doc_header.dart
// lib/document_layout_templates/document_template_layout_data/doc_header.dart
//
// SIZE-INDEPENDENT FREEFORM LOGO PASS (this update): the floating header
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
// -1..1 offset and rendered via Alignment(offsetDx, offsetDy) inside a
// Positioned.fill that fills this row's own box. Align computes the
// child's position as (parentSize - childSize) * (alignment + 1) / 2, so
// alignment -1.0 always puts the logo's own left edge flush with the box's
// left edge — regardless of the logo's current size — and that box is the
// same width (same page padding) as the FROM/meta row rendered directly
// underneath it in buildSharedMetaRow. So dragging fully left already
// lines the logo up with the left edge of the FROM block. The clamp that
// enforces the -1..1 range lives in _DraggableHeaderLogoState.onScaleUpdate
// below, marked with a comment, in case that range ever needs widening.
// If drag still feels blocked before reaching -1.0 in your build, it is
// almost always because something OUTSIDE this widget (an ancestor
// ClipRect/ClipRRect or a narrower-than-content-width container wrapping
// buildSharedHeaderIdentity's result) is reporting a smaller RenderBox
// than the true page content width — not this clamp.
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
const double kHeaderLogoFreeformBaseSize = 60.0;

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
              // STATUS-UNDER-DOC-NUMBER-LEFT-ALIGNED PASS: the doc
              // number row and the status badge are wrapped together
              // in their own inner Column with crossAxisAlignment.start
              // — that's what makes the status badge's LEFT edge match
              // the doc-number row's own left edge (the "#" symbol),
              // regardless of how long the doc number text is. Without
              // this inner wrapper, each child would independently
              // align to the OUTER column's crossAxisAlignment.end
              // (the page's right margin) instead of to each other.
              // The inner Column as a WHOLE still gets end-aligned by
              // the outer column, so the block stays right-flush
              // against the page the same way it always has.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  // SHOW-STATUS-TOGGLE PASS: gated on the new 'status'
                  // enabledFields key (see invoice_data.dart's
                  // defaultInvoiceEnabledFields) so the Fields section
                  // on Customise can turn this badge off entirely.
                  if (docFieldOn(a, 'status')) ...[
                    const SizedBox(height: 8),
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
  // floating logo has a real box to be positioned within. This box's
  // width is identical to buildSharedMetaRow's own row width (both sit
  // inside the same page padding), which is what makes offsetDx: -1.0
  // line the logo's left edge up with the FROM block underneath — see
  // the "DRAG RANGE NOTE" at the top of this file.
  // Clip.none lets an enlarged logo (headerLogoFreeformScale > 1)
  // overflow that box visually rather than getting clipped, since
  // enlarging past the row's own height is the point of this feature —
  // and, per the SIZE-INDEPENDENT FREEFORM LOGO PASS above, the row's
  // own layout height never changes as a result, since this logo layer
  // is Positioned.fill (out of flow) rather than a flow child of `row`.
  //
  // SIZE-INDEPENDENT FREEFORM LOGO PASS: base size is now the fixed
  // kHeaderLogoFreeformBaseSize, not a.businessLogoDisplaySize.
  //
  // WIDE-WIDTH-CAP FIX (this update): Wide's box is height*2.6 wide
  // (see LogoShapeX.boxSizeFor) — uncapped, that reaches roughly
  // kContentW at only a moderate freeformHeight, and grows well past
  // the page's own width the further "Logo Size in Header" is raised.
  // A box that wide silently breaks two things at once: the drag
  // GestureDetector's hit region extends far outside anywhere a finger
  // can actually reach on a real page, and the slider stops reading as
  // functional past that point since the box has nowhere further to
  // usefully grow within the visible page. Clamping the EFFECTIVE
  // height used for Wide's box (so width = height*2.6 never exceeds
  // kContentW) keeps both the drag target and the slider's range
  // meaningful across its whole travel — every other shape is
  // unaffected, since this clamp only applies when logoShape is Wide.
  final rawFreeformHeight = kHeaderLogoFreeformBaseSize * a.headerLogoFreeformScale;
  final freeformHeight = (logoShape == LogoShape.wide && rawFreeformHeight * 2.6 > kContentW)
      ? kContentW / 2.6
      : rawFreeformHeight;
  final logoWidget = buildSharedLogo(a, size: freeformHeight);
  final initialOffset = Offset(
    a.headerLogoFreeformOffsetDx.clamp(-1.0, 1.0),
    a.headerLogoFreeformOffsetDy.clamp(-1.0, 1.0),
  );

  // DRAG-ON-HEADER PASS: no drag callback supplied — static render,
  // identical to every version of this file before this pass.
  if (onFreeformLogoOffsetChanged == null) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        row,
        Positioned.fill(
          child: Align(
            alignment: Alignment(initialOffset.dx, initialOffset.dy),
            child: logoWidget,
          ),
        ),
      ],
    );
  }

  // DRAG-ON-HEADER / PAN + PINCH PASS: interactive render — used by the
  // live Customise-screen preview. See _DraggableHeaderLogo below.
  return _DraggableHeaderLogo(
    row: row,
    logoWidget: logoWidget,
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
// Same visual result as the static Stack/Positioned.fill/Align branch
// above, but the floating logo is wrapped in a GestureDetector so it can
// be dragged AND pinch-resized directly on the rendered header, in a
// single combined gesture. A GlobalKey on the Stack itself gives us this
// row's real RenderBox size AFTER layout — needed to turn a screen drag
// into the -1..1 normalised offset buildSharedHeaderIdentity's static
// branch (and doc_header's PDF/Full Preview renders) already expect.
//
// SCREEN-TO-LOCAL DRAG FIX: an earlier version of this comment claimed
// details.focalPointDelta was "already in this widget's own local
// coordinate space" — that was wrong, and was the actual cause of drag
// feeling blocked before reaching the true left/right edge on a phone
// screen. focalPointDelta is a GLOBAL/screen-pixel delta, not adjusted
// for any ancestor transform at all. box.size (from _boxKey) is in this
// Stack's own LOCAL/native page-unit space (~499 units for the content
// width, regardless of how zoomed-out the on-screen preview currently
// is via ScaledPageStack's FittedBox, typically ~0.5-0.6x on a phone).
// Dividing a screen-pixel delta by a native-unit box size meant roughly
// 1.6-2x more physical finger travel was required to reach the -1.0
// clamp than the screen actually had room for. Fixed by converting the
// global focal point into the Stack's own local space via
// RenderBox.globalToLocal (see onScaleUpdate below), which correctly
// accounts for the entire ancestor transform chain — the drag distance
// now matches physical finger travel at any preview zoom level.
//
// DRAG RANGE NOTE: if dragging ever again feels blocked before reaching
// the true left edge, also check the ANCESTOR chain feeding this widget
// its size (via _boxKey) — a ClipRect/ClipRRect or fixed-width container
// upstream (e.g. wrapping the whole header row in something narrower
// than kContentW) would make the measured box narrower than the visible
// header, which would shrink the usable travel range before the -1.0
// clamp below is ever reached. The clamp itself is intentionally exactly
// -1.0..1.0 and does not need loosening for that case.
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
  final Widget logoWidget;
  final Offset initialOffset;
  final double initialScale;
  final void Function(Offset normalizedOffset) onOffsetChanged;
  final void Function(double scale)? onScaleChanged;
  final VoidCallback? onDragEnd;

  const _DraggableHeaderLogo({
    required this.row,
    required this.logoWidget,
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
        Positioned.fill(
          child: Align(
            alignment: Alignment(_offset.dx, _offset.dy),
            child: Transform.scale(
              // PAN + PINCH PASS: local _scale drives the on-screen size
              // immediately during a pinch, without waiting on a
              // Provider round-trip + rebuild every frame. widget.logoWidget
              // is already sized for the LAST committed scale (from
              // a.headerLogoFreeformScale), so this Transform.scale only
              // needs to account for the ratio between that committed size
              // and the current in-gesture size.
              scale: widget.initialScale == 0 ? 1.0 : _scale / widget.initialScale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _dragging = true;
                  _scaleAtGestureStart = _scale;
                  // SCREEN-TO-LOCAL DRAG FIX: details.focalPoint is in
                  // GLOBAL (screen) pixels — record it as the baseline
                  // for the first update's delta.
                  _lastGlobalFocal = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  final box = _measuredBox();
                  if (box != null && box.size.width > 0 && box.size.height > 0 && _lastGlobalFocal != null) {
                    // SCREEN-TO-LOCAL DRAG FIX: the old code used
                    // details.focalPointDelta directly — but that's a
                    // GLOBAL/screen-pixel delta, completely unscaled by
                    // any ancestor transform. box.size (from _boxKey) is
                    // in this Stack's own LOCAL/native page-unit space
                    // (e.g. ~499 units for the content width), not
                    // screen pixels. When the live preview is shown
                    // zoomed out to fit a phone screen (ScaledPageStack's
                    // FittedBox — often ~0.5-0.6x on a phone), a real
                    // finger drag of screen pixels was being treated as
                    // if it were that many NATIVE units of movement —
                    // requiring roughly 1.6-2x more physical finger
                    // travel than the screen has room for to reach the
                    // -1.0 clamp, which is exactly what "blocked before
                    // reaching the left edge" looks like.
                    //
                    // Fix: convert the global focal point into this
                    // Stack's own local coordinate space via
                    // RenderBox.globalToLocal, which correctly accounts
                    // for the ENTIRE ancestor transform chain (including
                    // ScaledPageStack's FittedBox) up to (but not
                    // including) this Stack's own descendants — giving a
                    // delta already expressed in the same units as
                    // box.size, regardless of how zoomed-out the preview
                    // currently is.
                    final localNow = box.globalToLocal(details.focalPoint);
                    final localPrev = box.globalToLocal(_lastGlobalFocal!);
                    final localDelta = localNow - localPrev;
                    _lastGlobalFocal = details.focalPoint;

                    // DRAG RANGE NOTE (see top of file): this clamp is
                    // what enforces the -1..1 normalised range. Widening
                    // it (e.g. to -1.15..1.15) would let the logo be
                    // nudged slightly past the header row's own edges if
                    // ever needed.
                    final nextOffset = Offset(
                      (_offset.dx + localDelta.dx / (box.size.width / 2)).clamp(-1.0, 1.0),
                      (_offset.dy + localDelta.dy / (box.size.height / 2)).clamp(-1.0, 1.0),
                    );
                    setState(() => _offset = nextOffset);
                    widget.onOffsetChanged(nextOffset);
                  }

                  // PAN + PINCH PASS: details.scale is a cumulative RATIO
                  // since onScaleStart (1.0 for a one-finger drag), which
                  // is scale-invariant by construction — unlike the
                  // translation delta above, this needs no coordinate-
                  // space conversion.
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
                child: widget.logoWidget,
              ),
            ),
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

  // META-ROW OVERFLOW FIX / NO-TRUNCATION PASS: label and value+icon
  // used to be wrapped in Flexible + maxLines:1 + TextOverflow.ellipsis
  // — a real fix for the RenderFlex overflow, but it truncated text
  // ("Issue Date" or a longer date string could get cut with "…").
  // Both sides now use autoFitText instead: still protected against
  // overflowing the narrow flex:2 meta column, but by shrinking the
  // whole label/value down to fit rather than hiding characters.
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

  // FROM / BILLED-TO RESTRUCTURE PASS: editable mode still allows
  // tapping the recipient's own name/email/phone (their edit controls
  // already existed on DocEditBundle) — only the FROM side (business
  // name/email/phone) has no dedicated inline-edit widgets wired up
  // here, since that data is authored on the template, not per-document.
  // When editable, the business's name/email/phone render as plain text
  // too, for visual consistency within the same block.
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
            // META-COLUMN TITLE PASS: same label styling as FROM /
            // BILLED-TO — fontSize 9, w700, accent color, letterSpacing
            // 1.6 — so this column reads as a labeled block too.
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
            // TAX-ID-GST-IN-DETAILS PASS: shown only when the business
            // actually has a Tax ID and/or GST number set (template
            // sheet's Business Information section — see
            // step_templates.dart) — an empty row for an unset value
            // would just be visual noise. Same metaDateRow styling as
            // the dates above, so all four rows in this column read
            // consistently.
            if (a.businessTaxId.trim().isNotEmpty) ...[
              metaDateRow('Tax ID', a.businessTaxId, null),
              const SizedBox(height: 6),
            ],
            if (a.businessGstNumber.trim().isNotEmpty) ...[
              metaDateRow('GST', a.businessGstNumber, null),
              const SizedBox(height: 6),
            ],
            // STATUS-UNDER-DOC-NUMBER-LEFT-ALIGNED PASS: the status
            // badge has moved back to buildSharedHeaderIdentity, under
            // the doc number, left-aligned to it — no longer rendered
            // here in the DETAILS column.
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
    // WIDE LOGO SHAPE PASS: shape-aware box — every existing shape
    // stays a square of boxHeight, unchanged; `wide` renders at a
    // wider box instead so a logo+wordmark image isn't cropped into a
    // square. See LogoShapeX.boxSizeFor.
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

  // WIDE LOGO SHAPE PASS: the fallback letter mark always stays a
  // square of boxHeight, regardless of the chosen logo shape — a
  // single-letter mark has no "wide" version. `wide` only changes
  // anything once a real logo image exists (the branch above).
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