// lib/screens/invoice_create_section/step_customers.dart
//
// OPTIONAL LABEL PASS (this update): _SheetField now appends "(Optional)"
// to a field's label automatically whenever `required` is false —
// matching the identical pass already applied to this same app's
// step_templates.dart _SheetField (Invoice Templates step), and just
// applied to QuoteField (quote_edit_widgets.dart) and ReceiptField
// (receipt_edit_widgets.dart). Required fields (already carrying their
// own "*") are untouched. This was the one remaining sheet in the app
// whose optional fields didn't say "(Optional)".
//
// UPDATED (earlier pass): Customer logo picking now uses SharedLogoPicker
// (lib/widgets/shared_logo_picker.dart) instead of a plain ImagePicker +
// "Remove Logo" button, so Reposition/Zoom/Shape are available here the
// same as Business Logo (step_templates.dart) and the receipt/quote
// business profiles. ClientInfo (aliased Customer) gains
// logoOffsetDx/Dy/Scale/Shape (see lib/models/client_info.dart).
// _CustomerCard's avatar now renders via SharedLogoThumbnail so saved
// cards reflect the chosen crop/shape instead of a flat centred cover-fit.
//
// CURRENCY DISPLAY PASS: the old single "Default Currency" free-text
// field is now two fields — currency code and currency symbol, both
// free text (no hardcoded currency list, so any currency works) — plus
// a Code/Symbol/Both display-mode selector with a live preview. See
// models/client_info.dart's ClientInfo.currencySymbol/
// currencyDisplayMode for the persisted fields this writes to.
//
// SCALE PASS: raised the saved-customer cap 12 → 100 and added a search
// box + sort control (Recently Added / Name A-Z / Name Z-A) above the
// customer list so a large saved-customer library stays usable.
// Selection/edit/delete still operate on the real _library index — the
// search/sort view only reorders/filters what's displayed via
// _visibleIndices, it never mutates _library's underlying order.
//
// SEARCH RELEVANCE PASS: while the search box has text, _visibleIndices
// now ranks matches by relevance instead of the chosen sort mode — name
// starts-with the query first, then name contains it, then email/phone
// contains it, each tier alphabetical — so typing a few letters brings
// the closest matches to the top immediately. The sort chips are
// dimmed/disabled while a search is active since relevance ranking
// takes over from them, and re-enable once the search box is cleared.
//
// TAX RATE COUNTER PASS (this update): Default Tax Rate (%) now shows a
// live "X / 6" character counter under the field, matching Name/Email/
// Phone/Address/Currency Code/Currency Symbol. This required adding
// _taxRateCtrl to the listener loop in initState (it was previously
// left out, so the field's setState-driven counter/limit UI wouldn't
// refresh live as the user typed).

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // required for LengthLimitingTextInputFormatter
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:invoice_quote_receipt_builder/models/invoice_data.dart';
import 'package:invoice_quote_receipt_builder/models/client_info.dart';
import 'package:invoice_quote_receipt_builder/services/storage_service.dart';
import 'package:invoice_quote_receipt_builder/widgets/shared_logo_picker.dart';
import 'invoice_edit_widgets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kMaxCustomers = 100;
const _kPrefCustomerList = 'invoice_customer_list';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------
Future<void> _persistCustomers(List<Customer> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefCustomerList,
    jsonEncode(list.map((c) => c.toJson()).toList()),
  );
}

Future<List<Customer>> _loadCustomers() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefCustomerList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// StepCustomers
// =============================================================================

class StepCustomers extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Customer? selectedCustomer;
  final ValueChanged<Customer?> onCustomerChanged;

  const StepCustomers({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.selectedCustomer,
    required this.onCustomerChanged,
  });

  @override
  State<StepCustomers> createState() => _StepCustomersState();
}

// Sort modes for the saved-customer list (used when there's no active search).
enum _SortMode { recent, nameAsc, nameDesc }

class _StepCustomersState extends State<StepCustomers> {
  bool _loading = true;
  List<Customer> _library = [];
  int? _selectedIndex;
  bool _showLibraryPanel = true;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.recent;

