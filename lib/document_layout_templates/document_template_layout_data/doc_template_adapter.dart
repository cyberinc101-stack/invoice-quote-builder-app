// doc_template_adapter.dart
// lib/document_layout_templates/document_template_layout_data/doc_template_adapter.dart
//
// TEXT-SIZE WIRING FIX (this update): added `fontSize` to the adapter
// itself, populated from InvoiceData.fontSize / QuoteData.fontSize /
// ReceiptData.fontSize in each conversion function below. Previously
// this value existed on every doc-type model (the "Text Size" slider in
// every customize screen writes it) but was NEVER carried across into
// DocTemplateAdapter at all — every template's TextStyle uses a
// hardcoded pixel fontSize with zero reference to this field, so the
// slider visibly moved while nothing in the actual rendered document
// ever changed. Rather than rewriting every hardcoded fontSize across
// all 10 templates (fragile, huge diff, easy to miss one), this value
// is turned into a single text-scale multiplier applied uniformly via
// A4Paginator's textScale param (see template_document.dart) — one
// change point, every template affected consistently, no template file
// needed touching.
//
// MERGE PASS (earlier): three additions that close the gap between
// this adapter and the (now-deleted) per-type editable stationary-layout
// files:
//
//   1. taxNameActual / discountNameActual — the user-typed label (e.g.
//      "GST", "Trade Discount") for the document's own whole-document
//      Tax %/Discount %. Previously only the RATE existed on this
//      adapter (taxRate/discountRate); the NAME never made it across
//      from InvoiceData.taxName/discountName (and QuoteData/ReceiptData's
//      identical fields), which is why every template except Executive
//      (which read InvoiceData directly) rendered "Tax (10%)" instead of
//      "GST (10%)". Named "*Actual" rather than reusing "taxName"/
//      "discountName" to avoid colliding with anything a future pass
//      might want for a different purpose; still just a plain field.
//
//   2. dueDateSummaryValue / amountDueValue — the Due Date/Amount Due bar
//      rendered directly under Grand Total (invoice-only; both null for
//      quote/receipt, same pattern metaLabel2/metaValue2 already uses
//      for doc-type-specific fields). Ported from InvoiceData's
//      dueDateSummary/amountDue enabledFields keys + amountDue getter.
//
//   3. quoteToAdapter()/receiptToAdapter() now actually populate
//      bankName/accountName/accountNumber/otherPaymentDetails/
//      termsAndConditions/signatureMode/signatureName/
//      signatureImagePath/signatureFontSize/signatureFontFamily instead
//      of leaving them at empty defaults.
//
// (All comments from the previous version describe work already done
// and still apply to the fields they mention; trimmed here to keep this
// header focused on what changed in this pass.)

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../document_layout_templates/01_executive/executive_template.dart'
    show invoiceAccent, quoteAccent, receiptAccent;

class DocTemplateAdapter {
  // ── Document identity ────────────────────────────────────────────────────
  final String docTypeLabel;       // 'INVOICE' | 'QUOTE' | 'RECEIPT'
  final String docNumber;
  final String continuationSuffix; // e.g. '(continued)'
  final String recipientLabel;     // 'BILLED TO' | 'PREPARED FOR' | 'RECEIVED FROM'

  // ── Business identity ────────────────────────────────────────────────────
  final String businessName;
  final String businessEmail;
  final String businessPhone;
  final String businessAddress;
  final String? businessLogoPath;

  final double businessLogoOffsetDx;
  final double businessLogoOffsetDy;
  final double businessLogoScale;
  final String businessLogoShape; // storage name from LogoShape.storageName
  final double businessLogoDisplaySize;

  final bool businessLogoShowInitial;
  final String businessLogoInitialLetter;

  // ── Client / recipient ───────────────────────────────────────────────────
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;

  // ── Meta row ──────────────────────────────────────────────────────────────
  final String metaLabel1;
  final String metaValue1;
  final String metaLabel2;
  final String metaValue2;

  // ── Status badge ──────────────────────────────────────────────────────────
  final String statusLabel;
  final Color statusColor;

  // ── Money ─────────────────────────────────────────────────────────────────
  final String currency;
  final String currencySymbol;
  final String currencyDisplayMode; // 'code' | 'symbol' | 'both'
  final List<LineItem> lineItems;
  final double subtotal;
  final double discountRate;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double itemTaxExtra;
  final double itemDiscountExtra;
  final Map<String, double> itemTaxExtraByName;
  final Map<String, double> itemDiscountExtraByName;
  final double total;
  final String totalLabel; // 'Grand Total' | 'Total' | 'Amount Paid'

  final String taxNameActual;
  final String discountNameActual;

  final String? dueDateSummaryValue;
  final double? amountDueValue;

  // ── Payment details / terms & conditions / signature ────────────────────
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String otherPaymentDetails;
  final String termsAndConditions;
  final String signatureMode; // 'typed' | 'image' | 'blank' | '' (none)
  final String signatureName;
  final String? signatureImagePath;
  final double signatureFontSize;
  final String signatureFontFamily;

