// client_dashboard_screen.dart
// lib/screens/clients/client_dashboard_screen.dart
//
// Read-only dashboard: one card per client, aggregated across their saved
// invoices/quotes/receipts via client_aggregator.dart. Sorted by
// totalOutstanding descending by default (surfaces who owes money first),
// with a menu to sort by total billed or most recent activity instead.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../clients/client_aggregator.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/receipt_provider.dart';

const Color kClientsAccent = Color(0xFF5E35B1);

enum _ClientSort { outstanding, billed, recent }

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  _ClientSort _sort = _ClientSort.outstanding;

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().savedInvoices;
    final quotes = context.watch<QuoteProvider>().savedQuotes;
    final receipts = context.watch<ReceiptProvider>().savedReceipts;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final summaries = buildClientSummaries(
      invoices: invoices,
      quotes: quotes,
      receipts: receipts,
    );

    switch (_sort) {
      case _ClientSort.outstanding:
        summaries.sort((a, b) => b.totalOutstanding.compareTo(a.totalOutstanding));
        break;
      case _ClientSort.billed:
        summaries.sort((a, b) => b.totalBilled.compareTo(a.totalBilled));
        break;
      case _ClientSort.recent:
        summaries.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: kClientsAccent,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<_ClientSort>(
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _ClientSort.outstanding, child: Text('Sort: Outstanding')),
              PopupMenuItem(value: _ClientSort.billed, child: Text('Sort: Total billed')),
              PopupMenuItem(value: _ClientSort.recent, child: Text('Sort: Most recent')),
            ],
          ),
        ],
      ),
      body: summaries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No clients yet. Create an invoice or quote to see them here.',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: summaries.length,
              itemBuilder: (context, i) => _ClientCard(summary: summaries[i], isDark: isDark),
            ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientSummary summary;
  final bool isDark;
  const _ClientCard({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasOutstanding = summary.totalOutstanding > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kClientsAccent.withOpacity(0.12),
                child: Text(
                  summary.clientName.isNotEmpty ? summary.clientName[0].toUpperCase() : '?',
                  style: const TextStyle(color: kClientsAccent, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.clientName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (summary.clientEmail.isNotEmpty)
                      Text(summary.clientEmail,
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('${summary.totalDocuments} doc${summary.totalDocuments == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(label: 'Billed', value: summary.totalBilled, color: cs.onSurface.withOpacity(0.7)),
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Outstanding',
                  value: summary.totalOutstanding,
                  color: hasOutstanding ? const Color(0xFFE53935) : cs.onSurface.withOpacity(0.4),
                ),
              ),
              Expanded(
                child: _MetricColumn(label: 'Paid', value: summary.totalPaid, color: const Color(0xFF43A047)),
              ),
            ],
          ),
          if (summary.avgDaysToPay != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: cs.onSurface.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(
                  'Avg. ${summary.avgDaysToPay!.toStringAsFixed(0)} days to pay',
                  style: TextStyle(fontSize: 11.5, color: cs.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MetricColumn({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: cs.onSurface.withOpacity(0.45), fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value.toStringAsFixed(2), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
