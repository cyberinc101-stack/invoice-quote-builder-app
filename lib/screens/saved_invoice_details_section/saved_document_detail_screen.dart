// lib/screens/saved_invoice_details_section/saved_document_detail_screen.dart
//
// One unified screen for SavedInvoice / SavedQuote / SavedReceipt, matched to
// the shape of those models exactly as defined in lib/models/*.dart.
//
// ── STATUS ──────────────────────────────────────────────────────────────
// Rename/delete call the REAL provider methods (confirmed against
// invoice_provider.dart / quote_provider.dart / receipt_provider.dart):
//   Invoice: renameInvoice(id, title) / deleteInvoice(id)
//   Quote:   renameQuote(id, title)   / deleteQuote(id)
//   Receipt: renameSavedReceipt(id, title) / deleteSavedReceipt(id)
//
// SavedDocumentDetailScreen.demo(...) — a second entry point for UI-preview
// purposes while still in the design phase. Takes plain values instead of
// SavedInvoice/SavedQuote/SavedReceipt, so it has zero dependency on those
// model constructors or on InvoiceProvider/QuoteProvider/ReceiptProvider.
// When isDemo is true, _liveState() returns the demo values directly (no
// provider reads at all) and Edit/Rename/Delete/Convert all just show a
// "this is a demo" snackbar instead of touching a provider. Full Preview
// works for BOTH demo and real documents.
//
// FIX (this pass): Edit is now FULLY WIRED for all three document types.
// Previously Invoice Edit was stubbed with a "wiring pending" snackbar,
// Quote Edit was stubbed with "not built yet", and Receipt Edit routed to
// CreateReceiptScreen(existingReceiptId:...) with an assumed constructor
// param. All three now route to a dedicated tap-to-edit canvas screen:
//   Invoice -> InvoiceEditableCanvasScreen(invoiceId: ...)
//   Quote   -> QuoteEditableCanvasScreen(quoteId: ...)
//   Receipt -> ReceiptEditableCanvasScreen(receiptId: ...)
// Each canvas seeds its provider's draft from the saved record on open,
// edits live via the provider, and only writes back to the saved list on
// Save. Back/cancel discards cleanly. See each canvas file's header comment
// for exact per-type mechanics (Receipt's provider only exposes a single
// updateReceiptData() method rather than granular update*() methods, so its
// canvas uses a local copyWith-based helper instead).
//
// FIX (this pass, cont.): removed the now-unused CreateReceiptScreen import
// — Receipt editing no longer routes there.
//
// FIX (latest pass): Activity card now shows a "Paid" row (green, check-
// circle icon) whenever an invoice's InvoiceData.paidDate is set — i.e. the
// invoice's status is currently Paid. Sourced through the same _liveState()
// normalization used for every other date on this screen; quotes/receipts/
// demo always pass paidDate: null since only InvoiceData tracks it.
//
// Everything below this point (PDF/export/convert/rename/delete/options
// sheet) is unchanged from the previous pass.
//
// Real PDF export wired in. Options sheet has "Download PDF" / "Share PDF"
// alongside Rename/Delete, calling the real InvoicePdfService
// (lib/services/invoice_pdf_service.dart) against the live SavedInvoice.
// Scoped to invoices only for now — quote/receipt PDF export isn't built.
//
// "Convert to Invoice" (on quotes) / "Convert to Receipt" (on invoices) in
// the "⋮" options sheet. Conversion logic lives in
// lib/conversion/document_converter.dart; this screen calls it, saves via
// InvoiceProvider.addConvertedInvoice / ReceiptProvider.addConvertedReceipt,
// and navigates to the new saved document's detail screen.
//
// "Export as Excel" / "Export as CSV" in the "⋮" options sheet, via
// InvoiceExportService — invoice-only for now, same scoping as PDF export.
//
// Still open:
// 1. The preview card is a generic branded summary, not a pixel-accurate
//    render of your real invoice/quote/receipt layout templates.
// 2. Quote/Receipt PDF and spreadsheet export not built — Download/Share
//    PDF and Export XLSX/CSV only work for invoices right now.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../services/invoice_pdf_service.dart';
import '../../export/invoice_export_service.dart';
import '../../conversion/document_converter.dart';
import '../../widgets/saved_documents_containers.dart'
    show DocType, kInvoiceAccent, kQuoteAccent, kReceiptAccent;
