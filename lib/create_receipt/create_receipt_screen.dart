// lib/create_receipt/create_receipt_screen.dart
//
// CUSTOMER STEP RENAME PASS (this update): the "Client" step is now
// "Customer" throughout — StepMeta label, the ReceiptStepCustomerSection
// widget (was ReceiptClientLibrarySection, now living in
// receipt_step_customer.dart instead of receipt_client_library.dart),
// and the step's own helper text. Mirrors the identical rename just
// done for the quote flow (quote_client_library.dart ->
// quote_step_customer.dart). Naming/wording + import-path change only —
// _selectedClient stays typed as ReceiptClient and every provider field
// (clientName, etc.) is untouched.
//
// Also applied the CURRENCY SYMBOL CONDITIONAL fix from
// step_create_invoice.dart / quote_step_customer.dart to this screen's
// own inline Currency Symbol field on the Create Receipt step: the field
// now only shows once Symbol or Both is picked in Display Format.
//
// STEP REORDER PASS (earlier): step order now matches the invoice
// flow's skeleton — Customer → Template → Create Receipt → Customise —
// instead of Template → Client & Details → Line Items → Customise.
// Customer selection is now its own standalone first step, Template
// stays step 1, and receipt number/date/currency/payment method/notes +
// line items + tax/discount are combined into a single "Create Receipt"
// step (mirrors invoice's step_create_invoice.dart).
//
// NO-CLIENT INLINE FIELDS PASS (earlier): mirrors invoice's
// step_create_invoice.dart — if no customer was selected on the
// Customer step, the Create Receipt step shows inline "Client Details"
// fields (name/email/phone/address) so the receipt can still be filled
// out without forcing a saved customer to be created first.
//
// FIELD VISIBILITY RELOCATION PASS (earlier): last step renamed
// "Customise"; for A4 receipts a live "Receipt Fields"/"Customer
// Fields" toggle section sits above Live Preview; thermal keeps its own
// live toggle section further down the same step
// (ReceiptThermalSettingsSection).
//
// TEMPLATE UNIFICATION PASS (earlier): a single saved, reusable
// ReceiptTemplate replaces the old separate business-profile library +
// inline non-reusable toggle step.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';
import '../models/receipt_data.dart';
import '../models/invoice_data.dart' show LineItem;
import '../widgets/step_editor_header.dart';
import '../widgets/shared_logo_picker.dart';
import '../screens/saved_invoice_details_section/saved_document_detail_screen.dart';
import 'receipt_edit_widgets.dart';
import 'receipt_full_preview_screen.dart';
import 'receipt_step_customer.dart';
import 'receipt_step_template.dart';
import 'receipt_paper_format.dart';
import 'receipt_thermal_settings.dart';
import 'receipt_thermal_live_preview.dart';
import 'receipt_template_chooser_01/preview_registry.dart' show buildReceiptPreview;
import '../document_layout_templates/01_executive/executive_receipt_logic_data.dart';
import '../document_layout_templates/01_executive/executive_receipt_stationary_layout.dart' show kPageW;
import '../document_layout_templates/pagination/scaled_page_stack.dart';

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

  // CUSTOMER STEP RENAME PASS: Customer is step 0 (standalone), Template
  // is step 1, receipt details + line items are combined into "Create
  // Receipt" at step 2, Customise stays last at step 3.
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

  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  double _logoSize = 44.0;

  late TextEditingController _receiptNumber;
  late TextEditingController _notes;
  String _paymentDate = '';

  // NO-CLIENT INLINE FIELDS PASS: manual client override fields, shown
  // on Create Receipt only when _selectedClient is null.
  late TextEditingController _custNameCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;
  late TextEditingController _custAddressCtrl;

  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code';

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  late List<TextEditingController> _descCtrls;
  late List<TextEditingController> _qtyCtrls;
  late List<TextEditingController> _priceCtrls;
  double _taxRate = 0.0;
  double _discountRate = 0.0;

  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;

  ReceiptColor _colorScheme = ReceiptColor.green;
  late TextEditingController _titleCtrl;

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

  String get _currencyPrefix {
    final symbol = _currencySymbolCtrl.text.trim();
    final code = _currencyCodeCtrl.text.trim().toUpperCase();
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

    final now = DateTime.now();
    _receiptNumber = TextEditingController(
      text: r.receiptNumber.isNotEmpty ? r.receiptNumber : 'R-${now.millisecondsSinceEpoch.toString().substring(7)}',
    );
    _notes         = TextEditingController(text: r.notes);
    _paymentDate   = r.paymentDate.isNotEmpty ? r.paymentDate : DateFormat('d MMM yyyy').format(now);

    _custNameCtrl    = TextEditingController(text: r.clientName);
    _custEmailCtrl   = TextEditingController(text: r.clientEmail);
    _custPhoneCtrl   = TextEditingController(text: r.clientPhone);
    _custAddressCtrl = TextEditingController(text: r.clientAddress);

    _currencyCodeCtrl = TextEditingController(text: r.currency.isNotEmpty ? r.currency : 'USD');
    _currencySymbolCtrl = TextEditingController(text: r.currencySymbol);
    _currencyDisplayMode = r.currencyDisplayMode.isNotEmpty ? r.currencyDisplayMode : 'code';
    _taxRate       = r.taxRate;
    _discountRate  = r.discountRate;
    _paymentMethod = r.paymentMethod;
    _colorScheme   = r.colorScheme;

    _taxCtrl      = TextEditingController(text: _taxRate == 0 ? '' : '$_taxRate');
    _discountCtrl = TextEditingController(text: _discountRate == 0 ? '' : '$_discountRate');

    final items = r.lineItems.isNotEmpty ? r.lineItems : [LineItem()];
    _descCtrls  = items.map((i) => TextEditingController(text: i.description)).toList();
    _qtyCtrls   = items.map((i) => TextEditingController(text: i.quantity == 1.0 ? '1' : '${i.quantity}')).toList();
    _priceCtrls = items.map((i) => TextEditingController(text: i.unitPrice == 0.0 ? '' : '${i.unitPrice}')).toList();

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
      _receiptNumber, _notes, _titleCtrl, _taxCtrl, _discountCtrl,
      _currencyCodeCtrl, _currencySymbolCtrl,
      _custNameCtrl, _custEmailCtrl, _custPhoneCtrl, _custAddressCtrl,
      _cashierNameCtrl, _posIdCtrl, _taxIdCtrl, _paymentReferenceCtrl,
      _authCodeCtrl, _cardLast4Ctrl, _footerMessageCtrl, _qrDataCtrl,
      _websiteCtrl, _facebookCtrl, _instagramCtrl, _twitterCtrl,
      ..._descCtrls, ..._qtyCtrls, ..._priceCtrls,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<LineItem> get _currentLineItems => List.generate(_descCtrls.length, (i) {
        return LineItem(
          description: _descCtrls[i].text,
          quantity: double.tryParse(_qtyCtrls[i].text) ?? 1.0,
          unitPrice: double.tryParse(_priceCtrls[i].text) ?? 0.0,
        );
      });

  double get _subtotal => _currentLineItems.fold(0.0, (s, i) => s + i.total);
  double get _discountAmount => _subtotal * (_discountRate / 100);
  double get _taxAmount => (_subtotal - _discountAmount) * (_taxRate / 100);
  double get _amountPaid => _subtotal - _discountAmount + _taxAmount;

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
      _currencyCodeCtrl.text = template?.currency ?? 'USD';
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

  // NO-CLIENT INLINE FIELDS PASS: client fields come from the selected
  // ReceiptClient if one is chosen, otherwise from the inline manual
  // fields on the Create Receipt step.
  void _syncToProvider() {
    final provider = context.read<ReceiptProvider>();
    final existing = provider.currentReceiptData;
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
      clientName: _selectedClient?.name ?? _custNameCtrl.text.trim(),
      clientEmail: _selectedClient?.email ?? _custEmailCtrl.text.trim(),
      clientPhone: _selectedClient?.phone ?? _custPhoneCtrl.text.trim(),
      clientAddress: _selectedClient?.address ?? _custAddressCtrl.text.trim(),
      receiptNumber: _receiptNumber.text,
      paymentDate: _paymentDate,
      notes: _notes.text,
      currency: _currencyCodeCtrl.text.trim().isEmpty
          ? 'USD'
          : _currencyCodeCtrl.text.trim().toUpperCase(),
      currencySymbol: _currencySymbolCtrl.text.trim(),
      currencyDisplayMode: _currencyDisplayMode,
      lineItems: _currentLineItems,
      taxRate: _taxRate,
      discountRate: _discountRate,
      paymentMethod: _paymentMethod,
      status: existing.status,
      fontFamily: existing.fontFamily,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paymentDate = DateFormat('d MMM yyyy').format(picked));
    }
  }

  void _addLineItem() {
    setState(() {
      _descCtrls.add(TextEditingController());
      _qtyCtrls.add(TextEditingController(text: '1'));
      _priceCtrls.add(TextEditingController());
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _descCtrls.removeAt(index).dispose();
      _qtyCtrls.removeAt(index).dispose();
      _priceCtrls.removeAt(index).dispose();
    });
  }

  // STEP-TAP BYPASS FIX: same fix applied to the quote flow — tapping a
  // step tab in the header used to jump straight there regardless of
  // whether earlier steps were actually filled in. Forward jumps now
  // re-run the same per-step validation _nextStep() does, stopping at
  // the first unmet requirement. Backward jumps are always allowed.
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
  /// enough to move past, or null if it's fine to continue. Mirrors the
  /// per-step checks in _nextStep(), factored out so both the Next
  /// button and step-tap navigation enforce the same rules.
  String? _stepBlockReason(int i) {
    if (i == 1 && _selectedTemplate == null) {
      return 'Select or add a template to continue';
    }
    if (i == 2) {
      if (_receiptNumber.text.trim().isEmpty) {
        return 'Please enter a receipt number.';
      }
      if (_selectedClient == null && _custNameCtrl.text.trim().isEmpty) {
        return 'Please enter a client name.';
      }
      for (final c in _descCtrls) {
        if (c.text.trim().isEmpty) {
          return 'Please fill in all item descriptions.';
        }
      }
      if (_discountRate < 0 || _discountRate > 100) {
        return 'Discount must be between 0 and 100%.';
      }
      if (_taxRate < 0) {
        return 'Tax rate cannot be negative.';
      }
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

  bool _validateDetailsStep() {
    if (_receiptNumber.text.trim().isEmpty) {
      _showValidationError('Please enter a receipt number.');
      return false;
    }
    if (_selectedClient == null && _custNameCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a client name.');
      return false;
    }
    return true;
  }

  bool _validateLineItemsStep() {
    for (final c in _descCtrls) {
      if (c.text.trim().isEmpty) {
        _showValidationError('Please fill in all item descriptions.');
        return false;
      }
    }

    if (_discountRate < 0 || _discountRate > 100) {
      _showValidationError('Discount must be between 0 and 100%.');
      return false;
    }

    if (_taxRate < 0) {
      _showValidationError('Tax rate cannot be negative.');
      return false;
    }

    return true;
  }

  // STEP REORDER PASS: step 1 (Template) requires a selection; step 2
  // (Create Receipt) validates receipt number/client name/items/tax/
  // discount; step 3 (Customise) is the "else" branch -> _save().
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

  Future<void> _save() async {
    if (_selectedTemplate == null) {
      _showSelectionRequiredSnack('template');
      return;
    }
    if (!_validateDetailsStep()) return;
    if (!_validateLineItemsStep()) return;

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
        return _customiseStep();
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

  // CUSTOMER STEP RENAME PASS: renamed from _clientStep(); now renders
  // ReceiptStepCustomerSection (receipt_step_customer.dart) instead of
  // the old ReceiptClientLibrarySection.
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

  // STEP REORDER PASS: merges the old Client & Details receipt-detail
  // fields with the old Line Items step into one "Create Receipt" step.
  //
  // NO-CLIENT INLINE FIELDS PASS: if no customer was picked on the
  // Customer step, a "Client Details" section appears here so the
  // receipt can still be filled in manually.
  Widget _createReceiptStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Receipt Details', _accent, icon: Icons.receipt_rounded),
        ReceiptField(ctrl: _receiptNumber, label: 'Receipt Number', accent: _accent, icon: Icons.tag_rounded, max: 40),
        const SizedBox(height: 12),
        ReceiptDateField(label: 'Payment Date', value: _paymentDate, accent: _accent, onTap: _pickDate),
        const SizedBox(height: 20),

        receiptSectionHeader(context, 'Currency', _accent, icon: Icons.attach_money_rounded),
        // CURRENCY SYMBOL CONDITIONAL: Display Format picker sits above,
        // and the Currency Symbol field below only renders once Symbol/
        // Both is picked — matches step_create_invoice.dart /
        // receipt_step_customer.dart.
        _ReceiptCurrencyDisplayModeSelector(
          value: _currencyDisplayMode,
          accent: _accent,
          onChanged: (mode) => setState(() => _currencyDisplayMode = mode),
          previewCode: _currencyCodeCtrl.text.trim().isEmpty
              ? 'USD'
              : _currencyCodeCtrl.text.trim().toUpperCase(),
          previewSymbol: _currencySymbolCtrl.text.trim(),
        ),
        if (_currencyDisplayMode != 'code') ...[
          const SizedBox(height: 12),
          ReceiptField(
            ctrl: _currencySymbolCtrl,
            label: 'Currency Symbol',
            accent: _accent,
            icon: Icons.currency_exchange_rounded,
            max: 6,
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 20),

        // NO-CLIENT INLINE FIELDS PASS: only shown when no saved
        // customer was picked on the Customer step.
        if (_selectedClient == null) ...[
          receiptSectionHeader(context, 'Client Details', _accent, icon: Icons.person_rounded),
          ReceiptField(
            ctrl: _custNameCtrl,
            label: 'Client Name',
            accent: _accent,
            icon: Icons.person_rounded,
            max: 100,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ReceiptField(
            ctrl: _custEmailCtrl,
            label: 'Client Email',
            accent: _accent,
            icon: Icons.email_rounded,
            max: 100,
            keyboard: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ReceiptField(
            ctrl: _custPhoneCtrl,
            label: 'Client Phone',
            accent: _accent,
            icon: Icons.phone_rounded,
            max: 20,
            keyboard: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ReceiptField(
            ctrl: _custAddressCtrl,
            label: 'Client Address',
            accent: _accent,
            icon: Icons.location_on_rounded,
            max: 200,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
        ],

        receiptSectionHeader(context, 'Payment Method', _accent, icon: Icons.payments_rounded),
        ReceiptPaymentMethodPicker(
          selected: _paymentMethod,
          accent: _accent,
          onChanged: (m) => setState(() => _paymentMethod = m),
        ),
        const SizedBox(height: 20),

        receiptSectionHeader(context, 'Line Items', _accent, icon: Icons.list_alt_rounded),
        ...List.generate(_descCtrls.length, (i) {
          final qty = double.tryParse(_qtyCtrls[i].text) ?? 0.0;
          final price = double.tryParse(_priceCtrls[i].text) ?? 0.0;
          return ReceiptItemCard(
            index: i,
            descCtrl: _descCtrls[i],
            qtyCtrl: _qtyCtrls[i],
            priceCtrl: _priceCtrls[i],
            total: qty * price,
            currencySymbol: _currencyPrefix,
            canRemove: _descCtrls.length > 1,
            accent: _accent,
            onRemove: () => _removeLineItem(i),
            onChanged: () => setState(() {}),
          );
        }),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _addLineItem,
          icon: Icon(Icons.add_rounded, color: _accent),
          label: Text('Add Item', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _accent.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        receiptSectionHeader(context, 'Tax & Discount', _accent, icon: Icons.percent_rounded),
        Row(
          children: [
            Expanded(
              child: ReceiptField(
                ctrl: _taxCtrl,
                label: 'Tax %',
                accent: _accent,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                max: 5,
                extraFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (v) => setState(() => _taxRate = double.tryParse(v) ?? 0.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReceiptField(
                ctrl: _discountCtrl,
                label: 'Discount %',
                accent: _accent,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                max: 5,
                extraFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (v) => setState(() => _discountRate = double.tryParse(v) ?? 0.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ReceiptTotalsCard(
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          amountPaid: _amountPaid,
          taxRate: _taxRate,
          discountRate: _discountRate,
          currencySymbol: _currencyPrefix,
          accent: _accent,
        ),
        const SizedBox(height: 20),

        // NOTES PLACEMENT PASS: moved below the totals card, matching
        // Invoice's step_create_invoice.dart layout (Notes / Payment
        // Terms sits right after the Totals card there) — professional
        // convention is notes/terms trailing the numbers, not sitting up
        // near Payment Method disconnected from the total they refer to.
        receiptSectionHeader(context, 'Additional Info', _accent, icon: Icons.notes_rounded),
        ReceiptField(
          ctrl: _notes,
          label: 'Notes',
          accent: _accent,
          icon: Icons.notes_rounded,
          maxLines: 3,
          max: _isThermal ? 200 : 500,
        ),
      ],
    );
  }

  Widget _fieldToggleRow(String label, bool value, ValueChanged<bool> onChanged, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.white,
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 10),
            ],
            Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
          ],
        ),
        value: value,
        activeThumbColor: _accent,
        onChanged: (v) {
          setState(() => onChanged(v));
          _syncToProvider();
        },
      ),
    );
  }

  Widget _receiptFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Receipt Fields', _accent, icon: Icons.tune_rounded),
        Text(
          'Toggle which fields appear on the generated receipt.',
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 10),
        _fieldToggleRow('Business Logo', _showLogo, (v) => _showLogo = v),
        _fieldToggleRow('Business Details (address/phone/email)', _showBusinessDetails, (v) => _showBusinessDetails = v),
        _fieldToggleRow('Receipt Number', _showReceiptNumber, (v) => _showReceiptNumber = v),
        _fieldToggleRow('Date/Time', _showDateTime, (v) => _showDateTime = v),
        _fieldToggleRow('Payment Method', _showPaymentMethod, (v) => _showPaymentMethod = v),
        _fieldToggleRow('Tax Line', _showTaxLine, (v) => _showTaxLine = v),
        _fieldToggleRow('Discount Line', _showDiscountLine, (v) => _showDiscountLine = v),
        const SizedBox(height: 12),
        receiptSectionHeader(context, 'Customer Fields', _accent, icon: Icons.person_rounded),
        _fieldToggleRow('Customer Details (name/email/phone/address)', _showCustomerDetails, (v) => _showCustomerDetails = v),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _customiseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Receipt Title', _accent, icon: Icons.title_rounded),
        ReceiptField(ctrl: _titleCtrl, label: 'Title (for your records)', accent: _accent, icon: Icons.bookmark_outline_rounded, required: true, max: 80),
        const SizedBox(height: 24),

        receiptSectionHeader(context, 'Live Preview', _accent, icon: Icons.visibility_rounded),
        const _ReceiptPreviewCard(),
        const SizedBox(height: 24),

        receiptSectionHeader(context, 'Business Logo', _accent, icon: Icons.image_rounded),
        Builder(builder: (context) {
          final hasLogo = _logoPath != null && _logoPath!.isNotEmpty;
          final previewSize = (90.0 + (_logoSize - 40.0) * 3.0).clamp(90.0, 220.0);
          return Column(
            children: [
              Center(
                child: Opacity(
                  opacity: hasLogo ? 1.0 : 0.5,
                  child: SharedLogoPicker(
                    logoPath: _logoPath,
                    logoOffset: _logoOffset,
                    logoScale: _logoScale,
                    logoShape: _logoShape,
                    accent: _accent,
                    compact: true,
                    compactBoxSize: previewSize,
                    onChanged: (path, offset, scale, shape) {
                      setState(() {
                        _logoPath = path;
                        _logoOffset = offset;
                        _logoScale = scale;
                        _logoShape = shape;
                      });
                      _syncToProvider();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasLogo ? 'Tap logo to change, reposition, or remove' : 'Tap to upload a logo',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: hasLogo ? 1.0 : 0.4,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: LogoShape.values.map((s) {
                    final selected = s == _logoShape;
                    return GestureDetector(
                      onTap: hasLogo
                          ? () {
                              setState(() => _logoShape = s);
                              _syncToProvider();
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _accent.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? _accent : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.icon, size: 16, color: selected ? _accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 5),
                            Text(s.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? _accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 16),

        receiptSectionHeader(context, 'Logo Size', _accent, icon: Icons.photo_size_select_large_rounded),
        Opacity(
          opacity: (_logoPath != null && _logoPath!.isNotEmpty) ? 1.0 : 0.4,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.image_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _accent,
                        inactiveTrackColor: _accent.withValues(alpha: 0.2),
                        thumbColor: _accent,
                        overlayColor: _accent.withValues(alpha: 0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _logoSize,
                        min: 24,
                        max: 60,
                        divisions: 9,
                        onChanged: (_logoPath != null && _logoPath!.isNotEmpty)
                            ? (v) {
                                setState(() => _logoSize = v);
                                _syncToProvider();
                              }
                            : null,
                      ),
                    ),
                  ),
                  Icon(Icons.image_outlined, size: 24, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ],
              ),
              Text(
                (_logoPath != null && _logoPath!.isNotEmpty) ? '${_logoSize.toInt()}px' : 'Add a logo to enable',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_isThermal) ...[
          ReceiptThermalSettingsSection(
            accent: _accent,
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
            compactLayout: _compactThermalLayout,
            showWebsite: _showWebsite,
            showFacebook: _showFacebook,
            showInstagram: _showInstagram,
            showTwitter: _showTwitter,
            onShowLogoChanged: (v) { setState(() => _showLogo = v); _syncToProvider(); },
            onShowBusinessDetailsChanged: (v) { setState(() => _showBusinessDetails = v); _syncToProvider(); },
            onShowCustomerDetailsChanged: (v) { setState(() => _showCustomerDetails = v); _syncToProvider(); },
            onShowReceiptNumberChanged: (v) { setState(() => _showReceiptNumber = v); _syncToProvider(); },
            onShowDateTimeChanged: (v) { setState(() => _showDateTime = v); _syncToProvider(); },
            onShowTaxLineChanged: (v) { setState(() => _showTaxLine = v); _syncToProvider(); },
            onShowDiscountLineChanged: (v) { setState(() => _showDiscountLine = v); _syncToProvider(); },
            onShowPaymentMethodChanged: (v) { setState(() => _showPaymentMethod = v); _syncToProvider(); },
            onShowBarcodeChanged: (v) { setState(() => _showBarcode = v); _syncToProvider(); },
            onShowQrCodeChanged: (v) { setState(() => _showQrCode = v); _syncToProvider(); },
            onCompactLayoutChanged: (v) { setState(() => _compactThermalLayout = v); _syncToProvider(); },
            onShowWebsiteChanged: (v) { setState(() => _showWebsite = v); _syncToProvider(); },
            onShowFacebookChanged: (v) { setState(() => _showFacebook = v); _syncToProvider(); },
            onShowInstagramChanged: (v) { setState(() => _showInstagram = v); _syncToProvider(); },
            onShowTwitterChanged: (v) { setState(() => _showTwitter = v); _syncToProvider(); },
          ),
          const SizedBox(height: 24),
        ] else ...[
          receiptSectionHeader(context, 'Accent Color', _accent, icon: Icons.palette_outlined),
          ReceiptColorPicker(
            selected: _colorScheme,
            onChanged: (c) {
              setState(() => _colorScheme = c);
              _syncToProvider();
            },
          ),
          const SizedBox(height: 24),

          // FIELD VISIBILITY RELOCATION PASS (position fix): moved to
          // sit after Accent Color rather than above Live Preview —
          // matches where invoice's own field-visibility section sits
          // relative to its Font/Size controls. Only shown for A4;
          // thermal keeps its own live toggle section
          // (ReceiptThermalSettingsSection) in the branch above.
          _receiptFieldsSection(),
        ],

        receiptSectionHeader(context, 'Summary', _accent, icon: Icons.summarize_rounded),
        ReceiptTotalsCard(
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          amountPaid: _amountPaid,
          taxRate: _taxRate,
          discountRate: _discountRate,
          currencySymbol: _currencyPrefix,
          accent: _accent,
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: _openFullPreview,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x504CAF50), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.preview_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Preview & Download',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptCurrencyDisplayModeSelector extends StatelessWidget {
  final String value;
  final Color accent;
  final ValueChanged<String> onChanged;
  final String previewCode;
  final String previewSymbol;

  const _ReceiptCurrencyDisplayModeSelector({
    required this.value,
    required this.accent,
    required this.onChanged,
    required this.previewCode,
    required this.previewSymbol,
  });

  String _previewFor(String mode) {
    const amount = '200.00';
    final hasSymbol = previewSymbol.trim().isNotEmpty;
    final hasCode = previewCode.trim().isNotEmpty;
    switch (mode) {
      case 'symbol':
        return hasSymbol ? '$previewSymbol$amount' : (hasCode ? '$previewCode $amount' : amount);
      case 'both':
        if (hasSymbol && hasCode) return '$previewCode $previewSymbol$amount';
        if (hasSymbol) return '$previewSymbol$amount';
        return hasCode ? '$previewCode $amount' : amount;
      case 'code':
      default:
        return hasCode ? '$previewCode $amount' : (hasSymbol ? '$previewSymbol$amount' : amount);
    }
  }

  static const _options = [
    ('code', 'Code'),
    ('symbol', 'Symbol'),
    ('both', 'Both'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Format',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: _options.map((opt) {
              final (mode, label) = opt;
              final selected = value == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: selected ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _previewFor(mode),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.85)
                                : colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ReceiptPreviewCard extends StatelessWidget {
  const _ReceiptPreviewCard();

  static Color _accentFromScheme(ReceiptColor scheme) {
    const map = {
      ReceiptColor.blue:   Color(0xFF1565C0),
      ReceiptColor.green:  Color(0xFF2E7D32),
      ReceiptColor.purple: Color(0xFF6A1B9A),
      ReceiptColor.orange: Color(0xFFE65100),
      ReceiptColor.red:    Color(0xFFC62828),
      ReceiptColor.teal:   Color(0xFF00695C),
      ReceiptColor.black:  Color(0xFF212121),
      ReceiptColor.indigo: Color(0xFF283593),
    };
    return map[scheme] ?? const Color(0xFF2E7D32);
  }

  Widget _buildPreviewWidget(ReceiptData data) {
    return buildReceiptPreview(data.layoutTemplateId, data) ??
        ExecutiveReceiptPreview(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final data        = context.watch<ReceiptProvider>().currentReceiptData;
    final accent      = _accentFromScheme(data.colorScheme);
    final colorScheme = Theme.of(context).colorScheme;
    final format      = receiptPaperFormatFromString(data.paperFormat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text('Live Preview',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
          ]),
        ),
        if (format.isThermal)
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final nativeWidth = format.widthMm * 4.2;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: nativeWidth,
                      child: ThermalReceiptLivePreview(data: data, widthMm: format.widthMm),
                    ),
                  ),
                );
              },
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ScaledPageStack(
                    targetWidth: constraints.maxWidth,
                    nativePageWidth: kPageW,
                    child: _buildPreviewWidget(data),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Center(
          child: Text('Live preview - changes appear instantly.',
              style: TextStyle(fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }
}
