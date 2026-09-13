// lib/screens/invoice_create_section/step_create_invoice/create_invoice_saved_items_filter_bar.dart
//
// PRICE RANGE FILTER PASS (this update): added
// CreateInvoiceSavedItemsPriceRangeFilter — a compact "Min / Max" price
// pair of number fields sitting alongside the existing sort dropdown.
// Filtering itself (comparing each entry's item.total against the
// parsed min/max) stays in create_invoice_saved_line_items_widgets.dart,
// since it needs the panel's own state — this file only owns the two
// controllers' rendering, same split already used for the sort enum/
// dropdown below.
//
// SAVED ITEMS SORT/FILTER PASS (earlier): split out of
// create_invoice_saved_line_items_widgets.dart to keep that file from
// growing further. Holds SavedLineItemSortOption (the sort choices for
// the Saved Items panel's library — name/price/date, each
// ascending/descending) and CreateInvoiceSavedItemsSortDropdown, the
// compact dropdown rendered directly under the panel's search field.
// Sorting itself (applying the chosen option to the entries list) stays
// in create_invoice_saved_line_items_widgets.dart, since it needs the
// panel's own state — this file only owns the enum + its UI.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sort choices for the Saved Items library list. Order here is the
/// order options appear in the dropdown.
enum SavedLineItemSortOption {
  dateNewest,
  dateOldest,
  nameAZ,
  nameZA,
  priceLowHigh,
  priceHighLow,
}

extension SavedLineItemSortOptionLabel on SavedLineItemSortOption {
  String get label {
    switch (this) {
      case SavedLineItemSortOption.dateNewest:
        return 'Newest first';
      case SavedLineItemSortOption.dateOldest:
        return 'Oldest first';
      case SavedLineItemSortOption.nameAZ:
        return 'Name (A–Z)';
      case SavedLineItemSortOption.nameZA:
        return 'Name (Z–A)';
      case SavedLineItemSortOption.priceLowHigh:
        return 'Price (low–high)';
      case SavedLineItemSortOption.priceHighLow:
        return 'Price (high–low)';
    }
  }

  IconData get icon {
    switch (this) {
      case SavedLineItemSortOption.dateNewest:
      case SavedLineItemSortOption.dateOldest:
        return Icons.schedule_rounded;
      case SavedLineItemSortOption.nameAZ:
      case SavedLineItemSortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case SavedLineItemSortOption.priceLowHigh:
      case SavedLineItemSortOption.priceHighLow:
        return Icons.attach_money_rounded;
    }
  }
}

/// Compact "Sort by" dropdown — same visual language (fill/border/radius)
/// as the search field it sits under in CreateInvoiceSavedLineItemsPanel.
class CreateInvoiceSavedItemsSortDropdown extends StatelessWidget {
  final SavedLineItemSortOption value;
  final Color accent;
  final ValueChanged<SavedLineItemSortOption> onChanged;

  const CreateInvoiceSavedItemsSortDropdown({
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
        child: DropdownButton<SavedLineItemSortOption>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          selectedItemBuilder: (context) => SavedLineItemSortOption.values
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
          items: SavedLineItemSortOption.values
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
// PRICE RANGE FILTER PASS: Min/Max price filter row.
//
// Two compact number fields side by side, labelled "Min" and "Max",
// each accepting a plain decimal amount (no currency symbol typed in —
// the panel already knows the invoice's currency prefix and shows it as
// a fixed leading label, same convention as every other amount field in
// this app, e.g. _AmountDueField in create_invoice_bottom_sheet.dart).
// Leaving a field blank means "no lower/upper bound" on that side.
// Purely presentational — minCtrl/maxCtrl are owned by the panel
// (CreateInvoiceSavedLineItemsPanel), which also does the actual
// filtering against each entry's item.total.
// =============================================================================

class CreateInvoiceSavedItemsPriceRangeFilter extends StatelessWidget {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final String currencyPrefix;
  final Color accent;

  const CreateInvoiceSavedItemsPriceRangeFilter({
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
