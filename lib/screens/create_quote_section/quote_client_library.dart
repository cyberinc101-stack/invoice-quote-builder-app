// lib/screens/create_quote_section/quote_client_library.dart
//
// Saved-client "library" feature for the quote flow — same UX as
// invoice_create_section/step_customers.dart (tap a saved card to reuse a
// client's details instead of retyping them), but kept self-contained per
// the existing convention in quote_edit_widgets.dart: its own model, its
// own SharedPreferences key, no dependency on invoice models.
//
// Usage: drop QuoteClientLibrarySection into the Client & Details step,
// above the manual fields. Tapping a card calls onClientSelected(client)
// so the caller can copy the data into its own TextEditingControllers —
// this widget does not own those controllers.
//
// UPDATED (this pass): added QuoteClientLibraryController, mirroring
// QuoteBusinessProfileLibraryController — lets QuoteEditorScreen trigger a
// save/update of the client library from outside (e.g. when the user taps
// "Next") using whatever is currently typed into the manual fields.
//
// UPDATED (this pass, 2): QuoteClient now also stores the logo's
// reposition/zoom crop (logoOffsetDx/Dy, logoScale) alongside logoPath,
// matching QuoteLogoPicker's new reposition feature in quote_edit_widgets.dart.
//
// UPDATED (this pass, 3): button label changed from "Save New Client" to
// "Add New Client" to match the invoice app's "Add New Customer" wording —
// QuoteEditorScreen no longer shows inline client fields on the page, so
// this button (which opens the add/edit bottom sheet) is now the only way
// to enter client info, same as the invoice flow's customer step.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'quote_edit_widgets.dart';

const int _kMaxQuoteClients = 12;
const String _kPrefQuoteClientList = 'quote_client_list_v1';

// =============================================================================
// Model
// =============================================================================

class QuoteClient {
  final String id;
  String name;
  String email;
  String phone;
  String address;
  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;

  QuoteClient({
    required this.id,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale = 1.0,
  });

  Offset get logoOffset => Offset(logoOffsetDx, logoOffsetDy);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'logoPath': logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale': logoScale,
      };

  factory QuoteClient.fromJson(Map<String, dynamic> j) => QuoteClient(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
        logoPath: j['logoPath'] as String?,
        logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale: (j['logoScale'] as num?)?.toDouble() ?? 1.0,
      );
}

// =============================================================================
// Persistence
// =============================================================================

Future<void> _persistQuoteClients(List<QuoteClient> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefQuoteClientList,
    jsonEncode(list.map((c) => c.toJson()).toList()),
  );
}

Future<List<QuoteClient>> _loadQuoteClients() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefQuoteClientList);
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

class QuoteClientLibraryController {
  _QuoteClientLibrarySectionState? _state;

  void _attach(_QuoteClientLibrarySectionState state) => _state = state;
  void _detach(_QuoteClientLibrarySectionState state) {
    if (identical(_state, state)) _state = null;
  }

  /// - If a saved card is currently selected, updates it in place with the
  ///   latest field values.
  /// - Else if an identical entry already exists, just selects it (avoids
  ///   duplicates if Next is pressed twice without changes).
  /// - Else creates a new saved client (respecting the max-count cap).
  /// No-ops if [name] is blank — nothing meaningful to save.
  Future<void> autoSave({
    required String name,
    String email = '',
    String phone = '',
    String address = '',
    String? logoPath,
    Offset logoOffset = Offset.zero,
    double logoScale = 1.0,
  }) {
    return _state?._autoSave(
          name: name,
          email: email,
          phone: phone,
          address: address,
          logoPath: logoPath,
          logoOffset: logoOffset,
          logoScale: logoScale,
        ) ??
        Future.value();
  }
}

// =============================================================================
// QuoteClientLibrarySection
// =============================================================================

class QuoteClientLibrarySection extends StatefulWidget {
  final Color accent;
  final ValueChanged<QuoteClient?> onClientSelected;
  final QuoteClientLibraryController? controller;

