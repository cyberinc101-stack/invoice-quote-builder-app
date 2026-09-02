// executive_receipt_stationary_layout.dart
// lib/document_layout_templates/01_executive/executive_receipt_stationary_layout.dart
//
// FIELD VISIBILITY PASS (this update): every section now checks its
// matching pre-existing ReceiptData show* toggle before rendering —
// _Logo gated on showLogo, business email/phone/address on
// showBusinessDetails (businessName itself has no dedicated toggle and
// always shows), the RECEIVED FROM block on showCustomerDetails, the
// receipt number on showReceiptNumber, the Payment Date/Payment Method
// meta rows on showDateTime/showPaymentMethod respectively, and the
// discount/tax rows in totals on showDiscountLine/showTaxLine. These
// show* fields already existed on ReceiptData and were already wired up
// end-to-end for thermal receipts (ThermalReceiptLivePreview,
// ReceiptPdfService._buildThermalPdf both already gated on them) — this
// A4 layout (used by the editable canvas and, via
// executive_receipt_logic_data.dart, the Review step's live A4 preview)
// simply never checked them, so a receipt saved with e.g. showTaxLine =
// false would still show its tax line here even though the toggle
// existed and was persisted correctly. receipt_pdf_service.dart's A4
// export (_buildExecutivePdf) has the matching fix in that file.
//
// LOGO SIZER PASS (earlier): _Logo now renders through
// SharedLogoThumbnail instead of a plain centred Image.file cover-fit, so
// the businessLogoOffsetDx/Dy/Scale/Shape values saved via the Review
// step's logo sizer (SharedLogoPicker, create_receipt_screen.dart)
// actually take visual effect here — previously this widget ignored all
// four fields entirely. Mirrors the identical fix in
// executive_invoice_stationary_layout.dart (invoice) and
// executive_quote_stationary_layout.dart (quote). The initial-letter
// diamond fallback (no logo set) is unchanged.
//
// Minimal, single-page receipt template. Diamond-logo mark, generous
// whitespace, no sidebar — mirrors
// document_layout_templates/01_executive/executive_invoice_stationary_layout.dart
// and document_layout_templates/01_executive/executive_quote_stationary_layout.dart
// exactly in structure and geometry. Receipt-specific differences only:
// "RECEIPT" heading, "RECEIVED FROM" instead of "BILLED TO"/"PREPARED FOR",
// a single Payment Date + Payment Method meta row instead of
// issue/due-or-expiry dates, a ReceiptStatus-driven badge instead of
// PaymentStatus/QuoteStatus, and "Amount Paid" as the final totals row
// instead of "Grand Total". The whole content column is scaled-to-fit by
// ExecutiveReceiptPreview in executive_receipt_logic_data.dart; nothing in
// here worries about overflow itself.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/receipt_data.dart';
import '../../widgets/shared_logo_picker.dart'
    show SharedLogoThumbnail, LogoShapeX, logoShapeFromString;

// ── Page geometry ─────────────────────────────────────────────────────────────
const double kPageW    = 595.0;
const double kPageH    = 842.0;
const double kPagePadH = 48.0;
const double kPagePadV = 48.0;
const double kContentW = kPageW - kPagePadH * 2;

// ── Palette ───────────────────────────────────────────────────────────────────
const Color kInk       = Color(0xFF16181D);
const Color kGrey      = Color(0xFF6B7280);
const Color kGreyLight = Color(0xFF9CA3AF);
const Color kRule      = Color(0xFFE5E7EB);
const Color kPanelBg   = Color(0xFFF9FAFB);

Color receiptAccent(ReceiptData d) {
  switch (d.colorScheme) {
    case ReceiptColor.blue:   return const Color(0xFF2563EB);
    case ReceiptColor.green:  return const Color(0xFF16A34A);
    case ReceiptColor.purple: return const Color(0xFF7C3AED);
    case ReceiptColor.orange: return const Color(0xFFEA580C);
    case ReceiptColor.red:    return const Color(0xFFDC2626);
    case ReceiptColor.teal:   return const Color(0xFF0D9488);
    case ReceiptColor.black:  return const Color(0xFF1A1A1A);
    case ReceiptColor.indigo: return const Color(0xFF4F46E5);
  }
}

Color _statusColor(ReceiptStatus s) => switch (s) {
  ReceiptStatus.issued   => const Color(0xFF16A34A),
  ReceiptStatus.refunded => const Color(0xFFDC2626),
};

String _statusLabel(ReceiptStatus s) => switch (s) {
  ReceiptStatus.issued   => 'ISSUED',
  ReceiptStatus.refunded => 'REFUNDED',
};

String _paymentMethodLabel(PaymentMethod m) => switch (m) {
  PaymentMethod.cash         => 'Cash',
  PaymentMethod.card         => 'Card',
  PaymentMethod.bankTransfer => 'Bank Transfer',
  PaymentMethod.other        => 'Other',
};

