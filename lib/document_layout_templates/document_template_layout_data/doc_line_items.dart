// doc_line_items.dart
// lib/document_layout_templates/document_template_layout_data/doc_line_items.dart
//
// ENGINE FOLDER SPLIT PASS: split out of the former shared_doc_widgets.
// dart — see doc_header.dart's header comment for the full rationale.
// No behavior change from the split; every function here is
// byte-for-byte what shared_doc_widgets.dart had.
//
// This file holds the two line-item-table widgets:
//   - buildSharedLineItemsHeaderRow — the DESCRIPTION/QTY/UNIT/UNIT
//     PRICE/DISCOUNT/TAX/TOTAL column header row.
//   - buildSharedLineItemRow — one line item's row. Read-only unless
//     `edit` is supplied, in which case description/qty/price render
//     via DocField (tap-to-edit) and a remove-item (X) button appears.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show LineItem, unitDisplayLabel;
import 'doc_template_adapter.dart';
import 'doc_edit_bundle.dart';
import '../pagination/doc_field.dart';
import 'doc_header.dart'
    show kInk, kRule, kGrey, kColGap, withGaps, fmtQty, abbreviateRateName,
        sharedLineItemColumnFlags;

Widget buildSharedLineItemsHeaderRow({required DocTemplateAdapter adapter}) {
  final ff = adapter.fontFamily;
  final accent = adapter.accent;
  final flags = sharedLineItemColumnFlags(adapter);
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: kGrey, letterSpacing: 1.0, fontFamily: ff);
  final trailingCols = <Widget>[
    Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
    if (flags.showUnitCol)
      Expanded(flex: 2, child: Text('UNIT', textAlign: TextAlign.center, style: hdr)),
    Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: hdr)),
    if (flags.showDiscountCol)
      Expanded(flex: 2, child: Text('DISCOUNT', textAlign: TextAlign.right, style: hdr)),
    if (flags.showTaxCol)
      Expanded(flex: 2, child: Text('TAX', textAlign: TextAlign.right, style: hdr)),
    Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
  ];
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: accent, width: 1.5))),
    child: Row(children: [
      Expanded(flex: 5, child: Text('DESCRIPTION', style: hdr)),
      const SizedBox(width: kColGap),
      ...withGaps(trailingCols),
    ]),
  );
}

/// One line item's row. Read-only unless `edit` is supplied, in which
/// case description/qty/price render via DocField bound to
/// edit.itemCtrls[index], and a remove-item (X) button appears.
Widget buildSharedLineItemRow({
  required LineItem item,
  required DocTemplateAdapter adapter,
  required String ff,
  DocEditBundle? edit,
  int index = 0,
}) {
  final editable = edit != null;
  final ctrls = editable ? edit.itemCtrls[index] : null;

  final flags = sharedLineItemColumnFlags(adapter);
  final qty = editable ? (double.tryParse(ctrls!.qtyCtrl.text) ?? item.quantity) : item.quantity;
  final price = editable ? (double.tryParse(ctrls!.priceCtrl.text) ?? item.unitPrice) : item.unitPrice;
  final total = qty * price;

  final itemDiscountAmt = item.discountEnabled ? total * item.itemDiscountRate / 100 : 0.0;
  final itemTaxAmt      = item.taxEnabled      ? total * item.itemTaxRate      / 100 : 0.0;

  final signedTaxAmt = item.taxEnabled
      ? (item.itemTaxIsAddition ? itemTaxAmt : -itemTaxAmt)
      : 0.0;
  final netTotal = total - itemDiscountAmt + signedTaxAmt;

  Widget rateCell({
    required bool enabled,
    required double amount,
    required double rate,
    required bool negative,
    String name = '',
  }) {
    if (!enabled) return const SizedBox.shrink();
    final trimmedName = name.trim();
    final displayName = abbreviateRateName(trimmedName);
    final rateText = '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${negative ? '−' : ''}${adapter.fmtMoney(amount)}',
            textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
        Text(trimmedName.isEmpty ? rateText : '$displayName ($rateText)',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 7.5, color: kInk, fontFamily: ff)),
      ],
    );
  }

  final trailingCells = <Widget>[
    Expanded(
      flex: 2,
      child: DocField(
        value: fmtQty(item.quantity), editable: editable, controller: ctrls?.qtyCtrl,
        onChanged: editable ? (_) => edit.onItemFieldChanged(index) : null,
        hint: '1', textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 10, color: kInk, fontFamily: ff),
      ),
    ),
    if (flags.showUnitCol)
      Expanded(
        flex: 2,
        child: Text(
          item.unit.isEmpty ? '' : unitDisplayLabel(item.unit, customUnitLabel: item.customUnitLabel),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9.5, color: kInk, fontFamily: ff),
        ),
      ),
    Expanded(
      flex: 2,
      child: DocField(
        value: adapter.fmtMoney(item.unitPrice), editable: editable, controller: ctrls?.priceCtrl,
        onChanged: editable ? (_) => edit.onItemFieldChanged(index) : null,
        hint: '0.00', textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 10, color: kInk, fontFamily: ff),
      ),
    ),
    if (flags.showDiscountCol)
      Expanded(
        flex: 2,
        child: rateCell(enabled: item.discountEnabled, amount: itemDiscountAmt,
            rate: item.itemDiscountRate, negative: true, name: item.itemDiscountName),
      ),
    if (flags.showTaxCol)
      Expanded(
        flex: 2,
        child: rateCell(enabled: item.taxEnabled, amount: itemTaxAmt,
            rate: item.itemTaxRate, negative: !item.itemTaxIsAddition, name: item.itemTaxName),
      ),
    Expanded(
      flex: 2,
      child: Text(adapter.fmtMoney(netTotal), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
    ),
  ];

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kRule, width: 0.75))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 5,
        child: DocField(
          value: item.description, editable: editable, controller: ctrls?.descCtrl,
          onChanged: editable ? (_) => edit.onItemFieldChanged(index) : null,
          hint: 'Item description',
          style: TextStyle(fontSize: 10, color: kInk, height: 1.4, fontFamily: ff),
        ),
      ),
      const SizedBox(width: kColGap),
      ...withGaps(trailingCells),
      if (editable) ...[
        const SizedBox(width: 6),
        SizedBox(
          width: 20,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
            onPressed: () => edit.onRemoveItem(index),
          ),
        ),
      ],
    ]),
  );
}
