// custom_image_sizer.dart
// lib/screens/cv_edit_section/step_customize/custom_image_sizer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/cv_provider.dart';
import '../../../../helpers/lang_helper.dart';
import 'section_card.dart';

class CustomImageSizer extends StatelessWidget {
  const CustomImageSizer({super.key});

  @override
  Widget build(BuildContext context) {
    final t           = watchLang(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CVProvider>(
      builder: (context, provider, _) {
        const noImageTemplates = {15, 18};
        if (noImageTemplates.contains(provider.templateId)) {
          return const SizedBox.shrink();
        }

        final imageSize = provider.cvData.imageSize;

        return SectionCard(
          title:     t['customize_image_size_title'] ?? 'Profile Image Size',
          icon:      Icons.photo_size_select_large_rounded,
          iconColor: const Color(0xFF9C27B0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t['customize_image_size_label'] ?? 'Image Size',
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
                      (t['customize_image_size_value'] ?? '{n} pt')
                          .replaceAll('{n}', '${imageSize.round()}'),
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
                  thumbColor:   const Color(0xFF9C27B0),
                  overlayColor: const Color(0xFF9C27B0).withOpacity(0.15),
                  trackHeight: 5,
                ),
                child: Slider(
                  value:     imageSize.clamp(10.0, 16.0),
                  min:       10,
                  max:       16,
                  divisions: 6,
                  onChanged: (v) => provider.updateImageSize(v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t['customize_image_size_min'] ?? 'Small',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.35))),
                  Text(t['customize_image_size_max'] ?? 'Large',
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
