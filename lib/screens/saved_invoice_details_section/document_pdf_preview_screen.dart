// lib/screens/saved_invoice_details_section/document_pdf_preview_screen.dart
//
// THERMAL PREVIEW BUG FIX PASS (this update): the real-template path for
// receipts always rendered via buildReceiptPreview() (the A4 design
// registry) wrapped in ScaledPageStack — same bug fixed in
// create_receipt_screen.dart's Live Preview card and
// receipt_full_preview_screen.dart's Preview screen. This is the third
// and final occurrence: _buildRealTemplateBody now checks
// receiptData!.paperFormat first and, when thermal, renders
// ThermalReceiptLivePreview via FittedBox (ScaledPageStack assumes a
// fixed A4 aspect ratio, which doesn't apply to a variable-length thermal
// roll) instead of falling into the invoice/quote/receipt A4 switch below.
//
// Full-screen "how this would look as a downloaded PDF" preview.
// One shared screen for Invoice / Quote / Receipt (see design rationale in
// saved_document_detail_screen.dart) — takes plain values only, no
// dependency on SavedInvoice/SavedQuote/SavedReceipt models, so it works for
// both real saved documents AND demo placeholder documents with zero
// branching logic.
//
// Invoices/quotes/receipts take an optional [invoiceData]/[quoteData]/
// [receiptData] (the real model for the document being viewed). When
// supplied, this screen renders the SAME preview pipeline used by each
// type's own full-preview screen — real page proportions and pixel-
// accurate match to both the Edit screen and the exported PDF. The
// "DUMMY PREVIEW" badge and mockup disclaimer only show when none of
// those are supplied.
//
// Save / Download / Share logic is UNCHANGED — both buttons call back
// into the SAME onDownloadPdf/onSharePdf callbacks passed in from
// saved_document_detail_screen.dart.

import 'package:flutter/material.dart';
import '../../widgets/saved_documents_containers.dart'
    show DocType, kInvoiceAccent, kQuoteAccent, kReceiptAccent;
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../document_layout_templates/01_executive/executive_invoice_logic_data.dart';
import '../../document_layout_templates/01_executive/executive_quote_logic_data.dart';
import '../../document_layout_templates/01_executive/executive_receipt_logic_data.dart';
import '../../document_layout_templates/01_executive/executive_invoice_stationary_layout.dart'
    show kPageW;
import '../../document_layout_templates/pagination/scaled_page_stack.dart';
import '../invoice_create_section/invoice_template_previews/preview_registry.dart'
    show buildInvoicePreview;
import '../create_quote_section/quote_template_chooser_01/preview_registry.dart'
    show buildQuotePreview;
import '../../create_receipt/receipt_template_chooser_01/preview_registry.dart'
    show buildReceiptPreview;
import '../../create_receipt/receipt_paper_format.dart';
import '../../create_receipt/receipt_thermal_live_preview.dart';

// -----------------------------------------------------------------------------
// PdfPreviewLineItem — plain line item shape, no model dependency
// (still used by the quote/receipt mockup fallback below)
// -----------------------------------------------------------------------------
class PdfPreviewLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  const PdfPreviewLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

// -----------------------------------------------------------------------------
// DocumentPdfPreviewScreen
// -----------------------------------------------------------------------------
class DocumentPdfPreviewScreen extends StatelessWidget {
  final DocType type;
  final String documentTitle;
  final String businessName;
  final String clientName;
  final String primaryDate;
  final String? secondaryDateLabel;
  final String? secondaryDate;
  final String currency;
  final List<PdfPreviewLineItem> items;
  final double total;
  final String notes;

  // NEW: the real invoice data, when available. When non-null (invoices
  // only, for now), the real A4 Executive template renders instead of the
  // generic mockup below.
  final InvoiceData? invoiceData;

  // Same idea as invoiceData, for quotes and receipts.
  final QuoteData? quoteData;
  final ReceiptData? receiptData;

  // Optional export actions. When provided (currently wired for all three
  // types — see saved_document_detail_screen.dart), tapping the button
  // runs the real PDF export. When null, tapping shows a "not built yet"
  // snackbar instead, so previews don't silently do nothing.
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onSharePdf;

