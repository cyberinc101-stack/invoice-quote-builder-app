// lib/screens/expense_screen.dart
//
// EXPORT WIRING (this pass): added ExpenseExportService (mirrors
// invoice_export_service.dart's XLSX/CSV conventions). Two entry points:
//  - AppBar icon -> bulk export (All / This month, XLSX or CSV, via share
//    sheet since that's the simplest cross-platform path for handing a
//    file to email/Drive/WhatsApp/etc for an accountant).
//  - Edit-sheet header icon -> single-entry export (same two formats),
//    built live off the current form field values so it works even before
//    the entry is saved.
// Both call Share.shareXFiles under the hood via ExpenseExportService, so
// there's no separate "saved to Downloads" confirmation UI needed here —
// the OS share sheet itself confirms where the file went.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export/expense_export_service.dart';
import '../models/expense_data.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../services/qr_service.dart';
import '../widgets/category_picker.dart';
import '../widgets/qr_code_display.dart';
import 'scan_screen.dart';

const Color kExpenseAccent = Color(0xFFE53935);

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final categories = context.watch<CategoryProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Group by month, most recent first (list is already sorted desc by date).
    final Map<String, List<ExpenseEntry>> grouped = {};
    for (final e in expenses) {
      grouped.putIfAbsent(_monthKey(e.date), () => []).add(e);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: kExpenseAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export',
            onPressed: expenses.isEmpty ? null : () => _openBulkExportSheet(context),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'scan_fab',
            backgroundColor: Colors.white,
            foregroundColor: kExpenseAccent,
            elevation: 1,
            onPressed: () async {
              final draft = await Navigator.push<ScannedExpenseDraft>(
                context, MaterialPageRoute(builder: (_) => const ScanScreen()));
              if (draft != null && context.mounted) {
                _openExpenseForm(context, prefill: draft);
              }
            },
            child: const Icon(Icons.qr_code_scanner_rounded),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'add_fab',
            backgroundColor: kExpenseAccent,
            foregroundColor: Colors.white,
            onPressed: () => _openExpenseForm(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add expense'),
          ),
        ],
      ),
      body: expenses.isEmpty
          ? Center(
              child: Text('No expenses yet — tap "Add expense" to start.',
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                for (final key in grouped.keys) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(_monthLabel(grouped[key]!.first.date),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.55))),
                  ),
                  for (final e in grouped[key]!)
                    _ExpenseTile(
                      expense: e,
                      category: categories.byId(e.categoryId),
                      onTap: () => _openExpenseForm(context, existing: e),
                    ),
                ],
              ],
            ),
    );
  }

  void _openExpenseForm(BuildContext context, {ExpenseEntry? existing, ScannedExpenseDraft? prefill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ExpenseFormSheet(existing: existing, prefill: prefill),
    );
  }

  // ── Bulk export ──────────────────────────────────────────────────────────

  void _openBulkExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _BulkExportSheet(
        expenseProvider: context.read<ExpenseProvider>(),
        categoryProvider: context.read<CategoryProvider>(),
      ),
    );
  }
}

class _BulkExportSheet extends StatefulWidget {
  final ExpenseProvider expenseProvider;
  final CategoryProvider categoryProvider;

  const _BulkExportSheet({required this.expenseProvider, required this.categoryProvider});

  @override
  State<_BulkExportSheet> createState() => _BulkExportSheetState();
}

class _BulkExportSheetState extends State<_BulkExportSheet> {
  bool _busy = false;

