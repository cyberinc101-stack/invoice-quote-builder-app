// lib/screens/create_quote_section/quote_step_customise.dart
//
// BUILD FIX (this pass): build() declared a local
// `final colorScheme = Theme.of(context).colorScheme;` which shadowed
// this widget's own `colorScheme` field (type QuoteColor, used by
// QuoteColorPicker). That made `QuoteColorPicker(selected: colorScheme, ...)`
// pass Flutter's ColorScheme instead of the QuoteColor field, which is a
// type error ("The argument type 'ColorScheme' can't be assigned to the
// parameter type 'QuoteColor'") and failed the build. Renamed the local
// Theme value to `themeColors` throughout build() so the widget's
// `colorScheme` field (QuoteColor) is no longer shadowed. No other
// behaviour changed.
//
// NEW FILE (earlier pass): extracted out of quote_editor_screen.dart's
// inline _customiseStep()/_fieldToggleRow()/_quoteFieldsSection()
// methods and the private _QuotePreviewCard class, giving Quote's
// Customise step its own file at last — matching Invoice's convention
// of a dedicated step_customise.dart, and fixing the file-naming gap
// the user flagged (Quote/Receipt never got their Customise step split
// out the way Invoice's was).
//
// This widget stays a plain, stateless presentational layer: all the
// underlying mutable state (logo path/offset/scale/shape/size, title
// controller, enabled fields, color scheme, font family/size) still
// lives in _QuoteEditorScreenState, exactly as before. Nothing about
// where state is held has changed — only where the WIDGET TREE that
// reads/writes it lives. quote_editor_screen.dart's _customiseStep()
// now just constructs one of these and hands it callbacks.
//
// REORDER PASS (this pass): moved the Fields section back up to sit
// directly under Live Preview, before Business Logo — matching where
// Invoice's step_customise.dart now places its own Fields section (see
// that file's FIELDS SECTION REORDER PASS). Supersedes the previous
// FONT + REORDER PASS positioning (Fields after Text Size). Final order
// for all three documents (Invoice/Quote/Receipt) is now:
//   Live Preview -> Fields section -> Business Logo -> Logo Size ->
//   Accent Color -> Font Family -> Text Size
//
// FONT + REORDER PASS (earlier pass): added Font Family and Text Size
// sections (new — Quote previously had neither, unlike Invoice's
// step_customise.dart _FontSection/_SizeSection). Font Family/Text Size
// read/write QuoteData.fontFamily/fontSize via
// QuoteProvider.updateFontFamily()/updateFontSize() (the latter new —
// see quote_provider.dart and quote_data.dart's FONT SIZE PASS).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/quote_provider.dart';
import '../../models/quote_data.dart';
import '../../widgets/shared_logo_picker.dart';
import 'quote_edit_widgets.dart';
import 'quote_template_chooser_01/preview_registry.dart' show buildQuotePreview;
import '../../document_layout_templates/01_executive/executive_quote_logic_data.dart';
import '../../document_layout_templates/01_executive/executive_quote_stationary_layout.dart'
    show kPageW;
import '../../document_layout_templates/pagination/scaled_page_stack.dart';

// Same font list Invoice's step_customise.dart offers (_kFonts) — kept
// as its own const here rather than importing from the invoice step
// file, matching quote_edit_widgets.dart's existing "fully
// self-contained, no cross-import from invoice_create_section" rule.
const List<String> kQuoteFonts = [
  'Default',
  'Roboto',
  'Lato',
  'Montserrat',
  'Open Sans',
  'Playfair Display',
  'Source Sans Pro',
];

class QuoteStepCustomise extends StatelessWidget {
  final Color accent;
  final TextEditingController titleCtrl;

  final Map<String, bool> enabledFields;
  final ValueChanged<Map<String, bool>> onEnabledFieldsChanged;

  final String? logoPath;
  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;
  final double logoSize;
  final void Function(String? path, Offset offset, double scale, LogoShape shape) onLogoChanged;
  final ValueChanged<LogoShape> onLogoShapeChanged;
  final ValueChanged<double> onLogoSizeChanged;

  final QuoteColor colorScheme;
  final ValueChanged<QuoteColor> onColorSchemeChanged;

  final String fontFamily;
  final ValueChanged<String> onFontFamilyChanged;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final double taxRate;
  final double discountRate;
  final String currencySymbol;

  final VoidCallback onOpenFullPreview;

