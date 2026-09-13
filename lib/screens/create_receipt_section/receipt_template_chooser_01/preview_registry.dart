// preview_registry.dart
// lib/create_receipt/receipt_template_chooser_01/preview_registry.dart
//
// MERGE PASS (this update): the EXECUTIVE PREVIEW ROUTING FIX workaround
// (hiding ExecutiveReceiptPreview from executive_template.dart and
// reimporting a "real" one from executive_receipt_logic_data.dart) is
// REMOVED — see invoice_template_previews/preview_registry.dart's
// identical note for the full reasoning. executive_template.dart's
// ExecutiveReceiptPreview now renders the Signature block itself (via
// shared_doc_widgets.dart's buildSharedTotalsAndNotesSection), and the
// file this workaround used to reach into
// (executive_receipt_logic_data.dart) no longer exists.
//
// Everything else (metadata, sample data, switch statement) is
// UNCHANGED from the previous version of this file.

import 'package:flutter/material.dart';
import '../../../models/receipt_data.dart';
import '../../../models/invoice_data.dart' show LineItem;
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show ExecutiveReceiptPreview;
import '../../../document_layout_templates/02_nordic/nordic_template.dart' show NordicReceiptPreview;
import '../../../document_layout_templates/03_vibrant/vibrant_template.dart' show VibrantReceiptPreview;
import '../../../document_layout_templates/04_tech_dark/tech_dark_template.dart' show TechDarkReceiptPreview;
import '../../../document_layout_templates/05_classic/classic_template.dart' show ClassicReceiptPreview;
import '../../../document_layout_templates/06_gradient_modern/gradient_modern_template.dart' show GradientModernReceiptPreview;
import '../../../document_layout_templates/07_editorial/editorial_template.dart' show EditorialReceiptPreview;
import '../../../document_layout_templates/08_pastel_soft/pastel_soft_template.dart' show PastelSoftReceiptPreview;
import '../../../document_layout_templates/09_brutalist/brutalist_template.dart' show BrutalistReceiptPreview;
import '../../../document_layout_templates/10_emerald/emerald_template.dart' show EmeraldReceiptPreview;

// -----------------------------------------------------------------------------
// Template metadata model
// -----------------------------------------------------------------------------
class ReceiptTemplateInfo {
  final int    id;
  final String name;
  final String description;
  final String tag;
  final Color  accentColor;
  final bool   isPremium;
  final bool   available; // false = "Coming Soon" placeholder card

  const ReceiptTemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.tag,
    required this.accentColor,
    this.isPremium = false,
    this.available = false,
  });
}

// -----------------------------------------------------------------------------
// All templates — ordered as they appear in the grid.
// -----------------------------------------------------------------------------
const List<ReceiptTemplateInfo> kReceiptTemplates = [
  ReceiptTemplateInfo(
    id: 1,
    name: 'Executive',
    description: 'Minimal diamond-logo mark, single page, generous whitespace',
    tag: 'Minimal',
    accentColor: Color(0xFF2563EB),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 2,
    name: 'Nordic',
    description: 'Side-by-side business/client blocks, wide letter-spaced wordmark, no rule',
    tag: 'Minimal',
    accentColor: Color(0xFF64748B),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 3,
    name: 'Vibrant',
    description: 'Bold accent color panel behind the identity block',
    tag: 'Creative',
    accentColor: Color(0xFFFF5C35),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 4,
    name: 'Tech Dark',
    description: 'Two-tone diagonal ribbon banner, layered corner accent',
    tag: 'Bold',
    accentColor: Color(0xFFD62839),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 5,
    name: 'Classic',
    description: 'Plain identity block, shaded line-item header, standard business format',
    tag: 'Minimal',
    accentColor: Color(0xFF334155),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 6,
    name: 'Gradient Modern',
    description: 'Two-column layout, dark-to-accent curved banner over line items',
    tag: 'Creative',
    accentColor: Color(0xFF7C3AED),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 7,
    name: 'Editorial',
    description: 'Bold masthead banner, letterhead-style double rule',
    tag: 'Bold',
    accentColor: Color(0xFFD0021B),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 8,
    name: 'Pastel Soft',
    description: 'Business/doc-type header split by a full-width accent bar, dark line-item table header',
    tag: 'Minimal',
    accentColor: Color(0xFF7C5CBF),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 9,
    name: 'Brutalist',
    description: 'Angular dark ribbon block behind recipient, table-style line items',
    tag: 'Bold',
    accentColor: Color(0xFF1E3A5F),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 10,
    name: 'Emerald',
    description: 'Corner doc-type tag, centered logo, compact single-column field stack led by Doc No.',
    tag: 'Elegant',
    accentColor: Color(0xFF10B981),
    available: true,
  ),
];

// -----------------------------------------------------------------------------
// Sample data used only for chooser previews — never persisted or shown
// to the end client.
// -----------------------------------------------------------------------------
ReceiptData sampleReceiptData() => ReceiptData(
      businessName: 'Nova Studio Co.',
      businessEmail: 'hello@novastudio.com',
      businessPhone: '+1 555 010 2020',
      businessAddress: '48 Market Street, Auckland',
      clientName: 'Harper & Co.',
      clientEmail: 'accounts@harperco.com',
      clientPhone: '+1 555 070 3030',
      clientAddress: '12 Queen Street, Wellington',
      receiptNumber: 'R-1042',
      paymentDate: '12 Jul 2026',
      currency: 'USD',
      lineItems: [
        LineItem(description: 'Brand strategy workshop', quantity: 1, unitPrice: 850),
        LineItem(description: 'Website design — 4 pages', quantity: 4, unitPrice: 220),
        LineItem(description: 'Revision rounds', quantity: 2, unitPrice: 90),
      ],
      taxRate: 8,
      discountRate: 5,
      paymentMethod: PaymentMethod.card,
      status: ReceiptStatus.issued,
      notes: 'Thank you for your payment. This receipt confirms your transaction.',
    );

// -----------------------------------------------------------------------------
// Preview builder — returns the real layout widget for available templates,
// or null for stub templates (caller renders the "Coming Soon" placeholder).
// -----------------------------------------------------------------------------
Widget? buildReceiptPreview(int templateId, ReceiptData data) {
  switch (templateId) {
    case 1:
      return ExecutiveReceiptPreview(data: data);
    case 2:
      return NordicReceiptPreview(data: data);
    case 3:
      return VibrantReceiptPreview(data: data);
    case 4:
      return TechDarkReceiptPreview(data: data);
    case 5:
      return ClassicReceiptPreview(data: data);
    case 6:
      return GradientModernReceiptPreview(data: data);
    case 7:
      return EditorialReceiptPreview(data: data);
    case 8:
      return PastelSoftReceiptPreview(data: data);
    case 9:
      return BrutalistReceiptPreview(data: data);
    case 10:
      return EmeraldReceiptPreview(data: data);
    default:
      return null; // no layout built yet for this id
  }
}
