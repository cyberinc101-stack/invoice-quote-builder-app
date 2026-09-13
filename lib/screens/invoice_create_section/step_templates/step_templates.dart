// lib/screens/invoice_create_section/step_templates/step_templates.dart
//
// SELECTION STATUS PASS (this update): Quote's/Receipt's editor screens
// (quote_editor_screen.dart / create_receipt_screen.dart) each wrap
// their template-step widget with a small colored info container below
// it — "Select or add a template above to continue." when nothing's
// selected, or "Using 'Name' for this quote/receipt." once something
// is — via their own _selectionStatus() helper. Invoice's EditorScreen
// has no equivalent wrapper at all; it renders StepTemplates directly
// with nothing appended after it, so this box never showed on the
// invoice flow. Since StepTemplates is a fully self-contained widget
// (unlike Quote's/Receipt's template-step widgets, which get wrapped by
// their editor screen from the outside), the fix lives here instead —
// same approach as step_customers.dart's own SELECTION STATUS PASS: a
// new _SelectionStatus widget, added as the final sliver in this same
// CustomScrollView so it always renders regardless of loading/empty
// state, matching the visual style and copy pattern of Quote's version
// exactly (just with this screen's own blue accent and "invoice"
// wording). Unselected copy is identical to Quote's verbatim — it
// doesn't mention "quote"/"invoice" at all. Selected copy reads
// `_library[_selectedIndex!].name` directly with no empty-name
// fallback (unlike Quote's `name.isNotEmpty ? name : businessName`),
// since InvoiceTemplate.name is a hard-required field here (see
// _SheetField's validator below) and _TemplateCard already renders it
// with no fallback anywhere else in this file.
//
// SCAFFOLD PARITY FIX (earlier): same root cause and same fix as
// step_create_invoice.dart's SCAFFOLD PARITY FIX pass — this widget's
// StepNavBar was just the last child of a plain Column, sitting inside
// EditorScreen's body (editor_screen.dart), and EditorScreen's own
// Scaffold has no `bottomNavigationBar` set at all. Any SnackBar shown
// via `ScaffoldMessenger.of(context)` from in here resolved to
// EditorScreen's Scaffold, which has nothing to dock above — so it just
// sat at the literal bottom of the screen, on top of wherever this
// widget's own StepNavBar happened to be rendered.
//
// Fix: this widget now wraps itself in its own `ScaffoldMessenger` +
// `Scaffold`, with its StepNavBar registered as that Scaffold's real
// `bottomNavigationBar` instead of being a plain trailing Column child.
// SnackBars in this file (the "Maximum templates reached"/"duplicated"
// toasts in _duplicateTemplate(), and the "Maximum of X templates
// reached" toast on the Add button) are now shown via a local
// `GlobalKey<ScaffoldMessengerState>` (`_messengerKey`) instead of
// `ScaffoldMessenger.of(context)`, so they resolve to THIS widget's own
// ScaffoldMessenger — which now has a real bottomNavigationBar to dock
// above. The stray `behavior: SnackBarBehavior.floating` on all three is
// also dropped for consistency, matching the fixed/docked look used
// elsewhere. The "Business Name is required" SnackBar inside
// _TemplateSheet (the modal bottom sheet, a separate State/context) is
// deliberately left untouched — it's shown from within a
// showModalBottomSheet route, which has no bottom nav bar of its own to
// dock above, so `floating` is already the right look there.
//
// SAVED-ITEMS FILTERS PASS (earlier): adds the same search field +
// Recent/A-Z/Z-A sort selector already used on Quote's
// quote_step_template.dart and Receipt's receipt_step_template.dart
// (both of which mirror the Customer step) — new _TemplateSearchField /
// _TemplateSortSelector widgets near the bottom of this file, matching
// relevance against InvoiceTemplate's name/businessInfo.name. The
// "Saved Templates" header/count/Hide-Show row is unchanged; the search
// field + sort selector sit directly beneath it, above the card list,
// as their own slivers. The template-card SliverList now iterates
// `_visibleIndices` instead of the previous hardcoded
// `_library.length - 1 - displayIdx` reversal — "Recent" (the default
// sort mode) reproduces that exact same newest-first order, so nothing
// changes visually until a person actually searches or picks a
// different sort. _kMaxTemplates was already 100 (unlike Quote's/
// Receipt's cap, which this same pass raised from 10 to 100 on those
// two files) — unchanged here.
//
// PAYMENT TERMS REMOVAL PASS (earlier): the "Payment Terms / Due
// Note" field is gone from the Terms & Conditions section —
// _paymentTermsCtrl removed entirely (declaration, initState seeding,
// listener registration, dispose, _duplicateTemplate's copy, and the
// BusinessInfo(...) constructor call in _save()). _TermsSection
// (step_templates_terms.dart) now only takes termsAndConditionsCtrl.
// Matches the corresponding removal in client_info.dart
// (BusinessInfo.paymentTerms), invoice_data.dart (InvoiceData.paymentTerms),
// step_customise.dart (the toggle row), step_create_invoice.dart (the
// sync step), and the two render sites
// (executive_invoice_payment_terms_signature.dart,
// invoice_pdf_extra_sections.dart).
//
// STRUCTURED ADDRESS WIRING PASS (earlier): Business Address and
// Sender Address are now each a six-field AddressFieldGroup (Line 1,
// Line 2, City, State/Province, Country, ZIP/Postal Code — see
// address_info.dart / shared_address_field_group.dart) instead of a
// single free-text field. `_bizAddressCtrl`/`_senderAddressCtrl` are
// gone, replaced by `_bizAddressControllers`/`_senderAddressControllers`
// (AddressFieldControllers). _save() now writes BOTH the legacy
// `address`/`senderAddress` strings (kept in sync as
// addressInfo.singleLine / senderAddressInfo.singleLine, for anything
// that still reads them as plain text) AND the new structured
// `addressInfo`/`senderAddressInfo` onto BusinessInfo.
// _duplicateTemplate() is also updated to copy both new structured
// fields — it was previously missing them entirely (they didn't exist
// on BusinessInfo yet when that method was last touched), so duplicating
// a template would silently drop its structured address data.
//
// CURRENCY REMOVAL PASS (earlier): the Currency Code input has been
// removed from the Template sheet entirely — same reasoning as the
// customer-sheet currency removal (see client_info.dart /
// step_customers.dart): it was redundant, and templates already carry a
// currency value with no per-template way to usefully act on it either.
// InvoiceTemplate.currency is UNTOUCHED as a model field (still read by
// _TemplateCard's badge, _duplicateTemplate, PDF/export code, etc.) — a
// new template still gets 'USD', and an EXISTING template being edited
// keeps whatever currency it already had (read once into `_currency` in
// initState and written back unchanged in _save()). There's just no way
// to change it from this sheet anymore. _currencyCtrl and its field/
// counter are gone.
//
// PERSISTED COLLAPSE STATE PASS (earlier): every optional section
// (Business Logo, Business Information, Sender/Contact, Thank You
// Message, Payment Info, Terms & Conditions, Signature) now defaults to
// COLLAPSED the first time this sheet is ever opened, and after that
// remembers whatever expand/collapse state the person leaves it in —
// via SharedPreferences, keyed per section (see _CollapsibleGroup's
// `sectionKey` param below) — independent of which template is being
// created/edited. This replaces the previous behaviour where a section
// auto-expanded if it already had data in it (the _hasLogo/
// _hasSenderInfo/etc. getters are gone).
//
// SAFETY GUARD: Business Information holds the required Business Name
// field. If that section is collapsed, its TextFormField isn't mounted,
// so Form validation silently skips it — someone could otherwise save a
// template with an empty business name without ever seeing an error.
// _save() now checks _bizNameCtrl directly before validating the rest of
// the form; if it's empty, the Business Information section is force-
// expanded (via _businessInfoExpanded, a ValueNotifier passed to that
// one _CollapsibleGroup as `expandedOverride`) and a snackbar explains
// why, instead of silently saving or silently failing.
//
// AUTO-SCROLL-ON-FOCUS PASS (earlier): _SheetField's focus-triggered
// Scrollable.ensureVisible() call now retries at several points during
// the keyboard's rise animation (80/200/350/500ms after focus) instead
// of a single fixed-delay guess — the single-delay version could
// undershoot if the keyboard/sheet hadn't finished resizing yet. Matches
// the identical strengthened pass applied to step_customers.dart.
//
// GROUPED SECTIONS PASS (earlier update): the Template sheet's optional
// sections are each wrapped in _CollapsibleGroup (defined near the
// bottom of this file). Tapping the header row toggles expand/collapse
// the same as flipping the switch. This is a pure layout change: every
// controller, every _SheetField, every save-time BusinessInfo field is
// unchanged.
//
// PAYMENT INFO / TERMS & SIGNATURE INPUT UI PASS (earlier): the actual
// data-entry UI for the fields step_customise.dart has show/hide
// toggles for. This is a Dart part-file library — see the `part`
// directives below:
//   step_templates.dart              // library root (this file)
//   step_templates_payment.dart      // part; Payment Info section
//   step_templates_terms.dart        // part; Terms & Conditions section
//   step_templates_signature.dart    // part; Signature section (3-mode)
// Deliberately does NOT add a poNumber field here — that's per-invoice
// only (see client_info.dart's BusinessInfo header comment) and belongs
// on the invoice itself, not the template.
//
// LOGO FALLBACK MARK WIRING PASS (earlier): the "show letter mark
// when there's no logo" switch + optional letter override is wired to
// SharedLogoPicker's showInitialFallback/onShowInitialFallbackChanged/
// initialLetterOverride/onInitialLetterOverrideChanged params.

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
import '../../../services/storage_service.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../../../widgets/shared_address_field_group.dart';
import '../invoice_edit_widgets.dart';

