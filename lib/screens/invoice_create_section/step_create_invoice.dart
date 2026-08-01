// lib/screens/invoice_create_section/step_create_invoice.dart
//
// REWRITE (this pass): This screen used to build its own local `Invoice`
// model (from client_info.dart via invoice_models.dart aliases) into a
// `buildInvoice()` method that was never actually called by anything —
// meaning everything typed here (invoice number, customer, line items,
// tax, notes) never reached InvoiceProvider, which is what
// SavedInvoice / InvoicePdfService / InvoiceExportService all actually use.
//
// Now this step reads/writes InvoiceProvider directly, the same pattern
// quote_editor_screen.dart and create_receipt_screen.dart already use:
//   - initState() seeds local controllers from provider.invoiceData (so
//     going back to this step from Customise doesn't lose what was typed),
//     falling back to widget.selectedCustomer / widget.selectedTemplate for
//     first-time entry.
//   - _syncToProvider() builds a full InvoiceData and calls
//     provider.updateInvoiceData(data) — called from _continue() right
//     before widget.onNext(), so by the time Customise reads
//     provider.invoiceData for its live preview, this step's data is in it.
//
// DROPPED (this pass): Barcode Number and Thank You Message fields are
// removed. Neither exists on InvoiceData, and neither was ever read by
// InvoicePdfService or InvoiceExportService — the old buildInvoice() that
// used them was unused, so this data was already going nowhere. Rather
// than adding two fields to InvoiceData that nothing downstream consumes,
// they're cut here. Flag it if you want them added as real, working
// fields — that's a small separate change to InvoiceData + the PDF/export
// services.
//
// Color scheme here and on the Customise step are the same field
// (InvoiceData.colorScheme) — this step seeds/sends it, Customise's own
// picker can then further adjust it via provider.updateColorScheme()
// without conflict, since that call preserves every other field via
// copyWith().

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/invoice_models.dart';
import '../../models/invoice_color_ext.dart';
import '../../providers/invoice_provider.dart';
import 'invoice_edit_widgets.dart';

// =============================================================================
// StepCreateInvoice
// =============================================================================

class StepCreateInvoice extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Customer? selectedCustomer;
  final InvoiceTemplate? selectedTemplate;

  /// Visual PDF layout chosen in InvoiceTemplateChooserScreen (e.g. 1 =
  /// Executive). Null/unrecognized falls back to the only built layout.
  final int? layoutTemplateId;

  const StepCreateInvoice({
    super.key,
    required this.onBack,
    required this.onNext,
    this.selectedCustomer,
    this.selectedTemplate,
    this.layoutTemplateId,
  });

  @override
  State<StepCreateInvoice> createState() => _StepCreateInvoiceState();
}

class _StepCreateInvoiceState extends State<StepCreateInvoice> {
  static const _accent = Color(0xFF2196F3);

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

  // Color scheme — same field as InvoiceData.colorScheme, seeded from
  // whatever's already on the provider (so Customise's picker and this
  // step's picker never fight over it).
  late InvoiceColorScheme _colorScheme;

  // Currency (override from template if present)
  late String _currency;

  bool _showColorPanel = true;

  static const _dateFmt = 'd MMM yyyy';

