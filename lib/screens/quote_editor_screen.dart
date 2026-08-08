// lib/screens/quote_editor_screen.dart
//
// UPDATED (this pass): Business Info and Client & Details steps no longer
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
// UPDATED (this pass, 2): Next is now blocked on step 0 until a business
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
// Everything below this point (Line Items step, Review & Save step,
// StepEditorHeader, preview/save flow) is otherwise unchanged from before.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/quote_provider.dart';
import '../models/quote_data.dart';
import '../models/invoice_data.dart' show LineItem;
import '../widgets/step_editor_header.dart';
import 'saved_invoice_details_section/saved_document_detail_screen.dart';
import 'create_quote_section/quote_edit_widgets.dart';
import 'create_quote_section/quote_full_preview_screen.dart';
import 'create_quote_section/quote_client_library.dart';
import 'create_quote_section/quote_business_profile_library.dart';

class QuoteEditorScreen extends StatefulWidget {
  /// Visual layout template id chosen on QuoteTemplateChooserScreen.
  /// Currently stored only — no quote layout exists yet to act on it.
  final int layoutTemplateId;

  const QuoteEditorScreen({
    super.key,
    this.layoutTemplateId = 1,
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

  int _step = 0;
  bool _saving = false;
  late int _layoutTemplateId;

  // Business — now sourced entirely from a selected saved profile. No more
  // inline TextEditingControllers for these; the sheet owns its own.
  QuoteBusinessProfile? _selectedBizProfile;

  // Client — same pattern.
  QuoteClient? _selectedClient;

  // Quote details — still edited inline, unrelated to the saved-profile
  // pattern above.
  late TextEditingController _quoteNumber;
  late TextEditingController _notes;
  String _issueDate = '';
  String _expiryDate = '';
  String _currency = 'USD';

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

  @override
  void initState() {
    super.initState();
    _layoutTemplateId = widget.layoutTemplateId;
    final q = context.read<QuoteProvider>().quoteData;

    final now = DateTime.now();
    _quoteNumber = TextEditingController(
      text: q.quoteNumber.isNotEmpty ? q.quoteNumber : 'Q-${now.millisecondsSinceEpoch.toString().substring(7)}',
    );
    _notes        = TextEditingController(text: q.notes);
    _issueDate    = q.issueDate.isNotEmpty ? q.issueDate : DateFormat('d MMM yyyy').format(now);
    _expiryDate   = q.expiryDate.isNotEmpty ? q.expiryDate : DateFormat('d MMM yyyy').format(now.add(const Duration(days: 14)));
    _currency     = q.currency;
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

  // ── Saved-client / saved-business-profile library callbacks ────────────────
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
    setState(() => _selectedBizProfile = profile);
  }

  void _syncToProvider() {
    final provider = context.read<QuoteProvider>();
    provider.updateBusinessInfo(
      businessName: _selectedBizProfile?.businessName ?? '',
      businessEmail: _selectedBizProfile?.businessEmail ?? '',
      businessPhone: _selectedBizProfile?.businessPhone ?? '',
      businessAddress: _selectedBizProfile?.businessAddress ?? '',
      businessLogoPath: _selectedBizProfile?.logoPath,
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
      currency: _currency,
      taxRate: _taxRate,
      discountRate: _discountRate,
    );
    provider.updateQuoteData(provider.quoteData.copyWith(lineItems: _currentLineItems));
    provider.updateColorScheme(_colorScheme);
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
        // ── Saved clients ────────────────────────────────────────────────
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
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: InputDecoration(
            labelText: 'Currency',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : const Color(0xFFF9F9F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: kQuoteCurrencies
              .map((c) => DropdownMenuItem(value: c['code'], child: Text('${c['code']} (${c['symbol']})')))
              .toList(),
          onChanged: (v) => setState(() => _currency = v ?? _currency),
        ),
        const SizedBox(height: 12),
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
            currencySymbol: quoteCurrencySymbol(_currency),
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
          currencySymbol: quoteCurrencySymbol(_currency),
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
        quoteSectionHeader(context, 'Accent Color', _accent, icon: Icons.palette_outlined),
        QuoteColorPicker(selected: _colorScheme, onChanged: (c) => setState(() => _colorScheme = c)),
        const SizedBox(height: 24),
        quoteSectionHeader(context, 'Summary', _accent, icon: Icons.summarize_rounded),
        QuoteTotalsCard(
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          total: _total,
          taxRate: _taxRate,
          discountRate: _discountRate,
          currencySymbol: quoteCurrencySymbol(_currency),
          accent: _accent,
        ),
        const SizedBox(height: 20),

        // ── Preview & Download ──────────────────────────────────────────
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