import 'document_detail_widgets.dart';
import 'document_pdf_preview_screen.dart';
import 'invoice_editable_canvas_screen.dart';
import 'quote_editable_canvas_screen.dart';
import 'receipt_editable_canvas_screen.dart';

// -----------------------------------------------------------------------------
// Small per-type status mapping (duplicated intentionally from
// saved_documents_containers.dart, since those helpers are private there)
// -----------------------------------------------------------------------------

({String label, Color color, IconData icon}) _invoiceStatusInfo(PaymentStatus s) {
  switch (s) {
    case PaymentStatus.paid:
      return (label: 'Paid', color: const Color(0xFF4CAF50), icon: Icons.check_circle_rounded);
    case PaymentStatus.partial:
      return (label: 'Partial', color: const Color(0xFF2196F3), icon: Icons.timelapse_rounded);
    case PaymentStatus.overdue:
      return (label: 'Overdue', color: const Color(0xFFE53935), icon: Icons.error_rounded);
    case PaymentStatus.unpaid:
      return (label: 'Unpaid', color: const Color(0xFFFF9800), icon: Icons.schedule_rounded);
  }
}

({String label, Color color, IconData icon}) _quoteStatusInfo(QuoteStatus s) {
  switch (s) {
    case QuoteStatus.accepted:
      return (label: 'Accepted', color: const Color(0xFF4CAF50), icon: Icons.check_circle_rounded);
    case QuoteStatus.sent:
      return (label: 'Sent', color: const Color(0xFF2196F3), icon: Icons.send_rounded);
    case QuoteStatus.declined:
      return (label: 'Declined', color: const Color(0xFFE53935), icon: Icons.cancel_rounded);
    case QuoteStatus.expired:
      return (label: 'Expired', color: const Color(0xFF9E9E9E), icon: Icons.event_busy_rounded);
    case QuoteStatus.draft:
      return (label: 'Draft', color: const Color(0xFFFF9800), icon: Icons.edit_rounded);
  }
}

({String label, Color color, IconData icon}) _receiptStatusInfo(ReceiptStatus s) {
  switch (s) {
    case ReceiptStatus.issued:
      return (label: 'Issued', color: const Color(0xFF4CAF50), icon: Icons.check_circle_rounded);
    case ReceiptStatus.refunded:
      return (label: 'Refunded', color: const Color(0xFFE53935), icon: Icons.replay_rounded);
  }
}

String _formatDate(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1)  return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours   < 24) return '${diff.inHours}h ago';
  if (diff.inDays    == 1) return 'Yesterday';
  if (diff.inDays    <  7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

IconData _typeIcon(DocType type) {
  switch (type) {
    case DocType.invoice: return Icons.receipt_long_rounded;
    case DocType.quote:   return Icons.request_quote_rounded;
    case DocType.receipt: return Icons.receipt_rounded;
  }
}

String _typeLabel(DocType type) {
  switch (type) {
    case DocType.invoice: return 'Invoice';
    case DocType.quote:   return 'Quote';
    case DocType.receipt: return 'Receipt';
  }
}

// -----------------------------------------------------------------------------
// DemoLineItem — plain line item shape for .demo(), no model dependency
// -----------------------------------------------------------------------------

class DemoLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  const DemoLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });
  double get total => quantity * unitPrice;
}

// -----------------------------------------------------------------------------
// SavedDocumentDetailScreen
// -----------------------------------------------------------------------------

class SavedDocumentDetailScreen extends StatefulWidget {
  final DocType type;
  final SavedInvoice? invoice;
  final SavedQuote? quote;
  final SavedReceipt? receipt;

