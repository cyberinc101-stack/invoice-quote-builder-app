// lib/screens/create_quote_section/create_quote_bottom_sheet.dart
//
// NEW FILE — QUOTE LIBRARY RESTRUCTURE PASS: mirrors
// create_invoice_bottom_sheet.dart (CreateInvoiceBottomSheet) exactly.
// Holds the entire quote-editing form (quote number, dates, currency,
// customer override, Saved Item Sets panel, line items, tax/discount,
// totals, notes) that previously lived inline in
// quote_editor_screen.dart's _createQuoteStep(). Shown as a bottom sheet
// (DraggableScrollableSheet) from the new library screen in
// create_quote_section/step_create_quote.dart, instead of being a
// step's only content.
//
// Behaviorally this mirrors CreateInvoiceBottomSheet: same controllers,
// same items/dates/currency/tax/discount state, same validation rules,
// same defensive re-sync of controller text into _items before building
// the final QuoteData (see _save() below). The differences, matching
// what Quote already needed:
//   - It doesn't talk to QuoteProvider directly. Instead it builds a
//     plain QuoteData and hands it back wrapped in a SavedQuoteDraft via
//     widget.onSaved() — the parent library screen
//     (step_create_quote.dart) owns persisting the draft library and the
//     outer QuoteEditorScreen owns syncing the *selected* draft into
//     QuoteProvider when "Next" is pressed past the Create Quote step.
//   - It gained a "Draft Label" field at the top (optional) so a draft
//     can be given a name for the library card independent of whatever
//     client name or quote number is typed below — see
//     SavedQuoteDraft.displayName's fallback chain in quote_data.dart.
//   - Uses QuoteField/QuoteDateField/QuoteItemCard/QuoteTotalsCard/
//     quoteSectionHeader from quote_edit_widgets.dart (Quote's existing
//     shared widgets) rather than Invoice's Create* equivalents.
//   - Uses QuoteSavedItemSets (quote_saved_items_widgets.dart) instead
//     of CreateInvoiceSavedItemSets — a SEPARATE Quote-only saved-sets
//     library, see that file's doc comment.
//   - There's no Back/Continue bar — a single "Save Quote"/"Save
//     Changes" button sits at the bottom of the sheet, matching
//     CreateInvoiceBottomSheet's own pattern.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../models/invoice_data.dart' show LineItem;
import '../../models/quote_data.dart';
import '../../providers/quote_provider.dart';
import 'quote_edit_widgets.dart';
import 'quote_step_customer.dart' show QuoteClient;
import 'quote_step_template.dart' show QuoteTemplate;
import 'quote_saved_items_widgets.dart';

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

  // Draft label — shown on the library card. Optional; falls back to
  // client name / quote number / "Untitled Draft" per
  // SavedQuoteDraft.displayName.
  late TextEditingController _nameCtrl;

  // Controllers
  late TextEditingController _quoteNumberCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;

  // Client override (if no client passed from the Customer step)
  late TextEditingController _custNameCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;
  late TextEditingController _custAddressCtrl;

  // Items
  late List<LineItem> _items;
  final List<TextEditingController> _descCtrl = [];
  final List<TextEditingController> _qtyCtrl = [];
  final List<TextEditingController> _priceCtrl = [];

  // Dates
  String _issueDate = '';
  String _expiryDate = '';

  // Currency — free-text code + symbol + Code/Symbol/Both display mode.
  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code'; // 'code' | 'symbol' | 'both'

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
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    final tsShort = ts
        .toString()
        .substring((ts.toString().length - 6).clamp(0, ts.toString().length));

    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');

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

    // Client override fields — the client picked on the Customer step
    // wins; otherwise fall back to whatever's stored on the draft being
    // edited.
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

    _issueDate = (existingData != null && existingData.issueDate.isNotEmpty)
        ? existingData.issueDate
        : DateFormat(_dateFmt).format(now);
    _expiryDate = (existingData != null && existingData.expiryDate.isNotEmpty)
        ? existingData.expiryDate
        : DateFormat(_dateFmt).format(now.add(const Duration(days: 14)));

    // Line items — restore from the draft if present, else start with one
    // blank item.
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
      _quoteNumberCtrl,
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
      _nameCtrl, _quoteNumberCtrl, _notesCtrl, _taxCtrl,
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
  // Saved item sets — quick add via QuoteSavedItemSets
  // (quote_saved_items_widgets.dart), a SEPARATE Quote-only library from
  // Invoice's own saved item sets.
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
    if (_quoteNumberCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a quote number.');
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

    if (_taxRate < 0 || _taxRate > 100) {
      _showValidationError('Tax rate must be between 0 and 100%.');
      return false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Save — validates, flushes controller text into _items, builds a
  // QuoteData, wraps it in a SavedQuoteDraft (preserving id/createdAt when
  // editing), hands it to the parent via onSaved(), and closes the sheet.
  // ---------------------------------------------------------------------------
  void _save() {
    if (!_validateForm()) return;

    for (int i = 0; i < _items.length; i++) {
      _items[i]
        ..description = _descCtrl[i].text.trim()
        ..quantity = double.tryParse(_qtyCtrl[i].text) ?? 1
        ..unitPrice = double.tryParse(_priceCtrl[i].text) ?? 0;
    }

    // Preserve everything not editable on this sheet (font/logo/colour/
    // enabledFields/etc.) from whatever's already on the provider, same
    // way _syncSelectedToProvider() does for Invoice.
    final current = context.read<QuoteProvider>().quoteData;

    final data = current.copyWith(
      clientName: _custNameCtrl.text.trim(),
      clientEmail: _custEmailCtrl.text.trim(),
      clientPhone: _custPhoneCtrl.text.trim(),
      clientAddress: _custAddressCtrl.text.trim(),
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
    );

    final now = DateTime.now();
    final draft = SavedQuoteDraft(
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

  // ── Context banner (template / client selection) — mirrors
  // CreateInvoiceContextBanner (create_invoice_form_widgets.dart). Kept
  // private here since it's only used by this sheet.
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

  // ── Currency display mode selector — mirrors
  // _QuoteCurrencyDisplayModeSelector (formerly private to
  // quote_editor_screen.dart, now lives here since this sheet is its
  // only user).
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

                      // ── Draft label ──────────────────────────────────
                      QuoteField(
                        ctrl: _nameCtrl,
                        label: 'Draft Label (Optional)',
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

                      // ── Quote number ──────────────────────────────────
                      quoteSectionHeader(context, 'Quote Details', _accent,
                          icon: Icons.request_quote_rounded),
                      QuoteField(
                        ctrl: _quoteNumberCtrl,
                        label: 'Quote Number',
                        accent: _accent,
                        icon: Icons.tag_rounded,
                        max: _quoteNumberMax,
                        required: true,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_quoteNumberCtrl.text.length, _quoteNumberMax),
                      const SizedBox(height: 12),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: QuoteDateField(
                              label: 'Issue Date',
                              value: _issueDate,
                              accent: _accent,
                              onTap: () => _pickDate(isExpiry: false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuoteDateField(
                              label: 'Valid Until',
                              value: _expiryDate,
                              accent: _accent,
                              onTap: () => _pickDate(isExpiry: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Currency ─────────────────────────────────────
                      quoteSectionHeader(context, 'Currency', _accent,
                          icon: Icons.attach_money_rounded),
                      QuoteField(
                        ctrl: _currencyCodeCtrl,
                        label: 'Currency Code',
                        accent: _accent,
                        icon: Icons.attach_money_rounded,
                        max: 6,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_currencyCodeCtrl.text.length, 6),
                      const SizedBox(height: 12),

                      _currencyDisplayModeSelector(),
                      if (_currencyDisplayMode != 'code') ...[
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _currencySymbolCtrl,
                          label: 'Currency Symbol',
                          accent: _accent,
                          icon: Icons.currency_exchange_rounded,
                          max: 6,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_currencySymbolCtrl.text.length, 6),
                      ],
                      const SizedBox(height: 20),

                      // ── Client (if none selected on the Customer step) ─
                      if (widget.selectedClient == null) ...[
                        quoteSectionHeader(context, 'Client Details', _accent,
                            icon: Icons.person_rounded),
                        QuoteField(
                          ctrl: _custNameCtrl,
                          label: 'Client Name',
                          accent: _accent,
                          icon: Icons.person_rounded,
                          max: 100,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _custEmailCtrl,
                          label: 'Client Email',
                          accent: _accent,
                          icon: Icons.email_rounded,
                          max: 100,
                          keyboard: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
                          ctrl: _custPhoneCtrl,
                          label: 'Client Phone',
                          accent: _accent,
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        QuoteField(
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

                      // ── Saved item sets (quick-add) — Quote-only
                      // library, separate from Invoice's ──────────────
                      QuoteSavedItemSets(
                        getCurrentItems: _getCurrentItemsSnapshot,
                        onQuickAdd: _quickAddItems,
                        currencySymbol: _currencyPrefix,
                      ),
                      const SizedBox(height: 20),

                      // ── Line items ───────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: quoteSectionHeader(
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
                                    ? const Color(0xFF2A0D33)
                                    : const Color(0xFFF3E5F5),
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
                        return QuoteItemCard(
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
                            child: QuoteField(
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
                                final parsed = double.tryParse(v) ?? 0.0;
                                _taxRate = parsed.clamp(0.0, 100.0);
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuoteField(
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
                                final parsed = double.tryParse(v) ?? 0.0;
                                _discountRate = parsed.clamp(0.0, 100.0);
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Totals card ──────────────────────────────────
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

                      // ── Notes ────────────────────────────────────────
                      quoteSectionHeader(context, 'Additional Info', _accent,
                          icon: Icons.notes_rounded),
                      QuoteField(
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
