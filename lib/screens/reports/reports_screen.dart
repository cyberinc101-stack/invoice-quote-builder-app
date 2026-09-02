// reports_screen.dart
// lib/screens/reports/reports_screen.dart
//
// PROFIT & LOSS PASS (this update): _sumIncome's single combined total is
// now backed by a new _incomeBreakdown() helper that returns invoice and
// receipt revenue as separate numbers (invoice, receipt) — _sumIncome
// just adds the two together, so every existing caller (income,
// _incomeForMonth, _buildTrendPoints, _topClientsTotals indirectly via
// the same gating) is byte-for-byte unchanged in behavior. The new
// ProfitLossCard (reports_pl_card.dart) needs that split to show
// "Invoices (paid)" and "Receipts (issued)" as separate revenue lines in
// a traditional P&L layout, and reuses the same sortedCategoryEntries /
// categories lookup the existing "Expenses by category" section already
// computes — so the P&L card can never disagree with any other card on
// this screen about what counts as revenue or an expense. Rendered as a
// new section directly under the Net stat card, above Total Unpaid.
//
// ── Everything else below is unchanged from the previous pass — see
// original header comments preserved below. ──
//
// MONTH PICKER THEME-COLOR PASS (earlier): _openMonthPicker() now
// passes Theme.of(context).colorScheme.primary as the picker's accent
// instead of this screen's own kReportsAccent (teal). colorScheme.primary
// is derived from the app-wide seed color set in main.dart
// (ColorScheme.fromSeed(seedColor: Color(0xFF1565C0))) — the same blue
// used for Invoice accents/buttons elsewhere in the app — so the month/
// date-range picker's selected-day circles, range band, mode toggle, and
// "Done" button now match the app's overall theme instead of standing
// out in Reports' own teal. Nothing else on this screen changes — every
// other kReportsAccent usage (stat cards, tax card, client statements,
// etc.) is untouched, since only the picker was reported as
// mismatched.
//
// TOTAL UNPAID PASS (earlier): added a new "Total Unpaid" stat card,
// rendered directly under the Net card. Sums InvoiceData.grandTotal for
// every period invoice whose paymentStatus is unpaid or overdue —
// deliberately excluding paid and partial, and there's no draft status
// on PaymentStatus itself (drafts are simply invoices with
// completionPercent < 100, which _isReportable() already filters out,
// same gate Income/Net/Top Clients use). Gated behind
// prefs.includeInvoices, same as every other invoice-derived figure on
// this screen, and computed from periodInvoices so it automatically
// respects the active month/range and folder scope with zero extra
// wiring.
//
// HOME UI-PARITY PASS (earlier): visual-only change, no data/logic
// changes. The screen used to open with a solid teal AppBar and a plain
// flat row for the period/folder/data-source controls — visually
// inconsistent with HomeScreen's dark-gradient hero banner. Now:
//   - AppBar is a plain default (theme) app bar, same as Home's, instead
//     of a hardcoded teal background/white foreground.
//   - The period selector, folder scope selector, and
//     DataSourceToggleRow are wrapped in the new ReportsHeroCard
//     (reports_widgets.dart) — the same navy gradient/radius/shadow
//     treatment as HomeScreen's hero banner — with their text/icon colors
//     switched to white/white70 to sit on that dark background.
//   - DataSourceToggleRow's call site dropped the now-removed `accent`
//     param (see reports_widgets.dart header comment); the chips now
//     carry their own per-type colors instead.
// Everything below the hero card (trend chart, stat cards, tax card,
// client statements, top clients, category breakdown, document list,
// status breakdown) — and every computation feeding them — is
// byte-for-byte unchanged from the previous pass.
//
// GROUPED DOCUMENTS + SHARED LAYOUT (earlier): "Documents in this
// period" no longer owns its own local layout state (_docsLayoutMode is
// gone) — ReportsDocumentSection now reads/writes the same SavedLayoutPrefs
// preference Home's Saved Documents section uses, so picking Grid/List/
// Compact on either screen shows up on both. The section itself also now
// groups items into My Invoices/My Quotes/My Receipts/My Expenses with
// headers, matching Home's layout exactly, instead of one flat filterable
// list — see reports_document_list.dart for that change.
//
// TREND-CHART PASS (earlier): the static "6-month trend" TrendStrip
// (reports_charts.dart) is retired and replaced by ReportsTrendChartCard
// (reports_trend_chart.dart) — a collapsible card with a Net/Income/
// Expenses metric toggle and a 1W/1M/3M/6M/1Y/2Y/5Y/10Y range selector,
// rendered as a line+area chart with a stock-app-style +X%/-X% badge
// (green = up, red = down) and a tap-and-drag scrub readout. The old
// `trendPoints`/MonthTrendPoint computation is gone; in its place,
// _buildTrendPoints() buckets the already folder-scoped invoices/
// receipts/expenses into whatever granularity the selected range calls
// for (daily/weekly/monthly/yearly — see TrendRangeX in
// reports_trend_chart.dart), anchored on "today" rather than the
// month/range picker above it, same reasoning the old trend strip used
// for staying anchored on _month regardless of an active custom range —
// a multi-year trend shouldn't jump around as you browse individual
// months. It reuses _filterByRange/_sumIncome so it can never disagree
// with the rest of the screen about what counts as income.
//
// EXPENSES-MERGED PASS (earlier): expenses are folded directly into
// `docItems` as ReportsDocumentItem entries (ReportsDocType.expense —
// see reports_document_list.dart) and rendered by the same
// ReportsDocumentSection as invoices/quotes/receipts, with its own
// filter pill and using category color as accent. The old, separate
// "Expenses in this period" section (ReportsListItem/ReportsItemSection
// from reports_item_list.dart) is retired — this was the last place
// expenses looked visually different from the other three document
// types, both here and versus Home's own unified list.  "Expenses by
// category" and its underlying byCategory rollup are UNCHANGED — that's a
// genuinely different view (category totals, not individual
// transactions) and stays as its own section further down the screen.
//
// Accounting accuracy note: the gating rules that decide what counts
// toward Income/Expenses/Net are unchanged by this pass. A document only
// counts when it's 100% complete AND not manually excluded (see
// _isReportable()); an expense counts when it's not manually excluded
// (expenses have no completion concept). Merging the display doesn't
// change what's counted — only how it's browsed.
//
// THIS PASS (earlier): wired ReportsPrefs.includeExpenses through —
// periodExpenses, expensesThisMonth, the "Expenses by category"
// breakdown, the trend strip's expense bars, and (at the time) the
// "Expenses in this period" list were all gated behind it, same as
// includeInvoices/includeQuotes/includeReceipts already gate the other
// three sources. Added the includeExpenses/onExpensesChanged params to
// the DataSourceToggleRow call so the 4th chip in reports_widgets.dart is
// wired up. That gating still applies — periodExpenses stays empty
// (so no expense docItems get built) whenever includeExpenses is off.
//
// "Documents in this period" renders with the same rich card visual
// language as the Saved Documents section on the home screen (logo
// avatar, template + edited-date line, secondary due/expires/paid line,
// created + item-count row, completion bar, amount, status chip) via
// ReportsDocumentSection/ReportsDocumentItem (reports_document_list.dart).
//
// _reportsInvoiceStatusInfo/_reportsQuoteStatusInfo/_reportsReceiptStatusInfo
// below mirror the status label/color/positive-dot mapping used elsewhere
// in the app (saved_documents_containers.dart) so a document reads the
// same color and "positive" state whether you're looking at it from Saved
// Documents or from Reports.
//
// ReportsDocumentSection uses ReportsItemSection's ReportsIncludeCheckbox
// (reports_item_list.dart): tapping it flips that item's
// excludeFromReports flag via the same provider methods the Saved
// Documents section already uses (updateInvoiceExcludeFromReports etc.,
// plus updateExpenseExcludeFromReports on ExpenseProvider).
//
// Tapping a document card opens SavedDocumentDetailScreen, same as
// everywhere else in the app. Tapping an expense card is currently a
// no-op — there's no expense detail/edit screen wired in from here yet.
//
// docItems is built directly off periodInvoices/periodQuotes/
// periodReceipts/periodExpenses, so it automatically respects the active
// month/range, folder scope, and data-source toggles already computed
// above it — no separate filtering logic needed.
//
// hasAnyDataThisMonth checks periodQuotes/docItems/periodExpenses so the
// section (and the empty state) agree about whether there's anything to
// show for the period.
//
// Custom date-range filtering. When a range is picked via
// month_picker_sheet.dart's range mode, Income/Expenses/Net/quote-
// pipeline/invoice-status/category-breakdown all total against the exact
// range instead of the single selected month.
//
// The month/day bucketing (_groupByMonth, invoicesByMonth, etc.) is kept
// for single-month mode; range mode filters the raw lists directly since
// a range is a one-off scan, not something computed repeatedly per
// render like the month lookups are.
//
// Tax set-aside estimate card, right under Net — net for the active
// period × prefs.taxRatePercent, adjustable inline.
//
// Completion + exclude-from-reports gating. A saved document only counts
// toward Income, the invoice-status breakdown, the accepted-quote
// pipeline total, and Top Clients when it is 100% complete AND the user
// hasn't manually excluded it (InvoiceData/QuoteData/
// ReceiptData.excludeFromReports). See _isReportable(). Expenses have
// their own excludeFromReports gate, applied inside ExpenseProvider's
// totalForMonth/byCategoryForMonth/totalForRange/byCategoryForRange
// rather than here.
//
// Top Clients card — paid invoices + issued receipts for the active
// period, gated the same way, summed per client, top 5.
//
// Folder scope. A "Folder" selector sits next to the data-source toggle
// row, sourced from the same folderName field the "Move to Folder" action
// already writes on SavedInvoice/SavedQuote/SavedReceipt (see
// folders_grid_view.dart) — no new data model needed. Picking a folder
// narrows Income/Expenses(invoices/quotes/receipts side)/Net/trend/
// status-breakdown/Top Clients/the document list to only documents
// carrying that folder name; picking "All folders" (the default) is a
// no-op that reproduces prior behavior exactly. Expenses are NOT
// folder-filtered — expenses have no folderName field, same reasoning as
// why they're not gated by completion/exclude either (aside from the
// manual excludeFromReports flag, which is independent of folders).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense_data.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/receipt_provider.dart';
import '../saved_invoice_details_section/saved_document_detail_screen.dart';
import 'month_picker_sheet.dart';
import 'reports_client_statement.dart';
import 'reports_charts.dart';
import 'reports_document_list.dart';
import 'reports_pl_card.dart';
import 'reports_prefs.dart';
import 'reports_trend_chart.dart';
import 'reports_widgets.dart';

