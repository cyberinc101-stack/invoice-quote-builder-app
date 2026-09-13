// pdf_doc_adapter.dart
// lib/services/pdf_doc_adapter.dart
//
// The pw (PDF widgets) equivalent of document_layout_templates/shared/doc_template_
// adapter.dart. InvoiceData/QuoteData/ReceiptData are structurally
// near-identical (same business/client fields, same lineItems +
// tax/discount pattern) but differ in field names and enum types — this
// is the common shape all three convert into so a PDF template design can
// be written ONCE against PdfDocData and used for invoice, quote, and
// receipt PDFs alike, mirroring the Flutter-side pattern exactly.
//
// SHARED/EXECUTIVE PARITY PASS — PDF SIDE (this update): added
// itemTaxExtraByName and itemDiscountExtraByName — the same grouped-by-
// name breakdown Executive's own PDF export (invoice_pdf_service.dart's
// _buildExecutivePdf) already uses, and the identical fields added to
// DocTemplateAdapter on the Flutter preview side (see
// document_layout_templates/document_template_layout_data/doc_template_adapter.dart). Previously
// PdfDocData only carried the flat itemTaxExtra/itemDiscountExtra sums,
// which is all pdf_templates.dart's _sharedTotalsAndNotes used — so an
// exported PDF for any of the 9 non-Executive styles showed one lumped
// "Item Discounts"/"Item Tax" row instead of Executive's real per-name
// breakdown (e.g. separate rows for "GST" and "Withholding Tax"). Both
// new fields default to const {}, and are now populated by ALL THREE
// toXPdfData() functions below from InvoiceData/QuoteData/ReceiptData's
// own itemDiscountExtraByName/itemTaxExtraByName getters — those getters
// already exist on all three data classes (their Flutter-side Executive
// stationary layouts already read them directly), so this is a straight
// pass-through. The flat itemTaxExtra/itemDiscountExtra fields
// previously only populated for invoiceToPdfData() are now ALSO
// populated for quoteToPdfData()/receiptToPdfData() — same reasoning,
// since QuoteData/ReceiptData carry those getters too.
//
// PER-ITEM TAX/DISCOUNT TOTALS PASS (earlier): added itemTaxExtra and
// itemDiscountExtra — mirrors the identical addition to DocTemplateAdapter
// in document_layout_templates/document_template_layout_data/doc_template_adapter.dart. `total`
// below already folds these in (invoiceToPdfData sets it to d.grandTotal,
// which already accounts for per-item tax/discount), but the previous
// Subtotal/Discount/Tax breakdown in pdf_templates.dart's
// _sharedTotalsAndNotes didn't show them, so an exported PDF for an
// invoice using per-item tax/discount could show a totals block that
// didn't visibly sum to the printed total.
//
// LOGO PARITY PASS (earlier): added logoShape — previously PdfDocData
// only carried logoImage, so every PDF template rendered the logo as a
// hardcoded circle (ClipOval) regardless of what shape the user actually
// picked via the Logo Sizer (SharedLogoPicker) on the Flutter side. This
// mirrors DocTemplateAdapter's businessLogoShape field on the Flutter
// preview side (see document_layout_templates/shared/doc_template_
// adapter.dart's own LOGO FIELDS PASS) so an exported PDF's logo shape
// matches what the user configured and saw in the preview. Offset/scale
// are deliberately NOT threaded through here — pdf_templates.dart's
// _logoWidget renders with BoxFit.contain (whole logo, no cropping, see
// that file's own LOGO PARITY PASS), and contain-fit has nothing for a
// pan/zoom crop to apply to, same reasoning as the Flutter-side
// DocLogoAvatar's contain-fit branch.
//
// CURRENCY DISPLAY PASS (earlier): added currencySymbol and
// currencyDisplayMode, mirroring DocTemplateAdapter's own fields on the
// Flutter preview side — see document_layout_templates/shared/
// doc_template_adapter.dart for the full rationale (free text, no
// hardcoded currency list). fmtMoney() here is the PDF-side twin of that
// file's fmtMoney() method, so the exported PDF renders money identically
// to the on-screen preview.

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';

class PdfDocData {
  final String docTypeLabel;
  final String docNumber;
  final String recipientLabel;

  final String businessName;
  final String businessEmail;
  final String businessPhone;
  final String businessAddress;
  final pw.MemoryImage? logoImage;

  // Shape the user picked via the Logo Sizer (SharedLogoPicker /
  // LogoShape.storageName) — 'circle' | 'square' | 'roundedSquare'. Only
  // meaningful when logoImage is set. Defaults to 'roundedSquare',
  // matching every model's own default for businessLogoShape.
  final String logoShape;

  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;

  final String metaLabel1;
  final String metaValue1;
  final String metaLabel2;
  final String metaValue2;

  final String statusLabel;
  final PdfColor statusColor;

