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

import 'package:flutter/material.dart';

class BackgroundSpec {
  final String? imagePath;
  final bool enabled;

  /// 0.0 = fully hidden (byte-for-byte identical to no background at
  /// all — see the OPACITY-ZERO FIX note on background_render.dart's
  /// renderBackground for why this matters), 1.0 = fully visible.
  final double opacity;

  /// Normalised -1..1, matching Alignment's own coordinate space.
  final double offsetDx;
  final double offsetDy;

  /// 1.0..3.0 for BoxFit.cover (crop-to-fill); ignored for
  /// BoxFit.contain (fit shows the whole image, nothing to zoom past
  /// what's needed to fit the box).
  final double scale;

  /// BoxFit.cover crops to fill the band edge-to-edge (used by footer
  /// and body, where "no empty space" matters more than "show the
  /// whole image"). BoxFit.contain shows the entire image, letterboxed
  /// (used by header, per the FULL-IMAGE HEADER PASS — cropping was
  /// hiding parts of an uploaded logo/banner image).
  final BoxFit fit;

  /// The translucent white wash drawn between the image and the
  /// content on top of it, so existing dark text stays legible without
  /// needing a color picker. 0.0 = no scrim at all (image at full
  /// strength); higher = more washed-out. Callers that DO provide an
  /// explicit ContentColorSpec (see content_color_spec.dart) for their
  /// text can reasonably pass a lower scrim, since the text itself is
  /// now guaranteed legible by color choice rather than by washing out
  /// the image underneath it.
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

  /// True only when there's actually something to draw — enabled and a
  /// non-empty path. Every render site should gate on this (or let
  /// renderBackground's own internal check do it) rather than
  /// re-deriving the same condition themselves.
  ///
  /// OPACITY-AS-FADE PASS: no longer includes an `opacity > 0.0`
  /// clause — see that pass's note on `opacity`'s doc comment above
  /// for why opacity 0 is now a valid, FULLY VISIBLE state (raw image,
  /// no scrim) rather than a hidden one. The old `opacity > 0.0`
  /// bypass was written back when opacity meant "image visibility";
  /// keeping it after the meaning flipped would have made opacity 0
  /// hide the background entirely again — the opposite of the fix.
  bool get hasVisibleImage => enabled && (imagePath?.isNotEmpty ?? false);

  Alignment get alignment =>
      Alignment(offsetDx.clamp(-1.0, 1.0), offsetDy.clamp(-1.0, 1.0));

  double get clampedOpacity => opacity.clamp(0.0, 1.0);

  /// BoxFit.cover's scale is meaningful (1..3, zoom past fill);
  /// BoxFit.contain has nothing to zoom past fitting the box, so this
  /// clamp only matters for cover.
  double get clampedScale => scale.clamp(1.0, 3.0);

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