const Color kReportsAccent = Color(0xFF00897B);

// Accent colors for the "Documents in this period" cards — match the
// accents _showInvoiceMenu/_showQuoteMenu/_showReceiptMenu already use in
// saved_documents_section.dart, so a document reads the same color
// whether you're looking at it from Saved Documents or from Reports.
// Expenses use each entry's own category color instead of a single fixed
// accent (same reasoning the Expenses screen/Home's "My Expenses" section
// use), so there's no _kDocsExpenseAccent constant here.
const Color _kDocsInvoiceAccent = Color(0xFF1565C0);
const Color _kDocsQuoteAccent = Color(0xFF7B1FA2);
const Color _kDocsReceiptAccent = Color(0xFF2E7D32);

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
String _formatShortDate(DateTime dt) => '${dt.day} ${_shortMonths[dt.month - 1]} ${dt.year}';

DateTime? _parseFlexibleDate(String s) {
  final trimmed = s.trim();
  if (trimmed.isEmpty) return null;
  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return iso;
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final monthIdx = _shortMonths.indexWhere(
      (m) => m.toLowerCase() == parts[1].toLowerCase().substring(0, parts[1].length < 3 ? parts[1].length : 3),
    );
    final year = int.tryParse(parts[2]);
    if (day != null && monthIdx != -1 && year != null) {
      return DateTime(year, monthIdx + 1, day);
    }
  }
  return null;
}

// Shared gating rule: a saved document counts toward reporting totals only
// when it's fully filled out AND the user hasn't manually excluded it.
bool _isReportable(int completionPercent, bool excludeFromReports) =>
    completionPercent == 100 && !excludeFromReports;

// ── Status mapping for the rich "Documents in this period" cards ─────────
// Mirrors the label/color/positive-dot mapping used elsewhere in the app
// (saved_documents_containers.dart's _invoiceStatusInfo/_quoteStatusInfo/
// _receiptStatusInfo) so a document reads the same color and "positive"
// state whether viewed from Saved Documents or from Reports.

({String label, Color color, bool isPositive}) _reportsInvoiceStatusInfo(PaymentStatus s) {
  switch (s) {
    case PaymentStatus.paid:
      return (label: 'Paid', color: const Color(0xFF4CAF50), isPositive: true);
    case PaymentStatus.partial:
      return (label: 'Partial', color: const Color(0xFF2196F3), isPositive: false);
    case PaymentStatus.overdue:
      return (label: 'Overdue', color: const Color(0xFFE53935), isPositive: false);
    case PaymentStatus.unpaid:
      return (label: 'Unpaid', color: const Color(0xFFFF9800), isPositive: false);
  }
}

({String label, Color color, bool isPositive}) _reportsQuoteStatusInfo(QuoteStatus s) {
  switch (s) {
    case QuoteStatus.accepted:
      return (label: 'Accepted', color: const Color(0xFF4CAF50), isPositive: true);
    case QuoteStatus.sent:
      return (label: 'Sent', color: const Color(0xFF2196F3), isPositive: false);
    case QuoteStatus.declined:
      return (label: 'Declined', color: const Color(0xFFE53935), isPositive: false);
    case QuoteStatus.expired:
      return (label: 'Expired', color: const Color(0xFF9E9E9E), isPositive: false);
    case QuoteStatus.draft:
      return (label: 'Draft', color: const Color(0xFFFF9800), isPositive: false);
  }
}

