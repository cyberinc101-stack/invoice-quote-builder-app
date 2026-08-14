// lib/screens/saved_invoice_details_section/saved_document_detail_screen.dart
//
// One unified screen for SavedInvoice / SavedQuote / SavedReceipt, matched to
// the shape of those models exactly as defined in lib/models/*.dart.
//
// PDF PREVIEW FIX (this pass): _handleFullPreview now also passes the real
// InvoiceData (widget.invoice?.data, null for demo/quote/receipt) through to
// DocumentPdfPreviewScreen as `invoiceData:`. That screen uses it to render
// the actual A4 Executive template instead of its generic mockup card —
// see document_pdf_preview_screen.dart for the rendering-side change.
// Nothing else in this file changed for this pass.
//
// THEME-MATCH REDESIGN PASS (earlier update): DocumentDetailHeader now always
// renders on the app's navy hero gradient (kHeroGradient, same colors as
// the home screen's hero banner) instead of a separate flat/blurred color
// per branch — see detail/document_detail_header.dart for the full
// rationale. The only change needed here is _buildSliverAppBar's
// `barColor`: it used to switch between a logo-only dark navy
// (kDetailLogoHeaderColor) and the per-document accent color. Since the
// header itself is now navy in both branches, the collapsed/pinned
// SliverAppBar bar should match that same navy in both branches too —
// otherwise the bar would flash to the accent color on scroll while the
// header content sits on navy. Now sourced from kHeroGradient[0] (the
// header's own constant) so the two can never drift out of sync again.
//
// DETAIL REDESIGN PASS (earlier update): two things pulled out into
// lib/screens/saved_invoice_details_section/detail/ to keep this file
// from growing unbounded, and to fix a real overflow bug:
//   - The header background (_HeaderBackground) is now
//     DocumentDetailHeader (detail/document_detail_header.dart). The old
//     header packed a logo + status pill + title + type/date row into a
//     FIXED expandedHeight: 170 regardless of whether a logo was present,
//     which reliably overflowed ("BOTTOM OVERFLOWED BY N PIXELS") on any
//     document with a logo. _buildSliverAppBar now calls
//     DocumentDetailHeader.heightFor(hasLogo:) to size expandedHeight
//     correctly per branch. The logo itself is also no longer squeezed
//     into a small 56x56 square — it now renders as a full-width,
//     contain-fit banner across the top of the header, so the whole
//     business logo is visible.
//   - A new DocumentStatusStatsCard (detail/document_detail_status_card.
//     dart) sits between the Total/Line Items stat row and the Document
//     preview card — a large, prominent status block (Paid/Partial/
//     Unpaid/Overdue for invoices, Accepted/Declined/Sent/Expired/Draft
//     for quotes, Issued/Refunded for receipts) with a plain-English
//     description, the relevant due/expires/paid date, and — for an
//     overdue invoice or a still-sent quote — a computed day-count
//     ("3 days overdue" / "6 days left"). Previously status only showed
//     as a small pill in the header; this is the first place on the
//     screen where it's the unmissable headline it should be for a
//     financial document.
//
// Everything else in this header comment block is unchanged from the
// previous pass — see prior history for the Edit-wiring, convert,
// rename/delete, and per-type export dispatch notes (all preserved
// below).
//
// FIX (earlier pass): PDF / Excel / CSV export in the options sheet was
// previously invoice-only — _handleDownloadPdf, _handleSharePdf,
// _handleExportXlsx, and _handleExportCsv all early-returned with an
// "isn't built yet" snackbar for quotes and receipts. QuotePdfService,
// ReceiptPdfService (lib/services/) and QuoteExportService,
// ReceiptExportService (lib/export/) mirror InvoicePdfService/
// InvoiceExportService exactly, so all four handlers dispatch on
// widget.type instead of hard-coding the invoice path.
//
// FIX (earlier pass, build error): the receipt branch of _liveState()
// mapped `qty: i.qty`, but LineItem only exposes `quantity` — fixed to
// match the other branches.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../services/invoice_pdf_service.dart';
import '../../services/quote_pdf_service.dart';
import '../../services/receipt_pdf_service.dart';
import '../../export/invoice_export_service.dart';
import '../../export/quote_export_service.dart';
import '../../export/receipt_export_service.dart';
import '../../conversion/document_converter.dart';
import '../../widgets/saved_documents_containers.dart'
    show DocType, kInvoiceAccent, kQuoteAccent, kReceiptAccent;
