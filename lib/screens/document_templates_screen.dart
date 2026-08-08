// document_templates_screen.dart
// lib/screens/document_templates_screen.dart
//
// Grid of document template cards, reachable from the "Templates" button on
// the home screen hero banner. Now wired to real template data and real
// scaled previews (InvoiceStepChooserScaledPreview / QuoteStepChooserScaledPreview)
// instead of dummy icon placeholders.
//
// Receipts: no receipt template registry exists yet (no kReceiptTemplates,
// no receipt preview builder) — the Receipts filter intentionally shows the
// empty state below rather than fake data. Wire it in once receipt layouts
// exist, following the same pattern as the invoice/quote branches.

import 'package:flutter/material.dart';
import 'invoice_create_section/editor_screen.dart';
import 'invoice_create_section/invoice_step_template_chooser_registry.dart'
    show InvoiceStepChooserScaledPreview;
import 'invoice_create_section/invoice_template_previews/preview_registry.dart'
    show InvoiceTemplateInfo, kInvoiceTemplates;
import 'quote_editor_screen.dart';
import 'create_quote_section/quote_step_template_chooser_registry.dart'
    show QuoteStepChooserScaledPreview;
import 'create_quote_section/quote_template_chooser_01/preview_registry.dart'
    show QuoteTemplateInfo, kQuoteTemplates;

enum _TemplateType { invoice, quote, receipt }

// Unified wrapper so invoice + quote entries can share one grid/list,
// while still carrying enough type info to render the right preview
// widget and navigate to the right editor.
class _GalleryEntry {
  final _TemplateType type;
  final int id;
  final String name;
  final String tag;
  final Color accentColor;
  final bool available;
  final bool isPremium;

  const _GalleryEntry({
    required this.type,
    required this.id,
    required this.name,
    required this.tag,
    required this.accentColor,
    required this.available,
    required this.isPremium,
  });

  factory _GalleryEntry.fromInvoice(InvoiceTemplateInfo info) => _GalleryEntry(
        type: _TemplateType.invoice,
        id: info.id,
        name: info.name,
        tag: info.tag,
        accentColor: info.accentColor,
        available: info.available,
        isPremium: info.isPremium,
      );

  factory _GalleryEntry.fromQuote(QuoteTemplateInfo info) => _GalleryEntry(
        type: _TemplateType.quote,
        id: info.id,
        name: info.name,
        tag: info.tag,
        accentColor: info.accentColor,
        available: info.available,
        isPremium: info.isPremium,
      );

  String get styleLabel {
    switch (type) {
      case _TemplateType.invoice:
        return 'Invoice · $tag';
      case _TemplateType.quote:
        return 'Quote · $tag';
      case _TemplateType.receipt:
        return 'Receipt · $tag';
    }
  }
}

final List<_GalleryEntry> _kGalleryEntries = [
  ...kInvoiceTemplates.map(_GalleryEntry.fromInvoice),
  ...kQuoteTemplates.map(_GalleryEntry.fromQuote),
];

class DocumentTemplatesScreen extends StatefulWidget {
  const DocumentTemplatesScreen({super.key});

  @override
  State<DocumentTemplatesScreen> createState() => _DocumentTemplatesScreenState();
}

class _DocumentTemplatesScreenState extends State<DocumentTemplatesScreen> {
  _TemplateType? _selectedType; // null == All

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

    switch (entry.type) {
      case _TemplateType.invoice:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditorScreen(layoutTemplateId: entry.id),
          ),
        );
        return;
      case _TemplateType.quote:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuoteEditorScreen(layoutTemplateId: entry.id),
          ),
        );
        return;
      case _TemplateType.receipt:
        // No receipt template registry yet — nothing to route to.
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedType == null
        ? _kGalleryEntries
        : _kGalleryEntries.where((t) => t.type == _selectedType).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Document Templates')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _TypeChip(
                  label: 'All',
                  isSelected: _selectedType == null,
                  onTap: () => setState(() => _selectedType = null),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Invoices',
                  isSelected: _selectedType == _TemplateType.invoice,
                  onTap: () => setState(() => _selectedType = _TemplateType.invoice),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Quotes',
                  isSelected: _selectedType == _TemplateType.quote,
                  onTap: () => setState(() => _selectedType = _TemplateType.quote),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Receipts',
                  isSelected: _selectedType == _TemplateType.receipt,
                  onTap: () => setState(() => _selectedType = _TemplateType.receipt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _selectedType == _TemplateType.receipt
                            ? 'Receipt templates are coming soon'
                            : 'No templates in this category yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, i) => _TemplateCard(
                      entry: filtered[i],
                      onTap: () => _select(context, filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _TypeChip
// -----------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isSelected
        ? const Color(0xFF1A1A2E)
        : (isDark ? cs.surfaceContainerHighest : const Color(0xFFF5F5F5));
    final fg = isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: fg,
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

  const _TemplateCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
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
                    child: entry.type == _TemplateType.invoice
                        ? InvoiceStepChooserScaledPreview(templateId: entry.id)
                        : QuoteStepChooserScaledPreview(templateId: entry.id),
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
                    entry.styleLabel,
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
