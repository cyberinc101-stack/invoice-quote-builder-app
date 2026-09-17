// lib/screens/create_quote_section/step_templates/quote_step_template.dart
//
// TAGLINE PASS (this update): QuoteTemplate gains `tagline` (String,
// default '') — mirrors BusinessInfo.tagline / InvoiceTemplate's
// business tagline exactly, a short line rendered under the business
// name in the document header (e.g. "TECHNOLOGY | WEBSITES |
// SUPPORT"). Edited via a new field in the "Business Information"
// section, right after Business Name. Synced onto QuoteData.
// businessTagline wherever a QuoteTemplate is applied.
//
// SAVED-ITEMS CAP + FILTERS PASS (earlier): _kMaxQuoteTemplates
// raised from 10 to 100, matching the cap used elsewhere in this app's
// saved-item libraries. Since a library of up to 100 saved templates is
// unusable without a way to narrow it down, this pass also adds the
// same search field + Recent/A-Z/Z-A sort selector already used on the
// Customer step (quote_step_customer.dart's _CustomerSearchField /
// _SortSelector) — new _TemplateSearchField / _TemplateSortSelector
// widgets at the bottom of this file, functionally identical to their
// Customer-step counterparts but matching relevance against
// name/businessName instead of name/email/phone. The "Saved Templates"
// header/count/Hide-Show row is unchanged; the search field + sort
// selector sit directly beneath it, above the card list, exactly where
// the Customer step places them.
//
// PAYMENT INFO REMOVAL PASS (earlier): the "Payment Info"
// _CollapsibleGroup section has been removed from this sheet — a quote
// isn't collecting payment, that belongs on the Invoice it converts
// into. QuoteTemplate.bankName/accountName/accountNumber/
// otherPaymentDetails are left on the model unedited (harmless, unused
// dead fields — same treatment QuoteData gave its own copies of these
// in quote_data.dart) rather than ripped out, so no persisted template
// JSON breaks. quote_step_template_payment.dart (the
// _QuotePaymentInfoSection part file) is no longer referenced from this
// file's build() and can be deleted from the project if nothing else
// uses it — it's still a valid part of this library either way, so
// leaving it in place is also safe.
//
// INVOICE PARITY PASS (earlier): QuoteTemplate now carries the same
// authorable fields as Invoice's BusinessInfo (client_info.dart) —
// structured Business Address (AddressInfo), a full Sender/Contact
// block (name/position/email/phone/structured address/website), Payment
// Info (bankName/accountName/accountNumber/otherPaymentDetails), Terms &
// Conditions, and a three-mode Signature (typed/image/blank, plus a
// fourth deselected '' state) — see quote_step_template_payment.dart /
// quote_step_template_terms.dart / quote_step_template_signature.dart
// for the input UI, split into their own part files exactly mirroring
// Invoice's step_templates.dart / _payment.dart / _terms.dart /
// _signature.dart layout.
//
// NOT YET WIRED into QuoteData at template-select time — that sync step
// (the Quote equivalent of StepCreateInvoice._syncSelectedToProvider())
// still needs to be added wherever a QuoteTemplate is applied to
// QuoteProvider (likely inside create_quote_bottom_sheet.dart's _save(),
// alongside the existing current.copyWith() call). Every new field
// defaults to '' / 'blank' / an empty AddressInfo, so this is purely
// additive — no existing persisted template is affected until these
// sections are filled in.
//
// CURRENCY REMOVAL PASS (earlier): the Currency Code input has been
// removed from the sheet, matching Invoice's identical pass — currency
// is still a real model field (shown on the template card badge, copied
// on duplicate), it's just no longer editable from here. A new template
// still gets 'USD'; an existing template keeps whatever currency it
// already had.
//
// STRUCTURED ADDRESS PASS (earlier): Business Address and Sender
// Address are each a six-field AddressFieldGroup (see
// lib/widgets/shared_address_field_group.dart) instead of a single
// free-text field, exactly like Invoice. The legacy flat
// businessAddress/senderAddress strings are kept in sync
// (addressInfo.singleLine) for anything still reading them as plain
// text.
//
// PERSISTED COLLAPSE STATE PASS (earlier): every optional section
// (Business Logo, Business Information, Sender/Contact, Thank You
// Message, Terms & Conditions, Signature) defaults to
// COLLAPSED the first time this sheet is opened, then remembers
// whatever expand/collapse state it's left in — via SharedPreferences,
// keyed per section — independent of which template is being
// created/edited. Matches Invoice's _CollapsibleGroup exactly.
//
// SAFETY GUARD: Business Information holds the required Business Name
// field. If collapsed, its field isn't mounted, so Form validation
// silently skips it. _save() checks the Business Name controller
// directly before validating the rest of the form; if empty, Business
// Information is force-expanded and a snackbar explains why.
//
// FOLDER SPLIT PASS (earlier): this file is now a Dart part-file
// library root, matching Invoice's step_templates/ folder exactly:
//   quote_step_template.dart              // library root (this file)
//   quote_step_template_payment.dart      // part; unused as of this update
//   quote_step_template_terms.dart        // part; Terms & Conditions section
//   quote_step_template_signature.dart    // part; Signature section (4-mode)
//
// Deliberately does NOT add Tax ID / GST fields — Quote's model never
// had them, and BusinessInfo's own versions are invoice-specific
// (gstNumber etc.) — not carried over in this pass.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/quote_data.dart' show defaultQuoteEnabledFields;
import '../../../models/address_info.dart';
import '../../../models/footer_tagline.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../../../widgets/shared_address_field_group.dart';
import '../../../widgets/footer_taglines_editor.dart';

