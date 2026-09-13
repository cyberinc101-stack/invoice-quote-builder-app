// doc_header.dart
// lib/document_layout_templates/document_template_layout_data/doc_header.dart
//
// ALL-BLACK-TEXT PASS (this update): kGrey and kGreyLight are now the
// same near-black value as kInk, instead of the mid/light grey they
// were before (0xFF6B7280 / 0xFF9CA3AF). Every template in the set
// imports these two constants from HERE — some via a bare import, some
// via an explicit `show` — and uses them throughout for "secondary" text
// (addresses, contact lines, meta labels, item sub-text, etc.), so
// changing the two values in this single file makes every template's
// text render in black without touching any of the 10 template files
// individually. The three names (kInk/kGrey/kGreyLight) are kept as
// distinct constants rather than collapsed into one, since several
// templates reference all three by name — removing kGrey/kGreyLight
// entirely would break every import across the template set for no
// benefit; giving them the same VALUE achieves the actual goal (all
// text black) with a one-line-per-constant change and zero risk of
// undefined-identifier errors elsewhere.
//
// ENGINE FOLDER SPLIT PASS (earlier): split out of the former
// shared_doc_widgets.dart (which has been broken into doc_header.dart /
// doc_line_items.dart / doc_totals.dart / template_document.dart, all
// now living together in document_template_layout_data/ instead of
// shared/).
//
// This file holds:
//   - Page geometry constants (kPageW/H, kPagePadH/V, kContentW) and the
//     palette (kInk, kGrey, kGreyLight, kRule, kPanelBg) — the base
//     values every other file in this folder imports from here.
//   - Common formatting helpers (fmtMoney, fmtQty, withGaps, kColGap,
//     abbreviateRateName, sharedLineItemColumnFlags) used by both the
//     line-items file and the totals file.
//   - The actual header-identity widgets: buildSharedLogo,
//     buildSharedHeaderIdentity (business logo/name/address/email/phone
//     block + doc-type label/number), buildSharedMetaRow (recipient
//     block + meta dates + status badge).
//
// Every doc-identity function here handles both read-only (edit: null)
// and editable (edit: non-null, tap-to-edit via DocField) rendering —
// see doc_edit_bundle.dart for the DocEditBundle shape.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/shared_logo_picker.dart'
    show SharedLogoPicker, SharedLogoThumbnail, LogoShapeX, logoShapeFromString;
import 'doc_template_adapter.dart';
import 'doc_edit_bundle.dart';
import '../pagination/doc_field.dart';

// ── Page geometry ────────────────────────────────────────────────────────
const double kPageW    = 595.0;
const double kPageH    = 842.0;
const double kPagePadH = 48.0;
const double kPagePadV = 48.0;
const double kContentW = kPageW - kPagePadH * 2;

// ── Palette ──────────────────────────────────────────────────────────────
// ALL-BLACK-TEXT PASS: kGrey and kGreyLight now match kInk. Kept as
// separate named constants (rather than removed) so every template's
// existing `color: kGrey` / `color: kGreyLight` references keep
// compiling unchanged — only the VALUE changed, not the API.
const Color kInk       = Color(0xFF16181D);
const Color kGrey      = Color(0xFF16181D);
const Color kGreyLight = Color(0xFF16181D);
const Color kRule      = Color(0xFFE5E7EB);
const Color kPanelBg   = Color(0xFFF9FAFB);

String fmtMoney(String currency, double v) =>
    '${currency.toUpperCase()} ${v.toStringAsFixed(2)}';

// Public (no leading underscore) since doc_line_items.dart also needs
// this — was private when everything lived in one file.
String fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

const double kColGap = 10.0;

// Public — shared by doc_line_items.dart's row layout.
List<Widget> withGaps(List<Widget> columns) {
  final out = <Widget>[];
  for (var i = 0; i < columns.length; i++) {
    if (i > 0) out.add(const SizedBox(width: kColGap));
    out.add(columns[i]);
  }
  return out;
}

const Map<String, String> _kRateNameAbbreviations = {
  'gst': 'GST',
  'vat': 'VAT',
  'sales tax': 'ST',
  'hst': 'HST',
  'pst': 'PST',
  'withholding tax': 'WHT',
  'trade discount': 'TD',
  'early payment discount': 'EPD',
  'bulk discount': 'BD',
  'loyalty discount': 'LD',
};

String abbreviateRateName(String name) =>
    _kRateNameAbbreviations[name.trim().toLowerCase()] ?? name.trim();