  final String currency;
  // Free-text symbol + display mode — see doc_template_adapter.dart
  // (Flutter side) for the full rationale. Not gated by any hardcoded
  // currency list.
  final String currencySymbol;
  final String currencyDisplayMode; // 'code' | 'symbol' | 'both'
  final List<LineItem> lineItems;
  final double subtotal;
  final double discountRate;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  // Flat sum of every line item's OWN tax/discount contribution (only
  // items with taxEnabled/discountEnabled true) — mirrors InvoiceData/
  // QuoteData/ReceiptData's itemTaxExtra/itemDiscountExtra getters.
  // `total` below already includes these amounts; prefer
  // itemTaxExtraByName/itemDiscountExtraByName below for any NEW totals
  // rendering — those give the same per-name breakdown Executive's real
  // PDF export shows.
  final double itemTaxExtra;
  final double itemDiscountExtra;
  // SHARED/EXECUTIVE PARITY PASS — PDF SIDE: grouped-by-name breakdown of
  // the same data itemTaxExtra/itemDiscountExtra sum — one entry per
  // distinct itemTaxName/itemDiscountName in use (an empty-string key
  // covers items with no name set), mirroring InvoiceData/QuoteData/
  // ReceiptData's own itemTaxExtraByName/itemDiscountExtraByName getters
  // and the identical fields on DocTemplateAdapter (Flutter preview
  // side). This is what lets pdf_templates.dart's _sharedTotalsAndNotes
  // render one "Item Tax (Withholding Tax)" row and a separate "Item Tax
  // (GST)" row instead of lumping every named rate into a single "Item
  // Tax" figure. Tax values may be signed (a withholding-style rate
  // subtracts) — consumers should render entry.value.abs() with a
  // negative flag when entry.value < 0. Defaults to const {}.
  final Map<String, double> itemTaxExtraByName;
  final Map<String, double> itemDiscountExtraByName;
  final double total;
  final String totalLabel;

  final String notes;
  final PdfColor accent;
  final String thankYouLabel;

  const PdfDocData({
    required this.docTypeLabel,
    required this.docNumber,
    required this.recipientLabel,
    required this.businessName,
    required this.businessEmail,
    required this.businessPhone,
    required this.businessAddress,
    this.logoImage,
    this.logoShape = 'roundedSquare',
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
    required this.notes,
    required this.accent,
    required this.thankYouLabel,
  });

  /// PDF-side twin of DocTemplateAdapter.fmtMoney() (Flutter preview side)
  /// — same logic, so exported PDFs render money identically to what the
  /// user saw in the preview before exporting.
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

// ── Color mapping (shared across all three converters) ─────────────────────

PdfColor pdfColorForInvoice(InvoiceColor c) {
  switch (c) {
    case InvoiceColor.blue: return PdfColors.blue800;
    case InvoiceColor.green: return PdfColors.green800;
    case InvoiceColor.purple: return PdfColors.purple800;
    case InvoiceColor.orange: return PdfColors.orange800;
    case InvoiceColor.red: return PdfColors.red800;
    case InvoiceColor.teal: return PdfColors.teal800;
    case InvoiceColor.black: return PdfColors.grey900;
    case InvoiceColor.indigo: return PdfColors.indigo800;
  }
}

PdfColor pdfColorForQuote(QuoteColor c) {
  switch (c) {
    case QuoteColor.blue: return PdfColors.blue800;
    case QuoteColor.green: return PdfColors.green800;
    case QuoteColor.purple: return PdfColors.purple800;
    case QuoteColor.orange: return PdfColors.orange800;
    case QuoteColor.red: return PdfColors.red800;
    case QuoteColor.teal: return PdfColors.teal800;
    case QuoteColor.black: return PdfColors.grey900;
    case QuoteColor.indigo: return PdfColors.indigo800;
  }
}

PdfColor pdfColorForReceipt(ReceiptColor c) {
  switch (c) {
    case ReceiptColor.blue: return PdfColors.blue800;
    case ReceiptColor.green: return PdfColors.green800;
    case ReceiptColor.purple: return PdfColors.purple800;
    case ReceiptColor.orange: return PdfColors.orange800;
    case ReceiptColor.red: return PdfColors.red800;
    case ReceiptColor.teal: return PdfColors.teal800;
    case ReceiptColor.black: return PdfColors.grey900;
    case ReceiptColor.indigo: return PdfColors.indigo800;
  }
}

// ── Status label/color helpers ──────────────────────────────────────────────

PdfColor _invoiceStatusColor(PaymentStatus s) => switch (s) {
      PaymentStatus.paid => PdfColors.green700,
      PaymentStatus.partial => PdfColors.orange700,
      PaymentStatus.overdue => PdfColors.red700,
      PaymentStatus.unpaid => PdfColors.grey600,
    };

String _invoiceStatusLabel(PaymentStatus s) => switch (s) {
      PaymentStatus.paid => 'PAID',
      PaymentStatus.partial => 'PARTIALLY PAID',
      PaymentStatus.overdue => 'OVERDUE',
      PaymentStatus.unpaid => 'UNPAID',
    };

PdfColor _quoteStatusColor(QuoteStatus s) => switch (s) {
      QuoteStatus.accepted => PdfColors.green700,
      QuoteStatus.sent => PdfColors.blue700,
      QuoteStatus.declined => PdfColors.red700,
      QuoteStatus.expired => PdfColors.orange700,
      QuoteStatus.draft => PdfColors.grey600,
    };

String _quoteStatusLabel(QuoteStatus s) => switch (s) {
      QuoteStatus.accepted => 'ACCEPTED',
      QuoteStatus.sent => 'SENT',
      QuoteStatus.declined => 'DECLINED',
      QuoteStatus.expired => 'EXPIRED',
      QuoteStatus.draft => 'DRAFT',
    };

PdfColor _receiptStatusColor(ReceiptStatus s) => switch (s) {
      ReceiptStatus.issued => PdfColors.green700,
      ReceiptStatus.refunded => PdfColors.red700,
    };

String _receiptStatusLabel(ReceiptStatus s) => switch (s) {
      ReceiptStatus.issued => 'ISSUED',
      ReceiptStatus.refunded => 'REFUNDED',
    };

String _paymentMethodLabel(PaymentMethod m) => switch (m) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.card => 'Card',
      PaymentMethod.bankTransfer => 'Bank Transfer',
      PaymentMethod.other => 'Other',
    };

