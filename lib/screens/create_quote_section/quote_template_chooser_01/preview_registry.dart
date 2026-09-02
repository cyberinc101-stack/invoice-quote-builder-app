// preview_registry.dart
// lib/screens/create_quote_section/quote_template_chooser_01/preview_registry.dart
//
// METADATA SYNC PASS (this update): descriptions + swatches brought in
// line with the invoice registry (and with the templates' actual current
// designs, not earlier design eras):
//   - Executive: description unified to the invoice registry's wording
//     (more specific — names the diamond-logo mark).
//   - Nordic: was "Monochrome minimal, thin double rule..." — the real
//     header has no rule at all; it's a side-by-side Row (wordmark left,
//     client/meta right). Rewritten.
//   - Tech Dark: was still describing the retired terminal-chrome header
//     (dots, monospace "> label value" lines). Rewritten to the current
//     two-tone diagonal ribbon banner; swatch updated from the old
//     terminal blue (0xFF58A6FF) to the ribbon red (0xFFD62839).
//   - Gradient Modern: was vague/stale ("soft diagonal gradient band").
//     Rewritten to the current two-column + dark-to-accent curved banner
//     layout. Swatch unchanged (already matched invoice).
//   - Pastel Soft: was still describing the retired lavender chip-badge
//     era. Rewritten to the current accent-bar + dark item-table-header
//     design.
//   - Brutalist: was still describing the retired raw-border/thick-rule
//     design. Rewritten to the current angular dark ribbon block; swatch
//     updated from the old yellow (0xFFFFE500) to navy (0xFF1E3A5F).
//   - Emerald: was describing a hairline-rule design that doesn't match
//     the current compact corner-tag + centered-logo field stack.
//     Rewritten; tag left as 'Elegant' (already matched receipt).
// Vibrant, Classic, Editorial were already correct and already agreed
// across all three registries — left unchanged.
//
// Nordic (id 2) is built via the shared DocTemplateAdapter pattern
// (lib/document_layout_templates/) — the same Nordic design file used by
// the invoice registry, just converted through quoteToAdapter() instead
// of invoiceToAdapter() inside NordicQuotePreview. Everything from
// Vibrant onward follows the same pattern.

import 'package:flutter/material.dart';
import '../../../models/quote_data.dart';
import '../../../models/invoice_data.dart' show LineItem;
import '../../../document_layout_templates/01_executive/executive_template.dart';
import '../../../document_layout_templates/02_nordic/nordic_template.dart' show NordicQuotePreview;
import '../../../document_layout_templates/03_vibrant/vibrant_template.dart' show VibrantQuotePreview;
import '../../../document_layout_templates/04_tech_dark/tech_dark_template.dart' show TechDarkQuotePreview;
import '../../../document_layout_templates/05_classic/classic_template.dart' show ClassicQuotePreview;
import '../../../document_layout_templates/06_gradient_modern/gradient_modern_template.dart' show GradientModernQuotePreview;
import '../../../document_layout_templates/07_editorial/editorial_template.dart' show EditorialQuotePreview;
import '../../../document_layout_templates/08_pastel_soft/pastel_soft_template.dart' show PastelSoftQuotePreview;
import '../../../document_layout_templates/09_brutalist/brutalist_template.dart' show BrutalistQuotePreview;
import '../../../document_layout_templates/10_emerald/emerald_template.dart' show EmeraldQuotePreview;

// ─────────────────────────────────────────────────────────────────────────
// Template metadata model
// ─────────────────────────────────────────────────────────────────────────
class QuoteTemplateInfo {
  final int    id;
  final String name;
  final String description;
  final String tag;
  final Color  accentColor;
  final bool   isPremium;
  final bool   available; // false = "Coming Soon" placeholder card

