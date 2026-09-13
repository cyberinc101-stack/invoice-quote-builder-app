part of 'step_templates.dart';

// =============================================================================
// _SignatureSection — three selectable modes (matches
// BusinessInfo.signatureMode / InvoiceData.signatureMode exactly):
// 'image' (upload a scanned signature, no crop/shape mask), 'typed' (a
// typed name rendered in a script-style font on the document), 'blank'
// (no image or text -- just reserves a signing line on the printed/PDF
// invoice).
//
// SIGNATURE OVERFLOW FIX v2 (this update): cap relaxed from 30 back up
// to 40. The earlier 30-char cap was a workaround for the render side
// truncating long names with an ellipsis; now that
// executive_invoice_payment_terms_signature.dart auto-shrinks the whole
// name to fit instead of cutting it off, a slightly longer name is safe
// again — 40 covers a full "Business Name Pty Ltd"-style signature
// without the field feeling stingy, while the render-side FittedBox
// still protects against anything longer than that.
//
// GROUPED SECTIONS PASS (earlier): the internal _sectionLabel
// ('Signature') call was removed — this widget is now always rendered
// inside a _CollapsibleGroup (step_templates.dart) whose own header
// already shows the 'Signature' label, icon and expand/collapse switch,
// so a second label here would just duplicate it.
//
// DESELECT PASS (earlier): tapping whichever chip is already selected
// now deselects it, setting mode to '' — a fourth, distinct state
// meaning "no signature block at all". This is NOT the same as 'blank':
// 'blank' still reserves an empty signing line on the document; ''
// renders nothing whatsoever, the same as if the Customise step's
// Signature toggle were off, but scoped to this template rather than
// the whole invoice. See executive_invoice_payment_terms_signature.dart
// and invoice_pdf_extra_sections.dart's buildSignatureBlock/
// buildPdfSignatureBlock for the render-side half of this — both now
// early-return nothing when signatureMode is empty, distinct from the
// 'blank' case just below it. Existing templates are unaffected: '' is
// a new value nothing writes automatically, so every template saved
// before this pass keeps whatever real mode it already had.
//
// Wired to BusinessInfo's signatureMode/signatureName/signatureImagePath
// (see client_info.dart's PAYMENT INFO / TERMS & SIGNATURE PASS), synced
// onto InvoiceData's matching fields at template-select time by
// StepCreateInvoice._syncSelectedToProvider().
//
// Signature images are copied into the app's documents directory under
// signatures/ on pick, mirroring the existing logo-storage convention
// (persistent logo storage copied to app documents/quote_logos/ etc).
//
// Requires image_picker and path_provider — both already used elsewhere
// in this app for logo picking/storage, so no new pubspec dependency is
// expected, but flag it to Jesse if either is missing.
// =============================================================================

class _SignatureSection extends StatefulWidget {
  final String mode; // 'typed' | 'image' | 'blank' | '' (deselected)
  final ValueChanged<String> onModeChanged;
  final TextEditingController nameCtrl;
  final String? imagePath;
  final ValueChanged<String?> onImageChanged;
  final Color accent;

  const _SignatureSection({
    required this.mode,
    required this.onModeChanged,
    required this.nameCtrl,
    required this.imagePath,
    required this.onImageChanged,
    required this.accent,
  });

  @override
  State<_SignatureSection> createState() => _SignatureSectionState();
}

class _SignatureSectionState extends State<_SignatureSection> {
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

  // DESELECT PASS: tapping a chip that's already selected clears the
  // mode back to '' instead of leaving it selected — this is the only
  // change to chip behaviour. Tapping a different (unselected) chip
  // still just switches straight to it, same as before.
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
          _SheetField(
            ctrl: widget.nameCtrl,
            label: 'Signature Name',
            hint: 'e.g. Jane Smith',
            icon: Icons.draw_outlined,
            // SIGNATURE OVERFLOW FIX v2: 30 -> 40 — see file header
            // comment. The render side now auto-shrinks instead of
            // truncating, so this cap only exists to stop truly absurd
            // input lengths, not to protect the layout.
            max: 40,
            accent: widget.accent,
          ),
          _counter(context, widget.nameCtrl.text.length, 40),
          const SizedBox(height: 8),
          Text(
            'Rendered in a script-style font on the invoice.',
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
          // DESELECT PASS: mode == '' — none of the three chips are
          // selected. Distinct wording from the 'blank' box above: this
          // isn't "reserve a line", it's "nothing renders at all".
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
                Text('No signature — nothing will appear on the invoice',
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