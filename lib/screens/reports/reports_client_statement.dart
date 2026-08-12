// reports_client_statement.dart
// lib/screens/reports/reports_client_statement.dart
//
// CLIENT STATEMENT PASS (new file): adds a per-client "statement of
// account", reached by tapping a row in the Top Clients card on
// ReportsScreen. Kept in its own file rather than folded into
// reports_widgets.dart / reports_screen.dart so the statement's data
// model, card widget, and sheet UI stay together and reports_screen.dart
// (which already owns period/folder/data-source computation, trend
// bucketing, and document-list wiring) doesn't grow further.
//
// What's here:
//   - ReportsTopClientsCard: a drop-in replacement for the old
//     TopClientsCard (reports_widgets.dart) — same visual intent (avatar
//     initials, name, amount, thin proportional bar per row) but every
//     row is now tappable via onClientTap. The old TopClientsCard is
//     untouched — reports_screen.dart now calls this one instead.
//   - ClientStatementLine: one invoice or receipt on a statement — just
//     enough fields (date, label, doc type, amount, payment flag) to
//     render a running-balance ledger. Built by the caller
//     (reports_screen.dart's _openClientStatement) from its
//     already-scoped periodInvoices/periodReceipts, so a statement can
//     never disagree with the rest of the screen about which period or
//     folder is active.
//   - showClientStatementSheet(): opens the statement as a draggable
//     modal bottom sheet. Invoices increase the balance owed, issued
//     receipts decrease it; each line shows the running balance as of
//     that line. Header shows totals invoiced / received / balance due.
//     "Copy summary" copies a plain-text version to the clipboard —
//     deliberately not wired to any share package, so this file has no
//     new pubspec dependency.
//
// Note on what counts as "invoiced" here vs. the Income figure elsewhere
// on Reports: Income (and Top Clients' own totals) only count PAID
// invoices + issued receipts — that's realized income. A statement is a
// different question ("what does this client owe / what have they paid
// me"), so it includes every reportable invoice regardless of payment
// status. Both readings are correct for what they're answering; they're
// just answering different questions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientStatementLine {
  final DateTime date;
  final String label; // invoice/receipt title
  final String docTypeLabel; // 'Invoice' or 'Receipt'
  final double amount;
  final bool isPayment; // true = receipt (reduces balance), false = invoice (increases balance)

  const ClientStatementLine({
    required this.date,
    required this.label,
    required this.docTypeLabel,
    required this.amount,
    required this.isPayment,
  });
}

// ── All-clients entry point ─────────────────────────────────────────────
// ENTRY-POINT PASS (this update): Top Clients (and its onClientTap) only
// ever lists clients with PAID invoices or issued receipts — that's
// deliberate, it's a realized-income leaderboard. But it means a client
// who's been invoiced and hasn't paid yet — the client you'd most want a
// statement for — has no row there to tap. ClientStatementsEntryRow +
// showClientStatementsListSheet give statements their own always-visible
// door, independent of whether anything's been paid this period: any
// client with at least one reportable invoice or issued receipt shows up,
// so an unpaid invoice is still enough to reach that client's statement.

// One client's rolled-up totals for the "all clients" list — same
// invoiced/received/balance math as the single-client sheet below, just
// precomputed so the list can show a balance next to each name without
// every row re-deriving it on tap.
class ClientStatementSummary {
  final String clientName;
  final List<ClientStatementLine> lines;
  final double totalInvoiced;
  final double totalReceived;
  final double balance;

  const ClientStatementSummary._({
    required this.clientName,
    required this.lines,
    required this.totalInvoiced,
    required this.totalReceived,
    required this.balance,
  });

  factory ClientStatementSummary.fromLines(String clientName, List<ClientStatementLine> lines) {
    final totalInvoiced = lines.where((l) => !l.isPayment).fold(0.0, (s, l) => s + l.amount);
    final totalReceived = lines.where((l) => l.isPayment).fold(0.0, (s, l) => s + l.amount);
    return ClientStatementSummary._(
      clientName: clientName,
      lines: lines,
      totalInvoiced: totalInvoiced,
      totalReceived: totalReceived,
      balance: totalInvoiced - totalReceived,
    );
  }
}

