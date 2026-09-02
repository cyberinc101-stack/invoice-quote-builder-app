// preview_registry.dart
// lib/screens/invoice_create_section/invoice_template_previews/preview_registry.dart
//
// METADATA SYNC PASS (this update): Nordic (2), Pastel Soft (8), and
// Emerald (10) descriptions rewritten to match their actual current
// headers instead of stale/earlier-era wording — Nordic is now a
// side-by-side Row with no rule (was described as stacked/no-side-by-side,
// the opposite of the real layout); Pastel Soft is now an accent-bar +
// dark item-table-header design (was still describing the old lavender
// chip-badge era); Emerald is now a compact corner-tag + centered-logo
// single-column field stack (was describing a three-column bill-to/from
// row that no longer exists). Emerald's tag also changed Formal -> Elegant
// to match quote/receipt (2 of 3 registries already used Elegant).
// These same three fixes + the swatch updates below were also applied to
// the quote and receipt registries so all three agree with each other.
//
// Earlier update: Tech Dark (id 4) and Gradient Modern (id 6)
// descriptions/swatch updated to match their redesigned headers — Tech
// Dark moved from the old terminal-chrome look to a two-tone diagonal
// ribbon banner (accent swatch updated from the old terminal blue to a
// red matching the new ribbon), and Gradient Modern moved from the
// stat-card dashboard row to a two-column layout with a dark-to-accent
// curved banner. Both are still built via the shared DocTemplateAdapter
// pattern — only the gallery metadata below changed, not how they're
// wired into the switch.
//
// Everything else unchanged: Nordic (id 2) is built via the shared
// DocTemplateAdapter pattern (lib/document_layout_templates/) rather than
// a hand-copied invoice-only file. Everything from Vibrant onward follows
// the same pattern: one file under lib/document_layout_templates/0N_<name>/,
// exporting <Name>InvoicePreview / <Name>QuotePreview / <Name>ReceiptPreview.

import 'package:flutter/material.dart';
import '../../../models/invoice_data.dart';
import '../../../document_layout_templates/01_executive/executive_template.dart';
import '../../../document_layout_templates/02_nordic/nordic_template.dart' show NordicInvoicePreview;
import '../../../document_layout_templates/03_vibrant/vibrant_template.dart' show VibrantInvoicePreview;
import '../../../document_layout_templates/04_tech_dark/tech_dark_template.dart' show TechDarkInvoicePreview;
import '../../../document_layout_templates/05_classic/classic_template.dart' show ClassicInvoicePreview;
import '../../../document_layout_templates/06_gradient_modern/gradient_modern_template.dart' show GradientModernInvoicePreview;
import '../../../document_layout_templates/07_editorial/editorial_template.dart' show EditorialInvoicePreview;
import '../../../document_layout_templates/08_pastel_soft/pastel_soft_template.dart' show PastelSoftInvoicePreview;
import '../../../document_layout_templates/09_brutalist/brutalist_template.dart' show BrutalistInvoicePreview;
import '../../../document_layout_templates/10_emerald/emerald_template.dart' show EmeraldInvoicePreview;

// ─────────────────────────────────────────────────────────────────────────
// Template metadata model
// ─────────────────────────────────────────────────────────────────────────
class InvoiceTemplateInfo {
  final int    id;
  final String name;
  final String description;
  final String tag;
  final Color  accentColor;
  final bool   isPremium;
  final bool   available; // false = "Coming Soon" placeholder card