  static const _accent = Color(0xFF2E7D32); // green accent for customers

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
    final customers = await _loadCustomers();
    // Try to find currently selected customer
    int? selected;
    if (widget.selectedCustomer != null) {
      final idx = customers.indexWhere((c) => c.id == widget.selectedCustomer!.id);
      if (idx != -1) selected = idx;
    }
    if (!mounted) return;
    setState(() {
      _library = customers;
      _selectedIndex = selected;
      _loading = false;
    });
  }

  // Relevance tier for a customer against the current search query, lower
  // is a closer match. 4 means "doesn't match" and gets filtered out.
  int _relevance(int i, String q) {
    final c = _library[i];
    final name = c.name.toLowerCase();
    if (name.startsWith(q)) return 0;
    if (name.contains(q)) return 1;
    if (c.email.toLowerCase().contains(q)) return 2;
    if (c.phone.toLowerCase().contains(q)) return 3;
    return 4;
  }

  // Real _library indices for what's currently displayed. With no active
  // search, this applies the chosen sort mode. With an active search, it
  // ignores the sort mode and ranks by relevance instead (name starts-with
  // > name contains > email/phone contains, alphabetical within each tier)
  // so the closest matches surface immediately as the person types.
  // Either way, cards/edit/delete key off these real indices so they keep
  // pointing at the right customer regardless of on-screen ordering.
  List<int> get _visibleIndices {
    final q = _searchQuery.trim().toLowerCase();
    var indices = List<int>.generate(_library.length, (i) => i);

    if (q.isEmpty) {
      switch (_sortMode) {
        case _SortMode.nameAsc:
          indices.sort((a, b) =>
              _library[a].name.toLowerCase().compareTo(_library[b].name.toLowerCase()));
          break;
        case _SortMode.nameDesc:
          indices.sort((a, b) =>
              _library[b].name.toLowerCase().compareTo(_library[a].name.toLowerCase()));
          break;
        case _SortMode.recent:
          indices = indices.reversed.toList(); // newest added shown first
          break;
      }
      return indices;
    }

    indices = indices.where((i) => _relevance(i, q) < 4).toList();
    indices.sort((a, b) {
      final ra = _relevance(a, q);
      final rb = _relevance(b, q);
      if (ra != rb) return ra.compareTo(rb);
      return _library[a].name.toLowerCase().compareTo(_library[b].name.toLowerCase());
    });
    return indices;
  }

  void _toggleProfile(int index) {
    if (_selectedIndex == index) {
      setState(() => _selectedIndex = null);
      widget.onCustomerChanged(null);
    } else {
      setState(() => _selectedIndex = index);
      widget.onCustomerChanged(_library[index]);
    }
  }

  void _showAddSheet({Customer? existing, int? editIndex}) {
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
      builder: (_) => _CustomerSheet(
        existing: existing,
        onSaved: (customer) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = customer);
            if (_selectedIndex == editIndex) {
              widget.onCustomerChanged(customer);
            }
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(customer);
              _selectedIndex = newIdx;
              _showLibraryPanel = true;
            });
            widget.onCustomerChanged(customer);
          }
          _persistCustomers(_library);
        },
      ),
    );
  }

  void _deleteCustomer(int index) {
    setState(() {
      _library.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
        widget.onCustomerChanged(null);
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _persistCustomers(_library);
  }

  void _saveAndNext() {
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atMax = _library.length >= _kMaxCustomers;
    final visible = _visibleIndices;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage Customers',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add and select a customer for this invoice',
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
                                '${_library.length}/$_kMaxCustomers',
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
                      const SizedBox(height: 12),

                      // Info banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0A1F0A)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? _accent.withValues(alpha: 0.4)
                                : const Color(0xFFA5D6A7),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: _accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Save up to $_kMaxCustomers customers and select one per invoice.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Add button
                      GestureDetector(
                        onTap: atMax
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Maximum of $_kMaxCustomers customers reached.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                )
                            : () => _showAddSheet(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: atMax
                                ? (isDark
                                    ? colorScheme.surfaceContainerHighest
                                    : const Color(0xFFF5F5F5))
                                : (isDark
                                    ? const Color(0xFF0A1F0A)
                                    : const Color(0xFFE8F5E9)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: atMax
                                  ? colorScheme.outline.withValues(alpha: 0.3)
                                  : (isDark
                                      ? _accent.withValues(alpha: 0.5)
                                      : const Color(0xFFA5D6A7)),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_add_rounded,
                                color: atMax
                                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                                    : _accent,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  atMax
                                      ? 'Maximum Customers Reached'
                                      : 'Add New Customer',
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
                    ],
                  ),
                ),
              ),

              // ── Library header ───────────────────────────────────────────
              if (!_loading && _library.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bookmark_rounded,
                                size: 16, color: _accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Saved Customers',
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _selectedIndex != null ? '1 ✓' : 'none',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedIndex != null
                                      ? _accent
                                      : colorScheme.onSurface.withValues(alpha: 0.45),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _showLibraryPanel = !_showLibraryPanel),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0A1F0A)
                                      : const Color(0xFFE8F5E9),
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
                                      maxLines: 1,
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
                          'Tap a card to select it for this invoice.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),

                        // ── Search + sort ─────────────────────────────────
                        if (_showLibraryPanel) ...[
                          const SizedBox(height: 12),
                          _CustomerSearchField(
                            controller: _searchCtrl,
                            accent: _accent,
                            onClear: () => _searchCtrl.clear(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: IgnorePointer(
                                  ignoring: isSearching,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: isSearching ? 0.35 : 1.0,
                                    child: _SortSelector(
                                      value: _sortMode,
                                      accent: _accent,
                                      onChanged: (mode) =>
                                          setState(() => _sortMode = mode),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                    ),
                  ),
                ),

              // ── Customer cards ───────────────────────────────────────────
              if (!_loading && _showLibraryPanel && visible.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, displayIdx) {
                        final i = visible[displayIdx];
                        return _CustomerCard(
                          customer: _library[i],
                          isSelected: _selectedIndex == i,
                          onTap: () => _toggleProfile(i),
                          onEdit: () => _showAddSheet(
                              existing: _library[i], editIndex: i),
                          onDelete: () => _deleteCustomer(i),
                        );
                      },
                      childCount: visible.length,
                    ),
                  ),
                ),

              // ── No search results (library has customers, none match) ──
              if (!_loading &&
                  _showLibraryPanel &&
                  _library.isNotEmpty &&
                  visible.isEmpty &&
                  isSearching)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    message: 'No customers match your search',
                    sub: 'Try a different name, email, or phone number',
                  ),
                ),

              // ── Empty state (no customers saved at all) ─────────────────
              if (!_loading && _library.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.people_outline_rounded,
                    message: 'No customers saved yet',
                    sub: 'Tap above to add your first customer',
                  ),
                ),

              if (_loading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),

        SafeArea(
          top: false,
          bottom: true,
          child: StepNavBar(
            onBack: widget.onBack,
            onNext: _saveAndNext,
            nextLabel: 'Continue to Templates',
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Search field for the saved-customer list
// =============================================================================

class _CustomerSearchField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final VoidCallback onClear;

  const _CustomerSearchField({
    required this.controller,
    required this.accent,
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
            hintText: 'Search saved customers…',
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
// Sort selector (segmented chips) for the saved-customer list. Disabled
// (dimmed, non-interactive) by the parent while a search is active, since
// relevance ranking takes over from the chosen sort mode during a search.
// =============================================================================

class _SortSelector extends StatelessWidget {
  final _SortMode value;
  final Color accent;
  final ValueChanged<_SortMode> onChanged;

  const _SortSelector({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  static const _options = [
    (_SortMode.recent, 'Recent', Icons.schedule_rounded),
    (_SortMode.nameAsc, 'A–Z', Icons.arrow_downward_rounded),
    (_SortMode.nameDesc, 'Z–A', Icons.arrow_upward_rounded),
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
                    color: selected
                        ? accent
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 13,
                        color: selected
                            ? Colors.white
                            : colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : colorScheme.onSurface.withValues(alpha: 0.6),
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
// Customer Card
// =============================================================================

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _accent = Color(0xFF2E7D32);

  const _CustomerCard({
    required this.customer,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasLogo = customer.logoPath != null &&
        customer.logoPath!.isNotEmpty &&
        File(customer.logoPath!).existsSync();
    final shape = logoShapeFromString(customer.logoShape);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF0D1F0D) : Colors.white)
            : (isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? _accent.withValues(alpha: isDark ? 0.6 : 0.5)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: isDark ? 0.12 : 0.08),
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
                  color: isSelected ? _accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? _accent
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

              // Avatar / logo
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: shape.radiusFor(46),
                  color: hasLogo
                      ? Colors.black
                      : (isSelected
                          ? (isDark
                              ? _accent.withValues(alpha: 0.15)
                              : const Color(0xFFE8F5E9))
                          : colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5)),
                  border: Border.all(
                    color: isSelected
                        ? _accent.withValues(alpha: 0.4)
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? SharedLogoThumbnail(
                        logoPath: customer.logoPath!,
                        logoOffset: Offset(customer.logoOffsetDx, customer.logoOffsetDy),
                        logoScale: customer.logoScale,
                        logoShape: shape,
                        boxSize: 46,
                      )
                    : Center(
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? _accent
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name.isNotEmpty ? customer.name : '(No name)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (customer.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? _accent
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (customer.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(width: 3),
                          Text(
                            customer.phone,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (customer.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              customer.address,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active for this invoice',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _accent,
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
                            ? _accent.withValues(alpha: 0.12)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.edit_rounded, color: _accent, size: 16),
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
// Bottom Sheet – add / edit a customer
// =============================================================================

class _CustomerSheet extends StatefulWidget {
  final Customer? existing;
  final void Function(Customer) onSaved;

  const _CustomerSheet({this.existing, required this.onSaved});

  @override
  State<_CustomerSheet> createState() => _CustomerSheetState();
}

class _CustomerSheetState extends State<_CustomerSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _currencySymbolCtrl;
  late TextEditingController _taxRateCtrl;
  String _currencyDisplayMode = 'code'; // 'code' | 'symbol' | 'both'
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.circle;

  static const _accent = Color(0xFF2E7D32);

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _currencyCtrl = TextEditingController(text: e?.defaultCurrency ?? 'USD');
    _currencySymbolCtrl = TextEditingController(text: e?.currencySymbol ?? '');
    _currencyDisplayMode = e?.currencyDisplayMode ?? 'code';
    _taxRateCtrl = TextEditingController(text: (e == null || e.defaultTaxRate == 0.0) ? '' : e.defaultTaxRate.toString());
    _logoPath = e?.logoPath;
    _logoOffset = e != null ? Offset(e.logoOffsetDx, e.logoOffsetDy) : Offset.zero;
    _logoScale = e?.logoScale ?? 1.0;
    _logoShape = logoShapeFromString(e?.logoShape ?? 'circle');

    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _addressCtrl, _currencyCtrl, _currencySymbolCtrl, _taxRateCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currencyCtrl.dispose();
    _currencySymbolCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSaved(Customer(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      logoPath: _logoPath,
      logoOffsetDx: _logoOffset.dx,
      logoOffsetDy: _logoOffset.dy,
      logoScale: _logoScale,
      logoShape: _logoShape.storageName,
      defaultCurrency: _currencyCtrl.text.trim().isEmpty ? 'USD' : _currencyCtrl.text.trim().toUpperCase(),
      currencySymbol: _currencySymbolCtrl.text.trim(),
      currencyDisplayMode: _currencyDisplayMode,
      defaultTaxRate: double.tryParse(_taxRateCtrl.text.trim()) ?? 0.0,
    ));
    Navigator.pop(context);
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _counter(int current, int max) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$current / $max',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: current > max
                ? const Color(0xFFF44336)
                : colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = kb + 32 + MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sheet title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isEditing ? 'Edit Customer' : 'New Customer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (_isEditing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0A1F0A)
                                      : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _accent.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'Editing',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Logo section ──────────────────────────────────
                        _sectionLabel('Customer Logo'),
                        SharedLogoPicker(
                          logoPath: _logoPath,
                          logoOffset: _logoOffset,
                          logoScale: _logoScale,
                          logoShape: _logoShape,
                          accent: _accent,
                          onChanged: (p, o, s, shape) => setState(() {
                            _logoPath = p;
                            _logoOffset = o;
                            _logoScale = s;
                            _logoShape = shape;
                          }),
                        ),
                        const SizedBox(height: 20),

                        // ── Basic details ─────────────────────────────────
                        _sectionLabel('Customer Details'),
                        _SheetField(
                          ctrl: _nameCtrl,
                          label: 'Name *',
                          hint: 'e.g. Acme Corp',
                          icon: Icons.person_rounded,
                          max: 100,
                          required: true,
                          accent: _accent,
                        ),
                        _counter(_nameCtrl.text.length, 100),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          hint: 'e.g. billing@acme.com',
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                          accent: _accent,
                        ),
                        _counter(_emailCtrl.text.length, 100),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _phoneCtrl,
                          label: 'Phone',
                          hint: 'e.g. +1 555 123 4567',
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                          accent: _accent,
                        ),
                        _counter(_phoneCtrl.text.length, 20),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _addressCtrl,
                          label: 'Address',
                          hint: 'e.g. 123 Main St, New York, USA',
                          icon: Icons.location_on_rounded,
                          max: 200,
                          maxLines: 2,
                          accent: _accent,
                        ),
                        _counter(_addressCtrl.text.length, 200),
                        const SizedBox(height: 12),

                        // ── Currency ───────────────────────────────────────
                        _SheetField(
                          ctrl: _currencyCtrl,
                          label: 'Default Currency Code',
                          hint: 'e.g. USD',
                          icon: Icons.attach_money_rounded,
                          max: 6,
                          accent: _accent,
                        ),
                        _counter(_currencyCtrl.text.length, 6),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _currencySymbolCtrl,
                          label: 'Currency Symbol',
                          hint: 'e.g. \$, €, kr — optional',
                          icon: Icons.currency_exchange_rounded,
                          max: 6,
                          accent: _accent,
                        ),
                        _counter(_currencySymbolCtrl.text.length, 6),
                        const SizedBox(height: 12),
                        _CurrencyDisplayModeSelector(
                          value: _currencyDisplayMode,
                          accent: _accent,
                          onChanged: (mode) => setState(() => _currencyDisplayMode = mode),
                          previewCode: _currencyCtrl.text.trim().isEmpty
                              ? 'USD' : _currencyCtrl.text.trim().toUpperCase(),
                          previewSymbol: _currencySymbolCtrl.text.trim(),
                        ),
                        const SizedBox(height: 12),

                        _SheetField(
                          ctrl: _taxRateCtrl,
                          label: 'Default Tax Rate (%)',
                          hint: 'e.g. 8.5',
                          icon: Icons.percent_rounded,
                          max: 6,
                          keyboard: TextInputType.numberWithOptions(decimal: true),
                          accent: _accent,
                        ),
                        _counter(_taxRateCtrl.text.length, 6),
                        const SizedBox(height: 12),
                        const SizedBox(height: 28),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isEditing ? 'Save Changes' : 'Save Customer',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// =============================================================================
// Reusable text field for the sheet
// =============================================================================

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData? icon;
  final int? max;
  final int maxLines;
  final bool required;
  final TextInputType? keyboard;
  final Color accent;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.ctrl,
    required this.label,
    required this.accent,
    this.hint,
    this.icon,
    this.max,
    this.maxLines = 1,
    this.required = false,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atLimit = max != null && ctrl.text.length >= max!;
    // OPTIONAL LABEL PASS: matches step_templates.dart's _SheetField —
    // non-required fields get "(Optional)" appended to their label
    // automatically. Required fields (already carrying their own "*")
    // are untouched.
    final displayLabel = required ? label : '$label (Optional)';

    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      inputFormatters: max != null
          ? [LengthLimitingTextInputFormatter(max!)]
          : null,
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
      decoration: InputDecoration(
        labelText: displayLabel,
        labelStyle:
            TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        hintText: hint,
        hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.45))
            : null,
        suffixIcon: atLimit
            ? Tooltip(
                message: 'Character limit reached',
                child: const Icon(Icons.warning_amber_rounded,
                    size: 18, color: Color(0xFFF44336)))
            : null,
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: atLimit
                    ? const Color(0xFFF44336)
                    : colorScheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: atLimit ? const Color(0xFFF44336) : accent,
                width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF44336))),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      ),
    );
  }
}

