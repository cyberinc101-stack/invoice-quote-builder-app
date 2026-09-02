// template_gallery_card.dart
// lib/screens/invoice_create_section/invoice_template_previews/template_gallery_card.dart
//
// Single shared template card, used by BOTH InvoiceTemplateChooserScreen
// (the "Choose a Design" step inside the create-invoice/quote/receipt
// wizard) and DocumentTemplatesScreen (the standalone "Document Templates"
// gallery reachable from the home screen). Previously each screen had its
// own hand-written _TemplateCard — same underlying preview widget
// (InvoiceStepChooserScaledPreview) but different chrome (card size,
// footer treatment, selection UI), which is what made the two screens
// look inconsistent even though the actual template designs rendered
// identically. This file is now the one place card appearance lives, so
// the two screens can't drift apart again.
//
// [isSelected] drives the chooser's radio-button + checkmark overlay
// style. Pass null (the default) to get the gallery's plain tap-to-open
// style instead, with no selection chrome. Both usages share the same
// accent footer bar, PRO badge, and "Coming Soon" treatment underneath.

import 'package:flutter/material.dart';
import '../invoice_step_template_chooser_registry.dart'
    show InvoiceStepChooserScaledPreview;

class TemplateGalleryCard extends StatelessWidget {
  final int templateId;
  final String name;
  final String tag;
  final Color accentColor;
  final bool available;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Null = no selection UI (gallery usage). Non-null = chooser usage,
  /// showing a checkmark badge + accent border when true.
  final bool? isSelected;

  const TemplateGalleryCard({
    super.key,
    required this.templateId,
    required this.name,
    required this.tag,
    required this.accentColor,
    required this.available,
    required this.isPremium,
    required this.onTap,
    this.onLongPress,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = isSelected ?? false;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: 0.9)
                : cs.outline.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accentColor.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: selected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white),
                  Opacity(
                    opacity: available ? 1.0 : 0.45,
                    child: InvoiceStepChooserScaledPreview(templateId: templateId),
                  ),
                  if (isPremium && available)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 11),
                            SizedBox(width: 3),
                            Text('PRO',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  if (isSelected != null && selected && available)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                      ),
                    ),
                  if (!available)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.15),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Coming Soon',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 3,
                      color: accentColor.withValues(alpha: available ? 1 : 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: available
                                ? cs.onSurface
                                : cs.onSurface.withValues(alpha: 0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            color: available
                                ? accentColor
                                : cs.onSurface.withValues(alpha: 0.3),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Chooser-only radio indicator, mirroring the old
                  // InvoiceTemplateChooserScreen card exactly.
                  if (isSelected != null && available)
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 15,
                      color: selected
                          ? accentColor
                          : cs.onSurface.withValues(alpha: 0.25),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
