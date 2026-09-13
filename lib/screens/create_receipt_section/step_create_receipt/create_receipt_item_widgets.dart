// lib/screens/create_receipt_section/step_create_receipt/create_receipt_item_widgets.dart
//
// NEW FILE — CREATE-RECEIPT UI PARITY PASS: mirrors
// create_quote_section/step_create_quote/create_quote_item_widgets.dart.
// A single-draft "New Item" card with its own Save Item button (instead
// of Receipt's old N-cards-always-editable list), a compact read-only
// committed-item row, and a live Totals card.
//
// PER-ITEM TAX/DISCOUNT PASS (this update): CreateReceiptItemCard now
// has the same per-item Tax/Discount toggle+sign+name block Quote's
// CreateQuoteItemCard has — Receipt's LineItem is the same shared class
// from invoice_data.dart, so this is a straight parity port, no new
// LineItem fields needed. Total displays (draft card + committed row)
// now use item.lineNetTotal (post item-tax/discount) instead of
// item.total (pre), matching Quote's own item total display.
// CreateReceiptTotalsCard gained itemTaxByName/itemDiscountByName +
// taxEnabled/discountEnabled/taxName/discountName params, rendering one
// breakdown row per distinct item-tax/discount name — mirrors
// CreateQuoteTotalsCard exactly. See receipt_data.dart's PER-ITEM
// TAX/DISCOUNT PASS for the model-side math these numbers come from.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/invoice_data.dart'
    show LineItem, unitPriceSuffix, unitDisplayLabel;
import 'create_receipt_form_widgets.dart'
    show
        CreateReceiptUnitDropdown,
        CreateReceiptTaxSignToggle,
        CreateReceiptRateNameField,
        CreateReceiptRateNameKind;

// =============================================================================
// Draft item card — the single "type a new item" editor
// =============================================================================

class CreateReceiptItemCard extends StatelessWidget {
  final LineItem item;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController unitCustomLabelCtrl;
  final TextEditingController taxRateCtrl;
  final TextEditingController discountRateCtrl;
  final TextEditingController taxNameCtrl;
  final TextEditingController discountNameCtrl;
  final String currencySymbol;
  final Color accent;
  final VoidCallback onChanged;
  final VoidCallback onSaveItem;

  const CreateReceiptItemCard({
    super.key,
    required this.item,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.unitCustomLabelCtrl,
    required this.taxRateCtrl,
    required this.discountRateCtrl,
    required this.taxNameCtrl,
    required this.discountNameCtrl,
    required this.currencySymbol,
    required this.accent,
    required this.onChanged,
    required this.onSaveItem,
  });

  static const int _descriptionMax = 200;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final priceSuffix = unitPriceSuffix(item.unit, customUnitLabel: item.customUnitLabel);
    final priceLabel = priceSuffix == null
        ? 'Price ($currencySymbol)'
        : 'Price ($currencySymbol, per $priceSuffix)';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: accent.withValues(alpha: 0.35), width: 1.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 17, color: accent),
                const SizedBox(width: 6),
                Text(
                  'New Item',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: descCtrl,
              style: TextStyle(color: colorScheme.onSurface),
              inputFormatters: [
                LengthLimitingTextInputFormatter(_descriptionMax),
              ],
              onChanged: (v) {
                item.description = v;
                onChanged();
              },
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6)),
                hintText: 'e.g. Consulting Services',
                hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                    fontSize: 13),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF9F9F9),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accent, width: 1.5)),
                counterText: '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 2),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${descCtrl.text.length} / $_descriptionMax',
                  style: TextStyle(
                    fontSize: 11,
                    color: descCtrl.text.length >= _descriptionMax
                        ? const Color(0xFFF44336)
                        : colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            CreateReceiptUnitDropdown(
              value: item.unit,
              accent: accent,
              onChanged: (v) {
                item.unit = v;
                if (v != 'custom') item.customUnitLabel = '';
                onChanged();
              },
            ),
            if (item.unit == 'custom') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: unitCustomLabelCtrl,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                inputFormatters: [LengthLimitingTextInputFormatter(24)],
                onChanged: (v) {
                  item.customUnitLabel = v;
                  onChanged();
                },
                decoration: InputDecoration(
                  labelText: 'Custom Unit Name',
                  labelStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                  hintText: 'e.g. sqm, page, seat',
                  hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 12),
                  filled: true,
                  fillColor: isDark
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFF9F9F9),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
            ],
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: qtyCtrl,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (v) {
                      item.quantity = double.tryParse(v) ?? 1;
                      onChanged();
                    },
                    decoration: _smallDeco(
                        context, 'Qty', colorScheme, isDark, accent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: priceCtrl,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (v) {
                      item.unitPrice = double.tryParse(v) ?? 0;
                      onChanged();
                    },
                    decoration: _smallDeco(context, priceLabel,
                        colorScheme, isDark, accent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(height: 2),
                        Text(
                          '$currencySymbol${item.lineNetTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Per-item Tax / Discount — PER-ITEM TAX/DISCOUNT PASS:
            // mirrors CreateQuoteItemCard's identical block exactly.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Tax for this item',
                                style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                          ),
                          Switch(
                            value: item.taxEnabled,
                            onChanged: (v) {
                              item.taxEnabled = v;
                              onChanged();
                            },
                            activeTrackColor: accent,
                          ),
                        ],
                      ),
                      if (item.taxEnabled) ...[
                        CreateReceiptRateNameField(
                          controller: taxNameCtrl,
                          hint: 'VAT, GST…',
                          accent: accent,
                          kind: CreateReceiptRateNameKind.tax,
                          onChanged: (v) {
                            item.itemTaxName = v;
                            onChanged();
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CreateReceiptTaxSignToggle(
                              isAddition: item.itemTaxIsAddition,
                              accent: accent,
                              onChanged: (v) {
                                item.itemTaxIsAddition = v;
                                onChanged();
                              },
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 64,
                              child: TextFormField(
                                controller: taxRateCtrl,
                                textAlign: TextAlign.center,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                                onChanged: (v) {
                                  item.itemTaxRate = (double.tryParse(v) ?? 0.0).clamp(0.0, 100.0);
                                  onChanged();
                                },
                                decoration: InputDecoration(
                                  isDense: true,
                                  suffixText: '%',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  filled: true,
                                  fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Discount for this item',
                          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                    ),
                    Switch(
                      value: item.discountEnabled,
                      onChanged: (v) {
                        item.discountEnabled = v;
                        onChanged();
                      },
                      activeTrackColor: accent,
                    ),
                  ],
                ),
                if (item.discountEnabled) ...[
                  CreateReceiptRateNameField(
                    controller: discountNameCtrl,
                    hint: 'Loyalty Discount, Bulk Discount…',
                    accent: accent,
                    kind: CreateReceiptRateNameKind.discount,
                    onChanged: (v) {
                      item.itemDiscountName = v;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      controller: discountRateCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                      onChanged: (v) {
                        item.itemDiscountRate = (double.tryParse(v) ?? 0.0).clamp(0.0, 100.0);
                        onChanged();
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        suffixText: '%',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        filled: true,
                        fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
            const SizedBox(height: 4),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onSaveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Item',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _smallDeco(BuildContext context, String label,
      ColorScheme cs, bool isDark, Color accent) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12),
      filled: true,
      fillColor:
          isDark ? cs.surfaceContainerHighest : const Color(0xFFF9F9F9),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5)),
      counterText: '',
    );
  }
}

