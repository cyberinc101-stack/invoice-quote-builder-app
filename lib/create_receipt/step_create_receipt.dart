// lib/create_receipt/step_create_receipt.dart
//
// NEW FILE — RECEIPT LIBRARY RESTRUCTURE PASS: mirrors
// step_create_invoice.dart / create_quote_section/step_create_quote.dart's
// library pattern (header -> info banner -> "Create Receipt" button ->
// "Saved Receipts" section with Hide/Show -> cards) as an EMBEDDED
// widget, not a standalone screen with its own Scaffold/nav bar —
// matching how ReceiptStepCustomerSection/ReceiptStepTemplateSection are
// embedded inside CreateReceiptScreen's single shared bottomNavigationBar
// (ReceiptStepNavBar), same pattern quote's StepCreateQuote uses.
//
// This widget owns a library of SavedReceiptDraft (receipt_data.dart),
// persisted as a single JSON-encoded SharedPreferences list under
// 'receipt_saved_draft_list'. Tapping "Create Receipt" opens
// CreateReceiptBottomSheet blank (seeded only from
// widget.selectedClient/widget.selectedTemplate); saving it appends a
// new draft to the library and selects it. Tapping a saved card selects
// it (single-select); tapping its pencil icon reopens the sheet
// pre-filled with that draft's data for further editing; tapping its
// trash icon deletes it.
//
// Selection is reported to the parent (CreateReceiptScreen) via
// onDraftSelected(SavedReceiptDraft?) every time it changes.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt_data.dart';
import 'create_receipt_bottom_sheet.dart';
import 'receipt_step_customer.dart' show ReceiptClient;
import 'receipt_step_template.dart' show ReceiptTemplate;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kMaxReceiptDrafts = 100;
const _kPrefReceiptDraftList = 'receipt_saved_draft_list';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------
Future<void> _persistDrafts(List<SavedReceiptDraft> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefReceiptDraftList,
    jsonEncode(list.map((d) => d.toJson()).toList()),
  );
}

Future<List<SavedReceiptDraft>> _loadDrafts() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefReceiptDraftList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => SavedReceiptDraft.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// StepCreateReceipt
// =============================================================================

class StepCreateReceipt extends StatefulWidget {
  final Color accent;
  final ReceiptClient? selectedClient;
  final ReceiptTemplate? selectedTemplate;

  /// Called every time the selected draft changes (including becoming
  /// null when a selected card is tapped again to deselect it, or
  /// deleted).
  final void Function(SavedReceiptDraft? draft) onDraftSelected;

  const StepCreateReceipt({
    super.key,
    required this.accent,
    required this.onDraftSelected,
    this.selectedClient,
    this.selectedTemplate,
  });

  @override
  State<StepCreateReceipt> createState() => _StepCreateReceiptState();
}

class _StepCreateReceiptState extends State<StepCreateReceipt> {
  bool _loading = true;
  List<SavedReceiptDraft> _library = [];
  int? _selectedIndex;
  bool _showLibraryPanel = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final drafts = await _loadDrafts();
    if (!mounted) return;
    setState(() {
      _library = drafts;
      _loading = false;
    });
  }

  void _toggleDraft(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
    widget.onDraftSelected(_selectedIndex == null ? null : _library[_selectedIndex!]);
  }

  void _showCreateSheet({SavedReceiptDraft? existing, int? editIndex}) {
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
      builder: (_) => CreateReceiptBottomSheet(
        selectedClient: widget.selectedClient,
        selectedTemplate: widget.selectedTemplate,
        existing: existing,
        onSaved: (draft) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = draft);
            if (_selectedIndex == editIndex) {
              widget.onDraftSelected(draft);
            }
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(draft);
              _selectedIndex = newIdx;
              _showLibraryPanel = true;
            });
            widget.onDraftSelected(draft);
          }
          _persistDrafts(_library);
        },
      ),
    );
  }

  void _deleteDraft(int index) {
    setState(() {
      _library.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _persistDrafts(_library);
    widget.onDraftSelected(_selectedIndex == null ? null : _library[_selectedIndex!]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atMax = _library.length >= _kMaxReceiptDrafts;
    final accent = widget.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Receipt',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save one or more receipts, then continue with the one you want',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_library.length}/$_kMaxReceiptDrafts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: atMax
                        ? const Color(0xFFEF5350)
                        : colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Create Receipt button ──────────────────────────────────────
        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Maximum of $_kMaxReceiptDrafts receipts reached.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  )
              : () => _showCreateSheet(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: atMax
                  ? (isDark
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFF5F5F5))
                  : (isDark
                      ? const Color(0xFF0D2A0F)
                      : const Color(0xFFE8F5E9)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: atMax
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : (isDark
                        ? accent.withValues(alpha: 0.5)
                        : const Color(0xFFA5D6A7)),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: atMax
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : accent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    atMax ? 'Maximum Receipts Reached' : 'Create Receipt',
                    style: TextStyle(
                      color: atMax
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : accent,
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

        // ── Library header ────────────────────────────────────────────
        if (!_loading && _library.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.bookmark_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Saved Receipts',
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedIndex != null ? '1 ✓' : 'none',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _selectedIndex != null
                        ? accent
                        : colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                        ? const Color(0xFF0D2A0F)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showLibraryPanel ? 'Hide' : 'Show',
                        style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _showLibraryPanel
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a card to select it for this receipt.',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],

        // ── Draft cards ────────────────────────────────────────────────
        if (!_loading && _showLibraryPanel && _library.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_library.length, (displayIdx) {
            final i = _library.length - 1 - displayIdx; // newest first
            return _ReceiptDraftCard(
              draft: _library[i],
              isSelected: _selectedIndex == i,
              accent: accent,
              onTap: () => _toggleDraft(i),
              onEdit: () => _showCreateSheet(existing: _library[i], editIndex: i),
              onDelete: () => _deleteDraft(i),
            );
          }),
        ],

        // ── Empty state ─────────────────────────────────────────────
        if (!_loading && _library.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 40, color: colorScheme.onSurface.withValues(alpha: 0.25)),
                  const SizedBox(height: 12),
                  Text(
                    'No receipts created yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap above to create your first receipt',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Receipt Draft Card
// =============================================================================

class _ReceiptDraftCard extends StatelessWidget {
  final SavedReceiptDraft draft;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReceiptDraftCard({
    required this.draft,
    required this.isSelected,
    required this.accent,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = draft.data;
    final currencyPrefix = d.currencySymbol.trim().isNotEmpty
        ? d.currencySymbol.trim()
        : (d.currency.trim().isNotEmpty ? '${d.currency.trim()} ' : '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF0D2A0F) : Colors.white)
            : (isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? accent.withValues(alpha: isDark ? 0.6 : 0.5)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? accent
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),

              // Icon block
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? (isDark
                          ? accent.withValues(alpha: 0.15)
                          : const Color(0xFFE8F5E9))
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  border: Border.all(
                    color: isSelected
                        ? accent.withValues(alpha: 0.4)
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: isSelected
                      ? accent
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.receiptNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        d.receiptNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? accent
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                            '${draft.itemCount} item${draft.itemCount == 1 ? '' : 's'}',
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
                            '$currencyPrefix${draft.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edited ${draft.lastEditedDisplay()}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Selected to continue',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? accent.withValues(alpha: 0.12)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_rounded, color: accent, size: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Color(0xFFEF5350), size: 16),
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
