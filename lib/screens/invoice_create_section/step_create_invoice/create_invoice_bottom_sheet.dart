// lib/screens/invoice_create_section/step_create_invoice/create_invoice_bottom_sheet.dart
//
// NEW FILE — INVOICE LIBRARY RESTRUCTURE PASS: this holds the entire
// invoice-editing form that used to be step_create_invoice.dart's whole
// body (invoice number, dates, currency, customer override, Saved Item
// Sets panel, line items, tax/discount, totals, notes). It's now shown
// as a bottom sheet (DraggableScrollableSheet, matching the pattern
// already used by step_customers.dart's _CustomerSheet and
// step_templates.dart's _TemplateSheet) from the new library screen in
// step_create_invoice.dart, instead of being the step's only content.
//
// Behaviorally this is almost identical to the pre-restructure
// _StepCreateInvoiceState: same controllers, same items/dates/currency/
// tax/discount state, same validation rules, same defensive re-sync of
// controller text into _items before building the final InvoiceData
// (see _save() below, mirroring the old _continue()). The differences:
//   - It no longer talks to InvoiceProvider directly. Instead it builds
//     a plain InvoiceData and hands it back wrapped in a
//     SavedInvoiceDraft via widget.onSaved() — the parent library screen
//     (step_create_invoice.dart) owns persisting the draft library and
//     later syncing the *selected* draft into InvoiceProvider when
//     "Continue to Customise" is tapped.
//   - It gained a "Draft Label" field at the top (optional) so a draft
//     can be given a name for the library card independent of whatever
//     customer name or invoice number is typed below — see
//     SavedInvoiceDraft.displayName's fallback chain in invoice_data.dart.
//   - There's no Back/Continue bar (CreateInvoiceBottomBar) — a bottom
//     sheet has its own single Save button instead, matching
//     _CustomerSheet's/_TemplateSheet's "Save Customer"/"Save Template"
//     pattern exactly.
//
// SavedInvoiceDraft/InvoiceData/InvoiceItem/Customer/InvoiceTemplate are
// all pulled in through the single invoice_models.dart import below —
// same as the original step_create_invoice.dart did for InvoiceData/
// InvoiceItem, on the assumption invoice_models.dart re-exports
// invoice_data.dart in full (confirmed by the original file constructing
// `InvoiceData(...)` directly with only that one import). If
// SavedInvoiceDraft isn't visible through that import once this compiles,
// invoice_models.dart's export list needs `SavedInvoiceDraft` added
// alongside wherever SavedLineItemSet already is.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../models/invoice_models.dart';
import 'create_invoice_item_widgets.dart';
import 'create_invoice_form_widgets.dart';
import 'create_invoice_saved_items_widgets.dart';

// =============================================================================
// CreateInvoiceBottomSheet
// =============================================================================

class CreateInvoiceBottomSheet extends StatefulWidget {
  final Customer? selectedCustomer;
  final InvoiceTemplate? selectedTemplate;

  /// The draft being edited, or null when creating a brand new one.
  final SavedInvoiceDraft? existing;

  final void Function(SavedInvoiceDraft draft) onSaved;

  const CreateInvoiceBottomSheet({
    super.key,
    this.selectedCustomer,
    this.selectedTemplate,
    this.existing,
    required this.onSaved,
  });

  @override
  State<CreateInvoiceBottomSheet> createState() =>
      _CreateInvoiceBottomSheetState();
}

class _CreateInvoiceBottomSheetState extends State<CreateInvoiceBottomSheet> {
  static const _accent = Color(0xFF2196F3);

  // INVOICE NUMBER LENGTH FIX (carried over): single source of truth for
  // the field's max character cap — see the original step file's note.
  static const int _invoiceNumberMax = 18;

  // Draft label — shown on the library card. Optional; falls back to
  // customer name / invoice number / "Untitled Draft" per
  // SavedInvoiceDraft.displayName.
  late TextEditingController _nameCtrl;

  // Controllers
  late TextEditingController _invoiceNumberCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;

  // Customer override (if no customer passed from step 1)
  late TextEditingController _custNameCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;
  late TextEditingController _custAddressCtrl;

  // Items
  late List<InvoiceItem> _items;
  final List<TextEditingController> _descCtrl = [];
  final List<TextEditingController> _qtyCtrl = [];
  final List<TextEditingController> _priceCtrl = [];

