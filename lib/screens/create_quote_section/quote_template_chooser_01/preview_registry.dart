// preview_registry.dart
// lib/screens/create_quote_section/quote_template_chooser_01/preview_registry.dart
//
// Central registry for quote layout templates. Mirrors
// invoice_create_section/invoice_template_chooser_01/preview_registry.dart's
// structure and its "render the real widget, not hand-drawn art" approach —
// buildQuotePreview() returns the actual layout widget at a fixed sample
// QuoteData, scaled down by the caller.
//
// UPDATED (this pass): Executive (id 1) is now a real, built layout under
// lib/quote_layout_templates/01_executive_quote_layout/ — mirrors
// lib/invoice_layout_templates/01_executive_cv_layout/ exactly. Its entry
// below is flipped to `available: true` and wired into buildQuotePreview().
// Every other entry is still a stub (`available: false`) — same "Coming
// Soon" starting point the invoice chooser had before the rest of its
// designs were built. To light one up: build its layout under
// lib/quote_layout_templates/0N_..._quote_layout/, flip that entry's
// `available` to true, and add its id as a case in buildQuotePreview()
// below — nothing else in this file or in quote_template_chooser_screen.dart
// needs to change.

import 'package:flutter/material.dart';
import '../../../models/quote_data.dart';
import '../../../models/invoice_data.dart' show LineItem;
import '../../../quote_layout_templates/01_executive_quote_layout/executive_quote_logic_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Template metadata model
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// All templates — ordered as they appear in the grid. Names/ids mirror the
// invoice registry's set so the two chooser grids stay visually consistent
// once designs are ported across. Executive is now built; the rest remain
// stubs until their own lib/quote_layout_templates/ folders are built.
// ─────────────────────────────────────────────────────────────────────────────
const List<QuoteTemplateInfo> kQuoteTemplates = [
  QuoteTemplateInfo(
    id: 1,
    name: 'Executive',
    description: 'Clean single-page layout, ready to send',
    tag: 'Minimal',
    accentColor: Color(0xFF2563EB),
    available: true,
  ),
  QuoteTemplateInfo(
    id: 2,
    name: 'Nordic',
    description: 'Coming soon',
    tag: 'Minimal',
    accentColor: Color(0xFF64748B),
  ),
  QuoteTemplateInfo(
    id: 3,
    name: 'Vibrant',
    description: 'Coming soon',
    tag: 'Creative',
    accentColor: Color(0xFFFF5C35),
  ),
  QuoteTemplateInfo(
    id: 4,
    name: 'Tech Dark',
    description: 'Coming soon',
    tag: 'Bold',
    accentColor: Color(0xFF58A6FF),
  ),
  QuoteTemplateInfo(
    id: 6,
    name: 'Gradient Modern',
    description: 'Coming soon',
    tag: 'Creative',
    accentColor: Color(0xFF7C3AED),
  ),
  QuoteTemplateInfo(
    id: 7,
    name: 'Editorial',
    description: 'Coming soon',
    tag: 'Bold',
    accentColor: Color(0xFFD0021B),
  ),
  QuoteTemplateInfo(
    id: 8,
    name: 'Pastel Soft',
    description: 'Coming soon',
    tag: 'Minimal',
    accentColor: Color(0xFF7C5CBF),
  ),
  QuoteTemplateInfo(
    id: 9,
    name: 'Brutalist',
    description: 'Coming soon',
    tag: 'Bold',
    accentColor: Color(0xFFFFE500),
  ),
  QuoteTemplateInfo(
    id: 10,
    name: 'Emerald',
    description: 'Coming soon',
    tag: 'Elegant',
    accentColor: Color(0xFF10B981),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Reference page size for scaled previews — matches kPageW/kPageH in
// executive_quote_stationary_layout.dart (standard A4 @ ~2x for crisp
// scaling). Kept as separate constants here (rather than importing the
// layout's) so this file doesn't have to import a specific template's
// geometry just to run the grid — same reasoning as before.
// ─────────────────────────────────────────────────────────────────────────────
const double kQuotePageW = 595.0;
const double kQuotePageH = 842.0;

// ─────────────────────────────────────────────────────────────────────────────
// Sample data used only for chooser previews — never persisted or shown
// to the end client.
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Preview builder — returns the real layout widget for available templates,
// or null for stub templates (caller renders the "Coming Soon" placeholder).
// ─────────────────────────────────────────────────────────────────────────────
Widget? buildQuotePreview(int templateId, QuoteData data) {
  switch (templateId) {
    case 1:
      return ExecutiveQuotePreview(data: data);
    default:
      return null; // no layout built yet for this id
  }
}
