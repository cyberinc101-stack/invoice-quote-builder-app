// document_templates_screen.dart
// lib/screens/document_templates_screen.dart
//
// Grid of document template cards, reachable from the "Templates" button on
// the home screen hero banner.
//
// MATCH-CHOOSER PASS (this update): this screen's card and grid now match
// InvoiceTemplateChooserScreen / QuoteTemplateChooserScreen exactly —
// same padding (16,20,16,24), same spacing (14/18), same aspect ratio
// (0.66, taller/narrower cards), same card visuals (accent-colored footer
// bar, name + radio-style dot below the card, tag beneath that). This
// screen has no real "selection" concept (tapping opens a "use as..."
// sheet rather than selecting), so the dot always renders in its
// unselected/off state — purely visual parity with the choosers, not
// functional selection.
//
// SAFE-AREA PASS (this update): this screen has no bottom "Save & Continue"
// bar like the invoice/quote choosers do (those absorb the device's
// gesture-nav inset via MediaQuery.of(context).padding.bottom in their own
// bottom bar padding). Since this screen's GridView runs straight to the
// bottom of the Scaffold, it now adds that same inset to its own bottom
// padding so the last row of cards isn't hidden behind the Android nav
// buttons.
//
// DEDUPE (earlier pass): kInvoiceTemplates and kQuoteTemplates describe the
// exact same 10 designs (same ids, names, tags, accent colors) — each
// design is already built once via DocTemplateAdapter and rendered
// per-doc-type through invoiceToAdapter()/quoteToAdapter()/
// receiptToAdapter(). The gallery sources from a single list
// (kInvoiceTemplates — quote's list is identical) and shows each design
// once.
//
// FILTERS REMOVED (earlier pass): the All/Invoices/Quotes/Receipts chip row
// is gone per request — this screen now just shows the 10 designs, full
// stop. Tapping any card opens the "use as Invoice/Quote/Receipt" sheet.
//
// LONG-PRESS FULL PREVIEW: showTemplateFullPreview()
// (invoice_template_previews/template_full_preview_modal.dart) is wired
// onto onLongPress.
//
// RECEIPTS: routable — CreateReceiptScreen accepts layoutTemplateId the
// same way EditorScreen/QuoteEditorScreen do.

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
        // Matches InvoiceTemplateChooserScreen / QuoteTemplateChooserScreen
        // exactly — same padding, spacing, and aspect ratio. Bottom padding
        // adds the device's safe-area/gesture-nav inset so the last row
        // isn't hidden behind the Android nav buttons (this screen has no
        // bottom bar like the invoice/quote choosers to absorb that inset).
        padding: EdgeInsets.fromLTRB(
          16, 20, 16, 24 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: _kGalleryEntries.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
          childAspectRatio: 0.66,
        ),
        itemBuilder: (context, i) {
          final entry = _kGalleryEntries[i];
          return _TemplateCard(
            entry: entry,
            onTap: () => _select(context, entry),
            onLongPress: () => showTemplateFullPreview(
              context,
              info: entry.original,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid card — matches InvoiceTemplateChooserScreen's/QuoteTemplateChooserScreen's
// _TemplateCard exactly, minus the "selected" state (this screen has no
// selection concept — tapping opens the "use as..." sheet directly).
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final _GalleryEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TemplateCard({
    required this.entry,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: entry.accentColor.withValues(alpha: entry.available ? 0.22 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                        top: 8, right: 8,
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
                              Text('PRO', style: TextStyle(
                                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
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
                                  color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        height: 3,
                        color: entry.accentColor.withValues(alpha: entry.available ? 1 : 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: entry.available
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.available)
                Icon(Icons.radio_button_off_rounded, size: 15, color: colorScheme.onSurface.withValues(alpha: 0.25)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            entry.tag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: entry.available
                  ? entry.accentColor
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}