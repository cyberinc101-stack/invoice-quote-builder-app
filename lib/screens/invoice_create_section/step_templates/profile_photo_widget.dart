// lib/screens/cv_edit_section/step_personal_info/profile_photo_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../helpers/lang_helper.dart';

// =============================================================================
// ProfilePhotoWidget
// =============================================================================

class ProfilePhotoWidget extends StatelessWidget {
  final String  imagePath;
  final Offset  imageOffset; // normalised -1…1, relative to maxTravel at imageScale
  final double  imageScale;  // 1.0 = no zoom, up to 3.0
  final void Function(String path, Offset normOffset, double scale) onChanged;

  const ProfilePhotoWidget({
    super.key,
    required this.imagePath,
    required this.imageOffset,
    required this.imageScale,
    required this.onChanged,
  });

  bool get _hasImage =>
      imagePath.isNotEmpty && File(imagePath).existsSync();

  Future<void> _pickImage(BuildContext context, ImageSource src) async {
    final img = await ImagePicker().pickImage(
        source: src, maxWidth: 1024, maxHeight: 1024, imageQuality: 92);
    if (img != null) onChanged(img.path, Offset.zero, 1.0);
  }

  Future<void> _openReposition(BuildContext context) async {
    final t      = getLang(context);
    final result = await showDialog<({Offset normOffset, double scale})>(
      context: context,
      builder: (_) => ImageRepositionDialog(
        imagePath:         imagePath,
        initialNormOffset: imageOffset,
        initialScale:      imageScale,
        translations:      t,
      ),
    );
    if (result != null) onChanged(imagePath, result.normOffset, result.scale);
  }

