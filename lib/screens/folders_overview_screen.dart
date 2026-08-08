// folders_overview_screen.dart
// lib/screens/folders_overview_screen.dart
//
// Standalone "Folders" browser: shows every folder name in use across
// invoices/quotes/receipts as a tappable tile (icon, name, total count,
// per-type breakdown), plus rename/delete-folder actions via long-press or
// the tile's ⋯ button. Tapping a tile opens SavedDocumentsSection
// pre-filtered to that folder (via initialFolder).
//
// Rename/delete both operate on the *live* provider data by iterating every
// document currently carrying that folder name and calling the same
// updateXFolder(id, name) methods the "Move to Folder" sheet already uses —
// rename re-applies the new name to every doc that had the old one; delete
// clears folderName (passes null) on every doc that had it. Neither ever
// deletes a document, only its folder assignment.
//
// Entry point: wire an IconButton into the AppBar hosting SavedDocumentsSection
// (or wherever makes sense in your nav), e.g.:
//
//   IconButton(
//     tooltip: 'Folders',
//     icon: const Icon(Icons.folder_copy_outlined),
//     onPressed: () => Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const FoldersOverviewScreen()),
//     ),
//   ),

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../widgets/saved_documents/saved_documents_section.dart';

class FoldersOverviewScreen extends StatelessWidget {
  const FoldersOverviewScreen({super.key});

  static const List<Color> _palette = [
    Color(0xFF1565C0),
    Color(0xFF7B1FA2),
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFFAD1457),
    Color(0xFF00838F),
  ];

  Color _colorFor(String name) {
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: Consumer3<InvoiceProvider, QuoteProvider, ReceiptProvider>(
        builder: (context, invoiceProvider, quoteProvider, receiptProvider, _) {
          final invoices = invoiceProvider.savedInvoices;
          final quotes   = quoteProvider.savedQuotes;
          final receipts = receiptProvider.savedReceipts;

          final Map<String, _FolderCounts> byFolder = {};

          for (final inv in invoices) {
            final f = inv.folderName;
            if (f == null || f.trim().isEmpty) continue;
            byFolder.putIfAbsent(f, () => _FolderCounts()).invoices++;
          }
          for (final q in quotes) {
            final f = q.folderName;
            if (f == null || f.trim().isEmpty) continue;
            byFolder.putIfAbsent(f, () => _FolderCounts()).quotes++;
          }
          for (final r in receipts) {
            final f = r.folderName;
            if (f == null || f.trim().isEmpty) continue;
            byFolder.putIfAbsent(f, () => _FolderCounts()).receipts++;
          }

          final folderNames = byFolder.keys.toList()..sort();

          if (folderNames.isEmpty) {
            final cs = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_off_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'No folders yet',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Long-press a document, then use its ⋮ menu\'s "Move to Folder" to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(name)),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SavedDocumentsSection(initialFolder: name),
                      ),
                    ),
                  ),
                ),
                onRename: () => _renameFolder(context, name),
                onDelete: () => _deleteFolder(context, name),
              );
            },
          );
        },
      ),
    );
  }

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
    final quoteProvider   = context.read<QuoteProvider>();
    final receiptProvider = context.read<ReceiptProvider>();

    for (final inv in invoiceProvider.savedInvoices.where((i) => i.folderName == oldName).toList()) {
      invoiceProvider.updateInvoiceFolder(inv.id, newName);
    }
    for (final q in quoteProvider.savedQuotes.where((q) => q.folderName == oldName).toList()) {
      quoteProvider.updateQuoteFolder(q.id, newName);
    }
    for (final r in receiptProvider.savedReceipts.where((r) => r.folderName == oldName).toList()) {
      receiptProvider.updateReceiptFolder(r.id, newName);
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
    final quoteProvider   = context.read<QuoteProvider>();
    final receiptProvider = context.read<ReceiptProvider>();

    for (final inv in invoiceProvider.savedInvoices.where((i) => i.folderName == name).toList()) {
      invoiceProvider.updateInvoiceFolder(inv.id, null);
    }
    for (final q in quoteProvider.savedQuotes.where((q) => q.folderName == name).toList()) {
      quoteProvider.updateQuoteFolder(q.id, null);
    }
    for (final r in receiptProvider.savedReceipts.where((r) => r.folderName == name).toList()) {
      receiptProvider.updateReceiptFolder(r.id, null);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted folder "$name"'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _FolderCounts {
  int invoices = 0;
  int quotes = 0;
  int receipts = 0;
  int get total => invoices + quotes + receipts;
}

class _FolderTile extends StatelessWidget {
  final String name;
  final _FolderCounts counts;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _FolderTile({
    required this.name,
    required this.counts,
    required this.color,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  void _showMenu(BuildContext context) {
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showMenu(context),
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
                  onPressed: () => _showMenu(context),
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
              ].join(' · '),
              style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.45)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
