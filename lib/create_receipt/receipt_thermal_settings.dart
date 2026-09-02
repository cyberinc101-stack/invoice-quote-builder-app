// receipt_thermal_settings.dart
// lib/create_receipt/receipt_thermal_settings.dart
//
// CHARACTER-LIMIT HARDENING PASS (this update): every field on this
// section previously used caps borrowed loosely from the A4 flow's own
// conventions (40/20/40/20/100/120/80) — reasonable widths for a
// full-page document, but generous for a 58/80mm roll that prints
// roughly 32-48 monospace characters per line. Tightened each field to a
// width that comfortably fits one printed line at the smaller 58mm size
// without wrapping awkwardly:
//   Tax ID / GST Number:        40 -> 24
//   Cashier Name:                40 -> 20
//   POS / Register ID:           20 -> 12
//   Reference / Transaction ID:  40 -> 24
//   Auth Code:                   20 -> 12
//   Code Value (barcode/QR):    100 -> 60  (barcode drawText renders this
//                                            below the code itself, so it
//                                            still needs to fit one line;
//                                            QR codes can absorb more data
//                                            than a printed barcode label
//                                            can, so 60 stays generous
//                                            enough for either)
//   Footer Message:             120 -> 80  (wraps across multiple lines
//                                            rather than overflowing --
//                                            this cap is about keeping the
//                                            printed strip a reasonable
//                                            length, not preventing an
//                                            outright layout break)
//   Website:                     80 -> 40
// Now that ReceiptField actually displays its counter (see
// receipt_edit_widgets.dart's CHARACTER-COUNTER DISPLAY FIX), these
// tighter caps are also visible to the user while typing instead of only
// enforced silently.
//
// SOCIAL TOGGLES-ONLY PASS (earlier): removed the @handle text input
// under each social platform row — Facebook/Instagram/Twitter are now
// just a show/hide toggle each, no typing required. The handle
// controllers are still accepted (constructor signature unchanged, so
// nothing else has to change) but are no longer rendered here.
//
// WEBSITE + SOCIAL PASS (earlier): added a "Website & Social" section
// — a website text field + toggle, and one row per platform (Facebook/
// Instagram/Twitter) pairing a show/hide switch with an @handle field
// that only appears once that platform is toggled on. Handles are plain
// text, not raw platform IDs — see the recommendation in
// ReceiptPdfService / create_receipt_screen's header comments for why.
//
// "Thermal Receipt Settings" panel shown on CreateReceiptScreen's Review
// step whenever the chosen paper format is thermal (58mm/80mm).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'receipt_edit_widgets.dart' show receiptSectionHeader, ReceiptField;

class ReceiptThermalSettingsSection extends StatelessWidget {
  final Color accent;

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

  final bool showLogo;
  final bool showBusinessDetails;
  final bool showCustomerDetails;
  final bool showReceiptNumber;
  final bool showDateTime;
  final bool showTaxLine;
  final bool showDiscountLine;
  final bool showPaymentMethod;
  final bool showBarcode;
  final bool showQrCode;
  final bool compactLayout;
  final bool showWebsite;
  final bool showFacebook;
  final bool showInstagram;
  final bool showTwitter;

  final ValueChanged<bool> onShowLogoChanged;
  final ValueChanged<bool> onShowBusinessDetailsChanged;
  final ValueChanged<bool> onShowCustomerDetailsChanged;
  final ValueChanged<bool> onShowReceiptNumberChanged;
  final ValueChanged<bool> onShowDateTimeChanged;
  final ValueChanged<bool> onShowTaxLineChanged;
  final ValueChanged<bool> onShowDiscountLineChanged;
  final ValueChanged<bool> onShowPaymentMethodChanged;
  final ValueChanged<bool> onShowBarcodeChanged;
  final ValueChanged<bool> onShowQrCodeChanged;
  final ValueChanged<bool> onCompactLayoutChanged;
  final ValueChanged<bool> onShowWebsiteChanged;
  final ValueChanged<bool> onShowFacebookChanged;
  final ValueChanged<bool> onShowInstagramChanged;
  final ValueChanged<bool> onShowTwitterChanged;

