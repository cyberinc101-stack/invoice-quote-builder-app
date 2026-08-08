// lib/screens/create_quote_section/quote_edit_widgets.dart
//
// Self-contained reusable widgets for the quote creation/edit flow.
//
// Deliberately does NOT depend on invoice_create_section/invoice_edit_widgets.dart
// or anything from invoice_models.dart — this feature is kept fully
// self-contained rather than risking a cross-import from a different model
// set.
//
// UPDATED (this pass): QuoteLogoPicker now matches the invoice app's
// profile_photo_widget.dart UX:
//   - Tapping the logo box opens a bottom sheet: Choose from Gallery /
//     Take a Photo / Reposition Logo (if one exists) / Remove Logo —
//     instead of jumping straight into the gallery picker.
//   - A picked image can be repositioned/zoomed via a dialog (drag to pan,
//     pinch or slider to zoom), same drag/pinch mechanics as
//     ImageRepositionDialog in the invoice app's photo widget, adapted to
//     a rounded-square crop instead of a circle to match this app's logo
//     box shape.
//   - Picked images are still copied into the app's own documents
//     directory (under quote_logos/) before the path is handed back, so
//     saved-client / saved-business-profile logos remain durable across
//     app restarts — unchanged from the previous pass.
//   - onChanged now reports (path, normalizedOffset, scale) instead of
//     just a path, so callers that want to persist the crop (saved
//     business profiles / saved clients) can store it alongside the path.
//     Callers that don't care about the crop can ignore the extra two
//     arguments.
//
// NOTE: the offset/scale only affects how the logo is framed inside this
// picker's own preview box and inside saved-library cards — it is not
// baked into the actual generated quote PDF. If you want the chosen crop
// to also apply wherever the logo is drawn in the final quote layout,
// share the quote layout template file(s) that render businessLogoPath
// and I can thread the same offset/scale through there.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../models/quote_data.dart' show QuoteColor;

