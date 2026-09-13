// lib/screens/create_receipt_section/step_create_receipt/create_receipt_saved_items_filter_bar.dart
//
// PRICE RANGE FILTER PASS (this update): added
// CreateReceiptSavedItemsPriceRangeFilter — a compact "Min / Max" price
// pair of number fields sitting alongside the existing sort dropdown,
// mirroring create_invoice_saved_items_filter_bar.dart's/
// create_quote_saved_items_filter_bar.dart's identical addition.
// Filtering itself (comparing each entry's item.total against the
// parsed min/max) stays in create_receipt_saved_line_items_widgets.dart,
// since it needs the panel's own state — this file only owns the two
// controllers' rendering, same split already used for the sort enum/
// dropdown below.
//
// FIX: this file was previously truncated mid-file (cut off inside the
// sort dropdown's DropdownMenuItem list) and never actually defined
// CreateReceiptSavedItemsPriceRangeFilter, even though
// create_receipt_saved_line_items_widgets.dart already imports and
// renders that exact class — which would have been a compile error.
// This is the complete, correct file.
//
// NEW FILE (earlier) — CREATE-RECEIPT PARITY PASS: mirrors
// create_invoice_saved_items_filter_bar.dart /
// create_quote_saved_items_filter_bar.dart exactly. Holds
// ReceiptSavedLineItemSortOption (the sort choices for the Saved Items
// panel's library) and CreateReceiptSavedItemsSortDropdown, the compact
// dropdown rendered directly under the panel's search field.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ReceiptSavedLineItemSortOption {
  dateNewest,
  dateOldest,
  nameAZ,
  nameZA,
  priceLowHigh,
  priceHighLow,
}

extension ReceiptSavedLineItemSortOptionLabel on ReceiptSavedLineItemSortOption {
  String get label {
    switch (this) {
      case ReceiptSavedLineItemSortOption.dateNewest:
        return 'Newest first';
      case ReceiptSavedLineItemSortOption.dateOldest:
        return 'Oldest first';
      case ReceiptSavedLineItemSortOption.nameAZ:
        return 'Name (A–Z)';
      case ReceiptSavedLineItemSortOption.nameZA:
        return 'Name (Z–A)';
      case ReceiptSavedLineItemSortOption.priceLowHigh:
        return 'Price (low–high)';
      case ReceiptSavedLineItemSortOption.priceHighLow:
        return 'Price (high–low)';
    }
  }

  IconData get icon {
    switch (this) {
      case ReceiptSavedLineItemSortOption.dateNewest:
      case ReceiptSavedLineItemSortOption.dateOldest:
        return Icons.schedule_rounded;
      case ReceiptSavedLineItemSortOption.nameAZ:
      case ReceiptSavedLineItemSortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case ReceiptSavedLineItemSortOption.priceLowHigh:
      case ReceiptSavedLineItemSortOption.priceHighLow:
        return Icons.attach_money_rounded;
    }
  }
}

class CreateReceiptSavedItemsSortDropdown extends StatelessWidget {
  final ReceiptSavedLineItemSortOption value;
  final Color accent;
  final ValueChanged<ReceiptSavedLineItemSortOption> onChanged;

  const CreateReceiptSavedItemsSortDropdown({
    super.key,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReceiptSavedLineItemSortOption>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          selectedItemBuilder: (context) => ReceiptSavedLineItemSortOption.values
              .map((opt) => Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort_rounded, size: 15, color: accent),
                        const SizedBox(width: 6),
                        Text('Sort: ${opt.label}',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      ],
                    ),
                  ))
              .toList(),
          items: ReceiptSavedLineItemSortOption.values
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.icon, size: 15, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Text(opt.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (opt) {
            if (opt != null) onChanged(opt);
          },
        ),
      ),
    );
  }
}

// =============================================================================
// PRICE RANGE FILTER PASS: Min/Max price filter row. Mirrors
// CreateInvoiceSavedItemsPriceRangeFilter /
// CreateQuoteSavedItemsPriceRangeFilter exactly, adapted for Receipt's
// naming. Blank means "no bound" on that side. Purely presentational —
// minCtrl/maxCtrl are owned by the panel
// (CreateReceiptSavedLineItemsPanel), which also does the actual
// filtering against each entry's item.total.
// =============================================================================

class CreateReceiptSavedItemsPriceRangeFilter extends StatelessWidget {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final String currencyPrefix;
  final Color accent;

  const CreateReceiptSavedItemsPriceRangeFilter({
    super.key,
    required this.minCtrl,
    required this.maxCtrl,
    required this.currencyPrefix,
    required this.accent,
  });

  InputDecoration _decoration(BuildContext context, String hint) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.35)),
      prefixText: currencyPrefix.isNotEmpty ? currencyPrefix : null,
      prefixStyle: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.55)),
      isDense: true,
      filled: true,
      fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final numberFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
    ];

    return Row(
      children: [
        Icon(Icons.filter_alt_outlined, size: 15, color: colorScheme.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: minCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: numberFormatters,
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
            decoration: _decoration(context, 'Min price'),
          ),
        ),
        const SizedBox(width: 8),
        Text('–', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4))),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: maxCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: numberFormatters,
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
            decoration: _decoration(context, 'Max price'),
          ),
        ),
      ],
    );
  }
}