// Always-visible tappable row — sits above/near Top Clients regardless of
// whether Top Clients itself has anything to show, so "no paid income yet
// this period" never means "no way to see what's owed."
class ClientStatementsEntryRow extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const ClientStatementsEntryRow({
    super.key,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_rounded, size: 16, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client statements', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      'See what every client has been invoiced and what they owe.',
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

// Modal list of every client with a reportable invoice or issued receipt
// in the period, sorted by outstanding balance (highest first, since
// that's the one you're most likely opening this to check). Tapping a
// row opens that client's full statement via showClientStatementSheet.
Future<void> showClientStatementsListSheet(
  BuildContext context, {
  required String periodLabel,
  required List<ClientStatementSummary> summaries,
  required bool isDark,
  required Color accent,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _ClientStatementsListBody(
      periodLabel: periodLabel,
      summaries: summaries,
      isDark: isDark,
      accent: accent,
    ),
  );
}

class _ClientStatementsListBody extends StatelessWidget {
  final String periodLabel;
  final List<ClientStatementSummary> summaries;
  final bool isDark;
  final Color accent;

  const _ClientStatementsListBody({
    required this.periodLabel,
    required this.summaries,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client statements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(periodLabel, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: summaries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'No invoiced or paid clients in this period.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.45)),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: summaries.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
                      itemBuilder: (ctx, i) {
                        final s = summaries[i];
                        final trimmed = s.clientName.trim();
                        final initials = trimmed.isEmpty
                            ? '?'
                            : trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              showClientStatementSheet(
                                context,
                                clientName: s.clientName,
                                periodLabel: periodLabel,
                                lines: s.lines,
                                isDark: isDark,
                                accent: accent,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text(initials, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: accent)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.clientName,
                                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(
                                          s.balance > 0 ? 'Balance due' : (s.balance < 0 ? 'Overpaid' : 'Settled'),
                                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _fmt(s.balance),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: s.balance > 0
                                          ? const Color(0xFFE53935)
                                          : (s.balance < 0 ? const Color(0xFF4CAF50) : cs.onSurface.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(double v) => v.toStringAsFixed(2);

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
String _fmtDate(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]} ${d.year}';

// ── Top Clients card, with tappable rows ────────────────────────────────

class ReportsTopClientsCard extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final bool isDark;
  final Color accent;
  final ValueChanged<String> onClientTap;

  const ReportsTopClientsCard({
    super.key,
    required this.entries,
    required this.isDark,
    required this.accent,
    required this.onClientTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxAmount = entries.isEmpty ? 1.0 : entries.first.value.abs().clamp(0.01, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top clients', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Tap a client to see their statement.',
            style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.35)),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < entries.length; i++) ...[
            _ClientRow(
              name: entries[i].key,
              amount: entries[i].value,
              fraction: (entries[i].value.abs() / maxAmount).clamp(0.0, 1.0),
              accent: accent,
              onTap: () => onClientTap(entries[i].key),
            ),
            if (i != entries.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final String name;
  final double amount;
  final double fraction;
  final Color accent;
  final VoidCallback onTap;

  const _ClientRow({
    required this.name,
    required this.amount,
    required this.fraction,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    final initials = trimmed.isEmpty
        ? '?'
        : trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(initials, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: accent)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(name,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(_fmt(amount), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 5,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(accent.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Statement sheet ──────────────────────────────────────────────────────

Future<void> showClientStatementSheet(
  BuildContext context, {
  required String clientName,
  required String periodLabel,
  required List<ClientStatementLine> lines,
  required bool isDark,
  required Color accent,
}) {
  final sorted = List<ClientStatementLine>.from(lines)..sort((a, b) => a.date.compareTo(b.date));
  final totalInvoiced = sorted.where((l) => !l.isPayment).fold(0.0, (s, l) => s + l.amount);
  final totalReceived = sorted.where((l) => l.isPayment).fold(0.0, (s, l) => s + l.amount);
  final balance = totalInvoiced - totalReceived;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _ClientStatementSheetBody(
      clientName: clientName,
      periodLabel: periodLabel,
      lines: sorted,
      totalInvoiced: totalInvoiced,
      totalReceived: totalReceived,
      balance: balance,
      accent: accent,
    ),
  );
}

class _ClientStatementSheetBody extends StatelessWidget {
  final String clientName;
  final String periodLabel;
  final List<ClientStatementLine> lines;
  final double totalInvoiced;
  final double totalReceived;
  final double balance;
  final Color accent;

  const _ClientStatementSheetBody({
    required this.clientName,
    required this.periodLabel,
    required this.lines,
    required this.totalInvoiced,
    required this.totalReceived,
    required this.balance,
    required this.accent,
  });

  String _summaryText() {
    final buf = StringBuffer();
    buf.writeln('Statement of account — $clientName');
    buf.writeln(periodLabel);
    buf.writeln('');
    double running = 0;
    for (final l in lines) {
      running += l.isPayment ? -l.amount : l.amount;
      final sign = l.isPayment ? '-' : ' ';
      buf.writeln('${_fmtDate(l.date)}  ${l.docTypeLabel.padRight(8)} $sign${_fmt(l.amount)}  (balance ${_fmt(running)})');
    }
    buf.writeln('');
    buf.writeln('Total invoiced: ${_fmt(totalInvoiced)}');
    buf.writeln('Total received: ${_fmt(totalReceived)}');
    buf.writeln('Balance due: ${_fmt(balance)}');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    double running = 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clientName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                        const SizedBox(height: 2),
                        Text(periodLabel, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: 'Copy summary',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _summaryText()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Statement copied to clipboard'), duration: Duration(seconds: 2)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(child: _StatBlock(label: 'Invoiced', value: totalInvoiced, color: cs.onSurface)),
                    Expanded(child: _StatBlock(label: 'Received', value: totalReceived, color: const Color(0xFF4CAF50))),
                    Expanded(
                      child: _StatBlock(
                        label: 'Balance due',
                        value: balance,
                        color: balance > 0 ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: lines.isEmpty
                  ? Center(
                      child: Text(
                        'No invoices or receipts for this client in this period.',
                        style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.45)),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
                      itemBuilder: (ctx, i) {
                        final l = lines[i];
                        running += l.isPayment ? -l.amount : l.amount;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (l.isPayment ? const Color(0xFF4CAF50) : accent).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l.docTypeLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: l.isPayment ? const Color(0xFF4CAF50) : accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.label,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(_fmtDate(l.date), style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${l.isPayment ? '-' : ''}${_fmt(l.amount)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: l.isPayment ? const Color(0xFF4CAF50) : cs.onSurface,
                                    ),
                                  ),
                                  Text('bal ${_fmt(running)}', style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.4))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StatBlock({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 3),
        Text(_fmt(value), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
