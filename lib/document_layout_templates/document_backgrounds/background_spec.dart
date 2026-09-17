// background_spec.dart
// lib/document_layout_templates/document_backgrounds/background_spec.dart
//
// DOCUMENT BACKGROUNDS FOUNDATION PASS: this is the root cause fix for
// why header/footer/mid-page background bugs kept reappearing in
// different places after being "fixed" once — the same 6 loose
// parameters (imagePath, enabled, opacity, offsetDx, offsetDy, scale)
// were copy-pasted as individual function arguments across THREE
// different files (doc_header.dart's withOptionalBackgroundImage,
// executive_template.dart's _fullBleedHeaderBackground,
// a4_paginator.dart's body-background wiring), each with its own
// slightly different bleed/clip/opacity logic. Fixing one never fixed
// the other two. BackgroundSpec bundles all of it into one immutable
// value so every render site consumes the EXACT same shape, and
// background_render.dart (the other new file in this folder) is the
// ONE place that actually draws it — header/footer/body all call the
// same function now instead of reimplementing it.
//
// EXISTS-CHECK RESTORATION FIX (this update): hasVisibleImage below now
// also requires File(imagePath).existsSync() — see that getter's own
// doc comment for why this was missing and what it fixes. Confirmed via
// a full read-through of every background render/preview call site
// (executive_template.dart's header path, a4_paginator.dart's body
// path, and customise_background_section.dart's thumbnail preview,
// which has its own separate inline existence handling via Image.file
// directly rather than going through this spec) that this is the only
// place the check needed restoring.

import 'dart:io';
import 'package:flutter/material.dart';

// ZOOM-OUT RANGE PASS (this update): the floor a person can zoom a
// background image OUT to — letting BoxFit.cover's normally-covering
// image shrink below "just barely fills the box", revealing background
// around it, instead of only ever being able to zoom IN past fill.
// Matches the same floor already used for the header logo's own
// freeform zoom (kHeaderLogoFreeformMinScale in doc_header.dart). Lives
// here (the data/spec layer), not in the screens file that uses it to
// build its slider — same relationship that logo constant has to
// doc_header.dart rather than step_customise.dart — so this is the ONE
// place BackgroundSpec.clampedScale (the render-time clamp, below) and
// any UI control reading/writing a scale value both pull this floor
// from. Before this pass, the reposition dialog had its own separate
// 1.0 floor and this getter had ITS OWN separate 1.0 floor — raising
// the dialog's alone (as an earlier pass did) let a person drag the
// slider below 100%, but this getter silently re-clamped that value
// back up to 1.0 the moment it reached the real document, so the
// zoomed-out choice never actually showed up on the invoice. Both now
// read from this single constant so they can't drift apart again.
const double kBackgroundMinZoomOutScale = 0.4;

class BackgroundSpec {
  final String? imagePath;
  final bool enabled;

  /// OPACITY-INVERSION FIX: this no longer controls the image's own
  /// visibility — the image always renders at full strength (see
  /// background_render.dart's renderDocumentBackground). Instead this
  /// scales how much of `scrimOpacity` is actually applied: 0.0 = none
  /// of it (raw, undimmed image), 1.0 = the full scrimOpacity value.
  /// This is what makes the slider read correctly as a "fade/wash"
  /// control — turning it up washes the photo out more, rather than
  /// (the old, backwards behaviour) fading the image itself in from
  /// invisible while a fixed-strength wash sat on top regardless.
  final double opacity;

  /// Normalised -1..1, matching Alignment's own coordinate space.
  final double offsetDx;
  final double offsetDy;

  /// ZOOM-OUT RANGE PASS: kBackgroundMinZoomOutScale (0.4) .. 3.0 for
  /// BoxFit.cover (below 1.0 zooms OUT past "just covers the box",
  /// revealing background around the image; above 1.0 zooms IN,
  /// cropping tighter). Ignored for BoxFit.contain (fit already shows
  /// the whole image, nothing to zoom past what's needed to fit the
  /// box).
  final double scale;

  /// BoxFit.cover crops to fill the band edge-to-edge (used by footer,
  /// body, and — since the BANNER-SHAPE LOCK / COVER-FIT FIX in
  /// executive_template.dart — header too, so the header's real render
  /// always matches its own editing thumbnail rather than letterboxing
  /// against the fixed banner shape). BoxFit.contain shows the entire
  /// image without cropping, letterboxed, for any call site that still
  /// wants that instead.
  final BoxFit fit;

