// lib/widgets/shared_logo_picker.dart
//
// Shared logo picker + reposition/zoom/shape editor, used identically by
// Quote, Invoice, and Receipt business-profile sheets. Mirrors the pattern
// from cv_edit_section/step_personal_info/profile_photo_widget.dart
// (ProfilePhotoWidget / ImageRepositionDialog), extended with a shape
// selector (circle / square / rounded square) so business logos — which
// are rarely headshots — aren't forced into a circular crop.
//
// Public API (do not change without updating every call site):
//   LogoShape                — enum { circle, square, roundedSquare }
//   logoShapeFromString(s)   — parses persisted 'circle'|'square'|'roundedSquare'
//   LogoShape.storageName    — inverse, for toJson()
//   LogoShape.radiusFor(size)— BorderRadius for a box of the given size
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// =============================================================================
// LogoShape
// =============================================================================

enum LogoShape { circle, square, roundedSquare }

LogoShape logoShapeFromString(String s) {
  switch (s) {
    case 'square':
      return LogoShape.square;
    case 'roundedSquare':
      return LogoShape.roundedSquare;
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
    }
  }
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

  /// Box size in compact mode. Ignored when [compact] is false (full mode
  /// always uses its original 90px box to preserve existing layouts).
  final double compactBoxSize;

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

  Widget _logoBox(BuildContext context, double boxSize) {
    final colorScheme = Theme.of(context).colorScheme;
    const double overScale = 1.35;

    final maxTravel = (boxSize * overScale * logoScale - boxSize) / 2;
    final pixelOffset = Offset(
      logoOffset.dx * maxTravel,
      logoOffset.dy * maxTravel,
    );

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: logoShape.radiusFor(boxSize),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: _hasLogo
            ? OverflowBox(
                alignment: Alignment.center,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.translate(
                  offset: pixelOffset,
                  child: Image.file(
                    File(logoPath!),
                    fit: BoxFit.cover,
                    width: boxSize * overScale * logoScale,
                    height: boxSize * overScale * logoScale,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_rounded,
                      size: boxSize * 0.31, color: accent.withValues(alpha: 0.5)),
                  SizedBox(height: boxSize * 0.045),
                  Text('Upload',
                      style: TextStyle(
                          fontSize: boxSize * 0.11,
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
      // has no minimum-width requirement from its parent.
      return _logoBox(context, compactBoxSize);
    }

    const double boxSize = 90.0;

    return Row(
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
  late LogoShape _shape;

  Offset? _focalStart;
  Offset? _offsetAtGestureStart;
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
            Text('Reposition Logo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              'Drag to move · Pinch or use slider to zoom',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: _shape.radiusFor(_viewSize),
              child: SizedBox(
                width: _viewSize,
                height: _viewSize,
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
                        width: _viewSize * _overScale * _scale,
                        height: _viewSize * _overScale * _scale,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Shape selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: LogoShape.values.map((s) {
                final selected = s == _shape;
                return GestureDetector(
                  onTap: () => setState(() => _shape = s),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
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
                    onPressed: () => Navigator.pop(context, (_normOffset, _scale, _shape)),
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