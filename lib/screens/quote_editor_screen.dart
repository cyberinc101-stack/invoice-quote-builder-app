// lib/screens/quote_editor_screen.dart
//
// QUOTE LIBRARY RESTRUCTURE PASS (this update): mirrors Invoice's own
// library restructure. The entire _createQuoteStep() body (quote
// number, dates, currency, client override, Saved Item Sets panel, line
// items, tax/discount, notes) has moved out into a bottom sheet
// (create_quote_section/create_quote_bottom_sheet.dart,
// CreateQuoteBottomSheet), opened from a new library screen embedded at
// this step (create_quote_section/step_create_quote.dart,
// StepCreateQuote). Unlike Invoice's per-step StepNavBar, Quote keeps
// its existing single shared bottomNavigationBar (QuoteStepNavBar) —
// StepCreateQuote is an embedded widget (like QuoteStepCustomerSection/
// QuoteStepTemplateSection), not a standalone screen with its own nav.
//
// New state: _selectedQuoteDraft (SavedQuoteDraft?) replaces every piece
// of per-quote-details/line-item local state this screen used to own
// directly (_quoteNumber, _issueDate/_expiryDate, _custNameCtrl etc.,
// _currencyCodeCtrl/_currencySymbolCtrl/_currencyDisplayMode,
// _descCtrls/_qtyCtrls/_priceCtrls, _taxRate/_discountRate,
// _taxCtrl/_discountCtrl — all removed). StepCreateQuote reports the
// selected draft via onDraftSelected(); _syncToProvider() now pulls
// quote number/dates/currency/line items/tax/discount from
// _selectedQuoteDraft?.data (falling back to whatever's already on the
// provider before any draft is selected, same fallback pattern Invoice
// uses). _stepBlockReason(2) and _validateForm() now just check that a
// draft is selected, since the bottom sheet does its own full field
// validation before it will hand back a draft at all.
//
// Customise step's totals/currency prefix now read from _draftData
// (getter: _selectedQuoteDraft?.data ?? current provider QuoteData)
// instead of locally-computed getters over removed controllers.
//
// Everything below this point in the doc history (CUSTOMISE STEP
// EXTRACTION + FONT PASS, CUSTOMER STEP RENAME PASS, FIELD VISIBILITY
// POSITION PASS, STEP REORDER PASS, NO-CLIENT INLINE FIELDS PASS,
// RESTORE-ON-EDIT PASS) is UNCHANGED and still describes the Customer/
// Template/Customise steps exactly as before — only the Create Quote
// step's internals changed in this pass.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quote_provider.dart';
import '../providers/history_provider.dart';
import '../models/history_event.dart';
import '../models/quote_data.dart';
import '../widgets/step_editor_header.dart';
import 'saved_invoice_details_section/saved_document_detail_screen.dart';
import 'create_quote_section/quote_edit_widgets.dart';
import 'create_quote_section/quote_full_preview_screen.dart';
import 'create_quote_section/quote_step_customer.dart';
import 'create_quote_section/quote_step_customise.dart';
import 'create_quote_section/quote_step_template.dart';
import 'create_quote_section/step_create_quote.dart';
import '../widgets/shared_logo_picker.dart';

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

  // QUOTE LIBRARY RESTRUCTURE PASS: the selected draft from the Create
  // Quote step's library — carries quote number/dates/currency/client
  // override/line items/tax/discount/notes. Null until one is created or
  // selected on that step.
  SavedQuoteDraft? _selectedQuoteDraft;

  late Map<String, bool> _enabledFields;

  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  double _logoSize = 44.0;

  QuoteColor _colorScheme = QuoteColor.purple;
  late TextEditingController _titleCtrl;

  late String _fontFamily;
  late double _fontSize;

  /// The data driving totals/currency display on the Customise step —
  /// the selected draft's data if one is selected, else whatever's
  /// already on the provider (e.g. before any draft has been picked).
  QuoteData get _draftData =>
      _selectedQuoteDraft?.data ?? context.read<QuoteProvider>().quoteData;

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
    final q = context.read<QuoteProvider>().quoteData;
    _logoSize = q.businessLogoDisplaySize;

    _enabledFields = Map<String, bool>.from(q.enabledFields);

    _initialTemplateId = q.sourceTemplateId;
    _initialClientId = q.sourceClientId;

    _colorScheme  = q.colorScheme;
    _fontFamily   = q.fontFamily;
    _fontSize     = q.fontSize;

    _titleCtrl = TextEditingController(
      text: q.clientName.isNotEmpty ? '${q.clientName} Quote' : '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

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
        // Currency code now lives on the selected draft (see
        // CreateQuoteBottomSheet's own template-currency prefill for new
        // drafts) rather than a local controller here.
      }
    });
  }

  void _restoreTemplate(QuoteTemplate? template) {
    setState(() => _selectedTemplate = template);
  }

  void _restoreClient(QuoteClient? client) {
    setState(() => _selectedClient = client);
  }

  // QUOTE LIBRARY RESTRUCTURE PASS: business info/client info sync is
  // unchanged; quote number/dates/currency/line items/tax/discount now
  // come from _selectedQuoteDraft?.data, falling back to whatever's
  // already on the provider before any draft is selected (mirrors
  // Invoice's own current-value fallback in _syncSelectedToProvider()).
  void _syncToProvider() {
    final provider = context.read<QuoteProvider>();
    final current = provider.quoteData;
    final d = _selectedQuoteDraft?.data;

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
      clientName: _selectedClient?.name ?? d?.clientName ?? current.clientName,
      clientEmail: _selectedClient?.email ?? d?.clientEmail ?? current.clientEmail,
      clientPhone: _selectedClient?.phone ?? d?.clientPhone ?? current.clientPhone,
      clientAddress: _selectedClient?.address ?? d?.clientAddress ?? current.clientAddress,
      sourceClientId: _selectedClient?.id,
      clearSourceClientId: _selectedClient == null,
    );
    provider.updateQuoteDetails(
      quoteNumber: d?.quoteNumber ?? current.quoteNumber,
      issueDate: d?.issueDate ?? current.issueDate,
      expiryDate: d?.expiryDate ?? current.expiryDate,
      notes: d?.notes ?? current.notes,
      currency: d?.currency ?? current.currency,
      currencySymbol: d?.currencySymbol ?? current.currencySymbol,
      currencyDisplayMode: d?.currencyDisplayMode ?? current.currencyDisplayMode,
      taxRate: d?.taxRate ?? current.taxRate,
      discountRate: d?.discountRate ?? current.discountRate,
    );
    provider.updateEnabledFields(_enabledFields);
    if (d != null) {
      provider.updateQuoteData(provider.quoteData.copyWith(
        lineItems: d.lineItems.map((i) => i.copyWith()).toList(),
      ));
    }
    provider.updateColorScheme(_colorScheme);
    provider.updateFontFamily(_fontFamily);
    provider.updateFontSize(_fontSize);
    provider.updateLayoutTemplateId(_layoutTemplateId);
  }

  // STEP-TAP BYPASS FIX (unchanged): tapping a step tab re-runs the same
  // per-step validation _nextStep() enforces when pressing Next.
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
  /// enough to move past, or null if it's fine to continue.
  String? _stepBlockReason(int i) {
    if (i == 1 && _selectedTemplate == null) {
      return 'Select or add a template to continue';
    }
    if (i == 2 && _selectedQuoteDraft == null) {
      return 'Select or create a quote to continue';
    }
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // QUOTE LIBRARY RESTRUCTURE PASS: field-level validation (quote
  // number, client name, line item descriptions, tax/discount range)
  // now lives entirely in CreateQuoteBottomSheet's own _validateForm() —
  // a draft can't be handed back to this screen unless it already passed
  // those checks. This screen's own final validation is reduced to
  // "was everything actually selected/entered".
  String? _validateForm() {
    if (_selectedTemplate == null) return 'Select or add a template before saving';
    if (_selectedQuoteDraft == null) {
      return 'Select or create a quote before saving';
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
    // HISTORY WIRING: logs this save as a 'created' activity-feed event —
    // see history_screen.dart / history_provider.dart. Fire-and-forget:
    // history logging should never block or fail the actual save.
    unawaited(context.read<HistoryProvider>().logCreated(
          docType: HistoryDocType.quote,
          docId: saved.id,
          docNumber: saved.data.quoteNumber,
          clientName: saved.data.clientName.isNotEmpty ? saved.data.clientName : null,
          amount: saved.data.grandTotal,
          currency: saved.data.currency,
        ));
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

  // QUOTE LIBRARY RESTRUCTURE PASS: now just embeds StepCreateQuote
  // (create_quote_section/step_create_quote.dart) — the entire form has
  // moved into CreateQuoteBottomSheet, opened from that library screen.
  Widget _createQuoteStep() {
    return StepCreateQuote(
      accent: _accent,
      selectedClient: _selectedClient,
      selectedTemplate: _selectedTemplate,
      onDraftSelected: (draft) {
        setState(() => _selectedQuoteDraft = draft);
        _syncToProvider();
      },
    );
  }

  Widget _customiseStep() {
    return QuoteStepCustomise(
      accent: _accent,
      titleCtrl: _titleCtrl,
      enabledFields: _enabledFields,
      onEnabledFieldsChanged: (updated) {
        setState(() => _enabledFields = updated);
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
      onLogoShapeChanged: (shape) {
        setState(() => _logoShape = shape);
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
      subtotal: _draftData.subtotal,
      taxAmount: _draftData.taxAmount,
      discountAmount: _draftData.discountAmount,
      total: _draftData.grandTotal,
      taxRate: _draftData.taxRate,
      discountRate: _draftData.discountRate,
      currencySymbol: _currencyPrefix,
      onOpenFullPreview: _openFullPreview,
    );
  }
}