  const QuoteTemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.tag,
    required this.accentColor,
    this.isPremium = false,
    this.available = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────
// All templates — ordered as they appear in the grid.
// ─────────────────────────────────────────────────────────────────────────
const List<QuoteTemplateInfo> kQuoteTemplates = [
  QuoteTemplateInfo(
    id: 1,
    name: 'Executive',
    description: 'Minimal diamond-logo mark, single page, generous whitespace',
    tag: 'Minimal',
    accentColor: Color(0xFF2563EB),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 2,
    name: 'Nordic',
    description: 'Side-by-side business/client blocks, wide letter-spaced wordmark, no rule',
    tag: 'Minimal',
    accentColor: Color(0xFF64748B),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 3,
    name: 'Vibrant',
    description: 'Bold accent color panel behind the identity block',
    tag: 'Creative',
    accentColor: Color(0xFFFF5C35),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 4,
    name: 'Tech Dark',
    description: 'Two-tone diagonal ribbon banner, layered corner accent',
    tag: 'Bold',
    accentColor: Color(0xFFD62839),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 5,
    name: 'Classic',
    description: 'Plain identity block, shaded line-item header, standard business format',
    tag: 'Minimal',
    accentColor: Color(0xFF334155),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 6,
    name: 'Gradient Modern',
    description: 'Two-column layout, dark-to-accent curved banner over line items',
    tag: 'Creative',
    accentColor: Color(0xFF7C3AED),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 7,
    name: 'Editorial',
    description: 'Bold masthead banner, letterhead-style double rule',
    tag: 'Bold',
    accentColor: Color(0xFFD0021B),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 8,
    name: 'Pastel Soft',
    description: 'Business/doc-type header split by a full-width accent bar, dark line-item table header',
    tag: 'Minimal',
    accentColor: Color(0xFF7C5CBF),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 9,
    name: 'Brutalist',
    description: 'Angular dark ribbon block behind recipient, table-style line items',
    tag: 'Bold',
    accentColor: Color(0xFF1E3A5F),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 10,
    name: 'Emerald',
    description: 'Corner doc-type tag, centered logo, compact single-column field stack led by Doc No.',
    tag: 'Elegant',
    accentColor: Color(0xFF10B981),
    available: true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────
const double kQuotePageW = 595.0;
const double kQuotePageH = 842.0;

// ─────────────────────────────────────────────────────────────────────────
// Sample data used only for chooser previews — never persisted or shown
// to the end client.
// ─────────────────────────────────────────────────────────────────────────
QuoteData sampleQuoteData() => QuoteData(
      businessName: 'Nova Studio Co.',
      businessEmail: 'hello@novastudio.com',
      businessPhone: '+1 555 010 2020',
      businessAddress: '48 Market Street, Auckland',
      clientName: 'Harper & Co.',
      clientEmail: 'accounts@harperco.com',
      clientAddress: '12 Queen Street, Wellington',
      quoteNumber: 'Q-1042',
      issueDate: '12 Jul 2026',
      expiryDate: '26 Jul 2026',
      currency: 'USD',
      lineItems: [
        LineItem(description: 'Brand strategy workshop', quantity: 1, unitPrice: 850),
        LineItem(description: 'Website design — 4 pages', quantity: 4, unitPrice: 220),
        LineItem(description: 'Revision rounds', quantity: 2, unitPrice: 90),
      ],
      taxRate: 8,
      discountRate: 5,
      quoteStatus: QuoteStatus.draft,
      notes: 'This quote is valid for 14 days. Thank you for considering us.',
    );

// ─────────────────────────────────────────────────────────────────────────
// Preview builder — returns the real layout widget for available templates,
// or null for stub templates (caller renders the "Coming Soon" placeholder).
// ─────────────────────────────────────────────────────────────────────────
Widget? buildQuotePreview(int templateId, QuoteData data) {
  switch (templateId) {
    case 1:
      return ExecutiveQuotePreview(data: data);
    case 2:
      return NordicQuotePreview(data: data);
    case 3:
      return VibrantQuotePreview(data: data);
    case 4:
      return TechDarkQuotePreview(data: data);
    case 5:
      return ClassicQuotePreview(data: data);
    case 6:
      return GradientModernQuotePreview(data: data);
    case 7:
      return EditorialQuotePreview(data: data);
    case 8:
      return PastelSoftQuotePreview(data: data);
    case 9:
      return BrutalistQuotePreview(data: data);
    case 10:
      return EmeraldQuotePreview(data: data);
    default:
      return null; // no layout built yet for this id
  }
}
