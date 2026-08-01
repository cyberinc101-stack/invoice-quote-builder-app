// lib/screens/reports_screen.dart
//
// Pulls from InvoiceProvider/QuoteProvider/ReceiptProvider (fields confirmed
// against saved_document_detail_screen.dart: savedInvoices/.data.grandTotal/
// .data.paymentStatus/.createdAt, savedQuotes/.data.grandTotal/.data.quoteStatus,
// savedReceipts/.data.amountPaid/.data.status) plus the new ExpenseProvider.
//
// ASSUMPTION: months are bucketed by each document's `createdAt` (a real
// DateTime on every Saved* model), not by the free-text issueDate/dueDate/
// paymentDate strings those models also carry — those are user-typed strings
// in whatever format the date picker wrote, so createdAt is the only date
// guaranteed parseable here without importing the filters' date-parsing
// helper. If you'd rather report by issue/payment date, say so and I'll
// switch it to reuse parseDocDate from lib/filters/filter_date_utils.dart.
//
// "Income" = paid invoices (PaymentStatus.paid) + all issued receipts
// (amountPaid). Accepted quotes are shown separately as a pipeline figure,
// not counted as income, since a quote isn't a payment.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';

const Color kReportsAccent = Color(0xFF00897B);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  String _monthLabel(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }

  bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().savedInvoices;
    final quotes = context.watch<QuoteProvider>().savedQuotes;
    final receipts = context.watch<ReceiptProvider>().savedReceipts;
    final expenses = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final paidInvoicesThisMonth = invoices.where((i) =>
        _sameMonth(i.createdAt, _month) && i.data.paymentStatus == PaymentStatus.paid);
    final receiptsThisMonth = receipts.where((r) =>
        _sameMonth(r.createdAt, _month) && r.data.status == ReceiptStatus.issued);
    final acceptedQuotesThisMonth = quotes.where((q) =>
        _sameMonth(q.createdAt, _month) && q.data.quoteStatus == QuoteStatus.accepted);

    final invoiceIncome = paidInvoicesThisMonth.fold(0.0, (s, i) => s + i.data.grandTotal);
    final receiptIncome = receiptsThisMonth.fold(0.0, (s, r) => s + r.data.amountPaid);
    final income = invoiceIncome + receiptIncome;
    final quotePipeline = acceptedQuotesThisMonth.fold(0.0, (s, q) => s + q.data.grandTotal);

    final expensesThisMonth = expenses.totalForMonth(_month);
    final net = income - expensesThisMonth;
    final byCategory = expenses.byCategoryForMonth(_month);
    final sortedCategoryEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCategoryAmount = sortedCategoryEntries.isEmpty
        ? 1.0
        : sortedCategoryEntries.first.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), backgroundColor: kReportsAccent, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              ),
              Text(_monthLabel(_month), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Income', value: income, color: const Color(0xFF4CAF50), isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Expenses', value: expensesThisMonth, color: const Color(0xFFE53935), isDark: isDark)),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(label: 'Net', value: net, color: net >= 0 ? const Color(0xFF2196F3) : const Color(0xFFE53935), isDark: isDark, wide: true),
          const SizedBox(height: 12),
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
                  child: Text('Accepted quotes this month (not counted as income): ${acceptedQuotesThisMonth.length} · ${quotePipeline.toStringAsFixed(2)} total',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Expenses by category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
          const SizedBox(height: 12),
          if (sortedCategoryEntries.isEmpty)
            Text('No expenses recorded this month.', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.45)))
          else
            for (final entry in sortedCategoryEntries)
              _CategoryBarRow(
                category: categories.byId(entry.key),
                amount: entry.value,
                fraction: entry.value / maxCategoryAmount,
              ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;
  final bool wide;

  const _StatCard({required this.label, required this.value, required this.color, required this.isDark, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(isDark ? 0.15 : 0.08), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          Text(value.toStringAsFixed(2), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _CategoryBarRow extends StatelessWidget {
  final dynamic category; // DocumentCategory
  final double amount;
  final double fraction;

  const _CategoryBarRow({required this.category, required this.amount, required this.fraction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 14, color: category.color),
              const SizedBox(width: 6),
              Expanded(child: Text(category.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface))),
              Text(amount.toStringAsFixed(2), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: category.color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(category.color),
            ),
          ),
        ],
      ),
    );
  }
}