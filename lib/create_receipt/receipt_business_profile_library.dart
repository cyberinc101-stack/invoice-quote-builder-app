// lib/create_receipt/receipt_business_profile_library.dart
//
// Saved "business profile" library for the receipt Business step — mirrors
// create_quote_section/quote_business_profile_library.dart's card/sheet
// pattern and invoice_edit_section/step_templates.dart's business-info half.
// Self-contained: no inline business fields remain on the receipt Business
// step. Tap a saved card to select it, or "Add New Business Profile" to
// open the sheet (Save lives at the bottom of the sheet).
//
// UPDATED (this pass): logo picking now uses the shared SharedLogoPicker
// (lib/widgets/shared_logo_picker.dart) instead of this file's own
// ReceiptLogoPicker, so the picker UI/UX is identical across Quote,
// Invoice, and Receipt. ReceiptBusinessProfile gains logoShape ('circle' |
// 'square' | 'roundedSquare') alongside the existing offset/scale fields.
// Saved-card thumbnails use SharedLogoThumbnail so they render the chosen
// shape. receipt_logo_picker.dart is no longer used by this file (left in
// place in case anything else references it — safe to delete otherwise).

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'receipt_edit_widgets.dart';
import '../widgets/shared_logo_picker.dart';

const int _kMaxReceiptBusinessProfiles = 10;
const String _kPrefReceiptBusinessProfileList = 'receipt_business_profile_list_v1';

// =============================================================================
// Model
// =============================================================================

class ReceiptBusinessProfile {
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
  String logoShape; // 'circle' | 'square' | 'roundedSquare'

  ReceiptBusinessProfile({
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
    this.logoShape = 'circle',
  });

  Offset get logoOffset => Offset(logoOffsetDx, logoOffsetDy);
  LogoShape get shape => logoShapeFromString(logoShape);

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
        'logoShape': logoShape,
      };

  factory ReceiptBusinessProfile.fromJson(Map<String, dynamic> j) => ReceiptBusinessProfile(
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
        logoShape: j['logoShape'] as String? ?? 'circle',
      );
}

// =============================================================================
// Persistence
// =============================================================================

Future<void> _persistReceiptBusinessProfiles(List<ReceiptBusinessProfile> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefReceiptBusinessProfileList,
    jsonEncode(list.map((p) => p.toJson()).toList()),
  );
}

Future<List<ReceiptBusinessProfile>> _loadReceiptBusinessProfiles() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefReceiptBusinessProfileList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => ReceiptBusinessProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// ReceiptBusinessProfileLibrarySection
// =============================================================================

class ReceiptBusinessProfileLibrarySection extends StatefulWidget {
  final Color accent;
  final ValueChanged<ReceiptBusinessProfile?> onProfileSelected;

  /// If set (e.g. when editing a saved receipt), tries to pre-select the
  /// matching saved profile once the library loads. Does NOT synthesize a
  /// profile from the receipt's own stored fields if no match is found.
  final String? initialSelectedId;

  const ReceiptBusinessProfileLibrarySection({
    super.key,
    required this.accent,
    required this.onProfileSelected,
    this.initialSelectedId,
  });

  @override
  State<ReceiptBusinessProfileLibrarySection> createState() =>
      _ReceiptBusinessProfileLibrarySectionState();
}

