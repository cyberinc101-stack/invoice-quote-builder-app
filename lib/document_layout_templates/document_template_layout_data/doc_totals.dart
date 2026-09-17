// doc_totals.dart
// lib/document_layout_templates/document_template_layout_data/doc_totals.dart
//
// NO-TRUNCATION / MAX-14PT PASS (this update): the totals row() helper
// (Subtotal/Discount/Tax/Grand Total labels + amounts) and
// buildSharedThankYouFooter both used `maxLines: 1, overflow:
// TextOverflow.ellipsis` — a long discount/tax name (user-typed, e.g.
// "Early Payment Discount (3%)") or a long thank-you line
// ("Thank you for your business — someone@areallylongdomainname.com")
// could get cut with "…". Both now use the shared autoFitText() helper
// from doc_header.dart, which shrinks the whole line to fit instead of
// hiding part of it, and never exceeds kMaxAutoFitFontSize (14pt).
// buildSharedPaymentInfoPanel / buildSharedTermsPanel / notes already
// wrap (softWrap true, no maxLines) so multi-line panel text was never
// truncated — left unchanged.
//
// DIVIDER-MOVE PASS (earlier): buildSharedThankYouFooter no longer
// draws its own leading divider — that divider now lives in
// doc_footer.dart's buildSharedFooterTaglines instead, sitting directly
// ABOVE the taglines row (which now renders below this thank-you text
// in _defaultFooterContent — see template_document.dart). Visual order
// is now: thank-you text, divider, taglines row.
//
// ENGINE FOLDER SPLIT PASS: split out of the former shared_doc_widgets.
// dart — see doc_header.dart's header comment for the full rationale.
//
// This file holds everything that renders below the line-item table:
//   - buildSharedPaymentInfoPanel — Bank/Account Name/Account Number/
//     Other Payment Details panel.
//   - buildSharedTermsPanel — Terms & Conditions panel.
//   - buildSharedSignatureBlock — typed/image/blank signature, with
//     auto-measured signing-line width for typed names.
//   - buildSharedDueDateAmountBar — the Due Date/Amount Due bar under
//     Grand Total (invoice-only; no-op for quote/receipt since their
//     adapter values are always null — see doc_template_adapter.dart).
//   - buildSharedTotalsAndNotesSection — Subtotal/Discount/Tax/Total,
//     Notes, and the four panels above, assembled together. Takes
//     optional `edit` — when non-null, the whole-document Discount/Tax
//     rate rows render as an editable "(  X  )%" pill.
//   - buildSharedThankYouFooter — the thin "Thank you..." strip pinned
//     to the bottom of the last page.

import 'dart:io';
import 'package:flutter/material.dart';
import 'doc_template_adapter.dart';
import 'doc_edit_bundle.dart';
import '../pagination/doc_field.dart';
import 'doc_header.dart' show kInk, kGrey, kGreyLight, kPanelBg, kRule, autoFitText;

Widget _panelLabel(String text, String ff) => Text(text,
    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
        color: kGrey, letterSpacing: 1.2, fontFamily: ff));

Widget buildSharedPaymentInfoPanel(DocTemplateAdapter a) {
  final ff = a.fontFamily;

  final rows = <Widget>[
    if (docFieldOn(a, 'bankName') && a.bankName.trim().isNotEmpty)
      _paymentRow('Bank', a.bankName, ff),
    if (docFieldOn(a, 'accountName') && a.accountName.trim().isNotEmpty)
      _paymentRow('Account Name', a.accountName, ff),
    if (docFieldOn(a, 'accountNumber') && a.accountNumber.trim().isNotEmpty)
      _paymentRow('Account Number', a.accountNumber, ff),
    if (docFieldOn(a, 'otherPaymentDetails') && a.otherPaymentDetails.trim().isNotEmpty)
      _paymentRow('Other', a.otherPaymentDetails, ff),
  ];

  if (rows.isEmpty) return const SizedBox.shrink();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kPanelBg, borderRadius: BorderRadius.circular(6)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _panelLabel('PAYMENT DETAILS', ff),
        const SizedBox(height: 8),
        ...rows,
      ],
    ),
  );
}

// Already wraps (softWrap: true, no maxLines) — never truncated, left
// unchanged by the NO-TRUNCATION PASS.
Widget _paymentRow(String label, String value, String ff) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: TextStyle(fontSize: 8.5, color: kGrey, fontFamily: ff)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff, height: 1.35),
          softWrap: true),
    ],
  ),
);

Widget buildSharedTermsPanel(DocTemplateAdapter a) {
  if (!docFieldOn(a, 'termsAndConditions')) return const SizedBox.shrink();
  final text = a.termsAndConditions.trim();
  if (text.isEmpty) return const SizedBox.shrink();

  final ff = a.fontFamily;
  return Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPanelBg, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _panelLabel('TERMS & CONDITIONS', ff),
          const SizedBox(height: 6),
          Text(text,
              style: TextStyle(fontSize: 9, color: kInk, height: 1.5, fontFamily: ff),
              softWrap: true, overflow: TextOverflow.visible),
        ],
      ),
    ),
  );
}

