import 'package:flutter/material.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../models/address_info.dart';
import '../../models/footer_tagline.dart';
import '../document_backgrounds/page_background_spec.dart';
import '../../document_layout_templates/01_executive/executive_template.dart'
    show invoiceAccent, quoteAccent, receiptAccent;

class DocTemplateAdapter {
  final String docTypeLabel;
  final String docNumber;
  final String continuationSuffix;
  final String recipientLabel;

  final String businessName;
  final String businessTagline;
  final bool businessTaglineEnabled;
  final bool footerTaglinesEnabled;
  final double footerTaglinesFontSize;
  final List<FooterTaglineItem> footerTaglines;
  final String businessEmail;
  final String businessPhone;
  final String businessAddress;
  final String businessTaxId;
  final String businessGstNumber;
  final AddressInfo businessAddressInfo;
  final String? businessLogoPath;

  final double businessLogoOffsetDx;
  final double businessLogoOffsetDy;
  final double businessLogoScale;
  final String businessLogoShape;
  final double businessLogoDisplaySize;

  final bool businessLogoShowInitial;
  final String businessLogoInitialLetter;

  // FREEFORM HEADER LOGO PASS: mirrors InvoiceData's identically-named
  // fields â€” see that model's doc comment. Defaults keep Quote/Receipt
  // adapters (whose own data models don't yet carry these fields)
  // rendering exactly as before this pass; the invoice-only wiring
  // happens in invoiceToAdapter() below.
  final double headerLogoFreeformOffsetDx;
  final double headerLogoFreeformOffsetDy;
  final double headerLogoFreeformScale;

  // BACKGROUND-IMAGE PASS: header/footer background image path +
  // on/off toggle, mirroring InvoiceData/QuoteData/ReceiptData's
  // identically-named new fields. Null path or enabled=false means
  // "no background" â€” every existing document loads and renders
  // exactly as before this pass, since both default to
  // null/false. See doc_header.dart's withOptionalBackgroundImage()
  // for the actual render-side handling (image + translucent scrim,
  // so existing dark text always stays readable â€” no color picker
  // needed).
  final String? headerBackgroundImagePath;
  final bool headerBackgroundEnabled;
  final double headerBackgroundOpacity;
  final double headerBackgroundOffsetDx;
  final double headerBackgroundOffsetDy;
  final double headerBackgroundScale;
  final String? footerBackgroundImagePath;
  final bool footerBackgroundEnabled;
  final double footerBackgroundOpacity;
  final double footerBackgroundOffsetDx;
  final double footerBackgroundOffsetDy;
  final double footerBackgroundScale;

  // MID-PAGE BACKGROUND PASS: same treatment for the page body area
  // (line items + totals) â€” see doc_header.dart's
  // withOptionalBackgroundImage and a4_paginator.dart's own
  // bodyBackgroundImagePath/bodyBackgroundEnabled for the render side.
  final String? bodyBackgroundImagePath;
  final bool bodyBackgroundEnabled;
  final double bodyBackgroundOpacity;
  final double bodyBackgroundOffsetDx;
  final double bodyBackgroundOffsetDy;
  final double bodyBackgroundScale;

  // PER-PAGE BACKGROUND PASS: one continuous image behind the WHOLE
  // page (header + meta row + items + footer), as opposed to
  // header/footer/body above which each paint a separately-clipped
  // ZONE. Defaults ('none' scope) mean every existing document
  // renders exactly as before this pass.
  final String pageBackgroundScope;
  final String? page1BackgroundImagePath;
  final bool page1BackgroundEnabled;
  final double page1BackgroundOpacity;
  final double page1BackgroundOffsetDx;
  final double page1BackgroundOffsetDy;
  final double page1BackgroundScale;
  final bool page1BackgroundFitToPage;
  final Map<int, PageBackgroundSpec> otherPageBackgrounds;

  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final AddressInfo clientAddressInfo;

  final String metaLabel1;
  final String metaValue1;
  final String metaLabel2;
  final String metaValue2;

  final String statusLabel;
  final Color statusColor;

  final String currency;
  final String currencySymbol;
  final String currencyDisplayMode;
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
  final String totalLabel;

  final String taxNameActual;
  final String discountNameActual;

  final String? dueDateSummaryValue;
  final double? amountDueValue;

  final String bankName;
  final String accountName;
  final String accountNumber;
  final String otherPaymentDetails;
  final String termsAndConditions;
  final String signatureMode;
  final String signatureName;
  final String? signatureImagePath;
  final double signatureFontSize;
  final String signatureFontFamily;