  // ── Misc ──────────────────────────────────────────────────────────────────
  final String notes;
  final String fontFamily;
  // TEXT-SIZE WIRING FIX: the "Text Size" slider in every customize screen
  // writes InvoiceData.fontSize / QuoteData.fontSize / ReceiptData.fontSize
  // — but this adapter never carried that value across, and every
  // template's TextStyle uses a hardcoded pixel size with no reference
  // to it at all. Default 12.0 matches the slider's own midpoint (range
  // is 10–16 in every customize screen) — see template_document.dart for
  // how this becomes an actual text-scale multiplier at render time.
  final double fontSize;
  final Color accent;
  final String thankYouLabel;

  final Map<String, bool> enabledFields;

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
    this.businessLogoOffsetDx = 0.0,
    this.businessLogoOffsetDy = 0.0,
    this.businessLogoScale = 1.0,
    this.businessLogoShape = 'roundedSquare',
    this.businessLogoDisplaySize = 40.0,
    this.businessLogoShowInitial = true,
    this.businessLogoInitialLetter = '',
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
    this.currencySymbol = '',
    this.currencyDisplayMode = 'code',
    required this.lineItems,
    required this.subtotal,
    required this.discountRate,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    this.itemTaxExtra = 0.0,
    this.itemDiscountExtra = 0.0,
    this.itemTaxExtraByName = const {},
    this.itemDiscountExtraByName = const {},
    required this.total,
    required this.totalLabel,
    this.taxNameActual = '',
    this.discountNameActual = '',
    this.dueDateSummaryValue,
    this.amountDueValue,
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.otherPaymentDetails = '',
    this.termsAndConditions = '',
    this.signatureMode = '',
    this.signatureName = '',
    this.signatureImagePath,
    this.signatureFontSize = 22.0,
    this.signatureFontFamily = '',
    required this.notes,
    required this.fontFamily,
    this.fontSize = 12.0,
    required this.accent,
    required this.thankYouLabel,
    this.enabledFields = const {},
  });

  String fmtMoney(double v) {
    final amount = v.toStringAsFixed(2);
    final hasSymbol = currencySymbol.trim().isNotEmpty;
    final hasCode = currency.trim().isNotEmpty;

    switch (currencyDisplayMode) {
      case 'symbol':
        if (hasSymbol) return '$currencySymbol$amount';
        return hasCode ? '$currency $amount' : amount;
      case 'both':
        if (hasSymbol && hasCode) return '$currency $currencySymbol$amount';
        if (hasSymbol) return '$currencySymbol$amount';
        if (hasCode) return '$currency $amount';
        return amount;
      case 'code':
      default:
        if (hasCode) return '$currency $amount';
        return hasSymbol ? '$currencySymbol$amount' : amount;
    }
  }
}

bool docFieldOn(DocTemplateAdapter a, String key) => a.enabledFields[key] ?? true;

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

