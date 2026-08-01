import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../models/invoice_data.dart';
import '../language_keys/lang_en_english.dart'; // swap for active locale map at runtime

class CustomizationPanel extends StatelessWidget {
  const CustomizationPanel({super.key});

  // Active translation map — replace with the user's chosen locale map at runtime.
  static const Map<String, String> _t = enEnglish;

  @override
  Widget build(BuildContext context) {
    return Consumer<CVProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildColorSchemeSection(context, provider),
              const SizedBox(height: 24),
              _buildFontSection(context, provider),
              const SizedBox(height: 24),
              _buildTemplatePreview(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorSchemeSection(BuildContext context, CVProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 12),
                Text(
                  _t['custom_color_scheme_title']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: CVColor.values.map((color) {
                final isSelected = provider.cvData.colorScheme == color;
                return InkWell(
                  onTap: () => provider.updateColorScheme(color),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getColor(color),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSection(BuildContext context, CVProvider provider) {
    final fonts = [
      'Roboto', 'Open Sans', 'Lato', 'Montserrat',
      'Raleway', 'Poppins', 'Merriweather', 'Playfair Display',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields),
                const SizedBox(width: 12),
                Text(
                  _t['custom_font_settings_title']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: provider.cvData.fontFamily,
              decoration: InputDecoration(
                labelText: _t['custom_font_family_label'],
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: fonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(font, style: TextStyle(fontFamily: font)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) provider.updateFontFamily(value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(_t['custom_font_size_label']!),
                Text(
                  '${provider.cvData.fontSize.toInt()}pt',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: provider.cvData.fontSize,
              min: 9,
              max: 14,
              divisions: 10,
              label: '${provider.cvData.fontSize.toInt()}pt',
              onChanged: (value) => provider.updateFontSize(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview(BuildContext context, CVProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.view_carousel),
                const SizedBox(width: 12),
                Text(
                  _t['custom_current_template_title']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTemplateIcon(provider.selectedTemplate),
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTemplateName(provider.selectedTemplate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTemplateDescription(provider.selectedTemplate),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/templates');
              },
              icon: const Icon(Icons.swap_horiz),
              label: Text(_t['custom_change_template_btn']!),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(CVColor color) {
    switch (color) {
      case CVColor.blue:   return Colors.blue;
      case CVColor.green:  return Colors.green;
      case CVColor.purple: return Colors.purple;
      case CVColor.orange: return Colors.orange;
      case CVColor.red:    return Colors.red;
      case CVColor.teal:   return Colors.teal;
      case CVColor.indigo: return Colors.indigo;
    }
  }

  IconData _getTemplateIcon(CVTemplate template) {
    switch (template) {
      case CVTemplate.modern:       return Icons.space_dashboard;
      case CVTemplate.classic:      return Icons.article;
      case CVTemplate.professional: return Icons.business_center;
      case CVTemplate.creative:     return Icons.color_lens;
      case CVTemplate.minimal:      return Icons.minimize;
    }
  }

  String _getTemplateName(CVTemplate template) {
    switch (template) {
      case CVTemplate.modern:       return _t['custom_tpl_modern']!;
      case CVTemplate.classic:      return _t['custom_tpl_classic']!;
      case CVTemplate.professional: return _t['custom_tpl_professional']!;
      case CVTemplate.creative:     return _t['custom_tpl_creative']!;
      case CVTemplate.minimal:      return _t['custom_tpl_minimal']!;
    }
  }

  String _getTemplateDescription(CVTemplate template) {
    switch (template) {
      case CVTemplate.modern:       return _t['custom_tpl_modern_desc']!;
      case CVTemplate.classic:      return _t['custom_tpl_classic_desc']!;
      case CVTemplate.professional: return _t['custom_tpl_professional_desc']!;
      case CVTemplate.creative:     return _t['custom_tpl_creative_desc']!;
      case CVTemplate.minimal:      return _t['custom_tpl_minimal_desc']!;
    }
  }
}
