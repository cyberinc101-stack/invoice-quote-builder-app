// lib/widgets/shared_logo_picker.dart
//
// WIDE LOGO INTERACTIVE PASS (this update): `wide` used to render as a
// completely static image — no drag, no zoom, logoOffset/logoScale
// simply ignored ("there's nothing to crop"). That kept a logo with a
// baked-in wordmark from ever losing text to a crop, but it also meant
// a wide/thin box (letterboxing an image with a different aspect ratio)
// always showed extra empty space with zero way to fill it, and there
// was no way to recentre the artwork if it wasn't drawn dead centre in
// the source file. `wide` now supports drag-to-reposition and zoom
// (pinch, a corner-drag handle, and the slider) in
// _LogoRepositionDialog, plus renders that same offset/scale live in
// SharedLogoThumbnail and SharedLogoPicker's compact box.
//
// The technique is deliberately NOT the same OverflowBox+Transform.
// translate+BoxFit.cover approach circle/square/roundedSquare use (that
// crops-by-default, which is exactly what `wide` exists to avoid).
// Instead it mirrors withOptionalBackgroundImage() in doc_header.dart:
// Transform.scale anchored at `alignment`, wrapping an Image already
// fit via BoxFit.contain at that SAME alignment. At the default
// logoScale == 1.0 / logoOffset == (0,0) — every existing saved wide
// logo — this renders BYTE-IDENTICAL to the old static branch: the
// whole image, uncropped, centred. Only once a person actually drags or
// zooms does anything change: zooming in enlarges the still-fully-
// visible contained image from that alignment point, and the ambient
// ClipRRect/Container clip (already present at every call site) crops
// whatever now overflows the box — a safe "starts fully visible, crop
// in only if you choose to" zoom, instead of crop-by-default.
//
// The corner-drag resize handle is `wide`-only, per what was actually
// asked for — circle/square/roundedSquare keep pinch + slider only,
// completely unchanged. It's a plain onPanUpdate (not onScale*), since
// this dialog always renders at a fixed 1:1 scale with no ancestor
// transform to account for — unlike the live document preview
// elsewhere in the app (see doc_header.dart's _DraggableHeaderLogo and
// its "SCREEN-TO-LOCAL DRAG FIX" comment for why that one needs more
// care).
//
// WIDE FILL-CONTAINER PASS (earlier): the Wide shape's picker box
// used to be capped at height*2.6 (LogoShapeX.boxSizeFor's multiplier)
// regardless of how much width was actually available in the card that
// hosts it — so on the Customise screen's Business Logo card it looked
// like a small rectangle floating in the middle of a much bigger box
// instead of a banner that fills the card. SharedLogoPicker now takes
// an optional `wideWidthOverride`: when the shape is `wide` and a
// caller supplies this (step_customise.dart does, via LayoutBuilder),
// it wins over the multiplier and the box stretches to that width
// instead. Same overflow-safety fix applied to _LogoRepositionDialog's
// own Wide preview, which — being sized off the fixed 240px _viewSize —
// would try to render a 624px-wide box and overflow a normal phone-
// width dialog; it's now wrapped in a LayoutBuilder that clamps the
// preview to whatever width the dialog actually has.
//
// WIDE LOGO SHAPE PASS (earlier): adds a fourth LogoShape — `wide` —
// alongside circle/square/roundedSquare. The three existing shapes all
// crop the uploaded image into a roughly-square box (BoxFit.cover +
// pan/zoom), which works for an icon-only logo but is the wrong
// container for a logo that already has its wordmark baked into the
// same image (e.g. a "mountain icon + Summit Solutions" flattened
// PNG) — cropping that into a square chops off most of the text.
// `wide` renders the full image (see WIDE LOGO INTERACTIVE PASS above
// for how offset/scale now apply on top of that) inside a wider box
// (2.6x as wide as it is tall, via the new LogoShapeX.boxSizeFor
// helper) sized for that kind of logo+text composition.
//
// Every existing shape's behavior/box size is completely unchanged —
// boxSizeFor returns a plain square for circle/square/roundedSquare,
// exactly matching every call site's previous assumption. Only `wide`
// diverges, and only where the caller's box-sizing already routes
// through LogoShape (this file's _logoBox/_LogoRepositionDialog, plus
// doc_header.dart's buildSharedLogo/buildSharedHeaderIdentity on the
// render side).
//
// Shared logo picker + reposition/zoom/shape editor, used identically by
// Quote, Invoice, and Receipt business-profile sheets. Mirrors the pattern
// from cv_edit_section/step_personal_info/profile_photo_widget.dart
// (ProfilePhotoWidget / ImageRepositionDialog), extended with a shape
// selector (circle / square / rounded square / wide) so business logos —
// which are rarely headshots, and sometimes already include their own
// wordmark — aren't forced into a square crop.
//
// Public API (do not change without updating every call site):
//   LogoShape                — enum { circle, square, roundedSquare, wide }
//   logoShapeFromString(s)   — parses persisted 'circle'|'square'|'roundedSquare'|'wide'
//   LogoShape.storageName    — inverse, for toJson()
//   LogoShape.radiusFor(size)— BorderRadius for a box of the given size
//   LogoShape.boxSizeFor(h)  — full Size (width x height) for a box of base
//                              height h — square for every shape except
//                              `wide`, which widens instead
//   SharedLogoPicker         — the tappable picker + "Gallery/Camera/Reposition/
//                              Shape/Remove" bottom sheet
//   SharedLogoThumbnail      — read-only render of a saved logo (card thumbnails)
//
// SharedLogoPicker.compact — when true, renders ONLY the tappable logo box
//   (no inline Gallery/Camera/Reposition/Remove chip row next to it). Tap
//   still opens the full bottom sheet with all four options. Use this in
//   tight header layouts (e.g. saved-document editable canvas screens) where
//   there isn't enough horizontal room for the chip row's Expanded content.
//   Defaults to false, so every existing call site keeps the chip row.
//
// SharedLogoPicker.wideWidthOverride — WIDE FILL-CONTAINER PASS: optional,
//   only used when logoShape is `wide` and compact is true. See the pass
//   comment above and the field's own doc comment below.
//
// FALLBACK MARK SETTINGS PASS (earlier): added four optional params —
// showInitialFallback, onShowInitialFallbackChanged, initialLetterOverride,
// onInitialLetterOverrideChanged. When onShowInitialFallbackChanged is
// provided (opt-in — every existing call site that doesn't pass it renders
// exactly as before), a small settings block appears below the picker
// (full/non-compact mode only): a switch to hide the no-logo rotated-square
// mark ("the blue diamond") entirely, and — while it's on — a one-character
// text field to override which letter it shows instead of always
// auto-deriving the first letter of the business name. These two values are
// meant to be persisted alongside logoPath/logoOffset/logoScale/logoShape on
// whatever business-profile model the caller uses, and ultimately land on
// InvoiceData/QuoteData/ReceiptData's own businessLogoShowInitial/
// businessLogoInitialLetter fields (see those files' doc comments) so
// buildSharedLogo() in doc_header.dart can honour them when rendering every
// template. Note the fallback letter mark always renders as a square
// regardless of the chosen LogoShape (including `wide`) — a single-letter
// mark has no "wide" version; `wide` only changes anything once a real
// image is uploaded.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// =============================================================================
// LogoShape
// =============================================================================

