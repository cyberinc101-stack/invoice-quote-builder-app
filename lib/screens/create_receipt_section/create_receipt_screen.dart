// lib/screens/create_receipt_section/create_receipt_screen.dart
//
// TOAST PARITY FIX (this update): _showValidationError()'s SnackBar
// (used for "Select or create a receipt to continue." and "Select or
// add a template to continue") was explicitly set to
// `behavior: SnackBarBehavior.floating` — a rounded, margined bar that
// floats and overlaps the content above it. Quote's equivalent
// (quote_editor_screen.dart's _showSnack()) never sets `behavior` at
// all, which defaults to SnackBarBehavior.fixed — a full-width bar
// docked directly above the bottom nav bar, not overlapping anything.
// Removed the `behavior: SnackBarBehavior.floating` line so Receipt's
// toast now docks the same way Quote's does (matching the identical fix
// applied to step_create_invoice.dart's _continue()).
//
// SIGNATURE SYNC FIX (earlier): two related bugs, both around the
// Signature feature (receipt_provider.dart's SIGNATURE PASS added
// updateSignatureMode()/updateSignatureName()/updateSignatureImagePath()/
// updateSignatureFontSize()/updateSignatureFontFamily()/
// updateShowSignature(), but nothing on this screen ever used most of
// them correctly):
//
//   1. _applyTemplate() copied the selected ReceiptTemplate's logo and
//      show* toggles into local state, but never touched
//      template.signatureMode/signatureName/signatureImagePath — so a
//      signature typed/picked on the Template sheet
//      (receipt_step_template_signature.dart) stayed on the
//      ReceiptTemplate object and never reached ReceiptData. Same root
//      cause as the bug already fixed in quote_editor_screen.dart's
//      _applyTemplate() (see that file's SIGNATURE/PAYMENT/TERMS SYNC
//      FIX comment).
//
//   2. _syncToProvider() builds a BRAND NEW ReceiptData(...) from
//      scratch on every step transition (_goToStep/_nextStep) and pushes
//      it wholesale via provider.updateReceiptData(data) — but never
//      included showSignature/signatureMode/signatureName/
//      signatureImagePath/signatureFontSize/signatureFontFamily in that
//      constructor call. Since none of those six fields are tracked as
//      local state on this screen (unlike showLogo/showBusinessDetails/
//      etc, which all have their own _showXxx field seeded/synced
//      here), omitting them from the constructor call meant every
//      single step transition silently reset them to ReceiptData()'s
//      constructor defaults — even a signature set moments earlier
//      directly through Customise's own Signature section (which writes
//      straight to ReceiptProvider, per that section's own comment in
//      receipt_provider.dart). This is the exact same class of bug
//      quote_editor_screen.dart's CUSTOMISE OWNERSHIP PASS fixed for
//      Quote, just never applied here — and for Receipt it's worse,
//      since it wipes the signature on every step tap, not only on
//      template selection.
//
// Fix, kept consistent with Receipt's existing architecture (this
// screen was never given Quote's "own every field via provider" style
// refactor, so introducing that here is out of scope — this is the
// minimal, same-shape fix):
//   - _applyTemplate() now pushes template.signatureMode/signatureName/
//     signatureImagePath straight onto ReceiptProvider via its existing
//     updateSignatureMode()/updateSignatureName()/
//     updateSignatureImagePath() methods — mirroring exactly how
//     quote_editor_screen.dart's _applyTemplate() now calls
//     applyPaymentAndTermsFromTemplate(). Deliberately does NOT touch
//     showSignature — whether the signature is visible at all is a
//     Customise-step concern (like every other show* toggle), not
//     something a template should force on/off.
//   - _syncToProvider()'s ReceiptData(...) constructor call now carries
//     forward existing.showSignature/signatureMode/signatureName/
//     signatureImagePath/signatureFontSize/signatureFontFamily — the
//     same existing-value-fallback pattern already used for every
//     per-draft field in this function (`d?.field ?? existing.field`) —
//     instead of dropping them and falling back to the ReceiptData()
//     constructor defaults on every sync.
//
// Bank/Terms & Conditions on ReceiptTemplate are deliberately left
// alone — ReceiptData has no matching fields and ReceiptProvider has no
// updateBankName/updateTermsAndConditions-style methods, so those
// ReceiptTemplate fields appear to be unused-by-design for Receipt
// (same treatment Quote gave Payment Info).
//
// IMPORT PATH FIX PASS (earlier): three imports corrected to their
// real, current locations following the parity-with-Invoice/Quote folder
// moves:
//   'receipt_step_template.dart'   -> 'step_templates/receipt_step_template.dart'
//   'receipt_step_customise.dart'  -> 'step_customize/receipt_step_customise.dart'
//   'step_create_receipt.dart'     -> 'step_create_receipt/step_create_receipt.dart'
// No other changes in this pass — this file's own logic, state, and
// widget wiring are unchanged from the CASHIER NAME TOGGLE PASS below.
// receipt_edit_widgets.dart, receipt_full_preview_screen.dart, and
// receipt_paper_format.dart are all still at create_receipt_section/
// root and are unaffected.
//
// CASHIER NAME TOGGLE PASS (earlier): added `_showCashierName` state
// (bool, seeded from ReceiptData.showCashierName in initState), wired
// into _syncToProvider()'s ReceiptData construction, and passed into
// ReceiptStepCustomise as `showCashierName` + `onShowCashierNameChanged`
// — applies on both the A4 branch (new toggle row in
// receipt_step_customise.dart's "Receipt Fields" section) and, forwarded
// straight through that same widget, the thermal branch (new toggle row
// in receipt_thermal_settings.dart's "Staff & Terminal" section, next to
// the Cashier Name field itself). Same seed/sync/pass-through pattern as
// every other show* toggle already on this screen.
//
// PAPER FORMAT PICKER PASS (earlier): _paperFormat was previously
// only ever set once in initState from the constructor's paperFormat
// arg / provider fallback — it's now live-editable from the Customise
// step. Added `paperFormat: receiptPaperFormatFromString(_paperFormat)`
// and a new `onPaperFormatChanged` callback into the ReceiptStepCustomise
// call in _customiseStepWidget(), following the exact
// `setState(() => _x = v); _syncToProvider();` pattern already used for
// _colorScheme/_fontFamily/_fontSize above it. Picking a different
// format (A4/58mm/80mm) via the new picker on that step now updates
// _paperFormat, which flows into _isThermal (already a getter off
// _paperFormat, unchanged) and into _syncToProvider()'s ReceiptData —
// which is what _ReceiptPreviewCard watches to decide which preview to
// render. No other changes needed: _isThermal, the constructor, and
// initState's seeding of _paperFormat are all unchanged.
//
// THANK YOU MESSAGE TOGGLE PASS (earlier update): added `_showThankYouMessage`
// state (bool, seeded from ReceiptData.showThankYouMessage in initState),
// wired into _syncToProvider()'s ReceiptData construction
// (showThankYouMessage / thankYouMessage — the latter pulled from the
// selected ReceiptTemplate when one's chosen, mirroring how businessName/
// businessEmail/etc. are already pulled from _selectedTemplate above),
// and passed into ReceiptStepCustomise as `showThankYouMessage` +
// `onShowThankYouMessageChanged` so the new toggle row on
// receipt_step_customise.dart's "Receipt Fields" section actually has
// somewhere to read/write. See receipt_data.dart and
// receipt_step_customise.dart for their matching passes.
//
// RECEIPT LIBRARY RESTRUCTURE PASS (earlier): mirrors Invoice/Quote's
// own library restructure. The entire _createReceiptStep() body (receipt
// number, payment date, currency, client override, payment method, Saved
// Item Sets panel, line items, tax/discount, notes) has moved out into a
// bottom sheet (step_create_receipt/create_receipt_bottom_sheet.dart,
// CreateReceiptBottomSheet), opened from a new library screen embedded
// at this step (step_create_receipt/step_create_receipt.dart,
// StepCreateReceipt). Like Quote (and unlike Invoice), Receipt keeps its
// existing single shared bottomNavigationBar (ReceiptStepNavBar) —
// StepCreateReceipt is an embedded widget (like
// ReceiptStepCustomerSection/ReceiptStepTemplateSection), not a
// standalone screen with its own nav.
//
// New state: _selectedReceiptDraft (SavedReceiptDraft?) replaces every
// piece of per-receipt-details/line-item local state this screen used
// to own directly (_receiptNumber, _paymentDate, _custNameCtrl etc.,
// _currencyCodeCtrl/_currencySymbolCtrl/_currencyDisplayMode,
// _paymentMethod, _descCtrls/_qtyCtrls/_priceCtrls, _taxRate/
// _discountRate, _taxCtrl/_discountCtrl — all removed).
// StepCreateReceipt reports the selected draft via onDraftSelected();
// _syncToProvider() now pulls receipt number/payment date/currency/
// client override/line items/tax/discount/payment method from
// _selectedReceiptDraft?.data (falling back to whatever's already on the
// provider before any draft is selected). _stepBlockReason(2) and
// _save() now just check that a draft is selected, since the bottom
// sheet does its own full field validation before it will hand back a
// draft at all.
//
// Everything else — thermal/POS fields, social handles, font/colour,
// logo, field-visibility toggles, and the Customise step itself — is
// UNCHANGED and still lives directly on this State object exactly as
// before this pass; only the Create Receipt step's internals changed.
// Customise step's totals/currency prefix now read from _draftData
// (getter: _selectedReceiptDraft?.data ?? current provider ReceiptData)
// instead of locally-computed getters over removed controllers.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/history_provider.dart';
import '../../models/receipt_data.dart';
import '../../models/history_event.dart';
import '../../widgets/step_editor_header.dart';
import '../../widgets/shared_logo_picker.dart';
import '../saved_invoice_details_section/saved_document_detail_screen.dart';
import 'receipt_edit_widgets.dart';
import 'receipt_full_preview_screen.dart';
import 'step_customer/receipt_step_customer.dart';
import 'step_templates/receipt_step_template.dart';
import 'step_customize/receipt_step_customise.dart';
import 'receipt_paper_format.dart';
import 'step_create_receipt/step_create_receipt.dart';