  // Dates
  late DateTime _invoiceDate;
  late DateTime _dueDate;

  // Currency — free-text code + symbol + Code/Symbol/Both display mode.
  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code'; // 'code' | 'symbol' | 'both'

  // Tax / discount rates -- source of truth for totals math (see
  // OVERFLOW FIX note in the original step file, carried over unchanged).
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
  double get _total => _subtotal + _taxAmount - _discountAmount;

  @override
  void initState() {
    super.initState();

    final existingData = widget.existing?.data;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tsShort = ts
        .toString()
        .substring((ts.toString().length - 6).clamp(0, ts.toString().length));

    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');

    _invoiceNumberCtrl = TextEditingController(
      text: (existingData != null && existingData.invoiceNumber.isNotEmpty)
          ? existingData.invoiceNumber
          : 'INV-$tsShort',
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

    // Customer override fields — the customer picked in step 1 wins;
    // otherwise fall back to whatever's stored on the draft being edited.
    _custNameCtrl = TextEditingController(
      text: widget.selectedCustomer?.name ?? existingData?.clientName ?? '',
    );
    _custEmailCtrl = TextEditingController(
      text: widget.selectedCustomer?.email ?? existingData?.clientEmail ?? '',
    );
    _custPhoneCtrl = TextEditingController(
      text: widget.selectedCustomer?.phone ?? existingData?.clientPhone ?? '',
    );
    _custAddressCtrl = TextEditingController(
      text:
          widget.selectedCustomer?.address ?? existingData?.clientAddress ?? '',
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

    _invoiceDate = (existingData != null && existingData.issueDate.isNotEmpty)
        ? (DateFormat(_dateFmt).tryParse(existingData.issueDate) ??
            DateTime.now())
        : DateTime.now();
    _dueDate = (existingData != null && existingData.dueDate.isNotEmpty)
        ? (DateFormat(_dateFmt).tryParse(existingData.dueDate) ??
            DateTime.now().add(const Duration(days: 30)))
        : DateTime.now().add(const Duration(days: 30));

    // Line items — restore from the draft if present, else start with one
    // blank item.
    _items = (existingData != null && existingData.lineItems.isNotEmpty)
        ? existingData.lineItems.map((i) => i.copyWith()).toList()
        : [InvoiceItem()];
    for (final item in _items) {
      _descCtrl.add(TextEditingController(text: item.description));
      _qtyCtrl.add(TextEditingController(
        text: item.quantity == 1.0 ? '1' : '${item.quantity}',
      ));
      _priceCtrl.add(TextEditingController(
        text: item.unitPrice == 0.0 ? '0' : '${item.unitPrice}',
      ));
    }

    // Rebuild on changes for totals / live currency preview / counters.
    for (final c in [
      _nameCtrl,
      _invoiceNumberCtrl,
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
      _nameCtrl, _invoiceNumberCtrl, _notesCtrl, _taxCtrl,
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
      _items.add(InvoiceItem());
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
  // Saved item sets — quick add (unchanged from the original step file's
  // LINE ITEM CONTAINERS PASS — see step_create_invoice.dart's old
  // top-of-file note for the full rationale, carried over verbatim).
  // ---------------------------------------------------------------------------
  List<InvoiceItem> _getCurrentItemsSnapshot() {
    for (int i = 0; i < _items.length; i++) {
      _items[i]
        ..description = _descCtrl[i].text.trim()
        ..quantity = double.tryParse(_qtyCtrl[i].text) ?? 1
        ..unitPrice = double.tryParse(_priceCtrl[i].text) ?? 0;
    }
    return _items.map((i) => i.copyWith()).toList();
  }

  void _quickAddItems(List<InvoiceItem> items) {
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
  // Validation — identical rules to the original step file.
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
    if (_invoiceNumberCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter an invoice number.');
      return false;
    }

    if (widget.selectedCustomer == null && _custNameCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a customer name.');
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

    if (_taxRate < 0 || _taxRate > 100) {
      _showValidationError('Tax rate must be between 0 and 100%.');
      return false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Save — validates, flushes controller text into _items (same defensive
  // re-sync the old _continue() did), builds an InvoiceData, wraps it in a
  // SavedInvoiceDraft (preserving id/createdAt when editing), hands it to
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

    final data = InvoiceData(
      clientName: _custNameCtrl.text.trim(),
      clientEmail: _custEmailCtrl.text.trim(),
      clientPhone: _custPhoneCtrl.text.trim(),
      clientAddress: _custAddressCtrl.text.trim(),
      invoiceNumber: _invoiceNumberCtrl.text.trim(),
      issueDate: DateFormat(_dateFmt).format(_invoiceDate),
      dueDate: DateFormat(_dateFmt).format(_dueDate),
      notes: _notesCtrl.text.trim(),
      currency: _currencyCodeCtrl.text.trim().isEmpty
          ? 'USD'
          : _currencyCodeCtrl.text.trim().toUpperCase(),
      currencySymbol: _currencySymbolCtrl.text.trim(),
      currencyDisplayMode: _currencyDisplayMode,
      lineItems: List<InvoiceItem>.from(_items),
      taxRate: _taxRate,
      discountRate: _discountRate,
    );

    final now = DateTime.now();
    final draft = SavedInvoiceDraft(
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
  Future<void> _pickDate(bool isDueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _dueDate : _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Section helpers (mirrors the original step file's helpers exactly)
  // ---------------------------------------------------------------------------
  Widget _sectionHeader(String label, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          if (icon != null) ...[
            Icon(icon, size: 16, color: _accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _rangeWarning(double raw, double clamped) {
    if (raw == clamped) return const SizedBox.shrink();
    final clampedLabel = clamped % 1 == 0
        ? clamped.toInt().toString()
        : clamped.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 2),
      child: Text(
        'Using $clampedLabel% for totals (must be 0-100)',
        style: const TextStyle(fontSize: 10.5, color: Color(0xFFF44336)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat(_dateFmt);
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
                              _isEditing ? 'Edit Invoice' : 'Create Invoice',
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
                                    ? const Color(0xFF0D1B2E)
                                    : const Color(0xFFE3F2FD),
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
                      CreateInvoiceField(
                        ctrl: _nameCtrl,
                        label: 'Draft Label (Optional)',
                        hint: 'e.g. Acme Corp — March retainer',
                        icon: Icons.label_rounded,
                        max: 60,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_nameCtrl.text.length, 60),
                      const SizedBox(height: 20),

                      // ── Context banner (template / customer selection) ─
                      CreateInvoiceContextBanner(
                        template: widget.selectedTemplate,
                        customer: widget.selectedCustomer,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // ── Invoice number ───────────────────────────────
                      _sectionHeader('Invoice Details',
                          icon: Icons.receipt_long_rounded),
                      CreateInvoiceField(
                        ctrl: _invoiceNumberCtrl,
                        label: 'Invoice Number',
                        hint: 'e.g. INV-001',
                        icon: Icons.tag_rounded,
                        max: _invoiceNumberMax,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_invoiceNumberCtrl.text.length, _invoiceNumberMax),
                      const SizedBox(height: 12),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: CreateInvoiceDateField(
                              label: 'Invoice Date',
                              value: dateFormat.format(_invoiceDate),
                              onTap: () => _pickDate(false),
                              accent: _accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CreateInvoiceDateField(
                              label: 'Due Date',
                              value: dateFormat.format(_dueDate),
                              onTap: () => _pickDate(true),
                              accent: _accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Currency ─────────────────────────────────────
                      _sectionHeader('Currency',
                          icon: Icons.attach_money_rounded),
                      CreateInvoiceField(
                        ctrl: _currencyCodeCtrl,
                        label: 'Currency Code',
                        hint: 'e.g. USD',
                        icon: Icons.attach_money_rounded,
                        max: 6,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_currencyCodeCtrl.text.length, 6),
                      const SizedBox(height: 12),

                      CreateInvoiceCurrencyDisplayModeSelector(
                        value: _currencyDisplayMode,
                        accent: _accent,
                        onChanged: (mode) =>
                            setState(() => _currencyDisplayMode = mode),
                        previewCode: _currencyCodeCtrl.text.trim().isEmpty
                            ? 'USD'
                            : _currencyCodeCtrl.text.trim().toUpperCase(),
                        previewSymbol: _currencySymbolCtrl.text.trim(),
                      ),
                      if (_currencyDisplayMode != 'code') ...[
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _currencySymbolCtrl,
                          label: 'Currency Symbol',
                          hint: 'e.g. \$, €, kr',
                          icon: Icons.currency_exchange_rounded,
                          max: 6,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_currencySymbolCtrl.text.length, 6),
                      ],
                      const SizedBox(height: 20),

                      // ── Customer (if none selected in step 1) ────────
                      if (widget.selectedCustomer == null) ...[
                        _sectionHeader('Customer Details',
                            icon: Icons.person_rounded),
                        CreateInvoiceField(
                          ctrl: _custNameCtrl,
                          label: 'Customer Name',
                          hint: 'e.g. Acme Corp',
                          icon: Icons.person_rounded,
                          max: 100,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custEmailCtrl,
                          label: 'Customer Email',
                          hint: 'e.g. billing@acme.com',
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custPhoneCtrl,
                          label: 'Customer Phone',
                          hint: 'e.g. +1 555 000 1234',
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custAddressCtrl,
                          label: 'Customer Address',
                          hint: 'e.g. 123 Main St, NYC',
                          icon: Icons.location_on_rounded,
                          max: 200,
                          maxLines: 2,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Saved item sets (quick-add) ──────────────────
                      CreateInvoiceSavedItemSets(
                        getCurrentItems: _getCurrentItemsSnapshot,
                        onQuickAdd: _quickAddItems,
                        currencySymbol: _currencyPrefix,
                      ),
                      const SizedBox(height: 20),

                      // ── Line items ───────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _sectionHeader('Line Items',
                                icon: Icons.list_alt_rounded),
                          ),
                          GestureDetector(
                            onTap: _addItem,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D1B2E)
                                    : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded,
                                      size: 16, color: _accent),
                                  const SizedBox(width: 4),
                                  const Text('Add Item',
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
                        return CreateInvoiceItemCard(
                          index: index,
                          item: _items[index],
                          descCtrl: _descCtrl[index],
                          qtyCtrl: _qtyCtrl[index],
                          priceCtrl: _priceCtrl[index],
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CreateInvoiceField(
                                  ctrl: _taxCtrl,
                                  label: 'Tax %',
                                  hint: 'e.g. 10',
                                  icon: Icons.percent_rounded,
                                  max: 5,
                                  keyboard: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  extraFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}')),
                                  ],
                                  accent: _accent,
                                  onChanged: (v) => setState(() {
                                    final parsed = double.tryParse(v) ?? 0.0;
                                    _taxRate = parsed.clamp(0.0, 100.0);
                                  }),
                                ),
                                _rangeWarning(
                                    double.tryParse(_taxCtrl.text) ?? 0.0,
                                    _taxRate),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CreateInvoiceField(
                                  ctrl: _discountCtrl,
                                  label: 'Discount %',
                                  hint: 'e.g. 5',
                                  icon: Icons.local_offer_rounded,
                                  max: 5,
                                  keyboard: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  extraFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}')),
                                  ],
                                  accent: _accent,
                                  onChanged: (v) => setState(() {
                                    final parsed = double.tryParse(v) ?? 0.0;
                                    _discountRate = parsed.clamp(0.0, 100.0);
                                  }),
                                ),
                                _rangeWarning(
                                    double.tryParse(_discountCtrl.text) ?? 0.0,
                                    _discountRate),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Totals card ──────────────────────────────────
                      CreateInvoiceTotalsCard(
                        subtotal: _subtotal,
                        taxAmount: _taxAmount,
                        discountAmount: _discountAmount,
                        total: _total,
                        taxRate: _taxRate,
                        discountRate: _discountRate,
                        currencySymbol: _currencyPrefix,
                        isDark: isDark,
                        accent: _accent,
                      ),
                      const SizedBox(height: 20),

                      // ── Notes ────────────────────────────────────────
                      _sectionHeader('Additional Info',
                          icon: Icons.notes_rounded),
                      CreateInvoiceField(
                        ctrl: _notesCtrl,
                        label: 'Notes / Payment Terms',
                        hint: 'e.g. Payment due within 30 days...',
                        icon: Icons.note_rounded,
                        max: 500,
                        maxLines: 3,
                        accent: _accent,
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
                            _isEditing ? 'Save Changes' : 'Save Invoice',
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
