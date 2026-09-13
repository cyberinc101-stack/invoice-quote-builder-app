// lib/screens/create_quote_section/step_customise/quote_full_preview_screen.dart
//
// PREVIEW SCREEN PARITY PASS (this update): brings this screen back into
// full alignment with receipt_full_preview_screen.dart, which is now the
// reference layout both Invoice and Quote match:
//   - Restored the "Save" AppBar action (with its own save-name dialog),
//     reversing the earlier SAVE-FROM-CUSTOMISE PARITY PASS that removed
//     it — Save now lives in BOTH places, same as Receipt: the Customise
//     step's bottom-bar "Save Quote" button (quote_step_customise.dart,
//     unchanged by this pass) AND this screen's AppBar action. Tapping
//     either saves the current draft via QuoteProvider.saveCurrentQuote()
//     and jumps straight to SavedDocumentDetailScreen.quote(saved) —
//     identical flow to receipt_full_preview_screen.dart's
//     _handleSaveReceipt(), just backed by QuoteProvider instead of
//     ReceiptProvider (which already returns the real SavedQuote
//     directly, so there's no need for receipt's extra "look it back up
//     in savedReceipts" step).
//   - Added _handlePrint(), routed through QuotePdfService.printQuote()
//     (OS print dialog) — mirrors receipt's _handlePrint exactly. Quote
//     has no thermal/paper-format concept, so no format branching is
//     needed the way receipt's print handler has.
//   - QuotePreviewBottomBar now receives onPrint, rendering the third
//     Print button alongside Save PDF / Share (see that file's own
//     PRINT BUTTON PASS).
//
// FOLDER MOVE + SAVE-FROM-CUSTOMISE PARITY PASS (earlier): relocated
// from create_quote_section/quote_full_preview_screen.dart into its own
// step_customise/ folder, alongside quote_step_customise.dart (which
// opens this screen) and quote_preview_bottom_bar.dart — matching
// Invoice's step_customize/ folder shape exactly.
//
// TEMPLATE PASS (earlier): the body no longer hardcodes
// ExecutiveQuotePreview — it now dispatches on data.layoutTemplateId via
// buildQuotePreview() (quote_template_chooser_01/preview_registry.dart),
// the same function the template chooser grid already uses.
//
// UPDATED (earlier pass): the old inline _QuoteDocument mockup widget has
// been replaced with ExecutiveQuotePreview from
// document_layout_templates/01_executive — the same self-scaling
// A4-page template used by the real PDF export and by
// invoice_full_preview_screen.dart / receipt_full_preview_screen.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/quote_provider.dart';
import '../../../models/quote_data.dart';
import '../../../services/quote_pdf_service.dart';
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show ExecutiveQuotePreview;
import '../../../document_layout_templates/document_template_layout_data/doc_header.dart'
    show kPageW;
import '../../../document_layout_templates/pagination/scaled_page_stack.dart';
import '../quote_template_chooser_01/preview_registry.dart' show buildQuotePreview;
import '../../saved_invoice_details_section/saved_document_detail_screen.dart';
import 'quote_preview_bottom_bar.dart';

class QuoteFullPreviewScreen extends StatefulWidget {
  const QuoteFullPreviewScreen({super.key});

  @override
  State<QuoteFullPreviewScreen> createState() => _QuoteFullPreviewScreenState();
}

class _QuoteFullPreviewScreenState extends State<QuoteFullPreviewScreen> {
  final _pdfService = QuotePdfService();
  bool _isLoading = false;
  bool _isSaving = false;

  // Wraps the live draft as a SavedQuote so it can go through the same
  // PDF path as a saved one, without actually persisting it. Used for
  // Download/Share/Print.
  SavedQuote _wrapAsSavedQuote(QuoteData data) {
    final now = DateTime.now();
    return SavedQuote(
      id: 'preview_${now.millisecondsSinceEpoch}',
      title: data.businessName.isNotEmpty ? data.businessName : 'Quote',
      templateName: 'Executive',
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
      final path = await _pdfService.generateAndDownloadPDF(
        _wrapAsSavedQuote(data),
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
    final data = context.read<QuoteProvider>().quoteData;
    setState(() => _isLoading = true);
    try {
      await _pdfService.generateAndSharePDF(
        _wrapAsSavedQuote(data),
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
  // QuotePdfService.printQuote() (OS print dialog). No paper-format
  // branching needed — Quote is always A4.
  Future<void> _handlePrint() async {
    final data = context.read<QuoteProvider>().quoteData;
    setState(() => _isLoading = true);
    try {
      await _pdfService.printQuote(
        _wrapAsSavedQuote(data),
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
  // QuoteProvider.saveCurrentQuote() (not the preview-only wrapper
  // above), then replaces the nav stack with the new saved quote's
  // detail screen. QuoteProvider.saveCurrentQuote() already returns the
  // real SavedQuote directly, so — unlike Receipt — there's no need to
  // look it back up in the provider's saved list afterwards.
  Future<void> _handleSaveQuote() async {
    final provider = context.read<QuoteProvider>();
    final data = provider.quoteData;

    final suggestedTitle = data.clientName.isNotEmpty
        ? '${data.clientName} — ${data.quoteNumber.isNotEmpty ? data.quoteNumber : 'Quote'}'
        : (data.quoteNumber.isNotEmpty ? data.quoteNumber : 'Quote');

    final controller = TextEditingController(text: suggestedTitle);
    final formKey = GlobalKey<FormState>();

    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Save Quote',
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
              hintText: 'Enter a name for this quote',
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
      final saved = provider.saveCurrentQuote(
        title: title,
        templateName: 'Executive',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Quote "${saved.title}" saved'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SavedDocumentDetailScreen.quote(saved),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Couldn\'t save quote: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  // Dispatches on data.layoutTemplateId — falls back to Executive if the
  // id is unrecognized.
  Widget _buildPreviewWidget(QuoteData data) {
    return buildQuotePreview(data.layoutTemplateId, data) ??
        ExecutiveQuotePreview(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final data   = context.watch<QuoteProvider>().quoteData;
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
                    onPressed: _handleSaveQuote,
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
      bottomNavigationBar: QuotePreviewBottomBar(
        accent: accent,
        isLoading: _isLoading,
        onExport: _handleDownload,
        onShare: _handleShare,
        onPrint: _handlePrint,
      ),
    );
  }
}
