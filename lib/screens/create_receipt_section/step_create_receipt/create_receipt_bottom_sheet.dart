// lib/screens/create_receipt_section/step_create_receipt/create_receipt_bottom_sheet.dart
//
// SAVED-ITEMS CAP ENFORCEMENT PASS (this update): _saveDraftItem() now
// checks the saved single-item library against
// kMaxSavedReceiptLineItems (create_receipt_saved_line_items_widgets.dart,
// 200 — matching Quote's/Invoice's own saved-line-item cap) before
// adding a new entry — previously the constant existed but nothing ever
// compared the library's length against it. When already at the cap,
// the item is NOT added to the saved library (and therefore not added
// to the receipt either, since it's only ever added as a saved-linked
// copy here), and a snackbar explains why. The typed draft is left
// exactly as entered so nothing is lost — same "block and explain,
// don't silently drop" pattern used for the equivalent fix on
// create_quote_bottom_sheet.dart and create_invoice_bottom_sheet.dart.
// Toggling inclusion of an ALREADY-saved item (_toggleSavedLineItem) is
// unaffected — that never creates a new saved entry, so the cap doesn't
// apply there.
//
// TAX-BASE FIX (earlier): _taxAmount was computing tax on the raw
// _subtotal (before the whole-receipt discount was subtracted) —
// `_subtotal * _taxRate / 100`. ReceiptData.taxAmount (the model that
// actually gets saved and rendered everywhere else — thermal preview,
// A4 layout, PDF service) has always computed it on the DISCOUNTED
// subtotal instead: `(subtotal - discountAmount) * taxRate / 100`.
// Fixed to match ReceiptData.taxAmount exactly.
//
// CREATE-RECEIPT UI PARITY PASS (earlier): rebuilt to match Quote's
// create_quote_bottom_sheet.dart structure — Container Name (required) +
// Container Logo section, a single-draft item card (with Unit dropdown)
// backed by a real "Saved Items" single-item library with inclusion
// checkboxes, a toggle-gated whole-receipt Tax/Discount with its own
// name field, and a live Totals card.
//
// PER-ITEM TAX/DISCOUNT PASS (earlier): the draft item card
// (CreateReceiptItemCard) supports per-item Tax/Discount toggle+sign+
// name, same as Quote's — see receipt_data.dart's PER-ITEM TAX/DISCOUNT
// PASS. This sheet's own live totals (_itemTaxExtra/_itemDiscountExtra/
// _itemTaxExtraByName/_itemDiscountExtraByName below) mirror that exact
// same math over the in-progress _items list.
//
// Deliberately LEFT OUT / DIFFERENT FROM QUOTE (flagged scope calls):
//   - Structured 6-field client address (Quote/Invoice use AddressInfo).
//     ReceiptData.clientAddress is a single free-text string.
//   - PO/Reference Number and Amount Due override — receipt-inappropriate
//     concepts.
//
// Payment Method (ReceiptPaymentMethodPicker) is Receipt-specific and
// kept exactly where it was.
//
// Deliberately still doesn't talk to ReceiptProvider for line-item math
// — this sheet builds a ReceiptData from scratch off its own state,
// copyWith-ing over whatever currently exists on the provider only for
// the fields this sheet doesn't own (business info, logo, thermal,
// social, font, colour, layoutTemplateId, paperFormat).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../../models/invoice_data.dart' show LineItem;
import '../../../models/receipt_data.dart';
import '../../../providers/receipt_provider.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../receipt_edit_widgets.dart' show ReceiptPaymentMethodPicker;
import '../step_customer/receipt_step_customer.dart' show ReceiptClient;
import '../step_templates/receipt_step_template.dart' show ReceiptTemplate;
import 'create_receipt_form_widgets.dart';
import 'create_receipt_item_widgets.dart';
import 'create_receipt_saved_line_items_widgets.dart';

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
  String? _containerLogoPath;
  Offset _containerLogoOffset = Offset.zero;
  double _containerLogoScale = 1.0;
  LogoShape _containerLogoShape = LogoShape.roundedSquare;
  bool _containerLogoShowInitial = true;
  String _containerLogoInitialLetter = '';

  late TextEditingController _receiptNumberCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _taxNameCtrl;
  late TextEditingController _discountNameCtrl;

  late TextEditingController _custNameCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;
  late TextEditingController _custAddressCtrl;

  // Committed line items — every entry here is already final (added via
  // the draft card's Save Item button, or via toggling a Saved-items
  // checkbox).
  late List<LineItem> _items;

  // The one item currently being typed under "New", not yet part of
  // _items — mirrors Quote's/Invoice's single-draft-item pattern.
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
  List<SavedReceiptLineItem> _savedLineItems = [];

  String _paymentDate = '';

  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code';

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  double _taxRate = 0.0;
  double _discountRate = 0.0;

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

  double get _amountPaid =>
      _subtotal + _taxAmount - _discountAmount + _itemTaxExtra - _itemDiscountExtra;

  Set<String> get _includedSavedIds =>
      _items.map((i) => i.sourceSavedId).whereType<String>().toSet();

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

    _containerLogoPath = widget.existing?.logoPath;
    _containerLogoOffset = Offset(
      widget.existing?.logoOffsetDx ?? 0.0,
      widget.existing?.logoOffsetDy ?? 0.0,
    );
    _containerLogoScale = widget.existing?.logoScale ?? 1.0;
    _containerLogoShape = logoShapeFromString(widget.existing?.logoShape ?? 'roundedSquare');
    _containerLogoShowInitial = widget.existing?.logoShowInitial ?? true;
    _containerLogoInitialLetter = widget.existing?.logoInitialLetter ?? '';

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
    _taxEnabled = existingData?.taxEnabled ?? true;
    _discountEnabled = existingData?.discountEnabled ?? true;
    _taxNameCtrl = TextEditingController(text: existingData?.taxName ?? '');
    _discountNameCtrl = TextEditingController(text: existingData?.discountName ?? '');
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
      _receiptNumberCtrl,
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
    final items = await loadSavedReceiptLineItems();
    if (!mounted) return;
    setState(() {
      _savedLineItems = items;
      _savedLibraryLoading = false;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _receiptNumberCtrl, _notesCtrl, _taxCtrl,
      _discountCtrl, _taxNameCtrl, _discountNameCtrl,
      _custNameCtrl, _custEmailCtrl,
      _custPhoneCtrl, _custAddressCtrl,
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
  // Commit the draft card — adds it to the receipt's real line items AND
  // saves it into the single-item library, then resets the draft card.
  //
  // SAVED-ITEMS CAP ENFORCEMENT PASS: guards the saved-library side of
  // this action against kMaxSavedReceiptLineItems (200) — if the
  // library is already full, the new item is NOT saved to the library
  // (and therefore not added to _items either, since it's only ever
  // added as a saved-linked copy here), and a snackbar explains why.
  // The typed draft is left untouched so nothing the person entered is
  // lost.
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
    // library entry — kMaxSavedReceiptLineItems is exported from
    // create_receipt_saved_line_items_widgets.dart (200).
    if (_savedLineItems.length >= kMaxSavedReceiptLineItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maximum of $kMaxSavedReceiptLineItems saved items reached. Delete one before saving another.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final libraryEntry = SavedReceiptLineItem(
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
    await persistSavedReceiptLineItems(_savedLineItems);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${libraryEntry.displayName}" and added it to this receipt.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSavedLineItem(SavedReceiptLineItem saved) {
    final alreadyIncluded = _items.any((i) => i.sourceSavedId == saved.id);
    setState(() {
      if (alreadyIncluded) {
        _items.removeWhere((i) => i.sourceSavedId == saved.id);
      } else {
        _items.add(saved.item.copyWith(sourceSavedId: saved.id));
      }
    });
  }

  Future<void> _editSavedLineItem(int index, SavedReceiptLineItem updated) async {
    setState(() => _savedLineItems[index] = updated);
    await persistSavedReceiptLineItems(_savedLineItems);
  }

  Future<void> _deleteSavedLineItem(int index) async {
    setState(() => _savedLineItems.removeAt(index));
    await persistSavedReceiptLineItems(_savedLineItems);
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

    if (_receiptNumberCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a receipt number.');
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
  // Save — validates, builds the final ReceiptData by copyWith-ing over
  // whatever's currently on ReceiptProvider (preserving business info/
  // logo/thermal/social/font/colour/layoutTemplateId/paperFormat
  // untouched), wraps it in a SavedReceiptDraft, hands it to the parent
  // via onSaved(), and closes the sheet.
  // ---------------------------------------------------------------------------
  void _save() {
    if (!_validateForm()) return;

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
      taxEnabled: _taxEnabled,
      discountEnabled: _discountEnabled,
      taxName: _taxNameCtrl.text.trim(),
      discountName: _discountNameCtrl.text.trim(),
      paymentMethod: _paymentMethod,
    );

    final now = DateTime.now();
    final draft = SavedReceiptDraft(
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

                      // ── Context banner ───────────────────────────────
                      CreateReceiptContextBanner(
                        template: widget.selectedTemplate,
                        client: widget.selectedClient,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // ── Container name + logo ────────────────────────
                      _sectionHeader('Container Details', icon: Icons.folder_rounded),
                      CreateReceiptField(
                        ctrl: _nameCtrl,
                        label: 'Container Name *',
                        hint: 'e.g. Acme Corp — March 12 sale',
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

                      // ── Receipt number / date ────────────────────────
                      _sectionHeader('Receipt Details', icon: Icons.receipt_rounded),
                      CreateReceiptField(
                        ctrl: _receiptNumberCtrl,
                        label: 'Receipt Number',
                        hint: 'e.g. R-001',
                        icon: Icons.tag_rounded,
                        max: _receiptNumberMax,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_receiptNumberCtrl.text.length, _receiptNumberMax),
                      const SizedBox(height: 12),

                      CreateReceiptDateField(
                        label: 'Payment Date',
                        value: _paymentDate,
                        onTap: _pickDate,
                        accent: _accent,
                      ),
                      const SizedBox(height: 20),

                      // ── Currency ─────────────────────────────────────
                      _sectionHeader('Currency', icon: Icons.attach_money_rounded),
                      CreateReceiptCurrencyDisplayModeSelector(
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
                      CreateReceiptField(
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
                        CreateReceiptField(
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
                        CreateReceiptField(
                          ctrl: _custNameCtrl,
                          label: 'Client Name',
                          hint: 'e.g. Jane Smith',
                          icon: Icons.person_rounded,
                          max: 100,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateReceiptField(
                          ctrl: _custEmailCtrl,
                          label: 'Client Email',
                          hint: 'e.g. jane@acme.com',
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateReceiptField(
                          ctrl: _custPhoneCtrl,
                          label: 'Client Phone',
                          hint: 'e.g. +1 555 000 1234',
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateReceiptField(
                          ctrl: _custAddressCtrl,
                          label: 'Client Address',
                          hint: 'e.g. 123 Queen Street, Auckland',
                          icon: Icons.location_on_rounded,
                          max: 200,
                          maxLines: 2,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Payment Method (Receipt-specific) ─────────────
                      _sectionHeader('Payment Method', icon: Icons.payments_rounded),
                      ReceiptPaymentMethodPicker(
                        selected: _paymentMethod,
                        accent: _accent,
                        onChanged: (m) => setState(() => _paymentMethod = m),
                      ),
                      const SizedBox(height: 20),

                      // ── Line items ───────────────────────────────────
                      _sectionHeader('Line Items', icon: Icons.list_alt_rounded),

                      CreateReceiptItemCard(
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
                          : CreateReceiptSavedLineItemsPanel(
                              library: _savedLineItems,
                              includedIds: _includedSavedIds,
                              currencySymbol: _currencyPrefix,
                              accent: _accent,
                              onToggleInclude: _toggleSavedLineItem,
                              onEdit: _editSavedLineItem,
                              onDelete: _deleteSavedLineItem,
                            ),
                      const SizedBox(height: 12),

                      // Tax / Discount (whole-receipt) — Quote's/Invoice's
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
                                  CreateReceiptField(
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
                                  CreateReceiptField(
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
                                  CreateReceiptField(
                                    ctrl: _discountNameCtrl,
                                    label: 'Discount Name (Optional)',
                                    hint: 'e.g. Loyalty',
                                    icon: Icons.label_outline_rounded,
                                    max: 8,
                                    accent: _accent,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  _counter(_discountNameCtrl.text.length, 8),
                                  const SizedBox(height: 12),
                                  CreateReceiptField(
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
                      CreateReceiptTotalsCard(
                        subtotal: _subtotal,
                        taxAmount: _taxAmount,
                        discountAmount: _discountAmount,
                        amountPaid: _amountPaid,
                        taxRate: _taxRate,
                        discountRate: _discountRate,
                        taxName: _taxNameCtrl.text,
                        discountName: _discountNameCtrl.text,
                        taxEnabled: _taxEnabled,
                        discountEnabled: _discountEnabled,
                        itemTaxByName: _itemTaxExtraByName,
                        itemDiscountByName: _itemDiscountExtraByName,
                        currencySymbol: _currencyPrefix,
                        isDark: isDark,
                        accent: _accent,
                      ),
                      const SizedBox(height: 20),

                      // ── Notes ────────────────────────────────────────
                      _sectionHeader('Additional Info', icon: Icons.notes_rounded),
                      CreateReceiptField(
                        ctrl: _notesCtrl,
                        label: 'Notes',
                        maxLines: 3,
                        max: 500,
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
