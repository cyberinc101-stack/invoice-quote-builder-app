// executive_page_stationary_layout.dart
// lib/invoice_layout_templates/01_executive_cv_layout/executive_page_stationary_layout.dart
//
// Minimal, single-page invoice template. Diamond-logo mark, generous
// whitespace, no sidebar (unlike the CV executive template — invoices
// don't need one). The whole content column is scaled-to-fit by
// ExecutiveInvoicePreview in executive_cv_logic_data.dart; nothing in
// here worries about overflow itself.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/invoice_data.dart';

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

Color invoiceAccent(InvoiceData d) {
  switch (d.colorScheme) {
    case InvoiceColor.blue:   return const Color(0xFF2563EB);
    case InvoiceColor.green:  return const Color(0xFF16A34A);
    case InvoiceColor.purple: return const Color(0xFF7C3AED);
    case InvoiceColor.orange: return const Color(0xFFEA580C);
    case InvoiceColor.red:    return const Color(0xFFDC2626);
    case InvoiceColor.teal:   return const Color(0xFF0D9488);
    case InvoiceColor.black:  return const Color(0xFF1A1A1A);
    case InvoiceColor.indigo: return const Color(0xFF4F46E5);
  }
}

Color _statusColor(PaymentStatus s) => switch (s) {
  PaymentStatus.paid    => const Color(0xFF16A34A),
  PaymentStatus.partial => const Color(0xFFD97706),
  PaymentStatus.overdue => const Color(0xFFDC2626),
  PaymentStatus.unpaid  => kGrey,
};

String _statusLabel(PaymentStatus s) => switch (s) {
  PaymentStatus.paid    => 'PAID',
  PaymentStatus.partial => 'PARTIALLY PAID',
  PaymentStatus.overdue => 'OVERDUE',
  PaymentStatus.unpaid  => 'UNPAID',
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
// InvoiceExecutiveContent — the full invoice body, laid out at natural size.
// Wrapped in Transform.scale by the caller; never clips or scales itself.
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceExecutiveContent extends StatelessWidget {
  final InvoiceData data;
  final Color accent;
  const InvoiceExecutiveContent({super.key, required this.data, required this.accent});

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

// ─── Header: diamond logo + business identity, invoice title + number ────────

class _Header extends StatelessWidget {
  final InvoiceData data; final Color accent; final String ff;
  const _Header({required this.data, required this.accent, required this.ff});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Logo(data: data, accent: accent),
        const SizedBox(width: 14),
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
              if (data.businessAddress.isNotEmpty)
                Text(data.businessAddress, style: TextStyle(fontSize: 9, color: kGrey,
                    height: 1.4, fontFamily: ff), softWrap: true),
              if (data.businessEmail.isNotEmpty || data.businessPhone.isNotEmpty)
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
            Text('INVOICE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                color: kInk, letterSpacing: 3.0, fontFamily: ff)),
            const SizedBox(height: 6),
            Text('#${data.invoiceNumber.isEmpty ? '—' : data.invoiceNumber}',
                style: TextStyle(fontSize: 10.5, color: accent,
                    fontWeight: FontWeight.w600, fontFamily: ff)),
          ],
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final InvoiceData data; final Color accent;
  const _Logo({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    final path = data.businessLogoPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(path), width: size, height: size, fit: BoxFit.cover),
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

// ─── Bill-to (left) + invoice meta grid (right) ───────────────────────────────

class _BillToMetaRow extends StatelessWidget {
  final InvoiceData data; final Color accent; final String ff;
  const _BillToMetaRow({required this.data, required this.accent, required this.ff});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('BILLED TO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
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
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _metaRow('Issue Date', data.issueDate, ff),
              const SizedBox(height: 6),
              _metaRow('Due Date', data.dueDate, ff),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(data.paymentStatus).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_statusLabel(data.paymentStatus),
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                        letterSpacing: 1.0, color: _statusColor(data.paymentStatus), fontFamily: ff)),
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
  final InvoiceData data; final Color accent; final String ff;
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
  final InvoiceData data; final Color accent; final String ff;
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

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: kContentW * 0.42,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          row('Subtotal', data.subtotal),
          if (data.discountRate > 0)
            row('Discount (${data.discountRate.toStringAsFixed(0)}%)', data.discountAmount, negative: true),
          if (data.taxRate > 0)
            row('Tax (${data.taxRate.toStringAsFixed(0)}%)', data.taxAmount),
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, color: kRule)),
          row('Grand Total', data.grandTotal, bold: true),
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
  final InvoiceData data; final String ff;
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
            ? 'Thank you for your business — ${data.businessEmail}'
            : 'Thank you for your business',
        style: TextStyle(fontSize: 8.5, color: kGreyLight, fontFamily: ff),
      ),
    ],
  );
}