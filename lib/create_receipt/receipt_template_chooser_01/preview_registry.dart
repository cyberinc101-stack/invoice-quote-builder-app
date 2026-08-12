// preview_registry.dart
// lib/create_receipt/receipt_template_chooser_01/preview_registry.dart
//
// Mirrors lib/screens/create_quote_section/quote_template_chooser_01/preview_registry.dart
// exactly. Unlike quote (which only has Executive + Nordic real so far),
// receipts already have real preview widgets for all 10 designs via
// receiptToAdapter() + the shared doc_templates/ files, so every template
// here is marked available: true from the start.

import 'package:flutter/material.dart';
import '../../models/receipt_data.dart';
import '../../models/invoice_data.dart' show LineItem;
import '../../receipt_layout_templates/01_executive_receipt_layout/executive_receipt_logic_data.dart';
import '../../doc_templates/02_nordic/nordic_template.dart' show NordicReceiptPreview;
import '../../doc_templates/03_vibrant/vibrant_template.dart' show VibrantReceiptPreview;
import '../../doc_templates/04_tech_dark/tech_dark_template.dart' show TechDarkReceiptPreview;
import '../../doc_templates/05_classic/classic_template.dart' show ClassicReceiptPreview;
import '../../doc_templates/06_gradient_modern/gradient_modern_template.dart' show GradientModernReceiptPreview;
import '../../doc_templates/07_editorial/editorial_template.dart' show EditorialReceiptPreview;
import '../../doc_templates/08_pastel_soft/pastel_soft_template.dart' show PastelSoftReceiptPreview;
import '../../doc_templates/09_brutalist/brutalist_template.dart' show BrutalistReceiptPreview;
import '../../doc_templates/10_emerald/emerald_template.dart' show EmeraldReceiptPreview;

// ─────────────────────────────────────────────────────────────────────────────
// Template metadata model
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// All templates — ordered as they appear in the grid.
// ─────────────────────────────────────────────────────────────────────────────
const List<ReceiptTemplateInfo> kReceiptTemplates = [
  ReceiptTemplateInfo(
    id: 1,
    name: 'Executive',
    description: 'Clean single-page layout, ready to send',
    tag: 'Minimal',
    accentColor: Color(0xFF2563EB),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 2,
    name: 'Nordic',
    description: 'Monochrome minimal, thin double rule, wide letter spacing',
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
    description: 'Near-black panel, accent rule, monospace doc tag',
    tag: 'Bold',
    accentColor: Color(0xFF58A6FF),
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
    description: 'Soft diagonal gradient band, airy and modern',
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
    description: 'Flat lavender tint panel, rounded corners, quiet and minimal',
    tag: 'Minimal',
    accentColor: Color(0xFF7C5CBF),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 9,
    name: 'Brutalist',
    description: 'Thick black borders, hard-edged accent block, high contrast',
    tag: 'Bold',
    accentColor: Color(0xFFFFE500),
    available: true,
  ),
  ReceiptTemplateInfo(
    id: 10,
    name: 'Emerald',
    description: 'Elegant deep-green accent, thin hairline rule, refined and quiet',
    tag: 'Elegant',
    accentColor: Color(0xFF10B981),
    available: true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Sample data used only for chooser previews — never persisted or shown
// to the end client.
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Preview builder — returns the real layout widget for available templates,
// or null for stub templates (caller renders the "Coming Soon" placeholder).
// ─────────────────────────────────────────────────────────────────────────────
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
