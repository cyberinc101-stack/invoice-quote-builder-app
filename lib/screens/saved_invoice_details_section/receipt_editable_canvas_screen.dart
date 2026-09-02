// receipt_editable_canvas_screen.dart
// lib/screens/saved_invoice_details_section/receipt_editable_canvas_screen.dart
//
// CRASH SAFETY PASS (this update): _loadStackTrace was captured in
// _loadData()'s catch block but never read anywhere — it only ever went
// to debugPrint (console-only). _buildErrorScreen now includes a
// collapsible "Technical details" section (ExpansionTile) that renders
// the full stack trace via SelectableText, so a real load failure is
// actually diagnosable in production instead of the trace being silently
// discarded. Identical fix applied to invoice_editable_canvas_screen.dart
// and quote_editable_canvas_screen.dart.
//
// Receipt counterpart to InvoiceEditableCanvasScreen — same tap-to-edit
// pattern, adapted to ReceiptData's shape:
//   invoiceNumber/dueDate -> receiptNumber/paymentDate (single date, no due)
//   InvoiceColor          -> ReceiptColor
//   "INVOICE"             -> "RECEIPT"
//   plus a Payment Method row (Cash/Card/Bank Transfer/Other), since that's
//   a real receipt field with no invoice/quote equivalent.
//
// IMPORTANT DIFFERENCE FROM THE INVOICE/QUOTE CANVASES: ReceiptProvider
// doesn't have granular updateBusinessInfo()/updateClientInfo()/
// addLineItem() methods the way InvoiceProvider/QuoteProvider do — it only
// exposes updateReceiptData(ReceiptData). So every edit here goes through
// a local _update((d) => d.copyWith(...)) helper instead of a matching
// provider method. This is intentional — it means receipt_provider.dart
// didn't need to change at all to support this screen.
//
// Barcode/QR intentionally NOT editable here — same reasoning as the other
// two canvases: it encodes real functional data, not decorative text.
//
// Pattern: loadSavedReceipt(id) on open seeds
// ReceiptProvider.currentReceiptData with this saved receipt's data. Title
// and templateName are captured once at open (from the matching
// SavedReceipt in savedReceipts) since they're not edited on this screen,
// and are re-passed to saveCurrentReceipt() on Save so they aren't lost.
// Save calls saveCurrentReceipt(title, templateName) — because
// _currentReceiptId is already set (via loadSavedReceipt), this updates
// the existing saved entry in place rather than creating a new one. Back/
// cancel discards via resetReceiptData() without ever calling
// saveCurrentReceipt(), so the saved record on disk is untouched.
//
// FIX (earlier pass): TWO fixes on top of the pass before it's guard
// around firstWhere-with-no-orElse (kept below, unchanged):
//
// 1. ROOT CAUSE of the blank-screen crash. loadSavedReceipt() calls
//    notifyListeners() on ReceiptProvider — calling that synchronously
//    inside initState() is illegal mid-build in Flutter (the same bug
//    confirmed via stack trace in the invoice canvas). The provider load
//    is now deferred to a post-frame callback via _loadData(), and a new
//    `_loading` flag keeps build() from touching the TextEditingControllers
//    until that load completes.
// 2. The existing try/catch (-> _loadError) and the
//    `provider.savedReceipts.where(...)` empty-check (replacing the old
//    firstWhere-with-no-orElse) are both unchanged and still surface a
//    real error screen for any load failure.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/receipt_provider.dart';
import '../../models/receipt_data.dart';
import '../../models/invoice_data.dart' show LineItem;
import '../../widgets/shared_logo_picker.dart';

const _kDateFmt = 'd MMM yyyy';

const _kPresetColors = [
  ('Ocean Blue', ReceiptColor.blue),
  ('Slate', ReceiptColor.black),
  ('Emerald', ReceiptColor.green),
  ('Crimson', ReceiptColor.red),
  ('Violet', ReceiptColor.purple),
  ('Amber', ReceiptColor.orange),
  ('Teal', ReceiptColor.teal),
  ('Indigo', ReceiptColor.indigo),
];

const _kPaymentMethods = [
  ('Cash', PaymentMethod.cash, Icons.payments_rounded),
  ('Card', PaymentMethod.card, Icons.credit_card_rounded),
  ('Bank Transfer', PaymentMethod.bankTransfer, Icons.account_balance_rounded),
  ('Other', PaymentMethod.other, Icons.more_horiz_rounded),
];

