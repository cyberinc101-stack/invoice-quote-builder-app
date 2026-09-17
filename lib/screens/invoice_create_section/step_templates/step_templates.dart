// lib/screens/invoice_create_section/step_templates/step_templates.dart
//
// BUSINESS INFO TRIM PASS (this update): the "Business Information"
// section's child Column now collects ONLY Business Name, Tagline, Tax
// ID / EIN, and GST Number — Business Email, Business Phone, the whole
// "Business Address" sub-section, and Website have been removed from
// this UI. The underlying controllers (_bizEmailCtrl, _bizPhoneCtrl,
// _bizAddressControllers, _bizWebsiteCtrl) are UNCHANGED and still
// exist, still get initialized/listened-to/disposed, and are still
// written into the BusinessInfo(...) constructor call in _save() below
// — they'll simply always save as empty, since there's no UI left to
// type into them. This keeps the change surgical (no risk of missing a
// reference elsewhere that reads BusinessInfo.email/phone/address/
// website) while accomplishing the actual ask: Sender / Contact Person
// (already further down this sheet, unchanged) is now the SINGLE place
// that collects address/email/phone — see doc_template_adapter.dart's
// invoiceToAdapter(), which now sources the FROM block's email/phone/
// address from BusinessInfo.senderEmail/senderPhone/senderAddressInfo
// (via InvoiceData.senderEmail/senderPhone/senderAddressInfo — see that
// model and step_create_invoice.dart's sync step) instead of the
// business* fields this pass just stopped collecting.
//
// SECTIONS REMOVAL PASS (earlier): removed the "Business Logo",
// "Header Style", and "Footer Background Image" _CollapsibleGroup
// sections from the template sheet's build() method. The underlying
// state fields (_logoPath/_logoOffset/_logoScale/_logoShape/
// _logoShowInitial/_logoInitialLetter, _headerMode/_headerImagePath,
// _footerBackgroundEnabled/_footerBackgroundImagePath) and the
// BusinessInfo(...) constructor call in _save() are UNCHANGED, so any
// template that already has a saved logo, header image, or footer
// background keeps that data — there just isn't a UI section on this
// sheet to edit it anymore. _TemplateCard's thumbnail (which reads
// logoPath/logoShape) and _duplicateTemplate() are also unaffected.
//
// HEADER STYLE / FOOTER BACKGROUND IMAGE PASS (earlier): added a new
// "Header Style" section (mode selector: Built-in / Full Image / Logo +
// Text, wired to BusinessInfo.headerMode/headerImagePath) right after
// Business Logo, and a new "Footer Background Image" section (toggle +
// image upload, wired to BusinessInfo.footerBackgroundEnabled/
// footerBackgroundImagePath) right after Footer Taglines. Both live in
// the new part file step_templates_header.dart. UI/model plumbing only —
// not yet wired into any renderer or the Customise-step switches, and
// scoped to this (Executive) template sheet only, per plan. Tagline
// itself is UNCHANGED — logoText header mode reuses the existing
// businessInfo.tagline field rather than adding a separate short field.
//
// TAGLINE PASS (earlier): adds a Tagline input field to the
// "Business Information" section, right after Business Name —
// BusinessInfo.tagline itself already exists on the model (see
// client_info.dart), so this pass is UI-only: a new _bizTaglineCtrl
// wired into initState/dispose/the listener-registration loop, a new
// _SheetField for it, and `tagline: _bizTaglineCtrl.text.trim()` added
// to the BusinessInfo(...) constructor call in _save().
//
// (All other header comments from the previous version describe work
// already done and unaffected by this pass — see project history.)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/invoice_models.dart';
import '../../../models/invoice_data.dart' show defaultInvoiceEnabledFields;
import '../../../models/address_info.dart';
import '../../../models/footer_tagline.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../../../widgets/shared_address_field_group.dart';
import '../../../widgets/footer_taglines_editor.dart';
import '../invoice_edit_widgets.dart';