enum LogoShape { circle, square, roundedSquare, wide }

LogoShape logoShapeFromString(String s) {
  switch (s) {
    case 'square':
      return LogoShape.square;
    case 'roundedSquare':
      return LogoShape.roundedSquare;
    case 'wide':
      return LogoShape.wide;
    case 'circle':
    default:
      return LogoShape.circle;
  }
}

extension LogoShapeX on LogoShape {
  String get storageName {
    switch (this) {
      case LogoShape.square:
        return 'square';
      case LogoShape.roundedSquare:
        return 'roundedSquare';
      case LogoShape.circle:
        return 'circle';
      case LogoShape.wide:
        return 'wide';
    }
  }

  BorderRadius radiusFor(double boxSize) {
    switch (this) {
      case LogoShape.circle:
        return BorderRadius.circular(boxSize / 2);
      case LogoShape.square:
        return BorderRadius.zero;
      case LogoShape.roundedSquare:
        return BorderRadius.circular(boxSize * 0.22);
      case LogoShape.wide:
        return BorderRadius.circular(8);
    }
  }

  IconData get icon {
    switch (this) {
      case LogoShape.circle:
        return Icons.circle_outlined;
      case LogoShape.square:
        return Icons.crop_square_rounded;
      case LogoShape.roundedSquare:
        return Icons.crop_7_5_rounded;
      case LogoShape.wide:
        return Icons.crop_16_9_rounded;
    }
  }

