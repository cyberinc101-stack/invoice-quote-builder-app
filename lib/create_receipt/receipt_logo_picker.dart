// lib/create_receipt/receipt_logo_picker.dart
//
// Logo picker + reposition/zoom editor for the receipt Business Profile
// sheet. Mirrors the pattern used elsewhere in the app (CV Builder's
// ProfilePhotoWidget/ImageRepositionDialog, and the reposition feature
// quote_business_profile_library.dart's docstring references as
// "QuoteLogoPicker") — pick from gallery/camera, then drag to pan and
// pinch/slider to zoom, with the crop stored as a normalised offset
// (-1…1) + scale so it's resolution-independent and can be redrawn at
// any size (avatar-sized picker button, larger sheet preview, small
// card thumbnail) without re-cropping the source file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptLogoPicker extends StatelessWidget {
  final String? logoPath;
  final Offset logoOffset; // normalised -1…1
  final double logoScale; // 1.0 = no zoom, up to 3.0
  final Color accent;
  final void Function(String? path, Offset normOffset, double scale) onChanged;

  const ReceiptLogoPicker({
    super.key,
    required this.logoPath,
    required this.logoOffset,
    required this.logoScale,
    required this.accent,
    required this.onChanged,
  });

  bool get _hasLogo => logoPath != null && logoPath!.isNotEmpty && File(logoPath!).existsSync();

  Future<void> _pickImage(BuildContext context, ImageSource src) async {
    final img = await ImagePicker().pickImage(
      source: src,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 92,
    );
    if (img != null) onChanged(img.path, Offset.zero, 1.0);
  }

  Future<void> _openReposition(BuildContext context) async {
    final result = await showDialog<({Offset normOffset, double scale})>(
      context: context,
      builder: (_) => ReceiptImageRepositionDialog(
        imagePath: logoPath!,
        initialNormOffset: logoOffset,
        initialScale: logoScale,
        accent: accent,
      ),
    );
    if (result != null) onChanged(logoPath, result.normOffset, result.scale);
  }

  void _showOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Business Logo',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.onSurface)),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              color: accent,
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
                label: 'Reposition Logo',
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
                label: 'Remove Logo',
                color: const Color(0xFFF44336),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(null, Offset.zero, 1.0);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double boxSize = 80.0;
    const double overScale = 1.35; // must match ReceiptImageRepositionDialog

    final double maxTravel = (boxSize * overScale * logoScale - boxSize) / 2;
    final pixelOffset = Offset(logoOffset.dx * maxTravel, logoOffset.dy * maxTravel);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _showOptions(context),
          child: Stack(
            children: [
              Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  color: _hasLogo ? Colors.black : (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF9F9F9)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
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
                          Icon(Icons.business_rounded, size: 26, color: accent.withOpacity(0.5)),
                          const SizedBox(height: 4),
                          Text('Upload',
                              style: TextStyle(fontSize: 10, color: accent.withOpacity(0.6), fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _hasLogo ? 'Logo added ✓' : 'Add your business logo',
                style: TextStyle(fontSize: 12, color: _hasLogo ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Chip(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: accent,
                    onTap: () => _pickImage(context, ImageSource.gallery),
                  ),
                  _Chip(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: accent,
                    onTap: () => _pickImage(context, ImageSource.camera),
                  ),
                  if (_hasLogo)
                    _Chip(
                      icon: Icons.crop_rotate_rounded,
                      label: 'Reposition',
                      color: const Color(0xFF9C27B0),
                      onTap: () => _openReposition(context),
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

/// Renders a saved logo honoring its stored reposition/zoom crop — used in
/// the saved-profile card thumbnails so they match what the user framed in
/// the picker, instead of a plain centred cover-fit.
class ReceiptLogoThumbnail extends StatelessWidget {
  final String logoPath;
  final Offset logoOffset;
  final double logoScale;
  final double boxSize;

  const ReceiptLogoThumbnail({
    super.key,
    required this.logoPath,
    required this.logoOffset,
    required this.logoScale,
    this.boxSize = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    const double overScale = 1.35;
    final maxTravel = (boxSize * overScale * logoScale - boxSize) / 2;
    final pixelOffset = Offset(logoOffset.dx * maxTravel, logoOffset.dy * maxTravel);
    return OverflowBox(
      alignment: Alignment.center,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.translate(
        offset: pixelOffset,
        child: Image.file(
          File(logoPath),
          fit: BoxFit.cover,
          width: boxSize * overScale * logoScale,
          height: boxSize * overScale * logoScale,
        ),
      ),
    );
  }
}

// =============================================================================
// ReceiptImageRepositionDialog — drag to pan, pinch/slider to zoom
// =============================================================================

class ReceiptImageRepositionDialog extends StatefulWidget {
  final String imagePath;
  final Offset initialNormOffset;
  final double initialScale;
  final Color accent;

  const ReceiptImageRepositionDialog({
    super.key,
    required this.imagePath,
    required this.initialNormOffset,
    required this.initialScale,
    required this.accent,
  });

  @override
  State<ReceiptImageRepositionDialog> createState() => _ReceiptImageRepositionDialogState();
}

class _ReceiptImageRepositionDialogState extends State<ReceiptImageRepositionDialog> {
  static const double _viewSize = 280.0;
  static const double _overScale = 1.35;
  static const double _minScale = 1.0;
  static const double _maxScale = 3.0;

  late double _scale;
  late Offset _pixelOffset;

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
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.45)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ClipOval(
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

            Row(
              children: [
                Icon(Icons.zoom_out_rounded, size: 20, color: colorScheme.onSurface.withOpacity(0.4)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accent,
                      inactiveTrackColor: accent.withOpacity(0.2),
                      thumbColor: accent,
                      overlayColor: accent.withOpacity(0.12),
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
                Icon(Icons.zoom_in_rounded, size: 20, color: colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),

            Text(
              '${(_scale * 100).round()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 4),

            TextButton.icon(
              onPressed: () => setState(() {
                _scale = 1.0;
                _pixelOffset = Offset.zero;
              }),
              icon: Icon(Icons.center_focus_strong_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.45)),
              label: Text('Reset to centre',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.45))),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.45))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, (normOffset: _normOffset, scale: _scale)),
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

// =============================================================================
// Small shared widgets
// =============================================================================

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
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
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      contentPadding: EdgeInsets.zero,
    );
  }
}