  String get _currencySymbol => CurrencyHelper.getSymbol(_currency);

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.total);
  double get _taxAmount =>
      _subtotal * (double.tryParse(_taxCtrl.text) ?? 0) / 100;
  double get _discountAmount =>
      _subtotal * (double.tryParse(_discountCtrl.text) ?? 0) / 100;
  double get _total => _subtotal + _taxAmount - _discountAmount;

  @override
  void initState() {
    super.initState();

    // Seed everything from whatever's already on InvoiceProvider first —
    // this is what makes going Customise -> Back -> this step not lose
    // data. Falls back to widget.selectedCustomer / widget.selectedTemplate
    // / sensible defaults for first-time entry.
    final existing = context.read<InvoiceProvider>().invoiceData;
    final ts = DateTime.now().millisecondsSinceEpoch;

    _invoiceNumberCtrl = TextEditingController(
      text: existing.invoiceNumber.isNotEmpty
          ? existing.invoiceNumber
          : 'INV-$ts',
    );
    _notesCtrl = TextEditingController(text: existing.notes);
    _taxCtrl = TextEditingController(
      text: existing.taxRate == 0 ? '0' : '${existing.taxRate}',
    );
    _discountCtrl = TextEditingController(
      text: existing.discountRate == 0 ? '0' : '${existing.discountRate}',
    );

    // Customer override fields — prefer the customer picked in step 1;
    // otherwise fall back to whatever's already stored on the provider
    // (covers returning to this step after typing manually).
    _custNameCtrl = TextEditingController(
      text: widget.selectedCustomer?.name ?? existing.clientName,
    );
    _custEmailCtrl = TextEditingController(
      text: widget.selectedCustomer?.email ?? existing.clientEmail,
    );
    _custPhoneCtrl = TextEditingController(
      text: widget.selectedCustomer?.phone ?? existing.clientPhone,
    );
    _custAddressCtrl = TextEditingController(
      text: widget.selectedCustomer?.address ?? existing.clientAddress,
    );

    // Currency: template selection wins on first entry; otherwise whatever
    // was already on the provider.
    _currency = widget.selectedTemplate?.currency ??
        (existing.currency.isNotEmpty ? existing.currency : 'USD');

    // Dates — parse back out of the stored display strings if present.
    _invoiceDate = existing.issueDate.isNotEmpty
        ? (DateFormat(_dateFmt).tryParse(existing.issueDate) ?? DateTime.now())
        : DateTime.now();
    _dueDate = existing.dueDate.isNotEmpty
        ? (DateFormat(_dateFmt).tryParse(existing.dueDate) ??
            DateTime.now().add(const Duration(days: 30)))
        : DateTime.now().add(const Duration(days: 30));

    _colorScheme = existing.colorScheme;

    // Line items — restore from provider if present, else start with one
    // blank item.
    _items = existing.lineItems.isNotEmpty
        ? existing.lineItems.map((i) => i.copyWith()).toList()
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

    // Rebuild on changes for totals
    for (final c in [_taxCtrl, _discountCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _invoiceNumberCtrl, _notesCtrl, _taxCtrl,
      _discountCtrl, _custNameCtrl, _custEmailCtrl,
      _custPhoneCtrl, _custAddressCtrl,
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
  // Sync to InvoiceProvider
  //
  // Builds a full InvoiceData from everything on this step and writes it
  // via provider.updateInvoiceData(). paymentStatus and fontFamily aren't
  // edited on this step, so they're carried over from whatever's currently
  // on the provider rather than reset to defaults.
  // ---------------------------------------------------------------------------
  void _syncToProvider() {
    final provider = context.read<InvoiceProvider>();
    final current = provider.invoiceData;
    final businessInfo = widget.selectedTemplate?.businessInfo;

    final data = InvoiceData(
      businessName: businessInfo?.name ?? current.businessName,
      businessEmail: businessInfo?.email ?? current.businessEmail,
      businessPhone: businessInfo?.phone ?? current.businessPhone,
      businessAddress: businessInfo?.address ?? current.businessAddress,
      businessLogoPath: businessInfo?.logoPath ?? current.businessLogoPath,
      clientName: _custNameCtrl.text.trim(),
      clientEmail: _custEmailCtrl.text.trim(),
      clientPhone: _custPhoneCtrl.text.trim(),
      clientAddress: _custAddressCtrl.text.trim(),
      invoiceNumber: _invoiceNumberCtrl.text.trim(),
      issueDate: DateFormat(_dateFmt).format(_invoiceDate),
      dueDate: DateFormat(_dateFmt).format(_dueDate),
      notes: _notesCtrl.text.trim(),
      currency: _currency,
      lineItems: List<InvoiceItem>.from(_items),
      taxRate: double.tryParse(_taxCtrl.text) ?? 0,
      discountRate: double.tryParse(_discountCtrl.text) ?? 0,
      paymentStatus: current.paymentStatus,
      fontFamily: current.fontFamily,
      colorScheme: _colorScheme,
    );

    provider.updateInvoiceData(data);
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

  // ---------------------------------------------------------------------------
  // Continue — validates the items on this step, syncs everything into
  // InvoiceProvider, then hands off to the parent flow (the customise
  // step) via widget.onNext().
  // ---------------------------------------------------------------------------
  void _continue() {
    if (!_validateItems()) return;
    // Push current controller text into _items before syncing, since
    // description/qty/price are only mirrored into _items via onChanged
    // callbacks below — this guards against any missed callback.
    for (int i = 0; i < _items.length; i++) {
      _items[i]
        ..description = _descCtrl[i].text
        ..quantity = double.tryParse(_qtyCtrl[i].text) ?? 1
        ..unitPrice = double.tryParse(_priceCtrl[i].text) ?? 0;
    }
    _syncToProvider();
    widget.onNext();
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
  // Section helpers
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
                : colorScheme.onSurface.withOpacity(0.35),
          ),
        ),
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

    return Column(
      children: [
        // ── Scrollable body ─────────────────────────────────────────────────
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Page title ───────────────────────────────────────
                      Text(
                        'Create Invoice',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill in the details to generate your invoice',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Context banner (template / customer selection) ────
                      _ContextBanner(
                        template: widget.selectedTemplate,
                        customer: widget.selectedCustomer,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // ── Invoice number ───────────────────────────────────
                      _sectionHeader('Invoice Details',
                          icon: Icons.receipt_long_rounded),
                      _InvoiceField(
                        ctrl: _invoiceNumberCtrl,
                        label: 'Invoice Number',
                        hint: 'e.g. INV-001',
                        icon: Icons.tag_rounded,
                        max: 30,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_invoiceNumberCtrl.text.length, 30),
                      const SizedBox(height: 12),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Invoice Date',
                              value: dateFormat.format(_invoiceDate),
                              onTap: () => _pickDate(false),
                              accent: _accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              label: 'Due Date',
                              value: dateFormat.format(_dueDate),
                              onTap: () => _pickDate(true),
                              accent: _accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Currency ─────────────────────────────────────────
                      _sectionHeader('Currency',
                          icon: Icons.attach_money_rounded),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select Currency',
                          labelStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.attach_money_rounded,
                              size: 20,
                              color: colorScheme.onSurface.withOpacity(0.45)),
                          filled: true,
                          fillColor: isDark
                              ? colorScheme.surfaceContainerHighest
                              : const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: colorScheme.outline)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: colorScheme.outline)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: _accent, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                        items: CurrencyHelper.getAllCurrencies()
                            .map((c) => DropdownMenuItem<String>(
                                  value: c['code'],
                                  child: Text(
                                    '${c['symbol']}  ${c['code']} – ${c['name']}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurface),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Customer (if none selected in step 1) ───────────
                      if (widget.selectedCustomer == null) ...[
                        _sectionHeader('Customer Details',
                            icon: Icons.person_rounded),
                        _InvoiceField(
                          ctrl: _custNameCtrl,
                          label: 'Customer Name',
                          hint: 'e.g. Acme Corp',
                          icon: Icons.person_rounded,
                          max: 100,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _InvoiceField(
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
                        _InvoiceField(
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
                        _InvoiceField(
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

                      // ── Line items ───────────────────────────────────────
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
                        return _ItemCard(
                          index: index,
                          item: _items[index],
                          descCtrl: _descCtrl[index],
                          qtyCtrl: _qtyCtrl[index],
                          priceCtrl: _priceCtrl[index],
                          currencySymbol: _currencySymbol,
                          canRemove: _items.length > 1,
                          accent: _accent,
                          onRemove: () => _removeItem(index),
                          onChanged: () => setState(() {}),
                        );
                      }),
                      const SizedBox(height: 12),

                      // ── Tax / Discount ───────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _InvoiceField(
                              ctrl: _taxCtrl,
                              label: 'Tax %',
                              hint: 'e.g. 10',
                              icon: Icons.percent_rounded,
                              max: 5,
                              keyboard: const TextInputType
                                  .numberWithOptions(decimal: true),
                              accent: _accent,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InvoiceField(
                              ctrl: _discountCtrl,
                              label: 'Discount %',
                              hint: 'e.g. 5',
                              icon: Icons.local_offer_rounded,
                              max: 5,
                              keyboard: const TextInputType
                                  .numberWithOptions(decimal: true),
                              accent: _accent,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Totals card ──────────────────────────────────────
                      _TotalsCard(
                        subtotal: _subtotal,
                        taxAmount: _taxAmount,
                        discountAmount: _discountAmount,
                        total: _total,
                        taxRate: double.tryParse(_taxCtrl.text) ?? 0,
                        discountRate:
                            double.tryParse(_discountCtrl.text) ?? 0,
                        currencySymbol: _currencySymbol,
                        isDark: isDark,
                        accent: _accent,
                      ),
                      const SizedBox(height: 20),

                      // ── Notes ────────────────────────────────────────────
                      _sectionHeader('Additional Info',
                          icon: Icons.notes_rounded),
                      _InvoiceField(
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
                      const SizedBox(height: 20),

                      // ── Color scheme ─────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _sectionHeader('Color Scheme',
                                icon: Icons.palette_rounded),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                () => _showColorPanel = !_showColorPanel),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D1B2E)
                                    : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _showColorPanel ? 'Hide' : 'Show',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _accent,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    _showColorPanel
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: _accent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showColorPanel)
                        _ColorSchemePicker(
                          selected: _colorScheme,
                          onChanged: (s) =>
                              setState(() => _colorScheme = s),
                        ),
                      const SizedBox(height: 20),

                      // ── Done card ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A1A2E),
                              Color(0xFF0F3460)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF4CAF50), size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Invoice details ready!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap Continue below to customise the look.',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.6),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom action bar ────────────────────────────────────────────────
        _InvoiceBottomBar(
          onBack: widget.onBack,
          onContinue: _continue,
        ),
      ],
    );
  }
}

// =============================================================================
// Context Banner (shows selected template / customer from previous steps)
// =============================================================================

class _ContextBanner extends StatelessWidget {
  final InvoiceTemplate? template;
  final Customer? customer;
  final bool isDark;

  const _ContextBanner({
    required this.template,
    required this.customer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTemplate = template != null;
    final hasCustomer = customer != null;

    if (!hasTemplate && !hasCustomer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2200) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark
                  ? const Color(0xFFFFE082).withOpacity(0.4)
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
          _BannerChip(
            icon: Icons.description_rounded,
            color: const Color(0xFF1565C0),
            label: 'Template: ${template!.name}',
            sub: (template!.businessInfo.name.isNotEmpty)
                ? template!.businessInfo.name
                : null,
            isDark: isDark,
          ),
        if (hasTemplate && hasCustomer) const SizedBox(height: 8),
        if (hasCustomer)
          _BannerChip(
            icon: Icons.person_rounded,
            color: const Color(0xFF2E7D32),
            label: 'Customer: ${customer!.name}',
            sub: customer!.email.isNotEmpty ? customer!.email : null,
            isDark: isDark,
          ),
      ],
    );
  }
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? sub;
  final bool isDark;

  const _BannerChip({
    required this.icon,
    required this.color,
    required this.label,
    this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
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
                    sub!,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.7),
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
}

// =============================================================================
// Item card
// =============================================================================

class _ItemCard extends StatelessWidget {
  final int index;
  final InvoiceItem item;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final String currencySymbol;
  final bool canRemove;
  final Color accent;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ItemCard({
    required this.index,
    required this.item,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.currencySymbol,
    required this.canRemove,
    required this.accent,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colorScheme.outline.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: accent),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (canRemove)
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF5350).withOpacity(0.12)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFFEF5350), size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            TextFormField(
              controller: descCtrl,
              style: TextStyle(color: colorScheme.onSurface),
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
              onChanged: (v) {
                item.description = v;
                onChanged();
              },
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6)),
                hintText: 'e.g. Consulting Services',
                hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.35),
                    fontSize: 13),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF9F9F9),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: accent, width: 1.5)),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),

            // Qty / Price / Total
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: qtyCtrl,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (v) {
                      item.quantity = double.tryParse(v) ?? 1;
                      onChanged();
                    },
                    decoration: _smallDeco(
                        context, 'Qty', colorScheme, isDark, accent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: priceCtrl,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                      LengthLimitingTextInputFormatter(12),
                    ],
                    onChanged: (v) {
                      item.unitPrice = double.tryParse(v) ?? 0;
                      onChanged();
                    },
                    decoration: _smallDeco(context, 'Price ($currencySymbol)',
                        colorScheme, isDark, accent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(isDark ? 0.12 : 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: accent.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    colorScheme.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 2),
                        Text(
                          '$currencySymbol${item.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _smallDeco(BuildContext context, String label,
      ColorScheme cs, bool isDark, Color accent) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 12),
      filled: true,
      fillColor:
          isDark ? cs.surfaceContainerHighest : const Color(0xFFF9F9F9),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5)),
      counterText: '',
    );
  }
}