class CreateReceiptScreen extends StatefulWidget {
  final int layoutTemplateId;
  final String paperFormat;
  final int initialStep;

  const CreateReceiptScreen({
    super.key,
    this.layoutTemplateId = 1,
    this.paperFormat = 'a4',
    this.initialStep = 0,
  });

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  static const Color _accent = Color(0xFF2E7D32);

  static const List<StepMeta> _steps = [
    StepMeta(label: 'Customer', icon: Icons.person_rounded),
    StepMeta(label: 'Template', icon: Icons.tune_rounded),
    StepMeta(label: 'Create Receipt', icon: Icons.receipt_long_rounded),
    StepMeta(label: 'Customise', icon: Icons.rate_review_rounded),
  ];

  late int _step;
  bool _saving = false;
  late int _layoutTemplateId;
  late String _paperFormat;

  bool get _isThermal => receiptPaperFormatFromString(_paperFormat).isThermal;

  ReceiptTemplate? _selectedTemplate;
  ReceiptClient? _selectedClient;

  // RECEIPT LIBRARY RESTRUCTURE PASS: the selected draft from the Create
  // Receipt step's library — carries receipt number/payment date/
  // currency/client override/line items/tax/discount/payment method.
  // Null until one is created or selected on that step.
  SavedReceiptDraft? _selectedReceiptDraft;

  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  double _logoSize = 44.0;

