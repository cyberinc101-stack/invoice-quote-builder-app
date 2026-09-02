// lib/create_receipt/receipt_step_customise.dart
//
// FIELD TOGGLE OVERFLOW FIX (this update): _fieldToggleRow()'s label was
// a bare Text() inside a Row with no Expanded/Flexible wrapper, so any
// label too wide for the row (e.g. "Business Details (address/phone/
// email)", "Customer Details (name/email/phone/address)") just grew
// past the available width instead of wrapping — visible as the
// "RIGHT OVERFLOWED BY N PIXELS" yellow/black stripe. This is also a
// latent bug against translations: a longer string in another language
// hits the exact same overflow even for labels that fit fine in
// English. Fixed by wrapping the label in Expanded with softWrap
// enabled, and removing `dense: true` from the SwitchListTile (dense
// locks the tile to a fixed single-line height, which would clip a
// wrapped 2-3 line label instead of letting the tile grow to fit it).
//
// NEW FILE (earlier pass): extracted out of create_receipt_screen.dart's
// inline _customiseStep()/_fieldToggleRow()/_receiptFieldsSection()
// methods and the private _ReceiptPreviewCard class, giving Receipt's
// Customise step its own file at last — matching Invoice/Quote's
// convention of a dedicated step_customise.dart
// (step_customize/step_customise.dart, quote_step_customise.dart).
//
// This widget stays a plain, stateless presentational layer: all the
// underlying mutable state (logo path/offset/scale/shape/size, title
// controller, field toggles, color scheme, font family/size, every
// thermal field) still lives in _CreateReceiptScreenState, exactly as
// before. Nothing about where state is held has changed — only where
// the WIDGET TREE that reads/writes it lives.
// create_receipt_screen.dart's _customiseStep() now just constructs one
// of these and hands it callbacks.
//
// REORDER PASS (earlier pass, same file): the A4 "Receipt Fields" /
// "Customer Fields" toggle section (previously placed after Accent
// Color, per the old FIELD VISIBILITY RELOCATION PASS comment) now sits
// directly under Live Preview, before Business Logo — matching where
// Invoice's and Quote's own field-toggle sections currently sit
// (invoice's step_customise.dart FIELDS SECTION REORDER PASS,
// quote_step_customise.dart's REORDER PASS). Thermal is unaffected —
// it never showed this section; it keeps its own live toggle section
// (ReceiptThermalSettingsSection) further down, unchanged.
//
// FONT SIZE PASS (earlier pass): added Font Family and Text Size sections
// for the A4 (non-thermal) branch — new, Receipt previously had
// neither, unlike Invoice/Quote's own Font Family/Text Size controls.
// Positioned directly after Accent Color, matching Invoice/Quote's
// order exactly (Colour -> Font -> Size). Reads/writes
// ReceiptData.fontFamily/fontSize via plain callbacks into
// _CreateReceiptScreenState's own _fontFamily/_fontSize fields (synced
// to the provider through the existing _syncToProvider(), same pattern
// already used for _colorScheme) — unlike Quote/Invoice, Receipt's
// customise state lives directly on the screen's State object rather
// than routed through dedicated ReceiptProvider update methods, so no
// provider changes were needed; ReceiptData.fontSize already existed
// (see receipt_data.dart's own FONT SIZE PASS) but nothing wrote to it
// until now. Font Family/Text Size only apply to the A4 branch —
// thermal receipts don't use them (ReceiptThermalSettingsSection has no
// font controls of its own either).
//
// Final order for the A4 (non-thermal) branch, matching
// Invoice/Quote's Customise steps:
//   Title -> Live Preview -> Fields section -> Business Logo ->
//   Logo Size -> Accent Color -> Font Family -> Text Size -> Summary
// Thermal branch is unchanged apart from the Fields-section move (which
// never applied to it): Title -> Live Preview -> Business Logo ->
// Logo Size -> ReceiptThermalSettingsSection -> Summary.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/receipt_provider.dart';
import '../models/receipt_data.dart';
import '../widgets/shared_logo_picker.dart';
import 'receipt_edit_widgets.dart';
import 'receipt_thermal_settings.dart';
import 'receipt_thermal_live_preview.dart';
import 'receipt_paper_format.dart';
import 'receipt_template_chooser_01/preview_registry.dart' show buildReceiptPreview;
import '../document_layout_templates/01_executive/executive_receipt_logic_data.dart';
import '../document_layout_templates/01_executive/executive_receipt_stationary_layout.dart'
    show kPageW;
import '../document_layout_templates/pagination/scaled_page_stack.dart';