// =============================================================================
// Totals card
// =============================================================================

class _TotalsCard extends StatelessWidget {
  final double subtotal, taxAmount, discountAmount, total;
  final double taxRate, discountRate;
  final String currencySymbol;
  final bool isDark;
  final Color accent;

  const _TotalsCard({
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.taxRate,
    required this.discountRate,
    required this.currencySymbol,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2E) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _row('Subtotal',
              '$currencySymbol${subtotal.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row('Tax (${taxRate.toStringAsFixed(taxRate % 1 == 0 ? 0 : 1)}%)',
              '+$currencySymbol${taxAmount.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row(
              'Discount (${discountRate.toStringAsFixed(discountRate % 1 == 0 ? 0 : 1)}%)',
              '-$currencySymbol${discountAmount.toStringAsFixed(2)}',
              colorScheme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                color: accent.withOpacity(0.3), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$currencySymbol${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, color: cs.onSurface.withOpacity(0.7))),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
      ],
    );
  }
}

// =============================================================================
// Color scheme picker grid
// =============================================================================

class _ColorSchemePicker extends StatelessWidget {
  final InvoiceColorScheme selected;
  final ValueChanged<InvoiceColorScheme> onChanged;

  const _ColorSchemePicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: InvoiceColor.values.length,
      itemBuilder: (_, i) {
        final scheme = InvoiceColor.values[i];
        final isSelected = selected.displayName == scheme.displayName;
        return GestureDetector(
          onTap: () => onChanged(scheme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(scheme.primaryColor),
                          Color(scheme.accentColor),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(9),
                        topRight: Radius.circular(9),
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 22))
                        : null,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(9),
                      bottomRight: Radius.circular(9),
                    ),
                  ),
                  child: Text(
                    scheme.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF2196F3)
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Invoice field – reusable text field
// =============================================================================

