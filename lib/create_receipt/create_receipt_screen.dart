// lib/create_receipt/create_receipt_screen.dart
//
// TEMPLATE ROUTING (this pass): accepts an optional layoutTemplateId, same
// role as EditorScreen/QuoteEditorScreen's parameter of the same name —
// set when the receipt was started from a template card on
// DocumentTemplatesScreen instead of the plain "Create Receipt" button.
// Resolved to a design name via kInvoiceTemplates (invoice's and quote's
// template registries list the exact same 10 designs by id/name, so
// either works as the lookup source) and saved as the receipt's
// templateName — same field invoices/quotes already use, previously
// always hardcoded to 'Standard' here since receipts had no template
// concept yet. Only applies to new receipts; editing an existing one
// (existingReceiptId set) keeps whatever templateName it already has.
//
// UPDATED (earlier pass): Business step and Client & Details step now match
// the invoice/quote flow's saved-profile pattern:
//   - Business step: inline Logo/Business Name/Email/Phone/Address fields
//     removed. Only ReceiptBusinessProfileLibrarySection (saved cards +
//     "Add New Business Profile" opening a bottom sheet, Save at the
//     sheet's bottom) remains. Next is blocked until a profile is selected.
//   - Client & Details step: inline Customer Name/Email/Phone/Address
//     fields removed in favour of ReceiptClientLibrarySection, same
//     pattern. Receipt Details (receipt number, payment date, currency,
//     payment method) stays inline on this step, unchanged — it isn't a
//     "saved" concept the way business/client profiles are, matching how
//     Quote Details was left inline on the quote flow's equivalent step.
//     Next is blocked until a client is selected.
//   - "Save Receipt" bottom-bar button is gone. The receipt now auto-saves:
//     every change (profile/client selection, line items, tax/discount,
//     notes, dates, payment method) schedules a debounced save via
//     ReceiptProvider — no explicit save action required. The final step's
//     button is "Done", which just validates line items and closes the
//     screen (data is already persisted by then).
//
// KNOWN GAP (carried over from the quote pass): opening an existing saved
// receipt to edit it passes businessProfileId/clientId as
// initialSelectedId to the library sections, so it WILL auto-restore the
// matching saved profile/client if one still exists with those ids — this
// works because _selectedBusinessProfileId/_selectedClientId are persisted
// on ReceiptData below. If the saved profile/client was since deleted from
// the library, the step falls back to unselected and Next stays blocked
// until the user reselects.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice_data.dart' show LineItem;
import '../models/receipt_data.dart';
import '../providers/receipt_provider.dart';
import '../screens/invoice_create_section/invoice_template_previews/preview_registry.dart'
    show kInvoiceTemplates;
import '../widgets/step_editor_header.dart';
import 'receipt_business_profile_library.dart';
import 'receipt_client_library.dart';
import 'receipt_edit_widgets.dart';
import 'receipt_full_preview_screen.dart';

class CreateReceiptScreen extends StatefulWidget {
  final String? existingReceiptId;
  final int? layoutTemplateId;

  const CreateReceiptScreen({
    super.key,
    this.existingReceiptId,
    this.layoutTemplateId,
  });

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  static const _accent = Color(0xFF2E7D32);

  static const List<StepMeta> _steps = [
    StepMeta(label: 'Business', icon: Icons.store_rounded),
    StepMeta(label: 'Client & Details', icon: Icons.person_rounded),
    StepMeta(label: 'Line Items', icon: Icons.list_alt_rounded),
    StepMeta(label: 'Review & Save', icon: Icons.rate_review_rounded),
  ];

  int _step = 0;

  bool get _isEditing => widget.existingReceiptId != null;

  // Resolved once from widget.layoutTemplateId — 'Standard' if none was
  // passed (plain "Create Receipt" entry point) or the id doesn't match
  // any known design. Editing an existing receipt ignores this entirely
  // and keeps its already-saved templateName (see _persistDraft).
  String get _templateName {
    final id = widget.layoutTemplateId;
    if (id == null) return 'Standard';
    for (final t in kInvoiceTemplates) {
      if (t.id == id) return t.name;
    }
    return 'Standard';
  }

