// invoice_full_preview_screen.dart
// lib/screens/invoice_create_section/step_customize/invoice_full_preview_screen.dart
//
// SAVE-FROM-CUSTOMISE PASS (this update): removed the "Save" AppBar
// action, _handleSaveInvoice(), and the Save Invoice dialog
// (_SaveInvoiceDialogResult) entirely. Saving an invoice now happens
// directly from step_customise.dart's "Save Invoice" bottom-bar button
// (see that file's own SAVE-FROM-CUSTOMISE PASS comment), matching how
// QuoteFullPreviewScreen has no save affordance of its own either — the
// wizard's Save action lives on the Customise step, this screen is pure
// preview/export/share. The optional "Business Name" field that used to
// live in that dialog is gone with it; business name is set via the
// selected Template (step_templates.dart) same as before, and can still
// be edited there.
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
import '../../../document_layout_templates/01_executive/executive_invoice_logic_data.dart';
import '../../../document_layout_templates/01_executive/executive_invoice_stationary_layout.dart'
    show kPageW;
import '../../../document_layout_templates/pagination/scaled_page_stack.dart';
import '../invoice_template_previews/preview_registry.dart' show buildInvoicePreview;
import 'invoice_preview_bottom_bar.dart';

class InvoiceFullPreviewScreen extends StatefulWidget {
  const InvoiceFullPreviewScreen({super.key});

  @override
  State<InvoiceFullPreviewScreen> createState() => _InvoiceFullPreviewScreenState();
}

class _InvoiceFullPreviewScreenState extends State<InvoiceFullPreviewScreen> {
  final _pdfService = InvoicePdfService();
  bool _isLoading = false;

  // Wraps the live draft as a SavedInvoice so it can go through the same
  // PDF path as a saved one, without actually persisting it. Used only
  // for the Download/Share actions below.
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
      ),
    );
  }
}