  final String notes;
  final String fontFamily;
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
    this.businessTagline = '',
    this.businessTaglineEnabled = true,
    this.footerTaglinesEnabled = false,
    this.footerTaglinesFontSize = 8.0,
    this.footerTaglines = const [],
    required this.businessEmail,
    required this.businessPhone,
    required this.businessAddress,
    this.businessTaxId = '',
    this.businessGstNumber = '',
    required this.businessAddressInfo,
    this.businessLogoPath,
    this.businessLogoOffsetDx = 0.0,
    this.businessLogoOffsetDy = 0.0,
    this.businessLogoScale = 1.0,
    this.businessLogoShape = 'roundedSquare',
    this.businessLogoDisplaySize = 40.0,
    this.businessLogoShowInitial = true,
    this.businessLogoInitialLetter = '',
    this.headerLogoFreeformOffsetDx = 0.0,
    this.headerLogoFreeformOffsetDy = 0.0,
    this.headerLogoFreeformScale = 1.0,
    this.headerBackgroundImagePath,
    this.headerBackgroundEnabled = false,
    this.headerBackgroundOpacity = 1.0,
    this.headerBackgroundOffsetDx = 0.0,
    this.headerBackgroundOffsetDy = 0.0,
    this.headerBackgroundScale = 1.0,
    this.footerBackgroundImagePath,
    this.footerBackgroundEnabled = false,
    this.footerBackgroundOpacity = 1.0,
    this.footerBackgroundOffsetDx = 0.0,
    this.footerBackgroundOffsetDy = 0.0,
    this.footerBackgroundScale = 1.0,
    this.bodyBackgroundImagePath,
    this.bodyBackgroundEnabled = false,
    this.bodyBackgroundOpacity = 1.0,
    this.bodyBackgroundOffsetDx = 0.0,
    this.bodyBackgroundOffsetDy = 0.0,
    this.bodyBackgroundScale = 1.0,
    this.pageBackgroundScope = 'none',
    this.page1BackgroundImagePath,
    this.page1BackgroundEnabled = false,
    this.page1BackgroundOpacity = 1.0,
    this.page1BackgroundOffsetDx = 0.0,
    this.page1BackgroundOffsetDy = 0.0,
    this.page1BackgroundScale = 1.0,
    this.page1BackgroundFitToPage = false,
    this.otherPageBackgrounds = const {},
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.clientAddress,
    required this.clientAddressInfo,
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

