// lib/screens/create_quote_section/quote_business_profile_library.dart
//
// Saved "business profile" library for the quote flow — mirrors
// invoice_create_section/step_templates.dart's business-info half (not the
// invoice-field toggles, which don't apply to quotes). Self-contained, same
// convention as quote_client_library.dart.
//
// UPDATED (this pass): added QuoteBusinessProfileLibraryController, which
// lets QuoteEditorScreen trigger a save/update of the library from outside
// (e.g. when the user taps "Next") using whatever is currently typed into
// the manual fields, without this section exposing its private state.
//
// UPDATED (this pass, 2): QuoteBusinessProfile now also stores the logo's
// reposition/zoom crop (logoOffsetDx/Dy, logoScale) alongside logoPath, so
// a saved profile's logo reopens exactly as it was left — matching
// QuoteLogoPicker's new reposition feature in quote_edit_widgets.dart.
//
// UPDATED (this pass, 3): button label changed from "Save New Business
// Profile" to "Add New Business Profile" to match the invoice app's
// "Add New Customer" wording — QuoteEditorScreen no longer shows inline
// business fields on the page, so this button (which opens the add/edit
// bottom sheet) is now the only way to enter business info, same as the
// invoice flow's customer step.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'quote_edit_widgets.dart';

const int _kMaxQuoteBusinessProfiles = 10;
const String _kPrefQuoteBusinessProfileList = 'quote_business_profile_list_v1';

// =============================================================================
// Model
// =============================================================================

class QuoteBusinessProfile {
  final String id;
  String profileName;
  String businessName;
  String businessEmail;
  String businessPhone;
  String businessAddress;
  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;

  QuoteBusinessProfile({
    required this.id,
    this.profileName = '',
    this.businessName = '',
    this.businessEmail = '',
    this.businessPhone = '',
    this.businessAddress = '',
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale = 1.0,
  });

  Offset get logoOffset => Offset(logoOffsetDx, logoOffsetDy);

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileName': profileName,
        'businessName': businessName,
        'businessEmail': businessEmail,
        'businessPhone': businessPhone,
        'businessAddress': businessAddress,
        'logoPath': logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale': logoScale,
      };

  factory QuoteBusinessProfile.fromJson(Map<String, dynamic> j) => QuoteBusinessProfile(
        id: j['id'] as String,
        profileName: j['profileName'] as String? ?? '',
        businessName: j['businessName'] as String? ?? '',
        businessEmail: j['businessEmail'] as String? ?? '',
        businessPhone: j['businessPhone'] as String? ?? '',
        businessAddress: j['businessAddress'] as String? ?? '',
        logoPath: j['logoPath'] as String?,
        logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale: (j['logoScale'] as num?)?.toDouble() ?? 1.0,
      );
}

// =============================================================================
// Persistence
// =============================================================================

Future<void> _persistQuoteBusinessProfiles(List<QuoteBusinessProfile> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefQuoteBusinessProfileList,
    jsonEncode(list.map((p) => p.toJson()).toList()),
  );
}

Future<List<QuoteBusinessProfile>> _loadQuoteBusinessProfiles() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefQuoteBusinessProfileList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => QuoteBusinessProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// Controller — lets the parent screen trigger a save/update of the library
// from outside (e.g. when the user taps "Next"), using whatever is
// currently typed into the manual fields below the section, without the
// parent needing to know about the section's internal selection state.
// =============================================================================

class QuoteBusinessProfileLibraryController {
  _QuoteBusinessProfileLibrarySectionState? _state;

  void _attach(_QuoteBusinessProfileLibrarySectionState state) => _state = state;
  void _detach(_QuoteBusinessProfileLibrarySectionState state) {
    if (identical(_state, state)) _state = null;
  }

  /// - If a saved card is currently selected, updates it in place with the
  ///   latest field values.
  /// - Else if an identical entry already exists, just selects it (avoids
  ///   duplicates if Next is pressed twice without changes).
  /// - Else creates a new saved profile (respecting the max-count cap).
  /// No-ops if [businessName] is blank — nothing meaningful to save.
  Future<void> autoSave({
    required String businessName,
    String businessEmail = '',
    String businessPhone = '',
    String businessAddress = '',
    String? logoPath,
    Offset logoOffset = Offset.zero,
    double logoScale = 1.0,
  }) {
    return _state?._autoSave(
          businessName: businessName,
          businessEmail: businessEmail,
          businessPhone: businessPhone,
          businessAddress: businessAddress,
          logoPath: logoPath,
          logoOffset: logoOffset,
          logoScale: logoScale,
        ) ??
        Future.value();
  }
}

// =============================================================================
// QuoteBusinessProfileLibrarySection
// =============================================================================

class QuoteBusinessProfileLibrarySection extends StatefulWidget {
  final Color accent;
  final ValueChanged<QuoteBusinessProfile?> onProfileSelected;
  final QuoteBusinessProfileLibraryController? controller;

  const QuoteBusinessProfileLibrarySection({
    super.key,
    required this.accent,
    required this.onProfileSelected,
    this.controller,
  });

