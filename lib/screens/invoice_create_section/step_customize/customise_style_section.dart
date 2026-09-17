// customise_style_section.dart
// lib/screens/invoice_create_section/step_customize/customise_style_section.dart
//
// FILE-SPLIT PASS: pulled out of the former monolithic step_customise.dart
// (was `_ColourSection` and `_FontSection`, now public `ColourSection` and
// `FontSection`). Behavior unchanged from the original file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/invoice_provider.dart';
import '../../../models/invoice_data.dart' show InvoiceColor;
import '../../../models/invoice_color_ext.dart';
import 'customise_shared_widgets.dart';

// COLLAPSIBLE SECTIONS PASS (earlier): Accent Colour is collapsible,
// matching the other cards on this screen.
class ColourSection extends StatelessWidget {
  const ColourSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final selected    = provider.invoiceData.colorScheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SectionCard(
      icon: Icons.palette_rounded,
      title: 'Accent Colour',
      sectionKey: 'accent_colour',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
        ),
        itemCount: InvoiceColor.values.length,
        itemBuilder: (_, i) {
          final scheme = InvoiceColor.values[i];
          final isSelected = scheme == selected;
          return GestureDetector(
            onTap: () => provider.updateColorScheme(scheme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2196F3)
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(scheme.primaryColor),
                            Color(scheme.accentColor),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(9),
                          topRight: Radius.circular(9),
                        ),
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 22))
                          : null,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(9),
                        bottomRight: Radius.circular(9),
                      ),
                    ),
                    child: Text(
                      scheme.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Font section
//
// COLLAPSIBLE SECTIONS + MERGE PASS (earlier): this card is
// collapsible (see SectionCard), and the Text Size slider lives
// inside this same card, after the font chips, separated by a thin
// divider.
// =============================================================================

const _kFonts = [
  'Default',
  'Roboto',
  'Lato',
  'Lora',
  'Montserrat',
  'Nunito',
  'Open Sans',
  'Playfair Display',
  'Raleway',
  'Space Grotesk',
];

class FontSection extends StatelessWidget {
  const FontSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final selected    = provider.invoiceData.fontFamily;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = colorForScheme(provider.invoiceData.colorScheme);
    final size        = provider.fontSize;

    return SectionCard(
      icon: Icons.text_fields_rounded,
      title: 'Font Family',
      sectionKey: 'font_family',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kFonts.map((font) {
              final isActive = font == selected;
              final previewFamily = font == 'Default' ? null : font;
              return GestureDetector(
                onTap: () => provider.updateFontFamily(font),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accent
                        : isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? accent
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    font,
                    style: TextStyle(
                      fontFamily: previewFamily,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // MERGE PASS: Text Size controls, formerly the standalone
          // _SizeSection card — moved in here as-is, separated from the
          // font chips above by a divider.
          const SizedBox(height: 18),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.format_size_rounded, size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Text('Text Size',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('A',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5))),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor:   accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.2),
                    thumbColor:         accent,
                    overlayColor:       accent.withValues(alpha: 0.15),
                    trackHeight:        4,
                  ),
                  child: Slider(
                    value: size,
                    min: 10,
                    max: 14,
                    divisions: 4,
                    onChanged: (v) => provider.updateFontSize(v),
                  ),
                ),
              ),
              Text('A',
                  style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
          Center(
            child: Text(
              '${size.toInt()}pt',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}