  // PER-PAGE BACKGROUND PASS: (pageIndex, pageCount) -> PageBackgroundSpec?
  // matches PageBackgroundResolver exactly, so any template's
  // Preview/Editor can pass adapter.pageBackgroundFor straight into
  // TemplateDocument(pageBackgroundResolver: ...).
  PageBackgroundSpec? pageBackgroundFor(int pageIndex, int pageCount) {
    final scope = pageBackgroundScopeFromString(pageBackgroundScope);
    if (scope == PageBackgroundScope.none) return null;
    final page1Spec = PageBackgroundSpec(
      imagePath: page1BackgroundImagePath,
      enabled: page1BackgroundEnabled,
      opacity: page1BackgroundOpacity,
      offsetDx: page1BackgroundOffsetDx,
      offsetDy: page1BackgroundOffsetDy,
      scale: page1BackgroundScale,
      fitToPage: page1BackgroundFitToPage,
    );
    return resolvePageBackground(
      scope: scope,
      pageIndex: pageIndex,
      pageCount: pageCount,
      page1Spec: page1Spec,
      otherPages: otherPageBackgrounds,
    );
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

// SENDER-AS-FROM-CONTACT PASS (this update): the FROM block's
// email/phone/address slots on this adapter are generic â€” they don't
// care WHERE the caller sources them from. For invoices specifically,
// they're now fed from InvoiceData's senderEmail/senderPhone/
// senderAddressInfo (synced down from the selected template's
// BusinessInfo.sender* fields â€” see step_create_invoice.dart) instead
// of the business* fields, since the template sheet's own Business
// Information section no longer collects a separate business address/
// email/phone (see step_templates.dart) â€” Sender / Contact Person is
// now the single source of "who do I contact about this document".
// businessName still comes from d.businessName (the FROM block's name
// line is unchanged). Quote and Receipt are NOT touched by this pass â€”
// their own data models don't have sender* fields, so they keep
// sourcing the FROM block from their own business* fields exactly as
// before.
DocTemplateAdapter invoiceToAdapter(InvoiceData d) {
  return DocTemplateAdapter(
      docTypeLabel: 'INVOICE',
      docNumber: d.invoiceNumber,
      continuationSuffix: '(continued)',
      recipientLabel: 'BILLED TO',
      businessName: d.businessName,
      businessTagline: d.businessTagline,
      businessTaglineEnabled: d.businessTaglineEnabled,
      footerTaglinesEnabled: d.footerTaglinesEnabled,
      footerTaglinesFontSize: d.footerTaglinesFontSize,
      footerTaglines: d.footerTaglines,
      // SENDER-AS-FROM-CONTACT PASS: sender-sourced, not business-sourced.
      businessEmail: d.senderEmail,
      businessPhone: d.senderPhone,
      businessAddress: d.senderAddressInfo.singleLine,
      businessTaxId: d.businessTaxId,
      businessGstNumber: d.businessGst,
      businessAddressInfo: d.senderAddressInfo,
      businessLogoPath: d.businessLogoPath,
      businessLogoOffsetDx: d.businessLogoOffsetDx,
      businessLogoOffsetDy: d.businessLogoOffsetDy,
      businessLogoScale: d.businessLogoScale,
      businessLogoShape: d.businessLogoShape,
      businessLogoDisplaySize: d.businessLogoDisplaySize,
      businessLogoShowInitial: d.businessLogoShowInitial,
      businessLogoInitialLetter: d.businessLogoInitialLetter,
      headerLogoFreeformOffsetDx: d.headerLogoFreeformOffsetDx,
      headerLogoFreeformOffsetDy: d.headerLogoFreeformOffsetDy,
      headerLogoFreeformScale: d.headerLogoFreeformScale,
      headerBackgroundImagePath: d.headerBackgroundImagePath,
      headerBackgroundEnabled: d.headerBackgroundEnabled,
      headerBackgroundOpacity: d.headerBackgroundOpacity,
      headerBackgroundOffsetDx: d.headerBackgroundOffsetDx,
      headerBackgroundOffsetDy: d.headerBackgroundOffsetDy,
      headerBackgroundScale: d.headerBackgroundScale,
      footerBackgroundImagePath: d.footerBackgroundImagePath,
      footerBackgroundEnabled: d.footerBackgroundEnabled,
      footerBackgroundOpacity: d.footerBackgroundOpacity,
      footerBackgroundOffsetDx: d.footerBackgroundOffsetDx,
      footerBackgroundOffsetDy: d.footerBackgroundOffsetDy,
      footerBackgroundScale: d.footerBackgroundScale,
      bodyBackgroundImagePath: d.bodyBackgroundImagePath,
      bodyBackgroundEnabled: d.bodyBackgroundEnabled,
      bodyBackgroundOpacity: d.bodyBackgroundOpacity,
      bodyBackgroundOffsetDx: d.bodyBackgroundOffsetDx,
      bodyBackgroundOffsetDy: d.bodyBackgroundOffsetDy,
      bodyBackgroundScale: d.bodyBackgroundScale,
      pageBackgroundScope: d.pageBackgroundScope,
      page1BackgroundImagePath: d.page1BackgroundImagePath,
      page1BackgroundEnabled: d.page1BackgroundEnabled,
      page1BackgroundOpacity: d.page1BackgroundOpacity,
      page1BackgroundOffsetDx: d.page1BackgroundOffsetDx,
      page1BackgroundOffsetDy: d.page1BackgroundOffsetDy,
      page1BackgroundScale: d.page1BackgroundScale,
      page1BackgroundFitToPage: d.page1BackgroundFitToPage,
      otherPageBackgrounds: d.otherPageBackgrounds,
      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
      clientAddressInfo: d.clientAddressInfo,
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
      fontSize: d.fontSize,
      accent: invoiceAccent(d),
      thankYouLabel: d.senderEmail.isNotEmpty
          ? 'Thank you for your business â€” ${d.senderEmail}'
          : 'Thank you for your business',
      enabledFields: d.enabledFields,
    );
}

DocTemplateAdapter quoteToAdapter(QuoteData d) => DocTemplateAdapter(
      docTypeLabel: 'QUOTE',
      docNumber: d.quoteNumber,
      continuationSuffix: '(continued)',
      recipientLabel: 'PREPARED FOR',
      businessName: d.businessName,
      businessTagline: d.businessTagline,
      businessTaglineEnabled: d.businessTaglineEnabled,
      footerTaglinesEnabled: d.footerTaglinesEnabled,
      footerTaglinesFontSize: d.footerTaglinesFontSize,
      footerTaglines: d.footerTaglines,
      businessEmail: d.businessEmail,
      businessPhone: d.businessPhone,
      businessAddress: d.businessAddress,
      businessAddressInfo: d.businessAddressInfo,
      businessLogoPath: d.businessLogoPath,
      businessLogoOffsetDx: d.businessLogoOffsetDx,
      businessLogoOffsetDy: d.businessLogoOffsetDy,
      businessLogoScale: d.businessLogoScale,
      businessLogoShape: d.businessLogoShape,
      businessLogoDisplaySize: d.businessLogoDisplaySize,
      businessLogoShowInitial: d.businessLogoShowInitial,
      businessLogoInitialLetter: d.businessLogoInitialLetter,
      headerBackgroundImagePath: d.headerBackgroundImagePath,
      headerBackgroundEnabled: d.headerBackgroundEnabled,
      headerBackgroundOpacity: d.headerBackgroundOpacity,
      headerBackgroundOffsetDx: d.headerBackgroundOffsetDx,
      headerBackgroundOffsetDy: d.headerBackgroundOffsetDy,
      headerBackgroundScale: d.headerBackgroundScale,
      footerBackgroundImagePath: d.footerBackgroundImagePath,
      footerBackgroundEnabled: d.footerBackgroundEnabled,
      footerBackgroundOpacity: d.footerBackgroundOpacity,
      footerBackgroundOffsetDx: d.footerBackgroundOffsetDx,
      footerBackgroundOffsetDy: d.footerBackgroundOffsetDy,
      footerBackgroundScale: d.footerBackgroundScale,
      bodyBackgroundImagePath: d.bodyBackgroundImagePath,
      bodyBackgroundEnabled: d.bodyBackgroundEnabled,
      bodyBackgroundOpacity: d.bodyBackgroundOpacity,
      bodyBackgroundOffsetDx: d.bodyBackgroundOffsetDx,
      bodyBackgroundOffsetDy: d.bodyBackgroundOffsetDy,
      bodyBackgroundScale: d.bodyBackgroundScale,
      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
      clientAddressInfo: d.clientAddressInfo,
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
      fontSize: d.fontSize,
      accent: quoteAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for considering us â€” ${d.businessEmail}'
          : 'Thank you for considering us',
      enabledFields: d.enabledFields,
    );

DocTemplateAdapter receiptToAdapter(ReceiptData d) => DocTemplateAdapter(
      docTypeLabel: 'RECEIPT',
      docNumber: d.receiptNumber,
      continuationSuffix: '(continued)',
      recipientLabel: 'RECEIVED FROM',
      businessName: d.businessName,
      businessTagline: d.businessTagline,
      businessTaglineEnabled: d.businessTaglineEnabled,
      footerTaglinesEnabled: d.footerTaglinesEnabled,
      footerTaglinesFontSize: d.footerTaglinesFontSize,
      footerTaglines: d.footerTaglines,
      businessEmail: d.businessEmail,
      businessPhone: d.businessPhone,
      businessAddress: d.businessAddress,
      businessAddressInfo: d.businessAddressInfo,
      businessLogoPath: d.businessLogoPath,
      businessLogoOffsetDx: d.businessLogoOffsetDx,
      businessLogoOffsetDy: d.businessLogoOffsetDy,
      businessLogoScale: d.businessLogoScale,
      businessLogoShape: d.businessLogoShape,
      businessLogoDisplaySize: d.businessLogoDisplaySize,
      businessLogoShowInitial: d.businessLogoShowInitial,
      businessLogoInitialLetter: d.businessLogoInitialLetter,
      headerBackgroundImagePath: d.headerBackgroundImagePath,
      headerBackgroundEnabled: d.headerBackgroundEnabled,
      headerBackgroundOpacity: d.headerBackgroundOpacity,
      headerBackgroundOffsetDx: d.headerBackgroundOffsetDx,
      headerBackgroundOffsetDy: d.headerBackgroundOffsetDy,
      headerBackgroundScale: d.headerBackgroundScale,
      footerBackgroundImagePath: d.footerBackgroundImagePath,
      footerBackgroundEnabled: d.footerBackgroundEnabled,
      footerBackgroundOpacity: d.footerBackgroundOpacity,
      footerBackgroundOffsetDx: d.footerBackgroundOffsetDx,
      footerBackgroundOffsetDy: d.footerBackgroundOffsetDy,
      footerBackgroundScale: d.footerBackgroundScale,
      bodyBackgroundImagePath: d.bodyBackgroundImagePath,
      bodyBackgroundEnabled: d.bodyBackgroundEnabled,
      bodyBackgroundOpacity: d.bodyBackgroundOpacity,
      bodyBackgroundOffsetDx: d.bodyBackgroundOffsetDx,
      bodyBackgroundOffsetDy: d.bodyBackgroundOffsetDy,
      bodyBackgroundScale: d.bodyBackgroundScale,
      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
      clientAddressInfo: d.clientAddressInfo,
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
      fontSize: d.fontSize,
      accent: receiptAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for your payment â€” ${d.businessEmail}'
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