// =============================================================================
// Currency display mode selector — segmented Code / Symbol / Both control
// with a live preview using whatever's currently typed in the code/symbol
// fields above.
// =============================================================================

class _CurrencyDisplayModeSelector extends StatelessWidget {
  final String value; // 'code' | 'symbol' | 'both'
  final Color accent;
  final ValueChanged<String> onChanged;
  final String previewCode;
  final String previewSymbol;

  const _CurrencyDisplayModeSelector({
    required this.value,
    required this.accent,
    required this.onChanged,
    required this.previewCode,
    required this.previewSymbol,
  });

  String _previewFor(String mode) {
    const amount = '200.00';
    final hasSymbol = previewSymbol.trim().isNotEmpty;
    final hasCode = previewCode.trim().isNotEmpty;
    switch (mode) {
      case 'symbol':
        return hasSymbol ? '$previewSymbol$amount' : (hasCode ? '$previewCode $amount' : amount);
      case 'both':
        if (hasSymbol && hasCode) return '$previewCode $previewSymbol$amount';
        if (hasSymbol) return '$previewSymbol$amount';
        return hasCode ? '$previewCode $amount' : amount;
      case 'code':
      default:
        return hasCode ? '$previewCode $amount' : (hasSymbol ? '$previewSymbol$amount' : amount);
    }
  }

  static const _options = [
    ('code', 'Code'),
    ('symbol', 'Symbol'),
    ('both', 'Both'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Format',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: _options.map((opt) {
              final (mode, label) = opt;
              final selected = value == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: selected ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _previewFor(mode),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.85)
                                : colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
