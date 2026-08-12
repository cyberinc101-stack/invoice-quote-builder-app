// lib/screens/expense_screen.dart
//
// MANUAL-ONLY PASS (this update): removed the QR-code scan FAB and its
// handler (_handleScan) entirely, along with the scan_screen.dart import.
// Finding an expense by reference number is now manual-only — type it
// into the search field above the list (already wired: vendor OR
// reference number, case-insensitive). No camera flow, nothing decoded
// from an image. QrService/ScannedExpenseDraft stay imported and in use
// for the unrelated "Share as QR" export button in the edit sheet (that
// generates a code FROM an expense — a different feature from the
// scan-to-find flow that's being removed here).
//
// FILTER BAR PASS (earlier): the old plain TextField search box is
// replaced with ExpenseFilterBar (lib/widgets/expenses/expense_filter_bar.
// dart) — same search-field styling and "Filters" bottom sheet pattern
// lib/widgets/document_filter_bar.dart uses on the home screen, scoped to
// what expenses actually have: Folder, Date & Sort, Amount Range (backed
// by filterExpensesByFolder/DateRange/AmountRange + sortExpenses, already
// in lib/filters/filter_logic.dart). The "${expenses.length} expenses"
// count row has an ExpenseSortToggleButton next to the existing
// ExpenseLayoutToggleButton, matching the pairing
// saved_documents_section.dart's _SectionHeader uses for
// _SortToggleButton + _LayoutToggleButton. Vendor/reference-number text
// search stays as its own local pass (_applySearch) since
// filter_logic.dart's searchExpenses() only matches vendor+notes and this
// screen's search hint explicitly promises reference-number matching too
// — everything else (date range, amount range, folder, sort) routes
// through the shared filter_logic.dart helpers instead of being absent.
//
// REFERENCE NUMBER PASS (earlier):
//   - The add/edit sheet has a "Reference number" text field (plain
//     manual entry — see expense_data.dart) sitting next to Notes.
//
// DOC-CARD STYLE PASS (earlier): _entriesFor() passes referenceNumber
// into ExpenseCardEntry so the restyled list layout (expense_cards.dart)
// can show it. No other visual change happens here — the actual restyle
// lives in expense_card_shared.dart/expense_cards.dart.
//
// LOGO + FOLDERS + DETAIL PAGE PASS (earlier):
//   - The add/edit sheet includes a compact SharedLogoPicker (the same
//     widget/bottom-sheet Quote/Invoice/Receipt business profiles use) so
//     an expense can carry a photo (receipt snap, vendor logo, whatever).
//     Gallery, Camera, Reposition/Zoom/Shape, and Remove all come for free
//     from that shared widget — see shared_logo_picker.dart.
//   - openExpenseFolderSheet() (public) — the "Move to Folder" bottom
//     sheet for one or many expenses at once, mirroring the shape of
//     SavedDocumentsSection's own folder sheet but scoped to
//     ExpenseProvider.folderNames. Public so expense_detail_screen.dart and
//     saved_documents_section.dart's inline expense-card menu can open the
//     exact same sheet instead of duplicating it.
//   - "Move to Folder" is in the single-item menu (_showItemMenu) and
//     in the selection-mode app bar (bulk move).
//   - Card taps push ExpenseDetailScreen instead of opening the edit
//     sheet directly — the edit sheet is one tap further, from the detail
//     screen's Edit button (or straight from here via the item menu).
//
// The single-entry edit sheet, QR share, and single/bulk export are all
// otherwise unchanged from the previous pass — see openExpenseFormSheet()
// below, still the one public entry point ReportsScreen's "Expenses in
// this period" cards also call into.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export/expense_export_service.dart';
import '../filters/filter_logic.dart';
import '../filters/filter_types.dart';
import '../models/expense_data.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../services/qr_service.dart';
import '../widgets/category_picker.dart';
import '../widgets/expenses/expense_card_shared.dart';
import '../widgets/expenses/expense_cards.dart';
import '../widgets/expenses/expense_filter_bar.dart';
import '../widgets/qr_code_display.dart';
import '../widgets/shared_logo_picker.dart';
import 'expense_detail_screen.dart';

