// lib/create_receipt/receipt_client_library.dart
//
// Saved "client" library for the receipt Client & Details step — same UX as
// invoice_edit_section/step_customers/step_customers.dart (tap a saved card
// to reuse a client's details instead of retyping them) and
// create_quote_section/quote_client_library.dart, kept self-contained per
// the receipt flow's existing convention (no dependency on invoice or quote
// files). No inline client fields remain on the receipt Client & Details
// step — only this saved-list section + "Add New Client" opening the sheet.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'receipt_edit_widgets.dart';

const int _kMaxReceiptClients = 12;
const String _kPrefReceiptClientList = 'receipt_client_list_v1';

// =============================================================================
// Model
// =============================================================================

class ReceiptClient {
  final String id;
  String name;
  String email;
  String phone;
  String address;

  String defaultCurrency;
  double defaultTaxRate;

  ReceiptClient({
    required this.id,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.defaultCurrency = 'USD',
    this.defaultTaxRate = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'defaultCurrency': defaultCurrency,
        'defaultTaxRate': defaultTaxRate,
      };

  factory ReceiptClient.fromJson(Map<String, dynamic> j) => ReceiptClient(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
        defaultCurrency: j['defaultCurrency'] as String? ?? 'USD',
        defaultTaxRate: (j['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      );
}

// =============================================================================
// Persistence
// =============================================================================

Future<void> _persistReceiptClients(List<ReceiptClient> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefReceiptClientList,
    jsonEncode(list.map((c) => c.toJson()).toList()),
  );
}

Future<List<ReceiptClient>> _loadReceiptClients() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefReceiptClientList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => ReceiptClient.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// ReceiptClientLibrarySection
// =============================================================================

class ReceiptClientLibrarySection extends StatefulWidget {
  final Color accent;
  final ValueChanged<ReceiptClient?> onClientSelected;

  /// If set (e.g. when editing a saved receipt), tries to pre-select the
  /// matching saved client once the library loads.
  final String? initialSelectedId;

  const ReceiptClientLibrarySection({
    super.key,
    required this.accent,
    required this.onClientSelected,
    this.initialSelectedId,
  });

  @override
  State<ReceiptClientLibrarySection> createState() => _ReceiptClientLibrarySectionState();
}

class _ReceiptClientLibrarySectionState extends State<ReceiptClientLibrarySection> {
  bool _loading = true;
  List<ReceiptClient> _library = [];
  int? _selectedIndex;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final clients = await _loadReceiptClients();
    int? selected;
    if (widget.initialSelectedId != null) {
      final idx = clients.indexWhere((c) => c.id == widget.initialSelectedId);
      if (idx != -1) selected = idx;
    }
    if (!mounted) return;
    setState(() {
      _library = clients;
      _selectedIndex = selected;
      _loading = false;
    });
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

  void _showAddSheet({ReceiptClient? existing, int? editIndex}) {
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
      builder: (_) => _ReceiptClientSheet(
        accent: widget.accent,
        existing: existing,
        onSaved: (client) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = client);
            if (_selectedIndex == editIndex) widget.onClientSelected(client);
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(client);
              _selectedIndex = newIdx;
              _showPanel = true;
            });
            widget.onClientSelected(client);
          }
          _persistReceiptClients(_library);
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
    _persistReceiptClients(_library);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final atMax = _library.length >= _kMaxReceiptClients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: receiptSectionHeader(context, 'Saved Clients', accent, icon: Icons.people_alt_rounded),
            ),
            if (_loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            else
              Text(
                '${_library.length}/$_kMaxReceiptClients',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: atMax ? const Color(0xFFEF5350) : colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
          ],
        ),
        Text(
          'Tap a saved client to use them for this receipt.',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 10),

