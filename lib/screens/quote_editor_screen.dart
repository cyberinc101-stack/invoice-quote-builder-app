// lib/screens/quote_editor_screen.dart
//
// CUSTOMER STEP RENAME PASS (this update): the "Client" step is now
// "Customer" throughout — StepMeta label, the QuoteStepCustomerSection
// widget (was QuoteClientLibrarySection, now living in
// create_quote_section/quote_step_customer.dart instead of
// quote_client_library.dart), and the step's own helper text. This is a
// naming/wording + import-path change only — _selectedClient stays typed
// as QuoteClient (unchanged model name) and every provider field
// (clientName, sourceClientId, etc.) is untouched, since renaming those
// would ripple into quote_data.dart and QuoteProvider outside the scope
// of this pass.
//
// FIELD VISIBILITY POSITION PASS (earlier): "Quote Fields" / "Client
// Fields" toggle section moved to sit directly under Live Preview (was
// after Accent Color). This now matches the same relative position used
// on the Receipt Customise step, and the Invoice Customise step once its
// equivalent field-visibility section is added there.
//
// STEP REORDER PASS (earlier): step order now matches the invoice
// flow's skeleton — Customer → Template → Create Quote → Customise —
// instead of Template → Client & Details → Line Items → Customise.
// Customer selection is now its own standalone first step (mirrors
// invoice's step_customers.dart being step 0), Template stays step 1,
// and quote number/dates/currency/notes + line items + tax/discount are
// now combined into a single "Create Quote" step (mirrors invoice's
// step_create_invoice.dart combining Invoice Details + Line Items).
//
// NO-CLIENT INLINE FIELDS PASS (earlier): mirrors invoice's
// step_create_invoice.dart behaviour exactly — if no customer was
// selected on the Customer step, the Create Quote step now shows inline
// "Client Details" fields (name/email/phone/address) so the quote can
// still be filled out without forcing a saved customer to be created
// first. These write straight into _custNameCtrl etc. and feed
// _syncToProvider() the same way a selected QuoteClient's fields would.
// If a customer WAS selected, this section is hidden entirely (same as
// invoice) and the selected customer's info is used instead.
//
// RESTORE-ON-EDIT PASS (earlier): opening an existing saved quote to
// edit it restores _selectedTemplate/_selectedClient from that quote's
// stored sourceTemplateId/sourceClientId — see _restoreTemplate()/
// _restoreClient() below and quote_data.dart's doc comment.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/quote_provider.dart';
import '../models/quote_data.dart';
import '../models/invoice_data.dart' show LineItem;
import '../widgets/step_editor_header.dart';
import '../widgets/shared_logo_picker.dart';
import 'saved_invoice_details_section/saved_document_detail_screen.dart';
import 'create_quote_section/quote_edit_widgets.dart';
import 'create_quote_section/quote_full_preview_screen.dart';
import 'create_quote_section/quote_step_customer.dart';
import 'create_quote_section/quote_step_template.dart';
import 'create_quote_section/quote_template_chooser_01/preview_registry.dart' show buildQuotePreview;
import '../document_layout_templates/01_executive/executive_quote_logic_data.dart';
import '../document_layout_templates/01_executive/executive_quote_stationary_layout.dart' show kPageW;
import '../document_layout_templates/pagination/scaled_page_stack.dart';

class QuoteEditorScreen extends StatefulWidget {
  final int layoutTemplateId;

  /// Which step to open on (0 = Customer ... 3 = Customise).
  final int initialStep;

  const QuoteEditorScreen({
    super.key,
    this.layoutTemplateId = 1,
    this.initialStep = 0,
  });

  @override
  State<QuoteEditorScreen> createState() => _QuoteEditorScreenState();
}

class _QuoteEditorScreenState extends State<QuoteEditorScreen> {
  static const Color _accent = Color(0xFF7B1FA2);

  static const List<StepMeta> _steps = [
    StepMeta(label: 'Customer', icon: Icons.person_rounded),
    StepMeta(label: 'Template', icon: Icons.tune_rounded),
    StepMeta(label: 'Create Quote', icon: Icons.request_quote_rounded),
    StepMeta(label: 'Customise', icon: Icons.rate_review_rounded),
  ];