const Map<String, String> _kCurrencySymbols = {
  'USD': '\$', 'NZD': '\$', 'AUD': '\$', 'CAD': '\$',
  'GBP': '£', 'EUR': '€', 'JPY': '¥',
};

String fmtMoney(String currency, double v) {
  final sym = _kCurrencySymbols[currency.toUpperCase()];
  final prefix = sym ?? '${currency.toUpperCase()} ';
  return '$prefix${v.toStringAsFixed(2)}';
}

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

// ─────────────────────────────────────────────────────────────────────────────
// ReceiptExecutiveContent — the full receipt body, laid out at natural size.
// Wrapped in Transform.scale by the caller; never clips or scales itself.
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptExecutiveContent extends StatelessWidget {
  final ReceiptData data;
  final Color accent;
  const ReceiptExecutiveContent({super.key, required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    final ff = data.fontFamily;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(data: data, accent: accent, ff: ff),
        const SizedBox(height: 28),
        Container(height: 1, color: kRule),
        const SizedBox(height: 24),
        _BillToMetaRow(data: data, accent: accent, ff: ff),
        const SizedBox(height: 28),
        _LineItemsTable(data: data, accent: accent, ff: ff),
        const SizedBox(height: 20),
        _TotalsBlock(data: data, accent: accent, ff: ff),
        if (data.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 28),
          _NotesBlock(notes: data.notes, ff: ff),
        ],
        const SizedBox(height: 32),
        _Footer(data: data, ff: ff),
      ],
    );
  }
}

// ─── Header: diamond logo + business identity, "RECEIPT" title + number ──────

class _Header extends StatelessWidget {
  final ReceiptData data; final Color accent; final String ff;
  const _Header({required this.data, required this.accent, required this.ff});

  @override
  Widget build(BuildContext context) {
    // FIELD VISIBILITY PASS: businessName has no dedicated toggle and
    // always shows; email/phone/address are gated together by
    // showBusinessDetails (the one toggle that already covers all three
    // — see ReceiptThermalSettingsSection's identical grouping).
    final showDetails = data.showBusinessDetails;
    final showReceiptNumber = data.showReceiptNumber;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.showLogo) ...[
          _Logo(data: data, accent: accent),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.businessName.isEmpty ? 'Your Business' : data.businessName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: kInk, fontFamily: ff),
                  softWrap: true, overflow: TextOverflow.visible),
              const SizedBox(height: 4),
              if (showDetails && data.businessAddress.isNotEmpty)
                Text(data.businessAddress, style: TextStyle(fontSize: 9, color: kGrey,
                    height: 1.4, fontFamily: ff), softWrap: true),
              if (showDetails && (data.businessEmail.isNotEmpty || data.businessPhone.isNotEmpty))
                Text([data.businessEmail, data.businessPhone]
                        .where((s) => s.isNotEmpty).join('   ·   '),
                    style: TextStyle(fontSize: 9, color: kGrey, fontFamily: ff)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('RECEIPT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                color: kInk, letterSpacing: 3.0, fontFamily: ff)),
            if (showReceiptNumber) ...[
              const SizedBox(height: 6),
              Text('#${data.receiptNumber.isEmpty ? '—' : data.receiptNumber}',
                  style: TextStyle(fontSize: 10.5, color: accent,
                      fontWeight: FontWeight.w600, fontFamily: ff)),
            ],
          ],
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final ReceiptData data; final Color accent;
  const _Logo({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    final size = data.businessLogoDisplaySize;
    final path = data.businessLogoPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      final shape = logoShapeFromString(data.businessLogoShape);
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: shape.radiusFor(size),
          child: SharedLogoThumbnail(
            logoPath: path,
            logoOffset: Offset(data.businessLogoOffsetDx, data.businessLogoOffsetDy),
            logoScale: data.businessLogoScale,
            logoShape: shape,
            boxSize: size,
          ),
        ),
      );
    }
    final initial = data.businessName.trim().isNotEmpty
        ? data.businessName.trim()[0].toUpperCase()
        : 'B';
    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: size * 0.72, height: size * 0.72,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(5)),
          ),
        ),
        Text(initial, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
    );
  }
}

// ─── Received-from (left) + receipt meta grid (right) ─────────────────────────

class _BillToMetaRow extends StatelessWidget {
  final ReceiptData data; final Color accent; final String ff;
  const _BillToMetaRow({required this.data, required this.accent, required this.ff});

