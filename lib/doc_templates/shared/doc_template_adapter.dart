// doc_template_adapter.dart
// lib/doc_templates/shared/doc_template_adapter.dart
//
// The whole point of this file: InvoiceData, QuoteData, and ReceiptData are
// structurally near-identical (same business/client fields, same lineItems
// + tax/discount pattern) but differ in field *names* and enum types, which
// is exactly what forced every template design to be hand-copied three
// times. DocTemplateAdapter is the common shape all three convert into, so
// a template's header/body design can be written ONCE against the adapter
// and used by invoice, quote, and receipt alike.
//
// This only covers the READ path (preview rendering / PDF-style layout).
// It does not know about InvoiceEditBundle or its quote/receipt
// equivalents â€” the existing WYSIWYG edit canvases keep talking to
// executive_page_stationary_layout.dart / executive_quote_stationary_layout.dart
// / executive_receipt_stationary_layout.dart directly, untouched by this.
//
// To add a new template design: write one header widget against
// DocTemplateAdapter (see 02_nordic/nordic_template.dart), reuse
// buildSharedLineItemRow / buildSharedFooterSection from
// shared_doc_widgets.dart for the rest, and expose three thin Preview
// wrappers (one per doc type) that call the three toXAdapter() functions
// below.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../invoice_layout_templates/01_executive_cv_layout/executive_page_stationary_layout.dart'
    show invoiceAccent;
import '../../quote_layout_templates/01_executive_quote_layout/executive_quote_stationary_layout.dart'
    show quoteAccent;
import '../../receipt_layout_templates/01_executive_receipt_layout/executive_receipt_stationary_layout.dart'
    show receiptAccent;

class DocTemplateAdapter {
  // â”€â”€ Document identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final String docTypeLabel;       // 'INVOICE' | 'QUOTE' | 'RECEIPT'
  final String docNumber;
  final String continuationSuffix; // e.g. '(continued)'
  final String recipientLabel;     // 'BILLED TO' | 'PREPARED FOR' | 'RECEIVED FROM'

  // â”€â”€ Business identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final String businessName;
  final String businessEmail;
  final String businessPhone;
  final String businessAddress;
  final String? businessLogoPath;

  // â”€â”€ Client / recipient â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;

  // â”€â”€ Meta row (two label/value pairs â€” dates for invoice/quote, date +
  // payment method for receipt) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final String metaLabel1;
  final String metaValue1;
  final String metaLabel2;
  final String metaValue2;

  // â”€â”€ Status badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final String statusLabel;
  final Color statusColor;

  // â”€â”€ Money â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final String currency;
  final List<LineItem> lineItems;
  final double subtotal;
  final double discountRate;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String totalLabel; // 'Grand Total' | 'Total' | 'Amount Paid'

  // â”€â”€ Misc â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final String notes;
  final String fontFamily;
  final Color accent;
  final String thankYouLabel;

