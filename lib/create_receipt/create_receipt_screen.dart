// lib/create_receipt/create_receipt_screen.dart
//
// TEMPLATE + LOGO SIZER PASS (this update): _syncToProvider() now also
// sets layoutTemplateId on the built ReceiptData (widget.layoutTemplateId,
// chosen on ReceiptTemplateChooserScreen — previously stored in
// _layoutTemplateId but never actually written to ReceiptData, same bug
// pattern the quote editor had, per this file's own earlier header
// comment about the full preview screen always rendering Executive
// regardless of the chosen id). A new "Business Logo" section on the
// Review & Save step lets the logo be repositioned/zoomed/reshaped
// independently of the saved business profile it came from — local
// _logoPath/_logoOffset/_logoScale/_logoShape state, seeded from whichever
// profile is selected in _applyBusinessProfile() but editable afterward
// via SharedLogoPicker, then written directly into the ReceiptData built
// in _syncToProvider().
//
// Receipt editor stepper. Rebuilt from scratch — the previous version of
// this file was a leftover copy of quote_editor_screen.dart (wrong class
// name, wrong imports pointing at create_quote_section/*, wrong Quote*
// prefixed types), which broke the build. This version is self-contained:
// imports only the sibling receipt_*.dart files under lib/create_receipt/,
// same pattern already established by receipt_business_profile_library.dart,
// receipt_client_library.dart, and receipt_full_preview_screen.dart.
//
// Business Info and Client & Details steps use the saved-profile /
// saved-client library pattern (tap a saved card to select it, or "Add
// New..." to open the sheet) — same UX as the invoice and quote editors.
// Next is blocked on step 0 until a business profile is selected, and on
// step 1 until a client is selected.
//
// KNOWN GAP (same one flagged in quote_editor_screen.dart): if you open an
// existing *saved* receipt to edit it, business/client selection will NOT
// auto-restore from that receipt's previously-stored raw strings —
// _selectedBizProfile / _selectedClient both start null regardless of
// what's already saved on the receipt. Flag it if you want this
// reconciled.
//
// NOTE on saving: ReceiptProvider.saveCurrentReceipt() returns Future<void>
// (unlike QuoteProvider.saveCurrentQuote(), which hands back the SavedQuote
// directly). After awaiting the save, this screen looks the SavedReceipt
// back up via the newly-added ReceiptProvider.currentReceiptId getter.

import 'package:flutter/material.dart';
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
import 'receipt_client_library.dart';
import 'receipt_business_profile_library.dart';

class CreateReceiptScreen extends StatefulWidget {
  /// Visual layout template id chosen on ReceiptTemplateChooserScreen.
  final int layoutTemplateId;

  const CreateReceiptScreen({
    super.key,
    this.layoutTemplateId = 1,
  });

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  static const Color _accent = Color(0xFF2E7D32); // matches ReceiptColor.green

  static const List<StepMeta> _steps = [
    StepMeta(label: 'Business Info', icon: Icons.storefront_rounded),
    StepMeta(label: 'Client & Details', icon: Icons.person_rounded),
    StepMeta(label: 'Line Items', icon: Icons.list_alt_rounded),
    StepMeta(label: 'Review & Save', icon: Icons.rate_review_rounded),
  ];

  int _step = 0;
  bool _saving = false;
  late int _layoutTemplateId;

  // Business — sourced entirely from a selected saved profile.
  ReceiptBusinessProfile? _selectedBizProfile;

  // Client — same pattern.
  ReceiptClient? _selectedClient;

  // Logo override — seeded from _selectedBizProfile whenever a new profile
  // is picked, but independently editable afterward via the Business Logo
  // section on the Review step (SharedLogoPicker), so the logo can be
  // repositioned/zoomed/reshaped per-receipt without altering the saved
  // profile itself.
  String? _logoPath;
  Offset _logoOffset = Offset.zero;
  double _logoScale = 1.0;
  LogoShape _logoShape = LogoShape.roundedSquare;
  double _logoSize = 44.0;

  // Receipt details
  late TextEditingController _receiptNumber;
  late TextEditingController _notes;
  String _paymentDate = '';
  String _currency = 'USD';
  PaymentMethod _paymentMethod = PaymentMethod.cash;

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
  ReceiptColor _colorScheme = ReceiptColor.green;
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _layoutTemplateId = widget.layoutTemplateId;
    final r = context.read<ReceiptProvider>().currentReceiptData;
    _logoSize = r.businessLogoDisplaySize;

