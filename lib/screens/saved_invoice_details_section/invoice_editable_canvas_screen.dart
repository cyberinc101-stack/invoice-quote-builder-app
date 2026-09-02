// lib/screens/saved_invoice_details_section/invoice_editable_canvas_screen.dart
//
// CRASH SAFETY PASS (this update): _loadStackTrace was captured in
// _loadData()'s catch block but never read anywhere — it only ever went
// to debugPrint (console-only, invisible outside a dev machine). The
// error screen showed just the exception message with no way to see
// what actually failed. _buildErrorScreen now includes a collapsible
// "Technical details" section (ExpansionTile) that renders the full
// stack trace via SelectableText, so a real load failure in production
// is actually diagnosable — the user can expand it, select the text, and
// paste it into a bug report — instead of the trace being silently
// discarded. Mirrors the identical fix applied to quote_editable_canvas_
// screen.dart and receipt_editable_canvas_screen.dart.
//
// REWRITE (earlier): previously this was a bespoke card UI (colored header
// band, tap-to-edit text fields, no A4 page geometry at all) — visually
// different from what Preview/PDF actually show. This version renders the
// real ExecutiveInvoiceEditor (same template as ExecutiveInvoicePreview
// and the PDF export, via executive_invoice_stationary_layout.dart +
// executive_invoice_logic_data.dart) with an InvoiceEditBundle wired to
// InvoiceProvider — tapping any text on the page edits it in place, and
// the page paginates for real via A4Paginator if line items overflow one
// A4 page, instead of shrinking.
//
// Load/save/discard mechanics (deferred post-frame load, _loading/_loadError
// guards, resetInvoiceData() on discard) are unchanged from the previous
// pass — only the body/rendering changed.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/invoice_provider.dart';
import '../../models/invoice_data.dart';
import '../../document_layout_templates/01_executive/executive_invoice_logic_data.dart';
import '../../document_layout_templates/01_executive/executive_invoice_stationary_layout.dart'
    show kPageW, InvoiceEditBundle;
import '../../document_layout_templates/pagination/scaled_page_stack.dart';

const _kDateFmt = 'd MMM yyyy';

const _kPresetColors = [
  ('Ocean Blue', InvoiceColor.blue),
  ('Slate', InvoiceColor.black),
  ('Emerald', InvoiceColor.green),
  ('Crimson', InvoiceColor.red),
  ('Violet', InvoiceColor.purple),
  ('Amber', InvoiceColor.orange),
  ('Teal', InvoiceColor.teal),
  ('Indigo', InvoiceColor.indigo),
];

Color _accentFromScheme(InvoiceColor scheme) {
  const map = {
    InvoiceColor.blue: Color(0xFF1565C0),
    InvoiceColor.green: Color(0xFF2E7D32),
    InvoiceColor.purple: Color(0xFF6A1B9A),
    InvoiceColor.orange: Color(0xFFE65100),
    InvoiceColor.red: Color(0xFFC62828),
    InvoiceColor.teal: Color(0xFF00695C),
    InvoiceColor.black: Color(0xFF212121),
    InvoiceColor.indigo: Color(0xFF283593),
  };
  return map[scheme] ?? const Color(0xFF1565C0);
}

class InvoiceEditableCanvasScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceEditableCanvasScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceEditableCanvasScreen> createState() =>
      _InvoiceEditableCanvasScreenState();
}

