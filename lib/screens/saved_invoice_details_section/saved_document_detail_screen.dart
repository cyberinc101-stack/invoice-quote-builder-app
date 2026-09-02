// lib/screens/saved_invoice_details_section/saved_document_detail_screen.dart
//
// CONVERT-FORMAT (RECEIPT) PASS (this update): added a "Convert Format
// (A4 / Thermal)" option to the options sheet, receipt-only. Reuses
// ReceiptTemplateChooserScreen exactly the way "Convert to Receipt"
// already does — as a plain paper-format/design picker via its
// onTemplateChosen callback — except this time on an EXISTING receipt
// rather than building a brand-new one from a converted invoice.
// existingReceiptId is also passed so the chooser opens pre-selected to
// the receipt's current format/design (see
// ReceiptTemplateChooserScreen._loadInitialSelection). The chosen
// (templateId, paperFormat) is written straight onto the saved receipt
// via the new ReceiptProvider.updateSavedReceiptFormat() — no name
// prompt or loading dialog needed here, since this doesn't create a new
// document the way the invoice→receipt conversion does.
//
// CONFIRM-BEFORE-EXPORT PASS (earlier update): Download PDF, Share PDF,
// Export as Excel, and Export as CSV in the options sheet previously
// fired their handler the instant the row was tapped — no confirmation,
// so a mis-tap immediately kicked off a file write or share sheet.
// Added a shared _confirmAction(...) dialog (professional, plain-English
// wording — "This will generate a PDF of this invoice and save it to
// your device. Continue?" etc., tailored per action/doc type) that each
// of those four options now awaits before calling its handler. Rename,
// Convert, and Delete are untouched — Delete already had its own
// confirmation dialog, and Rename/Convert aren't one-shot destructive-ish
// actions the same way a file export is.
//
// CONVERT-TO-RECEIPT SIZE PICKER (earlier pass): _handleConvertInvoiceToReceipt
// now opens ReceiptTemplateChooserScreen (with its new onTemplateChosen
// callback) instead of converting straight through with whatever
// layoutTemplateId the converter happened to produce. The user picks a
// paper format (A4 grid / Thermal) and, for A4, a design, exactly like the
// regular "Create Receipt" flow — the chosen (templateId, paperFormat) is
// applied to the converted ReceiptData via copyWith before saving. The
// chooser is popped from inside the callback once the receipt is saved,
// then the new saved receipt's detail screen is pushed.
//
// FORMAL REDESIGN PASS (earlier pass): three visual changes to de-saturate the
// screen alongside the stat-card/status-card restyle in
// document_detail_widgets.dart and detail/document_detail_status_card.dart:
//   - Template chip (in _buildPreviewCard) now a neutral gray pill instead
//     of an accent-tinted one.
//   - Edit button (bottom bar) now solid neutral (colorScheme.onSurface)
//     instead of the per-document accent color.
//   - _SecondaryActionButton (Preview) now a plain outlined gray button
//     instead of an accent-tinted one — removes the "two colorful pills"
//     look at the bottom of the screen.
// Nothing else in this file changed for this pass.
//
// PDF PREVIEW FIX (earlier pass): _handleFullPreview now also passes the
// real InvoiceData (widget.invoice?.data, null for demo/quote/receipt)
// through to DocumentPdfPreviewScreen as `invoiceData:`. That screen uses it
// to render the actual A4 Executive template instead of its generic mockup
// card — see document_pdf_preview_screen.dart for the rendering-side change.
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
import '../invoice_create_section/editor_screen.dart';
import '../quote_editor_screen.dart';
import '../../create_receipt/create_receipt_screen.dart';
import 'detail/document_detail_header.dart';
import 'detail/document_detail_status_card.dart';
import '../invoice_template_chooser_screen.dart';
import '../quote_template_chooser_screen.dart';
import '../../create_receipt/receipt_template_chooser_screen.dart';
import '../../create_receipt/receipt_paper_format.dart';

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
                      // Ties the card's neutral border/background tint
                      // to the same navy used by the header, instead of
                      // a flat unrelated gray.
                      neutralAccent: kHeroGradient[0],
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
              neutralAccent: kHeroGradient[0],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DetailStatCard(
              value: '${state.items.length}',
              label: 'Line Items',
              icon: Icons.list_alt_rounded,
              iconColor: const Color(0xFF9C27B0),
              neutralAccent: kHeroGradient[0],
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
              // FORMAL REDESIGN: neutral pill instead of the old
              // per-document accent-tinted chip — this is document
              // metadata, not a status or action, so it shouldn't carry
              // invoice/quote/receipt brand color. Tinted with the
              // header's own navy (kHeroGradient[0]) rather than a flat
              // unrelated gray, so it still reads as this app.
              if (state.templateName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kHeroGradient[0].withValues(alpha: isDark ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kHeroGradient[0].withValues(alpha: 0.16)),
                  ),
                  child: Text(
                    state.templateName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : kHeroGradient[0],
                    ),
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
                          striped: i.isOdd,
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
                // FORMAL REDESIGN: solid navy (the same kHeroGradient[0]
                // used by the header) instead of the per-document accent
                // color — Edit is the primary action, so it stays solid,
                // but now echoes the header's own brand color instead of
                // switching between invoice/quote/receipt colors or a
                // generic black.
                backgroundColor: kHeroGradient[0],
                foregroundColor: Colors.white,
                onTap: () => _handleEdit(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryActionButton(
                label: 'Preview',
                icon: Icons.visibility_rounded,
                accent: kHeroGradient[0],
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

  // CONFIRM-BEFORE-EXPORT PASS: shared confirmation dialog used by
  // Download PDF / Share PDF / Export as Excel / Export as CSV before
  // any of those handlers actually run. Returns true only if the user
  // taps the primary (confirm) button; false for Cancel, a barrier tap,
  // or a back-gesture dismissal (showDialog<bool> resolves null in all
  // of those cases, so the `?? false` below covers them all in one go).
  Future<bool> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = kHeroGradient[0];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.45))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _handleEdit(BuildContext context) {
    if (widget.isDemo) {
      _demoSnack(context, 'This is a demo document — editing is disabled.');
      return;
    }
    // Load the real saved document into its provider first, then jump
    // straight to the step-based editor's Customise/Review step (step 3)
    // with that data already filled in — no template re-selection step.
    switch (widget.type) {
      case DocType.invoice:
        final provider = context.read<InvoiceProvider>();
        provider.loadSavedInvoice(widget.invoice!.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditorScreen(
              initialStep: 3,
              layoutTemplateId: widget.invoice!.data.layoutTemplateId,
            ),
          ),
        ).then((_) {
          if (context.mounted) setState(() {});
        });
        break;
      case DocType.quote:
        final provider = context.read<QuoteProvider>();
        provider.loadSavedQuote(widget.quote!.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuoteEditorScreen(
              initialStep: 3,
              layoutTemplateId: widget.quote!.data.layoutTemplateId,
            ),
          ),
        ).then((_) {
          if (context.mounted) setState(() {});
        });
        break;
      case DocType.receipt:
        final provider = context.read<ReceiptProvider>();
        provider.loadSavedReceipt(widget.receipt!.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateReceiptScreen(
              initialStep: 3,
              layoutTemplateId: widget.receipt!.data.layoutTemplateId,
            ),
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
          quoteData: (!widget.isDemo && widget.type == DocType.quote)
              ? widget.quote!.data
              : null,
          receiptData: (!widget.isDemo && widget.type == DocType.receipt)
              ? widget.receipt!.data
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

  // NAME + LOADING PASS: asks for a name up front via
  // _showConversionNameDialog (defaulting to the quote's own title, but
  // editable), then runs the actual conversion behind
  // _runWithLoadingDialog so the user sees a brief, real loading state
  // instead of the screen just silently swapping underneath them.
  Future<void> _handleConvertQuoteToInvoice(BuildContext context) async {
    if (widget.isDemo || widget.quote == null) {
      _demoSnack(context, 'This is a demo document — conversion is disabled.');
      return;
    }
    final quote = widget.quote!;

    final newTitle = await _showConversionNameDialog(
      context,
      defaultTitle: quote.title,
      dialogTitle: 'Name this Invoice',
      actionLabel: 'Create Invoice',
      accent: kInvoiceAccent,
    );
    if (newTitle == null || !context.mounted) return; // cancelled

    final convertedInvoiceData = convertQuoteDataToInvoiceData(quote.data);
    final newInvoiceData = convertedInvoiceData.copyWith(
      invoiceNumber: '',
      notes: _prependConversionNote(convertedInvoiceData.notes, 'Quote "${quote.title}"'),
    );
    final saved = await _runWithLoadingDialog(
      context,
      () async => context.read<InvoiceProvider>().addConvertedInvoice(
            data: newInvoiceData,
            title: newTitle,
            templateName: quote.templateName,
          ),
      message: 'Creating invoice…',
    );
    if (!context.mounted) return;

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

  // CONVERT-TO-RECEIPT SIZE PICKER + NAME + LOADING PASS: order is now
  // name -> paper format/design -> loading -> done.
  //   1. _showConversionNameDialog asks for a name up front (defaulting to
  //      the invoice's own title, editable, cancel bails out entirely).
  //   2. ReceiptTemplateChooserScreen opens as a plain size/design picker
  //      (via its onTemplateChosen callback) instead of saving straight
  //      through with whatever layoutTemplateId the converter happened to
  //      produce.
  //   3. Once a template/paper format is picked, _runWithLoadingDialog
  //      shows a real loading state (with a small minimum-visible floor so
  //      it never just flashes) while the converted ReceiptData — now with
  //      the chosen layoutTemplateId/paperFormat and the user's name —
  //      is actually saved.
  //   4. The chooser pops itself from inside the callback once the save
  //      completes, then the new saved receipt's detail screen is pushed
  //      on top of this one.
  Future<void> _handleConvertInvoiceToReceipt(BuildContext context) async {
    if (widget.isDemo || widget.invoice == null) {
      _demoSnack(context, 'This is a demo document — conversion is disabled.');
      return;
    }
    final invoice = widget.invoice!;

    final newTitle = await _showConversionNameDialog(
      context,
      defaultTitle: invoice.title,
      dialogTitle: 'Name this Receipt',
      actionLabel: 'Continue',
      accent: kReceiptAccent,
    );
    if (newTitle == null || !context.mounted) return; // cancelled

    final receiptProvider = context.read<ReceiptProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptTemplateChooserScreen(
          onTemplateChosen: (templateId, paperFormat) async {
            final convertedData = convertInvoiceDataToReceiptData(invoice.data);
            final newReceiptData = convertedData.copyWith(
              layoutTemplateId: templateId,
              paperFormat: paperFormat,
              receiptNumber: '',
              notes: _prependConversionNote(convertedData.notes, 'Invoice "${invoice.title}"'),
            );
            final saved = await _runWithLoadingDialog(
              context,
              () => receiptProvider.addConvertedReceipt(
                data: newReceiptData,
                title: newTitle,
                templateName: invoice.templateName,
              ),
              message: 'Creating receipt…',
            );
            if (!context.mounted) return;
            // Close the chooser first so it doesn't sit underneath the new
            // receipt's detail screen in the back stack.
            Navigator.pop(context);
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
          },
        ),
      ),
    );
  }

  // CONVERT-FORMAT (RECEIPT) PASS: unlike the two conversions above, this
  // doesn't create a new document — it changes an EXISTING receipt's
  // paper format in place. Rather than pushing the full
  // ReceiptTemplateChooserScreen, this shows a small bottom sheet listing
  // only the formats the receipt ISN'T currently in (e.g. currently A4 ->
  // shows 58mm and 80mm; currently 58mm -> shows A4 and 80mm). Tapping one
  // converts instantly (with an inline spinner on that row while it
  // saves) via ReceiptProvider.updateSavedReceiptFormat() — no design
  // picker, since a format switch keeps whatever layoutTemplateId the
  // receipt already had (thermal ignores it entirely; A4 keeps its
  // existing design if it already had one, or falls back to Executive).
  Future<void> _handleConvertReceiptFormat(BuildContext context) async {
    if (widget.isDemo || widget.receipt == null) {
      _demoSnack(context, 'This is a demo document — conversion is disabled.');
      return;
    }
    final receipt = widget.receipt!;
    final receiptProvider = context.read<ReceiptProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final currentFormat = receiptPaperFormatFromString(receipt.data.paperFormat);
    final otherFormats =
        ReceiptPaperFormat.values.where((f) => f != currentFormat).toList();

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ConvertFormatSheet(
        currentFormat: currentFormat,
        otherFormats: otherFormats,
        onConvert: (format) => receiptProvider.updateSavedReceiptFormat(
          receipt.id,
          layoutTemplateId: receipt.data.layoutTemplateId,
          paperFormat: format.storageName,
        ),
      ),
    );

    if (!context.mounted) return;
    setState(() {}); // refresh this screen's preview/template chip
  }

  // Shared "Converted from …" note prepended to whatever notes carried
  // over from the source document — the audit trail for a conversion,
  // since the number field itself is left blank (see handlers above) and
  // can't be relied on to identify the source.
  String _prependConversionNote(String existingNotes, String sourceLabel) {
    final line = 'Converted from $sourceLabel';
    if (existingNotes.trim().isEmpty) return line;
    return '$line\n${existingNotes.trim()}';
  }

  // Shared naming prompt for both conversion flows — prefilled with the
  // source document's title (editable), Cancel returns null so the caller
  // can bail out of the conversion entirely.
  Future<String?> _showConversionNameDialog(
    BuildContext context, {
    required String defaultTitle,
    required String dialogTitle,
    required String actionLabel,
    required Color accent,
  }) {
    final controller = TextEditingController(text: defaultTitle);
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(dialogTitle,
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
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 2)),
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
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Shows a non-dismissible loading dialog while `work` runs, with a small
  // minimum-visible floor (550ms) so a fast conversion doesn't just flash
  // and disappear — the point is for the user to actually perceive that
  // something happened, not just to gate on real latency. Always pops the
  // dialog itself (success or failure) via the root navigator, since
  // showDialog always mounts on the root navigator regardless of how
  // deeply nested `context` is at the call site.
  Future<T> _runWithLoadingDialog<T>(
    BuildContext context,
    Future<T> Function() work, {
    String message = 'Working…',
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConversionLoadingDialog(message: message),
    );
    final stopwatch = Stopwatch()..start();
    try {
      final result = await work();
      final elapsed = stopwatch.elapsed;
      const minDuration = Duration(milliseconds: 550);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      return result;
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showOptionsSheet(BuildContext context) {
    if (widget.isDemo) {
      _demoSnack(context, 'This is a demo document — options are disabled.');
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final typeLabelLower = _typeLabel(widget.type).toLowerCase();

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
              // CONVERT-FORMAT (RECEIPT) PASS: receipt-only — switches
              // paper format (A4 <-> 58mm/80mm thermal) and, for A4, the
              // design, on this already-saved receipt.
              if (widget.type == DocType.receipt)
                DetailSheetOption(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Convert Format (A4 / Thermal)',
                  color: kReceiptAccent,
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleConvertReceiptFormat(context);
                  },
                ),
              // CONFIRM-BEFORE-EXPORT PASS: each of the four export/share
              // options below now closes the sheet, then awaits
              // _confirmAction before calling its handler. If the user
              // taps Cancel (or dismisses the dialog any other way), the
              // handler is simply never called — no file write, no share
              // sheet, no snackbar.
              DetailSheetOption(
                icon: Icons.download_rounded,
                label: 'Download PDF',
                color: const Color(0xFF2196F3),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _confirmAction(
                    context,
                    title: 'Download PDF',
                    message: 'This will generate a PDF of this $typeLabelLower and save it to your device. Continue?',
                    confirmLabel: 'Download',
                    icon: Icons.download_rounded,
                  );
                  if (ok && context.mounted) _handleDownloadPdf(context);
                },
              ),
              DetailSheetOption(
                icon: Icons.ios_share_rounded,
                label: 'Share PDF',
                color: const Color(0xFF4CAF50),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _confirmAction(
                    context,
                    title: 'Share PDF',
                    message: 'This will generate a PDF of this $typeLabelLower and open your device\'s share menu. Continue?',
                    confirmLabel: 'Share',
                    icon: Icons.ios_share_rounded,
                  );
                  if (ok && context.mounted) _handleSharePdf(context);
                },
              ),
              DetailSheetOption(
                icon: Icons.grid_on_rounded,
                label: 'Export as Excel',
                color: const Color(0xFF1D6F42),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _confirmAction(
                    context,
                    title: 'Export as Excel',
                    message: 'This will generate an Excel spreadsheet of this $typeLabelLower and save it to your Downloads folder. Continue?',
                    confirmLabel: 'Export',
                    icon: Icons.grid_on_rounded,
                  );
                  if (ok && context.mounted) _handleExportXlsx(context);
                },
              ),
              DetailSheetOption(
                icon: Icons.table_chart_rounded,
                label: 'Export as CSV',
                color: const Color(0xFF607D8B),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _confirmAction(
                    context,
                    title: 'Export as CSV',
                    message: 'This will generate a CSV file of this $typeLabelLower and save it to your Downloads folder. Continue?',
                    confirmLabel: 'Export',
                    icon: Icons.table_chart_rounded,
                  );
                  if (ok && context.mounted) _handleExportCsv(context);
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
// _ConversionLoadingDialog — small non-dismissible spinner + message shown
// while a conversion (quote→invoice, invoice→receipt) actually saves, so
// it reads as a real action instead of the screen silently swapping.
// canPop: false blocks the hardware/gesture back action while it's up;
// the dialog is only ever dismissed programmatically by
// _runWithLoadingDialog once the work finishes.
// -----------------------------------------------------------------------------
class _ConversionLoadingDialog extends StatelessWidget {
  final String message;
  const _ConversionLoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: kHeroGradient[0]),
              ),
              const SizedBox(width: 16),
              Text(
                message,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _ConvertFormatSheet — CONVERT-FORMAT (RECEIPT) PASS: bottom sheet
// listing only the paper formats a receipt ISN'T currently in. Tapping a
// row converts instantly, showing an inline spinner on that row while
// ReceiptProvider.updateSavedReceiptFormat() saves, then closes itself.
// -----------------------------------------------------------------------------
class _ConvertFormatSheet extends StatefulWidget {
  final ReceiptPaperFormat currentFormat;
  final List<ReceiptPaperFormat> otherFormats;
  final Future<void> Function(ReceiptPaperFormat) onConvert;

  const _ConvertFormatSheet({
    required this.currentFormat,
    required this.otherFormats,
    required this.onConvert,
  });

  @override
  State<_ConvertFormatSheet> createState() => _ConvertFormatSheetState();
}

class _ConvertFormatSheetState extends State<_ConvertFormatSheet> {
  ReceiptPaperFormat? _converting;

  Future<void> _tap(ReceiptPaperFormat format) async {
    if (_converting != null) return;
    setState(() => _converting = format);
    try {
      await widget.onConvert(format);
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF2E7D32);
    final busy = _converting != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Convert Format',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(
              'Currently ${widget.currentFormat.label} — tap a format below to convert instantly.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            for (final format in widget.otherFormats)
              GestureDetector(
                onTap: busy ? null : () => _tap(format),
                child: Opacity(
                  opacity: busy && _converting != format ? 0.4 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                          : const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            format.isThermal ? Icons.receipt_rounded : Icons.description_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(format.label,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                              const SizedBox(height: 2),
                              Text(format.description,
                                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                            ],
                          ),
                        ),
                        if (_converting == format)
                          SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: accent),
                          )
                        else
                          Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _SecondaryActionButton — outlined navy button for the bottom bar.
//
// FORMAL REDESIGN: was a flat per-document-accent fill with an accent
// border and accent text/icon — paired with the also-accent-colored Edit
// button, this made the bottom bar read as "two colorful pills." Now
// outlined only (no fill), colored by whatever's passed as `accent` — the
// call site passes kHeroGradient[0] (the header's navy), so this pairs
// with the now-solid-navy Edit button as one calm, on-brand color instead
// of a rotating cast of invoice/quote/receipt accents.
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
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.2,
            ),
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