part 'step_templates_payment.dart';
part 'step_templates_terms.dart';
part 'step_templates_signature.dart';

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

  // SAVED-ITEMS FILTERS PASS: search + sort state, matching Quote's/
  // Receipt's/Customer's identical pattern.
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _TemplateSortMode _sortMode = _TemplateSortMode.recent;

  // SCAFFOLD PARITY FIX: this widget's own ScaffoldMessenger, so
  // SnackBars shown from here (_duplicateTemplate()'s two toasts, the
  // "Maximum templates reached" tap on the Add button) dock above THIS
  // widget's own StepNavBar — now registered as this widget's own
  // nested Scaffold's `bottomNavigationBar` in build() below — instead
  // of resolving to EditorScreen's ambient Scaffold, which has no
  // `bottomNavigationBar` to dock above at all.
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

  // SAVED-ITEMS FILTERS PASS: relevance tier against template name /
  // business name. 3 means "doesn't match" and gets filtered out.
  int _relevance(int i, String q) {
    final t = _library[i];
    final name = t.name.toLowerCase();
    final biz = t.businessInfo.name.toLowerCase();
    if (name.startsWith(q)) return 0;
    if (name.contains(q)) return 1;
    if (biz.contains(q)) return 2;
    return 3;
  }

  // Real _library indices for what's currently displayed — same
  // relevance-vs-sort behaviour as Quote's/Receipt's/Customer's own
  // _visibleIndices. "Recent" reproduces the exact same newest-first
  // order the SliverList previously got via the hardcoded
  // `_library.length - 1 - displayIdx` reversal, so the default view is
  // unchanged.
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

  // SCAFFOLD PARITY FIX: both SnackBars below now go through
  // `_messengerKey` instead of `ScaffoldMessenger.of(context)`, and drop
  // the stray `behavior: SnackBarBehavior.floating` — see this file's
  // header comment for why.
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
    // SAVED-ITEMS FILTERS PASS
    final visible = _visibleIndices;
    final isSearching = _searchQuery.trim().isNotEmpty;

    // SCAFFOLD PARITY FIX: this widget now returns its OWN
    // ScaffoldMessenger + Scaffold, with the StepNavBar registered as
    // that Scaffold's real `bottomNavigationBar` — instead of being a
    // plain trailing Column child inside EditorScreen's body. This is
    // what actually gives SnackBars shown via `_messengerKey` something
    // correct to dock above. `backgroundColor: Colors.transparent` keeps
    // this a pure layout/messenger change with no visual difference —
    // EditorScreen's own background still shows through underneath.
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
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
                    // SCAFFOLD PARITY FIX: routed through _messengerKey
                    // instead of ScaffoldMessenger.of(context); the
                    // stray `behavior: SnackBarBehavior.floating` here
                    // is dropped for consistency — the SnackBar default
                    // (fixed) now docks above this widget's own
                    // StepNavBar exactly like the other toasts in this
                    // file.
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

            // ── Search + sort (SAVED-ITEMS FILTERS PASS) ─────────────────
            // Same placement/behaviour as Quote's/Receipt's/Customer's
            // template & customer steps: sits directly beneath the
            // library header, above the card list, and hides along
            // with the cards when the panel is collapsed.
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

            // ── Template cards ───────────────────────────────────────────
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

            // ── No search results ────────────────────────────────────────
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

            // SELECTION STATUS PASS: the box Quote's/Receipt's editor
            // screens add via their own _selectionStatus() wrapper —
            // added here instead since StepTemplates has no outer
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
                        : 'Select or add a template above to continue.',
                    accent: _accent,
                  ),
                ),
              ),
          ],
        ),

        // SCAFFOLD PARITY FIX: this is now the nested Scaffold's real
        // `bottomNavigationBar` — the piece that actually makes SnackBars
        // shown via `_messengerKey` dock correctly above it, instead of
        // being just another trailing Column child with nothing for a
        // fixed-behavior SnackBar to dock above.
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

