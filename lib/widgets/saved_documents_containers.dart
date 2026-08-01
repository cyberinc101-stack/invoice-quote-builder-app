// saved_documents_containers.dart
// lib/widgets/saved_documents_containers.dart
//
// UPDATED (this pass): _demoInvoices()/_demoQuotes()/_demoReceipts() and
// their .isEmpty ? demo() : ... fallbacks have been removed — this widget
// now only ever renders real saved invoices/quotes/receipts. An empty
// category (or an empty combined list) falls through to the existing
// _EmptyState instead of fake placeholder cards.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../models/invoice_data.dart';
import '../models/quote_data.dart';
import '../models/receipt_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared types
// ─────────────────────────────────────────────────────────────────────────────

enum DocType { invoice, quote, receipt }

enum DocFilter { all, invoices, quotes, receipts }

enum DocSortOption { mostRecent, alphabetical, lastEdited, byType }

class _UnifiedDoc {
  final DocType type;
  final String id;
  final String title;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final double amount;
  final String currency;
  final DateTime date;
  final SavedInvoice? invoice;
  final SavedQuote? quote;
  final SavedReceipt? receipt;

  _UnifiedDoc({
    required this.type,
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.amount,
    required this.currency,
    required this.date,
    this.invoice,
    this.quote,
    this.receipt,
  });
}

const Color kInvoiceAccent = Color(0xFF2196F3);
const Color kQuoteAccent   = Color(0xFF9C27B0);
const Color kReceiptAccent = Color(0xFF4CAF50);

Color _accentFor(DocType type) {
  switch (type) {
    case DocType.invoice: return kInvoiceAccent;
    case DocType.quote:   return kQuoteAccent;
    case DocType.receipt: return kReceiptAccent;
  }
}

IconData _iconFor(DocType type) {
  switch (type) {
    case DocType.invoice: return Icons.receipt_long_rounded;
    case DocType.quote:   return Icons.request_quote_rounded;
    case DocType.receipt: return Icons.receipt_rounded;
  }
}

String _labelFor(DocType type) {
  switch (type) {
    case DocType.invoice: return 'Invoice';
    case DocType.quote:   return 'Quote';
    case DocType.receipt: return 'Receipt';
  }
}

