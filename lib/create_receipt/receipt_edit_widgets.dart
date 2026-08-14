// lib/create_receipt/receipt_edit_widgets.dart
//
// Reusable pieces for the Receipt step flow — mirrors the naming and shape
// of create_quote_section/quote_edit_widgets.dart (QuoteField, QuoteItemCard,
// QuoteTotalsCard, QuoteStepNavBar, quoteSectionHeader) so Receipt, Quote,
// and Invoice all read the same way.
//
// ADDED (this pass): kReceiptCurrencies / receiptCurrencySymbol() and
// ReceiptColorPicker — the receipt equivalents of quote_edit_widgets.dart's
// kQuoteCurrencies / quoteCurrencySymbol() / QuoteColorPicker, needed by
// CreateReceiptScreen's Client & Details and Review & Save steps.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/receipt_data.dart' show PaymentMethod, ReceiptColor;

// ─────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────

Widget receiptSectionHeader(
  BuildContext context,
  String label,
  Color accent, {
  IconData? icon,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration:
              BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        if (icon != null) ...[
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Text field
// ─────────────────────────────────────────────────────────────────────────

class ReceiptField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final Color accent;
  final IconData? icon;
  final int? max;
  final int maxLines;
  final bool required;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const ReceiptField({
    super.key,
    required this.ctrl,
    required this.label,
    required this.accent,
    this.icon,
    this.max,
    this.maxLines = 1,
    this.required = false,
    this.keyboard,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: TextStyle(color: colorScheme.onSurface),
      inputFormatters:
          max != null ? [LengthLimitingTextInputFormatter(max!)] : null,
      onChanged: onChanged,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.45))
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor:
            isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Date field
// ─────────────────────────────────────────────────────────────────────────

class ReceiptDateField extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  const ReceiptDateField({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value,
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Payment method picker
// ─────────────────────────────────────────────────────────────────────────

class ReceiptPaymentMethodPicker extends StatelessWidget {
  final PaymentMethod selected;
  final Color accent;
  final ValueChanged<PaymentMethod> onChanged;

  const ReceiptPaymentMethodPicker({
    super.key,
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  static String _labelFor(PaymentMethod m) => switch (m) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Card',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((m) {
        final isSelected = selected == m;
        return GestureDetector(
          onTap: () => onChanged(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent
                  : (isDark
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFF5F5F5)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _labelFor(m),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Line item card
// ─────────────────────────────────────────────────────────────────────────

class ReceiptItemCard extends StatelessWidget {
  final int index;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final double total;
  final String currencySymbol;
  final bool canRemove;
  final Color accent;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const ReceiptItemCard({
    super.key,
    required this.index,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.total,
    required this.currencySymbol,
    required this.canRemove,
    required this.accent,
    required this.onRemove,
    required this.onChanged,
  });

  InputDecoration _smallDeco(ColorScheme cs, bool isDark, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12),
      filled: true,
      fillColor: isDark ? cs.surfaceContainerHighest : const Color(0xFFF9F9F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Item ${index + 1}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface)),
                const Spacer(),
                if (canRemove)
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFFEF5350), size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: descCtrl,
              style: TextStyle(color: colorScheme.onSurface),
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                filled: true,
                fillColor:
                    isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: qtyCtrl,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => onChanged(),
                    decoration: _smallDeco(colorScheme, isDark, 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: priceCtrl,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => onChanged(),
                    decoration: _smallDeco(colorScheme, isDark, 'Price ($currencySymbol)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: TextStyle(
                                fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(height: 2),
                        Text('$currencySymbol ${total.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Totals card
// ─────────────────────────────────────────────────────────────────────────

class ReceiptTotalsCard extends StatelessWidget {
  final double subtotal, taxAmount, discountAmount, amountPaid;
  final double taxRate, discountRate;
  final String currencySymbol;
  final Color accent;

  const ReceiptTotalsCard({
    super.key,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.amountPaid,
    required this.taxRate,
    required this.discountRate,
    required this.currencySymbol,
    required this.accent,
  });

  Widget _row(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7))),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2A0F) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _row('Subtotal', '$currencySymbol ${subtotal.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row('Tax (${taxRate.toStringAsFixed(taxRate % 1 == 0 ? 0 : 1)}%)',
              '$currencySymbol ${taxAmount.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row('Discount (${discountRate.toStringAsFixed(discountRate % 1 == 0 ? 0 : 1)}%)',
              '-$currencySymbol ${discountAmount.toStringAsFixed(2)}', colorScheme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: accent.withValues(alpha: 0.3), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount Paid',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              Text('$currencySymbol ${amountPaid.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bottom step nav bar
// ─────────────────────────────────────────────────────────────────────────

class ReceiptStepNavBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final IconData nextIcon;
  final bool isLoading;
  final Color accent;

  const ReceiptStepNavBar({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
    required this.nextIcon,
    required this.isLoading,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.55), size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: isLoading ? null : onNext,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLoading
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [accent.withValues(alpha: 0.85), accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isLoading
                      ? []
                      : [
                          BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Icon(nextIcon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      nextLabel,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Currency list / symbol lookup
// Mirrors quote_edit_widgets.dart's kQuoteCurrencies / quoteCurrencySymbol.
// ─────────────────────────────────────────────────────────────────────────

const List<Map<String, String>> kReceiptCurrencies = [
  {'code': 'USD', 'symbol': r'$'},
  {'code': 'EUR', 'symbol': '€'},
  {'code': 'GBP', 'symbol': '£'},
  {'code': 'CAD', 'symbol': r'$'},
  {'code': 'AUD', 'symbol': r'$'},
  {'code': 'NZD', 'symbol': r'$'},
  {'code': 'INR', 'symbol': '₹'},
  {'code': 'JPY', 'symbol': '¥'},
  {'code': 'ZAR', 'symbol': 'R'},
];

String receiptCurrencySymbol(String code) {
  final match = kReceiptCurrencies.firstWhere(
    (c) => c['code'] == code,
    orElse: () => const {'code': 'USD', 'symbol': r'$'},
  );
  return match['symbol']!;
}

// ─────────────────────────────────────────────────────────────────────────
// Accent color picker for ReceiptColor
// Mirrors quote_edit_widgets.dart's QuoteColorPicker.
// ─────────────────────────────────────────────────────────────────────────

const Map<ReceiptColor, Color> kReceiptColorSwatches = {
  ReceiptColor.blue:   Color(0xFF1565C0),
  ReceiptColor.green:  Color(0xFF2E7D32),
  ReceiptColor.purple: Color(0xFF6A1B9A),
  ReceiptColor.orange: Color(0xFFE65100),
  ReceiptColor.red:    Color(0xFFC62828),
  ReceiptColor.teal:   Color(0xFF00695C),
  ReceiptColor.black:  Color(0xFF212121),
  ReceiptColor.indigo: Color(0xFF283593),
};

class ReceiptColorPicker extends StatelessWidget {
  final ReceiptColor selected;
  final ValueChanged<ReceiptColor> onChanged;

  const ReceiptColorPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ReceiptColor.values.map((c) {
        final color = kReceiptColorSwatches[c]!;
        final isSelected = selected == c;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
          ),
        );
      }).toList(),
    );
  }
}