        // Add button
        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maximum of $_kMaxReceiptClients saved clients reached.'),
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
                    atMax ? 'Maximum Clients Reached' : 'Add New Client',
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
          GestureDetector(
            onTap: () => setState(() => _showPanel = !_showPanel),
            child: Row(
              children: [
                Text(
                  _showPanel ? 'Hide saved clients' : 'Show saved clients (${_library.length})',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                ),
                const SizedBox(width: 2),
                Icon(
                  _showPanel ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: accent,
                ),
              ],
            ),
          ),
          if (_showPanel) ...[
            const SizedBox(height: 8),
            ...List.generate(_library.length, (displayIdx) {
              final i = _library.length - 1 - displayIdx;
              return _ReceiptClientCard(
                client: _library[i],
                accent: accent,
                isSelected: _selectedIndex == i,
                onTap: () => _toggle(i),
                onEdit: () => _showAddSheet(existing: _library[i], editIndex: i),
                onDelete: () => _delete(i),
              );
            }),
          ],
        ],
      ],
    );
  }
}

// =============================================================================
// Client card
// =============================================================================

class _ReceiptClientCard extends StatelessWidget {
  final ReceiptClient client;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReceiptClientCard({
    required this.client,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? accent.withValues(alpha: 0.1) : Colors.white)
            : (isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? accent.withValues(alpha: isDark ? 0.6 : 0.5) : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: accent.withValues(alpha: isDark ? 0.12 : 0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null,
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border.all(
                    color: isSelected ? accent.withValues(alpha: 0.4) : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name.isNotEmpty ? client.name : '(No name)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (client.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(client.email,
                          style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w600)),
                    ],
                    if (client.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(client.phone,
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45))),
                    ],
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Active for this receipt',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
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
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.14 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_rounded, color: accent, size: 14),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFEF5350).withValues(alpha: 0.12) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Color(0xFFEF5350), size: 14),
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
// =============================================================================

class _ReceiptClientSheet extends StatefulWidget {
  final Color accent;
  final ReceiptClient? existing;
  final void Function(ReceiptClient) onSaved;

  const _ReceiptClientSheet({required this.accent, this.existing, required this.onSaved});

  @override
  State<_ReceiptClientSheet> createState() => _ReceiptClientSheetState();
}

class _ReceiptClientSheetState extends State<_ReceiptClientSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _taxRateCtrl;

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
    _taxRateCtrl = TextEditingController(text: (e == null || e.defaultTaxRate == 0.0) ? '' : e.defaultTaxRate.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currencyCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSaved(ReceiptClient(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      defaultCurrency: _currencyCtrl.text.trim().isEmpty ? 'USD' : _currencyCtrl.text.trim().toUpperCase(),
      defaultTaxRate: double.tryParse(_taxRateCtrl.text.trim()) ?? 0.0,
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
      initialChildSize: 0.75,
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
                    decoration:
                        BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
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
                        Text(
                          _isEditing ? 'Edit Client' : 'New Client',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 20),
                        ReceiptField(
                          ctrl: _nameCtrl,
                          label: 'Client Name *',
                          accent: accent,
                          icon: Icons.person_rounded,
                          max: 100,
                          required: true,
                        ),
                        const SizedBox(height: 12),
                        ReceiptField(
                          ctrl: _emailCtrl,
                          label: 'Client Email',
                          accent: accent,
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        ReceiptField(
                          ctrl: _phoneCtrl,
                          label: 'Client Phone',
                          accent: accent,
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        ReceiptField(
                          ctrl: _addressCtrl,
                          label: 'Client Address',
                          accent: accent,
                          icon: Icons.location_on_rounded,
                          max: 200,
                          maxLines: 2,
                        ),
                        ReceiptField(
                          ctrl: _currencyCtrl,
                          label: 'Default Currency',
                          accent: accent,
                          icon: Icons.attach_money_rounded,
                          max: 3,
                        ),
                        const SizedBox(height: 12),
                        ReceiptField(
                          ctrl: _taxRateCtrl,
                          label: 'Default Tax Rate (%)',
                          accent: accent,
                          icon: Icons.percent_rounded,
                          max: 6,
                          keyboard: TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 12),
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
                              _isEditing ? 'Save Changes' : 'Save Client',
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
