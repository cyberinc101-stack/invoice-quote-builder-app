// lib/create_receipt/create_receipt_screen.dart
//
// RECEIPT LIBRARY RESTRUCTURE PASS (this update): mirrors Invoice/Quote's
// own library restructure. The entire _createReceiptStep() body (receipt
// number, payment date, currency, client override, payment method, Saved
// Item Sets panel, line items, tax/discount, notes) has moved out into a
// bottom sheet (create_receipt/create_receipt_bottom_sheet.dart,
// CreateReceiptBottomSheet), opened from a new library screen embedded
// at this step (create_receipt/step_create_receipt.dart,
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
import '../providers/receipt_provider.dart';
import '../providers/history_provider.dart';
import '../models/receipt_data.dart';
import '../models/history_event.dart';
import '../widgets/step_editor_header.dart';
import '../widgets/shared_logo_picker.dart';
import '../screens/saved_invoice_details_section/saved_document_detail_screen.dart';
import 'receipt_edit_widgets.dart';
import 'receipt_full_preview_screen.dart';
import 'receipt_step_customer.dart';
import 'receipt_step_template.dart';
import 'receipt_step_customise.dart';
import 'receipt_paper_format.dart';
import 'step_create_receipt.dart';

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
  }

  // RECEIPT LIBRARY RESTRUCTURE PASS: client fields and receipt-detail
  // fields now come from _selectedReceiptDraft?.data, falling back to
  // whatever's already on the provider before any draft is selected.
  // Every other field (business info, logo, thermal/POS, social,
  // font/colour, toggles) is unchanged from before this pass.
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

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
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
  // (create_receipt/step_create_receipt.dart) — the entire form has
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
      onShowLogoChanged: (v) { setState(() => _showLogo = v); _syncToProvider(); },
      onShowBusinessDetailsChanged: (v) { setState(() => _showBusinessDetails = v); _syncToProvider(); },
      onShowCustomerDetailsChanged: (v) { setState(() => _showCustomerDetails = v); _syncToProvider(); },
      onShowReceiptNumberChanged: (v) { setState(() => _showReceiptNumber = v); _syncToProvider(); },
      onShowDateTimeChanged: (v) { setState(() => _showDateTime = v); _syncToProvider(); },
      onShowTaxLineChanged: (v) { setState(() => _showTaxLine = v); _syncToProvider(); },
      onShowDiscountLineChanged: (v) { setState(() => _showDiscountLine = v); _syncToProvider(); },
      onShowPaymentMethodChanged: (v) { setState(() => _showPaymentMethod = v); _syncToProvider(); },
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