class _InvoiceEditableCanvasScreenState
    extends State<InvoiceEditableCanvasScreen> {
  Object? _loadError;
  StackTrace? _loadStackTrace;
  bool _initialized = false;
  bool _loading = true;

  late TextEditingController _businessNameCtrl;
  late TextEditingController _businessEmailCtrl;
  late TextEditingController _businessPhoneCtrl;
  late TextEditingController _businessAddressCtrl;

  late TextEditingController _clientNameCtrl;
  late TextEditingController _clientEmailCtrl;
  late TextEditingController _clientPhoneCtrl;
  late TextEditingController _clientAddressCtrl;

  late TextEditingController _invoiceNumberCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _notesCtrl;

  late DateTime _issueDate;
  late DateTime _dueDate;

  late List<LineItem> _items;
  final List<TextEditingController> _descCtrl = [];
  final List<TextEditingController> _qtyCtrl = [];
  final List<TextEditingController> _priceCtrl = [];

  int _pageCount = 1;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    try {
      final provider = context.read<InvoiceProvider>();
      provider.loadSavedInvoice(widget.invoiceId);
      final data = provider.invoiceData;

      _businessNameCtrl = TextEditingController(text: data.businessName);
      _businessEmailCtrl = TextEditingController(text: data.businessEmail);
      _businessPhoneCtrl = TextEditingController(text: data.businessPhone);
      _businessAddressCtrl = TextEditingController(text: data.businessAddress);

      _clientNameCtrl = TextEditingController(text: data.clientName);
      _clientEmailCtrl = TextEditingController(text: data.clientEmail);
      _clientPhoneCtrl = TextEditingController(text: data.clientPhone);
      _clientAddressCtrl = TextEditingController(text: data.clientAddress);

      _invoiceNumberCtrl = TextEditingController(text: data.invoiceNumber);
      _taxCtrl = TextEditingController(text: data.taxRate == 0 ? '0' : '${data.taxRate}');
      _discountCtrl =
          TextEditingController(text: data.discountRate == 0 ? '0' : '${data.discountRate}');
      _notesCtrl = TextEditingController(text: data.notes);

      _issueDate = DateFormat(_kDateFmt).tryParse(data.issueDate) ?? DateTime.now();
      _dueDate = DateFormat(_kDateFmt).tryParse(data.dueDate) ??
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
      debugPrint('InvoiceEditableCanvasScreen load failed: $e\n$st');
      _loadError = e;
      _loadStackTrace = st;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    if (_initialized) {
      for (final c in [
        _businessNameCtrl, _businessEmailCtrl, _businessPhoneCtrl, _businessAddressCtrl,
        _clientNameCtrl, _clientEmailCtrl, _clientPhoneCtrl, _clientAddressCtrl,
        _invoiceNumberCtrl, _taxCtrl, _discountCtrl, _notesCtrl,
      ]) {
        c.dispose();
      }
      for (final cList in [_descCtrl, _qtyCtrl, _priceCtrl]) {
        for (final c in cList) c.dispose();
      }
    }
    super.dispose();
  }

  InvoiceProvider get _provider => context.read<InvoiceProvider>();

  void _onItemFieldChanged(int index) {
    _items[index]
      ..description = _descCtrl[index].text
      ..quantity = double.tryParse(_qtyCtrl[index].text) ?? 1
      ..unitPrice = double.tryParse(_priceCtrl[index].text) ?? 0;
    _provider.updateLineItem(index, _items[index]);
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

  Future<void> _pickDate(bool isDue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDue ? _dueDate : _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isDue) {
        _dueDate = picked;
      } else {
        _issueDate = picked;
      }
    });
    _provider.updateInvoiceDetails(
      issueDate: DateFormat(_kDateFmt).format(_issueDate),
      dueDate: DateFormat(_kDateFmt).format(_dueDate),
    );
  }

  Future<void> _handleSave() async {
    _provider.updateSavedInvoice(widget.invoiceId);
    _saved = true;
    _provider.resetInvoiceData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Invoice updated'),
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
              child: const Text('Keep Editing')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (discard != true) return;
    _provider.resetInvoiceData();
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Edit Invoice'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
            icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context, false)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE53935)),
              const SizedBox(height: 16),
              const Text("Couldn't load this invoice for editing",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SelectableText('$_loadError',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              // Captured in _loadData()'s catch block — previously discarded
              // after debugPrint. Collapsed by default so the common case
              // (a normal user hitting this) still just sees the message
              // above; expanding it gives a copy-pasteable trace for a bug
              // report or for debugging during development.
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
              ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Go Back')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) return _buildErrorScreen(context);

    final data = context.watch<InvoiceProvider>().invoiceData;
    final accent = _accentFromScheme(data.colorScheme);
    final screenW = MediaQuery.of(context).size.width;
    final targetWidth = (screenW - 40).clamp(200.0, kPageW);

    final editBundle = InvoiceEditBundle(
      businessNameCtrl: _businessNameCtrl,
      businessEmailCtrl: _businessEmailCtrl,
      businessPhoneCtrl: _businessPhoneCtrl,
      businessAddressCtrl: _businessAddressCtrl,
      invoiceNumberCtrl: _invoiceNumberCtrl,
      clientNameCtrl: _clientNameCtrl,
      clientEmailCtrl: _clientEmailCtrl,
      clientPhoneCtrl: _clientPhoneCtrl,
      clientAddressCtrl: _clientAddressCtrl,
      notesCtrl: _notesCtrl,
      taxRateCtrl: _taxCtrl,
      discountRateCtrl: _discountCtrl,
      itemDescCtrls: _descCtrl,
      itemQtyCtrls: _qtyCtrl,
      itemPriceCtrls: _priceCtrl,
      onBusinessNameChanged: (v) => _provider.updateBusinessInfo(businessName: v),
      onBusinessEmailChanged: (v) => _provider.updateBusinessInfo(businessEmail: v),
      onBusinessPhoneChanged: (v) => _provider.updateBusinessInfo(businessPhone: v),
      onBusinessAddressChanged: (v) => _provider.updateBusinessInfo(businessAddress: v),
      onLogoChanged: (path) => _provider.updateBusinessInfo(businessLogoPath: path ?? ''),
      onInvoiceNumberChanged: (v) => _provider.updateInvoiceDetails(invoiceNumber: v),
      onClientNameChanged: (v) => _provider.updateClientInfo(clientName: v),
      onClientEmailChanged: (v) => _provider.updateClientInfo(clientEmail: v),
      onClientPhoneChanged: (v) => _provider.updateClientInfo(clientPhone: v),
      onClientAddressChanged: (v) => _provider.updateClientInfo(clientAddress: v),
      onNotesChanged: (v) => _provider.updateInvoiceDetails(notes: v),
      onTaxRateChanged: (v) => _provider.updateInvoiceDetails(taxRate: double.tryParse(v) ?? 0),
      onDiscountRateChanged: (v) =>
          _provider.updateInvoiceDetails(discountRate: double.tryParse(v) ?? 0),
      onTapIssueDate: () => _pickDate(false),
      onTapDueDate: () => _pickDate(true),
      onItemFieldChanged: _onItemFieldChanged,
      onRemoveItem: _removeItem,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: const Text('Edit Invoice'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: _handleBack),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _handleSave,
                icon: Icon(Icons.check_rounded, size: 18, color: accent),
                label: Text('Save', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _AccentColorRow(
                selected: data.colorScheme,
                onChanged: (c) => _provider.updateColorScheme(c),
              ),
              const SizedBox(height: 8),
              if (_pageCount > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('$_pageCount pages',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ),
              ScaledPageStack(
                targetWidth: targetWidth,
                nativePageWidth: kPageW,
                child: ExecutiveInvoiceEditor(
                  data: data,
                  edit: editBundle,
                  onPageCount: (count) {
                    if (count != _pageCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _pageCount = count);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: Icon(Icons.add_rounded, color: accent),
                label: Text('Add line item', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accent.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentColorRow extends StatelessWidget {
  final InvoiceColor selected;
  final ValueChanged<InvoiceColor> onChanged;
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
                  border: isActive ? Border.all(color: Colors.white, width: 2.5) : null,
                  boxShadow: isActive
                      ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: isActive ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
