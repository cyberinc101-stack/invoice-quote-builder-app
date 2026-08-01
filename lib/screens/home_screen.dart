// home_screen.dart
// lib/screens/home_screen.dart
//
// UPDATED (this pass): added a per-user "layout mode" for the saved
// documents list — List / Grid / Compact. The toggle button lives right
// next to the "X documents" count in each section header (that's the
// spot that used to just show the count). Only ONE toggle is rendered
// (on the first section that actually has results) since layout mode is
// a single global preference, not per-section.
//
// Card rendering was refactored: invoices/quotes/receipts are now mapped
// into a common _DocEntry shape so the three layout builders (list/grid/
// compact) don't need type-specific branches.
//
// Previous pass: all DEV DUMMY demo-document code was removed — no demo
// data exists anywhere in this file; only real saved invoices/quotes/
// receipts render, with the standard "No documents match this filter"
// empty state.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';
import '../filters/filter_types.dart';
import '../filters/filter_logic.dart';
import '../alerts/alert_engine.dart';
import '../alerts/alert_prefs.dart';
import '../alerts/custom_reminders/reminder_provider.dart';
import '../widgets/document_filter_bar.dart';
import '../widgets/create_receipt_button.dart';
import 'alerts_screen.dart';
import 'document_templates_screen.dart';
import 'invoice_template_chooser_screen.dart'; // ← NEW
import 'quote_editor_screen.dart';
import 'quote_template_chooser_screen.dart'; // ← NEW
import 'saved_invoice_details_section/saved_document_detail_screen.dart';
import 'settings_screen.dart';
import 'expense_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Watched here (not just read) so the badge count on the bell updates
    // live as invoices/quotes/receipts are saved, paid, or edited — same
    // predicates as the quick-filter chips, via filter_logic.dart, so this
    // number can never disagree with what "Needs Action"/"Overdue" show.
    final alertsEnabled = context.watch<AlertPrefs>().alertsEnabled;
    final invoices = context.watch<InvoiceProvider>().savedInvoices;
    final quotes    = context.watch<QuoteProvider>().savedQuotes;
    final receipts  = context.watch<ReceiptProvider>().savedReceipts;
    final dueReminders = context.watch<ReminderProvider>().dueReminders;
    final alertCount = alertsEnabled
        ? buildAlerts(
            invoices: invoices,
            quotes: quotes,
            receipts: receipts,
            dueReminders: dueReminders,
          ).length
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice & Quote Builder'),
        actions: [
          _AlertBellButton(
            count: alertCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_outlined),
            tooltip: 'Expenses',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildHeroBanner(context),
            const SizedBox(height: 28),
            const _SavedDocumentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final screenWidth      = MediaQuery.of(context).size.width;
    final showIllustration = screenWidth >= 360;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x401A1A2E),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        // Stack instead of Row. The illustration is a decorative Positioned
        // overlay in the top-right corner — it no longer takes a column
        // slot in the layout. The text + button Column below is the
        // Stack's base child and gets the FULL container width, so the
        // three CTA buttons (each Expanded) span edge-to-edge.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Text(
                    'Professional documents in minutes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.only(right: showIllustration ? 90 : 0),
                  child: const Text(
                    'Create Your\nInvoice or Quote',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: 0.3,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(right: showIllustration ? 90 : 0),
                  child: const Text(
                    'Send professional invoices & quotes instantly',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 18),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _CtaButton(
                          label: 'Create Invoice',
                          icon: Icons.receipt_long_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                          ),
                          glowColor: const Color(0x602196F3),
                          onTap: () {
                            context.read<InvoiceProvider>().resetInvoiceData();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InvoiceTemplateChooserScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CtaButton(
                          label: 'Create Quote',
                          icon: Icons.request_quote_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                          ),
                          glowColor: const Color(0x607B1FA2),
                          onTap: () {
                            context.read<QuoteProvider>().resetQuoteData();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuoteTemplateChooserScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: CreateReceiptButton(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CtaButton(
                          label: 'Templates',
                          icon: Icons.grid_view_rounded,
                          iconSize: 28,
                          singleLine: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF78909C), Color(0xFF546E7A)],
                          ),
                          glowColor: const Color(0x6078909C),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DocumentTemplatesScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showIllustration)
              Positioned(
                right: 0,
                top: 0,
                child: SizedBox(
                  width: 80,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 0,
                        top: 10,
                        child: _MiniDocIcon(
                          color: const Color(0xFF7B1FA2),
                          rotateAngle: 0.15,
                          isQuote: true,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 20,
                        child: _MiniDocIcon(
                          color: const Color(0xFF1565C0),
                          rotateAngle: -0.1,
                          isQuote: false,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 0,
                        child: _MiniDocIcon(
                          color: const Color(0xFF2196F3),
                          rotateAngle: 0.0,
                          isQuote: false,
                        ),
                      ),
                    ],
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
// _AlertBellButton — bell icon + badge, lives in the AppBar
// -----------------------------------------------------------------------------

class _AlertBellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AlertBellButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Alerts',
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// DocLayoutMode — the new saved-documents view-style preference
// -----------------------------------------------------------------------------

enum DocLayoutMode { list, grid, compactGrid, compact }

extension on DocLayoutMode {
  IconData get icon {
    switch (this) {
      case DocLayoutMode.list:
        return Icons.view_agenda_rounded;
      case DocLayoutMode.grid:
        return Icons.grid_view_rounded;
      case DocLayoutMode.compactGrid:
        return Icons.apps_rounded;
      case DocLayoutMode.compact:
        return Icons.view_headline_rounded;
    }
  }

  String get label {
    switch (this) {
      case DocLayoutMode.list:
        return 'List';
      case DocLayoutMode.grid:
        return 'Grid';
      case DocLayoutMode.compactGrid:
        return 'Compact Grid';
      case DocLayoutMode.compact:
        return 'Compact';
    }
  }
}

/// Small trigger button + popup menu for switching between List / Grid /
/// Compact. Visually styled to sit inline with the "X documents" count
/// text in a _SectionHeader.
class _LayoutToggleButton extends StatelessWidget {
  final DocLayoutMode selected;
  final ValueChanged<DocLayoutMode> onChanged;

  const _LayoutToggleButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<DocLayoutMode>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Change layout',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => DocLayoutMode.values.map((mode) {
        final isSelected = mode == selected;
        return PopupMenuItem<DocLayoutMode>(
          value: mode,
          child: Row(
            children: [
              Icon(mode.icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mode.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 15, color: cs.onSurface.withOpacity(0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _DocEntry — common shape used by list/grid/compact renderers so invoices,
// quotes, and receipts don't need separate card-building branches.
// -----------------------------------------------------------------------------

class _DocEntry {
  final String title;
  final String subtitle;
  final String date;
  final int percent;
  final Color accentColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _DocEntry({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.percent,
    required this.accentColor,
    required this.statusLabel,
    required this.onTap,
  });
}

// -----------------------------------------------------------------------------
// _SavedDocumentsSection — holds filter + layout state and renders the list
// -----------------------------------------------------------------------------

class _SavedDocumentsSection extends StatefulWidget {
  const _SavedDocumentsSection();

  @override
  State<_SavedDocumentsSection> createState() => _SavedDocumentsSectionState();
}

class _SavedDocumentsSectionState extends State<_SavedDocumentsSection> {
  DocTypeFilter    _selectedType           = DocTypeFilter.all;
  PaymentStatus?   _selectedPaymentStatus;
  QuoteStatus?     _selectedQuoteStatus;
  ReceiptStatus?   _selectedReceiptStatus;
  QuickFilter      _selectedQuickFilter    = QuickFilter.none;
  DocLayoutMode    _selectedLayout         = DocLayoutMode.list;

  @override
  Widget build(BuildContext context) {
    return Consumer3<InvoiceProvider, QuoteProvider, ReceiptProvider>(
      builder: (context, invoiceProvider, quoteProvider, receiptProvider, _) {
        final allInvoices = invoiceProvider.savedInvoices;
        final allQuotes   = quoteProvider.savedQuotes;
        final allReceipts = receiptProvider.savedReceipts;

        // Badge counts on the quick-filter chips always reflect the FULL
        // saved-document set, regardless of which type tab or status is
        // currently selected.
        final needsActionCount = countNeedsAction(invoices: allInvoices, quotes: allQuotes);
        final overdueCount     = countOverdue(allInvoices);
        final draftsCount      = countDrafts(
          invoices: allInvoices,
          quotes:   allQuotes,
          receipts: allReceipts,
        );

        var filteredInvoices = allInvoices;
        var filteredQuotes   = allQuotes;
        var filteredReceipts = allReceipts;

        if (_selectedType == DocTypeFilter.invoices) {
          filteredQuotes   = const [];
          filteredReceipts = const [];
        } else if (_selectedType == DocTypeFilter.quotes) {
          filteredInvoices = const [];
          filteredReceipts = const [];
        } else if (_selectedType == DocTypeFilter.receipts) {
          filteredInvoices = const [];
          filteredQuotes   = const [];
        }

        if (_selectedPaymentStatus != null) {
          filteredInvoices = filteredInvoices
              .where((inv) => inv.data.paymentStatus == _selectedPaymentStatus)
              .toList();
        }
        if (_selectedQuoteStatus != null) {
          filteredQuotes = filteredQuotes
              .where((q) => q.data.quoteStatus == _selectedQuoteStatus)
              .toList();
        }
        if (_selectedReceiptStatus != null) {
          filteredReceipts = filteredReceipts
              .where((r) => r.data.status == _selectedReceiptStatus)
              .toList();
        }

        filteredInvoices = applyQuickFilterToInvoices(filteredInvoices, _selectedQuickFilter);
        filteredQuotes   = applyQuickFilterToQuotes(filteredQuotes, _selectedQuickFilter);
        filteredReceipts = applyQuickFilterToReceipts(filteredReceipts, _selectedQuickFilter);

        final hasResults = filteredInvoices.isNotEmpty ||
            filteredQuotes.isNotEmpty ||
            filteredReceipts.isNotEmpty;

        // Map each saved-document type into the common _DocEntry shape.
        final invoiceEntries = filteredInvoices
            .map((inv) => _DocEntry(
                  title: inv.title,
                  subtitle: inv.templateName,
                  date: inv.lastEditedDisplay(),
                  percent: inv.completionPercent,
                  accentColor: const Color(0xFF1565C0),
                  statusLabel: inv.data.paymentStatus.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedDocumentDetailScreen.invoice(inv),
                    ),
                  ),
                ))
            .toList();

        final quoteEntries = filteredQuotes
            .map((q) => _DocEntry(
                  title: q.title,
                  subtitle: q.templateName,
                  date: q.lastEditedDisplay(),
                  percent: q.completionPercent,
                  accentColor: const Color(0xFF7B1FA2),
                  statusLabel: q.data.quoteStatus.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedDocumentDetailScreen.quote(q),
                    ),
                  ),
                ))
            .toList();

        final receiptEntries = filteredReceipts
            .map((r) => _DocEntry(
                  title: r.title,
                  subtitle: r.templateName,
                  date: r.lastEditedDisplay(),
                  percent: r.completionPercent,
                  accentColor: const Color(0xFF2E7D32),
                  statusLabel: r.data.status.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedDocumentDetailScreen.receipt(r),
                    ),
                  ),
                ))
            .toList();

        // The layout toggle is a single global preference, so it's only
        // rendered once — on whichever section actually has results first
        // (Invoices → Quotes → Receipts order).
        final showToggleOnInvoices = invoiceEntries.isNotEmpty;
        final showToggleOnQuotes   = !showToggleOnInvoices && quoteEntries.isNotEmpty;
        final showToggleOnReceipts = !showToggleOnInvoices && !showToggleOnQuotes && receiptEntries.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DocumentFilterBar(
              selectedType: _selectedType,
              onTypeChanged: (t) => setState(() {
                _selectedType          = t;
                _selectedPaymentStatus = null;
                _selectedQuoteStatus   = null;
                _selectedReceiptStatus = null;
              }),
              selectedPaymentStatus: _selectedPaymentStatus,
              onPaymentStatusChanged: (s) =>
                  setState(() => _selectedPaymentStatus = s),
              selectedQuoteStatus: _selectedQuoteStatus,
              onQuoteStatusChanged: (s) =>
                  setState(() => _selectedQuoteStatus = s),
              selectedReceiptStatus: _selectedReceiptStatus,
              onReceiptStatusChanged: (s) =>
                  setState(() => _selectedReceiptStatus = s),
              invoiceCount: allInvoices.length,
              quoteCount:   allQuotes.length,
              receiptCount: allReceipts.length,
              selectedQuickFilter: _selectedQuickFilter,
              onQuickFilterChanged: (f) => setState(() => _selectedQuickFilter = f),
              needsActionCount: needsActionCount,
              overdueCount: overdueCount,
              draftsCount: draftsCount,
            ),
            const SizedBox(height: 16),
            if (!hasResults)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: Text(
                    'No documents match this filter',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (invoiceEntries.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'My Invoices',
                        count: invoiceEntries.length,
                        accentColor: const Color(0xFF1565C0),
                        layoutToggle: showToggleOnInvoices
                            ? _LayoutToggleButton(
                                selected: _selectedLayout,
                                onChanged: (m) => setState(() => _selectedLayout = m),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _buildEntries(invoiceEntries),
                      const SizedBox(height: 20),
                    ],
                    if (quoteEntries.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'My Quotes',
                        count: quoteEntries.length,
                        accentColor: const Color(0xFF7B1FA2),
                        layoutToggle: showToggleOnQuotes
                            ? _LayoutToggleButton(
                                selected: _selectedLayout,
                                onChanged: (m) => setState(() => _selectedLayout = m),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _buildEntries(quoteEntries),
                      const SizedBox(height: 20),
                    ],
                    if (receiptEntries.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'My Receipts',
                        count: receiptEntries.length,
                        accentColor: const Color(0xFF2E7D32),
                        layoutToggle: showToggleOnReceipts
                            ? _LayoutToggleButton(
                                selected: _selectedLayout,
                                onChanged: (m) => setState(() => _selectedLayout = m),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _buildEntries(receiptEntries),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// Renders a list of _DocEntry using whichever layout mode is currently
  /// selected — list (full detail), grid (2-col cards), or compact (dense
  /// single-line rows).
  Widget _buildEntries(List<_DocEntry> entries) {
    switch (_selectedLayout) {
      case DocLayoutMode.list:
        return Column(
          children: entries.map((e) => _DocCard(entry: e)).toList(),
        );
      case DocLayoutMode.grid:
        // Fixed mainAxisExtent instead of childAspectRatio — the card's
        // content height (icon + 2-line title + subtitle + date + status
        // chip) is constant regardless of column width, so a fixed extent
        // guarantees no overflow even with long titles or larger text
        // scaling, unlike aspect ratio which broke when the cell got
        // narrower than the content needed.
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 178,
          ),
          children: entries.map((e) => _DocGridCard(entry: e)).toList(),
        );
      case DocLayoutMode.compactGrid:
        // Denser 3-column variant — icon, title, status only. No
        // subtitle/date, so cards stay small and a lot fit on screen.
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 124,
          ),
          children: entries.map((e) => _DocCompactGridCard(entry: e)).toList(),
        );
      case DocLayoutMode.compact:
        return Column(
          children: entries.map((e) => _DocCompactRow(entry: e)).toList(),
        );
    }
  }
}

// -----------------------------------------------------------------------------
// _CtaButton
// -----------------------------------------------------------------------------

class _CtaButton extends StatelessWidget {
  final String         label;
  final IconData       icon;
  final LinearGradient gradient;
  final Color          glowColor;
  final VoidCallback   onTap;
  final bool           singleLine;
  final double         iconSize;

  const _CtaButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
    this.singleLine = false,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient:     gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            const SizedBox(height: 6),
            if (singleLine)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              )
            else
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _MiniDocIcon
// -----------------------------------------------------------------------------

class _MiniDocIcon extends StatelessWidget {
  final Color  color;
  final double rotateAngle;
  final bool   isQuote;

  const _MiniDocIcon({
    required this.color,
    required this.rotateAngle,
    required this.isQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotateAngle,
      child: Container(
        width: 50,
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  isQuote ? '?' : '\$',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            ...List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                height: 3,
                width: i == 0 ? 32 : (i == 1 ? 24 : (i == 2 ? 28 : 18)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
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
// _SectionHeader — now carries an optional layoutToggle, shown where the
// document count used to sit alone.
// -----------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  final int    count;
  final Color  accentColor;
  final Widget? layoutToggle;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.accentColor,
    this.layoutToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const Spacer(),
        if (layoutToggle != null) ...[
          layoutToggle!,
          const SizedBox(width: 10),
        ],
        Text(
          '$count document${count == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// _DocCard — LIST layout (full detail: subtitle, date, progress bar)
// -----------------------------------------------------------------------------

class _DocCard extends StatelessWidget {
  final _DocEntry entry;
  const _DocCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: entry.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entry.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description_rounded, color: entry.accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(entry.subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: entry.accentColor,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('- ${entry.date}',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.4))),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.percent / 100,
                      backgroundColor: cs.outline.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(entry.accentColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: entry.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: entry.accentColor,
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
// _DocGridCard — GRID layout (2-column cards, no progress bar, compact)
// -----------------------------------------------------------------------------

class _DocGridCard extends StatelessWidget {
  final _DocEntry entry;
  const _DocGridCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: entry.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // mainAxisSize.min + a fixed-height spacer (instead of Spacer)
        // keeps every card's content height identical and comfortably
        // under the grid's 178px mainAxisExtent, regardless of whether
        // the title wraps to 1 or 2 lines.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.description_rounded, color: entry.accentColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              entry.subtitle,
              style: TextStyle(fontSize: 10, color: entry.accentColor, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              entry.date,
              style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.4)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: entry.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.statusLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: entry.accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _DocCompactGridCard — COMPACT GRID layout (3-column, icon + title + status
// only — no subtitle/date, so it stays small and a lot fit on screen)
// -----------------------------------------------------------------------------

class _DocCompactGridCard extends StatelessWidget {
  final _DocEntry entry;
  const _DocCompactGridCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: entry.onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: entry.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.description_rounded, color: entry.accentColor, size: 15),
            ),
            const SizedBox(height: 7),
            Text(
              entry.title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: entry.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                entry.statusLabel,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: entry.accentColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _DocCompactRow — COMPACT layout (dense single-line rows)
// -----------------------------------------------------------------------------

class _DocCompactRow extends StatelessWidget {
  final _DocEntry entry;
  const _DocCompactRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: entry.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description_rounded, color: entry.accentColor, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              entry.date,
              style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: entry.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                entry.statusLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: entry.accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}