// ─────────────────────────────────────────────────────────────────────────────
// Currency list (self-contained — avoids depending on an uncertain
// CurrencyHelper class referenced only in mismatched invoice reference
// files, whose real availability outside that file is unconfirmed)
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, String>> kQuoteCurrencies = [
  {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
  {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
  {'code': 'NZD', 'symbol': 'NZ\$', 'name': 'New Zealand Dollar'},
  {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
  {'code': 'ZAR', 'symbol': 'R', 'name': 'South African Rand'},
  {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
  {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
];

String quoteCurrencySymbol(String code) {
  final match = kQuoteCurrencies.firstWhere(
    (c) => c['code'] == code,
    orElse: () => {'symbol': code},
  );
  return match['symbol'] ?? code;
}

// ─────────────────────────────────────────────────────────────────────────────
// Color mapping for QuoteColor (the enum itself has no color properties)
// ─────────────────────────────────────────────────────────────────────────────

Color quoteColorPrimary(QuoteColor c) {
  switch (c) {
    case QuoteColor.blue:   return const Color(0xFF2196F3);
    case QuoteColor.green:  return const Color(0xFF4CAF50);
    case QuoteColor.purple: return const Color(0xFF9C27B0);
    case QuoteColor.orange: return const Color(0xFFFF9800);
    case QuoteColor.red:    return const Color(0xFFE53935);
    case QuoteColor.teal:   return const Color(0xFF009688);
    case QuoteColor.black:  return const Color(0xFF37474F);
    case QuoteColor.indigo: return const Color(0xFF3F51B5);
  }
}

Color quoteColorAccent(QuoteColor c) {
  switch (c) {
    case QuoteColor.blue:   return const Color(0xFF64B5F6);
    case QuoteColor.green:  return const Color(0xFF81C784);
    case QuoteColor.purple: return const Color(0xFFBA68C8);
    case QuoteColor.orange: return const Color(0xFFFFB74D);
    case QuoteColor.red:    return const Color(0xFFE57373);
    case QuoteColor.teal:   return const Color(0xFF4DB6AC);
    case QuoteColor.black:  return const Color(0xFF78909C);
    case QuoteColor.indigo: return const Color(0xFF7986CB);
  }
}

String quoteColorLabel(QuoteColor c) {
  switch (c) {
    case QuoteColor.blue:   return 'Blue';
    case QuoteColor.green:  return 'Green';
    case QuoteColor.purple: return 'Purple';
    case QuoteColor.orange: return 'Orange';
    case QuoteColor.red:    return 'Red';
    case QuoteColor.teal:   return 'Teal';
    case QuoteColor.black:  return 'Slate';
    case QuoteColor.indigo: return 'Indigo';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuoteStepNavBar — back / next bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class QuoteStepNavBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final IconData nextIcon;
  final bool isLoading;
  final Color accent;

  const QuoteStepNavBar({
    super.key,
    this.onBack,
    this.onNext,
    this.nextLabel = 'Next',
    this.nextIcon = Icons.arrow_forward_rounded,
    this.isLoading = false,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, -3))],
      ),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface.withValues(alpha: 0.55), size: 22),
              ),
            ),
          const SizedBox(width: 12),
          if (onNext != null)
            Expanded(
              child: GestureDetector(
                onTap: isLoading ? null : onNext,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLoading
                          ? [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHighest]
                          : [accent, accent.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isLoading
                        ? []
                        : [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(nextLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(width: 6),
                              Icon(nextIcon, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuoteField — reusable text field
// ─────────────────────────────────────────────────────────────────────────────

class QuoteField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData? icon;
  final int? max;
  final int maxLines;
  final bool required;
  final TextInputType? keyboard;
  final Color accent;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const QuoteField({
    super.key,
    required this.ctrl,
    required this.label,
    required this.accent,
    this.hint,
    this.icon,
    this.max,
    this.maxLines = 1,
    this.required = false,
    this.keyboard,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atLimit = max != null && ctrl.text.length >= max!;

    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      inputFormatters: max != null ? [LengthLimitingTextInputFormatter(max!)] : null,
      onChanged: onChanged,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.45)) : null,
        suffixIcon: suffix ??
            (atLimit
                ? const Tooltip(
                    message: 'Character limit reached',
                    child: Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF44336)),
                  )
                : null),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: atLimit ? const Color(0xFFF44336) : colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: atLimit ? const Color(0xFFF44336) : accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuoteDateField — tap-to-pick date field (stores as plain display string,
// matching QuoteData.issueDate / expiryDate being plain Strings)
// ─────────────────────────────────────────────────────────────────────────────

class QuoteDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color accent;

  const QuoteDateField({super.key, required this.label, required this.value, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 8),
                Expanded(child: Text(value.isEmpty ? '—' : value, style: TextStyle(fontSize: 14, color: colorScheme.onSurface))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuoteLogoPicker — optional business/client logo image
//
// UPDATED (this pass): now offers Gallery / Camera / Reposition / Remove
// via a bottom sheet (same pattern as the invoice app's photo widget),
// plus a drag-to-pan + pinch/slider-to-zoom reposition dialog. Picked
// images are still copied into <app documents>/quote_logos/<uuid>.<ext>
// before the path is handed back, so saved logos stay durable across app
// restarts / cache clears.
// ─────────────────────────────────────────────────────────────────────────────

class QuoteLogoPicker extends StatefulWidget {
  final String? logoPath;

  /// Normalised pan offset, -1..1 on each axis. Defaults to centred.
  final Offset logoOffset;

  /// Zoom level, 1.0 = no zoom, up to 3.0. Defaults to no zoom.
  final double logoScale;

  final Color accent;

  /// Reports the (possibly-new) logo path plus its normalised offset and
  /// zoom scale. Callers that don't care about crop/position can ignore
  /// the last two arguments.
  final void Function(String? path, Offset offset, double scale) onChanged;

  const QuoteLogoPicker({
    super.key,
    required this.logoPath,
    this.logoOffset = Offset.zero,
    this.logoScale = 1.0,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<QuoteLogoPicker> createState() => _QuoteLogoPickerState();
}

class _QuoteLogoPickerState extends State<QuoteLogoPicker> {
  bool _saving = false;

  bool get _hasLogo =>
      widget.logoPath != null && widget.logoPath!.isNotEmpty && File(widget.logoPath!).existsSync();

  Future<String> _persistPickedImage(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final logosDir = Directory(p.join(docsDir.path, 'quote_logos'));
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    final ext = p.extension(sourcePath);
    final destPath = p.join(logosDir.path, '${const Uuid().v4()}$ext');
    final destFile = await File(sourcePath).copy(destPath);
    return destFile.path;
  }

  Future<void> _pickFrom(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 90);
    if (image == null) return;

    setState(() => _saving = true);
    try {
      final persistedPath = await _persistPickedImage(image.path);
      // Fresh pick — reset crop to centred / no zoom.
      widget.onChanged(persistedPath, Offset.zero, 1.0);
    } catch (_) {
      // Fall back to the raw picker path rather than losing the pick
      // entirely if copying somehow fails.
      widget.onChanged(image.path, Offset.zero, 1.0);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openReposition() async {
    final logoPath = widget.logoPath;
    if (logoPath == null || logoPath.isEmpty) return;
    final result = await showDialog<({Offset normOffset, double scale})>(
      context: context,
      builder: (_) => _QuoteLogoRepositionDialog(
        imagePath: logoPath,
        initialNormOffset: widget.logoOffset,
        initialScale: widget.logoScale,
        accent: widget.accent,
      ),
    );
    if (result != null) {
      widget.onChanged(logoPath, result.normOffset, result.scale);
    }
  }

  void _showOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Logo Image',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
            const SizedBox(height: 16),
            _LogoSourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              color: const Color(0xFF2196F3),
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 50));
                if (!mounted) return;
                _pickFrom(ImageSource.gallery);
              },
            ),
            _LogoSourceTile(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              color: const Color(0xFF4CAF50),
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 50));
                if (!mounted) return;
                _pickFrom(ImageSource.camera);
              },
            ),
            if (_hasLogo) ...[
              _LogoSourceTile(
                icon: Icons.crop_rotate_rounded,
                label: 'Reposition Logo',
                color: const Color(0xFF9C27B0),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 50));
                  if (!mounted) return;
                  _openReposition();
                },
              ),
              _LogoSourceTile(
                icon: Icons.delete_rounded,
                label: 'Remove Logo',
                color: const Color(0xFFF44336),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onChanged(null, Offset.zero, 1.0);
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final logoPath = widget.logoPath;
    final hasLogo = _hasLogo;

    const double boxSize = 72.0;
    const double overScale = 1.35; // must match _QuoteLogoRepositionDialog
    final double maxTravel = (boxSize * overScale * widget.logoScale - boxSize) / 2;
    final pixelOffset = Offset(
      widget.logoOffset.dx * maxTravel,
      widget.logoOffset.dy * maxTravel,
    );

    return Row(
      children: [
        GestureDetector(
          onTap: _saving ? null : _showOptions,
          child: Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: _saving
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                    ),
                  )
                : hasLogo
                    ? OverflowBox(
                        alignment: Alignment.center,
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: Transform.translate(
                          offset: pixelOffset,
                          child: Image.file(
                            File(logoPath!),
                            fit: BoxFit.cover,
                            width: boxSize * overScale * widget.logoScale,
                            height: boxSize * overScale * widget.logoScale,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, size: 24, color: accent.withValues(alpha: 0.6)),
                          const SizedBox(height: 4),
                          Text('Logo', style: TextStyle(fontSize: 10, color: accent.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                        ],
                      ),
          ),
        ),
        if (hasLogo && !_saving) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _openReposition,
                icon: Icon(Icons.crop_rotate_rounded, size: 16, color: accent),
                label: Text('Reposition', style: TextStyle(color: accent)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              ),
              TextButton.icon(
                onPressed: () => widget.onChanged(null, Offset.zero, 1.0),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF5350)),
                label: const Text('Remove', style: TextStyle(color: Color(0xFFEF5350))),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LogoSourceTile — bottom-sheet row (mirrors invoice app's _ImageSourceTile)
// ─────────────────────────────────────────────────────────────────────────────

class _LogoSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LogoSourceTile({
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
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuoteLogoRepositionDialog — drag to pan, pinch/slider to zoom.
// Same interaction model as the invoice app's ImageRepositionDialog, but
// clipped to a rounded square (RRect) instead of a circle, to match this
// picker's own box shape, and themed off the caller's accent color instead
// of a fixed blue.
// ─────────────────────────────────────────────────────────────────────────────

class _QuoteLogoRepositionDialog extends StatefulWidget {
  final String imagePath;
  final Offset initialNormOffset;
  final double initialScale;
  final Color accent;

  const _QuoteLogoRepositionDialog({
    required this.imagePath,
    required this.initialNormOffset,
    required this.initialScale,
    required this.accent,
  });

  @override
  State<_QuoteLogoRepositionDialog> createState() => _QuoteLogoRepositionDialogState();
}

class _QuoteLogoRepositionDialogState extends State<_QuoteLogoRepositionDialog> {
  static const double _viewSize = 240.0;
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
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: BorderRadius.circular(18),
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
                  child: Container(
                    color: colorScheme.surfaceContainerHighest,
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
              label: Text('Reset to centre', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45))),
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

// ─────────────────────────────────────────────────────────────────────────────
// QuoteItemCard — one line item row (description / qty / price / total)
// ─────────────────────────────────────────────────────────────────────────────

class QuoteItemCard extends StatelessWidget {
  final int index;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final double total;
  final String currencySymbol;
  final bool canRemove;
  final Color accent;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const QuoteItemCard({
    super.key,
    required this.index,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.total,
    required this.currencySymbol,
    required this.canRemove,
    required this.accent,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text('${index + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Item ${index + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                const Spacer(),
                if (canRemove)
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFEF5350).withValues(alpha: 0.12) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, color: Color(0xFFEF5350), size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: descCtrl,
              style: TextStyle(color: colorScheme.onSurface),
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                hintText: 'e.g. Consulting Services',
                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
                filled: true,
                fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: qtyCtrl,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (_) => onChanged(),
                    decoration: _smallDeco(context, 'Qty', colorScheme, isDark, accent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: priceCtrl,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      LengthLimitingTextInputFormatter(12),
                    ],
                    onChanged: (_) => onChanged(),
                    decoration: _smallDeco(context, 'Price ($currencySymbol)', colorScheme, isDark, accent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(height: 2),
                        Text('$currencySymbol${total.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _smallDeco(BuildContext context, String label, ColorScheme cs, bool isDark, Color accent) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12),
      filled: true,
      fillColor: isDark ? cs.surfaceContainerHighest : const Color(0xFFF9F9F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 1.5)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuoteTotalsCard
// ─────────────────────────────────────────────────────────────────────────────

class QuoteTotalsCard extends StatelessWidget {
  final double subtotal, taxAmount, discountAmount, total;
  final double taxRate, discountRate;
  final String currencySymbol;
  final Color accent;

  const QuoteTotalsCard({
    super.key,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.taxRate,
    required this.discountRate,
    required this.currencySymbol,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? accent.withValues(alpha: 0.1) : accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _row('Subtotal', '$currencySymbol${subtotal.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row('Tax (${taxRate.toStringAsFixed(taxRate % 1 == 0 ? 0 : 1)}%)', '+$currencySymbol${taxAmount.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row('Discount (${discountRate.toStringAsFixed(discountRate % 1 == 0 ? 0 : 1)}%)',
              '-$currencySymbol${discountAmount.toStringAsFixed(2)}', colorScheme),
          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(color: accent.withValues(alpha: 0.3), height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              Text('$currencySymbol${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuoteColorPicker
// ─────────────────────────────────────────────────────────────────────────────

class QuoteColorPicker extends StatelessWidget {
  final QuoteColor selected;
  final ValueChanged<QuoteColor> onChanged;

  const QuoteColorPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: QuoteColor.values.length,
      itemBuilder: (_, i) {
        final scheme = QuoteColor.values[i];
        final isSelected = selected == scheme;
        return GestureDetector(
          onTap: () => onChanged(scheme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? quoteColorPrimary(scheme) : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [quoteColorPrimary(scheme), quoteColorAccent(scheme)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9)),
                    ),
                    child: isSelected ? const Center(child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20)) : null,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(9), bottomRight: Radius.circular(9)),
                  ),
                  child: Text(
                    quoteColorLabel(scheme),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                      color: isSelected ? quoteColorPrimary(scheme) : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header (small decorative label used across both steps)
// ─────────────────────────────────────────────────────────────────────────────

Widget quoteSectionHeader(BuildContext context, String label, Color accent, {IconData? icon}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        if (icon != null) ...[Icon(icon, size: 16, color: accent), const SizedBox(width: 6)],
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface, letterSpacing: 0.2)),
      ],
    ),
  );
}