({bool showDiscountCol, bool showTaxCol, bool showUnitCol}) sharedLineItemColumnFlags(DocTemplateAdapter a) => (
  showDiscountCol: docFieldOn(a, 'discount') && a.lineItems.any((i) => i.discountEnabled),
  showTaxCol: docFieldOn(a, 'tax') && a.lineItems.any((i) => i.taxEnabled),
  showUnitCol: a.lineItems.any((i) => i.unit.trim().isNotEmpty),
);

/// Business logo + name/address/email/phone block, with the doc-type
/// label ("INVOICE"/"QUOTE"/"RECEIPT") and doc number on the trailing
/// side. Read-only unless `edit` is supplied.
Widget buildSharedHeaderIdentity({
  required DocTemplateAdapter a,
  DocEditBundle? edit,
}) {
  final editable = edit != null;
  final ff = a.fontFamily;
  final showBusinessName = docFieldOn(a, 'businessName');
  final showBusinessAddress = docFieldOn(a, 'businessAddress');
  final showBusinessEmail = docFieldOn(a, 'businessEmail');
  final showBusinessPhone = docFieldOn(a, 'businessPhone');
  final showDocNumber = docFieldOn(a, 'invoiceNumber');

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      editable
          ? SizedBox(
              width: a.businessLogoDisplaySize,
              height: a.businessLogoDisplaySize,
              child: SharedLogoPicker(
                logoPath: a.businessLogoPath,
                logoOffset: Offset(a.businessLogoOffsetDx, a.businessLogoOffsetDy),
                logoScale: a.businessLogoScale,
                logoShape: logoShapeFromString(a.businessLogoShape),
                accent: a.accent,
                compact: true,
                compactBoxSize: a.businessLogoDisplaySize,
                onChanged: (path, offset, scale, shape) => edit.onLogoChanged(path),
              ),
            )
          : buildSharedLogo(a),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBusinessName) ...[
              DocField(
                value: a.businessName,
                editable: editable,
                controller: edit?.businessNameCtrl,
                onChanged: edit?.onBusinessNameChanged,
                hint: 'Your Business',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff),
              ),
              const SizedBox(height: 4),
            ],
            if (showBusinessAddress)
              DocField(
                value: a.businessAddress,
                editable: editable,
                controller: edit?.businessAddressCtrl,
                onChanged: edit?.onBusinessAddressChanged,
                hint: 'Business address',
                style: TextStyle(fontSize: 9, color: kGrey, height: 1.4, fontFamily: ff),
              ),
            if (showBusinessEmail) ...[
              const SizedBox(height: 2),
              DocField(
                value: a.businessEmail,
                editable: editable,
                controller: edit?.businessEmailCtrl,
                onChanged: edit?.onBusinessEmailChanged,
                hint: 'Business email',
                style: TextStyle(fontSize: 9, color: kGrey, fontFamily: ff),
              ),
            ],
            if (showBusinessPhone) ...[
              const SizedBox(height: 2),
              DocField(
                value: a.businessPhone,
                editable: editable,
                controller: edit?.businessPhoneCtrl,
                onChanged: edit?.onBusinessPhoneChanged,
                hint: 'Business phone',
                style: TextStyle(fontSize: 9, color: kGrey, fontFamily: ff),
              ),
            ],
          ],
        ),
      ),
      ConstrainedBox(
        // DOC-NUMBER WIDTH FIX: widened from 150 — at the top of the
        // Text Size slider's range, a longer invoice/quote/receipt
        // number no longer fit in the old width and wrapped to a second
        // line (the last couple of characters left dangling below the
        // rest). Widening this box gives it room to stay on one line and
        // naturally shifts the whole block slightly left within the
        // header row, since it's still right-anchored via
        // crossAxisAlignment.end below.
        constraints: const BoxConstraints(maxWidth: 175),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(a.docTypeLabel,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: kInk, letterSpacing: 3.0, fontFamily: ff),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (showDocNumber) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('#', style: TextStyle(fontSize: 10.5, color: a.accent, fontWeight: FontWeight.w600, fontFamily: ff)),
                  const SizedBox(width: 3),
                  ConstrainedBox(
                    // DOC-NUMBER WIDTH FIX: widened from 110 to match
                    // the outer box's increase above.
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: DocField(
                      value: a.docNumber,
                      editable: editable,
                      controller: edit?.docNumberCtrl,
                      onChanged: edit?.onDocNumberChanged,
                      hint: '—',
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      style: TextStyle(fontSize: 10.5, color: a.accent, fontWeight: FontWeight.w600, fontFamily: ff),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

/// Recipient block (client name/address/email/phone) + meta dates +
/// status badge. Read-only unless `edit` is supplied.
Widget buildSharedMetaRow({
  required DocTemplateAdapter a,
  DocEditBundle? edit,
}) {
  final editable = edit != null;
  final ff = a.fontFamily;
  final showClientName = docFieldOn(a, 'customerName');
  final showClientAddress = docFieldOn(a, 'customerAddress');
  final showClientEmail = docFieldOn(a, 'customerEmail');
  final showClientPhone = docFieldOn(a, 'customerPhone');
  final showMeta1 = docFieldOn(a, 'date');
  final showMeta2 = docFieldOn(a, 'dueDate');

  Widget metaDateRow(String label, String value, VoidCallback? onTap) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value.isEmpty ? '—' : value,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.edit_calendar_rounded, size: 11, color: a.accent.withValues(alpha: 0.6)),
          ],
        ]),
      ],
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(a.recipientLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: a.accent, letterSpacing: 1.6, fontFamily: ff)),
            const SizedBox(height: 8),
            if (showClientName) ...[
              DocField(
                value: a.clientName, editable: editable, controller: edit?.clientNameCtrl,
                onChanged: edit?.onClientNameChanged, hint: 'Client name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff),
              ),
              const SizedBox(height: 3),
            ],
            if (showClientAddress) ...[
              DocField(
                value: a.clientAddress, editable: editable, controller: edit?.clientAddressCtrl,
                onChanged: edit?.onClientAddressChanged, hint: 'Client address',
                style: TextStyle(fontSize: 9.5, color: kGrey, height: 1.4, fontFamily: ff),
              ),
              const SizedBox(height: 3),
            ],
            if (showClientEmail) ...[
              DocField(
                value: a.clientEmail, editable: editable, controller: edit?.clientEmailCtrl,
                onChanged: edit?.onClientEmailChanged, hint: 'Client email',
                style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff),
              ),
              const SizedBox(height: 2),
            ],
            if (showClientPhone)
              DocField(
                value: a.clientPhone, editable: editable, controller: edit?.clientPhoneCtrl,
                onChanged: edit?.onClientPhoneChanged, hint: 'Client phone',
                style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff),
              ),
          ],
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMeta1) ...[
              metaDateRow(a.metaLabel1, a.metaValue1, editable ? edit.onTapMetaDate1 : null),
              const SizedBox(height: 6),
            ],
            if (showMeta2) ...[
              metaDateRow(a.metaLabel2, a.metaValue2, editable ? edit.onTapMetaDate2 : null),
              const SizedBox(height: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: a.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(a.statusLabel,
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.0, color: a.statusColor, fontFamily: ff)),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget buildSharedLogo(
  DocTemplateAdapter a, {
  double? size,
  Color? fallbackMarkColor,
  Color? fallbackMarkTextColor,
}) {
  final boxSize = size ?? a.businessLogoDisplaySize;

  if (!docFieldOn(a, 'businessLogo')) {
    return SizedBox(width: boxSize, height: boxSize);
  }

  final path = a.businessLogoPath;

  if (path != null && path.isNotEmpty && File(path).existsSync()) {
    final shape = logoShapeFromString(a.businessLogoShape);
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: ClipRRect(
        borderRadius: shape.radiusFor(boxSize),
        child: SharedLogoThumbnail(
          logoPath: path,
          logoOffset: Offset(a.businessLogoOffsetDx, a.businessLogoOffsetDy),
          logoScale: a.businessLogoScale,
          logoShape: shape,
          boxSize: boxSize,
        ),
      ),
    );
  }

  if (!a.businessLogoShowInitial) {
    return SizedBox(width: boxSize, height: boxSize);
  }

  final markColor = fallbackMarkColor ?? a.accent;
  final textColor = fallbackMarkTextColor ?? Colors.white;
  final customLetter = a.businessLogoInitialLetter.trim();
  final initial = customLetter.isNotEmpty
      ? customLetter[0].toUpperCase()
      : (a.businessName.trim().isNotEmpty ? a.businessName.trim()[0].toUpperCase() : 'B');

  return SizedBox(
    width: boxSize,
    height: boxSize,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: boxSize * 0.72,
            height: boxSize * 0.72,
            decoration: BoxDecoration(color: markColor, borderRadius: BorderRadius.circular(5)),
          ),
        ),
        Text(initial,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: boxSize * 0.34)),
      ],
    ),
  );
}