// lib/screens/create_receipt_section/step_templates/receipt_step_template.dart
//
// FOLDER MOVE + INVOICE/QUOTE PARITY PASS (this update): relocated from
// create_receipt_section/receipt_step_template.dart into its own
// step_templates/ folder — matching Invoice's
// invoice_create_section/step_templates/step_templates.dart and Quote's
// create_quote_section/step_templates/quote_step_template.dart layout
// exactly. This file is now a Dart part-file library root, split the
// same way those two are:
//   receipt_step_template.dart              // library root (this file)
//   receipt_step_template_payment.dart      // part; Payment Info section
//   receipt_step_template_terms.dart        // part; Terms & Conditions section
//   receipt_step_template_signature.dart    // part; Signature section (4-mode)
//
// create_receipt_screen.dart's and any other importer's paths need
// updating to 'step_templates/receipt_step_template.dart' to match.
//
// INVOICE/QUOTE PARITY PASS (this update): ReceiptTemplate gains the
// same authorable fields Invoice's BusinessInfo and Quote's
// QuoteTemplate already carry, for exactly the fields that are generic
// (not invoice-specific — no PO Number; not carried over from Invoice's
// Tax ID/GST either, since neither Quote nor Receipt ever had them):
//   - addressInfo (AddressInfo) — structured six-field business address,
//     replacing the old single free-text Business Address field. The
//     legacy flat businessAddress string is kept in sync
//     (addressInfo.singleLine) by this sheet's _save().
//   - Sender/Contact block — senderName/senderEmail/senderPhone/
//     senderPosition/senderAddress (legacy flat)/senderAddressInfo
//     (structured)/senderWebsite.
//   - Payment Info — bankName/accountName/accountNumber/
//     otherPaymentDetails.
//   - Terms & Conditions — termsAndConditions.
//   - Signature — three modes (typed/image/blank) plus a fourth
//     deselected '' state, exactly mirroring Invoice's/Quote's.
// None of this is yet wired onto ReceiptData at template-select time —
// same NOT YET WIRED boundary Quote's own parity pass documented; that
// sync step (the Receipt equivalent of
// StepCreateInvoice._syncSelectedToProvider()) still needs to be added
// wherever a ReceiptTemplate is applied (create_receipt_screen.dart's
// _applyTemplate()). Every new field defaults to '' / 'blank' / an empty
// AddressInfo, so this is purely additive — no existing persisted
// template is affected until these sections are filled in.
//
// CURRENCY REMOVAL PASS (this update): the Currency Code input has been
// removed from the sheet entirely, matching Invoice's and Quote's
// identical passes — currency is still a real model field (shown on the
// template card badge, copied on duplicate), it's just no longer
// editable from here. A new template still gets 'USD'; an existing
// template keeps whatever currency it already had. _currencyCtrl is
// gone.
//
// PERSISTED COLLAPSE STATE PASS (this update): every optional section
// (Business Logo, Business Information, Sender/Contact, Thank You
// Message, Payment Info, Terms & Conditions, Signature) now defaults to
// COLLAPSED the first time this sheet is opened, then remembers
// whatever expand/collapse state it's left in — via SharedPreferences,
// keyed per section — independent of which template is being
// created/edited. Matches Invoice's/Quote's _CollapsibleGroup exactly.
//
// SAFETY GUARD: Business Information holds the required Business Name
// field. If collapsed, its field isn't mounted, so Form validation
// silently skips it. _save() checks the Business Name controller
// directly before validating the rest of the form; if empty, Business
// Information is force-expanded and a snackbar explains why — matches
// Invoice's/Quote's identical guard.
//
// FIELD VISIBILITY RELOCATION PASS (earlier, preserved): the "Receipt
// Fields" / "Customer Fields" toggle switches stay OFF this sheet —
// they live on create_receipt_screen.dart's Customise step. The eight
// show* fields below remain on the model purely for backward
// compatibility with templates saved before that relocation, unedited
// from here.
//
// ICON CLEANUP PASS (earlier, preserved): no heart icon on Thank You
// Message.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/address_info.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../../../widgets/shared_address_field_group.dart';
import '../receipt_edit_widgets.dart' show receiptSectionHeader, ReceiptField;

