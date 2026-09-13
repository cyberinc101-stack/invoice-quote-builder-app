// lib/screens/create_quote_section/step_create_quote/create_quote_bottom_sheet.dart
//
// SAVED-ITEMS CAP ENFORCEMENT PASS (this update): _saveDraftItem() now
// checks the saved single-item library against kMaxSavedQuoteLineItems
// (create_quote_saved_line_items_widgets.dart, currently 200) before
// adding a new entry — previously the constant existed but nothing ever
// compared the library's length against it, so a saved-items library
// with no practical ceiling could grow unbounded. When already at the
// cap, the item is NOT added to the saved library and a snackbar
// explains why; the draft card is left exactly as typed so nothing is
// lost, matching the same "block and explain, don't silently drop"
// pattern already used for Container/Template/Customer caps elsewhere
// in this app. Toggling inclusion of an ALREADY-saved item
// (_toggleSavedLineItem) is unaffected — that never creates a new saved
// entry, so the cap doesn't apply there.
//
// TAX-BASE FIX (earlier): _taxAmount was computing tax on the raw
// _subtotal (before the whole-quote discount was subtracted) —
// `_subtotal * _taxRate / 100`. QuoteData.taxAmount (the model that
// actually gets saved and rendered everywhere else on the document) has
// always computed it on the DISCOUNTED subtotal instead:
// `(subtotal - discountAmount) * taxRate / 100`. Whenever both
// whole-quote Tax and Discount were switched on, this sheet's own live
// Totals card showed a tax figure — and therefore a running Estimated
// Total — slightly higher than what actually got saved into the quote
// and rendered on the document. Fixed to match QuoteData.taxAmount
// exactly. No other totals math on this sheet was affected — subtotal,
// discountAmount, itemTaxExtra/itemDiscountExtra (and their
// by-name breakdowns), and _total's own formula were already correct.
//
// CREATE-QUOTE PARITY PASS (earlier): rebuilt to match Invoice's
// create_invoice_bottom_sheet.dart structure — Container Name (required)
// + Container Logo section, structured six-field Client Address, a
// single-draft item card (with Unit dropdown + per-item Tax/Discount
// toggle+sign+name) backed by a real "Saved Items" single-item library
// with inclusion checkboxes, whole-quote Tax/Discount with their own
// name field + on/off switch, and a live Totals card — replacing the
// old flat client-address field / N-cards-stacked line-item list /
// bundle-only saved items.
//
// Deliberately LEFT OUT (Invoice-only, no QuoteData equivalent and
// genuinely quote-inappropriate):
//   - PO / Reference Number — a purchase-order concept; quotes precede
//     a PO, they don't carry one.
//   - Amount Due override — quotes don't have an amount "due"; they have
//     a total the client accepts or declines. QuoteData.grandTotal is
//     the only total a quote needs.
//   - The persisted "last used" default for the whole-quote Tax/
//     Discount switches (Invoice's SharedPreferences convenience) — kept
//     simple: a brand-new quote starts with both on, matching every
//     quote persisted before this pass (which already applied
//     taxRate/discountRate unconditionally).
//
// PARITY CORRECTION (earlier): the "Saved Item Sets" bundle
// quick-add panel (QuoteSavedItemSets, quote_saved_items_widgets.dart)
// has been removed from this sheet — a prior pass kept it on the theory
// that dropping it would be an unrequested regression, but the person
// confirmed the bundle-sets feature isn't wanted here at all, matching
// Invoice exactly (which has no bundle panel on its own bottom sheet).
// quote_saved_items_widgets.dart itself is no longer referenced by this
// file and can be deleted from the project if nothing else uses it.
//
// Behaviorally this otherwise mirrors CreateInvoiceBottomSheet closely:
// same shape of controllers, same validation rules, same defensive
// re-sync of controller text before building the final QuoteData. It
// still doesn't talk to QuoteProvider directly for line-item math (no
// provider read needed here, unlike the old version's
// `current.copyWith()` — this sheet now builds a QuoteData from scratch
// off its own state, mirroring Invoice's CreateInvoiceBottomSheet, which
// never touched InvoiceProvider either) — the outer QuoteEditorScreen
// still owns syncing the *selected* draft's data into QuoteProvider when
// continuing to Customise.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../models/invoice_data.dart' show LineItem;
import '../../../models/quote_data.dart';
import '../../../models/address_info.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../step_customer/quote_step_customer.dart' show QuoteClient;
import '../step_templates/quote_step_template.dart' show QuoteTemplate;
import 'create_quote_form_widgets.dart';
import 'create_quote_item_widgets.dart';
import 'create_quote_saved_line_items_widgets.dart';

