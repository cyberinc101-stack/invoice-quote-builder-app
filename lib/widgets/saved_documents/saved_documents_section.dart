// saved_documents_section.dart
// lib/widgets/saved_documents/saved_documents_section.dart
//
// Entry point for the saved-documents section. This file owns the
// SavedDocumentsSection widget + its State: filtering, selection mode,
// bulk delete/export, the per-document 3-dot menu wiring (status radios,
// rename, move-to-folder, delete), and the top-level build()/_buildEntries()
// that picks which card layout to render.
//
// NEW (this pass): tapping the Folders quick-chip in DocumentFilterBar no
// longer navigates to a separate FoldersOverviewScreen — it now flips
// _browsingFolders to true, which swaps the filter bar for a small "←
// Folders" header and swaps the document list for FoldersGridView
// (lib/widgets/folders_grid_view.dart), all inline on this same screen.
// Tapping a folder tile sets _selectedFolder and flips _browsingFolders
// back to false in one go, landing on the normal filtered document view
// with the existing "Folder: X ✕" banner. This mirrors how selectionMode
// already swaps out the filter bar for its own toolbar — browsingFolders,
// selectionMode, and the normal filter bar are three mutually exclusive
// states for the top control row.
//
// NEW (earlier pass): SavedDocumentsSection accepts an optional
// `initialFolder` — seeded into _selectedFolder in initState() — so callers
// (e.g. FoldersOverviewScreen's standalone entry point) can push straight
// into this widget already filtered to one folder. When _selectedFolder is
// set, a small "Folder: X ✕" banner renders above the filter bar /
// selection toolbar, with the ✕ clearing the filter via setState.
//
// FIX (earlier pass): _DocCompactGridCard's GridView delegate had
// mainAxisExtent: 124, which clipped the last ~8px of its Column (the
// Due/Paid/Expires row) — bumped to 134. Only the compact-grid layout uses
// this delegate, so the other three card layouts are unaffected.
//
// NEW (earlier pass): one-time SnackBar hint telling users that long-pressing
// a document enters selection mode, which is how they discover the
// "Move to Folder" action. Shown once ever, gated behind a SharedPreferences
// flag (_kFolderHintShownKey) so it doesn't nag on every visit. Fires from
// initState() via a post-frame callback so ScaffoldMessenger.of(context) is
// safe to call (the widget tree is fully laid out by then).
//
// FIX (earlier pass): _DocEntry now carries secondaryDateLabel/secondaryDateValue
// — the type-relevant date (Due for invoices, or Paid once an invoice is
// marked paid; Expires for quotes; Paid for receipts) — alongside the
// existing `date` field (last edited, relative). Card widgets in
// doc_cards.dart display both. Added a local _formatShortDate() helper for
// rendering InvoiceData.paidDate (a real DateTime) the same way the other
// date fields (plain Strings the user typed) already read.
//
// FIX (earlier pass, cont'd): _openExportSheet's handleExport() used `context`
// after an `await` guarded only by `this.mounted` (the State's own
// lifecycle), but the context actually used post-await is `sheetContext`
// (the bottom sheet's own, narrower-lived context, captured before the
// async gap). The State being mounted doesn't guarantee the sheet is still
// on screen — it can be dismissed independently. Both the success path and
// the catch block now also check `sheetContext.mounted` before touching
// anything tied to the sheet.
//
// Split out of the original single-file saved_documents_section.dart into
// this folder using Dart `part`/`part of` directives, so all the
// underscore-prefixed private classes (_DocCard, _DocEntry, etc.) keep
// working across files exactly as before — same library, just organized
// into smaller files:
//   - doc_layout_mode.dart   → DocLayoutMode enum + _LayoutToggleButton
//   - doc_card_shared.dart   → _SectionHeader, _SelectionBadge, _ThreeDotIcon, _positiveDot()
//   - doc_cards.dart         → _DocCard, _DocGridCard, _DocCompactGridCard, _DocCompactRow
//   - doc_kanban.dart        → _DocKanbanBoard, _DocKanbanColumn, _DocKanbanCard
//
// NOTE ON IMPORT PATHS: this file now lives one directory deeper than the
// original (lib/widgets/ -> lib/widgets/saved_documents/), so relative
// imports that used to be `../providers/...` are now `../../providers/...`,
// and former same-folder imports like `document_filter_bar.dart` are now
// `../document_filter_bar.dart`. Double check these against your actual
// folder layout before building.

