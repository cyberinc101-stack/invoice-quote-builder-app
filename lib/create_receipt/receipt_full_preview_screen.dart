// receipt_full_preview_screen.dart
// lib/create_receipt/receipt_full_preview_screen.dart
//
// THERMAL PREVIEW BUG FIX PASS (this update): same bug as the Review
// step's Live Preview card — _buildPreviewWidget always called
// buildReceiptPreview(data.layoutTemplateId, data), the A4 registry,
// regardless of data.paperFormat. Now branches on
// receiptPaperFormatFromString(data.paperFormat).isThermal and renders
// ThermalReceiptLivePreview via FittedBox instead of ScaledPageStack
// (which assumes a fixed A4 aspect ratio) when thermal.
//
// PRINT ACTION PASS (earlier): added _handlePrint(), routed through
// ReceiptPdfService.printReceipt() (OS print dialog).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/receipt_provider.dart';
import '../models/receipt_data.dart';
import '../services/receipt_pdf_service.dart';
import '../screens/saved_invoice_details_section/saved_document_detail_screen.dart';
import '../document_layout_templates/01_executive/executive_receipt_logic_data.dart';
import '../document_layout_templates/01_executive/executive_receipt_stationary_layout.dart'
    show kPageW;
import '../document_layout_templates/pagination/scaled_page_stack.dart';
import 'receipt_paper_format.dart';
import 'receipt_thermal_live_preview.dart';
import 'receipt_template_chooser_01/preview_registry.dart'
    show buildReceiptPreview;
import 'receipt_preview_bottom_bar.dart';

class ReceiptFullPreviewScreen extends StatefulWidget {
  const ReceiptFullPreviewScreen({super.key});

  @override
  State<ReceiptFullPreviewScreen> createState() => _ReceiptFullPreviewScreenState();
}

class _ReceiptFullPreviewScreenState extends State<ReceiptFullPreviewScreen> {
  final _pdfService = ReceiptPdfService();
  bool _isLoading = false;
  bool _isSaving = false;

  // Wraps the live draft as a SavedReceipt so it can go through the same
  // PDF path as a saved one, without actually persisting it.
  SavedReceipt _wrapAsSavedReceipt(ReceiptData data) {
    final now = DateTime.now();
    return SavedReceipt(
      id: 'preview_${now.millisecondsSinceEpoch}',
      title: data.businessName.isNotEmpty ? data.businessName : 'Receipt',
      templateName: 'Standard',
      data: data,
      createdAt: now,
      lastEditedAt: now,
      completionPercent: 100,
    );
  }

  Future<void> _handleDownload() async {
    final data = context.read<ReceiptProvider>().currentReceiptData;
    setState(() => _isLoading = true);
    try {
      final path = await _pdfService.generateAndDownloadPDF(_wrapAsSavedReceipt(data));
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
    final data = context.read<ReceiptProvider>().currentReceiptData;
    setState(() => _isLoading = true);
    try {
      await _pdfService.generateAndSharePDF(_wrapAsSavedReceipt(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePrint() async {
    final data = context.read<ReceiptProvider>().currentReceiptData;
    setState(() => _isLoading = true);
    try {
      await _pdfService.printReceipt(
        _wrapAsSavedReceipt(data),
        layoutTemplateId: data.layoutTemplateId,
        paperFormat: data.paperFormat,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSaveReceipt() async {
    final provider = context.read<ReceiptProvider>();
    final data = provider.currentReceiptData;

    final suggestedTitle = data.clientName.isNotEmpty
        ? '${data.clientName} — ${data.receiptNumber.isNotEmpty ? data.receiptNumber : 'Receipt'}'
        : (data.receiptNumber.isNotEmpty ? data.receiptNumber : 'Receipt');

    final controller = TextEditingController(text: suggestedTitle);
    final formKey = GlobalKey<FormState>();

    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Save Receipt',
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
              hintText: 'Enter a name for this receipt',
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
      await provider.saveCurrentReceipt(
        title: title,
        templateName: 'Standard',
      );

      if (!mounted) return;

      final id = provider.currentReceiptId;
      final matches = provider.savedReceipts.where((r) => r.id == id);
      if (matches.isEmpty) {
        setState(() => _isSaving = false);
        return;
      }
      final saved = matches.first;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Receipt "${saved.title}" saved'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SavedDocumentDetailScreen.receipt(saved),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Couldn\'t save receipt: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static Color _accentFromScheme(ReceiptColor scheme) {
    const map = {
      ReceiptColor.blue:   Color(0xFF1565C0),
      ReceiptColor.green:  Color(0xFF2E7D32),
      ReceiptColor.purple: Color(0xFF6A1B9A),
      ReceiptColor.orange: Color(0xFFE65100),
      ReceiptColor.red:    Color(0xFFC62828),
      ReceiptColor.teal:   Color(0xFF00695C),
      ReceiptColor.black:  Color(0xFF212121),
      ReceiptColor.indigo: Color(0xFF283593),
    };
    return map[scheme] ?? const Color(0xFF2E7D32);
  }

  // Dispatches on data.layoutTemplateId — falls back to Executive if the
  // id is unrecognized. A4 path only; thermal is handled separately in
  // build() since it isn't a fixed-aspect-ratio page like A4 designs are.
  Widget _buildPreviewWidget(ReceiptData data) {
    return buildReceiptPreview(data.layoutTemplateId, data) ??
        ExecutiveReceiptPreview(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final data   = context.watch<ReceiptProvider>().currentReceiptData;
    final accent = _accentFromScheme(data.colorScheme);
    final format = receiptPaperFormatFromString(data.paperFormat);
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
                    onPressed: _handleSaveReceipt,
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
          child: format.isThermal
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: format.widthMm * 4.2,
                    child: ThermalReceiptLivePreview(data: data, widthMm: format.widthMm),
                  ),
                )
              : ScaledPageStack(
                  targetWidth: targetWidth,
                  nativePageWidth: kPageW,
                  child: _buildPreviewWidget(data),
                ),
        ),
      ),
      bottomNavigationBar: ReceiptPreviewBottomBar(
        accent: accent,
        isLoading: _isLoading,
        onExport: _handleDownload,
        onShare: _handleShare,
        onPrint: _handlePrint,
      ),
    );
  }
}