  const DocumentPdfPreviewScreen({
    super.key,
    required this.type,
    required this.documentTitle,
    required this.businessName,
    required this.clientName,
    required this.primaryDate,
    this.secondaryDateLabel,
    this.secondaryDate,
    required this.currency,
    required this.items,
    required this.total,
    required this.notes,
    this.invoiceData,
    this.quoteData,
    this.receiptData,
    this.onDownloadPdf,
    this.onSharePdf,
  });

  bool get _usesRealTemplate {
    switch (type) {
      case DocType.invoice:
        return invoiceData != null;
      case DocType.quote:
        return quoteData != null;
      case DocType.receipt:
        return receiptData != null;
    }
  }

  // Thermal receipts don't fit the A4-shaped real-template pipeline below
  // (fixed page width/height, ScaledPageStack) — they get their own
  // variable-length branch in _buildRealTemplateBody.
  bool get _isThermalReceipt =>
      type == DocType.receipt &&
      receiptData != null &&
      receiptPaperFormatFromString(receiptData!.paperFormat).isThermal;

  Color get _accent {
    switch (type) {
      case DocType.invoice:
        return kInvoiceAccent;
      case DocType.quote:
        return kQuoteAccent;
      case DocType.receipt:
        return kReceiptAccent;
    }
  }

  String get _docLabel {
    switch (type) {
      case DocType.invoice:
        return 'INVOICE';
      case DocType.quote:
        return 'QUOTE';
      case DocType.receipt:
        return 'RECEIPT';
    }
  }

  String get _clientBlockLabel {
    switch (type) {
      case DocType.invoice:
        return 'Bill To';
      case DocType.quote:
        return 'Quote For';
      case DocType.receipt:
        return 'Received From';
    }
  }

  String get _primaryDateLabel {
    switch (type) {
      case DocType.invoice:
        return 'Issue Date';
      case DocType.quote:
        return 'Issue Date';
      case DocType.receipt:
        return 'Payment Date';
    }
  }

