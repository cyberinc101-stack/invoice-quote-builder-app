// lib/screens/invoice_create_section/step_create_invoice/create_invoice_item_widgets.dart
//
// WHOLE-INVOICE TAX/DISCOUNT TOGGLE PASS (this update): CreateInvoiceTotalsCard
// gained taxEnabled/discountEnabled (both default true) — when off, that
// row disappears from the totals card entirely instead of just showing
// $0.00, matching create_invoice_bottom_sheet.dart's matching switches
// hiding the Name/% fields above it.
//
// TAX/DISCOUNT NAMING PASS (earlier): CreateInvoiceTotalsCard now
// accepts taxName/discountName (both default '') — the whole-invoice
// custom label typed on the Create Invoice sheet, mirroring
// InvoiceData.taxName/discountName. The Tax/Discount rows now render
// "GST (10%)" / "Trade (5%)" when a name is set, falling back to the
// plain "Tax (10%)"/"Discount (5%)" every existing invoice already
// shows when left blank.
//
// TAX NAME DROPDOWN PASS (earlier): both CreateInvoiceRateNameField
// calls below now pass `kind:` (tax / discount) so each reads the
// correct preset list (kTaxNamePresets / kDiscountNamePresets in
// create_invoice_form_widgets.dart) instead of defaulting to the tax
// list for both. No other change here — the field's controller/hint/
// onChanged wiring is unchanged from the previous pass.
//
// TAX NAME PASS (earlier): CreateInvoiceItemCard's Tax/Discount
// switches each gained a CreateInvoiceRateNameField ("VAT, GST…" /
// "Trade Discount, Early Payment…") right below the switch, writing to
// item.itemTaxName/itemDiscountName. CreateInvoiceTotalsCard's old
// single itemTaxExtra/itemDiscountExtra doubles are replaced with
// itemTaxByName/itemDiscountByName maps (grouped by name — see
// create_invoice_bottom_sheet.dart's matching getters) so genuinely
// different tax/discount names on the same invoice each get their own
// totals row instead of being silently combined into one figure; a
// single shared name (or no name) still renders as one row exactly as
// before.
//
// TAX SIGN PASS (earlier): the "Tax for this item" row gained
// CreateInvoiceTaxSignToggle (create_invoice_form_widgets.dart) right
// before the % input, only while the switch is on — a compact +/−
// control choosing whether this item's tax adds to the total (sales
// tax, the default) or subtracts from it (withholding tax). Writes
// straight onto item.itemTaxIsAddition, same mutate-in-place pattern as
// every other field on this card. CreateInvoiceTotalsCard's "Item-level
// tax" row also updated to handle itemTaxExtra now being a signed value
// (see invoice_data.dart's TAX SIGN PASS) — gates on `!= 0` instead of
// `> 0`, and its +/− prefix now reflects the actual sign instead of
// always showing "+".
//
// PER-ITEM TAX/DISCOUNT ON DRAFT CARD PASS (earlier): "Tax for this
// item" / "Discount for this item" — the two switches the SINGLE-DRAFT
// ITEM PASS originally removed from this card, reasoning it added
// too much complexity to a quick single-item entry form — are back,
// sitting right after Qty/Price/Total and before Save Item. Same shape
// as the Saved Item edit sheet's own switches (create_invoice_saved_
// line_items_widgets.dart's _EditSavedLineItemSheet): a Switch that
// reveals an inline %-input TextFormField only while it's on, writing
// straight onto item.taxEnabled/itemTaxRate/discountEnabled/
// itemDiscountRate. Needed two new controllers on this card
// (taxRateCtrl/discountRateCtrl) for the % inputs — the switches
// themselves need no controller, same as the Unit dropdown's own value.
//
// UNIT OF MEASURE PASS (earlier): CreateInvoiceItemCard gained a Unit
// dropdown (CreateInvoiceUnitDropdown, create_invoice_form_widgets.
// dart) sitting between Description and the Qty/Price/Total row. Picking
// 'custom' reveals a free-text field for customUnitLabel right below the
// dropdown. The Price field's label now dynamically shows a "per X"
// suffix (e.g. "Price (per hour)") whenever the selected unit has one —
// see invoice_data.dart's unitPriceSuffix() for exactly which units
// qualify — falling back to the plain "Price ($currencySymbol)" label
// used before this pass for units with no natural "per X" reading
// (blank/fixed price/expense/percentage). Both the dropdown's value and
// the custom-label text are read/written straight onto `item.unit`/
// `item.customUnitLabel` the same way description/qty/price already
// mutate `item` directly and call onChanged() — no new parent-side state
// needed for the dropdown itself, only a new controller for the
// free-text custom-label field (unitCustomLabelCtrl), owned by the
// parent bottom sheet the same way descCtrl/qtyCtrl/priceCtrl already
// are.
//
// SINGLE-DRAFT ITEM PASS (earlier): CreateInvoiceItemCard is no
// longer one of several stacked editable cards representing every item
// on the invoice — under "New", there's now exactly ONE of these on
// screen at a time (the item currently being typed, not yet added to
// the invoice), instead of a growing wall of containers every time "Add
// Item" was tapped. Once its Save Item button is tapped, the parent
// bottom sheet commits it (adds to the invoice + saves it into the
// single-item library in one action — see
// create_invoice_bottom_sheet.dart's _saveDraftItem) and this card
// resets to blank for the next one.
//   - Header simplified to a plain "New Item" label — no index number
//     (there's nothing to number now), no remove/X button (nothing to
//     remove before it's even been added), no small icon-only bookmark.
//   - Per-item tax/discount toggle row (taxEnabled/itemTaxRate/
//     discountEnabled/itemDiscountRate) was REMOVED from this card at
//     the time of this pass — it added a layer of complexity to a
//     screen meant to be a quick single-item entry form. Those fields
//     still exist on the LineItem model and remained fully editable
//     from the Saved tab's edit sheet
//     (create_invoice_saved_line_items_widgets.dart) for anyone who
//     wanted a per-item rate on an already-saved item. THIS IS NO
//     LONGER CURRENT — see the PER-ITEM TAX/DISCOUNT ON DRAFT CARD PASS
//     note at the top of this file: both switches are back on this card
//     as of that later pass.
//   - onSaveItem is now REQUIRED (was optional) and rendered as a
//     proper full-width filled button below Qty/Price/Total, labeled
//     "Save Item" with a bookmark icon — not a small icon-only tap
//     target buried in the header, so it visibly reads as the card's
//     primary action instead of a decoration.
//
// New widget: CreateInvoiceCommittedItemRow — a compact, read-only
// summary row (description + qty×price=total + a small remove X) for
// items already added to the invoice, shown above the single draft card
// under "New" so the user can still see and remove what's already on
// the invoice without every item reopening as a full editable form.
//
// CreateInvoiceTotalsCard is UNCHANGED in this pass — still accepts
// itemTaxExtra/itemDiscountExtra and renders their rows conditionally;
// the parent bottom sheet now only mounts it while the "Saved" tab is
// active (see that file's own header comment).
//
// ── Everything below unchanged from the previous pass — see original
// header comments preserved below. ──
//
// DESCRIPTION COUNTER: the Description field already had a real
// 200-character cap (LengthLimitingTextInputFormatter(200)) but no
// visible feedback — the decoration hid its native counter via
// counterText: ''. There's a visible "N / 200" counter underneath,
// matching the counter style used elsewhere in this step.
//
// OVERFLOW SAFETY: CreateInvoiceTotalsCard's row() helper and the
// separate Total row both wrap label and value in Flexible with
// maxLines: 1 + ellipsis, mirroring the identical fix already applied to
// shared_doc_widgets.dart's buildSharedTotalsAndNotesSection and
// pdf_templates.dart's _sharedTotalsAndNotes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/invoice_models.dart';
import 'create_invoice_form_widgets.dart'
    show
        CreateInvoiceUnitDropdown,
        CreateInvoiceTaxSignToggle,
        CreateInvoiceRateNameField,
        CreateInvoiceRateNameKind;

