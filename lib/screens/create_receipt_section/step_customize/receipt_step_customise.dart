// lib/screens/create_receipt_section/step_customize/receipt_step_customise.dart
//
// MERGE PASS (this update): imports redirected off the three deleted
// executive_receipt_logic_data.dart / executive_receipt_stationary_
// layout.dart / executive_invoice_payment_terms_signature.dart files.
// ExecutiveReceiptPreview and kSignatureFonts now come from
// executive_template.dart (the merged, adapter-based file that replaces
// all three — see that file's own MERGE PASS header comment), and
// kPageW now comes from shared_doc_widgets.dart. No other change in
// this file — same widget tree, same behavior, same call sites.
//
// FIELD GROUPS PARITY PASS (earlier): the flat "Receipt Fields"
// toggle list and the separate standalone "Signature" section have been
// replaced with the same collapsible GROUP-CARD pattern Quote's
// step_customise.dart uses ("Quote Fields" -> Header & Meta / Client
// Details / Quote Details / Terms & Signature / Notes & Thank You).
// Receipt now has: Header & Meta, Payment Details, Customer Details,
// Signature, Notes & Thank You — each its own collapsible card with a
// master on/off switch, an "n/total" badge, and a chevron to expand/
// collapse; state persists per-group via SharedPreferences, same as
// Quote's _kFieldGroupExpandedPrefPrefix pattern (this file uses its
// own 'receipt_customise_field_group_expanded_' prefix so the two
// flows never share state).
//
// Signature is now ONE GROUP inside that same list — matching Quote's
// "Terms & Signature" group exactly in shape: the group's own row IS
// the Signature toggle (no separate switch needed since there's only
// one field in it), its master switch maps to signatureMode being
// non-empty (turning off sets signatureMode to '', turning back on
// restores 'blank' — the same default QuoteData/ReceiptData ship with),
// and expanding it reveals the exact same Upload/Type/Blank mode-chip
// row, image-upload tile, and typed-name field + inline Size slider +
// font chips that the previous standalone _ReceiptSignatureSection had
// — content is unchanged, just re-homed into the shared group-card
// shell instead of its own top-level section. Still reads/writes
// ReceiptProvider directly via context.watch/read (unlike every other
// field group here, which is driven by plain bool/callback constructor
// params owned by create_receipt_screen.dart's state) — same reasoning
// as before: ReceiptData.signatureMode/signatureName/etc. live only on
// ReceiptProvider, with no equivalent constructor params threaded
// through from create_receipt_screen.dart.
//
// ReceiptStepCustomise's own public constructor is UNCHANGED — every
// existing bool/callback param this widget already took is still taken
// and still wired to the same underlying toggle; only the rendering
// changed from a flat list to grouped cards. create_receipt_screen.dart
// needs no changes to keep compiling against this file.
//
// FONT FIX PASS (earlier): kReceiptFonts previously listed "Source
// Sans Pro" (never bundled) and was missing Lora/Nunito/Raleway/Space
// Grotesk — the same stale-list bug Invoice's step_customise.dart had
// before its own FONT FAMILY LIST FIX, and the same one just fixed on
// Quote's step_customise.dart. kReceiptFonts now exactly mirrors the
// bundled family names. _fontSection's chips also now preview each
// chip's own label IN that font (fontFamily: previewFamily) — same
// mechanism as Invoice's and Quote's Font Family chips. 'Default'
// deliberately maps to fontFamily: null (platform default) rather than
// the literal string 'Default'. A4-only, same as before — no change to
// the thermal branch, which never showed a Font Family section at all.
//
// FOLDER MOVE PASS (earlier): relocated from
// create_receipt_section/receipt_step_customise.dart into its own
// step_customize/ folder.
//
// Every other pass note (CASHIER NAME TOGGLE, PAPER FORMAT PICKER,
// THANK YOU MESSAGE TOGGLE, FIELD TOGGLE OVERFLOW FIX) — see prior
// header comments; unaffected by this update.
//
// Final order for the A4 (non-thermal) branch:
//   Title -> Live Preview -> Paper Format -> Receipt Fields (grouped
//   cards: Header & Meta / Payment Details / Customer Details /
//   Signature / Notes & Thank You) -> Business Logo -> Logo Size ->
//   Accent Color -> Font Family -> Text Size -> Summary
// Thermal branch is unchanged — Signature is A4-only, same as Invoice's
// own Signature toggle never applying to a thermal-format document.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/receipt_provider.dart';
import '../../../models/receipt_data.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../receipt_edit_widgets.dart';
import '../receipt_thermal_settings.dart';
import '../receipt_thermal_live_preview.dart';
import '../receipt_paper_format.dart';
import '../receipt_paper_format_picker.dart';
import '../receipt_template_chooser_01/preview_registry.dart' show buildReceiptPreview;
// MERGE PASS: both symbols now come from the merged executive_template.dart
// instead of the deleted executive_receipt_logic_data.dart /
// executive_receipt_stationary_layout.dart /
// executive_invoice_payment_terms_signature.dart.
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show ExecutiveReceiptPreview, kSignatureFonts;
// MERGE PASS: kPageW now lives on the shared widgets file.
import '../../../document_layout_templates/document_template_layout_data/doc_header.dart'
    show kPageW;
