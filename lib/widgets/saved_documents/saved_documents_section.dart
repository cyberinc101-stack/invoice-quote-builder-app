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
import 'client_color_prefs.dart';

import 'doc_card_shared.dart';
part 'doc_layout_mode.dart';
part 'cards/doc_card_list.dart';
part 'cards/doc_card_grid.dart';
part 'cards/doc_card_compact.dart';
part 'cards/doc_completion_bar.dart';
part 'doc_kanban.dart';

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

final NumberFormat _cardAmountFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
String _formatCardAmount(double v) => _cardAmountFormat.format(v);

String _formatCardAmountShort(double v) {
  final sign = v < 0 ? '-' : '';
  final abs = v.abs();

  String withSuffix(double value, String suffix) {
    var s = value.toStringAsFixed(1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return '$sign\$$s$suffix';
  }

  if (abs >= 1000000000) return withSuffix(abs / 1000000000, 'B');
  if (abs >= 1000000) return withSuffix(abs / 1000000, 'M');
  if (abs >= 1000) return withSuffix(abs / 1000, 'K');
  return _formatCardAmount(v);
}

class _AmountLabel extends StatelessWidget {
  final double amount;
  final TextStyle style;
  final TextAlign? textAlign;

  const _AmountLabel({required this.amount, required this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    final display = _formatCardAmountShort(amount);
    final isAbbreviated = amount.abs() >= 1000;

    final text = Text(
      display,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );

    if (!isAbbreviated) return text;

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Full amount: ${_formatCardAmount(amount)}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      ),
      child: text,
    );
  }
}

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

enum _KanbanGroupBy { status, client }

class _GroupByToggleButton extends StatelessWidget {
  final _KanbanGroupBy selected;
  final ValueChanged<_KanbanGroupBy> onChanged;