part 'receipt_step_template_payment.dart';
part 'receipt_step_template_terms.dart';
part 'receipt_step_template_signature.dart';

const int _kMaxReceiptTemplates = 10;
const String _kPrefReceiptTemplateList = 'receipt_template_list_v1';
const _kReceiptSectionExpandedPrefPrefix =
    'receipt_template_sheet_section_expanded_';

// =============================================================================
// Model
// =============================================================================

class ReceiptTemplate {
  final String id;
  String name;
  String businessName;
  String businessEmail;
  String businessPhone;
  String businessAddress; // legacy flat address — kept in sync from
                           // addressInfo.singleLine by this sheet's _save().
  AddressInfo addressInfo;
  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape; // storage name — see LogoShape.storageName
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

  // Non-thermal field toggles — mirrors the show* fields on ReceiptData.
  // Not edited from this file's sheet — kept purely for backward
  // compatibility and as the initial seed the first time this template
  // is selected.
  bool showLogo;
  bool showBusinessDetails;
  bool showCustomerDetails;
  bool showReceiptNumber;
  bool showDateTime;
  bool showTaxLine;
  bool showDiscountLine;
  bool showPaymentMethod;

  // THANK YOU MESSAGE PASS: a template-level thank-you message, separate
  // from ReceiptData.footerMessage (the thermal-only footer text set on
  // ReceiptThermalSettingsSection).
  String thankYouMessage;

  // ── Payment Info ────────────────────────────────────────────────────────
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

  ReceiptTemplate({
    required this.id,
    this.name = '',
    this.businessName = '',
    this.businessEmail = '',
    this.businessPhone = '',
    this.businessAddress = '',
    AddressInfo? addressInfo,
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
    this.showLogo = true,
    this.showBusinessDetails = true,
    this.showCustomerDetails = true,
    this.showReceiptNumber = true,
    this.showDateTime = true,
    this.showTaxLine = true,
    this.showDiscountLine = true,
    this.showPaymentMethod = true,
    this.thankYouMessage = 'Thank you for your purchase!',
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.otherPaymentDetails = '',
    this.termsAndConditions = '',
    this.signatureMode = 'blank',
    this.signatureName = '',
    this.signatureImagePath,
  })  : addressInfo = addressInfo ?? AddressInfo(),
        senderAddressInfo = senderAddressInfo ?? AddressInfo();

  Offset get logoOffset => Offset(logoOffsetDx, logoOffsetDy);
  LogoShape get shape => logoShapeFromString(logoShape);

  /// Count of the 8 non-thermal toggles that are currently on — drives
  /// the "n/8 fields" chip on the saved-template card.
  int get enabledFieldCount => [
        showLogo,
        showBusinessDetails,
        showCustomerDetails,
        showReceiptNumber,
        showDateTime,
        showTaxLine,
        showDiscountLine,
        showPaymentMethod,
      ].where((v) => v).length;

  static const int totalFieldCount = 8;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'businessName': businessName,
        'businessEmail': businessEmail,
        'businessPhone': businessPhone,
        'businessAddress': businessAddress,
        'addressInfo': addressInfo.toJson(),
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
        'showLogo': showLogo,
        'showBusinessDetails': showBusinessDetails,
        'showCustomerDetails': showCustomerDetails,
        'showReceiptNumber': showReceiptNumber,
        'showDateTime': showDateTime,
        'showTaxLine': showTaxLine,
        'showDiscountLine': showDiscountLine,
        'showPaymentMethod': showPaymentMethod,
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

