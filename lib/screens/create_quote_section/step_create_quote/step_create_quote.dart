// lib/screens/create_quote_section/step_create_quote/step_create_quote.dart
//
// SAVED-ITEMS FILTERS PASS (this update): adds a search field +
// Recent/A-Z/Z-A sort selector to the "Saved Quotes" list, matching the
// same treatment already applied to the Templates step
// (quote_step_template.dart) — new _DraftSearchField / _DraftSortSelector
// widgets at the bottom of this file, matching relevance against the
// draft's display name, quote number, and client name. The library's
// previous hardcoded `_library.length - 1 - displayIdx` reversal
// (via List.generate) is gone — the card list now iterates
// `_visibleIndices`, which reproduces that exact same newest-first
// order under the default "Recent" sort mode, so nothing changes
// visually until a person actually searches or picks a different sort.
//
// CREATE-QUOTE PARITY PASS (earlier): _QuoteDraftCard renders the
// draft's own container logo (SavedQuoteDraft.logoPath, set via
// create_quote_bottom_sheet.dart's "Container Logo" section) exactly
// the way Invoice's _InvoiceDraftCard does — a real SharedLogoThumbnail
// when a logo is set, else the same rotated-square initial-letter
// fallback mark (respecting logoShowInitial/logoInitialLetter), else a
// plain icon as the last resort. _QuoteDraftCardFallbackMark mirrors
// Invoice's _DraftCardFallbackMark exactly, adapted to SavedQuoteDraft's
// flat logo fields.
//
// Deliberately still an EMBEDDED widget, not a standalone Scaffold+
// StepNavBar screen — this is wired into QuoteEditorScreen's single
// shared bottomNavigationBar (QuoteStepNavBar) alongside
// QuoteStepCustomerSection/QuoteStepTemplateSection, and changing that
// container shape would break that integration.
//
// This widget owns a library of SavedQuoteDraft (quote_data.dart),
// persisted as a single JSON-encoded SharedPreferences list under
// 'quote_saved_draft_list'. Tapping "Create Quote" opens
// CreateQuoteBottomSheet blank (seeded only from
// widget.selectedClient/widget.selectedTemplate); saving it appends a
// new draft to the library and selects it. Tapping a saved card selects
// it (single-select); tapping its pencil icon reopens the sheet
// pre-filled with that draft's data for further editing; tapping its
// trash icon deletes it.
//
// Selection is reported to the parent (QuoteEditorScreen) via
// onDraftSelected(SavedQuoteDraft?) every time it changes.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/quote_data.dart';
import '../../../widgets/shared_logo_picker.dart';
import 'create_quote_bottom_sheet.dart';
import '../step_customer/quote_step_customer.dart' show QuoteClient;
import '../step_templates/quote_step_template.dart' show QuoteTemplate;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kMaxQuoteDrafts = 100;
const _kPrefQuoteDraftList = 'quote_saved_draft_list';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------
Future<void> _persistDrafts(List<SavedQuoteDraft> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefQuoteDraftList,
    jsonEncode(list.map((d) => d.toJson()).toList()),
  );
}

Future<List<SavedQuoteDraft>> _loadDrafts() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefQuoteDraftList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => SavedQuoteDraft.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// StepCreateQuote
// =============================================================================

class StepCreateQuote extends StatefulWidget {
  final Color accent;
  final QuoteClient? selectedClient;
  final QuoteTemplate? selectedTemplate;

  final void Function(SavedQuoteDraft? draft) onDraftSelected;

  const StepCreateQuote({
    super.key,
    required this.accent,
    required this.onDraftSelected,
    this.selectedClient,
    this.selectedTemplate,
  });

  @override
  State<StepCreateQuote> createState() => _StepCreateQuoteState();
}

// SAVED-ITEMS FILTERS PASS: sort modes for the saved-quote list,
// matching Templates' own sort modes.
enum _DraftSortMode { recent, nameAsc, nameDesc }

class _StepCreateQuoteState extends State<StepCreateQuote> {
  bool _loading = true;
  List<SavedQuoteDraft> _library = [];
  int? _selectedIndex;
  bool _showLibraryPanel = true;