  const _GroupByToggleButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<_KanbanGroupBy>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Group by',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => _KanbanGroupBy.values.map((mode) {
        final isSelected = mode == selected;
        final label = mode == _KanbanGroupBy.status ? 'Status' : 'Client';
        final icon = mode == _KanbanGroupBy.status ? Icons.flag_rounded : Icons.groups_rounded;
        return PopupMenuItem<_KanbanGroupBy>(
          value: mode,
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
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
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected == _KanbanGroupBy.status ? Icons.flag_rounded : Icons.groups_rounded,
              size: 15,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
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

  final String? logoPath;

  final VoidCallback onSetClientColor;

  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;

  final Color? clientColor;

  final String docTypeLabel;

  final String businessName;
  final String createdLabel;
  final int itemCount;
  final double totalAmount;

  final bool statusHidden;

  // FOLDER-GROUPING PASS: only populated for Expense entries (see
  // expenseDocEntries in build() below and _clientGroupKey in
  // doc_kanban.dart). Lets the client-grouped Kanban board group a
  // folder-assigned expense into that folder's column instead of always
  // grouping by vendor. Invoice/Quote/Receipt entries leave this null --
  // their own client-column grouping is unaffected by this pass.
  final String? folderName;

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
    required this.onSetClientColor,
    this.logoOffset = Offset.zero,
    this.logoScale = 1.0,
    this.logoShape = LogoShape.roundedSquare,
    this.clientColor,
    required this.docTypeLabel,
    required this.businessName,
    required this.createdLabel,
    required this.itemCount,
    required this.totalAmount,
    this.statusHidden = false,
    this.folderName,
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
  _KanbanGroupBy   _kanbanGroupBy         = _KanbanGroupBy.status;
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
                // BOTTOM SAFE-AREA FIX (this pass): was a fixed
                // EdgeInsets.fromLTRB(20, 12, 20, 24) -- on devices with an
                // on-screen Android nav bar, the fixed 24px wasn't enough
                // to clear it, so "Remove from Folder"/"Apply" sat
                // partially behind the nav bar. Now adds
                // MediaQuery.of(context).padding.bottom on top of the
                // fixed 24px, same fix applied to the Filters sheet in
                // document_filter_bar.dart. The Padding above (viewInsets.
                // bottom) is unchanged -- that handles the keyboard when
                // the folder-name TextField is focused; this handles the
                // nav bar; both are needed together.
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
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

  // Opens the "Create Folder" sheet from a Kanban client column
  // (_DocKanbanBoardByClient's onConvertToFolder, see doc_kanban.dart).
  // Distinct from _openFolderSheet above: that one moves an existing
  // selection into a folder (or clears it) via key strings pulled from
  // _selectedKeys; this one starts from a specific column's full
  // _DocEntry list, pre-checks every document, and lets the user
  // deselect individual documents before confirming. Folders aren't a
  // separate stored entity in this app -- they're just the shared
  // folderName string already living on each document -- so "creating"
  // one here means the same thing _openFolderSheet's applyFolder already
  // does: writing folderName onto the chosen documents via each type's
  // provider. Once at least one document carries that name,
  // collectFolderNames() picks it up automatically and it shows up
  // everywhere folders are listed (FoldersGridView, the folder filter
  // chip, etc.) -- no separate folder-creation call needed.
  //
  // EXPENSES PASS (this update): entries passed in here can now include
  // 'expense:<id>' keys (see the client-grouped board's entries list in
  // build() below, which folds expenseDocEntries into allDocEntries).
  // Added the matching case so converting a client column that contains
  // expenses actually writes folderName onto those expenses too, via
  // ExpenseProvider.updateExpensesFolder -- the same call
  // expense_screen.dart's own "Move to Folder" sheet already uses.
  // Without this case, expenses in the column would silently no-op (hit
  // `if (sepIndex == -1) continue`? no -- they'd fall through the switch
  // with no matching case and never get the folder applied at all).
  void _openConvertToFolderSheet(String suggestedName, List<_DocEntry> entries) {
    if (entries.isEmpty) return;

    final nameController = TextEditingController(text: suggestedName);
    final Set<String> includedKeys = entries.map((e) => e.key).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cs = Theme.of(context).colorScheme;

            void confirm() {
              final folderName = nameController.text.trim();
              if (folderName.isEmpty || includedKeys.isEmpty) return;

              final invoiceProvider = context.read<InvoiceProvider>();
              final quoteProvider   = context.read<QuoteProvider>();
              final receiptProvider = context.read<ReceiptProvider>();
              final expenseProvider = context.read<ExpenseProvider>();

              for (final entry in entries) {
                if (!includedKeys.contains(entry.key)) continue;
                final sepIndex = entry.key.indexOf(':');
                if (sepIndex == -1) continue;
                final type = entry.key.substring(0, sepIndex);
                final id = entry.key.substring(sepIndex + 1);
                switch (type) {
                  case 'invoice':
                    invoiceProvider.updateInvoiceFolder(id, folderName);
                    break;
                  case 'quote':
                    quoteProvider.updateQuoteFolder(id, folderName);
                    break;
                  case 'receipt':
                    receiptProvider.updateReceiptFolder(id, folderName);
                    break;
                  case 'expense':
                    expenseProvider.updateExpensesFolder([id], folderName);
                    break;
                }
              }

              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Created folder "$folderName" with ${includedKeys.length} document${includedKeys.length == 1 ? '' : 's'}',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            final canConfirm = nameController.text.trim().isNotEmpty && includedKeys.isNotEmpty;

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
                          child: Icon(Icons.create_new_folder_outlined, size: 18, color: cs.primary),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Create Folder',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Folder Name',
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
                        autofocus: suggestedName.isEmpty,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          hintText: 'e.g. Client Name, 2026 Projects',
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Text(
                          'Documents (${includedKeys.length}/${entries.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withValues(alpha: 0.55),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setSheetState(() {
                            if (includedKeys.length == entries.length) {
                              includedKeys.clear();
                            } else {
                              includedKeys
                                ..clear()
                                ..addAll(entries.map((e) => e.key));
                            }
                          }),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(includedKeys.length == entries.length ? 'Deselect all' : 'Select all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final checked = includedKeys.contains(entry.key);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) => setSheetState(() {
                              if (v == true) {
                                includedKeys.add(entry.key);
                              } else {
                                includedKeys.remove(entry.key);
                              }
                            }),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              entry.title,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              entry.docTypeLabel,
                              style: TextStyle(fontSize: 11, color: entry.accentColor, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canConfirm ? confirm : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Create Folder'),
                      ),
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
      statusOptions: [
        ...PaymentStatus.values.map((s) {
          final info = _paymentStatusInfo(s);
          return StatusOption(
            label: info.label,
            color: info.color,
            selected: !inv.data.statusHidden && inv.data.paymentStatus == s,
            onSelect: () {
              Navigator.pop(context);
              provider.updateSavedInvoiceStatus(inv.id, s);
            },
          );
        }),
        StatusOption(
          label: 'None',
          color: Colors.grey,
          selected: inv.data.statusHidden,
          onSelect: () {
            Navigator.pop(context);
            provider.updateSavedInvoiceStatusHidden(inv.id, true);
          },
        ),
      ],
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

  void _showClientColorSheet(String businessName) {
    final prefs = context.read<ClientColorPrefs>();
    showClientColorPicker(
      context,
      clientName: businessName,
      currentColor: prefs.colorFor(businessName),
      onColorSelected: (color) => prefs.setColorFor(businessName, color),
      onCleared: () => prefs.clearColorFor(businessName),
    );
  }

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
    required List<ExpenseEntry> allExpenses,
    required CategoryProvider categories,
  }) {
    if (_selectedKeys.isEmpty) return;

    final selectedInvoiceIds = <String>{};
    final selectedQuoteIds = <String>{};
    final selectedReceiptIds = <String>{};
    final selectedExpenseIds = <String>{};
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
        case 'expense':
          selectedExpenseIds.add(id);
          break;
      }
    }

    final selectedInvoices =
        allInvoices.where((i) => selectedInvoiceIds.contains(i.id)).toList();
    final selectedQuotes =
        allQuotes.where((q) => selectedQuoteIds.contains(q.id)).toList();
    final selectedReceipts =
        allReceipts.where((r) => selectedReceiptIds.contains(r.id)).toList();
    // EXPENSES PASS: mixed-selection export previously dropped expenses
    // silently -- this switch had no 'expense' case at all, and neither
    // handleExport() call below passed expenses/categoryNameOf through to
    // BulkDocumentExportService even though that service has supported
    // them since the earlier expenses-in-export pass. Selecting expense
    // cards (via the expense list/grid -- selection state is layout-
    // independent) and hitting Export as CSV produced a file with the
    // expense rows simply missing, which is exactly the accounting-
    // accuracy gap this whole feature is meant to close.
    final selectedExpenses =
        allExpenses.where((e) => selectedExpenseIds.contains(e.id)).toList();

    final defaultName =
        'Documents_Export_${DateFormat('d_MMM_yyyy').format(DateTime.now())}';
    final nameController = TextEditingController(text: defaultName);
    final totalCount = selectedInvoices.length +
        selectedQuotes.length +
        selectedReceipts.length +
        selectedExpenses.length;

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
                    expenses: selectedExpenses,
                    categoryNameOf: (id) => categories.byId(id).name,
                  );
                } else {
                  savedPath = await _exportService.exportToDownloads(
                    fileName: nameController.text,
                    invoices: selectedInvoices,
                    quotes: selectedQuotes,
                    receipts: selectedReceipts,
                    expenses: selectedExpenses,
                    categoryNameOf: (id) => categories.byId(id).name,
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
        final clientColorPrefs = context.watch<ClientColorPrefs>();

        final layoutPrefs = context.watch<SavedLayoutPrefs>();
        final DocLayoutMode effectiveLayout = _selectedLayout == DocLayoutMode.kanban
            ? DocLayoutMode.kanban
            : _fromShared(layoutPrefs.layout);

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
        final paidCount     = countPaid(allInvoices);
        final acceptedCount = countAccepted(allQuotes);
        final declinedCount = countDeclined(allQuotes);
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
                  onSetClientColor: () => _showClientColorSheet(inv.data.businessName),
                  logoPath: inv.data.businessLogoPath,
                  logoOffset: Offset(inv.data.businessLogoOffsetDx, inv.data.businessLogoOffsetDy),
                  logoScale: inv.data.businessLogoScale,
                  logoShape: logoShapeFromString(inv.data.businessLogoShape),
                  clientColor: clientColorPrefs.colorFor(inv.data.businessName),
                  docTypeLabel: 'Invoice',
                  businessName: inv.data.businessName,
                  createdLabel: _formatShortDate(inv.createdAt),
                  itemCount: inv.data.lineItems.length,
                  totalAmount: inv.data.grandTotal,
                  statusHidden: inv.data.statusHidden,
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
                  onSetClientColor: () => _showClientColorSheet(q.data.businessName),
                  logoPath: q.data.businessLogoPath,
                  logoOffset: Offset(q.data.businessLogoOffsetDx, q.data.businessLogoOffsetDy),
                  logoScale: q.data.businessLogoScale,
                  logoShape: logoShapeFromString(q.data.businessLogoShape),
                  clientColor: clientColorPrefs.colorFor(q.data.businessName),
                  docTypeLabel: 'Quote',
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
                  onSetClientColor: () => _showClientColorSheet(r.data.businessName),
                  logoPath: r.data.businessLogoPath,
                  logoOffset: Offset(r.data.businessLogoOffsetDx, r.data.businessLogoOffsetDy),
                  logoScale: r.data.businessLogoScale,
                  logoShape: logoShapeFromString(r.data.businessLogoShape),
                  clientColor: clientColorPrefs.colorFor(r.data.businessName),
                  docTypeLabel: 'Receipt',
                  businessName: r.data.businessName,
                  createdLabel: _formatShortDate(r.createdAt),
                  itemCount: r.data.lineItems.length,
                  totalAmount: r.data.amountPaid,
                ))
            .toList();

        final expenseDocEntries = filteredExpenses
            .map((e) => _DocEntry(
                  key: 'expense:${e.id}',
                  title: e.vendor.trim().isEmpty ? '(No vendor)' : e.vendor,
                  subtitle: categories.byId(e.categoryId).name,
                  date: _formatShortDate(e.date),
                  secondaryDateLabel: 'Date',
                  secondaryDateValue: _formatShortDate(e.date),
                  percent: 0,
                  accentColor: kExpenseAccent,
                  statusLabel: categories.byId(e.categoryId).name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: e.id)),
                  ),
                  onShowMenu: () => _showExpenseMenu(e),
                  isPositiveStatus: false,
                  onSetClientColor: () => _showClientColorSheet(e.vendor),
                  logoPath: e.logoPath,
                  logoOffset: Offset(e.logoOffsetDx, e.logoOffsetDy),
                  logoScale: e.logoScale,
                  logoShape: logoShapeFromString(e.logoShape),
                  clientColor: clientColorPrefs.colorFor(e.vendor),
                  docTypeLabel: 'Expense',
                  businessName: e.vendor,
                  createdLabel: _formatShortDate(e.createdAt),
                  itemCount: 0,
                  totalAmount: -e.amount,
                  folderName: e.folderName,
                ))
            .toList();

        final allDocEntries = [...invoiceEntries, ...quoteEntries, ...receiptEntries, ...expenseDocEntries];

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

        void handleLayoutChange(DocLayoutMode m) {
          final shared = _toShared(m);
          if (shared != null) {
            context.read<SavedLayoutPrefs>().setLayout(shared);
            if (_selectedLayout == DocLayoutMode.kanban) {
              setState(() => _selectedLayout = DocLayoutMode.list);
            }
          } else {
            setState(() => _selectedLayout = DocLayoutMode.kanban);
          }
        }

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
                                  allExpenses: allExpenses,
                                  categories: categories,
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
                paidCount: paidCount,
                acceptedCount: acceptedCount,
                declinedCount: declinedCount,
              ),
            const SizedBox(height: 16),

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
                              if (effectiveLayout == DocLayoutMode.kanban &&
                                  _kanbanGroupBy == _KanbanGroupBy.client &&
                                  allDocEntries.isNotEmpty) ...[
                                SectionHeader(
                                  label: 'All Documents',
                                  count: allDocEntries.length,
                                  accentColor: cs.primary,
                                  layoutToggle: _LayoutToggleButton(
                                    selected: effectiveLayout,
                                    onChanged: handleLayoutChange,
                                  ),
                                  groupByToggle: _GroupByToggleButton(
                                    selected: _kanbanGroupBy,
                                    onChanged: (g) => setState(() => _kanbanGroupBy = g),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _DocKanbanBoardByClient(
                                  entries: allDocEntries,
                                  onConvertToFolder: _openConvertToFolderSheet,
                                ),
                                const SizedBox(height: 20),
                              ] else ...[
                              if (invoiceEntries.isNotEmpty) ...[
                                SectionHeader(
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
                                          selected: effectiveLayout,
                                          onChanged: handleLayoutChange,
                                        )
                                      : null,
                                  groupByToggle: (showToggleOnInvoices && effectiveLayout == DocLayoutMode.kanban)
                                      ? _GroupByToggleButton(
                                          selected: _kanbanGroupBy,
                                          onChanged: (g) => setState(() => _kanbanGroupBy = g),
                                        )
                                      : null,
                                  displayOptionsToggle: showToggleOnInvoices
                                      ? const DisplayOptionsButton()
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                _buildEntries(invoiceEntries, effectiveLayout),
                                const SizedBox(height: 20),
                              ],
                              if (quoteEntries.isNotEmpty) ...[
                                SectionHeader(
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
                                          selected: effectiveLayout,
                                          onChanged: handleLayoutChange,
                                        )
                                      : null,
                                  groupByToggle: (showToggleOnQuotes && effectiveLayout == DocLayoutMode.kanban)
                                      ? _GroupByToggleButton(
                                          selected: _kanbanGroupBy,
                                          onChanged: (g) => setState(() => _kanbanGroupBy = g),
                                        )
                                      : null,
                                  displayOptionsToggle: showToggleOnQuotes
                                      ? const DisplayOptionsButton()
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                _buildEntries(quoteEntries, effectiveLayout),
                                const SizedBox(height: 20),
                              ],
                              if (receiptEntries.isNotEmpty) ...[
                                SectionHeader(
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
                                          selected: effectiveLayout,
                                          onChanged: handleLayoutChange,
                                        )
                                      : null,
                                  groupByToggle: (showToggleOnReceipts && effectiveLayout == DocLayoutMode.kanban)
                                      ? _GroupByToggleButton(
                                          selected: _kanbanGroupBy,
                                          onChanged: (g) => setState(() => _kanbanGroupBy = g),
                                        )
                                      : null,
                                  displayOptionsToggle: showToggleOnReceipts
                                      ? const DisplayOptionsButton()
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                _buildEntries(receiptEntries, effectiveLayout),
                                if (expenseEntries.isNotEmpty) const SizedBox(height: 20),
                              ],
                              ],
                              // FOLDER-GROUPING PASS: suppressed while the
                              // client-grouped Kanban board is showing --
                              // expenses are already rendered inside their
                              // client/folder column above (see
                              // allDocEntries / _DocKanbanBoardByClient),
                              // so this block used to duplicate them into
                              // a second, separate "My Expenses" section
                              // underneath the whole board instead of
                              // nesting a folder-assigned expense inside
                              // its actual folder's column.
                              if (expenseEntries.isNotEmpty &&
                                  !(effectiveLayout == DocLayoutMode.kanban &&
                                      _kanbanGroupBy == _KanbanGroupBy.client)) ...[
                                SectionHeader(
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
                                          selected: effectiveLayout,
                                          onChanged: handleLayoutChange,
                                        )
                                      : null,
                                  displayOptionsToggle: showToggleOnExpenses
                                      ? const DisplayOptionsButton()
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                _buildExpenseEntries(expenseEntries, effectiveLayout),
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

  Widget _buildEntries(List<_DocEntry> entries, DocLayoutMode layout) {
    switch (layout) {
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

  Widget _buildExpenseEntries(List<ExpenseCardEntry> entries, DocLayoutMode layout) {
    switch (layout) {
      case DocLayoutMode.list:
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
      case DocLayoutMode.kanban:
        return ExpenseKanbanBoard(entries: entries);
    }
  }
}