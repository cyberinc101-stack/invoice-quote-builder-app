// quote_editable_canvas_screen.dart
// lib/screens/saved_invoice_details_section/quote_editable_canvas_screen.dart
//
// CRASH SAFETY PASS (this update): _loadStackTrace was captured in
// _loadData()'s catch block but never read anywhere — it only ever went
// to debugPrint (console-only). _buildErrorScreen now includes a
// collapsible "Technical details" section (ExpansionTile) that renders
// the full stack trace via SelectableText, so a real load failure is
// actually diagnosable in production instead of the trace being silently
// discarded. Identical fix applied to invoice_editable_canvas_screen.dart
// and receipt_editable_canvas_screen.dart.
//
// Quote counterpart to InvoiceEditableCanvasScreen — same tap-to-edit
// pattern, mirrored field-for-field against QuoteData/QuoteProvider:
//   invoiceNumber -> quoteNumber
//   dueDate       -> expiryDate ("Expires" instead of "Due")
//   InvoiceColor  -> QuoteColor
//   "INVOICE"     -> "QUOTE"
//
// Barcode/QR intentionally NOT editable here — same reasoning as the
// invoice canvas: it encodes real functional data, not decorative text.
//
// KNOWN LIMITATION (same as invoice canvas): logo reposition/zoom/shape is
// session-only — QuoteData only stores businessLogoPath, not
// offset/scale/shape.
//
// Pattern: loadSavedQuote(id) on open seeds QuoteProvider.quoteData with
// this saved quote's data. All edits go through the provider's existing
// update*() methods (live, so totals update instantly). Nothing is written
// back into savedQuotes until Save is tapped (updateSavedQuote(id)).
// Back/cancel discards via resetQuoteData() without ever calling
// updateSavedQuote(), so the saved record on disk is untouched.
//
// FIX (earlier pass): loadSavedQuote() calls notifyListeners() on
// QuoteProvider, and calling it synchronously inside initState() is
// illegal mid-build in Flutter — that caused "setState() or
// markNeedsBuild() called during build." and the resulting blank/crashed
// screen. The provider load is now deferred to a post-frame callback via
// _loadData(), and a new `_loading` flag keeps build() from touching the
// TextEditingControllers until that load completes. The existing
// try/catch (-> _loadError) is unchanged and still surfaces a real error
// screen for any other load failure.
//
// FIX (earlier pass): SharedLogoPicker is now used in compact mode (just
// the tappable logo box, no inline chip row) instead of being force-
// wrapped in a fixed-width SizedBox — cleaner header, no more guessing
// at a width. Also added cursorColor/cursorHeight/cursorWidth to
// _EditableText's TextField, since the previously auto-calculated cursor
// could render oversized/mispositioned relative to these fields' small
// custom font sizes.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/quote_provider.dart';
import '../../models/quote_data.dart';
import '../../models/invoice_data.dart' show LineItem;
import '../../widgets/shared_logo_picker.dart';

const _kDateFmt = 'd MMM yyyy';

const _kPresetColors = [
  ('Ocean Blue', QuoteColor.blue),
  ('Slate', QuoteColor.black),
  ('Emerald', QuoteColor.green),
  ('Crimson', QuoteColor.red),
  ('Violet', QuoteColor.purple),
  ('Amber', QuoteColor.orange),
  ('Teal', QuoteColor.teal),
  ('Indigo', QuoteColor.indigo),
];

Color _accentFromScheme(QuoteColor scheme) {
  const map = {
    QuoteColor.blue: Color(0xFF1565C0),
    QuoteColor.green: Color(0xFF2E7D32),
    QuoteColor.purple: Color(0xFF6A1B9A),
    QuoteColor.orange: Color(0xFFE65100),
    QuoteColor.red: Color(0xFFC62828),
    QuoteColor.teal: Color(0xFF00695C),
    QuoteColor.black: Color(0xFF212121),
    QuoteColor.indigo: Color(0xFF283593),
  };
  return map[scheme] ?? const Color(0xFF6A1B9A);
}