  /// The BASE translucent white wash drawn between the image and the
  /// content on top of it, so existing dark text stays legible without
  /// needing a color picker. This is the wash strength at `opacity ==
  /// 1.0` — the actual applied strength is `scrimOpacity * opacity`
  /// (see OPACITY-INVERSION FIX above), so at opacity 0 the wash is
  /// zero regardless of this value. Callers that DO provide an
  /// explicit ContentColorSpec (see content_color_spec.dart) for their
  /// text can reasonably pass a lower base scrim, since the text
  /// itself is now guaranteed legible by color choice rather than by
  /// washing out the image underneath it.
  final double scrimOpacity;

  const BackgroundSpec({
    this.imagePath,
    this.enabled = false,
    this.opacity = 1.0,
    this.offsetDx = 0.0,
    this.offsetDy = 0.0,
    this.scale = 1.0,
    this.fit = BoxFit.cover,
    this.scrimOpacity = 0.82,
  });

  /// True whenever there's actually an image to draw — enabled AND a
  /// non-empty path AND the file still exists on disk.
  ///
  /// OPACITY-INVERSION FIX: this no longer requires opacity > 0 —
  /// opacity 0 is now a normal, VISIBLE state (raw, undimmed image, no
  /// wash), not a hidden one.
  ///
  /// EXISTS-CHECK RESTORATION FIX: the original withOptionalBackgroundImage
  /// this spec replaced (formerly in doc_header.dart, now deleted —
  /// see that file's own note) always checked
  /// File(imagePath).existsSync() before treating an image as visible.
  /// That check was dropped when this class was first written, which
  /// meant `enabled: true` with a stale or deleted path (e.g. left over
  /// from before the Header/Footer Background cards were hidden from
  /// the Customise UI, or a file the user removed outside the app)
  /// would still be treated as "has a visible image", reach
  /// background_render.dart's Image.file(), and paint Flutter's
  /// broken-image error box instead of silently falling back to
  /// `child` the way every other "no background" state does. Restored
  /// here so every render site (header/footer/body, all of which read
  /// this getter rather than re-deriving the condition themselves)
  /// gets the fix in one place.
  ///
  /// Every render site should gate on this (or let
  /// renderDocumentBackground's own internal check do it) rather than
  /// re-deriving the same condition themselves.
  bool get hasVisibleImage =>
      enabled &&
      (imagePath?.isNotEmpty ?? false) &&
      File(imagePath!).existsSync();

  Alignment get alignment =>
      Alignment(offsetDx.clamp(-1.0, 1.0), offsetDy.clamp(-1.0, 1.0));

  double get clampedOpacity => opacity.clamp(0.0, 1.0);

  /// ZOOM-OUT RANGE PASS: floor widened from 1.0 to
  /// kBackgroundMinZoomOutScale — this is the getter background_render
  /// .dart's _imageScrimStack actually reads at render time, so this is
  /// the fix that makes a zoomed-out value chosen in the reposition
  /// dialog actually show up on the real document, instead of being
  /// silently pulled back up to 100% here. BoxFit.cover's scale is
  /// meaningful across this whole range; BoxFit.contain has nothing to
  /// zoom past fitting the box, so this clamp only matters for cover.
  double get clampedScale => scale.clamp(kBackgroundMinZoomOutScale, 3.0);

  BackgroundSpec copyWith({
    String? imagePath,
    bool clearImagePath = false,
    bool? enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
    BoxFit? fit,
    double? scrimOpacity,
  }) =>
      BackgroundSpec(
        imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
        enabled: enabled ?? this.enabled,
        opacity: opacity ?? this.opacity,
        offsetDx: offsetDx ?? this.offsetDx,
        offsetDy: offsetDy ?? this.offsetDy,
        scale: scale ?? this.scale,
        fit: fit ?? this.fit,
        scrimOpacity: scrimOpacity ?? this.scrimOpacity,
      );

  /// Convenience for call sites that currently hold the six loose
  /// fields (every InvoiceData.header/footer/bodyBackground* group) and
  /// want to build a spec without a big constructor call at each site.
  factory BackgroundSpec.fromFields({
    required String? imagePath,
    required bool enabled,
    required double opacity,
    required double offsetDx,
    required double offsetDy,
    required double scale,
    BoxFit fit = BoxFit.cover,
    double scrimOpacity = 0.82,
  }) =>
      BackgroundSpec(
        imagePath: imagePath,
        enabled: enabled,
        opacity: opacity,
        offsetDx: offsetDx,
        offsetDy: offsetDy,
        scale: scale,
        fit: fit,
        scrimOpacity: scrimOpacity,
      );
}