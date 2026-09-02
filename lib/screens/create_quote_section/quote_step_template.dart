// lib/screens/create_quote_section/quote_step_template.dart
//
// RENAME + LAYOUT PARITY PASS (this update): replaces
// quote_template_library.dart. Renamed to match the invoice flow's file
// naming (step_templates.dart -> quote_step_template.dart) and the
// identical rename already done for quote_step_customer.dart.
// QuoteTemplateLibrarySection is now QuoteStepTemplateSection.
//
// LAYOUT PASS: the section header now matches Invoice's
// step_templates.dart — a "Manage Templates" title + subtitle, an info
// banner ("Save up to N templates..."), and the same "Saved Templates"
// panel treatment (count badge + Hide/Show chip, "Tap a card to select
// it for this quote." helper line) instead of the previous compact
// quoteSectionHeader-only header. Card layout, add/edit sheet, and the
// fallback-mark wiring (already correct here — see
// showInitialFallback/onShowInitialFallbackChanged below) are unchanged.
//
// See create_quote_section/quote_step_customer.dart for the identical
// pass already applied to the Customer step, and
// quote_editor_screen.dart for the updated import/class name.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/quote_data.dart' show defaultQuoteEnabledFields;
import '../../widgets/shared_logo_picker.dart';
import 'quote_edit_widgets.dart';

const int _kMaxQuoteTemplates = 10;
const String _kPrefQuoteTemplateList = 'quote_template_list_v1';

// =============================================================================
// Model
// =============================================================================

class QuoteTemplate {
  final String id;
  String name;
  String businessName;
  String businessEmail;
  String businessPhone;
  String businessAddress;
  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape; // storage name — see LogoShape.storageName
  bool logoShowInitial;
  String logoInitialLetter;

  /// Bare currency code only (e.g. 'USD') — matches InvoiceTemplate's
  /// currency field. Symbol/display-mode are set later on the quote's own
  /// Client & Details step, same split Invoice uses.
  String currency;

  /// Same key set as defaultQuoteEnabledFields() (quote_data.dart).
  /// Not edited from this file's sheet — kept purely for backward
  /// compatibility and as the initial seed the first time this template
  /// is selected.
  Map<String, bool> enabledFields;

  // THANK YOU MESSAGE PASS: the message text itself now lives on the
  // template (previously only a "Thank You Message" toggle existed on
  // the Customise step's Quote Fields list, with no field anywhere to
  // type what it says). Not yet wired into QuoteData.thankYouMessage on
  // template selection — UI/model plumbing only for now.
  String thankYouMessage;

  QuoteTemplate({
    required this.id,
    this.name = '',
    this.businessName = '',
    this.businessEmail = '',
    this.businessPhone = '',
    this.businessAddress = '',
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale = 1.0,
    this.logoShape = 'roundedSquare',
    this.logoShowInitial = true,
    this.logoInitialLetter = '',
    this.currency = 'USD',
    Map<String, bool>? enabledFields,
    this.thankYouMessage = 'Thank you for your business!',
  }) : enabledFields = enabledFields ?? defaultQuoteEnabledFields();

  Offset get logoOffset => Offset(logoOffsetDx, logoOffsetDy);
  LogoShape get shape => logoShapeFromString(logoShape);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'businessName': businessName,
        'businessEmail': businessEmail,
        'businessPhone': businessPhone,
        'businessAddress': businessAddress,
        'logoPath': logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale': logoScale,
        'logoShape': logoShape,
        'logoShowInitial': logoShowInitial,
        'logoInitialLetter': logoInitialLetter,
        'currency': currency,
        'enabledFields': enabledFields,
        'thankYouMessage': thankYouMessage,
      };

  factory QuoteTemplate.fromJson(Map<String, dynamic> j) => QuoteTemplate(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        businessName: j['businessName'] as String? ?? '',
        businessEmail: j['businessEmail'] as String? ?? '',
        businessPhone: j['businessPhone'] as String? ?? '',
        businessAddress: j['businessAddress'] as String? ?? '',
        logoPath: j['logoPath'] as String?,
        logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale: (j['logoScale'] as num?)?.toDouble() ?? 1.0,
        logoShape: j['logoShape'] as String? ?? 'roundedSquare',
        logoShowInitial: j['logoShowInitial'] as bool? ?? true,
        logoInitialLetter: j['logoInitialLetter'] as String? ?? '',
        currency: j['currency'] as String? ?? 'USD',
        enabledFields: (j['enabledFields'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as bool? ?? true),
            ) ??
            defaultQuoteEnabledFields(),
        thankYouMessage: j['thankYouMessage'] as String? ?? 'Thank you for your business!',
      );
}

