// quote_full_preview_screen.dart
// lib/screens/create_quote_section/quote_full_preview_screen.dart
//
// UPDATED (this pass): the old inline _QuoteDocument mockup widget has
// been replaced with ExecutiveQuotePreview from
// quote_layout_templates/01_executive_quote_layout — the same self-scaling
// A4-page template used by the real PDF export and by
// invoice_full_preview_screen.dart / receipt_full_preview_screen.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/quote_provider.dart';
import '../../models/quote_data.dart';
import '../../services/quote_pdf_service.dart';
import '../../quote_layout_templates/01_executive_quote_layout/executive_quote_logic_data.dart';
import '../../quote_layout_templates/01_executive_quote_layout/executive_quote_stationary_layout.dart'
    show kPageW, kPageH;
import 'quote_preview_bottom_bar.dart';

class QuoteFullPreviewScreen extends StatefulWidget {
  const QuoteFullPreviewScreen({super.key});

  @override
  State<QuoteFullPreviewScreen> createState() => _QuoteFullPreviewScreenState();
}

class _QuoteFullPreviewScreenState extends State<QuoteFullPreviewScreen> {
  final _pdfService = QuotePdfService();
  bool _isLoading = false;

  // Wraps the live draft as a SavedQuote so it can go through the same
  // PDF path as a saved one, without actually persisting it.
  SavedQuote _wrapAsSavedQuote(QuoteData data) {
    final now = DateTime.now();
    return SavedQuote(
      id: 'preview_${now.millisecondsSinceEpoch}',
      title: data.businessName.isNotEmpty ? data.businessName : 'Quote',
      templateName: 'Standard',
      data: data,
      createdAt: now,
      lastEditedAt: now,
      completionPercent: 100,
    );
  }

  Future<void> _handleDownload() async {
    final data = context.read<QuoteProvider>().quoteData;
    setState(() => _isLoading = true);
    try {
      final path = await _pdfService.generateAndDownloadPDF(_wrapAsSavedQuote(data));
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
    final data = context.read<QuoteProvider>().quoteData;
    setState(() => _isLoading = true);
    try {
      await _pdfService.generateAndSharePDF(_wrapAsSavedQuote(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static Color _accentFromScheme(QuoteColor scheme) {
    const map = {
      QuoteColor.blue:   Color(0xFF1565C0),
      QuoteColor.green:  Color(0xFF2E7D32),
      QuoteColor.purple: Color(0xFF6A1B9A),
      QuoteColor.orange: Color(0xFFE65100),
      QuoteColor.red:    Color(0xFFC62828),
      QuoteColor.teal:   Color(0xFF00695C),
      QuoteColor.black:  Color(0xFF212121),
      QuoteColor.indigo: Color(0xFF283593),
    };
    return map[scheme] ?? const Color(0xFF6A1B9A);
  }

  @override
  Widget build(BuildContext context) {
    final data   = context.watch<QuoteProvider>().quoteData;
    final accent = _accentFromScheme(data.colorScheme);
    final screenW = MediaQuery.of(context).size.width;
    // Page renders at its native A4 size (kPageW x kPageH); scale the
    // whole thing down to fit the available screen width, same approach
    // used by the invoice and receipt full preview screens.
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
              child: ExecutiveQuotePreview(data: data),
            ),
          ),
        ),
      ),
      bottomNavigationBar: QuotePreviewBottomBar(
        accent: accent,
        isLoading: _isLoading,
        onExport: _handleDownload,
        onShare: _handleShare,
      ),
    );
  }
}