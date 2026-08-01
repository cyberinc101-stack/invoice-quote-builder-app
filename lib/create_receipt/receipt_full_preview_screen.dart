// receipt_full_preview_screen.dart
// lib/screens/receipt_full_preview_screen.dart
//
// Mirrors invoice_full_preview_screen.dart, built against the real receipt
// types: ReceiptProvider, ReceiptData, SavedReceipt, ReceiptPdfService.
// Lives flat under lib/screens/ (not a subfolder) to match the import path
// already used by create_receipt_screen.dart.
//
// UPDATED (this pass): the old inline _ReceiptDocument widget has been
// replaced with ExecutiveReceiptPreview from
// receipt_layout_templates/01_executive_receipt_layout — the same
// self-scaling A4-page template used for invoices and quotes. Download,
// share, and the bottom bar are unchanged.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/receipt_provider.dart';
import '../models/receipt_data.dart';
import '../services/receipt_pdf_service.dart';
import '../receipt_layout_templates/01_executive_receipt_layout/executive_receipt_logic_data.dart';
import '../receipt_layout_templates/01_executive_receipt_layout/executive_receipt_stationary_layout.dart'
    show kPageW, kPageH;
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

  @override
  Widget build(BuildContext context) {
    final data   = context.watch<ReceiptProvider>().currentReceiptData;
    final accent = _accentFromScheme(data.colorScheme);
    final screenW = MediaQuery.of(context).size.width;
    // Page renders at its native A4-ish size (kPageW x kPageH); scale the
    // whole thing down to fit the available screen width, same idea as
    // the invoice/quote full preview screens.
    final fitScale = ((screenW - 40) / kPageW).clamp(0.3, 1.0);

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
          child: SizedBox(
            width: kPageW * fitScale,
            height: kPageH * fitScale,
            child: Transform.scale(
              scale: fitScale,
              alignment: Alignment.topCenter,
              child: ExecutiveReceiptPreview(data: data),
            ),
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