    final now = DateTime.now();
    _receiptNumber = TextEditingController(
      text: r.receiptNumber.isNotEmpty ? r.receiptNumber : 'R-${now.millisecondsSinceEpoch.toString().substring(7)}',
    );
    _notes         = TextEditingController(text: r.notes);
    _paymentDate   = r.paymentDate.isNotEmpty ? r.paymentDate : DateFormat('d MMM yyyy').format(now);
    _currency      = r.currency;
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
  }

  @override
  void dispose() {
    for (final c in [
      _receiptNumber, _notes, _titleCtrl, _taxCtrl, _discountCtrl,
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

  // ── Saved-client / saved-business-profile library callbacks ────────────────

  void _applyClient(ReceiptClient? client) {
    setState(() {
      _selectedClient = client;
      if (client != null && _titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = '${client.name} Receipt';
      }
    });
  }

  void _applyBusinessProfile(ReceiptBusinessProfile? profile) {
    setState(() {
      _selectedBizProfile = profile;
      // Re-seed the logo override from the newly selected profile — same
      // reasoning as the quote editor: switching business profiles should
      // bring that business's own logo along, discarding any manual
      // reposition/zoom done for a previous profile.
      _logoPath = profile?.logoPath;
      _logoOffset = profile?.logoOffset ?? Offset.zero;
      _logoScale = profile?.logoScale ?? 1.0;
      _logoShape = profile?.shape ?? LogoShape.roundedSquare;
    });
  }

  void _syncToProvider() {
    final provider = context.read<ReceiptProvider>();
    final existing = provider.currentReceiptData;
    final data = ReceiptData(
      businessName: _selectedBizProfile?.businessName ?? '',
      businessEmail: _selectedBizProfile?.businessEmail ?? '',
      businessPhone: _selectedBizProfile?.businessPhone ?? '',
      businessAddress: _selectedBizProfile?.businessAddress ?? '',
      businessLogoPath: _logoPath,
      businessLogoOffsetDx: _logoOffset.dx,
      businessLogoOffsetDy: _logoOffset.dy,
      businessLogoScale: _logoScale,
      businessLogoShape: _logoShape.storageName,
      businessLogoDisplaySize: _logoSize,
      clientName: _selectedClient?.name ?? '',
      clientEmail: _selectedClient?.email ?? '',
      clientPhone: _selectedClient?.phone ?? '',
      clientAddress: _selectedClient?.address ?? '',
      receiptNumber: _receiptNumber.text,
      paymentDate: _paymentDate,
      notes: _notes.text,
      currency: _currency,
      lineItems: _currentLineItems,
      taxRate: _taxRate,
      discountRate: _discountRate,
      paymentMethod: _paymentMethod,
      // Preserve fields this editor doesn't manage directly.
      status: existing.status,
      fontFamily: existing.fontFamily,
      colorScheme: _colorScheme,
      layoutTemplateId: _layoutTemplateId,
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

  // Syncs the draft to ReceiptProvider (same as step navigation) and pushes
  // the full preview screen wrapped around the same provider instance, so
  // Preview & Download always reflects exactly what's on screen.
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
      // Shouldn't happen, but don't crash the flow if it does — just pop
      // back rather than navigating to a detail screen with nothing to show.
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
        nextLabel: _step == 3 ? 'Save Receipt' : 'Next',
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

  // ── Status strip — shown under both library sections.
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
        : 'Using "${_selectedBizProfile!.profileName.isNotEmpty ? _selectedBizProfile!.profileName : _selectedBizProfile!.businessName}" for this receipt.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptBusinessProfileLibrarySection(
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
        : 'Using "${_selectedClient!.name}" for this receipt.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Saved clients ────────────────────────────────────────────────
        ReceiptClientLibrarySection(
          accent: _accent,
          onClientSelected: _applyClient,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedClient != null, label: label),
        const SizedBox(height: 24),

        receiptSectionHeader(context, 'Receipt Details', _accent, icon: Icons.receipt_rounded),
        ReceiptField(ctrl: _receiptNumber, label: 'Receipt Number', accent: _accent, icon: Icons.tag_rounded, max: 40),
        const SizedBox(height: 12),
        ReceiptDateField(label: 'Payment Date', value: _paymentDate, accent: _accent, onTap: _pickDate),
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
          items: kReceiptCurrencies
              .map((c) => DropdownMenuItem(value: c['code'], child: Text('${c['code']} (${c['symbol']})')))
              .toList(),
          onChanged: (v) => setState(() => _currency = v ?? _currency),
        ),
        const SizedBox(height: 20),
        receiptSectionHeader(context, 'Payment Method', _accent, icon: Icons.payments_rounded),
        ReceiptPaymentMethodPicker(
          selected: _paymentMethod,
          accent: _accent,
          onChanged: (m) => setState(() => _paymentMethod = m),
        ),
        const SizedBox(height: 20),
        ReceiptField(ctrl: _notes, label: 'Notes', accent: _accent, icon: Icons.notes_rounded, maxLines: 3, max: 500),
      ],
    );
  }

  Widget _lineItemsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            currencySymbol: receiptCurrencySymbol(_currency),
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
        receiptSectionHeader(context, 'Tax & Discount', _accent, icon: Icons.percent_rounded),
        Row(
          children: [
            Expanded(
              child: ReceiptField(
                ctrl: _taxCtrl,
                label: 'Tax %',
                accent: _accent,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
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
          currencySymbol: receiptCurrencySymbol(_currency),
          accent: _accent,
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Receipt Title', _accent, icon: Icons.title_rounded),
        ReceiptField(ctrl: _titleCtrl, label: 'Title (for your records)', accent: _accent, icon: Icons.bookmark_outline_rounded, required: true, max: 80),
        const SizedBox(height: 24),

        // ── Business logo sizer ─────────────────────────────────────────
        // Reposition/zoom/shape the logo for THIS receipt only — the
        // saved business profile's own logo settings are untouched.
        receiptSectionHeader(context, 'Business Logo', _accent, icon: Icons.image_rounded),
        SharedLogoPicker(
          logoPath: _logoPath,
          logoOffset: _logoOffset,
          logoScale: _logoScale,
          logoShape: _logoShape,
          accent: _accent,
          onChanged: (path, offset, scale, shape) {
            setState(() {
              _logoPath = path;
              _logoOffset = offset;
              _logoScale = scale;
              _logoShape = shape;
            });
          },
        ),
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
                            ? (v) => setState(() => _logoSize = v)
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

        receiptSectionHeader(context, 'Accent Color', _accent, icon: Icons.palette_outlined),
        ReceiptColorPicker(selected: _colorScheme, onChanged: (c) => setState(() => _colorScheme = c)),
        const SizedBox(height: 24),
        receiptSectionHeader(context, 'Summary', _accent, icon: Icons.summarize_rounded),
        ReceiptTotalsCard(
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          amountPaid: _amountPaid,
          taxRate: _taxRate,
          discountRate: _discountRate,
          currencySymbol: receiptCurrencySymbol(_currency),
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
