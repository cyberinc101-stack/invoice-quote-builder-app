// document_templates_screen.dart
// lib/screens/document_templates_screen.dart
//
// Grid of document template cards, reachable from the "Templates" button on
// the home screen hero banner.
//
// DEDUPE (earlier pass): kInvoiceTemplates and kQuoteTemplates describe the
// exact same 10 designs (same ids, names, tags, accent colors) — each
// design is already built once via DocTemplateAdapter and rendered
// per-doc-type through invoiceToAdapter()/quoteToAdapter()/
// receiptToAdapter(). The gallery sources from a single list
// (kInvoiceTemplates — quote's list is identical) and shows each design
// once. Confirmed fixed on-device: cards now read "Nordic · Minimal" etc,
// not the old doubled "Invoice · Nordic" / "Quote · Nordic" pairs.
//
// FILTERS REMOVED (this pass): the All/Invoices/Quotes/Receipts chip row
// is gone per request — this screen now just shows the 10 designs, full
// stop. Since there's no more chip to pre-select a doc type, tapping any
// card always opens the small "use as Invoice/Quote/Receipt" sheet
// (previously only shown under "All"). Card thumbnails always render via
// the invoice-flavored preview widget now that there's no chip to switch
// them to quote's.
//
// LONG-PRESS FULL PREVIEW: _TemplateCard wires showTemplateFullPreview()
// (invoice_template_previews/template_full_preview_modal.dart) onto
// onLongPress. That modal renders via buildInvoicePreview()/
// sampleInvoiceData() regardless of doc type — same simplification as the
// card thumbnail. _GalleryEntry carries the original InvoiceTemplateInfo
// so the modal has what it needs without a second registry lookup.
//
// RECEIPTS: routable — CreateReceiptScreen accepts layoutTemplateId the
// same way EditorScreen/QuoteEditorScreen do, and every template file
// already exports a <Name>ReceiptPreview wrapper via receiptToAdapter().

import 'package:flutter/material.dart';
import '../create_receipt/create_receipt_screen.dart';
import 'invoice_create_section/editor_screen.dart';
import 'invoice_create_section/invoice_step_template_chooser_registry.dart'
    show InvoiceStepChooserScaledPreview;
import 'invoice_create_section/invoice_template_previews/preview_registry.dart'
    show InvoiceTemplateInfo, kInvoiceTemplates;
import 'invoice_create_section/invoice_template_previews/template_full_preview_modal.dart'
    show showTemplateFullPreview;
import 'quote_editor_screen.dart';

enum _TemplateType { invoice, quote, receipt }

extension on _TemplateType {
  String get label => switch (this) {
        _TemplateType.invoice => 'Invoice',
        _TemplateType.quote => 'Quote',
        _TemplateType.receipt => 'Receipt',
      };

  IconData get icon => switch (this) {
        _TemplateType.invoice => Icons.receipt_long_rounded,
        _TemplateType.quote => Icons.description_rounded,
        _TemplateType.receipt => Icons.receipt_rounded,
      };
}

// One design == one entry, regardless of which doc type it's used for.
class _GalleryEntry {
  final int id;
  final String name;
  final String tag;
  final Color accentColor;
  final bool available;
  final bool isPremium;
  // Kept around so long-press preview doesn't need a second registry
  // lookup — same object InvoiceStepChooserScaledPreview/showTemplateFullPreview expect.
  final InvoiceTemplateInfo original;

  const _GalleryEntry({
    required this.id,
    required this.name,
    required this.tag,
    required this.accentColor,
    required this.available,
    required this.isPremium,
    required this.original,
  });

  factory _GalleryEntry.fromInvoice(InvoiceTemplateInfo info) => _GalleryEntry(
        id: info.id,
        name: info.name,
        tag: info.tag,
        accentColor: info.accentColor,
        available: info.available,
        isPremium: info.isPremium,
        original: info,
      );
}

final List<_GalleryEntry> _kGalleryEntries =
    kInvoiceTemplates.map(_GalleryEntry.fromInvoice).toList();

class DocumentTemplatesScreen extends StatelessWidget {
  const DocumentTemplatesScreen({super.key});

  void _select(BuildContext context, _GalleryEntry entry) {
    if (!entry.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.name} is coming soon.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showTypeSheet(context, entry);
  }

  void _navigateTo(BuildContext context, _TemplateType type, _GalleryEntry entry) {
    switch (type) {
      case _TemplateType.invoice:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditorScreen(layoutTemplateId: entry.id)),
        );
        return;
      case _TemplateType.quote:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuoteEditorScreen(layoutTemplateId: entry.id)),
        );
        return;
      case _TemplateType.receipt:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateReceiptScreen(layoutTemplateId: entry.id)),
        );
        return;
    }
  }

  void _showTypeSheet(BuildContext context, _GalleryEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: entry.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.name} — use as',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              for (final type in _TemplateType.values)
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: entry.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(type.icon, color: entry.accentColor, size: 19),
                  ),
                  title: Text(type.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateTo(context, type, entry);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Templates')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _kGalleryEntries.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, i) => _TemplateCard(
          entry: _kGalleryEntries[i],
          onTap: () => _select(context, _kGalleryEntries[i]),
          onLongPress: () => showTemplateFullPreview(
            context,
            info: _kGalleryEntries[i].original,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _TemplateCard
// -----------------------------------------------------------------------------

class _TemplateCard extends StatelessWidget {
  final _GalleryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TemplateCard({
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white),
                  Opacity(
                    opacity: entry.available ? 1.0 : 0.45,
                    child: InvoiceStepChooserScaledPreview(templateId: entry.id),
                  ),
                  if (entry.isPremium && entry.available)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 11),
                            SizedBox(width: 3),
                            Text('PRO',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  if (!entry.available)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.15),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Coming Soon',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 3,
                      color: entry.accentColor.withValues(alpha: entry.available ? 1 : 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: entry.available
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.tag,
                    style: TextStyle(
                      fontSize: 11,
                      color: entry.available
                          ? entry.accentColor
                          : cs.onSurface.withValues(alpha: 0.3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