  const ReceiptThermalSettingsSection({
    super.key,
    required this.accent,
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
    required this.showLogo,
    required this.showBusinessDetails,
    required this.showCustomerDetails,
    required this.showReceiptNumber,
    required this.showDateTime,
    required this.showTaxLine,
    required this.showDiscountLine,
    required this.showPaymentMethod,
    required this.showBarcode,
    required this.showQrCode,
    required this.compactLayout,
    required this.showWebsite,
    required this.showFacebook,
    required this.showInstagram,
    required this.showTwitter,
    required this.onShowLogoChanged,
    required this.onShowBusinessDetailsChanged,
    required this.onShowCustomerDetailsChanged,
    required this.onShowReceiptNumberChanged,
    required this.onShowDateTimeChanged,
    required this.onShowTaxLineChanged,
    required this.onShowDiscountLineChanged,
    required this.onShowPaymentMethodChanged,
    required this.onShowBarcodeChanged,
    required this.onShowQrCodeChanged,
    required this.onCompactLayoutChanged,
    required this.onShowWebsiteChanged,
    required this.onShowFacebookChanged,
    required this.onShowInstagramChanged,
    required this.onShowTwitterChanged,
  });

  Widget _toggleRow(BuildContext context, String label, bool value, ValueChanged<bool> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.8))),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: accent,
          ),
        ],
      ),
    );
  }

  // Social platform row — toggle only. The @handle input was removed;
  // toggling a platform just shows/hides its badge on the receipt, with
  // no handle text next to it.
  Widget _socialPlatformRow(
    BuildContext context, {
    required String label,
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return _toggleRow(context, label, enabled, onToggle);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Thermal Receipt Settings', accent, icon: Icons.receipt_long_rounded),

        // ── Section visibility toggles ──────────────────────────────
        _toggleRow(context, 'Business logo', showLogo, onShowLogoChanged),
        _toggleRow(context, 'Business details (address/phone/email/tax ID)', showBusinessDetails, onShowBusinessDetailsChanged),
        _toggleRow(context, 'Customer details', showCustomerDetails, onShowCustomerDetailsChanged),
        _toggleRow(context, 'Receipt number', showReceiptNumber, onShowReceiptNumberChanged),
        _toggleRow(context, 'Date/time', showDateTime, onShowDateTimeChanged),
        _toggleRow(context, 'Tax / GST line', showTaxLine, onShowTaxLineChanged),
        _toggleRow(context, 'Discount line', showDiscountLine, onShowDiscountLineChanged),
        _toggleRow(context, 'Payment method details', showPaymentMethod, onShowPaymentMethodChanged),
        _toggleRow(context, 'Barcode', showBarcode, onShowBarcodeChanged),
        _toggleRow(context, 'QR code', showQrCode, onShowQrCodeChanged),
        _toggleRow(context, 'Compact layout (tighter spacing)', compactLayout, onCompactLayoutChanged),

        const SizedBox(height: 16),
        receiptSectionHeader(context, 'Business Details', accent, icon: Icons.storefront_rounded),
        // CHARACTER-LIMIT HARDENING PASS: 40 -> 24, sized to fit one
        // printed line on a 58mm roll instead of the A4-scale cap.
        ReceiptField(
          ctrl: taxIdCtrl,
          label: 'Tax ID / GST Number',
          accent: accent,
          icon: Icons.badge_outlined,
          max: 24,
        ),

        const SizedBox(height: 16),
        receiptSectionHeader(context, 'Staff & Terminal', accent, icon: Icons.badge_rounded),
        Row(
          children: [
            Expanded(
              // CHARACTER-LIMIT HARDENING PASS: 40 -> 20.
              child: ReceiptField(
                ctrl: cashierNameCtrl,
                label: 'Cashier Name',
                accent: accent,
                icon: Icons.person_outline_rounded,
                max: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              // CHARACTER-LIMIT HARDENING PASS: 20 -> 12 — a POS/register
              // ID is a short code, not a name; 12 is already generous.
              child: ReceiptField(
                ctrl: posIdCtrl,
                label: 'POS / Register ID',
                accent: accent,
                icon: Icons.point_of_sale_rounded,
                max: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        receiptSectionHeader(context, 'Payment Reference', accent, icon: Icons.credit_card_rounded),
        // CHARACTER-LIMIT HARDENING PASS: 40 -> 24.
        ReceiptField(
          ctrl: paymentReferenceCtrl,
          label: 'Reference / Transaction ID',
          accent: accent,
          icon: Icons.confirmation_number_outlined,
          max: 24,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              // CHARACTER-LIMIT HARDENING PASS: 20 -> 12, matching POS ID
              // above — an auth code is a short alphanumeric string, not
              // free text.
              child: ReceiptField(
                ctrl: authCodeCtrl,
                label: 'Auth Code',
                accent: accent,
                icon: Icons.verified_outlined,
                max: 12,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: cardLast4Ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'Card Last 4 Digits',
                  prefixIcon: Icon(Icons.credit_card_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),

        if (showBarcode || showQrCode) ...[
          const SizedBox(height: 16),
          receiptSectionHeader(context, 'Barcode / QR Data', accent, icon: Icons.qr_code_2_rounded),
          // CHARACTER-LIMIT HARDENING PASS: 100 -> 60. A code128 barcode
          // renders this value as printed text directly beneath the
          // bars (drawText: true in both the live preview and the PDF
          // builder) — that text needs to fit one line at 58mm just like
          // any other field here. QR codes can hold far more, but there's
          // no separate field to split the two, so 60 stays the shared
          // cap; a QR-only receipt still has plenty of room within it.
          ReceiptField(
            ctrl: qrDataCtrl,
            label: 'Code Value (defaults to receipt number)',
            accent: accent,
            icon: Icons.qr_code_rounded,
            max: 60,
          ),
        ],

        const SizedBox(height: 16),
        receiptSectionHeader(context, 'Footer Message', accent, icon: Icons.chat_bubble_outline_rounded),
        // CHARACTER-LIMIT HARDENING PASS: 120 -> 80. This text wraps
        // across multiple printed lines rather than overflowing
        // horizontally, so the cap here is about keeping the printed
        // strip a sane length rather than preventing a hard break.
        ReceiptField(
          ctrl: footerMessageCtrl,
          label: 'Footer Message',
          accent: accent,
          icon: Icons.short_text_rounded,
          max: 80,
        ),

        // ── Website & Social ───────────────────────────────────────
        const SizedBox(height: 16),
        receiptSectionHeader(context, 'Website & Social', accent, icon: Icons.public_rounded),
        _toggleRow(context, 'Website', showWebsite, onShowWebsiteChanged),
        if (showWebsite)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            // CHARACTER-LIMIT HARDENING PASS: 80 -> 40 — a printed
            // website line at 12pt bold on a 58mm roll wraps badly well
            // before 80 characters; 40 keeps it to a realistic domain +
            // short path.
            child: ReceiptField(
              ctrl: websiteCtrl,
              label: 'Website',
              accent: accent,
              icon: Icons.language_rounded,
              max: 40,
            ),
          ),
        _socialPlatformRow(
          context,
          label: 'Facebook',
          enabled: showFacebook,
          onToggle: onShowFacebookChanged,
        ),
        _socialPlatformRow(
          context,
          label: 'Instagram',
          enabled: showInstagram,
          onToggle: onShowInstagramChanged,
        ),
        _socialPlatformRow(
          context,
          label: 'Twitter / X',
          enabled: showTwitter,
          onToggle: onShowTwitterChanged,
        ),
      ],
    );
  }
}
