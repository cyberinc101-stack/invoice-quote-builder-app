// lib/screens/invoice_create_section/step_customers.dart
//
// SELECTION STATUS PASS (this update): Quote's/Receipt's editor screens
// (quote_editor_screen.dart / create_receipt_screen.dart) each wrap
// their customer-step widget with a small colored info container below
// it — "Select a saved customer, or enter one manually on the next
// Create X step." when nothing's selected, or "Using 'Name' for this
// quote/receipt." once something is — via their own _selectionStatus()
// helper. Invoice's EditorScreen has no equivalent wrapper at all; it
// renders StepCustomers directly with nothing appended after it, so
// this box never showed on the invoice flow. Since StepCustomers is a
// fully self-contained widget (unlike Quote's/Receipt's customer-step
// widgets, which get wrapped by their editor screen from the outside),
// the fix lives here instead: a new _SelectionStatus widget, added as
// the final sliver in this same CustomScrollView so it always renders
// regardless of loading/empty state, matching the visual style and
// copy pattern of Quote's/Receipt's version exactly (just with this
// screen's own green accent and "invoice" wording).
//
// SCAFFOLD PARITY FIX (earlier): same root cause and same fix as
// step_create_invoice.dart's SCAFFOLD PARITY FIX pass — this widget's
// StepNavBar was just the last child of a plain Column, sitting inside
// EditorScreen's body (editor_screen.dart), and EditorScreen's own
// Scaffold has no `bottomNavigationBar` set at all. The "Maximum of X
// customers reached" SnackBar shown via `ScaffoldMessenger.of(context)`
// from in here resolved to EditorScreen's Scaffold, which has nothing to
// dock above — so it just sat at the literal bottom of the screen, on
// top of wherever this widget's own StepNavBar happened to be rendered.
//
// Fix: this widget now wraps itself in its own `ScaffoldMessenger` +
// `Scaffold`, with its StepNavBar registered as that Scaffold's real
// `bottomNavigationBar` instead of being a plain trailing Column child.
// The "Maximum of X customers reached" SnackBar is now shown via a
// local `GlobalKey<ScaffoldMessengerState>` (`_messengerKey`) instead of
// `ScaffoldMessenger.of(context)`, so it resolves to THIS widget's own
// ScaffoldMessenger — which now has a real bottomNavigationBar to dock
// above. The stray `behavior: SnackBarBehavior.floating` is also dropped
// for consistency, matching the fixed/docked look used elsewhere.
//
// STRUCTURED ADDRESS WIRING PASS (earlier): the single free-text
// Address field is replaced with AddressFieldGroup (six fields — Line 1,
// Line 2, City, State/Province, Country, ZIP/Postal Code — see
// address_info.dart / shared_address_field_group.dart). This is the pass
// that was missing: address_info.dart/shared_address_field_group.dart
// existed already but nothing in this sheet actually used them, so the
// address input still rendered/saved as one flat string. `_addressCtrl`
// is gone, replaced by `_addressControllers` (AddressFieldControllers).
// _save() now writes BOTH `address` (kept in sync as
// addressInfo.singleLine, for anything that still reads the legacy
// string field — PDF export, older screens, etc.) AND the new
// structured `addressInfo` onto Customer (ClientInfo).
//
// FIELD LENGTH TIGHTENING PASS (earlier): Name/Email caps lowered from
// 100/100 to 40/60 — those wider limits let a customer record hold
// enough text to visibly overexpand the invoice's "Billed To" block
// (executive_invoice_stationary_layout.dart's _BillToMetaRow renders
// Name/Email with no maxLines or truncation of its own), pushing the
// header taller than intended and throwing off alignment against the
// meta/status column beside it. The old Address cap (120, 2 lines) no
// longer applies now that Address is six separate structured fields
// (each with its own cap — see shared_address_field_group.dart).
// Phone's 20-char cap is unchanged — already realistic.
//
// TAX RATE REMOVAL PASS (earlier, re-issued): the Default Tax Rate
// (%) field has been removed from the customer sheet entirely — same
// reasoning as the earlier currency removal: it's redundant to set
// per-customer. ClientInfo.defaultTaxRate is UNTOUCHED as a model
// field — an existing customer being edited keeps whatever tax rate
// they already had (read once into `_defaultTaxRate` in initState and
// written back unchanged in _save()); a new customer gets 0.0. There's
// just no way to set/change it from this sheet anymore. _taxRateCtrl
// and its field/counter are gone.
//
// AUTO-SCROLL-ON-FOCUS PASS (earlier, strengthened): _SheetField's
// focus-triggered Scrollable.ensureVisible() call retries at several
// points during the keyboard's rise animation (80/200/350/500ms after
// focus) instead of a single fixed-delay guess. Matches the identical
// strengthened pass in step_templates.dart's _SheetField.
//
// CURRENCY REMOVAL PASS (earlier update): the Default Currency Code /
// Currency Symbol / Display Format (Code/Symbol/Both) section has been
// removed from the customer sheet entirely. Currency now lives only on
// InvoiceTemplate (see client_info.dart) — setting it per-customer was
// redundant and confusing. ClientInfo.defaultCurrency/currencySymbol/
// currencyDisplayMode were removed from the model in the same pass (see
// client_info.dart).
//
// OPTIONAL LABEL PASS (earlier): _SheetField appends "(Optional)" to a
// field's label automatically whenever `required` is false.
//
// UPDATED (earlier pass): Customer logo picking now uses SharedLogoPicker.
//
// SCALE PASS: raised the saved-customer cap 12 → 100 and added a search
// box + sort control above the customer list.
//
// SEARCH RELEVANCE PASS: while the search box has text, _visibleIndices
// ranks matches by relevance instead of the chosen sort mode.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:invoice_quote_receipt_builder/models/invoice_data.dart';
import 'package:invoice_quote_receipt_builder/models/client_info.dart';
import 'package:invoice_quote_receipt_builder/models/address_info.dart';
import 'package:invoice_quote_receipt_builder/services/storage_service.dart';
import 'package:invoice_quote_receipt_builder/widgets/shared_logo_picker.dart';
import 'package:invoice_quote_receipt_builder/widgets/shared_address_field_group.dart';
import 'invoice_edit_widgets.dart';

