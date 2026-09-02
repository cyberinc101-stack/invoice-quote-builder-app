// lib/screens/invoice_create_section/step_create_invoice/create_invoice_item_widgets.dart
//
// FILE SPLIT: extracted from the former single step_create_invoice.dart
// (was _ItemCard and _TotalsCard, now public as CreateInvoiceItemCard and
// CreateInvoiceTotalsCard so step_create_invoice.dart can import them).
// No behavior changed — only location and class names.
//
// DESCRIPTION COUNTER: CreateInvoiceItemCard's Description field already
// had a real 200-character cap (LengthLimitingTextInputFormatter(200))
// but no visible feedback — the decoration hid its native counter via
// counterText: ''. There's now a visible "N / 200" counter underneath,
// matching the counter style used elsewhere in this step.
//
// OVERFLOW SAFETY: CreateInvoiceTotalsCard's row() helper and the
// separate Total row both wrap label and value in Flexible with
// maxLines: 1 + ellipsis, mirroring the identical fix already applied to
// shared_doc_widgets.dart's buildSharedTotalsAndNotesSection and
// pdf_templates.dart's _sharedTotalsAndNotes. This is defense in depth on
// top of the tax/discount rate clamp that lives in the parent step
// (StepCreateInvoice._taxRate/_discountRate).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/invoice_models.dart';

// =============================================================================
// Item card
// =============================================================================

class CreateInvoiceItemCard extends StatelessWidget {
  final int index;
  final InvoiceItem item;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final String currencySymbol;
  final bool canRemove;
  final Color accent;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const CreateInvoiceItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.currencySymbol,
    required this.canRemove,
    required this.accent,
    required this.onRemove,
    required this.onChanged,
  });

  static const int _descriptionMax = 200;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
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
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: accent),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
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

            // Description
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
                    borderSide:
                        BorderSide(color: accent, width: 1.5)),
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
            const SizedBox(height: 4),

            // Qty / Price / Total
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
                      LengthLimitingTextInputFormatter(10),
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
                      LengthLimitingTextInputFormatter(12),
                    ],
                    onChanged: (v) {
                      item.unitPrice = double.tryParse(v) ?? 0;
                      onChanged();
                    },
                    decoration: _smallDeco(context, 'Price ($currencySymbol)',
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
                          '$currencySymbol${item.total.toStringAsFixed(2)}',
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
// Totals card
// =============================================================================

class CreateInvoiceTotalsCard extends StatelessWidget {
  final double subtotal, taxAmount, discountAmount, total;
  final double taxRate, discountRate;
  final String currencySymbol;
  final bool isDark;
  final Color accent;

  const CreateInvoiceTotalsCard({
    super.key,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.taxRate,
    required this.discountRate,
    required this.currencySymbol,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2E) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _row('Subtotal',
              '$currencySymbol${subtotal.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row('Tax (${taxRate.toStringAsFixed(taxRate % 1 == 0 ? 0 : 1)}%)',
              '+$currencySymbol${taxAmount.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row(
              'Discount (${discountRate.toStringAsFixed(discountRate % 1 == 0 ? 0 : 1)}%)',
              '-$currencySymbol${discountAmount.toStringAsFixed(2)}',
              colorScheme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                color: accent.withValues(alpha: 0.3), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Flexible(
                child: Text(
                  '$currencySymbol${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
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
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
