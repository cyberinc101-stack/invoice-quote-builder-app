// customize_size_section.dart
// lib/screens/cv_edit_section/step_customize/customize_size_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/cv_provider.dart';
import '../../../../helpers/lang_helper.dart';
import 'section_card.dart';

class CustomizeSizeSection extends StatelessWidget {
  const CustomizeSizeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t           = watchLang(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CVProvider>(
      builder: (context, provider, _) {
        final fontSize = provider.cvData.fontSize;

        return SectionCard(
          title:     t['customize_font_size_title'] ?? 'Font Size',
          icon:      Icons.format_size_rounded,
          iconColor: const Color(0xFF9C27B0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t['customize_font_size_label'] ?? 'Text Size',
                    style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.55)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0)
                          .withOpacity(isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (t['customize_font_size_value'] ?? '{n} pt')
                          .replaceAll('{n}', '${fontSize.round()}'),
                      style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w800,
                        color:      Color(0xFF9C27B0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor:   const Color(0xFF9C27B0),
                  inactiveTrackColor: isDark
                      ? colorScheme.outline.withOpacity(0.3)
                      : const Color(0xFFE0E0E0),
                  thumbColor:  const Color(0xFF9C27B0),
                  overlayColor: const Color(0xFF9C27B0).withOpacity(0.15),
                  trackHeight: 5,
                ),
                child: Slider(
                  value:     fontSize.clamp(10.0, 16.0),
                  min:       10,
                  max:       16,
                  divisions: 6,
                  onChanged: (v) => provider.updateFontSize(v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t['customize_font_size_min'] ?? 'Small',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.35))),
                  Text(t['customize_font_size_max'] ?? 'Large',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.35))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