import '../../../document_layout_templates/pagination/scaled_page_stack.dart';

// FONT FIX PASS: this list now exactly mirrors the family names
// actually registered in pubspec.yaml's flutter: fonts: section (the
// same set Invoice's/Quote's step_customise.dart offer), plus the
// 'Default' sentinel, which deliberately doesn't match any registered
// family — it falls through to the platform default on purpose.
// Previously included "Source Sans Pro" (never bundled at all) and
// never offered Lora/Nunito/Raleway/Space Grotesk even though those
// were already bundled and unused.
const List<String> kReceiptFonts = [
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

class ReceiptStepCustomise extends StatelessWidget {
  final Color accent;
  final TextEditingController titleCtrl;
  final bool isThermal;

  // Which format (A4/58mm/80mm) is selected, and the callback fired
  // when the user taps a different one in the Paper Format section.
  final ReceiptPaperFormat paperFormat;
  final ValueChanged<ReceiptPaperFormat> onPaperFormatChanged;

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

  // Font (A4 only)
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
  final bool showThankYouMessage;
  final ValueChanged<bool> onShowLogoChanged;
  final ValueChanged<bool> onShowBusinessDetailsChanged;
  final ValueChanged<bool> onShowCustomerDetailsChanged;
  final ValueChanged<bool> onShowReceiptNumberChanged;
  final ValueChanged<bool> onShowDateTimeChanged;
  final ValueChanged<bool> onShowTaxLineChanged;
  final ValueChanged<bool> onShowDiscountLineChanged;
  final ValueChanged<bool> onShowPaymentMethodChanged;
  final bool showCashierName;
  final ValueChanged<bool> onShowCashierNameChanged;
  final ValueChanged<bool> onShowThankYouMessageChanged;

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
    required this.paperFormat,
    required this.onPaperFormatChanged,
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
    required this.showCashierName,
    required this.onShowCashierNameChanged,
    required this.showThankYouMessage,
    required this.onShowLogoChanged,
    required this.onShowBusinessDetailsChanged,
    required this.onShowCustomerDetailsChanged,
    required this.onShowReceiptNumberChanged,
    required this.onShowDateTimeChanged,
    required this.onShowTaxLineChanged,
    required this.onShowDiscountLineChanged,
    required this.onShowPaymentMethodChanged,
    required this.onShowThankYouMessageChanged,
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
            final previewFamily = font == 'Default' ? null : font;
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
                    fontFamily: previewFamily,
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

        receiptSectionHeader(context, 'Paper Format', accent, icon: Icons.description_outlined),
        ReceiptPaperFormatPicker(
          selected: paperFormat,
          accent: accent,
          onChanged: onPaperFormatChanged,
        ),
        const SizedBox(height: 24),

        if (!isThermal) ...[
          _ReceiptFieldGroups(
            accent: accent,
            showLogo: showLogo,
            onShowLogoChanged: onShowLogoChanged,
            showBusinessDetails: showBusinessDetails,
            onShowBusinessDetailsChanged: onShowBusinessDetailsChanged,
            showReceiptNumber: showReceiptNumber,
            onShowReceiptNumberChanged: onShowReceiptNumberChanged,
            showDateTime: showDateTime,
            onShowDateTimeChanged: onShowDateTimeChanged,
            showPaymentMethod: showPaymentMethod,
            onShowPaymentMethodChanged: onShowPaymentMethodChanged,
            showCashierName: showCashierName,
            onShowCashierNameChanged: onShowCashierNameChanged,
            showTaxLine: showTaxLine,
            onShowTaxLineChanged: onShowTaxLineChanged,
            showDiscountLine: showDiscountLine,
            onShowDiscountLineChanged: onShowDiscountLineChanged,
            showCustomerDetails: showCustomerDetails,
            onShowCustomerDetailsChanged: onShowCustomerDetailsChanged,
            showThankYouMessage: showThankYouMessage,
            onShowThankYouMessageChanged: onShowThankYouMessageChanged,
          ),
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
            showCashierName: showCashierName,
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
            onShowCashierNameChanged: onShowCashierNameChanged,
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

// =============================================================================
// Reusable section card — mirrors Quote's _SectionCard exactly (bordered
// container, icon+title header, then child content).
// =============================================================================

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final Widget   child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// FIELD GROUPS PARITY PASS: grouped, collapsible field toggles — mirrors
// Quote's _FieldsSection/_groupCard/_fieldRow shape exactly, adapted to
// this file's plain bool + ValueChanged<bool> constructor-param style
// (rather than reading everything off a provider the way Quote's
// version does). The Signature group is the one exception — it reads/
// writes ReceiptProvider directly, since ReceiptData.signatureMode/
// signatureName/etc. have no equivalent constructor params threaded
// through create_receipt_screen.dart.
// =============================================================================

class _FieldToggleSpec {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FieldToggleSpec({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
}

class _FieldGroupSpec {
  final String label;
  final IconData icon;
  final List<_FieldToggleSpec> fields;
  const _FieldGroupSpec({required this.label, required this.icon, required this.fields});
}

const _kReceiptFieldGroupExpandedPrefPrefix = 'receipt_customise_field_group_expanded_';

class _ReceiptFieldGroups extends StatefulWidget {
  final Color accent;

  final bool showLogo;
  final ValueChanged<bool> onShowLogoChanged;
  final bool showBusinessDetails;
  final ValueChanged<bool> onShowBusinessDetailsChanged;
  final bool showReceiptNumber;
  final ValueChanged<bool> onShowReceiptNumberChanged;
  final bool showDateTime;
  final ValueChanged<bool> onShowDateTimeChanged;
  final bool showPaymentMethod;
  final ValueChanged<bool> onShowPaymentMethodChanged;
  final bool showCashierName;
  final ValueChanged<bool> onShowCashierNameChanged;
  final bool showTaxLine;
  final ValueChanged<bool> onShowTaxLineChanged;
  final bool showDiscountLine;
  final ValueChanged<bool> onShowDiscountLineChanged;
  final bool showCustomerDetails;
  final ValueChanged<bool> onShowCustomerDetailsChanged;
  final bool showThankYouMessage;
  final ValueChanged<bool> onShowThankYouMessageChanged;

  const _ReceiptFieldGroups({
    required this.accent,
    required this.showLogo,
    required this.onShowLogoChanged,
    required this.showBusinessDetails,
    required this.onShowBusinessDetailsChanged,
    required this.showReceiptNumber,
    required this.onShowReceiptNumberChanged,
    required this.showDateTime,
    required this.onShowDateTimeChanged,
    required this.showPaymentMethod,
    required this.onShowPaymentMethodChanged,
    required this.showCashierName,
    required this.onShowCashierNameChanged,
    required this.showTaxLine,
    required this.onShowTaxLineChanged,
    required this.showDiscountLine,
    required this.onShowDiscountLineChanged,
    required this.showCustomerDetails,
    required this.onShowCustomerDetailsChanged,
    required this.showThankYouMessage,
    required this.onShowThankYouMessageChanged,
  });

  @override
  State<_ReceiptFieldGroups> createState() => _ReceiptFieldGroupsState();
}

class _ReceiptFieldGroupsState extends State<_ReceiptFieldGroups> {
  final Map<String, bool> _expanded = {};

  static const _kGroupLabels = [
    'Header & Meta',
    'Payment Details',
    'Customer Details',
    'Signature',
    'Notes & Thank You',
  ];

  @override
  void initState() {
    super.initState();
    _loadPersistedExpand();
  }

  Future<void> _loadPersistedExpand() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <String, bool>{};
    for (final label in _kGroupLabels) {
      loaded[label] = prefs.getBool('$_kReceiptFieldGroupExpandedPrefPrefix$label') ?? false;
    }
    if (!mounted) return;
    setState(() => _expanded.addAll(loaded));
  }

  Future<void> _persistExpand(String groupLabel, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kReceiptFieldGroupExpandedPrefPrefix$groupLabel', value);
  }

  void _setExpanded(String groupLabel, bool v) {
    setState(() => _expanded[groupLabel] = v);
    _persistExpand(groupLabel, v);
  }

  List<_FieldGroupSpec> _boolGroups() => [
        _FieldGroupSpec(label: 'Header & Meta', icon: Icons.tag_rounded, fields: [
          _FieldToggleSpec(label: 'Business Logo', icon: Icons.image_rounded,
              value: widget.showLogo, onChanged: widget.onShowLogoChanged),
          _FieldToggleSpec(label: 'Business Details', icon: Icons.business_rounded,
              value: widget.showBusinessDetails, onChanged: widget.onShowBusinessDetailsChanged),
          _FieldToggleSpec(label: 'Receipt Number', icon: Icons.tag_rounded,
              value: widget.showReceiptNumber, onChanged: widget.onShowReceiptNumberChanged),
          _FieldToggleSpec(label: 'Date/Time', icon: Icons.calendar_today_rounded,
              value: widget.showDateTime, onChanged: widget.onShowDateTimeChanged),
        ]),
        _FieldGroupSpec(label: 'Payment Details', icon: Icons.payments_rounded, fields: [
          _FieldToggleSpec(label: 'Payment Method', icon: Icons.credit_card_rounded,
              value: widget.showPaymentMethod, onChanged: widget.onShowPaymentMethodChanged),
          _FieldToggleSpec(label: 'Cashier Name', icon: Icons.person_outline_rounded,
              value: widget.showCashierName, onChanged: widget.onShowCashierNameChanged),
          _FieldToggleSpec(label: 'Tax Line', icon: Icons.percent_rounded,
              value: widget.showTaxLine, onChanged: widget.onShowTaxLineChanged),
          _FieldToggleSpec(label: 'Discount Line', icon: Icons.local_offer_rounded,
              value: widget.showDiscountLine, onChanged: widget.onShowDiscountLineChanged),
        ]),
        _FieldGroupSpec(label: 'Customer Details', icon: Icons.person_rounded, fields: [
          _FieldToggleSpec(label: 'Customer Details', icon: Icons.person_outline_rounded,
              value: widget.showCustomerDetails, onChanged: widget.onShowCustomerDetailsChanged),
        ]),
        _FieldGroupSpec(label: 'Notes & Thank You', icon: Icons.notes_rounded, fields: [
          _FieldToggleSpec(label: 'Thank You Message', icon: Icons.favorite_border_rounded,
              value: widget.showThankYouMessage, onChanged: widget.onShowThankYouMessageChanged),
        ]),
      ];

  Widget _fieldRow(BuildContext context, _FieldToggleSpec f) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(9),
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : const Color(0xFFFAFAFA),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        visualDensity: VisualDensity.compact,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(f.icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                f.label,
                style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
                softWrap: true,
              ),
            ),
          ],
        ),
        value: f.value,
        activeThumbColor: accent,
        onChanged: f.onChanged,
      ),
    );
  }

  Widget _groupCardShell({
    required IconData icon,
    required String label,
    required bool groupOn,
    required int onCount,
    required int totalCount,
    required VoidCallback onToggleExpand,
    required ValueChanged<bool> onToggleGroup,
    required Widget expandedChild,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final isExpanded = _expanded[label] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF23233A) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 17,
                      color: groupOn ? accent : colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$onCount/$totalCount',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: groupOn,
                    activeThumbColor: accent,
                    onChanged: onToggleGroup,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: expandedChild,
            ),
        ],
      ),
    );
  }

  Widget _boolGroupCard(_FieldGroupSpec group) {
    final groupOn = group.fields.every((f) => f.value);
    final onCount = group.fields.where((f) => f.value).length;

    return _groupCardShell(
      icon: group.icon,
      label: group.label,
      groupOn: groupOn,
      onCount: onCount,
      totalCount: group.fields.length,
      onToggleExpand: () => _setExpanded(group.label, !(_expanded[group.label] ?? false)),
      onToggleGroup: (v) {
        for (final f in group.fields) {
          f.onChanged(v);
        }
        _setExpanded(group.label, v);
      },
      expandedChild: Column(
        children: [for (final f in group.fields) _fieldRow(context, f)],
      ),
    );
  }

  Widget _signatureFieldRow(ReceiptProvider provider) {
    final data = provider.currentReceiptData;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final mode = data.signatureMode;
    final on = mode.trim().isNotEmpty;
    final sigSize = data.signatureFontSize;
    final sigFamily = data.signatureFontFamily;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(9),
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : const Color(0xFFFAFAFA),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            visualDensity: VisualDensity.compact,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.draw_outlined, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Signature',
                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            value: on,
            activeThumbColor: accent,
            onChanged: (v) {
              if (v) {
                if (mode.isEmpty) provider.updateSignatureMode('blank');
              } else {
                provider.updateSignatureMode('');
              }
            },
          ),
          if (on) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: [
                  Icon(Icons.format_size_rounded, size: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Text('Size', style: TextStyle(fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.55))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accent,
                        inactiveTrackColor: accent.withValues(alpha: 0.2),
                        thumbColor: accent,
                        overlayColor: accent.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: sigSize,
                        min: 14,
                        max: 36,
                        divisions: 11,
                        onChanged: provider.updateSignatureFontSize,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('${sigSize.toInt()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kSignatureFonts.map((font) {
                  final active = sigFamily == font;
                  return GestureDetector(
                    onTap: () => provider.updateSignatureFontFamily(active ? '' : font),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? accent
                            : (isDark
                                ? colorScheme.surfaceContainerHighest
                                : const Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? accent : colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        font,
                        style: GoogleFonts.getFont(
                          font,
                          fontSize: 13,
                          color: active ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _signatureGroupCard(ReceiptProvider provider) {
    final mode = provider.currentReceiptData.signatureMode;
    final groupOn = mode.trim().isNotEmpty;

    return _groupCardShell(
      icon: Icons.draw_outlined,
      label: 'Signature',
      groupOn: groupOn,
      onCount: groupOn ? 1 : 0,
      totalCount: 1,
      onToggleExpand: () => _setExpanded('Signature', !(_expanded['Signature'] ?? false)),
      onToggleGroup: (v) {
        if (v) {
          if (mode.isEmpty) provider.updateSignatureMode('blank');
        } else {
          provider.updateSignatureMode('');
        }
        _setExpanded('Signature', v);
      },
      expandedChild: _signatureFieldRow(provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final groups = _boolGroups();

    return _SectionCard(
      icon: Icons.tune_rounded,
      title: 'Receipt Fields',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flip a group on/off, or tap it to expand and fine-tune individual fields.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 10),
          _boolGroupCard(groups[0]),
          _boolGroupCard(groups[1]),
          _boolGroupCard(groups[2]),
          _signatureGroupCard(provider),
          _boolGroupCard(groups[3]),
        ],
      ),
    );
  }
}

// Reads ReceiptProvider directly via context.watch, so it didn't need
// any constructor params to begin with.
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
