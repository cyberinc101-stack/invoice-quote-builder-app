// executive_page_stationary_layout.dart
// lib/invoice_layout_templates/01_executive_cv_layout/executive_page_stationary_layout.dart
//
// REWRITE: previously a single monolithic InvoiceExecutiveContent widget
// that got Transform.scale'd to force everything onto one page. This
// version splits the document into header / line-item-row / footer
// builder functions consumed by A4Paginator, so real overflow paginates
// onto additional A4 pages instead of shrinking text. Every builder here
// also accepts an optional InvoiceEditBundle: when null, fields render as
// plain Text (DocField in read-only mode); when provided, fields render
// as borderless TextFields bound to the bundle's controllers â€” same
// widget tree for Preview and Edit, per doc_field.dart's whole reason for
// existing.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/invoice_data.dart';
import '../../../widgets/shared_logo_picker.dart' show SharedLogoPicker, LogoShape;
import '../pagination/doc_field.dart';

// â”€â”€ Page geometry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const double kPageW    = 595.0;
const double kPageH    = 842.0;
const double kPagePadH = 48.0;
const double kPagePadV = 48.0;
const double kContentW = kPageW - kPagePadH * 2;

// â”€â”€ Palette â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  'GBP': 'Â£', 'EUR': 'â‚¬', 'JPY': 'Â¥',
};

String fmtMoney(String currency, double v) {
  final sym = _kCurrencySymbols[currency.toUpperCase()];
  final prefix = sym ?? '${currency.toUpperCase()} ';
  return '$prefix${v.toStringAsFixed(2)}';
}

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// InvoiceEditBundle â€” every controller + callback the editable canvas needs.
// Passing this as null anywhere below means "render read-only."
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class InvoiceEditBundle {
  final TextEditingController businessNameCtrl;
  final TextEditingController businessEmailCtrl;
  final TextEditingController businessPhoneCtrl;
  final TextEditingController businessAddressCtrl;
  final TextEditingController invoiceNumberCtrl;
  final TextEditingController clientNameCtrl;
  final TextEditingController clientEmailCtrl;
  final TextEditingController clientPhoneCtrl;
  final TextEditingController clientAddressCtrl;
  final TextEditingController notesCtrl;
  final TextEditingController taxRateCtrl;
  final TextEditingController discountRateCtrl;
  final List<TextEditingController> itemDescCtrls;
  final List<TextEditingController> itemQtyCtrls;
  final List<TextEditingController> itemPriceCtrls;

  final ValueChanged<String> onBusinessNameChanged;
  final ValueChanged<String> onBusinessEmailChanged;
  final ValueChanged<String> onBusinessPhoneChanged;
  final ValueChanged<String> onBusinessAddressChanged;
  final ValueChanged<String?> onLogoChanged;
  final ValueChanged<String> onInvoiceNumberChanged;
  final ValueChanged<String> onClientNameChanged;
  final ValueChanged<String> onClientEmailChanged;
  final ValueChanged<String> onClientPhoneChanged;
  final ValueChanged<String> onClientAddressChanged;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<String> onTaxRateChanged;
  final ValueChanged<String> onDiscountRateChanged;
  final VoidCallback onTapIssueDate;
  final VoidCallback onTapDueDate;
  final void Function(int index) onItemFieldChanged;
  final void Function(int index) onRemoveItem;

  const InvoiceEditBundle({
    required this.businessNameCtrl,
    required this.businessEmailCtrl,
    required this.businessPhoneCtrl,
    required this.businessAddressCtrl,
    required this.invoiceNumberCtrl,
    required this.clientNameCtrl,
    required this.clientEmailCtrl,
    required this.clientPhoneCtrl,
    required this.clientAddressCtrl,
    required this.notesCtrl,
    required this.taxRateCtrl,
    required this.discountRateCtrl,
    required this.itemDescCtrls,
    required this.itemQtyCtrls,
    required this.itemPriceCtrls,
    required this.onBusinessNameChanged,
    required this.onBusinessEmailChanged,
    required this.onBusinessPhoneChanged,
    required this.onBusinessAddressChanged,
    required this.onLogoChanged,
    required this.onInvoiceNumberChanged,
    required this.onClientNameChanged,
    required this.onClientEmailChanged,
    required this.onClientPhoneChanged,
    required this.onClientAddressChanged,
    required this.onNotesChanged,
    required this.onTaxRateChanged,
    required this.onDiscountRateChanged,
    required this.onTapIssueDate,
    required this.onTapDueDate,
    required this.onItemFieldChanged,
    required this.onRemoveItem,
  });
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Full header (page 1 only): identity + INVOICE title/number, Bill-To/meta
// row, and the column header row above line items.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Widget buildFullHeader({
  required InvoiceData data,
  required Color accent,
  required String ff,
  InvoiceEditBundle? edit,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _HeaderIdentity(data: data, accent: accent, ff: ff, edit: edit),
      const SizedBox(height: 28),
      Container(height: 1, color: kRule),
      const SizedBox(height: 24),
      _BillToMetaRow(data: data, accent: accent, ff: ff, edit: edit),
      const SizedBox(height: 28),
      _LineItemsHeaderRow(accent: accent, ff: ff),
    ],
  );
}

