// lib/screens/invoice_create_section/step_templates/step_templates.dart
//
// LOGO FALLBACK MARK WIRING PASS (this update): the "show letter mark
// when there's no logo" switch + optional letter override — already
// live on Quote's and (after this same pass) Receipt's template sheets
// via SharedLogoPicker's showInitialFallback/onShowInitialFallbackChanged/
// initialLetterOverride/onInitialLetterOverrideChanged params — was never
// wired up here, so it silently never rendered on the invoice Template
// sheet even though BusinessInfo now carries logoShowInitial/
// logoInitialLetter (see client_info.dart's LOGO FALLBACK MARK PASS).
// _TemplateSheetState gained _logoShowInitial/_logoInitialLetter state,
// seeded from the existing template on edit, passed through to
// SharedLogoPicker, and saved back onto BusinessInfo in _save().
// _TemplateCard also gained the same no-logo fallback mark rendering
// Quote's/Receipt's saved-template cards already have (a rotated-square
// initial mark instead of a bare description icon), respecting
// logoShowInitial/logoInitialLetter.
//
// COUNTERS + OPTIONAL LABELS PASS (earlier): every capped text field
// in the New/Edit Template sheet shows a live "X / max" character
// counter underneath it. _SheetField also auto-appends "(Optional)" to
// a field's label whenever `required` is false.
//
// FIELD VISIBILITY RELOCATION PASS (earlier update): the "Invoice Fields" /
// "Customer Fields" toggle switches have been removed from this sheet
// entirely. Field visibility is now a genuine per-invoice setting,
// controlled from step_customise.dart's _FieldVisibilitySection.
//
// CURRENCY DISPLAY PASS (earlier update): Currency field is a plain
// free-text Currency Code field (no hardcoded currency list).
//
// UPDATED (earlier pass): Business Logo picking uses SharedLogoPicker
// (lib/widgets/shared_logo_picker.dart), so Reposition/Zoom/Shape are
// available here the same as the Customer step and the receipt/quote
// business profiles.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../models/invoice_models.dart';
import '../../../models/invoice_data.dart' show defaultInvoiceEnabledFields;
import '../../../services/storage_service.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../invoice_edit_widgets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kMaxTemplates = 10;
const _kPrefTemplateList = 'invoice_template_list_v2';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------
Future<void> _persistTemplates(List<InvoiceTemplate> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefTemplateList,
    jsonEncode(list.map((t) => t.toJson()).toList()),
  );
}

Future<List<InvoiceTemplate>> _loadTemplates() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefTemplateList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => InvoiceTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// StepTemplates
// =============================================================================

class StepTemplates extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final InvoiceTemplate? selectedTemplate;
  final ValueChanged<InvoiceTemplate?> onTemplateChanged;

  const StepTemplates({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.selectedTemplate,
    required this.onTemplateChanged,
  });

  @override
  State<StepTemplates> createState() => _StepTemplatesState();
}

class _StepTemplatesState extends State<StepTemplates> {
  bool _loading = true;
  List<InvoiceTemplate> _library = [];
  int? _selectedIndex;
  bool _showLibraryPanel = true;