  String get label {
    switch (this) {
      case LogoShape.circle:
        return 'Circle';
      case LogoShape.square:
        return 'Square';
      case LogoShape.roundedSquare:
        return 'Rounded';
      case LogoShape.wide:
        return 'Wide';
    }
  }

  bool get isWide => this == LogoShape.wide;

  /// WIDE LOGO SHAPE PASS: the box size a logo of this shape should
  /// render at, given a base "height" (the same single number every
  /// call site already threads through as businessLogoDisplaySize /
  /// boxSize / compactBoxSize / viewSize). Every existing shape stays
  /// a square of that height, unchanged. `wide` keeps the same height
  /// but widens the box (2.6x) — sized for a horizontal icon+wordmark
  /// logo, where the crop shapes are for icon-only logos and `wide` is
  /// for logos that already include their own text and shouldn't be
  /// cropped into a square at all.
  ///
  /// WIDE FILL-CONTAINER PASS: this multiplier is only the FALLBACK
  /// used when a caller has no better width to offer (e.g. the actual
  /// document render in doc_header.dart, where the header row's
  /// available width isn't known to this helper). Callers that do know
  /// their available width — SharedLogoPicker's compact mode, via
  /// wideWidthOverride — bypass this multiplier entirely instead of
  /// going through this getter.
  Size boxSizeFor(double height) =>
      this == LogoShape.wide ? Size(height * 2.6, height) : Size.square(height);
}

// =============================================================================
// SharedLogoThumbnail — read-only, for saved-card thumbnails
// =============================================================================

class SharedLogoThumbnail extends StatelessWidget {
  final String logoPath;
  final Offset logoOffset; // normalised -1…1
  final double logoScale;
  final LogoShape logoShape;
  final double boxSize;

  const SharedLogoThumbnail({
    super.key,
    required this.logoPath,
    required this.logoOffset,
    required this.logoScale,
    required this.logoShape,
    this.boxSize = 40,
  });

  static const double _overScale = 1.35;

  @override
  Widget build(BuildContext context) {
    // WIDE LOGO INTERACTIVE PASS: Transform.scale anchored at
    // `alignment`, wrapping a BoxFit.contain image fit at that SAME
    // alignment. At logoScale 1.0 / logoOffset (0,0) — the default for
    // every logo saved before this pass — this is byte-identical to the
    // old "just show the whole image" branch. The caller (buildSharedLogo
    // in doc_header.dart) already wraps this in a ClipRRect sized to the
    // box, so anything that overflows once zoomed in gets cropped there;
    // no extra clip needed in here.
    if (logoShape == LogoShape.wide) {
      final alignment = Alignment(logoOffset.dx.clamp(-1.0, 1.0), logoOffset.dy.clamp(-1.0, 1.0));
      final clampedScale = logoScale.clamp(1.0, 3.0);
      return Transform.scale(
        scale: clampedScale,
        alignment: alignment,
        child: Image.file(File(logoPath), fit: BoxFit.contain, alignment: alignment),
      );
    }

    final maxTravel = (boxSize * _overScale * logoScale - boxSize) / 2;
    final pixelOffset = Offset(
      logoOffset.dx * maxTravel,
      logoOffset.dy * maxTravel,
    );
    return OverflowBox(
      alignment: Alignment.center,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.translate(
        offset: pixelOffset,
        child: Image.file(
          File(logoPath),
          fit: BoxFit.cover,
          width: boxSize * _overScale * logoScale,
          height: boxSize * _overScale * logoScale,
        ),
      ),
    );
  }
}