/// Lightweight header repeated on page 2+: just enough context to identify
/// the document, plus the same column header row above continued items.
Widget buildContinuationHeader({
  required InvoiceData data,
  required Color accent,
  required String ff,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(data.businessName.isEmpty ? 'Your Business' : data.businessName,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGrey, fontFamily: ff)),
          Text('INVOICE #${data.invoiceNumber.isEmpty ? 'â€”' : data.invoiceNumber} (continued)',
              style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: ff)),
        ],
      ),
      const SizedBox(height: 16),
      _LineItemsHeaderRow(accent: accent, ff: ff),
    ],
  );
}

class _HeaderIdentity extends StatelessWidget {
  final InvoiceData data; final Color accent; final String ff; final InvoiceEditBundle? edit;
  const _HeaderIdentity({required this.data, required this.accent, required this.ff, this.edit});

  @override
  Widget build(BuildContext context) {
    final editable = edit != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        editable
            ? SizedBox(
                width: 44,
                height: 44,
                child: SharedLogoPicker(
                  logoPath: data.businessLogoPath,
                  logoOffset: Offset.zero,
                  logoScale: 1.0,
                  logoShape: LogoShape.roundedSquare,
                  accent: accent,
                  compact: true,
                  compactBoxSize: 44,
                  onChanged: (path, offset, scale, shape) => edit!.onLogoChanged(path),
                ),
              )
            : _Logo(data: data, accent: accent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DocField(
                value: data.businessName,
                editable: editable,
                controller: edit?.businessNameCtrl,
                onChanged: edit?.onBusinessNameChanged,
                hint: 'Your Business',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff),
              ),
              const SizedBox(height: 4),
              DocField(
                value: data.businessAddress,
                editable: editable,
                controller: edit?.businessAddressCtrl,
                onChanged: edit?.onBusinessAddressChanged,
                hint: 'Business address',
                style: TextStyle(fontSize: 9, color: kGrey, height: 1.4, fontFamily: ff),
              ),
              if (editable) ...[
                const SizedBox(height: 2),
                DocField(
                  value: data.businessEmail,
                  editable: true,
                  controller: edit!.businessEmailCtrl,
                  onChanged: edit!.onBusinessEmailChanged,
                  hint: 'Business email',
                  style: TextStyle(fontSize: 9, color: kGrey, fontFamily: ff),
                ),
                DocField(
                  value: data.businessPhone,
                  editable: true,
                  controller: edit!.businessPhoneCtrl,
                  onChanged: edit!.onBusinessPhoneChanged,
                  hint: 'Business phone',
                  style: TextStyle(fontSize: 9, color: kGrey, fontFamily: ff),
                ),
              ] else if (data.businessEmail.isNotEmpty || data.businessPhone.isNotEmpty)
                Text([data.businessEmail, data.businessPhone].where((s) => s.isNotEmpty).join('   Â·   '),
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
            Row(children: [
              Text('#', style: TextStyle(fontSize: 10.5, color: accent, fontWeight: FontWeight.w600, fontFamily: ff)),
              SizedBox(
                width: 90,
                child: DocField(
                  value: data.invoiceNumber,
                  editable: editable,
                  controller: edit?.invoiceNumberCtrl,
                  onChanged: edit?.onInvoiceNumberChanged,
                  hint: 'â€”',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10.5, color: accent, fontWeight: FontWeight.w600, fontFamily: ff),
                ),
              ),
            ]),
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
        Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
    );
  }
}