// =============================================================================
// Persistence
// =============================================================================

Future<void> _persistQuoteTemplates(List<QuoteTemplate> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefQuoteTemplateList,
    jsonEncode(list.map((t) => t.toJson()).toList()),
  );
}

Future<List<QuoteTemplate>> _loadQuoteTemplates() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefQuoteTemplateList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => QuoteTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// QuoteStepTemplateSection
// =============================================================================

class QuoteStepTemplateSection extends StatefulWidget {
  final Color accent;
  final ValueChanged<QuoteTemplate?> onTemplateSelected;

  /// If set and it matches a saved template's id once the library
  /// finishes loading, that template is selected automatically (without
  /// calling [onTemplateSelected]) and reported via
  /// [onInitialSelectionRestored] instead. Used to restore which saved
  /// template a quote was built from when reopening it for edit.
  final String? initialSelectedId;

  /// Called at most once, when [initialSelectedId] matches a saved
  /// template on init. Kept separate from [onTemplateSelected] so
  /// restoring a selection doesn't trigger the same "apply this
  /// template's current business info/logo/fields" cascade a manual tap
  /// does.
  final ValueChanged<QuoteTemplate?>? onInitialSelectionRestored;

  const QuoteStepTemplateSection({
    super.key,
    required this.accent,
    required this.onTemplateSelected,
    this.initialSelectedId,
    this.onInitialSelectionRestored,
  });

  @override
  State<QuoteStepTemplateSection> createState() => _QuoteStepTemplateSectionState();
}

class _QuoteStepTemplateSectionState extends State<QuoteStepTemplateSection> {
  bool _loading = true;
  List<QuoteTemplate> _library = [];
  int? _selectedIndex;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final templates = await _loadQuoteTemplates();
    if (!mounted) return;

    int? restoredIndex;
    if (widget.initialSelectedId != null) {
      final idx = templates.indexWhere((t) => t.id == widget.initialSelectedId);
      if (idx != -1) restoredIndex = idx;
    }

    setState(() {
      _library = templates;
      _loading = false;
      _selectedIndex = restoredIndex;
    });