Future<pw.MemoryImage?> _loadLogo(String? path) async {
  if (path == null || path.isEmpty) return null;
  final f = File(path);
  if (await f.exists()) {
    return pw.MemoryImage(await f.readAsBytes());
  }
  return null;
}

// ── Conversion functions ────────────────────────────────────────────────────

Future<PdfDocData> invoiceToPdfData(InvoiceData d) async => PdfDocData(
      docTypeLabel: 'INVOICE',
      docNumber: d.invoiceNumber,
      recipientLabel: 'BILLED TO',
      businessName: d.businessName,
      businessEmail: d.businessEmail,
      businessPhone: d.businessPhone,
      businessAddress: d.businessAddress,
      logoImage: await _loadLogo(d.businessLogoPath),
      logoShape: d.businessLogoShape,
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
      // SHARED/EXECUTIVE PARITY PASS — PDF SIDE: grouped-by-name
      // breakdown, straight pass-through from InvoiceData's own getter.
      itemTaxExtraByName: d.itemTaxExtraByName,
      itemDiscountExtraByName: d.itemDiscountExtraByName,
      total: d.grandTotal,
      totalLabel: 'Grand Total',
      notes: d.notes,
      accent: pdfColorForInvoice(d.colorScheme),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for your business - ${d.businessEmail}'
          : 'Thank you for your business',
    );

Future<PdfDocData> quoteToPdfData(QuoteData d) async => PdfDocData(
      docTypeLabel: 'QUOTE',
      docNumber: d.quoteNumber,
      recipientLabel: 'PREPARED FOR',
      businessName: d.businessName,
      businessEmail: d.businessEmail,
      businessPhone: d.businessPhone,
      businessAddress: d.businessAddress,
      logoImage: await _loadLogo(d.businessLogoPath),
      logoShape: d.businessLogoShape,
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
      // SHARED/EXECUTIVE PARITY PASS — PDF SIDE: QuoteData carries the
      // same itemTaxExtra/itemDiscountExtra flat getters AND the same
      // grouped-by-name itemTaxExtraByName/itemDiscountExtraByName
      // getters Invoice does — previously none of these four were
      // passed here, so a quote PDF using per-item tax/discount showed
      // no breakdown for it at all.
      itemTaxExtra: d.itemTaxExtra,
      itemDiscountExtra: d.itemDiscountExtra,
      itemTaxExtraByName: d.itemTaxExtraByName,
      itemDiscountExtraByName: d.itemDiscountExtraByName,
      total: d.grandTotal,
      totalLabel: 'Total',
      notes: d.notes,
      accent: pdfColorForQuote(d.colorScheme),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for considering us - ${d.businessEmail}'
          : 'Thank you for considering us',
    );

Future<PdfDocData> receiptToPdfData(ReceiptData d) async => PdfDocData(
      docTypeLabel: 'RECEIPT',
      docNumber: d.receiptNumber,
      recipientLabel: 'RECEIVED FROM',
      businessName: d.businessName,
      businessEmail: d.businessEmail,
      businessPhone: d.businessPhone,
      businessAddress: d.businessAddress,
      logoImage: await _loadLogo(d.businessLogoPath),
      logoShape: d.businessLogoShape,
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
      // SHARED/EXECUTIVE PARITY PASS — PDF SIDE: ReceiptData carries the
      // same four getters Invoice/Quote do — previously none of these
      // four were passed here.
      itemTaxExtra: d.itemTaxExtra,
      itemDiscountExtra: d.itemDiscountExtra,
      itemTaxExtraByName: d.itemTaxExtraByName,
      itemDiscountExtraByName: d.itemDiscountExtraByName,
      total: d.amountPaid,
      totalLabel: 'Amount Paid',
      notes: d.notes,
      accent: pdfColorForReceipt(d.colorScheme),
      thankYouLabel: d.businessEmail.isNotEmpty
          ? 'Thank you for your payment - ${d.businessEmail}'
          : 'Thank you for your payment',
    );