part 'quote_step_template_payment.dart';
part 'quote_step_template_terms.dart';
part 'quote_step_template_signature.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
// SAVED-ITEMS CAP + FILTERS PASS: raised 10 -> 100.
const int _kMaxQuoteTemplates = 100;
const String _kPrefQuoteTemplateList = 'quote_template_list_v1';
const _kQuoteSectionExpandedPrefPrefix =
    'quote_template_sheet_section_expanded_';

// =============================================================================
// Model
// =============================================================================

class QuoteTemplate {
  final String id;
  String name;

  // ── Business ────────────────────────────────────────────────────────────
  String businessName;
  // TAGLINE PASS: short line rendered under the business name in the
  // document header — mirrors BusinessInfo.tagline exactly.
  String tagline;
  String businessEmail;
  String businessPhone;
  String businessAddress; // legacy flat address — kept in sync from
                           // addressInfo.singleLine by the sheet's _save().
  AddressInfo addressInfo;
  String? website;
  // FOOTER TAGLINES PASS: 3–6 icon+text items authored here on the
  // template; the Customise-step "Footer Taglines" switch (backed by
  // QuoteData.footerTaglinesEnabled) controls whether they actually
  // render — this list is just the content.
  List<FooterTaglineItem> footerTaglines;
  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape;
  bool logoShowInitial;
  String logoInitialLetter;

  // ── Sender / Contact ────────────────────────────────────────────────────
  String? senderName;
  String? senderEmail;
  String? senderPhone;
  String? senderPosition;
  String? senderAddress; // legacy flat sender address.
  AddressInfo senderAddressInfo;
  String? senderWebsite;

  /// Bare currency code only (e.g. 'USD'). Not editable from this sheet
  /// anymore — see CURRENCY REMOVAL PASS above.
  String currency;

  Map<String, bool> enabledFields;
  String thankYouMessage;

  // ── Payment Info ────────────────────────────────────────────────────────
  // PAYMENT INFO REMOVAL PASS: no longer editable from this sheet (see
  // file header comment) — kept on the model, unedited, purely so
  // nothing breaks for any template saved before this pass.
  String bankName;
  String accountName;
  String accountNumber;
  String otherPaymentDetails;

  // ── Terms & Conditions ──────────────────────────────────────────────────
  String termsAndConditions;

  // ── Signature ───────────────────────────────────────────────────────────
  // 'typed' | 'image' | 'blank' | '' (deselected — nothing renders)
  String signatureMode;
  String signatureName;
  String? signatureImagePath;

  QuoteTemplate({
    required this.id,
    this.name = '',
    this.businessName = '',
    this.tagline = '',
    this.businessEmail = '',
    this.businessPhone = '',
    this.businessAddress = '',
    AddressInfo? addressInfo,
    this.website,
    List<FooterTaglineItem>? footerTaglines,
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale = 1.0,
    this.logoShape = 'roundedSquare',
    this.logoShowInitial = true,
    this.logoInitialLetter = '',
    this.senderName,
    this.senderEmail,
    this.senderPhone,
    this.senderPosition,
    this.senderAddress,
    AddressInfo? senderAddressInfo,
    this.senderWebsite,
    this.currency = 'USD',
    Map<String, bool>? enabledFields,
    this.thankYouMessage = 'Thank you for your business!',
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.otherPaymentDetails = '',
    this.termsAndConditions = '',
    this.signatureMode = 'blank',
    this.signatureName = '',
    this.signatureImagePath,
  })  : enabledFields = enabledFields ?? defaultQuoteEnabledFields(),
        addressInfo = addressInfo ?? AddressInfo(),
        senderAddressInfo = senderAddressInfo ?? AddressInfo(),
        footerTaglines = footerTaglines ?? [];

