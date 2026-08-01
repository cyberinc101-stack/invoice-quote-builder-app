// lib/widgets/swipable_cv_templates_homescreen_widgets/swipable_cv_templates.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/cv_edit_section/cv_template_chooser_01/template_full_preview_modal.dart';
import '../../screens/cv_edit_section/cv_template_chooser_01/preview_registry.dart'
    show TemplateCardInfo, kAllTemplates, buildMiniPreview;
import '../../helpers/lang_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────
class SwipableCvTemplates extends StatefulWidget {
  final void Function(int templateId)? onTemplateSelected;

  const SwipableCvTemplates({super.key, this.onTemplateSelected});

  @override
  State<SwipableCvTemplates> createState() => _SwipableCvTemplatesState();
}

class _SwipableCvTemplatesState extends State<SwipableCvTemplates> {
  late final PageController _ctrl;
  int _current = 0;

  late final List<Widget> _cachedPreviews;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.68);
    _cachedPreviews = List.generate(kAllTemplates.length, (i) {
      return RepaintBoundary(
        child: _ScaledMiniPreview(templateId: kAllTemplates[i].id),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // FIX: accepts the BuildContext from the itemBuilder so the modal is
  // opened from a context that is properly inside the Provider widget tree.
  // Using the State's `context` caused "listened from outside widget tree".
  void _openPreview(BuildContext itemContext, TemplateCardInfo tmplInfo) {
    HapticFeedback.lightImpact();
    showTemplateFullPreview(itemContext, info: tmplInfo);
  }

  @override
  Widget build(BuildContext context) {
    // FIX: renamed from `t` to `lang` so it cannot be accidentally
    // shadowed by any TemplateCardInfo parameter named `t`.
    final lang = getLang(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section heading ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Text(
            lang['swipe_section_title'] ?? 'Choose Template',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── Carousel ─────────────────────────────────────────────────
        LayoutBuilder(builder: (context, constraints) {
          final cardW     = constraints.maxWidth * 0.68;
          final carouselH = cardW * 1.08;
          return SizedBox(
            height: carouselH,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: kAllTemplates.length,
              physics: const _SnapPagePhysics(),
              onPageChanged: (i) {
                setState(() => _current = i);
                HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) {
                final tmpl     = kAllTemplates[index];
                final isActive = index == _current;

                // Resolve translated name & description using `lang`
                final translatedName = lang[tmpl.name] ?? tmpl.name;
                final translatedDesc = lang[tmpl.description] ?? tmpl.description;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  margin: EdgeInsets.only(
                    right:  10,
                    top:    isActive ? 0 : 16,
                    bottom: isActive ? 0 : 16,
                  ),
                  child: RepaintBoundary(
                    child: _TemplateCard(
                      template:        tmpl,
                      isActive:        isActive,
                      cachedPreview:   _cachedPreviews[index],
                      photoBadgeLabel: lang['swipe_photo_badge'] ?? 'Photo',
                      translatedName:  translatedName,
                      translatedDesc:  translatedDesc,
                      onTap:           () => _openPreview(context, tmpl),
                    ),
                  ),
                );
              },
            ),
          );
        }),

        // ── Dot indicator ─────────────────────────────────────────────
        const SizedBox(height: 12),
        SizedBox(
          height: 6,
          child: Center(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: kAllTemplates.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (_, i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width:  active ? 18 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: active
                        ? kAllTemplates[_current].accentColor
                        : const Color(0xFFD0D0D0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom scroll physics
// ─────────────────────────────────────────────────────────────────────────────
class _SnapPagePhysics extends PageScrollPhysics {
  const _SnapPagePhysics() : super(parent: const ClampingScrollPhysics());

  @override
  _SnapPagePhysics applyTo(ScrollPhysics? ancestor) =>
      const _SnapPagePhysics();

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 200, stiffness: 30, damping: 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual card
// ─────────────────────────────────────────────────────────────────────────────
class _TemplateCard extends StatelessWidget {
  final TemplateCardInfo template;
  final bool isActive;
  final Widget cachedPreview;
  final String photoBadgeLabel;
  final String translatedName;
  final String translatedDesc;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isActive,
    required this.cachedPreview,
    required this.photoBadgeLabel,
    required this.translatedName,
    required this.translatedDesc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: template.accentColor.withOpacity(isActive ? 0.35 : 0.10),
              blurRadius: isActive ? 22 : 6,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              cachedPreview,

              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(isActive ? 0.70 : 0.58),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.38, 1.0],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(translatedName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                        )),
                    const SizedBox(height: 2),
                    Text(translatedDesc,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 11,
                          shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                        )),
                  ],
                ),
              ),

              if (template.hasPhoto)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.22)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_a_photo_rounded,
                          color: Colors.white70, size: 9),
                      const SizedBox(width: 3),
                      Text(photoBadgeLabel,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scaled mini-preview
// ─────────────────────────────────────────────────────────────────────────────
class _ScaledMiniPreview extends StatelessWidget {
  final int templateId;
  const _ScaledMiniPreview({required this.templateId});

  static const _designW = 320.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final scale = constraints.maxWidth / _designW;

      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: _designW,
          maxHeight: double.infinity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _designW,
              child: buildMiniPreview(templateId),
            ),
          ),
        ),
      );
    });
  }
}