// =============================================================================
// SharedLogoPicker
// =============================================================================

class SharedLogoPicker extends StatelessWidget {
  final String? logoPath;
  final Offset logoOffset; // normalised -1…1
  final double logoScale;
  final LogoShape logoShape;
  final Color accent;
  final void Function(String? path, Offset normOffset, double scale, LogoShape shape) onChanged;

  /// When true, renders only the tappable logo box — no inline chip row.
  /// Tap still opens the full bottom sheet (Gallery/Camera/Reposition/Remove).
  /// Use in tight layouts where there's no room for the chip row's Expanded
  /// content (that row needs a bounded parent width to lay out its flex
  /// children).
  final bool compact;

  /// Box HEIGHT in compact mode — the actual rendered box width also
  /// depends on [logoShape] (see LogoShapeX.boxSizeFor: square for
  /// every shape except `wide`, which widens) unless [wideWidthOverride]
  /// is supplied. Ignored when [compact] is false (full mode always uses
  /// its original 90px base height to preserve existing layouts).
  final double compactBoxSize;

  /// WIDE FILL-CONTAINER PASS: optional explicit box WIDTH, used only
  /// when [logoShape] is `wide` and [compact] is true. When supplied,
  /// this wins over LogoShapeX.boxSizeFor's height*2.6 multiplier, so
  /// the wide box can stretch to fill however much horizontal space the
  /// caller actually has (e.g. the full width of a Customise-screen
  /// card, via LayoutBuilder) instead of being capped at a fraction of
  /// it. Left null (the default), every existing call site is
  /// unaffected and wide keeps using the height*2.6 fallback.
  final double? wideWidthOverride;

  // FALLBACK MARK SETTINGS PASS — all four optional and default to the
  // pre-existing behaviour (mark shown, auto-derived letter, no settings
  // UI rendered). Only shown in full (non-compact) mode, and only when
  // onShowInitialFallbackChanged is provided — that's the opt-in signal;
  // a caller that doesn't pass it gets exactly the old picker.
  final bool showInitialFallback;
  final ValueChanged<bool>? onShowInitialFallbackChanged;
  final String initialLetterOverride;
  final ValueChanged<String>? onInitialLetterOverrideChanged;

  const SharedLogoPicker({
    super.key,
    required this.logoPath,
    required this.logoOffset,
    required this.logoScale,
    required this.logoShape,
    required this.accent,
    required this.onChanged,
    this.compact = false,
    this.compactBoxSize = 56.0,
    this.wideWidthOverride,
    this.showInitialFallback = true,
    this.onShowInitialFallbackChanged,
    this.initialLetterOverride = '',
    this.onInitialLetterOverrideChanged,
  });

  bool get _hasLogo =>
      logoPath != null && logoPath!.isNotEmpty && File(logoPath!).existsSync();

  Future<void> _pickImage(BuildContext context, ImageSource src) async {
    final img = await ImagePicker().pickImage(
        source: src, maxWidth: 1024, maxHeight: 1024, imageQuality: 92);
    if (img != null) {
      onChanged(img.path, Offset.zero, 1.0, logoShape);
    }
  }

