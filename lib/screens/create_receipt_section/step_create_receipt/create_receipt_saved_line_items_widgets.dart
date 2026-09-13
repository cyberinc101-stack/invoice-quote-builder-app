// lib/screens/create_receipt_section/step_create_receipt/create_receipt_saved_line_items_widgets.dart
//
// COUNT BADGE PASS (this update): the "Saved Items" header badge now
// shows "X/200" (X/kMaxSavedReceiptLineItems) instead of just the bare
// count — matches the N/max convention used everywhere else in this
// app (Container/Template/Customer library headers all show a count
// against their cap), and matches Invoice's/Quote's identical COUNT
// BADGE PASS. The badge also now always renders (previously it was
// hidden entirely while the library was empty via
// `if (widget.library.isNotEmpty)`), so the cap is visible even at
// 0/200.
//
// PRICE RANGE FILTER PASS (earlier): CreateReceiptSavedLineItemsPanel
// gained a Min/Max price filter
// (CreateReceiptSavedItemsPriceRangeFilter,
// create_receipt_saved_items_filter_bar.dart) sitting directly under the
// sort dropdown, mirroring Invoice's identical addition. Two plain
// TextEditingControllers (_minPriceCtrl/_maxPriceCtrl) — blank means "no
// bound" on that side. An entry must match the search text AND fall
// within [min, max] (each side only applied when that field actually
// parses to a number) to be included. Sorting is applied after both
// filters. Same `library.length > 4` gate as the search field/sort
// dropdown, and it collapses along with everything else when the
// panel's header is tapped shut. kMaxSavedReceiptLineItems remains 200
// (matching Quote's/Invoice's own saved-line-item cap) — unchanged by
// this pass.
//
// PER-ITEM TAX/DISCOUNT PASS (earlier): the edit sheet has the same
// per-item Tax/Discount toggle+sign+name block Quote's equivalent edit
// sheet has — Receipt's LineItem is the same shared class from
// invoice_data.dart, so this is a straight parity port. The saved-item
// card also shows Tax/Discount mini-badges when set.
//
// NEW FILE (earlier) — CREATE-RECEIPT UI PARITY PASS: mirrors
// create_quote_section/step_create_quote/create_quote_saved_line_items_widgets.dart
// exactly, adapted to SavedReceiptLineItem (receipt_data.dart) instead
// of SavedQuoteLineItem. Own SharedPreferences key
// ('receipt_saved_single_line_items') so a line item saved while
// building a receipt never mixes with Invoice's or Quote's own
// single-item libraries.
//
// Each card carries a radio-style checkbox reflecting whether THIS
// receipt currently includes an item sourced from that saved container
// (tracked via LineItem.sourceSavedId — see
// create_receipt_bottom_sheet.dart's _toggleSavedLineItem).

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/receipt_data.dart' show SavedReceiptLineItem;
import '../../../models/invoice_data.dart' show unitDisplayLabel;
import 'create_receipt_form_widgets.dart'
    show
        CreateReceiptUnitDropdown,
        CreateReceiptTaxSignToggle,
        CreateReceiptRateNameField,
        CreateReceiptRateNameKind;
import 'create_receipt_saved_items_filter_bar.dart'
    show
        ReceiptSavedLineItemSortOption,
        CreateReceiptSavedItemsSortDropdown,
        CreateReceiptSavedItemsPriceRangeFilter;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
// Kept at 200 — matches Quote's/Invoice's own saved-line-item cap.
const int kMaxSavedReceiptLineItems = 200;
const _kPrefSavedReceiptLineItemList = 'receipt_saved_single_line_items';

// ---------------------------------------------------------------------------
// Persistence helpers — shared by this panel and the parent bottom
// sheet's Save Item action.
// ---------------------------------------------------------------------------
Future<void> persistSavedReceiptLineItems(List<SavedReceiptLineItem> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefSavedReceiptLineItemList,
    jsonEncode(list.map((s) => s.toJson()).toList()),
  );
}

Future<List<SavedReceiptLineItem>> loadSavedReceiptLineItems() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefSavedReceiptLineItemList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => SavedReceiptLineItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// CreateReceiptSavedLineItemsPanel
// =============================================================================

class CreateReceiptSavedLineItemsPanel extends StatefulWidget {
  final List<SavedReceiptLineItem> library;
  final Set<String> includedIds;
  final String currencySymbol;
  final Color accent;
  final ValueChanged<SavedReceiptLineItem> onToggleInclude;
  final void Function(int index, SavedReceiptLineItem updated) onEdit;
  final void Function(int index) onDelete;

