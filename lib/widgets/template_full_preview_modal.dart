// template_full_preview_modal.dart
// lib/widgets/template_full_preview_modal.dart
//
// Generic version of invoice_template_previews/template_full_preview_modal.
// dart — that file is hardcoded to InvoiceTemplateInfo/buildInvoicePreview/
// sampleInvoiceData, so it can't be reused by the quote or receipt
// choosers. This version takes the already-built preview widget plus the
// small set of display fields (name, description, accent, premium flag)
// directly, so invoice/quote/receipt choosers can each pass their own
// buildXxxPreview(id, sampleXxxData()) result straight in.
//
// A4-SCALE + SQUARE EDGES PASS (this update): mirrors the identical fix
// applied to invoice_template_previews/template_full_preview_modal.dart.
// The previous version rendered the preview widget at real document scale
// (every template's page is a fixed-size SizedBox at kPageW=595px
// internally) inside a much narrower container (screenW - 32), which
// caused text to wrap awkwardly and threw a genuine RenderFlex overflow
// ("RIGHT OVERFLOWED BY X PIXELS" on-device — confirmed on both the
// invoice and quote choosers' long-press previews, which both call
// showGenericTemplateFullPreview). Now uses the same OverflowBox +
// Transform.scale technique the card thumbnails use — the full
// kPageW×kPageH page scales down to exactly fill the screen width, with
// square corners and a plain white background matching the real PDF
// Preview screen, instead of a rounded "card" with cramped, reflowing
// content. Sample data for all three doc types is a small, fixed 3-line-
// item document that always fits on exactly one page, so a single-page
// height assumption (kPageH) is safe here.

import 'package:flutter/material.dart';
import '../document_layout_templates/01_executive/executive_invoice_stationary_layout.dart'
    show kPageW, kPageH;
import '../helpers/lang_helper.dart';

/// Call this to show the full preview overlay for any doc type. Pass the
/// already-built preview widget (e.g. buildInvoicePreview(id,
/// sampleInvoiceData())) — this modal doesn't know which doc type it's
/// previewing, it just renders whatever widget it's given, scaled to fit
/// an A4 page.
void showGenericTemplateFullPreview(
  BuildContext context, {
  required String name,
  required String description,
  required Color accentColor,
  required bool isPremium,
  required Widget? preview,
}) {
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
    pageBuilder: (context, _, __) => _GenericFullPreviewModal(
      name: name,
      description: description,
      accentColor: accentColor,
      isPremium: isPremium,
      preview: preview,
    ),
  );
}

class _GenericFullPreviewModal extends StatelessWidget {
  final String name;
  final String description;
  final Color accentColor;
  final bool isPremium;
  final Widget? preview;

  const _GenericFullPreviewModal({
    required this.name,
    required this.description,
    required this.accentColor,
    required this.isPremium,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    // Scale the fixed-size A4 page (kPageW × kPageH) to exactly fill the
    // available screen width — same math the card thumbnails use, applied
    // at full-screen size. This is what prevents the wrapping/overflow
    // bug: the page renders at its real internal width and gets scaled
    // down as a whole, rather than being squeezed into a narrower
    // container it wasn't designed to reflow into.
    final pageAreaWidth = screenW - 32; // matches the horizontal padding below
    final scale = pageAreaWidth / kPageW;
    final scaledPageHeight = kPageH * scale;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isPremium) ...[
                      const Icon(Icons.workspace_premium_rounded,
                          color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      name,
                      style: TextStyle(
                          color: accentColor == const Color(0xFF000000)
                              ? Colors.white
                              : accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
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
              // Square corners, full-width A4 page scaled to fit exactly —
              // matches the real PDF Preview screen's look, not a rounded
              // "card" chrome.
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    width: pageAreaWidth,
                    height: preview == null ? 200 : scaledPageHeight,
                    constraints: BoxConstraints(maxHeight: screenH * 0.78),
                    color: Colors.white,
                    child: preview == null
                        ? Container(
                            color: const Color(0xFFF3F4F6),
                            alignment: Alignment.center,
                            child: const Icon(Icons.hourglass_empty_rounded,
                                color: Color(0xFFB0B7C3), size: 32),
                          )
                        : ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              maxWidth: kPageW,
                              maxHeight: kPageH,
                              child: IgnorePointer(
                                child: Transform.scale(
                                  scale: scale,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: kPageW,
                                    height: kPageH,
                                    child: DefaultTextStyle(
                                      style: const TextStyle(
                                        decoration: TextDecoration.none,
                                        decorationColor: Colors.transparent,
                                        color: Color(0xFF111111),
                                      ),
                                      child: preview!,
                                    ),
                                  ),
                                ),
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