part 'step_templates_payment.dart';
part 'step_templates_terms.dart';
part 'step_templates_signature.dart';
part 'step_templates_header.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kMaxTemplates = 100;
const _kPrefTemplateList = 'invoice_template_list_v2';

const _kSectionExpandedPrefPrefix = 'template_sheet_section_expanded_';

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

// SAVED-ITEMS FILTERS PASS: sort modes for the saved-template list,
// matching Quote's/Receipt's/Customer's own sort modes.
enum _TemplateSortMode { recent, nameAsc, nameDesc }

class _StepTemplatesState extends State<StepTemplates> {
  bool _loading = true;
  List<InvoiceTemplate> _library = [];
  int? _selectedIndex;
  bool _showLibraryPanel = true;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _TemplateSortMode _sortMode = _TemplateSortMode.recent;

  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const _accent = Color(0xFF1565C0); // blue accent for templates

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

  int _relevance(int i, String q) {
    final t = _library[i];
    final name = t.name.toLowerCase();
    final biz = t.businessInfo.name.toLowerCase();
    if (name.startsWith(q)) return 0;
    if (name.contains(q)) return 1;
    if (biz.contains(q)) return 2;
    return 3;
  }

  List<int> get _visibleIndices {
    final q = _searchQuery.trim().toLowerCase();
    var indices = List<int>.generate(_library.length, (i) => i);

    if (q.isEmpty) {
      switch (_sortMode) {
        case _TemplateSortMode.nameAsc:
          indices.sort((a, b) =>
              _library[a].name.toLowerCase().compareTo(_library[b].name.toLowerCase()));
          break;
        case _TemplateSortMode.nameDesc:
          indices.sort((a, b) =>
              _library[b].name.toLowerCase().compareTo(_library[a].name.toLowerCase()));
          break;
        case _TemplateSortMode.recent:
          indices = indices.reversed.toList();
          break;
      }
      return indices;
    }

    indices = indices.where((i) => _relevance(i, q) < 3).toList();
    indices.sort((a, b) {
      final ra = _relevance(a, q);
      final rb = _relevance(b, q);
      if (ra != rb) return ra.compareTo(rb);
      return _library[a].name.toLowerCase().compareTo(_library[b].name.toLowerCase());
    });
    return indices;
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
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Maximum templates reached.'),
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
        tagline: orig.businessInfo.tagline,
        headerMode: orig.businessInfo.headerMode,
        headerImagePath: orig.businessInfo.headerImagePath,
        email: orig.businessInfo.email,
        phone: orig.businessInfo.phone,
        address: orig.businessInfo.address,
        addressInfo: orig.businessInfo.addressInfo,
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
        senderAddressInfo: orig.businessInfo.senderAddressInfo,
        senderWebsite: orig.businessInfo.senderWebsite,
        footerTaglines: orig.businessInfo.footerTaglines.map((t) => t.copyWith()).toList(),
        footerBackgroundEnabled: orig.businessInfo.footerBackgroundEnabled,
        footerBackgroundImagePath: orig.businessInfo.footerBackgroundImagePath,
        bankName: orig.businessInfo.bankName,
        accountName: orig.businessInfo.accountName,
        accountNumber: orig.businessInfo.accountNumber,
        otherPaymentDetails: orig.businessInfo.otherPaymentDetails,
        termsAndConditions: orig.businessInfo.termsAndConditions,
        signatureMode: orig.businessInfo.signatureMode,
        signatureName: orig.businessInfo.signatureName,
        signatureImagePath: orig.businessInfo.signatureImagePath,
      ),
      currency: orig.currency,
      enabledFields: Map<String, bool>.from(orig.enabledFields),
      thankYouMessage: orig.thankYouMessage,
    );
    setState(() {
      _library.add(dupe);
    });
    _persistTemplates(_library);
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('"${orig.name}" duplicated.'),
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
    final visible = _visibleIndices;
    final isSearching = _searchQuery.trim().isNotEmpty;

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

                    GestureDetector(
                      onTap: atMax
                          ? () => _messengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Maximum of $_kMaxTemplates templates reached.'),
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

            if (!_loading && _showLibraryPanel && _library.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TemplateSearchField(
                        controller: _searchCtrl,
                        accent: _accent,
                        onClear: () => _searchCtrl.clear(),
                      ),
                      const SizedBox(height: 10),
                      IgnorePointer(
                        ignoring: isSearching,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isSearching ? 0.35 : 1.0,
                          child: _TemplateSortSelector(
                            value: _sortMode,
                            accent: _accent,
                            onChanged: (mode) =>
                                setState(() => _sortMode = mode),
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
                  ),
                ),
              ),

            if (!_loading && _showLibraryPanel && _library.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, displayIdx) {
                      final i = visible[displayIdx];
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
                    childCount: visible.length,
                  ),
                ),
              ),

            if (!_loading &&
                _showLibraryPanel &&
                _library.isNotEmpty &&
                isSearching &&
                visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    'No templates match your search',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),

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

            if (!_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _SelectionStatus(
                    selected: _selectedIndex != null,
                    label: _selectedIndex != null
                        ? 'Using "${_library[_selectedIndex!].name}" for this invoice.'
                        : 'Select or add a template above to continue.',
                    accent: _accent,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          bottom: true,
          child: StepNavBar(
            onBack: widget.onBack,
            onNext: _saveAndNext,
            nextLabel: 'Continue to Invoice',
          ),
        ),
      ),
    );
  }
}

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

