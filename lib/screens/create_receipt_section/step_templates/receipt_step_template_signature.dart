part of 'receipt_step_template.dart';

// =============================================================================
// _ReceiptSignatureSection — three selectable modes plus a fourth
// deselected state, mirroring Invoice's _SignatureSection
// (step_templates_signature.dart) and Quote's _QuoteSignatureSection
// (quote_step_template_signature.dart) exactly:
//   'image'  — upload a scanned signature, no crop/shape mask
//   'typed'  — a typed name rendered in a script-style font
//   'blank'  — no image or text, just reserves a signing line
//   ''       — deselected: nothing renders at all (tapping the already-
//              selected chip clears back to this state)
//
// Wired to ReceiptTemplate's signatureMode/signatureName/
// signatureImagePath — NOT yet synced onto ReceiptData at template-
// select time, and ReceiptData itself has no matching signature fields
// yet either (see receipt_step_template.dart's file header for the
// pending sync step — this is model+UI plumbing only for now, same
// boundary Quote's own parity pass started from).
//
// Signature images are copied into the app's documents directory under
// signatures/ on pick, mirroring the existing logo-storage convention
// used elsewhere. Requires image_picker and path_provider — both
// already used elsewhere in this app.
//
// Named distinctly from Invoice's _SignatureSection and Quote's
// _QuoteSignatureSection so all three part-file libraries can coexist
// in the app without symbol collisions.
// =============================================================================

class _ReceiptSignatureSection extends StatefulWidget {
  final String mode; // 'typed' | 'image' | 'blank' | '' (deselected)
  final ValueChanged<String> onModeChanged;
  final TextEditingController nameCtrl;
  final String? imagePath;
  final ValueChanged<String?> onImageChanged;
  final Color accent;

  const _ReceiptSignatureSection({
    required this.mode,
    required this.onModeChanged,
    required this.nameCtrl,
    required this.imagePath,
    required this.onImageChanged,
    required this.accent,
  });

  @override
  State<_ReceiptSignatureSection> createState() => _ReceiptSignatureSectionState();
}

class _ReceiptSignatureSectionState extends State<_ReceiptSignatureSection> {
  bool _picking = false;

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;
      final docsDir = await getApplicationDocumentsDirectory();
      final sigDir = Directory('${docsDir.path}/signatures');
      if (!await sigDir.exists()) {
        await sigDir.create(recursive: true);
      }
      final ext = picked.path.split('.').last;
      final destPath =
          '${sigDir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(picked.path).copy(destPath);
      widget.onImageChanged(destPath);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Widget _modeChip(BuildContext context, String value, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = widget.mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onModeChanged(selected ? '' : value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? widget.accent.withValues(alpha: isDark ? 0.22 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? widget.accent
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? widget.accent
                      : colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? widget.accent
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _modeChip(context, 'image', 'Upload', Icons.upload_rounded),
            const SizedBox(width: 8),
            _modeChip(context, 'typed', 'Type', Icons.edit_rounded),
            const SizedBox(width: 8),
            _modeChip(context, 'blank', 'Blank Line', Icons.horizontal_rule_rounded),
          ],
        ),
        const SizedBox(height: 14),

        if (widget.mode == 'image') ...[
          GestureDetector(
            onTap: _picking ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _picking
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: widget.accent),
                      ),
                    )
                  : (widget.imagePath != null &&
                          File(widget.imagePath!).existsSync())
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(widget.imagePath!), fit: BoxFit.contain),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => widget.onImageChanged(null),
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
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 26,
                                  color: colorScheme.onSurface.withValues(alpha: 0.35)),
                              const SizedBox(height: 6),
                              Text('Tap to upload a signature image',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurface.withValues(alpha: 0.4))),
                            ],
                          ),
                        ),
            ),
          ),
        ] else if (widget.mode == 'typed') ...[
          ReceiptField(
            ctrl: widget.nameCtrl,
            label: 'Signature Name',
            hint: 'e.g. Jane Smith',
            accent: widget.accent,
            icon: Icons.draw_outlined,
            max: 40,
          ),
          _counter(context, widget.nameCtrl.text.length, 40),
          const SizedBox(height: 8),
          Text(
            'Rendered in a script-style font on the receipt.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ] else if (widget.mode == 'blank') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.horizontal_rule_rounded,
                    size: 22, color: colorScheme.onSurface.withValues(alpha: 0.35)),
                const SizedBox(height: 6),
                Text('Reserves a blank signing line for a physical signature',
                    style: TextStyle(
                        fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.block_rounded,
                    size: 22, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 6),
                Text('No signature — nothing will appear on the receipt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.4))),
                const SizedBox(height: 2),
                Text('Tap a mode above to add one',
                    style: TextStyle(
                        fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