// =============================================================================
// CreateQuoteBottomSheet
// =============================================================================

class CreateQuoteBottomSheet extends StatefulWidget {
  final QuoteClient? selectedClient;
  final QuoteTemplate? selectedTemplate;

  /// The draft being edited, or null when creating a brand new one.
  final SavedQuoteDraft? existing;

  final void Function(SavedQuoteDraft draft) onSaved;

  const CreateQuoteBottomSheet({
    super.key,
    this.selectedClient,
    this.selectedTemplate,
    this.existing,
    required this.onSaved,
  });

  @override
  State<CreateQuoteBottomSheet> createState() =>
      _CreateQuoteBottomSheetState();
}

class _CreateQuoteBottomSheetState extends State<CreateQuoteBottomSheet> {
  static const _accent = Color(0xFF7B1FA2);
  static const int _quoteNumberMax = 18;

  // Container name/logo — CREATE-QUOTE PARITY PASS: mirrors Invoice's
  // "Container Name *" + "Container Logo" section exactly. Required,
  // same reasoning as Invoice: it's the label shown on the library card
  // back on step_create_quote.dart.
  late TextEditingController _nameCtrl;
  String? _containerLogoPath;
  Offset _containerLogoOffset = Offset.zero;
  double _containerLogoScale = 1.0;
  LogoShape _containerLogoShape = LogoShape.roundedSquare;
  bool _containerLogoShowInitial = true;
  String _containerLogoInitialLetter = '';

  // Controllers
  late TextEditingController _quoteNumberCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _taxNameCtrl;
  late TextEditingController _discountNameCtrl;

  // Client override (if no client passed from the Customer step)
  late TextEditingController _custNameCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;

  // CREATE-QUOTE PARITY PASS: structured six-field client address,
  // mirrors Invoice's own six manual address fields exactly. Only used/
  // shown when widget.selectedClient == null.
  late TextEditingController _custAddrLine1Ctrl;
  late TextEditingController _custAddrLine2Ctrl;
  late TextEditingController _custCityCtrl;
  late TextEditingController _custStateCtrl;
  late TextEditingController _custCountryCtrl;
  late TextEditingController _custZipCtrl;

  // Committed line items — every entry here is already final (added via
  // the draft card's Save Item button, or via toggling a Saved-items
  // checkbox, or via the bundle quick-add).
  late List<LineItem> _items;

  // The one item currently being typed under "New", not yet part of
  // _items — mirrors Invoice's single-draft-item pattern.
  late LineItem _draftItem;
  late TextEditingController _draftDescCtrl;
  late TextEditingController _draftQtyCtrl;
  late TextEditingController _draftPriceCtrl;
  late TextEditingController _draftUnitCustomLabelCtrl;
  late TextEditingController _draftTaxRateCtrl;
  late TextEditingController _draftDiscountRateCtrl;
  late TextEditingController _draftTaxNameCtrl;
  late TextEditingController _draftDiscountNameCtrl;

  // Saved single-item library, always shown alongside the draft card.
  bool _savedLibraryLoading = true;
  List<SavedQuoteLineItem> _savedLineItems = [];

  // Dates
  String _issueDate = '';
  String _expiryDate = '';

  // Currency
  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code';

  double _taxRate = 0.0;
  double _discountRate = 0.0;

