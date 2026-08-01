// quote_full_preview_screen.dart
// lib/screens/create_quote_section/quote_full_preview_screen.dart
//
// Mirrors invoice_full_preview_screen.dart, built against the real quote
// types: QuoteProvider, QuoteData, SavedQuote, QuotePdfService.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/quote_provider.dart';
import '../../models/quote_data.dart';
import '../../services/quote_pdf_service.dart';
import 'quote_preview_bottom_bar.dart';

class QuoteFullPreviewScreen extends StatefulWidget {
  const QuoteFullPreviewScreen({super.key});

  @override
  State<QuoteFullPreviewScreen> createState() => _QuoteFullPreviewScreenState();
}

class _QuoteFullPreviewScreenState extends State<QuoteFullPreviewScreen> {
  final _pdfService = QuotePdfService();
  bool _isLoading = false;

  // Wraps the live draft as a SavedQuote so it can go through the same
  // PDF path as a saved one, without actually persisting it.
  SavedQuote _wrapAsSavedQuote(QuoteData data) {
    final now = DateTime.now();
    return SavedQuote(
      id: 'preview_${now.millisecondsSinceEpoch}',
      title: data.businessName.isNotEmpty ? data.businessName : 'Quote',
      templateName: 'Standard',
      data: data,
      createdAt: now,
      lastEditedAt: now,
      completionPercent: 100,
    );
  }

  Future<void> _handleDownload() async {
    final data = context.read<QuoteProvider>().quoteData;
    setState(() => _isLoading = true);
    try {
      final path = await _pdfService.generateAndDownloadPDF(_wrapAsSavedQuote(data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleShare() async {
    final data = context.read<QuoteProvider>().quoteData;
    setState(() => _isLoading = true);
    try {
      await _pdfService.generateAndSharePDF(_wrapAsSavedQuote(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static Color _accentFromScheme(QuoteColor scheme) {
    const map = {
      QuoteColor.blue:   Color(0xFF1565C0),
      QuoteColor.green:  Color(0xFF2E7D32),
      QuoteColor.purple: Color(0xFF6A1B9A),
      QuoteColor.orange: Color(0xFFE65100),
      QuoteColor.red:    Color(0xFFC62828),
      QuoteColor.teal:   Color(0xFF00695C),
      QuoteColor.black:  Color(0xFF212121),
      QuoteColor.indigo: Color(0xFF283593),
    };
    return map[scheme] ?? const Color(0xFF6A1B9A);
  }

  static String _symbolFor(String code) {
    const symbols = {
      'USD': '\$',  'EUR': '€',   'GBP': '£',   'JPY': '¥',
      'AUD': 'A\$', 'CAD': 'C\$', 'NZD': 'NZ\$','CHF': 'Fr',
      'CNY': '¥',   'INR': '₹',   'KRW': '₩',   'SGD': 'S\$',
      'HKD': 'HK\$','SEK': 'kr',  'NOK': 'kr',  'DKK': 'kr',
      'MXN': '\$',  'BRL': 'R\$', 'ZAR': 'R',   'AED': 'د.إ',
    };
    return symbols[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    final data   = context.watch<QuoteProvider>().quoteData;
    final accent = _accentFromScheme(data.colorScheme);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _QuoteDocument(data: data, accent: accent, symbol: _symbolFor(data.currency)),
      ),
      bottomNavigationBar: QuotePreviewBottomBar(
        accent: accent,
        isLoading: _isLoading,
        onExport: _handleDownload,
        onShare: _handleShare,
      ),
    );
  }
}

// ── Full-page quote document preview ────────────────────────────────────

class _QuoteDocument extends StatelessWidget {
  final QuoteData data;
  final Color accent;
  final String symbol;

  const _QuoteDocument({required this.data, required this.accent, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final hasCustomer = data.clientName.isNotEmpty ||
        data.clientEmail.isNotEmpty ||
        data.clientPhone.isNotEmpty ||
        data.clientAddress.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: accent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.businessName.isNotEmpty)
                        Text(data.businessName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      if (data.businessEmail.isNotEmpty)
                        Text(data.businessEmail, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                      if (data.businessPhone.isNotEmpty)
                        Text(data.businessPhone, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                      if (data.businessAddress.isNotEmpty)
                        Text(data.businessAddress, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('QUOTE',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    if (data.quoteNumber.isNotEmpty)
                      Text('#${data.quoteNumber}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                    if (data.issueDate.isNotEmpty)
                      Text(data.issueDate, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10)),
                    if (data.expiryDate.isNotEmpty)
                      Text('Valid until: ${data.expiryDate}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCustomer) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PREPARED FOR',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        if (data.clientName.isNotEmpty)
                          Text(data.clientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        if (data.clientEmail.isNotEmpty) Text(data.clientEmail, style: const TextStyle(fontSize: 11)),
                        if (data.clientPhone.isNotEmpty) Text(data.clientPhone, style: const TextStyle(fontSize: 11)),
                        if (data.clientAddress.isNotEmpty) Text(data.clientAddress, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Line item table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: accent.withOpacity(0.09), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                      SizedBox(width: 50, child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                      SizedBox(width: 70, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                      SizedBox(width: 70, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                    ],
                  ),
                ),
                ...data.lineItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: Text(item.description, style: const TextStyle(fontSize: 12))),
                        SizedBox(
                          width: 50,
                          child: Text(
                            item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(width: 70, child: Text('$symbol${fmt.format(item.unitPrice)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        SizedBox(width: 70, child: Text('$symbol${fmt.format(item.total)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),

                // Totals — sourced from QuoteData's own getters, matching
                // exactly what QuotePdfService puts in the PDF.
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        _totalRow('Subtotal', '$symbol${fmt.format(data.subtotal)}'),
                        if (data.taxRate > 0)
                          _totalRow('Tax (${_fmtPct(data.taxRate)}%)', '+$symbol${fmt.format(data.taxAmount)}'),
                        if (data.discountRate > 0)
                          _totalRow('Discount (${_fmtPct(data.discountRate)}%)', '-$symbol${fmt.format(data.discountAmount)}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ESTIMATED TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('$symbol${fmt.format(data.grandTotal)}',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: accent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (data.notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Notes / Terms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: accent)),
                  const SizedBox(height: 4),
                  Text(data.notes, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtPct(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  static Widget _totalRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            Text(value, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}