class _BillToMetaRow extends StatelessWidget {
  final InvoiceData data; final Color accent; final String ff; final InvoiceEditBundle? edit;
  const _BillToMetaRow({required this.data, required this.accent, required this.ff, this.edit});

  @override
  Widget build(BuildContext context) {
    final editable = edit != null;
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
              DocField(
                value: data.clientName, editable: editable, controller: edit?.clientNameCtrl,
                onChanged: edit?.onClientNameChanged, hint: 'Client name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff),
              ),
              const SizedBox(height: 3),
              DocField(
                value: data.clientAddress, editable: editable, controller: edit?.clientAddressCtrl,
                onChanged: edit?.onClientAddressChanged, hint: 'Client address',
                style: TextStyle(fontSize: 9.5, color: kGrey, height: 1.4, fontFamily: ff),
              ),
              const SizedBox(height: 3),
              DocField(
                value: data.clientEmail, editable: editable, controller: edit?.clientEmailCtrl,
                onChanged: edit?.onClientEmailChanged, hint: 'Client email',
                style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff),
              ),
              const SizedBox(height: 2),
              DocField(
                value: data.clientPhone, editable: editable, controller: edit?.clientPhoneCtrl,
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
              _metaDateRow('Issue Date', data.issueDate, ff, editable ? edit!.onTapIssueDate : null),
              const SizedBox(height: 6),
              _metaDateRow('Due Date', data.dueDate, ff, editable ? edit!.onTapDueDate : null),
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

  Widget _metaDateRow(String label, String value, String ff, VoidCallback? onTap) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value.isEmpty ? 'â€”' : value,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.edit_calendar_rounded, size: 11, color: accent.withOpacity(0.6)),
          ],
        ]),
      ],
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }
}

class _LineItemsHeaderRow extends StatelessWidget {
  final Color accent; final String ff;
  const _LineItemsHeaderRow({required this.accent, required this.ff});

