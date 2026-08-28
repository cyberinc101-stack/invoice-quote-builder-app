// lib/screens/quote_editor_screen.dart
//
// CURRENCY DISPLAY PASS (this update): the "Currency" dropdown
// (backed by kQuoteCurrencies, a fixed list) on the Client & Details
// step is replaced with a free-text Currency Code field + free-text
// Currency Symbol field + a Code/Symbol/Both display-mode selector with
// a live preview — same pattern already live on the invoice
// (step_create_invoice.dart's _InvoiceCurrencyDisplayModeSelector) and
// receipt (create_receipt_screen.dart) create steps. The single
// `String _currency` field is replaced by
// `_currencyCodeCtrl` / `_currencySymbolCtrl` / `_currencyDisplayMode`,
// which map straight onto QuoteData.currency/currencySymbol/
// currencyDisplayMode (already present on the model — see
// quote_data.dart) via QuoteProvider.updateQuoteDetails(), which now
// also accepts currencySymbol/currencyDisplayMode.
//
// The Line Items and Review steps previously called the shared
// `quoteCurrencySymbol(_currency)` helper (a hardcoded code -> symbol
// lookup) to prefix amounts on screen. That's replaced with a local
// `_currencyPrefix` getter (symbol first, falling back to code) — the
// same cosmetic-only pattern used on the invoice step; the actual
// generated PDF/preview already does the full Code/Symbol/Both
// formatting off the three model fields, so no changes were needed
// there.
//
// TEMPLATE + LOGO SIZER PASS (earlier update): _syncToProvider() now also
// sets layoutTemplateId (widget.layoutTemplateId, chosen on
// QuoteTemplateChooserScreen — previously stored in _layoutTemplateId but
// never actually written to QuoteData, so the quote always rendered as
// Executive regardless of what was picked). A new "Business Logo" section
// on the Review & Save step lets the logo be repositioned/zoomed/reshaped
// independently of the saved business profile it came from — local
// _logoPath/_logoOffset/_logoScale/_logoShape state, seeded from whichever
// profile is selected in _applyBusinessProfile() but editable afterward
// via SharedLogoPicker, then written into QuoteData through
// provider.updateBusinessInfo()'s new optional logo params.
//
// UPDATED (earlier pass): Business Info and Client & Details steps no longer
// show inline manual fields (Logo / Business Name / Email / Phone /
// Address, and Client Name / Email / Phone / Address). They now match the
// invoice app's customer step exactly: a saved-items list plus an
// "Add New Business Profile" / "Add New Client" button that opens the
// existing bottom sheet (_QuoteBusinessProfileSheet / _QuoteClientSheet),
// where Save lives at the bottom of the sheet. Selecting a saved card is
// now the only way to populate business/client info for the quote.
//
// Because there's no more inline typing on the page, the old
// "auto-save whatever's typed on Next" logic (_autoSaveCurrentStepContainer,
// QuoteBusinessProfileLibraryController / QuoteClientLibraryController)
// has been removed — saving now only ever happens through the sheet's own
// Save button, which already persists to the library.
//
// UPDATED (earlier pass, 2): Next is now blocked on step 0 until a business
// profile is selected, and on step 1 until a client is selected (per
// explicit instruction — Jesse chose "require selection" over "allow
// empty"). A status strip under each library section shows either a
// prompt to select/add one, or a confirmation of what's currently in use.
//
// KNOWN GAP: if you open an existing *saved* quote to edit it, the
// business/client selection will NOT auto-restore from that quote's
// previously-stored raw strings — _selectedBizProfile / _selectedClient
// both start null regardless of what's already saved on the quote. You'll
// need to reselect the matching saved profile/client (or add a new one)
// before Next will allow you past those two steps. Flag it if you want
// this reconciled — it would need to either match against the saved
// library by fields, or synthesize a placeholder profile/client from the
// quote's raw data.
//
// Everything below this point (Line Items step, StepEditorHeader,
// preview/save flow) is otherwise unchanged from before.