const String _kDefaultCurrency = 'NZD';

// Public entry point so other screens (e.g. ReportsScreen's "Expenses in
// this period" list, ExpenseDetailScreen's Edit button) can open the exact
// same edit sheet used here, rather than duplicating the form.
void openExpenseFormSheet(
  BuildContext context, {
  ExpenseEntry? existing,
  ScannedExpenseDraft? prefill,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _ExpenseFormSheet(existing: existing, prefill: prefill),
  );
}

// Public entry point for the "Move to Folder" sheet, usable for one
// expense or many. `onApplied` fires after a folder change is applied —
// callers doing bulk selection use it to clear selection state.
void openExpenseFolderSheet(
  BuildContext context, {
  required Set<String> ids,
  VoidCallback? onApplied,
}) {
  if (ids.isEmpty) return;
  final availableFolders = context.read<ExpenseProvider>().folderNames.toList()..sort();
  final newFolderController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final cs = Theme.of(context).colorScheme;

          void applyFolder(String? raw) {
            context.read<ExpenseProvider>().updateExpensesFolder(ids, raw);
            Navigator.pop(sheetContext);
            final trimmed = raw?.trim();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text((trimmed == null || trimmed.isEmpty)
                    ? 'Removed from folder'
                    : 'Moved to "$trimmed"'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            onApplied?.call();
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kExpenseAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.folder_outlined, size: 18, color: kExpenseAccent),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Move to Folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (availableFolders.isNotEmpty) ...[
                    Text('Existing Folders',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.55))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableFolders.map((f) {
                        return GestureDetector(
                          onTap: () => applyFolder(f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.045),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.folder_rounded, size: 14, color: kExpenseAccent),
                                const SizedBox(width: 6),
                                Text(f, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text('New Folder',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.55))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.045),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                    ),
                    child: TextField(
                      controller: newFolderController,
                      autofocus: availableFolders.isEmpty,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        hintText: 'e.g. Client Name, 2026 Projects',
                      ),
                      onSubmitted: applyFolder,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => applyFolder(null),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Remove from Folder'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => applyFolder(newFolderController.text),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  ExpenseLayoutMode _layoutMode = ExpenseLayoutMode.list;
  bool _selectionMode = false;
  final Set<String> _selected = {};

  // ── Search + filter state ─────────────────────────────────────────────
  // searchQuery stays as its own local pass (vendor OR reference number —
  // see _applySearch below). Everything else here routes through the
  // shared filter_logic.dart helpers, same functions the home screen's
  // documents use, just called against ExpenseEntry instead.
  String _searchQuery = '';
  DateRangePreset _selectedDateRange = DateRangePreset.all;
  DateTime? _customRangeStart;
  DateTime? _customRangeEnd;
  SortOption _selectedSort = SortOption.recentFirst;
  double? _minAmount;
  double? _maxAmount;
  String? _selectedFolder;

  String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }

  // Plain local filter — vendor OR reference number, case-insensitive
  // substring match. No database; runs over the list already held in
  // ExpenseProvider. Kept separate from filter_logic.dart's
  // searchExpenses() because that helper only matches vendor+notes, and
  // this screen's search field explicitly promises reference-number
  // matching too — this manual search box is now the ONLY way to look up
  // an expense by reference number (the QR scan flow has been removed).
  List<ExpenseEntry> _applySearch(List<ExpenseEntry> expenses) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return expenses;
    return expenses.where((e) {
      final vendorMatch = e.vendor.toLowerCase().contains(q);
      final refMatch = (e.referenceNumber ?? '').toLowerCase().contains(q);
      return vendorMatch || refMatch;
    }).toList();
  }

  void _enterSelection(String key) {
    setState(() {
      _selectionMode = true;
      _selected.add(key);
    });
  }

  void _toggleSelect(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(key);
      }
    });
  }

  void _cancelSelection() => setState(() {
        _selectionMode = false;
        _selected.clear();
      });

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${_selected.length} expense${_selected.length == 1 ? '' : 's'}?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: kExpenseAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await context.read<ExpenseProvider>().deleteExpenses(_selected);
    if (mounted) _cancelSelection();
  }

  Future<void> _bulkSetExcluded(bool exclude) async {
    await context.read<ExpenseProvider>().updateExpensesExcludeFromReports(_selected, exclude);
    if (mounted) _cancelSelection();
  }

  void _bulkMoveToFolder() {
    openExpenseFolderSheet(context, ids: Set.of(_selected), onApplied: _cancelSelection);
  }

  void _showItemMenu(ExpenseEntry expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: kExpenseAccent),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                openExpenseFormSheet(context, existing: expense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: kExpenseAccent),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(context);
                openExpenseFolderSheet(context, ids: {expense.id});
              },
            ),
            ListTile(
              leading: Icon(
                expense.excludeFromReports ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: kExpenseAccent,
              ),
              title: Text(expense.excludeFromReports ? 'Include in reports' : 'Exclude from reports'),
              onTap: () {
                Navigator.pop(context);
                context.read<ExpenseProvider>().updateExpenseExcludeFromReports(expense.id, !expense.excludeFromReports);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: kExpenseAccent),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<ExpenseProvider>().deleteExpenses([expense.id]);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allExpenses = context.watch<ExpenseProvider>().expenses;
    final availableFolders = context.watch<ExpenseProvider>().folderNames.toList()..sort();

    // ── Filter pipeline ────────────────────────────────────────────────
    // Same order the home screen applies its own filters in: search ->
    // date range -> amount range -> folder -> sort.
    var expenses = _applySearch(allExpenses);
    expenses = filterExpensesByDateRange(expenses, _selectedDateRange,
        customStart: _customRangeStart, customEnd: _customRangeEnd);
    expenses = filterExpensesByAmountRange(expenses, _minAmount, _maxAmount);
    expenses = filterExpensesByFolder(expenses, _selectedFolder);
    expenses = sortExpenses(expenses, _selectedSort);

    final categories = context.watch<CategoryProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final Map<String, List<ExpenseEntry>> grouped = {};
    for (final e in expenses) {
      grouped.putIfAbsent(_monthKey(e.date), () => []).add(e);
    }

    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              backgroundColor: kExpenseAccent,
              foregroundColor: Colors.white,
              leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: _cancelSelection),
              title: Text('${_selected.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.folder_outlined),
                  tooltip: 'Move to Folder',
                  onPressed: _selected.isEmpty ? null : _bulkMoveToFolder,
                ),
                IconButton(
                  icon: const Icon(Icons.visibility_off_rounded),
                  tooltip: 'Exclude from reports',
                  onPressed: _selected.isEmpty ? null : () => _bulkSetExcluded(true),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility_rounded),
                  tooltip: 'Include in reports',
                  onPressed: _selected.isEmpty ? null : () => _bulkSetExcluded(false),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Delete',
                  onPressed: _selected.isEmpty ? null : _bulkDelete,
                ),
              ],
            )
          : AppBar(
              title: const Text('Expenses'),
              backgroundColor: kExpenseAccent,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Export',
                  onPressed: allExpenses.isEmpty ? null : () => _openBulkExportSheet(context),
                ),
              ],
            ),
      // MANUAL-ONLY: single FAB now — the scan-to-find camera FAB and its
      // handler are gone. Adding an expense (and finding one, via the
      // search field above) is manual-input only from here on.
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              heroTag: 'add_fab',
              backgroundColor: kExpenseAccent,
              foregroundColor: Colors.white,
              onPressed: () => openExpenseFormSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add expense'),
            ),
      body: allExpenses.isEmpty
          ? Center(
              child: Text('No expenses yet — tap "Add expense" to start.',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (_selectedFolder != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: kExpenseAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kExpenseAccent.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_rounded, size: 16, color: kExpenseAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Folder: $_selectedFolder',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedFolder = null),
                            child: Icon(Icons.close_rounded, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ExpenseFilterBar(
                  searchQuery: _searchQuery,
                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                  selectedDateRange: _selectedDateRange,
                  onDateRangeChanged: (p) => setState(() => _selectedDateRange = p),
                  customRangeStart: _customRangeStart,
                  customRangeEnd: _customRangeEnd,
                  onCustomRangeChanged: (start, end) => setState(() {
                    _customRangeStart = start;
                    _customRangeEnd = end;
                  }),
                  selectedSort: _selectedSort,
                  onSortChanged: (s) => setState(() => _selectedSort = s),
                  minAmount: _minAmount,
                  maxAmount: _maxAmount,
                  onAmountRangeChanged: (min, max) => setState(() {
                    _minAmount = min;
                    _maxAmount = max;
                  }),
                  selectedFolder: _selectedFolder,
                  onFolderChanged: (f) => setState(() => _selectedFolder = f),
                  availableFolders: availableFolders,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                    const Spacer(),
                    ExpenseSortToggleButton(selected: _selectedSort, onChanged: (s) => setState(() => _selectedSort = s)),
                    const SizedBox(width: 8),
                    ExpenseLayoutToggleButton(selected: _layoutMode, onChanged: (m) => setState(() => _layoutMode = m)),
                  ],
                ),
                const SizedBox(height: 12),
                if (expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No expenses match this filter.',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
                    ),
                  )
                else
                  for (final key in grouped.keys) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_monthLabel(grouped[key]!.first.date),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withValues(alpha: 0.55))),
                          Text(_monthTotalLabel(grouped[key]!),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withValues(alpha: 0.75))),
                        ],
                      ),
                    ),
                    _buildEntries(context, grouped[key]!, categories),
                  ],
              ],
            ),
    );
  }

  List<ExpenseCardEntry> _entriesFor(List<ExpenseEntry> expenses, CategoryProvider categories) {
    return expenses
        .map((e) => ExpenseCardEntry(
              key: e.id,
              expense: e,
              category: categories.byId(e.categoryId),
              editedLabel: formatExpenseRelativeTime(e.lastEditedAt),
              dateLabel: formatExpenseShortDate(e.date),
              createdLabel: formatExpenseShortDate(e.createdAt),
              logoPath: e.logoPath,
              logoOffset: Offset(e.logoOffsetDx, e.logoOffsetDy),
              logoScale: e.logoScale,
              logoShape: logoShapeFromString(e.logoShape),
              folderName: e.folderName,
              referenceNumber: e.referenceNumber,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: e.id)),
              ),
              onShowMenu: () => _showItemMenu(e),
            ))
        .toList();
  }

  Widget _buildEntries(BuildContext context, List<ExpenseEntry> expenses, CategoryProvider categories) {
    final entries = _entriesFor(expenses, categories);

    switch (_layoutMode) {
      case ExpenseLayoutMode.list:
        return Column(
          children: entries
              .map((e) => ExpenseListCard(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selected.contains(e.key),
                    onToggleSelect: _toggleSelect,
                    onEnterSelection: _enterSelection,
                  ))
              .toList(),
        );
      case ExpenseLayoutMode.compact:
        return Column(
          children: entries
              .map((e) => ExpenseCompactRow(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selected.contains(e.key),
                    onToggleSelect: _toggleSelect,
                    onEnterSelection: _enterSelection,
                  ))
              .toList(),
        );
      case ExpenseLayoutMode.grid:
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 175,
          ),
          children: entries
              .map((e) => ExpenseGridCard(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selected.contains(e.key),
                    onToggleSelect: _toggleSelect,
                    onEnterSelection: _enterSelection,
                  ))
              .toList(),
        );
      case ExpenseLayoutMode.compactGrid:
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 118,
          ),
          children: entries
              .map((e) => ExpenseCompactGridCard(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selected.contains(e.key),
                    onToggleSelect: _toggleSelect,
                    onEnterSelection: _enterSelection,
                  ))
              .toList(),
        );
    }
  }

  /// Sums a month's entries. NOTE: assumes entries within a month group
  /// share one currency for display purposes.
  String _monthTotalLabel(List<ExpenseEntry> entries) {
    if (entries.isEmpty) return '';
    final total = entries.fold<double>(0, (sum, e) => sum + e.amount);
    final currency = entries.first.currency;
    return '$currency ${total.toStringAsFixed(2)}';
  }

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
    String Function(String) categoryNameOf(CategoryProvider cats) => (id) => cats.byId(id).name;

    try {
      if (xlsx) {
        await service.shareBulkXlsx(entries, categoryNameOf: categoryNameOf(widget.categoryProvider));
      } else {
        await service.shareBulkCsv(entries, categoryNameOf: categoryNameOf(widget.categoryProvider));
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export failed. Please try again.')));
      }
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final thisMonth = widget.expenseProvider.forMonth(DateTime(now.year, now.month));
    final all = widget.expenseProvider.expenses;

    Widget tile({required String label, required String subtitle, required IconData icon, required VoidCallback? onTap}) {
      return ListTile(
        leading: Icon(icon, color: kExpenseAccent),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
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
              child: Text('Export expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            ),
            const SizedBox(height: 8),
            if (_busy)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
            else ...[
              tile(
                label: 'This month — Excel (.xlsx)',
                subtitle: '${thisMonth.length} entries',
                icon: Icons.table_chart_rounded,
                onTap: thisMonth.isEmpty ? null : () => _export(thisMonth, xlsx: true),
              ),
              tile(
                label: 'This month — CSV',
                subtitle: '${thisMonth.length} entries',
                icon: Icons.description_rounded,
                onTap: thisMonth.isEmpty ? null : () => _export(thisMonth, xlsx: false),
              ),
              const Divider(height: 1),
              tile(
                label: 'All expenses — Excel (.xlsx)',
                subtitle: '${all.length} entries',
                icon: Icons.table_chart_rounded,
                onTap: all.isEmpty ? null : () => _export(all, xlsx: true),
              ),
              tile(
                label: 'All expenses — CSV',
                subtitle: '${all.length} entries',
                icon: Icons.description_rounded,
                onTap: all.isEmpty ? null : () => _export(all, xlsx: false),
              ),
            ],
          ],
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
  late final TextEditingController _referenceController;
  late String _categoryId;
  late DateTime _date;

  // Logo state — mirrors the pattern Quote/Invoice/Receipt business
  // profile sheets use with SharedLogoPicker.
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;

  bool _exporting = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final p = widget.prefill;
    _vendorController = TextEditingController(text: e?.vendor ?? p?.vendor ?? '');
    _amountController = TextEditingController(text: (e?.amount ?? p?.amount)?.toString() ?? '');
    _currencyController = TextEditingController(text: e?.currency ?? p?.currency ?? _kDefaultCurrency);
    _notesController = TextEditingController(text: e?.notes ?? p?.notes ?? '');
    _referenceController = TextEditingController(text: e?.referenceNumber ?? p?.referenceNumber ?? '');
    _categoryId = e?.categoryId ?? p?.categoryId ?? 'other';
    _date = e?.date ?? p?.date ?? DateTime.now();
    _logoPath = e?.logoPath;
    _logoOffset = Offset(e?.logoOffsetDx ?? 0.0, e?.logoOffsetDy ?? 0.0);
    _logoScale = e?.logoScale ?? 1.0;
    _logoShape = logoShapeFromString(e?.logoShape ?? 'roundedSquare');
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100),
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
      referenceNumber: _referenceController.text.trim(),
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
      lastEditedAt: now,
      logoPath: _logoPath,
      logoOffsetDx: _logoOffset.dx,
      logoOffsetDy: _logoOffset.dy,
      logoScale: _logoScale,
      logoShape: _logoShape.storageName,
      folderName: widget.existing?.folderName,
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
    );
  }

  Future<void> _exportSingle({required bool xlsx}) async {
    setState(() => _exporting = true);
    try {
      final entry = _currentEntryForExport();
      final categoryName = context.read<CategoryProvider>().byId(_categoryId).name;
      final service = ExpenseExportService();
      if (xlsx) {
        await service.shareSingleXlsx(entry, categoryName: categoryName);
      } else {
        await service.shareSingleCsv(entry, categoryName: categoryName);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export failed. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: Text(
          'This will permanently remove '
          '"${_vendorController.text.trim().isEmpty ? 'this expense' : _vendorController.text.trim()}". '
          'This can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: kExpenseAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || widget.existing == null) return;

    setState(() => _deleting = true);
    try {
      await context.read<ExpenseProvider>().deleteExpense(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn\'t delete this expense. Please try again.')));
      }
    }
  }

  Future<void> _save() async {
    final vendor = _vendorController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final currency = _currencyController.text.trim();
    final reference = _referenceController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount greater than 0')));
      return;
    }
    if (currency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a currency')));
      return;
    }

    final provider = context.read<ExpenseProvider>();
    try {
      if (widget.existing != null) {
        await provider.updateExpense(widget.existing!.copyWith(
          vendor: vendor, amount: amount, currency: currency,
          categoryId: _categoryId, date: _date, notes: _notesController.text.trim(),
          logoPath: _logoPath, clearLogo: _logoPath == null,
          logoOffsetDx: _logoOffset.dx, logoOffsetDy: _logoOffset.dy,
          logoScale: _logoScale, logoShape: _logoShape.storageName,
          referenceNumber: reference.isEmpty ? null : reference,
          clearReferenceNumber: reference.isEmpty,
        ));
      } else {
        await provider.addExpense(
          vendor: vendor, amount: amount, currency: currency,
          categoryId: _categoryId, date: _date, notes: _notesController.text.trim(),
          logoPath: _logoPath,
          logoOffsetDx: _logoOffset.dx, logoOffsetDy: _logoOffset.dy,
          logoScale: _logoScale, logoShape: _logoShape.storageName,
          referenceNumber: reference.isEmpty ? null : reference,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn\'t save this expense. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoryProvider>().byId(_categoryId);
    final colorScheme = Theme.of(context).colorScheme;
    final busy = _exporting || _deleting;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
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
                    if (_exporting)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      IconButton(icon: const Icon(Icons.ios_share_rounded), tooltip: 'Export', onPressed: busy ? null : _showExportMenu),
                    if (widget.existing != null)
                      _deleting
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kExpenseAccent)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: kExpenseAccent),
                              onPressed: busy ? null : _confirmDelete,
                            ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SharedLogoPicker(
                logoPath: _logoPath,
                logoOffset: _logoOffset,
                logoScale: _logoScale,
                logoShape: _logoShape,
                accent: kExpenseAccent,
                compact: true,
                compactBoxSize: 72,
                onChanged: (path, offset, scale, shape) => setState(() {
                  _logoPath = path;
                  _logoOffset = offset;
                  _logoScale = scale;
                  _logoShape = shape;
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _vendorController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Vendor')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 2, child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Amount'),
                )),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                  controller: _currencyController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Currency'),
                )),
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
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(category.icon, size: 18, color: category.color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(category.name, style: TextStyle(color: colorScheme.onSurface))),
                    Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface.withValues(alpha: 0.5)),
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
                    Icon(Icons.calendar_today_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 10),
                    Text('${_date.day}/${_date.month}/${_date.year}', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.existing != null)
              GestureDetector(
                onTap: () => openExpenseFolderSheet(context, ids: {widget.existing!.id}),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.existing!.folderName ?? 'No folder',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            if (widget.existing != null) const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Reference number',
                helperText: 'Type it manually. Used to search this expense here and to match it against Reports.',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _showQr,
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Share as QR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kExpenseAccent, foregroundColor: Colors.white),
                    onPressed: busy ? null : _save,
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