  Offset get logoOffset => Offset(logoOffsetDx, logoOffsetDy);
  LogoShape get shape => logoShapeFromString(logoShape);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'businessName': businessName,
        'tagline': tagline,
        'businessEmail': businessEmail,
        'businessPhone': businessPhone,
        'businessAddress': businessAddress,
        'addressInfo': addressInfo.toJson(),
        'website': website,
        'footerTaglines': footerTaglinesToJson(footerTaglines),
        'logoPath': logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale': logoScale,
        'logoShape': logoShape,
        'logoShowInitial': logoShowInitial,
        'logoInitialLetter': logoInitialLetter,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'senderPhone': senderPhone,
        'senderPosition': senderPosition,
        'senderAddress': senderAddress,
        'senderAddressInfo': senderAddressInfo.toJson(),
        'senderWebsite': senderWebsite,
        'currency': currency,
        'enabledFields': enabledFields,
        'thankYouMessage': thankYouMessage,
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'otherPaymentDetails': otherPaymentDetails,
        'termsAndConditions': termsAndConditions,
        'signatureMode': signatureMode,
        'signatureName': signatureName,
        'signatureImagePath': signatureImagePath,
      };

  factory QuoteTemplate.fromJson(Map<String, dynamic> j) => QuoteTemplate(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        businessName: j['businessName'] as String? ?? '',
        tagline: j['tagline'] as String? ?? '',
        businessEmail: j['businessEmail'] as String? ?? '',
        businessPhone: j['businessPhone'] as String? ?? '',
        businessAddress: j['businessAddress'] as String? ?? '',
        addressInfo:
            AddressInfo.fromJson(j['addressInfo'] ?? j['businessAddress']),
        website: j['website'] as String?,
        footerTaglines: footerTaglinesFromJson(j['footerTaglines']),
        logoPath: j['logoPath'] as String?,
        logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale: (j['logoScale'] as num?)?.toDouble() ?? 1.0,
        logoShape: j['logoShape'] as String? ?? 'roundedSquare',
        logoShowInitial: j['logoShowInitial'] as bool? ?? true,
        logoInitialLetter: j['logoInitialLetter'] as String? ?? '',
        senderName: j['senderName'] as String?,
        senderEmail: j['senderEmail'] as String?,
        senderPhone: j['senderPhone'] as String?,
        senderPosition: j['senderPosition'] as String?,
        senderAddress: j['senderAddress'] as String?,
        senderAddressInfo:
            AddressInfo.fromJson(j['senderAddressInfo'] ?? j['senderAddress']),
        senderWebsite: j['senderWebsite'] as String?,
        currency: j['currency'] as String? ?? 'USD',
        enabledFields: (j['enabledFields'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as bool? ?? true),
            ) ??
            defaultQuoteEnabledFields(),
        thankYouMessage:
            j['thankYouMessage'] as String? ?? 'Thank you for your business!',
        bankName: j['bankName'] as String? ?? '',
        accountName: j['accountName'] as String? ?? '',
        accountNumber: j['accountNumber'] as String? ?? '',
        otherPaymentDetails: j['otherPaymentDetails'] as String? ?? '',
        termsAndConditions: j['termsAndConditions'] as String? ?? '',
        signatureMode: j['signatureMode'] as String? ?? 'blank',
        signatureName: j['signatureName'] as String? ?? '',
        signatureImagePath: j['signatureImagePath'] as String?,
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
  final String? initialSelectedId;
  final ValueChanged<QuoteTemplate?>? onInitialSelectionRestored;

  const QuoteStepTemplateSection({
    super.key,
    required this.accent,
    required this.onTemplateSelected,
    this.initialSelectedId,
    this.onInitialSelectionRestored,
  });

  @override
  State<QuoteStepTemplateSection> createState() =>
      _QuoteStepTemplateSectionState();
}

// SAVED-ITEMS CAP + FILTERS PASS: sort modes for the saved-template
// list, same shape as quote_step_customer.dart's _SortMode.
enum _TemplateSortMode { recent, nameAsc, nameDesc }

class _QuoteStepTemplateSectionState extends State<QuoteStepTemplateSection> {
  bool _loading = true;
  List<QuoteTemplate> _library = [];
  int? _selectedIndex;
  bool _showPanel = true;

  // SAVED-ITEMS CAP + FILTERS PASS: search + sort state, same shape as
  // quote_step_customer.dart's _QuoteStepCustomerSectionState.
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _TemplateSortMode _sortMode = _TemplateSortMode.recent;

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
    final templates = await _loadQuoteTemplates();
    if (!mounted) return;