library saved_documents_section;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../models/invoice_data.dart';
import '../../models/quote_data.dart';
import '../../models/receipt_data.dart';
import '../../filters/filter_types.dart';
import '../../filters/filter_logic.dart';
import '../../export/bulk_document_export_service.dart';
import '../../screens/saved_invoice_details_section/saved_document_detail_screen.dart';
import '../document_filter_bar.dart';
import '../document_status_menu.dart';
import '../folders_grid_view.dart';

part 'doc_layout_mode.dart';
part 'doc_card_shared.dart';
part 'doc_cards.dart';
part 'doc_kanban.dart';

// -----------------------------------------------------------------------------
// Status → (label, color) mappings. Kept local/private to this library (same
// pattern already used in saved_documents_containers.dart and
// saved_document_detail_screen.dart) so the 3-dot menu's radio options and
// the green-dot logic don't need a cross-file dependency.
// -----------------------------------------------------------------------------

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

// NEW: formats a real DateTime (currently only InvoiceData.paidDate) the
// same way the rest of this library's plain-String date fields read —
// e.g. "6 Aug 2026". Kept local since doc_cards.dart (a `part of` this
// library) needs it too.
String _formatShortDate(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

// -----------------------------------------------------------------------------
// _DocEntry — carries `key`, used for selection state and to dispatch
// deletion/folder-assignment to the right provider ("invoice:<id>" /
// "quote:<id>" / "receipt:<id>"). onShowMenu opens the 3-dot sheet for that
// one document; isPositiveStatus drives the green dot.
//
// secondaryDateLabel/secondaryDateValue carry the type-relevant date shown
// alongside `date` (last edited): Due (or Paid, once marked paid) for
// invoices, Expires for quotes, Paid for receipts.
// -----------------------------------------------------------------------------

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
  });
}

// -----------------------------------------------------------------------------
// SavedDocumentsSection
// -----------------------------------------------------------------------------

class SavedDocumentsSection extends StatefulWidget {
  /// When set, seeds _selectedFolder in initState so this section opens
  /// already filtered to one folder (used by FoldersOverviewScreen's
  /// standalone entry point). Leave null for the normal, unfiltered entry
  /// point (e.g. from home_screen.dart).
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

  // ── Folder browsing (inline) ────────────────────────────────────────
  //
  // NEW: when true, the filter bar and document list are swapped out for
  // a "← Folders" header + FoldersGridView, right here on this same
  // screen. Picking a tile sets _selectedFolder and flips this back to
  // false in one setState call. Mutually exclusive with _selectionMode —
  // entering one doesn't need to explicitly clear the other since neither
  // UI affordance to enter one is visible while the other is active.
  bool _browsingFolders = false;

  // ── Selection mode ──────────────────────────────────────────────────
  bool _selectionMode = false;
  final Set<String> _selectedKeys = {};

  // ── Export ───────────────────────────────────────────────────────────
  final BulkDocumentExportService _exportService = BulkDocumentExportService();
  bool _exporting = false;

  // ── One-time "long-press to select" discovery hint ──────────────────
  //
  // Shown once ever (persisted via SharedPreferences) the first time this
  // section is built, so first-time users learn that long-pressing a
  // document enters selection mode — which is the only way to discover
  // "Move to Folder" and "Export as CSV", since neither is exposed via a
  // visible always-on button.
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

