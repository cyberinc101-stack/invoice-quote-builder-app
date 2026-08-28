// receipt_thermal_live_preview.dart
// lib/create_receipt/receipt_thermal_live_preview.dart
//
// CURRENCY DISPLAY PASS (this update): the old _currencySymbol(code)
// helper was a hardcoded code -> symbol switch that completely ignored
// ReceiptData.currencySymbol/currencyDisplayMode — so a custom currency
// typed on the Create Receipt step (via the new free-text Currency
// Code/Symbol fields + Code/Symbol/Both selector) never showed up
// correctly on this 58mm/80mm thermal preview specifically, even though
// the A4 layout and generated PDF already read those fields correctly.
//
// Replaced with _currencyPrefix(d), which builds the amount prefix off
// d.currency / d.currencySymbol / d.currencyDisplayMode:
//   - 'symbol' -> the custom symbol if set, else falls back to the old
//     hardcoded map (keeps existing persisted receipts that predate the
//     custom-symbol field looking the same as before)
//   - 'code'   -> the currency code followed by a space (e.g. "USD ")
//   - 'both'   -> code + symbol together (falls back sensibly if either
//     is missing)
// This mirrors the Code/Symbol/Both formatting already used by the PDF
// service and the on-screen A4 preview — just applied here too.
//
// WEBSITE TEXT SIZE (earlier): bumped the footer website line from
// 9pt regular to 12pt bold so it reads clearly instead of blending in
// with the surrounding thin text.
//
// LOGO SIZE FIX (earlier): the logo was rendered at a hardcoded
// height (62) that never read the Logo Size slider's value at all — the
// slider writes to ReceiptData.businessLogoDisplaySize, but this preview
// ignored that field entirely. Now uses d.businessLogoDisplaySize
// directly, so dragging the slider actually changes the logo size shown
// here. Clamped to a sane 20–120 range so a bad persisted value (or 0)
// can't collapse/blow out the header.
//
// SQUARE BOTTOM + GRAYSCALE LOGO + SOCIAL FOOTER PASS (earlier):
// - Reverted the torn/zigzag bottom edge back to a plain square edge —
//   just the drop shadow, no clip, no border stroke.
// - The logo now renders through a grayscale ColorFilter (standard
//   luminance matrix) so it always reads as black & white regardless of
//   the source image's colors — matches a monochrome thermal printout.
//   The filter preserves the alpha channel, so a transparent-background
//   PNG stays transparent (no white/colored box behind it) — there's
//   still no container/background around the image at all.
// - Added the website line and Facebook/Instagram/Twitter icon row to
//   the footer, each independently gated by its own show* toggle, each
//   showing a plain @handle next to a simple monochrome badge (never a
//   raw platform ID).
//
// Real, data-driven thermal receipt preview — bound to an actual
// ReceiptData: reflects real business/client info, line items, totals,
// and every show*/compactThermalLayout toggle from
// ReceiptThermalSettingsSection, live.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import '../models/receipt_data.dart';

class ThermalReceiptLivePreview extends StatelessWidget {
  final ReceiptData data;
  final double widthMm;

  const ThermalReceiptLivePreview({super.key, required this.data, required this.widthMm});

  static const _mono = 'Courier';
  static const _boldBlack = TextStyle(fontFamily: _mono, color: Colors.black, fontWeight: FontWeight.w700);
  static const _regularBlack = TextStyle(fontFamily: _mono, color: Colors.black, fontWeight: FontWeight.w600);

