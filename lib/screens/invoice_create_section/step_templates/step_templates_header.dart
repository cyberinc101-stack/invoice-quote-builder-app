// lib/screens/invoice_create_section/step_templates/step_templates_header.dart
//
// HEADER STYLE / FOOTER BACKGROUND IMAGE PASS: this part file defines the
// two widgets referenced from step_templates.dart's _TemplateSheetState:
//   - HeaderStyleSection: lets the user pick how the document header is
//     rendered (Built-in text header / Full header image / Logo + Text),
//     and upload an image when an image-based mode is selected.
//   - FooterBackgroundSection: a toggle + image upload for an optional
//     footer background image, independent of the Footer Taglines text.
//
// Both widgets are UI/model-plumbing only, per the earlier plan — they
// write into BusinessInfo.headerMode/headerImagePath and
// BusinessInfo.footerBackgroundEnabled/footerBackgroundImagePath via the
// callbacks the parent _TemplateSheetState already wires into _save().
// They do not touch any renderer (in-app preview or PDF export) — that is
// a separate, deliberately deferred step.

part of 'step_templates.dart';

// =============================================================================
// HeaderStyleSection
// =============================================================================

class HeaderStyleSection extends StatefulWidget {
  final String mode; // 'built' | 'image' | 'logoText'
  final ValueChanged<String> onModeChanged;
  final String? imagePath;
  final ValueChanged<String?> onImageChanged;
  final Color accent;

  const HeaderStyleSection({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.imagePath,
    required this.onImageChanged,
    required this.accent,
  });

  @override
  State<HeaderStyleSection> createState() => _HeaderStyleSectionState();
}

class _HeaderStyleSectionState extends State<HeaderStyleSection> {
  bool _picking = false;

  static const _modes = [
    ('built', 'Built-in', Icons.view_headline_rounded,
        'Text-based header using your business name and details.'),
    ('image', 'Full Image', Icons.panorama_rounded,
        'Replace the whole header area with one uploaded image.'),
    ('logoText', 'Logo + Text', Icons.badge_outlined,
        'Keep your logo and text header, side by side.'),
  ];

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 90,
      );
      if (picked == null) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last;
      final fileName = 'header_image_${const Uuid().v4()}.$ext';
      final savedPath = '${docsDir.path}/$fileName';
      await File(picked.path).copy(savedPath);

      widget.onImageChanged(savedPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load that image. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _removeImage() {
    widget.onImageChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final needsImage = widget.mode == 'image';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose how the header is displayed on your documents.',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        ..._modes.map((m) {
          final (value, label, icon, desc) = m;
          final selected = widget.mode == value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => widget.onModeChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark
                          ? widget.accent.withValues(alpha: 0.15)
                          : widget.accent.withValues(alpha: 0.08))
                      : (isDark
                          ? colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4)
                          : const Color(0xFFF9F9F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? widget.accent.withValues(alpha: 0.6)
                        : colorScheme.outline.withValues(alpha: 0.25),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 20,
                        color: selected
                            ? widget.accent
                            : colorScheme.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: value,
                      groupValue: widget.mode,
                      activeColor: widget.accent,
                      onChanged: (v) {
                        if (v != null) widget.onModeChanged(v);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (needsImage) ...[
          const SizedBox(height: 4),
          if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Image.file(
                    File(widget.imagePath!),
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      color:
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: _picking ? null : _pickImage,
            icon: _picking
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: widget.accent),
                  )
                : Icon(Icons.upload_rounded, size: 16, color: widget.accent),
            label: Text(
              (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                  ? 'Replace Image'
                  : 'Upload Header Image',
              style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: widget.accent.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// FooterBackgroundSection
// =============================================================================

class FooterBackgroundSection extends StatefulWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final String? imagePath;
  final ValueChanged<String?> onImageChanged;
  final Color accent;

  const FooterBackgroundSection({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    required this.imagePath,
    required this.onImageChanged,
    required this.accent,
  });

  @override
  State<FooterBackgroundSection> createState() =>
      _FooterBackgroundSectionState();
}

class _FooterBackgroundSectionState extends State<FooterBackgroundSection> {
  bool _picking = false;

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 90,
      );
      if (picked == null) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last;
      final fileName = 'footer_background_${const Uuid().v4()}.$ext';
      final savedPath = '${docsDir.path}/$fileName';
      await File(picked.path).copy(savedPath);

      widget.onImageChanged(savedPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load that image. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _removeImage() {
    widget.onImageChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Show a background image behind the document footer.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            Switch(
              value: widget.enabled,
              activeThumbColor: widget.accent,
              onChanged: widget.onEnabledChanged,
            ),
          ],
        ),
        if (widget.enabled) ...[
          const SizedBox(height: 8),
          if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Image.file(
                    File(widget.imagePath!),
                    width: double.infinity,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 90,
                      color:
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: _picking ? null : _pickImage,
            icon: _picking
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: widget.accent),
                  )
                : Icon(Icons.upload_rounded, size: 16, color: widget.accent),
            label: Text(
              (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                  ? 'Replace Image'
                  : 'Upload Footer Background',
              style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: widget.accent.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ],
    );
  }
}