  @override
  State<QuoteBusinessProfileLibrarySection> createState() =>
      _QuoteBusinessProfileLibrarySectionState();
}

class _QuoteBusinessProfileLibrarySectionState
    extends State<QuoteBusinessProfileLibrarySection> {
  bool _loading = true;
  List<QuoteBusinessProfile> _library = [];
  int? _selectedIndex;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _init();
  }

  @override
  void didUpdateWidget(covariant QuoteBusinessProfileLibrarySection oldWidget) {
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
    final profiles = await _loadQuoteBusinessProfiles();
    if (!mounted) return;
    setState(() {
      _library = profiles;
      _loading = false;
    });
  }

  Future<void> _autoSave({
    required String businessName,
    required String businessEmail,
    required String businessPhone,
    required String businessAddress,
    String? logoPath,
    Offset logoOffset = Offset.zero,
    double logoScale = 1.0,
  }) async {
    if (businessName.trim().isEmpty) return;

    // A card is selected — update it in place.
    if (_selectedIndex != null) {
      final existing = _library[_selectedIndex!];
      final updated = QuoteBusinessProfile(
        id: existing.id,
        profileName:
            existing.profileName.isNotEmpty ? existing.profileName : businessName,
        businessName: businessName,
        businessEmail: businessEmail,
        businessPhone: businessPhone,
        businessAddress: businessAddress,
        logoPath: logoPath,
        logoOffsetDx: logoOffset.dx,
        logoOffsetDy: logoOffset.dy,
        logoScale: logoScale,
      );
      setState(() => _library[_selectedIndex!] = updated);
      widget.onProfileSelected(updated);
      await _persistQuoteBusinessProfiles(_library);
      return;
    }

    // No card selected — don't create a duplicate if an identical entry
    // already exists.
    final dupeIdx = _library.indexWhere((p) =>
        p.businessName == businessName &&
        p.businessEmail == businessEmail &&
        p.businessPhone == businessPhone &&
        p.businessAddress == businessAddress);
    if (dupeIdx != -1) {
      setState(() => _selectedIndex = dupeIdx);
      widget.onProfileSelected(_library[dupeIdx]);
      return;
    }

    if (_library.length >= _kMaxQuoteBusinessProfiles) return;

    final profile = QuoteBusinessProfile(
      id: const Uuid().v4(),
      profileName: businessName,
      businessName: businessName,
      businessEmail: businessEmail,
      businessPhone: businessPhone,
      businessAddress: businessAddress,
      logoPath: logoPath,
      logoOffsetDx: logoOffset.dx,
      logoOffsetDy: logoOffset.dy,
      logoScale: logoScale,
    );
    setState(() {
      _library.add(profile);
      _selectedIndex = _library.length - 1;
      _showPanel = true;
    });
    widget.onProfileSelected(profile);
    await _persistQuoteBusinessProfiles(_library);
  }

  void _toggle(int index) {
    if (_selectedIndex == index) {
      setState(() => _selectedIndex = null);
      widget.onProfileSelected(null);
    } else {
      setState(() => _selectedIndex = index);
      widget.onProfileSelected(_library[index]);
    }
  }

  void _showAddSheet({QuoteBusinessProfile? existing, int? editIndex}) {
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
      builder: (_) => _QuoteBusinessProfileSheet(
        accent: widget.accent,
        existing: existing,
        onSaved: (profile) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = profile);
            if (_selectedIndex == editIndex) {
              widget.onProfileSelected(profile);
            }
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(profile);
              _selectedIndex = newIdx;
              _showPanel = true;
            });
            widget.onProfileSelected(profile);
          }
          _persistQuoteBusinessProfiles(_library);
        },
      ),
    );
  }

  void _delete(int index) {
    setState(() {
      _library.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
        widget.onProfileSelected(null);
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _persistQuoteBusinessProfiles(_library);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final atMax = _library.length >= _kMaxQuoteBusinessProfiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: quoteSectionHeader(context, 'Saved Business Profiles', accent,
                  icon: Icons.storefront_rounded),
            ),
            if (_loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            else
              Text(
                '${_library.length}/$_kMaxQuoteBusinessProfiles',
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
          'Tap a saved profile to use it for this quote.',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.45)),
        ),
        const SizedBox(height: 10),

        // Add button
        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maximum of $_kMaxQuoteBusinessProfiles saved profiles reached.'),
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
                Icon(Icons.add_business_rounded,
                    color: atMax ? colorScheme.onSurface.withOpacity(0.3) : accent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    atMax ? 'Maximum Profiles Reached' : 'Add New Business Profile',
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
                  _showPanel ? 'Hide saved profiles' : 'Show saved profiles (${_library.length})',
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
              return _QuoteBusinessProfileCard(
                profile: _library[i],
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
// Profile card
// =============================================================================

class _QuoteBusinessProfileCard extends StatelessWidget {
  final QuoteBusinessProfile profile;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuoteBusinessProfileCard({
    required this.profile,
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

    final hasLogo = profile.logoPath != null &&
        profile.logoPath!.isNotEmpty &&
        File(profile.logoPath!).existsSync();

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
                  color: isSelected
                      ? accent.withOpacity(isDark ? 0.18 : 0.1)
                      : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  border: Border.all(
                    color: isSelected ? accent.withOpacity(0.4) : colorScheme.outline.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? _CardLogo(profile: profile)
                    : Icon(Icons.storefront_rounded,
                        color: isSelected ? accent : colorScheme.onSurface.withOpacity(0.3), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.profileName.isNotEmpty ? profile.profileName : '(Unnamed profile)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    if (profile.businessName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.businessName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? accent : colorScheme.onSurface.withOpacity(0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (profile.businessEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(profile.businessEmail,
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

/// Renders a saved logo in a small card thumbnail, honoring the saved
/// reposition/zoom crop so the thumbnail matches what the user framed in
/// the picker instead of always defaulting to a plain centred cover-fit.
class _CardLogo extends StatelessWidget {
  final QuoteBusinessProfile profile;
  const _CardLogo({required this.profile});

  @override
  Widget build(BuildContext context) {
    const double boxSize = 40.0;
    const double overScale = 1.35;
    final maxTravel = (boxSize * overScale * profile.logoScale - boxSize) / 2;
    final pixelOffset = Offset(
      profile.logoOffset.dx * maxTravel,
      profile.logoOffset.dy * maxTravel,
    );
    return OverflowBox(
      alignment: Alignment.center,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.translate(
        offset: pixelOffset,
        child: Image.file(
          File(profile.logoPath!),
          fit: BoxFit.cover,
          width: boxSize * overScale * profile.logoScale,
          height: boxSize * overScale * profile.logoScale,
        ),
      ),
    );
  }
}

// =============================================================================
// Add / edit sheet
// =============================================================================

class _QuoteBusinessProfileSheet extends StatefulWidget {
  final Color accent;
  final QuoteBusinessProfile? existing;
  final void Function(QuoteBusinessProfile) onSaved;

  const _QuoteBusinessProfileSheet({required this.accent, this.existing, required this.onSaved});

  @override
  State<_QuoteBusinessProfileSheet> createState() => _QuoteBusinessProfileSheetState();
}

class _QuoteBusinessProfileSheetState extends State<_QuoteBusinessProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _profileNameCtrl;
  late TextEditingController _bizNameCtrl;
  late TextEditingController _bizEmailCtrl;
  late TextEditingController _bizPhoneCtrl;
  late TextEditingController _bizAddressCtrl;
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _profileNameCtrl = TextEditingController(text: e?.profileName ?? '');
    _bizNameCtrl = TextEditingController(text: e?.businessName ?? '');
    _bizEmailCtrl = TextEditingController(text: e?.businessEmail ?? '');
    _bizPhoneCtrl = TextEditingController(text: e?.businessPhone ?? '');
    _bizAddressCtrl = TextEditingController(text: e?.businessAddress ?? '');
    _logoPath = e?.logoPath;
    _logoOffset = e?.logoOffset ?? Offset.zero;
    _logoScale = e?.logoScale ?? 1.0;
  }

  @override
  void dispose() {
    _profileNameCtrl.dispose();
    _bizNameCtrl.dispose();
    _bizEmailCtrl.dispose();
    _bizPhoneCtrl.dispose();
    _bizAddressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSaved(QuoteBusinessProfile(
      id: widget.existing?.id ?? const Uuid().v4(),
      profileName: _profileNameCtrl.text.trim(),
      businessName: _bizNameCtrl.text.trim(),
      businessEmail: _bizEmailCtrl.text.trim(),
      businessPhone: _bizPhoneCtrl.text.trim(),
      businessAddress: _bizAddressCtrl.text.trim(),
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
                        Text(
                          _isEditing ? 'Edit Business Profile' : 'New Business Profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 20),
                        QuoteField(
                          ctrl: _profileNameCtrl,
                          label: 'Profile Label *',
                          hint: 'e.g. Main Business',
                          icon: Icons.label_rounded,
                          max: 60,
                          required: true,
                          accent: accent,
                        ),
                        const SizedBox(height: 20),
                        Text('Business Logo (optional)',
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
                          ctrl: _bizNameCtrl,
                          label: 'Business Name *',
                          hint: 'e.g. Nova Studio Co.',
                          icon: Icons.business_rounded,
                          max: 80,
                          required: true,
                          accent: accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _bizEmailCtrl,
                          label: 'Business Email',
                          hint: 'e.g. hello@novastudio.com',
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                          accent: accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _bizPhoneCtrl,
                          label: 'Business Phone',
                          hint: 'e.g. +1 555 010 2020',
                          icon: Icons.phone_rounded,
                          max: 30,
                          keyboard: TextInputType.phone,
                          accent: accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _bizAddressCtrl,
                          label: 'Business Address',
                          hint: 'e.g. 48 Market Street, Auckland',
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
                              _isEditing ? 'Save Changes' : 'Save Profile',
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