  late TextEditingController _receiptNumberCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _currencyCtrl;

  final List<LineItem> _items = [];
  final List<TextEditingController> _descCtrl = [];
  final List<TextEditingController> _qtyCtrl = [];
  final List<TextEditingController> _priceCtrl = [];

  DateTime _paymentDate = DateTime.now();
  ReceiptColor _colorScheme = ReceiptColor.green;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  // ── Saved-profile / saved-client selection (replaces inline fields) ────
  ReceiptBusinessProfile? _selectedBusinessProfile;
  ReceiptClient? _selectedClient;
  String? _initialBusinessProfileId;
  String? _initialClientId;

  Timer? _autoSaveTimer;
  bool _isSaving = false;

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.total);
  double get _taxAmount => _subtotal * (double.tryParse(_taxCtrl.text) ?? 0) / 100;
  double get _discountAmount =>
      _subtotal * (double.tryParse(_discountCtrl.text) ?? 0) / 100;
  double get _amountPaid => _subtotal + _taxAmount - _discountAmount;

  String get _currency => _currencyCtrl.text.trim().isEmpty ? 'USD' : _currencyCtrl.text.trim();

  static String _qtyText(double qty) => qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

  @override
  void initState() {
    super.initState();
    final ts = DateTime.now().millisecondsSinceEpoch;

    ReceiptData? existing;
    if (_isEditing) {
      final provider = context.read<ReceiptProvider>();
      provider.loadSavedReceipt(widget.existingReceiptId!);
      existing = provider.currentReceiptData;
    }

    _receiptNumberCtrl = TextEditingController(text: existing?.receiptNumber ?? 'RCPT-$ts');
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
    _taxCtrl = TextEditingController(text: (existing?.taxRate ?? 0).toString());
    _discountCtrl = TextEditingController(text: (existing?.discountRate ?? 0).toString());
    _currencyCtrl = TextEditingController(text: existing?.currency ?? 'USD');

    // Seed the saved-profile/client selection from whatever the loaded
    // receipt's business/client fields already look like. We don't have a
    // dedicated "businessProfileId"/"clientId" field on ReceiptData yet, so
    // we match by name+email as a best-effort restore; if the exact saved
    // entry was deleted from the library since, this falls back to
    // unselected and the user reselects (same known gap as the quote pass).
    if (existing != null && existing.businessName.isNotEmpty) {
      _selectedBusinessProfile = ReceiptBusinessProfile(
        id: '_preload_business',
        profileName: existing.businessName,
        businessName: existing.businessName,
        businessEmail: existing.businessEmail,
        businessPhone: existing.businessPhone,
        businessAddress: existing.businessAddress,
        logoPath: existing.businessLogoPath,
      );
    }
    if (existing != null && existing.clientName.isNotEmpty) {
      _selectedClient = ReceiptClient(
        id: '_preload_client',
        name: existing.clientName,
        email: existing.clientEmail,
        phone: existing.clientPhone,
        address: existing.clientAddress,
      );
    }

    if (existing != null && existing.paymentDate.isNotEmpty) {
      _paymentDate = DateTime.tryParse(existing.paymentDate) ?? DateTime.now();
    }
    _colorScheme = existing?.colorScheme ?? ReceiptColor.green;
    _paymentMethod = existing?.paymentMethod ?? PaymentMethod.cash;

    final sourceItems =
        (existing != null && existing.lineItems.isNotEmpty) ? existing.lineItems : [LineItem()];
    for (final item in sourceItems) {
      _items.add(item);
      _descCtrl.add(TextEditingController(text: item.description));
      _qtyCtrl.add(TextEditingController(text: _qtyText(item.quantity)));
      _priceCtrl.add(TextEditingController(text: item.unitPrice.toString()));
    }

    for (final c in [_taxCtrl, _discountCtrl, _currencyCtrl, _notesCtrl, _receiptNumberCtrl]) {
      c.addListener(_scheduleAutoSave);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (final c in [_receiptNumberCtrl, _notesCtrl, _taxCtrl, _discountCtrl, _currencyCtrl]) {
      c.dispose();
    }
    for (final cList in [_descCtrl, _qtyCtrl, _priceCtrl]) {
      for (final c in cList) c.dispose();
    }
    super.dispose();
  }

  // ── Auto-save ────────────────────────────────────────────────────────
  // Debounced so rapid typing doesn't hammer SharedPreferences — every
  // change reschedules a save 700ms out. Immediate (non-debounced) saves
  // happen on step transitions and profile/client selection, since those
  // are discrete actions rather than continuous typing.

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 700), () => _persistDraft());
  }

  Future<void> _persistDraft() async {
    final provider = context.read<ReceiptProvider>();
    final data = _buildCurrentReceiptData();
    provider.updateReceiptData(data);
    await provider.saveCurrentReceipt(
      title: _selectedClient?.name.isNotEmpty == true
          ? 'Receipt for ${_selectedClient!.name}'
          : 'Receipt ${_receiptNumberCtrl.text.trim()}',
      // New receipts started from a template card carry that design's name
      // through; editing an existing receipt keeps whatever it already had
      // (saveCurrentReceipt only overwrites templateName on first save for
      // a given id — see ReceiptProvider.saveCurrentReceipt).
      templateName: _templateName,
    );
  }

  // ── Line items ────────────────────────────────────────────────────────

  void _addItem() {
    setState(() {
      _items.add(LineItem());
      _descCtrl.add(TextEditingController());
      _qtyCtrl.add(TextEditingController(text: '1'));
      _priceCtrl.add(TextEditingController(text: '0'));
    });
    _scheduleAutoSave();
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items.removeAt(index);
      _descCtrl[index].dispose();
      _qtyCtrl[index].dispose();
      _priceCtrl[index].dispose();
      _descCtrl.removeAt(index);
      _qtyCtrl.removeAt(index);
      _priceCtrl.removeAt(index);
    });
    _scheduleAutoSave();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
      _scheduleAutoSave();
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────

  void _goToStep(int index) => setState(() => _step = index);

  void _nextStep() {
    if (_step == 0 && _selectedBusinessProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select or add a business profile to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_step == 1 && _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select or add a client to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _autoSaveTimer?.cancel();
    _persistDraft();

    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateItems() {
    if (_items.any((item) => item.description.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all item descriptions.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  ReceiptData _buildCurrentReceiptData() {
    return ReceiptData(
      businessName: _selectedBusinessProfile?.businessName ?? '',
      businessEmail: _selectedBusinessProfile?.businessEmail ?? '',
      businessPhone: _selectedBusinessProfile?.businessPhone ?? '',
      businessAddress: _selectedBusinessProfile?.businessAddress ?? '',
      businessLogoPath: _selectedBusinessProfile?.logoPath,
      clientName: _selectedClient?.name ?? '',
      clientEmail: _selectedClient?.email ?? '',
      clientPhone: _selectedClient?.phone ?? '',
      clientAddress: _selectedClient?.address ?? '',
      receiptNumber: _receiptNumberCtrl.text.trim(),
      paymentDate: DateFormat('yyyy-MM-dd').format(_paymentDate),
      notes: _notesCtrl.text.trim(),
      currency: _currency,
      lineItems: _items,
      taxRate: double.tryParse(_taxCtrl.text) ?? 0,
      discountRate: double.tryParse(_discountCtrl.text) ?? 0,
      paymentMethod: _paymentMethod,
      colorScheme: _colorScheme,
    );
  }

  // Pushes the current draft into ReceiptProvider and opens the full
  // preview screen wrapped around that same provider instance.
  void _openFullPreview() {
    final provider = context.read<ReceiptProvider>();
    provider.updateReceiptData(_buildCurrentReceiptData());
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

  // Final step's action — data is already auto-saved by this point, so
  // this just validates line items one last time and closes the screen.
  void _finish() {
    if (!_validateItems()) return;
    setState(() => _isSaving = true);
    _persistDraft().then((_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? '✓ Receipt updated!' : '✓ Receipt saved!'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    });
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          StepEditorHeader(
            title: _isEditing ? 'Edit Receipt' : 'Create Receipt',
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
        nextLabel: _step == _steps.length - 1 ? 'Done' : 'Next',
        nextIcon: _step == _steps.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
        isLoading: _isSaving,
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

  Widget _businessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptBusinessProfileLibrarySection(
          accent: _accent,
          initialSelectedId: _initialBusinessProfileId,
          onProfileSelected: (profile) {
            setState(() => _selectedBusinessProfile = profile);
            _persistDraft();
          },
        ),
      ],
    );
  }

  Widget _clientAndDetailsStep() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptClientLibrarySection(
          accent: _accent,
          initialSelectedId: _initialClientId,
          onClientSelected: (client) {
            setState(() => _selectedClient = client);
            _persistDraft();
          },
        ),
        const SizedBox(height: 24),

        receiptSectionHeader(context, 'Receipt Details', _accent, icon: Icons.receipt_rounded),
        ReceiptField(ctrl: _receiptNumberCtrl, label: 'Receipt Number', accent: _accent, icon: Icons.tag_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ReceiptDateField(
                label: 'Payment Date',
                value: dateFormat.format(_paymentDate),
                accent: _accent,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReceiptField(ctrl: _currencyCtrl, label: 'Currency', accent: _accent, icon: Icons.attach_money_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text('Payment Method',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 6),
        ReceiptPaymentMethodPicker(
          selected: _paymentMethod,
          accent: _accent,
          onChanged: (m) {
            setState(() => _paymentMethod = m);
            _scheduleAutoSave();
          },
        ),
      ],
    );
  }

  Widget _lineItemsStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: receiptSectionHeader(context, 'Line Items', _accent, icon: Icons.list_alt_rounded),
            ),
            GestureDetector(
              onTap: _addItem,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2A0F) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 16, color: _accent),
                    const SizedBox(width: 4),
                    const Text('Add Item',
                        style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
        ...List.generate(_items.length, (index) {
          final qty = double.tryParse(_qtyCtrl[index].text) ?? 0.0;
          final price = double.tryParse(_priceCtrl[index].text) ?? 0.0;
          return ReceiptItemCard(
            index: index,
            descCtrl: _descCtrl[index],
            qtyCtrl: _qtyCtrl[index],
            priceCtrl: _priceCtrl[index],
            total: qty * price,
            currencySymbol: _currency,
            canRemove: _items.length > 1,
            accent: _accent,
            onRemove: () => _removeItem(index),
            onChanged: () {
              setState(() {
                _items[index].description = _descCtrl[index].text;
                _items[index].quantity = qty;
                _items[index].unitPrice = price;
              });
              _scheduleAutoSave();
            },
          );
        }),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: ReceiptField(
                ctrl: _taxCtrl,
                label: 'Tax %',
                accent: _accent,
                icon: Icons.percent_rounded,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReceiptField(
                ctrl: _discountCtrl,
                label: 'Discount %',
                accent: _accent,
                icon: Icons.local_offer_rounded,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        ReceiptTotalsCard(
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          amountPaid: _amountPaid,
          taxRate: double.tryParse(_taxCtrl.text) ?? 0,
          discountRate: double.tryParse(_discountCtrl.text) ?? 0,
          currencySymbol: _currency,
          accent: _accent,
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        receiptSectionHeader(context, 'Notes', _accent, icon: Icons.notes_rounded),
        ReceiptField(ctrl: _notesCtrl, label: 'Notes', accent: _accent, icon: Icons.note_rounded, maxLines: 3),
        const SizedBox(height: 24),

        receiptSectionHeader(context, 'Summary', _accent, icon: Icons.summarize_rounded),
        ReceiptTotalsCard(
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          amountPaid: _amountPaid,
          taxRate: double.tryParse(_taxCtrl.text) ?? 0,
          discountRate: double.tryParse(_discountCtrl.text) ?? 0,
          currencySymbol: _currency,
          accent: _accent,
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 14, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your changes are saved automatically.',
                  style: TextStyle(fontSize: 11, color: const Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
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