  const DocTemplateAdapter({
    required this.docTypeLabel,
    required this.docNumber,
    required this.continuationSuffix,
    required this.recipientLabel,
    required this.businessName,
    required this.businessEmail,
    required this.businessPhone,
    required this.businessAddress,
    this.businessLogoPath,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.clientAddress,
    required this.metaLabel1,
    required this.metaValue1,
    required this.metaLabel2,
    required this.metaValue2,
    required this.statusLabel,
    required this.statusColor,
    required this.currency,
    required this.lineItems,
    required this.subtotal,
    required this.discountRate,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.totalLabel,
    required this.notes,
    required this.fontFamily,
    required this.accent,
    required this.thankYouLabel,
  });
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Status label/color helpers â€” mirror the private ones already living in
// each 01_executive_*_stationary_layout.dart file (kept private there;
// duplicated here rather than exported, since these are one-liners and
// exporting private helpers across files isn't worth the coupling).
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const Color _kGrey = Color(0xFF6B7280);

Color _invoiceStatusColor(PaymentStatus s) => switch (s) {
  PaymentStatus.paid    => const Color(0xFF16A34A),
  PaymentStatus.partial => const Color(0xFFD97706),
  PaymentStatus.overdue => const Color(0xFFDC2626),
  PaymentStatus.unpaid  => _kGrey,
};

String _invoiceStatusLabel(PaymentStatus s) => switch (s) {
  PaymentStatus.paid    => 'PAID',
  PaymentStatus.partial => 'PARTIALLY PAID',
  PaymentStatus.overdue => 'OVERDUE',
  PaymentStatus.unpaid  => 'UNPAID',
};

Color _quoteStatusColor(QuoteStatus s) => switch (s) {
  QuoteStatus.accepted => const Color(0xFF16A34A),
  QuoteStatus.sent     => const Color(0xFF2563EB),
  QuoteStatus.declined => const Color(0xFFDC2626),
  QuoteStatus.expired  => const Color(0xFFD97706),
  QuoteStatus.draft    => _kGrey,
};

String _quoteStatusLabel(QuoteStatus s) => switch (s) {
  QuoteStatus.accepted => 'ACCEPTED',
  QuoteStatus.sent     => 'SENT',
  QuoteStatus.declined => 'DECLINED',
  QuoteStatus.expired  => 'EXPIRED',
  QuoteStatus.draft    => 'DRAFT',
};

Color _receiptStatusColor(ReceiptStatus s) => switch (s) {
  ReceiptStatus.issued   => const Color(0xFF16A34A),
  ReceiptStatus.refunded => const Color(0xFFDC2626),
};

String _receiptStatusLabel(ReceiptStatus s) => switch (s) {
  ReceiptStatus.issued   => 'ISSUED',
  ReceiptStatus.refunded => 'REFUNDED',
};

String _paymentMethodLabel(PaymentMethod m) => switch (m) {
  PaymentMethod.cash         => 'Cash',
  PaymentMethod.card         => 'Card',
  PaymentMethod.bankTransfer => 'Bank Transfer',
  PaymentMethod.other        => 'Other',
};

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Conversion functions â€” one per doc type. Call the matching one from a
// template's Preview wrapper before handing off to TemplateDocument.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

DocTemplateAdapter invoiceToAdapter(InvoiceData d) => DocTemplateAdapter(
      docTypeLabel: 'INVOICE',
      docNumber: d.invoiceNumber,
      continuationSuffix: '(continued)',
      recipientLabel: 'BILLED TO',
      businessName: d.businessName,
      businessEmail: d.businessEmail,
      businessPhone: d.businessPhone,
      businessAddress: d.businessAddress,
      businessLogoPath: d.businessLogoPath,
      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
      metaLabel1: 'Issue Date',
      metaValue1: d.issueDate,
      metaLabel2: 'Due Date',
      metaValue2: d.dueDate,
      statusLabel: _invoiceStatusLabel(d.paymentStatus),
      statusColor: _invoiceStatusColor(d.paymentStatus),
      currency: d.currency,
      lineItems: d.lineItems,
      subtotal: d.subtotal,
      discountRate: d.discountRate,
      discountAmount: d.discountAmount,
      taxRate: d.taxRate,
      taxAmount: d.taxAmount,
      total: d.grandTotal,
      totalLabel: 'Grand Total',
      notes: d.notes,
      fontFamily: d.fontFamily,
      accent: invoiceAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for your business â€” ${d.businessEmail}'
          : 'Thank you for your business',
    );

DocTemplateAdapter quoteToAdapter(QuoteData d) => DocTemplateAdapter(
      docTypeLabel: 'QUOTE',
      docNumber: d.quoteNumber,
      continuationSuffix: '(continued)',
      recipientLabel: 'PREPARED FOR',
      businessName: d.businessName,
      businessEmail: d.businessEmail,
      businessPhone: d.businessPhone,
      businessAddress: d.businessAddress,
      businessLogoPath: d.businessLogoPath,
      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
      metaLabel1: 'Issue Date',
      metaValue1: d.issueDate,
      metaLabel2: 'Valid Until',
      metaValue2: d.expiryDate,
      statusLabel: _quoteStatusLabel(d.quoteStatus),
      statusColor: _quoteStatusColor(d.quoteStatus),
      currency: d.currency,
      lineItems: d.lineItems,
      subtotal: d.subtotal,
      discountRate: d.discountRate,
      discountAmount: d.discountAmount,
      taxRate: d.taxRate,
      taxAmount: d.taxAmount,
      total: d.grandTotal,
      totalLabel: 'Total',
      notes: d.notes,
      fontFamily: d.fontFamily,
      accent: quoteAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for considering us â€” ${d.businessEmail}'
          : 'Thank you for considering us',
    );

DocTemplateAdapter receiptToAdapter(ReceiptData d) => DocTemplateAdapter(
      docTypeLabel: 'RECEIPT',
      docNumber: d.receiptNumber,
      continuationSuffix: '(continued)',
      recipientLabel: 'RECEIVED FROM',
      businessName: d.businessName,
      businessEmail: d.businessEmail,
      businessPhone: d.businessPhone,
      businessAddress: d.businessAddress,
      businessLogoPath: d.businessLogoPath,
      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
      metaLabel1: 'Payment Date',
      metaValue1: d.paymentDate,
      metaLabel2: 'Payment Method',
      metaValue2: _paymentMethodLabel(d.paymentMethod),
      statusLabel: _receiptStatusLabel(d.status),
      statusColor: _receiptStatusColor(d.status),
      currency: d.currency,
      lineItems: d.lineItems,
      subtotal: d.subtotal,
      discountRate: d.discountRate,
      discountAmount: d.discountAmount,
      taxRate: d.taxRate,
      taxAmount: d.taxAmount,
      total: d.amountPaid,
      totalLabel: 'Amount Paid',
      notes: d.notes,
      fontFamily: d.fontFamily,
      accent: receiptAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for your payment â€” ${d.businessEmail}'
          : 'Thank you for your payment',
    );