  void _showOptions(BuildContext context) {
    final t = getLang(context);
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
            Text(t['photo_sheet_title'] ?? 'Choose Photo',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).colorScheme.onSurface)),
            const SizedBox(height: 16),
            _ImageSourceTile(
              icon: Icons.photo_library_rounded,
              label: t['photo_option_gallery'] ?? 'Choose from Gallery',
              color: const Color(0xFF2196F3),
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 50));
                if (!context.mounted) return;
                _pickImage(context, ImageSource.gallery);
              },
            ),
            _ImageSourceTile(
              icon: Icons.camera_alt_rounded,
              label: t['photo_option_camera'] ?? 'Take a Photo',
              color: const Color(0xFF4CAF50),
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 50));
                if (!context.mounted) return;
                _pickImage(context, ImageSource.camera);
              },
            ),
            if (_hasImage) ...[
              _ImageSourceTile(
                icon: Icons.crop_rotate_rounded,
                label: t['photo_option_reposition'] ?? 'Reposition Photo',
                color: const Color(0xFF9C27B0),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 50));
                  if (!context.mounted) return;
                  _openReposition(context);
                },
              ),
              _ImageSourceTile(
                icon: Icons.delete_rounded,
                label: t['photo_option_remove'] ?? 'Remove Photo',
                color: const Color(0xFFF44336),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged('', Offset.zero, 1.0);
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
    final t = getLang(context);
    const double avatarSize = 72.0;
    const double overScale  = 1.35; // must match ImageRepositionDialog

    // Max travel grows with user scale so the image always covers the circle.
    final double avatarMaxTravel =
        (avatarSize * overScale * imageScale - avatarSize) / 2;
    final pixelOffset = Offset(
      imageOffset.dx * avatarMaxTravel,
      imageOffset.dy * avatarMaxTravel,
    );

    return Row(
      children: [
        GestureDetector(
          onTap: () => _showOptions(context),
          child: Stack(
            children: [
              Container(
                width: avatarSize, height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasImage ? Colors.black : const Color(0xFFF5F5F5),
                  border: Border.all(
                      color: _hasImage
                          ? const Color(0xFF2196F3)
                          : const Color(0xFFE0E0E0),
                      width: 2.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: _hasImage
                    ? OverflowBox(
                        alignment: Alignment.center,
                        maxWidth:  double.infinity,
                        maxHeight: double.infinity,
                        child: Transform.translate(
                          offset: pixelOffset,
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width:  avatarSize * overScale * imageScale,
                            height: avatarSize * overScale * imageScale,
                          ),
                        ),
                      )
                    : const Icon(Icons.person_rounded,
                        size: 34, color: Color(0xFFBDBDBD)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2196F3), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 13),
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
                _hasImage
                    ? (t['photo_status_added'] ?? 'Photo added ✓')
                    : (t['photo_status_empty'] ?? 'Add a professional headshot'),
                style: TextStyle(
                    fontSize: 12,
                    color: _hasImage
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PhotoChip(
                      icon: Icons.photo_library_rounded,
                      label: t['photo_chip_gallery'] ?? 'Gallery',
                      onTap: () => _pickImage(context, ImageSource.gallery)),
                  PhotoChip(
                      icon: Icons.camera_alt_rounded,
                      label: t['photo_chip_camera'] ?? 'Camera',
                      onTap: () => _pickImage(context, ImageSource.camera)),
                  if (_hasImage)
                    PhotoChip(
                        icon: Icons.crop_rotate_rounded,
                        label: t['photo_chip_reposition'] ?? 'Reposition',
                        color: const Color(0xFF9C27B0),
                        onTap: () => _openReposition(context)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ImageRepositionDialog
// =============================================================================

class ImageRepositionDialog extends StatefulWidget {
  final String              imagePath;
  final Offset              initialNormOffset;
  final double              initialScale;
  final Map<String, String> translations;

  const ImageRepositionDialog({
    super.key,
    required this.imagePath,
    required this.initialNormOffset,
    required this.initialScale,
    required this.translations,
  });

  @override
  State<ImageRepositionDialog> createState() => _ImageRepositionDialogState();
}

class _ImageRepositionDialogState extends State<ImageRepositionDialog> {
  static const double _viewSize  = 280.0;
  static const double _overScale = 1.35;
  static const double _minScale  = 1.0;
  static const double _maxScale  = 3.0;

  late double _scale;
  late Offset _pixelOffset; // displacement from centre in px

  // Gesture tracking
  Offset? _focalStart;
  Offset? _offsetAtGestureStart;
  double? _scaleAtGestureStart;

  Map<String, String> get t => widget.translations;

  /// Max travel in px for the current scale — grows as user zooms in.
  double get _maxTravel =>
      (_viewSize * _overScale * _scale - _viewSize) / 2;

  Offset _clamped(Offset o) {
    final m = _maxTravel;
    return Offset(o.dx.clamp(-m, m), o.dy.clamp(-m, m));
  }

  /// Normalised offset relative to the current maxTravel (-1…1).
  Offset get _normOffset {
    final m = _maxTravel;
    if (m == 0) return Offset.zero;
    return Offset(_pixelOffset.dx / m, _pixelOffset.dy / m);
  }

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale.clamp(_minScale, _maxScale);
    // Convert stored normOffset → pixels using the stored scale's maxTravel.
    final storedMaxTravel =
        (_viewSize * _overScale * _scale - _viewSize) / 2;
    _pixelOffset = _clamped(Offset(
      widget.initialNormOffset.dx * storedMaxTravel,
      widget.initialNormOffset.dy * storedMaxTravel,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title ────────────────────────────────────────────────────
            Text(t['photo_reposition_title'] ?? 'Reposition Photo',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              t['photo_reposition_sub'] ??
                  'Drag to move · Pinch or use slider to zoom',
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.45)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ── Circular drag / pinch viewport ───────────────────────────
            ClipOval(
              child: SizedBox(
                width: _viewSize, height: _viewSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // onScale* handles both pan (1 finger) and pinch (2 fingers).
                  onScaleStart: (d) {
                    _focalStart            = d.localFocalPoint;
                    _offsetAtGestureStart  = _pixelOffset;
                    _scaleAtGestureStart   = _scale;
                  },
                  onScaleUpdate: (d) {
                    if (_focalStart == null) return;
                    final newScale = (_scaleAtGestureStart! * d.scale)
                        .clamp(_minScale, _maxScale);
                    final delta = d.localFocalPoint - _focalStart!;
                    setState(() {
                      _scale       = newScale;
                      _pixelOffset = _clamped(_offsetAtGestureStart! + delta);
                    });
                  },
                  onScaleEnd: (_) {
                    _focalStart           = null;
                    _offsetAtGestureStart = null;
                    _scaleAtGestureStart  = null;
                  },
                  child: OverflowBox(
                    alignment: Alignment.center,
                    maxWidth:  double.infinity,
                    maxHeight: double.infinity,
                    child: Transform.translate(
                      offset: _pixelOffset,
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.cover,
                        width:  _viewSize * _overScale * _scale,
                        height: _viewSize * _overScale * _scale,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Zoom slider ───────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.zoom_out_rounded,
                    size: 20, color: colorScheme.onSurface.withOpacity(0.4)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:   const Color(0xFF2196F3),
                      inactiveTrackColor: const Color(0xFF2196F3).withOpacity(0.2),
                      thumbColor:         const Color(0xFF2196F3),
                      overlayColor:       const Color(0xFF2196F3).withOpacity(0.12),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: _scale,
                      min:   _minScale,
                      max:   _maxScale,
                      onChanged: (v) => setState(() {
                        _scale       = v;
                        _pixelOffset = _clamped(_pixelOffset);
                      }),
                    ),
                  ),
                ),
                Icon(Icons.zoom_in_rounded,
                    size: 20, color: colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),

            // Zoom percentage label
            Text(
              '${(_scale * 100).round()}%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 4),

            // ── Reset button ─────────────────────────────────────────────
            TextButton.icon(
              onPressed: () => setState(() {
                _scale       = 1.0;
                _pixelOffset = Offset.zero;
              }),
              icon: Icon(Icons.center_focus_strong_rounded,
                  size: 16, color: colorScheme.onSurface.withOpacity(0.45)),
              label: Text(
                t['photo_reposition_reset'] ?? 'Reset to centre',
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.45)),
              ),
            ),
            const SizedBox(height: 8),

            // ── Cancel / Apply ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      t['detail_rename_btn_cancel'] ?? 'Cancel',
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.45)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (normOffset: _normOffset, scale: _scale),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(t['photo_reposition_apply'] ?? 'Apply'),
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
// PhotoChip
// =============================================================================

class PhotoChip extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final Color        color;

  const PhotoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF2196F3),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.35))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _ImageSourceTile
// =============================================================================

class _ImageSourceTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface)),
      contentPadding: EdgeInsets.zero,
    );
  }
}