    int? restoredIndex;
    if (widget.initialSelectedId != null) {
      final idx =
          templates.indexWhere((t) => t.id == widget.initialSelectedId);
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

  // SAVED-ITEMS CAP + FILTERS PASS: relevance tier against name/
  // businessName, same shape as the Customer step's _relevance. 3 means
  // "doesn't match" and gets filtered out.
  int _relevance(int i, String q) {
    final t = _library[i];
    final name = t.name.toLowerCase();
    final biz = t.businessName.toLowerCase();
    if (name.startsWith(q)) return 0;
    if (name.contains(q)) return 1;
    if (biz.contains(q)) return 2;
    return 3;
  }

  // Real _library indices for what's currently displayed — same
  // relevance-vs-sort behaviour as the Customer step's _visibleIndices.
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
          indices = indices.reversed.toList(); // newest added shown first
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
        const SnackBar(
            content: Text('Maximum templates reached.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final o = _library[index];
    final dupe = QuoteTemplate(
      id: const Uuid().v4(),
      name: '${o.name} (Copy)',
      businessName: o.businessName,
      tagline: o.tagline,
      businessEmail: o.businessEmail,
      businessPhone: o.businessPhone,
      businessAddress: o.businessAddress,
      addressInfo: o.addressInfo.copyWith(),
      website: o.website,
      footerTaglines: o.footerTaglines.map((t) => t.copyWith()).toList(),
      logoPath: o.logoPath,
      logoOffsetDx: o.logoOffsetDx,
      logoOffsetDy: o.logoOffsetDy,
      logoScale: o.logoScale,
      logoShape: o.logoShape,
      logoShowInitial: o.logoShowInitial,
      logoInitialLetter: o.logoInitialLetter,
      senderName: o.senderName,
      senderEmail: o.senderEmail,
      senderPhone: o.senderPhone,
      senderPosition: o.senderPosition,
      senderAddress: o.senderAddress,
      senderAddressInfo: o.senderAddressInfo.copyWith(),
      senderWebsite: o.senderWebsite,
      currency: o.currency,
      enabledFields: Map<String, bool>.from(o.enabledFields),
      thankYouMessage: o.thankYouMessage,
      bankName: o.bankName,
      accountName: o.accountName,
      accountNumber: o.accountNumber,
      otherPaymentDetails: o.otherPaymentDetails,
      termsAndConditions: o.termsAndConditions,
      signatureMode: o.signatureMode,
      signatureName: o.signatureName,
      signatureImagePath: o.signatureImagePath,
    );
    setState(() => _library.add(dupe));
    _persistQuoteTemplates(_library);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('"${o.name}" duplicated.'),
          behavior: SnackBarBehavior.floating),
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
    // SAVED-ITEMS CAP + FILTERS PASS
    final visible = _visibleIndices;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage Templates',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Create and select a quote template',
                      style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.45))),
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
                        strokeWidth: 2, color: accent)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_library.length}/$_kMaxQuoteTemplates',
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
            color: isDark
                ? accent.withValues(alpha: 0.12)
                : accent.withValues(alpha: 0.08),
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

        GestureDetector(
          onTap: atMax
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Maximum of $_kMaxQuoteTemplates templates reached.'),
                        behavior: SnackBarBehavior.floating),
                  )
              : () => _showAddSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: atMax
                  ? (isDark
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFF5F5F5))
                  : accent.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: atMax
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : accent.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded,
                    color: atMax
                        ? colorScheme.onSurface.withValues(alpha: 0.3)
                        : accent,
                    size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    atMax ? 'Maximum Templates Reached' : 'Add New Template',
                    style: TextStyle(
                      color: atMax
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : accent,
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
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20)),
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
              GestureDetector(
                onTap: () => setState(() => _showPanel = !_showPanel),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_showPanel ? 'Hide' : 'Show',
                          style: TextStyle(
                              fontSize: 12,
                              color: accent,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 2),
                      Icon(
                          _showPanel
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Tap a card to select it for this quote.',
              style: TextStyle(
                  fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45))),
          if (_showPanel) ...[
            const SizedBox(height: 12),
            // SAVED-ITEMS CAP + FILTERS PASS: search field + sort
            // selector, same placement/behaviour as the Customer step.
            _TemplateSearchField(
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
                child: _TemplateSortSelector(
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
              ...visible.map((i) => _QuoteTemplateCard(
                    template: _library[i],
                    accent: accent,
                    isSelected: _selectedIndex == i,
                    onTap: () => _toggle(i),
                    onEdit: () => _showAddSheet(existing: _library[i], editIndex: i),
                    onDuplicate: () => _duplicate(i),
                    onDelete: () => _delete(i),
                  ))
            else if (isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No templates match your search',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                ),
              ),
          ],
        ] else if (!_loading && _library.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'No templates saved yet — add one to set business info and field visibility for your quotes.',
            style: TextStyle(
                fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// SAVED-ITEMS CAP + FILTERS PASS: search field for the saved-template
// list. Functionally identical to quote_step_customer.dart's
// _CustomerSearchField, duplicated here (rather than shared) since that
// widget is file-private to the Customer step file.
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
// SAVED-ITEMS CAP + FILTERS PASS: sort selector (segmented chips) for
// the saved-template list. Same shape as
// quote_step_customer.dart's _SortSelector.
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
    final hasLogo = template.logoPath != null &&
        template.logoPath!.isNotEmpty &&
        File(template.logoPath!).existsSync();
    final enabledCount = template.enabledFields.values.where((v) => v).length;
    final totalCount = template.enabledFields.length;

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
                    offset: const Offset(0, 2))
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
                      color: isSelected
                          ? accent
                          : colorScheme.onSurface.withValues(alpha: 0.3),
                      width: 1.5),
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
                  color: isSelected
                      ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: template.shape.radiusFor(46),
                  border: Border.all(
                      color: isSelected
                          ? accent.withValues(alpha: 0.4)
                          : colorScheme.outline.withValues(alpha: 0.3),
                      width: 1.5),
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
                        : Icon(Icons.storefront_rounded,
                            color: isSelected
                                ? accent
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                            size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name.isNotEmpty
                          ? template.name
                          : '(Unnamed template)',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                    if (template.businessName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(template.businessName,
                          style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? accent
                                  : colorScheme.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: isDark ? 0.2 : 0.1)
                                : colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(template.currency,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? accent
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.3))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: isDark ? 0.2 : 0.1)
                                : colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$enabledCount/$totalCount fields',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? accent
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.3))),
                        ),
                      ],
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('Active for this quote',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accent)),
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
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.edit_rounded, color: accent, size: 16),
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
                              ? Colors.orange.withValues(alpha: 0.14)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8)),
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
                          borderRadius: BorderRadius.circular(8)),
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
  final QuoteTemplate template;
  final Color accent;
  const _CardFallbackMark({required this.template, required this.accent});

  @override
  Widget build(BuildContext context) {
    final letter = template.logoInitialLetter.trim();
    final initial = letter.isNotEmpty
        ? letter[0].toUpperCase()
        : (template.businessName.trim().isNotEmpty
            ? template.businessName.trim()[0].toUpperCase()
            : 'B');
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(4))),
        ),
        Text(initial,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    );
  }
}