String _symbolFor(String code) {
  const symbols = {
    'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥',
    'AUD': 'A\$', 'CAD': 'C\$', 'NZD': 'NZ\$', 'CHF': 'Fr',
    'CNY': '¥', 'INR': '₹', 'KRW': '₩', 'SGD': 'S\$',
    'HKD': 'HK\$', 'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr',
    'MXN': '\$', 'BRL': 'R\$', 'ZAR': 'R', 'AED': 'د.إ',
  };
  return symbols[code] ?? code;
}

class QuoteEditableCanvasScreen extends StatefulWidget {
  final String quoteId;
  const QuoteEditableCanvasScreen({super.key, required this.quoteId});

  @override
  State<QuoteEditableCanvasScreen> createState() =>
      _QuoteEditableCanvasScreenState();
}

class _QuoteEditableCanvasScreenState
    extends State<QuoteEditableCanvasScreen> {
  Object? _loadError;
  StackTrace? _loadStackTrace;
  bool _initialized = false;

  // build() must not touch the controllers below until the deferred
  // load in _loadData() has actually run and created them.
  bool _loading = true;

  late TextEditingController _businessNameCtrl;
  late TextEditingController _businessEmailCtrl;
  late TextEditingController _businessPhoneCtrl;
  late TextEditingController _businessAddressCtrl;

  late TextEditingController _clientNameCtrl;
  late TextEditingController _clientEmailCtrl;
  late TextEditingController _clientPhoneCtrl;
  late TextEditingController _clientAddressCtrl;

  late TextEditingController _quoteNumberCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _notesCtrl;

  late DateTime _issueDate;
  late DateTime _expiryDate;

  late List<LineItem> _items;
  final List<TextEditingController> _descCtrl = [];
  final List<TextEditingController> _qtyCtrl = [];
  final List<TextEditingController> _priceCtrl = [];

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // Defer the provider load until after the first frame finishes
    // building, instead of calling it synchronously here.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    try {
      final provider = context.read<QuoteProvider>();
      provider.loadSavedQuote(widget.quoteId);
      final data = provider.quoteData;

      _businessNameCtrl = TextEditingController(text: data.businessName);
      _businessEmailCtrl = TextEditingController(text: data.businessEmail);
      _businessPhoneCtrl = TextEditingController(text: data.businessPhone);
      _businessAddressCtrl =
          TextEditingController(text: data.businessAddress);

      _clientNameCtrl = TextEditingController(text: data.clientName);
      _clientEmailCtrl = TextEditingController(text: data.clientEmail);
      _clientPhoneCtrl = TextEditingController(text: data.clientPhone);
      _clientAddressCtrl = TextEditingController(text: data.clientAddress);

      _quoteNumberCtrl = TextEditingController(text: data.quoteNumber);
      _taxCtrl = TextEditingController(
          text: data.taxRate == 0 ? '0' : '${data.taxRate}');
      _discountCtrl = TextEditingController(
          text: data.discountRate == 0 ? '0' : '${data.discountRate}');
      _notesCtrl = TextEditingController(text: data.notes);

      _issueDate =
          DateFormat(_kDateFmt).tryParse(data.issueDate) ?? DateTime.now();
      _expiryDate = DateFormat(_kDateFmt).tryParse(data.expiryDate) ??
          DateTime.now().add(const Duration(days: 30));

      _items = data.lineItems.map((i) => i.copyWith()).toList();
      if (_items.isEmpty) _items.add(LineItem());
      for (final item in _items) {
        _descCtrl.add(TextEditingController(text: item.description));
        _qtyCtrl.add(TextEditingController(
            text: item.quantity == 1.0 ? '1' : '${item.quantity}'));
        _priceCtrl.add(TextEditingController(
            text: item.unitPrice == 0.0 ? '0' : '${item.unitPrice}'));
      }

      _initialized = true;
    } catch (e, st) {
      debugPrint('QuoteEditableCanvasScreen load failed: $e\n$st');
      _loadError = e;
      _loadStackTrace = st;
    }
    // Flip _loading off (and trigger a rebuild) now that the load
    // attempt has finished, whichever way it went.
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    if (_initialized) {
      for (final c in [
        _businessNameCtrl, _businessEmailCtrl, _businessPhoneCtrl,
        _businessAddressCtrl, _clientNameCtrl, _clientEmailCtrl,
        _clientPhoneCtrl, _clientAddressCtrl, _quoteNumberCtrl,
        _taxCtrl, _discountCtrl, _notesCtrl,
      ]) {
        c.dispose();
      }
      for (final cList in [_descCtrl, _qtyCtrl, _priceCtrl]) {
        for (final c in cList) c.dispose();
      }
    }
    super.dispose();
  }

  QuoteProvider get _provider => context.read<QuoteProvider>();

  void _pushLineItemsToProvider() {
    for (int i = 0; i < _items.length; i++) {
      _items[i]
        ..description = _descCtrl[i].text
        ..quantity = double.tryParse(_qtyCtrl[i].text) ?? 1
        ..unitPrice = double.tryParse(_priceCtrl[i].text) ?? 0;
      _provider.updateLineItem(i, _items[i]);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(LineItem());
      _descCtrl.add(TextEditingController());
      _qtyCtrl.add(TextEditingController(text: '1'));
      _priceCtrl.add(TextEditingController(text: '0'));
    });
    _provider.addLineItem(_items.last);
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
    _provider.removeLineItem(index);
  }

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry ? _expiryDate : _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isExpiry) {
        _expiryDate = picked;
      } else {
        _issueDate = picked;
      }
    });
    _provider.updateQuoteDetails(
      issueDate: DateFormat(_kDateFmt).format(_issueDate),
      expiryDate: DateFormat(_kDateFmt).format(_expiryDate),
    );
  }

  Future<void> _handleSave() async {
    _pushLineItemsToProvider();
    _provider.updateBusinessInfo(
      businessName: _businessNameCtrl.text.trim(),
      businessEmail: _businessEmailCtrl.text.trim(),
      businessPhone: _businessPhoneCtrl.text.trim(),
      businessAddress: _businessAddressCtrl.text.trim(),
    );
    _provider.updateClientInfo(
      clientName: _clientNameCtrl.text.trim(),
      clientEmail: _clientEmailCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim(),
      clientAddress: _clientAddressCtrl.text.trim(),
    );
    _provider.updateQuoteDetails(
      quoteNumber: _quoteNumberCtrl.text.trim(),
      issueDate: DateFormat(_kDateFmt).format(_issueDate),
      expiryDate: DateFormat(_kDateFmt).format(_expiryDate),
      notes: _notesCtrl.text.trim(),
      taxRate: double.tryParse(_taxCtrl.text) ?? 0,
      discountRate: double.tryParse(_discountCtrl.text) ?? 0,
    );

    _provider.updateSavedQuote(widget.quoteId);
    _saved = true;
    _provider.resetQuoteData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Quote updated'),
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.pop(context, true);
  }

  Future<void> _handleBack() async {
    if (_saved) {
      Navigator.pop(context, false);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard changes?'),
        content: const Text('Any edits made here will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (discard != true) return;
    _provider.resetQuoteData();
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Edit Quote'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFE53935)),
              const SizedBox(height: 16),
              const Text(
                "Couldn't load this quote for editing",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SelectableText(
                '$_loadError',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              // Captured in _loadData()'s catch block — previously
              // discarded after debugPrint. Collapsed by default; expanding
              // gives a copy-pasteable trace for a bug report.
              if (_loadStackTrace != null) ...[
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('Technical details',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SelectableText(
                          '$_loadStackTrace',
                          style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // While the deferred load hasn't finished yet, show a spinner
    // instead of touching controllers/data that don't exist yet.
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return _buildErrorScreen(context);
    }

    final data = context.watch<QuoteProvider>().quoteData;
    final accent = _accentFromScheme(data.colorScheme);
    final symbol = _symbolFor(data.currency);
    final fmt = NumberFormat('#,##0.00');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: const Text('Edit Quote'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _handleBack,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _handleSave,
                icon: Icon(Icons.check_rounded, size: 18, color: accent),
                label: Text('Save',
                    style:
                        TextStyle(color: accent, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AccentColorRow(
                selected: data.colorScheme,
                onChanged: (c) => _provider.updateColorScheme(c),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      color: accent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SharedLogoPicker used in compact mode — just
                          // the tappable logo box, no inline chip row, no
                          // need to guess a wrapping SizedBox width. Tap
                          // still opens the full bottom sheet (Gallery/
                          // Camera/Reposition/Remove).
                          SharedLogoPicker(
                            logoPath: data.businessLogoPath,
                            logoOffset: Offset.zero,
                            logoScale: 1.0,
                            logoShape: LogoShape.roundedSquare,
                            accent: Colors.white,
                            compact: true,
                            compactBoxSize: 64,
                            onChanged: (path, offset, scale, shape) {
                              _provider.updateBusinessInfo(
                                  businessLogoPath: path ?? '');
                            },
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _EditableText(
                                  controller: _businessNameCtrl,
                                  hint: 'Business name',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800),
                                  onChanged: (v) =>
                                      _provider.updateBusinessInfo(businessName: v),
                                ),
                                _EditableText(
                                  controller: _businessEmailCtrl,
                                  hint: 'Business email',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12),
                                  onChanged: (v) => _provider
                                      .updateBusinessInfo(businessEmail: v),
                                ),
                                _EditableText(
                                  controller: _businessPhoneCtrl,
                                  hint: 'Business phone',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12),
                                  onChanged: (v) => _provider
                                      .updateBusinessInfo(businessPhone: v),
                                ),
                                _EditableText(
                                  controller: _businessAddressCtrl,
                                  hint: 'Business address',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12),
                                  onChanged: (v) => _provider
                                      .updateBusinessInfo(businessAddress: v),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('QUOTE',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1)),
                              SizedBox(
                                width: 110,
                                child: _EditableText(
                                  controller: _quoteNumberCtrl,
                                  hint: '#',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                  onChanged: (v) => _provider
                                      .updateQuoteDetails(quoteNumber: v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Bill To', accent),
                                const SizedBox(height: 4),
                                _EditableText(
                                  controller: _clientNameCtrl,
                                  hint: 'Client name',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700),
                                  onChanged: (v) =>
                                      _provider.updateClientInfo(clientName: v),
                                ),
                                _EditableText(
                                  controller: _clientEmailCtrl,
                                  hint: 'Client email',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600),
                                  onChanged: (v) =>
                                      _provider.updateClientInfo(clientEmail: v),
                                ),
                                _EditableText(
                                  controller: _clientPhoneCtrl,
                                  hint: 'Client phone',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600),
                                  onChanged: (v) =>
                                      _provider.updateClientInfo(clientPhone: v),
                                ),
                                _EditableText(
                                  controller: _clientAddressCtrl,
                                  hint: 'Client address',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600),
                                  onChanged: (v) => _provider
                                      .updateClientInfo(clientAddress: v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _dateChip('Issued', _issueDate, accent,
                                  () => _pickDate(false)),
                              const SizedBox(height: 6),
                              _dateChip('Expires', _expiryDate, accent,
                                  () => _pickDate(true)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: Text('Description',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: accent))),
                          SizedBox(
                              width: 44,
                              child: Text('Qty',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: accent))),
                          SizedBox(
                              width: 64,
                              child: Text('Price',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: accent))),
                          SizedBox(
                              width: 64,
                              child: Text('Total',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: accent))),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),
                    ...List.generate(_items.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _EditableText(
                                controller: _descCtrl[i],
                                hint: 'Item description',
                                style: const TextStyle(fontSize: 12),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: _EditableText(
                                controller: _qtyCtrl[i],
                                hint: '1',
                                textAlign: TextAlign.right,
                                keyboard: const TextInputType.numberWithOptions(
                                    decimal: true),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: _EditableText(
                                controller: _priceCtrl[i],
                                hint: '0.00',
                                textAlign: TextAlign.right,
                                keyboard: const TextInputType.numberWithOptions(
                                    decimal: true),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Text(
                                '$symbol${fmt.format((double.tryParse(_qtyCtrl[i].text) ?? 0) * (double.tryParse(_priceCtrl[i].text) ?? 0))}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              child: _items.length > 1
                                  ? IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.close_rounded,
                                          size: 16, color: Colors.redAccent),
                                      onPressed: () => _removeItem(i),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                      child: GestureDetector(
                        onTap: _addItem,
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, size: 16, color: accent),
                            const SizedBox(width: 4),
                            Text('Add item',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: accent,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Divider(height: 1, color: accent.withValues(alpha: 0.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Notes', accent),
                                const SizedBox(height: 4),
                                _EditableText(
                                  controller: _notesCtrl,
                                  hint: 'Terms, validity note...',
                                  maxLines: 3,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600),
                                  onChanged: (v) =>
                                      _provider.updateQuoteDetails(notes: v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _totalRow('Subtotal',
                                  '$symbol${fmt.format(data.subtotal)}'),
                              Row(
                                children: [
                                  Text('Tax ',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600)),
                                  SizedBox(
                                    width: 34,
                                    child: _EditableText(
                                      controller: _taxCtrl,
                                      hint: '0',
                                      textAlign: TextAlign.right,
                                      keyboard:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                      onChanged: (v) =>
                                          _provider.updateQuoteDetails(
                                              taxRate: double.tryParse(v) ?? 0),
                                    ),
                                  ),
                                  Text('%  $symbol${fmt.format(data.taxAmount)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Discount ',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600)),
                                  SizedBox(
                                    width: 34,
                                    child: _EditableText(
                                      controller: _discountCtrl,
                                      hint: '0',
                                      textAlign: TextAlign.right,
                                      keyboard:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                      onChanged: (v) =>
                                          _provider.updateQuoteDetails(
                                              discountRate:
                                                  double.tryParse(v) ?? 0),
                                    ),
                                  ),
                                  Text(
                                      '%  -$symbol${fmt.format(data.discountAmount)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(9)),
                                child: Text(
                                    'Total  $symbol${fmt.format(data.grandTotal)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color accent) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: accent),
      );

  Widget _dateChip(String label, DateTime date, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  ',
              style:
                  TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600)),
          Text(DateFormat(_kDateFmt).format(date), style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Icon(Icons.edit_calendar_rounded, size: 12, color: accent.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text('$label  $value',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      );
}

class _AccentColorRow extends StatelessWidget {
  final QuoteColor selected;
  final ValueChanged<QuoteColor> onChanged;
  const _AccentColorRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _kPresetColors.map((c) {
          final isActive = c.$2 == selected;
          final color = _accentFromScheme(c.$2);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(c.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isActive ? 48 : 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: isActive
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EditableText extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final TextInputType? keyboard;
  final ValueChanged<String> onChanged;

  const _EditableText({
    required this.controller,
    required this.hint,
    required this.style,
    required this.onChanged,
    this.textAlign = TextAlign.left,
    this.maxLines = 1,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      keyboardType: keyboard,
      onChanged: onChanged,
      // Pin cursor size/color explicitly instead of letting Flutter
      // auto-calculate it. These fields use small custom font sizes with
      // isCollapsed:true; an auto-sized cursor can end up oversized/
      // mispositioned relative to the tiny text.
      cursorColor: style.color ?? Colors.black87,
      cursorHeight: (style.fontSize ?? 14) * 1.15,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        hintText: hint,
        hintStyle: style.copyWith(color: style.color?.withValues(alpha: 0.4) ?? Colors.grey),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
      ),
    );
  }
}