  const InvoiceTemplateInfo({
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
const List<InvoiceTemplateInfo> kInvoiceTemplates = [
  InvoiceTemplateInfo(
    id: 1,
    name: 'Executive',
    description: 'Minimal diamond-logo mark, single page, generous whitespace',
    tag: 'Minimal',
    accentColor: Color(0xFF2563EB),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 2,
    name: 'Nordic',
    description: 'Side-by-side business/client blocks, wide letter-spaced wordmark, no rule',
    tag: 'Minimal',
    accentColor: Color(0xFF64748B),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 3,
    name: 'Vibrant',
    description: 'Bold accent color panel behind the identity block',
    tag: 'Creative',
    accentColor: Color(0xFFFF5C35),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 4,
    name: 'Tech Dark',
    description: 'Two-tone diagonal ribbon banner, layered corner accent',
    tag: 'Bold',
    accentColor: Color(0xFFD62839),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 5,
    name: 'Classic',
    description: 'Plain identity block, shaded line-item header, standard business format',
    tag: 'Minimal',
    accentColor: Color(0xFF334155),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 6,
    name: 'Gradient Modern',
    description: 'Two-column layout, dark-to-accent curved banner over line items',
    tag: 'Creative',
    accentColor: Color(0xFF7C3AED),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 7,
    name: 'Editorial',
    description: 'Bold masthead banner, letterhead-style double rule',
    tag: 'Bold',
    accentColor: Color(0xFFD0021B),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 8,
    name: 'Pastel Soft',
    description: 'Business/doc-type header split by a full-width accent bar, dark line-item table header',
    tag: 'Minimal',
    accentColor: Color(0xFF7C5CBF),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 9,
    name: 'Brutalist',
    description: 'Angular dark ribbon block behind recipient, table-style line items',
    tag: 'Bold',
    accentColor: Color(0xFF1E3A5F),
    available: true,
  ),
  InvoiceTemplateInfo(
    id: 10,
    name: 'Emerald',
    description: 'Corner doc-type tag, centered logo, compact single-column field stack led by Doc No.',
    tag: 'Elegant',
    accentColor: Color(0xFF10B981),
    available: true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────
// Sample data used only for chooser previews — never persisted or shown
// to the end client.
// ─────────────────────────────────────────────────────────────────────────
InvoiceData sampleInvoiceData() => InvoiceData(
      businessName: 'Nova Studio Co.',
      businessEmail: 'hello@novastudio.com',
      businessPhone: '+1 555 010 2020',
      businessAddress: '48 Market Street, Auckland',
      clientName: 'Harper & Co.',
      clientEmail: 'accounts@harperco.com',
      clientAddress: '12 Queen Street, Wellington',
      invoiceNumber: 'INV-1042',
      issueDate: '12 Jul 2026',
      dueDate: '26 Jul 2026',
      currency: 'USD',
      lineItems: [
        LineItem(description: 'Brand strategy workshop', quantity: 1, unitPrice: 850),
        LineItem(description: 'Website design — 4 pages', quantity: 4, unitPrice: 220),
        LineItem(description: 'Revision rounds', quantity: 2, unitPrice: 90),
      ],
      taxRate: 8,
      discountRate: 5,
      paymentStatus: PaymentStatus.unpaid,
      notes: 'Payment due within 14 days. Thank you for your business.',
    );

// ─────────────────────────────────────────────────────────────────────────
// Preview builder — returns the real layout widget for available templates,
// or null for stub templates (caller renders the "Coming Soon" placeholder).
// ─────────────────────────────────────────────────────────────────────────
Widget? buildInvoicePreview(int templateId, InvoiceData data) {
  switch (templateId) {
    case 1:
      return ExecutiveInvoicePreview(data: data);
    case 2:
      return NordicInvoicePreview(data: data);
    case 3:
      return VibrantInvoicePreview(data: data);
    case 4:
      return TechDarkInvoicePreview(data: data);
    case 5:
      return ClassicInvoicePreview(data: data);
    case 6:
      return GradientModernInvoicePreview(data: data);
    case 7:
      return EditorialInvoicePreview(data: data);
    case 8:
      return PastelSoftInvoicePreview(data: data);
    case 9:
      return BrutalistInvoicePreview(data: data);
    case 10:
      return EmeraldInvoicePreview(data: data);
    default:
      return null; // no layout built yet for this id
  }
}