    if (restoredIndex != null) {
      widget.onInitialSelectionRestored?.call(templates[restoredIndex]);
    }
  }

  void _toggle(int index) {
    if (_selectedIndex == index) {
      setState(() => _selectedIndex = null);
      widget.onTemplateSelected(null);
    } else {
      setState(() => _selectedIndex = index);
      widget.onTemplateSelected(_library[index]);
    }
  }

  void _showAddSheet({QuoteTemplate? existing, int? editIndex}) {
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
      builder: (_) => _QuoteTemplateSheet(
        accent: widget.accent,
        existing: existing,
        onSaved: (template) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = template);
            if (_selectedIndex == editIndex) widget.onTemplateSelected(template);
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(template);
              _selectedIndex = newIdx;
              _showPanel = true;
            });
            widget.onTemplateSelected(template);
          }
          _persistQuoteTemplates(_library);
        },
      ),
    );
  }

  void _duplicate(int index) {
    if (_library.length >= _kMaxQuoteTemplates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum templates reached.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final orig = _library[index];
    final dupe = QuoteTemplate(
      id: const Uuid().v4(),
      name: '${orig.name} (Copy)',
      businessName: orig.businessName,
      businessEmail: orig.businessEmail,
      businessPhone: orig.businessPhone,
      businessAddress: orig.businessAddress,
      logoPath: orig.logoPath,
      logoOffsetDx: orig.logoOffsetDx,
      logoOffsetDy: orig.logoOffsetDy,
      logoScale: orig.logoScale,
      logoShape: orig.logoShape,
      logoShowInitial: orig.logoShowInitial,
      logoInitialLetter: orig.logoInitialLetter,
      currency: orig.currency,
      enabledFields: Map<String, bool>.from(orig.enabledFields),
      thankYouMessage: orig.thankYouMessage,
    );
    setState(() => _library.add(dupe));
    _persistQuoteTemplates(_library);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${orig.name}" duplicated.'), behavior: SnackBarBehavior.floating),
    );
  }

  void _delete(int index) {
    setState(() {
      _library.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
        widget.onTemplateSelected(null);
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _persistQuoteTemplates(_library);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final atMax = _library.length >= _kMaxQuoteTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header (LAYOUT PASS: matches Invoice's "Manage Templates") ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Templates',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and select a quote template',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_library.length}/$_kMaxQuoteTemplates',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: atMax ? const Color(0xFFEF5350) : colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? accent.withValues(alpha: 0.12) : accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: isDark ? 0.4 : 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Save up to $_kMaxQuoteTemplates templates with your business info and select one per quote.',
                  style: TextStyle(fontSize: 11, color: accent),
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
                    SnackBar(content: Text('Maximum of $_kMaxQuoteTemplates templates reached.'), behavior: SnackBarBehavior.floating),
                  )
              : () => _showAddSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                Icon(Icons.add_rounded, color: atMax ? colorScheme.onSurface.withValues(alpha: 0.3) : accent, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    atMax ? 'Maximum Templates Reached' : 'Add New Template',
                    style: TextStyle(
                      color: atMax ? colorScheme.onSurface.withValues(alpha: 0.3) : accent,
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

        if (!_loading && _library.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.bookmark_rounded, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Saved Templates',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _selectedIndex != null ? '1 ✓' : 'none',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _selectedIndex != null ? accent : colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showPanel = !_showPanel),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? 0.14 : 0.08), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_showPanel ? 'Hide' : 'Show', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 2),
                      Icon(_showPanel ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a card to select it for this quote.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
          if (_showPanel) ...[
            const SizedBox(height: 12),
            ...List.generate(_library.length, (displayIdx) {
              final i = _library.length - 1 - displayIdx;
              return _QuoteTemplateCard(
                template: _library[i],
                accent: accent,
                isSelected: _selectedIndex == i,
                onTap: () => _toggle(i),
                onEdit: () => _showAddSheet(existing: _library[i], editIndex: i),
                onDuplicate: () => _duplicate(i),
                onDelete: () => _delete(i),
              );
            }),
          ],
        ] else if (!_loading && _library.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'No templates saved yet — add one to set business info and field visibility for your quotes.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Template card
// =============================================================================

class _QuoteTemplateCard extends StatelessWidget {
  final QuoteTemplate template;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _QuoteTemplateCard({
    required this.template,
    required this.accent,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLogo = template.logoPath != null && template.logoPath!.isNotEmpty && File(template.logoPath!).existsSync();
    final enabledCount = template.enabledFields.values.where((v) => v).length;
    final totalCount = template.enabledFields.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? (isDark ? accent.withValues(alpha: 0.1) : Colors.white) : (isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? accent.withValues(alpha: isDark ? 0.6 : 0.5) : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected ? [BoxShadow(color: accent.withValues(alpha: isDark ? 0.12 : 0.08), blurRadius: 8, offset: const Offset(0, 2))] : [],
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
                width: 22, height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accent : Colors.transparent,
                  border: Border.all(color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3), width: 1.5),
                ),
                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: isDark ? 0.18 : 0.1) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: template.shape.radiusFor(46),
                  border: Border.all(color: isSelected ? accent.withValues(alpha: 0.4) : colorScheme.outline.withValues(alpha: 0.3), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? SharedLogoThumbnail(
                        logoPath: template.logoPath!,
                        logoOffset: template.logoOffset,
                        logoScale: template.logoScale,
                        logoShape: template.shape,
                        boxSize: 46,
                      )
                    : (template.logoShowInitial
                        ? _CardFallbackMark(template: template, accent: accent)
                        : Icon(Icons.storefront_rounded, color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3), size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name.isNotEmpty ? template.name : '(Unnamed template)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                    if (template.businessName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(template.businessName,
                          style: TextStyle(fontSize: 13, color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? accent.withValues(alpha: isDark ? 0.2 : 0.1) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(template.currency,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? accent.withValues(alpha: isDark ? 0.2 : 0.1) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$enabledCount/$totalCount fields',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3))),
                        ),
                      ],
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? 0.18 : 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('Active for this quote', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
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
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? 0.14 : 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.edit_rounded, color: accent, size: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDuplicate,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: isDark ? Colors.orange.withValues(alpha: 0.14) : const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.copy_rounded, color: Colors.orange, size: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: isDark ? const Color(0xFFEF5350).withValues(alpha: 0.12) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
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

class _CardFallbackMark extends StatelessWidget {
  final QuoteTemplate template;
  final Color accent;
  const _CardFallbackMark({required this.template, required this.accent});

  @override
  Widget build(BuildContext context) {
    final letter = template.logoInitialLetter.trim();
    final initial = letter.isNotEmpty
        ? letter[0].toUpperCase()
        : (template.businessName.trim().isNotEmpty ? template.businessName.trim()[0].toUpperCase() : 'B');
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(width: 28, height: 28, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4))),
        ),
        Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

// =============================================================================
// Add / edit sheet
// =============================================================================

class _QuoteTemplateSheet extends StatefulWidget {
  final Color accent;
  final QuoteTemplate? existing;
  final void Function(QuoteTemplate) onSaved;

  const _QuoteTemplateSheet({required this.accent, this.existing, required this.onSaved});

  @override
  State<_QuoteTemplateSheet> createState() => _QuoteTemplateSheetState();
}

class _QuoteTemplateSheetState extends State<_QuoteTemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _bizNameCtrl;
  late TextEditingController _bizEmailCtrl;
  late TextEditingController _bizPhoneCtrl;
  late TextEditingController _bizAddressCtrl;
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  bool _logoShowInitial = true;
  String _logoInitialLetter = '';

  // THANK YOU MESSAGE PASS: the message shown on the generated quote.
  late TextEditingController _thankYouCtrl;

  late Map<String, bool> _enabledFields;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _currencyCtrl = TextEditingController(text: e?.currency ?? 'USD');
    _bizNameCtrl = TextEditingController(text: e?.businessName ?? '');
    _bizEmailCtrl = TextEditingController(text: e?.businessEmail ?? '');
    _bizPhoneCtrl = TextEditingController(text: e?.businessPhone ?? '');
    _bizAddressCtrl = TextEditingController(text: e?.businessAddress ?? '');
    _logoPath = e?.logoPath;
    _logoOffset = e?.logoOffset ?? Offset.zero;
    _logoScale = e?.logoScale ?? 1.0;
    _logoShape = e != null ? logoShapeFromString(e.logoShape) : LogoShape.roundedSquare;
    _logoShowInitial = e?.logoShowInitial ?? true;
    _logoInitialLetter = e?.logoInitialLetter ?? '';
    _enabledFields = e != null ? Map<String, bool>.from(e.enabledFields) : defaultQuoteEnabledFields();
    _thankYouCtrl = TextEditingController(
      text: e?.thankYouMessage ?? 'Thank you for your business!',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currencyCtrl.dispose();
    _bizNameCtrl.dispose();
    _bizEmailCtrl.dispose();
    _bizPhoneCtrl.dispose();
    _bizAddressCtrl.dispose();
    _thankYouCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final typedCurrency = _currencyCtrl.text.trim();
    widget.onSaved(QuoteTemplate(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      currency: typedCurrency.isEmpty ? 'USD' : typedCurrency.toUpperCase(),
      businessName: _bizNameCtrl.text.trim(),
      businessEmail: _bizEmailCtrl.text.trim(),
      businessPhone: _bizPhoneCtrl.text.trim(),
      businessAddress: _bizAddressCtrl.text.trim(),
      logoPath: _logoPath,
      logoOffsetDx: _logoOffset.dx,
      logoOffsetDy: _logoOffset.dy,
      logoScale: _logoScale,
      logoShape: _logoShape.storageName,
      logoShowInitial: _logoShowInitial,
      logoInitialLetter: _logoInitialLetter.trim(),
      enabledFields: _enabledFields,
      thankYouMessage: _thankYouCtrl.text.trim().isEmpty
          ? 'Thank you for your business!'
          : _thankYouCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = kb + 32 + MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, sc) {
        return Container(
          decoration: BoxDecoration(color: colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
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
                        Text(_isEditing ? 'Edit Template' : 'New Template',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                        const SizedBox(height: 20),

                        quoteSectionHeader(context, 'Template Info', widget.accent),
                        QuoteField(
                          ctrl: _nameCtrl,
                          label: 'Template Name *',
                          hint: 'e.g. Standard Quote',
                          icon: Icons.label_rounded,
                          max: 60,
                          required: true,
                          accent: widget.accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _currencyCtrl,
                          label: 'Currency Code',
                          hint: 'e.g. USD',
                          icon: Icons.attach_money_rounded,
                          max: 6,
                          accent: widget.accent,
                        ),
                        const SizedBox(height: 20),

                        quoteSectionHeader(context, 'Business Logo', widget.accent),
                        SharedLogoPicker(
                          logoPath: _logoPath,
                          logoOffset: _logoOffset,
                          logoScale: _logoScale,
                          logoShape: _logoShape,
                          accent: widget.accent,
                          onChanged: (p, o, s, shape) => setState(() {
                            _logoPath = p;
                            _logoOffset = o;
                            _logoScale = s;
                            _logoShape = shape;
                          }),
                          showInitialFallback: _logoShowInitial,
                          onShowInitialFallbackChanged: (v) => setState(() => _logoShowInitial = v),
                          initialLetterOverride: _logoInitialLetter,
                          onInitialLetterOverrideChanged: (v) => setState(() => _logoInitialLetter = v),
                        ),
                        const SizedBox(height: 20),

                        quoteSectionHeader(context, 'Business Information', widget.accent),
                        QuoteField(
                          ctrl: _bizNameCtrl,
                          label: 'Business Name *',
                          hint: 'e.g. Nova Studio Co.',
                          icon: Icons.business_rounded,
                          max: 100,
                          required: true,
                          accent: widget.accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _bizEmailCtrl,
                          label: 'Business Email',
                          hint: 'e.g. hello@novastudio.com',
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                          accent: widget.accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _bizPhoneCtrl,
                          label: 'Business Phone',
                          hint: 'e.g. +1 555 010 2020',
                          icon: Icons.phone_rounded,
                          max: 30,
                          keyboard: TextInputType.phone,
                          accent: widget.accent,
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _bizAddressCtrl,
                          label: 'Business Address',
                          hint: 'e.g. 48 Market Street, Auckland',
                          icon: Icons.location_on_rounded,
                          max: 200,
                          maxLines: 2,
                          accent: widget.accent,
                        ),
                        const SizedBox(height: 20),

                        // THANK YOU MESSAGE PASS: the message shown on
                        // the generated quote when the "Thank You
                        // Message" toggle is on (Customise step). No
                        // field existed anywhere to type this before.
                        quoteSectionHeader(context, 'Thank You Message', widget.accent),
                        QuoteField(
                          ctrl: _thankYouCtrl,
                          label: 'Message',
                          hint: 'e.g. Thank you for your business!',
                          icon: Icons.favorite_border_rounded,
                          max: 150,
                          maxLines: 2,
                          accent: widget.accent,
                        ),
                        const SizedBox(height: 28),

                        // NOTE: the "Quote Fields" / "Client Fields" toggle
                        // switches previously lived here. They now live on
                        // the last step of the quote wizard ("Customise")
                        // in quote_editor_screen.dart as a genuine
                        // per-quote setting — see that file's header
                        // comment.

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(_isEditing ? 'Save Changes' : 'Save Template', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
