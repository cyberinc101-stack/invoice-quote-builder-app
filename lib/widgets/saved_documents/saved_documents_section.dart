library saved_documents_section;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../models/expense_data.dart';
import '../../filters/filter_types.dart';
import '../../filters/filter_logic.dart';
import '../../export/bulk_document_export_service.dart';
import '../../screens/saved_invoice_details_section/saved_document_detail_screen.dart';
import '../../screens/expense_detail_screen.dart';
import '../../screens/expense_screen.dart';
import '../document_filter_bar.dart';
import '../document_status_menu.dart';
import '../folders_grid_view.dart';
import '../shared_logo_picker.dart';
import '../expenses/expense_card_shared.dart';
import '../expenses/expense_cards.dart';
import 'card_display_prefs.dart';
import 'display_options_button.dart';
import 'saved_layout_prefs.dart';

part 'doc_layout_mode.dart';
part 'doc_card_shared.dart';
part 'doc_cards.dart';
part 'doc_kanban.dart';

// DISPLAY OPTIONS PASS (this update): _SectionHeader now gets a third
// control — displayOptionsToggle — passed for the Invoices/Quotes/Receipts
// sections, rendered right next to the existing layoutToggle. It opens
// DisplayOptionsButton's sheet (display_options_button.dart), which reads/
// writes CardDisplayPrefs (card_display_prefs.dart) — a persisted,
// app-wide set of switches for which stats show on the cards themselves
// (secondary date, created date + item count, progress bar, status chip,
// amount, logo). doc_cards.dart's four card widgets watch CardDisplayPrefs
// directly, so flipping a switch in the sheet updates every visible card
// immediately, across whichever DocLayoutMode is currently active. The
// Expenses section gets the same displayOptionsToggle now too, paired
// with its existing ExpenseSortToggleButton, since expense_cards.dart's
// four layouts watch the exact same CardDisplayPrefs instance — one set
// of switches controls Invoices/Quotes/Receipts/Expenses together.
//
// EXPENSES SECTION PASS (earlier): a new "My Expenses" section now
// renders right after "My Receipts" whenever the All pill (or the new
// Expenses pill) is selected — closing the last gap where expenses lived
// entirely on their own screen with no presence on Home. Rather than
// build a parallel _DocEntry-compatible card family for expenses, this
// section reuses ExpenseCardEntry + ExpenseListCard/ExpenseGridCard/
// ExpenseCompactGridCard/ExpenseCompactRow directly from
// lib/widgets/expenses/ — the exact same widgets the Expenses screen
// itself renders, so the two screens stay visually identical by
// construction rather than by kept-in-sync duplication.
//
// Filtering for expenses routes through the same filter_logic.dart
// helpers expense_screen.dart already uses (searchExpenses,
// filterExpensesByDateRange/AmountRange/Folder, sortExpenses) so the
// Home search box, date range, amount range, folder filter, and sort all
// apply to the expenses section too, composing with the existing
// invoice/quote/receipt filtering above it. Expenses have no quick-filter
// concept (needsAction/overdue/drafts don't apply), so quick filters are
// left untouched for them, matching how the Expenses screen itself has no
// quick-filter row either.
//
// Selection mode is shared across all four sections: an expense card's
// key is 'expense:<id>', following the same 'type:id' convention the
// other three types use, so _confirmDelete/_confirmDeleteSingle/
// _openFolderSheet's per-key switches just needed one more case each to
// support bulk delete and bulk move-to-folder on expense selections too.
// Bulk CSV export stays invoice/quote/receipt-only (expenses have their
// own export format via expense_export_service.dart) — selecting an
// expense card and exporting simply leaves it out of the CSV, same as
// before this pass.
//
// Layout: expenses map DocLayoutMode -> the nearest ExpenseLayoutMode
// (list/grid/compactGrid/compact); DocLayoutMode.kanban has no expense
// equivalent (expenses have no status field to build columns from), so it
// falls back to the expense list layout when kanban is the active mode.

({String label, Color color}) _paymentStatusInfo(PaymentStatus s) {
  switch (s) {
    case PaymentStatus.paid:
      return (label: 'Paid', color: const Color(0xFF4CAF50));
    case PaymentStatus.partial:
      return (label: 'Partial', color: const Color(0xFF2196F3));
    case PaymentStatus.overdue:
      return (label: 'Overdue', color: const Color(0xFFE53935));
    case PaymentStatus.unpaid:
      return (label: 'Unpaid', color: const Color(0xFFFF9800));
  }
}

({String label, Color color}) _quoteStatusInfo(QuoteStatus s) {
  switch (s) {
    case QuoteStatus.accepted:
      return (label: 'Accepted', color: const Color(0xFF4CAF50));
    case QuoteStatus.sent:
      return (label: 'Sent', color: const Color(0xFF2196F3));
    case QuoteStatus.declined:
      return (label: 'Declined', color: const Color(0xFFE53935));
    case QuoteStatus.expired:
      return (label: 'Expired', color: const Color(0xFF9E9E9E));
    case QuoteStatus.draft:
      return (label: 'Draft', color: const Color(0xFFFF9800));
  }
}

({String label, Color color}) _receiptStatusInfo(ReceiptStatus s) {
  switch (s) {
    case ReceiptStatus.issued:
      return (label: 'Issued', color: const Color(0xFF4CAF50));
    case ReceiptStatus.refunded:
      return (label: 'Refunded', color: const Color(0xFFE53935));
  }
}