// =============================================================================
// SAVED-ITEMS FILTERS PASS: search field for the saved-template list.
// Functionally identical to Quote's/Receipt's/Customer's own search
// field, duplicated here since those widgets are file-private.
// =============================================================================

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

// =============================================================================
// SAVED-ITEMS FILTERS PASS: sort selector (segmented chips) for the
// saved-template list. Same shape as Quote's/Receipt's/Customer's own
// sort selector.
// =============================================================================

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
// set and logoShowInitial is on.
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

  late final String _currency;

  // Business info
  late TextEditingController _bizNameCtrl;
  late TextEditingController _bizEmailCtrl;
  late TextEditingController _bizPhoneCtrl;

  late AddressFieldControllers _bizAddressControllers;

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

  // Sender info
  late TextEditingController _senderNameCtrl;
  late TextEditingController _senderPositionCtrl;
  late TextEditingController _senderEmailCtrl;
  late TextEditingController _senderPhoneCtrl;

  late AddressFieldControllers _senderAddressControllers;

  late TextEditingController _senderWebsiteCtrl;

  // PAYMENT INFO / TERMS & SIGNATURE INPUT UI PASS
  // PAYMENT TERMS REMOVAL PASS: _paymentTermsCtrl removed.
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
    _bizEmailCtrl = TextEditingController(text: b.email);
    _bizPhoneCtrl = TextEditingController(text: b.phone);
    _bizAddressControllers = AddressFieldControllers.seeded(b.addressInfo);
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
      _nameCtrl, _bizNameCtrl, _bizEmailCtrl, _bizPhoneCtrl,
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
      _nameCtrl, _bizNameCtrl, _bizEmailCtrl, _bizPhoneCtrl,
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
      // SCAFFOLD PARITY FIX: deliberately left as ScaffoldMessenger.of
      // (context) with `behavior: floating` — this fires from inside a
      // showModalBottomSheet route, which has no bottom nav bar of its
      // own to dock above, so `floating` is already the correct look
      // here (see this file's header comment).
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
                                ctrl: _bizEmailCtrl,
                                label: 'Business Email',
                                hint: 'e.g. hello@acme.com',
                                icon: Icons.email_rounded,
                                max: 60,
                                keyboard: TextInputType.emailAddress,
                                accent: _accent,
                              ),
                              _counter(context, _bizEmailCtrl.text.length, 60),
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
                              _counter(context, _bizPhoneCtrl.text.length, 20),
                              const SizedBox(height: 16),
                              _sectionLabel(context, 'Business Address', _accent),
                              AddressFieldGroup(
                                controllers: _bizAddressControllers,
                                accent: _accent,
                              ),
                              const SizedBox(height: 12),
                              _SheetField(
                                ctrl: _bizWebsiteCtrl,
                                label: 'Website',
                                hint: 'e.g. acme.com',
                                icon: Icons.language_rounded,
                                max: 50,
                                keyboard: TextInputType.url,
                                accent: _accent,
                              ),
                              _counter(context, _bizWebsiteCtrl.text.length, 50),
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