// Same font list Invoice's/Quote's step_customise.dart offer
// (_kFonts/kQuoteFonts) — kept as its own const here rather than
// importing from either, matching quote_step_customise.dart's existing
// "fully self-contained, no cross-import" rule.
const List<String> kReceiptFonts = [
  'Default',
  'Roboto',
  'Lato',
  'Montserrat',
  'Open Sans',
  'Playfair Display',
  'Source Sans Pro',
];

class ReceiptStepCustomise extends StatelessWidget {
  final Color accent;
  final TextEditingController titleCtrl;
  final bool isThermal;

  // Logo
  final String? logoPath;
  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;
  final double logoSize;
  final void Function(String? path, Offset offset, double scale, LogoShape shape) onLogoChanged;
  final ValueChanged<LogoShape> onLogoShapeChanged;
  final ValueChanged<double> onLogoSizeChanged;

  // Accent color (A4 only)
  final ReceiptColor colorScheme;
  final ValueChanged<ReceiptColor> onColorSchemeChanged;

  // Font (A4 only) — FONT SIZE PASS
  final String fontFamily;
  final ValueChanged<String> onFontFamilyChanged;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  // A4 field toggles ("Receipt Fields" / "Customer Fields")
  final bool showLogo;
  final bool showBusinessDetails;
  final bool showCustomerDetails;
  final bool showReceiptNumber;
  final bool showDateTime;
  final bool showTaxLine;
  final bool showDiscountLine;
  final bool showPaymentMethod;
  final ValueChanged<bool> onShowLogoChanged;
  final ValueChanged<bool> onShowBusinessDetailsChanged;
  final ValueChanged<bool> onShowCustomerDetailsChanged;
  final ValueChanged<bool> onShowReceiptNumberChanged;
  final ValueChanged<bool> onShowDateTimeChanged;
  final ValueChanged<bool> onShowTaxLineChanged;
  final ValueChanged<bool> onShowDiscountLineChanged;
  final ValueChanged<bool> onShowPaymentMethodChanged;

  // Thermal-only fields — forwarded straight through to
  // ReceiptThermalSettingsSection, unchanged from create_receipt_screen.dart.
  final TextEditingController cashierNameCtrl;
  final TextEditingController posIdCtrl;
  final TextEditingController taxIdCtrl;
  final TextEditingController paymentReferenceCtrl;
  final TextEditingController authCodeCtrl;
  final TextEditingController cardLast4Ctrl;
  final TextEditingController footerMessageCtrl;
  final TextEditingController qrDataCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController facebookCtrl;
  final TextEditingController instagramCtrl;
  final TextEditingController twitterCtrl;
  final bool showBarcode;
  final bool showQrCode;
  final bool compactThermalLayout;
  final bool showWebsite;
  final bool showFacebook;
  final bool showInstagram;
  final bool showTwitter;
  final ValueChanged<bool> onShowBarcodeChanged;
  final ValueChanged<bool> onShowQrCodeChanged;
  final ValueChanged<bool> onCompactLayoutChanged;
  final ValueChanged<bool> onShowWebsiteChanged;
  final ValueChanged<bool> onShowFacebookChanged;
  final ValueChanged<bool> onShowInstagramChanged;
  final ValueChanged<bool> onShowTwitterChanged;

  // Summary
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double amountPaid;
  final double taxRate;
  final double discountRate;
  final String currencySymbol;

  final VoidCallback onOpenFullPreview;

  const ReceiptStepCustomise({
    super.key,
    required this.accent,
    required this.titleCtrl,
    required this.isThermal,
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
    required this.showLogo,
    required this.showBusinessDetails,
    required this.showCustomerDetails,
    required this.showReceiptNumber,
    required this.showDateTime,
    required this.showTaxLine,
    required this.showDiscountLine,
    required this.showPaymentMethod,
    required this.onShowLogoChanged,
    required this.onShowBusinessDetailsChanged,
    required this.onShowCustomerDetailsChanged,
    required this.onShowReceiptNumberChanged,
    required this.onShowDateTimeChanged,
    required this.onShowTaxLineChanged,
    required this.onShowDiscountLineChanged,
    required this.onShowPaymentMethodChanged,
    required this.cashierNameCtrl,
    required this.posIdCtrl,
    required this.taxIdCtrl,
    required this.paymentReferenceCtrl,
    required this.authCodeCtrl,
    required this.cardLast4Ctrl,
    required this.footerMessageCtrl,
    required this.qrDataCtrl,
    required this.websiteCtrl,
    required this.facebookCtrl,
    required this.instagramCtrl,
    required this.twitterCtrl,
    required this.showBarcode,
    required this.showQrCode,
    required this.compactThermalLayout,
    required this.showWebsite,
    required this.showFacebook,
    required this.showInstagram,
    required this.showTwitter,
    required this.onShowBarcodeChanged,
    required this.onShowQrCodeChanged,
    required this.onCompactLayoutChanged,
    required this.onShowWebsiteChanged,
    required this.onShowFacebookChanged,
    required this.onShowInstagramChanged,
    required this.onShowTwitterChanged,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.amountPaid,
    required this.taxRate,
    required this.discountRate,
    required this.currencySymbol,
    required this.onOpenFullPreview,
  });