class _InvoiceField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData? icon;
  final int? max;
  final int maxLines;
  final bool required;
  final TextInputType? keyboard;
  final Color accent;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _InvoiceField({
    required this.ctrl,
    required this.label,
    required this.accent,
    this.hint,
    this.icon,
    this.max,
    this.maxLines = 1,
    this.required = false,
    this.keyboard,
    this.onChanged,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atLimit = max != null && ctrl.text.length >= max!;

    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      inputFormatters: max != null
          ? [LengthLimitingTextInputFormatter(max!)]
          : null,
      onChanged: onChanged,
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        hintText: hint,
        hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.35), fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 20,
                color: colorScheme.onSurface.withOpacity(0.45))
            : null,
        suffixIcon: suffix ??
            (atLimit
                ? Tooltip(
                    message: 'Character limit reached',
                    child: const Icon(Icons.warning_amber_rounded,
                        size: 18, color: Color(0xFFF44336)))
                : null),
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: atLimit
                    ? const Color(0xFFF44336)
                    : colorScheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: atLimit ? const Color(0xFFF44336) : accent,
                width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF44336))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// =============================================================================
// Date tap field
// =============================================================================

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color accent;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withOpacity(0.45)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: 14, color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Bottom action bar
// =============================================================================

class _InvoiceBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _InvoiceBottomBar({
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface.withOpacity(0.55), size: 22),
            ),
          ),
          const SizedBox(width: 10),

          // Continue
          Expanded(
            child: GestureDetector(
              onTap: onContinue,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x501565C0),
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Continue',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}