// ─────────────────────────────────────────────────────────────────────────────
// Conversion functions — one per doc type.
// ─────────────────────────────────────────────────────────────────────────────

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
      businessLogoOffsetDx: d.businessLogoOffsetDx,
      businessLogoOffsetDy: d.businessLogoOffsetDy,
      businessLogoScale: d.businessLogoScale,
      businessLogoShape: d.businessLogoShape,
      businessLogoDisplaySize: d.businessLogoDisplaySize,
      businessLogoShowInitial: d.businessLogoShowInitial,
      businessLogoInitialLetter: d.businessLogoInitialLetter,
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
      currencySymbol: d.currencySymbol,
      currencyDisplayMode: d.currencyDisplayMode,
      lineItems: d.lineItems,
      subtotal: d.subtotal,
      discountRate: d.discountRate,
      discountAmount: d.discountAmount,
      taxRate: d.taxRate,
      taxAmount: d.taxAmount,
      itemTaxExtra: d.itemTaxExtra,
      itemDiscountExtra: d.itemDiscountExtra,
      itemTaxExtraByName: d.itemTaxExtraByName,
      itemDiscountExtraByName: d.itemDiscountExtraByName,
      total: d.grandTotal,
      totalLabel: 'Grand Total',
      taxNameActual: d.taxName,
      discountNameActual: d.discountName,
      dueDateSummaryValue: d.dueDate,
      amountDueValue: d.amountDue,
      bankName: d.bankName,
      accountName: d.accountName,
      accountNumber: d.accountNumber,
      otherPaymentDetails: d.otherPaymentDetails,
      termsAndConditions: d.termsAndConditions,
      signatureMode: d.signatureMode,
      signatureName: d.signatureName,
      signatureImagePath: d.signatureImagePath,
      signatureFontSize: d.signatureFontSize,
      signatureFontFamily: d.signatureFontFamily,
      notes: d.notes,
      fontFamily: d.fontFamily,
      // TEXT-SIZE WIRING FIX: previously dropped entirely — this is what
      // makes the Text Size slider in step_customise.dart actually do
      // something to the rendered document.
      fontSize: d.fontSize,
      accent: invoiceAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for your business — ${d.businessEmail}'
          : 'Thank you for your business',
      enabledFields: d.enabledFields,
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
      businessLogoOffsetDx: d.businessLogoOffsetDx,
      businessLogoOffsetDy: d.businessLogoOffsetDy,
      businessLogoScale: d.businessLogoScale,
      businessLogoShape: d.businessLogoShape,
      businessLogoDisplaySize: d.businessLogoDisplaySize,
      businessLogoShowInitial: d.businessLogoShowInitial,
      businessLogoInitialLetter: d.businessLogoInitialLetter,
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
      currencySymbol: d.currencySymbol,
      currencyDisplayMode: d.currencyDisplayMode,
      lineItems: d.lineItems,
      subtotal: d.subtotal,
      discountRate: d.discountRate,
      discountAmount: d.discountAmount,
      taxRate: d.taxRate,
      taxAmount: d.taxAmount,
      itemTaxExtra: d.itemTaxExtra,
      itemDiscountExtra: d.itemDiscountExtra,
      itemTaxExtraByName: d.itemTaxExtraByName,
      itemDiscountExtraByName: d.itemDiscountExtraByName,
      total: d.grandTotal,
      totalLabel: 'Total',
      taxNameActual: d.taxName,
      discountNameActual: d.discountName,
      dueDateSummaryValue: null,
      amountDueValue: null,
      bankName: d.bankName,
      accountName: d.accountName,
      accountNumber: d.accountNumber,
      otherPaymentDetails: d.otherPaymentDetails,
      termsAndConditions: d.termsAndConditions,
      signatureMode: d.signatureMode,
      signatureName: d.signatureName,
      signatureImagePath: d.signatureImagePath,
      signatureFontSize: d.signatureFontSize,
      signatureFontFamily: d.signatureFontFamily,
      notes: d.notes,
      fontFamily: d.fontFamily,
      // TEXT-SIZE WIRING FIX: see invoiceToAdapter()'s note above — same
      // gap existed for Quote.
      fontSize: d.fontSize,
      accent: quoteAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for considering us — ${d.businessEmail}'
          : 'Thank you for considering us',
      enabledFields: d.enabledFields,
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
      businessLogoOffsetDx: d.businessLogoOffsetDx,
      businessLogoOffsetDy: d.businessLogoOffsetDy,
      businessLogoScale: d.businessLogoScale,
      businessLogoShape: d.businessLogoShape,
      businessLogoDisplaySize: d.businessLogoDisplaySize,
      businessLogoShowInitial: d.businessLogoShowInitial,
      businessLogoInitialLetter: d.businessLogoInitialLetter,
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
      currencySymbol: d.currencySymbol,
      currencyDisplayMode: d.currencyDisplayMode,
      lineItems: d.lineItems,
      subtotal: d.subtotal,
      discountRate: d.discountRate,
      discountAmount: d.discountAmount,
      taxRate: d.taxRate,
      taxAmount: d.taxAmount,
      itemTaxExtra: d.itemTaxExtra,
      itemDiscountExtra: d.itemDiscountExtra,
      itemTaxExtraByName: d.itemTaxExtraByName,
      itemDiscountExtraByName: d.itemDiscountExtraByName,
      total: d.amountPaid,
      totalLabel: 'Amount Paid',
      taxNameActual: d.taxName,
      discountNameActual: d.discountName,
      dueDateSummaryValue: null,
      amountDueValue: null,
      signatureMode: d.signatureMode,
      signatureName: d.signatureName,
      signatureImagePath: d.signatureImagePath,
      signatureFontSize: d.signatureFontSize,
      signatureFontFamily: d.signatureFontFamily,
      notes: d.notes,
      fontFamily: d.fontFamily,
      // TEXT-SIZE WIRING FIX: see invoiceToAdapter()'s note above — same
      // gap existed for Receipt.
      fontSize: d.fontSize,
      accent: receiptAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for your payment — ${d.businessEmail}'
          : 'Thank you for your payment',
      enabledFields: {
        'businessLogo': d.showLogo,
        'businessEmail': d.showBusinessDetails,
        'businessPhone': d.showBusinessDetails,
        'businessAddress': d.showBusinessDetails,
        'invoiceNumber': d.showReceiptNumber,
        'date': d.showDateTime,
        'dueDate': d.showPaymentMethod,
        'customerName': d.showCustomerDetails,
        'customerEmail': d.showCustomerDetails,
        'customerPhone': d.showCustomerDetails,
        'customerAddress': d.showCustomerDetails,
        'tax': d.showTaxLine,
        'discount': d.showDiscountLine,
        'thankYouMessage': d.showThankYouMessage,
        'signature': d.showSignature,
      },
    );