// =============================================================================
// Bottom Sheet – create / edit a template
// =============================================================================

class _QuoteTemplateSheet extends StatefulWidget {
  final Color accent;
  final QuoteTemplate? existing;
  final void Function(QuoteTemplate) onSaved;

  const _QuoteTemplateSheet(
      {required this.accent, this.existing, required this.onSaved});

  @override
  State<_QuoteTemplateSheet> createState() => _QuoteTemplateSheetState();
}

class _QuoteTemplateSheetState extends State<_QuoteTemplateSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late final String _currency;

  // Business
  late TextEditingController _bizNameCtrl;
  late TextEditingController _bizTaglineCtrl;
  late TextEditingController _bizEmailCtrl;
  late TextEditingController _bizPhoneCtrl;
  late AddressFieldControllers _bizAddressControllers;
  late TextEditingController _websiteCtrl;
  // FOOTER TAGLINES PASS: plain list state (not a TextEditingController
  // per field) — FooterTaglinesEditor manages its own controllers
  // internally and reports the current list back via onChanged.
  List<FooterTaglineItem> _footerTaglines = [];
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  bool _logoShowInitial = true;
  String _logoInitialLetter = '';

  late TextEditingController _thankYouCtrl;

  // Sender
  late TextEditingController _senderNameCtrl;
  late TextEditingController _senderPositionCtrl;
  late TextEditingController _senderEmailCtrl;
  late TextEditingController _senderPhoneCtrl;
  late AddressFieldControllers _senderAddressControllers;
  late TextEditingController _senderWebsiteCtrl;

  // PAYMENT INFO REMOVAL PASS: bank* controllers removed — this sheet
  // no longer edits QuoteTemplate.bankName/accountName/accountNumber/
  // otherPaymentDetails at all (see file header comment). _save() below
  // passes those four fields straight through from widget.existing so
  // an existing template's already-saved values (if any, from before
  // this pass) are preserved rather than silently wiped on next edit.

  // Terms / Signature
  late TextEditingController _termsAndConditionsCtrl;
  String _signatureMode = 'blank';
  late TextEditingController _signatureNameCtrl;
  String? _signatureImagePath;

  late Map<String, bool> _enabledFields;

  bool get _isEditing => widget.existing != null;

  final ValueNotifier<bool> _businessInfoExpanded = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _currency = e?.currency ?? 'USD';

    _bizNameCtrl = TextEditingController(text: e?.businessName ?? '');
    _bizTaglineCtrl = TextEditingController(text: e?.tagline ?? '');
    _bizEmailCtrl = TextEditingController(text: e?.businessEmail ?? '');
    _bizPhoneCtrl = TextEditingController(text: e?.businessPhone ?? '');
    _bizAddressControllers = AddressFieldControllers.seeded(e?.addressInfo);
    _websiteCtrl = TextEditingController(text: e?.website ?? '');
    _footerTaglines = e?.footerTaglines.map((t) => t.copyWith()).toList() ?? [];
    _logoPath = e?.logoPath;
    _logoOffset = e?.logoOffset ?? Offset.zero;
    _logoScale = e?.logoScale ?? 1.0;
    _logoShape = e != null
        ? logoShapeFromString(e.logoShape)
        : LogoShape.roundedSquare;
    _logoShowInitial = e?.logoShowInitial ?? true;
    _logoInitialLetter = e?.logoInitialLetter ?? '';

    _senderNameCtrl = TextEditingController(text: e?.senderName ?? '');
    _senderPositionCtrl = TextEditingController(text: e?.senderPosition ?? '');
    _senderEmailCtrl = TextEditingController(text: e?.senderEmail ?? '');
    _senderPhoneCtrl = TextEditingController(text: e?.senderPhone ?? '');
    _senderAddressControllers =
        AddressFieldControllers.seeded(e?.senderAddressInfo);
    _senderWebsiteCtrl = TextEditingController(text: e?.senderWebsite ?? '');

    _thankYouCtrl = TextEditingController(
        text: e?.thankYouMessage ?? 'Thank you for your business!');

    _termsAndConditionsCtrl =
        TextEditingController(text: e?.termsAndConditions ?? '');
    _signatureMode = e?.signatureMode ?? 'blank';
    _signatureNameCtrl = TextEditingController(text: e?.signatureName ?? '');
    _signatureImagePath = e?.signatureImagePath;

    _enabledFields = e?.enabledFields != null
        ? Map<String, bool>.from(e!.enabledFields)
        : defaultQuoteEnabledFields();

    for (final c in [
      _nameCtrl,
      _bizNameCtrl,
      _bizTaglineCtrl,
      _bizEmailCtrl,
      _bizPhoneCtrl,
      _websiteCtrl,
      _senderNameCtrl,
      _senderPositionCtrl,
      _senderEmailCtrl,
      _senderPhoneCtrl,
      _senderWebsiteCtrl,
      _thankYouCtrl,
      _termsAndConditionsCtrl,
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
      _nameCtrl,
      _bizNameCtrl,
      _bizTaglineCtrl,
      _bizEmailCtrl,
      _bizPhoneCtrl,
      _websiteCtrl,
      _senderNameCtrl,
      _senderPositionCtrl,
      _senderEmailCtrl,
      _senderPhoneCtrl,
      _senderWebsiteCtrl,
      _thankYouCtrl,
      _termsAndConditionsCtrl,
      _signatureNameCtrl,
    ]) {
      c.dispose();
    }
    _bizAddressControllers.dispose();
    _senderAddressControllers.dispose();
    _businessInfoExpanded.dispose();
    super.dispose();
  }

  Color get _accent => widget.accent;

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

    widget.onSaved(QuoteTemplate(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      currency: _currency,
      enabledFields: _enabledFields,
      thankYouMessage: _thankYouCtrl.text.trim().isEmpty
          ? 'Thank you for your business!'
          : _thankYouCtrl.text.trim(),
      businessName: _bizNameCtrl.text.trim(),
      tagline: _bizTaglineCtrl.text.trim(),
      businessEmail: _bizEmailCtrl.text.trim(),
      businessPhone: _bizPhoneCtrl.text.trim(),
      businessAddress: bizAddressInfo.singleLine,
      addressInfo: bizAddressInfo,
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      footerTaglines: _footerTaglines.map((t) => t.copyWith()).toList(),
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
      // PAYMENT INFO REMOVAL PASS: no longer editable here — pass the
      // existing template's values straight through unchanged (empty
      // strings for a brand-new template) rather than editing them.
      bankName: widget.existing?.bankName ?? '',
      accountName: widget.existing?.accountName ?? '',
      accountNumber: widget.existing?.accountNumber ?? '',
      otherPaymentDetails: widget.existing?.otherPaymentDetails ?? '',
      termsAndConditions: _termsAndConditionsCtrl.text.trim(),
      signatureMode: _signatureMode,
      signatureName: _signatureNameCtrl.text.trim(),
      signatureImagePath: _signatureImagePath,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = kb + 32 + MediaQuery.of(context).padding.bottom;
    final accent = _accent;

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
                                _isEditing ? 'Edit Template' : 'New Template',
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
                                      ? const Color(0xFF2A0D33)
                                      : const Color(0xFFF3E5F5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: accent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Editing',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _sectionLabel(context, 'Template Info', accent),
                        QuoteFieldLite(
                          ctrl: _nameCtrl,
                          label: 'Template Name',
                          hint: 'e.g. Standard Quote',
                          icon: Icons.label_rounded,
                          max: 50,
                          required: true,
                          accent: accent,
                        ),
                        _counter(context, _nameCtrl.text.length, 50),
                        const SizedBox(height: 20),

                        _CollapsibleGroup(
                          label: 'Business Logo',
                          icon: Icons.image_rounded,
                          accent: accent,
                          sectionKey: 'business_logo',
                          child: SharedLogoPicker(
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
                          accent: accent,
                          sectionKey: 'business_info',
                          expandedOverride: _businessInfoExpanded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              QuoteFieldLite(
                                ctrl: _bizNameCtrl,
                                label: 'Business Name',
                                hint: 'e.g. Nova Studio Co.',
                                icon: Icons.business_rounded,
                                max: 40,
                                required: true,
                                accent: accent,
                              ),
                              _counter(context, _bizNameCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              QuoteFieldLite(
                                ctrl: _bizTaglineCtrl,
                                label: 'Tagline',
                                hint: 'e.g. Technology | Websites | Support',
                                icon: Icons.short_text_rounded,
                                max: 60,
                                accent: accent,
                              ),
                              _counter(context, _bizTaglineCtrl.text.length, 60),
                              const SizedBox(height: 12),
                              QuoteFieldLite(
                                ctrl: _bizEmailCtrl,
                                label: 'Business Email',
                                hint: 'e.g. hello@novastudio.com',
                                icon: Icons.email_rounded,
                                max: 60,
                                keyboard: TextInputType.emailAddress,
                                accent: accent,
                              ),
                              _counter(context, _bizEmailCtrl.text.length, 60),
                              const SizedBox(height: 12),
                              QuoteFieldLite(
                                ctrl: _bizPhoneCtrl,
                                label: 'Business Phone',
                                hint: 'e.g. +1 555 010 2020',
                                icon: Icons.phone_rounded,
                                max: 20,
                                keyboard: TextInputType.phone,
                                accent: accent,
                              ),
                              _counter(context, _bizPhoneCtrl.text.length, 20),
                              const SizedBox(height: 16),
                              _sectionLabel(context, 'Business Address', accent),
                              AddressFieldGroup(
                                controllers: _bizAddressControllers,
                                accent: accent,
                              ),
                              const SizedBox(height: 12),
                              QuoteFieldLite(
                                ctrl: _websiteCtrl,
                                label: 'Website',
                                hint: 'e.g. novastudio.com',
                                icon: Icons.language_rounded,
                                max: 50,
                                keyboard: TextInputType.url,
                                accent: accent,
                              ),
                              _counter(context, _websiteCtrl.text.length, 50),
                            ],
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Footer Taglines',
                          icon: Icons.share_rounded,
                          accent: accent,
                          sectionKey: 'footer_taglines',
                          child: FooterTaglinesEditor(
                            initialItems: _footerTaglines,
                            accent: accent,
                            onChanged: (items) => _footerTaglines = items,
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Sender / Contact Person',
                          icon: Icons.person_rounded,
                          accent: accent,
                          sectionKey: 'sender_contact',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              QuoteFieldLite(
                                ctrl: _senderNameCtrl,
                                label: 'Sender Name',
                                hint: 'e.g. Jane Smith',
                                icon: Icons.person_rounded,
                                max: 40,
                                accent: accent,
                              ),
                              _counter(context, _senderNameCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              QuoteFieldLite(
                                ctrl: _senderPositionCtrl,
                                label: 'Position / Title',
                                hint: 'e.g. Sales Manager',
                                icon: Icons.work_rounded,
                                max: 40,
                                accent: accent,
                              ),
                              _counter(
                                  context, _senderPositionCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              QuoteFieldLite(
                                ctrl: _senderEmailCtrl,
                                label: 'Sender Email',
                                hint: 'e.g. jane@novastudio.com',
                                icon: Icons.email_outlined,
                                max: 60,
                                keyboard: TextInputType.emailAddress,
                                accent: accent,
                              ),
                              _counter(context, _senderEmailCtrl.text.length, 60),
                              const SizedBox(height: 12),
                              QuoteFieldLite(
                                ctrl: _senderPhoneCtrl,
                                label: 'Sender Phone',
                                hint: 'e.g. +1 555 999 8888',
                                icon: Icons.phone_outlined,
                                max: 20,
                                keyboard: TextInputType.phone,
                                accent: accent,
                              ),
                              _counter(context, _senderPhoneCtrl.text.length, 20),
                              const SizedBox(height: 16),
                              _sectionLabel(context, 'Sender Address', accent),
                              AddressFieldGroup(
                                controllers: _senderAddressControllers,
                                accent: accent,
                              ),
                              const SizedBox(height: 12),
                              QuoteFieldLite(
                                ctrl: _senderWebsiteCtrl,
                                label: 'Sender Website',
                                hint: 'e.g. jane.novastudio.com',
                                icon: Icons.language_outlined,
                                max: 50,
                                keyboard: TextInputType.url,
                                accent: accent,
                              ),
                              _counter(
                                  context, _senderWebsiteCtrl.text.length, 50),
                            ],
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Thank You Message',
                          icon: Icons.favorite_border_rounded,
                          accent: accent,
                          sectionKey: 'thank_you_message',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              QuoteFieldLite(
                                ctrl: _thankYouCtrl,
                                label: 'Message',
                                hint: 'e.g. Thank you for your business!',
                                max: 120,
                                maxLines: 2,
                                accent: accent,
                              ),
                              _counter(context, _thankYouCtrl.text.length, 120),
                            ],
                          ),
                        ),

                        // PAYMENT INFO REMOVAL PASS: the "Payment Info"
                        // _CollapsibleGroup (bank name/account name/
                        // account number/other payment details) has
                        // been removed from this sheet entirely — see
                        // file header comment. Terms & Conditions and
                        // Signature remain, unchanged.
                        _CollapsibleGroup(
                          label: 'Terms & Conditions',
                          icon: Icons.gavel_rounded,
                          accent: accent,
                          sectionKey: 'terms_conditions',
                          child: _QuoteTermsSection(
                            termsAndConditionsCtrl: _termsAndConditionsCtrl,
                            accent: accent,
                          ),
                        ),
                        _CollapsibleGroup(
                          label: 'Signature',
                          icon: Icons.draw_outlined,
                          accent: accent,
                          sectionKey: 'signature',
                          child: _QuoteSignatureSection(
                            mode: _signatureMode,
                            onModeChanged: (m) =>
                                setState(() => _signatureMode = m),
                            nameCtrl: _signatureNameCtrl,
                            imagePath: _signatureImagePath,
                            onImageChanged: (p) =>
                                setState(() => _signatureImagePath = p),
                            accent: accent,
                          ),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isEditing ? 'Save Changes' : 'Save Template',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
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
// Shared sheet helpers (kept local to this library, distinct names from
// Invoice's step_templates.dart so both files can coexist in the app
// without symbol collisions)
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
// _CollapsibleGroup — mirrors Invoice's step_templates.dart exactly,
// persisted per-section via SharedPreferences under a Quote-specific key
// prefix so the two flows never share state.
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

  String get _prefKey => '$_kQuoteSectionExpandedPrefPrefix${widget.sectionKey}';

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
// QuoteFieldLite — a self-contained text field for this sheet, matching
// Invoice's _SheetField behaviour (auto-scroll on focus via retried
// Scrollable.ensureVisible, "(Optional)" label suffix, length limiter +
// counter via the shared _counter() helper above). Named distinctly from
// Quote's existing QuoteField (quote_edit_widgets.dart) since this one
// omits QuoteField's built-in maxLength counter (this sheet renders its
// own counter via _counter(), matching Invoice's split between field and
// counter widget) — both can coexist without collision.
// =============================================================================

class QuoteFieldLite extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData? icon;
  final int? max;
  final int maxLines;
  final bool required;
  final TextInputType? keyboard;
  final Color accent;

  const QuoteFieldLite({
    super.key,
    required this.ctrl,
    required this.label,
    required this.accent,
    this.hint,
    this.icon,
    this.max,
    this.maxLines = 1,
    this.required = false,
    this.keyboard,
  });

  @override
  State<QuoteFieldLite> createState() => _QuoteFieldLiteState();
}

class _QuoteFieldLiteState extends State<QuoteFieldLite> {
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
    final atLimit =
        widget.max != null && widget.ctrl.text.length >= widget.max!;
    final displayLabel =
        widget.required ? widget.label : '${widget.label} (Optional)';

    return TextFormField(
      controller: widget.ctrl,
      focusNode: _focusNode,
      keyboardType: widget.keyboard,
      maxLines: widget.maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      inputFormatters: widget.max != null
          ? [LengthLimitingTextInputFormatter(widget.max!)]
          : null,
      validator: widget.required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: displayLabel,
        labelStyle:
            TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        hintText: widget.hint,
        hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon,
                size: 20, color: colorScheme.onSurface.withValues(alpha: 0.45))
            : null,
        suffixIcon: atLimit
            ? const Tooltip(
                message: 'Character limit reached',
                child: Icon(Icons.warning_amber_rounded,
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
                color: atLimit ? const Color(0xFFF44336) : colorScheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: atLimit ? const Color(0xFFF44336) : widget.accent,
                width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF44336))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
