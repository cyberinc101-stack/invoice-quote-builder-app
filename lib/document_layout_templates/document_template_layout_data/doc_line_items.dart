// doc_line_items.dart
// lib/document_layout_templates/document_template_layout_data/doc_line_items.dart
//
// NO-TRUNCATION / MAX-14PT PASS (this update): every Text() in this
// file that used `maxLines: 1, overflow: TextOverflow.ellipsis` — the
// column header labels (DESCRIPTION/QTY/UNIT/UNIT PRICE/DISCOUNT/
// TAX/TOTAL), the UNIT cell value, each rate cell's amount + name/rate
// sub-line, and the TOTAL cell — now use the shared autoFitText()
// helper from doc_header.dart instead. Ellipsis was hiding real content
// (e.g. a longer unit label like "Kilometer" or a rate name would get
// cut to "…"); autoFitText shrinks the whole line down to fit its
// column instead of cutting any of it off, and never renders above
// kMaxAutoFitFontSize (14pt).
//
// COLUMN-WIDTH REBALANCE PASS (earlier): every trailing column (QTY,
// UNIT, UNIT PRICE, DISCOUNT, TAX, TOTAL) previously shared the exact
// same `flex: 2`, regardless of what actually has to fit in it. QTY
// only ever holds a short number ("1", "79"); DISCOUNT/TAX/TOTAL have
// to fit a currency amount AND a rate-name/percentage sub-line
// ("-USD 15.00" / "TD (3%)") in the same column. Rebalanced so QTY
// gets the least width and the three money columns get the most; UNIT
// sits in between (needs to fit words like "Kilometer", not just
// digits).
//
// ENGINE FOLDER SPLIT PASS (earlier): split out of the former
// shared_doc_widgets.dart — see doc_header.dart's header comment for
// the full rationale. No behavior change from the split; every
// function here is byte-for-byte what shared_doc_widgets.dart had
// (aside from the truncation fix above).
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
        sharedLineItemColumnFlags, autoFitText;

// COLUMN-WIDTH REBALANCE PASS: named flex constants instead of magic
// numbers repeated across the header row and every item row — the two
// MUST stay identical or columns misalign between the header and the
// body, which is exactly the kind of drift a shared constant prevents.
const int _kFlexQty = 1;
const int _kFlexUnit = 2;
const int _kFlexUnitPrice = 3;
const int _kFlexDiscount = 3;
const int _kFlexTax = 3;
const int _kFlexTotal = 3;

Widget buildSharedLineItemsHeaderRow({required DocTemplateAdapter adapter}) {
  final ff = adapter.fontFamily;
  final accent = adapter.accent;
  final flags = sharedLineItemColumnFlags(adapter);
  final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: kGrey, letterSpacing: 1.0, fontFamily: ff);
  // NO-TRUNCATION PASS: header labels now render via autoFitText
  // instead of maxLines:1 + ellipsis — a narrow column (e.g. DISCOUNT
  // at a small "Text Size" setting on a tight page width) shrinks the
  // whole label instead of wrapping/cutting it ("DISCOUN"/"T").
  final trailingCols = <Widget>[
    Expanded(
      flex: _kFlexQty,
      child: autoFitText('QTY', hdr, textAlign: TextAlign.center),
    ),
    if (flags.showUnitCol)
      Expanded(
        flex: _kFlexUnit,
        child: autoFitText('UNIT', hdr, textAlign: TextAlign.center),
      ),
    Expanded(
      flex: _kFlexUnitPrice,
      child: autoFitText('UNIT PRICE', hdr, textAlign: TextAlign.right),
    ),
    if (flags.showDiscountCol)
      Expanded(
        flex: _kFlexDiscount,
        child: autoFitText('DISCOUNT', hdr, textAlign: TextAlign.right),
      ),
    if (flags.showTaxCol)
      Expanded(
        flex: _kFlexTax,
        child: autoFitText('TAX', hdr, textAlign: TextAlign.right),
      ),
    Expanded(
      flex: _kFlexTotal,
      child: autoFitText('TOTAL', hdr, textAlign: TextAlign.right),
    ),
  ];
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: accent, width: 1.5))),
    child: Row(children: [
      Expanded(flex: 5, child: autoFitText('DESCRIPTION', hdr)),
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

  // NO-TRUNCATION PASS: both lines of a rate cell (the amount, and the
  // name/percentage sub-line below it, e.g. "-USD 15.00" / "TD (3%)")
  // now render via autoFitText instead of maxLines:1 + ellipsis — a
  // long discount/tax name no longer gets cut to "…", it shrinks to
  // fit the column instead. A tighter minScale (0.45) is used here
  // specifically because this sub-line already renders quite small
  // (7.5px base) and these are the tightest columns on the page.
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
        autoFitText(
          '${negative ? '−' : ''}${adapter.fmtMoney(amount)}',
          TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff),
          textAlign: TextAlign.right,
          minScale: 0.45,
        ),
        autoFitText(
          trimmedName.isEmpty ? rateText : '$displayName ($rateText)',
          TextStyle(fontSize: 7.5, color: kInk, fontFamily: ff),
          textAlign: TextAlign.right,
          minScale: 0.45,
        ),
      ],
    );
  }

  final trailingCells = <Widget>[
    Expanded(
      flex: _kFlexQty,
      child: DocField(
        value: fmtQty(item.quantity), editable: editable, controller: ctrls?.qtyCtrl,
        onChanged: editable ? (_) => edit.onItemFieldChanged(index) : null,
        hint: '1', textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 10, color: kInk, fontFamily: ff),
      ),
    ),
    // NO-TRUNCATION PASS: unit label (e.g. "Kilometer") now shrinks to
    // fit via autoFitText instead of being cut with an ellipsis.
    if (flags.showUnitCol)
      Expanded(
        flex: _kFlexUnit,
        child: autoFitText(
          item.unit.isEmpty ? '' : unitDisplayLabel(item.unit, customUnitLabel: item.customUnitLabel),
          TextStyle(fontSize: 9.5, color: kInk, fontFamily: ff),
          textAlign: TextAlign.center,
          minScale: 0.5,
        ),
      ),
    Expanded(
      flex: _kFlexUnitPrice,
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
        flex: _kFlexDiscount,
        child: rateCell(enabled: item.discountEnabled, amount: itemDiscountAmt,
            rate: item.itemDiscountRate, negative: true, name: item.itemDiscountName),
      ),
    if (flags.showTaxCol)
      Expanded(
        flex: _kFlexTax,
        child: rateCell(enabled: item.taxEnabled, amount: itemTaxAmt,
            rate: item.itemTaxRate, negative: !item.itemTaxIsAddition, name: item.itemTaxName),
      ),
    // NO-TRUNCATION PASS: TOTAL cell now shrinks to fit instead of
    // ellipsizing a long formatted amount.
    Expanded(
      flex: _kFlexTotal,
      child: autoFitText(
        adapter.fmtMoney(netTotal),
        TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff),
        textAlign: TextAlign.right,
        minScale: 0.45,
      ),
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