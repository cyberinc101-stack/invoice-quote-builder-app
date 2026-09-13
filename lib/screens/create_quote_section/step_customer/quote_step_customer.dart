// lib/screens/create_quote_section/step_customer/quote_step_customer.dart
//
// SAVED-ITEMS CAP PASS (this update): _kMaxQuoteCustomers raised from 12
// to 100, matching the cap already used elsewhere in this app's saved-
// item libraries (quote templates, invoice drafts, quote drafts, etc).
// No other change in this file — filters (search + Recent/A-Z/Z-A sort)
// already existed here from the INVOICE PARITY PASS below and are
// unaffected.
//
// FOLDER MOVE PASS (this update): relocated from
// create_quote_section/quote_step_customer.dart into its own
// create_quote_section/step_customer/ folder — no code changes from
// that move alone, only the relative import paths below shifted one
// level deeper (../../.. instead of ../.., etc). quote_editor_screen.dart's
// import needs updating to
// 'create_quote_section/step_customer/quote_step_customer.dart' to match.
//
// INVOICE PARITY PASS (earlier): brings this step in line with
// Invoice's step_customers.dart in the three places it had drifted:
//
//   1. STRUCTURED ADDRESS — QuoteClient.address was still a single flat
//      string with a plain QuoteField, unlike ClientInfo (Invoice's
//      equivalent model), which has carried a structured six-field
//      AddressInfo (Line 1, Line 2, City, State/Province, Country, ZIP/
//      Postal Code) for a while now. QuoteClient gains `addressInfo`
//      (AddressInfo, see lib/models/address_info.dart) alongside the
//      existing `address` string — `address` is NOT removed, it's kept
//      in sync as addressInfo.singleLine so anything still reading the
//      flat field (saved-card display, PDF export, etc) keeps working
//      unchanged. The sheet's single "Address" QuoteField is replaced
//      with AddressFieldGroup (lib/widgets/shared_address_field_group.dart),
//      the exact same shared six-field widget Invoice's step_customers.dart
//      and step_templates.dart already use — so a quote customer's
//      address will render as a proper multi-line postal block wherever
//      the quote layout eventually adopts AddressInfo.formattedLines, the
//      same way Invoice's already does.
//
//   2. CURRENCY / TAX RATE REMOVED FROM THE SHEET — Invoice removed
//      Default Currency Code/Symbol/Display Format and Default Tax Rate
//      from its customer sheet entirely (see step_customers.dart's own
//      CURRENCY REMOVAL PASS / TAX RATE REMOVAL PASS): setting these
//      per-customer was redundant since currency/tax now live on the
//      template/invoice. QuoteClient's defaultCurrency/
//      defaultCurrencySymbol/defaultCurrencyDisplayMode/defaultTaxRate
//      fields are UNTOUCHED as model fields (still serialized, still
//      read once and written back unchanged for an existing customer
//      being edited) — there's just no longer any way to set/change them
//      from this sheet. _currencyCtrl/_currencySymbolCtrl/
//      _currencyDisplayMode/_taxRateCtrl and the whole
//      _QuoteCustomerCurrencyDisplayModeSelector widget are gone.
//
//   3. FIELD LENGTH TIGHTENING — Name/Email caps lowered from 100/100 to
//      40/60, matching Invoice's identical FIELD LENGTH TIGHTENING PASS
//      (a wider cap let a customer record hold enough text to visibly
//      overexpand the quote's "Billed To" block on the rendered
//      document, which renders Name/Email with no truncation of its
//      own).
//
// autoSave() (QuoteStepCustomerController) keeps its existing `address`
// String parameter for source compatibility with any external caller,
// but now also builds/carries the matching AddressInfo — a legacy flat
// string handed to autoSave lands in AddressInfo.line1 (same convention
// AddressInfo.fromJson already uses for migrating old persisted data),
// with the rest of the six fields left blank for the user to fill in
// later via the full edit sheet if they want the structured version.
//
// Everything else — persistence key/shape, duplicate-detection in
// autoSave, restore-on-edit via initialSelectedId/
// onInitialSelectionRestored, search/sort — is unchanged from the
// previous pass.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../models/address_info.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../../../widgets/shared_address_field_group.dart';
import '../quote_edit_widgets.dart';

// SAVED-ITEMS CAP PASS: raised 12 -> 100.
const int _kMaxQuoteCustomers = 100;
const String _kPrefQuoteCustomerList = 'quote_client_list_v1'; // unchanged key — keeps existing saved data

// =============================================================================
// Model
// =============================================================================

