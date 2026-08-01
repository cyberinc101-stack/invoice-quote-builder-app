// customize_font_section.dart
// lib/screens/cv_edit_section/step_customize/customize_font_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/cv_provider.dart';
import '../../../../cv_templates/template_palettes.dart';
import '../../../../cv_template_data/cv_template_data.dart';
import '../../../../helpers/lang_helper.dart';
import 'customize_color_section.dart';
import 'section_card.dart';

class CustomizeFontSection extends StatelessWidget {
  const CustomizeFontSection({super.key});

  static TextStyle _fontStyle(
    String fontName, {
    double fontSize       = 15,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontName,
      fontSize:   fontSize,
      fontWeight: fontWeight,
      color:      color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t           = watchLang(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CVProvider>(
      builder: (context, provider, _) {
        final templateId = provider.templateId;
        final fonts      = fontsForTemplate(templateId);
        final selected   = fonts.contains(provider.cvData.fontFamily)
            ? provider.cvData.fontFamily
            : fonts.first;
        final accent     = cvColorToFlutter(provider.cvData.colorScheme);

        if (selected != provider.cvData.fontFamily) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.updateFontFamily(selected);
          });
        }

        final fieldBg = isDark
            ? const Color(0xFF252840)
            : const Color(0xFFF8F9FC);
        final fieldBorder = isDark
            ? colorScheme.outline.withOpacity(0.25)
            : const Color(0xFFE8E8E8);

        return SectionCard(
          title:     t['customize_font_family_title'] ?? 'Font Family',
          icon:      Icons.text_fields_rounded,
          iconColor: accent,
          child: GestureDetector(
            onTap: () => _showFontPicker(
                context, fonts, selected, provider, accent, t),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color:        fieldBg,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: fieldBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected,
                      style: _fontStyle(
                        selected,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurface.withOpacity(0.45),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFontPicker(
    BuildContext context,
    List<String> fonts,
    String selected,
    CVProvider provider,
    Color accent,
    Map<String, String> t,
  ) {
    showModalBottomSheet(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      useSafeArea:        true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.60,
        minChildSize:     0.40,
        maxChildSize:     0.92,
        expand:           false,
        builder: (sheetContext, scrollController) => _FontPickerSheet(
          fonts:            fonts,
          selected:         selected,
          accent:           accent,
          translations:     t,
          scrollController: scrollController,
          onSelect: (font) {
            provider.updateFontFamily(font);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _FontPickerSheet
// -----------------------------------------------------------------------------
class _FontPickerSheet extends StatelessWidget {
  final List<String>         fonts;
  final String               selected;
  final Color                accent;
  final Map<String, String>  translations;
  final ScrollController     scrollController;
  final ValueChanged<String> onSelect;

  const _FontPickerSheet({
    required this.fonts,
    required this.selected,
    required this.accent,
    required this.translations,
    required this.scrollController,
    required this.onSelect,
  });

  static TextStyle _fontStyle(
    String fontName, {
    double fontSize       = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontName,
      fontSize:   fontSize,
      fontWeight: fontWeight,
      color:      color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t           = translations;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bottomPad   = MediaQuery.of(context).padding.bottom;

    final sheetBg   = isDark ? const Color(0xFF1E2235) : Colors.white;
    final handleBg  = isDark
        ? colorScheme.outline.withOpacity(0.4)
        : const Color(0xFFE0E0E0);
    final itemBg    = isDark ? const Color(0xFF252840) : const Color(0xFFF8F9FC);
    final itemBorder = isDark
        ? colorScheme.outline.withOpacity(0.2)
        : const Color(0xFFE8E8E8);

    return Container(
      decoration: BoxDecoration(
        color:        sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // -- Fixed header ------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color:        handleBg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t['customize_font_picker_title'] ?? 'Choose Font',
                  style: TextStyle(
                    fontSize:   17,
                    fontWeight: FontWeight.w800,
                    color:      colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t['customize_font_picker_sub'] ?? 'Select a font for your CV.',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.45)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // -- Scrollable font list -----------------------------------------
          Expanded(
            child: ListView.builder(
              controller:  scrollController,
              padding:     EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
              itemCount:   fonts.length,
              itemBuilder: (context, index) {
                final font       = fonts[index];
                final isSelected = font == selected;

                return GestureDetector(
                  onTap: () => onSelect(font),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin:   const EdgeInsets.only(bottom: 8),
                    padding:  const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected ? accent : itemBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accent : itemBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                font,
                                style: _fontStyle(
                                  font,
                                  fontSize:   15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t['customize_font_preview_sample'] ?? 'The quick brown fox',
                                style: _fontStyle(
                                  font,
                                  fontSize:   12,
                                  fontWeight: FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white70
                                      : colorScheme.onSurface.withOpacity(0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