  // Whole-quote Tax/Discount on/off switches. A brand new quote starts
  // with both on (matches every quote persisted before this field
  // existed, which already applied taxRate/discountRate unconditionally)
  // — no persisted "last used" convenience default, unlike Invoice.
  bool _taxEnabled = true;
  bool _discountEnabled = true;

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
  double get _discountAmount => _discountEnabled ? _subtotal * _discountRate / 100 : 0.0;
  // TAX-BASE FIX: tax now applies to the DISCOUNTED subtotal, matching
  // QuoteData.taxAmount exactly — previously this read
  // `_subtotal * _taxRate / 100`, ignoring the whole-quote discount
  // entirely and showing a higher live total than what actually got
  // saved. _discountAmount is referenced here even though it's declared
  // as the getter above; Dart getters resolve lazily so the order
  // between them doesn't matter.
  double get _taxAmount =>
      _taxEnabled ? (_subtotal - _discountAmount) * _taxRate / 100 : 0.0;
  double get _itemTaxExtra => _items.fold(
      0.0,
      (sum, i) => sum +
          (i.taxEnabled
              ? (i.itemTaxIsAddition ? 1 : -1) * i.total * i.itemTaxRate / 100
              : 0.0));
  double get _itemDiscountExtra => _items.fold(0.0,
      (sum, i) => sum + (i.discountEnabled ? i.total * i.itemDiscountRate / 100 : 0.0));
  double get _total =>
      _subtotal + _taxAmount - _discountAmount + _itemTaxExtra - _itemDiscountExtra;

  Map<String, double> get _itemTaxExtraByName {
    final map = <String, double>{};
    for (final i in _items) {
      if (!i.taxEnabled) continue;
      final key = i.itemTaxName.trim();
      final amt = (i.itemTaxIsAddition ? 1 : -1) * i.total * i.itemTaxRate / 100;
      map[key] = (map[key] ?? 0.0) + amt;
    }
    return map;
  }

  Map<String, double> get _itemDiscountExtraByName {
    final map = <String, double>{};
    for (final i in _items) {
      if (!i.discountEnabled) continue;
      final key = i.itemDiscountName.trim();
      final amt = i.total * i.itemDiscountRate / 100;
      map[key] = (map[key] ?? 0.0) + amt;
    }
    return map;
  }

  Set<String> get _includedSavedIds => _items
      .map((i) => i.sourceSavedId)
      .whereType<String>()
      .toSet();

