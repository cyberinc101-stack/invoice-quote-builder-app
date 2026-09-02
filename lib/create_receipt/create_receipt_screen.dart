// lib/create_receipt/create_receipt_screen.dart
//
// CUSTOMISE STEP EXTRACTION PASS (this update): the Customise step's
// UI (_customiseStep()/_fieldToggleRow()/_receiptFieldsSection() plus
// the private _ReceiptPreviewCard class) moved out into its own file,
// receipt_step_customise.dart — matching Invoice/Quote's convention of
// a dedicated step_customise.dart. This screen now just builds a
// ReceiptStepCustomise widget and hands it callbacks; every underlying
// field (logo, toggles, color scheme, etc.) is unchanged and still
// lives right here in _CreateReceiptScreenState.
//
// Also added _fontFamily/_fontSize state (new — Receipt previously had
// no UI for either, despite ReceiptData.fontSize already existing per
// receipt_data.dart's own FONT SIZE PASS). Initialized from
// currentReceiptData in initState() and written back in
// _syncToProvider(), same pattern already used for _colorScheme; no
// ReceiptProvider changes were needed since Receipt's customise state
// lives directly on this State object rather than routed through
// provider update methods the way Quote/Invoice's does.
//
// CUSTOMER STEP RENAME PASS (earlier update): the "Client" step is now
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
// FIELD VISIBILITY RELOCATION PASS (earlier, superseded): last step
// renamed "Customise"; the A4 field-toggle section's position has since
// moved again — see receipt_step_customise.dart's own REORDER PASS
// comment for where it sits now.
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
import 'receipt_step_customise.dart';
import 'receipt_paper_format.dart';

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

  // CUSTOMISE STEP EXTRACTION PASS: new — Receipt had a fontFamily field
  // synced straight through from `existing` (never editable) and no
  // fontSize UI at all. Now both are real editable state, same pattern
  // as _colorScheme above.
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
    _fontFamily    = r.fontFamily;
    _fontSize      = r.fontSize;

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
      // CUSTOMISE STEP EXTRACTION PASS: was `existing.fontFamily`
      // (never editable). Now both fontFamily and fontSize come from
      // this screen's own editable state, written by the new Font
      // Family / Text Size controls on receipt_step_customise.dart.
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

  // CUSTOMISE STEP EXTRACTION PASS: was _customiseStep() — now builds
  // the extracted ReceiptStepCustomise widget (receipt_step_customise.dart)
  // instead of the old inline Column. Every value/callback below maps
  // 1:1 onto what the old inline code read/wrote directly on this State.
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
      subtotal: _subtotal,
      taxAmount: _taxAmount,
      discountAmount: _discountAmount,
      amountPaid: _amountPaid,
      taxRate: _taxRate,
      discountRate: _discountRate,
      currencySymbol: _currencyPrefix,
      onOpenFullPreview: _openFullPreview,
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