// =============================================================================
// Draft item card — the single "type a new item" editor
// =============================================================================

class CreateInvoiceItemCard extends StatelessWidget {
  final InvoiceItem item;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  // UNIT OF MEASURE PASS: free-text label used only while
  // item.unit == 'custom'. The dropdown's own value lives directly on
  // item.unit (mutated in place, same as description/qty/price below),
  // so no separate controller is needed for that half of the picker.
  final TextEditingController unitCustomLabelCtrl;

  // PER-ITEM TAX/DISCOUNT ON DRAFT CARD PASS: brings back the two
  // switches the SINGLE-DRAFT ITEM PASS originally removed from this
  // card (they remained available only from the Saved Item edit sheet).
  // Same shape as that sheet's own _taxCtrl/_discountCtrl — a text
  // controller for the % input, shown only while the matching *Enabled
  // switch is on. item.taxEnabled/itemTaxRate/discountEnabled/
  // itemDiscountRate are mutated in place, same pattern as unit/
  // description/qty/price above.
  final TextEditingController taxRateCtrl;
  final TextEditingController discountRateCtrl;

  // TAX NAME PASS: free-text "VAT, GST…" / "Trade Discount…" labels,
  // shown right below each switch while it's on, writing to
  // item.itemTaxName/itemDiscountName.
  final TextEditingController taxNameCtrl;
  final TextEditingController discountNameCtrl;

  final String currencySymbol;
  final Color accent;
  final VoidCallback onChanged;

  /// Commits this draft — the parent adds it to the invoice's line items
  /// AND saves it into the single-item library, then resets this card
  /// back to blank for the next item. Always present (this card has no
  /// reason to exist without it).
  final VoidCallback onSaveItem;

