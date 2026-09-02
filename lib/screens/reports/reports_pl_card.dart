// reports_pl_card.dart
// lib/screens/reports/reports_pl_card.dart
//
// PROFIT/LOSS RING PASS (this update): added ProfitLossRing — a compact
// circular indicator in the card header, colored green/orange/red for an
// at-a-glance profit/loss read before scanning the actual numbers below
// it. Green when net > 0 ("Profit"), red when net < 0 ("Loss"), orange
// for the exact break-even case (net == 0) or when there's no revenue/
// expense data at all this period. The ring's fill fraction is the
// profit margin (net / total revenue, clamped to 0-100%) — a period with
// a thin margin shows a mostly-empty ring even while still green, a
// strong margin shows it mostly filled. Purely derived from the same
// _totalRevenue/_totalExpenses/_netProfit getters already on this widget
// — no new data logic, so it can never disagree with the numbers in the
// rest of the card. Placed in the header row next to the title/period
// label, replacing the plain single-line header with title+ring on top
// and the period label underneath.
//
// A structured Profit & Loss statement card for ReportsScreen. Purely
// presentational — takes already-computed figures from reports_screen.dart
// (same _isReportable-gated invoice/receipt/expense totals every other
// card on that screen uses) and lays them out in the traditional P&L
// shape: Revenue (by source) -> Total Revenue -> Expenses (by category)
// -> Total Expenses -> Net Profit/Loss. No new data logic lives here —
// this can never disagree with the Income/Expenses/Net stat cards or the
// "Expenses by category" section above it, since it's fed the exact same
// numbers.
//
// Kept dependency-free (no provider reads), same pattern as
// reports_widgets.dart/reports_trend_chart.dart — the screen owns the
// data, this just renders it.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/document_category.dart';

class ProfitLossCategoryLine {
  final DocumentCategory category;
  final double amount;
  const ProfitLossCategoryLine({required this.category, required this.amount});
}

class ProfitLossCard extends StatelessWidget {
  final String periodLabel;
  final double invoiceRevenue;
  final double receiptRevenue;
  final List<ProfitLossCategoryLine> expensesByCategory;
  final bool isDark;
  final Color accent;

  const ProfitLossCard({
    super.key,
    required this.periodLabel,
    required this.invoiceRevenue,
    required this.receiptRevenue,
    required this.expensesByCategory,
    required this.isDark,
    required this.accent,
  });

  double get _totalRevenue => invoiceRevenue + receiptRevenue;
  double get _totalExpenses =>
      expensesByCategory.fold(0.0, (s, e) => s + e.amount);
  double get _netProfit => _totalRevenue - _totalExpenses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isProfit = _netProfit >= 0;
    final netColor = isProfit ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.summarize_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profit & Loss',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      periodLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ProfitLossRing(
                revenue: _totalRevenue,
                expenses: _totalExpenses,
                net: _netProfit,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _sectionLabel(cs, 'REVENUE'),
          const SizedBox(height: 8),
          if (invoiceRevenue > 0) _lineRow(cs, 'Invoices (paid)', invoiceRevenue),
          if (receiptRevenue > 0) _lineRow(cs, 'Receipts (issued)', receiptRevenue),
          if (invoiceRevenue <= 0 && receiptRevenue <= 0)
            _emptyLine(cs, 'No revenue this period'),
          const SizedBox(height: 8),
          _totalRow(cs, 'Total Revenue', _totalRevenue, const Color(0xFF4CAF50)),

          const SizedBox(height: 18),
          Divider(color: cs.outline.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 18),

          _sectionLabel(cs, 'EXPENSES'),
          const SizedBox(height: 8),
          if (expensesByCategory.isEmpty)
            _emptyLine(cs, 'No expenses this period')
          else
            for (final line in expensesByCategory)
              _lineRow(cs, line.category.name, line.amount, dotColor: line.category.color),
          const SizedBox(height: 8),
          _totalRow(cs, 'Total Expenses', _totalExpenses, const Color(0xFFE53935)),

          const SizedBox(height: 18),
          Divider(color: cs.outline.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 18),

          Row(
            children: [
              Text(
                isProfit ? 'Net Profit' : 'Net Loss',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _netProfit),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  v.toStringAsFixed(2),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: netColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: cs.onSurface.withValues(alpha: 0.4),
        ),
      );

  Widget _emptyLine(ColorScheme cs, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
        ),
      );

  Widget _lineRow(ColorScheme cs, String label, double amount, {Color? dotColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (dotColor != null) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.8)),
            ),
          ),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(ColorScheme cs, String label, double amount, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        const Spacer(),
        Text(
          amount.toStringAsFixed(2),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ProfitLossRing — compact circular Profit/Loss/Break-even indicator.
//
// Color rule:
//   net > 0  -> green  ("Profit")
//   net < 0  -> red    ("Loss")
//   net == 0 (exact break-even) OR no revenue/expense data at all this
//   period -> orange ("Break-even" / "No data")
//
// Fill rule: the ring's arc fills proportional to the profit margin
// (net / totalRevenue), clamped to 0-100% of the circle — a thin-margin
// profitable period shows a mostly-empty green ring, a strong margin
// shows it mostly filled. When there's no revenue to divide by, the ring
// falls back to fully filled for a clear net>0/net<0 (nothing to take a
// fraction of) or empty for the true no-data case.
// ─────────────────────────────────────────────────────────────────────────

class ProfitLossRing extends StatelessWidget {
  final double revenue;
  final double expenses;
  final double net;
  final double size;

  const ProfitLossRing({
    super.key,
    required this.revenue,
    required this.expenses,
    required this.net,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasData = revenue > 0 || expenses > 0;

    late final Color color;
    late final String label;
    late final IconData icon;
    late final double fraction;

    if (!hasData) {
      color = cs.onSurface.withValues(alpha: 0.35);
      label = 'No data';
      icon = Icons.remove_rounded;
      fraction = 0.0;
    } else if (net > 0) {
      color = const Color(0xFF4CAF50);
      label = 'Profit';
      icon = Icons.trending_up_rounded;
      fraction = revenue > 0 ? (net / revenue).clamp(0.0, 1.0) : 1.0;
    } else if (net < 0) {
      color = const Color(0xFFE53935);
      label = 'Loss';
      icon = Icons.trending_down_rounded;
      fraction = revenue > 0 ? (net.abs() / revenue).clamp(0.0, 1.0) : 1.0;
    } else {
      color = const Color(0xFFFF9800);
      label = 'Even';
      icon = Icons.trending_flat_rounded;
      fraction = 0.0;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: fraction),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => CustomPaint(
              size: Size(size, size),
              painter: _ProfitLossRingPainter(
                fraction: v,
                color: color,
                trackColor: color.withValues(alpha: 0.14),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: size * 0.24, color: color),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(fontSize: size * 0.135, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfitLossRingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;

  _ProfitLossRingPainter({required this.fraction, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.13;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final center = rect.center;
    final radius = rect.width / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfitLossRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
