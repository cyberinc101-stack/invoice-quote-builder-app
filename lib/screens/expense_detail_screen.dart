// expense_detail_screen.dart
// lib/screens/expense_detail_screen.dart
//
// CONFIRM-BEFORE-EXPORT PASS (this update): Export as Excel / Export as CSV
// in the options sheet previously fired their handler the instant the row
// was tapped — no confirmation, so a mis-tap immediately wrote a file.
// Added the same _confirmAction(...) dialog saved_document_detail_screen.
// dart uses (icon chip, plain-English message, Cancel/Export buttons,
// accented with kHeroGradient[0] to match) — both export rows now await
// it before calling their handler. Edit / Move to Folder / Include-
// Exclude / Delete are untouched — Delete already had its own
// confirmation dialog, and the others aren't one-shot destructive-ish
// actions the same way a file export is.
//
// SHEET SAFE-AREA FIX (earlier): _showOptionsSheet's bottom sheet used
// to wrap its content in a plain SafeArea, which was not enough to clear
// the gesture-nav bar on some devices — "Delete" (the last row) was
// getting hidden behind the Android nav buttons. Replaced with an explicit
// Padding using MediaQuery.of(ctx).padding.bottom, the same pattern
// saved_document_detail_screen.dart's own options sheet already uses
// successfully.
//
// EXPORT WIRING PASS (earlier): ExpenseExportService existed with
// full single-entry XLSX/CSV support but had no button anywhere in the
// app calling it — the options sheet only had Edit/Move to Folder/
// Include-Exclude/Delete. Added "Export as Excel" and "Export as CSV"
// entries, mirroring the exact working pattern already proven in
// saved_document_detail_screen.dart's _handleExportXlsx/_handleExportCsv
// (try/catch, path-in-snackbar on success, error message on failure,
// context.mounted guards around every post-await ScaffoldMessenger call).
// categoryName is resolved once in build() (already needed for the stat
// card / header) and threaded through to _showOptionsSheet so the export
// handlers don't need a second CategoryProvider lookup.
//
// THEME-MATCH PASS (earlier): previously this screen used its own header
// widget (_ExpenseHeaderBackground) with a flat red/expense-accent
// gradient, a small logo-or-category-icon avatar, and a fixed
// expandedHeight: 190 — none of which matched the navy hero-gradient
// header used everywhere else (SavedDocumentDetailScreen for invoices/
// quotes/receipts, via detail/document_detail_header.dart). This screen
// now uses that same DocumentDetailHeader widget: the navy kHeroGradient
// base in both branches, a full-bleed cover-fit logo when one exists
// (matching hasLogo sizing via DocumentDetailHeader.heightFor), a status
// pill, and the type+date pill row — so Home/Reports/Expenses detail
// screens are visually one product again.
//
// Since expenses don't have a payment-style status enum, the status pill
// now reflects excludeFromReports: "Included in Reports" (green,
// check-circle) or "Excluded from Reports" (grey, visibility-off) — the
// same fact the old header showed as a separate badge, now folded into
// the shared header's own status-pill slot. typeIcon is the expense's
// category icon (falls back to a generic receipt icon has no fallback
// needed — category.icon is always set), typeLabel is the category name,
// so the type+date pill reads e.g. "Travel · 11 Aug 2026" instead of a
// generic "Expense" label.
//
// The stat cards, Details card, and bottom bar are otherwise unchanged
// from the previous pass (still local _StatCard/_DetailRow widgets, same
// fields/order) — only the header and SliverAppBar sizing changed.
//
// Re-reads the live copy from ExpenseProvider by id on every build (same
// pattern SavedDocumentDetailScreen uses for invoices/quotes/receipts) so
// edits made via the Edit sheet, folder changes, or the exclude-from-
// reports toggle show up immediately without needing to pop and re-push
// this screen.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export/expense_export_service.dart';
import '../models/expense_data.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expenses/expense_card_shared.dart';
import 'expense_screen.dart';
import 'saved_invoice_details_section/detail/document_detail_header.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  File? _resolveLogoFile(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    final expense = context.watch<ExpenseProvider>().getExpenseById(expenseId);

    if (expense == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: kExpenseAccent, foregroundColor: Colors.white),
        body: const Center(child: Text('This expense no longer exists.')),
      );
    }

    final category = context.watch<CategoryProvider>().byId(expense.categoryId);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoFile = _resolveLogoFile(expense.logoPath);
    final hasLogo = logoFile != null;

    final title = expense.vendor.trim().isEmpty ? '(No vendor)' : expense.vendor.trim();

    final statusLabel = expense.excludeFromReports ? 'Excluded from Reports' : 'Included in Reports';
    final statusColor = expense.excludeFromReports ? const Color(0xFF9E9E9E) : const Color(0xFF4CAF50);
    final statusIcon = expense.excludeFromReports ? Icons.visibility_off_rounded : Icons.check_circle_rounded;

    final barColor = kHeroGradient[0];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
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
                  onTap: () => _showOptionsSheet(context, expense, category.name),
                  child: Container(
                    width: 40,
                    height: 40,
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
                accentColor: kExpenseAccent,
                logoFile: logoFile,
                title: title,
                typeLabel: category.name,
                typeIcon: category.icon,
                statusLabel: statusLabel,
                statusColor: statusColor,
                statusIcon: statusIcon,
                createdAt: expense.date,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                          label: 'Amount',
                          icon: Icons.payments_rounded,
                          iconColor: kExpenseAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: category.name,
                          label: 'Category',
                          icon: category.icon,
                          iconColor: category.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withValues(alpha: 0.55))),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
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
                            _DetailRow(icon: Icons.event_rounded, label: 'Date', value: formatExpenseShortDate(expense.date), color: kExpenseAccent),
                            const SizedBox(height: 12),
                            _DetailRow(icon: Icons.add_circle_outline_rounded, label: 'Created', value: formatExpenseShortDate(expense.createdAt), color: const Color(0xFF9C27B0)),
                            const SizedBox(height: 12),
                            _DetailRow(icon: Icons.edit_outlined, label: 'Last edited', value: formatExpenseRelativeTime(expense.lastEditedAt), color: const Color(0xFF2196F3)),
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.folder_outlined,
                              label: 'Folder',
                              value: (expense.folderName == null || expense.folderName!.trim().isEmpty) ? 'None' : expense.folderName!,
                              color: const Color(0xFF546E7A),
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.confirmation_number_outlined,
                              label: 'Reference',
                              value: (expense.referenceNumber == null || expense.referenceNumber!.trim().isEmpty) ? 'None' : expense.referenceNumber!,
                              color: const Color(0xFF00897B),
                            ),
                            if (expense.notes.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  expense.notes,
                                  style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => openExpenseFormSheet(context, existing: expense),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kExpenseAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => openExpenseFolderSheet(context, ids: {expense.id}),
                icon: const Icon(Icons.folder_outlined, size: 18),
                label: const Text('Folder'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kExpenseAccent,
                  side: const BorderSide(color: kExpenseAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CONFIRM-BEFORE-EXPORT PASS: shared confirmation dialog used by
  // Export as Excel / Export as CSV before either handler actually runs.
  // Byte-for-byte the same shape as saved_document_detail_screen.dart's
  // _confirmAction (icon chip, plain-English message, Cancel/Export,
  // accented with kHeroGradient[0]) so the two screens' export
  // confirmations look identical. Returns true only if the user taps the
  // primary (confirm) button; false for Cancel, a barrier tap, or a
  // back-gesture dismissal.
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

  Future<void> _handleExportXlsx(BuildContext context, ExpenseEntry expense, String categoryName) async {
    try {
      final path = await ExpenseExportService().exportSingleXlsxToDownloads(
        expense,
        categoryName: categoryName,
      );
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

  Future<void> _handleExportCsv(BuildContext context, ExpenseEntry expense, String categoryName) async {
    try {
      final path = await ExpenseExportService().exportSingleCsvToDownloads(
        expense,
        categoryName: categoryName,
      );
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

  void _showOptionsSheet(BuildContext context, ExpenseEntry expense, String categoryName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
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
            // CONFIRM-BEFORE-EXPORT PASS: each export row now closes the
            // sheet, then awaits _confirmAction before calling its
            // handler. If the user taps Cancel (or dismisses the dialog
            // any other way), the handler is simply never called — no
            // file write, no snackbar.
            ListTile(
              leading: const Icon(Icons.grid_on_rounded, color: Color(0xFF1D6F42)),
              title: const Text('Export as Excel'),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _confirmAction(
                  context,
                  title: 'Export as Excel',
                  message: 'This will generate an Excel spreadsheet of this expense and save it to your Downloads folder. Continue?',
                  confirmLabel: 'Export',
                  icon: Icons.grid_on_rounded,
                );
                if (ok && context.mounted) _handleExportXlsx(context, expense, categoryName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded, color: Color(0xFF607D8B)),
              title: const Text('Export as CSV'),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _confirmAction(
                  context,
                  title: 'Export as CSV',
                  message: 'This will generate a CSV file of this expense and save it to your Downloads folder. Continue?',
                  confirmLabel: 'Export',
                  icon: Icons.table_chart_rounded,
                );
                if (ok && context.mounted) _handleExportCsv(context, expense, categoryName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: kExpenseAccent),
              title: const Text('Delete'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete this expense?'),
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
                if (!context.mounted) return;
                Navigator.pop(context); // close sheet
                await context.read<ExpenseProvider>().deleteExpenses([expense.id]);
                if (context.mounted) Navigator.pop(context); // close detail screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatCard({required this.value, required this.label, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.55))),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}