import 'document_detail_widgets.dart';
import 'document_pdf_preview_screen.dart';
import 'invoice_editable_canvas_screen.dart';
import 'quote_editable_canvas_screen.dart';
import 'receipt_editable_canvas_screen.dart';
import 'detail/document_detail_header.dart';
import 'detail/document_detail_status_card.dart';

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

  // Resolves to a real, existing logo File, or null if there is none / the
  // path is stale. Centralized here (rather than inline in the header
  // widget) so both the SliverAppBar's expandedHeight/backgroundColor
  // decision and DocumentDetailHeader's rendering agree on whether "logo
  // mode" is active.
  File? _resolveLogoFile(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
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
  ({String title, String templateName, DateTime createdAt, DateTime lastEditedAt,
    int completionPercent, String statusLabel, Color statusColor, IconData statusIcon,
    double total, String currency, List<({String desc, double qty, double unitPrice, double total})> items,
    String businessName, String clientName, String primaryDate, String? secondaryDateLabel,
    String? secondaryDate, String notes, DateTime? paidDate, String? logoPath})
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
        logoPath: null,
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
          secondaryDateLabel: inv.data.paymentStatus == PaymentStatus.paid ? 'Paid' : 'Due',
          secondaryDate: inv.data.paymentStatus == PaymentStatus.paid
              ? (inv.data.paidDate != null ? _formatDate(inv.data.paidDate!) : '—')
              : inv.data.dueDate,
          notes: inv.data.notes,
          paidDate: inv.data.paidDate,
          logoPath: inv.data.businessLogoPath,
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
          logoPath: q.data.businessLogoPath,
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
          secondaryDateLabel: 'Paid',
          secondaryDate: r.data.paymentDate.isEmpty ? '—' : r.data.paymentDate,
          notes: r.data.notes,
          paidDate: null,
          logoPath: r.data.businessLogoPath,
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
                    DocumentStatusStatsCard(
                      type: widget.type,
                      statusLabel: state.statusLabel,
                      statusColor: state.statusColor,
                      statusIcon: state.statusIcon,
                      accent: _accent,
                      secondaryDateLabel: state.secondaryDateLabel,
                      secondaryDateValue: state.secondaryDate,
                    ),
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
    final logoFile = _resolveLogoFile(state.logoPath as String?);
    final hasLogo = logoFile != null;
    // DocumentDetailHeader always renders on the app's navy hero gradient
    // now (both branches — see detail/document_detail_header.dart), so
    // the collapsed/pinned bar uses that same navy rather than switching
    // to the per-document accent color. Sourced from the header's own
    // kHeroGradient constant so the two can never drift apart.
    final barColor = kHeroGradient[0];

    return SliverAppBar(
      expandedHeight: DocumentDetailHeader.heightFor(hasLogo: hasLogo),
      pinned: true,
      backgroundColor: barColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: DocumentDetailHeader(
          accentColor: _accent,
          logoFile: logoFile,
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
                    color: _accent.withValues(alpha: 0.12),
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
                BoxShadow(color: _accent.withValues(alpha: isDark ? 0.15 : 0.1), blurRadius: 20, offset: const Offset(0, 6)),
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
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.55))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13, color: colorScheme.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(width: 5),
                    Text(state.primaryDate.isEmpty ? '—' : state.primaryDate,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                    if (state.secondaryDateLabel != null) ...[
                      const SizedBox(width: 14),
                      Icon(Icons.event_rounded, size: 13, color: colorScheme.onSurface.withValues(alpha: 0.35)),
                      const SizedBox(width: 5),
                      Text('${state.secondaryDateLabel}: ${state.secondaryDate ?? '—'}',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
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
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: state.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No line items',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
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
                          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF0F0F0)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- Activity card ------------------------------------------------------------
  // Added a "Paid" row (green check-circle) whenever state.paidDate is
  // non-null — only ever true for a paid invoice.
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
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
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
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
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
  // documents — the already-normalized `state` (identical shape for
  // demo/real) feeds the plain-values fields directly. For real invoices
  // (not demo), the actual InvoiceData is also passed as `invoiceData:` so
  // the preview screen can render the real A4 Executive template instead
  // of its generic mockup — see document_pdf_preview_screen.dart.
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
          invoiceData: (!widget.isDemo && widget.type == DocType.invoice)
              ? widget.invoice!.data
              : null,
          onDownloadPdf: () => _handleDownloadPdf(context),
          onSharePdf: () => _handleSharePdf(context),
        ),
      ),
    );
  }

  // Dispatches on widget.type. Quote/receipt branches use
  // QuotePdfService/ReceiptPdfService, which mirror InvoicePdfService's
  // generateAndDownloadPDF signature exactly.
  Future<void> _handleDownloadPdf(BuildContext context) async {
    if (widget.isDemo) {
      _demoSnack(context, "This is a demo document — export isn't available.");
      return;
    }
    try {
      final String path;
      switch (widget.type) {
        case DocType.invoice:
          path = await InvoicePdfService().generateAndDownloadPDF(
            widget.invoice!,
            layoutTemplateId: widget.invoice!.data.layoutTemplateId,
          );
          break;
        case DocType.quote:
          path = await QuotePdfService().generateAndDownloadPDF(
            widget.quote!,
            layoutTemplateId: widget.quote!.data.layoutTemplateId,
          );
          break;
        case DocType.receipt:
          path = await ReceiptPdfService().generateAndDownloadPDF(
            widget.receipt!,
            layoutTemplateId: widget.receipt!.data.layoutTemplateId,
          );
          break;
      }
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

  Future<void> _handleSharePdf(BuildContext context) async {
    if (widget.isDemo) {
      _demoSnack(context, "This is a demo document — export isn't available.");
      return;
    }
    try {
      switch (widget.type) {
        case DocType.invoice:
          await InvoicePdfService().generateAndSharePDF(
            widget.invoice!,
            layoutTemplateId: widget.invoice!.data.layoutTemplateId,
          );
          break;
        case DocType.quote:
          await QuotePdfService().generateAndSharePDF(
            widget.quote!,
            layoutTemplateId: widget.quote!.data.layoutTemplateId,
          );
          break;
        case DocType.receipt:
          await ReceiptPdfService().generateAndSharePDF(
            widget.receipt!,
            layoutTemplateId: widget.receipt!.data.layoutTemplateId,
          );
          break;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Couldn\'t generate PDF: $e'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _handleExportXlsx(BuildContext context) async {
    if (widget.isDemo) {
      _demoSnack(context, "This is a demo document — export isn't available.");
      return;
    }
    try {
      final String path;
      switch (widget.type) {
        case DocType.invoice:
          path = await InvoiceExportService().exportSingleXlsxToDownloads(widget.invoice!);
          break;
        case DocType.quote:
          path = await QuoteExportService().exportSingleXlsxToDownloads(widget.quote!);
          break;
        case DocType.receipt:
          path = await ReceiptExportService().exportSingleXlsxToDownloads(widget.receipt!);
          break;
      }
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

  Future<void> _handleExportCsv(BuildContext context) async {
    if (widget.isDemo) {
      _demoSnack(context, "This is a demo document — export isn't available.");
      return;
    }
    try {
      final String path;
      switch (widget.type) {
        case DocType.invoice:
          path = await InvoiceExportService().exportSingleCsvToDownloads(widget.invoice!);
          break;
        case DocType.quote:
          path = await QuoteExportService().exportSingleCsvToDownloads(widget.quote!);
          break;
        case DocType.receipt:
          path = await ReceiptExportService().exportSingleCsvToDownloads(widget.receipt!);
          break;
      }
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
              hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.35)),
              filled: true,
              fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF8F9FC),
              counterStyle: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.35)),
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
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.45))),
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
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.45))),
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
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
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