  @override
  Widget build(BuildContext context) {
    final hdr = TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: kGrey, letterSpacing: 1.0, fontFamily: ff);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: accent, width: 1.5))),
      child: Row(children: [
        Expanded(flex: 5, child: Text('DESCRIPTION', style: hdr)),
        Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: hdr)),
        Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: hdr)),
        Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: hdr)),
      ]),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// One line-item row â€” this is what gets fed into A4Paginator's `items` list.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Widget buildLineItemRow({
  required LineItem item,
  required int index,
  required String currency,
  required String ff,
  InvoiceEditBundle? edit,
}) {
  final editable = edit != null;
  final descCtrl  = editable ? edit!.itemDescCtrls[index] : null;
  final qtyCtrl   = editable ? edit!.itemQtyCtrls[index] : null;
  final priceCtrl = editable ? edit!.itemPriceCtrls[index] : null;

  final qty   = editable ? (double.tryParse(qtyCtrl!.text) ?? item.quantity) : item.quantity;
  final price = editable ? (double.tryParse(priceCtrl!.text) ?? item.unitPrice) : item.unitPrice;
  final total = qty * price;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kRule, width: 0.75))),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: DocField(
            value: item.description, editable: editable, controller: descCtrl,
            onChanged: editable ? (_) => edit!.onItemFieldChanged(index) : null,
            hint: 'Item description',
            style: TextStyle(fontSize: 10, color: kInk, height: 1.4, fontFamily: ff),
          ),
        ),
        Expanded(
          flex: 1,
          child: DocField(
            value: _fmtQty(item.quantity), editable: editable, controller: qtyCtrl,
            onChanged: editable ? (_) => edit!.onItemFieldChanged(index) : null,
            hint: '1', textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff),
          ),
        ),
        Expanded(
          flex: 2,
          child: DocField(
            value: fmtMoney(currency, item.unitPrice), editable: editable, controller: priceCtrl,
            onChanged: editable ? (_) => edit!.onItemFieldChanged(index) : null,
            hint: '0.00', textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(fmtMoney(currency, total), textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
        ),
        if (editable)
          SizedBox(
            width: 20,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
              onPressed: () => edit!.onRemoveItem(index),
            ),
          ),
      ],
    ),
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Footer (last page only): totals block, tax/discount rows (editable inline
// when a bundle is given), notes panel, thank-you line.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Widget buildFooterSection({
  required InvoiceData data,
  required Color accent,
  required String ff,
  InvoiceEditBundle? edit,
}) {
  final editable = edit != null;

  Widget row(String label, double v, {bool bold = false, bool negative = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: bold ? 11 : 10,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: bold ? kInk : kGrey, fontFamily: ff)),
      Text('${negative ? 'âˆ’' : ''}${fmtMoney(data.currency, v)}',
          style: TextStyle(fontSize: bold ? 13 : 10.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? accent : kInk, fontFamily: ff)),
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
              style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff),
            ),
          ),
          Text('%)', style: TextStyle(fontSize: 10, color: kGrey, fontFamily: ff)),
        ]),
        Text('${negative ? 'âˆ’' : ''}${fmtMoney(data.currency, amount)}',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kInk, fontFamily: ff)),
      ]),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: kContentW * 0.42,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            row('Subtotal', data.subtotal),
            editable
                ? editableRateRow('Discount', edit!.discountRateCtrl, edit!.onDiscountRateChanged,
                    data.discountAmount, negative: true)
                : (data.discountRate > 0
                    ? row('Discount (${data.discountRate.toStringAsFixed(0)}%)', data.discountAmount, negative: true)
                    : const SizedBox.shrink()),
            editable
                ? editableRateRow('Tax', edit!.taxRateCtrl, edit!.onTaxRateChanged, data.taxAmount)
                : (data.taxRate > 0
                    ? row('Tax (${data.taxRate.toStringAsFixed(0)}%)', data.taxAmount)
                    : const SizedBox.shrink()),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, color: kRule)),
            row('Grand Total', data.grandTotal, bold: true),
          ]),
        ),
      ),
      if (editable || data.notes.trim().isNotEmpty) ...[
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kPanelBg, borderRadius: BorderRadius.circular(6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('NOTES', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                color: kGrey, letterSpacing: 1.2, fontFamily: ff)),
            const SizedBox(height: 6),
            DocField(
              value: data.notes, editable: editable, controller: edit?.notesCtrl,
              onChanged: edit?.onNotesChanged, hint: 'Payment terms, thank-you note...', maxLines: 4,
              style: TextStyle(fontSize: 9.5, color: kInk, height: 1.5, fontFamily: ff),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 32),
      Container(height: 0.75, color: kRule),
      const SizedBox(height: 10),
      Text(
        data.businessEmail.isNotEmpty
            ? 'Thank you for your business â€” ${data.businessEmail}'
            : 'Thank you for your business',
        style: TextStyle(fontSize: 8.5, color: kGreyLight, fontFamily: ff),
      ),
    ],
  );
}