class _ReceiptBusinessProfileLibrarySectionState
    extends State<ReceiptBusinessProfileLibrarySection> {
  bool _loading = true;
  List<ReceiptBusinessProfile> _library = [];
  int? _selectedIndex;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final profiles = await _loadReceiptBusinessProfiles();
    int? selected;
    if (widget.initialSelectedId != null) {
      final idx = profiles.indexWhere((p) => p.id == widget.initialSelectedId);
      if (idx != -1) selected = idx;
    }
    if (!mounted) return;
    setState(() {
      _library = profiles;
      _selectedIndex = selected;
      _loading = false;
    });
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

  void _showAddSheet({ReceiptBusinessProfile? existing, int? editIndex}) {
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
      builder: (_) => _ReceiptBusinessProfileSheet(
        accent: widget.accent,
        existing: existing,
        onSaved: (profile) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = profile);
            if (_selectedIndex == editIndex) widget.onProfileSelected(profile);
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(profile);
              _selectedIndex = newIdx;
              _showPanel = true;
            });
            widget.onProfileSelected(profile);
          }
          _persistReceiptBusinessProfiles(_library);
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
    _persistReceiptBusinessProfiles(_library);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final atMax = _library.length >= _kMaxReceiptBusinessProfiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: receiptSectionHeader(context, 'Saved Business Profiles', accent,
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
                '${_library.length}/$_kMaxReceiptBusinessProfiles',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: atMax ? const Color(0xFFEF5350) : colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
          ],
        ),
        Text(
          'Tap a saved profile to use it for this receipt.',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 10),

        // Add button
        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maximum of $_kMaxReceiptBusinessProfiles saved profiles reached.'),
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
                Icon(Icons.add_business_rounded,
                    color: atMax ? colorScheme.onSurface.withValues(alpha: 0.3) : accent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    atMax ? 'Maximum Profiles Reached' : 'Add New Business Profile',
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
              return _ReceiptBusinessProfileCard(
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

class _ReceiptBusinessProfileCard extends StatelessWidget {
  final ReceiptBusinessProfile profile;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReceiptBusinessProfileCard({
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
    final hasLogo =
        profile.logoPath != null && profile.logoPath!.isNotEmpty && File(profile.logoPath!).existsSync();

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
                  color: isSelected
                      ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: profile.shape.radiusFor(40),
                  border: Border.all(
                    color: isSelected ? accent.withValues(alpha: 0.4) : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? SharedLogoThumbnail(
                        logoPath: profile.logoPath!,
                        logoOffset: profile.logoOffset,
                        logoScale: profile.logoScale,
                        logoShape: profile.shape,
                        boxSize: 40,
                      )
                    : Icon(Icons.storefront_rounded,
                        color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3), size: 18),
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
                        color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (profile.businessName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(profile.businessName,
                          style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w600)),
                    ],
                    if (profile.businessEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(profile.businessEmail,
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

class _ReceiptBusinessProfileSheet extends StatefulWidget {
  final Color accent;
  final ReceiptBusinessProfile? existing;
  final void Function(ReceiptBusinessProfile) onSaved;

  const _ReceiptBusinessProfileSheet({required this.accent, this.existing, required this.onSaved});

  @override
  State<_ReceiptBusinessProfileSheet> createState() => _ReceiptBusinessProfileSheetState();
}

class _ReceiptBusinessProfileSheetState extends State<_ReceiptBusinessProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _profileNameCtrl;
  late TextEditingController _bizNameCtrl;
  late TextEditingController _bizEmailCtrl;
  late TextEditingController _bizPhoneCtrl;
  late TextEditingController _bizAddressCtrl;
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.circle;

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
    _logoShape = e != null ? logoShapeFromString(e.logoShape) : LogoShape.circle;
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
    widget.onSaved(ReceiptBusinessProfile(
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
      logoShape: _logoShape.storageName,
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
                          _isEditing ? 'Edit Business Profile' : 'New Business Profile',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 20),
                        ReceiptField(
                          ctrl: _profileNameCtrl,
                          label: 'Profile Label *',
                          accent: accent,
                          icon: Icons.label_rounded,
                          max: 60,
                          required: true,
                        ),
                        const SizedBox(height: 20),
                        Text('Business Logo (optional)',
                            style:
                                TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                        const SizedBox(height: 10),
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
                        ReceiptField(
                          ctrl: _bizNameCtrl,
                          label: 'Business Name *',
                          accent: accent,
                          icon: Icons.business_rounded,
                          max: 80,
                          required: true,
                        ),
                        const SizedBox(height: 12),
                        ReceiptField(
                          ctrl: _bizEmailCtrl,
                          label: 'Business Email',
                          accent: accent,
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        ReceiptField(
                          ctrl: _bizPhoneCtrl,
                          label: 'Business Phone',
                          accent: accent,
                          icon: Icons.phone_rounded,
                          max: 30,
                          keyboard: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        ReceiptField(
                          ctrl: _bizAddressCtrl,
                          label: 'Business Address',
                          accent: accent,
                          icon: Icons.location_on_rounded,
                          max: 200,
                          maxLines: 2,
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