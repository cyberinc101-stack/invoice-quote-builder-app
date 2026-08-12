// folders_grid_view.dart
// lib/widgets/folders_grid_view.dart
//
// Shared folder-tile grid (icon, name, total count, per-type breakdown,
// rename, delete-folder, download) — extracted out of
// folders_overview_screen.dart so it can be reused two places:
//   1. FoldersOverviewScreen (standalone screen, full-page grid)
//   2. SavedDocumentsSection's inline "browsing folders" mode (embedded,
//      shrinkWrap: true, physics: NeverScrollableScrollPhysics(), sitting
//      inside that screen's own scroll view)
//
// EXPENSES (this pass): ExpenseProvider folded in as a fourth source
// alongside invoices/quotes/receipts. _FolderCounts gained an `expenses`
// field, counted into `total` the same as the other three. Rename/delete
// call ExpenseProvider.updateExpensesFolder(oldName, newName) — a single
// bulk call (unlike the per-document updateXFolder(id, name) pattern the
// other three providers use), since ExpenseProvider does the "find every
// expense with this folder name" loop internally. typeFilter's switch
// gained a DocTypeFilter.expenses case. Kanban dominant-type grouping
// gained an "Expenses" column alongside Invoices/Quotes/Receipts/Mixed.
//
// NOTE: the download sheet (_showDownloadSheet/_runDownload) still only
// bundles invoices/quotes/receipts via FolderDownloadService — expenses
// have their own lib/export/expense_export_service.dart that isn't wired
// into folder-level ZIP/CSV download yet. An expenses-only folder will
// still show the download button, but it'll produce an archive with no
// expense data in it. Flagging this as a follow-up rather than blocking
// this pass on it.
//
// SORT/LAYOUT (earlier pass): FolderSortOption and FolderLayoutMode both
// expanded to match the richer options already available on the main
// document list (SortOption / DocLayoutMode in doc_layout_mode.dart) —
// same dropdown widgets, just driven by these two enums:
//   - FolderSortOption gained recentActivity/oldestActivity, ordering
//     folders by the most-recently-edited document inside each one
//     (_FolderCounts.lastActivity, tracked from each doc's lastEditedAt
//     while building byFolder — folders with no activity sort last).
//   - FolderLayoutMode gained compactGrid (4-across mini tiles), compact
//     (single-line rows), and kanban. Folders have no status field to
//     key columns off the way documents do, so kanban groups by dominant
//     document type instead.
// Every prior default (nameAsc / grid) is unchanged, so callers that don't
// pass sortOption/layoutMode see identical behavior to before this pass.
//
// Rename/delete both operate on the *live* provider data. For invoices/
// quotes/receipts this iterates every document currently carrying that
// folder name and calls the same updateXFolder(id, name) methods the
// "Move to Folder" sheet already uses — rename re-applies the new name to
// every doc that had the old one; delete clears folderName (passes null)
// on every doc that had it. Neither ever deletes a document, only its
// folder assignment. Expenses go through
// ExpenseProvider.updateExpensesFolder(oldName, newName) instead, which
// performs the equivalent bulk update internally.
//
// onFolderTap is a plain callback (String name) => ... rather than this
// widget owning navigation — callers decide what "tapping a folder" means:
// FoldersOverviewScreen pushes a new screen, SavedDocumentsSection just
// sets state inline.
//
// TYPE FILTER (earlier pass, extended this pass): optional `typeFilter`
// param (DocTypeFilter, imported from document_filter_bar.dart — same enum
// the main document list uses for its All/Invoices/Quotes/Receipts/Expenses
// pills). Defaults to DocTypeFilter.all, a no-op. When set to a specific
// type, folders are narrowed to only those whose already-computed
// _FolderCounts show at least one document of that type — applied BEFORE
// the search filter.
//
// SEARCH (earlier pass): optional searchQuery param, filtered
// case-insensitively against folder names before the grid is built. Empty
// state distinguishes "no folders exist yet" from "no folders match your
// search" so a search that comes up empty doesn't look identical to a
// brand-new account.
//
// COLOR (earlier pass): every folder tile now renders in the same blue,
// instead of being hashed into a 6-color palette per folder name. Kept
// _colorFor() as the single call site so every tile/row/card stays in sync
// automatically.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../export/folder_download_service.dart';
import '../providers/expense_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import 'document_filter_bar.dart' show DocTypeFilter;