({String label, Color color, bool isPositive}) _reportsReceiptStatusInfo(ReceiptStatus s) {
  switch (s) {
    case ReceiptStatus.issued:
      return (label: 'Issued', color: const Color(0xFF4CAF50), isPositive: true);
    case ReceiptStatus.refunded:
      return (label: 'Refunded', color: const Color(0xFFE53935), isPositive: false);
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  // Custom range state. Both non-null = range mode active, and it takes
  // priority over _month for the stat cards / breakdown / pipeline.
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool get _isRangeActive => _rangeStart != null && _rangeEnd != null;

  // Folder scope. null = "All folders" (no filtering, prior behavior).
  // Non-null narrows every document list to that folder before any
  // month/range bucketing happens.
  String? _selectedFolder;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String _monthLabel(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

  String _rangeLabel() {
    if (_rangeStart == null || _rangeEnd == null) return '';
    String fmt(DateTime d) => '${_monthNames[d.month - 1].substring(0, 3)} ${d.day}, ${d.year}';
    return '${fmt(_rangeStart!)} – ${fmt(_rangeEnd!)}';
  }

  String _monthKey(DateTime d) => '${d.year}-${d.month}';

  DateTime _monthsBefore(DateTime month, int n) => DateTime(month.year, month.month - n);

  Future<void> _openMonthPicker() async {
    final result = await showMonthPickerSheet(
      context,
      initialMonth: _month,
      initialRangeStart: _rangeStart,
      initialRangeEnd: _rangeEnd,
      // Uses the app's overall theme color (colorScheme.primary, seeded
      // from Color(0xFF1565C0) in main.dart) rather than this screen's
      // own kReportsAccent teal, so the picker's selected-day circles,
      // range band, mode toggle, and "Done" button match the rest of the
      // app instead of standing out in Reports-specific teal.
      accent: Theme.of(context).colorScheme.primary,
    );
    if (result == null) return;

    if (result.isRange) {
      setState(() {
        _rangeStart = result.rangeStart;
        _rangeEnd = result.rangeEnd;
      });
    } else if (result.month != null) {
      setState(() {
        _month = DateTime(result.month!.year, result.month!.month);
        _rangeStart = null;
        _rangeEnd = null;
      });
    }
  }

  void _clearRange() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  // Folder picker sheet — lists "All folders" plus every folder name
  // currently in use across invoices/quotes/receipts (folderNames is
  // computed fresh in build() from live provider data, then passed in
  // here). Mirrors the style of the existing rename/delete sheets used
  // elsewhere in the app.
  Future<void> _openFolderPicker(List<String> folderNames) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Report scope',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: Icon(Icons.dashboard_customize_rounded, color: kReportsAccent),
                      title: const Text('All folders', style: TextStyle(fontWeight: FontWeight.w700)),
                      trailing: _selectedFolder == null ? Icon(Icons.check_rounded, color: kReportsAccent) : null,
                      onTap: () => Navigator.pop(ctx, ''),
                    ),
                    if (folderNames.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Text(
                          'No folders yet. Create one from a document\'s ⋮ menu → "Move to Folder".',
                          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      )
                    else
                      for (final name in folderNames)
                        ListTile(
                          leading: Icon(Icons.folder_rounded, color: isDark ? colorScheme.onSurface.withValues(alpha: 0.6) : const Color(0xFF1565C0)),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          trailing: _selectedFolder == name ? Icon(Icons.check_rounded, color: kReportsAccent) : null,
                          onTap: () => Navigator.pop(ctx, name),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (picked == null) return; // dismissed without choosing
    setState(() => _selectedFolder = picked.isEmpty ? null : picked);
  }

  // ── One-time grouping helper (single-month mode) ───────────────────────

  Map<String, List<T>> _groupByMonth<T>(List<T> items, DateTime Function(T) dateOf) {
    final map = <String, List<T>>{};
    for (final item in items) {
      final d = dateOf(item);
      final key = '${d.year}-${d.month}';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  // Exact-bounds range filter — used when a custom range is active and by
  // the trend chart's per-bucket lookups, so it's fine that this is a
  // plain O(n) scan rather than a precomputed map.
  List<T> _filterByRange<T>(List<T> items, DateTime Function(T) dateOf, DateTime start, DateTime end) {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEndExclusive = DateTime(end.year, end.month, end.day + 1);
    return items.where((i) {
      final d = dateOf(i);
      return !d.isBefore(rangeStart) && d.isBefore(rangeEndExclusive);
    }).toList();
  }

  // ── Income breakdown (PROFIT & LOSS PASS): the single choke point for
  // "what counts as revenue and how much of it came from invoices vs
  // receipts". _sumIncome below just adds the two together, so every
  // existing caller (income, _incomeForMonth, _buildTrendPoints,
  // _topClientsTotals) keeps behaving exactly as before — this split only
  // adds a NEW way to read the same numbers, for the P&L card, without
  // touching what already consumes the combined total.
  ({double invoice, double receipt}) _incomeBreakdown({
    required List<SavedInvoice> invoices,
    required List<SavedReceipt> receipts,
    required ReportsPrefs prefs,
  }) {
    double invoiceTotal = 0;
    double receiptTotal = 0;
    if (prefs.includeInvoices) {
      invoiceTotal = invoices
          .where((i) =>
              i.data.paymentStatus == PaymentStatus.paid &&
              _isReportable(i.completionPercent, i.data.excludeFromReports))
          .fold(0.0, (s, i) => s + i.data.grandTotal);
    }
    if (prefs.includeReceipts) {
      receiptTotal = receipts
          .where((r) =>
              r.data.status == ReceiptStatus.issued &&
              _isReportable(r.completionPercent, r.data.excludeFromReports))
          .fold(0.0, (s, r) => s + r.data.amountPaid);
    }
    return (invoice: invoiceTotal, receipt: receiptTotal);
  }

  // Gated: paid invoices + issued receipts, but only the ones that are
  // 100% complete and not excluded. This is the single choke point for
  // "does this document count as income" — _incomeForMonth, the range
  // branch, and the trend chart's bucketing all funnel through here, so
  // trend/margin/current-period totals can never disagree about which
  // documents are reportable.
  double _sumIncome({
    required List<SavedInvoice> invoices,
    required List<SavedReceipt> receipts,
    required ReportsPrefs prefs,
  }) {
    final breakdown = _incomeBreakdown(invoices: invoices, receipts: receipts, prefs: prefs);
    return breakdown.invoice + breakdown.receipt;
  }

  // Gated: unpaid + overdue invoices only (deliberately excludes paid and
  // partial), 100% complete and not manually excluded — same
  // _isReportable gate as _sumIncome, so this can never disagree with the
  // rest of the screen about what counts as a "real" invoice. There's no
  // separate draft status to exclude here — a draft invoice simply has
  // completionPercent < 100, which _isReportable already filters out.
  double _sumUnpaid({
    required List<SavedInvoice> invoices,
    required ReportsPrefs prefs,
  }) {
    if (!prefs.includeInvoices) return 0.0;
    return invoices
        .where((i) =>
            (i.data.paymentStatus == PaymentStatus.unpaid ||
                i.data.paymentStatus == PaymentStatus.overdue) &&
            _isReportable(i.completionPercent, i.data.excludeFromReports))
        .fold(0.0, (s, i) => s + i.data.grandTotal);
  }

  // Average days between issue date (falls back to createdAt if issueDate
  // is unparseable) and paidDate, for paid + reportable invoices in the
  // given list. Returns null when there's nothing to average.
  double? _averageDaysToPaid(List<SavedInvoice> invoices) {
    final durations = <int>[];
    for (final inv in invoices) {
      if (inv.data.paymentStatus != PaymentStatus.paid) continue;
      if (!_isReportable(inv.completionPercent, inv.data.excludeFromReports)) continue;
      final paid = inv.data.paidDate;
      if (paid == null) continue;
      final issued = _parseFlexibleDate(inv.data.issueDate) ?? inv.createdAt;
      final days = paid.difference(issued).inDays;
      if (days >= 0) durations.add(days);
    }
    if (durations.isEmpty) return null;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  // Unpaid/overdue + reportable invoices in the given list, bucketed by
  // days past their due date. An invoice with no parseable due date, or a
  // due date that hasn't passed yet, is skipped here (it still counts in
  // _sumUnpaid's Total Unpaid figure - this is a breakdown of that same
  // total, not a separate gate).
  ({double d0to30, double d31to60, double d61plus}) _overdueAgingBuckets(List<SavedInvoice> invoices) {
    double b1 = 0, b2 = 0, b3 = 0;
    final now = DateTime.now();
    for (final inv in invoices) {
      final status = inv.data.paymentStatus;
      if (status != PaymentStatus.unpaid && status != PaymentStatus.overdue) continue;
      if (!_isReportable(inv.completionPercent, inv.data.excludeFromReports)) continue;
      final due = _parseFlexibleDate(inv.data.dueDate);
      if (due == null) continue;
      final daysOverdue = now.difference(due).inDays;
      if (daysOverdue <= 0) continue;
      final amt = inv.data.grandTotal;
      if (daysOverdue <= 30) {
        b1 += amt;
      } else if (daysOverdue <= 60) {
        b2 += amt;
      } else {
        b3 += amt;
      }
    }
    return (d0to30: b1, d31to60: b2, d61plus: b3);
  }

  double _incomeForMonth(
    DateTime month, {
    required Map<String, List<SavedInvoice>> invoicesByMonth,
    required Map<String, List<SavedReceipt>> receiptsByMonth,
    required ReportsPrefs prefs,
  }) {
    final key = _monthKey(month);
    return _sumIncome(
      invoices: invoicesByMonth[key] ?? const <SavedInvoice>[],
      receipts: receiptsByMonth[key] ?? const <SavedReceipt>[],
      prefs: prefs,
    );
  }

  // Client name -> total, gated the same way as _sumIncome (paid invoices
  // + issued receipts, 100% complete, not excluded). Kept separate from
  // _sumIncome rather than reusing its fold so each client name can be
  // tracked individually instead of collapsed into one sum.
  Map<String, double> _topClientsTotals({
    required List<SavedInvoice> invoices,
    required List<SavedReceipt> receipts,
    required ReportsPrefs prefs,
  }) {
    final totals = <String, double>{};
    if (prefs.includeInvoices) {
      for (final i in invoices.where((i) =>
          i.data.paymentStatus == PaymentStatus.paid &&
          _isReportable(i.completionPercent, i.data.excludeFromReports))) {
        final name = i.data.clientName.trim();
        if (name.isEmpty) continue;
        totals[name] = (totals[name] ?? 0) + i.data.grandTotal;
      }
    }
    if (prefs.includeReceipts) {
      for (final r in receipts.where((r) =>
          r.data.status == ReceiptStatus.issued &&
          _isReportable(r.completionPercent, r.data.excludeFromReports))) {
        final name = r.data.clientName.trim();
        if (name.isEmpty) continue;
        totals[name] = (totals[name] ?? 0) + r.data.amountPaid;
      }
    }
    return totals;
  }

  // ── Data for the collapsible trend chart (reports_trend_chart.dart).
  // Buckets the already folder-scoped invoices/receipts/expenses into
  // TrendRange.bucketCount points of TrendRange.bucketUnit width, anchored
  // on "today" (not the selected month/range — a multi-year trend
  // shouldn't jump around as you browse individual months). Reuses
  // _filterByRange/_sumIncome so this can never disagree with the rest of
  // the screen about what counts as income. Every source is gated by the
  // same DataSourceToggleRow chips (Invoices/Quotes/Receipts/Expenses)
  // that gate Income/Expenses/Net above — turning a chip off removes that
  // source from the chart too, not just the stat cards. Quotes never
  // factor into Net/Income here, same as everywhere else on this screen
  // (accepted quotes are shown separately as a pipeline total, never
  // counted as income).
  List<TrendChartPoint> _buildTrendPoints({
    required TrendMetric metric,
    required TrendRange range,
    required List<SavedInvoice> invoices,
    required List<SavedReceipt> receipts,
    required ExpenseProvider expenseProvider,
    required ReportsPrefs prefs,
  }) {
    final now = DateTime.now();
    final unit = range.bucketUnit;
    final count = range.bucketCount;
    final points = <TrendChartPoint>[];

    for (int i = count - 1; i >= 0; i--) {
      DateTime bucketStart;
      DateTime bucketEndInclusive;
      DateTime labelDate;

      switch (unit) {
        case TrendBucketUnit.day:
          final d = DateTime(now.year, now.month, now.day - i);
          bucketStart = d;
          bucketEndInclusive = d;
          labelDate = d;
          break;
        case TrendBucketUnit.week:
          final end = DateTime(now.year, now.month, now.day - i * 7);
          bucketStart = end.subtract(const Duration(days: 6));
          bucketEndInclusive = end;
          labelDate = end;
          break;
        case TrendBucketUnit.month:
          final m = DateTime(now.year, now.month - i, 1);
          bucketStart = DateTime(m.year, m.month, 1);
          bucketEndInclusive = DateTime(m.year, m.month + 1, 0);
          labelDate = bucketEndInclusive;
          break;
        case TrendBucketUnit.year:
          final y = now.year - i;
          bucketStart = DateTime(y, 1, 1);
          bucketEndInclusive = DateTime(y, 12, 31);
          labelDate = bucketEndInclusive;
          break;
      }

      final bucketInvoices = _filterByRange(invoices, (x) => x.createdAt, bucketStart, bucketEndInclusive);
      final bucketReceipts = _filterByRange(receipts, (x) => x.createdAt, bucketStart, bucketEndInclusive);
      final incomeVal = _sumIncome(invoices: bucketInvoices, receipts: bucketReceipts, prefs: prefs);
      final expenseVal = prefs.includeExpenses
          ? expenseProvider.totalForRange(bucketStart, bucketEndInclusive)
          : 0.0;

      final value = switch (metric) {
        TrendMetric.net => incomeVal - expenseVal,
        TrendMetric.income => incomeVal,
        TrendMetric.expenses => expenseVal,
      };

      points.add(TrendChartPoint(date: labelDate, value: value));
    }

    return points;
  }

  // ── Per-client statement of account. Builds the ledger lines from the
  // already-computed period lists (periodInvoices/periodReceipts) so it
  // can never disagree with the rest of the screen about the active
  // month/range/folder scope. Unlike Top Clients (which only sums PAID
  // invoices + issued receipts, i.e. realized income), a statement shows
  // every reportable invoice regardless of payment status — the whole
  // point of a statement is to show what's still owed, not just what's
  // been collected. Receipts still only count when issued, since a
  // refunded receipt isn't a payment received. Shared by both the
  // single-client tap (Top Clients rows) and the all-clients list below,
  // so both can never disagree about what belongs to a given client.
  List<ClientStatementLine> _statementLinesForClient(
    String clientName, {
    required List<SavedInvoice> periodInvoices,
    required List<SavedReceipt> periodReceipts,
  }) {
    final invoiceLines = periodInvoices
        .where((i) =>
            i.data.clientName.trim() == clientName &&
            _isReportable(i.completionPercent, i.data.excludeFromReports))
        .map((i) => ClientStatementLine(
              date: i.createdAt,
              label: i.title.isEmpty ? 'Invoice' : i.title,
              docTypeLabel: 'Invoice',
              amount: i.data.grandTotal,
              isPayment: false,
            ));

    final receiptLines = periodReceipts
        .where((r) =>
            r.data.clientName.trim() == clientName &&
            r.data.status == ReceiptStatus.issued &&
            _isReportable(r.completionPercent, r.data.excludeFromReports))
        .map((r) => ClientStatementLine(
              date: r.createdAt,
              label: r.title.isEmpty ? 'Receipt' : r.title,
              docTypeLabel: 'Receipt',
              amount: r.data.amountPaid,
              isPayment: true,
            ));

    return [...invoiceLines, ...receiptLines];
  }

  void _openClientStatement(
    String clientName, {
    required List<SavedInvoice> periodInvoices,
    required List<SavedReceipt> periodReceipts,
  }) {
    showClientStatementSheet(
      context,
      clientName: clientName,
      periodLabel: _isRangeActive ? _rangeLabel() : _monthLabel(_month),
      lines: _statementLinesForClient(
        clientName,
        periodInvoices: periodInvoices,
        periodReceipts: periodReceipts,
      ),
      isDark: Theme.of(context).brightness == Brightness.dark,
      accent: kReportsAccent,
    );
  }

  // ── All-clients statements list — the always-visible entry point.
  // Unlike _openClientStatement (reached by tapping a Top Clients row,
  // which only lists clients with PAID income), this includes ANY client
  // with a reportable invoice or issued receipt in the period, paid or
  // not — so a client who's been invoiced but hasn't paid yet still shows
  // up and is reachable even when Income is 0.00 and Top Clients isn't
  // rendered at all.
  void _openAllClientStatements({
    required List<SavedInvoice> periodInvoices,
    required List<SavedReceipt> periodReceipts,
  }) {
    final clientNames = <String>{
      for (final i in periodInvoices.where(
          (i) => _isReportable(i.completionPercent, i.data.excludeFromReports)))
        if (i.data.clientName.trim().isNotEmpty) i.data.clientName.trim(),
      for (final r in periodReceipts.where((r) =>
          r.data.status == ReceiptStatus.issued &&
          _isReportable(r.completionPercent, r.data.excludeFromReports)))
        if (r.data.clientName.trim().isNotEmpty) r.data.clientName.trim(),
    };

    final summaries = clientNames
        .map((name) => ClientStatementSummary.fromLines(
              name,
              _statementLinesForClient(
                name,
                periodInvoices: periodInvoices,
                periodReceipts: periodReceipts,
              ),
            ))
        .toList()
      ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));

    showClientStatementsListSheet(
      context,
      periodLabel: _isRangeActive ? _rangeLabel() : _monthLabel(_month),
      summaries: summaries,
      isDark: Theme.of(context).brightness == Brightness.dark,
      accent: kReportsAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAll = context.watch<InvoiceProvider>().savedInvoices;
    final quotesAll = context.watch<QuoteProvider>().savedQuotes;
    final receiptsAll = context.watch<ReceiptProvider>().savedReceipts;
    final expenseProvider = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final prefs = context.watch<ReportsPrefs>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!prefs.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Every folder name currently in use across all three document types,
    // for the folder picker sheet. Computed fresh each build from live
    // provider data — cheap (folders are a handful, not thousands) and
    // guarantees the picker never shows a stale/deleted folder name.
    final folderNames = <String>{
      for (final i in invoicesAll)
        if ((i.folderName ?? '').trim().isNotEmpty) i.folderName!.trim(),
      for (final q in quotesAll)
        if ((q.folderName ?? '').trim().isNotEmpty) q.folderName!.trim(),
      for (final r in receiptsAll)
        if ((r.folderName ?? '').trim().isNotEmpty) r.folderName!.trim(),
    }.toList()
      ..sort();

    // If the previously-selected folder no longer exists (renamed/deleted
    // elsewhere in the app), fall back to "All folders" rather than
    // silently reporting on an empty, invisible scope.
    if (_selectedFolder != null && !folderNames.contains(_selectedFolder)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedFolder = null);
      });
    }

    // Folder scope applied here, before any month/range bucketing —
    // everything below this point (invoicesByMonth, range filtering, the
    // trend chart's per-bucket lookups) operates on these already-narrowed
    // lists, so the folder scope composes automatically with both
    // single-month and custom-range mode without touching that logic.
    final invoices = _selectedFolder == null
        ? invoicesAll
        : invoicesAll.where((i) => i.folderName == _selectedFolder).toList();
    final quotes = _selectedFolder == null
        ? quotesAll
        : quotesAll.where((q) => q.folderName == _selectedFolder).toList();
    final receipts = _selectedFolder == null
        ? receiptsAll
        : receiptsAll.where((r) => r.folderName == _selectedFolder).toList();

    final invoicesByMonth = _groupByMonth<SavedInvoice>(invoices, (i) => i.createdAt);
    final receiptsByMonth = _groupByMonth<SavedReceipt>(receipts, (r) => r.createdAt);
    final quotesByMonth = _groupByMonth<SavedQuote>(quotes, (q) => q.createdAt);

    // ── Current period figures — either the active custom range, or the
    // single selected month (unchanged behavior). periodExpenses/
    // expensesThisMonth respect prefs.includeExpenses, same pattern as
    // includeInvoices/includeQuotes gating income above. ─────────────
    late final List<SavedInvoice> periodInvoices;
    late final List<SavedReceipt> periodReceipts;
    late final List<SavedQuote> periodQuotes;
    late final List<ExpenseEntry> periodExpenses;
    late final double income;
    late final double expensesThisMonth;

    if (_isRangeActive) {
      periodInvoices = _filterByRange(invoices, (i) => i.createdAt, _rangeStart!, _rangeEnd!);
      periodReceipts = _filterByRange(receipts, (r) => r.createdAt, _rangeStart!, _rangeEnd!);
      periodQuotes = _filterByRange(quotes, (q) => q.createdAt, _rangeStart!, _rangeEnd!);
      periodExpenses = prefs.includeExpenses
          ? expenseProvider.forRange(_rangeStart!, _rangeEnd!)
          : const <ExpenseEntry>[];
      income = _sumIncome(invoices: periodInvoices, receipts: periodReceipts, prefs: prefs);
      expensesThisMonth = prefs.includeExpenses
          ? expenseProvider.totalForRange(_rangeStart!, _rangeEnd!)
          : 0.0;
    } else {
      final monthKey = _monthKey(_month);
      periodInvoices = invoicesByMonth[monthKey] ?? const <SavedInvoice>[];
      periodReceipts = receiptsByMonth[monthKey] ?? const <SavedReceipt>[];
      periodQuotes = quotesByMonth[monthKey] ?? const <SavedQuote>[];
      periodExpenses = prefs.includeExpenses ? expenseProvider.forMonth(_month) : const <ExpenseEntry>[];
      income = _incomeForMonth(_month, invoicesByMonth: invoicesByMonth, receiptsByMonth: receiptsByMonth, prefs: prefs);
      expensesThisMonth = prefs.includeExpenses ? expenseProvider.totalForMonth(_month) : 0.0;
    }

    // Revenue split for the P&L card — same gating, same period list as
    // `income` above, just broken into its two sources instead of one
    // combined figure. See _incomeBreakdown's doc comment.
    final incomeBreakdown = _incomeBreakdown(invoices: periodInvoices, receipts: periodReceipts, prefs: prefs);

    // Total unpaid — unpaid + overdue invoices for the active period, same
    // gating (100% complete, not excluded) and same folder/month/range
    // scope as everything else above. See _sumUnpaid's doc comment.
    final totalUnpaid = _sumUnpaid(invoices: periodInvoices, prefs: prefs);

    final agingBuckets = prefs.includeInvoices
        ? _overdueAgingBuckets(periodInvoices)
        : (d0to30: 0.0, d31to60: 0.0, d61plus: 0.0);
    final avgDaysToPaid = prefs.includeInvoices ? _averageDaysToPaid(periodInvoices) : null;

    // Gated: only 100%-complete, non-excluded accepted quotes count toward
    // the pipeline figure shown under Net.
    final acceptedQuotesThisPeriod = periodQuotes
        .where((q) =>
            q.data.quoteStatus == QuoteStatus.accepted &&
            _isReportable(q.completionPercent, q.data.excludeFromReports))
        .toList();
    final quotePipeline = prefs.includeQuotes
        ? acceptedQuotesThisPeriod.fold(0.0, (s, q) => s + q.data.grandTotal)
        : 0.0;

    final net = income - expensesThisMonth;

    // Category breakdown respects the Expenses toggle too — off means an
    // empty breakdown, consistent with the $0 Expenses stat card.
    final byCategory = !prefs.includeExpenses
        ? const <String, double>{}
        : (_isRangeActive
            ? expenseProvider.byCategoryForRange(_rangeStart!, _rangeEnd!)
            : expenseProvider.byCategoryForMonth(_month));
    final sortedCategoryEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCategoryAmount = sortedCategoryEntries.isEmpty ? 1.0 : sortedCategoryEntries.first.value;

    // Top Clients — gated the same way as income, top 5 by total.
    final topClientsEntries = _topClientsTotals(
      invoices: periodInvoices,
      receipts: periodReceipts,
      prefs: prefs,
    ).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topClientsTop5 = topClientsEntries.take(5).toList();

    // ── Net margin badge — only meaningful for single-month mode; a
    // "previous period" comparison doesn't have an obvious definition for
    // an arbitrary custom range, so it's hidden in range mode. ─────────
    double? netChangePercent;
    if (!_isRangeActive) {
      final prevMonth = _monthsBefore(_month, 1);
      final prevIncome = _incomeForMonth(prevMonth, invoicesByMonth: invoicesByMonth, receiptsByMonth: receiptsByMonth, prefs: prefs);
      final prevExpenses = prefs.includeExpenses ? expenseProvider.totalForMonth(prevMonth) : 0.0;
      final prevNet = prevIncome - prevExpenses;
      if (prevNet != 0) {
        netChangePercent = ((net - prevNet) / prevNet.abs()) * 100;
      } else if (net != 0) {
        netChangePercent = net > 0 ? 100 : -100;
      }
    }

    // ── Invoice status breakdown — gated the same way as income. ────────
    final statusTotals = <String, double>{};
    if (prefs.includeInvoices) {
      for (final inv in periodInvoices.where(
          (i) => _isReportable(i.completionPercent, i.data.excludeFromReports))) {
        final label = inv.data.paymentStatus.name;
        statusTotals[label] = (statusTotals[label] ?? 0) + inv.data.grandTotal;
      }
    }
    final statusSegments = statusTotals.entries
        .map((e) => StatusSegment(label: e.key, amount: e.value, color: colorForStatusLabel(e.key)))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // ── "Documents in this period" — one ReportsDocumentItem per
    // invoice/quote/receipt/expense in the current period, respecting the
    // existing data-source toggles, all rendered with the same rich card
    // visual language as the Saved Documents section on the home screen
    // via a single ReportsDocumentSection below, grouped into per-type
    // sections matching Home exactly. Sorted biggest-first here as the
    // baseline order (ReportsDocumentSection re-sorts within each group
    // per its own sort control). ─────────────────────────────────────
    final List<ReportsDocumentItem> docItems = [];

    if (prefs.includeInvoices) {
      for (final inv in periodInvoices) {
        final info = _reportsInvoiceStatusInfo(inv.data.paymentStatus);
        final isPaid = inv.data.paymentStatus == PaymentStatus.paid;
        docItems.add(ReportsDocumentItem(
          key: 'invoice:${inv.id}',
          docType: ReportsDocType.invoice,
          title: inv.title,
          templateName: inv.templateName,
          editedLabel: _formatShortDate(inv.lastEditedAt),
          secondaryDateLabel: isPaid ? 'Paid' : 'Due',
          secondaryDateValue: isPaid
              ? (inv.data.paidDate != null ? _formatShortDate(inv.data.paidDate!) : '—')
              : (inv.data.dueDate.isEmpty ? '—' : inv.data.dueDate),
          createdLabel: _formatShortDate(inv.createdAt),
          itemCount: inv.data.lineItems.length,
          completionPercent: inv.completionPercent,
          amount: inv.data.grandTotal,
          statusLabel: info.label,
          statusColor: info.color,
          accentColor: _kDocsInvoiceAccent,
          logoPath: inv.data.businessLogoPath,
          businessName: inv.data.businessName,
          isPositiveStatus: info.isPositive,
          excludedFromReports: inv.data.excludeFromReports,
          countsTowardReports: _isReportable(inv.completionPercent, inv.data.excludeFromReports),
          sortDate: inv.lastEditedAt,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SavedDocumentDetailScreen.invoice(inv)),
          ),
          onToggleExclude: (v) =>
              context.read<InvoiceProvider>().updateInvoiceExcludeFromReports(inv.id, v),
        ));
      }
    }
    if (prefs.includeQuotes) {
      for (final q in periodQuotes) {
        final info = _reportsQuoteStatusInfo(q.data.quoteStatus);
        docItems.add(ReportsDocumentItem(
          key: 'quote:${q.id}',
          docType: ReportsDocType.quote,
          title: q.title,
          templateName: q.templateName,
          editedLabel: _formatShortDate(q.lastEditedAt),
          secondaryDateLabel: 'Expires',
          secondaryDateValue: q.data.expiryDate.isEmpty ? '—' : q.data.expiryDate,
          createdLabel: _formatShortDate(q.createdAt),
          itemCount: q.data.lineItems.length,
          completionPercent: q.completionPercent,
          amount: q.data.grandTotal,
          statusLabel: info.label,
          statusColor: info.color,
          accentColor: _kDocsQuoteAccent,
          logoPath: q.data.businessLogoPath,
          businessName: q.data.businessName,
          isPositiveStatus: info.isPositive,
          excludedFromReports: q.data.excludeFromReports,
          countsTowardReports: _isReportable(q.completionPercent, q.data.excludeFromReports),
          sortDate: q.lastEditedAt,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SavedDocumentDetailScreen.quote(q)),
          ),
          onToggleExclude: (v) =>
              context.read<QuoteProvider>().updateQuoteExcludeFromReports(q.id, v),
        ));
      }
    }
    if (prefs.includeReceipts) {
      for (final r in periodReceipts) {
        final info = _reportsReceiptStatusInfo(r.data.status);
        docItems.add(ReportsDocumentItem(
          key: 'receipt:${r.id}',
          docType: ReportsDocType.receipt,
          title: r.title,
          templateName: r.templateName,
          editedLabel: _formatShortDate(r.lastEditedAt),
          secondaryDateLabel: 'Paid',
          secondaryDateValue: r.data.paymentDate.isEmpty ? '—' : r.data.paymentDate,
          createdLabel: _formatShortDate(r.createdAt),
          itemCount: r.data.lineItems.length,
          completionPercent: r.completionPercent,
          amount: r.data.amountPaid,
          statusLabel: info.label,
          statusColor: info.color,
          accentColor: _kDocsReceiptAccent,
          logoPath: r.data.businessLogoPath,
          businessName: r.data.businessName,
          isPositiveStatus: info.isPositive,
          excludedFromReports: r.data.excludeFromReports,
          countsTowardReports: _isReportable(r.completionPercent, r.data.excludeFromReports),
          sortDate: r.lastEditedAt,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SavedDocumentDetailScreen.receipt(r)),
          ),
          onToggleExclude: (v) =>
              context.read<ReceiptProvider>().updateReceiptExcludeFromReports(r.id, v),
        ));
      }
    }
    // Expenses — merged into the same unified list. No completion concept
    // (countsTowardReports is simply !excludeFromReports), no payment-
    // style status (statusLabel is empty unless excluded, which shows an
    // "Excluded" chip — see reports_document_list.dart), category color
    // stands in as the per-item accent, and the manually-entered
    // reference number (if any) shows in place of an item count via
    // referenceLabel. periodExpenses is already empty when
    // prefs.includeExpenses is false, so this loop naturally contributes
    // nothing in that case.
    for (final e in periodExpenses) {
      final category = categories.byId(e.categoryId);
      final ref = e.referenceNumber?.trim() ?? '';
      docItems.add(ReportsDocumentItem(
        key: 'expense:${e.id}',
        docType: ReportsDocType.expense,
        title: e.vendor.trim().isEmpty ? 'Expense' : e.vendor.trim(),
        templateName: category.name,
        editedLabel: _formatShortDate(e.lastEditedAt),
        secondaryDateLabel: 'Date',
        secondaryDateValue: _formatShortDate(e.date),
        createdLabel: _formatShortDate(e.createdAt),
        itemCount: 0,
        completionPercent: 100,
        amount: e.amount,
        statusLabel: e.excludeFromReports ? 'Excluded' : '',
        statusColor: const Color(0xFFE53935),
        accentColor: category.color,
        logoPath: e.logoPath,
        businessName: e.vendor,
        isPositiveStatus: false,
        excludedFromReports: e.excludeFromReports,
        countsTowardReports: !e.excludeFromReports,
        sortDate: e.lastEditedAt,
        referenceLabel: ref.isEmpty ? null : 'Ref: $ref',
        onTap: () {},
        onToggleExclude: (v) =>
            context.read<ExpenseProvider>().updateExpenseExcludeFromReports(e.id, v),
      ));
    }
    docItems.sort((a, b) => b.amount.compareTo(a.amount));

    final hasAnyDataThisMonth = periodInvoices.isNotEmpty ||
        periodReceipts.isNotEmpty ||
        periodQuotes.isNotEmpty ||
        periodExpenses.isNotEmpty ||
        acceptedQuotesThisPeriod.isNotEmpty ||
        sortedCategoryEntries.isNotEmpty;

    final animationSignature =
        '${_isRangeActive}-${_rangeStart}-${_rangeEnd}-${_month.year}-${_month.month}-${prefs.includeInvoices}-${prefs.includeQuotes}-${prefs.includeReceipts}-${prefs.includeExpenses}-$_selectedFolder';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // ── Hero card — period selector, folder scope, and the
          // data-source toggle row, all inside the same dark gradient
          // card HomeScreen's banner uses, so Reports opens with the
          // same visual weight as Home instead of a flat teal AppBar. ──
          ReportsHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period selector — either month chevrons + label, or the
                // active range label + a clear button. White-on-dark
                // styling since this now sits on the gradient card.
                if (_isRangeActive)
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _openMonthPicker,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range_rounded, size: 16, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _rangeLabel(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        tooltip: 'Clear range',
                        onPressed: _clearRange,
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                        onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _openMonthPicker,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _monthLabel(_month),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.expand_more_rounded, size: 18, color: Colors.white54),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                        onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),

                // Folder scope selector — white-on-dark translucent chip.
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openFolderPicker(folderNames),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: _selectedFolder != null
                            ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_rounded, size: 15, color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFolder ?? 'All folders',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedFolder != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedFolder = null),
                              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                            )
                          else
                            const Icon(Icons.expand_more_rounded, size: 16, color: Colors.white54),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                DataSourceToggleRow(
                  includeInvoices: prefs.includeInvoices,
                  includeQuotes: prefs.includeQuotes,
                  includeReceipts: prefs.includeReceipts,
                  includeExpenses: prefs.includeExpenses,
                  onInvoicesChanged: (v) => prefs.setIncludeInvoices(v),
                  onQuotesChanged: (v) => prefs.setIncludeQuotes(v),
                  onReceiptsChanged: (v) => prefs.setIncludeReceipts(v),
                  onExpensesChanged: (v) => prefs.setIncludeExpenses(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Collapsible Net/Income/Expenses trend chart — 1W up to 10Y,
          // green/red % change badge, tap-and-drag scrub. Sits right below
          // the hero card and above the Income/Expenses/Net stat cards, so
          // it reads as "here's the shape of the numbers below." Anchored
          // on "today", not the period selector above (see
          // _buildTrendPoints doc comment) — and shown regardless of
          // whether the selected month has data, since it isn't scoped to
          // that month anyway. Replaces the old static 6-month TrendStrip.
          ReportsTrendChartCard(
            isDark: isDark,
            initiallyExpanded: false,
            pointsBuilder: (metric, range) => _buildTrendPoints(
              metric: metric,
              range: range,
              invoices: invoices,
              receipts: receipts,
              expenseProvider: expenseProvider,
              prefs: prefs,
            ),
          ),
          const SizedBox(height: 16),

          if (!hasAnyDataThisMonth) ...[
            ReportsEmptyState(isDark: isDark),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ReportsStatCard(
                    label: 'Income',
                    value: income,
                    color: const Color(0xFF4CAF50),
                    isDark: isDark,
                    animationKey: '$animationSignature-income',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReportsStatCard(
                    label: 'Expenses',
                    value: expensesThisMonth,
                    color: const Color(0xFFE53935),
                    isDark: isDark,
                    animationKey: '$animationSignature-expenses',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReportsStatCard(
              label: 'Net',
              value: net,
              color: net >= 0 ? const Color(0xFF2196F3) : const Color(0xFFE53935),
              isDark: isDark,
              wide: true,
              animationKey: '$animationSignature-net',
              trailing: NetMarginBadge(percentChange: netChangePercent),
            ),
            const SizedBox(height: 12),

            // ── Profit & Loss statement — new section, sits right under
            // Net so the headline number (Net) is immediately followed by
            // the structured breakdown explaining how it was arrived at.
            // Fed the exact same income breakdown / category totals every
            // other card on this screen already computes, so it can never
            // disagree with Income/Expenses/Net or "Expenses by category"
            // further down.
            ProfitLossCard(
              periodLabel: _isRangeActive ? _rangeLabel() : _monthLabel(_month),
              invoiceRevenue: incomeBreakdown.invoice,
              receiptRevenue: incomeBreakdown.receipt,
              expensesByCategory: [
                for (final entry in sortedCategoryEntries)
                  ProfitLossCategoryLine(category: categories.byId(entry.key), amount: entry.value),
              ],
              isDark: isDark,
              accent: kReportsAccent,
            ),
            const SizedBox(height: 12),

            if (!_isRangeActive)
              IncomeGoalCard(
                income: income,
                goal: prefs.monthlyIncomeGoal,
                isDark: isDark,
                accent: kReportsAccent,
                onGoalChanged: (v) => prefs.setMonthlyIncomeGoal(v),
              ),
            const SizedBox(height: 12),

            // Total Unpaid — unpaid + overdue invoices for the active
            // period. Sits directly under Net, same wide-card treatment,
            // amber to match the "Unpaid" status color used elsewhere on
            // this screen (_reportsInvoiceStatusInfo) and in Saved
            // Documents.
            ReportsStatCard(
              label: 'Total Unpaid',
              value: totalUnpaid,
              color: const Color(0xFFFF9800),
              isDark: isDark,
              wide: true,
              animationKey: '$animationSignature-unpaid',
            ),
            const SizedBox(height: 12),
            AgingBucketsCard(
              d0to30: agingBuckets.d0to30,
              d31to60: agingBuckets.d31to60,
              d61plus: agingBuckets.d61plus,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            DaysToPaidCard(
              averageDays: avgDaysToPaid,
              isDark: isDark,
              accent: kReportsAccent,
            ),
            const SizedBox(height: 12),

            TaxSetAsideCard(
              net: net,
              taxRatePercent: prefs.taxRatePercent,
              isDark: isDark,
              accent: kReportsAccent,
              onRateChanged: (v) => prefs.setTaxRatePercent(v),
            ),
            const SizedBox(height: 12),

            if (prefs.includeQuotes)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.request_quote_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Accepted quotes ${_isRangeActive ? 'in this range' : 'this month'} (not counted as income): '
                        '${acceptedQuotesThisPeriod.length} · ${quotePipeline.toStringAsFixed(2)} total',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Insight cards — Top Clients and Expenses by category
            // moved up here (above "Documents in this period") so the
            // higher-level summaries sit together right after the
            // stat/tax cards, and the raw per-document list reads as the
            // detail underneath them rather than something to scroll
            // past to reach the summaries.
            //
            // ClientStatementsEntryRow is deliberately OUTSIDE the
            // topClientsTop5 check below — Top Clients only lists clients
            // with PAID income, so on a month with $0 collected (like
            // this one) it doesn't render at all and there'd be no way to
            // reach a statement. This row stays visible any time there's
            // period data at all, and opens the full client list rather
            // than a single client.
            ClientStatementsEntryRow(
              isDark: isDark,
              accent: kReportsAccent,
              onTap: () => _openAllClientStatements(
                periodInvoices: periodInvoices,
                periodReceipts: periodReceipts,
              ),
            ),
            const SizedBox(height: 12),

            if (topClientsTop5.isNotEmpty) ...[
              ReportsTopClientsCard(
                entries: topClientsTop5,
                isDark: isDark,
                accent: kReportsAccent,
                onClientTap: (name) => _openClientStatement(
                  name,
                  periodInvoices: periodInvoices,
                  periodReceipts: periodReceipts,
                ),
              ),
              const SizedBox(height: 24),
            ],

            ReportsSectionHeader(title: 'Expenses by category'),
            const SizedBox(height: 12),
            if (sortedCategoryEntries.isEmpty)
              Text(
                !prefs.includeExpenses
                    ? 'Expenses are turned off for this report.'
                    : 'No expenses recorded ${_isRangeActive ? 'in this range' : 'this month'}.',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
              )
            else
              for (final entry in sortedCategoryEntries)
                CategoryBarRow(
                  category: categories.byId(entry.key),
                  amount: entry.value,
                  fraction: entry.value / maxCategoryAmount,
                ),
            const SizedBox(height: 24),

            // The saved documents (invoices, quotes, receipts, AND
            // expenses now) behind Income/Expenses/the status breakdown/
            // the quote pipeline, grouped into My Invoices/My Quotes/My
            // Receipts/My Expenses sections matching Home exactly, with a
            // visible include/exclude checkbox and a single shared layout
            // control (SavedLayoutPrefs — the same preference Home's
            // Saved Documents dropdown writes to).
            ReportsDocumentSection(
              title: 'Documents in this period',
              items: docItems,
              isDark: isDark,
              emptyLabel: 'No invoices, quotes, receipts, or expenses in this period.',
            ),
            const SizedBox(height: 24),

            if (statusSegments.isNotEmpty) ...[
              StatusBreakdownBar(title: 'Invoice value by status', segments: statusSegments, isDark: isDark),
              const SizedBox(height: 24),
            ],
          ],
        ],
      ),
    );
  }
}
