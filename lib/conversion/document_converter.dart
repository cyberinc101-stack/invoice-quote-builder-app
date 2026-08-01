// lib/conversion/document_converter.dart
//
// Pure conversion functions for turning one document type's data into
// another's, used by the "Convert to..." action in
// saved_document_detail_screen.dart. These only build new *Data objects —
// saving them as SavedInvoice/SavedReceipt entries happens via
// InvoiceProvider.addConvertedInvoice / ReceiptProvider.addConvertedReceipt,
// so the currently-open editor draft is never touched.
//
// FLAG: issueDate/paymentDate/dueDate are plain free-text String fields on
// InvoiceData/QuoteData/ReceiptData (not DateTime) — the exact format your
// date-picker screens write isn't visible from the model files alone, so
// _todayString()/_addDaysString() below use a "1 Aug 2026" style format,
// matching the display formatter already used in
// saved_document_detail_screen.dart's _formatDate(). If your create-screens
// write dates differently, this is the one place to change it.

import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dateString(DateTime dt) => '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

String _todayString() => _dateString(DateTime.now());

String _addDaysString(int days) => _dateString(DateTime.now().add(Duration(days: days)));

/// Swaps a recognizable "QT-"/"Q-" prefix for "INV-"; otherwise appends
/// "-INV" so the new number is still distinguishable from the source quote.
String _deriveInvoiceNumber(String quoteNumber) {
  if (quoteNumber.isEmpty) return '';
  final upper = quoteNumber.toUpperCase();
  if (upper.startsWith('QT-')) return 'INV-${quoteNumber.substring(3)}';
  if (upper.startsWith('Q-')) return 'INV-${quoteNumber.substring(2)}';
  return '$quoteNumber-INV';
}

/// Same idea as _deriveInvoiceNumber but for Invoice -> Receipt.
String _deriveReceiptNumber(String invoiceNumber) {
  if (invoiceNumber.isEmpty) return '';
  final upper = invoiceNumber.toUpperCase();
  if (upper.startsWith('INV-')) return 'RC-${invoiceNumber.substring(4)}';
  return '$invoiceNumber-RC';
}

InvoiceColor _invoiceColorFromQuoteColor(QuoteColor c) => InvoiceColor.values.firstWhere(
      (v) => v.name == c.name,
      orElse: () => InvoiceColor.blue,
    );

ReceiptColor _receiptColorFromInvoiceColor(InvoiceColor c) => ReceiptColor.values.firstWhere(
      (v) => v.name == c.name,
      orElse: () => ReceiptColor.green,
    );

/// Builds a fresh InvoiceData from an existing quote's data. Client info,
/// business info, line items, notes, tax rate and discount rate all carry
/// over untouched. invoiceNumber/issueDate/dueDate/paymentStatus are reset
/// to invoice-appropriate defaults since they don't make sense carried over
/// 1:1 from a quote.
InvoiceData convertQuoteDataToInvoiceData(QuoteData quote) {
  return InvoiceData(
    businessName: quote.businessName,
    businessEmail: quote.businessEmail,
    businessPhone: quote.businessPhone,
    businessAddress: quote.businessAddress,
    businessLogoPath: quote.businessLogoPath,
    clientName: quote.clientName,
    clientEmail: quote.clientEmail,
    clientPhone: quote.clientPhone,
    clientAddress: quote.clientAddress,
    invoiceNumber: _deriveInvoiceNumber(quote.quoteNumber),
    issueDate: _todayString(),
    dueDate: _addDaysString(14),
    notes: quote.notes,
    currency: quote.currency,
    lineItems: quote.lineItems.map((i) => i.copyWith()).toList(),
    taxRate: quote.taxRate,
    discountRate: quote.discountRate,
    paymentStatus: PaymentStatus.unpaid,
    fontFamily: quote.fontFamily,
    colorScheme: _invoiceColorFromQuoteColor(quote.colorScheme),
  );
}

/// Builds a fresh ReceiptData from an existing invoice's data (typically
/// one that's just been marked paid). paymentMethod defaults to cash since
/// InvoiceData has no equivalent field to carry over — change the default
/// below, or add a picker in the UI before saving, if you'd rather ask the
/// user at convert time.
ReceiptData convertInvoiceDataToReceiptData(InvoiceData invoice) {
  return ReceiptData(
    businessName: invoice.businessName,
    businessEmail: invoice.businessEmail,
    businessPhone: invoice.businessPhone,
    businessAddress: invoice.businessAddress,
    businessLogoPath: invoice.businessLogoPath,
    clientName: invoice.clientName,
    clientEmail: invoice.clientEmail,
    clientPhone: invoice.clientPhone,
    clientAddress: invoice.clientAddress,
    receiptNumber: _deriveReceiptNumber(invoice.invoiceNumber),
    paymentDate: _todayString(),
    notes: invoice.notes,
    currency: invoice.currency,
    lineItems: invoice.lineItems.map((i) => i.copyWith()).toList(),
    taxRate: invoice.taxRate,
    discountRate: invoice.discountRate,
    paymentMethod: PaymentMethod.cash,
    status: ReceiptStatus.issued,
    fontFamily: invoice.fontFamily,
    colorScheme: _receiptColorFromInvoiceColor(invoice.colorScheme),
  );
}