  late int _step;
  bool _saving = false;
  late int _layoutTemplateId;

  QuoteTemplate? _selectedTemplate;
  QuoteClient? _selectedClient;

  String? _initialTemplateId;
  String? _initialClientId;

  late Map<String, bool> _enabledFields;

  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  double _logoSize = 44.0;

  late TextEditingController _quoteNumber;
  late TextEditingController _notes;
  String _issueDate = '';
  String _expiryDate = '';

  late TextEditingController _custNameCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;
  late TextEditingController _custAddressCtrl;

  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code';

  late List<TextEditingController> _descCtrls;
  late List<TextEditingController> _qtyCtrls;
  late List<TextEditingController> _priceCtrls;
  double _taxRate = 0.0;
  double _discountRate = 0.0;

  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;

  QuoteColor _colorScheme = QuoteColor.purple;
  late TextEditingController _titleCtrl;

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
    final q = context.read<QuoteProvider>().quoteData;
    _logoSize = q.businessLogoDisplaySize;

    _enabledFields = Map<String, bool>.from(q.enabledFields);

    _initialTemplateId = q.sourceTemplateId;
    _initialClientId = q.sourceClientId;

    final now = DateTime.now();
    _quoteNumber = TextEditingController(
      text: q.quoteNumber.isNotEmpty ? q.quoteNumber : 'Q-${now.millisecondsSinceEpoch.toString().substring(7)}',
    );
    _notes        = TextEditingController(text: q.notes);
    _issueDate    = q.issueDate.isNotEmpty ? q.issueDate : DateFormat('d MMM yyyy').format(now);
    _expiryDate   = q.expiryDate.isNotEmpty ? q.expiryDate : DateFormat('d MMM yyyy').format(now.add(const Duration(days: 14)));

    _custNameCtrl    = TextEditingController(text: q.clientName);
    _custEmailCtrl   = TextEditingController(text: q.clientEmail);
    _custPhoneCtrl   = TextEditingController(text: q.clientPhone);
    _custAddressCtrl = TextEditingController(text: q.clientAddress);

    _currencyCodeCtrl   = TextEditingController(text: q.currency.isNotEmpty ? q.currency : 'USD');
    _currencySymbolCtrl = TextEditingController(text: q.currencySymbol);
    _currencyDisplayMode = q.currencyDisplayMode.isNotEmpty ? q.currencyDisplayMode : 'code';

    _taxRate      = q.taxRate.clamp(0.0, 100.0);
    _discountRate = q.discountRate.clamp(0.0, 100.0);
    _colorScheme  = q.colorScheme;

    _taxCtrl      = TextEditingController(text: _taxRate == 0 ? '' : '$_taxRate');
    _discountCtrl = TextEditingController(text: _discountRate == 0 ? '' : '$_discountRate');

    final items = q.lineItems.isNotEmpty ? q.lineItems : [LineItem()];
    _descCtrls  = items.map((i) => TextEditingController(text: i.description)).toList();
    _qtyCtrls   = items.map((i) => TextEditingController(text: i.quantity == 1.0 ? '1' : '${i.quantity}')).toList();
    _priceCtrls = items.map((i) => TextEditingController(text: i.unitPrice == 0.0 ? '' : '${i.unitPrice}')).toList();

