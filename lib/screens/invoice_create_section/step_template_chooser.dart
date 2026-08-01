// step_template_chooser.dart
// lib/screens/cv_edit_section/step_template_chooser.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/cv_provider.dart';
import '../../helpers/lang_helper.dart';
import 'cv_template_chooser_01/preview_registry.dart';
import 'cv_step_template_chooser_registry.dart';
import 'cv_template_chooser_01/template_full_preview_modal.dart';

class StepTemplateChooser extends StatefulWidget {
  final VoidCallback onNext;
  const StepTemplateChooser({super.key, required this.onNext});

  @override
  State<StepTemplateChooser> createState() => _StepTemplateChooserState();
}

class _StepTemplateChooserState extends State<StepTemplateChooser> {
  late final PageController _ctrl;
  late int _current;
  late int _selectedId;

  late final List<Widget> _cachedPreviews;

  Offset? _pointerDownPos;
  bool    _longPressFired = false;
  Timer?  _longPressTimer;
  double  _carouselWidth = 0;

  static const double   _swipeThreshold   = 10.0;
  static const Duration _longPressDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    final savedTemplateId = context.read<CVProvider>().templateId;
    _selectedId = savedTemplateId;
    final savedIndex =
        kAllTemplates.indexWhere((t) => t.id == savedTemplateId);
    final initialPage = savedIndex != -1 ? savedIndex : 0;
    _current = initialPage;
    _ctrl = PageController(viewportFraction: 0.72, initialPage: initialPage);
    _cachedPreviews = List.generate(kAllTemplates.length, (i) {
      return RepaintBoundary(
        child: IgnorePointer(
          child: StepChooserScaledPreview(templateId: kAllTemplates[i].id),
        ),
      );
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPos = event.localPosition;
    _longPressFired = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_longPressDuration, () {
      final pos = _pointerDownPos;
      if (pos == null || _longPressFired) return;
      _longPressFired = true;
      final t = _templateAt(pos);
      if (t != null) {
        HapticFeedback.mediumImpact();
        showTemplateFullPreview(context, info: t);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    final down = _pointerDownPos;
    if (down == null) return;
    if ((event.localPosition - down).distance > _swipeThreshold) {
      _longPressTimer?.cancel();
      _pointerDownPos = null;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
    final down = _pointerDownPos;
    _pointerDownPos = null;
    if (down == null || _longPressFired) return;
    if ((event.localPosition - down).distance <= _swipeThreshold) {
      final t = _templateAt(down);
      if (t != null) {
        HapticFeedback.lightImpact();
        setState(() => _selectedId = t.id);
        context.read<CVProvider>().updateTemplateId(t.id);
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _longPressTimer?.cancel();
    _pointerDownPos = null;
  }

  TemplateCardInfo? _templateAt(Offset localPos) {
    if (!_ctrl.hasClients || _carouselWidth == 0) return null;
    const cardMargin = 12.0;
    final cardWidth  = _carouselWidth * 0.72;
    final slotWidth  = cardWidth + cardMargin;
    final currentPage = _ctrl.page ?? _current.toDouble();
    final centerX     = _carouselWidth / 2;
    final tapOffset   = localPos.dx - centerX;
    final index = (currentPage + tapOffset / slotWidth)
        .round()
        .clamp(0, kAllTemplates.length - 1);
    return kAllTemplates[index];
  }

  // -- 30-CV limit dialog -----------------------------------------------------
  void _showLimitDialog() {
    final t           = getLang(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_off_rounded,
                  color: Color(0xFFFF9800),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t['limit_dialog_title'] ?? 'CV Limit Reached',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t['limit_dialog_body'] ??
                    'You\'ve reached the maximum of 30 CVs. Please delete an existing CV before creating a new one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: Text(
                    t['limit_dialog_go_to_my_cvs'] ?? 'Go to My CVs',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    t['limit_dialog_cancel'] ?? 'Cancel',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onContinue() {
    final provider = context.read<CVProvider>();

    if (provider.savedCvs.length >= 30) {
      _showLimitDialog();
      return;
    }

    final selected    = kAllTemplates.firstWhere((t) => t.id == _selectedId);
    final t           = getLang(context);
    provider.updateTemplateId(_selectedId);

    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _SaveCvModal(
        template: selected,
        isDark: isDark,
        translations: t,
        onSave: (name) {
          provider.saveCurrentCv(
            name: name,
            templateName: selected.name,
            defaultTitle: name,
          );
          widget.onNext();
        },
        onLoadExisting: (cv) {
          provider.loadSavedCv(cv.id);
          setState(() => _selectedId = cv.templateId);
          final idx = kAllTemplates.indexWhere((t) => t.id == cv.templateId);
          if (idx != -1) {
            _ctrl.animateToPage(idx,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic);
          }
          widget.onNext();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t           = getLang(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t['chooser_title'] ?? 'Pick Your Template',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t['chooser_subtitle'] ?? 'Swipe to browse  ·  Tap to select  ·  Hold to preview',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  _carouselWidth = constraints.maxWidth;
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown:   _onPointerDown,
                    onPointerMove:   _onPointerMove,
                    onPointerUp:     _onPointerUp,
                    onPointerCancel: _onPointerCancel,
                    child: PageView.builder(
                      controller: _ctrl,
                      itemCount: kAllTemplates.length,
                      physics: const _SnapPhysics(),
                      onPageChanged: (i) {
                        setState(() => _current = i);
                        HapticFeedback.selectionClick();
                      },
                      itemBuilder: (context, index) {
                        final tmpl       = kAllTemplates[index];
                        final isActive   = index == _current;
                        final isSelected = _selectedId == tmpl.id;

                        final translatedName = t[tmpl.name] ?? tmpl.name;
                        final translatedDesc = t[tmpl.description] ?? tmpl.description;

                        return AnimatedContainer(
                          key: ValueKey(tmpl.id),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          margin: EdgeInsets.only(
                            right:  12,
                            top:    isActive ?  8 : 28,
                            bottom: isActive ?  8 : 28,
                          ),
                          child: _EditorCard(
                            template:        tmpl,
                            isActive:        isActive,
                            isSelected:      isSelected,
                            cachedPreview:   _cachedPreviews[index],
                            translatedName:  translatedName,
                            translatedDesc:  translatedDesc,
                            holdHint:        t['chooser_card_hold_hint'] ?? 'Hold to preview',
                            selectedBadge:   t['chooser_card_selected_badge'] ?? 'Selected',
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),

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
                        duration: const Duration(milliseconds: 400),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width:  active ? 18 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: active
                              ? kAllTemplates[_current].accentColor
                              : (isDark
                                  ? colorScheme.onSurface.withOpacity(0.2)
                                  : const Color(0xFFD0D0D0)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        _BottomNavBar(
          selectedTemplate: kAllTemplates.firstWhere((t) => t.id == _selectedId),
          translations: t,
          onContinue: _onContinue,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Unified Save Modal
// -----------------------------------------------------------------------------
class _SaveCvModal extends StatefulWidget {
  final TemplateCardInfo template;
  final bool isDark;
  final Map<String, String> translations;
  final void Function(String name) onSave;
  final void Function(SavedCv cv) onLoadExisting;

  const _SaveCvModal({
    required this.template,
    required this.isDark,
    required this.translations,
    required this.onSave,
    required this.onLoadExisting,
  });

  @override
  State<_SaveCvModal> createState() => _SaveCvModalState();
}

class _SaveCvModalState extends State<_SaveCvModal> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  int _len = 0;

  Map<String, String> get t => widget.translations;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _len = _ctrl.text.length));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) { _focus.requestFocus(); return; }
    Navigator.pop(context);
    widget.onSave(name);
  }

  Color _accentFor(SavedCv cv) {
    try {
      return kAllTemplates.firstWhere((t) => t.id == cv.templateId).accentColor;
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

  Color _statusColor(SavedCvStatus s) {
    switch (s) {
      case SavedCvStatus.complete: return const Color(0xFF4CAF50);
      case SavedCvStatus.saved:    return const Color(0xFF2196F3);
      case SavedCvStatus.draft:    return const Color(0xFFFF9800);
    }
  }

  String _statusLabel(SavedCvStatus s) {
    switch (s) {
      case SavedCvStatus.complete: return t['saved_status_complete'] ?? 'Complete';
      case SavedCvStatus.saved:    return t['saved_status_saved']    ?? 'Saved';
      case SavedCvStatus.draft:    return t['saved_status_draft']    ?? 'Draft';
    }
  }

  IconData _statusIcon(SavedCvStatus s) {
    switch (s) {
      case SavedCvStatus.complete: return Icons.check_circle_rounded;
      case SavedCvStatus.saved:    return Icons.bookmark_rounded;
      case SavedCvStatus.draft:    return Icons.edit_rounded;
    }
  }

  Widget _buildCvCard(SavedCv cv) {
    final cvAccent    = _accentFor(cv);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = widget.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          widget.onLoadExisting(cv);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? cvAccent.withOpacity(0.2)
                  : const Color(0xFFF0F0F0),
            ),
            boxShadow: [
              BoxShadow(
                color: cvAccent.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cvAccent, cvAccent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    cv.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle: title / meta / progress bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cv.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.style_rounded, size: 10, color: cvAccent),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              cv.templateName,
                              style: TextStyle(
                                fontSize: 10,
                                color: cvAccent,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 10,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(cv.lastEditedAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: cv.completionPercent / 100,
                          backgroundColor: isDark
                              ? colorScheme.onSurface.withOpacity(0.1)
                              : const Color(0xFFF0F0F0),
                          valueColor: AlwaysStoppedAnimation<Color>(cvAccent),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right: status badge + arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(cv.status)
                            .withOpacity(isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(cv.status),
                            size: 8,
                            color: _statusColor(cv.status),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _statusLabel(cv.status),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(cv.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: cvAccent.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent      = widget.template.accentColor;
    final savedCvs    = context.watch<CVProvider>().savedCvs;
    final hasSaved    = savedCvs.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = widget.isDark;

    final translatedTplName = t[widget.template.name] ?? widget.template.name;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Template badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.style_rounded, size: 13, color: accent),
                const SizedBox(width: 5),
                Text(
                  translatedTplName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            Text(
              t['chooser_modal_heading'] ?? 'Name Your CV',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t['chooser_modal_sub'] ?? 'Give it a name to find it easily.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 20),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                t['chooser_modal_field_label'] ?? 'CV Name',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '$_len/60',
                style: TextStyle(
                  fontSize: 11,
                  color: _len > 60
                      ? const Color(0xFFEF5350)
                      : colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ]),
            const SizedBox(height: 6),

            TextField(
              controller: _ctrl,
              focusNode: _focus,
              maxLength: 60,
              style: TextStyle(color: colorScheme.onSurface),
              buildCounter: (_, {required currentLength,
                  required isFocused, maxLength}) => null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: t['detail_rename_hint'] ?? 'e.g. Software Engineer CV',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.35),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF8F9FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                suffixIcon: _len > 0
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        onPressed: () => _ctrl.clear(),
                      )
                    : null,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _len == 0 ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: isDark
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFE0E0E0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      t['chooser_modal_save_btn'] ?? 'Save & Start',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -- Existing CVs -----------------------------------------------
            if (hasSaved) ...[
              const SizedBox(height: 28),
              Row(children: [
                Expanded(child: Divider(color: colorScheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    t['chooser_modal_divider'] ?? 'or continue with existing CV',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.35),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colorScheme.outlineVariant)),
              ]),
              const SizedBox(height: 14),

              ...savedCvs.take(5).map(_buildCvCard),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple date formatter — avoids needing the intl package.
String _formatDate(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

// -----------------------------------------------------------------------------
// Individual carousel card
// -----------------------------------------------------------------------------
class _EditorCard extends StatelessWidget {
  final TemplateCardInfo template;
  final bool isActive;
  final bool isSelected;
  final Widget cachedPreview;
  final String translatedName;
  final String translatedDesc;
  final String holdHint;
  final String selectedBadge;

  const _EditorCard({
    required this.template,
    required this.isActive,
    required this.isSelected,
    required this.cachedPreview,
    required this.translatedName,
    required this.translatedDesc,
    required this.holdHint,
    required this.selectedBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: template.accentColor, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: template.accentColor.withOpacity(isActive ? 0.32 : 0.10),
            blurRadius: isActive ? 22 : 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSelected ? 18 : 20),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge, // prevents overflow errors during card animation
          children: [
            cachedPreview,
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(isActive ? 0.70 : 0.55),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  stops: const [0.42, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hold-to-preview hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.remove_red_eye_outlined,
                            color: Colors.white70, size: 9),
                        const SizedBox(width: 3),
                        Text(
                          holdHint,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    translatedName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    translatedDesc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 12,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 6)
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: template.accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            selectedBadge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom nav bar
// -----------------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  final TemplateCardInfo selectedTemplate;
  final Map<String, String> translations;
  final VoidCallback onContinue;

  const _BottomNavBar({
    required this.selectedTemplate,
    required this.translations,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t           = translations;

    final translatedName = t[selectedTemplate.name] ?? selectedTemplate.name;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: selectedTemplate.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selectedTemplate.accentColor.withOpacity(0.3)),
            ),
            child: Icon(Icons.style_rounded,
                color: selectedTemplate.accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translatedName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selectedTemplate.accentColor,
                  ),
                ),
                Text(
                  t['chooser_nav_selected_sub'] ?? 'Selected template',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onContinue,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x502196F3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t['chooser_nav_cta'] ?? 'Save & Continue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Relaxed page snap physics
// -----------------------------------------------------------------------------
class _SnapPhysics extends PageScrollPhysics {
  const _SnapPhysics() : super(parent: const ClampingScrollPhysics());

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) => const _SnapPhysics();

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 200, stiffness: 30, damping: 1);
}