String _formatShortDate(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

// Shared currency formatter for the amount stat shown on every card layout.
// Kept as a single top-level function (rather than repeating NumberFormat
// calls in doc_cards.dart / doc_kanban.dart) so the format only needs to
// change in one place later if a currency-symbol setting gets added.
final NumberFormat _cardAmountFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
String _formatCardAmount(double v) => _cardAmountFormat.format(v);

// Converts between the shared, cross-screen SharedDocLayout (persisted via
// SavedLayoutPrefs, also read by reports_document_list.dart) and this
// library's own DocLayoutMode. Kanban has no shared equivalent — callers
// treat a null result from _toShared() as "don't touch the shared pref,
// this is a local-only choice."
DocLayoutMode _fromShared(SharedDocLayout s) {
  switch (s) {
    case SharedDocLayout.list:
      return DocLayoutMode.list;
    case SharedDocLayout.grid:
      return DocLayoutMode.grid;
    case SharedDocLayout.compactGrid:
      return DocLayoutMode.compactGrid;
    case SharedDocLayout.compact:
      return DocLayoutMode.compact;
  }
}

SharedDocLayout? _toShared(DocLayoutMode m) {
  switch (m) {
    case DocLayoutMode.list:
      return SharedDocLayout.list;
    case DocLayoutMode.grid:
      return SharedDocLayout.grid;
    case DocLayoutMode.compactGrid:
      return SharedDocLayout.compactGrid;
    case DocLayoutMode.compact:
      return SharedDocLayout.compact;
    case DocLayoutMode.kanban:
      return null;
  }
}

class _DocEntry {
  final String key;
  final String title;
  final String subtitle;
  final String date;
  final String secondaryDateLabel;
  final String secondaryDateValue;
  final int percent;
  final Color accentColor;
  final String statusLabel;
  final VoidCallback onTap;
  final VoidCallback onShowMenu;
  final bool isPositiveStatus;

  // Business logo (for the card avatar, falls back to initials/icon),
  // created date (distinct from last-edited `date` above), line-item count,
  // and the document's final total (grandTotal / amountPaid).
  final String? logoPath;
  final String businessName;
  final String createdLabel;
  final int itemCount;
  final double totalAmount;

  const _DocEntry({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.secondaryDateLabel,
    required this.secondaryDateValue,
    required this.percent,
    required this.accentColor,
    required this.statusLabel,
    required this.onTap,
    required this.onShowMenu,
    required this.isPositiveStatus,
    required this.logoPath,
    required this.businessName,
    required this.createdLabel,
    required this.itemCount,
    required this.totalAmount,
  });
}

class SavedDocumentsSection extends StatefulWidget {
  final String? initialFolder;

  const SavedDocumentsSection({super.key, this.initialFolder});

  @override
  State<SavedDocumentsSection> createState() => _SavedDocumentsSectionState();
}

class _SavedDocumentsSectionState extends State<SavedDocumentsSection> {
  DocTypeFilter    _selectedType           = DocTypeFilter.all;
  PaymentStatus?   _selectedPaymentStatus;
  QuoteStatus?     _selectedQuoteStatus;
  ReceiptStatus?   _selectedReceiptStatus;
  QuickFilter      _selectedQuickFilter    = QuickFilter.none;
  DocLayoutMode    _selectedLayout         = DocLayoutMode.list;
  String           _searchQuery            = '';
  DateRangePreset  _selectedDateRange      = DateRangePreset.all;
  DateTime?        _customRangeStart;
  DateTime?        _customRangeEnd;
  SortOption       _selectedSort           = SortOption.recentFirst;
  double?          _minAmount;
  double?          _maxAmount;
  String?          _selectedFolder;

  bool _browsingFolders = false;

  String _foldersSearchQuery = '';

  FolderSortOption _foldersSortOption = FolderSortOption.nameAsc;

  FolderLayoutMode _foldersLayoutMode = FolderLayoutMode.grid;

  DocTypeFilter _foldersTypeFilter = DocTypeFilter.all;

  bool _selectionMode = false;
  final Set<String> _selectedKeys = {};

  final BulkDocumentExportService _exportService = BulkDocumentExportService();
  bool _exporting = false;

  static const String _kFolderHintShownKey = 'seen_folder_longpress_hint_v1';

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.initialFolder;
    _maybeShowFolderHint();
  }

  Future<void> _maybeShowFolderHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(_kFolderHintShownKey) ?? false;
      if (alreadyShown) return;
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip: long-press a document to select it and move it to a folder'),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });

      await prefs.setBool(_kFolderHintShownKey, true);
    } catch (e) {
      debugPrint('[SavedDocumentsSection] _maybeShowFolderHint error: $e');
    }
  }

  void _enterSelectionMode(String key) {
    setState(() {
      _selectionMode = true;
      _selectedKeys.add(key);
    });
  }

  void _toggleSelection(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
        if (_selectedKeys.isEmpty) _selectionMode = false;
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedKeys.clear();
    });
  }

  Future<void> _confirmDelete() async {
    final count = _selectedKeys.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete documents?'),
        content: Text(
          'This will permanently delete $count selected document${count == 1 ? '' : 's'}. '
          "This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final invoiceProvider = context.read<InvoiceProvider>();
    final quoteProvider   = context.read<QuoteProvider>();
    final receiptProvider = context.read<ReceiptProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    for (final key in _selectedKeys) {
      final sepIndex = key.indexOf(':');
      if (sepIndex == -1) continue;
      final type = key.substring(0, sepIndex);
      final id = key.substring(sepIndex + 1);
      switch (type) {
        case 'invoice':
          invoiceProvider.deleteInvoice(id);
          break;
        case 'quote':
          quoteProvider.deleteQuote(id);
          break;
        case 'receipt':
          receiptProvider.deleteSavedReceipt(id);
          break;
        case 'expense':
          expenseProvider.deleteExpense(id);
          break;
      }
    }

    setState(() {
      _selectionMode = false;
      _selectedKeys.clear();
    });
  }

  Future<void> _confirmDeleteSingle(String key, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('This will permanently delete "$title". This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final sepIndex = key.indexOf(':');
    if (sepIndex == -1) return;
    final type = key.substring(0, sepIndex);
    final id = key.substring(sepIndex + 1);
    switch (type) {
      case 'invoice':
        context.read<InvoiceProvider>().deleteInvoice(id);
        break;
      case 'quote':
        context.read<QuoteProvider>().deleteQuote(id);
        break;
      case 'receipt':
        context.read<ReceiptProvider>().deleteSavedReceipt(id);
        break;
      case 'expense':
        context.read<ExpenseProvider>().deleteExpense(id);
        break;
    }
  }

  Future<void> _showRenameDialogFor({
    required String type,
    required String id,
    required String currentTitle,
  }) async {
    final controller = TextEditingController(text: currentTitle);
    final formKey = GlobalKey<FormState>();

    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Rename', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
            decoration: InputDecoration(
              hintText: 'Enter a name',
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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

    if (title == null || !mounted) return;
    switch (type) {
      case 'invoice':
        context.read<InvoiceProvider>().renameInvoice(id, title);
        break;
      case 'quote':
        context.read<QuoteProvider>().renameQuote(id, title);
        break;
      case 'receipt':
        context.read<ReceiptProvider>().renameSavedReceipt(id, title);
        break;
    }
  }

  void _openFolderSheet({required List<String> availableFolders, Set<String>? overrideKeys}) {
    final keys = overrideKeys ?? _selectedKeys;
    if (keys.isEmpty) return;

    final newFolderController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cs = Theme.of(context).colorScheme;

            void applyFolder(String? rawFolder) {
              final trimmed = rawFolder?.trim();
              final finalFolder = (trimmed == null || trimmed.isEmpty) ? null : trimmed;

              final invoiceProvider = context.read<InvoiceProvider>();
              final quoteProvider   = context.read<QuoteProvider>();
              final receiptProvider = context.read<ReceiptProvider>();
              final expenseProvider = context.read<ExpenseProvider>();

              for (final key in keys) {
                final sepIndex = key.indexOf(':');
                if (sepIndex == -1) continue;
                final type = key.substring(0, sepIndex);
                final id = key.substring(sepIndex + 1);
                switch (type) {
                  case 'invoice':
                    invoiceProvider.updateInvoiceFolder(id, finalFolder);
                    break;
                  case 'quote':
                    quoteProvider.updateQuoteFolder(id, finalFolder);
                    break;
                  case 'receipt':
                    receiptProvider.updateReceiptFolder(id, finalFolder);
                    break;
                  case 'expense':
                    expenseProvider.updateExpensesFolder([id], finalFolder);
                    break;
                }
              }

              Navigator.pop(sheetContext);
              if (overrideKeys == null) {
                setState(() {
                  _selectionMode = false;
                  _selectedKeys.clear();
                });
              }
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(finalFolder == null
                      ? 'Removed from folder'
                      : 'Moved to "$finalFolder"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.folder_outlined, size: 18, color: cs.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Move to Folder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (availableFolders.isNotEmpty) ...[
                      Text(
                        'Existing Folders',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.55),
                          letterSpacing: 0.2,
                        ),
                      ),
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
                                  Icon(Icons.folder_rounded, size: 14, color: cs.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ],

                    Text(
                      'New Folder',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        letterSpacing: 0.2,
                      ),
                    ),
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
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

  void _showInvoiceMenu(SavedInvoice inv, List<String> folders) {
    final provider = context.read<InvoiceProvider>();
    showDocumentOptionsMenu(
      context,
      title: inv.title,
      accent: const Color(0xFF1565C0),
      statusOptions: PaymentStatus.values.map((s) {
        final info = _paymentStatusInfo(s);
        return StatusOption(
          label: info.label,
          color: info.color,
          selected: inv.data.paymentStatus == s,
          onSelect: () {
            Navigator.pop(context);
            provider.updateSavedInvoiceStatus(inv.id, s);
          },
        );
      }).toList(),
      onRename: () => _showRenameDialogFor(type: 'invoice', id: inv.id, currentTitle: inv.title),
      onMoveToFolder: () => _openFolderSheet(
        availableFolders: folders,
        overrideKeys: {'invoice:${inv.id}'},
      ),
      onDelete: () => _confirmDeleteSingle('invoice:${inv.id}', inv.title),
    );
  }

  void _showQuoteMenu(SavedQuote q, List<String> folders) {
    final provider = context.read<QuoteProvider>();
    showDocumentOptionsMenu(
      context,
      title: q.title,
      accent: const Color(0xFF7B1FA2),
      statusOptions: QuoteStatus.values.map((s) {
        final info = _quoteStatusInfo(s);
        return StatusOption(
          label: info.label,
          color: info.color,
          selected: q.data.quoteStatus == s,
          onSelect: () {
            Navigator.pop(context);
            provider.updateSavedQuoteStatus(q.id, s);
          },
        );
      }).toList(),
      onRename: () => _showRenameDialogFor(type: 'quote', id: q.id, currentTitle: q.title),
      onMoveToFolder: () => _openFolderSheet(
        availableFolders: folders,
        overrideKeys: {'quote:${q.id}'},
      ),
      onDelete: () => _confirmDeleteSingle('quote:${q.id}', q.title),
    );
  }

  void _showReceiptMenu(SavedReceipt r, List<String> folders) {
    final provider = context.read<ReceiptProvider>();
    showDocumentOptionsMenu(
      context,
      title: r.title,
      accent: const Color(0xFF2E7D32),
      statusOptions: ReceiptStatus.values.map((s) {
        final info = _receiptStatusInfo(s);
        return StatusOption(
          label: info.label,
          color: info.color,
          selected: r.data.status == s,
          onSelect: () {
            Navigator.pop(context);
            provider.updateSavedReceiptStatus(r.id, s);
          },
        );
      }).toList(),
      onRename: () => _showRenameDialogFor(type: 'receipt', id: r.id, currentTitle: r.title),
      onMoveToFolder: () => _openFolderSheet(
        availableFolders: folders,
        overrideKeys: {'receipt:${r.id}'},
      ),
      onDelete: () => _confirmDeleteSingle('receipt:${r.id}', r.title),
    );
  }

  // Expenses have no status enum (only excludeFromReports), so this is a
  // plain ListTile sheet rather than showDocumentOptionsMenu — mirrors
  // expense_screen.dart's own _showItemMenu (Edit/Move to Folder/
  // Exclude-Include/Delete), reusing openExpenseFormSheet and
  // openExpenseFolderSheet (both public in expense_screen.dart) so the
  // exact same sheets open here as on the Expenses screen itself.
  void _showExpenseMenu(ExpenseEntry e) {
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
                openExpenseFormSheet(context, existing: e);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: kExpenseAccent),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(context);
                openExpenseFolderSheet(context, ids: {e.id});
              },
            ),
            ListTile(
              leading: Icon(
                e.excludeFromReports ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: kExpenseAccent,
              ),
              title: Text(e.excludeFromReports ? 'Include in reports' : 'Exclude from reports'),
              onTap: () {
                Navigator.pop(context);
                context.read<ExpenseProvider>().updateExpenseExcludeFromReports(e.id, !e.excludeFromReports);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: kExpenseAccent),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<ExpenseProvider>().deleteExpenses([e.id]);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openExportSheet({
    required List<SavedInvoice> allInvoices,
    required List<SavedQuote> allQuotes,
    required List<SavedReceipt> allReceipts,
  }) {
    if (_selectedKeys.isEmpty) return;

    final selectedInvoiceIds = <String>{};
    final selectedQuoteIds = <String>{};
    final selectedReceiptIds = <String>{};
    for (final key in _selectedKeys) {
      final sepIndex = key.indexOf(':');
      if (sepIndex == -1) continue;
      final type = key.substring(0, sepIndex);
      final id = key.substring(sepIndex + 1);
      switch (type) {
        case 'invoice':
          selectedInvoiceIds.add(id);
          break;
        case 'quote':
          selectedQuoteIds.add(id);
          break;
        case 'receipt':
          selectedReceiptIds.add(id);
          break;
        // 'expense' keys are intentionally not handled here — expenses
        // export via their own format (expense_export_service.dart), so
        // an expense selected alongside documents just doesn't appear in
        // this CSV, same as before this pass.
      }
    }

    final selectedInvoices =
        allInvoices.where((i) => selectedInvoiceIds.contains(i.id)).toList();
    final selectedQuotes =
        allQuotes.where((q) => selectedQuoteIds.contains(q.id)).toList();
    final selectedReceipts =
        allReceipts.where((r) => selectedReceiptIds.contains(r.id)).toList();

    final defaultName =
        'Documents_Export_${DateFormat('d_MMM_yyyy').format(DateTime.now())}';
    final nameController = TextEditingController(text: defaultName);
    final totalCount = selectedInvoices.length + selectedQuotes.length + selectedReceipts.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cs = Theme.of(context).colorScheme;

            Future<void> handleExport(bool share) async {
              setSheetState(() => _exporting = true);
              try {
                String? savedPath;
                if (share) {
                  await _exportService.share(
                    fileName: nameController.text,
                    invoices: selectedInvoices,
                    quotes: selectedQuotes,
                    receipts: selectedReceipts,
                  );
                } else {
                  savedPath = await _exportService.exportToDownloads(
                    fileName: nameController.text,
                    invoices: selectedInvoices,
                    quotes: selectedQuotes,
                    receipts: selectedReceipts,
                  );
                }
                if (!mounted || !sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                setState(() {
                  _selectionMode = false;
                  _selectedKeys.clear();
                });
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(share
                        ? 'Opening share sheet…'
                        : 'Saved "${nameController.text}.csv" to Downloads'),
                    behavior: SnackBarBehavior.floating,
                    action: (!share && savedPath != null)
                        ? SnackBarAction(
                            label: 'Open',
                            onPressed: () => OpenFile.open(savedPath!),
                          )
                        : null,
                  ),
                );
              } catch (e) {
                if (!sheetContext.mounted) return;
                setSheetState(() => _exporting = false);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Export failed: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
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
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.ios_share_rounded, size: 18, color: cs.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export as CSV',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                '$totalCount document${totalCount == 1 ? '' : 's'} selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'File Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.045),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                      ),
                      child: TextField(
                        controller: nameController,
                        autofocus: true,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          suffixText: '.csv',
                          suffixStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    if (_exporting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => handleExport(false),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Save to Device'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => handleExport(true),
                              icon: const Icon(Icons.ios_share_rounded, size: 18),
                              label: const Text('Share'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
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
    ).whenComplete(() {
      if (mounted) setState(() => _exporting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer4<InvoiceProvider, QuoteProvider, ReceiptProvider, ExpenseProvider>(
      builder: (context, invoiceProvider, quoteProvider, receiptProvider, expenseProvider, _) {
        final categories = context.watch<CategoryProvider>();
        // Keep _selectedLayout in sync with the shared, cross-screen layout
        // preference (also read by Reports) — unless Kanban is active,
        // which is a local-only choice with no shared equivalent.
        final layoutPrefs = context.watch<SavedLayoutPrefs>();
        if (_selectedLayout != DocLayoutMode.kanban) {
          _selectedLayout = _fromShared(layoutPrefs.layout);
        }

        final allInvoices = invoiceProvider.savedInvoices;
        final allQuotes   = quoteProvider.savedQuotes;
        final allReceipts = receiptProvider.savedReceipts;
        final allExpenses = expenseProvider.expenses;

        final needsActionCount = countNeedsAction(invoices: allInvoices, quotes: allQuotes);
        final overdueCount     = countOverdue(allInvoices);
        final draftsCount      = countDrafts(
          invoices: allInvoices,
          quotes:   allQuotes,
          receipts: allReceipts,
        );
        // Union in expense folder names too — collectFolderNames() (from
        // filter_logic.dart) only knows about invoices/quotes/receipts,
        // so expenses' own folder assignments are merged in here rather
        // than touching that helper's signature.
        final allFolderNames = <String>{
          ...collectFolderNames(
            invoices: allInvoices,
            quotes:   allQuotes,
            receipts: allReceipts,
          ),
          ...expenseProvider.folderNames,
        }.toList()
          ..sort();

        final invoiceFolderNames = allInvoices
            .where((i) => i.folderName != null && i.folderName!.trim().isNotEmpty)
            .map((i) => i.folderName!)
            .toSet();
        final quoteFolderNames = allQuotes
            .where((q) => q.folderName != null && q.folderName!.trim().isNotEmpty)
            .map((q) => q.folderName!)
            .toSet();
        final receiptFolderNames = allReceipts
            .where((r) => r.folderName != null && r.folderName!.trim().isNotEmpty)
            .map((r) => r.folderName!)
            .toSet();
        final expenseFolderNames = allExpenses
            .where((e) => e.folderName != null && e.folderName!.trim().isNotEmpty)
            .map((e) => e.folderName!)
            .toSet();

        var visibleFolderNames = allFolderNames;
        switch (_foldersTypeFilter) {
          case DocTypeFilter.all:
            break;
          case DocTypeFilter.invoices:
            visibleFolderNames =
                visibleFolderNames.where(invoiceFolderNames.contains).toList();
            break;
          case DocTypeFilter.quotes:
            visibleFolderNames =
                visibleFolderNames.where(quoteFolderNames.contains).toList();
            break;
          case DocTypeFilter.receipts:
            visibleFolderNames =
                visibleFolderNames.where(receiptFolderNames.contains).toList();
            break;
          case DocTypeFilter.expenses:
            visibleFolderNames =
                visibleFolderNames.where(expenseFolderNames.contains).toList();
            break;
        }
        final trimmedFoldersQuery = _foldersSearchQuery.trim().toLowerCase();
        if (trimmedFoldersQuery.isNotEmpty) {
          visibleFolderNames = visibleFolderNames
              .where((n) => n.toLowerCase().contains(trimmedFoldersQuery))
              .toList();
        }

        var filteredInvoices = allInvoices;
        var filteredQuotes   = allQuotes;
        var filteredReceipts = allReceipts;
        var filteredExpenses = allExpenses;

        if (_selectedType == DocTypeFilter.invoices) {
          filteredQuotes   = const [];
          filteredReceipts = const [];
          filteredExpenses = const [];
        } else if (_selectedType == DocTypeFilter.quotes) {
          filteredInvoices = const [];
          filteredReceipts = const [];
          filteredExpenses = const [];
        } else if (_selectedType == DocTypeFilter.receipts) {
          filteredInvoices = const [];
          filteredQuotes   = const [];
          filteredExpenses = const [];
        } else if (_selectedType == DocTypeFilter.expenses) {
          filteredInvoices = const [];
          filteredQuotes   = const [];
          filteredReceipts = const [];
        }
        // DocTypeFilter.all: every list stays as-is.

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
        // No quick-filter concept for expenses (needsAction/overdue/
        // drafts don't apply) — left untouched, same as on the Expenses
        // screen itself.

        filteredInvoices = searchInvoices(filteredInvoices, _searchQuery);
        filteredQuotes   = searchQuotes(filteredQuotes, _searchQuery);
        filteredReceipts = searchReceipts(filteredReceipts, _searchQuery);
        filteredExpenses = searchExpenses(filteredExpenses, _searchQuery);

        filteredInvoices = filterInvoicesByDateRange(filteredInvoices, _selectedDateRange,
            customStart: _customRangeStart, customEnd: _customRangeEnd);
        filteredQuotes   = filterQuotesByDateRange(filteredQuotes, _selectedDateRange,
            customStart: _customRangeStart, customEnd: _customRangeEnd);
        filteredReceipts = filterReceiptsByDateRange(filteredReceipts, _selectedDateRange,
            customStart: _customRangeStart, customEnd: _customRangeEnd);
        filteredExpenses = filterExpensesByDateRange(filteredExpenses, _selectedDateRange,
            customStart: _customRangeStart, customEnd: _customRangeEnd);

        filteredInvoices = filterInvoicesByAmountRange(filteredInvoices, _minAmount, _maxAmount);
        filteredQuotes   = filterQuotesByAmountRange(filteredQuotes, _minAmount, _maxAmount);
        filteredReceipts = filterReceiptsByAmountRange(filteredReceipts, _minAmount, _maxAmount);
        filteredExpenses = filterExpensesByAmountRange(filteredExpenses, _minAmount, _maxAmount);

        filteredInvoices = filterInvoicesByFolder(filteredInvoices, _selectedFolder);
        filteredQuotes   = filterQuotesByFolder(filteredQuotes, _selectedFolder);
        filteredReceipts = filterReceiptsByFolder(filteredReceipts, _selectedFolder);
        filteredExpenses = filterExpensesByFolder(filteredExpenses, _selectedFolder);

        filteredInvoices = sortInvoices(filteredInvoices, _selectedSort);
        filteredQuotes   = sortQuotes(filteredQuotes, _selectedSort);
        filteredReceipts = sortReceipts(filteredReceipts, _selectedSort);
        filteredExpenses = sortExpenses(filteredExpenses, _selectedSort);

        final hasResults = filteredInvoices.isNotEmpty ||
            filteredQuotes.isNotEmpty ||
            filteredReceipts.isNotEmpty ||
            filteredExpenses.isNotEmpty;

        final invoiceEntries = filteredInvoices
            .map((inv) => _DocEntry(
                  key: 'invoice:${inv.id}',
                  title: inv.title,
                  subtitle: inv.templateName,
                  date: inv.lastEditedDisplay(),
                  secondaryDateLabel:
                      inv.data.paymentStatus == PaymentStatus.paid ? 'Paid' : 'Due',
                  secondaryDateValue: inv.data.paymentStatus == PaymentStatus.paid
                      ? (inv.data.paidDate != null
                          ? _formatShortDate(inv.data.paidDate!)
                          : '—')
                      : (inv.data.dueDate.isEmpty ? '—' : inv.data.dueDate),
                  percent: inv.completionPercent,
                  accentColor: const Color(0xFF1565C0),
                  statusLabel: inv.data.paymentStatus.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedDocumentDetailScreen.invoice(inv),
                    ),
                  ),
                  onShowMenu: () => _showInvoiceMenu(inv, allFolderNames),
                  isPositiveStatus: inv.data.paymentStatus == PaymentStatus.paid,
                  logoPath: inv.data.businessLogoPath,
                  businessName: inv.data.businessName,
                  createdLabel: _formatShortDate(inv.createdAt),
                  itemCount: inv.data.lineItems.length,
                  totalAmount: inv.data.grandTotal,
                ))
            .toList();

        final quoteEntries = filteredQuotes
            .map((q) => _DocEntry(
                  key: 'quote:${q.id}',
                  title: q.title,
                  subtitle: q.templateName,
                  date: q.lastEditedDisplay(),
                  secondaryDateLabel: 'Expires',
                  secondaryDateValue:
                      q.data.expiryDate.isEmpty ? '—' : q.data.expiryDate,
                  percent: q.completionPercent,
                  accentColor: const Color(0xFF7B1FA2),
                  statusLabel: q.data.quoteStatus.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedDocumentDetailScreen.quote(q),
                    ),
                  ),
                  onShowMenu: () => _showQuoteMenu(q, allFolderNames),
                  isPositiveStatus: q.data.quoteStatus == QuoteStatus.accepted,
                  logoPath: q.data.businessLogoPath,
                  businessName: q.data.businessName,
                  createdLabel: _formatShortDate(q.createdAt),
                  itemCount: q.data.lineItems.length,
                  totalAmount: q.data.grandTotal,
                ))
            .toList();

        final receiptEntries = filteredReceipts
            .map((r) => _DocEntry(
                  key: 'receipt:${r.id}',
                  title: r.title,
                  subtitle: r.templateName,
                  date: r.lastEditedDisplay(),
                  secondaryDateLabel: 'Paid',
                  secondaryDateValue:
                      r.data.paymentDate.isEmpty ? '—' : r.data.paymentDate,
                  percent: r.completionPercent,
                  accentColor: const Color(0xFF2E7D32),
                  statusLabel: r.data.status.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedDocumentDetailScreen.receipt(r),
                    ),
                  ),
                  onShowMenu: () => _showReceiptMenu(r, allFolderNames),
                  isPositiveStatus: r.data.status == ReceiptStatus.issued,
                  logoPath: r.data.businessLogoPath,
                  businessName: r.data.businessName,
                  createdLabel: _formatShortDate(r.createdAt),
                  itemCount: r.data.lineItems.length,
                  totalAmount: r.data.amountPaid,
                ))
            .toList();

        // Expenses render via the same ExpenseCardEntry + card widgets the
        // Expenses screen itself uses (see expense_card_shared.dart /
        // expense_cards.dart) rather than a parallel _DocEntry-shaped
        // family — visual parity by sharing the widgets, not by keeping
        // two implementations in sync.
        final expenseEntries = filteredExpenses
            .map((e) => ExpenseCardEntry(
                  key: 'expense:${e.id}',
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
                  onShowMenu: () => _showExpenseMenu(e),
                ))
            .toList();

        final showToggleOnInvoices = invoiceEntries.isNotEmpty;
        final showToggleOnQuotes   = !showToggleOnInvoices && quoteEntries.isNotEmpty;
        final showToggleOnReceipts = !showToggleOnInvoices && !showToggleOnQuotes && receiptEntries.isNotEmpty;
        final showToggleOnExpenses = !showToggleOnInvoices && !showToggleOnQuotes && !showToggleOnReceipts && expenseEntries.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedFolder != null && !_browsingFolders)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Folder: $_selectedFolder',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFolder = null),
                        child: Icon(Icons.close_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),

            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${_selectedKeys.length} selected',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _cancelSelection,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Cancel'),
                      ),
                      IconButton(
                        tooltip: 'Move to Folder',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: _selectedKeys.isEmpty
                            ? null
                            : () => _openFolderSheet(availableFolders: allFolderNames),
                        icon: Icon(Icons.folder_outlined, size: 19, color: cs.onSurface.withValues(alpha: 0.75)),
                      ),
                      IconButton(
                        tooltip: 'Export as CSV',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: _selectedKeys.isEmpty
                            ? null
                            : () => _openExportSheet(
                                  allInvoices: allInvoices,
                                  allQuotes: allQuotes,
                                  allReceipts: allReceipts,
                                ),
                        icon: Icon(Icons.ios_share_rounded, size: 19, color: cs.primary),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: _selectedKeys.isEmpty ? null : _confirmDelete,
                        icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error),
                      ),
                    ],
                  ),
                ),
              )
            else
              DocumentFilterBar(
                selectedType: _browsingFolders ? _foldersTypeFilter : _selectedType,
                onTypeChanged: (t) => setState(() {
                  if (_browsingFolders) {
                    _foldersTypeFilter = t;
                  } else {
                    _selectedType          = t;
                    _selectedPaymentStatus = null;
                    _selectedQuoteStatus   = null;
                    _selectedReceiptStatus = null;
                  }
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
                invoiceCount: _browsingFolders ? invoiceFolderNames.length : allInvoices.length,
                quoteCount:   _browsingFolders ? quoteFolderNames.length : allQuotes.length,
                receiptCount: _browsingFolders ? receiptFolderNames.length : allReceipts.length,
                expensesCount: _browsingFolders ? expenseFolderNames.length : allExpenses.length,
                selectedQuickFilter: _browsingFolders ? QuickFilter.none : _selectedQuickFilter,
                onQuickFilterChanged: (f) => setState(() {
                  if (!_browsingFolders) _selectedQuickFilter = f;
                }),
                searchQuery: _browsingFolders ? _foldersSearchQuery : _searchQuery,
                onSearchChanged: (v) => setState(() {
                  if (_browsingFolders) {
                    _foldersSearchQuery = v;
                  } else {
                    _searchQuery = v;
                  }
                }),
                searchHint: _browsingFolders ? 'Search folders' : null,
                selectedDateRange: _selectedDateRange,
                onDateRangeChanged: (p) => setState(() => _selectedDateRange = p),
                customRangeStart: _customRangeStart,
                customRangeEnd: _customRangeEnd,
                onCustomRangeChanged: (start, end) => setState(() {
                  _customRangeStart = start;
                  _customRangeEnd   = end;
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
                availableFolders: allFolderNames,
                onFoldersChipTap: () => setState(() {
                  _browsingFolders = !_browsingFolders;
                  if (!_browsingFolders) {
                    _foldersSearchQuery = '';
                  }
                }),
                isBrowsingFolders: _browsingFolders,
                needsActionCount: needsActionCount,
                overdueCount: overdueCount,
                draftsCount: draftsCount,
                overdue1to30Count: countAgingBucket(allInvoices, QuickFilter.overdue1to30),
                overdue31to60Count: countAgingBucket(allInvoices, QuickFilter.overdue31to60),
                overdue61plusCount: countAgingBucket(allInvoices, QuickFilter.overdue61plus),
              ),
            const SizedBox(height: 16),

            // The folder-browsing grid and the document list/empty-state
            // sit inside a single AnimatedSize with distinct ValueKeys per
            // branch, so switching between them (e.g. the first tap on the
            // "Folders" quick-access pill) animates the height change
            // instead of snapping.
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: _browsingFolders
                  ? Padding(
                      key: const ValueKey('folders'),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${visibleFolderNames.length} folder${visibleFolderNames.length == 1 ? '' : 's'}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                              const Spacer(),
                              _FolderSortToggleButton(
                                selected: _foldersSortOption,
                                onChanged: (o) => setState(() => _foldersSortOption = o),
                              ),
                              const SizedBox(width: 8),
                              _FolderLayoutToggleButton(
                                selected: _foldersLayoutMode,
                                onChanged: (m) => setState(() => _foldersLayoutMode = m),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FoldersGridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            searchQuery: _foldersSearchQuery,
                            sortOption: _foldersSortOption,
                            layoutMode: _foldersLayoutMode,
                            typeFilter: _foldersTypeFilter,
                            onFolderTap: (name) => setState(() {
                              _selectedFolder      = name;
                              _browsingFolders     = false;
                              _foldersSearchQuery  = '';
                            }),
                          ),
                        ],
                      ),
                    )
                  : (!hasResults
                      ? Padding(
                          key: const ValueKey('empty'),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Center(
                            child: Text(
                              'No documents match this filter',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          key: const ValueKey('documents'),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (invoiceEntries.isNotEmpty) ...[
                                _SectionHeader(
                                  label: 'My Invoices',
                                  count: invoiceEntries.length,
                                  accentColor: const Color(0xFF1565C0),
                                  sortToggle: showToggleOnInvoices
                                      ? _SortToggleButton(
                                          selected: _selectedSort,
                                          onChanged: (s) => setState(() => _selectedSort = s),
                                        )
                                      : null,
                                  layoutToggle: showToggleOnInvoices
                                      ? _LayoutToggleButton(
                                          selected: _selectedLayout,
                                          onChanged: (m) {
                                          final shared = _toShared(m);
                                          if (shared != null) {
                                            context.read<SavedLayoutPrefs>().setLayout(shared);
                                          } else {
                                            setState(() => _selectedLayout = m);
                                          }
                                        },
                                        )
                                      : null,
                                  displayOptionsToggle: showToggleOnInvoices
                                      ? const DisplayOptionsButton()
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
                                  sortToggle: showToggleOnQuotes
                                      ? _SortToggleButton(
                                          selected: _selectedSort,
                                          onChanged: (s) => setState(() => _selectedSort = s),
                                        )
                                      : null,
                                  layoutToggle: showToggleOnQuotes
                                      ? _LayoutToggleButton(
                                          selected: _selectedLayout,
                                          onChanged: (m) {
                                          final shared = _toShared(m);
                                          if (shared != null) {
                                            context.read<SavedLayoutPrefs>().setLayout(shared);
                                          } else {
                                            setState(() => _selectedLayout = m);
                                          }
                                        },
                                        )
                                      : null,
                                  displayOptionsToggle: showToggleOnQuotes
                                      ? const DisplayOptionsButton()
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
                                  sortToggle: showToggleOnReceipts
                                      ? _SortToggleButton(
                                          selected: _selectedSort,
                                          onChanged: (s) => setState(() => _selectedSort = s),
                                        )
                                      : null,
                                  layoutToggle: showToggleOnReceipts
                                      ? _LayoutToggleButton(
                                          selected: _selectedLayout,
                                          onChanged: (m) {
                                          final shared = _toShared(m);
                                          if (shared != null) {
                                            context.read<SavedLayoutPrefs>().setLayout(shared);
                                          } else {
                                            setState(() => _selectedLayout = m);
                                          }
                                        },
                                        )
                                      : null,
                                  displayOptionsToggle: showToggleOnReceipts
                                      ? const DisplayOptionsButton()
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                _buildEntries(receiptEntries),
                                if (expenseEntries.isNotEmpty) const SizedBox(height: 20),
                              ],
                              if (expenseEntries.isNotEmpty) ...[
                                _SectionHeader(
                                  label: 'My Expenses',
                                  count: expenseEntries.length,
                                  accentColor: kExpenseAccent,
                                  sortToggle: showToggleOnExpenses
                                      ? ExpenseSortToggleButton(
                                          selected: _selectedSort,
                                          onChanged: (s) => setState(() => _selectedSort = s),
                                        )
                                      : null,
                                  layoutToggle: showToggleOnExpenses
                                      ? _LayoutToggleButton(
                                          selected: _selectedLayout,
                                          onChanged: (m) {
                                          final shared = _toShared(m);
                                          if (shared != null) {
                                            context.read<SavedLayoutPrefs>().setLayout(shared);
                                          } else {
                                            setState(() => _selectedLayout = m);
                                          }
                                        },
                                        )
                                      : null,
                                  displayOptionsToggle: showToggleOnExpenses
                                      ? const DisplayOptionsButton()
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                _buildExpenseEntries(expenseEntries),
                              ],
                            ],
                          ),
                        )),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEntries(List<_DocEntry> entries) {
    switch (_selectedLayout) {
      case DocLayoutMode.list:
        return Column(
          children: entries
              .map((e) => _DocCard(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selectedKeys.contains(e.key),
                    onToggleSelect: _toggleSelection,
                    onEnterSelection: _enterSelectionMode,
                  ))
              .toList(),
        );
      case DocLayoutMode.grid:
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 186,
          ),
          children: entries
              .map((e) => _DocGridCard(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selectedKeys.contains(e.key),
                    onToggleSelect: _toggleSelection,
                    onEnterSelection: _enterSelectionMode,
                  ))
              .toList(),
        );
      case DocLayoutMode.compactGrid:
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 120,
          ),
          children: entries
              .map((e) => _DocCompactGridCard(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selectedKeys.contains(e.key),
                    onToggleSelect: _toggleSelection,
                    onEnterSelection: _enterSelectionMode,
                  ))
              .toList(),
        );
      case DocLayoutMode.compact:
        return Column(
          children: entries
              .map((e) => _DocCompactRow(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selectedKeys.contains(e.key),
                    onToggleSelect: _toggleSelection,
                    onEnterSelection: _enterSelectionMode,
                  ))
              .toList(),
        );
      case DocLayoutMode.kanban:
        return _DocKanbanBoard(entries: entries);
    }
  }

  // Expenses map DocLayoutMode -> the nearest ExpenseLayoutMode. There's
  // no expense-kanban equivalent (no status field to build columns from),
  // so kanban falls back to the expense list layout.
  Widget _buildExpenseEntries(List<ExpenseCardEntry> entries) {
    switch (_selectedLayout) {
      case DocLayoutMode.list:
      case DocLayoutMode.kanban:
        return Column(
          children: entries
              .map((e) => ExpenseListCard(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selectedKeys.contains(e.key),
                    onToggleSelect: _toggleSelection,
                    onEnterSelection: _enterSelectionMode,
                  ))
              .toList(),
        );
      case DocLayoutMode.grid:
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
                    selected: _selectedKeys.contains(e.key),
                    onToggleSelect: _toggleSelection,
                    onEnterSelection: _enterSelectionMode,
                  ))
              .toList(),
        );
      case DocLayoutMode.compactGrid:
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
                    selected: _selectedKeys.contains(e.key),
                    onToggleSelect: _toggleSelection,
                    onEnterSelection: _enterSelectionMode,
                  ))
              .toList(),
        );
      case DocLayoutMode.compact:
        return Column(
          children: entries
              .map((e) => ExpenseCompactRow(
                    entry: e,
                    selectionMode: _selectionMode,
                    selected: _selectedKeys.contains(e.key),
                    onToggleSelect: _toggleSelection,
                    onEnterSelection: _enterSelectionMode,
                  ))
              .toList(),
        );
    }
  }
}