import 'package:flutter/material.dart';
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
import 'create_quote_section/quote_client_library.dart';
import 'create_quote_section/quote_business_profile_library.dart';
import 'create_quote_section/quote_template_chooser_01/preview_registry.dart' show buildQuotePreview;
import '../document_layout_templates/01_executive/executive_quote_logic_data.dart';
import '../document_layout_templates/01_executive/executive_quote_stationary_layout.dart' show kPageW;
import '../document_layout_templates/pagination/scaled_page_stack.dart';

class QuoteEditorScreen extends StatefulWidget {
  /// Visual layout template id chosen on QuoteTemplateChooserScreen.
  final int layoutTemplateId;

  /// Which step to open on (0 = Business Info ... 3 = Review & Save).
  /// Defaults to 0 for a fresh quote; the "Edit" flow on an existing
  /// saved quote passes 3 to jump straight to Review & Save.
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
    StepMeta(label: 'Business Info', icon: Icons.storefront_rounded),
    StepMeta(label: 'Client & Details', icon: Icons.person_rounded),
    StepMeta(label: 'Line Items', icon: Icons.list_alt_rounded),
    StepMeta(label: 'Review & Save', icon: Icons.rate_review_rounded),
  ];

  late int _step;
  bool _saving = false;
  late int _layoutTemplateId;

  // Business — now sourced entirely from a selected saved profile. No more
  // inline TextEditingControllers for these; the sheet owns its own.
  QuoteBusinessProfile? _selectedBizProfile;

  // Client — same pattern.
  QuoteClient? _selectedClient;

  // Logo override — seeded from _selectedBizProfile whenever a new profile
  // is picked, but independently editable afterward via the Business Logo
  // section on the Review step (SharedLogoPicker), so the logo can be
  // repositioned/zoomed/reshaped per-quote without altering the saved
  // profile itself. QuoteBusinessProfile has no shape field of its own, so
  // shape always starts at roundedSquare (matching InvoiceData's default)
  // regardless of profile.
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  double _logoSize = 44.0;

  // Quote details — still edited inline, unrelated to the saved-profile
  // pattern above.
  late TextEditingController _quoteNumber;
  late TextEditingController _notes;
  String _issueDate = '';
  String _expiryDate = '';

  // Currency — free-text code + symbol + Code/Symbol/Both display mode.
  // No hardcoded currency list; any code/symbol combination is accepted.
  // These map straight onto QuoteData.currency/currencySymbol/
  // currencyDisplayMode.
  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code'; // 'code' | 'symbol' | 'both'

  // Line items
  late List<TextEditingController> _descCtrls;
  late List<TextEditingController> _qtyCtrls;
  late List<TextEditingController> _priceCtrls;
  double _taxRate = 0.0;
  double _discountRate = 0.0;

  // Tax / discount controllers (persistent — avoids cursor jump on rebuild)
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;

  // Style + save
  QuoteColor _colorScheme = QuoteColor.purple;
  late TextEditingController _titleCtrl;

  /// Local display prefix used only for the item/totals cards on this
  /// step (cosmetic while editing) — symbol first, falling back to code.
  /// The real generated PDF/preview already does the full
  /// Code/Symbol/Both branching off QuoteData's three currency fields, so
  /// this doesn't need to replicate that logic exactly.
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
    _step = widget.initialStep.clamp(0, 3);
    _layoutTemplateId = widget.layoutTemplateId;
    final q = context.read<QuoteProvider>().quoteData;
    _logoSize = q.businessLogoDisplaySize;

    final now = DateTime.now();
    _quoteNumber = TextEditingController(
      text: q.quoteNumber.isNotEmpty ? q.quoteNumber : 'Q-${now.millisecondsSinceEpoch.toString().substring(7)}',
    );
    _notes        = TextEditingController(text: q.notes);
    _issueDate    = q.issueDate.isNotEmpty ? q.issueDate : DateFormat('d MMM yyyy').format(now);
    _expiryDate   = q.expiryDate.isNotEmpty ? q.expiryDate : DateFormat('d MMM yyyy').format(now.add(const Duration(days: 14)));

    _currencyCodeCtrl   = TextEditingController(text: q.currency.isNotEmpty ? q.currency : 'USD');
    _currencySymbolCtrl = TextEditingController(text: q.currencySymbol);
    _currencyDisplayMode = q.currencyDisplayMode.isNotEmpty ? q.currencyDisplayMode : 'code';

    _taxRate      = q.taxRate;
    _discountRate = q.discountRate;
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

  // ── Saved-client / saved-business-profile library callbacks ─────────────────
  // Fired by QuoteClientLibrarySection / QuoteBusinessProfileLibrarySection
  // when a saved card is tapped (or deselected — profile/client comes back
  // null in that case).

  void _applyClient(QuoteClient? client) {
    setState(() {
      _selectedClient = client;
      if (client != null && _titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = '${client.name} Quote';
      }
    });
  }

  void _applyBusinessProfile(QuoteBusinessProfile? profile) {
    setState(() {
      _selectedBizProfile = profile;
      // Re-seed the logo override from the newly selected profile. Any
      // manual reposition/zoom done on the Review step for a previous
      // profile is intentionally discarded here — switching business
      // profiles is switching businesses, so their logo should come along.
      _logoPath = profile?.logoPath;
      _logoOffset = profile?.logoOffset ?? Offset.zero;
      _logoScale = profile?.logoScale ?? 1.0;
      _logoShape = LogoShape.roundedSquare;
    });
  }

  void _syncToProvider() {
    final provider = context.read<QuoteProvider>();
    provider.updateBusinessInfo(
      businessName: _selectedBizProfile?.businessName ?? '',
      businessEmail: _selectedBizProfile?.businessEmail ?? '',
      businessPhone: _selectedBizProfile?.businessPhone ?? '',
      businessAddress: _selectedBizProfile?.businessAddress ?? '',
      businessLogoPath: _logoPath,
      clearBusinessLogo: _logoPath == null,
      businessLogoOffsetDx: _logoOffset.dx,
      businessLogoOffsetDy: _logoOffset.dy,
      businessLogoScale: _logoScale,
      businessLogoShape: _logoShape.storageName,
      businessLogoDisplaySize: _logoSize,
    );
    provider.updateClientInfo(
      clientName: _selectedClient?.name ?? '',
      clientEmail: _selectedClient?.email ?? '',
      clientPhone: _selectedClient?.phone ?? '',
      clientAddress: _selectedClient?.address ?? '',
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

  void _goToStep(int index) {
    _syncToProvider();
    setState(() => _step = index);
  }

  void _showSelectionRequiredSnack(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Select or add a $what to continue')),
    );
  }

  void _nextStep() {
    if (_step == 0 && _selectedBizProfile == null) {
      _showSelectionRequiredSnack('business profile');
      return;
    }
    if (_step == 1 && _selectedClient == null) {
      _showSelectionRequiredSnack('client');
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

  // Syncs the draft to QuoteProvider (same as step navigation) and pushes
  // the full preview screen wrapped around the same provider instance, so
  // Preview & Download always reflects exactly what's on screen.
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
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this quote a title before saving')),
      );
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
        nextLabel: _step == 3 ? 'Save Quote' : 'Next',
        nextIcon: _step == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded,
        isLoading: _saving,
        accent: _accent,
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _businessStep();
      case 1:
        return _clientAndDetailsStep();
      case 2:
        return _lineItemsStep();
      default:
        return _reviewStep();
    }
  }

  // ── Status strip — shown under both library sections. Green/check when
  // something's selected, accent/info when nothing is yet.
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

  Widget _businessStep() {
    final label = _selectedBizProfile == null
        ? 'Select or add a business profile above to continue.'
        : 'Using "${_selectedBizProfile!.profileName.isNotEmpty ? _selectedBizProfile!.profileName : _selectedBizProfile!.businessName}" for this quote.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuoteBusinessProfileLibrarySection(
          accent: _accent,
          onProfileSelected: _applyBusinessProfile,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedBizProfile != null, label: label),
      ],
    );
  }

  Widget _clientAndDetailsStep() {
    final label = _selectedClient == null
        ? 'Select or add a client above to continue.'
        : 'Using "${_selectedClient!.name}" for this quote.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Saved clients ──────────────────────────────────────────────────
        QuoteClientLibrarySection(
          accent: _accent,
          onClientSelected: _applyClient,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedClient != null, label: label),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Quote Details', _accent, icon: Icons.request_quote_rounded),
        QuoteField(ctrl: _quoteNumber, label: 'Quote Number', accent: _accent, icon: Icons.tag_rounded, max: 40),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: QuoteDateField(label: 'Issue Date', value: _issueDate, accent: _accent, onTap: () => _pickDate(isExpiry: false))),
            const SizedBox(width: 12),
            Expanded(child: QuoteDateField(label: 'Valid Until', value: _expiryDate, accent: _accent, onTap: () => _pickDate(isExpiry: true))),
          ],
        ),
        const SizedBox(height: 24),

        // ── Currency — free-text code + symbol, no hardcoded currency
        // list — matches the pattern already live on the invoice and
        // receipt create steps.
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
        QuoteField(
          ctrl: _currencySymbolCtrl,
          label: 'Currency Symbol',
          accent: _accent,
          icon: Icons.currency_exchange_rounded,
          max: 6,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _QuoteCurrencyDisplayModeSelector(
          value: _currencyDisplayMode,
          accent: _accent,
          onChanged: (mode) => setState(() => _currencyDisplayMode = mode),
          previewCode: _currencyCodeCtrl.text.trim().isEmpty ? 'USD' : _currencyCodeCtrl.text.trim().toUpperCase(),
          previewSymbol: _currencySymbolCtrl.text.trim(),
        ),
        const SizedBox(height: 24),

        QuoteField(ctrl: _notes, label: 'Notes', accent: _accent, icon: Icons.notes_rounded, maxLines: 3, max: 500),
      ],
    );
  }

  Widget _lineItemsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                onChanged: (v) => setState(() => _taxRate = double.tryParse(v) ?? 0.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuoteField(
                ctrl: _discountCtrl,
                label: 'Discount %',
                accent: _accent,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setState(() => _discountRate = double.tryParse(v) ?? 0.0),
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
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quoteSectionHeader(context, 'Quote Title', _accent, icon: Icons.title_rounded),
        QuoteField(ctrl: _titleCtrl, label: 'Title (for your records)', accent: _accent, icon: Icons.bookmark_outline_rounded, required: true, max: 80),
        const SizedBox(height: 24),

        quoteSectionHeader(context, 'Live Preview', _accent, icon: Icons.visibility_rounded),
        const _QuotePreviewCard(),
        const SizedBox(height: 24),

        // ── Business logo sizer ─────────────────────────────────────────────
        // Reposition/zoom/shape the logo for THIS quote only — the saved
        // business profile's own logo settings are untouched.
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

        // ── Preview & Download ──────────────────────────────────────────────
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

// =============================================================================
// Currency display mode selector — segmented Code / Symbol / Both control
// with a live preview, mirroring step_create_invoice.dart's
// _InvoiceCurrencyDisplayModeSelector. Kept private/self-contained here
// rather than shared, matching this app's existing per-flow widget
// pattern (quote_edit_widgets.dart's old kQuoteCurrencies/
// quoteCurrencySymbol are no longer used by this screen).
// =============================================================================

class _QuoteCurrencyDisplayModeSelector extends StatelessWidget {
  final String value; // 'code' | 'symbol' | 'both'
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