String _formatDate(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String _formatAmount(double amount, String currency) {
  return '$currency ${amount.toStringAsFixed(2)}';
}

// ── Status mapping per type ─────────────────────────────────────────────────

({String label, Color color, IconData icon}) _invoiceStatusInfo(PaymentStatus s) {
  switch (s) {
    case PaymentStatus.paid:
      return (label: 'Paid', color: const Color(0xFF4CAF50), icon: Icons.check_circle_rounded);
    case PaymentStatus.partial:
      return (label: 'Partial', color: const Color(0xFF2196F3), icon: Icons.timelapse_rounded);
    case PaymentStatus.overdue:
      return (label: 'Overdue', color: const Color(0xFFE53935), icon: Icons.error_rounded);
    case PaymentStatus.unpaid:
      return (label: 'Unpaid', color: const Color(0xFFFF9800), icon: Icons.schedule_rounded);
  }
}

({String label, Color color, IconData icon}) _quoteStatusInfo(QuoteStatus s) {
  switch (s) {
    case QuoteStatus.accepted:
      return (label: 'Accepted', color: const Color(0xFF4CAF50), icon: Icons.check_circle_rounded);
    case QuoteStatus.sent:
      return (label: 'Sent', color: const Color(0xFF2196F3), icon: Icons.send_rounded);
    case QuoteStatus.declined:
      return (label: 'Declined', color: const Color(0xFFE53935), icon: Icons.cancel_rounded);
    case QuoteStatus.expired:
      return (label: 'Expired', color: const Color(0xFF9E9E9E), icon: Icons.event_busy_rounded);
    case QuoteStatus.draft:
      return (label: 'Draft', color: const Color(0xFFFF9800), icon: Icons.edit_rounded);
  }
}

({String label, Color color, IconData icon}) _receiptStatusInfo(ReceiptStatus s) {
  switch (s) {
    case ReceiptStatus.issued:
      return (label: 'Issued', color: const Color(0xFF4CAF50), icon: Icons.check_circle_rounded);
    case ReceiptStatus.refunded:
      return (label: 'Refunded', color: const Color(0xFFE53935), icon: Icons.replay_rounded);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class SavedDocumentsContainers extends StatefulWidget {
  final void Function(SavedInvoice)? onTapInvoice;
  final void Function(SavedQuote)? onTapQuote;
  final void Function(SavedReceipt)? onTapReceipt;
  final DocSortOption sortOption;

  const SavedDocumentsContainers({
    super.key,
    this.onTapInvoice,
    this.onTapQuote,
    this.onTapReceipt,
    this.sortOption = DocSortOption.mostRecent,
  });

  @override
  State<SavedDocumentsContainers> createState() => _SavedDocumentsContainersState();
}

class _SavedDocumentsContainersState extends State<SavedDocumentsContainers> {
  DocFilter _selectedFilter = DocFilter.all;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer3<InvoiceProvider, QuoteProvider, ReceiptProvider>(
      builder: (context, invoiceProvider, quoteProvider, receiptProvider, _) {
        final invoiceDocs = invoiceProvider.savedInvoices.map((inv) {
          final info = _invoiceStatusInfo(inv.data.paymentStatus);
          return _UnifiedDoc(
            type: DocType.invoice,
            id: inv.id,
            title: inv.title,
            statusLabel: info.label,
            statusColor: info.color,
            statusIcon: info.icon,
            amount: inv.data.grandTotal,
            currency: inv.data.currency,
            date: inv.lastEditedAt,
            invoice: inv,
          );
        }).toList();

        final quoteDocs = quoteProvider.savedQuotes.map((q) {
          final info = _quoteStatusInfo(q.data.quoteStatus);
          return _UnifiedDoc(
            type: DocType.quote,
            id: q.id,
            title: q.title,
            statusLabel: info.label,
            statusColor: info.color,
            statusIcon: info.icon,
            amount: q.data.grandTotal,
            currency: q.data.currency,
            date: q.lastEditedAt,
            quote: q,
          );
        }).toList();

        final receiptDocs = receiptProvider.savedReceipts.map((r) {
          final info = _receiptStatusInfo(r.data.status);
          return _UnifiedDoc(
            type: DocType.receipt,
            id: r.id,
            title: r.title,
            statusLabel: info.label,
            statusColor: info.color,
            statusIcon: info.icon,
            amount: r.data.amountPaid,
            currency: r.data.currency,
            date: r.lastEditedAt,
            receipt: r,
          );
        }).toList();

        List<_UnifiedDoc> combined;
        switch (_selectedFilter) {
          case DocFilter.all:
            combined = [...invoiceDocs, ...quoteDocs, ...receiptDocs];
            break;
          case DocFilter.invoices:
            combined = invoiceDocs;
            break;
          case DocFilter.quotes:
            combined = quoteDocs;
            break;
          case DocFilter.receipts:
            combined = receiptDocs;
            break;
        }
        switch (widget.sortOption) {
          case DocSortOption.mostRecent:
          case DocSortOption.lastEdited:
            combined.sort((a, b) => b.date.compareTo(a.date));
            break;
          case DocSortOption.alphabetical:
            combined.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
            break;
          case DocSortOption.byType:
            combined.sort((a, b) {
              final typeCompare = a.type.index.compareTo(b.type.index);
              if (typeCompare != 0) return typeCompare;
              return b.date.compareTo(a.date);
            });
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Saved Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _FilterBar(
              selectedFilter: _selectedFilter,
              onFilterChanged: (f) => setState(() => _selectedFilter = f),
              counts: {
                DocFilter.all: invoiceDocs.length + quoteDocs.length + receiptDocs.length,
                DocFilter.invoices: invoiceDocs.length,
                DocFilter.quotes: quoteDocs.length,
                DocFilter.receipts: receiptDocs.length,
              },
            ),
            const SizedBox(height: 16),
            if (combined.isEmpty)
              const _EmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: combined.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _DocCard(
                  key: ValueKey('${combined[i].type}_${combined[i].id}'),
                  doc: combined[i],
                  onTap: () {
                    final doc = combined[i];
                    if (doc.type == DocType.invoice && doc.invoice != null) {
                      widget.onTapInvoice?.call(doc.invoice!);
                    } else if (doc.type == DocType.quote && doc.quote != null) {
                      widget.onTapQuote?.call(doc.quote!);
                    } else if (doc.type == DocType.receipt && doc.receipt != null) {
                      widget.onTapReceipt?.call(doc.receipt!);
                    }
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final DocFilter selectedFilter;
  final ValueChanged<DocFilter> onFilterChanged;
  final Map<DocFilter, int> counts;

  const _FilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      (DocFilter.all, 'All', Icons.grid_view_rounded, colorScheme.primary),
      (DocFilter.invoices, 'Invoices', Icons.receipt_long_rounded, kInvoiceAccent),
      (DocFilter.quotes, 'Quotes', Icons.request_quote_rounded, kQuoteAccent),
      (DocFilter.receipts, 'Receipts', Icons.receipt_rounded, kReceiptAccent),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label, icon, color) = filters[index];
          final isSelected = selectedFilter == filter;
          final count = counts[filter] ?? 0;

          final chipBg = isSelected
              ? color
              : (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5));
          final textColor = isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.55);
          final badgeBg = isSelected ? Colors.white.withOpacity(0.2) : colorScheme.onSurface.withOpacity(0.1);
          final badgeText = isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.45);

          return GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: textColor),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: textColor)),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                    child: Text('$count',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeText)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Doc card ─────────────────────────────────────────────────────────────────

class _DocCard extends StatelessWidget {
  final _UnifiedDoc doc;
  final VoidCallback onTap;
  const _DocCard({super.key, required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(doc.type);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? accent.withOpacity(0.18) : const Color(0xFFF0F0F0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(isDark ? 0.12 : 0.08), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.04), blurRadius: 4, offset: const Offset(0, 1)),
        ],
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: accent.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Icon(_iconFor(doc.type), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.label_rounded, size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(_labelFor(doc.type),
                            style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 12, color: colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(width: 3),
                        Text(_formatDate(doc.date),
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.35))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatAmount(doc.amount, doc.currency),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: doc.statusColor.withOpacity(isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(doc.statusIcon, size: 10, color: doc.statusColor),
                    const SizedBox(width: 3),
                    Text(doc.statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: doc.statusColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state (shown when the filtered list has no real documents) ─────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.description_outlined, size: 36, color: colorScheme.onSurface.withOpacity(0.3)),
            ),
            const SizedBox(height: 16),
            Text('No documents yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withOpacity(0.55))),
            const SizedBox(height: 6),
            Text('Create an invoice, quote, or receipt to see it here',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.35))),
          ],
        ),
      ),
    );
  }
}