// Measures the rendered signature name's actual width so the signing
// line matches it (clamped [70, 220]) instead of always being a fixed
// 160px.
double _measureTextWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}

/// Signature block. Modes: 'typed', 'image', 'blank', '' (none). 'typed'
/// resolves a chosen script family via a plain TextStyle(fontFamily:)
/// against the locally-bundled asset (see pubspec.yaml) — no runtime
/// font fetch. Already used FittedBox(scaleDown) for the typed name
/// before this pass, so it was never subject to the ellipsis-truncation
/// bug this pass fixes elsewhere — left unchanged.
Widget buildSharedSignatureBlock(DocTemplateAdapter a) {
  if (!docFieldOn(a, 'signature')) return const SizedBox.shrink();
  if (a.signatureMode.trim().isEmpty) return const SizedBox.shrink();

  final ff = a.fontFamily;
  final mode = a.signatureMode;

  Widget line({double width = 160}) =>
      Container(width: width, height: 1, color: kInk.withValues(alpha: 0.4));

  Widget content;
  switch (mode) {
    case 'typed':
      final name = a.signatureName.trim();
      final family = a.signatureFontFamily.trim();
      final style = family.isEmpty
          ? TextStyle(
              fontSize: a.signatureFontSize,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: kInk,
              fontFamily: ff,
            )
          : TextStyle(fontSize: a.signatureFontSize, color: kInk, fontFamily: family);
      final boxHeight = (a.signatureFontSize * 1.35).clamp(24.0, 56.0);
      final lineWidth = name.isEmpty ? 70.0 : _measureTextWidth(name, style).clamp(70.0, 220.0);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: boxHeight,
            width: lineWidth,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(name.isEmpty ? ' ' : name, maxLines: 1, softWrap: false, style: style),
              ),
            ),
          ),
          const SizedBox(height: 2),
          line(width: lineWidth),
        ],
      );
      break;
    case 'image':
      final path = a.signatureImagePath;
      final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 44,
            child: hasImage
                ? Image.file(File(path), fit: BoxFit.contain, alignment: Alignment.bottomLeft)
                : null,
          ),
          const SizedBox(height: 4),
          line(),
        ],
      );
      break;
    case 'blank':
    default:
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [const SizedBox(height: 44), line()],
      );
  }

  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          const SizedBox(height: 4),
          Text('Authorized Signature', style: TextStyle(fontSize: 8, color: kGreyLight, fontFamily: ff)),
        ],
      ),
    ),
  );
}

/// Due Date/Amount Due bar, rendered under Grand Total. Renders nothing
/// when either value is null (quote/receipt — see
/// doc_template_adapter.dart) or its toggle is off. Neither label had
/// maxLines/ellipsis before this pass — left unchanged.
Widget buildSharedDueDateAmountBar(DocTemplateAdapter a) {
  final showDueDateSummary = docFieldOn(a, 'dueDateSummary') && a.dueDateSummaryValue != null;
  final showAmountDueSummary = docFieldOn(a, 'amountDue') && a.amountDueValue != null;
  if (!showDueDateSummary && !showAmountDueSummary) return const SizedBox.shrink();

  final ff = a.fontFamily;
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: kPanelBg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisAlignment: (showDueDateSummary && showAmountDueSummary)
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        children: [
          if (showDueDateSummary)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DUE DATE', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700,
                    color: kGrey, letterSpacing: 1.0, fontFamily: ff)),
                const SizedBox(height: 3),
                autoFitText(
                  a.dueDateSummaryValue!.isEmpty ? '—' : a.dueDateSummaryValue!,
                  TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff),
                ),
              ],
            ),
          if (showAmountDueSummary)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AMOUNT DUE', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700,
                    color: kGrey, letterSpacing: 1.0, fontFamily: ff)),
                const SizedBox(height: 3),
                autoFitText(
                  a.fmtMoney(a.amountDueValue!),
                  TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: a.accent, fontFamily: ff),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

