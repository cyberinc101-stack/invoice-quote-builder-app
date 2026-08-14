// receipt_full_preview_screen.dart
// lib/screens/receipt_full_preview_screen.dart
//
// TEMPLATE + A4 FORMAT PASS (this update): the body no longer hardcodes
// ExecutiveReceiptPreview — it now dispatches on data.layoutTemplateId via
// buildReceiptPreview() (receipt_template_chooser_01/preview_registry.dart),
// same as the receipt template chooser grid already uses. Also swapped the
// fixed-height Transform.scale (which forced a hard kPageH box regardless
// of the design's actual rendered height) for ScaledPageStack — the same
// fix already applied to invoice_full_preview_screen.dart and
// quote_full_preview_screen.dart — so this screen always shows the true
// A4 proportions of whichever design is selected instead of stretching or
// clipping it into a fixed box.
//
// Mirrors invoice_full_preview_screen.dart, built against the real receipt
// types: ReceiptProvider, ReceiptData, SavedReceipt, ReceiptPdfService.
// Lives flat under lib/screens/ (not a subfolder) to match the import path
// already used by create_receipt_screen.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/receipt_provider.dart';
import '../models/receipt_data.dart';
import '../services/receipt_pdf_service.dart';
import '../receipt_layout_templates/01_executive_receipt_layout/executive_receipt_logic_data.dart';
import '../receipt_layout_templates/01_executive_receipt_layout/executive_receipt_stationary_layout.dart'
    show kPageW;
import '../invoice_layout_templates/pagination/scaled_page_stack.dart';
import '../create_receipt/receipt_template_chooser_01/preview_registry.dart'
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
  // id is unrecognized.
  Widget _buildPreviewWidget(ReceiptData data) {
    return buildReceiptPreview(data.layoutTemplateId, data) ??
        ExecutiveReceiptPreview(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final data   = context.watch<ReceiptProvider>().currentReceiptData;
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
      bottomNavigationBar: ReceiptPreviewBottomBar(
        accent: accent,
        isLoading: _isLoading,
        onExport: _handleDownload,
        onShare: _handleShare,
      ),
    );
  }
}