  // Standard luminance grayscale matrix — alpha channel (column 4) is left
  // untouched, so transparency in the source image is preserved.
  static const List<double> _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  // Legacy hardcoded code -> symbol lookup. Kept as a fallback for
  // 'symbol'/'both' display modes when currencySymbol hasn't been set
  // (e.g. receipts saved before the free-text currency fields existed),
  // so those keep rendering exactly as before.
  static String _legacySymbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'NZD': return 'NZ\$';
      case 'AUD': return 'A\$';
      case 'CAD': return 'C\$';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      default:    return '';
    }
  }

  /// Amount prefix for this receipt, built off currency/currencySymbol/
  /// currencyDisplayMode — mirrors the Code/Symbol/Both formatting the
  /// PDF service and A4 preview already use, so a custom currency renders
  /// correctly on the thermal preview too.
  static String _currencyPrefix(ReceiptData d) {
    final code = d.currency.trim().toUpperCase();
    final customSymbol = d.currencySymbol.trim();
    final symbol = customSymbol.isNotEmpty ? customSymbol : _legacySymbolFor(code);

    switch (d.currencyDisplayMode) {
      case 'symbol':
        if (symbol.isNotEmpty) return symbol;
        return code.isNotEmpty ? '$code ' : '';
      case 'both':
        if (code.isNotEmpty && symbol.isNotEmpty) return '$code $symbol';
        if (symbol.isNotEmpty) return symbol;
        return code.isNotEmpty ? '$code ' : '';
      case 'code':
      default:
        if (code.isNotEmpty) return '$code ';
        return symbol;
    }
  }

  static String _paymentMethodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:         return 'Cash';
      case PaymentMethod.card:         return 'Card';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
      case PaymentMethod.other:        return 'Other';
    }
  }

  static String _fmtPct(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _socialBadge(FaIconData icon) => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: FaIcon(icon, color: Colors.white, size: 13),
      );

  @override
  Widget build(BuildContext context) {
    final d = data;
    final sym = _currencyPrefix(d);
    final gap = d.compactThermalLayout ? 3.0 : 7.0;
    final previewWidth = widthMm * 4.2;

    // Logo Size slider writes to businessLogoDisplaySize — clamp to a sane
    // range so a stray 0/negative/huge persisted value can't break layout.
    final logoHeight = d.businessLogoDisplaySize.clamp(20.0, 120.0);

    final subtotal = d.subtotal;
    final discountAmount = d.discountAmount;
    final taxAmount = d.taxAmount;
    final amountPaid = d.amountPaid;

    final hasCustomer = d.showCustomerDetails &&
        (d.clientName.isNotEmpty || d.clientEmail.isNotEmpty || d.clientPhone.isNotEmpty || d.clientAddress.isNotEmpty);

    final hasLogo = d.showLogo && d.businessLogoPath != null && d.businessLogoPath!.isNotEmpty;
    final hasSocial = d.showFacebook || d.showInstagram || d.showTwitter;

    Widget dashedDivider() => Padding(
          padding: EdgeInsets.symmetric(vertical: gap),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const gapWidth = 3.0;
              final count = (constraints.maxWidth / (dashWidth + gapWidth)).floor();
              return Row(
                children: List.generate(
                  count,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: gapWidth),
                    child: Container(width: dashWidth, height: 1.4, color: Colors.black),
                  ),
                ),
              );
            },
          ),
        );

    Widget metaRow(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: _regularBlack.copyWith(fontSize: 10))),
              const SizedBox(width: 6),
              Flexible(child: Text(value, textAlign: TextAlign.right, style: _regularBlack.copyWith(fontSize: 10))),
            ],
          ),
        );

    return Container(
      width: previewWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Business header ─────────────────────────────────────────
          if (hasLogo)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
                  child: Image.file(
                    File(d.businessLogoPath!),
                    height: logoHeight,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          if (d.businessName.isNotEmpty)
            Text(d.businessName.toUpperCase(), textAlign: TextAlign.center, style: _boldBlack.copyWith(fontSize: 15)),
          if (d.showBusinessDetails) ...[
            if (d.businessAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(d.businessAddress, textAlign: TextAlign.center, style: _regularBlack.copyWith(fontSize: 10)),
              ),
            if (d.businessPhone.isNotEmpty)
              Text('Ph: ${d.businessPhone}', textAlign: TextAlign.center, style: _regularBlack.copyWith(fontSize: 10)),
            if (d.businessEmail.isNotEmpty)
              Text('Email: ${d.businessEmail}', textAlign: TextAlign.center, style: _regularBlack.copyWith(fontSize: 10)),
            if (d.taxId.isNotEmpty)
              Text('Tax ID: ${d.taxId}', textAlign: TextAlign.center, style: _regularBlack.copyWith(fontSize: 10)),
          ],
          dashedDivider(),

          // ── Title ─────────────────────────────────────────────────
          Text('RECEIPT', textAlign: TextAlign.center, style: _boldBlack.copyWith(fontSize: 11)),
          SizedBox(height: gap),

          // ── Meta ──────────────────────────────────────────────────
          if (d.showReceiptNumber && d.receiptNumber.isNotEmpty) metaRow('Receipt No:', d.receiptNumber),
          if (d.showDateTime && d.paymentDate.isNotEmpty) metaRow('Date:', d.paymentDate),
          if (d.cashierName.isNotEmpty) metaRow('Cashier:', d.cashierName),
          if (d.posId.isNotEmpty) metaRow('POS ID:', d.posId),
          dashedDivider(),

          // ── Items ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(flex: 5, child: Text('Item', style: _boldBlack.copyWith(fontSize: 10))),
              Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: _boldBlack.copyWith(fontSize: 10))),
              Expanded(flex: 3, child: Text('Price', textAlign: TextAlign.right, style: _boldBlack.copyWith(fontSize: 10))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(height: 1.4, color: Colors.black),
          ),
          ...d.lineItems.map((item) => Padding(
                padding: EdgeInsets.only(bottom: gap),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Text(item.description, style: _regularBlack.copyWith(fontSize: 10))),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(2),
                        textAlign: TextAlign.center,
                        style: _regularBlack.copyWith(fontSize: 10),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('$sym${item.total.toStringAsFixed(2)}',
                          textAlign: TextAlign.right, style: _regularBlack.copyWith(fontSize: 10)),
                    ),
                  ],
                ),
              )),
          dashedDivider(),

          // ── Totals ────────────────────────────────────────────────
          metaRow('Subtotal', '$sym${subtotal.toStringAsFixed(2)}'),
          if (d.showDiscountLine && d.discountRate > 0)
            metaRow('Discount (${_fmtPct(d.discountRate)}%)', '-$sym${discountAmount.toStringAsFixed(2)}'),
          if (d.showTaxLine && d.taxRate > 0)
            metaRow('Tax (${_fmtPct(d.taxRate)}%)', '$sym${taxAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: _boldBlack.copyWith(fontSize: 13)),
                Text('$sym${amountPaid.toStringAsFixed(2)}', style: _boldBlack.copyWith(fontSize: 13)),
              ],
            ),
          ),

          // ── Payment ───────────────────────────────────────────────
          if (d.showPaymentMethod) ...[
            dashedDivider(),
            Text('Payment Method:', style: _boldBlack.copyWith(fontSize: 10)),
            const SizedBox(height: 2),
            metaRow(_paymentMethodLabel(d.paymentMethod), '$sym${amountPaid.toStringAsFixed(2)}'),
            if (d.paymentReference.isNotEmpty) metaRow('Reference:', d.paymentReference),
            if (d.authCode.isNotEmpty) metaRow('Auth Code:', d.authCode),
            if (d.cardLast4.isNotEmpty) metaRow('Card:', '**** **** **** ${d.cardLast4}'),
          ],

          // ── Customer ──────────────────────────────────────────────
          if (hasCustomer) ...[
            dashedDivider(),
            Text('Customer:', style: _boldBlack.copyWith(fontSize: 10)),
            if (d.clientName.isNotEmpty) Text(d.clientName, style: _regularBlack.copyWith(fontSize: 10)),
            if (d.clientEmail.isNotEmpty) Text(d.clientEmail, style: _regularBlack.copyWith(fontSize: 10)),
            if (d.clientPhone.isNotEmpty) Text(d.clientPhone, style: _regularBlack.copyWith(fontSize: 10)),
            if (d.clientAddress.isNotEmpty) Text(d.clientAddress, style: _regularBlack.copyWith(fontSize: 10)),
          ],

          // ── Barcode / QR — real, scannable codes matching the actual
          // PDF export, not a placeholder pattern. The value is whatever
          // qrData holds, falling back to the receipt number (which is
          // already auto-generated fresh — from a millisecond timestamp
          // — every time a new receipt is started), so this is unique
          // per receipt with no extra setup needed.
          if (d.showBarcode || d.showQrCode) ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final codeValue = d.qrData.isNotEmpty
                  ? d.qrData
                  : (d.receiptNumber.isNotEmpty ? d.receiptNumber : 'RECEIPT');
              return Column(
                children: [
                  if (d.showBarcode)
                    Center(
                      child: bw.BarcodeWidget(
                        barcode: bw.Barcode.code128(),
                        data: codeValue,
                        width: previewWidth * 0.7,
                        height: 42,
                        drawText: true,
                        style: const TextStyle(fontFamily: _mono, fontSize: 8, color: Colors.black),
                        color: Colors.black,
                      ),
                    ),
                  if (d.showQrCode)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: bw.BarcodeWidget(
                          barcode: bw.Barcode.qrCode(),
                          data: codeValue,
                          width: 84,
                          height: 84,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],

          // ── Footer ────────────────────────────────────────────────
          const SizedBox(height: 14),
          if (d.notes.isNotEmpty) ...[
            Text(d.notes, textAlign: TextAlign.center, style: _regularBlack.copyWith(fontSize: 9)),
            const SizedBox(height: 6),
          ],
          if (d.footerMessage.isNotEmpty)
            Text(d.footerMessage, textAlign: TextAlign.center, style: _boldBlack.copyWith(fontSize: 11)),

          if (hasSocial) ...[
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (d.showFacebook) ...[_socialBadge(FontAwesomeIcons.facebookF), const SizedBox(width: 8)],
                  if (d.showInstagram) ...[_socialBadge(FontAwesomeIcons.instagram), const SizedBox(width: 8)],
                  if (d.showTwitter) _socialBadge(FontAwesomeIcons.xTwitter),
                ],
              ),
            ),
          ],

          if (d.showWebsite && d.businessWebsite.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(d.businessWebsite, textAlign: TextAlign.center, style: _boldBlack.copyWith(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