  Future<void> _export(List<ExpenseEntry> entries, {required bool xlsx}) async {
    setState(() => _busy = true);
    final service = ExpenseExportService();
    String Function(String) categoryNameOf(CategoryProvider cats) =>
        (id) => cats.byId(id).name;

    try {
      if (xlsx) {
        await service.shareBulkXlsx(entries, categoryNameOf: categoryNameOf(widget.categoryProvider));
      } else {
        await service.shareBulkCsv(entries, categoryNameOf: categoryNameOf(widget.categoryProvider));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final thisMonth = widget.expenseProvider.forMonth(DateTime(now.year, now.month));
    final all = widget.expenseProvider.expenses;

    Widget tile({required String label, required String subtitle, required IconData icon, required VoidCallback onTap}) {
      return ListTile(
        leading: Icon(icon, color: kExpenseAccent),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
        onTap: _busy ? null : onTap,
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Export expenses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            ),
            const SizedBox(height: 8),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              tile(
                label: 'This month — Excel (.xlsx)',
                subtitle: '${thisMonth.length} entries',
                icon: Icons.table_chart_rounded,
                onTap: thisMonth.isEmpty ? () {} : () => _export(thisMonth, xlsx: true),
              ),
              tile(
                label: 'This month — CSV',
                subtitle: '${thisMonth.length} entries',
                icon: Icons.description_rounded,
                onTap: thisMonth.isEmpty ? () {} : () => _export(thisMonth, xlsx: false),
              ),
              const Divider(height: 1),
              tile(
                label: 'All expenses — Excel (.xlsx)',
                subtitle: '${all.length} entries',
                icon: Icons.table_chart_rounded,
                onTap: () => _export(all, xlsx: true),
              ),
              tile(
                label: 'All expenses — CSV',
                subtitle: '${all.length} entries',
                icon: Icons.description_rounded,
                onTap: () => _export(all, xlsx: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseEntry expense;
  final dynamic category; // DocumentCategory
  final VoidCallback onTap;

  const _ExpenseTile({required this.expense, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: category.color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                  child: Icon(category.icon, size: 18, color: category.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.vendor.isEmpty ? '(No vendor)' : expense.vendor,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(category.name, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5))),
                    ],
                  ),
                ),
                Text('${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  final ExpenseEntry? existing;
  final ScannedExpenseDraft? prefill;
  const _ExpenseFormSheet({this.existing, this.prefill});

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  late final TextEditingController _vendorController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _notesController;
  late String _categoryId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final p = widget.prefill;
    _vendorController = TextEditingController(text: e?.vendor ?? p?.vendor ?? '');
    _amountController = TextEditingController(text: (e?.amount ?? p?.amount)?.toString() ?? '');
    _currencyController = TextEditingController(text: e?.currency ?? p?.currency ?? 'NZD');
    _notesController = TextEditingController(text: e?.notes ?? p?.notes ?? '');
    _categoryId = e?.categoryId ?? p?.categoryId ?? 'other';
    _date = e?.date ?? p?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _showQr() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final payload = QrService.encodeExpense(
      vendor: _vendorController.text.trim(),
      amount: amount,
      currency: _currencyController.text.trim(),
      categoryId: _categoryId,
      date: _date,
      notes: _notesController.text.trim(),
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: QrCodeDisplay(data: payload, title: 'Share this expense', accentColor: kExpenseAccent),
      ),
    );
  }

  /// Builds a live ExpenseEntry from the current form fields — used so
  /// export works even before the entry is saved. Falls back to the
  /// existing entry's id/createdAt when editing, or synthesizes temporary
  /// ones for a brand-new, not-yet-saved entry.
  ExpenseEntry _currentEntryForExport() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final now = DateTime.now();
    return ExpenseEntry(
      id: widget.existing?.id ?? 'exp_draft_${now.microsecondsSinceEpoch}',
      vendor: _vendorController.text.trim(),
      amount: amount,
      currency: _currencyController.text.trim(),
      categoryId: _categoryId,
      date: _date,
      notes: _notesController.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
    );
  }

  Future<void> _exportSingle({required bool xlsx}) async {
    final entry = _currentEntryForExport();
    final categoryName = context.read<CategoryProvider>().byId(_categoryId).name;
    final service = ExpenseExportService();
    if (xlsx) {
      await service.shareSingleXlsx(entry, categoryName: categoryName);
    } else {
      await service.shareSingleCsv(entry, categoryName: categoryName);
    }
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_rounded, color: kExpenseAccent),
              title: const Text('Share as Excel (.xlsx)'),
              onTap: () {
                Navigator.pop(context);
                _exportSingle(xlsx: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded, color: kExpenseAccent),
              title: const Text('Share as CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportSingle(xlsx: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final vendor = _vendorController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final currency = _currencyController.text.trim();
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    final provider = context.read<ExpenseProvider>();
    if (widget.existing != null) {
      await provider.updateExpense(widget.existing!.copyWith(
        vendor: vendor, amount: amount, currency: currency,
        categoryId: _categoryId, date: _date, notes: _notesController.text.trim(),
      ));
    } else {
      await provider.addExpense(
        vendor: vendor, amount: amount, currency: currency,
        categoryId: _categoryId, date: _date, notes: _notesController.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoryProvider>().byId(_categoryId);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.existing != null ? 'Edit expense' : 'Add expense',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.ios_share_rounded),
                      tooltip: 'Export',
                      onPressed: _showExportMenu,
                    ),
                    if (widget.existing != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935)),
                        onPressed: () async {
                          await context.read<ExpenseProvider>().deleteExpense(widget.existing!.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _vendorController, decoration: const InputDecoration(labelText: 'Vendor')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 2, child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                )),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _currencyController, decoration: const InputDecoration(labelText: 'Currency'))),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showCategoryPicker(context, selectedId: _categoryId);
                if (picked != null) setState(() => _categoryId = picked.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(category.icon, size: 18, color: category.color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(category.name, style: TextStyle(color: colorScheme.onSurface))),
                    Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 10),
                    Text('${_date.day}/${_date.month}/${_date.year}', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showQr,
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Share as QR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kExpenseAccent, foregroundColor: Colors.white),
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