  // SAVED-ITEMS FILTERS PASS: search + sort state.
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _DraftSortMode _sortMode = _DraftSortMode.recent;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final drafts = await _loadDrafts();
    if (!mounted) return;
    setState(() {
      _library = drafts;
      _loading = false;
    });
  }

  // SAVED-ITEMS FILTERS PASS: relevance tier against display name,
  // quote number, and client name. 3 means "doesn't match" and gets
  // filtered out.
  int _relevance(int i, String q) {
    final draft = _library[i];
    final d = draft.data;
    final name = draft.displayName.toLowerCase();
    final quoteNumber = d.quoteNumber.toLowerCase();
    final client = d.clientName.toLowerCase();
    if (name.startsWith(q)) return 0;
    if (name.contains(q)) return 1;
    if (quoteNumber.contains(q) || client.contains(q)) return 2;
    return 3;
  }

  // Real _library indices for what's currently displayed — same
  // relevance-vs-sort behaviour as the Templates step's own
  // _visibleIndices. "Recent" reproduces the exact same newest-first
  // order the card list previously got via the hardcoded
  // `_library.length - 1 - displayIdx` reversal, so the default view is
  // unchanged.
  List<int> get _visibleIndices {
    final q = _searchQuery.trim().toLowerCase();
    var indices = List<int>.generate(_library.length, (i) => i);

    if (q.isEmpty) {
      switch (_sortMode) {
        case _DraftSortMode.nameAsc:
          indices.sort((a, b) => _library[a]
              .displayName
              .toLowerCase()
              .compareTo(_library[b].displayName.toLowerCase()));
          break;
        case _DraftSortMode.nameDesc:
          indices.sort((a, b) => _library[b]
              .displayName
              .toLowerCase()
              .compareTo(_library[a].displayName.toLowerCase()));
          break;
        case _DraftSortMode.recent:
          indices = indices.reversed.toList(); // newest added shown first
          break;
      }
      return indices;
    }

    indices = indices.where((i) => _relevance(i, q) < 3).toList();
    indices.sort((a, b) {
      final ra = _relevance(a, q);
      final rb = _relevance(b, q);
      if (ra != rb) return ra.compareTo(rb);
      return _library[a]
          .displayName
          .toLowerCase()
          .compareTo(_library[b].displayName.toLowerCase());
    });
    return indices;
  }

  void _toggleDraft(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
    widget.onDraftSelected(_selectedIndex == null ? null : _library[_selectedIndex!]);
  }

  void _showCreateSheet({SavedQuoteDraft? existing, int? editIndex}) {
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
      builder: (_) => CreateQuoteBottomSheet(
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
    final atMax = _library.length >= _kMaxQuoteDrafts;
    final accent = widget.accent;
    // SAVED-ITEMS FILTERS PASS
    final visible = _visibleIndices;
    final isSearching = _searchQuery.trim().isNotEmpty;

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
                    'Create Quote',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save one or more quotes, then continue with the one you want',
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
                  '${_library.length}/$_kMaxQuoteDrafts',
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

        // ── Create Quote button ──────────────────────────────────────
        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Maximum of $_kMaxQuoteDrafts quotes reached.',
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
                      ? const Color(0xFF2A0D33)
                      : const Color(0xFFF3E5F5)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: atMax
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : (isDark
                        ? accent.withValues(alpha: 0.5)
                        : const Color(0xFFCE93D8)),
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
                    atMax ? 'Maximum Quotes Reached' : 'Create Quote',
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
                  'Saved Quotes',
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
                        ? const Color(0xFF2A0D33)
                        : const Color(0xFFF3E5F5),
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
            'Tap a card to select it for this quote.',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          if (_showLibraryPanel) ...[
            const SizedBox(height: 12),
            // SAVED-ITEMS FILTERS PASS: search field + sort selector,
            // same placement/behaviour as the Templates step.
            _DraftSearchField(
              controller: _searchCtrl,
              accent: accent,
              hintText: 'Search saved quotes…',
              onClear: () => _searchCtrl.clear(),
            ),
            const SizedBox(height: 10),
            IgnorePointer(
              ignoring: isSearching,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSearching ? 0.35 : 1.0,
                child: _DraftSortSelector(
                  value: _sortMode,
                  accent: accent,
                  onChanged: (mode) => setState(() => _sortMode = mode),
                ),
              ),
            ),
            if (isSearching) ...[
              const SizedBox(height: 6),
              Text(
                'Sorted by relevance to "${_searchCtrl.text.trim()}"',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ],

        // ── Draft cards ────────────────────────────────────────────────
        if (!_loading && _showLibraryPanel && _library.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (visible.isNotEmpty)
            ...visible.map((i) => _QuoteDraftCard(
                  draft: _library[i],
                  isSelected: _selectedIndex == i,
                  accent: accent,
                  onTap: () => _toggleDraft(i),
                  onEdit: () => _showCreateSheet(existing: _library[i], editIndex: i),
                  onDelete: () => _deleteDraft(i),
                ))
          else if (isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No quotes match your search',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.45)),
              ),
            ),
        ],

        // ── Empty state ─────────────────────────────────────────────
        if (!_loading && _library.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.request_quote_outlined,
                      size: 40, color: colorScheme.onSurface.withValues(alpha: 0.25)),
                  const SizedBox(height: 12),
                  Text(
                    'No quotes created yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap above to create your first quote',
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
// SAVED-ITEMS FILTERS PASS: search field for the saved-quote list.
// Functionally identical to the Templates step's own search field,
// duplicated here since that widget is file-private to that file.
// =============================================================================

class _DraftSearchField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final String hintText;
  final VoidCallback onClear;

  const _DraftSearchField({
    required this.controller,
    required this.accent,
    required this.hintText,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return TextField(
          controller: controller,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
                fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.35)),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            suffixIcon: hasText
                ? GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded,
                        size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : const Color(0xFFF9F9F9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.5)),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SAVED-ITEMS FILTERS PASS: sort selector (segmented chips) for the
// saved-quote list. Same shape as the Templates step's own sort
// selector.
// =============================================================================

class _DraftSortSelector extends StatelessWidget {
  final _DraftSortMode value;
  final Color accent;
  final ValueChanged<_DraftSortMode> onChanged;

  const _DraftSortSelector({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  static const _options = [
    (_DraftSortMode.recent, 'Recent', Icons.schedule_rounded),
    (_DraftSortMode.nameAsc, 'A–Z', Icons.arrow_downward_rounded),
    (_DraftSortMode.nameDesc, 'Z–A', Icons.arrow_upward_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((opt) {
          final (mode, label, icon) = opt;
          final selected = value == mode;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? accent
                      : (isDark
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                          : const Color(0xFFF9F9F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? accent : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 13,
                        color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Quote Draft Card
// =============================================================================

class _QuoteDraftCard extends StatelessWidget {
  final SavedQuoteDraft draft;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuoteDraftCard({
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

    // CREATE-QUOTE PARITY PASS: real thumbnail when the container has a
    // logo set, else the same rotated-square fallback mark Invoice's
    // _InvoiceDraftCard uses (or a plain icon as the last resort when
    // logoShowInitial is off).
    final hasLogo = draft.logoPath != null &&
        draft.logoPath!.isNotEmpty &&
        File(draft.logoPath!).existsSync();
    final shape = logoShapeFromString(draft.logoShape);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF2A0D33) : Colors.white)
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

              // Logo / fallback mark — see CREATE-QUOTE PARITY PASS above.
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: shape.radiusFor(46),
                  color: isSelected
                      ? (isDark
                          ? accent.withValues(alpha: 0.15)
                          : const Color(0xFFF3E5F5))
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  border: Border.all(
                    color: isSelected
                        ? accent.withValues(alpha: 0.4)
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? SharedLogoThumbnail(
                        logoPath: draft.logoPath!,
                        logoOffset: Offset(draft.logoOffsetDx, draft.logoOffsetDy),
                        logoScale: draft.logoScale,
                        logoShape: shape,
                        boxSize: 46,
                      )
                    : (draft.logoShowInitial
                        ? _QuoteDraftCardFallbackMark(draft: draft, accent: accent)
                        : Icon(
                            Icons.request_quote_rounded,
                            color: isSelected
                                ? accent
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                            size: 22,
                          )),
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
                    if (d.quoteNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        d.quoteNumber,
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
                            : const Color(0xFFF3E5F5),
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

// =============================================================================
// _QuoteDraftCardFallbackMark — rotated-square initial mark shown when a
// draft has no container logo set and logoShowInitial is on. Mirrors
// Invoice's _DraftCardFallbackMark exactly, adapted to SavedQuoteDraft's
// flat logo fields (and draft.name / the quote's client name as the
// letter source) instead of BusinessInfo's nesting.
// =============================================================================

class _QuoteDraftCardFallbackMark extends StatelessWidget {
  final SavedQuoteDraft draft;
  final Color accent;
  const _QuoteDraftCardFallbackMark({required this.draft, required this.accent});

  @override
  Widget build(BuildContext context) {
    final letter = draft.logoInitialLetter.trim();
    final source = draft.name.trim().isNotEmpty
        ? draft.name.trim()
        : draft.data.clientName.trim();
    final initial = letter.isNotEmpty
        ? letter[0].toUpperCase()
        : (source.isNotEmpty ? source[0].toUpperCase() : 'Q');
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
          ),
        ),
        Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}