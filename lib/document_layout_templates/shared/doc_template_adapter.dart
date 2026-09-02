// doc_template_adapter.dart
// lib/document_layout_templates/shared/doc_template_adapter.dart
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
// equivalents — the existing WYSIWYG edit canvases keep talking to
// executive_invoice_stationary_layout.dart / executive_quote_stationary_layout.dart
// / executive_receipt_stationary_layout.dart directly, untouched by this.
//
// To add a new template design: write one header widget against
// DocTemplateAdapter (see 02_nordic/nordic_template.dart), reuse
// buildSharedLineItemRow / buildSharedTotalsAndNotesSection /
// buildSharedThankYouFooter / buildSharedLogo from shared_doc_widgets.dart
// for the rest, and expose three thin Preview wrappers (one per doc type)
// that call the three toXAdapter() functions below.
//
// QUOTE + RECEIPT FIELD VISIBILITY PASS (this update):
//   - quoteToAdapter() now passes d.enabledFields straight through — see
//     QuoteData's own TEMPLATE FIELD VISIBILITY PASS. Quote gained a new
//     "Template" step (quote_editor_screen.dart) mirroring the invoice
//     flow's toggle sheet, backed by the same key set
//     executive_template.dart already reads generically via docFieldOn().
//   - receiptToAdapter() now builds its enabledFields map from
//     ReceiptData's own pre-existing granular show* booleans
//     (showLogo, showBusinessDetails, showCustomerDetails,
//     showReceiptNumber, showDateTime, showPaymentMethod, showTaxLine,
//     showDiscountLine) instead of leaving the class default (const {}).
//     Receipt never needed a new toggle sheet or a new model field for
//     this — those show* fields already existed and are already synced
//     from CreateReceiptScreen's new "Template" step (see that file) —
//     this mapping is what makes the DocTemplateAdapter-based rendering
//     path (executive_template.dart, used by the template chooser and
//     the saved-document Preview screen) finally respect them, the same
//     way executive_receipt_stationary_layout.dart and
//     receipt_pdf_service.dart's A4 export now do directly. businessName
//     itself and the notes/thank-you lines have no dedicated receipt
//     toggle, so those two keys are left out of the map (defaulting true
//     via docFieldOn's `?? true`).
//
// LOGO FALLBACK MARK PASS (earlier): added businessLogoShowInitial
// and businessLogoInitialLetter, threaded through from InvoiceData/
// QuoteData/ReceiptData's own new fields (see those files' doc
// comments). Lets buildSharedLogo() in shared_doc_widgets.dart honour
// the user's choice to hide the no-logo initial-letter mark entirely, or
// override which letter it shows, the same way it already honours
// reposition/zoom/shape for a real uploaded logo.
//
// CURRENCY DISPLAY PASS (earlier): added currencySymbol and
// currencyDisplayMode, threaded through from InvoiceData/QuoteData/
// ReceiptData's own new fields (see those files' doc comments). Money
// formatting itself moved out of shared_doc_widgets.dart's fmtMoney() and
// now lives on DocTemplateAdapter as a method, since it needs both the
// symbol and the display-mode choice rather than a hardcoded lookup.
//
// LOGO FIELDS PASS (earlier): added businessLogoOffsetDx/Dy,
// businessLogoScale, businessLogoShape, businessLogoDisplaySize alongside
// the existing businessLogoPath. Previously the adapter only carried the
// logo *path*, so every non-Executive template design (Nordic, Vibrant,
// Tech Dark, Classic, Gradient Modern, Editorial, Pastel Soft, Brutalist,
// Emerald — anything built against DocTemplateAdapter rather than talking
// to InvoiceData directly) had no way to honour the reposition/zoom/shape/
// size the user configured via the Logo Sizer (SharedLogoPicker) on the
// Customise step — they either rendered no logo at all, or would have had
// to fall back to a plain centred cover-fit render that ignores those
// settings entirely. All three toXAdapter() functions below now pass these
// straight through from InvoiceData/QuoteData/ReceiptData, which already
// had these exact fields (see TEMPLATE + LOGO SIZER PASS in those files'
// doc comments). Defaults match the data classes' own defaults (zero
// offset, scale 1.0, 'roundedSquare' shape, size 40.0), so nothing changes
// for documents that never set a logo, and no persisted-data migration is
// needed.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../document_layout_templates/01_executive/executive_invoice_stationary_layout.dart'
    show invoiceAccent;
import '../../document_layout_templates/01_executive/executive_quote_stationary_layout.dart'
    show quoteAccent;