      // Post-frame so the Scaffold/ScaffoldMessenger above this widget is
      // guaranteed to be laid out before we try to show a SnackBar on it.
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
      }
    }

    setState(() {
      _selectionMode = false;
      _selectedKeys.clear();
    });
  }

  // Single-document delete, used by the 3-dot menu. Same confirm-dialog
  // pattern as _confirmDelete() above, but doesn't touch selection state.
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
    }
  }

  // Single-document rename, used by the 3-dot menu. Same dialog pattern
  // used in saved_document_detail_screen.dart, generalized across all
  // three doc types via a `type` string.
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

  // ── Folder flow ──────────────────────────────────────────────────────
  //
  // "Move to Folder" — opens a sheet where the user either taps an existing
  // folder chip or types a new name inline. Both paths call the matching
  // provider's updateXFolder(id, folderName) for every key in `keys`
  // (either the multi-select set, or a single overrideKeys set passed in
  // from the 3-dot menu). Tapping "Remove from Folder" clears it (null).
  //
  // overrideKeys lets the 3-dot menu reuse this same sheet for a single
  // document without entering/clearing multi-select state — only the
  // plain multi-select call (overrideKeys == null) touches
  // _selectionMode/_selectedKeys.

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

  // ── 3-dot menu wiring (per doc type) ────────────────────────────────
  //
  // Each of these opens showDocumentOptionsMenu() with:
  //  - one StatusOption per enum value for that doc type, wired straight to
  //    the matching provider's updateSavedXStatus() (already exists —
  //    powers the tappable status chip on the detail screen too)
  //  - Rename / Move to Folder / Delete wired to the single-document
  //    helpers above.

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

  // ── Export flow ──────────────────────────────────────────────────────
  //
  // Resolves the current selection against the FULL (unfiltered) provider
  // lists — not the filtered view — so a selection made before changing a
  // filter still resolves correctly, then opens the naming sheet.

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

    return Consumer3<InvoiceProvider, QuoteProvider, ReceiptProvider>(
      builder: (context, invoiceProvider, quoteProvider, receiptProvider, _) {
        final allInvoices = invoiceProvider.savedInvoices;
        final allQuotes   = quoteProvider.savedQuotes;
        final allReceipts = receiptProvider.savedReceipts;

        final needsActionCount = countNeedsAction(invoices: allInvoices, quotes: allQuotes);
        final overdueCount     = countOverdue(allInvoices);
        final draftsCount      = countDrafts(
          invoices: allInvoices,
          quotes:   allQuotes,
          receipts: allReceipts,
        );
        final allFolderNames = collectFolderNames(
          invoices: allInvoices,
          quotes:   allQuotes,
          receipts: allReceipts,
        );

        var filteredInvoices = allInvoices;
        var filteredQuotes   = allQuotes;
        var filteredReceipts = allReceipts;

        if (_selectedType == DocTypeFilter.invoices) {
          filteredQuotes   = const [];
          filteredReceipts = const [];
        } else if (_selectedType == DocTypeFilter.quotes) {
          filteredInvoices = const [];
          filteredReceipts = const [];
        } else if (_selectedType == DocTypeFilter.receipts) {
          filteredInvoices = const [];
          filteredQuotes   = const [];
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

        filteredInvoices = filterInvoicesByDateRange(filteredInvoices, _selectedDateRange,
            customStart: _customRangeStart, customEnd: _customRangeEnd);
        filteredQuotes   = filterQuotesByDateRange(filteredQuotes, _selectedDateRange,
            customStart: _customRangeStart, customEnd: _customRangeEnd);
        filteredReceipts = filterReceiptsByDateRange(filteredReceipts, _selectedDateRange,
            customStart: _customRangeStart, customEnd: _customRangeEnd);

        filteredInvoices = filterInvoicesByAmountRange(filteredInvoices, _minAmount, _maxAmount);
        filteredQuotes   = filterQuotesByAmountRange(filteredQuotes, _minAmount, _maxAmount);
        filteredReceipts = filterReceiptsByAmountRange(filteredReceipts, _minAmount, _maxAmount);

        filteredInvoices = filterInvoicesByFolder(filteredInvoices, _selectedFolder);
        filteredQuotes   = filterQuotesByFolder(filteredQuotes, _selectedFolder);
        filteredReceipts = filterReceiptsByFolder(filteredReceipts, _selectedFolder);

        filteredInvoices = sortInvoices(filteredInvoices, _selectedSort);
        filteredQuotes   = sortQuotes(filteredQuotes, _selectedSort);
        filteredReceipts = sortReceipts(filteredReceipts, _selectedSort);

        final hasResults = filteredInvoices.isNotEmpty ||
            filteredQuotes.isNotEmpty ||
            filteredReceipts.isNotEmpty;

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
                ))
            .toList();

        final showToggleOnInvoices = invoiceEntries.isNotEmpty;
        final showToggleOnQuotes   = !showToggleOnInvoices && quoteEntries.isNotEmpty;
        final showToggleOnReceipts = !showToggleOnInvoices && !showToggleOnQuotes && receiptEntries.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Folder: X ✕" banner — shown whenever _selectedFolder is set
            // (either via the Filters sheet's dropdown, via
            // widget.initialFolder, or via picking a tile while browsing
            // folders below). Tapping ✕ just clears the filter; it doesn't
            // navigate back. Suppressed while _browsingFolders is true —
            // the two shouldn't ever be true at once in practice (picking
            // a tile clears _browsingFolders in the same setState that
            // sets this), but the guard keeps the header from doubling up
            // if that ever changes.
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

            // ── Top control row: selection toolbar, folder-browsing
            // header, or the normal filter bar — mutually exclusive.
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
            else if (_browsingFolders)
              // NEW: replaces the filter bar while browsing folders inline.
              // Back arrow just flips _browsingFolders back off — it
              // doesn't touch any other filter state, so returning lands
              // exactly where the user left the document list.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _browsingFolders = false),
                      child: Icon(Icons.arrow_back_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Folders',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface),
                    ),
                  ],
                ),
              )
            else
              DocumentFilterBar(
                selectedType: _selectedType,
                onTypeChanged: (t) => setState(() {
                  _selectedType          = t;
                  _selectedPaymentStatus = null;
                  _selectedQuoteStatus   = null;
                  _selectedReceiptStatus = null;
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
                invoiceCount: allInvoices.length,
                quoteCount:   allQuotes.length,
                receiptCount: allReceipts.length,
                selectedQuickFilter: _selectedQuickFilter,
                onQuickFilterChanged: (f) => setState(() => _selectedQuickFilter = f),
                searchQuery: _searchQuery,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
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
                // NEW: shows the folder grid inline instead of navigating.
                onFoldersChipTap: () => setState(() => _browsingFolders = true),
                needsActionCount: needsActionCount,
                overdueCount: overdueCount,
                draftsCount: draftsCount,
                overdue1to30Count: countAgingBucket(allInvoices, QuickFilter.overdue1to30),
                overdue31to60Count: countAgingBucket(allInvoices, QuickFilter.overdue31to60),
                overdue61plusCount: countAgingBucket(allInvoices, QuickFilter.overdue61plus),
              ),
            const SizedBox(height: 16),

            // ── Content area: folder grid, "no results", or document list.
            if (_browsingFolders)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FoldersGridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  onFolderTap: (name) => setState(() {
                    _selectedFolder   = name;
                    _browsingFolders  = false;
                  }),
                ),
              )
            else if (!hasResults)
              Padding(
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
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (invoiceEntries.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'My Invoices',
                        count: invoiceEntries.length,
                        accentColor: const Color(0xFF1565C0),
                        layoutToggle: showToggleOnInvoices
                            ? _LayoutToggleButton(
                                selected: _selectedLayout,
                                onChanged: (m) => setState(() => _selectedLayout = m),
                              )
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
                        layoutToggle: showToggleOnQuotes
                            ? _LayoutToggleButton(
                                selected: _selectedLayout,
                                onChanged: (m) => setState(() => _selectedLayout = m),
                              )
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
                        layoutToggle: showToggleOnReceipts
                            ? _LayoutToggleButton(
                                selected: _selectedLayout,
                                onChanged: (m) => setState(() => _selectedLayout = m),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _buildEntries(receiptEntries),
                    ],
                  ],
                ),
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
            mainAxisExtent: 178,
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
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 134,
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
}