  const QuoteClientLibrarySection({
    super.key,
    required this.accent,
    required this.onClientSelected,
    this.controller,
  });

  @override
  State<QuoteClientLibrarySection> createState() =>
      _QuoteClientLibrarySectionState();
}

class _QuoteClientLibrarySectionState extends State<QuoteClientLibrarySection> {
  bool _loading = true;
  List<QuoteClient> _library = [];
  int? _selectedIndex;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _init();
  }

  @override
  void didUpdateWidget(covariant QuoteClientLibrarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  Future<void> _init() async {
    final clients = await _loadQuoteClients();
    if (!mounted) return;
    setState(() {
      _library = clients;
      _loading = false;
    });
  }

  Future<void> _autoSave({
    required String name,
    required String email,
    required String phone,
    required String address,
    String? logoPath,
    Offset logoOffset = Offset.zero,
    double logoScale = 1.0,
  }) async {
    if (name.trim().isEmpty) return;

    if (_selectedIndex != null) {
      final existing = _library[_selectedIndex!];
      final updated = QuoteClient(
        id: existing.id,
        name: name,
        email: email,
        phone: phone,
        address: address,
        logoPath: logoPath ?? existing.logoPath,
        logoOffsetDx: logoPath != null ? logoOffset.dx : existing.logoOffsetDx,
        logoOffsetDy: logoPath != null ? logoOffset.dy : existing.logoOffsetDy,
        logoScale: logoPath != null ? logoScale : existing.logoScale,
      );
      setState(() => _library[_selectedIndex!] = updated);
      widget.onClientSelected(updated);
      await _persistQuoteClients(_library);
      return;
    }

    final dupeIdx = _library.indexWhere((c) =>
        c.name == name && c.email == email && c.phone == phone && c.address == address);
    if (dupeIdx != -1) {
      setState(() => _selectedIndex = dupeIdx);
      widget.onClientSelected(_library[dupeIdx]);
      return;
    }

    if (_library.length >= _kMaxQuoteClients) return;

    final client = QuoteClient(
      id: const Uuid().v4(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      logoPath: logoPath,
      logoOffsetDx: logoOffset.dx,
      logoOffsetDy: logoOffset.dy,
      logoScale: logoScale,
    );
    setState(() {
      _library.add(client);
      _selectedIndex = _library.length - 1;
      _showPanel = true;
    });
    widget.onClientSelected(client);
    await _persistQuoteClients(_library);
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
      builder: (_) => _QuoteClientSheet(
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
          _persistQuoteClients(_library);
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
    _persistQuoteClients(_library);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final atMax = _library.length >= _kMaxQuoteClients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: quoteSectionHeader(context, 'Saved Clients', accent,
                  icon: Icons.people_alt_rounded),
            ),
            if (_loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            else
              Text(
                '${_library.length}/$_kMaxQuoteClients',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: atMax
                      ? const Color(0xFFEF5350)
                      : colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
          ],
        ),
        Text(
          'Tap a saved client to use them for this quote.',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.45)),
        ),
        const SizedBox(height: 10),

        // Add button
        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maximum of $_kMaxQuoteClients saved clients reached.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  )
              : () => _showAddSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: atMax
                  ? (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5))
                  : accent.withOpacity(isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: atMax ? colorScheme.outline.withOpacity(0.3) : accent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_rounded,
                    color: atMax ? colorScheme.onSurface.withOpacity(0.3) : accent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    atMax ? 'Maximum Clients Reached' : 'Add New Client',
                    style: TextStyle(
                      color: atMax ? colorScheme.onSurface.withOpacity(0.3) : accent,
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
              return _QuoteClientCard(
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

class _QuoteClientCard extends StatelessWidget {
  final QuoteClient client;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuoteClientCard({
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

    final hasLogo = client.logoPath != null &&
        client.logoPath!.isNotEmpty &&
        File(client.logoPath!).existsSync();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? accent.withOpacity(0.1) : Colors.white)
            : (isDark
                ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? accent.withOpacity(isDark ? 0.6 : 0.5)
              : colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withOpacity(isDark ? 0.12 : 0.08),
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
                    color: isSelected ? accent : colorScheme.onSurface.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasLogo
                      ? Colors.black
                      : (isSelected
                          ? accent.withOpacity(isDark ? 0.18 : 0.1)
                          : colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                  border: Border.all(
                    color: isSelected ? accent.withOpacity(0.4) : colorScheme.outline.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? _CardLogo(client: client)
                    : Center(
                        child: Text(
                          client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? accent : colorScheme.onSurface.withOpacity(0.3),
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
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    if (client.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? accent : colorScheme.onSurface.withOpacity(0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (client.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(client.phone,
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.45))),
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
                        color: accent.withOpacity(isDark ? 0.14 : 0.1),
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
                        color: isDark
                            ? const Color(0xFFEF5350).withOpacity(0.12)
                            : const Color(0xFFFFEBEE),
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

/// Renders a saved client logo honoring its saved reposition/zoom crop —
/// mirrors _CardLogo in quote_business_profile_library.dart.
class _CardLogo extends StatelessWidget {
  final QuoteClient client;
  const _CardLogo({required this.client});

  @override
  Widget build(BuildContext context) {
    const double boxSize = 40.0;
    const double overScale = 1.35;
    final maxTravel = (boxSize * overScale * client.logoScale - boxSize) / 2;
    final pixelOffset = Offset(
      client.logoOffset.dx * maxTravel,
      client.logoOffset.dy * maxTravel,
    );
    return OverflowBox(
      alignment: Alignment.center,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.translate(
        offset: pixelOffset,
        child: Image.file(
          File(client.logoPath!),
          fit: BoxFit.cover,
          width: boxSize * overScale * client.logoScale,
          height: boxSize * overScale * client.logoScale,
        ),
      ),
    );
  }
}

// =============================================================================
// Add / edit sheet
// =============================================================================

class _QuoteClientSheet extends StatefulWidget {
  final Color accent;
  final QuoteClient? existing;
  final void Function(QuoteClient) onSaved;

  const _QuoteClientSheet({required this.accent, this.existing, required this.onSaved});

  @override
  State<_QuoteClientSheet> createState() => _QuoteClientSheetState();
}

class _QuoteClientSheetState extends State<_QuoteClientSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _logoPath = e?.logoPath;
    _logoOffset = e?.logoOffset ?? Offset.zero;
    _logoScale = e?.logoScale ?? 1.0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSaved(QuoteClient(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      logoPath: _logoPath,
      logoOffsetDx: _logoOffset.dx,
      logoOffsetDy: _logoOffset.dy,
      logoScale: _logoScale,
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
                        Text(
                          _isEditing ? 'Edit Client' : 'New Client',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 20),
                        Text('Client Logo (optional)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                        const SizedBox(height: 10),
                        QuoteLogoPicker(
                          logoPath: _logoPath,
                          logoOffset: _logoOffset,
                          logoScale: _logoScale,
                          accent: accent,
                          onChanged: (p, o, s) => setState(() {
                            _logoPath = p;
                            _logoOffset = o;
                            _logoScale = s;
                          }),
                        ),
                        const SizedBox(height: 20),
                        QuoteField(
                          ctrl: _nameCtrl,
                          label: 'Name *',
                          hint: 'e.g. Acme Corp',
                          icon: Icons.person_rounded,
                          max: 100,
                          required: true,
                          accent: accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          hint: 'e.g. billing@acme.com',
                          icon: Icons.email_rounded,
                          max: 100,
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
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _addressCtrl,
                          label: 'Address',
                          hint: 'e.g. 123 Main St, New York, USA',
                          icon: Icons.location_on_rounded,
                          max: 200,
                          maxLines: 2,
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