class QuoteClient {
  final String id;
  String name;
  String email;
  String phone;
  String address; // legacy single-line address — kept in sync from
                   // addressInfo.singleLine by whatever saves this record.
  AddressInfo addressInfo;
  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape; // storage name — see LogoShape.storageName

  String defaultCurrency;
  String defaultCurrencySymbol;
  String defaultCurrencyDisplayMode; // 'code' | 'symbol' | 'both'
  double defaultTaxRate;

  QuoteClient({
    required this.id,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    AddressInfo? addressInfo,
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale = 1.0,
    this.logoShape = 'circle',
    this.defaultCurrency = 'USD',
    this.defaultCurrencySymbol = '',
    this.defaultCurrencyDisplayMode = 'code',
    this.defaultTaxRate = 0.0,
  }) : addressInfo = addressInfo ?? AddressInfo();

  Offset get logoOffset => Offset(logoOffsetDx, logoOffsetDy);
  LogoShape get shape => logoShapeFromString(logoShape);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'addressInfo': addressInfo.toJson(),
        'logoPath': logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale': logoScale,
        'logoShape': logoShape,
        'defaultCurrency': defaultCurrency,
        'defaultCurrencySymbol': defaultCurrencySymbol,
        'defaultCurrencyDisplayMode': defaultCurrencyDisplayMode,
        'defaultTaxRate': defaultTaxRate,
      };

  factory QuoteClient.fromJson(Map<String, dynamic> j) => QuoteClient(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
        // INVOICE PARITY PASS: falls back to the legacy `address` string
        // when no `addressInfo` key exists yet (every customer saved
        // before this pass) — see AddressInfo.fromJson's own
        // String-input handling.
        addressInfo: AddressInfo.fromJson(j['addressInfo'] ?? j['address']),
        logoPath: j['logoPath'] as String?,
        logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale: (j['logoScale'] as num?)?.toDouble() ?? 1.0,
        logoShape: j['logoShape'] as String? ?? 'circle',
        defaultCurrency: j['defaultCurrency'] as String? ?? 'USD',
        defaultCurrencySymbol: j['defaultCurrencySymbol'] as String? ?? '',
        defaultCurrencyDisplayMode:
            j['defaultCurrencyDisplayMode'] as String? ?? 'code',
        defaultTaxRate: (j['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      );
}

// =============================================================================
// Persistence
// =============================================================================

Future<void> _persistQuoteCustomers(List<QuoteClient> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefQuoteCustomerList,
    jsonEncode(list.map((c) => c.toJson()).toList()),
  );
}

Future<List<QuoteClient>> _loadQuoteCustomers() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefQuoteCustomerList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => QuoteClient.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// Controller — lets the parent screen trigger a save/update of the library
// from outside (e.g. when the user taps "Next"), mirroring
// QuoteBusinessProfileLibraryController.
// =============================================================================

class QuoteStepCustomerController {
  _QuoteStepCustomerSectionState? _state;

  void _attach(_QuoteStepCustomerSectionState state) => _state = state;
  void _detach(_QuoteStepCustomerSectionState state) {
    if (identical(_state, state)) _state = null;
  }

  /// - If a saved card is currently selected, updates it in place with the
  ///   latest field values.
  /// - Else if an identical entry already exists, just selects it (avoids
  ///   duplicates if Next is pressed twice without changes).
  /// - Else creates a new saved customer (respecting the max-count cap).
  /// No-ops if [name] is blank — nothing meaningful to save.
  ///
  /// INVOICE PARITY PASS: [address] is still a plain String for source
  /// compatibility with any external caller — internally it's now
  /// migrated into AddressInfo.line1 (same convention
  /// AddressInfo.fromJson uses for legacy data) so every QuoteClient this
  /// produces carries a structured address too, even though this entry
  /// point has no six-field UI of its own. A caller that wants the full
  /// structured address should use the "Add New Customer" sheet instead,
  /// which now has AddressFieldGroup.
  Future<void> autoSave({
    required String name,
    String email = '',
    String phone = '',
    String address = '',
    String? logoPath,
    Offset logoOffset = Offset.zero,
    double logoScale = 1.0,
    LogoShape logoShape = LogoShape.circle,
  }) {
    return _state?._autoSave(
          name: name,
          email: email,
          phone: phone,
          address: address,
          logoPath: logoPath,
          logoOffset: logoOffset,
          logoScale: logoScale,
          logoShape: logoShape,
        ) ??
        Future.value();
  }
}

// =============================================================================
// QuoteStepCustomerSection
// =============================================================================

class QuoteStepCustomerSection extends StatefulWidget {
  final Color accent;
  final ValueChanged<QuoteClient?> onClientSelected;
  final QuoteStepCustomerController? controller;

  /// If set and it matches a saved customer's id once the library
  /// finishes loading, that card is shown selected and
  /// [onInitialSelectionRestored] (not [onClientSelected]) is called once
  /// with the matched QuoteClient. Used to restore which saved customer a
  /// quote was built for when reopening it for edit.
  final String? initialSelectedId;

  /// Called at most once, when [initialSelectedId] matches a saved entry
  /// on init. Kept separate from [onClientSelected] so restoring a
  /// selection doesn't trigger the same "seed the title from this
  /// customer's current name" behaviour a manual tap does.
  final ValueChanged<QuoteClient?>? onInitialSelectionRestored;

  const QuoteStepCustomerSection({
    super.key,
    required this.accent,
    required this.onClientSelected,
    this.controller,
    this.initialSelectedId,
    this.onInitialSelectionRestored,
  });

  @override
  State<QuoteStepCustomerSection> createState() =>
      _QuoteStepCustomerSectionState();
}

// Sort modes for the saved-customer list (used when there's no active search).
enum _SortMode { recent, nameAsc, nameDesc }

class _QuoteStepCustomerSectionState extends State<QuoteStepCustomerSection> {
  bool _loading = true;
  List<QuoteClient> _library = [];
  int? _selectedIndex;
  bool _showPanel = true;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.recent;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
    _init();
  }

  @override
  void didUpdateWidget(covariant QuoteStepCustomerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final customers = await _loadQuoteCustomers();
    if (!mounted) return;

    int? restoredIndex;
    if (widget.initialSelectedId != null) {
      final idx = customers.indexWhere((c) => c.id == widget.initialSelectedId);
      if (idx != -1) restoredIndex = idx;
    }

    setState(() {
      _library = customers;
      _loading = false;
      _selectedIndex = restoredIndex;
    });

    if (restoredIndex != null) {
      widget.onInitialSelectionRestored?.call(customers[restoredIndex]);
    }
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

  // Real _library indices for what's currently displayed — same
  // relevance-vs-sort behaviour as Invoice's step_customers.dart.
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

  // INVOICE PARITY PASS: builds a fallback AddressInfo from the flat
  // `address` string (into line1) when autoSave is called with no
  // structured address of its own to carry — mirrors
  // AddressInfo.fromJson's legacy-string migration convention.
  AddressInfo _fallbackAddressInfo(String address) =>
      address.trim().isEmpty ? AddressInfo() : AddressInfo(line1: address.trim());

  Future<void> _autoSave({
    required String name,
    required String email,
    required String phone,
    required String address,
    String? logoPath,
    Offset logoOffset = Offset.zero,
    double logoScale = 1.0,
    LogoShape logoShape = LogoShape.circle,
  }) async {
    if (name.trim().isEmpty) return;

    if (_selectedIndex != null) {
      final existing = _library[_selectedIndex!];
      // Only rebuild addressInfo from the flat string when it actually
      // changed — otherwise keep whatever structured address the person
      // may have already entered via the full edit sheet, rather than
      // collapsing it back down to a single line1 on every autosave.
      final addressChanged = address.trim() != existing.address.trim();
      final updated = QuoteClient(
        id: existing.id,
        name: name,
        email: email,
        phone: phone,
        address: address,
        addressInfo: addressChanged ? _fallbackAddressInfo(address) : existing.addressInfo,
        logoPath: logoPath ?? existing.logoPath,
        logoOffsetDx: logoPath != null ? logoOffset.dx : existing.logoOffsetDx,
        logoOffsetDy: logoPath != null ? logoOffset.dy : existing.logoOffsetDy,
        logoScale: logoPath != null ? logoScale : existing.logoScale,
        logoShape: logoPath != null ? logoShape.storageName : existing.logoShape,
        defaultCurrency: existing.defaultCurrency,
        defaultCurrencySymbol: existing.defaultCurrencySymbol,
        defaultCurrencyDisplayMode: existing.defaultCurrencyDisplayMode,
        defaultTaxRate: existing.defaultTaxRate,
      );
      setState(() => _library[_selectedIndex!] = updated);
      widget.onClientSelected(updated);
      await _persistQuoteCustomers(_library);
      return;
    }

    final dupeIdx = _library.indexWhere((c) =>
        c.name == name && c.email == email && c.phone == phone && c.address == address);
    if (dupeIdx != -1) {
      setState(() => _selectedIndex = dupeIdx);
      widget.onClientSelected(_library[dupeIdx]);
      return;
    }

    if (_library.length >= _kMaxQuoteCustomers) return;

    final client = QuoteClient(
      id: const Uuid().v4(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      addressInfo: _fallbackAddressInfo(address),
      logoPath: logoPath,
      logoOffsetDx: logoOffset.dx,
      logoOffsetDy: logoOffset.dy,
      logoScale: logoScale,
      logoShape: logoShape.storageName,
    );
    setState(() {
      _library.add(client);
      _selectedIndex = _library.length - 1;
      _showPanel = true;
    });
    widget.onClientSelected(client);
    await _persistQuoteCustomers(_library);
  }

  void _toggle(int index) {
    if (_selectedIndex == index) {
      setState(() => _selectedIndex = null);
      widget.onClientSelected(null);
    } else {
      setState(() => _selectedIndex = index);
      widget.onClientSelected(_library[index]);
    }
  }

  void _showAddSheet({QuoteClient? existing, int? editIndex}) {
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
      builder: (_) => _QuoteCustomerSheet(
        accent: widget.accent,
        existing: existing,
        onSaved: (client) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = client);
            if (_selectedIndex == editIndex) {
              widget.onClientSelected(client);
            }
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(client);
              _selectedIndex = newIdx;
              _showPanel = true;
            });
            widget.onClientSelected(client);
          }
          _persistQuoteCustomers(_library);
        },
      ),
    );
  }

  void _delete(int index) {
    setState(() {
      _library.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
        widget.onClientSelected(null);
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _persistQuoteCustomers(_library);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final atMax = _library.length >= _kMaxQuoteCustomers;
    final visible = _visibleIndices;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: quoteSectionHeader(context, 'Manage Customers', accent,
                  icon: Icons.person_rounded),
            ),
            if (_loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            else
              Text(
                '${_library.length}/$_kMaxQuoteCustomers',
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
        Text(
          'Add and select a customer for this quote.',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 10),

        // Add button
        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maximum of $_kMaxQuoteCustomers customers reached.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  )
              : () => _showAddSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: atMax
                  ? (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5))
                  : accent.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: atMax ? colorScheme.outline.withValues(alpha: 0.3) : accent.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_rounded,
                    color: atMax ? colorScheme.onSurface.withValues(alpha: 0.3) : accent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    atMax ? 'Maximum Customers Reached' : 'Add New Customer',
                    style: TextStyle(
                      color: atMax ? colorScheme.onSurface.withValues(alpha: 0.3) : accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

        if (!_loading && _library.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showPanel = !_showPanel),
                  child: Row(
                    children: [
                      Text(
                        'Saved Customers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showPanel = !_showPanel),
                child: Row(
                  children: [
                    Text(
                      _showPanel ? 'Hide' : 'Show',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                    ),
                    Icon(
                      _showPanel ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a card to select it for this quote.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),

          if (_showPanel) ...[
            const SizedBox(height: 12),
            _CustomerSearchField(
              controller: _searchCtrl,
              accent: accent,
              onClear: () => _searchCtrl.clear(),
            ),
            const SizedBox(height: 10),
            IgnorePointer(
              ignoring: isSearching,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSearching ? 0.35 : 1.0,
                child: _SortSelector(
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
            const SizedBox(height: 12),

            if (visible.isNotEmpty)
              ...visible.map((i) => _QuoteCustomerCard(
                    customer: _library[i],
                    accent: accent,
                    isSelected: _selectedIndex == i,
                    onTap: () => _toggle(i),
                    onEdit: () => _showAddSheet(existing: _library[i], editIndex: i),
                    onDelete: () => _delete(i),
                  ))
            else if (isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No customers match your search',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                ),
              ),
          ],
        ] else if (!_loading && _library.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'No customers saved yet — tap above to add your first customer.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
        ],
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
// Sort selector (segmented chips) for the saved-customer list.
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
// Customer card
// =============================================================================

class _QuoteCustomerCard extends StatelessWidget {
  final QuoteClient customer;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuoteCustomerCard({
    required this.customer,
    required this.accent,
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
    final shape = customer.shape;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? accent.withValues(alpha: 0.1) : Colors.white)
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                    : null,
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
                          ? accent.withValues(alpha: isDark ? 0.15 : 0.1)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                  border: Border.all(
                    color: isSelected ? accent.withValues(alpha: 0.4) : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? SharedLogoThumbnail(
                        logoPath: customer.logoPath!,
                        logoOffset: customer.logoOffset,
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
                            color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3),
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
                          color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3),
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
                          Text(customer.phone,
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45))),
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
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active for this quote',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
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
                        color: accent.withValues(alpha: isDark ? 0.14 : 0.1),
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

// =============================================================================
// Add / edit sheet
//
// INVOICE PARITY PASS: single flat Address field replaced with
// AddressFieldGroup (six fields); Currency Code/Symbol/Display Format and
// Default Tax Rate inputs removed entirely — see the file header comment
// for full rationale. Name/Email caps tightened 100/100 -> 40/60.
// =============================================================================

class _QuoteCustomerSheet extends StatefulWidget {
  final Color accent;
  final QuoteClient? existing;
  final void Function(QuoteClient) onSaved;

  const _QuoteCustomerSheet({required this.accent, this.existing, required this.onSaved});

  @override
  State<_QuoteCustomerSheet> createState() => _QuoteCustomerSheetState();
}

class _QuoteCustomerSheetState extends State<_QuoteCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  // INVOICE PARITY PASS: six-field structured address, replacing the old
  // single `_addressCtrl` TextEditingController. See
  // address_info.dart / shared_address_field_group.dart.
  late AddressFieldControllers _addressControllers;

  // INVOICE PARITY PASS: Currency Code/Symbol/Display Format and Default
  // Tax Rate are no longer editable on this sheet — preserved as-is from
  // the existing customer (or the constructor defaults for a new one)
  // and written straight back unchanged in _save().
  late final String _defaultCurrency;
  late final String _defaultCurrencySymbol;
  late final String _defaultCurrencyDisplayMode;
  late final double _defaultTaxRate;

  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.circle;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressControllers = AddressFieldControllers.seeded(e?.addressInfo);
    _defaultCurrency = e?.defaultCurrency ?? 'USD';
    _defaultCurrencySymbol = e?.defaultCurrencySymbol ?? '';
    _defaultCurrencyDisplayMode = e?.defaultCurrencyDisplayMode ?? 'code';
    _defaultTaxRate = e?.defaultTaxRate ?? 0.0;
    _logoPath = e?.logoPath;
    _logoOffset = e?.logoOffset ?? Offset.zero;
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
    // INVOICE PARITY PASS: `address` is kept in sync as
    // addressInfo.singleLine for anything that still reads the legacy
    // flat string (saved-card display, PDF export, etc); `addressInfo`
    // is the new structured value.
    final addressInfo = _addressControllers.toAddressInfo();
    widget.onSaved(QuoteClient(
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
      defaultCurrency: _defaultCurrency,
      defaultCurrencySymbol: _defaultCurrencySymbol,
      defaultCurrencyDisplayMode: _defaultCurrencyDisplayMode,
      defaultTaxRate: _defaultTaxRate,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.accent;
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                              ),
                            ),
                            if (_isEditing)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                                ),
                                child: Text('Editing',
                                    style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Logo section ──────────────────────────────────
                        quoteSectionHeader(context, 'Customer Logo', accent),
                        SharedLogoPicker(
                          logoPath: _logoPath,
                          logoOffset: _logoOffset,
                          logoScale: _logoScale,
                          logoShape: _logoShape,
                          accent: accent,
                          onChanged: (p, o, s, shape) => setState(() {
                            _logoPath = p;
                            _logoOffset = o;
                            _logoScale = s;
                            _logoShape = shape;
                          }),
                        ),
                        const SizedBox(height: 20),

                        quoteSectionHeader(context, 'Customer Details', accent),
                        // FIELD LENGTH TIGHTENING PASS: 100 -> 40 —
                        // matches Invoice's step_customers.dart; a wider
                        // cap let a customer's name hold enough text to
                        // visibly overexpand the quote's "Billed To"
                        // block, which renders it with no truncation of
                        // its own.
                        QuoteField(
                          ctrl: _nameCtrl,
                          label: 'Name *',
                          hint: 'e.g. Acme Corp',
                          icon: Icons.person_rounded,
                          max: 40,
                          required: true,
                          accent: accent,
                        ),
                        const SizedBox(height: 12),
                        // FIELD LENGTH TIGHTENING PASS: 100 -> 60.
                        QuoteField(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          hint: 'e.g. billing@acme.com',
                          icon: Icons.email_rounded,
                          max: 60,
                          keyboard: TextInputType.emailAddress,
                          accent: accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _phoneCtrl,
                          label: 'Phone',
                          hint: 'e.g. +1 555 123 4567',
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                          accent: accent,
                        ),
                        const SizedBox(height: 20),

                        // INVOICE PARITY PASS: six-field structured
                        // address replaces the old single free-text
                        // field. See shared_address_field_group.dart.
                        quoteSectionHeader(context, 'Address', accent),
                        AddressFieldGroup(
                          controllers: _addressControllers,
                          accent: accent,
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
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