  // Demo-mode fields — only populated when constructed via .demo()
  final bool isDemo;
  final String? demoTitle;
  final String? demoTemplateName;
  final String? demoStatusLabel;
  final Color? demoStatusColor;
  final IconData? demoStatusIcon;
  final double? demoTotal;
  final String? demoCurrency;
  final String? demoBusinessName;
  final String? demoClientName;
  final String? demoPrimaryDate;
  final String? demoSecondaryDateLabel;
  final String? demoSecondaryDate;
  final String? demoNotes;
  final List<DemoLineItem>? demoItems;
  final DateTime? demoCreatedAt;
  final DateTime? demoLastEditedAt;

  const SavedDocumentDetailScreen._({
    required this.type,
    this.invoice,
    this.quote,
    this.receipt,
    this.isDemo = false,
    this.demoTitle,
    this.demoTemplateName,
    this.demoStatusLabel,
    this.demoStatusColor,
    this.demoStatusIcon,
    this.demoTotal,
    this.demoCurrency,
    this.demoBusinessName,
    this.demoClientName,
    this.demoPrimaryDate,
    this.demoSecondaryDateLabel,
    this.demoSecondaryDate,
    this.demoNotes,
    this.demoItems,
    this.demoCreatedAt,
    this.demoLastEditedAt,
  });

  factory SavedDocumentDetailScreen.invoice(SavedInvoice invoice) =>
      SavedDocumentDetailScreen._(type: DocType.invoice, invoice: invoice);

  factory SavedDocumentDetailScreen.quote(SavedQuote quote) =>
      SavedDocumentDetailScreen._(type: DocType.quote, quote: quote);

  factory SavedDocumentDetailScreen.receipt(SavedReceipt receipt) =>
      SavedDocumentDetailScreen._(type: DocType.receipt, receipt: receipt);

  /// UI-preview-only entry point — no SavedInvoice/Quote/Receipt or provider
  /// dependency at all. For opening this screen from the placeholder demo
  /// cards while there are no real saved documents yet.
  factory SavedDocumentDetailScreen.demo({
    required DocType type,
    required String title,
    required String templateName,
    required String statusLabel,
    required Color statusColor,
    required IconData statusIcon,
    required double total,
    required String currency,
    required String businessName,
    required String clientName,
    required String primaryDate,
    String? secondaryDateLabel,
    String? secondaryDate,
    required String notes,
    required List<DemoLineItem> items,
    required DateTime createdAt,
    required DateTime lastEditedAt,
  }) =>
      SavedDocumentDetailScreen._(
        type: type,
        isDemo: true,
        demoTitle: title,
        demoTemplateName: templateName,
        demoStatusLabel: statusLabel,
        demoStatusColor: statusColor,
        demoStatusIcon: statusIcon,
        demoTotal: total,
        demoCurrency: currency,
        demoBusinessName: businessName,
        demoClientName: clientName,
        demoPrimaryDate: primaryDate,
        demoSecondaryDateLabel: secondaryDateLabel,
        demoSecondaryDate: secondaryDate,
        demoNotes: notes,
        demoItems: items,
        demoCreatedAt: createdAt,
        demoLastEditedAt: lastEditedAt,
      );

  @override
  State<SavedDocumentDetailScreen> createState() => _SavedDocumentDetailScreenState();
}