  const CreateReceiptSavedLineItemsPanel({
    super.key,
    required this.library,
    required this.includedIds,
    required this.currencySymbol,
    required this.accent,
    required this.onToggleInclude,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CreateReceiptSavedLineItemsPanel> createState() =>
      _CreateReceiptSavedLineItemsPanelState();
}

class _CreateReceiptSavedLineItemsPanelState
    extends State<CreateReceiptSavedLineItemsPanel> {
  String _query = '';
  bool _collapsed = false;
  ReceiptSavedLineItemSortOption _sort = ReceiptSavedLineItemSortOption.dateNewest;

  // PRICE RANGE FILTER PASS: blank means "no bound" on that side.
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _minPriceCtrl.addListener(() => setState(() {}));
    _maxPriceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _openEditSheet(int index) {
    final existing = widget.library[index];
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditSavedReceiptLineItemSheet(
        existing: existing,
        currencySymbol: widget.currencySymbol,
        accent: widget.accent,
        onSaved: (updated) => widget.onEdit(index, updated),
      ),
    );
  }

  void _applySort(List<MapEntry<int, SavedReceiptLineItem>> entries) {
    switch (_sort) {
      case ReceiptSavedLineItemSortOption.dateNewest:
        entries.sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
        break;
      case ReceiptSavedLineItemSortOption.dateOldest:
        entries.sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
        break;
      case ReceiptSavedLineItemSortOption.nameAZ:
        entries.sort((a, b) =>
            a.value.displayName.toLowerCase().compareTo(b.value.displayName.toLowerCase()));
        break;
      case ReceiptSavedLineItemSortOption.nameZA:
        entries.sort((a, b) =>
            b.value.displayName.toLowerCase().compareTo(a.value.displayName.toLowerCase()));
        break;
      case ReceiptSavedLineItemSortOption.priceLowHigh:
        entries.sort((a, b) => a.value.item.total.compareTo(b.value.item.total));
        break;
      case ReceiptSavedLineItemSortOption.priceHighLow:
        entries.sort((a, b) => b.value.item.total.compareTo(a.value.item.total));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final trimmed = _query.trim().toLowerCase();
    // PRICE RANGE FILTER PASS: blank/unparseable bounds are treated as
    // "no limit" on that side.
    final minPrice = double.tryParse(_minPriceCtrl.text.trim());
    final maxPrice = double.tryParse(_maxPriceCtrl.text.trim());

    final entries = <MapEntry<int, SavedReceiptLineItem>>[];
    for (int i = 0; i < widget.library.length; i++) {
      final item = widget.library[i];
      final matchesSearch = trimmed.isEmpty ||
          item.displayName.toLowerCase().contains(trimmed) ||
          item.item.description.toLowerCase().contains(trimmed);
      if (!matchesSearch) continue;

      final price = item.item.total;
      if (minPrice != null && price < minPrice) continue;
      if (maxPrice != null && price > maxPrice) continue;

      entries.add(MapEntry(i, item));
    }
    _applySort(entries);

    final hasActivePriceFilter =
        _minPriceCtrl.text.trim().isNotEmpty || _maxPriceCtrl.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _collapsed = !_collapsed),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: widget.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.bookmark_rounded, size: 16, color: widget.accent),
                const SizedBox(width: 6),
                Text(
                  'Saved Items',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.library.length}/$kMaxSavedReceiptLineItems',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.library.length >= kMaxSavedReceiptLineItems
                          ? const Color(0xFFEF5350)
                          : widget.accent,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _collapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.expand_more_rounded,
                      size: 22, color: colorScheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
        ),
        if (!_collapsed) ...[
          const SizedBox(height: 12),
          if (widget.library.length > 4) ...[
            TextFormField(
              initialValue: _query,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search saved items',
                hintStyle: TextStyle(
                    fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.35)),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF9F9F9),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 8),
            CreateReceiptSavedItemsSortDropdown(
              value: _sort,
              accent: widget.accent,
              onChanged: (opt) => setState(() => _sort = opt),
            ),
            const SizedBox(height: 8),
            CreateReceiptSavedItemsPriceRangeFilter(
              minCtrl: _minPriceCtrl,
              maxCtrl: _maxPriceCtrl,
              currencyPrefix: widget.currencySymbol,
              accent: widget.accent,
            ),
            const SizedBox(height: 12),
          ],
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  widget.library.isEmpty
                      ? 'No saved items yet. Save one from the item card above.'
                      : (hasActivePriceFilter && trimmed.isEmpty
                          ? 'No saved items in that price range.'
                          : 'No saved items match "$_query".'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            )
          else
            ...entries.map((e) {
              final index = e.key;
              final saved = e.value;
              final isIncluded = widget.includedIds.contains(saved.id);
              return _SavedReceiptLineItemCard(
                saved: saved,
                isIncluded: isIncluded,
                currencySymbol: widget.currencySymbol,
                accent: widget.accent,
                onToggle: () => widget.onToggleInclude(saved),
                onEdit: () => _openEditSheet(index),
                onDelete: () => widget.onDelete(index),
              );
            }),
        ],
      ],
    );
  }
}

