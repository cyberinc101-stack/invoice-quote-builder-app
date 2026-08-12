// template_full_preview_modal.dart
// lib/screens/invoice_create_section/invoice_template_previews/template_full_preview_modal.dart
//
// Full-screen "tap to preview" overlay for a template card. Rebuilt against
// the current preview_registry.dart API (InvoiceTemplateInfo,
// buildInvoicePreview, sampleInvoiceData) - the older version of this file
// (from the CV-builder era, using TemplateCardInfo / individual Preview*
// classes) is not compatible and lives only in git history now.
//
// SCROLL FIX (this pass): the preview widget renders each design at real
// document scale (not scaled down like the card thumbnail), so for any
// design taller than ~78% of screen height the old fixed-height Container
// clipped content and threw a RenderFlex overflow (seen with Nordic:
// "BOTTOM OVERFLOWED BY 204 PIXELS"). The document sheet is now wrapped in
// a SingleChildScrollView inside the same maxHeight container, so tall
// designs scroll instead of overflowing. A lingering ~6-7px *horizontal*
// overflow on Nordic's issue-date row is inside nordic_template.dart
// itself (a Row that doesn't leave quite enough width for "26 Jul 2026"
// next to its label) - not something this modal can fix; needs a tweak in
// that template file directly.

import 'package:flutter/material.dart';
import 'preview_registry.dart';
import '../../../helpers/lang_helper.dart';

/// Call this to show the full preview overlay.
void showTemplateFullPreview(
  BuildContext context, {
  required InvoiceTemplateInfo info,
}) {
  // getLang uses context.read - safe to call outside build().
  // watchLang uses context.watch which is only valid inside build()
  // and throws "Tried to listen from outside the widget tree" here.
  final t = getLang(context);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: t['preview_modal_barrier_label'] ?? 'Close preview',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, anim, __, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween(begin: 0.88, end: 1.0).animate(curve),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) => _FullPreviewModal(info: info),
  );
}

// -----------------------------------------------------------------------
// Modal shell
// -----------------------------------------------------------------------
class _FullPreviewModal extends StatelessWidget {
  final InvoiceTemplateInfo info;
  const _FullPreviewModal({required this.info});

  @override
  Widget build(BuildContext context) {
    final t       = getLang(context);
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    final displayName        = t[info.name]        ?? info.name;
    final displayDescription = t[info.description] ?? info.description;

    final preview = buildInvoicePreview(info.id, sampleInvoiceData());

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -- Top bar ---------------------------------------------------
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: info.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: info.accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (info.isPremium) ...[
                      const Icon(Icons.workspace_premium_rounded,
                          color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      displayName,
                      style: TextStyle(
                          color: info.accentColor == const Color(0xFF000000)
                              ? Colors.white
                              : info.accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayDescription,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // -- Document preview sheet -------------------------------------
              // SingleChildScrollView here (new) is what actually fixes the
              // overflow - the design renders at full document scale, which
              // is routinely taller than screenH * 0.78, so it needs to
              // scroll inside the fixed-height frame rather than clip.
              Flexible(
                child: Container(
                  width: screenW - 32,
                  constraints: BoxConstraints(maxHeight: screenH * 0.78),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                          color: Color(0xFF111111),
                        ),
                        child: preview ??
                            Container(
                              height: 200,
                              color: const Color(0xFFF3F4F6),
                              alignment: Alignment.center,
                              child: const Icon(Icons.hourglass_empty_rounded,
                                  color: Color(0xFFB0B7C3), size: 32),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