// =============================================================================
// Committed item row — compact, read-only summary for an item already
// added to the receipt.
// =============================================================================

class CreateReceiptCommittedItemRow extends StatelessWidget {
  final LineItem item;
  final String currencySymbol;
  final Color accent;
  final VoidCallback onRemove;

  const CreateReceiptCommittedItemRow({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.accent,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unitLabel = item.unit.isEmpty
        ? null
        : unitDisplayLabel(item.unit, customUnitLabel: item.customUnitLabel);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description.trim().isEmpty ? '(no description)' : item.description.trim(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (unitLabel != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(unitLabel,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: accent)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} × $currencySymbol${item.unitPrice.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 8),
          Text(
            '$currencySymbol${item.lineNetTotal.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: accent),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.close_rounded, color: Color(0xFFEF5350), size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Totals card — whole-receipt Tax/Discount rows only rendered when
// enabled (matches ReceiptData.taxEnabled/discountEnabled), each showing
// its custom name when one's set (matches ReceiptData.taxName/
// discountName), same pattern as CreateQuoteTotalsCard.
// =============================================================================

class CreateReceiptTotalsCard extends StatelessWidget {
  final double subtotal, taxAmount, discountAmount, amountPaid;
  final double taxRate, discountRate;
  final String taxName;
  final String discountName;
  final bool taxEnabled;
  final bool discountEnabled;

  // PER-ITEM TAX/DISCOUNT PASS: per-distinct-name breakdown of item-level
  // tax/discount extras — mirrors CreateQuoteTotalsCard's identical
  // params exactly. Empty maps (the default) render nothing extra, so
  // every existing call site is unaffected.
  final Map<String, double> itemTaxByName;
  final Map<String, double> itemDiscountByName;

  final String currencySymbol;
  final bool isDark;
  final Color accent;

  const CreateReceiptTotalsCard({
    super.key,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.amountPaid,
    required this.taxRate,
    required this.discountRate,
    required this.currencySymbol,
    required this.isDark,
    required this.accent,
    this.taxName = '',
    this.discountName = '',
    this.taxEnabled = true,
    this.discountEnabled = true,
    this.itemTaxByName = const {},
    this.itemDiscountByName = const {},
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2A0F) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _row('Subtotal', '$currencySymbol${subtotal.toStringAsFixed(2)}', colorScheme),
          if (taxEnabled) ...[
            const SizedBox(height: 8),
            _row(
                '${taxName.trim().isEmpty ? 'Tax' : taxName.trim()} (${taxRate.toStringAsFixed(taxRate % 1 == 0 ? 0 : 1)}%)',
                '+$currencySymbol${taxAmount.toStringAsFixed(2)}', colorScheme),
          ],
          if (discountEnabled) ...[
            const SizedBox(height: 8),
            _row(
                '${discountName.trim().isEmpty ? 'Discount' : discountName.trim()} (${discountRate.toStringAsFixed(discountRate % 1 == 0 ? 0 : 1)}%)',
                '-$currencySymbol${discountAmount.toStringAsFixed(2)}', colorScheme),
          ],
          for (final entry in itemTaxByName.entries)
            if (entry.value != 0) ...[
              const SizedBox(height: 8),
              _row(
                  entry.key.isEmpty ? 'Item Tax' : 'Item Tax (${entry.key})',
                  '${entry.value >= 0 ? '+' : '-'}$currencySymbol${entry.value.abs().toStringAsFixed(2)}',
                  colorScheme),
            ],
          for (final entry in itemDiscountByName.entries)
            if (entry.value > 0) ...[
              const SizedBox(height: 8),
              _row(
                  entry.key.isEmpty ? 'Item Discounts' : 'Item Discounts (${entry.key})',
                  '-$currencySymbol${entry.value.toStringAsFixed(2)}',
                  colorScheme),
            ],
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
              Flexible(
                child: Text(
                  '$currencySymbol${amountPaid.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
