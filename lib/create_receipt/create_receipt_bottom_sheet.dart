// lib/create_receipt/create_receipt_bottom_sheet.dart
//
// NEW FILE — RECEIPT LIBRARY RESTRUCTURE PASS: mirrors
// create_invoice_bottom_sheet.dart / create_quote_bottom_sheet.dart
// exactly. Holds the entire receipt-editing form (receipt number,
// payment date, currency, customer override, payment method, Saved Item
// Sets panel, line items, tax/discount, totals, notes) that previously
// lived inline in create_receipt_screen.dart's _createReceiptStep().
// Shown as a bottom sheet (DraggableScrollableSheet) from the new
// library screen in create_receipt/step_create_receipt.dart, instead of
// being a step's only content.
//
// Only the fields actually editable on this step are ever set into the
// resulting ReceiptData — everything else (business info, logo, thermal
// settings, social handles, font, colour, layoutTemplateId, paperFormat)
// is preserved unchanged via ReceiptData.copyWith() against whatever's
// already on ReceiptProvider, since those stay owned by
// create_receipt_screen.dart's own Customise-step state (see
// receipt_data.dart's SavedReceiptDraft doc comment).
//
// Receipt Number stays OPTIONAL in label (ReceiptField's automatic
// "(Optional)" suffix, matching the original screen's behavior — no
// required:true was ever passed here) even though _validateForm() below
// still enforces it be non-empty before saving, exactly matching
// create_receipt_screen.dart's pre-restructure _stepBlockReason(2) /
// _validateDetailsStep() behavior — this pass changes WHERE that
// validation lives, not what it checks.
//
// Adds a Payment Method section (ReceiptPaymentMethodPicker) between
// Currency and the Client Details / Saved Item Sets block, matching the
// original step's field order exactly.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../models/invoice_data.dart' show LineItem;
import '../models/receipt_data.dart';
import '../providers/receipt_provider.dart';
import 'receipt_edit_widgets.dart';
import 'receipt_step_customer.dart' show ReceiptClient;
import 'receipt_step_template.dart' show ReceiptTemplate;
import 'receipt_saved_items_widgets.dart';

// =============================================================================
// CreateReceiptBottomSheet
// =============================================================================

class CreateReceiptBottomSheet extends StatefulWidget {
  final ReceiptClient? selectedClient;
  final ReceiptTemplate? selectedTemplate;

  /// The draft being edited, or null when creating a brand new one.
  final SavedReceiptDraft? existing;

  final void Function(SavedReceiptDraft draft) onSaved;

  const CreateReceiptBottomSheet({
    super.key,
    this.selectedClient,
    this.selectedTemplate,
    this.existing,
    required this.onSaved,
  });

  @override
  State<CreateReceiptBottomSheet> createState() =>
      _CreateReceiptBottomSheetState();
}

class _CreateReceiptBottomSheetState extends State<CreateReceiptBottomSheet> {
  static const _accent = Color(0xFF2E7D32);

  static const int _receiptNumberMax = 40;

  late TextEditingController _nameCtrl;

  late TextEditingController _receiptNumberCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;

  late TextEditingController _custNameCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;
  late TextEditingController _custAddressCtrl;

  late List<LineItem> _items;
  final List<TextEditingController> _descCtrl = [];
  final List<TextEditingController> _qtyCtrl = [];
  final List<TextEditingController> _priceCtrl = [];

  String _paymentDate = '';

  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code';

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  double _taxRate = 0.0;
  double _discountRate = 0.0;

  static const _dateFmt = 'd MMM yyyy';

  bool get _isEditing => widget.existing != null;