  const QuoteStepCustomise({
    super.key,
    required this.accent,
    required this.titleCtrl,
    required this.enabledFields,
    required this.onEnabledFieldsChanged,
    required this.logoPath,
    required this.logoOffset,
    required this.logoScale,
    required this.logoShape,
    required this.logoSize,
    required this.onLogoChanged,
    required this.onLogoShapeChanged,
    required this.onLogoSizeChanged,
    required this.colorScheme,
    required this.onColorSchemeChanged,
    required this.fontFamily,
    required this.onFontFamilyChanged,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.taxRate,
    required this.discountRate,
    required this.currencySymbol,
    required this.onOpenFullPreview,
  });

  void _toggleField(String key, bool value) {
    final updated = Map<String, bool>.from(enabledFields);
    updated[key] = value;
    onEnabledFieldsChanged(updated);
  }

  Widget _fieldToggleRow(BuildContext context, String key, String label, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = enabledFields[key] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.white,
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 10),
            ],
            Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
          ],
        ),
        value: value,
        activeThumbColor: accent,
        onChanged: (v) => _toggleField(key, v),
      ),
    );
  }

  Widget _fieldsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quoteSectionHeader(context, 'Quote Fields', accent, icon: Icons.tune_rounded),
        Text(
          'Toggle which fields appear on the generated quote.',
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 10),
        _fieldToggleRow(context, 'invoiceNumber', 'Quote Number', icon: Icons.tag_rounded),
        _fieldToggleRow(context, 'date', 'Issue Date', icon: Icons.calendar_today_rounded),
        _fieldToggleRow(context, 'dueDate', 'Valid Until', icon: Icons.event_rounded),
        _fieldToggleRow(context, 'businessLogo', 'Business Logo', icon: Icons.image_rounded),
        _fieldToggleRow(context, 'tax', 'Tax', icon: Icons.percent_rounded),
        _fieldToggleRow(context, 'discount', 'Discount', icon: Icons.local_offer_rounded),
        _fieldToggleRow(context, 'notes', 'Notes', icon: Icons.notes_rounded),
        _fieldToggleRow(context, 'thankYouMessage', 'Thank You Message', icon: Icons.favorite_border_rounded),
        const SizedBox(height: 12),
        quoteSectionHeader(context, 'Client Fields', accent, icon: Icons.person_rounded),
        _fieldToggleRow(context, 'customerName', 'Client Name', icon: Icons.person_outline_rounded),
        _fieldToggleRow(context, 'customerEmail', 'Client Email', icon: Icons.email_rounded),
        _fieldToggleRow(context, 'customerPhone', 'Client Phone', icon: Icons.phone_rounded),
        _fieldToggleRow(context, 'customerAddress', 'Client Address', icon: Icons.location_on_rounded),
      ],
    );
  }

  Widget _fontSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quoteSectionHeader(context, 'Font Family', accent, icon: Icons.text_fields_rounded),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kQuoteFonts.map((font) {
            final isActive = font == fontFamily;
            return GestureDetector(
              onTap: () => onFontFamilyChanged(font),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? accent : (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? accent : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  font,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sizeSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quoteSectionHeader(context, 'Text Size', accent, icon: Icons.format_size_rounded),
        Row(
          children: [
            Text('A', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accent,
                  inactiveTrackColor: accent.withValues(alpha: 0.2),
                  thumbColor: accent,
                  overlayColor: accent.withValues(alpha: 0.15),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: fontSize,
                  min: 10,
                  max: 16,
                  divisions: 6,
                  onChanged: onFontSizeChanged,
                ),
              ),
            ),
            Text('A', style: TextStyle(fontSize: 18, color: colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
        Center(
          child: Text(
            '${fontSize.toInt()}pt',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // BUILD FIX: renamed from `colorScheme` -> `themeColors` throughout
    // this method. The widget's own `colorScheme` field is type
    // QuoteColor (used by QuoteColorPicker below); a local variable of
    // the same name holding Flutter's Theme ColorScheme was shadowing
    // that field and getting passed into QuoteColorPicker by mistake.
    final themeColors = Theme.of(context).colorScheme;
    final hasLogo = logoPath != null && logoPath!.isNotEmpty;
    final previewSize = (90.0 + (logoSize - 40.0) * 3.0).clamp(90.0, 220.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quoteSectionHeader(context, 'Quote Title', accent, icon: Icons.title_rounded),
        QuoteField(
          ctrl: titleCtrl,
          label: 'Title (for your records)',
          accent: accent,
          icon: Icons.bookmark_outline_rounded,
          required: true,
          max: 80,
        ),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Live Preview', accent, icon: Icons.visibility_rounded),
        const _QuotePreviewCard(),
        const SizedBox(height: 24),

        // REORDER PASS: Fields section moved here, directly under Live
        // Preview and before Business Logo, matching Invoice's
        // step_customise.dart FIELDS SECTION REORDER PASS order.
        _fieldsSection(context),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Business Logo', accent, icon: Icons.image_rounded),
        Builder(builder: (context) {
          return Column(
            children: [
              Center(
                child: Opacity(
                  opacity: hasLogo ? 1.0 : 0.5,
                  child: SharedLogoPicker(
                    logoPath: logoPath,
                    logoOffset: logoOffset,
                    logoScale: logoScale,
                    logoShape: logoShape,
                    accent: accent,
                    compact: true,
                    compactBoxSize: previewSize,
                    onChanged: onLogoChanged,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasLogo ? 'Tap logo to change, reposition, or remove' : 'Tap to upload a logo',
                style: TextStyle(fontSize: 11, color: themeColors.onSurface.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: hasLogo ? 1.0 : 0.4,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: LogoShape.values.map((s) {
                    final selected = s == logoShape;
                    return GestureDetector(
                      onTap: hasLogo ? () => onLogoShapeChanged(s) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? accent : themeColors.outline.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.icon, size: 16, color: selected ? accent : themeColors.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 5),
                            Text(
                              s.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? accent : themeColors.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 16),

        quoteSectionHeader(context, 'Logo Size', accent, icon: Icons.photo_size_select_large_rounded),
        Opacity(
          opacity: hasLogo ? 1.0 : 0.4,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.image_outlined, size: 14, color: themeColors.onSurface.withValues(alpha: 0.5)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accent,
                        inactiveTrackColor: accent.withValues(alpha: 0.2),
                        thumbColor: accent,
                        overlayColor: accent.withValues(alpha: 0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: logoSize,
                        min: 24,
                        max: 60,
                        divisions: 9,
                        onChanged: hasLogo ? onLogoSizeChanged : null,
                      ),
                    ),
                  ),
                  Icon(Icons.image_outlined, size: 24, color: themeColors.onSurface.withValues(alpha: 0.5)),
                ],
              ),
              Text(
                hasLogo ? '${logoSize.toInt()}px' : 'Add a logo to enable',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Accent Color', accent, icon: Icons.palette_outlined),
        QuoteColorPicker(selected: colorScheme, onChanged: onColorSchemeChanged),
        const SizedBox(height: 24),

        // FONT + REORDER PASS: Font Family + Text Size sit right after
        // Accent Color, matching Invoice's step_customise.dart order
        // exactly (Colour -> Font -> Size).
        _fontSection(context),
        const SizedBox(height: 24),

        _sizeSection(context),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Summary', accent, icon: Icons.summarize_rounded),
        QuoteTotalsCard(
          subtotal: subtotal,
          taxAmount: taxAmount,
          discountAmount: discountAmount,
          total: total,
          taxRate: taxRate,
          discountRate: discountRate,
          currencySymbol: currencySymbol,
          accent: accent,
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: onOpenFullPreview,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x504CAF50), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.preview_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Preview & Download',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Moved verbatim from quote_editor_screen.dart (was a private top-level
// class there) — reads QuoteProvider directly via context.watch, so it
// didn't need any constructor params to begin with.
class _QuotePreviewCard extends StatelessWidget {
  const _QuotePreviewCard();

  static Color _accentFromScheme(QuoteColor scheme) {
    const map = {
      QuoteColor.blue:   Color(0xFF1565C0),
      QuoteColor.green:  Color(0xFF2E7D32),
      QuoteColor.purple: Color(0xFF6A1B9A),
      QuoteColor.orange: Color(0xFFE65100),
      QuoteColor.red:    Color(0xFFC62828),
      QuoteColor.teal:   Color(0xFF00695C),
      QuoteColor.black:  Color(0xFF212121),
      QuoteColor.indigo: Color(0xFF283593),
    };
    return map[scheme] ?? const Color(0xFF6A1B9A);
  }

  Widget _buildPreviewWidget(QuoteData data) {
    return buildQuotePreview(data.layoutTemplateId, data) ??
        ExecutiveQuotePreview(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final data        = context.watch<QuoteProvider>().quoteData;
    final accent      = _accentFromScheme(data.colorScheme);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text('Live Preview',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
          ]),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ScaledPageStack(
                  targetWidth: constraints.maxWidth,
                  nativePageWidth: kPageW,
                  child: _buildPreviewWidget(data),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Live preview - changes appear instantly.',
              style: TextStyle(fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }
}