  @override
  void initState() {
    super.initState();

    final existingData = widget.existing?.data;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tsShort = ts
        .toString()
        .substring((ts.toString().length - 6).clamp(0, ts.toString().length));

    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');

    _containerLogoPath = widget.existing?.logoPath;
    _containerLogoOffset = Offset(
      widget.existing?.logoOffsetDx ?? 0.0,
      widget.existing?.logoOffsetDy ?? 0.0,
    );
    _containerLogoScale = widget.existing?.logoScale ?? 1.0;
    _containerLogoShape = logoShapeFromString(widget.existing?.logoShape ?? 'roundedSquare');
    _containerLogoShowInitial = widget.existing?.logoShowInitial ?? true;
    _containerLogoInitialLetter = widget.existing?.logoInitialLetter ?? '';

    _quoteNumberCtrl = TextEditingController(
      text: (existingData != null && existingData.quoteNumber.isNotEmpty)
          ? existingData.quoteNumber
          : 'Q-$tsShort',
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
    _taxEnabled = existingData?.taxEnabled ?? true;
    _discountEnabled = existingData?.discountEnabled ?? true;
    _taxNameCtrl = TextEditingController(text: existingData?.taxName ?? '');
    _discountNameCtrl = TextEditingController(text: existingData?.discountName ?? '');

    _custNameCtrl = TextEditingController(
      text: widget.selectedClient?.name ?? existingData?.clientName ?? '',
    );
    _custEmailCtrl = TextEditingController(
      text: widget.selectedClient?.email ?? existingData?.clientEmail ?? '',
    );
    _custPhoneCtrl = TextEditingController(
      text: widget.selectedClient?.phone ?? existingData?.clientPhone ?? '',
    );

    final seedAddress = existingData?.clientAddressInfo ?? AddressInfo();
    _custAddrLine1Ctrl = TextEditingController(text: seedAddress.line1);
    _custAddrLine2Ctrl = TextEditingController(text: seedAddress.line2);
    _custCityCtrl = TextEditingController(text: seedAddress.city);
    _custStateCtrl = TextEditingController(text: seedAddress.state);
    _custCountryCtrl = TextEditingController(text: seedAddress.country);
    _custZipCtrl = TextEditingController(text: seedAddress.postalCode);

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

    _issueDate = (existingData != null && existingData.issueDate.isNotEmpty)
        ? existingData.issueDate
        : DateFormat(_dateFmt).format(DateTime.now());
    _expiryDate = (existingData != null && existingData.expiryDate.isNotEmpty)
        ? existingData.expiryDate
        : DateFormat(_dateFmt).format(DateTime.now().add(const Duration(days: 14)));

    // Committed items — restore from the draft if present, else start
    // empty (the draft card below is how the first item gets added).
    _items = (existingData != null && existingData.lineItems.isNotEmpty)
        ? existingData.lineItems.map((i) => i.copyWith()).toList()
        : [];

    _draftItem = LineItem();
    _draftDescCtrl = TextEditingController();
    _draftQtyCtrl = TextEditingController(text: '1');
    _draftPriceCtrl = TextEditingController(text: '0');
    _draftUnitCustomLabelCtrl = TextEditingController();
    _draftTaxRateCtrl = TextEditingController(text: '0');
    _draftDiscountRateCtrl = TextEditingController(text: '0');
    _draftTaxNameCtrl = TextEditingController();
    _draftDiscountNameCtrl = TextEditingController();

    for (final c in [
      _nameCtrl,
      _quoteNumberCtrl,
      _taxCtrl,
      _discountCtrl,
      _taxNameCtrl,
      _discountNameCtrl,
      _currencyCodeCtrl,
      _currencySymbolCtrl,
      _draftDescCtrl,
      _draftQtyCtrl,
      _draftPriceCtrl,
      _draftUnitCustomLabelCtrl,
      _draftTaxRateCtrl,
      _draftDiscountRateCtrl,
      _draftTaxNameCtrl,
      _draftDiscountNameCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }

    _loadSavedLibrary();
  }

  Future<void> _loadSavedLibrary() async {
    final items = await loadSavedQuoteLineItems();
    if (!mounted) return;
    setState(() {
      _savedLineItems = items;
      _savedLibraryLoading = false;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _quoteNumberCtrl, _notesCtrl, _taxCtrl,
      _discountCtrl, _taxNameCtrl, _discountNameCtrl,
      _custNameCtrl, _custEmailCtrl, _custPhoneCtrl,
      _custAddrLine1Ctrl, _custAddrLine2Ctrl, _custCityCtrl,
      _custStateCtrl, _custCountryCtrl, _custZipCtrl,
      _currencyCodeCtrl, _currencySymbolCtrl,
      _draftDescCtrl, _draftQtyCtrl, _draftPriceCtrl,
      _draftUnitCustomLabelCtrl,
      _draftTaxRateCtrl, _draftDiscountRateCtrl,
      _draftTaxNameCtrl, _draftDiscountNameCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Commit the draft card — adds it to the quote's real line items AND
  // saves it into the single-item library, then resets the draft card.
  //
  // SAVED-ITEMS CAP ENFORCEMENT PASS: guards the saved-library side of
  // this action against kMaxSavedQuoteLineItems — if the library is
  // already full, the new item is NOT saved to the library (and
  // therefore not added to _items either, since it's only ever added as
  // a saved-linked copy here), and a snackbar explains why. The typed
  // draft is left untouched so nothing the person entered is lost.
  // ---------------------------------------------------------------------------
  Future<void> _saveDraftItem() async {
    _draftItem
      ..description = _draftDescCtrl.text.trim()
      ..quantity = double.tryParse(_draftQtyCtrl.text) ?? 1
      ..unitPrice = double.tryParse(_draftPriceCtrl.text) ?? 0
      ..customUnitLabel = _draftItem.unit == 'custom'
          ? _draftUnitCustomLabelCtrl.text.trim()
          : ''
      ..itemTaxRate = (double.tryParse(_draftTaxRateCtrl.text) ?? 0.0).clamp(0.0, 100.0)
      ..itemDiscountRate = (double.tryParse(_draftDiscountRateCtrl.text) ?? 0.0).clamp(0.0, 100.0)
      ..itemTaxName = _draftTaxNameCtrl.text.trim()
      ..itemDiscountName = _draftDiscountNameCtrl.text.trim();

    if (_draftItem.description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a description before saving this item.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // SAVED-ITEMS CAP ENFORCEMENT PASS: block before creating the
    // library entry — kMaxSavedQuoteLineItems is exported from
    // create_quote_saved_line_items_widgets.dart (currently 200).
    if (_savedLineItems.length >= kMaxSavedQuoteLineItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maximum of $kMaxSavedQuoteLineItems saved items reached. Delete one before saving another.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final libraryEntry = SavedQuoteLineItem(
      id: const Uuid().v4(),
      item: _draftItem.copyWith(clearSourceSavedId: true),
      createdAt: now,
      lastEditedAt: now,
    );

    setState(() {
      _savedLineItems.add(libraryEntry);
      _items.add(_draftItem.copyWith(sourceSavedId: libraryEntry.id));
      _draftItem = LineItem();
      _draftDescCtrl.text = '';
      _draftQtyCtrl.text = '1';
      _draftPriceCtrl.text = '0';
      _draftUnitCustomLabelCtrl.text = '';
      _draftTaxRateCtrl.text = '0';
      _draftDiscountRateCtrl.text = '0';
      _draftTaxNameCtrl.text = '';
      _draftDiscountNameCtrl.text = '';
    });
    await persistSavedQuoteLineItems(_savedLineItems);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${libraryEntry.displayName}" and added it to this quote.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSavedLineItem(SavedQuoteLineItem saved) {
    final alreadyIncluded = _items.any((i) => i.sourceSavedId == saved.id);
    setState(() {
      if (alreadyIncluded) {
        _items.removeWhere((i) => i.sourceSavedId == saved.id);
      } else {
        _items.add(saved.item.copyWith(sourceSavedId: saved.id));
      }
    });
  }

  Future<void> _editSavedLineItem(int index, SavedQuoteLineItem updated) async {
    setState(() => _savedLineItems[index] = updated);
    await persistSavedQuoteLineItems(_savedLineItems);
  }

  Future<void> _deleteSavedLineItem(int index) async {
    setState(() => _savedLineItems.removeAt(index));
    await persistSavedQuoteLineItems(_savedLineItems);
  }

  // ---------------------------------------------------------------------------
  // Validation
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
    if (_nameCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a name for this container.');
      return false;
    }

    if (_quoteNumberCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a quote number.');
      return false;
    }

    if (widget.selectedClient == null && _custNameCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a client name.');
      return false;
    }

    if (_items.isEmpty) {
      _showValidationError('Add and save at least one item to continue.');
      return false;
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
  // Save — validates, builds a QuoteData off the already-committed
  // _items list, wraps it in a SavedQuoteDraft (preserving id/createdAt
  // when editing), hands it to the parent via onSaved(), closes the sheet.
  // ---------------------------------------------------------------------------
  void _save() {
    if (!_validateForm()) return;

    final clientAddressInfo = widget.selectedClient != null
        ? AddressInfo(line1: widget.selectedClient!.address)
        : AddressInfo(
            line1: _custAddrLine1Ctrl.text.trim(),
            line2: _custAddrLine2Ctrl.text.trim(),
            city: _custCityCtrl.text.trim(),
            state: _custStateCtrl.text.trim(),
            country: _custCountryCtrl.text.trim(),
            postalCode: _custZipCtrl.text.trim(),
          );

    // Business info is deliberately NOT set here — matches Invoice's
    // CreateInvoiceBottomSheet exactly, which leaves every business field
    // at its constructor default and lets the outer sync step (wherever
    // a selected draft is applied to QuoteProvider when continuing past
    // this step) resolve business info from the selected template
    // merged with whatever's already on the provider, the same
    // template-first-else-current pattern
    // StepCreateInvoice._syncSelectedToProvider() uses.
    final data = QuoteData(
      clientName: _custNameCtrl.text.trim(),
      clientEmail: _custEmailCtrl.text.trim(),
      clientPhone: _custPhoneCtrl.text.trim(),
      clientAddress: clientAddressInfo.singleLine,
      clientAddressInfo: clientAddressInfo,
      quoteNumber: _quoteNumberCtrl.text.trim(),
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      notes: _notesCtrl.text.trim(),
      currency: _currencyCodeCtrl.text.trim().isEmpty
          ? 'USD'
          : _currencyCodeCtrl.text.trim().toUpperCase(),
      currencySymbol: _currencySymbolCtrl.text.trim(),
      currencyDisplayMode: _currencyDisplayMode,
      lineItems: List<LineItem>.from(_items),
      taxRate: _taxRate,
      discountRate: _discountRate,
      taxName: _taxNameCtrl.text.trim(),
      discountName: _discountNameCtrl.text.trim(),
      taxEnabled: _taxEnabled,
      discountEnabled: _discountEnabled,
    );

    final now = DateTime.now();
    final draft = SavedQuoteDraft(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      data: data,
      createdAt: widget.existing?.createdAt ?? now,
      lastEditedAt: now,
      logoPath: _containerLogoPath,
      logoOffsetDx: _containerLogoOffset.dx,
      logoOffsetDy: _containerLogoOffset.dy,
      logoScale: _containerLogoScale,
      logoShape: _containerLogoShape.storageName,
      logoShowInitial: _containerLogoShowInitial,
      logoInitialLetter: _containerLogoInitialLetter.trim(),
    );

    widget.onSaved(draft);
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------
  Future<void> _pickDate({required bool isExpiry}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        final formatted = DateFormat(_dateFmt).format(picked);
        if (isExpiry) {
          _expiryDate = formatted;
        } else {
          _issueDate = formatted;
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
                              _isEditing ? 'Edit Quote' : 'Create Quote',
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
                                    ? const Color(0xFF2A0D33)
                                    : const Color(0xFFF3E5F5),
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

                      // ── Context banner ───────────────────────────────
                      CreateQuoteContextBanner(
                        template: widget.selectedTemplate,
                        client: widget.selectedClient,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // ── Container name + logo ────────────────────────
                      _sectionHeader('Container Details', icon: Icons.folder_rounded),
                      CreateQuoteField(
                        ctrl: _nameCtrl,
                        label: 'Container Name *',
                        hint: 'e.g. Acme Corp — March proposal',
                        icon: Icons.label_rounded,
                        max: 60,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_nameCtrl.text.length, 60),
                      const SizedBox(height: 20),

                      _sectionHeader('Container Logo', icon: Icons.image_rounded),
                      SharedLogoPicker(
                        logoPath: _containerLogoPath,
                        logoOffset: _containerLogoOffset,
                        logoScale: _containerLogoScale,
                        logoShape: _containerLogoShape,
                        accent: _accent,
                        onChanged: (p, o, s, shape) => setState(() {
                          _containerLogoPath = p;
                          _containerLogoOffset = o;
                          _containerLogoScale = s;
                          _containerLogoShape = shape;
                        }),
                        showInitialFallback: _containerLogoShowInitial,
                        onShowInitialFallbackChanged: (v) =>
                            setState(() => _containerLogoShowInitial = v),
                        initialLetterOverride: _containerLogoInitialLetter,
                        onInitialLetterOverrideChanged: (v) =>
                            setState(() => _containerLogoInitialLetter = v),
                      ),
                      const SizedBox(height: 20),

                      // ── Quote number ──────────────────────────────────
                      _sectionHeader('Quote Details', icon: Icons.request_quote_rounded),
                      CreateQuoteField(
                        ctrl: _quoteNumberCtrl,
                        label: 'Quote Number',
                        hint: 'e.g. Q-001',
                        icon: Icons.tag_rounded,
                        max: _quoteNumberMax,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_quoteNumberCtrl.text.length, _quoteNumberMax),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: CreateQuoteDateField(
                              label: 'Issue Date',
                              value: _issueDate,
                              onTap: () => _pickDate(isExpiry: false),
                              accent: _accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CreateQuoteDateField(
                              label: 'Valid Until',
                              value: _expiryDate,
                              onTap: () => _pickDate(isExpiry: true),
                              accent: _accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Currency ─────────────────────────────────────
                      _sectionHeader('Currency', icon: Icons.attach_money_rounded),
                      CreateQuoteCurrencyDisplayModeSelector(
                        value: _currencyDisplayMode,
                        accent: _accent,
                        onChanged: (mode) =>
                            setState(() => _currencyDisplayMode = mode),
                        previewCode: _currencyCodeCtrl.text.trim().isEmpty
                            ? 'USD'
                            : _currencyCodeCtrl.text.trim().toUpperCase(),
                        previewSymbol: _currencySymbolCtrl.text.trim(),
                      ),
                      const SizedBox(height: 12),
                      CreateQuoteField(
                        ctrl: _currencyCodeCtrl,
                        label: 'Currency Code',
                        hint: 'e.g. USD',
                        icon: Icons.attach_money_rounded,
                        max: 6,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_currencyCodeCtrl.text.length, 6),
                      if (_currencyDisplayMode != 'code') ...[
                        const SizedBox(height: 12),
                        CreateQuoteField(
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

                      // ── Client (if none selected on the Customer step) ─
                      if (widget.selectedClient == null) ...[
                        _sectionHeader('Client Details', icon: Icons.person_rounded),
                        CreateQuoteField(
                          ctrl: _custNameCtrl,
                          label: 'Client Name',
                          hint: 'e.g. Acme Corp',
                          icon: Icons.person_rounded,
                          max: 40,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateQuoteField(
                          ctrl: _custEmailCtrl,
                          label: 'Client Email',
                          hint: 'e.g. billing@acme.com',
                          icon: Icons.email_rounded,
                          max: 60,
                          keyboard: TextInputType.emailAddress,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateQuoteField(
                          ctrl: _custPhoneCtrl,
                          label: 'Client Phone',
                          hint: 'e.g. +1 555 000 1234',
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),

                        _sectionHeader('Client Address', icon: Icons.location_on_rounded),
                        CreateQuoteField(
                          ctrl: _custAddrLine1Ctrl,
                          label: 'Address Line 1 (Optional)',
                          hint: 'e.g. 123 Queen Street',
                          icon: Icons.location_on_rounded,
                          max: 60,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custAddrLine1Ctrl.text.length, 60),
                        const SizedBox(height: 12),
                        CreateQuoteField(
                          ctrl: _custAddrLine2Ctrl,
                          label: 'Address Line 2 (Optional)',
                          hint: 'e.g. Apt 4B, Level 2',
                          icon: Icons.location_on_rounded,
                          max: 60,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custAddrLine2Ctrl.text.length, 60),
                        const SizedBox(height: 12),
                        CreateQuoteField(
                          ctrl: _custCityCtrl,
                          label: 'City (Optional)',
                          hint: 'e.g. Auckland',
                          icon: Icons.location_city_rounded,
                          max: 40,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custCityCtrl.text.length, 40),
                        const SizedBox(height: 12),
                        CreateQuoteField(
                          ctrl: _custStateCtrl,
                          label: 'State / Province (Optional)',
                          hint: 'e.g. Auckland',
                          icon: Icons.map_rounded,
                          max: 40,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custStateCtrl.text.length, 40),
                        const SizedBox(height: 12),
                        CreateQuoteField(
                          ctrl: _custCountryCtrl,
                          label: 'Country (Optional)',
                          hint: 'e.g. New Zealand',
                          icon: Icons.public_rounded,
                          max: 40,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custCountryCtrl.text.length, 40),
                        const SizedBox(height: 12),
                        CreateQuoteField(
                          ctrl: _custZipCtrl,
                          label: 'ZIP / Postal Code (Optional)',
                          hint: 'e.g. 1010',
                          icon: Icons.markunread_mailbox_rounded,
                          max: 16,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custZipCtrl.text.length, 16),
                        const SizedBox(height: 20),
                      ],

                      // ── Line items ───────────────────────────────────
                      _sectionHeader('Line Items', icon: Icons.list_alt_rounded),

                      CreateQuoteItemCard(
                        item: _draftItem,
                        descCtrl: _draftDescCtrl,
                        qtyCtrl: _draftQtyCtrl,
                        priceCtrl: _draftPriceCtrl,
                        unitCustomLabelCtrl: _draftUnitCustomLabelCtrl,
                        taxRateCtrl: _draftTaxRateCtrl,
                        discountRateCtrl: _draftDiscountRateCtrl,
                        taxNameCtrl: _draftTaxNameCtrl,
                        discountNameCtrl: _draftDiscountNameCtrl,
                        currencySymbol: _currencyPrefix,
                        accent: _accent,
                        onChanged: () => setState(() {}),
                        onSaveItem: _saveDraftItem,
                      ),
                      const SizedBox(height: 20),

                      _savedLibraryLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : CreateQuoteSavedLineItemsPanel(
                              library: _savedLineItems,
                              includedIds: _includedSavedIds,
                              currencySymbol: _currencyPrefix,
                              accent: _accent,
                              onToggleInclude: _toggleSavedLineItem,
                              onEdit: _editSavedLineItem,
                              onDelete: _deleteSavedLineItem,
                            ),
                      const SizedBox(height: 12),

                      // ── Tax / Discount (whole-quote) ─────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('Tax',
                                          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                                    ),
                                    Switch(
                                      value: _taxEnabled,
                                      onChanged: (v) => setState(() => _taxEnabled = v),
                                      activeTrackColor: _accent,
                                    ),
                                  ],
                                ),
                                if (_taxEnabled) ...[
                                  CreateQuoteField(
                                    ctrl: _taxNameCtrl,
                                    label: 'Tax Name (Optional)',
                                    hint: 'e.g. GST',
                                    icon: Icons.label_outline_rounded,
                                    max: 8,
                                    accent: _accent,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  _counter(_taxNameCtrl.text.length, 8),
                                  const SizedBox(height: 12),
                                  CreateQuoteField(
                                    ctrl: _taxCtrl,
                                    label: 'Tax %',
                                    hint: 'e.g. 10',
                                    icon: Icons.percent_rounded,
                                    max: 5,
                                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                                    extraFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    accent: _accent,
                                    onChanged: (v) => setState(() {
                                      final parsed = double.tryParse(v) ?? 0.0;
                                      _taxRate = parsed.clamp(0.0, 100.0);
                                    }),
                                  ),
                                  _rangeWarning(double.tryParse(_taxCtrl.text) ?? 0.0, _taxRate),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('Discount',
                                          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                                    ),
                                    Switch(
                                      value: _discountEnabled,
                                      onChanged: (v) => setState(() => _discountEnabled = v),
                                      activeTrackColor: _accent,
                                    ),
                                  ],
                                ),
                                if (_discountEnabled) ...[
                                  CreateQuoteField(
                                    ctrl: _discountNameCtrl,
                                    label: 'Discount Name (Optional)',
                                    hint: 'e.g. Trade',
                                    icon: Icons.label_outline_rounded,
                                    max: 8,
                                    accent: _accent,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  _counter(_discountNameCtrl.text.length, 8),
                                  const SizedBox(height: 12),
                                  CreateQuoteField(
                                    ctrl: _discountCtrl,
                                    label: 'Discount %',
                                    hint: 'e.g. 5',
                                    icon: Icons.local_offer_rounded,
                                    max: 5,
                                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                                    extraFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    accent: _accent,
                                    onChanged: (v) => setState(() {
                                      final parsed = double.tryParse(v) ?? 0.0;
                                      _discountRate = parsed.clamp(0.0, 100.0);
                                    }),
                                  ),
                                  _rangeWarning(double.tryParse(_discountCtrl.text) ?? 0.0, _discountRate),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Totals card ──────────────────────────────────
                      CreateQuoteTotalsCard(
                        subtotal: _subtotal,
                        taxAmount: _taxAmount,
                        discountAmount: _discountAmount,
                        itemTaxByName: _itemTaxExtraByName,
                        itemDiscountByName: _itemDiscountExtraByName,
                        total: _total,
                        taxRate: _taxRate,
                        discountRate: _discountRate,
                        taxName: _taxNameCtrl.text.trim(),
                        discountName: _discountNameCtrl.text.trim(),
                        taxEnabled: _taxEnabled,
                        discountEnabled: _discountEnabled,
                        currencySymbol: _currencyPrefix,
                        isDark: isDark,
                        accent: _accent,
                      ),
                      const SizedBox(height: 20),

                      // ── Notes ────────────────────────────────────────
                      _sectionHeader('Additional Info', icon: Icons.notes_rounded),
                      CreateQuoteField(
                        ctrl: _notesCtrl,
                        label: 'Notes',
                        hint: 'e.g. This quote is valid for 14 days...',
                        icon: Icons.note_rounded,
                        max: 250,
                        maxLines: 3,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_notesCtrl.text.length, 250),
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
                            _isEditing ? 'Save Changes' : 'Save Quote',
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
