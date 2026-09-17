// page_background_spec.dart
// lib/document_layout_templates/document_backgrounds/page_background_spec.dart
//
// PER-PAGE BACKGROUND PASS: adds the "whole page" background layer —
// distinct from BackgroundSpec (background_spec.dart), which paints
// behind ONE zone (header band / mid-page body region / footer band)
// independently per zone, clipped to that zone's own bounds. That
// zone-by-zone approach is why an uploaded image visibly cut off
// between the header, the FROM/BILLED-TO meta row, and the item rows
// — each region draws its own separate copy of the image, cropped to
// its own box, instead of one continuous image running behind the
// whole page.
//
// PageBackgroundSpec instead describes ONE image painted behind the
// ENTIRE page — header, FROM/BILLED-TO meta row, item rows, and footer
// all sit on top of the SAME image layer. Every content container that
// currently has its own opaque/white fill (panel backgrounds, alternating
// line-item row shading, etc.) needs to go transparent wherever a page
// background is active — that part isn't in this file; it depends on
// content_color_spec.dart and the per-template render code, neither of
// which has been shared yet. This file is the data model + resolver
// only.
//
// PER-PAGE SCOPE PASS: a document can have more than one page (see
// A4Paginator). Rather than forcing one global image across every
// page, each page index gets its OWN PageBackgroundSpec — different
// pages can show different images, or no image at all.
// PageBackgroundScope is the authored intent (apply to just page 1?
// every page? a fully custom per-page selection?) that
// resolvePageBackground turns into a concrete spec per page index at
// render time.
//
// LIVE-LINK PASS: a page whose spec has `linkedToPage1: true` mirrors
// page 1's image/opacity/offset/scale live — editing page 1 updates
// every linked page automatically. The moment a person edits an
// individual page's own image or reposition (while linked), the UI
// that performs that edit should save that page's spec with
// `linkedToPage1: false`, breaking the link for that one page only.
// This file doesn't enforce that itself — it's a UI-level decision
// made wherever a page's spec is edited — but the data shape supports
// it directly via this flag.

import 'background_spec.dart';

/// Which pages get a background image, at the authoring level (what
/// the user picked in the UI) — turned into a concrete per-page spec
/// via [resolvePageBackground].
enum PageBackgroundScope {
  /// No page background at all (default — every existing document is
  /// unaffected).
  none,

  /// Only the first page shows a background image.
  firstPageOnly,

  /// Every page shows a background image — page 1's image/position/
  /// scale is duplicated to every later page unless that specific page
  /// has been given its own independent (unlinked) spec.
  allPages,

  /// Fully custom per-page control — each page's spec is whatever is
  /// explicitly stored for it, with no automatic duplication.
  custom,
}

class PageBackgroundSpec {
  final String? imagePath;
  final bool enabled;
  final double opacity;
  final double offsetDx;
  final double offsetDy;
  final double scale;
  final double scrimOpacity;

  /// LIVE-LINK PASS: true while this page mirrors page 1's spec
  /// automatically (see resolvePageBackground). Meaningless for page 0
  /// itself, which is always the source of truth, never a follower.
  final bool linkedToPage1;

  const PageBackgroundSpec({
    this.imagePath,
    this.enabled = false,
    this.opacity = 1.0,
    this.offsetDx = 0.0,
    this.offsetDy = 0.0,
    this.scale = 1.0,
    this.scrimOpacity = 0.82,
    this.linkedToPage1 = true,
  });

  bool get hasVisibleImage => enabled && (imagePath?.isNotEmpty ?? false);

  /// Converts to the existing BackgroundSpec shape so this draws
  /// through the SAME renderDocumentBackground()/BackgroundSpec
  /// machinery every other background in this app already uses,
  /// instead of a second, parallel render implementation.
  BackgroundSpec toBackgroundSpec() => BackgroundSpec(
        imagePath: imagePath,
        enabled: enabled,
        opacity: opacity,
        offsetDx: offsetDx,
        offsetDy: offsetDy,
        scale: scale,
        scrimOpacity: scrimOpacity,
      );

  PageBackgroundSpec copyWith({
    String? imagePath,
    bool clearImagePath = false,
    bool? enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
    double? scrimOpacity,
    bool? linkedToPage1,
  }) =>
      PageBackgroundSpec(
        imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
        enabled: enabled ?? this.enabled,
        opacity: opacity ?? this.opacity,
        offsetDx: offsetDx ?? this.offsetDx,
        offsetDy: offsetDy ?? this.offsetDy,
        scale: scale ?? this.scale,
        scrimOpacity: scrimOpacity ?? this.scrimOpacity,
        linkedToPage1: linkedToPage1 ?? this.linkedToPage1,
      );
}

/// Turns the authored scope + whatever per-page specs are actually
/// stored into the concrete spec to render for `pageIndex` out of
/// `pageCount` total pages. This is the ONE place "which pages get the
/// background, and with what image" is decided — callers (A4Paginator)
/// should call this once per page rather than re-deriving the scope
/// logic themselves.
///
/// `page1Spec` is the spec authored for page 1 (always the source of
/// truth for anything linked). `otherPages` holds whatever has been
/// explicitly stored for pages after the first — pages not present in
/// this map fall back to mirroring page1Spec whenever the scope calls
/// for them to have a background at all.
PageBackgroundSpec? resolvePageBackground({
  required PageBackgroundScope scope,
  required int pageIndex,
  required int pageCount,
  required PageBackgroundSpec page1Spec,
  Map<int, PageBackgroundSpec> otherPages = const {},
}) {
  switch (scope) {
    case PageBackgroundScope.none:
      return null;

    case PageBackgroundScope.firstPageOnly:
      return pageIndex == 0 ? page1Spec : null;

    case PageBackgroundScope.allPages:
      if (pageIndex == 0) return page1Spec;
      final stored = otherPages[pageIndex];
      // No independent spec stored yet for this page, OR it's still
      // marked as linked — mirror page 1 live.
      if (stored == null || stored.linkedToPage1) {
        return page1Spec.copyWith(linkedToPage1: true);
      }
      return stored;

    case PageBackgroundScope.custom:
      if (pageIndex == 0) return page1Spec;
      return otherPages[pageIndex];
  }
}
