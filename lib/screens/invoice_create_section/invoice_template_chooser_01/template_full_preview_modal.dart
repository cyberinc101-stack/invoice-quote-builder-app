// template_full_preview_modal.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/template_full_preview_modal.dart

import 'package:flutter/material.dart';
import 'preview_registry.dart';
import 'cv_fullscreen_preview_individual_files/previews_index.dart';
import '../../../helpers/lang_helper.dart';

/// Call this to show the full preview overlay.
void showTemplateFullPreview(
  BuildContext context, {
  required TemplateCardInfo info,
}) {
  // getLang uses context.read — safe to call outside build().
  // watchLang uses context.watch which is only valid inside build()
  // and throws "Tried to listen from outside the widget tree" here.
  final t = getLang(context);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: t['preview_modal_barrier_label'] ?? 'Close preview',
    barrierColor: Colors.black.withOpacity(0.75),
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

// -----------------------------------------------------------------------------
// Modal shell
// -----------------------------------------------------------------------------
class _FullPreviewModal extends StatelessWidget {
  final TemplateCardInfo info;
  const _FullPreviewModal({required this.info});

  @override
  Widget build(BuildContext context) {
    final t       = getLang(context);
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    final displayName        = t[info.name]        ?? info.name;
    final displayDescription = t[info.description] ?? info.description;

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
                    color: info.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: info.accentColor.withOpacity(0.4)),
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
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // -- CV preview sheet ------------------------------------------
              Flexible(
                child: Container(
                  width: screenW - 32,
                  constraints: BoxConstraints(maxHeight: screenH * 0.78),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        color: Color(0xFF111111),
                      ),
                      child: _previewForTemplate(info.id),
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

  Widget _previewForTemplate(int id) {
    switch (id) {
      case 1:                    return const PreviewExec();
      case kTemplateIdArchivist: return const PreviewArchivist();
      case 2:                    return const PreviewNordic();
      case kTemplateIdDiplomat:  return const PreviewDiplomat();
      case 3:                    return const PreviewVibrant();
      case kTemplateIdMeridian:  return const PreviewMeridian();
      case 4:                    return const PreviewTech();
      case kTemplateIdMomentum:  return const PreviewMomentum();
      case 5:  return const PreviewLuxury();
      case 6:  return const PreviewGradientModern();
      case 7:  return const PreviewEditorial();
      case 8:  return const PreviewPastelSoft();
      case 9:  return const PreviewBrutalist();
      case 10: return const PreviewEmerald();
      case 11: return const PreviewInfographic();
      case 12: return const PreviewArtDeco();
      case 13: return const PreviewWina();
      case 14: return const PreviewRio();
      case 15: return const PreviewSummer();
      case 16: return const PreviewHelene();
      case 17: return const PreviewCanfield();
      case 18: return const PreviewCollins();
      case 19: return const PreviewTony();
      case 20: return const PreviewFashion();
      default: return const PreviewExec();
    }
  }
}