class _SavedDocumentDetailScreenState extends State<SavedDocumentDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late String _currentTitle;

  Color get _accent {
    switch (widget.type) {
      case DocType.invoice: return kInvoiceAccent;
      case DocType.quote:   return kQuoteAccent;
      case DocType.receipt: return kReceiptAccent;
    }
  }

  String get _id {
    if (widget.isDemo) return 'demo';
    switch (widget.type) {
      case DocType.invoice: return widget.invoice!.id;
      case DocType.quote:   return widget.quote!.id;
      case DocType.receipt: return widget.receipt!.id;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.isDemo
        ? widget.demoTitle!
        : switch (widget.type) {
            DocType.invoice => widget.invoice!.title,
            DocType.quote   => widget.quote!.title,
            DocType.receipt => widget.receipt!.title,
          };
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Re-reads the freshest saved copy from the provider's list (not a getById
  // call, since that method isn't confirmed to exist — the list itself is
  // confirmed, from saved_documents_containers.dart). In demo mode, skips
  // providers entirely and returns the plain demo values passed to .demo().
  //
  // FIX (this pass): added `paidDate` to the state shape — only ever
  // non-null for a paid invoice (sourced from InvoiceData.paidDate); quotes,
  // receipts, and demo documents always pass null since only invoices track
  // a paid timestamp.
  ({String title, String templateName, DateTime createdAt, DateTime lastEditedAt,
    int completionPercent, String statusLabel, Color statusColor, IconData statusIcon,
    double total, String currency, List<({String desc, double qty, double unitPrice, double total})> items,
    String businessName, String clientName, String primaryDate, String? secondaryDateLabel,
    String? secondaryDate, String notes, DateTime? paidDate})
      _liveState(BuildContext context) {
    if (widget.isDemo) {
      return (
        title: widget.demoTitle!,
        templateName: widget.demoTemplateName!,
        createdAt: widget.demoCreatedAt!,
        lastEditedAt: widget.demoLastEditedAt!,
        completionPercent: 100,
        statusLabel: widget.demoStatusLabel!,
        statusColor: widget.demoStatusColor!,
        statusIcon: widget.demoStatusIcon!,
        total: widget.demoTotal!,
        currency: widget.demoCurrency!,
        items: widget.demoItems!
            .map((i) => (desc: i.description, qty: i.quantity, unitPrice: i.unitPrice, total: i.total))
            .toList(),
        businessName: widget.demoBusinessName!,
        clientName: widget.demoClientName!,
        primaryDate: widget.demoPrimaryDate!,
        secondaryDateLabel: widget.demoSecondaryDateLabel,
        secondaryDate: widget.demoSecondaryDate,
        notes: widget.demoNotes!,
        paidDate: null,
      );
    }

    switch (widget.type) {
      case DocType.invoice:
        final list = context.watch<InvoiceProvider>().savedInvoices;
        final inv = list.firstWhere((i) => i.id == widget.invoice!.id, orElse: () => widget.invoice!);
        final info = _invoiceStatusInfo(inv.data.paymentStatus);
        return (
          title: inv.title,
          templateName: inv.templateName,
          createdAt: inv.createdAt,
          lastEditedAt: inv.lastEditedAt,
          completionPercent: inv.completionPercent,
          statusLabel: info.label, statusColor: info.color, statusIcon: info.icon,
          total: inv.data.grandTotal,
          currency: inv.data.currency,
          items: inv.data.lineItems
              .map((i) => (desc: i.description, qty: i.quantity, unitPrice: i.unitPrice, total: i.total))
              .toList(),
          businessName: inv.data.businessName,
          clientName: inv.data.clientName,
          primaryDate: inv.data.issueDate,
          secondaryDateLabel: 'Due',
          secondaryDate: inv.data.dueDate,
          notes: inv.data.notes,
          paidDate: inv.data.paidDate,
        );
      case DocType.quote:
        final list = context.watch<QuoteProvider>().savedQuotes;
        final q = list.firstWhere((i) => i.id == widget.quote!.id, orElse: () => widget.quote!);
        final info = _quoteStatusInfo(q.data.quoteStatus);
        return (
          title: q.title,
          templateName: q.templateName,
          createdAt: q.createdAt,
          lastEditedAt: q.lastEditedAt,
          completionPercent: q.completionPercent,
          statusLabel: info.label, statusColor: info.color, statusIcon: info.icon,
          total: q.data.grandTotal,
          currency: q.data.currency,
          items: q.data.lineItems
              .map((i) => (desc: i.description, qty: i.quantity, unitPrice: i.unitPrice, total: i.total))
              .toList(),
          businessName: q.data.businessName,
          clientName: q.data.clientName,
          primaryDate: q.data.issueDate,
          secondaryDateLabel: 'Expires',
          secondaryDate: q.data.expiryDate,
          notes: q.data.notes,
          paidDate: null,
        );
      case DocType.receipt:
        final list = context.watch<ReceiptProvider>().savedReceipts;
        final r = list.firstWhere((i) => i.id == widget.receipt!.id, orElse: () => widget.receipt!);
        final info = _receiptStatusInfo(r.data.status);
        return (
          title: r.title,
          templateName: r.templateName,
          createdAt: r.createdAt,
          lastEditedAt: r.lastEditedAt,
          completionPercent: r.completionPercent,
          statusLabel: info.label, statusColor: info.color, statusIcon: info.icon,
          total: r.data.amountPaid,
          currency: r.data.currency,
          items: r.data.lineItems
              .map((i) => (desc: i.description, qty: i.quantity, unitPrice: i.unitPrice, total: i.total))
              .toList(),
          businessName: r.data.businessName,
          clientName: r.data.clientName,
          primaryDate: r.data.paymentDate,
          secondaryDateLabel: null,
          secondaryDate: null,
          notes: r.data.notes,
          paidDate: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _liveState(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, state),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStatsRow(context, state),
                    const SizedBox(height: 20),
                    _buildPreviewCard(context, state),
                    const SizedBox(height: 20),
                    _buildLineItemsCard(context, state),
                    const SizedBox(height: 20),
                    _buildActivityCard(context, state),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, state),
    );
  }

  // --- Sliver App Bar --------------------------------------------------------
  Widget _buildSliverAppBar(BuildContext context, dynamic state) {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: _accent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => _showOptionsSheet(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _HeaderBackground(
          accentColor: _accent,
          title: _currentTitle,
          typeLabel: _typeLabel(widget.type),
          typeIcon: _typeIcon(widget.type),
          statusLabel: state.statusLabel,
          statusColor: state.statusColor,
          statusIcon: state.statusIcon,
          createdAt: state.createdAt,
        ),
      ),
    );
  }

  // --- Stats row --------------------------------------------------------------
  Widget _buildStatsRow(BuildContext context, dynamic state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: DetailStatCard(
              value: '${state.currency} ${state.total.toStringAsFixed(2)}',
              label: widget.type == DocType.receipt ? 'Amount Paid' : 'Total',
              icon: Icons.payments_rounded,
              iconColor: _accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DetailStatCard(
              value: '${state.items.length}',
              label: 'Line Items',
              icon: Icons.list_alt_rounded,
              iconColor: const Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }

  // --- Preview card (generic branded summary — see flag #1 at top) ------------
  Widget _buildPreviewCard(BuildContext context, dynamic state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const DetailSectionLabel(label: 'Document'),
              if (state.templateName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.templateName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: _accent.withOpacity(isDark ? 0.15 : 0.1), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.businessName.isNotEmpty)
                  Text(state.businessName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('To: ${state.clientName.isEmpty ? '—' : state.clientName}',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.55))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13, color: colorScheme.onSurface.withOpacity(0.35)),
                    const SizedBox(width: 5),
                    Text(state.primaryDate.isEmpty ? '—' : state.primaryDate,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
                    if (state.secondaryDateLabel != null) ...[
                      const SizedBox(width: 14),
                      Icon(Icons.event_rounded, size: 13, color: colorScheme.onSurface.withOpacity(0.35)),
                      const SizedBox(width: 5),
                      Text('${state.secondaryDateLabel}: ${state.secondaryDate ?? '—'}',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Line items card ---------------------------------------------------------
  Widget _buildLineItemsCard(BuildContext context, dynamic state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionLabel(label: 'Line Items'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: state.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No line items',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < state.items.length; i++) ...[
                        DetailLineItemRow(
                          description: state.items[i].desc,
                          quantity: state.items[i].qty,
                          unitPrice: state.items[i].unitPrice,
                          total: state.items[i].total,
                          currency: state.currency,
                        ),
                        if (i != state.items.length - 1)
                          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF0F0F0)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- Activity card ------------------------------------------------------------
  // FIX (this pass): added a "Paid" row (green check-circle) whenever
  // state.paidDate is non-null — only ever true for a paid invoice.
  Widget _buildActivityCard(BuildContext context, dynamic state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionLabel(label: 'Activity'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                DetailActivityRow(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Created',
                  value: _formatDate(state.createdAt),
                  color: _accent,
                ),
                const SizedBox(height: 12),
                DetailActivityRow(
                  icon: Icons.edit_outlined,
                  label: 'Last edited',
                  value: _timeAgo(state.lastEditedAt),
                  color: const Color(0xFF9C27B0),
                ),
                if (state.paidDate != null) ...[
                  const SizedBox(height: 12),
                  DetailActivityRow(
                    icon: Icons.check_circle_rounded,
                    label: 'Paid',
                    value: _formatDate(state.paidDate!),
                    color: const Color(0xFF4CAF50),
                  ),
                ],
                if (state.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.notes,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom bar -----------------------------------------------------------
  Widget _buildBottomBar(BuildContext context, dynamic state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DetailActionButton(
                label: 'Edit',
                icon: Icons.edit_rounded,
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                onTap: () => _handleEdit(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryActionButton(
                label: 'Preview',
                icon: Icons.visibility_rounded,
                accent: _accent,
                onTap: () => _handleFullPreview(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Navigation / actions ---------------------------------------------------

  void _demoSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // FIX (this pass): fully wired for all three document types — each routes
  // to its own tap-to-edit canvas screen, seeded from this saved document's
  // id. `.then((_) { setState... })` forces a rebuild on return so the
  // header/stats/preview reflect whatever was just saved (the underlying
  // data itself already updates live via context.watch in _liveState, but
  // this also covers the case where nothing changed and we still want a
  // clean repaint).
  void _handleEdit(BuildContext context) {
    if (widget.isDemo) {
      _demoSnack(context, 'This is a demo document — editing is disabled.');
      return;
    }
    switch (widget.type) {
      case DocType.invoice:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceEditableCanvasScreen(invoiceId: widget.invoice!.id),
          ),
        ).then((_) {
          if (context.mounted) setState(() {});
        });
        break;
      case DocType.quote:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuoteEditableCanvasScreen(quoteId: widget.quote!.id),
          ),
        ).then((_) {
          if (context.mounted) setState(() {});
        });
        break;
      case DocType.receipt:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptEditableCanvasScreen(receiptId: widget.receipt!.id),
          ),
        ).then((_) {
          if (context.mounted) setState(() {});
        });
        break;
    }
  }

  // Wired to DocumentPdfPreviewScreen. Works for BOTH real and demo
  // documents — it's a plain-values mockup screen, so the already-
  // normalized `state` (identical shape for demo/real) feeds it directly.
  void _handleFullPreview(BuildContext context, dynamic state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPdfPreviewScreen(
          type: widget.type,
          documentTitle: '${_typeLabel(widget.type)} · ${state.title}',
          businessName: state.businessName,
          clientName: state.clientName,
          primaryDate: state.primaryDate,
          secondaryDateLabel: state.secondaryDateLabel,
          secondaryDate: state.secondaryDate,
          currency: state.currency,
          items: [
            for (final i in state.items)
              PdfPreviewLineItem(
                description: i.desc,
                quantity: i.qty,
                unitPrice: i.unitPrice,
                total: i.total,
              ),
          ],
          total: state.total,
          notes: state.notes,
          onDownloadPdf: () => _handleDownloadPdf(context),
          onSharePdf: () => _handleSharePdf(context),
        ),
      ),
    );
  }

  // Downloads the invoice PDF to the Downloads folder via InvoicePdfService.
  // Only wired for invoices right now — quote/receipt PDF export isn't built.
  Future<void> _handleDownloadPdf(BuildContext context) async {
    if (widget.type != DocType.invoice || widget.invoice == null) {
      _demoSnack(context, 'PDF export for this document type isn\'t built yet.');
      return;
    }
    try {
      final path = await InvoicePdfService().generateAndDownloadPDF(widget.invoice!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved to $path'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Couldn\'t generate PDF: $e'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // Generates the invoice PDF and triggers the OS share sheet via
  // InvoicePdfService. Same invoice-only scoping as _handleDownloadPdf above.
  Future<void> _handleSharePdf(BuildContext context) async {
    if (widget.type != DocType.invoice || widget.invoice == null) {
      _demoSnack(context, 'PDF export for this document type isn\'t built yet.');
      return;
    }
    try {
      await InvoicePdfService().generateAndSharePDF(widget.invoice!);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Couldn\'t generate PDF: $e'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // Exports the invoice as an .xlsx file to the Downloads folder via
  // InvoiceExportService. Same invoice-only scoping as the PDF handlers.
  Future<void> _handleExportXlsx(BuildContext context) async {
    if (widget.type != DocType.invoice || widget.invoice == null) {
      _demoSnack(context, 'Spreadsheet export for this document type isn\'t built yet.');
      return;
    }
    try {
      final path = await InvoiceExportService().exportSingleXlsxToDownloads(widget.invoice!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved to $path'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Couldn\'t generate spreadsheet: $e'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // Same idea as _handleExportXlsx but for .csv.
  Future<void> _handleExportCsv(BuildContext context) async {
    if (widget.type != DocType.invoice || widget.invoice == null) {
      _demoSnack(context, 'Spreadsheet export for this document type isn\'t built yet.');
      return;
    }
    try {
      final path = await InvoiceExportService().exportSingleCsvToDownloads(widget.invoice!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved to $path'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Couldn\'t generate spreadsheet: $e'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // Builds a fresh InvoiceData from this quote via
  // convertQuoteDataToInvoiceData(), saves it as a brand-new SavedInvoice
  // via InvoiceProvider.addConvertedInvoice() (doesn't touch whatever's
  // open in the invoice editor), then navigates to that new invoice's
  // detail screen. Only reachable when widget.type == DocType.quote.
  void _handleConvertQuoteToInvoice(BuildContext context) {
    if (widget.isDemo || widget.quote == null) {
      _demoSnack(context, 'This is a demo document — conversion is disabled.');
      return;
    }
    final quote = widget.quote!;
    final newInvoiceData = convertQuoteDataToInvoiceData(quote.data);
    final saved = context.read<InvoiceProvider>().addConvertedInvoice(
          data: newInvoiceData,
          title: quote.title,
          templateName: quote.templateName,
        );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Invoice created from this quote'),
      backgroundColor: kInvoiceAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedDocumentDetailScreen.invoice(saved),
      ),
    );
  }

  // Same idea as above but for Invoice -> Receipt. Only reachable when
  // widget.type == DocType.invoice.
  Future<void> _handleConvertInvoiceToReceipt(BuildContext context) async {
    if (widget.isDemo || widget.invoice == null) {
      _demoSnack(context, 'This is a demo document — conversion is disabled.');
      return;
    }
    final invoice = widget.invoice!;
    final newReceiptData = convertInvoiceDataToReceiptData(invoice.data);
    final saved = await context.read<ReceiptProvider>().addConvertedReceipt(
          data: newReceiptData,
          title: invoice.title,
          templateName: invoice.templateName,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Receipt created from this invoice'),
      backgroundColor: kReceiptAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedDocumentDetailScreen.receipt(saved),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    if (widget.isDemo) {
      _demoSnack(context, 'This is a demo document — options are disabled.');
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              DetailSheetOption(
                icon: Icons.drive_file_rename_outline_rounded,
                label: 'Rename',
                color: const Color(0xFFFF9800),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context);
                },
              ),
              // Convert to Invoice — quotes only.
              if (widget.type == DocType.quote)
                DetailSheetOption(
                  icon: Icons.receipt_long_rounded,
                  label: 'Convert to Invoice',
                  color: kInvoiceAccent,
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleConvertQuoteToInvoice(context);
                  },
                ),
              // Convert to Receipt — invoices only.
              if (widget.type == DocType.invoice)
                DetailSheetOption(
                  icon: Icons.receipt_rounded,
                  label: 'Convert to Receipt',
                  color: kReceiptAccent,
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleConvertInvoiceToReceipt(context);
                  },
                ),
              // Download / Share PDF, invoice-only for now.
              DetailSheetOption(
                icon: Icons.download_rounded,
                label: 'Download PDF',
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDownloadPdf(context);
                },
              ),
              DetailSheetOption(
                icon: Icons.ios_share_rounded,
                label: 'Share PDF',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleSharePdf(context);
                },
              ),
              // Export as Excel / CSV, invoice-only for now.
              DetailSheetOption(
                icon: Icons.grid_on_rounded,
                label: 'Export as Excel',
                color: const Color(0xFF1D6F42),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleExportXlsx(context);
                },
              ),
              DetailSheetOption(
                icon: Icons.table_chart_rounded,
                label: 'Export as CSV',
                color: const Color(0xFF607D8B),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleExportCsv(context);
                },
              ),
              DetailSheetOption(
                icon: Icons.delete_rounded,
                label: 'Delete',
                color: const Color(0xFFF44336),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: _currentTitle);
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Rename ${_typeLabel(widget.type)}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: colorScheme.onSurface),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
            decoration: InputDecoration(
              hintText: 'Enter a name',
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.35)),
              filled: true,
              fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF8F9FC),
              counterStyle: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.35)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.45))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newTitle = controller.text.trim();

                switch (widget.type) {
                  case DocType.invoice:
                    context.read<InvoiceProvider>().renameInvoice(_id, newTitle);
                    break;
                  case DocType.quote:
                    context.read<QuoteProvider>().renameQuote(_id, newTitle);
                    break;
                  case DocType.receipt:
                    context.read<ReceiptProvider>().renameSavedReceipt(_id, newTitle);
                    break;
                }

                setState(() => _currentTitle = newTitle);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Renamed to "$newTitle"'),
                  backgroundColor: _accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete ${_typeLabel(widget.type)}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        content: Text(
          'This will permanently delete "$_currentTitle". This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.45))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);

              switch (widget.type) {
                case DocType.invoice:
                  context.read<InvoiceProvider>().deleteInvoice(_id);
                  break;
                case DocType.quote:
                  context.read<QuoteProvider>().deleteQuote(_id);
                  break;
                case DocType.receipt:
                  context.read<ReceiptProvider>().deleteSavedReceipt(_id);
                  break;
              }

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _SecondaryActionButton — flat-tint, crisp-border button for the bottom bar.
// -----------------------------------------------------------------------------
class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _HeaderBackground
// -----------------------------------------------------------------------------
class _HeaderBackground extends StatelessWidget {
  final Color accentColor;
  final String title;
  final String typeLabel;
  final IconData typeIcon;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final DateTime createdAt;

  const _HeaderBackground({
    required this.accentColor,
    required this.title,
    required this.typeLabel,
    required this.typeIcon,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    const double topInset = 56;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
            ),
          ),
          Positioned(
            bottom: -20, left: -20,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
            ),
          ),
          Positioned(
            right: -10, bottom: -10,
            child: Icon(typeIcon, size: 110, color: Colors.white.withOpacity(0.06)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: topInset),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.45), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 10, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 10, color: Colors.white.withOpacity(0.85)),
                            const SizedBox(width: 4),
                            Text(typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.calendar_today_rounded, size: 10, color: Colors.white.withOpacity(0.55)),
                      const SizedBox(width: 4),
                      Text(_formatDate(createdAt), style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}