enum FolderSortOption {
  nameAsc,
  nameDesc,
  mostDocuments,
  leastDocuments,
  recentActivity,
  oldestActivity,
}

String folderSortOptionLabel(FolderSortOption o) {
  switch (o) {
    case FolderSortOption.nameAsc:
      return 'Name (A–Z)';
    case FolderSortOption.nameDesc:
      return 'Name (Z–A)';
    case FolderSortOption.mostDocuments:
      return 'Most Documents';
    case FolderSortOption.leastDocuments:
      return 'Fewest Documents';
    case FolderSortOption.recentActivity:
      return 'Recent Activity';
    case FolderSortOption.oldestActivity:
      return 'Oldest Activity';
  }
}

// Mirrors DocLayoutMode's full 5-mode set. grid/list are the two original
// layouts; compactGrid/compact/kanban are new this pass, matching the main
// document list's options exactly in spirit (same names, same icons).
enum FolderLayoutMode { grid, list, compactGrid, compact, kanban }

String folderLayoutModeLabel(FolderLayoutMode m) {
  switch (m) {
    case FolderLayoutMode.grid:
      return 'Grid';
    case FolderLayoutMode.list:
      return 'List';
    case FolderLayoutMode.compactGrid:
      return 'Compact Grid';
    case FolderLayoutMode.compact:
      return 'Compact';
    case FolderLayoutMode.kanban:
      return 'Kanban';
  }
}

class FoldersGridView extends StatelessWidget {
  final ValueChanged<String> onFolderTap;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final String searchQuery;
  final FolderSortOption sortOption;
  final FolderLayoutMode layoutMode;
  final DocTypeFilter typeFilter;

  const FoldersGridView({
    super.key,
    required this.onFolderTap,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.all(20),
    this.searchQuery = '',
    this.sortOption = FolderSortOption.nameAsc,
    this.layoutMode = FolderLayoutMode.grid,
    this.typeFilter = DocTypeFilter.all,
  });

  // All folders render in this single blue now — was previously hashed
  // per-name into a 6-color palette, which made folders look randomly
  // assigned rather than consistent.
  static const Color _folderColor = Color(0xFF1565C0);

  static final FolderDownloadService _downloadService = FolderDownloadService();

  Color _colorFor(String name) => _folderColor;