class _TemplateSearchField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final VoidCallback onClear;

  const _TemplateSearchField({
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
            hintText: 'Search saved templates…',
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

class _TemplateSortSelector extends StatelessWidget {
  final _TemplateSortMode value;
  final Color accent;
  final ValueChanged<_TemplateSortMode> onChanged;

  const _TemplateSortSelector({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  static const _options = [
    (_TemplateSortMode.recent, 'Recent', Icons.schedule_rounded),
    (_TemplateSortMode.nameAsc, 'A–Z', Icons.arrow_downward_rounded),
    (_TemplateSortMode.nameDesc, 'Z–A', Icons.arrow_upward_rounded),
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

  late TextEditingController _nameCtrl;

  late final String _currency;

  late TextEditingController _bizNameCtrl;
  late TextEditingController _bizTaglineCtrl;
  late TextEditingController _bizEmailCtrl;
  late TextEditingController _bizPhoneCtrl;

  late AddressFieldControllers _bizAddressControllers;
  List<FooterTaglineItem> _footerTaglines = [];

  // HEADER STYLE / FOOTER BACKGROUND IMAGE PASS: state for the Header
  // Style and Footer Background Image sections. SECTIONS REMOVAL PASS:
  // no longer editable from this sheet's UI, but kept here (and still
  // written into BusinessInfo(...) in _save()) so existing templates
  // don't lose already-saved header/footer-background data.
  String _headerMode = 'built';
  String? _headerImagePath;
  bool _footerBackgroundEnabled = false;
  String? _footerBackgroundImagePath;

  late TextEditingController _bizTaxIdCtrl;
  late TextEditingController _bizGstCtrl;
  late TextEditingController _bizWebsiteCtrl;
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.circle;

  bool _logoShowInitial = true;
  String _logoInitialLetter = '';

  late TextEditingController _thankYouCtrl;

  late TextEditingController _senderNameCtrl;
  late TextEditingController _senderPositionCtrl;
  late TextEditingController _senderEmailCtrl;
  late TextEditingController _senderPhoneCtrl;

  late AddressFieldControllers _senderAddressControllers;

  late TextEditingController _senderWebsiteCtrl;

  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNameCtrl;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _otherPaymentDetailsCtrl;
  late TextEditingController _termsAndConditionsCtrl;
  String _signatureMode = 'blank'; // 'typed' | 'image' | 'blank'
  late TextEditingController _signatureNameCtrl;
  String? _signatureImagePath;

  late Map<String, bool> _enabledFields;

  static const _accent = Color(0xFF1565C0);
  bool get _isEditing => widget.existing != null;

  final ValueNotifier<bool> _businessInfoExpanded = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _currency = e?.currency ?? 'USD';

    final b = e?.businessInfo ?? BusinessInfo();
    _bizNameCtrl = TextEditingController(text: b.name);
    _bizTaglineCtrl = TextEditingController(text: b.tagline);
    _bizEmailCtrl = TextEditingController(text: b.email);
    _bizPhoneCtrl = TextEditingController(text: b.phone);
    _bizAddressControllers = AddressFieldControllers.seeded(b.addressInfo);
    _footerTaglines = b.footerTaglines.map((t) => t.copyWith()).toList();
    _headerMode = b.headerMode;
    _headerImagePath = b.headerImagePath;
    _footerBackgroundEnabled = b.footerBackgroundEnabled;
    _footerBackgroundImagePath = b.footerBackgroundImagePath;
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
    _senderAddressControllers =
        AddressFieldControllers.seeded(b.senderAddressInfo);
    _senderWebsiteCtrl = TextEditingController(text: b.senderWebsite ?? '');

    _thankYouCtrl = TextEditingController(
      text: e?.thankYouMessage ?? 'Thank you for your business!',
    );

    _bankNameCtrl = TextEditingController(text: b.bankName);
    _accountNameCtrl = TextEditingController(text: b.accountName);
    _accountNumberCtrl = TextEditingController(text: b.accountNumber);
    _otherPaymentDetailsCtrl = TextEditingController(text: b.otherPaymentDetails);
    _termsAndConditionsCtrl = TextEditingController(text: b.termsAndConditions);
    _signatureMode = b.signatureMode;
    _signatureNameCtrl = TextEditingController(text: b.signatureName);
    _signatureImagePath = b.signatureImagePath;

    _enabledFields = e?.enabledFields != null
        ? Map<String, bool>.from(e!.enabledFields)
        : defaultInvoiceEnabledFields();

    for (final c in [
      _nameCtrl, _bizNameCtrl, _bizTaglineCtrl, _bizEmailCtrl, _bizPhoneCtrl,
      _bizTaxIdCtrl, _bizGstCtrl, _bizWebsiteCtrl,
      _senderNameCtrl, _senderPositionCtrl, _senderEmailCtrl,
      _senderPhoneCtrl, _senderWebsiteCtrl,
      _thankYouCtrl,
      _bankNameCtrl, _accountNameCtrl, _accountNumberCtrl,
      _otherPaymentDetailsCtrl, _termsAndConditionsCtrl,
      _signatureNameCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
    _bizAddressControllers.addListenerToAll(() => setState(() {}));
    _senderAddressControllers.addListenerToAll(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _bizNameCtrl, _bizTaglineCtrl, _bizEmailCtrl, _bizPhoneCtrl,
      _bizTaxIdCtrl, _bizGstCtrl, _bizWebsiteCtrl,
      _senderNameCtrl, _senderPositionCtrl, _senderEmailCtrl,
      _senderPhoneCtrl, _senderWebsiteCtrl,
      _thankYouCtrl,
      _bankNameCtrl, _accountNameCtrl, _accountNumberCtrl,
      _otherPaymentDetailsCtrl, _termsAndConditionsCtrl,
      _signatureNameCtrl,
    ]) {
      c.dispose();
    }
    _bizAddressControllers.dispose();
    _senderAddressControllers.dispose();
    _businessInfoExpanded.dispose();
    super.dispose();
  }

  void _save() {
    if (_bizNameCtrl.text.trim().isEmpty) {
      _businessInfoExpanded.value = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business Name is required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final bizAddressInfo = _bizAddressControllers.toAddressInfo();
    final senderAddressInfo = _senderAddressControllers.toAddressInfo();

    widget.onSaved(InvoiceTemplate(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      currency: _currency,
      enabledFields: _enabledFields,
      thankYouMessage: _thankYouCtrl.text.trim().isEmpty
          ? 'Thank you for your business!'
          : _thankYouCtrl.text.trim(),
      businessInfo: BusinessInfo(
        name: _bizNameCtrl.text.trim(),
        tagline: _bizTaglineCtrl.text.trim(),
        headerMode: _headerMode,
        headerImagePath: _headerImagePath,
        email: _bizEmailCtrl.text.trim(),
        phone: _bizPhoneCtrl.text.trim(),
        address: bizAddressInfo.singleLine,
        addressInfo: bizAddressInfo,
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
        senderAddress: senderAddressInfo.singleLine.isEmpty
            ? null
            : senderAddressInfo.singleLine,
        senderAddressInfo: senderAddressInfo,
        senderWebsite: _senderWebsiteCtrl.text.trim().isEmpty
            ? null
            : _senderWebsiteCtrl.text.trim(),
        footerTaglines: _footerTaglines.map((t) => t.copyWith()).toList(),
        footerBackgroundEnabled: _footerBackgroundEnabled,
        footerBackgroundImagePath: _footerBackgroundImagePath,
        bankName: _bankNameCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        otherPaymentDetails: _otherPaymentDetailsCtrl.text.trim(),
        termsAndConditions: _termsAndConditionsCtrl.text.trim(),
        signatureMode: _signatureMode,
        signatureName: _signatureNameCtrl.text.trim(),
        signatureImagePath: _signatureImagePath,
      ),
    ));
    Navigator.pop(context);
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

                        _sectionLabel(context, 'Template Info', _accent),
                        _SheetField(
                          ctrl: _nameCtrl,
                          label: 'Template Name *',
                          hint: 'e.g. Standard Invoice',
                          icon: Icons.label_rounded,
                          max: 50,
                          required: true,
                          accent: _accent,
                        ),
                        _counter(context, _nameCtrl.text.length, 50),
                        const SizedBox(height: 20),

                        // BUSINESS LOGO SECTION RESTORED (this update):
                        // the "Business Logo" _CollapsibleGroup was
                        // dropped entirely in an earlier SECTIONS
                        // REMOVAL PASS, but the underlying state
                        // (_logoPath/_logoOffset/_logoScale/_logoShape/
                        // _logoShowInitial/_logoInitialLetter) was never
                        // removed and is still written into
                        // BusinessInfo(...) in _save() below — so this
                        // is a pure UI restoration, not a model change.
                        // Uses the same full-mode SharedLogoPicker call
                        // (Gallery/Camera/Reposition/Remove chips + the
                        // "Show letter mark" switch/Letter box) Create
                        // Invoice's Container Logo section uses, so all
                        // three sheets (Customer/Template/Create
                        // Invoice) now render this section identically.
                        // Wrapped in _CollapsibleGroup like every other
                        // section on this sheet, so it can be opened/
                        // closed the same way Business Information,
                        // Footer Taglines, etc. already can.
                        _CollapsibleGroup(
                          label: 'Business Logo',
                          icon: Icons.image_rounded,
                          accent: _accent,
                          sectionKey: 'business_logo',
                          child: SharedLogoPicker(
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
                        ),

                        // BUSINESS INFO TRIM PASS: this collapsible group's
                        // child now collects ONLY Business Name, Tagline,
                        // Tax ID / EIN, and GST Number. See this file's
                        // header comment for the full rationale — Sender /
                        // Contact Person (further down this sheet) is now
                        // the single place that collects address/email/
                        // phone.
                        _CollapsibleGroup(
                          label: 'Business Information',
                          icon: Icons.business_rounded,
                          accent: _accent,
                          sectionKey: 'business_info',
                          expandedOverride: _businessInfoExpanded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SheetField(
                                ctrl: _bizNameCtrl,
                                label: 'Business Name *',
                                hint: 'e.g. Acme Solutions Ltd',
                                icon: Icons.business_rounded,
                                max: 40,
                                required: true,
                                accent: _accent,
                              ),
                              _counter(context, _bizNameCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              _SheetField(
                                ctrl: _bizTaglineCtrl,
                                label: 'Tagline',
                                hint: 'e.g. Technology | Websites | Support',
                                icon: Icons.short_text_rounded,
                                max: 60,
                                accent: _accent,
                              ),
                              _counter(context, _bizTaglineCtrl.text.length, 60),
                              const SizedBox(height: 12),
                              _SheetField(
                                ctrl: _bizTaxIdCtrl,
                                label: 'Tax ID / EIN',
                                hint: 'e.g. 12-3456789',
                                icon: Icons.receipt_long_rounded,
                                max: 30,
                                accent: _accent,
                              ),
                              _counter(context, _bizTaxIdCtrl.text.length, 30),
                              const SizedBox(height: 12),
                              _SheetField(
                                ctrl: _bizGstCtrl,
                                label: 'GST Number',
                                hint: 'e.g. 123456789',
                                icon: Icons.numbers_rounded,
                                max: 30,
                                accent: _accent,
                              ),
                              _counter(context, _bizGstCtrl.text.length, 30),
                            ],
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Footer Taglines',
                          icon: Icons.share_rounded,
                          accent: _accent,
                          sectionKey: 'footer_taglines',
                          child: FooterTaglinesEditor(
                            initialItems: _footerTaglines,
                            accent: _accent,
                            onChanged: (items) => _footerTaglines = items,
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Sender / Contact Person',
                          icon: Icons.person_rounded,
                          accent: _accent,
                          sectionKey: 'sender_contact',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SheetField(
                                ctrl: _senderNameCtrl,
                                label: 'Sender Name',
                                hint: 'e.g. Jane Smith',
                                icon: Icons.person_rounded,
                                max: 40,
                                accent: _accent,
                              ),
                              _counter(context, _senderNameCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              _SheetField(
                                ctrl: _senderPositionCtrl,
                                label: 'Position / Title',
                                hint: 'e.g. Sales Manager',
                                icon: Icons.work_rounded,
                                max: 40,
                                accent: _accent,
                              ),
                              _counter(context, _senderPositionCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              _SheetField(
                                ctrl: _senderEmailCtrl,
                                label: 'Sender Email',
                                hint: 'e.g. jane@acme.com',
                                icon: Icons.email_outlined,
                                max: 60,
                                keyboard: TextInputType.emailAddress,
                                accent: _accent,
                              ),
                              _counter(context, _senderEmailCtrl.text.length, 60),
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
                              _counter(context, _senderPhoneCtrl.text.length, 20),
                              const SizedBox(height: 16),
                              _sectionLabel(context, 'Sender Address', _accent),
                              AddressFieldGroup(
                                controllers: _senderAddressControllers,
                                accent: _accent,
                              ),
                              const SizedBox(height: 12),
                              _SheetField(
                                ctrl: _senderWebsiteCtrl,
                                label: 'Sender Website',
                                hint: 'e.g. jane.acme.com',
                                icon: Icons.language_outlined,
                                max: 50,
                                keyboard: TextInputType.url,
                                accent: _accent,
                              ),
                              _counter(context, _senderWebsiteCtrl.text.length, 50),
                            ],
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Thank You Message',
                          icon: Icons.favorite_border_rounded,
                          accent: _accent,
                          sectionKey: 'thank_you_message',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SheetField(
                                ctrl: _thankYouCtrl,
                                label: 'Message',
                                hint: 'e.g. Thank you for your business!',
                                max: 120,
                                maxLines: 2,
                                accent: _accent,
                              ),
                              _counter(context, _thankYouCtrl.text.length, 120),
                            ],
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Payment Info',
                          icon: Icons.account_balance_rounded,
                          accent: _accent,
                          sectionKey: 'payment_info',
                          child: _PaymentInfoSection(
                            bankNameCtrl: _bankNameCtrl,
                            accountNameCtrl: _accountNameCtrl,
                            accountNumberCtrl: _accountNumberCtrl,
                            otherPaymentDetailsCtrl: _otherPaymentDetailsCtrl,
                            accent: _accent,
                          ),
                        ),
                        _CollapsibleGroup(
                          label: 'Terms & Conditions',
                          icon: Icons.gavel_rounded,
                          accent: _accent,
                          sectionKey: 'terms_conditions',
                          child: _TermsSection(
                            termsAndConditionsCtrl: _termsAndConditionsCtrl,
                            accent: _accent,
                          ),
                        ),
                        _CollapsibleGroup(
                          label: 'Signature',
                          icon: Icons.draw_outlined,
                          accent: _accent,
                          sectionKey: 'signature',
                          child: _SignatureSection(
                            mode: _signatureMode,
                            onModeChanged: (m) => setState(() => _signatureMode = m),
                            nameCtrl: _signatureNameCtrl,
                            imagePath: _signatureImagePath,
                            onImageChanged: (p) =>
                                setState(() => _signatureImagePath = p),
                            accent: _accent,
                          ),
                        ),
                        const SizedBox(height: 8),

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
// Shared sheet helpers
// =============================================================================

Widget _sectionLabel(BuildContext context, String label, Color accent) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: accent,
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

Widget _counter(BuildContext context, int current, int max) {
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

// =============================================================================
// _CollapsibleGroup
// =============================================================================

class _CollapsibleGroup extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Widget child;
  final String sectionKey;
  final ValueNotifier<bool>? expandedOverride;

  const _CollapsibleGroup({
    required this.label,
    required this.icon,
    required this.accent,
    required this.child,
    required this.sectionKey,
    this.expandedOverride,
  });

  @override
  State<_CollapsibleGroup> createState() => _CollapsibleGroupState();
}

class _CollapsibleGroupState extends State<_CollapsibleGroup> {
  bool _expanded = false;

  String get _prefKey => '$_kSectionExpandedPrefPrefix${widget.sectionKey}';

  @override
  void initState() {
    super.initState();
    widget.expandedOverride?.addListener(_onOverrideChanged);
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getBool(_prefKey) ?? false;
    if (!mounted) return;
    setState(() {
      _expanded = widget.expandedOverride?.value ?? persisted;
    });
  }

  void _onOverrideChanged() {
    if (!mounted) return;
    setState(() => _expanded = widget.expandedOverride!.value);
  }

  Future<void> _setExpanded(bool v) async {
    setState(() => _expanded = v);
    if (widget.expandedOverride != null) {
      widget.expandedOverride!.value = v;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, v);
  }

  @override
  void dispose() {
    widget.expandedOverride?.removeListener(_onOverrideChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF20202E) : const Color(0xFFFCFCFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _expanded ? Radius.zero : const Radius.circular(12),
            ),
            onTap: () => _setExpanded(!_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: _expanded
                        ? widget.accent
                        : colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _expanded,
                    activeThumbColor: widget.accent,
                    onChanged: _setExpanded,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reusable text field (shared with customer sheet)
// =============================================================================

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
      inputFormatters: widget.max != null
          ? [LengthLimitingTextInputFormatter(widget.max!)]
          : null,
      validator: widget.validator ??
          (widget.required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
      decoration: InputDecoration(
        labelText: displayLabel,
        labelStyle:
            TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        hintText: widget.hint,
        hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, size: 20,
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
                color: atLimit ? const Color(0xFFF44336) : widget.accent,
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