  ReceiptColor _colorScheme = ReceiptColor.green;
  late TextEditingController _titleCtrl;

  String _fontFamily = 'Roboto';
  double _fontSize = 12.0;

  late TextEditingController _cashierNameCtrl;
  late TextEditingController _posIdCtrl;
  late TextEditingController _taxIdCtrl;
  late TextEditingController _paymentReferenceCtrl;
  late TextEditingController _authCodeCtrl;
  late TextEditingController _cardLast4Ctrl;
  late TextEditingController _footerMessageCtrl;
  late TextEditingController _qrDataCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _facebookCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _twitterCtrl;

  bool _showLogo = true;
  bool _showBusinessDetails = true;
  bool _showCustomerDetails = true;
  bool _showReceiptNumber = true;
  bool _showDateTime = true;
  bool _showTaxLine = true;
  bool _showDiscountLine = true;
  bool _showPaymentMethod = true;
  // CASHIER NAME TOGGLE PASS: new — applies on both the A4 and thermal
  // branches (seeded from ReceiptData in initState, synced back via
  // _syncToProvider, wired into both ReceiptStepCustomise's A4 Fields
  // section and, forwarded through it, ReceiptThermalSettingsSection).
  bool _showCashierName = true;
  // THANK YOU MESSAGE TOGGLE PASS: new — mirrors the other A4 field
  // toggles above (seeded from ReceiptData in initState, synced back via
  // _syncToProvider, wired into ReceiptStepCustomise below).
  bool _showThankYouMessage = true;
  bool _showBarcode = false;
  bool _showQrCode = false;
  bool _compactThermalLayout = false;
  bool _showWebsite = false;
  bool _showFacebook = false;
  bool _showInstagram = false;
  bool _showTwitter = false;

