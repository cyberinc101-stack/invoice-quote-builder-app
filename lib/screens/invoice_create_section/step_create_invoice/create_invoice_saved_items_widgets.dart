// lib/screens/invoice_create_section/step_create_invoice/create_invoice_saved_items_widgets.dart
//
// LAYOUT PARITY PASS (this update): restructured to actually mirror
// StepCustomers'/StepTemplates' visual rhythm instead of being a single
// compact block. Now, top to bottom:
//   1. Header row — bookmark icon + "Saved Item Sets" title + N/100 count.
//   2. Info banner (purple, matches Customers' green / Templates' blue
//      banner treatment) explaining what this does.
//   3. "Save Current Items" button — same big bordered pill styling as
//      Customers' "Add New Customer" / Templates' "Add New Template".
//   4. Saved-library header — "Saved Sets" label + count badge + a
//      Hide/Show toggle, exactly like Customers'/Templates' "Saved
//      Customers"/"Saved Templates" sub-header, plus the same
//      "Tap a card to..." helper line.
//   5. Cards, newest first.
// Behavior is unchanged from the previous pass: tapping a card performs
// an immediate one-shot ADD (appending fresh copies of that set's items
// onto the current line items) rather than a persistent select/deselect
// toggle, since a line item bundle isn't "the one linked to this
// invoice" the way a customer or template is. Edit is rename-only. Save
// Current Items always snapshots whatever's on screen right now.
//
// Persistence is unchanged: a single JSON-encoded list under one
// SharedPreferences key, capped at _kMaxLineItemSets (100), the same
// N/max-counter + atMax-disable pattern step_customers.dart/
// step_templates.dart use.
//
// This widget doesn't own the current invoice's line items -- it asks
// the parent (StepCreateInvoice) for a live snapshot via
// getCurrentItems() when "Save Current Items" is tapped, and hands
// fresh item copies back via onQuickAdd() when a saved card is tapped.
// StepCreateInvoice owns applying those into its own
// _items/_descCtrl/_qtyCtrl/_priceCtrl lists — see
// step_create_invoice.dart's own LINE ITEM CONTAINERS PASS note.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../models/invoice_models.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kMaxLineItemSets = 100;
const _kPrefLineItemSetList = 'invoice_line_item_set_list';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------
Future<void> _persistLineItemSets(List<SavedLineItemSet> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefLineItemSetList,
    jsonEncode(list.map((s) => s.toJson()).toList()),
  );
}

Future<List<SavedLineItemSet>> _loadLineItemSets() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefLineItemSetList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => SavedLineItemSet.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// CreateInvoiceSavedItemSets
// =============================================================================

class CreateInvoiceSavedItemSets extends StatefulWidget {
  /// Called when "Save Current Items" is tapped, to get a live, already
  /// flushed snapshot of whatever's currently in Line Items on the parent
  /// step. If the snapshot is empty or entirely blank items, the save is
  /// blocked with a snackbar instead of persisting an empty set.
  final List<InvoiceItem> Function() getCurrentItems;

  /// Called when a saved card is tapped, with fresh copies of that set's
  /// items -- the parent is responsible for actually appending them
  /// (with their own controllers) onto its live Line Items list.
  final void Function(List<InvoiceItem> items) onQuickAdd;

  /// Live currency prefix from the parent (e.g. '\$', 'USD ') so saved
  /// cards can preview each set's total in the same format Line Items/
  /// Totals already use on this step.
  final String currencySymbol;

  const CreateInvoiceSavedItemSets({
    super.key,
    required this.getCurrentItems,
    required this.onQuickAdd,
    required this.currencySymbol,
  });

  @override
  State<CreateInvoiceSavedItemSets> createState() =>
      _CreateInvoiceSavedItemSetsState();
}