  String get _totalLabel {
    switch (type) {
      case DocType.invoice:
        return 'Total Due';
      case DocType.quote:
        return 'Estimated Total';
      case DocType.receipt:
        return 'Amount Paid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2D3A),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('PDF Preview', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          // Only shown for the generic mockup path — every real-template
          // path (A4 or thermal) matches the actual export exactly, so no
          // disclaimer badge.
          if (!_usesRealTemplate)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DUMMY PREVIEW',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _usesRealTemplate ? _buildRealTemplateBody(context) : _buildMockupBody(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── Real template path (invoices/quotes/receipts with data supplied) ─────

  Widget _buildRealTemplateBody(BuildContext context) {
    // Thermal receipts: variable-length roll, not a fixed A4 page — render
    // via the same live-data thermal widget used on the Review step and
    // the receipt Preview screen, scaled with FittedBox rather than the
    // A4-shaped ScaledPageStack below.
    if (_isThermalReceipt) {
      final format = receiptPaperFormatFromString(receiptData!.paperFormat);
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: format.widthMm * 4.2,
              child: ThermalReceiptLivePreview(data: receiptData!, widthMm: format.widthMm),
            ),
          ),
        ),
      );
    }

    final screenW = MediaQuery.of(context).size.width;
    final targetWidth = (screenW - 32).clamp(200.0, kPageW);

    // Dispatches on the document's own chosen design (Executive/Nordic/
    // Vibrant/etc — see the relevant preview_registry.dart) instead of
    // always rendering Executive, so this preview matches whatever was
    // picked in the template chooser for that document type.
    final Widget preview;
    switch (type) {
      case DocType.invoice:
        final data = invoiceData!;
        preview = buildInvoicePreview(data.layoutTemplateId, data) ??
            ExecutiveInvoicePreview(data: data);
        break;
      case DocType.quote:
        final data = quoteData!;
        preview = buildQuotePreview(data.layoutTemplateId, data) ??
            ExecutiveQuotePreview(data: data);
        break;
      case DocType.receipt:
        final data = receiptData!;
        preview = buildReceiptPreview(data.layoutTemplateId, data) ??
            ExecutiveReceiptPreview(data: data);
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: ScaledPageStack(
          targetWidth: targetWidth,
          nativePageWidth: kPageW,
          child: preview,
        ),
      ),
    );
  }

  // ── Generic mockup path (quote/receipt, or invoices with no data) ───────

  Widget _buildMockupBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12)),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                _buildClientAndDates(),
                const SizedBox(height: 26),
                _buildItemsTable(),
                const SizedBox(height: 18),
                _buildTotals(),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _buildFooterNote(),
                ],
                const SizedBox(height: 8),
                _buildBottomDisclaimer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Download / Share bar. Equal-width buttons so neither reads as more
  // "correct" than the other — Share filled (most common action), Download
  // outlined.
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2B2D3A),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _PreviewActionButton(
              label: 'Download',
              icon: Icons.download_rounded,
              filled: false,
              accent: _accent,
              onTap: () => _handleAction(context, onDownloadPdf),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PreviewActionButton(
              label: 'Share',
              icon: Icons.ios_share_rounded,
              filled: true,
              accent: _accent,
              onTap: () => _handleAction(context, onSharePdf),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, VoidCallback? action) {
    if (action != null) {
      action();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('PDF export for this document type isn\'t built yet.'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessName.isEmpty ? 'Your Business' : businessName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 4),
              Text(documentTitle, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.45))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(6)),
          child: Text(
            _docLabel,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildClientAndDates() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _clientBlockLabel.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black.withValues(alpha: 0.4), letterSpacing: 0.6),
              ),
              const SizedBox(height: 6),
              Text(
                clientName.isEmpty ? '—' : clientName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDateLine(_primaryDateLabel, primaryDate),
              if (secondaryDateLabel != null && secondaryDate != null) ...[
                const SizedBox(height: 6),
                _buildDateLine(secondaryDateLabel!, secondaryDate!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black.withValues(alpha: 0.4), letterSpacing: 0.6),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _accent, width: 2))),
          child: Row(
            children: [
              Expanded(flex: 5, child: Text('DESCRIPTION', style: _thStyle())),
              Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.right, style: _thStyle())),
              Expanded(flex: 3, child: Text('PRICE', textAlign: TextAlign.right, style: _thStyle())),
              Expanded(flex: 3, child: Text('TOTAL', textAlign: TextAlign.right, style: _thStyle())),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text('No line items', style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.4))),
          )
        else
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)))),
              child: Row(
                children: [
                  Expanded(flex: 5, child: Text(item.description, style: _tdStyle())),
                  Expanded(flex: 2, child: Text(_fmtNum(item.quantity), textAlign: TextAlign.right, style: _tdStyle())),
                  Expanded(
                    flex: 3,
                    child: Text('$currency ${item.unitPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: _tdStyle()),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('$currency ${item.total.toStringAsFixed(2)}', textAlign: TextAlign.right, style: _tdStyle(bold: true)),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  String _fmtNum(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  TextStyle _thStyle() =>
      TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black.withValues(alpha: 0.45), letterSpacing: 0.4);

  TextStyle _tdStyle({bool bold = false}) =>
      TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: const Color(0xFF1A1A2E));

  Widget _buildTotals() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(color: _accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _totalLabel.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _accent, letterSpacing: 0.4),
            ),
            Text(
              '$currency ${total.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FC), borderRadius: BorderRadius.circular(8)),
      child: Text(notes, style: TextStyle(fontSize: 11.5, color: Colors.black.withValues(alpha: 0.55), height: 1.4)),
    );
  }

  Widget _buildBottomDisclaimer() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Layout mockup only — not your final PDF template.',
        style: TextStyle(fontSize: 10, color: Colors.black.withValues(alpha: 0.3), fontStyle: FontStyle.italic),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _PreviewActionButton — equal-size Download/Share buttons for the dark
// preview screen's bottom bar
// -----------------------------------------------------------------------------
class _PreviewActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final Color accent;
  final VoidCallback onTap;

  const _PreviewActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: filled ? accent : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