    _titleCtrl = TextEditingController(
      text: q.clientName.isNotEmpty ? '${q.clientName} Quote' : '',
    );
  }

  @override
  void dispose() {
    for (final c in [
      _quoteNumber, _notes, _titleCtrl, _taxCtrl, _discountCtrl,
      _currencyCodeCtrl, _currencySymbolCtrl,
      _custNameCtrl, _custEmailCtrl, _custPhoneCtrl, _custAddressCtrl,
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
  double get _total => _subtotal - _discountAmount + _taxAmount;

  void _applyClient(QuoteClient? client) {
    setState(() {
      _selectedClient = client;
      if (client != null && _titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = '${client.name} Quote';
      }
    });
  }

  void _applyTemplate(QuoteTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      _logoPath = template?.logoPath;
      _logoOffset = template?.logoOffset ?? Offset.zero;
      _logoScale = template?.logoScale ?? 1.0;
      _logoShape = template?.shape ?? LogoShape.roundedSquare;
      if (template != null) {
        _enabledFields = Map<String, bool>.from(template.enabledFields);
        _currencyCodeCtrl.text = template.currency;
      }
    });
  }

  void _restoreTemplate(QuoteTemplate? template) {
    setState(() => _selectedTemplate = template);
  }

  void _restoreClient(QuoteClient? client) {
    setState(() => _selectedClient = client);
  }

  void _syncToProvider() {
    final provider = context.read<QuoteProvider>();
    provider.updateBusinessInfo(
      businessName: _selectedTemplate?.businessName ?? '',
      businessEmail: _selectedTemplate?.businessEmail ?? '',
      businessPhone: _selectedTemplate?.businessPhone ?? '',
      businessAddress: _selectedTemplate?.businessAddress ?? '',
      businessLogoPath: _logoPath,
      clearBusinessLogo: _logoPath == null,
      businessLogoOffsetDx: _logoOffset.dx,
      businessLogoOffsetDy: _logoOffset.dy,
      businessLogoScale: _logoScale,
      businessLogoShape: _logoShape.storageName,
      businessLogoDisplaySize: _logoSize,
      sourceTemplateId: _selectedTemplate?.id,
      clearSourceTemplateId: _selectedTemplate == null,
    );
    provider.updateClientInfo(
      clientName: _selectedClient?.name ?? _custNameCtrl.text.trim(),
      clientEmail: _selectedClient?.email ?? _custEmailCtrl.text.trim(),
      clientPhone: _selectedClient?.phone ?? _custPhoneCtrl.text.trim(),
      clientAddress: _selectedClient?.address ?? _custAddressCtrl.text.trim(),
      sourceClientId: _selectedClient?.id,
      clearSourceClientId: _selectedClient == null,
    );
    provider.updateQuoteDetails(
      quoteNumber: _quoteNumber.text,
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      notes: _notes.text,
      currency: _currencyCodeCtrl.text.trim().isEmpty
          ? 'USD'
          : _currencyCodeCtrl.text.trim().toUpperCase(),
      currencySymbol: _currencySymbolCtrl.text.trim(),
      currencyDisplayMode: _currencyDisplayMode,
      taxRate: _taxRate,
      discountRate: _discountRate,
    );
    provider.updateEnabledFields(_enabledFields);
    provider.updateQuoteData(provider.quoteData.copyWith(lineItems: _currentLineItems));
    provider.updateColorScheme(_colorScheme);
    provider.updateLayoutTemplateId(_layoutTemplateId);
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        final formatted = DateFormat('d MMM yyyy').format(picked);
        if (isExpiry) {
          _expiryDate = formatted;
        } else {
          _issueDate = formatted;
        }
      });
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

  // STEP-TAP BYPASS FIX: tapping a step tab in the header used to jump
  // straight there regardless of whether earlier steps were actually
  // filled in — e.g. tapping "Create Quote" or "Customise" with no
  // template selected skipped the same check _nextStep() enforces when
  // pressing Next. Forward jumps now re-run the same per-step
  // validation _nextStep() does, stopping (with the same snack message)
  // at the first unmet requirement instead of landing on the tapped
  // step. Backward jumps are always allowed — nothing to validate when
  // returning to a step already visited.
  void _goToStep(int index) {
    if (index > _step) {
      for (int i = _step; i < index; i++) {
        final blocked = _stepBlockReason(i);
        if (blocked != null) {
          _showSnack(blocked);
          return;
        }
      }
    }
    _syncToProvider();
    setState(() => _step = index);
  }

  /// Returns the validation message to show if step [i] isn't complete
  /// enough to move past, or null if it's fine to continue. Mirrors the
  /// per-step checks in _nextStep() exactly, factored out so both the
  /// Next button and step-tap navigation enforce the same rules.
  String? _stepBlockReason(int i) {
    if (i == 1 && _selectedTemplate == null) {
      return 'Select or add a template to continue';
    }
    if (i == 2) {
      if (_quoteNumber.text.trim().isEmpty) {
        return 'Enter a quote number to continue';
      }
      if (_selectedClient == null && _custNameCtrl.text.trim().isEmpty) {
        return 'Enter a client name to continue';
      }
      final items = _currentLineItems;
      if (items.any((i) => i.description.trim().isEmpty)) {
        return 'Give every line item a description';
      }
      if (_discountRate < 0 || _discountRate > 100) {
        return 'Discount must be between 0 and 100%';
      }
      if (_taxRate < 0 || _taxRate > 100) {
        return 'Tax must be between 0 and 100%';
      }
    }
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSelectionRequiredSnack(String what) {
    _showSnack('Select or add a $what to continue');
  }

  String? _validateForm() {
    if (_selectedClient == null && _custNameCtrl.text.trim().isEmpty) {
      return 'Select a customer or enter a client name before saving';
    }
    if (_selectedTemplate == null) return 'Select or add a template before saving';
    if (_quoteNumber.text.trim().isEmpty) return 'Enter a quote number before saving';

    final items = _currentLineItems;
    if (items.isEmpty || items.every((i) => i.description.trim().isEmpty)) {
      return 'Add at least one item with a description';
    }
    if (items.any((i) => i.description.trim().isEmpty)) {
      return 'Give every line item a description';
    }

    if (_discountRate < 0 || _discountRate > 100) {
      return 'Discount must be between 0 and 100%';
    }
    if (_taxRate < 0 || _taxRate > 100) {
      return 'Tax must be between 0 and 100%';
    }

    if (_titleCtrl.text.trim().isEmpty) return 'Give this quote a title before saving';

    return null;
  }

  void _nextStep() {
    final blocked = _stepBlockReason(_step);
    if (blocked != null) {
      _showSnack(blocked);
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
    final provider = context.read<QuoteProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const QuoteFullPreviewScreen(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final error = _validateForm();
    if (error != null) {
      _showSnack(error);
      return;
    }
    setState(() => _saving = true);
    _syncToProvider();
    final saved = context.read<QuoteProvider>().saveCurrentQuote(
          title: _titleCtrl.text,
          templateName: 'Standard',
        );
    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SavedDocumentDetailScreen.quote(saved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          StepEditorHeader(
            title: 'Create Quote',
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
      bottomNavigationBar: QuoteStepNavBar(
        onBack: null,
        onNext: _nextStep,
        nextLabel: _step == _steps.length - 1 ? 'Save Quote' : 'Next',
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
        return _createQuoteStep();
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
  // QuoteStepCustomerSection (create_quote_section/quote_step_customer.dart)
  // instead of the old QuoteClientLibrarySection.
  Widget _customerStep() {
    final label = _selectedClient == null
        ? 'Select a saved customer, or enter one manually on the next Create Quote step.'
        : 'Using "${_selectedClient!.name}" for this quote.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuoteStepCustomerSection(
          accent: _accent,
          onClientSelected: _applyClient,
          initialSelectedId: _initialClientId,
          onInitialSelectionRestored: _restoreClient,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedClient != null, label: label),
      ],
    );
  }

  Widget _templateStep() {
    final label = _selectedTemplate == null
        ? 'Select or add a template above to continue.'
        : 'Using "${_selectedTemplate!.name.isNotEmpty ? _selectedTemplate!.name : _selectedTemplate!.businessName}" for this quote.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuoteStepTemplateSection(
          accent: _accent,
          onTemplateSelected: _applyTemplate,
          initialSelectedId: _initialTemplateId,
          onInitialSelectionRestored: _restoreTemplate,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedTemplate != null, label: label),
      ],
    );
  }

  Widget _createQuoteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quoteSectionHeader(context, 'Quote Details', _accent, icon: Icons.request_quote_rounded),
        QuoteField(ctrl: _quoteNumber, label: 'Quote Number', accent: _accent, icon: Icons.tag_rounded, max: 40, required: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: QuoteDateField(label: 'Issue Date', value: _issueDate, accent: _accent, onTap: () => _pickDate(isExpiry: false))),
            const SizedBox(width: 12),
            Expanded(child: QuoteDateField(label: 'Valid Until', value: _expiryDate, accent: _accent, onTap: () => _pickDate(isExpiry: true))),
          ],
        ),
        const SizedBox(height: 20),

        quoteSectionHeader(context, 'Currency', _accent, icon: Icons.attach_money_rounded),
        QuoteField(
          ctrl: _currencyCodeCtrl,
          label: 'Currency Code',
          accent: _accent,
          icon: Icons.attach_money_rounded,
          max: 6,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),

        // CURRENCY SYMBOL CONDITIONAL: Display Format picker sits
        // directly under Currency Code; Currency Symbol field below only
        // renders once Symbol/Both is picked — matches
        // step_create_invoice.dart / quote_step_customer.dart.
        _QuoteCurrencyDisplayModeSelector(
          value: _currencyDisplayMode,
          accent: _accent,
          onChanged: (mode) => setState(() => _currencyDisplayMode = mode),
          previewCode: _currencyCodeCtrl.text.trim().isEmpty ? 'USD' : _currencyCodeCtrl.text.trim().toUpperCase(),
          previewSymbol: _currencySymbolCtrl.text.trim(),
        ),
        if (_currencyDisplayMode != 'code') ...[
          const SizedBox(height: 12),
          QuoteField(
            ctrl: _currencySymbolCtrl,
            label: 'Currency Symbol',
            accent: _accent,
            icon: Icons.currency_exchange_rounded,
            max: 6,
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 20),

        if (_selectedClient == null) ...[
          quoteSectionHeader(context, 'Client Details', _accent, icon: Icons.person_rounded),
          QuoteField(
            ctrl: _custNameCtrl,
            label: 'Client Name',
            accent: _accent,
            icon: Icons.person_rounded,
            max: 100,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          QuoteField(
            ctrl: _custEmailCtrl,
            label: 'Client Email',
            accent: _accent,
            icon: Icons.email_rounded,
            max: 100,
            keyboard: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          QuoteField(
            ctrl: _custPhoneCtrl,
            label: 'Client Phone',
            accent: _accent,
            icon: Icons.phone_rounded,
            max: 20,
            keyboard: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          QuoteField(
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

        quoteSectionHeader(context, 'Line Items', _accent, icon: Icons.list_alt_rounded),
        ...List.generate(_descCtrls.length, (i) {
          final qty = double.tryParse(_qtyCtrls[i].text) ?? 0.0;
          final price = double.tryParse(_priceCtrls[i].text) ?? 0.0;
          return QuoteItemCard(
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        quoteSectionHeader(context, 'Tax & Discount', _accent, icon: Icons.percent_rounded),
        Row(
          children: [
            Expanded(
              child: QuoteField(
                ctrl: _taxCtrl,
                label: 'Tax %',
                accent: _accent,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                max: 5,
                extraFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                onChanged: (v) => setState(() {
                  final parsed = double.tryParse(v) ?? 0.0;
                  _taxRate = parsed.clamp(0.0, 100.0);
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuoteField(
                ctrl: _discountCtrl,
                label: 'Discount %',
                accent: _accent,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                max: 5,
                extraFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                onChanged: (v) => setState(() {
                  final parsed = double.tryParse(v) ?? 0.0;
                  _discountRate = parsed.clamp(0.0, 100.0);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuoteTotalsCard(
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          total: _total,
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
        // near the client fields disconnected from the total they refer
        // to.
        quoteSectionHeader(context, 'Additional Info', _accent, icon: Icons.notes_rounded),
        QuoteField(ctrl: _notes, label: 'Notes', accent: _accent, icon: Icons.notes_rounded, maxLines: 3, max: 500),
      ],
    );
  }

  Widget _fieldToggleRow(String key, String label, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = _enabledFields[key] ?? true;
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
          setState(() => _enabledFields[key] = v);
          _syncToProvider();
        },
      ),
    );
  }

  Widget _quoteFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quoteSectionHeader(context, 'Quote Fields', _accent, icon: Icons.tune_rounded),
        Text(
          'Toggle which fields appear on the generated quote.',
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 10),
        _fieldToggleRow('invoiceNumber', 'Quote Number', icon: Icons.tag_rounded),
        _fieldToggleRow('date', 'Issue Date', icon: Icons.calendar_today_rounded),
        _fieldToggleRow('dueDate', 'Valid Until', icon: Icons.event_rounded),
        _fieldToggleRow('businessLogo', 'Business Logo', icon: Icons.image_rounded),
        _fieldToggleRow('tax', 'Tax', icon: Icons.percent_rounded),
        _fieldToggleRow('discount', 'Discount', icon: Icons.local_offer_rounded),
        _fieldToggleRow('notes', 'Notes', icon: Icons.notes_rounded),
        _fieldToggleRow('thankYouMessage', 'Thank You Message', icon: Icons.favorite_border_rounded),
        const SizedBox(height: 12),
        quoteSectionHeader(context, 'Client Fields', _accent, icon: Icons.person_rounded),
        _fieldToggleRow('customerName', 'Client Name', icon: Icons.person_outline_rounded),
        _fieldToggleRow('customerEmail', 'Client Email', icon: Icons.email_rounded),
        _fieldToggleRow('customerPhone', 'Client Phone', icon: Icons.phone_rounded),
        _fieldToggleRow('customerAddress', 'Client Address', icon: Icons.location_on_rounded),
      ],
    );
  }

  Widget _customiseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quoteSectionHeader(context, 'Quote Title', _accent, icon: Icons.title_rounded),
        QuoteField(ctrl: _titleCtrl, label: 'Title (for your records)', accent: _accent, icon: Icons.bookmark_outline_rounded, required: true, max: 80),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Live Preview', _accent, icon: Icons.visibility_rounded),
        const _QuotePreviewCard(),
        const SizedBox(height: 24),

        // FIELD VISIBILITY POSITION PASS: Quote/Client Fields section
        // now sits directly under Live Preview — same relative position
        // as Receipt's Customise step, and matching where Invoice's own
        // field-visibility section will sit once added.
        _quoteFieldsSection(),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Business Logo', _accent, icon: Icons.image_rounded),
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

        quoteSectionHeader(context, 'Logo Size', _accent, icon: Icons.photo_size_select_large_rounded),
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

        quoteSectionHeader(context, 'Accent Color', _accent, icon: Icons.palette_outlined),
        QuoteColorPicker(
          selected: _colorScheme,
          onChanged: (c) {
            setState(() => _colorScheme = c);
            _syncToProvider();
          },
        ),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Summary', _accent, icon: Icons.summarize_rounded),
        QuoteTotalsCard(
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          total: _total,
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

class _QuotePreviewCard extends StatelessWidget {
  const _QuotePreviewCard();

  static Color _accentFromScheme(QuoteColor scheme) {
    const map = {
      QuoteColor.blue:   Color(0xFF1565C0),
      QuoteColor.green:  Color(0xFF2E7D32),
      QuoteColor.purple: Color(0xFF6A1B9A),
      QuoteColor.orange: Color(0xFFE65100),
      QuoteColor.red:    Color(0xFFC62828),
      QuoteColor.teal:   Color(0xFF00695C),
      QuoteColor.black:  Color(0xFF212121),
      QuoteColor.indigo: Color(0xFF283593),
    };
    return map[scheme] ?? const Color(0xFF6A1B9A);
  }

  Widget _buildPreviewWidget(QuoteData data) {
    return buildQuotePreview(data.layoutTemplateId, data) ??
        ExecutiveQuotePreview(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final data        = context.watch<QuoteProvider>().quoteData;
    final accent      = _accentFromScheme(data.colorScheme);
    final colorScheme = Theme.of(context).colorScheme;

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

class _QuoteCurrencyDisplayModeSelector extends StatelessWidget {
  final String value;
  final Color accent;
  final ValueChanged<String> onChanged;
  final String previewCode;
  final String previewSymbol;

  const _QuoteCurrencyDisplayModeSelector({
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
