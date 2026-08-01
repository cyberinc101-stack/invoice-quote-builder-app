// preview_registry.dart
// lib/screens/invoice_create_section/invoice_template_chooser_01/preview_registry.dart
//
// Central registry for invoice layout templates. Mirrors the CV app's
// preview_registry.dart structure, but with one deliberate difference:
// there's no per-template hand-drawn mini illustration. Instead
// buildInvoicePreview() renders the REAL layout widget (e.g.
// ExecutiveInvoicePreview) at a fixed sample InvoiceData, scaled down by
// the caller. This means the chooser card can never drift out of sync
// with the actual PDF, and adding template #2 is just one registry
// entry — no separate mini-preview art to draw and maintain.
//
// Only `available: true` templates have a real layout behind them right
// now. The rest are stub folders already sitting on disk
// (02_nordic_cv_layout, 03_vibrant_cv_layout, etc.) — they show as
// "Coming Soon" in the chooser until their layout files are built, at
// which point: build the layout, then flip `available` to true and wire
// its id into buildInvoicePreview() below.

import 'package:flutter/material.dart';
import '../../../models/invoice_data.dart';
import '../../../invoice_layout_templates/01_executive_cv_layout/executive_cv_logic_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Template metadata model
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// All templates — ordered as they appear in the grid.
// IDs match the numeric prefix of each lib/invoice_layout_templates/ folder.
// ─────────────────────────────────────────────────────────────────────────────
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
    description: 'Coming soon',
    tag: 'Minimal',
    accentColor: Color(0xFF64748B),
  ),
  InvoiceTemplateInfo(
    id: 3,
    name: 'Vibrant',
    description: 'Coming soon',
    tag: 'Creative',
    accentColor: Color(0xFFFF5C35),
  ),
  InvoiceTemplateInfo(
    id: 4,
    name: 'Tech Dark',
    description: 'Coming soon',
    tag: 'Bold',
    accentColor: Color(0xFF58A6FF),
  ),
  InvoiceTemplateInfo(
    id: 6,
    name: 'Gradient Modern',
    description: 'Coming soon',
    tag: 'Creative',
    accentColor: Color(0xFF7C3AED),
  ),
  InvoiceTemplateInfo(
    id: 7,
    name: 'Editorial',
    description: 'Coming soon',
    tag: 'Bold',
    accentColor: Color(0xFFD0021B),
  ),
  InvoiceTemplateInfo(
    id: 8,
    name: 'Pastel Soft',
    description: 'Coming soon',
    tag: 'Minimal',
    accentColor: Color(0xFF7C5CBF),
  ),
  InvoiceTemplateInfo(
    id: 9,
    name: 'Brutalist',
    description: 'Coming soon',
    tag: 'Bold',
    accentColor: Color(0xFFFFE500),
  ),
  InvoiceTemplateInfo(
    id: 10,
    name: 'Emerald',
    description: 'Coming soon',
    tag: 'Elegant',
    accentColor: Color(0xFF10B981),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Sample data used only for chooser previews — never persisted or shown
// to the end client.
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Preview builder — returns the real layout widget for available templates,
// or null for stub templates (caller renders the "Coming Soon" placeholder).
// ─────────────────────────────────────────────────────────────────────────────
Widget? buildInvoicePreview(int templateId, InvoiceData data) {
  switch (templateId) {
    case 1:
      return ExecutiveInvoicePreview(data: data);
    default:
      return null; // no layout built yet for this id
  }
}