  Future<void> _openReposition(BuildContext context) async {
    final result = await showDialog<(Offset, double, LogoShape)>(
      context: context,
      builder: (_) => _LogoRepositionDialog(
        imagePath: logoPath!,
        initialNormOffset: logoOffset,
        initialScale: logoScale,
        initialShape: logoShape,
        accent: accent,
      ),
    );
    if (result != null) {
      onChanged(logoPath, result.$1, result.$2, result.$3);
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Business Logo',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).colorScheme.onSurface)),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              color: const Color(0xFF2196F3),
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 50));
                if (!context.mounted) return;
                _pickImage(context, ImageSource.gallery);
              },
            ),
            _OptionTile(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              color: const Color(0xFF4CAF50),
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 50));
                if (!context.mounted) return;
                _pickImage(context, ImageSource.camera);
              },
            ),
            if (_hasLogo) ...[
              _OptionTile(
                icon: Icons.crop_rotate_rounded,
                label: 'Reposition / Zoom / Shape',
                color: const Color(0xFF9C27B0),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 50));
                  if (!context.mounted) return;
                  _openReposition(context);
                },
              ),
              _OptionTile(
                icon: Icons.delete_rounded,
                label: 'Remove',
                color: const Color(0xFFF44336),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(null, Offset.zero, 1.0, logoShape);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _logoBox(BuildContext context, double boxHeight) {
    final colorScheme = Theme.of(context).colorScheme;
    const double overScale = 1.35;
    final isWide = logoShape == LogoShape.wide;
    // WIDE LOGO SHAPE PASS: box size now depends on shape — square for
    // circle/square/roundedSquare (unchanged), wider for `wide`.
    // WIDE FILL-CONTAINER PASS: wideWidthOverride, when supplied for a
    // wide shape, wins over the height*2.6 multiplier so this box can
    // stretch to fill the caller's actual available width.
    final boxSize = (isWide && wideWidthOverride != null)
        ? Size(wideWidthOverride!, boxHeight)
        : logoShape.boxSizeFor(boxHeight);

    final maxTravel = (boxHeight * overScale * logoScale - boxHeight) / 2;
    final pixelOffset = Offset(
      logoOffset.dx * maxTravel,
      logoOffset.dy * maxTravel,
    );

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        width: boxSize.width,
        height: boxSize.height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: logoShape.radiusFor(boxHeight),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: _hasLogo
            ? (isWide
                // WIDE LOGO INTERACTIVE PASS: same Transform.scale +
                // alignment approach as SharedLogoThumbnail's wide
                // branch — safe default (fully visible, uncropped) at
                // logoScale 1.0 / logoOffset (0,0), zoomable/pannable
                // beyond that via the Reposition dialog. The old fixed
                // 8px inset is dropped so this box can use its full
                // area exactly like every other shape now can — the
                // Container above already clips to bounds
                // (clipBehavior: Clip.antiAlias), so nothing bleeds
                // past the border.
                ? Transform.scale(
                    scale: logoScale.clamp(1.0, 3.0),
                    alignment: Alignment(logoOffset.dx.clamp(-1.0, 1.0), logoOffset.dy.clamp(-1.0, 1.0)),
                    child: Image.file(
                      File(logoPath!),
                      fit: BoxFit.contain,
                      alignment: Alignment(logoOffset.dx.clamp(-1.0, 1.0), logoOffset.dy.clamp(-1.0, 1.0)),
                    ),
                  )
                : OverflowBox(
                    alignment: Alignment.center,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Transform.translate(
                      offset: pixelOffset,
                      child: Image.file(
                        File(logoPath!),
                        fit: BoxFit.cover,
                        width: boxHeight * overScale * logoScale,
                        height: boxHeight * overScale * logoScale,
                      ),
                    ),
                  ))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_rounded,
                      size: boxHeight * 0.31, color: accent.withValues(alpha: 0.5)),
                  SizedBox(height: boxHeight * 0.045),
                  Text('Upload',
                      style: TextStyle(
                          fontSize: boxHeight * 0.11,
                          color: accent.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Just the tappable box — no Row, no Expanded chip content, so this
      // has no minimum-width requirement from its parent. Fallback-mark
      // settings are full-mode only (see field doc comment above).
      return _logoBox(context, compactBoxSize);
    }

    const double boxSize = 90.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _logoBox(context, boxSize),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Chip(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        accent: accent,
                        onTap: () => _pickImage(context, ImageSource.gallery),
                      ),
                      _Chip(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        accent: accent,
                        onTap: () => _pickImage(context, ImageSource.camera),
                      ),
                      if (_hasLogo)
                        _Chip(
                          icon: Icons.crop_rotate_rounded,
                          label: 'Reposition',
                          accent: const Color(0xFF9C27B0),
                          onTap: () => _openReposition(context),
                        ),
                      if (_hasLogo)
                        _Chip(
                          icon: Icons.delete_outline_rounded,
                          label: 'Remove',
                          accent: const Color(0xFFF44336),
                          onTap: () => onChanged(null, Offset.zero, 1.0, logoShape),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        // FALLBACK MARK SETTINGS PASS: only rendered when the caller opts
        // in by providing onShowInitialFallbackChanged. Relevant
        // regardless of whether a real logo is currently set, since it
        // controls what shows if the logo is later removed — so it's not
        // gated on _hasLogo.
        if (onShowInitialFallbackChanged != null) ...[
          const SizedBox(height: 16),
          _FallbackMarkSettings(
            accent: accent,
            showInitial: showInitialFallback,
            onShowInitialChanged: onShowInitialFallbackChanged!,
            letterOverride: initialLetterOverride,
            onLetterOverrideChanged: onInitialLetterOverrideChanged,
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// _FallbackMarkSettings — "no logo? show a letter mark" switch + optional
// one-character override field. Lives directly under the logo picker row.
// =============================================================================

class _FallbackMarkSettings extends StatelessWidget {
  final Color accent;
  final bool showInitial;
  final ValueChanged<bool> onShowInitialChanged;
  final String letterOverride;
  final ValueChanged<String>? onLetterOverrideChanged;

  const _FallbackMarkSettings({
    required this.accent,
    required this.showInitial,
    required this.onShowInitialChanged,
    required this.letterOverride,
    required this.onLetterOverrideChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: accent,
            title: Text('Show letter mark when there\'s no logo',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            subtitle: Text(
              'A small colored mark with a letter, shown until a logo is uploaded.',
              style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            value: showInitial,
            onChanged: onShowInitialChanged,
          ),
          if (showInitial && onLetterOverrideChanged != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Letter (optional)',
                        style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.6))),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      initialValue: letterOverride,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [LengthLimitingTextInputFormatter(1)],
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: 'Auto',
                        hintStyle: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.35)),
                        filled: true,
                        fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 1.5)),
                      ),
                      onChanged: onLetterOverrideChanged,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _Chip({required this.icon, required this.label, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      contentPadding: EdgeInsets.zero,
    );
  }
}

// =============================================================================
// _LogoRepositionDialog — drag/pinch to reposition + zoom, plus shape picker
//
// WIDE LOGO INTERACTIVE PASS (this update): `wide` now gets its own
// interactive branch instead of a static, gesture-free preview:
//   - Drag (one finger) or pinch (two fingers) directly on the preview,
//     exactly like every other shape — but driven by `_wideOffset`
//     (already-normalised -1..1, matching Alignment's own coordinate
//     space) and rendered via Transform.scale + BoxFit.contain instead
//     of circle/square/roundedSquare's OverflowBox + BoxFit.cover, so
//     the default (scale 1.0, offset centred) still shows the whole
//     image uncropped — see this file's top-of-file pass comment for
//     why that matters.
//   - A small corner-drag resize handle, bottom-right of the preview,
//     `wide`-only — a single-finger-friendly alternative to pinch. Not
//     added to the other three shapes, which keep pinch + slider only.
//   - The zoom slider + "Reset to centre" row, previously hidden
//     entirely for `wide`, now always shows.
// =============================================================================

class _LogoRepositionDialog extends StatefulWidget {
  final String imagePath;
  final Offset initialNormOffset;
  final double initialScale;
  final LogoShape initialShape;
  final Color accent;

  const _LogoRepositionDialog({
    required this.imagePath,
    required this.initialNormOffset,
    required this.initialScale,
    required this.initialShape,
    required this.accent,
  });

  @override
  State<_LogoRepositionDialog> createState() => _LogoRepositionDialogState();
}

class _LogoRepositionDialogState extends State<_LogoRepositionDialog> {
  static const double _viewSize = 240.0;
  static const double _overScale = 1.35;
  static const double _minScale = 1.0;
  static const double _maxScale = 3.0;

  late double _scale;
  late Offset _pixelOffset;
  // WIDE LOGO INTERACTIVE PASS: wide's own offset, kept separate from
  // _pixelOffset since it's used a completely different way at render
  // time (Alignment for Transform.scale/Image.alignment, not a raw
  // pixel Transform.translate distance). It's already in the same
  // normalised -1..1 format this dialog returns, so — unlike
  // _pixelOffset — no conversion is needed going in or out.
  late Offset _wideOffset;
  late LogoShape _shape;

  Offset? _focalStart;
  Offset? _offsetAtGestureStart;
  Offset? _wideOffsetAtGestureStart;
  double? _scaleAtGestureStart;

  double get _maxTravel => (_viewSize * _overScale * _scale - _viewSize) / 2;

  Offset _clamped(Offset o) {
    final m = _maxTravel;
    return Offset(o.dx.clamp(-m, m), o.dy.clamp(-m, m));
  }

  Offset get _normOffset {
    final m = _maxTravel;
    if (m == 0) return Offset.zero;
    return Offset(_pixelOffset.dx / m, _pixelOffset.dy / m);
  }

  // WIDE LOGO INTERACTIVE PASS: which offset actually gets returned to
  // the caller depends on which shape is currently selected.
  Offset get _effectiveNormOffset => _shape == LogoShape.wide ? _wideOffset : _normOffset;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale.clamp(_minScale, _maxScale);
    _shape = widget.initialShape;
    final storedMaxTravel = (_viewSize * _overScale * _scale - _viewSize) / 2;
    _pixelOffset = _clamped(Offset(
      widget.initialNormOffset.dx * storedMaxTravel,
      widget.initialNormOffset.dy * storedMaxTravel,
    ));
    _wideOffset = Offset(
      widget.initialNormOffset.dx.clamp(-1.0, 1.0),
      widget.initialNormOffset.dy.clamp(-1.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.accent;
    final isWide = _shape == LogoShape.wide;
    // WIDE LOGO SHAPE PASS: preview box widens for `wide`, stays the
    // original square for every other shape. WIDE FILL-CONTAINER PASS:
    // this raw size is clamped against the dialog's actual available
    // width below, inside the LayoutBuilder.
    final previewSize = _shape.boxSizeFor(_viewSize);

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reposition Logo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              // WIDE LOGO INTERACTIVE PASS: copy updated to describe the
              // new drag/pinch/corner-handle/slider capability, while
              // still being clear the image starts fully visible.
              isWide
                  ? 'Starts fully visible, uncropped. Drag or pinch to move and zoom, or drag the corner handle to zoom in and crop closer.'
                  : 'Drag to move · Pinch or use slider to zoom',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, previewConstraints) {
                // WIDE FILL-CONTAINER PASS: clamp the wide box to the
                // width actually available inside the dialog (this
                // Padding already accounted for by LayoutBuilder here)
                // so it can never overflow — same fix philosophy as the
                // compact picker box, applied where a fixed multiplier
                // could otherwise exceed a fixed dialog width.
                final clampedPreviewSize = isWide
                    ? Size(previewSize.width.clamp(0.0, previewConstraints.maxWidth), previewSize.height)
                    : previewSize;
                final wideAlignment = Alignment(_wideOffset.dx, _wideOffset.dy);

                final previewContent = ClipRRect(
                  borderRadius: _shape.radiusFor(_viewSize),
                  child: SizedBox(
                    width: clampedPreviewSize.width,
                    height: clampedPreviewSize.height,
                    child: isWide
                        // WIDE LOGO INTERACTIVE PASS: real drag + pinch,
                        // driven by _wideOffset/_scale, rendered via
                        // Transform.scale + BoxFit.contain (see this
                        // file's top pass comment for why this — not
                        // OverflowBox + cover — is the right approach
                        // for a shape that must never crop by default).
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: (d) {
                              _focalStart = d.localFocalPoint;
                              _wideOffsetAtGestureStart = _wideOffset;
                              _scaleAtGestureStart = _scale;
                            },
                            onScaleUpdate: (d) {
                              if (_focalStart == null) return;
                              final newScale = (_scaleAtGestureStart! * d.scale).clamp(_minScale, _maxScale);
                              final delta = d.localFocalPoint - _focalStart!;
                              final halfW = clampedPreviewSize.width / 2;
                              final halfH = clampedPreviewSize.height / 2;
                              setState(() {
                                _scale = newScale;
                                _wideOffset = Offset(
                                  (_wideOffsetAtGestureStart!.dx + delta.dx / (halfW * newScale)).clamp(-1.0, 1.0),
                                  (_wideOffsetAtGestureStart!.dy + delta.dy / (halfH * newScale)).clamp(-1.0, 1.0),
                                );
                              });
                            },
                            onScaleEnd: (_) {
                              _focalStart = null;
                              _wideOffsetAtGestureStart = null;
                              _scaleAtGestureStart = null;
                            },
                            child: Transform.scale(
                              scale: _scale,
                              alignment: wideAlignment,
                              child: Image.file(File(widget.imagePath), fit: BoxFit.contain, alignment: wideAlignment),
                            ),
                          )
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: (d) {
                              _focalStart = d.localFocalPoint;
                              _offsetAtGestureStart = _pixelOffset;
                              _scaleAtGestureStart = _scale;
                            },
                            onScaleUpdate: (d) {
                              if (_focalStart == null) return;
                              final newScale = (_scaleAtGestureStart! * d.scale).clamp(_minScale, _maxScale);
                              final delta = d.localFocalPoint - _focalStart!;
                              setState(() {
                                _scale = newScale;
                                _pixelOffset = _clamped(_offsetAtGestureStart! + delta);
                              });
                            },
                            onScaleEnd: (_) {
                              _focalStart = null;
                              _offsetAtGestureStart = null;
                              _scaleAtGestureStart = null;
                            },
                            child: OverflowBox(
                              alignment: Alignment.center,
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: Transform.translate(
                                offset: _pixelOffset,
                                child: Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.cover,
                                  width: _viewSize * _overScale * _scale,
                                  height: _viewSize * _overScale * _scale,
                                ),
                              ),
                            ),
                          ),
                  ),
                );

                if (!isWide) return previewContent;

                // WIDE LOGO INTERACTIVE PASS: corner resize handle, sat
                // OUTSIDE the ClipRRect above (via this outer
                // clipBehavior: Clip.none Stack) so the handle itself
                // isn't clipped away by the preview's own rounded-box
                // clip.
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    previewContent,
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          // Plain per-frame delta is fine here — this
                          // dialog always renders at a fixed 1:1 scale,
                          // unlike the live document preview elsewhere
                          // (see doc_header.dart's _DraggableHeaderLogo)
                          // which needs a global-to-local conversion
                          // because of an ancestor zoom transform.
                          final avgDelta = (d.delta.dx + d.delta.dy) / 2;
                          setState(() {
                            _scale = (_scale + avgDelta / _viewSize).clamp(_minScale, _maxScale);
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: const Icon(Icons.open_in_full_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Shape selector — Wrap instead of a plain Row so the fourth
            // ("Wide") chip doesn't force a horizontal overflow in the
            // dialog's fixed width.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: LogoShape.values.map((s) {
                final selected = s == _shape;
                return GestureDetector(
                  onTap: () => setState(() => _shape = s),
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
            const SizedBox(height: 16),

            // WIDE LOGO INTERACTIVE PASS: zoom slider + reset now show
            // for every shape, `wide` included — previously hidden
            // entirely for `wide` since it had nothing to zoom/reset.
            Row(
              children: [
                Icon(Icons.zoom_out_rounded, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accent,
                      inactiveTrackColor: accent.withValues(alpha: 0.2),
                      thumbColor: accent,
                      overlayColor: accent.withValues(alpha: 0.12),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: _scale,
                      min: _minScale,
                      max: _maxScale,
                      onChanged: (v) => setState(() {
                        _scale = v;
                        _pixelOffset = _clamped(_pixelOffset);
                      }),
                    ),
                  ),
                ),
                Icon(Icons.zoom_in_rounded, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
            Text(
              '${(_scale * 100).round()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 4),

            TextButton.icon(
              onPressed: () => setState(() {
                _scale = 1.0;
                _pixelOffset = Offset.zero;
                _wideOffset = Offset.zero;
              }),
              icon: Icon(Icons.center_focus_strong_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.45)),
              label: Text('Reset to centre',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45))),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.45))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, (_effectiveNormOffset, _scale, _shape)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}