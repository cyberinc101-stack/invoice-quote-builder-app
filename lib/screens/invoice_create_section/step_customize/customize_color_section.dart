// customize_color_section.dart
// lib/screens/cv_edit_section/step_customize/customize_color_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/cv_data.dart';
import '../../../../providers/cv_provider.dart';
import '../../../../cv_templates/template_palettes.dart';
import '../../../../helpers/lang_helper.dart';
import 'section_card.dart';

const Color _kNordicBlue    = Color(0xFF2563EB);
const Color _kExecGold      = Color(0xFFC9A84C);
const Color _kNeonBlue      = Color(0xFF4DD0E1);
const Color _kBlueprintNavy = Color(0xFF1A3A6B);
const Color _kLightGrey     = Color(0xFF9E9E9E);

String _colorLabel(CVColor c, Map<String, String> t, {int templateId = 0}) {
  switch (c) {
    case CVColor.black:           return t['color_black']           ?? 'Black';
    case CVColor.blue:            return t['color_blue']            ?? 'Blue';
    case CVColor.nordicBlue:      return t['color_nordic_blue']     ?? 'Nordic Blue';
    case CVColor.indigo:          return t['color_indigo']          ?? 'Indigo';
    case CVColor.teal:            return t['color_teal']            ?? 'Teal';
    case CVColor.green:           return t['color_green']           ?? 'Green';
    case CVColor.purple:          return t['color_purple']          ?? 'Purple';
    case CVColor.orange:          return t['color_orange']          ?? 'Orange';
    case CVColor.red:             return t['color_red']             ?? 'Red';
    case CVColor.executiveGold:   return t['color_executive_gold']  ?? 'Executive Gold';
    case CVColor.vibrantCoral:    return t['color_vibrant_coral']   ?? 'Vibrant Coral';
    case CVColor.white:
      return templateId == 11
          ? (t['color_white_bg']  ?? 'White Background')
          : (t['color_white']     ?? 'White');
    case CVColor.maroon:          return t['color_maroon']          ?? 'Maroon';
    case CVColor.brutalistYellow: return t['color_brutalist_yellow']?? 'Brutalist Yellow';
    case CVColor.neonBlue:        return t['color_neon_blue']       ?? 'Neon Blue';
    case CVColor.blueprintNavy:   return t['color_blueprint_navy']  ?? 'Blueprint Navy';
    case CVColor.lightGrey:       return t['color_light_grey']      ?? 'Light Grey';
  }
}

class CustomizeColorSection extends StatefulWidget {
  const CustomizeColorSection({super.key});

  @override
  State<CustomizeColorSection> createState() => _CustomizeColorSectionState();
}

class _CustomizeColorSectionState extends State<CustomizeColorSection> {
  bool _open = false;
  int? _lastTemplateId;

  @override
  Widget build(BuildContext context) {
    final t           = watchLang(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    final fieldBg     = isDark
        ? const Color(0xFF252840)
        : const Color(0xFFF8F9FC);
    final fieldBorder = isDark
        ? colorScheme.outline.withOpacity(0.25)
        : const Color(0xFFE0E0E0);

    return Consumer<CVProvider>(
      builder: (context, provider, _) {
        final cvData     = provider.cvData;
        final templateId = provider.templateId;
        final palette    = paletteForTemplate(templateId);

        if (templateId == 4 || templateId == 6) return const SizedBox.shrink();

        if (_lastTemplateId != templateId) {
          _lastTemplateId = templateId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.updateColorScheme(palette.first);
          });
        } else if (!palette.contains(cvData.colorScheme)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.updateColorScheme(palette.first);
          });
        }

        if (palette.length <= 1) return const SizedBox.shrink();

        final selectedColor   = cvData.colorScheme;
        final selectedFlutter = cvColorToFlutter(selectedColor);

