// lib/screens/invoice_create_section/step_create_invoice/step_create_invoice.dart
//
// LINE ITEM CONTAINERS PASS (this update): added the "Saved Item Sets"
// panel (CreateInvoiceSavedItemSets, new file
// create_invoice_saved_items_widgets.dart) directly above the Line Items
// section. It lets a bundle of line items be saved under a name and
// quick-added back onto any future invoice's Line Items with a tap,
// mirroring the "tap a card to select it" pattern from Saved Customers/
// Saved Templates -- except tapping a saved set here APPENDS fresh
// copies of its items rather than replacing a persistent selection (see
// the new file's own header note for why). Backed by two new methods on
// this state:
//   - _getCurrentItemsSnapshot(): flushes controller text into _items
//     (same defensive re-sync _continue() already did) and returns
//     copies, so a saved set always reflects exactly what's on screen.
//   - _quickAddItems(): mirrors _addItem() exactly, just seeded with the
//     saved set's item data instead of starting blank. Also clears away
//     the single still-untouched default blank item first (if that's
//     all that's present) so quick-adding a set onto a fresh invoice
//     doesn't leave a stray empty "Item 1" above the added items.
// No other behavior on this step changed.
//
// INVOICE NUMBER LENGTH FIX (earlier update): the auto-generated default
// invoice number was 'INV-$ts' where ts is
// DateTime.now().millisecondsSinceEpoch -- a 13-digit timestamp, producing
// numbers like "INV-1788218487235" (17 chars). That's what was causing the
// "#INV-..." header on the Executive template to wrap and misalign (see
// executive_template.dart's DOC NUMBER WRAP/ALIGNMENT FIX note). The
// default now uses only the last 6 digits of the timestamp
// ("INV-184872", ~10 chars) -- still effectively unique for the purpose of
// a placeholder default, and short enough to fit on one line in every
// template's header. Paired with this, the Invoice Number field's max
// character cap dropped from 30 -> 18, so a manually-typed number can't
// reintroduce the same overflow.
//
// CURRENCY SYMBOL CONDITIONAL (this update): the Display Format picker
// (Code/Symbol/Both) now sits directly under Currency Code, and the
// Currency Symbol field only renders when the picked mode is Symbol or
// Both -- there's no point asking for a symbol while Code mode is active,
// since it isn't shown anywhere. Picking Symbol/Both reveals the field
// underneath the picker; switching back to Code hides it again (the typed
// value in _currencySymbolCtrl is preserved either way, just not shown).
//
// FILE SPLIT (earlier update): this used to be a single ~1,250-line file
// (lib/screens/invoice_create_section/step_create_invoice.dart). It's now
// split into three files under this new step_create_invoice/ folder,
// matching the pattern already used by step_customize/ and
// step_templates/:
//
//   - step_create_invoice.dart (this file)      — StepCreateInvoice
//     widget/state: controllers, sync-to-provider, validation, build().
//   - create_invoice_item_widgets.dart           — CreateInvoiceItemCard,
//     CreateInvoiceTotalsCard (line items + totals card).
//   - create_invoice_form_widgets.dart           — CreateInvoiceField,
//     CreateInvoiceDateField, CreateInvoiceContextBanner,
//     CreateInvoiceCurrencyDisplayModeSelector, CreateInvoiceBottomBar.
//   - create_invoice_saved_items_widgets.dart    — CreateInvoiceSavedItemSets
//     (new, see LINE ITEM CONTAINERS PASS above).
//
// All widget classes previously private to the single file (_ItemCard,
// _TotalsCard, _InvoiceField, _DateField, _ContextBanner,
// _InvoiceCurrencyDisplayModeSelector, _InvoiceBottomBar) are now public
// (renamed with a CreateInvoice prefix, since Dart's `_` privacy is
// file-scoped) so they can be imported here. No behavior changed — only
// location and class names. See each new file's own header for what
// moved there.
//
// Everything below (controllers, totals math, sync/validation logic,
// build()) is otherwise unchanged from the pre-split file, including the
// OVERFLOW FIX (tax/discount rate clamped 0-100 as the single source of
// truth for totals math — see _taxRate/_discountRate and each field's
// onChanged) and the item-description visible character counter, both
// already verified correct and unchanged by this split.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/invoice_models.dart';
import '../../../providers/invoice_provider.dart';
import '../invoice_edit_widgets.dart';
import 'create_invoice_item_widgets.dart';
import 'create_invoice_form_widgets.dart';
import 'create_invoice_saved_items_widgets.dart';

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

  // INVOICE NUMBER LENGTH FIX: single source of truth for the field's max
  // character cap, referenced both by the CreateInvoiceField below and its
  // counter, so they can never drift out of sync with each other.
  static const int _invoiceNumberMax = 18;

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

  // Color scheme — no picker lives on this step; seeded from whatever's
  // already on the provider in initState and carried straight back
  // through in _syncToProvider() so this step never resets a color
  // chosen on the Customise step.
  late InvoiceColorScheme _colorScheme;

  // Currency — free-text code + symbol + Code/Symbol/Both display mode.
  // No hardcoded currency list; any code/symbol combination is accepted.
  // These map straight onto InvoiceData.currency/currencySymbol/
  // currencyDisplayMode.
  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code'; // 'code' | 'symbol' | 'both'

  // Tax / discount rates -- the SOURCE OF TRUTH for all totals math and
  // display (see OVERFLOW FIX note at the top of this file). Kept
  // separate from _taxCtrl/_discountCtrl's raw text so a value typed
  // outside 0-100 can be clamped for calculation purposes without
  // fighting the text field's cursor position by rewriting its text
  // mid-edit. Updated in each field's onChanged below.
  double _taxRate = 0.0;
  double _discountRate = 0.0;

  static const _dateFmt = 'd MMM yyyy';

  /// Local display prefix used only for the item/totals cards on this
  /// step (cosmetic while editing) — symbol first, falling back to code.
  /// The real generated PDF/preview already does the full
  /// Code/Symbol/Both branching via fmtMoney(), so this doesn't need to
  /// replicate that logic exactly.
  String get _currencyPrefix {
    final symbol = _currencySymbolCtrl.text.trim();
    final code = _currencyCodeCtrl.text.trim().toUpperCase();
    if (symbol.isNotEmpty) return symbol;
    if (code.isNotEmpty) return '$code ';
    return '';
  }

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.total);

  // OVERFLOW FIX: these now read the already-clamped _taxRate/
  // _discountRate fields instead of re-parsing raw text on every access
  // with no upper bound -- see the top-of-file note for why that mattered.
  double get _taxAmount => _subtotal * _taxRate / 100;
  double get _discountAmount => _subtotal * _discountRate / 100;
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
    // INVOICE NUMBER LENGTH FIX: only the last 6 digits of the timestamp,
    // not the full 13-digit epoch millis -- see top-of-file note.
    final tsShort =
        ts.toString().substring((ts.toString().length - 6).clamp(0, ts.toString().length));

    _invoiceNumberCtrl = TextEditingController(
      text: existing.invoiceNumber.isNotEmpty
          ? existing.invoiceNumber
          : 'INV-$tsShort',
    );
    _notesCtrl = TextEditingController(text: existing.notes);
    _taxCtrl = TextEditingController(
      text: existing.taxRate == 0 ? '0' : '${existing.taxRate}',
    );
    _discountCtrl = TextEditingController(
      text: existing.discountRate == 0 ? '0' : '${existing.discountRate}',
    );

    // OVERFLOW FIX: clamp whatever was already stored too, in case it was
    // saved before this pass existed (e.g. from an older build, or
    // restored from a provider state that predates the clamp).
    _taxRate = existing.taxRate.clamp(0.0, 100.0);
    _discountRate = existing.discountRate.clamp(0.0, 100.0);

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

    // Currency: template selection wins on first entry for the code;
    // otherwise whatever was already on the provider. Free text — no
    // hardcoded currency list.
    final initialCurrencyCode = widget.selectedTemplate?.currency ??
        (existing.currency.isNotEmpty ? existing.currency : 'USD');
    _currencyCodeCtrl = TextEditingController(text: initialCurrencyCode);
    _currencySymbolCtrl = TextEditingController(text: existing.currencySymbol);
    _currencyDisplayMode = existing.currencyDisplayMode.isNotEmpty
        ? existing.currencyDisplayMode
        : 'code';

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

    // Rebuild on changes for totals / live currency preview
    for (final c in [_taxCtrl, _discountCtrl, _currencyCodeCtrl, _currencySymbolCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _invoiceNumberCtrl, _notesCtrl, _taxCtrl,
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
  // Saved item sets — quick add
  //
  // LINE ITEM CONTAINERS PASS: backs the new CreateInvoiceSavedItemSets
  // panel above the Line Items section (see this file's top-of-file
  // note and create_invoice_saved_items_widgets.dart).
  //
  // _getCurrentItemsSnapshot() flushes whatever's currently typed in
  // each item's controllers into _items -- the same defensive re-sync
  // _continue() already does before handing off to the provider -- and
  // hands back fresh copies, so a saved set always reflects exactly
  // what's on screen right now, not stale onChanged-mirrored data.
  //
  // _quickAddItems() mirrors _addItem() exactly, just seeded with the
  // saved set's item data instead of starting blank. It also clears
  // away the single still-untouched default blank item first (empty
  // description, qty 1, price 0) if that's the only item present, so
  // quick-adding a set onto a fresh invoice doesn't leave a stray empty
  // "Item 1" sitting above the items that were just added.
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
  // Sync to InvoiceProvider
  //
  // Builds a full InvoiceData from everything on this step and writes it
  // via provider.updateInvoiceData(). paymentStatus and fontFamily aren't
  // edited on this step, so they're carried over from whatever's currently
  // on the provider rather than reset to defaults. layoutTemplateId comes
  // from the selected BusinessInfo template, falling back to whatever's
  // already on the provider. currency/currencySymbol/currencyDisplayMode
  // now come straight from the free-text fields on this step.
  //
  // LOGO OVERWRITE FIX: the business logo's path/offset/scale/shape is
  // resolved as ONE unit rather than falling back independently per
  // field — keep whatever's already on the provider if it already has a
  // logo set (whether that came from the template originally or a later
  // Customise edit); only pull from the template when the provider has
  // no logo at all yet.
  // ---------------------------------------------------------------------------
  void _syncToProvider() {
    final provider = context.read<InvoiceProvider>();
    final current = provider.invoiceData;
    final businessInfo = widget.selectedTemplate?.businessInfo;

    final providerHasLogo = current.businessLogoPath != null &&
        current.businessLogoPath!.isNotEmpty;
    final useTemplateLogo = !providerHasLogo && businessInfo?.logoPath != null;

    final resolvedLogoPath =
        useTemplateLogo ? businessInfo!.logoPath : current.businessLogoPath;
    final resolvedLogoOffsetDx = useTemplateLogo
        ? businessInfo!.logoOffsetDx
        : current.businessLogoOffsetDx;
    final resolvedLogoOffsetDy = useTemplateLogo
        ? businessInfo!.logoOffsetDy
        : current.businessLogoOffsetDy;
    final resolvedLogoScale =
        useTemplateLogo ? businessInfo!.logoScale : current.businessLogoScale;
    final resolvedLogoShape =
        useTemplateLogo ? businessInfo!.logoShape : current.businessLogoShape;

    final data = InvoiceData(
      businessName: businessInfo?.name ?? current.businessName,
      businessEmail: businessInfo?.email ?? current.businessEmail,
      businessPhone: businessInfo?.phone ?? current.businessPhone,
      businessAddress: businessInfo?.address ?? current.businessAddress,
      businessLogoPath: resolvedLogoPath,
      businessLogoOffsetDx: resolvedLogoOffsetDx,
      businessLogoOffsetDy: resolvedLogoOffsetDy,
      businessLogoScale: resolvedLogoScale,
      businessLogoShape: resolvedLogoShape,
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
      paymentStatus: current.paymentStatus,
      fontFamily: current.fontFamily,
      colorScheme: _colorScheme,
      layoutTemplateId: widget.layoutTemplateId ?? current.layoutTemplateId,
    );

    provider.updateInvoiceData(data);
  }

  // ---------------------------------------------------------------------------
  // Validation
  //
  // Blocks Continue on: blank invoice number, blank customer name (when
  // no customer was selected in step 1), whitespace-only item
  // descriptions, and a tax/discount rate outside 0-100.
  //
  // OVERFLOW FIX: _taxRate/_discountRate are now clamped continuously as
  // they're typed (see each field's onChanged below), so the last two
  // checks should never actually trigger during normal use -- kept as a
  // defensive backstop in case a bad value was ever restored from an
  // older save that predates the clamp.
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
  // Continue — validates the items on this step, syncs everything into
  // InvoiceProvider, then hands off to the parent flow (the customise
  // step) via widget.onNext().
  // ---------------------------------------------------------------------------
  void _continue() {
    if (!_validateForm()) return;
    // Push current controller text into _items before syncing, since
    // description/qty/price are only mirrored into _items via onChanged
    // callbacks below — this guards against any missed callback.
    for (int i = 0; i < _items.length; i++) {
      _items[i]
        ..description = _descCtrl[i].text.trim()
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
                : colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  /// OVERFLOW FIX: small caption shown under Tax %/Discount % whenever
  /// the raw typed value is outside 0-100 -- since the field itself
  /// still shows exactly what was typed (rewriting the controller's text
  /// mid-edit would fight the cursor position rather than help), this
  /// makes it visible that the totals below are using the clamped rate,
  /// not the raw number sitting in the field.
  Widget _rangeWarning(double raw, double clamped) {
    if (raw == clamped) return const SizedBox.shrink();
    final clampedLabel =
        clamped % 1 == 0 ? clamped.toInt().toString() : clamped.toStringAsFixed(1);
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
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Context banner (template / customer selection) ────
                      CreateInvoiceContextBanner(
                        template: widget.selectedTemplate,
                        customer: widget.selectedCustomer,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // ── Invoice number ───────────────────────────────────
                      _sectionHeader('Invoice Details',
                          icon: Icons.receipt_long_rounded),
                      CreateInvoiceField(
                        ctrl: _invoiceNumberCtrl,
                        label: 'Invoice Number',
                        hint: 'e.g. INV-001',
                        icon: Icons.tag_rounded,
                        // INVOICE NUMBER LENGTH FIX: 30 -> 18. See
                        // top-of-file note; this is what stops a
                        // manually-typed number from wrapping/misaligning
                        // in the Executive header.
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

                      // ── Currency ─────────────────────────────────────────
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

                      // CURRENCY SYMBOL CONDITIONAL: Display Format picker
                      // now sits directly under Currency Code. The Currency
                      // Symbol field below only renders once Symbol/Both is
                      // selected -- see top-of-file note.
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

                      // ── Customer (if none selected in step 1) ───────────
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

                      // ── Saved item sets (quick-add) ──────────────────────
                      // LINE ITEM CONTAINERS PASS: see top-of-file note.
                      CreateInvoiceSavedItemSets(
                        getCurrentItems: _getCurrentItemsSnapshot,
                        onQuickAdd: _quickAddItems,
                        currencySymbol: _currencyPrefix,
                      ),
                      const SizedBox(height: 20),

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

                      // ── Tax / Discount ───────────────────────────────────
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

                      // ── Totals card ──────────────────────────────────────
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

                      // ── Notes ────────────────────────────────────────────
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
                                            .withValues(alpha: 0.6),
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
        CreateInvoiceBottomBar(
          onBack: widget.onBack,
          onContinue: _continue,
        ),
      ],
    );
  }
}