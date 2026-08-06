// reports_screen.dart
// lib/screens/reports/reports_screen.dart
//
// NEW (this pass): custom date-range filtering. When a range is picked via
// month_picker_sheet.dart's new range mode, Income/Expenses/Net/quote-
// pipeline/invoice-status/category-breakdown all total against the exact
// range instead of the single selected month. The 6-month trend strip
// intentionally still shows monthly cadence around _month regardless — a
// "6-month trend" doesn't make sense to redefine around an arbitrary
// range, so it's called out with a small caption instead of silently
// guessing what the person wants there.
//
// The month/day bucketing (_groupByMonth, invoicesByMonth, etc.) is kept
// for single-month mode and the trend strip's perf benefit; range mode
// filters the raw lists directly since a range is a one-off scan, not
// something computed 6-8 times per render like the month lookups are.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/receipt_provider.dart';
import 'month_picker_sheet.dart';
import 'reports_charts.dart';
import 'reports_prefs.dart';
import 'reports_widgets.dart';

const Color kReportsAccent = Color(0xFF00897B);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  // NEW: custom range state. Both non-null = range mode active, and it
  // takes priority over _month for the stat cards / breakdown / pipeline.
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool get _isRangeActive => _rangeStart != null && _rangeEnd != null;

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
      accent: kReportsAccent,
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

  // ── One-time grouping helper (single-month mode + trend strip) ─────────

  Map<String, List<T>> _groupByMonth<T>(List<T> items, DateTime Function(T) dateOf) {
    final map = <String, List<T>>{};
    for (final item in items) {
      final d = dateOf(item);
      final key = '${d.year}-${d.month}';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  // NEW: exact-bounds range filter — used only when a custom range is
  // active, so it's fine that this is a plain O(n) scan rather than a
  // precomputed map.
  List<T> _filterByRange<T>(List<T> items, DateTime Function(T) dateOf, DateTime start, DateTime end) {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEndExclusive = DateTime(end.year, end.month, end.day + 1);
    return items.where((i) {
      final d = dateOf(i);
      return !d.isBefore(rangeStart) && d.isBefore(rangeEndExclusive);
    }).toList();
  }

  double _sumIncome({
    required List<SavedInvoice> invoices,
    required List<SavedReceipt> receipts,
    required ReportsPrefs prefs,
  }) {
    double total = 0;
    if (prefs.includeInvoices) {
      total += invoices
          .where((i) => i.data.paymentStatus == PaymentStatus.paid)
          .fold(0.0, (s, i) => s + i.data.grandTotal);
    }
    if (prefs.includeReceipts) {
      total += receipts
          .where((r) => r.data.status == ReceiptStatus.issued)
          .fold(0.0, (s, r) => s + r.data.amountPaid);
    }
    return total;
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

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().savedInvoices;
    final quotes = context.watch<QuoteProvider>().savedQuotes;
    final receipts = context.watch<ReceiptProvider>().savedReceipts;
    final expenseProvider = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final prefs = context.watch<ReportsPrefs>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!prefs.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final invoicesByMonth = _groupByMonth<SavedInvoice>(invoices, (i) => i.createdAt);
    final receiptsByMonth = _groupByMonth<SavedReceipt>(receipts, (r) => r.createdAt);
    final quotesByMonth = _groupByMonth<SavedQuote>(quotes, (q) => q.createdAt);

    // ── Current period figures — either the active custom range, or the
    // single selected month (unchanged behavior). ──────────────────────
    late final List<SavedInvoice> periodInvoices;
    late final List<SavedReceipt> periodReceipts;
    late final List<SavedQuote> periodQuotes;
    late final double income;
    late final double expensesThisMonth;

    if (_isRangeActive) {
      periodInvoices = _filterByRange(invoices, (i) => i.createdAt, _rangeStart!, _rangeEnd!);
      periodReceipts = _filterByRange(receipts, (r) => r.createdAt, _rangeStart!, _rangeEnd!);
      periodQuotes = _filterByRange(quotes, (q) => q.createdAt, _rangeStart!, _rangeEnd!);
      income = _sumIncome(invoices: periodInvoices, receipts: periodReceipts, prefs: prefs);
      expensesThisMonth = expenseProvider.totalForRange(_rangeStart!, _rangeEnd!);
    } else {
      final monthKey = _monthKey(_month);
      periodInvoices = invoicesByMonth[monthKey] ?? const <SavedInvoice>[];
      periodReceipts = receiptsByMonth[monthKey] ?? const <SavedReceipt>[];
      periodQuotes = quotesByMonth[monthKey] ?? const <SavedQuote>[];
      income = _incomeForMonth(_month, invoicesByMonth: invoicesByMonth, receiptsByMonth: receiptsByMonth, prefs: prefs);
      expensesThisMonth = expenseProvider.totalForMonth(_month);
    }

    final acceptedQuotesThisPeriod =
        periodQuotes.where((q) => q.data.quoteStatus == QuoteStatus.accepted).toList();
    final quotePipeline = prefs.includeQuotes
        ? acceptedQuotesThisPeriod.fold(0.0, (s, q) => s + q.data.grandTotal)
        : 0.0;

    final net = income - expensesThisMonth;

    final byCategory = _isRangeActive
        ? expenseProvider.byCategoryForRange(_rangeStart!, _rangeEnd!)
        : expenseProvider.byCategoryForMonth(_month);
    final sortedCategoryEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCategoryAmount = sortedCategoryEntries.isEmpty ? 1.0 : sortedCategoryEntries.first.value;

    // ── Net margin badge — only meaningful for single-month mode; a
    // "previous period" comparison doesn't have an obvious definition for
    // an arbitrary custom range, so it's hidden in range mode. ─────────
    double? netChangePercent;
    if (!_isRangeActive) {
      final prevMonth = _monthsBefore(_month, 1);
      final prevIncome = _incomeForMonth(prevMonth, invoicesByMonth: invoicesByMonth, receiptsByMonth: receiptsByMonth, prefs: prefs);
      final prevExpenses = expenseProvider.totalForMonth(prevMonth);
      final prevNet = prevIncome - prevExpenses;
      if (prevNet != 0) {
        netChangePercent = ((net - prevNet) / prevNet.abs()) * 100;
      } else if (net != 0) {
        netChangePercent = net > 0 ? 100 : -100;
      }
    }

    // ── 6-month trend strip — always anchored on _month regardless of an
    // active range (see file header comment). ──────────────────────────
    final trendPoints = <MonthTrendPoint>[
      for (int i = 5; i >= 0; i--)
        MonthTrendPoint(
          month: _monthsBefore(_month, i),
          income: _incomeForMonth(_monthsBefore(_month, i), invoicesByMonth: invoicesByMonth, receiptsByMonth: receiptsByMonth, prefs: prefs),
          expenses: expenseProvider.totalForMonth(_monthsBefore(_month, i)),
        ),
    ];

    // ── Invoice status breakdown ─────────────────────────────────────────
    final statusTotals = <String, double>{};
    if (prefs.includeInvoices) {
      for (final inv in periodInvoices) {
        final label = inv.data.paymentStatus.name;
        statusTotals[label] = (statusTotals[label] ?? 0) + inv.data.grandTotal;
      }
    }
    final statusSegments = statusTotals.entries
        .map((e) => StatusSegment(label: e.key, amount: e.value, color: colorForStatusLabel(e.key)))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final hasAnyDataThisMonth = periodInvoices.isNotEmpty ||
        periodReceipts.isNotEmpty ||
        acceptedQuotesThisPeriod.isNotEmpty ||
        sortedCategoryEntries.isNotEmpty;

    final animationSignature =
        '${_isRangeActive}-${_rangeStart}-${_rangeEnd}-${_month.year}-${_month.month}-${prefs.includeInvoices}-${prefs.includeQuotes}-${prefs.includeReceipts}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: kReportsAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // ── Period selector — either month chevrons + label, or the
          // active range label + a clear button. ─────────────────────
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.date_range_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _rangeLabel(),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
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
                  icon: const Icon(Icons.close_rounded),
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
                  icon: const Icon(Icons.chevron_left_rounded),
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.45)),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                ),
              ],
            ),
          const SizedBox(height: 12),

          DataSourceToggleRow(
            includeInvoices: prefs.includeInvoices,
            includeQuotes: prefs.includeQuotes,
            includeReceipts: prefs.includeReceipts,
            accent: kReportsAccent,
            onInvoicesChanged: (v) => prefs.setIncludeInvoices(v),
            onQuotesChanged: (v) => prefs.setIncludeQuotes(v),
            onReceiptsChanged: (v) => prefs.setIncludeReceipts(v),
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

            if (prefs.includeQuotes)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.request_quote_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Accepted quotes ${_isRangeActive ? 'in this range' : 'this month'} (not counted as income): '
                        '${acceptedQuotesThisPeriod.length} · ${quotePipeline.toStringAsFixed(2)} total',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            const ReportsSectionHeader(title: '6-month trend'),
            if (_isRangeActive) ...[
              const SizedBox(height: 4),
              Text(
                'Always shows the trend around the month view, independent of the active range above.',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.4)),
              ),
            ],
            const SizedBox(height: 10),
            TrendStrip(points: trendPoints, isDark: isDark),
            const SizedBox(height: 24),

            if (statusSegments.isNotEmpty) ...[
              StatusBreakdownBar(title: 'Invoice value by status', segments: statusSegments, isDark: isDark),
              const SizedBox(height: 24),
            ],

            ReportsSectionHeader(title: 'Expenses by category'),
            const SizedBox(height: 12),
            if (sortedCategoryEntries.isEmpty)
              Text(
                'No expenses recorded ${_isRangeActive ? 'in this range' : 'this month'}.',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.45)),
              )
            else
              for (final entry in sortedCategoryEntries)
                CategoryBarRow(
                  category: categories.byId(entry.key),
                  amount: entry.value,
                  fraction: entry.value / maxCategoryAmount,
                ),
          ],
        ],
      ),
    );
  }
}