        return SectionCard(
          title:     t['customize_color_section_title'] ?? 'Accent Colour',
          icon:      Icons.palette_rounded,
          iconColor: const Color(0xFFE91E63),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Trigger row ----------------------------------------------
              GestureDetector(
                onTap: () => setState(() => _open = !_open),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _open ? selectedFlutter : fieldBorder,
                      width: _open ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: selectedFlutter,
                        borderRadius: BorderRadius.circular(6),
                        border: selectedFlutter == const Color(0xFFFFFFFF) ||
                                selectedFlutter == _kLightGrey
                            ? Border.all(color: fieldBorder)
                            : null,
                        boxShadow: [BoxShadow(
                          color: selectedFlutter.withOpacity(0.35),
                          blurRadius: 6, offset: const Offset(0, 2),
                        )],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _colorLabel(selectedColor, t, templateId: templateId),
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      colorScheme.onSurface),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns:    _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurface.withOpacity(0.45),
                          size: 22),
                    ),
                  ]),
                ),
              ),

              // -- Dropdown list --------------------------------------------
              AnimatedCrossFade(
                firstChild:  const SizedBox.shrink(),
                secondChild: _ColorList(
                  palette:    palette,
                  selected:   selectedColor,
                  templateId: templateId,
                  fieldBg:    fieldBg,
                  fieldBorder: fieldBorder,
                  translations: t,
                  onSelect: (c) {
                    provider.updateColorScheme(c);
                    setState(() => _open = false);
                  },
                ),
                crossFadeState: _open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// _ColorList
// -----------------------------------------------------------------------------
class _ColorList extends StatelessWidget {
  final List<CVColor>          palette;
  final CVColor                selected;
  final int                    templateId;
  final Color                  fieldBg;
  final Color                  fieldBorder;
  final Map<String, String>    translations;
  final void Function(CVColor) onSelect;

  const _ColorList({
    required this.palette,
    required this.selected,
    required this.templateId,
    required this.fieldBg,
    required this.fieldBorder,
    required this.translations,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          color:        fieldBg,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: fieldBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: palette.asMap().entries.map((entry) {
            final i       = entry.key;
            final cvColor = entry.value;
            final color   = cvColorToFlutter(cvColor);
            final isFirst = i == 0;
            final isLast  = i == palette.length - 1;
            final isSel   = cvColor == selected;

            return GestureDetector(
              onTap: () => onSelect(cvColor),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isSel ? color.withOpacity(isDark ? 0.15 : 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.vertical(
                    top:    isFirst ? const Radius.circular(11) : Radius.zero,
                    bottom: isLast  ? const Radius.circular(11) : Radius.zero,
                  ),
                  border: i < palette.length - 1
                      ? BorderDirectional(bottom: BorderSide(
                          color: isDark
                              ? colorScheme.outline.withOpacity(0.12)
                              : const Color(0xFFEEEEEE),
                          width: 1))
                      : null,
                ),
                child: Row(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color:        color,
                      borderRadius: BorderRadius.circular(5),
                      border: color == const Color(0xFFFFFFFF) ||
                              color == _kLightGrey
                          ? Border.all(color: fieldBorder)
                          : null,
                      boxShadow: [BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4, offset: const Offset(0, 1),
                      )],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _colorLabel(cvColor, translations, templateId: templateId),
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color:      isSel
                          ? color
                          : colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  if (isSel)
                    Icon(Icons.check_rounded, color: color, size: 18),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

Color cvColorToFlutter(CVColor c) {
  switch (c) {
    case CVColor.black:           return const Color(0xFF212121);
    case CVColor.blue:            return const Color(0xFF2196F3);
    case CVColor.nordicBlue:      return _kNordicBlue;
    case CVColor.green:           return const Color(0xFF4CAF50);
    case CVColor.purple:          return const Color(0xFF9C27B0);
    case CVColor.orange:          return const Color(0xFFFF9800);
    case CVColor.red:             return const Color(0xFFF44336);
    case CVColor.teal:            return const Color(0xFF009688);
    case CVColor.indigo:          return const Color(0xFF3F51B5);
    case CVColor.executiveGold:   return _kExecGold;
    case CVColor.vibrantCoral:    return const Color(0xFFFF6B6B);
    case CVColor.white:           return const Color(0xFFFFFFFF);
    case CVColor.maroon:          return const Color(0xFF800000);
    case CVColor.brutalistYellow: return const Color(0xFFFFE500);
    case CVColor.neonBlue:        return _kNeonBlue;
    case CVColor.blueprintNavy:   return _kBlueprintNavy;
    case CVColor.lightGrey:       return _kLightGrey;
  }
}