  /// The data driving totals/currency display on the Customise step —
  /// the selected draft's data if one is selected, else whatever's
  /// already on the provider (e.g. before any draft has been picked).
  ReceiptData get _draftData =>
      _selectedReceiptDraft?.data ??
      context.read<ReceiptProvider>().currentReceiptData;

  String get _currencyPrefix {
    final symbol = _draftData.currencySymbol.trim();
    final code = _draftData.currency.trim().toUpperCase();
    if (symbol.isNotEmpty) return symbol;
    if (code.isNotEmpty) return '$code ';
    return '';
  }

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, _steps.length - 1);
    _layoutTemplateId = widget.layoutTemplateId;
    final r = context.read<ReceiptProvider>().currentReceiptData;
    _paperFormat = widget.paperFormat.isNotEmpty
        ? widget.paperFormat
        : (r.paperFormat.isNotEmpty ? r.paperFormat : 'a4');
    _logoSize = r.businessLogoDisplaySize;

    _colorScheme   = r.colorScheme;
    _fontFamily    = r.fontFamily;
    _fontSize      = r.fontSize;

    _titleCtrl = TextEditingController(
      text: r.clientName.isNotEmpty ? '${r.clientName} Receipt' : '',
    );

    _cashierNameCtrl      = TextEditingController(text: r.cashierName);
    _posIdCtrl            = TextEditingController(text: r.posId);
    _taxIdCtrl            = TextEditingController(text: r.taxId);
    _paymentReferenceCtrl = TextEditingController(text: r.paymentReference);
    _authCodeCtrl         = TextEditingController(text: r.authCode);
    _cardLast4Ctrl        = TextEditingController(text: r.cardLast4);
    _footerMessageCtrl    = TextEditingController(
      text: r.footerMessage.isNotEmpty ? r.footerMessage : 'Thank you for your purchase!',
    );
    _qrDataCtrl    = TextEditingController(text: r.qrData);
    _websiteCtrl   = TextEditingController(text: r.businessWebsite);
    _facebookCtrl  = TextEditingController(text: r.facebookHandle);
    _instagramCtrl = TextEditingController(text: r.instagramHandle);
    _twitterCtrl   = TextEditingController(text: r.twitterHandle);

    _showLogo             = r.showLogo;
    _showBusinessDetails  = r.showBusinessDetails;
    _showCustomerDetails  = r.showCustomerDetails;
    _showReceiptNumber    = r.showReceiptNumber;
    _showDateTime         = r.showDateTime;
    _showTaxLine          = r.showTaxLine;
    _showDiscountLine     = r.showDiscountLine;
    _showPaymentMethod    = r.showPaymentMethod;
    _showCashierName      = r.showCashierName;
    _showThankYouMessage  = r.showThankYouMessage;
    _showBarcode          = r.showBarcode;
    _showQrCode           = r.showQrCode;
    _compactThermalLayout = r.compactThermalLayout;
    _showWebsite   = r.showWebsite;
    _showFacebook  = r.showFacebook;
    _showInstagram = r.showInstagram;
    _showTwitter   = r.showTwitter;
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _cashierNameCtrl, _posIdCtrl, _taxIdCtrl, _paymentReferenceCtrl,
      _authCodeCtrl, _cardLast4Ctrl, _footerMessageCtrl, _qrDataCtrl,
      _websiteCtrl, _facebookCtrl, _instagramCtrl, _twitterCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyClient(ReceiptClient? client) {
    setState(() {
      _selectedClient = client;
      if (client != null && _titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = '${client.name} Receipt';
      }
    });
  }

  // SIGNATURE SYNC FIX: now also pushes the selected template's
  // signatureMode/signatureName/signatureImagePath straight onto
  // ReceiptProvider — mirrors quote_editor_screen.dart's _applyTemplate()
  // calling applyPaymentAndTermsFromTemplate(). Previously these three
  // fields were read off `template` nowhere in this method, so a
  // signature typed/picked on the Template sheet never reached
  // ReceiptData. Deliberately does NOT touch showSignature — visibility
  // is a Customise-step concern, like every show* toggle above, not
  // something template selection should force on/off.
  void _applyTemplate(ReceiptTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      _logoPath = template?.logoPath;
      _logoOffset = template?.logoOffset ?? Offset.zero;
      _logoScale = template?.logoScale ?? 1.0;
      _logoShape = template?.shape ?? LogoShape.roundedSquare;
      // Currency code now lives on the selected draft (see
      // CreateReceiptBottomSheet's own template-currency prefill for new
      // drafts) rather than a local controller here.
      _showLogo            = template?.showLogo ?? true;
      _showBusinessDetails = template?.showBusinessDetails ?? true;
      _showCustomerDetails = template?.showCustomerDetails ?? true;
      _showReceiptNumber   = template?.showReceiptNumber ?? true;
      _showDateTime        = template?.showDateTime ?? true;
      _showTaxLine         = template?.showTaxLine ?? true;
      _showDiscountLine    = template?.showDiscountLine ?? true;
      _showPaymentMethod   = template?.showPaymentMethod ?? true;
    });
    if (template == null) return;
    final provider = context.read<ReceiptProvider>();
    provider.updateSignatureMode(template.signatureMode);
    provider.updateSignatureName(template.signatureName);
    provider.updateSignatureImagePath(template.signatureImagePath);
  }

  // RECEIPT LIBRARY RESTRUCTURE PASS: client fields and receipt-detail
  // fields now come from _selectedReceiptDraft?.data, falling back to
  // whatever's already on the provider before any draft is selected.
  // Every other field (business info, logo, thermal/POS, social,
  // font/colour, toggles) is unchanged from before this pass.
  //
  // THANK YOU MESSAGE TOGGLE PASS: showThankYouMessage now comes from
  // this screen's own _showThankYouMessage state (same pattern as every
  // other show* toggle below). thankYouMessage's TEXT pulls from the
  // selected template when one's chosen — same pattern already used for
  // businessName/businessEmail/businessPhone/businessAddress above —
  // falling back to whatever's already on the provider.
  //
  // SIGNATURE SYNC FIX: showSignature/signatureMode/signatureName/
  // signatureImagePath/signatureFontSize/signatureFontFamily are now
  // carried forward from `existing` (the provider's current ReceiptData)
  // into this freshly-built ReceiptData. Previously none of the six were
  // included in this constructor call at all — since this method builds
  // a brand new ReceiptData from scratch every time it runs (on every
  // step transition), omitting them meant they silently reset to
  // ReceiptData()'s constructor defaults on every single _goToStep/
  // _nextStep call, wiping out anything set via _applyTemplate() above
  // OR set directly through Customise's own Signature section (which
  // writes straight to ReceiptProvider — see that section's note in
  // receipt_provider.dart). This is the same class of bug
  // quote_editor_screen.dart's CUSTOMISE OWNERSHIP PASS fixed for Quote.
  void _syncToProvider() {
    final provider = context.read<ReceiptProvider>();
    final existing = provider.currentReceiptData;
    final d = _selectedReceiptDraft?.data;

    final data = ReceiptData(
      businessName: _selectedTemplate?.businessName ?? '',
      businessEmail: _selectedTemplate?.businessEmail ?? '',
      businessPhone: _selectedTemplate?.businessPhone ?? '',
      businessAddress: _selectedTemplate?.businessAddress ?? '',
      businessLogoPath: _logoPath,
      businessLogoOffsetDx: _logoOffset.dx,
      businessLogoOffsetDy: _logoOffset.dy,
      businessLogoScale: _logoScale,
      businessLogoShape: _logoShape.storageName,
      businessLogoDisplaySize: _logoSize,
      clientName: _selectedClient?.name ?? d?.clientName ?? existing.clientName,
      clientEmail: _selectedClient?.email ?? d?.clientEmail ?? existing.clientEmail,
      clientPhone: _selectedClient?.phone ?? d?.clientPhone ?? existing.clientPhone,
      clientAddress: _selectedClient?.address ?? d?.clientAddress ?? existing.clientAddress,
      receiptNumber: d?.receiptNumber ?? existing.receiptNumber,
      paymentDate: d?.paymentDate ?? existing.paymentDate,
      notes: d?.notes ?? existing.notes,
      currency: d?.currency ?? existing.currency,
      currencySymbol: d?.currencySymbol ?? existing.currencySymbol,
      currencyDisplayMode: d?.currencyDisplayMode ?? existing.currencyDisplayMode,
      lineItems: (d?.lineItems ?? existing.lineItems).map((i) => i.copyWith()).toList(),
      taxRate: d?.taxRate ?? existing.taxRate,
      discountRate: d?.discountRate ?? existing.discountRate,
      // TAX/DISCOUNT TOGGLE + NAME PASS: these now live on the selected
      // draft too (see receipt_data.dart), same fallback pattern as
      // taxRate/discountRate above.
      taxEnabled: d?.taxEnabled ?? existing.taxEnabled,
      discountEnabled: d?.discountEnabled ?? existing.discountEnabled,
      taxName: d?.taxName ?? existing.taxName,
      discountName: d?.discountName ?? existing.discountName,
      paymentMethod: d?.paymentMethod ?? existing.paymentMethod,
      status: existing.status,
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      colorScheme: _colorScheme,
      layoutTemplateId: _layoutTemplateId,
      paperFormat: _paperFormat,
      cashierName: _cashierNameCtrl.text,
      posId: _posIdCtrl.text,
      taxId: _taxIdCtrl.text,
      paymentReference: _paymentReferenceCtrl.text,
      authCode: _authCodeCtrl.text,
      cardLast4: _cardLast4Ctrl.text,
      showLogo: _showLogo,
      showBusinessDetails: _showBusinessDetails,
      showCustomerDetails: _showCustomerDetails,
      showReceiptNumber: _showReceiptNumber,
      showDateTime: _showDateTime,
      showTaxLine: _showTaxLine,
      showDiscountLine: _showDiscountLine,
      showPaymentMethod: _showPaymentMethod,
      showCashierName: _showCashierName,
      showThankYouMessage: _showThankYouMessage,
      thankYouMessage: _selectedTemplate?.thankYouMessage ?? existing.thankYouMessage,
      showBarcode: _showBarcode,
      showQrCode: _showQrCode,
      qrData: _qrDataCtrl.text,
      footerMessage: _footerMessageCtrl.text,
      compactThermalLayout: _compactThermalLayout,
      showWebsite: _showWebsite,
      businessWebsite: _websiteCtrl.text,
      showFacebook: _showFacebook,
      facebookHandle: _facebookCtrl.text,
      showInstagram: _showInstagram,
      instagramHandle: _instagramCtrl.text,
      showTwitter: _showTwitter,
      twitterHandle: _twitterCtrl.text,
      excludeFromReports: existing.excludeFromReports,
      // SIGNATURE SYNC FIX: carried forward from the provider's current
      // ReceiptData instead of being dropped (which previously reset
      // every one of these to its constructor default on every sync).
      showSignature: existing.showSignature,
      signatureMode: existing.signatureMode,
      signatureName: existing.signatureName,
      signatureImagePath: existing.signatureImagePath,
      signatureFontSize: existing.signatureFontSize,
      signatureFontFamily: existing.signatureFontFamily,
    );
    provider.updateReceiptData(data);
  }

  // STEP-TAP BYPASS FIX (unchanged): tapping a step tab re-runs the same
  // per-step validation _nextStep() enforces when pressing Next.
  void _goToStep(int index) {
    if (index > _step) {
      for (int i = _step; i < index; i++) {
        final blocked = _stepBlockReason(i);
        if (blocked != null) {
          _showValidationError(blocked);
          return;
        }
      }
    }
    _syncToProvider();
    setState(() => _step = index);
  }

  /// Returns the validation message to show if step [i] isn't complete
  /// enough to move past, or null if it's fine to continue.
  String? _stepBlockReason(int i) {
    if (i == 1 && _selectedTemplate == null) {
      return 'Select or add a template to continue';
    }
    if (i == 2 && _selectedReceiptDraft == null) {
      return 'Select or create a receipt to continue';
    }
    return null;
  }

  void _showSelectionRequiredSnack(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Select or add a $what to continue')),
    );
  }

  // TOAST PARITY FIX: this SnackBar previously set
  // `behavior: SnackBarBehavior.floating`, which renders as a rounded,
  // margined bar that floats and overlaps the content above it. Quote's
  // equivalent toast (quote_editor_screen.dart's _showSnack()) never
  // sets `behavior` at all — leaving it at the SnackBar default of
  // SnackBarBehavior.fixed, a full-width bar docked directly above the
  // bottom nav bar with no overlap. Removed the `behavior:` line here so
  // Receipt's "Select or create a receipt to continue"/"Select or add a
  // template to continue" toasts now dock the same way Quote's does
  // (matching the identical fix applied to
  // step_create_invoice.dart's _continue()).
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _nextStep() {
    final blocked = _stepBlockReason(_step);
    if (blocked != null) {
      _showValidationError(blocked);
      return;
    }
    if (_step < _steps.length - 1) {
      _syncToProvider();
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  void _openFullPreview() {
    _syncToProvider();
    final provider = context.read<ReceiptProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const ReceiptFullPreviewScreen(),
        ),
      ),
    );
  }

  // RECEIPT LIBRARY RESTRUCTURE PASS: field-level validation (receipt
  // number, client name, line item descriptions, tax/discount range)
  // now lives entirely in CreateReceiptBottomSheet's own _validateForm()
  // — a draft can't be handed back to this screen unless it already
  // passed those checks. This screen's own final validation is reduced
  // to "was everything actually selected/entered".
  Future<void> _save() async {
    if (_selectedTemplate == null) {
      _showSelectionRequiredSnack('template');
      return;
    }
    if (_selectedReceiptDraft == null) {
      _showValidationError('Select or create a receipt before saving');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this receipt a title before saving')),
      );
      return;
    }
    setState(() => _saving = true);
    _syncToProvider();

    final provider = context.read<ReceiptProvider>();
    await provider.saveCurrentReceipt(
      title: _titleCtrl.text,
      templateName: 'Standard',
    );

    if (!mounted) return;
    setState(() => _saving = false);

    final id = provider.currentReceiptId;
    final saved = provider.savedReceipts.where((r) => r.id == id);
    if (saved.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // HISTORY WIRING: logs this save as a 'created' activity-feed event —
    // see history_screen.dart / history_provider.dart. Fire-and-forget:
    // history logging should never block or fail the actual save.
    unawaited(context.read<HistoryProvider>().logCreated(
          docType: HistoryDocType.receipt,
          docId: saved.first.id,
          docNumber: saved.first.data.receiptNumber,
          clientName: saved.first.data.clientName.isNotEmpty
              ? saved.first.data.clientName
              : null,
          amount: saved.first.data.amountPaid,
          currency: saved.first.data.currency,
        ));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SavedDocumentDetailScreen.receipt(saved.first)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          StepEditorHeader(
            title: 'Create Receipt',
            currentStep: _step,
            steps: _steps,
            accent: _accent,
            onBack: _prevStep,
            onStepTap: _goToStep,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReceiptStepNavBar(
        onBack: _prevStep,
        onNext: _nextStep,
        nextLabel: _step == _steps.length - 1 ? 'Save Receipt' : 'Next',
        nextIcon: _step == _steps.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
        isLoading: _saving,
        accent: _accent,
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _customerStep();
      case 1:
        return _templateStep();
      case 2:
        return _createReceiptStep();
      default:
        return _customiseStepWidget();
    }
  }

  Widget _selectionStatus({required bool selected, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? const Color(0xFF2E7D32) : _accent;
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

  Widget _customerStep() {
    final label = _selectedClient == null
        ? 'Select a saved customer, or enter one manually on the next Create Receipt step.'
        : 'Using "${_selectedClient!.name}" for this receipt.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptStepCustomerSection(
          accent: _accent,
          onClientSelected: _applyClient,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedClient != null, label: label),
      ],
    );
  }

  Widget _templateStep() {
    final label = _selectedTemplate == null
        ? 'Select or add a template above to continue.'
        : 'Using "${_selectedTemplate!.name.isNotEmpty ? _selectedTemplate!.name : _selectedTemplate!.businessName}" for this receipt.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptStepTemplateSection(
          accent: _accent,
          onTemplateSelected: _applyTemplate,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedTemplate != null, label: label),
      ],
    );
  }

  // RECEIPT LIBRARY RESTRUCTURE PASS: now just embeds StepCreateReceipt
  // (step_create_receipt/step_create_receipt.dart) — the entire form has
  // moved into CreateReceiptBottomSheet, opened from that library
  // screen.
  Widget _createReceiptStep() {
    return StepCreateReceipt(
      accent: _accent,
      selectedClient: _selectedClient,
      selectedTemplate: _selectedTemplate,
      onDraftSelected: (draft) {
        setState(() => _selectedReceiptDraft = draft);
        _syncToProvider();
      },
    );
  }

  Widget _customiseStepWidget() {
    return ReceiptStepCustomise(
      accent: _accent,
      titleCtrl: _titleCtrl,
      isThermal: _isThermal,
      // PAPER FORMAT PICKER PASS: _paperFormat is now live-editable from
      // this step (previously only ever set once in initState). Picking
      // a different option in the new picker calls this callback, which
      // updates _paperFormat (and therefore _isThermal, computed off it)
      // and re-syncs the provider so _ReceiptPreviewCard's context.watch
      // picks up the change instantly.
      paperFormat: receiptPaperFormatFromString(_paperFormat),
      onPaperFormatChanged: (f) {
        setState(() => _paperFormat = f.storageName);
        _syncToProvider();
      },
      logoPath: _logoPath,
      logoOffset: _logoOffset,
      logoScale: _logoScale,
      logoShape: _logoShape,
      logoSize: _logoSize,
      onLogoChanged: (path, offset, scale, shape) {
        setState(() {
          _logoPath = path;
          _logoOffset = offset;
          _logoScale = scale;
          _logoShape = shape;
        });
        _syncToProvider();
      },
      onLogoShapeChanged: (s) {
        setState(() => _logoShape = s);
        _syncToProvider();
      },
      onLogoSizeChanged: (v) {
        setState(() => _logoSize = v);
        _syncToProvider();
      },
      colorScheme: _colorScheme,
      onColorSchemeChanged: (c) {
        setState(() => _colorScheme = c);
        _syncToProvider();
      },
      fontFamily: _fontFamily,
      onFontFamilyChanged: (f) {
        setState(() => _fontFamily = f);
        _syncToProvider();
      },
      fontSize: _fontSize,
      onFontSizeChanged: (v) {
        setState(() => _fontSize = v);
        _syncToProvider();
      },
      showLogo: _showLogo,
      showBusinessDetails: _showBusinessDetails,
      showCustomerDetails: _showCustomerDetails,
      showReceiptNumber: _showReceiptNumber,
      showDateTime: _showDateTime,
      showTaxLine: _showTaxLine,
      showDiscountLine: _showDiscountLine,
      showPaymentMethod: _showPaymentMethod,
      showCashierName: _showCashierName,
      showThankYouMessage: _showThankYouMessage,
      onShowLogoChanged: (v) { setState(() => _showLogo = v); _syncToProvider(); },
      onShowBusinessDetailsChanged: (v) { setState(() => _showBusinessDetails = v); _syncToProvider(); },
      onShowCustomerDetailsChanged: (v) { setState(() => _showCustomerDetails = v); _syncToProvider(); },
      onShowReceiptNumberChanged: (v) { setState(() => _showReceiptNumber = v); _syncToProvider(); },
      onShowDateTimeChanged: (v) { setState(() => _showDateTime = v); _syncToProvider(); },
      onShowTaxLineChanged: (v) { setState(() => _showTaxLine = v); _syncToProvider(); },
      onShowDiscountLineChanged: (v) { setState(() => _showDiscountLine = v); _syncToProvider(); },
      onShowPaymentMethodChanged: (v) { setState(() => _showPaymentMethod = v); _syncToProvider(); },
      onShowCashierNameChanged: (v) { setState(() => _showCashierName = v); _syncToProvider(); },
      onShowThankYouMessageChanged: (v) { setState(() => _showThankYouMessage = v); _syncToProvider(); },
      cashierNameCtrl: _cashierNameCtrl,
      posIdCtrl: _posIdCtrl,
      taxIdCtrl: _taxIdCtrl,
      paymentReferenceCtrl: _paymentReferenceCtrl,
      authCodeCtrl: _authCodeCtrl,
      cardLast4Ctrl: _cardLast4Ctrl,
      footerMessageCtrl: _footerMessageCtrl,
      qrDataCtrl: _qrDataCtrl,
      websiteCtrl: _websiteCtrl,
      facebookCtrl: _facebookCtrl,
      instagramCtrl: _instagramCtrl,
      twitterCtrl: _twitterCtrl,
      showBarcode: _showBarcode,
      showQrCode: _showQrCode,
      compactThermalLayout: _compactThermalLayout,
      showWebsite: _showWebsite,
      showFacebook: _showFacebook,
      showInstagram: _showInstagram,
      showTwitter: _showTwitter,
      onShowBarcodeChanged: (v) { setState(() => _showBarcode = v); _syncToProvider(); },
      onShowQrCodeChanged: (v) { setState(() => _showQrCode = v); _syncToProvider(); },
      onCompactLayoutChanged: (v) { setState(() => _compactThermalLayout = v); _syncToProvider(); },
      onShowWebsiteChanged: (v) { setState(() => _showWebsite = v); _syncToProvider(); },
      onShowFacebookChanged: (v) { setState(() => _showFacebook = v); _syncToProvider(); },
      onShowInstagramChanged: (v) { setState(() => _showInstagram = v); _syncToProvider(); },
      onShowTwitterChanged: (v) { setState(() => _showTwitter = v); _syncToProvider(); },
      subtotal: _draftData.subtotal,
      taxAmount: _draftData.taxAmount,
      discountAmount: _draftData.discountAmount,
      amountPaid: _draftData.amountPaid,
      taxRate: _draftData.taxRate,
      discountRate: _draftData.discountRate,
      currencySymbol: _currencyPrefix,
      onOpenFullPreview: _openFullPreview,
    );
  }
}