  static const _accent = Color(0xFF1565C0); // blue accent for templates

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final templates = await _loadTemplates();
    int? selected;
    if (widget.selectedTemplate != null) {
      final idx =
          templates.indexWhere((t) => t.id == widget.selectedTemplate!.id);
      if (idx != -1) selected = idx;
    }
    if (!mounted) return;
    setState(() {
      _library = templates;
      _selectedIndex = selected;
      _loading = false;
    });
  }

  void _toggleTemplate(int index) {
    if (_selectedIndex == index) {
      setState(() => _selectedIndex = null);
      widget.onTemplateChanged(null);
    } else {
      setState(() => _selectedIndex = index);
      widget.onTemplateChanged(_library[index]);
    }
  }

  void _showAddSheet({InvoiceTemplate? existing, int? editIndex}) {
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
      builder: (_) => _TemplateSheet(
        existing: existing,
        onSaved: (template) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = template);
            if (_selectedIndex == editIndex) {
              widget.onTemplateChanged(template);
            }
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(template);
              _selectedIndex = newIdx;
              _showLibraryPanel = true;
            });
            widget.onTemplateChanged(template);
          }
          _persistTemplates(_library);
        },
      ),
    );
  }

  void _duplicateTemplate(int index) {
    if (_library.length >= _kMaxTemplates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum templates reached.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final orig = _library[index];
    final dupe = InvoiceTemplate(
      id: const Uuid().v4(),
      name: '${orig.name} (Copy)',
      businessInfo: BusinessInfo(
        name: orig.businessInfo.name,
        email: orig.businessInfo.email,
        phone: orig.businessInfo.phone,
        address: orig.businessInfo.address,
        taxId: orig.businessInfo.taxId,
        gstNumber: orig.businessInfo.gstNumber,
        website: orig.businessInfo.website,
        logoPath: orig.businessInfo.logoPath,
        logoOffsetDx: orig.businessInfo.logoOffsetDx,
        logoOffsetDy: orig.businessInfo.logoOffsetDy,
        logoScale: orig.businessInfo.logoScale,
        logoShape: orig.businessInfo.logoShape,
        logoShowInitial: orig.businessInfo.logoShowInitial,
        logoInitialLetter: orig.businessInfo.logoInitialLetter,
        senderName: orig.businessInfo.senderName,
        senderEmail: orig.businessInfo.senderEmail,
        senderPhone: orig.businessInfo.senderPhone,
        senderPosition: orig.businessInfo.senderPosition,
        senderAddress: orig.businessInfo.senderAddress,
        senderWebsite: orig.businessInfo.senderWebsite,
      ),
      currency: orig.currency,
      enabledFields: Map<String, bool>.from(orig.enabledFields),
      thankYouMessage: orig.thankYouMessage,
    );
    setState(() {
      _library.add(dupe);
    });
    _persistTemplates(_library);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${orig.name}" duplicated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteTemplate(int index) {
    setState(() {
      _library.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
        widget.onTemplateChanged(null);
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _persistTemplates(_library);
  }

  void _saveAndNext() {
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atMax = _library.length >= _kMaxTemplates;

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
                                  'Manage Templates',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create and select an invoice template',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        colorScheme.onSurface.withValues(alpha: 0.45),
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
                                    color: colorScheme.primary),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${_library.length}/$_kMaxTemplates',
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
                              ? const Color(0xFF0D1B2E)
                              : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? _accent.withValues(alpha: 0.4)
                                : const Color(0xFF90CAF9),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: _accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Save up to $_kMaxTemplates templates with your business info and select one per invoice.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF64B5F6)
                                      : const Color(0xFF1565C0),
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
                                        'Maximum of $_kMaxTemplates templates reached.'),
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
                                    ? const Color(0xFF0D1B2E)
                                    : const Color(0xFFE3F2FD)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: atMax
                                  ? colorScheme.outline.withValues(alpha: 0.3)
                                  : (isDark
                                      ? _accent.withValues(alpha: 0.5)
                                      : const Color(0xFF90CAF9)),
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
                                    : _accent,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  atMax
                                      ? 'Maximum Templates Reached'
                                      : 'Add New Template',
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
                                'Saved Templates',
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
                                      ? const Color(0xFF0D1B2E)
                                      : const Color(0xFFE3F2FD),
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
                      ],
                    ),
                  ),
                ),

              // ── Template cards ───────────────────────────────────────────
              if (!_loading && _showLibraryPanel && _library.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, displayIdx) {
                        final i = _library.length - 1 - displayIdx;
                        return _TemplateCard(
                          template: _library[i],
                          isSelected: _selectedIndex == i,
                          onTap: () => _toggleTemplate(i),
                          onEdit: () => _showAddSheet(
                              existing: _library[i], editIndex: i),
                          onDuplicate: () => _duplicateTemplate(i),
                          onDelete: () => _deleteTemplate(i),
                        );
                      },
                      childCount: _library.length,
                    ),
                  ),
                ),

              // ── Empty state ──────────────────────────────────────────────
              if (!_loading && _library.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.description_outlined,
                    message: 'No templates saved yet',
                    sub: 'Tap above to create your first invoice template',
                  ),
                ),

              if (_loading)
                SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: colorScheme.primary)),
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
            nextLabel: 'Continue to Invoice',
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Template Card
// =============================================================================

class _TemplateCard extends StatelessWidget {
  final InvoiceTemplate template;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  static const _accent = Color(0xFF1565C0);

  const _TemplateCard({
    required this.template,
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
    final hasLogo = template.businessInfo.logoPath != null &&
        template.businessInfo.logoPath!.isNotEmpty &&
        File(template.businessInfo.logoPath!).existsSync();
    final shape = logoShapeFromString(template.businessInfo.logoShape);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF0D1B2E) : Colors.white)
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

