// invoice_full_preview_screen.dart
// lib/screens/invoice_create_section/step_customize/invoice_full_preview_screen.dart
//
// REPLACES a mis-copied CV Builder Pro file that imported CVProvider/CVData/
// CVColor and did not compile against this project. This version is built
// entirely from the real invoice types: InvoiceProvider, InvoiceData,
// SavedInvoice, InvoicePdfService.
//
// FIX (this pass): Added the actually-missing piece of the create flow —
// until now, nothing anywhere in step_create_invoice.dart / step_customise.dart
// / this screen ever called InvoiceProvider.saveCurrentInvoice(). The wizard
// could sync a draft into provider.invoiceData and download/share a PDF of
// it, but the invoice never got inserted into provider.savedInvoices — so it
// never showed up in the saved-documents list, never survived an app
// restart, and could never be opened in SavedDocumentDetailScreen (which is
// what the Export as Excel/CSV buttons operate on). This screen now has a
// real "Save" action in the AppBar: prompts for a title (same rename-dialog
// pattern used in saved_document_detail_screen.dart), calls
// provider.saveCurrentInvoice(), resets the draft (resetInvoiceData()) so
// the next "Create Invoice" run starts clean instead of reloading this one,
// and navigates to SavedDocumentDetailScreen.invoice(saved) — popping the
// whole create-flow stack down to the first route (home) so Back from the
// detail screen doesn't walk back through the wizard steps.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../providers/invoice_provider.dart';
import '../../../models/invoice_data.dart';
import '../../../services/invoice_pdf_service.dart';
import '../../saved_invoice_details_section/saved_document_detail_screen.dart';
import 'invoice_preview_bottom_bar.dart';

class InvoiceFullPreviewScreen extends StatefulWidget {
  const InvoiceFullPreviewScreen({super.key});

  @override
  State<InvoiceFullPreviewScreen> createState() => _InvoiceFullPreviewScreenState();
}

class _InvoiceFullPreviewScreenState extends State<InvoiceFullPreviewScreen> {
  final _pdfService = InvoicePdfService();
  bool _isLoading = false;
  bool _isSaving = false;

  // Wraps the live draft as a SavedInvoice so it can go through the same
  // PDF path as a saved one, without actually persisting it. Used only for
  // the Download/Share actions below — NOT for the real Save action, which
  // goes through InvoiceProvider.saveCurrentInvoice() instead so it's
  // actually inserted into savedInvoices.
  SavedInvoice _wrapAsSavedInvoice(InvoiceData data) {
    final now = DateTime.now();
    return SavedInvoice(
      id: 'preview_${now.millisecondsSinceEpoch}',
      title: data.businessName.isNotEmpty ? data.businessName : 'Invoice',
      templateName: 'Executive',
      data: data,
      createdAt: now,
      lastEditedAt: now,
      completionPercent: 100,
    );
  }