import '../../document_layout_templates/01_executive/executive_receipt_stationary_layout.dart'
    show receiptAccent;

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

  // Logo reposition/zoom/shape/display size — mirrors InvoiceData/
  // QuoteData/ReceiptData's own fields (SharedLogoPicker-driven). Only
  // meaningful when businessLogoPath is set. Carrying these on the adapter
  // (rather than just businessLogoPath) is what lets every template's
  // header — not just Executive's own edit-canvas layout — render the logo
  // the way the user actually configured it, instead of a plain centred
  // cover-fit circle that ignores their crop/zoom/shape choice.
  final double businessLogoOffsetDx;
  final double businessLogoOffsetDy;
  final double businessLogoScale;
  final String businessLogoShape; // storage name from LogoShape.storageName
  final double businessLogoDisplaySize;

  // No-logo fallback mark — mirrors InvoiceData/QuoteData/ReceiptData's
  // own fields. Only meaningful when businessLogoPath is NOT set:
  // businessLogoShowInitial = false hides the mark entirely (renders
  // nothing where the mark would go); businessLogoInitialLetter, when
  // non-empty, overrides the auto-derived first letter of businessName.
  final bool businessLogoShowInitial;
  final String businessLogoInitialLetter;

  // ── Client / recipient ───────────────────────────────────────────────────
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;

  // ── Meta row (two label/value pairs — dates for invoice/quote, date +
  // payment method for receipt) ────────────────────────────────────────────
  final String metaLabel1;
  final String metaValue1;
  final String metaLabel2;
  final String metaValue2;

  // ── Status badge ──────────────────────────────────────────────────────────
  final String statusLabel;
  final Color statusColor;

  // ── Money ─────────────────────────────────────────────────────────────────
  final String currency;
  // Free-text symbol (e.g. "$", "€") and how it combines with `currency`
  // (the code) when rendered — see fmtMoney() below. Neither is gated by
  // a hardcoded currency list; both come straight from user input.
  final String currencySymbol;
  final String currencyDisplayMode; // 'code' | 'symbol' | 'both'
  final List<LineItem> lineItems;
  final double subtotal;
  final double discountRate;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String totalLabel; // 'Grand Total' | 'Total' | 'Amount Paid'

  // ── Misc ──────────────────────────────────────────────────────────────────
  final String notes;
  final String fontFamily;
  final Color accent;
  final String thankYouLabel;

  // Which template-defined fields should render — same key set as
  // InvoiceData.enabledFields/QuoteData.enabledFields (businessName,
  // businessLogo, invoiceNumber, date, dueDate, customerName/Email/Phone/
  // Address, tax, discount, notes, thankYouMessage, etc). Every read site
  // (buildSharedLogo, buildSharedTotalsAndNotesSection,
  // buildSharedThankYouFooter, executive_template.dart) uses
  // `enabledFields[key] ?? true`, so a key that's absent always reads as
  // shown. Defaults to const {} so existing call sites that don't pass
  // this parameter are unaffected.
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
    required this.total,
    required this.totalLabel,
    required this.notes,
    required this.fontFamily,
    required this.accent,
    required this.thankYouLabel,
    this.enabledFields = const {},
  });

  /// Formats a money amount according to this document's currency code,
  /// symbol, and display mode. Used by shared_doc_widgets.dart instead of
  /// a hardcoded currency->symbol lookup table, since currency and symbol
  /// here are both free text — any currency in the world, not just ones on
  /// a fixed list.
  ///
  /// Falls back gracefully: if currencyDisplayMode calls for a symbol
  /// that's empty (user never set one), falls back to showing the code
  /// instead — so an amount is never rendered as a bare, ambiguous number.
  String fmtMoney(double v) {
    final amount = v.toStringAsFixed(2);
    final hasSymbol = currencySymbol.trim().isNotEmpty;
    final hasCode = currency.trim().isNotEmpty;

    switch (currencyDisplayMode) {
      case 'symbol':
        if (hasSymbol) return '$currencySymbol$amount';
        // No symbol set — fall back to code so the amount isn't bare.
        return hasCode ? '$currency $amount' : amount;
      case 'both':
        if (hasSymbol && hasCode) return '$currency $currencySymbol$amount';
        if (hasSymbol) return '$currencySymbol$amount';
        if (hasCode) return '$currency $amount';
        return amount;
      case 'code':
      default:
        if (hasCode) return '$currency $amount';
        // No code set (shouldn't normally happen) — fall back to symbol.
        return hasSymbol ? '$currencySymbol$amount' : amount;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEMPLATE FIELD VISIBILITY PASS: single read helper for
// DocTemplateAdapter.enabledFields — missing keys default to true
// (shown). Shared by shared_doc_widgets.dart and every *_template.dart
// file that gates a field.
// ─────────────────────────────────────────────────────────────────────────────
bool docFieldOn(DocTemplateAdapter a, String key) => a.enabledFields[key] ?? true;

// ─────────────────────────────────────────────────────────────────────────────
// Status label/color helpers — mirror the private ones already living in
// each 01_executive_*_stationary_layout.dart file (kept private there;
// duplicated here rather than exported, since these are one-liners and
// exporting private helpers across files isn't worth the coupling).
// ─────────────────────────────────────────────────────────────────────────────

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
// Conversion functions — one per doc type. Call the matching one from a
// template's Preview wrapper before handing off to TemplateDocument.
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
      total: d.grandTotal,
      totalLabel: 'Grand Total',
      notes: d.notes,
      fontFamily: d.fontFamily,
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
      total: d.grandTotal,
      totalLabel: 'Total',
      notes: d.notes,
      fontFamily: d.fontFamily,
      accent: quoteAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for considering us — ${d.businessEmail}'
          : 'Thank you for considering us',
      // QUOTE + RECEIPT FIELD VISIBILITY PASS: the piece that was
      // missing — QuoteData.enabledFields now exists (populated from the
      // new Template step in quote_editor_screen.dart) and is carried
      // straight onto the adapter here, same as invoiceToAdapter().
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
      total: d.amountPaid,
      totalLabel: 'Amount Paid',
      notes: d.notes,
      fontFamily: d.fontFamily,
      accent: receiptAccent(d),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for your payment — ${d.businessEmail}'
          : 'Thank you for your payment',
      // QUOTE + RECEIPT FIELD VISIBILITY PASS: ReceiptData has no
      // enabledFields map of its own — it already had granular show*
      // booleans (showLogo, showBusinessDetails, showCustomerDetails,
      // showReceiptNumber, showDateTime, showPaymentMethod, showTaxLine,
      // showDiscountLine), synced from CreateReceiptScreen's new
      // "Template" step. This maps those onto the same generic key set
      // executive_template.dart already gates on via docFieldOn(), so
      // the chooser preview / PDF-preview-screen path (which renders
      // through this adapter) respects them without needing its own
      // parallel toggle system. businessName and notes/thankYouMessage
      // have no dedicated receipt toggle, so those keys are left out
      // (defaulting true).
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
      },
    );