              // Logo / fallback mark
              // LOGO FALLBACK MARK WIRING PASS: when there's no logo, show
              // the same rotated-square initial mark Quote's/Receipt's
              // saved-template cards use (or nothing but a plain icon if
              // logoShowInitial is off), instead of always falling back to
              // a bare description icon regardless of that setting.
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: shape.radiusFor(46),
                  color: isSelected
                      ? (isDark
                          ? _accent.withValues(alpha: 0.15)
                          : const Color(0xFFE3F2FD))
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                        logoPath: template.businessInfo.logoPath!,
                        logoOffset: Offset(
                          template.businessInfo.logoOffsetDx,
                          template.businessInfo.logoOffsetDy,
                        ),
                        logoScale: template.businessInfo.logoScale,
                        logoShape: shape,
                        boxSize: 46,
                      )
                    : (template.businessInfo.logoShowInitial
                        ? _CardFallbackMark(template: template, accent: _accent)
                        : Icon(
                            Icons.description_rounded,
                            color: isSelected
                                ? _accent
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
                      template.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (template.businessInfo.name.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        template.businessInfo.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? _accent
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (template.businessInfo.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        template.businessInfo.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Currency badge — free-text code only. Previously
                    // prefixed with CurrencyHelper.getSymbol(), which is
                    // backed by the same fixed currency list the dropdown
                    // used; since the code can now be anything, the badge
                    // just shows the code as typed.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _accent.withValues(alpha: isDark ? 0.2 : 0.1)
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        template.currency,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? _accent
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
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

              // Action buttons (edit, duplicate, delete)
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
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: _accent, size: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDuplicate,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.withValues(alpha: 0.12)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          color: Colors.orange, size: 16),
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
// _CardFallbackMark — rotated-square initial mark shown when no logo is
// set and logoShowInitial is on. Mirrors Quote's/Receipt's
// _CardFallbackMark exactly, adapted to InvoiceTemplate's businessInfo
// nesting.
// =============================================================================

class _CardFallbackMark extends StatelessWidget {
  final InvoiceTemplate template;
  final Color accent;
  const _CardFallbackMark({required this.template, required this.accent});

  @override
  Widget build(BuildContext context) {
    final letter = template.businessInfo.logoInitialLetter.trim();
    final initial = letter.isNotEmpty
        ? letter[0].toUpperCase()
        : (template.businessInfo.name.trim().isNotEmpty
            ? template.businessInfo.name.trim()[0].toUpperCase()
            : 'B');
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

// =============================================================================
// Bottom Sheet – create / edit a template
// =============================================================================

class _TemplateSheet extends StatefulWidget {
  final InvoiceTemplate? existing;
  final void Function(InvoiceTemplate) onSaved;

  const _TemplateSheet({this.existing, required this.onSaved});

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  final _formKey = GlobalKey<FormState>();

  // Template meta
  late TextEditingController _nameCtrl;

  // Currency — free-text code, no hardcoded currency list. InvoiceTemplate
  // only stores a single currency code string (no symbol/display-mode —
  // those are set later on the actual invoice create step), so this is
  // just a plain text field rather than the Code/Symbol/Both selector
  // used on the invoice/quote/receipt create steps.
  late TextEditingController _currencyCtrl;

  // Business info
  late TextEditingController _bizNameCtrl;
  late TextEditingController _bizEmailCtrl;
  late TextEditingController _bizPhoneCtrl;
  late TextEditingController _bizAddressCtrl;
  late TextEditingController _bizTaxIdCtrl;
  late TextEditingController _bizGstCtrl;
  late TextEditingController _bizWebsiteCtrl;
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.circle;

  // LOGO FALLBACK MARK WIRING PASS: "show letter mark when there's no
  // logo" switch + optional letter override, now actually passed to
  // SharedLogoPicker below (was previously declared nowhere on this
  // sheet at all).
  bool _logoShowInitial = true;
  String _logoInitialLetter = '';

  // THANK YOU MESSAGE PASS: the message shown on the generated invoice.
  late TextEditingController _thankYouCtrl;

  // Sender info
  late TextEditingController _senderNameCtrl;
  late TextEditingController _senderPositionCtrl;
  late TextEditingController _senderEmailCtrl;
  late TextEditingController _senderPhoneCtrl;
  late TextEditingController _senderAddressCtrl;
  late TextEditingController _senderWebsiteCtrl;

  // FIELD VISIBILITY RELOCATION PASS: no longer editable from this sheet
  // (see file header). Carried through unedited to the saved
  // InvoiceTemplate purely for backward compatibility — a new template
  // gets defaultInvoiceEnabledFields()'s all-true default, an edited
  // template keeps whatever was already saved on it.
  late Map<String, bool> _enabledFields;

  static const _accent = Color(0xFF1565C0);
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _currencyCtrl = TextEditingController(text: e?.currency ?? 'USD');

    final b = e?.businessInfo ?? BusinessInfo();
    _bizNameCtrl = TextEditingController(text: b.name);
    _bizEmailCtrl = TextEditingController(text: b.email);
    _bizPhoneCtrl = TextEditingController(text: b.phone);
    _bizAddressCtrl = TextEditingController(text: b.address);
    _bizTaxIdCtrl = TextEditingController(text: b.taxId);
    _bizGstCtrl = TextEditingController(text: b.gstNumber ?? '');
    _bizWebsiteCtrl = TextEditingController(text: b.website ?? '');
    _logoPath = b.logoPath;
    _logoOffset = Offset(b.logoOffsetDx, b.logoOffsetDy);
    _logoScale = b.logoScale;
    _logoShape = logoShapeFromString(b.logoShape);
    _logoShowInitial = b.logoShowInitial;
    _logoInitialLetter = b.logoInitialLetter;

    _senderNameCtrl = TextEditingController(text: b.senderName ?? '');
    _senderPositionCtrl = TextEditingController(text: b.senderPosition ?? '');
    _senderEmailCtrl = TextEditingController(text: b.senderEmail ?? '');
    _senderPhoneCtrl = TextEditingController(text: b.senderPhone ?? '');
    _senderAddressCtrl = TextEditingController(text: b.senderAddress ?? '');
    _senderWebsiteCtrl = TextEditingController(text: b.senderWebsite ?? '');

    _thankYouCtrl = TextEditingController(
      text: e?.thankYouMessage ?? 'Thank you for your business!',
    );

    _enabledFields = e?.enabledFields != null
        ? Map<String, bool>.from(e!.enabledFields)
        : defaultInvoiceEnabledFields();

    // Live counter listeners — every capped text field rebuilds on change
    // so its "X / max" counter (rendered via _counter() next to each
    // field below) stays in sync as the person types. One loop covers
    // every controller instead of a one-off listener per field.
    for (final c in [
      _nameCtrl, _currencyCtrl, _bizNameCtrl, _bizEmailCtrl, _bizPhoneCtrl,
      _bizAddressCtrl, _bizTaxIdCtrl, _bizGstCtrl, _bizWebsiteCtrl,
      _senderNameCtrl, _senderPositionCtrl, _senderEmailCtrl,
      _senderPhoneCtrl, _senderAddressCtrl, _senderWebsiteCtrl,
      _thankYouCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _currencyCtrl, _bizNameCtrl, _bizEmailCtrl, _bizPhoneCtrl,
      _bizAddressCtrl, _bizTaxIdCtrl, _bizGstCtrl, _bizWebsiteCtrl,
      _senderNameCtrl, _senderPositionCtrl, _senderEmailCtrl,
      _senderPhoneCtrl, _senderAddressCtrl, _senderWebsiteCtrl,
      _thankYouCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final typedCurrency = _currencyCtrl.text.trim();
    widget.onSaved(InvoiceTemplate(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      currency: typedCurrency.isEmpty ? 'USD' : typedCurrency.toUpperCase(),
      enabledFields: _enabledFields,
      thankYouMessage: _thankYouCtrl.text.trim().isEmpty
          ? 'Thank you for your business!'
          : _thankYouCtrl.text.trim(),
      businessInfo: BusinessInfo(
        name: _bizNameCtrl.text.trim(),
        email: _bizEmailCtrl.text.trim(),
        phone: _bizPhoneCtrl.text.trim(),
        address: _bizAddressCtrl.text.trim(),
        taxId: _bizTaxIdCtrl.text.trim(),
        gstNumber: _bizGstCtrl.text.trim().isEmpty
            ? null
            : _bizGstCtrl.text.trim(),
        website: _bizWebsiteCtrl.text.trim().isEmpty
            ? null
            : _bizWebsiteCtrl.text.trim(),
        logoPath: _logoPath,
        logoOffsetDx: _logoOffset.dx,
        logoOffsetDy: _logoOffset.dy,
        logoScale: _logoScale,
        logoShape: _logoShape.storageName,
        logoShowInitial: _logoShowInitial,
        logoInitialLetter: _logoInitialLetter.trim(),
        senderName: _senderNameCtrl.text.trim().isEmpty
            ? null
            : _senderNameCtrl.text.trim(),
        senderPosition: _senderPositionCtrl.text.trim().isEmpty
            ? null
            : _senderPositionCtrl.text.trim(),
        senderEmail: _senderEmailCtrl.text.trim().isEmpty
            ? null
            : _senderEmailCtrl.text.trim(),
        senderPhone: _senderPhoneCtrl.text.trim().isEmpty
            ? null
            : _senderPhoneCtrl.text.trim(),
        senderAddress: _senderAddressCtrl.text.trim().isEmpty
            ? null
            : _senderAddressCtrl.text.trim(),
        senderWebsite: _senderWebsiteCtrl.text.trim().isEmpty
            ? null
            : _senderWebsiteCtrl.text.trim(),
      ),
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
      initialChildSize: 0.92,
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
                        // Title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isEditing
                                    ? 'Edit Template'
                                    : 'New Template',
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
                                      ? const Color(0xFF0D1B2E)
                                      : const Color(0xFFE3F2FD),
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

                        // ── Template name & currency ───────────────────────
                        _sectionLabel('Template Info'),
                        _SheetField(
                          ctrl: _nameCtrl,
                          label: 'Template Name *',
                          hint: 'e.g. Standard Invoice',
                          icon: Icons.label_rounded,
                          max: 100,
                          required: true,
                          accent: _accent,
                        ),
                        _counter(_nameCtrl.text.length, 100),
                        const SizedBox(height: 12),

                        // Currency — free-text code, no hardcoded currency
                        // list. Matches the free-text pattern already live
                        // on the invoice/quote/receipt create steps; this
                        // template only carries the code itself (symbol +
                        // display mode are chosen later on the invoice
                        // create step).
                        _SheetField(
                          ctrl: _currencyCtrl,
                          label: 'Currency Code',
                          hint: 'e.g. USD',
                          icon: Icons.attach_money_rounded,
                          max: 6,
                          accent: _accent,
                        ),
                        _counter(_currencyCtrl.text.length, 6),
                        const SizedBox(height: 20),

                        // ── Business logo ─────────────────────────────────
                        // LOGO FALLBACK MARK WIRING PASS: showInitialFallback/
                        // onShowInitialFallbackChanged/initialLetterOverride/
                        // onInitialLetterOverrideChanged now passed through —
                        // this is what actually makes the "show letter mark"
                        // switch + letter field render below the picker.
                        _sectionLabel('Business Logo'),
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
                          showInitialFallback: _logoShowInitial,
                          onShowInitialFallbackChanged: (v) =>
                              setState(() => _logoShowInitial = v),
                          initialLetterOverride: _logoInitialLetter,
                          onInitialLetterOverrideChanged: (v) =>
                              setState(() => _logoInitialLetter = v),
                        ),
                        const SizedBox(height: 20),

                        // ── Business info ─────────────────────────────────
                        _sectionLabel('Business Information'),
                        _SheetField(
                          ctrl: _bizNameCtrl,
                          label: 'Business Name *',
                          hint: 'e.g. Acme Solutions Ltd',
                          icon: Icons.business_rounded,
                          max: 100,
                          required: true,
                          accent: _accent,
                        ),
                        _counter(_bizNameCtrl.text.length, 100),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _bizEmailCtrl,
                          label: 'Business Email',
                          hint: 'e.g. hello@acme.com',
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                          accent: _accent,
                        ),
                        _counter(_bizEmailCtrl.text.length, 100),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _bizPhoneCtrl,
                          label: 'Business Phone',
                          hint: 'e.g. +1 555 000 1234',
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                          accent: _accent,
                        ),
                        _counter(_bizPhoneCtrl.text.length, 20),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _bizAddressCtrl,
                          label: 'Business Address',
                          hint: 'e.g. 123 Commerce Ave, NYC',
                          icon: Icons.location_on_rounded,
                          max: 200,
                          maxLines: 2,
                          accent: _accent,
                        ),
                        _counter(_bizAddressCtrl.text.length, 200),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _bizWebsiteCtrl,
                          label: 'Website',
                          hint: 'e.g. acme.com',
                          icon: Icons.language_rounded,
                          max: 100,
                          keyboard: TextInputType.url,
                          accent: _accent,
                        ),
                        _counter(_bizWebsiteCtrl.text.length, 100),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _bizTaxIdCtrl,
                          label: 'Tax ID / EIN',
                          hint: 'e.g. 12-3456789',
                          icon: Icons.receipt_long_rounded,
                          max: 30,
                          accent: _accent,
                        ),
                        _counter(_bizTaxIdCtrl.text.length, 30),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _bizGstCtrl,
                          label: 'GST Number',
                          hint: 'e.g. 123456789',
                          icon: Icons.numbers_rounded,
                          max: 30,
                          accent: _accent,
                        ),
                        _counter(_bizGstCtrl.text.length, 30),
                        const SizedBox(height: 20),

                        // ── Sender info ───────────────────────────────────
                        _sectionLabel('Sender / Contact Person'),
                        _SheetField(
                          ctrl: _senderNameCtrl,
                          label: 'Sender Name',
                          hint: 'e.g. Jane Smith',
                          icon: Icons.person_rounded,
                          max: 50,
                          accent: _accent,
                        ),
                        _counter(_senderNameCtrl.text.length, 50),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _senderPositionCtrl,
                          label: 'Position / Title',
                          hint: 'e.g. Sales Manager',
                          icon: Icons.work_rounded,
                          max: 50,
                          accent: _accent,
                        ),
                        _counter(_senderPositionCtrl.text.length, 50),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _senderEmailCtrl,
                          label: 'Sender Email',
                          hint: 'e.g. jane@acme.com',
                          icon: Icons.email_outlined,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                          accent: _accent,
                        ),
                        _counter(_senderEmailCtrl.text.length, 100),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _senderPhoneCtrl,
                          label: 'Sender Phone',
                          hint: 'e.g. +1 555 999 8888',
                          icon: Icons.phone_outlined,
                          max: 20,
                          keyboard: TextInputType.phone,
                          accent: _accent,
                        ),
                        _counter(_senderPhoneCtrl.text.length, 20),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _senderAddressCtrl,
                          label: 'Sender Address',
                          hint: 'e.g. Suite 4, 123 Commerce Ave',
                          icon: Icons.location_on_outlined,
                          max: 200,
                          maxLines: 2,
                          accent: _accent,
                        ),
                        _counter(_senderAddressCtrl.text.length, 200),
                        const SizedBox(height: 12),
                        _SheetField(
                          ctrl: _senderWebsiteCtrl,
                          label: 'Sender Website',
                          hint: 'e.g. jane.acme.com',
                          icon: Icons.language_outlined,
                          max: 100,
                          keyboard: TextInputType.url,
                          accent: _accent,
                        ),
                        _counter(_senderWebsiteCtrl.text.length, 100),
                        const SizedBox(height: 20),

                        // THANK YOU MESSAGE PASS: the message shown on
                        // the generated invoice when the "Thank You
                        // Message" toggle is on (Customise step). No
                        // field existed anywhere to type this before.
                        _sectionLabel('Thank You Message'),
                        _SheetField(
                          ctrl: _thankYouCtrl,
                          label: 'Message',
                          hint: 'e.g. Thank you for your business!',
                          icon: Icons.favorite_border_rounded,
                          max: 150,
                          maxLines: 2,
                          accent: _accent,
                        ),
                        _counter(_thankYouCtrl.text.length, 150),
                        const SizedBox(height: 28),

                        // NOTE: the "Invoice Fields" / "Customer Fields"
                        // toggle switches previously lived here. They now
                        // live on the Customise step (step_customise.dart)
                        // as a genuine per-invoice setting — see file
                        // header comment above for why.

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
                              _isEditing
                                  ? 'Save Changes'
                                  : 'Save Template',
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
// Reusable text field (shared with customer sheet)
//
// COUNTERS + OPTIONAL LABELS PASS: `required` now also drives the label
// text — non-required fields get "(Optional)" appended automatically
// (see `displayLabel` below), so every call site doesn't need to spell
// it out by hand. Required fields (which already carry their own "*")
// are untouched.
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
    // Required fields keep their label exactly as given (e.g. it already
    // carries a trailing "*"). Optional fields get "(Optional)" appended
    // automatically so every non-mandatory input is labelled as such.
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