  const CreateInvoiceItemCard({
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

    // UNIT OF MEASURE PASS: "Price (per hour)" etc. when the selected
    // unit has a natural "per X" reading, else the plain
    // "Price ($currencySymbol)" label used before this pass.
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

            // UNIT OF MEASURE PASS: Unit dropdown — sits between
            // Description and the Qty/Price/Total row. Mutates
            // item.unit directly, same pattern as every other field on
            // this card.
            CreateInvoiceUnitDropdown(
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
                          // LINE NET TOTAL PASS: reflects this item's own
                          // tax/discount (item.lineNetTotal) instead of
                          // the plain pre-tax/discount qty × price base
                          // figure (item.total).
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

            // ── Tax for this item / Discount for this item — same two
            // switches the Saved Item edit sheet already has, brought
            // back onto this draft card too. Mutates item.taxEnabled/
            // itemTaxRate/discountEnabled/itemDiscountRate directly,
            // same pattern as every other field on this card. ─────────
            //
            // TAX NAME PASS: each switch's expanded content is now a
            // small Column — the "VAT, GST…"/"Trade Discount…" name
            // field on its own line, then the sign toggle (tax only) +
            // % input on the line below — instead of everything
            // crammed into one Row, since there's now a third control
            // to fit alongside the switch.
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
                        CreateInvoiceRateNameField(
                          controller: taxNameCtrl,
                          hint: 'VAT, GST…',
                          accent: accent,
                          kind: CreateInvoiceRateNameKind.tax,
                          onChanged: (v) {
                            item.itemTaxName = v;
                            onChanged();
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CreateInvoiceTaxSignToggle(
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
                  CreateInvoiceRateNameField(
                    controller: discountNameCtrl,
                    hint: 'Trade Discount, Early Payment…',
                    accent: accent,
                    kind: CreateInvoiceRateNameKind.discount,
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

            // ── Save Item — the card's primary action, now a real
            // full-width filled button instead of a small header icon,
            // so it unambiguously reads as tappable. ──────────────────
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
// added to the invoice (either just saved from the draft card above, or
// included via the Saved tab). Not editable inline; tapping the X
// removes it from the invoice (the underlying saved-library entry, if
// any, is untouched — it stays browsable/re-addable from the Saved tab).
//
// UNIT OF MEASURE PASS: shows a small unit badge (e.g. "Hour") next to
// the qty × price line when the item has a unit set, so a glance at the
// committed list still shows what's being billed per-what.
// =============================================================================

class CreateInvoiceCommittedItemRow extends StatelessWidget {
  final InvoiceItem item;
  final String currencySymbol;
  final Color accent;
  final VoidCallback onRemove;
  final bool isFromSaved;

  const CreateInvoiceCommittedItemRow({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.accent,
    required this.onRemove,
    this.isFromSaved = false,
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
            // LINE NET TOTAL PASS: reflects this item's own tax/discount
            // instead of the plain pre-tax/discount base figure.
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
// Totals card
// =============================================================================

class CreateInvoiceTotalsCard extends StatelessWidget {
  final double subtotal, taxAmount, discountAmount, total;
  final double taxRate, discountRate;

  // TAX NAME PASS: replaces the old single itemTaxExtra/itemDiscountExtra
  // doubles with per-name maps (create_invoice_bottom_sheet.dart's
  // _itemTaxExtraByName/_itemDiscountExtraByName — same grouping logic
  // as InvoiceData.itemTaxExtraByName/itemDiscountExtraByName). When
  // every taxed/discounted item shares one name (or none has a name),
  // the map naturally has a single entry, so this renders exactly one
  // row like before this pass — genuinely different names each render
  // their own row instead of being silently summed together. Tax values
  // are signed (a withholding group is negative); discount values are
  // plain positive magnitudes, matching itemDiscountExtra's existing
  // convention.
  final Map<String, double> itemTaxByName;
  final Map<String, double> itemDiscountByName;

  // TAX/DISCOUNT NAMING PASS: whole-invoice custom label (e.g. "GST"),
  // mirrors InvoiceData.taxName/discountName. Falls back to the plain
  // "Tax"/"Discount" row label every existing invoice already shows.
  final String taxName;
  final String discountName;

  // WHOLE-INVOICE TAX/DISCOUNT TOGGLE PASS: gates the Tax/Discount rows
  // below entirely — default true so every existing call site (and
  // every invoice with nothing explicitly toggled off) renders exactly
  // as before this pass.
  final bool taxEnabled;
  final bool discountEnabled;

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
    this.itemTaxByName = const {},
    this.itemDiscountByName = const {},
    this.taxName = '',
    this.discountName = '',
    this.taxEnabled = true,
    this.discountEnabled = true,
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
                '-$currencySymbol${discountAmount.toStringAsFixed(2)}',
                colorScheme),
          ],
          // TAX NAME PASS: one row per distinct tax name (a plain "Item
          // Tax" row when a group's name is blank). Skips any group
          // that nets to exactly 0 (e.g. an item toggled on then
          // immediately off), same as the old `!= 0` gate.
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