// =============================================================================
// Saved Line Item Card
// =============================================================================

class _SavedReceiptLineItemCard extends StatelessWidget {
  final SavedReceiptLineItem saved;
  final bool isIncluded;
  final String currencySymbol;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SavedReceiptLineItemCard({
    required this.saved,
    required this.isIncluded,
    required this.currencySymbol,
    required this.accent,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = saved.item;
    final unitLabel = item.unit.isEmpty
        ? null
        : unitDisplayLabel(item.unit, customUnitLabel: item.customUnitLabel);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isIncluded
            ? (isDark ? const Color(0xFF0D2A0F) : Colors.white)
            : (isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isIncluded
              ? accent.withValues(alpha: isDark ? 0.6 : 0.5)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isIncluded ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isIncluded ? accent : Colors.transparent,
                  border: Border.all(
                    color: isIncluded
                        ? accent
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isIncluded
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saved.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} × $currencySymbol${item.unitPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unitLabel != null) ...[
                          const SizedBox(width: 6),
                          _miniBadge(unitLabel, accent),
                        ],
                        if (item.taxEnabled) ...[
                          const SizedBox(width: 6),
                          _miniBadge(
                            '${item.itemTaxIsAddition ? '' : '-'}${item.itemTaxName.trim().isNotEmpty ? '${item.itemTaxName.trim()} ' : 'Tax '}${item.itemTaxRate.toStringAsFixed(item.itemTaxRate % 1 == 0 ? 0 : 1)}%',
                            item.itemTaxIsAddition ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
                          ),
                        ],
                        if (item.discountEnabled) ...[
                          const SizedBox(width: 6),
                          _miniBadge(
                            '-${item.itemDiscountName.trim().isNotEmpty ? '${item.itemDiscountName.trim()} ' : ''}${item.itemDiscountRate.toStringAsFixed(item.itemDiscountRate % 1 == 0 ? 0 : 1)}%',
                            const Color(0xFFFF9800),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $currencySymbol${item.lineNetTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? accent.withValues(alpha: 0.12)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_rounded, color: accent, size: 14),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Color(0xFFEF5350), size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
        ),
      );
}

// =============================================================================
// Edit sheet — rename + adjust description/qty/price/unit/tax/discount
// for an existing saved line item.
// =============================================================================

class _EditSavedReceiptLineItemSheet extends StatefulWidget {
  final SavedReceiptLineItem existing;
  final String currencySymbol;
  final Color accent;
  final ValueChanged<SavedReceiptLineItem> onSaved;

  const _EditSavedReceiptLineItemSheet({
    required this.existing,
    required this.currencySymbol,
    required this.accent,
    required this.onSaved,
  });

  @override
  State<_EditSavedReceiptLineItemSheet> createState() => _EditSavedReceiptLineItemSheetState();
}

class _EditSavedReceiptLineItemSheetState extends State<_EditSavedReceiptLineItemSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late String _unit;
  late TextEditingController _customUnitLabelCtrl;

  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  late bool _taxEnabled;
  late bool _discountEnabled;
  late TextEditingController _taxNameCtrl;
  late TextEditingController _discountNameCtrl;
  late bool _taxIsAddition;

  @override
  void initState() {
    super.initState();
    final item = widget.existing.item;
    _nameCtrl = TextEditingController(text: widget.existing.name ?? '');
    _descCtrl = TextEditingController(text: item.description);
    _qtyCtrl = TextEditingController(
        text: item.quantity == 1.0 ? '1' : '${item.quantity}');
    _priceCtrl = TextEditingController(
        text: item.unitPrice == 0.0 ? '0' : '${item.unitPrice}');
    _unit = item.unit;
    _customUnitLabelCtrl = TextEditingController(text: item.customUnitLabel);
    _taxCtrl = TextEditingController(
        text: item.itemTaxRate == 0.0 ? '0' : '${item.itemTaxRate}');
    _discountCtrl = TextEditingController(
        text: item.itemDiscountRate == 0.0 ? '0' : '${item.itemDiscountRate}');
    _taxNameCtrl = TextEditingController(text: item.itemTaxName);
    _discountNameCtrl = TextEditingController(text: item.itemDiscountName);
    _taxEnabled = item.taxEnabled;
    _discountEnabled = item.discountEnabled;
    _taxIsAddition = item.itemTaxIsAddition;
    for (final c in [
      _nameCtrl, _descCtrl, _qtyCtrl, _priceCtrl, _customUnitLabelCtrl,
      _taxCtrl, _discountCtrl, _taxNameCtrl, _discountNameCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _descCtrl, _qtyCtrl, _priceCtrl, _customUnitLabelCtrl,
      _taxCtrl, _discountCtrl, _taxNameCtrl, _discountNameCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final updatedItem = widget.existing.item.copyWith(
      description: _descCtrl.text.trim(),
      quantity: double.tryParse(_qtyCtrl.text) ?? 1,
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
      unit: _unit,
      customUnitLabel: _unit == 'custom' ? _customUnitLabelCtrl.text.trim() : '',
      taxEnabled: _taxEnabled,
      itemTaxRate: (double.tryParse(_taxCtrl.text) ?? 0.0).clamp(0.0, 100.0),
      itemTaxIsAddition: _taxIsAddition,
      itemTaxName: _taxNameCtrl.text.trim(),
      discountEnabled: _discountEnabled,
      itemDiscountRate: (double.tryParse(_discountCtrl.text) ?? 0.0).clamp(0.0, 100.0),
      itemDiscountName: _discountNameCtrl.text.trim(),
    );
    final updated = widget.existing.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      clearName: _nameCtrl.text.trim().isEmpty,
      item: updatedItem,
      lastEditedAt: DateTime.now(),
    );
    widget.onSaved(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = kb + 32 + MediaQuery.of(context).padding.bottom;

    InputDecoration deco(String label, {String? prefix}) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12.5),
          prefixText: prefix,
          filled: true,
          fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.accent, width: 1.5)),
        );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, sc) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Saved Item',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameCtrl,
                        style: TextStyle(color: colorScheme.onSurface),
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                        decoration: deco('Label (Optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        style: TextStyle(color: colorScheme.onSurface),
                        inputFormatters: [LengthLimitingTextInputFormatter(200)],
                        decoration: deco('Description'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: deco('Qty'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: deco('Price', prefix: widget.currencySymbol),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      CreateReceiptUnitDropdown(
                        value: _unit,
                        accent: widget.accent,
                        onChanged: (v) => setState(() {
                          _unit = v;
                          if (v != 'custom') _customUnitLabelCtrl.clear();
                        }),
                      ),
                      if (_unit == 'custom') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _customUnitLabelCtrl,
                          style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                          inputFormatters: [LengthLimitingTextInputFormatter(24)],
                          decoration: deco('Custom Unit Name').copyWith(
                            hintText: 'e.g. sqm, page, seat',
                            hintStyle: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 12),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Tax for this item',
                                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                              ),
                              Switch(
                                value: _taxEnabled,
                                onChanged: (v) => setState(() => _taxEnabled = v),
                                activeTrackColor: widget.accent,
                              ),
                            ],
                          ),
                          if (_taxEnabled) ...[
                            CreateReceiptRateNameField(
                              controller: _taxNameCtrl,
                              hint: 'VAT, GST…',
                              accent: widget.accent,
                              kind: CreateReceiptRateNameKind.tax,
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CreateReceiptTaxSignToggle(
                                  isAddition: _taxIsAddition,
                                  accent: widget.accent,
                                  onChanged: (v) => setState(() => _taxIsAddition = v),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 64,
                                  child: TextFormField(
                                    controller: _taxCtrl,
                                    textAlign: TextAlign.center,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
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
                                value: _discountEnabled,
                                onChanged: (v) => setState(() => _discountEnabled = v),
                                activeTrackColor: widget.accent,
                              ),
                            ],
                          ),
                          if (_discountEnabled) ...[
                            CreateReceiptRateNameField(
                              controller: _discountNameCtrl,
                              hint: 'Loyalty Discount, Bulk Discount…',
                              accent: widget.accent,
                              kind: CreateReceiptRateNameKind.discount,
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 64,
                              child: TextFormField(
                                controller: _discountCtrl,
                                textAlign: TextAlign.center,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
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

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