  Future<void> _renameFolder(BuildContext context, String oldName) async {
    final controller = TextEditingController(text: oldName);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Rename Folder', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
            decoration: InputDecoration(
              hintText: 'Folder name',
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (newName == null || newName == oldName || !context.mounted) return;

    final invoiceProvider = context.read<InvoiceProvider>();
    final quoteProvider = context.read<QuoteProvider>();
    final receiptProvider = context.read<ReceiptProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    for (final inv in invoiceProvider.savedInvoices.where((i) => i.folderName == oldName).toList()) {
      invoiceProvider.updateInvoiceFolder(inv.id, newName);
    }
    for (final q in quoteProvider.savedQuotes.where((q) => q.folderName == oldName).toList()) {
      quoteProvider.updateQuoteFolder(q.id, newName);
    }
    for (final r in receiptProvider.savedReceipts.where((r) => r.folderName == oldName).toList()) {
      receiptProvider.updateReceiptFolder(r.id, newName);
    }
    final expenseIds = expenseProvider.expenses
        .where((e) => e.folderName == oldName)
        .map((e) => e.id)
        .toList();
    if (expenseIds.isNotEmpty) {
      expenseProvider.updateExpensesFolder(expenseIds, newName);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renamed to "$newName"'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _deleteFolder(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'This removes the "$name" folder. Documents inside it are kept — '
          "they just won't be in a folder anymore.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final invoiceProvider = context.read<InvoiceProvider>();
    final quoteProvider = context.read<QuoteProvider>();
    final receiptProvider = context.read<ReceiptProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    for (final inv in invoiceProvider.savedInvoices.where((i) => i.folderName == name).toList()) {
      invoiceProvider.updateInvoiceFolder(inv.id, null);
    }
    for (final q in quoteProvider.savedQuotes.where((q) => q.folderName == name).toList()) {
      quoteProvider.updateQuoteFolder(q.id, null);
    }
    for (final r in receiptProvider.savedReceipts.where((r) => r.folderName == name).toList()) {
      receiptProvider.updateReceiptFolder(r.id, null);
    }
    final expenseIds = expenseProvider.expenses
        .where((e) => e.folderName == name)
        .map((e) => e.id)
        .toList();
    if (expenseIds.isNotEmpty) {
      expenseProvider.updateExpensesFolder(expenseIds, null);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted folder "$name"'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ── download sheet ───────────────────────────────────────────────

  void _showDownloadSheet(
    BuildContext context,
    String name,
    List<dynamic> invoices,
    List<dynamic> quotes,
    List<dynamic> receipts,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Download as PDF (ZIP)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _runDownload(
                    context,
                    name,
                    invoices,
                    quotes,
                    receipts,
                    isPdf: true,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Export as CSV'),
                onTap: () {
                  Navigator.pop(ctx);
                  _runDownload(
                    context,
                    name,
                    invoices,
                    quotes,
                    receipts,
                    isPdf: false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runDownload(
    BuildContext context,
    String name,
    List<dynamic> invoices,
    List<dynamic> quotes,
    List<dynamic> receipts, {
    required bool isPdf,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPdf ? 'Building PDF ZIP…' : 'Building CSV…'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final path = isPdf
          ? await _downloadService.downloadFolderAsPdfZip(
              folderName: name,
              invoices: invoices.cast(),
              quotes: quotes.cast(),
              receipts: receipts.cast(),
            )
          : await _downloadService.downloadFolderAsCsv(
              folderName: name,
              invoices: invoices.cast(),
              quotes: quotes.cast(),
              receipts: receipts.cast(),
            );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Downloads: ${path.split(Platform.pathSeparator).last}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Shared rename/delete/download menu — used by every layout's tile/row
  // widget so all five stay behaviorally identical, just laid out
  // differently.
  void _showTileMenu(
    BuildContext context, {
    required VoidCallback onDownload,
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(ctx);
                  onDownload();
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline_rounded),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(ctx);
                  onRename();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error),
                title: Text('Delete Folder', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<InvoiceProvider, QuoteProvider, ReceiptProvider, ExpenseProvider>(
      builder: (context, invoiceProvider, quoteProvider, receiptProvider, expenseProvider, _) {
        final invoices = invoiceProvider.savedInvoices;
        final quotes = quoteProvider.savedQuotes;
        final receipts = receiptProvider.savedReceipts;
        final expenses = expenseProvider.expenses;

        final Map<String, _FolderCounts> byFolder = {};

        for (final inv in invoices) {
          final f = inv.folderName;
          if (f == null || f.trim().isEmpty) continue;
          final c = byFolder.putIfAbsent(f, () => _FolderCounts());
          c.invoices++;
          c.trackActivity(inv.lastEditedAt);
        }
        for (final q in quotes) {
          final f = q.folderName;
          if (f == null || f.trim().isEmpty) continue;
          final c = byFolder.putIfAbsent(f, () => _FolderCounts());
          c.quotes++;
          c.trackActivity(q.lastEditedAt);
        }
        for (final r in receipts) {
          final f = r.folderName;
          if (f == null || f.trim().isEmpty) continue;
          final c = byFolder.putIfAbsent(f, () => _FolderCounts());
          c.receipts++;
          c.trackActivity(r.lastEditedAt);
        }
        for (final e in expenses) {
          final f = e.folderName;
          if (f == null || f.trim().isEmpty) continue;
          final c = byFolder.putIfAbsent(f, () => _FolderCounts());
          c.expenses++;
          c.trackActivity(e.lastEditedAt);
        }

        final allFolderNamesCount = byFolder.length;

        var folderNames = byFolder.keys.toList()..sort();

        // Narrow to folders containing at least one document of the
        // selected type — applied before the search filter, mirroring how
        // the main document list's type pill composes with its own search
        // field. DocTypeFilter.all is a no-op.
        switch (typeFilter) {
          case DocTypeFilter.all:
            break;
          case DocTypeFilter.invoices:
            folderNames = folderNames.where((n) => byFolder[n]!.invoices > 0).toList();
            break;
          case DocTypeFilter.quotes:
            folderNames = folderNames.where((n) => byFolder[n]!.quotes > 0).toList();
            break;
          case DocTypeFilter.receipts:
            folderNames = folderNames.where((n) => byFolder[n]!.receipts > 0).toList();
            break;
          case DocTypeFilter.expenses:
            folderNames = folderNames.where((n) => byFolder[n]!.expenses > 0).toList();
            break;
        }

        final trimmedQuery = searchQuery.trim().toLowerCase();
        if (trimmedQuery.isNotEmpty) {
          folderNames = folderNames
              .where((name) => name.toLowerCase().contains(trimmedQuery))
              .toList();
        }

        // Re-order per sortOption. nameAsc is a no-op (folderNames is
        // already alphabetical from the sort above); the rest all re-sort
        // in place, running after search/type filtering on the
        // already-narrowed list. recentActivity/oldestActivity order by
        // each folder's most-recently-edited document — folders with no
        // tracked activity (shouldn't normally happen, since a folder only
        // exists because it has documents) sort to the end rather than
        // crashing on a null comparison.
        switch (sortOption) {
          case FolderSortOption.nameAsc:
            break;
          case FolderSortOption.nameDesc:
            folderNames = folderNames.reversed.toList();
            break;
          case FolderSortOption.mostDocuments:
            folderNames.sort((a, b) => byFolder[b]!.total.compareTo(byFolder[a]!.total));
            break;
          case FolderSortOption.leastDocuments:
            folderNames.sort((a, b) => byFolder[a]!.total.compareTo(byFolder[b]!.total));
            break;
          case FolderSortOption.recentActivity:
            folderNames.sort((a, b) {
              final da = byFolder[a]!.lastActivity;
              final db = byFolder[b]!.lastActivity;
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return db.compareTo(da);
            });
            break;
          case FolderSortOption.oldestActivity:
            folderNames.sort((a, b) {
              final da = byFolder[a]!.lastActivity;
              final db = byFolder[b]!.lastActivity;
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });
            break;
        }

        if (folderNames.isEmpty) {
          final cs = Theme.of(context).colorScheme;
          // Distinguish "nothing exists yet" from "search/type filter
          // matched nothing" — an empty result on a populated folder list
          // shouldn't read the same as a brand-new, never-used account.
          final isFilterMiss = allFolderNamesCount > 0 &&
              (trimmedQuery.isNotEmpty || typeFilter != DocTypeFilter.all);
          return Padding(
            padding: padding,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFilterMiss ? Icons.search_off_rounded : Icons.folder_off_outlined,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isFilterMiss
                          ? (trimmedQuery.isNotEmpty
                              ? 'No folders match "$searchQuery"'
                              : 'No folders match this filter')
                          : 'No folders yet',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isFilterMiss
                          ? 'Try a different search term or filter.'
                          : 'Long-press a document, then use its ⋮ menu\'s "Move to Folder" to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        List<dynamic> invoicesFor(String name) => invoices.where((inv) => inv.folderName == name).toList();
        List<dynamic> quotesFor(String name) => quotes.where((q) => q.folderName == name).toList();
        List<dynamic> receiptsFor(String name) => receipts.where((r) => r.folderName == name).toList();

        VoidCallback menuFor(BuildContext ctx, String name) => () => _showTileMenu(
              ctx,
              onDownload: () => _showDownloadSheet(
                ctx,
                name,
                invoicesFor(name),
                quotesFor(name),
                receiptsFor(name),
              ),
              onRename: () => _renameFolder(ctx, name),
              onDelete: () => _deleteFolder(ctx, name),
            );

        switch (layoutMode) {
          case FolderLayoutMode.list:
            return ListView.builder(
              padding: padding,
              shrinkWrap: shrinkWrap,
              physics: physics,
              itemCount: folderNames.length,
              itemBuilder: (context, i) {
                final name = folderNames[i];
                final counts = byFolder[name]!;
                return _FolderListRow(
                  name: name,
                  counts: counts,
                  color: _colorFor(name),
                  isLast: i == folderNames.length - 1,
                  onTap: () => onFolderTap(name),
                  onShowMenu: menuFor(context, name),
                );
              },
            );

          case FolderLayoutMode.compact:
            return ListView.builder(
              padding: padding,
              shrinkWrap: shrinkWrap,
              physics: physics,
              itemCount: folderNames.length,
              itemBuilder: (context, i) {
                final name = folderNames[i];
                final counts = byFolder[name]!;
                return _FolderCompactRow(
                  name: name,
                  counts: counts,
                  color: _colorFor(name),
                  isLast: i == folderNames.length - 1,
                  onTap: () => onFolderTap(name),
                  onShowMenu: menuFor(context, name),
                );
              },
            );

          case FolderLayoutMode.compactGrid:
            return GridView.builder(
              padding: padding,
              shrinkWrap: shrinkWrap,
              physics: physics,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 98,
              ),
              itemCount: folderNames.length,
              itemBuilder: (context, i) {
                final name = folderNames[i];
                final counts = byFolder[name]!;
                return _FolderCompactGridTile(
                  name: name,
                  counts: counts,
                  color: _colorFor(name),
                  onTap: () => onFolderTap(name),
                  onShowMenu: menuFor(context, name),
                );
              },
            );

          case FolderLayoutMode.kanban:
            return _FolderKanbanBoard(
              folderNames: folderNames,
              byFolder: byFolder,
              colorFor: _colorFor,
              onFolderTap: onFolderTap,
              onShowMenu: (name) => menuFor(context, name)(),
            );

          case FolderLayoutMode.grid:
            return GridView.builder(
              padding: padding,
              shrinkWrap: shrinkWrap,
              physics: physics,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 128,
              ),
              itemCount: folderNames.length,
              itemBuilder: (context, i) {
                final name = folderNames[i];
                final counts = byFolder[name]!;
                return _FolderTile(
                  name: name,
                  counts: counts,
                  color: _colorFor(name),
                  onTap: () => onFolderTap(name),
                  onShowMenu: menuFor(context, name),
                  onDownload: () => _showDownloadSheet(
                    context,
                    name,
                    invoicesFor(name),
                    quotesFor(name),
                    receiptsFor(name),
                  ),
                );
              },
            );
        }
      },
    );
  }
}

class _FolderCounts {
  int invoices = 0;
  int quotes = 0;
  int receipts = 0;
  int expenses = 0;
  DateTime? lastActivity;
  int get total => invoices + quotes + receipts + expenses;

  void trackActivity(DateTime dt) {
    if (lastActivity == null || dt.isAfter(lastActivity!)) {
      lastActivity = dt;
    }
  }
}

// ── Grid tile (original layout) ─────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  final String name;
  final _FolderCounts counts;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onShowMenu;
  final VoidCallback onDownload;

  const _FolderTile({
    required this.name,
    required this.counts,
    required this.color,
    required this.onTap,
    required this.onShowMenu,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Stack lets the download button sit half-outside the card's bottom-right
    // corner (a "badge" position) so it reads as a prominent, tappable
    // action rather than another small inline icon competing with ⋮.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          onLongPress: onShowMenu,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.folder_rounded, color: color, size: 19),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: onShowMenu,
                      icon: Icon(Icons.more_horiz_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${counts.total} document${counts.total == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (counts.invoices > 0) '${counts.invoices} inv',
                    if (counts.quotes > 0) '${counts.quotes} quo',
                    if (counts.receipts > 0) '${counts.receipts} rec',
                    if (counts.expenses > 0) '${counts.expenses} exp',
                  ].join(' · '),
                  style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.45)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // ── Download button — bottom-right, larger and more prominent ──
        Positioned(
          right: -6,
          bottom: -6,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: color.withValues(alpha: 0.5),
            child: InkWell(
              onTap: onDownload,
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E2235) : Colors.white,
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.file_download_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── List row ───────────────────────────────────────────────────────────
//
// Single-column equivalent of _FolderTile — same data, same tap/long-press
// behavior (tap opens the folder, long-press or the trailing ⋮ opens the
// same rename/delete/download menu), just laid out as a horizontal card
// so more folders are readable at once without the "which corner is the
// name in" scan a 2-across grid requires. isLast drops the bottom margin
// on the final row so the list doesn't end with extra trailing space.

class _FolderListRow extends StatelessWidget {
  final String name;
  final _FolderCounts counts;
  final Color color;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onShowMenu;

  const _FolderListRow({
    required this.name,
    required this.counts,
    required this.color,
    required this.isLast,
    required this.onTap,
    required this.onShowMenu,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Material(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          onLongPress: onShowMenu,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.folder_rounded, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          '${counts.total} document${counts.total == 1 ? '' : 's'}',
                          if (counts.invoices > 0) '${counts.invoices} inv',
                          if (counts.quotes > 0) '${counts.quotes} quo',
                          if (counts.receipts > 0) '${counts.receipts} rec',
                          if (counts.expenses > 0) '${counts.expenses} exp',
                        ].join(' · '),
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onShowMenu,
                  icon: Icon(Icons.more_horiz_rounded, size: 19, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact row ──────────────────────────────────────────────────────────
//
// Leaner single-line equivalent of _FolderListRow — icon, name, total
// count, and the ⋮ menu, all on one row with tighter padding. Mirrors the
// spirit of the main document list's DocLayoutMode.compact (_DocCompactRow)
// so "Compact" reads the same way across folders and documents.

class _FolderCompactRow extends StatelessWidget {
  final String name;
  final _FolderCounts counts;
  final Color color;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onShowMenu;

  const _FolderCompactRow({
    required this.name,
    required this.counts,
    required this.color,
    required this.isLast,
    required this.onTap,
    required this.onShowMenu,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Material(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onShowMenu,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_rounded, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${counts.total}',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: onShowMenu,
                  icon: Icon(Icons.more_horiz_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact grid tile ──────────────────────────────────────────────────
//
// 4-across mini tile — icon, single-line name, doc count. Mirrors the main
// document list's DocLayoutMode.compactGrid (_DocCompactGridCard) sizing
// so both grids read consistently when flipped between.

class _FolderCompactGridTile extends StatelessWidget {
  final String name;
  final _FolderCounts counts;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onShowMenu;

  const _FolderCompactGridTile({
    required this.name,
    required this.counts,
    required this.color,
    required this.onTap,
    required this.onShowMenu,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onShowMenu,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder_rounded, color: color, size: 22),
            const Spacer(),
            Text(
              name,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${counts.total} doc${counts.total == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kanban board ──────────────────────────────────────────────────────
//
// Documents key their kanban columns off a status enum (paid/unpaid,
// sent/accepted, etc.) — folders have no such field, so columns are keyed
// by dominant document type instead: a folder lands in Invoices/Quotes/
// Receipts/Expenses when every document inside it is that one type, or
// Mixed when it contains more than one type. Empty columns are simply not
// rendered.

class _FolderKanbanBoard extends StatelessWidget {
  final List<String> folderNames;
  final Map<String, _FolderCounts> byFolder;
  final Color Function(String) colorFor;
  final ValueChanged<String> onFolderTap;
  final ValueChanged<String> onShowMenu;

  const _FolderKanbanBoard({
    required this.folderNames,
    required this.byFolder,
    required this.colorFor,
    required this.onFolderTap,
    required this.onShowMenu,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> columns = {
      'Invoices': [],
      'Quotes': [],
      'Receipts': [],
      'Expenses': [],
      'Mixed': [],
    };

    for (final name in folderNames) {
      final c = byFolder[name]!;
      final types = [
        if (c.invoices > 0) 'Invoices',
        if (c.quotes > 0) 'Quotes',
        if (c.receipts > 0) 'Receipts',
        if (c.expenses > 0) 'Expenses',
      ];
      if (types.length == 1) {
        columns[types.first]!.add(name);
      } else {
        columns['Mixed']!.add(name);
      }
    }

    final nonEmptyColumns = columns.entries.where((e) => e.value.isNotEmpty).toList();

    return SizedBox(
      height: 420,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: nonEmptyColumns.length,
        itemBuilder: (context, i) {
          final entry = nonEmptyColumns[i];
          return _FolderKanbanColumn(
            title: entry.key,
            folderNames: entry.value,
            byFolder: byFolder,
            colorFor: colorFor,
            onFolderTap: onFolderTap,
            onShowMenu: onShowMenu,
          );
        },
      ),
    );
  }
}

class _FolderKanbanColumn extends StatelessWidget {
  final String title;
  final List<String> folderNames;
  final Map<String, _FolderCounts> byFolder;
  final Color Function(String) colorFor;
  final ValueChanged<String> onFolderTap;
  final ValueChanged<String> onShowMenu;

  const _FolderKanbanColumn({
    required this.title,
    required this.folderNames,
    required this.byFolder,
    required this.colorFor,
    required this.onFolderTap,
    required this.onShowMenu,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              '$title · ${folderNames.length}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: folderNames.length,
              itemBuilder: (context, i) {
                final name = folderNames[i];
                final counts = byFolder[name]!;
                return _FolderKanbanCard(
                  name: name,
                  counts: counts,
                  color: colorFor(name),
                  onTap: () => onFolderTap(name),
                  onShowMenu: () => onShowMenu(name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderKanbanCard extends StatelessWidget {
  final String name;
  final _FolderCounts counts;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onShowMenu;

  const _FolderKanbanCard({
    required this.name,
    required this.counts,
    required this.color,
    required this.onTap,
    required this.onShowMenu,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onShowMenu,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${counts.total} document${counts.total == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: onShowMenu,
                  icon: Icon(Icons.more_horiz_rounded, size: 15, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