class _CreateInvoiceSavedItemSetsState
    extends State<CreateInvoiceSavedItemSets> {
  bool _loading = true;
  List<SavedLineItemSet> _library = [];
  bool _showLibraryPanel = true;

  // Purple accent -- distinct from Saved Customers' green and Saved
  // Templates' blue (and from this step's own blue), so the panel reads
  // as its own distinct library at a glance.
  static const _accent = Color(0xFF7B1FA2);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sets = await _loadLineItemSets();
    if (!mounted) return;
    setState(() {
      _library = sets;
      _loading = false;
    });
  }

  void _showSaveSheet() {
    final snapshot = widget.getCurrentItems();
    final hasContent = snapshot
        .any((i) => i.description.trim().isNotEmpty || i.unitPrice != 0);
    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item before saving a set.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_library.length >= _kMaxLineItemSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Maximum of $_kMaxLineItemSets saved item sets reached.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SaveItemsSheet(
        items: snapshot,
        currencySymbol: widget.currencySymbol,
        accent: _accent,
        onSaved: (name) {
          final set = SavedLineItemSet(
            id: const Uuid().v4(),
            name: name,
            items: snapshot.map((i) => i.copyWith()).toList(),
          );
          setState(() {
            _library.add(set);
            _showLibraryPanel = true;
          });
          _persistLineItemSets(_library);
        },
      ),
    );
  }

  void _showRenameSheet(SavedLineItemSet existing, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SaveItemsSheet(
        items: existing.items,
        currencySymbol: widget.currencySymbol,
        accent: _accent,
        existingName: existing.name,
        isRename: true,
        onSaved: (name) {
          setState(() => _library[index] = existing.copyWith(name: name));
          _persistLineItemSets(_library);
        },
      ),
    );
  }

  void _deleteSet(int index) {
    setState(() => _library.removeAt(index));
    _persistLineItemSets(_library);
  }

  void _quickAdd(SavedLineItemSet set) {
    widget.onQuickAdd(set.items.map((i) => i.copyWith()).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${set.itemCount} item${set.itemCount == 1 ? '' : 's'} from "${set.name}".',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atMax = _library.length >= _kMaxLineItemSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row (mirrors StepCustomers'/StepTemplates' page
        // title row, condensed for embedding inline on this step) ─────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.bookmark_rounded, size: 16, color: _accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Saved Item Sets',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent),
                ),
              )
            else
              Text(
                '${_library.length}/$_kMaxLineItemSets',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: atMax
                      ? const Color(0xFFEF5350)
                      : colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Info banner (matches Customers' green / Templates' blue
        // banner treatment) ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A0D33) : const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? _accent.withValues(alpha: 0.4)
                  : const Color(0xFFCE93D8),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Save bundles of line items and quick-add them to any invoice. Save up to $_kMaxLineItemSets sets.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFFCE93D8)
                        : const Color(0xFF7B1FA2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Save Current Items button (styled like Customers'
        // "Add New Customer" / Templates' "Add New Template") ──────────
        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Maximum of $_kMaxLineItemSets saved item sets reached.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  )
              : _showSaveSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: atMax
                  ? (isDark
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFF5F5F5))
                  : (isDark
                      ? const Color(0xFF2A0D33)
                      : const Color(0xFFF3E5F5)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: atMax
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : (isDark
                        ? _accent.withValues(alpha: 0.5)
                        : const Color(0xFFCE93D8)),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_add_rounded,
                  color: atMax
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : _accent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    atMax ? 'Maximum Item Sets Reached' : 'Save Current Items',
                    style: TextStyle(
                      color: atMax
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : _accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Saved-library header (mirrors "Saved Customers"/"Saved
        // Templates" sub-header exactly: label + count badge + Hide/
        // Show toggle + helper line) ─────────────────────────────────
        if (!_loading && _library.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.list_alt_rounded, size: 16, color: _accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Saved Sets',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_library.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () =>
                    setState(() => _showLibraryPanel = !_showLibraryPanel),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A0D33)
                        : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showLibraryPanel ? 'Hide' : 'Show',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _showLibraryPanel
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: _accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a card to add its items to this invoice.',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],

        // ── Saved cards ───────────────────────────────────────────────
        if (_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _accent),
              ),
            ),
          )
        else if (_showLibraryPanel && _library.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_library.length, (displayIdx) {
            final i = _library.length - 1 - displayIdx; // newest first
            final set = _library[i];
            return _LineItemSetCard(
              set: set,
              currencySymbol: widget.currencySymbol,
              accent: _accent,
              onTap: () => _quickAdd(set),
              onEdit: () => _showRenameSheet(set, i),
              onDelete: () => _deleteSet(i),
            );
          }),
        ],
      ],
    );
  }
}

// =============================================================================
// Line Item Set Card
// =============================================================================

class _LineItemSetCard extends StatelessWidget {
  final SavedLineItemSet set;
  final String currencySymbol;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LineItemSetCard({
    required this.set,
    required this.currencySymbol,
    required this.accent,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = set.items
        .map((i) =>
            i.description.trim().isEmpty ? '(no description)' : i.description.trim())
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.playlist_add_check_rounded,
                    color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.name.isNotEmpty ? set.name : '(Unnamed set)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                accent.withValues(alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${set.itemCount} item${set.itemCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$currencySymbol${set.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? accent.withValues(alpha: 0.12)
                            : const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_rounded, color: accent, size: 15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Color(0xFFEF5350), size: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom Sheet – save current items as a set / rename a saved set
// =============================================================================

class _SaveItemsSheet extends StatefulWidget {
  final List<InvoiceItem> items;
  final String currencySymbol;
  final Color accent;
  final String? existingName;
  final bool isRename;
  final void Function(String name) onSaved;

  const _SaveItemsSheet({
    required this.items,
    required this.currencySymbol,
    required this.accent,
    this.existingName,
    this.isRename = false,
    required this.onSaved,
  });

  @override
  State<_SaveItemsSheet> createState() => _SaveItemsSheetState();
}

class _SaveItemsSheetState extends State<_SaveItemsSheet> {
  late TextEditingController _nameCtrl;
  static const int _nameMax = 100;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingName ?? '');
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onSaved(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = kb + 32 + MediaQuery.of(context).padding.bottom;
    final total = widget.items.fold(0.0, (sum, i) => sum + i.total);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, sc) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.isRename
                                  ? 'Rename Item Set'
                                  : 'Save Item Set',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (widget.isRename)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A0D33)
                                    : const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: widget.accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Editing',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nameCtrl,
                        autofocus: true,
                        style: TextStyle(color: colorScheme.onSurface),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_nameMax),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Set Name *',
                          labelStyle: TextStyle(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6)),
                          hintText: 'e.g. Monthly Retainer Bundle',
                          hintStyle: TextStyle(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.35),
                              fontSize: 13),
                          prefixIcon: Icon(Icons.label_rounded,
                              size: 20,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.45)),
                          filled: true,
                          fillColor: isDark
                              ? colorScheme.surfaceContainerHighest
                              : const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.outline)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.outline)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: widget.accent, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 2),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_nameCtrl.text.length} / $_nameMax',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: widget.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Items in this set',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5)
                              : const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            for (final item in widget.items)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.description.trim().isEmpty
                                            ? '(no description)'
                                            : item.description.trim(),
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme.onSurface),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} × ${widget.currencySymbol}${item.unitPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface)),
                                Text(
                                  '${widget.currencySymbol}${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: widget.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _nameCtrl.text.trim().isEmpty ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                colorScheme.outline.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            widget.isRename ? 'Save Changes' : 'Save Item Set',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
