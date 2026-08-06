// gradient_modern_template.dart
// lib/doc_templates/06_gradient_modern/gradient_modern_template.dart
//
// Gradient Modern: soft diagonal two-tone gradient band behind the
// identity block - the accent color blends into a lighter tint of
// itself (not a hard color fill like Vibrant, and not a dark panel like
// Tech Dark). Business name stays in dark ink for an airy, modern feel
// rather than a loud one. A thin accent-colored corner accent marks the
// doc type/number block.
//
// Everything below the header (line items, totals, notes, footer) comes
// from shared_doc_widgets.dart unchanged.

import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData;
import '../../models/quote_data.dart' show QuoteData;
import '../../models/receipt_data.dart' show ReceiptData;
import '../shared/doc_template_adapter.dart';
import '../shared/shared_doc_widgets.dart';

// -----------------------------------------------------------------------
// Header design
// -----------------------------------------------------------------------

BoxDecoration _gradientPanelDecoration(Color accent, {double radius = 10}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent.withOpacity(0.16),
        accent.withOpacity(0.04),
      ],
    ),
  );
}

Widget _gradientModernFullHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: _gradientPanelDecoration(a.accent),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a.businessName.isEmpty ? 'Your Business' : a.businessName,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: kInk, letterSpacing: 0.2, fontFamily: a.fontFamily),
                  ),
                  const SizedBox(height: 6),
                  if (a.businessAddress.isNotEmpty)
                    Text(a.businessAddress, style: TextStyle(fontSize: 9,
                        color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
                  if (a.businessEmail.isNotEmpty || a.businessPhone.isNotEmpty)
                    Text([a.businessEmail, a.businessPhone].where((s) => s.isNotEmpty).join('   ·   '),
                        style: TextStyle(fontSize: 9, color: kGrey, fontFamily: a.fontFamily)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.docTypeLabel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: a.accent, letterSpacing: 0.6, fontFamily: a.fontFamily)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: a.accent.withOpacity(0.35), width: 1),
                  ),
                  child: Text('#${a.docNumber.isEmpty ? '-' : a.docNumber}',
                      style: TextStyle(fontSize: 9.5, color: a.accent,
                          fontWeight: FontWeight.w700, fontFamily: a.fontFamily)),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _GradientModernMetaRow(a: a),
      const SizedBox(height: 24),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

Widget _gradientModernContinuationHeader(DocTemplateAdapter a) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: _gradientPanelDecoration(a.accent, radius: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                    color: kInk, fontFamily: a.fontFamily)),
            Text('${a.docTypeLabel} #${a.docNumber.isEmpty ? '-' : a.docNumber} ${a.continuationSuffix}',
                style: TextStyle(fontSize: 9.5, color: a.accent, fontFamily: a.fontFamily)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      buildSharedLineItemsHeaderRow(accent: a.accent, ff: a.fontFamily),
    ],
  );
}

class _GradientModernMetaRow extends StatelessWidget {
  final DocTemplateAdapter a;
  const _GradientModernMetaRow({required this.a});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.recipientLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                  color: a.accent, letterSpacing: 1.4, fontFamily: a.fontFamily)),
              const SizedBox(height: 8),
              Text(a.clientName.isEmpty ? 'Client name' : a.clientName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk, fontFamily: a.fontFamily),
                  softWrap: true, overflow: TextOverflow.visible),
              if (a.clientAddress.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(a.clientAddress, style: TextStyle(fontSize: 9.5, color: kGrey, height: 1.4, fontFamily: a.fontFamily)),
              ],
              if (a.clientEmail.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(a.clientEmail, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
              ],
              if (a.clientPhone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(a.clientPhone, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: a.fontFamily)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _metaRow(a.metaLabel1, a.metaValue1, a.fontFamily),
              const SizedBox(height: 6),
              _metaRow(a.metaLabel2, a.metaValue2, a.fontFamily),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: a.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: a.statusColor.withOpacity(0.4), width: 1),
                ),
                child: Text(a.statusLabel, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                    letterSpacing: 1.0, color: a.statusColor, fontFamily: a.fontFamily)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value, String ff) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 9.5, color: kGrey, fontFamily: ff)),
      Text(value.isEmpty ? '-' : value,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kInk, fontFamily: ff)),
    ],
  );
}

// -----------------------------------------------------------------------
// Preview wrappers - one per doc type, each ~5 lines: convert to the
// adapter, hand off to TemplateDocument. These are what preview_registry
// files (invoice / quote / receipt) import and wire into their id switch.
// -----------------------------------------------------------------------

class GradientModernInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        onPageCount: onPageCount,
      );
}

class GradientModernQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernQuotePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        onPageCount: onPageCount,
      );
}

class GradientModernReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const GradientModernReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: _gradientModernFullHeader,
        buildContinuationHeader: _gradientModernContinuationHeader,
        onPageCount: onPageCount,
      );
}