/// Subtotal/Discount/Tax/Total, Notes, and the panels above, assembled
/// together. `edit` non-null makes the whole-document Discount/Tax rate
/// rows render as an editable "(  X  )%" pill; uses
/// adapter.taxNameActual/discountNameActual for the row label instead of
/// the generic literal "Tax"/"Discount".
Widget buildSharedTotalsAndNotesSection(DocTemplateAdapter a, {DocEditBundle? edit}) {
  final editable = edit != null;
  final ff = a.fontFamily;

  // NO-TRUNCATION PASS: label and amount both now render via
  // autoFitText instead of Flexible + maxLines:1 + ellipsis. A
  // user-typed discount/tax label like "Early Payment Discount (3%)"
  // (row() is called with that whole string as its label — see
  // discountLabel/taxLabel below) used to get cut off; it now shrinks
  // to fit the row's width instead.
  Widget row(String label, double v, {bool bold = false, bool negative = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
        child: autoFitText(
          label,
          TextStyle(fontSize: bold ? 11 : 10,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? kInk : kGrey, fontFamily: ff),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: autoFitText(
          '${negative ? '−' : ''}${a.fmtMoney(v)}',
          TextStyle(fontSize: bold ? 13 : 10.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? a.accent : kInk, fontFamily: ff),
          textAlign: TextAlign.right,
        ),
      ),
    ]),
  );

  Widget editableRateRow(String label, TextEditingController ctrl, ValueChanged<String> onChanged,
      double amount, {bool negative = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$label (', style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff)),
          SizedBox(
            width: 28,
            child: DocField(
              value: ctrl.text, editable: true, controller: ctrl, onChanged: onChanged,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 10, color: kInk, fontFamily: ff),
            ),
          ),
          Text('%)', style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff)),
        ]),
        Text('${negative ? '−' : ''}${a.fmtMoney(amount)}',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
      ]),
    );
  }

  final showDiscount = docFieldOn(a, 'discount');
  final showTax = docFieldOn(a, 'tax');
  final showNotes = docFieldOn(a, 'notes');

  final discountLabel = a.discountNameActual.trim().isEmpty ? 'Discount' : a.discountNameActual.trim();
  final taxLabel = a.taxNameActual.trim().isEmpty ? 'Tax' : a.taxNameActual.trim();

  final paymentInfoPanel = buildSharedPaymentInfoPanel(a);

  final totalsColumn = Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      row('Subtotal', a.subtotal),
      if (!showDiscount)
        const SizedBox.shrink()
      else
        editable
            ? editableRateRow(discountLabel, edit.discountRateCtrl, edit.onDiscountRateChanged,
                a.discountAmount, negative: true)
            : (a.discountRate > 0
                ? row('$discountLabel (${a.discountRate.toStringAsFixed(0)}%)', a.discountAmount, negative: true)
                : const SizedBox.shrink()),
      if (!showTax)
        const SizedBox.shrink()
      else
        editable
            ? editableRateRow(taxLabel, edit.taxRateCtrl, edit.onTaxRateChanged, a.taxAmount)
            : (a.taxRate > 0
                ? row('$taxLabel (${a.taxRate.toStringAsFixed(0)}%)', a.taxAmount)
                : const SizedBox.shrink()),
      if (showDiscount)
        for (final entry in a.itemDiscountExtraByName.entries)
          if (entry.value > 0)
            row(entry.key.isEmpty ? 'Item Discounts' : 'Item Discounts (${entry.key})',
                entry.value, negative: true),
      if (showTax)
        for (final entry in a.itemTaxExtraByName.entries)
          if (entry.value != 0)
            row(entry.key.isEmpty ? 'Item Tax' : 'Item Tax (${entry.key})',
                entry.value.abs(), negative: entry.value < 0),
      const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, color: kRule)),
      row(a.totalLabel, a.total, bold: true),
      buildSharedDueDateAmountBar(a),
    ],
  );

  final notesPanel = (showNotes && (editable || a.notes.trim().isNotEmpty))
      ? Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kPanelBg, borderRadius: BorderRadius.circular(6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('NOTES', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                color: kGrey, letterSpacing: 1.2, fontFamily: ff)),
            const SizedBox(height: 6),
            DocField(
              value: a.notes, editable: editable, controller: edit?.notesCtrl,
              onChanged: edit?.onNotesChanged, hint: 'Notes…', maxLines: 4,
              style: TextStyle(fontSize: 9.5, color: kInk, height: 1.5, fontFamily: ff),
            ),
          ]),
        )
      : null;

  return Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: paymentInfoPanel),
            const SizedBox(width: 24),
            Expanded(flex: 4, child: totalsColumn),
          ],
        ),
        if (notesPanel != null)
          Padding(padding: const EdgeInsets.only(top: 14), child: notesPanel),
        buildSharedTermsPanel(a),
        buildSharedSignatureBlock(a),
      ],
    ),
  );
}

/// NO-TRUNCATION PASS: was maxLines:1 + ellipsis — a longer thank-you
/// line (e.g. with a long email address baked in — see
/// doc_template_adapter.dart's thankYouLabel construction) could get
/// cut with "…". Now shrinks via autoFitText instead.
Widget buildSharedThankYouFooter(DocTemplateAdapter a) {
  if (!docFieldOn(a, 'thankYouMessage')) return const SizedBox.shrink();

  return Align(
    alignment: Alignment.centerLeft,
    child: autoFitText(
      a.thankYouLabel,
      TextStyle(fontSize: 8.5, color: kGreyLight, fontFamily: a.fontFamily),
    ),
  );
}