  factory ReceiptTemplate.fromJson(Map<String, dynamic> j) => ReceiptTemplate(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        businessName: j['businessName'] as String? ?? '',
        businessEmail: j['businessEmail'] as String? ?? '',
        businessPhone: j['businessPhone'] as String? ?? '',
        businessAddress: j['businessAddress'] as String? ?? '',
        // INVOICE/QUOTE PARITY PASS: falls back to the legacy flat
        // businessAddress string when no addressInfo key exists yet
        // (every template saved before this pass).
        addressInfo:
            AddressInfo.fromJson(j['addressInfo'] ?? j['businessAddress']),
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
        showLogo: j['showLogo'] as bool? ?? true,
        showBusinessDetails: j['showBusinessDetails'] as bool? ?? true,
        showCustomerDetails: j['showCustomerDetails'] as bool? ?? true,
        showReceiptNumber: j['showReceiptNumber'] as bool? ?? true,
        showDateTime: j['showDateTime'] as bool? ?? true,
        showTaxLine: j['showTaxLine'] as bool? ?? true,
        showDiscountLine: j['showDiscountLine'] as bool? ?? true,
        showPaymentMethod: j['showPaymentMethod'] as bool? ?? true,
        thankYouMessage: j['thankYouMessage'] as String? ?? 'Thank you for your purchase!',
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

Future<void> _persistReceiptTemplates(List<ReceiptTemplate> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefReceiptTemplateList,
    jsonEncode(list.map((t) => t.toJson()).toList()),
  );
}

Future<List<ReceiptTemplate>> _loadReceiptTemplates() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefReceiptTemplateList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => ReceiptTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// ReceiptStepTemplateSection
// =============================================================================

class ReceiptStepTemplateSection extends StatefulWidget {
  final Color accent;
  final ValueChanged<ReceiptTemplate?> onTemplateSelected;

  const ReceiptStepTemplateSection({
    super.key,
    required this.accent,
    required this.onTemplateSelected,
  });

  @override
  State<ReceiptStepTemplateSection> createState() => _ReceiptStepTemplateSectionState();
}

class _ReceiptStepTemplateSectionState extends State<ReceiptStepTemplateSection> {
  bool _loading = true;
  List<ReceiptTemplate> _library = [];
  int? _selectedIndex;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final templates = await _loadReceiptTemplates();
    if (!mounted) return;
    setState(() {
      _library = templates;
      _loading = false;
    });
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

