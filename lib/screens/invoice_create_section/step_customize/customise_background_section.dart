// customise_background_section.dart
// lib/screens/invoice_create_section/step_customize/customise_background_section.dart
//
// FILE-SPLIT PASS: pulled out of the former monolithic step_customise.dart
// (was `_BackgroundImageSection` / `_BackgroundImageTarget` /
// `_BackgroundRepositionDialog`). The target enum is now public
// (`BackgroundImageTarget`) since step_customise.dart constructs this
// widget three times (header/mid-page/footer) from the shell file. The
// dialog stays private to this file — nothing outside it needs to
// reference the dialog class directly. Behavior unchanged from the
// original file.
//
// ZOOM-OUT RANGE PASS (this update): the reposition dialog's zoom floor
// (_minScale below) is lowered from 1.0 to kBackgroundMinZoomOutScale
// (imported from background_spec.dart — the same constant
// BackgroundSpec.clampedScale itself now uses as its render-time floor,
// so the dialog and the real document can't drift to different ranges
// again), so a person can zoom OUT past "just barely covers the box" to
// reveal more of the image (with background showing around it), not
// just zoom in. The thumbnail preview's own hardcoded .clamp(1.0, 3.0)
// calls are widened to match, so what's shown while editing doesn't
// clip a value the dialog itself now allows.

// BANNER-SHAPE LOCK PASS (earlier): the header target's reposition-
// dialog preview box used to be a hardcoded 280×110 (≈2.55:1) — which
// doesn't match the header's real rendered banner shape of
// kPageW × kHeaderBackgroundBandHeight (595×130, ≈4.58:1, exported as
// kHeaderBannerAspectRatio from executive_template.dart, the actual
// header background call site). That mismatch meant what a person
// framed/cropped in this dialog wasn't what they'd actually get on the
// document — a wider, shorter band than the preview suggested. Fixed by
// deriving the header preview height from the same real ratio instead of
// a second, independently-guessed number. Combined with the
// BoxFit.contain → BoxFit.cover fix in executive_template.dart (this
// dialog's crop math already assumed cover-style fill/crop — see
// _maxTravelX/Y below — it just wasn't connected to a render path that
// used it), this dialog's drag/zoom now matches the live document
// exactly. Footer and mid-page targets are unchanged — this pass only
// touches the header preview box, since only the header currently has a
// confirmed fixed band height to lock against.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/invoice_provider.dart';
import '../../../models/invoice_data.dart';
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show kHeaderBannerAspectRatio;
import '../../../document_layout_templates/document_backgrounds/background_spec.dart'
    show kBackgroundMinZoomOutScale;
import 'customise_shared_widgets.dart';

// =============================================================================
// BACKGROUND-IMAGE PASS — header/footer/mid-page background image section
//
// One card, reused for header/mid-page/footer via the `target` param.
// Shows a thumbnail preview (or an empty state), an Upload/Change button,
// a Remove button (only once an image is set), and the on/off switch that
// actually controls whether it renders on the document — matching the
// existing "toggle exists independently of whether content is set"
// pattern already used for Business Tagline/Footer Taglines elsewhere.
//
// Uses image_picker (already a transitive dependency via the logo/
// signature pickers elsewhere in this app) to grab a gallery image.
// The picked file's path is stored as-is, same as
// SavedInvoiceDraft.logoPath and other image-path fields on this model.
//
// COLLAPSIBLE SECTIONS PASS (earlier): each of the three cards built
// from this widget (Header/Mid-Page/Footer) is collapsible, with its own
// persisted expand state keyed by `_sectionKey` below, so collapsing one
// doesn't affect the others.
// =============================================================================

enum BackgroundImageTarget { header, body, footer }

class BackgroundImageSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final BackgroundImageTarget target;

  const BackgroundImageSection({
    super.key,
    required this.title,
    required this.icon,
    required this.target,
  });

  // COLLAPSIBLE SECTIONS PASS: unique persistence key per target so
  // Header/Mid-Page/Footer each remember their own collapsed state
  // independently of one another.
  String get _sectionKey => switch (target) {
        BackgroundImageTarget.header => 'header_background',
        BackgroundImageTarget.body => 'mid_background',
        BackgroundImageTarget.footer => 'footer_background',
      };

  String? _pathOf(InvoiceData data) => switch (target) {
        BackgroundImageTarget.header => data.headerBackgroundImagePath,
        BackgroundImageTarget.body => data.bodyBackgroundImagePath,
        BackgroundImageTarget.footer => data.footerBackgroundImagePath,
      };

  bool _enabledOf(InvoiceData data) => switch (target) {
        BackgroundImageTarget.header => data.headerBackgroundEnabled,
        BackgroundImageTarget.body => data.bodyBackgroundEnabled,
        BackgroundImageTarget.footer => data.footerBackgroundEnabled,
      };

  // REPOSITION/OPACITY PASS: opacity/offset/scale getters, mirroring
  // _pathOf/_enabledOf's switch-per-target shape.
  double _opacityOf(InvoiceData data) => switch (target) {
        BackgroundImageTarget.header => data.headerBackgroundOpacity,
        BackgroundImageTarget.body => data.bodyBackgroundOpacity,
        BackgroundImageTarget.footer => data.footerBackgroundOpacity,
      };

  double _offsetDxOf(InvoiceData data) => switch (target) {
        BackgroundImageTarget.header => data.headerBackgroundOffsetDx,
        BackgroundImageTarget.body => data.bodyBackgroundOffsetDx,
        BackgroundImageTarget.footer => data.footerBackgroundOffsetDx,
      };

  double _offsetDyOf(InvoiceData data) => switch (target) {
        BackgroundImageTarget.header => data.headerBackgroundOffsetDy,
        BackgroundImageTarget.body => data.bodyBackgroundOffsetDy,
        BackgroundImageTarget.footer => data.footerBackgroundOffsetDy,
      };

  double _scaleOf(InvoiceData data) => switch (target) {
        BackgroundImageTarget.header => data.headerBackgroundScale,
        BackgroundImageTarget.body => data.bodyBackgroundScale,
        BackgroundImageTarget.footer => data.footerBackgroundScale,
      };

  void _apply(
    InvoiceProvider provider, {
    String? path,
    required bool enabled,
    double? opacity,
    double? offsetDx,
    double? offsetDy,
    double? scale,
  }) {
    switch (target) {
      case BackgroundImageTarget.header:
        provider.updateHeaderBackgroundImage(
            path: path, enabled: enabled, opacity: opacity, offsetDx: offsetDx, offsetDy: offsetDy, scale: scale);
      case BackgroundImageTarget.body:
        provider.updateBodyBackgroundImage(
            path: path, enabled: enabled, opacity: opacity, offsetDx: offsetDx, offsetDy: offsetDy, scale: scale);
      case BackgroundImageTarget.footer:
        provider.updateFooterBackgroundImage(
            path: path, enabled: enabled, opacity: opacity, offsetDx: offsetDx, offsetDy: offsetDy, scale: scale);
    }
  }

  Future<void> _pickImage(BuildContext context, InvoiceProvider provider, bool currentEnabled) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      // Picking an image is a strong signal the person wants it showing —
      // turn the switch on at the same time, same as the logo picker's
      // own "setting a logo doesn't require a separate on/off step".
      // Also resets opacity/offset/scale to their defaults for a fresh
      // image — a leftover pan/zoom from a previous image wouldn't mean
      // anything on a brand new one.
      _apply(provider, path: picked.path, enabled: true, opacity: 1.0, offsetDx: 0.0, offsetDy: 0.0, scale: 1.0);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open the image picker: $e")),
        );
      }
    }
  }

  // REPOSITION/OPACITY PASS: opens the shared reposition dialog, sized
  // to roughly the real proportions of each target — header/footer are
  // wide and short, the mid-page body is closer to a tall panel — so
  // the drag/zoom preview feels representative of where the image will
  // actually land, even though the underlying stored values are
  // resolution-independent (normalised -1..1 offset, matching
  // Alignment's own coordinate space) and get reapplied correctly to
  // whatever the real box size turns out to be at render time (see
  // background_render.dart's renderDocumentBackground).
  //
  // BANNER-SHAPE LOCK PASS: the header preview box is now derived from
  // kHeaderBannerAspectRatio (the header's real, locked
  // kPageW × kHeaderBackgroundBandHeight shape, exported from
  // executive_template.dart) instead of a separately-guessed 280×110 —
  // see this file's header comment for why that mismatch mattered.
  // Footer/body keep their previous approximate proportions.
  Future<void> _openReposition(BuildContext context, InvoiceProvider provider, String path, InvoiceData data) async {
    final (previewW, previewH) = switch (target) {
      BackgroundImageTarget.header => (280.0, 280.0 / kHeaderBannerAspectRatio),
      BackgroundImageTarget.footer => (280.0, 100.0),
      BackgroundImageTarget.body => (240.0, 300.0),
    };
    final accent = colorForScheme(data.colorScheme);
    final result = await showDialog<(Offset, double)>(
      context: context,
      builder: (_) => _BackgroundRepositionDialog(
        imagePath: path,
        initialAlignment: Offset(_offsetDxOf(data), _offsetDyOf(data)),
        initialScale: _scaleOf(data),
        accent: accent,
        previewWidth: previewW,
        previewHeight: previewH,
      ),
    );
    if (result != null) {
      _apply(provider, path: path, enabled: true, offsetDx: result.$1.dx, offsetDy: result.$1.dy, scale: result.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final data = provider.invoiceData;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorForScheme(data.colorScheme);
    final path = _pathOf(data);
    final hasImage = path != null && path.isNotEmpty;
    final enabled = _enabledOf(data);
    final opacity = _opacityOf(data);

    // REPOSITION/OVERFLOW PASS: the thumbnail preview here is wrapped in
    // ClipRRect matching the container's own rounded corners — same
    // containment principle as the real render's ClipRect in
    // renderDocumentBackground — so this preview can never visually
    // bleed past its box either, consistent with the actual document.
    return SectionCard(
      icon: icon,
      title: title,
      sectionKey: _sectionKey,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImage(context, provider, enabled),
            child: Container(
              height: 90,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _scaleOf(data).clamp(kBackgroundMinZoomOutScale, 3.0),
                            alignment: Alignment(_offsetDxOf(data).clamp(-1.0, 1.0), _offsetDyOf(data).clamp(-1.0, 1.0)),
                            child: Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              alignment: Alignment(_offsetDxOf(data).clamp(-1.0, 1.0), _offsetDyOf(data).clamp(-1.0, 1.0)),
                            ),
                          ),
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.15)),
                        const Center(
                          child: Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 24, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(height: 4),
                          Text('Tap to upload an image',
                              style: TextStyle(fontSize: 11.5,
                                  color: colorScheme.onSurface.withValues(alpha: 0.45))),
                        ],
                      ),
                    ),
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openReposition(context, provider, path, data),
                icon: Icon(Icons.crop_rotate_rounded, size: 16, color: accent),
                label: Text('Reposition / Zoom', style: TextStyle(color: accent, fontSize: 12.5)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              ),
            ),
            const SizedBox(height: 6),
            // REPOSITION/OPACITY PASS: opacity slider — a separate,
            // simpler control from the reposition dialog's pan/zoom, same
            // relationship "Logo Size" has to the logo's own Reposition
            // dialog elsewhere in this screen.
            Row(
              children: [
                Icon(Icons.opacity_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 6),
                Text('Opacity', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.55))),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accent,
                      inactiveTrackColor: accent.withValues(alpha: 0.2),
                      thumbColor: accent,
                      overlayColor: accent.withValues(alpha: 0.15),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: opacity.clamp(0.0, 1.0),
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => _apply(provider, path: path, enabled: enabled, opacity: v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text('${(opacity.clamp(0.0, 1.0) * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasImage ? 'Show this background on the document' : 'Add an image to enable',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: hasImage
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Switch(
                value: enabled && hasImage,
                activeThumbColor: accent,
                onChanged: hasImage ? (v) => _apply(provider, path: path, enabled: v) : null,
              ),
            ],
          ),
          if (hasImage) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _apply(provider, path: null, enabled: false, opacity: 1.0, offsetDx: 0.0, offsetDy: 0.0, scale: 1.0),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                label: const Text('Remove image', style: TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// REPOSITION/OPACITY PASS — _BackgroundRepositionDialog
//
// Drag-to-move + pinch/slider-to-zoom, matching shared_logo_picker.dart's
// _LogoRepositionDialog exactly in interaction and math — same
// OverflowBox + Transform.translate + clamped-pixel-travel technique,
// same onScaleStart/onScaleUpdate/onScaleEnd gesture handling, same
// "Reset to centre" affordance. The only real difference is the preview
// box is a caller-supplied WIDTH × HEIGHT rectangle instead of a fixed
// square (backgrounds aren't square logo crops), so maxTravel is
// computed per-axis instead of once for both. Returns
// (normalisedOffset, scale) on Apply — normalisedOffset is exactly the
// Alignment(-1..1, -1..1) coordinate space the real render (BoxFit.cover,
// see executive_template.dart / background_render.dart) expects, so the
// result can be stored and reapplied at render time with no further
// conversion. BANNER-SHAPE LOCK PASS: for the header target this box is
// now sized to the true kHeaderBannerAspectRatio (see _openReposition
// above), so this dialog's own cover-style crop math already lines up
// exactly with what the document renders — no separate aspect-lock logic
// needed here beyond passing in the right box size.
// =============================================================================

class _BackgroundRepositionDialog extends StatefulWidget {
  final String imagePath;
  final Offset initialAlignment;
  final double initialScale;
  final Color accent;
  final double previewWidth;
  final double previewHeight;

  const _BackgroundRepositionDialog({
    required this.imagePath,
    required this.initialAlignment,
    required this.initialScale,
    required this.accent,
    required this.previewWidth,
    required this.previewHeight,
  });

  @override
  State<_BackgroundRepositionDialog> createState() => _BackgroundRepositionDialogState();
}

class _BackgroundRepositionDialogState extends State<_BackgroundRepositionDialog> {
  static const double _overScale = 1.35;
  // ZOOM-OUT RANGE PASS: was 1.0 — see this file's header comment for
  // why 0.4 (kBackgroundMinZoomOutScale) lets a person zoom out past
  // "just covers the box" instead of only ever zooming in.
  static const double _minScale = kBackgroundMinZoomOutScale;
  static const double _maxScale = 3.0;

  late double _scale;
  late Offset _pixelOffset;

  Offset? _focalStart;
  Offset? _offsetAtGestureStart;
  double? _scaleAtGestureStart;

  // ZOOM-OUT RANGE PASS: at scale below ~1/_overScale (≈0.74), the
  // zoomed image is now SMALLER than the preview box, not larger — the
  // old formula went negative there, which broke Offset.clamp (min >
  // max). Floored at 0: below that point there's no overflow to pan
  // through, so travel range is correctly zero and the image just sits
  // centred (still draggable back in once zoomed past the floor again).
  double get _maxTravelX =>
      ((widget.previewWidth * _overScale * _scale - widget.previewWidth) / 2).clamp(0.0, double.infinity);
  double get _maxTravelY =>
      ((widget.previewHeight * _overScale * _scale - widget.previewHeight) / 2).clamp(0.0, double.infinity);

  Offset _clamped(Offset o) {
    final mx = _maxTravelX;
    final my = _maxTravelY;
    return Offset(o.dx.clamp(-mx, mx), o.dy.clamp(-my, my));
  }

  Offset get _normOffset {
    final mx = _maxTravelX;
    final my = _maxTravelY;
    return Offset(mx == 0 ? 0.0 : _pixelOffset.dx / mx, my == 0 ? 0.0 : _pixelOffset.dy / my);
  }

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale.clamp(_minScale, _maxScale);
    final mx0 = (widget.previewWidth * _overScale * _scale - widget.previewWidth) / 2;
    final my0 = (widget.previewHeight * _overScale * _scale - widget.previewHeight) / 2;
    _pixelOffset = _clamped(Offset(
      widget.initialAlignment.dx * mx0,
      widget.initialAlignment.dy * my0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.accent;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reposition Background',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              'Drag to move · Pinch or use slider to zoom',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // OVERFLOW FIX: ClipRect here mirrors the real render's
            // containment — the preview can't bleed past this box
            // either, same as the actual render's own ClipRect at
            // render time (renderDocumentBackground's _imageScrimStack).
            ClipRect(
              child: Container(
                width: widget.previewWidth,
                height: widget.previewHeight,
                decoration: BoxDecoration(border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3))),
                child: GestureDetector(
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
                        width: widget.previewWidth * _overScale * _scale,
                        height: widget.previewHeight * _overScale * _scale,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                    onPressed: () => Navigator.pop(context, (_normOffset, _scale)),
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
