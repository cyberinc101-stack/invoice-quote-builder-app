// invoice_full_preview_screen.dart
// lib/screens/invoice_create_section/step_customize/invoice_full_preview_screen.dart
//
// PREVIEW SCREEN PARITY PASS (this update): brings this screen back into
// full alignment with receipt_full_preview_screen.dart, which is now the
// reference layout both Invoice and Quote match:
//   - Restored the "Save" AppBar action (with its own save-name dialog),
//     reversing the earlier SAVE-FROM-CUSTOMISE PASS that removed it —
//     Save now lives in BOTH places, same as Receipt: the Customise
//     step's bottom-bar "Save Invoice" button (step_customise.dart,
//     unchanged by this pass) AND this screen's AppBar action. Tapping
//     either saves the current draft via InvoiceProvider.
//     saveCurrentInvoice() and jumps straight to
//     SavedDocumentDetailScreen.invoice(saved) — identical flow to
//     receipt_full_preview_screen.dart's _handleSaveReceipt(), just
//     backed by InvoiceProvider instead of ReceiptProvider (which
//     already returns the real SavedInvoice directly, so there's no
//     need for receipt's extra "look it back up in savedReceipts" step).
//   - Added _handlePrint(), routed through InvoicePdfService.
//     printInvoice() (OS print dialog) — mirrors receipt's _handlePrint
//     exactly. Invoice has no thermal/paper-format concept, so no format
//     branching is needed the way receipt's print handler has.
//   - InvoicePreviewBottomBar now receives onPrint, rendering the third
//     Print button alongside Save PDF / Share (see that file's own
//     PRINT BUTTON PASS).
//
// TEMPLATE PASS (earlier): the body no longer hardcodes
// ExecutiveInvoicePreview — it now dispatches on
// data.layoutTemplateId via buildInvoicePreview() (preview_registry.dart),
// same as the template chooser grid, its full-preview modal, and
// step_customise.dart's live preview. Download/Share now also pass
// layoutTemplateId through to InvoicePdfService so that once PDF builders
// exist for designs beyond Executive, this screen picks the right one
// automatically — today only Executive's PDF builder exists, so other
// template ids still fall back to the Executive PDF layout even though
// the on-screen preview here correctly shows the real design.
//
// UPDATED (earlier pass): the old inline _InvoiceDocument mockup widget has
// been replaced with ExecutiveInvoicePreview from
// document_layout_templates/01_executive — the same self-scaling
// A4-page template used by the real PDF export and now also by
// quote_full_preview_screen.dart / receipt_full_preview_screen.dart. This
// preview now matches what actually gets exported, at correct A4
// proportions, instead of a free-form content-sized mockup.
//
// Download / Share logic is otherwise UNCHANGED from the previous pass.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/invoice_provider.dart';
import '../../../models/invoice_data.dart';
import '../../../services/invoice_pdf_service.dart';
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show ExecutiveInvoicePreview;
import '../../../document_layout_templates/document_template_layout_data/doc_header.dart'
    show kPageW;
import '../../../document_layout_templates/pagination/scaled_page_stack.dart';
import '../invoice_template_previews/preview_registry.dart' show buildInvoicePreview;
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
  // PDF path as a saved one, without actually persisting it. Used for
  // Download/Share/Print.
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
      final path = await _pdfService.generateAndDownloadPDF(
        _wrapAsSavedInvoice(data),
        layoutTemplateId: data.layoutTemplateId,
      );
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
      await _pdfService.generateAndSharePDF(
        _wrapAsSavedInvoice(data),
        layoutTemplateId: data.layoutTemplateId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // PREVIEW SCREEN PARITY PASS: new — mirrors receipt_full_preview_
  // screen.dart's _handlePrint() exactly, routed through
  // InvoicePdfService.printInvoice() (OS print dialog). No paper-format
  // branching needed — Invoice is always A4.
  Future<void> _handlePrint() async {
    final data = context.read<InvoiceProvider>().invoiceData;
    setState(() => _isLoading = true);
    try {
      await _pdfService.printInvoice(
        _wrapAsSavedInvoice(data),
        layoutTemplateId: data.layoutTemplateId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // PREVIEW SCREEN PARITY PASS: new — mirrors receipt_full_preview_
  // screen.dart's _handleSaveReceipt() exactly: asks for a name via a
  // small dialog, saves the ACTUAL current draft through
  // InvoiceProvider.saveCurrentInvoice() (not the preview-only wrapper
  // above), then replaces the nav stack with the new saved invoice's
  // detail screen. InvoiceProvider.saveCurrentInvoice() already returns
  // the real SavedInvoice directly, so — unlike Receipt — there's no
  // need to look it back up in the provider's saved list afterwards.
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

    if (title == null) return;

    setState(() => _isSaving = true);
    try {
      final saved = provider.saveCurrentInvoice(
        title: title,
        templateName: 'Executive',
      );

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

  // Dispatches on data.layoutTemplateId — Executive (id 1) renders
  // directly (the only design with true A4Paginator pagination today);
  // every other id goes through buildInvoicePreview(), falling back to
  // Executive if unrecognized.
  Widget _buildPreviewWidget(InvoiceData data) {
    if (data.layoutTemplateId == 1) {
      return ExecutiveInvoicePreview(data: data);
    }
    return buildInvoicePreview(data.layoutTemplateId, data) ??
        ExecutiveInvoicePreview(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final data   = context.watch<InvoiceProvider>().invoiceData;
    final accent = _accentFromScheme(data.colorScheme);
    final screenW = MediaQuery.of(context).size.width;
    final targetWidth = (screenW - 40).clamp(200.0, kPageW);

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
        child: Center(
          child: ScaledPageStack(
            targetWidth: targetWidth,
            nativePageWidth: kPageW,
            child: _buildPreviewWidget(data),
          ),
        ),
      ),
      bottomNavigationBar: InvoicePreviewBottomBar(
        accent: accent,
        isLoading: _isLoading,
        onExport: _handleDownload,
        onShare: _handleShare,
        onPrint: _handlePrint,
      ),
    );
  }
}