Color _accentFromScheme(ReceiptColor scheme) {
  const map = {
    ReceiptColor.blue: Color(0xFF1565C0),
    ReceiptColor.green: Color(0xFF2E7D32),
    ReceiptColor.purple: Color(0xFF6A1B9A),
    ReceiptColor.orange: Color(0xFFE65100),
    ReceiptColor.red: Color(0xFFC62828),
    ReceiptColor.teal: Color(0xFF00695C),
    ReceiptColor.black: Color(0xFF212121),
    ReceiptColor.indigo: Color(0xFF283593),
  };
  return map[scheme] ?? const Color(0xFF2E7D32);
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

class ReceiptEditableCanvasScreen extends StatefulWidget {
  final String receiptId;
  const ReceiptEditableCanvasScreen({super.key, required this.receiptId});

  @override
  State<ReceiptEditableCanvasScreen> createState() =>
      _ReceiptEditableCanvasScreenState();
}

class _ReceiptEditableCanvasScreenState
    extends State<ReceiptEditableCanvasScreen> {
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

  late TextEditingController _receiptNumberCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _notesCtrl;

  late DateTime _paymentDate;

  late List<LineItem> _items;
  final List<TextEditingController> _descCtrl = [];
  final List<TextEditingController> _qtyCtrl = [];
  final List<TextEditingController> _priceCtrl = [];

  late String _title;
  late String _templateName;

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
      final provider = context.read<ReceiptProvider>();
      provider.loadSavedReceipt(widget.receiptId);
      final data = provider.currentReceiptData;

      // Guard kept from an earlier pass: was firstWhere with no orElse —
      // threw with nothing on screen if the id wasn't found. Falls back to
      // a thrown StateError (caught below) so the error screen shows a
      // clear message instead of a blank one.
      final matches =
          provider.savedReceipts.where((r) => r.id == widget.receiptId);
      if (matches.isEmpty) {
        throw StateError(
          'No saved receipt found with id "${widget.receiptId}". '
          'It may have been deleted, or the id passed to this screen '
          "doesn't match what's in ReceiptProvider.savedReceipts.",
        );
      }
      final existing = matches.first;
      _title = existing.title;
      _templateName = existing.templateName;

      _businessNameCtrl = TextEditingController(text: data.businessName);
      _businessEmailCtrl = TextEditingController(text: data.businessEmail);
      _businessPhoneCtrl = TextEditingController(text: data.businessPhone);
      _businessAddressCtrl =
          TextEditingController(text: data.businessAddress);

      _clientNameCtrl = TextEditingController(text: data.clientName);
      _clientEmailCtrl = TextEditingController(text: data.clientEmail);
      _clientPhoneCtrl = TextEditingController(text: data.clientPhone);
      _clientAddressCtrl = TextEditingController(text: data.clientAddress);

      _receiptNumberCtrl = TextEditingController(text: data.receiptNumber);
      _taxCtrl = TextEditingController(
          text: data.taxRate == 0 ? '0' : '${data.taxRate}');
      _discountCtrl = TextEditingController(
          text: data.discountRate == 0 ? '0' : '${data.discountRate}');
      _notesCtrl = TextEditingController(text: data.notes);

      _paymentDate =
          DateFormat(_kDateFmt).tryParse(data.paymentDate) ?? DateTime.now();

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
      debugPrint('ReceiptEditableCanvasScreen load failed: $e\n$st');
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
        _clientPhoneCtrl, _clientAddressCtrl, _receiptNumberCtrl,
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

  ReceiptProvider get _provider => context.read<ReceiptProvider>();

  void _update(ReceiptData Function(ReceiptData current) fn) {
    _provider.updateReceiptData(fn(_provider.currentReceiptData));
  }

  void _pushLineItemsToProvider() {
    for (int i = 0; i < _items.length; i++) {
      _items[i]
        ..description = _descCtrl[i].text
        ..quantity = double.tryParse(_qtyCtrl[i].text) ?? 1
        ..unitPrice = double.tryParse(_priceCtrl[i].text) ?? 0;
    }
    _update((d) => d.copyWith(lineItems: List<LineItem>.from(_items)));
  }

  void _addItem() {
    setState(() {
      _items.add(LineItem());
      _descCtrl.add(TextEditingController());
      _qtyCtrl.add(TextEditingController(text: '1'));
      _priceCtrl.add(TextEditingController(text: '0'));
    });
    _update((d) => d.copyWith(lineItems: List<LineItem>.from(_items)));
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
    _update((d) => d.copyWith(lineItems: List<LineItem>.from(_items)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _paymentDate = picked);
    _update((d) => d.copyWith(paymentDate: DateFormat(_kDateFmt).format(_paymentDate)));
  }

  Future<void> _handleSave() async {
    _pushLineItemsToProvider();
    _update((d) => d.copyWith(
          businessName: _businessNameCtrl.text.trim(),
          businessEmail: _businessEmailCtrl.text.trim(),
          businessPhone: _businessPhoneCtrl.text.trim(),
          businessAddress: _businessAddressCtrl.text.trim(),
          clientName: _clientNameCtrl.text.trim(),
          clientEmail: _clientEmailCtrl.text.trim(),
          clientPhone: _clientPhoneCtrl.text.trim(),
          clientAddress: _clientAddressCtrl.text.trim(),
          receiptNumber: _receiptNumberCtrl.text.trim(),
          paymentDate: DateFormat(_kDateFmt).format(_paymentDate),
          notes: _notesCtrl.text.trim(),
          taxRate: double.tryParse(_taxCtrl.text) ?? 0,
          discountRate: double.tryParse(_discountCtrl.text) ?? 0,
        ));

    await _provider.saveCurrentReceipt(title: _title, templateName: _templateName);
    _saved = true;
    _provider.resetReceiptData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Receipt updated'),
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
    _provider.resetReceiptData();
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Edit Receipt'),
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
                "Couldn't load this receipt for editing",
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
              // gives a copy-pasteable trace for a bug report. Also
              // surfaces the specific StateError message from the
              // savedReceipts lookup guard above when that's the cause.
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

    final data = context.watch<ReceiptProvider>().currentReceiptData;
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
          title: const Text('Edit Receipt'),
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
                onChanged: (c) => _update((d) => d.copyWith(colorScheme: c)),
              ),
              const SizedBox(height: 10),
              _PaymentMethodRow(
                selected: data.paymentMethod,
                accent: accent,
                onChanged: (m) => _update((d) => d.copyWith(paymentMethod: m)),
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
                          // Same bounded-width fix as the invoice/quote
                          // canvases — SharedLogoPicker's internal Row uses
                          // Expanded/flex children and needs a finite width
                          // from its parent, which a bare Row child doesn't
                          // provide. Widened from 64 to 110 — 64 overflowed
                          // by 40px in testing.
                          SizedBox(
                            width: 110,
                            child: SharedLogoPicker(
                              logoPath: data.businessLogoPath,
                              logoOffset: Offset.zero,
                              logoScale: 1.0,
                              logoShape: LogoShape.roundedSquare,
                              accent: Colors.white,
                              onChanged: (path, offset, scale, shape) {
                                _update((d) =>
                                    d.copyWith(businessLogoPath: path ?? ''));
                              },
                            ),
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
                                      _update((d) => d.copyWith(businessName: v)),
                                ),
                                _EditableText(
                                  controller: _businessEmailCtrl,
                                  hint: 'Business email',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12),
                                  onChanged: (v) => _update(
                                      (d) => d.copyWith(businessEmail: v)),
                                ),
                                _EditableText(
                                  controller: _businessPhoneCtrl,
                                  hint: 'Business phone',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12),
                                  onChanged: (v) => _update(
                                      (d) => d.copyWith(businessPhone: v)),
                                ),
                                _EditableText(
                                  controller: _businessAddressCtrl,
                                  hint: 'Business address',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12),
                                  onChanged: (v) => _update(
                                      (d) => d.copyWith(businessAddress: v)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('RECEIPT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1)),
                              SizedBox(
                                width: 110,
                                child: _EditableText(
                                  controller: _receiptNumberCtrl,
                                  hint: '#',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                  onChanged: (v) => _update(
                                      (d) => d.copyWith(receiptNumber: v)),
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
                                _label('Customer', accent),
                                const SizedBox(height: 4),
                                _EditableText(
                                  controller: _clientNameCtrl,
                                  hint: 'Client name',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700),
                                  onChanged: (v) =>
                                      _update((d) => d.copyWith(clientName: v)),
                                ),
                                _EditableText(
                                  controller: _clientEmailCtrl,
                                  hint: 'Client email',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600),
                                  onChanged: (v) =>
                                      _update((d) => d.copyWith(clientEmail: v)),
                                ),
                                _EditableText(
                                  controller: _clientPhoneCtrl,
                                  hint: 'Client phone',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600),
                                  onChanged: (v) =>
                                      _update((d) => d.copyWith(clientPhone: v)),
                                ),
                                _EditableText(
                                  controller: _clientAddressCtrl,
                                  hint: 'Client address',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600),
                                  onChanged: (v) => _update(
                                      (d) => d.copyWith(clientAddress: v)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _dateChip('Paid', _paymentDate, accent, _pickDate),
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
                                  hint: 'Thank-you note, return policy...',
                                  maxLines: 3,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600),
                                  onChanged: (v) =>
                                      _update((d) => d.copyWith(notes: v)),
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
                                      onChanged: (v) => _update((d) => d.copyWith(
                                          taxRate: double.tryParse(v) ?? 0)),
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
                                      onChanged: (v) => _update((d) => d.copyWith(
                                          discountRate: double.tryParse(v) ?? 0)),
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
                                    'Paid  $symbol${fmt.format(data.amountPaid)}',
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
  final ReceiptColor selected;
  final ValueChanged<ReceiptColor> onChanged;
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

class _PaymentMethodRow extends StatelessWidget {
  final PaymentMethod selected;
  final Color accent;
  final ValueChanged<PaymentMethod> onChanged;
  const _PaymentMethodRow(
      {required this.selected, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _kPaymentMethods.map((m) {
          final isActive = m.$2 == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(m.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? accent.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isActive ? accent : Colors.grey.shade300,
                      width: isActive ? 1.4 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.$3, size: 13, color: isActive ? accent : Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Text(m.$1,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isActive ? accent : Colors.grey.shade600)),
                  ],
                ),
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