const int _kMaxCustomers = 100;
const _kPrefCustomerList = 'invoice_customer_list';

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

enum _SortMode { recent, nameAsc, nameDesc }

class _StepCustomersState extends State<StepCustomers> {
  bool _loading = true;
  List<Customer> _library = [];
  int? _selectedIndex;
  bool _showLibraryPanel = true;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.recent;

  // SCAFFOLD PARITY FIX: this widget's own ScaffoldMessenger, so the
  // "Maximum of X customers reached" SnackBar docks above THIS widget's
  // own StepNavBar — now registered as this widget's own nested
  // Scaffold's `bottomNavigationBar` in build() below — instead of
  // resolving to EditorScreen's ambient Scaffold, which has no
  // `bottomNavigationBar` to dock above at all.
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const _accent = Color(0xFF2E7D32);

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

  int _relevance(int i, String q) {
    final c = _library[i];
    final name = c.name.toLowerCase();
    if (name.startsWith(q)) return 0;
    if (name.contains(q)) return 1;
    if (c.email.toLowerCase().contains(q)) return 2;
    if (c.phone.toLowerCase().contains(q)) return 3;
    return 4;
  }

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
          indices = indices.reversed.toList();
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

    // SCAFFOLD PARITY FIX: this widget now returns its OWN
    // ScaffoldMessenger + Scaffold, with the StepNavBar registered as
    // that Scaffold's real `bottomNavigationBar` — instead of being a
    // plain trailing Column child inside EditorScreen's body. This is
    // what actually gives the SnackBar shown via `_messengerKey`
    // something correct to dock above. `backgroundColor:
    // Colors.transparent` keeps this a pure layout/messenger change with
    // no visual difference — EditorScreen's own background still shows
    // through underneath.
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0A1F0A) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? _accent.withValues(alpha: 0.4)
                              : const Color(0xFFA5D6A7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: _accent),
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
                    // SCAFFOLD PARITY FIX: routed through _messengerKey
                    // instead of ScaffoldMessenger.of(context); the
                    // stray `behavior: SnackBarBehavior.floating` here
                    // is dropped for consistency — the SnackBar default
                    // (fixed) now docks above this widget's own
                    // StepNavBar.
                    GestureDetector(
                      onTap: atMax
                          ? () => _messengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text('Maximum of $_kMaxCustomers customers reached.'),
                                ),
                              )
                          : () => _showAddSheet(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: atMax
                              ? (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5))
                              : (isDark ? const Color(0xFF0A1F0A) : const Color(0xFFE8F5E9)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: atMax
                                ? colorScheme.outline.withValues(alpha: 0.3)
                                : (isDark ? _accent.withValues(alpha: 0.5) : const Color(0xFFA5D6A7)),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_add_rounded,
                              color: atMax ? colorScheme.onSurface.withValues(alpha: 0.3) : _accent,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                atMax ? 'Maximum Customers Reached' : 'Add New Customer',
                                style: TextStyle(
                                  color: atMax ? colorScheme.onSurface.withValues(alpha: 0.3) : _accent,
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
            if (!_loading && _library.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark_rounded, size: 16, color: _accent),
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
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                            onTap: () => setState(() => _showLibraryPanel = !_showLibraryPanel),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0A1F0A) : const Color(0xFFE8F5E9),
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
                                    onChanged: (mode) => setState(() => _sortMode = mode),
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
                        onEdit: () => _showAddSheet(existing: _library[i], editIndex: i),
                        onDelete: () => _deleteCustomer(i),
                      );
                    },
                    childCount: visible.length,
                  ),
                ),
              ),
            if (!_loading && _showLibraryPanel && _library.isNotEmpty && visible.isEmpty && isSearching)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  message: 'No customers match your search',
                  sub: 'Try a different name, email, or phone number',
                ),
              ),
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
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
              ),
            // SELECTION STATUS PASS: the box Quote's/Receipt's editor
            // screens add via their own _selectionStatus() wrapper —
            // added here instead since StepCustomers has no outer
            // wrapper of its own. Always shown once loading is done,
            // regardless of whether the library is empty or a search is
            // active, matching Quote's/Receipt's "always visible"
            // placement at the very end of the step.
            if (!_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _SelectionStatus(
                    selected: _selectedIndex != null,
                    label: _selectedIndex != null
                        ? 'Using "${_library[_selectedIndex!].name}" for this invoice.'
                        : 'Select a saved customer, or enter one manually on the next Create Invoice step.',
                    accent: _accent,
                  ),
                ),
              ),
          ],
        ),
        // SCAFFOLD PARITY FIX: this is now the nested Scaffold's real
        // `bottomNavigationBar` — the piece that actually makes the
        // SnackBar shown via `_messengerKey` dock correctly above it,
        // instead of being just another trailing Column child with
        // nothing for a fixed-behavior SnackBar to dock above.
        bottomNavigationBar: SafeArea(
          top: false,
          bottom: true,
          child: StepNavBar(
            onBack: widget.onBack,
            onNext: _saveAndNext,
            nextLabel: 'Continue to Templates',
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SELECTION STATUS PASS: matches Quote's/Receipt's _selectionStatus()
// exactly in shape and styling — a bordered, tinted container with a
// check-circle (selected) or info (unselected) icon and a short label.
// =============================================================================

class _SelectionStatus extends StatelessWidget {
  final bool selected;
  final String label;
  final Color accent;

  const _SelectionStatus({
    required this.selected,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? const Color(0xFF2E7D32) : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(selected ? Icons.check_circle_rounded : Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.35)),
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            suffixIcon: hasText
                ? GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  )
                : null,
            filled: true,
            fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : const Color(0xFFF9F9F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      : (isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : const Color(0xFFF9F9F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? accent : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5)),
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

    final hasLogo = customer.logoPath != null && customer.logoPath!.isNotEmpty && File(customer.logoPath!).existsSync();
    final shape = logoShapeFromString(customer.logoShape);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF0D1F0D) : Colors.white)
            : (isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? _accent.withValues(alpha: isDark ? 0.6 : 0.5) : colorScheme.outline.withValues(alpha: 0.3),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _accent : colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: shape.radiusFor(46),
                  color: hasLogo
                      ? Colors.black
                      : (isSelected
                          ? (isDark ? _accent.withValues(alpha: 0.15) : const Color(0xFFE8F5E9))
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                  border: Border.all(
                    color: isSelected ? _accent.withValues(alpha: 0.4) : colorScheme.outline.withValues(alpha: 0.3),
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
                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? _accent : colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name.isNotEmpty ? customer.name : '(No name)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (customer.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? _accent : colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (customer.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 11, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(width: 3),
                          Text(
                            customer.phone,
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                          ),
                        ],
                      ),
                    ],
                    if (customer.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 11, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              customer.address,
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active for this invoice',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _accent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? _accent.withValues(alpha: 0.12) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_rounded, color: _accent, size: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFEF5350).withValues(alpha: 0.12) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Color(0xFFEF5350), size: 16),
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

  // STRUCTURED ADDRESS WIRING PASS: six-field structured address,
  // replacing the old single `_addressCtrl` TextEditingController. See
  // address_info.dart / shared_address_field_group.dart.
  late AddressFieldControllers _addressControllers;

  // TAX RATE REMOVAL PASS: no longer an editable field on this sheet.
  // Preserved as-is from the existing customer (or 0.0 for a new one)
  // and written straight back in _save().
  late final double _defaultTaxRate;

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
    _addressControllers = AddressFieldControllers.seeded(e?.addressInfo);
    _defaultTaxRate = e?.defaultTaxRate ?? 0.0;
    _logoPath = e?.logoPath;
    _logoOffset = e != null ? Offset(e.logoOffsetDx, e.logoOffsetDy) : Offset.zero;
    _logoScale = e?.logoScale ?? 1.0;
    _logoShape = logoShapeFromString(e?.logoShape ?? 'circle');

    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl]) {
      c.addListener(() => setState(() {}));
    }
    _addressControllers.addListenerToAll(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressControllers.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // STRUCTURED ADDRESS WIRING PASS: `address` is kept in sync as
    // addressInfo.singleLine for anything that still reads the legacy
    // flat string (PDF export, older screens, etc.); `addressInfo` is
    // the new structured value.
    final addressInfo = _addressControllers.toAddressInfo();
    widget.onSaved(Customer(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: addressInfo.singleLine,
      addressInfo: addressInfo,
      logoPath: _logoPath,
      logoOffsetDx: _logoOffset.dx,
      logoOffsetDy: _logoOffset.dy,
      logoScale: _logoScale,
      logoShape: _logoShape.storageName,
      defaultTaxRate: _defaultTaxRate,
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
            decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2)),
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
            color: current > max ? const Color(0xFFF44336) : colorScheme.onSurface.withValues(alpha: 0.35),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0A1F0A) : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _accent.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'Editing',
                                  style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                        _sectionLabel('Customer Details'),
                        // FIELD LENGTH TIGHTENING PASS: max 100 -> 40 —
                        // a wider cap let a customer's name hold enough
                        // text to visibly overexpand the invoice's
                        // "Billed To" block, which renders it with no
                        // truncation of its own.
                        _SheetField(
                          ctrl: _nameCtrl,
                          label: 'Name *',
                          hint: 'e.g. Acme Corp',
                          icon: Icons.person_rounded,
                          max: 40,
                          required: true,
                          accent: _accent,
                        ),
                        _counter(_nameCtrl.text.length, 40),
                        const SizedBox(height: 12),
                        // FIELD LENGTH TIGHTENING PASS: max 100 -> 60.
                        _SheetField(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          hint: 'e.g. billing@acme.com',
                          icon: Icons.email_rounded,
                          max: 60,
                          keyboard: TextInputType.emailAddress,
                          accent: _accent,
                        ),
                        _counter(_emailCtrl.text.length, 60),
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
                        const SizedBox(height: 20),
                        // STRUCTURED ADDRESS WIRING PASS: six-field
                        // structured address replaces the old single
                        // free-text field. See
                        // shared_address_field_group.dart.
                        _sectionLabel('Address'),
                        AddressFieldGroup(
                          controllers: _addressControllers,
                          accent: _accent,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isEditing ? 'Save Changes' : 'Save Customer',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

class _SheetField extends StatefulWidget {
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
  State<_SheetField> createState() => _SheetFieldState();
}

class _SheetFieldState extends State<_SheetField> {
  final FocusNode _focusNode = FocusNode();

  static const _retryDelaysMs = [80, 200, 350, 500];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) return;
    for (final delayMs in _retryDelaysMs) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted || !_focusNode.hasFocus) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.2,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atLimit = widget.max != null && widget.ctrl.text.length >= widget.max!;
    final displayLabel = widget.required ? widget.label : '${widget.label} (Optional)';

    return TextFormField(
      controller: widget.ctrl,
      focusNode: _focusNode,
      keyboardType: widget.keyboard,
      maxLines: widget.maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      inputFormatters: widget.max != null ? [LengthLimitingTextInputFormatter(widget.max!)] : null,
      validator: widget.validator ??
          (widget.required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null),
      decoration: InputDecoration(
        labelText: displayLabel,
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        hintText: widget.hint,
        hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.45))
            : null,
        suffixIcon: atLimit
            ? Tooltip(
                message: 'Character limit reached',
                child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF44336)))
            : null,
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: atLimit ? const Color(0xFFF44336) : colorScheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: atLimit ? const Color(0xFFF44336) : widget.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF44336))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}