  Widget _fieldToggleRow(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.white,
      ),
      child: SwitchListTile(
        // OVERFLOW FIX: `dense: true` removed — it locks the tile to a
        // fixed single-line height, which would clip a wrapped 2-3 line
        // label instead of letting the tile grow to fit it. Vertical
        // padding bumped slightly (0 -> 8) so a wrapped multi-line label
        // still has breathing room top/bottom.
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 10),
            ],
            // OVERFLOW FIX: label now wraps onto multiple lines instead
            // of overflowing past the switch — a bare Text() here had no
            // Expanded/Flexible wrapper, so long labels (and longer
            // translated strings, which run this same risk in any
            // language regardless of how well the English text fits)
            // just grew past the available width instead of wrapping.
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                softWrap: true,
              ),
            ),
          ],
        ),
        value: value,
        activeThumbColor: accent,
        onChanged: onChanged,
      ),
    );
  }

  Widget _receiptFieldsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Receipt Fields', accent, icon: Icons.tune_rounded),
        Text(
          'Toggle which fields appear on the generated receipt.',
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 10),
        _fieldToggleRow(context, 'Business Logo', showLogo, onShowLogoChanged),
        _fieldToggleRow(context, 'Business Details (address/phone/email)', showBusinessDetails, onShowBusinessDetailsChanged),
        _fieldToggleRow(context, 'Receipt Number', showReceiptNumber, onShowReceiptNumberChanged),
        _fieldToggleRow(context, 'Date/Time', showDateTime, onShowDateTimeChanged),
        _fieldToggleRow(context, 'Payment Method', showPaymentMethod, onShowPaymentMethodChanged),
        _fieldToggleRow(context, 'Tax Line', showTaxLine, onShowTaxLineChanged),
        _fieldToggleRow(context, 'Discount Line', showDiscountLine, onShowDiscountLineChanged),
        const SizedBox(height: 12),
        receiptSectionHeader(context, 'Customer Fields', accent, icon: Icons.person_rounded),
        _fieldToggleRow(context, 'Customer Details (name/email/phone/address)', showCustomerDetails, onShowCustomerDetailsChanged),
      ],
    );
  }

  Widget _fontSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Font Family', accent, icon: Icons.text_fields_rounded),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kReceiptFonts.map((font) {
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
        receiptSectionHeader(context, 'Text Size', accent, icon: Icons.format_size_rounded),
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
    final themeColors = Theme.of(context).colorScheme;
    final hasLogo = logoPath != null && logoPath!.isNotEmpty;
    final previewSize = (90.0 + (logoSize - 40.0) * 3.0).clamp(90.0, 220.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Receipt Title', accent, icon: Icons.title_rounded),
        ReceiptField(
          ctrl: titleCtrl,
          label: 'Title (for your records)',
          accent: accent,
          icon: Icons.bookmark_outline_rounded,
          required: true,
          max: 80,
        ),
        const SizedBox(height: 24),

        receiptSectionHeader(context, 'Live Preview', accent, icon: Icons.visibility_rounded),
        const _ReceiptPreviewCard(),
        const SizedBox(height: 24),

        // REORDER PASS: Fields section sits here, directly under Live
        // Preview and before Business Logo, matching Invoice/Quote's
        // step_customise.dart order. A4 only — thermal keeps its own
        // live toggle section (ReceiptThermalSettingsSection) below.
        if (!isThermal) ...[
          _receiptFieldsSection(context),
          const SizedBox(height: 24),
        ],

        receiptSectionHeader(context, 'Business Logo', accent, icon: Icons.image_rounded),
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

        receiptSectionHeader(context, 'Logo Size', accent, icon: Icons.photo_size_select_large_rounded),
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

        if (isThermal) ...[
          ReceiptThermalSettingsSection(
            accent: accent,
            cashierNameCtrl: cashierNameCtrl,
            posIdCtrl: posIdCtrl,
            taxIdCtrl: taxIdCtrl,
            paymentReferenceCtrl: paymentReferenceCtrl,
            authCodeCtrl: authCodeCtrl,
            cardLast4Ctrl: cardLast4Ctrl,
            footerMessageCtrl: footerMessageCtrl,
            qrDataCtrl: qrDataCtrl,
            websiteCtrl: websiteCtrl,
            facebookCtrl: facebookCtrl,
            instagramCtrl: instagramCtrl,
            twitterCtrl: twitterCtrl,
            showLogo: showLogo,
            showBusinessDetails: showBusinessDetails,
            showCustomerDetails: showCustomerDetails,
            showReceiptNumber: showReceiptNumber,
            showDateTime: showDateTime,
            showTaxLine: showTaxLine,
            showDiscountLine: showDiscountLine,
            showPaymentMethod: showPaymentMethod,
            showBarcode: showBarcode,
            showQrCode: showQrCode,
            compactLayout: compactThermalLayout,
            showWebsite: showWebsite,
            showFacebook: showFacebook,
            showInstagram: showInstagram,
            showTwitter: showTwitter,
            onShowLogoChanged: onShowLogoChanged,
            onShowBusinessDetailsChanged: onShowBusinessDetailsChanged,
            onShowCustomerDetailsChanged: onShowCustomerDetailsChanged,
            onShowReceiptNumberChanged: onShowReceiptNumberChanged,
            onShowDateTimeChanged: onShowDateTimeChanged,
            onShowTaxLineChanged: onShowTaxLineChanged,
            onShowDiscountLineChanged: onShowDiscountLineChanged,
            onShowPaymentMethodChanged: onShowPaymentMethodChanged,
            onShowBarcodeChanged: onShowBarcodeChanged,
            onShowQrCodeChanged: onShowQrCodeChanged,
            onCompactLayoutChanged: onCompactLayoutChanged,
            onShowWebsiteChanged: onShowWebsiteChanged,
            onShowFacebookChanged: onShowFacebookChanged,
            onShowInstagramChanged: onShowInstagramChanged,
            onShowTwitterChanged: onShowTwitterChanged,
          ),
          const SizedBox(height: 24),
        ] else ...[
          receiptSectionHeader(context, 'Accent Color', accent, icon: Icons.palette_outlined),
          ReceiptColorPicker(
            selected: colorScheme,
            onChanged: onColorSchemeChanged,
          ),
          const SizedBox(height: 24),

          // FONT SIZE PASS: Font Family + Text Size sit right after
          // Accent Color, matching Invoice/Quote's step_customise.dart
          // order exactly (Colour -> Font -> Size).
          _fontSection(context),
          const SizedBox(height: 24),

          _sizeSection(context),
          const SizedBox(height: 24),
        ],

        receiptSectionHeader(context, 'Summary', accent, icon: Icons.summarize_rounded),
        ReceiptTotalsCard(
          subtotal: subtotal,
          taxAmount: taxAmount,
          discountAmount: discountAmount,
          amountPaid: amountPaid,
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

// Moved verbatim from create_receipt_screen.dart (was a private
// top-level class there) — reads ReceiptProvider directly via
// context.watch, so it didn't need any constructor params to begin with.
class _ReceiptPreviewCard extends StatelessWidget {
  const _ReceiptPreviewCard();

  static Color _accentFromScheme(ReceiptColor scheme) {
    const map = {
      ReceiptColor.blue:   Color(0xFF1565C0),
      ReceiptColor.green:  Color(0xFF2E7D32),
      ReceiptColor.purple: Color(0xFF6A1B9A),
      ReceiptColor.orange: Color(0xFFE65100),
      ReceiptColor.red:    Color(0xFFC62828),
      ReceiptColor.teal:   Color(0xFF00695C),
      ReceiptColor.black:  Color(0xFF212121),
      ReceiptColor.indigo: Color(0xFF283593),
    };
    return map[scheme] ?? const Color(0xFF2E7D32);
  }

  Widget _buildPreviewWidget(ReceiptData data) {
    return buildReceiptPreview(data.layoutTemplateId, data) ??
        ExecutiveReceiptPreview(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final data        = context.watch<ReceiptProvider>().currentReceiptData;
    final accent      = _accentFromScheme(data.colorScheme);
    final colorScheme = Theme.of(context).colorScheme;
    final format      = receiptPaperFormatFromString(data.paperFormat);

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
        if (format.isThermal)
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final nativeWidth = format.widthMm * 4.2;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: nativeWidth,
                      child: ThermalReceiptLivePreview(data: data, widthMm: format.widthMm),
                    ),
                  ),
                );
              },
            ),
          )
        else
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