  Future<void> _handleDownload() async {
    final data = context.read<InvoiceProvider>().invoiceData;
    setState(() => _isLoading = true);
    try {
      final path = await _pdfService.generateAndDownloadPDF(_wrapAsSavedInvoice(data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleShare() async {
    final data = context.read<InvoiceProvider>().invoiceData;
    setState(() => _isLoading = true);
    try {
      await _pdfService.generateAndSharePDF(_wrapAsSavedInvoice(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // NEW: the actual save action. Prompts for a title, then inserts the
  // current draft into InvoiceProvider.savedInvoices via
  // saveCurrentInvoice() — this is the call that was missing from the
  // entire create flow. On success, resets the active draft and navigates
  // to the saved invoice's detail screen, clearing the wizard stack beneath
  // it (down to the first/home route) so Back doesn't re-enter the wizard.
  Future<void> _handleSaveInvoice() async {
    final provider = context.read<InvoiceProvider>();
    final data = provider.invoiceData;

    final suggestedTitle = data.clientName.isNotEmpty
        ? '${data.clientName} — ${data.invoiceNumber.isNotEmpty ? data.invoiceNumber : 'Invoice'}'
        : (data.invoiceNumber.isNotEmpty ? data.invoiceNumber : 'Invoice');

    final controller = TextEditingController(text: suggestedTitle);
    final formKey = GlobalKey<FormState>();

    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Save Invoice',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
            decoration: InputDecoration(
              hintText: 'Enter a name for this invoice',
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (title == null) return; // cancelled

    setState(() => _isSaving = true);
    try {
      final saved = provider.saveCurrentInvoice(
        title: title,
        templateName: 'Executive',
      );

      // Start the next "Create Invoice" run from a blank slate instead of
      // reloading what was just saved.
      provider.resetInvoiceData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invoice "${saved.title}" saved'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SavedDocumentDetailScreen.invoice(saved),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Couldn\'t save invoice: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static Color _accentFromScheme(InvoiceColor scheme) {
    const map = {
      InvoiceColor.blue:   Color(0xFF1565C0),
      InvoiceColor.green:  Color(0xFF2E7D32),
      InvoiceColor.purple: Color(0xFF6A1B9A),
      InvoiceColor.orange: Color(0xFFE65100),
      InvoiceColor.red:    Color(0xFFC62828),
      InvoiceColor.teal:   Color(0xFF00695C),
      InvoiceColor.black:  Color(0xFF212121),
      InvoiceColor.indigo: Color(0xFF283593),
    };
    return map[scheme] ?? const Color(0xFF1565C0);
  }

  static String _symbolFor(String code) {
    const symbols = {
      'USD': '\$',  'EUR': '€',   'GBP': '£',   'JPY': '¥',
      'AUD': 'A\$', 'CAD': 'C\$', 'NZD': 'NZ\$','CHF': 'Fr',
      'CNY': '¥',   'INR': '₹',   'KRW': '₩',   'SGD': 'S\$',
      'HKD': 'HK\$','SEK': 'kr',  'NOK': 'kr',  'DKK': 'kr',
      'MXN': '\$',  'BRL': 'R\$', 'ZAR': 'R',   'AED': 'د.إ',
    };
    return symbols[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    final data   = context.watch<InvoiceProvider>().invoiceData;
    final accent = _accentFromScheme(data.colorScheme);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _handleSaveInvoice,
                    icon: Icon(Icons.save_rounded, size: 18, color: accent),
                    label: Text(
                      'Save',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _InvoiceDocument(data: data, accent: accent, symbol: _symbolFor(data.currency)),
      ),
      bottomNavigationBar: InvoicePreviewBottomBar(
        accent: accent,
        isLoading: _isLoading,
        onExport: _handleDownload,
        onShare: _handleShare,
      ),
    );
  }
}

// ── Full-page invoice document preview ────────────────────────────────────

class _InvoiceDocument extends StatelessWidget {
  final InvoiceData data;
  final Color accent;
  final String symbol;

  const _InvoiceDocument({required this.data, required this.accent, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final hasCustomer = data.clientName.isNotEmpty ||
        data.clientEmail.isNotEmpty ||
        data.clientPhone.isNotEmpty ||
        data.clientAddress.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: accent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.businessName.isNotEmpty)
                        Text(data.businessName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      if (data.businessEmail.isNotEmpty)
                        Text(data.businessEmail, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                      if (data.businessPhone.isNotEmpty)
                        Text(data.businessPhone, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                      if (data.businessAddress.isNotEmpty)
                        Text(data.businessAddress, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('INVOICE',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    if (data.invoiceNumber.isNotEmpty)
                      Text('#${data.invoiceNumber}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                    if (data.issueDate.isNotEmpty)
                      Text(data.issueDate, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10)),
                    if (data.dueDate.isNotEmpty)
                      Text('Due: ${data.dueDate}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCustomer) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BILL TO',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        if (data.clientName.isNotEmpty)
                          Text(data.clientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        if (data.clientEmail.isNotEmpty) Text(data.clientEmail, style: const TextStyle(fontSize: 11)),
                        if (data.clientPhone.isNotEmpty) Text(data.clientPhone, style: const TextStyle(fontSize: 11)),
                        if (data.clientAddress.isNotEmpty) Text(data.clientAddress, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Line item table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: accent.withOpacity(0.09), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                      SizedBox(width: 50, child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                      SizedBox(width: 70, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                      SizedBox(width: 70, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                    ],
                  ),
                ),
                ...data.lineItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: Text(item.description, style: const TextStyle(fontSize: 12))),
                        SizedBox(
                          width: 50,
                          child: Text(
                            item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(width: 70, child: Text('$symbol${fmt.format(item.unitPrice)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        SizedBox(width: 70, child: Text('$symbol${fmt.format(item.total)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),

                // Totals — sourced from InvoiceData's own getters, matching
                // exactly what InvoicePdfService puts in the PDF.
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        _totalRow('Subtotal', '$symbol${fmt.format(data.subtotal)}'),
                        if (data.taxRate > 0)
                          _totalRow('Tax (${_fmtPct(data.taxRate)}%)', '+$symbol${fmt.format(data.taxAmount)}'),
                        if (data.discountRate > 0)
                          _totalRow('Discount (${_fmtPct(data.discountRate)}%)', '-$symbol${fmt.format(data.discountAmount)}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text('$symbol${fmt.format(data.grandTotal)}',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: accent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (data.notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Notes / Payment Terms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: accent)),
                  const SizedBox(height: 4),
                  Text(data.notes, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtPct(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  static Widget _totalRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            Text(value, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}