  void _showAddSheet({ReceiptTemplate? existing, int? editIndex}) {
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
      builder: (_) => _ReceiptTemplateSheet(
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
          _persistReceiptTemplates(_library);
        },
      ),
    );
  }

  void _duplicate(int index) {
    if (_library.length >= _kMaxReceiptTemplates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum templates reached.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final orig = _library[index];
    final dupe = ReceiptTemplate(
      id: const Uuid().v4(),
      name: '${orig.name} (Copy)',
      businessName: orig.businessName,
      businessEmail: orig.businessEmail,
      businessPhone: orig.businessPhone,
      businessAddress: orig.businessAddress,
      addressInfo: orig.addressInfo.copyWith(),
      logoPath: orig.logoPath,
      logoOffsetDx: orig.logoOffsetDx,
      logoOffsetDy: orig.logoOffsetDy,
      logoScale: orig.logoScale,
      logoShape: orig.logoShape,
      logoShowInitial: orig.logoShowInitial,
      logoInitialLetter: orig.logoInitialLetter,
      senderName: orig.senderName,
      senderEmail: orig.senderEmail,
      senderPhone: orig.senderPhone,
      senderPosition: orig.senderPosition,
      senderAddress: orig.senderAddress,
      senderAddressInfo: orig.senderAddressInfo.copyWith(),
      senderWebsite: orig.senderWebsite,
      currency: orig.currency,
      showLogo: orig.showLogo,
      showBusinessDetails: orig.showBusinessDetails,
      showCustomerDetails: orig.showCustomerDetails,
      showReceiptNumber: orig.showReceiptNumber,
      showDateTime: orig.showDateTime,
      showTaxLine: orig.showTaxLine,
      showDiscountLine: orig.showDiscountLine,
      showPaymentMethod: orig.showPaymentMethod,
      thankYouMessage: orig.thankYouMessage,
      bankName: orig.bankName,
      accountName: orig.accountName,
      accountNumber: orig.accountNumber,
      otherPaymentDetails: orig.otherPaymentDetails,
      termsAndConditions: orig.termsAndConditions,
      signatureMode: orig.signatureMode,
      signatureName: orig.signatureName,
      signatureImagePath: orig.signatureImagePath,
    );
    setState(() => _library.add(dupe));
    _persistReceiptTemplates(_library);
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
    _persistReceiptTemplates(_library);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final atMax = _library.length >= _kMaxReceiptTemplates;

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
                  Text(
                    'Manage Templates',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and select a receipt template',
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
                  '${_library.length}/$_kMaxReceiptTemplates',
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
                  'Save up to $_kMaxReceiptTemplates templates with your business info and select one per receipt.',
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
                    SnackBar(content: Text('Maximum of $_kMaxReceiptTemplates templates reached.'), behavior: SnackBarBehavior.floating),
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
            'Tap a card to select it for this receipt.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
          if (_showPanel) ...[
            const SizedBox(height: 12),
            ...List.generate(_library.length, (displayIdx) {
              final i = _library.length - 1 - displayIdx;
              return _ReceiptTemplateCard(
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
            'No templates saved yet — add one to set business info and field visibility for your receipts.',
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

class _ReceiptTemplateCard extends StatelessWidget {
  final ReceiptTemplate template;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _ReceiptTemplateCard({
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
                          child: Text('${template.enabledFieldCount}/${ReceiptTemplate.totalFieldCount} fields',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? accent : colorScheme.onSurface.withValues(alpha: 0.3))),
                        ),
                      ],
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? 0.18 : 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('Active for this receipt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
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
  final ReceiptTemplate template;
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
// Bottom Sheet – create / edit a template
//
// INVOICE/QUOTE PARITY PASS: rebuilt section order to match Invoice's
// _TemplateSheet / Quote's _QuoteTemplateSheet exactly: Template Info ->
// Business Logo -> Business Information (structured address) ->
// Sender/Contact (structured address) -> Thank You Message -> Payment
// Info -> Terms & Conditions -> Signature -> Save.
// =============================================================================

class _ReceiptTemplateSheet extends StatefulWidget {
  final Color accent;
  final ReceiptTemplate? existing;
  final void Function(ReceiptTemplate) onSaved;

  const _ReceiptTemplateSheet({required this.accent, this.existing, required this.onSaved});

  @override
  State<_ReceiptTemplateSheet> createState() => _ReceiptTemplateSheetState();
}

class _ReceiptTemplateSheetState extends State<_ReceiptTemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late final String _currency;

  late TextEditingController _bizNameCtrl;
  late TextEditingController _bizEmailCtrl;
  late TextEditingController _bizPhoneCtrl;
  late AddressFieldControllers _bizAddressControllers;

  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  bool _logoShowInitial = true;
  String _logoInitialLetter = '';

  late TextEditingController _senderNameCtrl;
  late TextEditingController _senderPositionCtrl;
  late TextEditingController _senderEmailCtrl;
  late TextEditingController _senderPhoneCtrl;
  late AddressFieldControllers _senderAddressControllers;
  late TextEditingController _senderWebsiteCtrl;

  late TextEditingController _thankYouCtrl;

  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNameCtrl;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _otherPaymentDetailsCtrl;
  late TextEditingController _termsAndConditionsCtrl;
  String _signatureMode = 'blank';
  late TextEditingController _signatureNameCtrl;
  String? _signatureImagePath;

  // FIELD VISIBILITY RELOCATION PASS: not editable from this sheet —
  // carried through unedited to the saved ReceiptTemplate purely for
  // backward compatibility.
  bool _showLogo = true;
  bool _showBusinessDetails = true;
  bool _showCustomerDetails = true;
  bool _showReceiptNumber = true;
  bool _showDateTime = true;
  bool _showTaxLine = true;
  bool _showDiscountLine = true;
  bool _showPaymentMethod = true;

  bool get _isEditing => widget.existing != null;

  final ValueNotifier<bool> _businessInfoExpanded = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _currency = e?.currency ?? 'USD';

    _bizNameCtrl = TextEditingController(text: e?.businessName ?? '');
    _bizEmailCtrl = TextEditingController(text: e?.businessEmail ?? '');
    _bizPhoneCtrl = TextEditingController(text: e?.businessPhone ?? '');
    _bizAddressControllers = AddressFieldControllers.seeded(e?.addressInfo);

    _logoPath = e?.logoPath;
    _logoOffset = e?.logoOffset ?? Offset.zero;
    _logoScale = e?.logoScale ?? 1.0;
    _logoShape = e != null ? logoShapeFromString(e.logoShape) : LogoShape.roundedSquare;
    _logoShowInitial = e?.logoShowInitial ?? true;
    _logoInitialLetter = e?.logoInitialLetter ?? '';

    _senderNameCtrl = TextEditingController(text: e?.senderName ?? '');
    _senderPositionCtrl = TextEditingController(text: e?.senderPosition ?? '');
    _senderEmailCtrl = TextEditingController(text: e?.senderEmail ?? '');
    _senderPhoneCtrl = TextEditingController(text: e?.senderPhone ?? '');
    _senderAddressControllers = AddressFieldControllers.seeded(e?.senderAddressInfo);
    _senderWebsiteCtrl = TextEditingController(text: e?.senderWebsite ?? '');

    _thankYouCtrl = TextEditingController(
      text: e?.thankYouMessage ?? 'Thank you for your purchase!',
    );

    _bankNameCtrl = TextEditingController(text: e?.bankName ?? '');
    _accountNameCtrl = TextEditingController(text: e?.accountName ?? '');
    _accountNumberCtrl = TextEditingController(text: e?.accountNumber ?? '');
    _otherPaymentDetailsCtrl = TextEditingController(text: e?.otherPaymentDetails ?? '');
    _termsAndConditionsCtrl = TextEditingController(text: e?.termsAndConditions ?? '');
    _signatureMode = e?.signatureMode ?? 'blank';
    _signatureNameCtrl = TextEditingController(text: e?.signatureName ?? '');
    _signatureImagePath = e?.signatureImagePath;

    _showLogo = e?.showLogo ?? true;
    _showBusinessDetails = e?.showBusinessDetails ?? true;
    _showCustomerDetails = e?.showCustomerDetails ?? true;
    _showReceiptNumber = e?.showReceiptNumber ?? true;
    _showDateTime = e?.showDateTime ?? true;
    _showTaxLine = e?.showTaxLine ?? true;
    _showDiscountLine = e?.showDiscountLine ?? true;
    _showPaymentMethod = e?.showPaymentMethod ?? true;

    for (final c in [
      _nameCtrl, _bizNameCtrl, _bizEmailCtrl, _bizPhoneCtrl,
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

    widget.onSaved(ReceiptTemplate(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      currency: _currency,
      businessName: _bizNameCtrl.text.trim(),
      businessEmail: _bizEmailCtrl.text.trim(),
      businessPhone: _bizPhoneCtrl.text.trim(),
      businessAddress: bizAddressInfo.singleLine,
      addressInfo: bizAddressInfo,
      logoPath: _logoPath,
      logoOffsetDx: _logoOffset.dx,
      logoOffsetDy: _logoOffset.dy,
      logoScale: _logoScale,
      logoShape: _logoShape.storageName,
      logoShowInitial: _logoShowInitial,
      logoInitialLetter: _logoInitialLetter.trim(),
      senderName: _senderNameCtrl.text.trim().isEmpty ? null : _senderNameCtrl.text.trim(),
      senderPosition: _senderPositionCtrl.text.trim().isEmpty ? null : _senderPositionCtrl.text.trim(),
      senderEmail: _senderEmailCtrl.text.trim().isEmpty ? null : _senderEmailCtrl.text.trim(),
      senderPhone: _senderPhoneCtrl.text.trim().isEmpty ? null : _senderPhoneCtrl.text.trim(),
      senderAddress: senderAddressInfo.singleLine.isEmpty ? null : senderAddressInfo.singleLine,
      senderAddressInfo: senderAddressInfo,
      senderWebsite: _senderWebsiteCtrl.text.trim().isEmpty ? null : _senderWebsiteCtrl.text.trim(),
      showLogo: _showLogo,
      showBusinessDetails: _showBusinessDetails,
      showCustomerDetails: _showCustomerDetails,
      showReceiptNumber: _showReceiptNumber,
      showDateTime: _showDateTime,
      showTaxLine: _showTaxLine,
      showDiscountLine: _showDiscountLine,
      showPaymentMethod: _showPaymentMethod,
      thankYouMessage: _thankYouCtrl.text.trim().isEmpty
          ? 'Thank you for your purchase!'
          : _thankYouCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      accountName: _accountNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim(),
      otherPaymentDetails: _otherPaymentDetailsCtrl.text.trim(),
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
    final accent = widget.accent;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = kb + 32 + MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(_isEditing ? 'Edit Template' : 'New Template',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                            ),
                            if (_isEditing)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                                ),
                                child: Text('Editing', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _sectionLabel(context, 'Template Info', accent),
                        ReceiptField(
                          ctrl: _nameCtrl,
                          label: 'Template Name *',
                          hint: 'e.g. Standard Receipt',
                          accent: accent,
                          icon: Icons.label_rounded,
                          max: 50,
                          required: true,
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
                            onShowInitialFallbackChanged: (v) => setState(() => _logoShowInitial = v),
                            initialLetterOverride: _logoInitialLetter,
                            onInitialLetterOverrideChanged: (v) => setState(() => _logoInitialLetter = v),
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
                              ReceiptField(
                                ctrl: _bizNameCtrl,
                                label: 'Business Name *',
                                hint: 'e.g. Acme Solutions Ltd',
                                accent: accent,
                                icon: Icons.business_rounded,
                                max: 40,
                                required: true,
                              ),
                              _counter(context, _bizNameCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              ReceiptField(
                                ctrl: _bizEmailCtrl,
                                label: 'Business Email',
                                hint: 'e.g. hello@acme.com',
                                accent: accent,
                                icon: Icons.email_rounded,
                                max: 60,
                                keyboard: TextInputType.emailAddress,
                              ),
                              _counter(context, _bizEmailCtrl.text.length, 60),
                              const SizedBox(height: 12),
                              ReceiptField(
                                ctrl: _bizPhoneCtrl,
                                label: 'Business Phone',
                                hint: 'e.g. +1 555 000 1234',
                                accent: accent,
                                icon: Icons.phone_rounded,
                                max: 20,
                                keyboard: TextInputType.phone,
                              ),
                              _counter(context, _bizPhoneCtrl.text.length, 20),
                              const SizedBox(height: 16),
                              _sectionLabel(context, 'Business Address', accent),
                              AddressFieldGroup(
                                controllers: _bizAddressControllers,
                                accent: accent,
                              ),
                            ],
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
                              ReceiptField(
                                ctrl: _senderNameCtrl,
                                label: 'Sender Name',
                                hint: 'e.g. Jane Smith',
                                accent: accent,
                                icon: Icons.person_rounded,
                                max: 40,
                              ),
                              _counter(context, _senderNameCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              ReceiptField(
                                ctrl: _senderPositionCtrl,
                                label: 'Position / Title',
                                hint: 'e.g. Store Manager',
                                accent: accent,
                                icon: Icons.work_rounded,
                                max: 40,
                              ),
                              _counter(context, _senderPositionCtrl.text.length, 40),
                              const SizedBox(height: 12),
                              ReceiptField(
                                ctrl: _senderEmailCtrl,
                                label: 'Sender Email',
                                hint: 'e.g. jane@acme.com',
                                accent: accent,
                                icon: Icons.email_outlined,
                                max: 60,
                                keyboard: TextInputType.emailAddress,
                              ),
                              _counter(context, _senderEmailCtrl.text.length, 60),
                              const SizedBox(height: 12),
                              ReceiptField(
                                ctrl: _senderPhoneCtrl,
                                label: 'Sender Phone',
                                hint: 'e.g. +1 555 999 8888',
                                accent: accent,
                                icon: Icons.phone_outlined,
                                max: 20,
                                keyboard: TextInputType.phone,
                              ),
                              _counter(context, _senderPhoneCtrl.text.length, 20),
                              const SizedBox(height: 16),
                              _sectionLabel(context, 'Sender Address', accent),
                              AddressFieldGroup(
                                controllers: _senderAddressControllers,
                                accent: accent,
                              ),
                              const SizedBox(height: 12),
                              ReceiptField(
                                ctrl: _senderWebsiteCtrl,
                                label: 'Sender Website',
                                hint: 'e.g. jane.acme.com',
                                accent: accent,
                                icon: Icons.language_outlined,
                                max: 50,
                                keyboard: TextInputType.url,
                              ),
                              _counter(context, _senderWebsiteCtrl.text.length, 50),
                            ],
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Thank You Message',
                          icon: Icons.notes_rounded,
                          accent: accent,
                          sectionKey: 'thank_you_message',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReceiptField(
                                ctrl: _thankYouCtrl,
                                label: 'Message',
                                hint: 'e.g. Thank you for your purchase!',
                                accent: accent,
                                max: 150,
                                maxLines: 2,
                              ),
                              _counter(context, _thankYouCtrl.text.length, 150),
                            ],
                          ),
                        ),

                        _CollapsibleGroup(
                          label: 'Payment Info',
                          icon: Icons.account_balance_rounded,
                          accent: accent,
                          sectionKey: 'payment_info',
                          child: _ReceiptPaymentInfoSection(
                            bankNameCtrl: _bankNameCtrl,
                            accountNameCtrl: _accountNameCtrl,
                            accountNumberCtrl: _accountNumberCtrl,
                            otherPaymentDetailsCtrl: _otherPaymentDetailsCtrl,
                            accent: accent,
                          ),
                        ),
                        _CollapsibleGroup(
                          label: 'Terms & Conditions',
                          icon: Icons.gavel_rounded,
                          accent: accent,
                          sectionKey: 'terms_conditions',
                          child: _ReceiptTermsSection(
                            termsAndConditionsCtrl: _termsAndConditionsCtrl,
                            accent: accent,
                          ),
                        ),
                        _CollapsibleGroup(
                          label: 'Signature',
                          icon: Icons.draw_outlined,
                          accent: accent,
                          sectionKey: 'signature',
                          child: _ReceiptSignatureSection(
                            mode: _signatureMode,
                            onModeChanged: (m) => setState(() => _signatureMode = m),
                            nameCtrl: _signatureNameCtrl,
                            imagePath: _signatureImagePath,
                            onImageChanged: (p) => setState(() => _signatureImagePath = p),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isEditing ? 'Save Changes' : 'Save Template',
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
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
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
          color: current > max ? const Color(0xFFF44336) : colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    ),
  );
}

// =============================================================================
// _CollapsibleGroup — matches Invoice's/Quote's exactly.
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

  String get _prefKey => '$_kReceiptSectionExpandedPrefPrefix${widget.sectionKey}';

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
                    color: _expanded ? widget.accent : colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
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