  String get _currencyPrefix {
    final symbol = _currencySymbolCtrl.text.trim();
    final code = _currencyCodeCtrl.text.trim().toUpperCase();
    if (symbol.isNotEmpty) return symbol;
    if (code.isNotEmpty) return '$code ';
    return '';
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _taxAmount => _subtotal * _taxRate / 100;
  double get _discountAmount => _subtotal * _discountRate / 100;
  double get _amountPaid => _subtotal + _taxAmount - _discountAmount;

  @override
  void initState() {
    super.initState();

    final existingData = widget.existing?.data;
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    final tsShort = ts
        .toString()
        .substring((ts.toString().length - 6).clamp(0, ts.toString().length));

    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');

    _receiptNumberCtrl = TextEditingController(
      text: (existingData != null && existingData.receiptNumber.isNotEmpty)
          ? existingData.receiptNumber
          : 'R-$tsShort',
    );
    _notesCtrl = TextEditingController(text: existingData?.notes ?? '');
    _taxCtrl = TextEditingController(
      text: (existingData == null || existingData.taxRate == 0)
          ? '0'
          : '${existingData.taxRate}',
    );
    _discountCtrl = TextEditingController(
      text: (existingData == null || existingData.discountRate == 0)
          ? '0'
          : '${existingData.discountRate}',
    );
    _taxRate = (existingData?.taxRate ?? 0.0).clamp(0.0, 100.0);
    _discountRate = (existingData?.discountRate ?? 0.0).clamp(0.0, 100.0);
    _paymentMethod = existingData?.paymentMethod ?? PaymentMethod.cash;

    _custNameCtrl = TextEditingController(
      text: widget.selectedClient?.name ?? existingData?.clientName ?? '',
    );
    _custEmailCtrl = TextEditingController(
      text: widget.selectedClient?.email ?? existingData?.clientEmail ?? '',
    );
    _custPhoneCtrl = TextEditingController(
      text: widget.selectedClient?.phone ?? existingData?.clientPhone ?? '',
    );
    _custAddressCtrl = TextEditingController(
      text:
          widget.selectedClient?.address ?? existingData?.clientAddress ?? '',
    );

    final initialCurrencyCode = widget.selectedTemplate?.currency ??
        ((existingData != null && existingData.currency.isNotEmpty)
            ? existingData.currency
            : 'USD');
    _currencyCodeCtrl = TextEditingController(text: initialCurrencyCode);
    _currencySymbolCtrl =
        TextEditingController(text: existingData?.currencySymbol ?? '');
    _currencyDisplayMode =
        (existingData != null && existingData.currencyDisplayMode.isNotEmpty)
            ? existingData.currencyDisplayMode
            : 'code';

    _paymentDate = (existingData != null && existingData.paymentDate.isNotEmpty)
        ? existingData.paymentDate
        : DateFormat(_dateFmt).format(now);

    _items = (existingData != null && existingData.lineItems.isNotEmpty)
        ? existingData.lineItems.map((i) => i.copyWith()).toList()
        : [LineItem()];
    for (final item in _items) {
      _descCtrl.add(TextEditingController(text: item.description));
      _qtyCtrl.add(TextEditingController(
        text: item.quantity == 1.0 ? '1' : '${item.quantity}',
      ));
      _priceCtrl.add(TextEditingController(
        text: item.unitPrice == 0.0 ? '0' : '${item.unitPrice}',
      ));
    }

    for (final c in [
      _nameCtrl,
      _receiptNumberCtrl,
      _taxCtrl,
      _discountCtrl,
      _currencyCodeCtrl,
      _currencySymbolCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _receiptNumberCtrl, _notesCtrl, _taxCtrl,
      _discountCtrl, _custNameCtrl, _custEmailCtrl,
      _custPhoneCtrl, _custAddressCtrl,
      _currencyCodeCtrl, _currencySymbolCtrl,
    ]) {
      c.dispose();
    }
    for (final cList in [_descCtrl, _qtyCtrl, _priceCtrl]) {
      for (final c in cList) c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Items
  // ---------------------------------------------------------------------------
  void _addItem() {
    setState(() {
      _items.add(LineItem());
      _descCtrl.add(TextEditingController());
      _qtyCtrl.add(TextEditingController(text: '1'));
      _priceCtrl.add(TextEditingController(text: '0'));
    });
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
  }

  // ---------------------------------------------------------------------------
  // Saved item sets — quick add via ReceiptSavedItemSets
  // (receipt_saved_items_widgets.dart), a SEPARATE Receipt-only library
  // from Invoice's/Quote's own saved item sets.
  // ---------------------------------------------------------------------------
  List<LineItem> _getCurrentItemsSnapshot() {
    for (int i = 0; i < _items.length; i++) {
      _items[i]
        ..description = _descCtrl[i].text.trim()
        ..quantity = double.tryParse(_qtyCtrl[i].text) ?? 1
        ..unitPrice = double.tryParse(_priceCtrl[i].text) ?? 0;
    }
    return _items.map((i) => i.copyWith()).toList();
  }

  void _quickAddItems(List<LineItem> items) {
    setState(() {
      if (_items.length == 1 &&
          _items[0].description.trim().isEmpty &&
          _items[0].quantity == 1.0 &&
          _items[0].unitPrice == 0.0) {
        _items.removeAt(0);
        _descCtrl.removeAt(0).dispose();
        _qtyCtrl.removeAt(0).dispose();
        _priceCtrl.removeAt(0).dispose();
      }
      for (final item in items) {
        final newItem = item.copyWith();
        _items.add(newItem);
        _descCtrl.add(TextEditingController(text: newItem.description));
        _qtyCtrl.add(TextEditingController(
          text: newItem.quantity == 1.0 ? '1' : '${newItem.quantity}',
        ));
        _priceCtrl.add(TextEditingController(
          text: newItem.unitPrice == 0.0 ? '0' : '${newItem.unitPrice}',
        ));
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Validation — same rules as the original step's
  // _stepBlockReason(2)/_validateDetailsStep()/_validateLineItemsStep().
  // ---------------------------------------------------------------------------
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateForm() {
    if (_receiptNumberCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a receipt number.');
      return false;
    }

    if (widget.selectedClient == null && _custNameCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a client name.');
      return false;
    }

    for (final c in _descCtrl) {
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

  // ---------------------------------------------------------------------------
  // Save — validates, flushes controller text into _items, builds the
  // final ReceiptData by copyWith-ing over whatever's currently on
  // ReceiptProvider (preserving business info/logo/thermal/social/font/
  // colour/layoutTemplateId/paperFormat untouched), wraps it in a
  // SavedReceiptDraft (preserving id/createdAt when editing), hands it to
  // the parent via onSaved(), and closes the sheet.
  // ---------------------------------------------------------------------------
  void _save() {
    if (!_validateForm()) return;

    for (int i = 0; i < _items.length; i++) {
      _items[i]
        ..description = _descCtrl[i].text.trim()
        ..quantity = double.tryParse(_qtyCtrl[i].text) ?? 1
        ..unitPrice = double.tryParse(_priceCtrl[i].text) ?? 0;
    }

    final current = context.read<ReceiptProvider>().currentReceiptData;

    final data = current.copyWith(
      clientName: _custNameCtrl.text.trim(),
      clientEmail: _custEmailCtrl.text.trim(),
      clientPhone: _custPhoneCtrl.text.trim(),
      clientAddress: _custAddressCtrl.text.trim(),
      receiptNumber: _receiptNumberCtrl.text.trim(),
      paymentDate: _paymentDate,
      notes: _notesCtrl.text.trim(),
      currency: _currencyCodeCtrl.text.trim().isEmpty
          ? 'USD'
          : _currencyCodeCtrl.text.trim().toUpperCase(),
      currencySymbol: _currencySymbolCtrl.text.trim(),
      currencyDisplayMode: _currencyDisplayMode,
      lineItems: List<LineItem>.from(_items),
      taxRate: _taxRate,
      discountRate: _discountRate,
      paymentMethod: _paymentMethod,
    );

    final now = DateTime.now();
    final draft = SavedReceiptDraft(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      data: data,
      createdAt: widget.existing?.createdAt ?? now,
      lastEditedAt: now,
    );

    widget.onSaved(draft);
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paymentDate = DateFormat(_dateFmt).format(picked));
    }
  }

  // ---------------------------------------------------------------------------
  // Section helpers
  // ---------------------------------------------------------------------------
  Widget _counter(int current, int max) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$current / $max',
          style: TextStyle(
            fontSize: 11,
            color: current > max
                ? const Color(0xFFF44336)
                : colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _contextBanner(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final template = widget.selectedTemplate;
    final client = widget.selectedClient;
    final hasTemplate = template != null;
    final hasClient = client != null;

    if (!hasTemplate && !hasClient) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2200) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark
                  ? const Color(0xFFFFE082).withValues(alpha: 0.4)
                  : const Color(0xFFFFE082)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 14, color: Color(0xFFF57F17)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No template or customer selected. You can fill in details manually below.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFFFFA726)
                      : const Color(0xFF795548),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (hasTemplate)
          _bannerChip(
            icon: Icons.description_rounded,
            color: const Color(0xFF1565C0),
            label: 'Template: ${template.name}',
            sub: template.businessName.isNotEmpty ? template.businessName : null,
            isDark: isDark,
          ),
        if (hasTemplate && hasClient) const SizedBox(height: 8),
        if (hasClient)
          _bannerChip(
            icon: Icons.person_rounded,
            color: const Color(0xFF2E7D32),
            label: 'Customer: ${client.name}',
            sub: client.email.isNotEmpty ? client.email : null,
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _bannerChip({
    required IconData icon,
    required Color color,
    required String label,
    String? sub,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 16, color: Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _currencyDisplayModeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewCode = _currencyCodeCtrl.text.trim().isEmpty
        ? 'USD'
        : _currencyCodeCtrl.text.trim().toUpperCase();
    final previewSymbol = _currencySymbolCtrl.text.trim();

    String previewFor(String mode) {
      const amount = '200.00';
      final hasSymbol = previewSymbol.isNotEmpty;
      final hasCode = previewCode.isNotEmpty;
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

    const options = [
      ('code', 'Code'),
      ('symbol', 'Symbol'),
      ('both', 'Both'),
    ];

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
            children: options.map((opt) {
              final (mode, label) = opt;
              final selected = _currencyDisplayMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currencyDisplayMode = mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: selected ? _accent : Colors.transparent,
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
                          previewFor(mode),
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = kb + 32 + MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      builder: (context, sc) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Sheet title row ─────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isEditing ? 'Edit Receipt' : 'Create Receipt',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (_isEditing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D2A0F)
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: _accent.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Editing',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Draft label ──────────────────────────────────
                      ReceiptField(
                        ctrl: _nameCtrl,
                        label: 'Draft Label',
                        accent: _accent,
                        icon: Icons.label_rounded,
                        max: 60,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_nameCtrl.text.length, 60),
                      const SizedBox(height: 20),

                      // ── Context banner ───────────────────────────────
                      _contextBanner(isDark),
                      const SizedBox(height: 20),

                      // ── Receipt number ────────────────────────────────
                      receiptSectionHeader(context, 'Receipt Details', _accent,
                          icon: Icons.receipt_rounded),
                      ReceiptField(
                        ctrl: _receiptNumberCtrl,
                        label: 'Receipt Number',
                        accent: _accent,
                        icon: Icons.tag_rounded,
                        max: _receiptNumberMax,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_receiptNumberCtrl.text.length, _receiptNumberMax),
                      const SizedBox(height: 12),

                      ReceiptDateField(
                        label: 'Payment Date',
                        value: _paymentDate,
                        accent: _accent,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 20),

                      // ── Currency ─────────────────────────────────────
                      receiptSectionHeader(context, 'Currency', _accent,
                          icon: Icons.attach_money_rounded),
                      _currencyDisplayModeSelector(),
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

                      // ── Client (if none selected on the Customer step) ─
                      if (widget.selectedClient == null) ...[
                        receiptSectionHeader(context, 'Client Details', _accent,
                            icon: Icons.person_rounded),
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

                      // ── Payment Method ────────────────────────────────
                      receiptSectionHeader(context, 'Payment Method', _accent,
                          icon: Icons.payments_rounded),
                      ReceiptPaymentMethodPicker(
                        selected: _paymentMethod,
                        accent: _accent,
                        onChanged: (m) => setState(() => _paymentMethod = m),
                      ),
                      const SizedBox(height: 20),

                      // ── Saved item sets (quick-add) — Receipt-only
                      // library, separate from Invoice's/Quote's ───────
                      ReceiptSavedItemSets(
                        getCurrentItems: _getCurrentItemsSnapshot,
                        onQuickAdd: _quickAddItems,
                        currencySymbol: _currencyPrefix,
                      ),
                      const SizedBox(height: 20),

                      // ── Line items ───────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: receiptSectionHeader(
                                context, 'Line Items', _accent,
                                icon: Icons.list_alt_rounded),
                          ),
                          GestureDetector(
                            onTap: _addItem,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D2A0F)
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.add_rounded,
                                      size: 16, color: _accent),
                                  SizedBox(width: 4),
                                  Text('Add Item',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _accent,
                                          fontWeight: FontWeight.w700)),
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
                          currencySymbol: _currencyPrefix,
                          canRemove: _items.length > 1,
                          accent: _accent,
                          onRemove: () => _removeItem(index),
                          onChanged: () => setState(() {}),
                        );
                      }),
                      const SizedBox(height: 12),

                      // ── Tax / Discount ───────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: ReceiptField(
                              ctrl: _taxCtrl,
                              label: 'Tax %',
                              accent: _accent,
                              icon: Icons.percent_rounded,
                              max: 5,
                              keyboard: const TextInputType.numberWithOptions(
                                  decimal: true),
                              extraFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              onChanged: (v) => setState(() {
                                _taxRate = double.tryParse(v) ?? 0.0;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ReceiptField(
                              ctrl: _discountCtrl,
                              label: 'Discount %',
                              accent: _accent,
                              icon: Icons.local_offer_rounded,
                              max: 5,
                              keyboard: const TextInputType.numberWithOptions(
                                  decimal: true),
                              extraFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              onChanged: (v) => setState(() {
                                _discountRate = double.tryParse(v) ?? 0.0;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Totals card ──────────────────────────────────
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

                      // ── Notes ────────────────────────────────────────
                      receiptSectionHeader(context, 'Additional Info', _accent,
                          icon: Icons.notes_rounded),
                      ReceiptField(
                        ctrl: _notesCtrl,
                        label: 'Notes',
                        accent: _accent,
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                        max: 500,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_notesCtrl.text.length, 500),
                      const SizedBox(height: 28),

                      // ── Save button ──────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            _isEditing ? 'Save Changes' : 'Save Receipt',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