  @override
  Widget build(BuildContext context) {
    // FIELD VISIBILITY PASS: the whole RECEIVED FROM block is gated by
    // showCustomerDetails (matches the thermal preview/PDF's identical
    // gating of the customer block). Payment Date/Payment Method rows
    // are gated individually by showDateTime/showPaymentMethod.
    final showCustomer = data.showCustomerDetails;
    final showDate = data.showDateTime;
    final showMethod = data.showPaymentMethod;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: showCustomer
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('RECEIVED FROM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: accent, letterSpacing: 1.6, fontFamily: ff)),
                    const SizedBox(height: 8),
                    Text(data.clientName.isEmpty ? 'Client name' : data.clientName,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: kInk, fontFamily: ff),
                        softWrap: true, overflow: TextOverflow.visible),
                    if (data.clientAddress.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(data.clientAddress, style: TextStyle(fontSize: 9.5, color: kGrey,
                          height: 1.4, fontFamily: ff), softWrap: true),
                    ],
                    if (data.clientEmail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(data.clientEmail, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
                    ],
                    if (data.clientPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(data.clientPhone, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
                    ],
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDate) ...[
                _metaRow('Payment Date', data.paymentDate, ff),
                const SizedBox(height: 6),
              ],
              if (showMethod)
                _metaRow('Payment Method', _paymentMethodLabel(data.paymentMethod), ff),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(data.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_statusLabel(data.status),
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                        letterSpacing: 1.0, color: _statusColor(data.status), fontFamily: ff)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value, String ff) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
      Text(value.isEmpty ? '—' : value,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
    ],
  );
}

// ─── Line items table ──────────────────────────────────────────────────────────

class _LineItemsTable extends StatelessWidget {
  final ReceiptData data; final Color accent; final String ff;
  const _LineItemsTable({required this.data, required this.accent, required this.ff});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: accent, width: 1.5))),
          child: Row(children: [
            Expanded(flex: 5, child: Text('DESCRIPTION', style: _hdrStyle(ff))),
            Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: _hdrStyle(ff))),
            Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: _hdrStyle(ff))),
            Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: _hdrStyle(ff))),
          ]),
        ),
        for (final item in data.lineItems)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kRule, width: 0.75))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: Text(
                  item.description.isEmpty ? 'Item description' : item.description,
                  style: TextStyle(fontSize: 10, color: kInk, height: 1.4, fontFamily: ff),
                  softWrap: true, overflow: TextOverflow.visible)),
              Expanded(flex: 1, child: Text(_fmtQty(item.quantity), textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
              Expanded(flex: 2, child: Text(fmtMoney(data.currency, item.unitPrice), textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff))),
              Expanded(flex: 2, child: Text(fmtMoney(data.currency, item.total), textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff))),
            ]),
          ),
        if (data.lineItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('No line items yet.',
                style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: ff)),
          ),
      ],
    );
  }

  TextStyle _hdrStyle(String ff) => TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
      color: kGrey, letterSpacing: 1.0, fontFamily: ff);
}

// ─── Totals ─────────────────────────────────────────────────────────────────────

class _TotalsBlock extends StatelessWidget {
  final ReceiptData data; final Color accent; final String ff;
  const _TotalsBlock({required this.data, required this.accent, required this.ff});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, double v, {bool bold = false, bool negative = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: bold ? 11 : 10,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? kInk : kGrey, fontFamily: ff)),
        Text('${negative ? '−' : ''}${fmtMoney(data.currency, v)}',
            style: TextStyle(fontSize: bold ? 13 : 10.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? accent : kInk, fontFamily: ff)),
      ]),
    );

    // FIELD VISIBILITY PASS: discount/tax rows gated on
    // showDiscountLine/showTaxLine (already the source of truth on the
    // thermal side), in addition to the existing ">0" check.
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: kContentW * 0.42,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          row('Subtotal', data.subtotal),
          if (data.showDiscountLine && data.discountRate > 0)
            row('Discount (${data.discountRate.toStringAsFixed(0)}%)', data.discountAmount, negative: true),
          if (data.showTaxLine && data.taxRate > 0)
            row('Tax (${data.taxRate.toStringAsFixed(0)}%)', data.taxAmount),
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, color: kRule)),
          row('Amount Paid', data.amountPaid, bold: true),
        ]),
      ),
    );
  }
}

// ─── Notes ──────────────────────────────────────────────────────────────────────

class _NotesBlock extends StatelessWidget {
  final String notes; final String ff;
  const _NotesBlock({required this.notes, required this.ff});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kPanelBg, borderRadius: BorderRadius.circular(6)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('NOTES', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
          color: kGrey, letterSpacing: 1.2, fontFamily: ff)),
      const SizedBox(height: 6),
      Text(notes, style: TextStyle(fontSize: 9.5, color: kInk, height: 1.5, fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible),
    ]),
  );
}

// ─── Footer ─────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final ReceiptData data; final String ff;
  const _Footer({required this.data, required this.ff});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(height: 0.75, color: kRule),
      const SizedBox(height: 10),
      Text(
        data.businessEmail.isNotEmpty
            ? 'Thank you for your payment — ${data.businessEmail}'
            : 'Thank you for your payment',
        style: TextStyle(fontSize: 8.5, color: kGreyLight, fontFamily: ff),
      ),
    ],
  );
}
