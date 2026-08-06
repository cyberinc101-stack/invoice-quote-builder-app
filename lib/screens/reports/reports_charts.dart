// reports_charts.dart
// lib/screens/reports/reports_charts.dart
//
// Two "premium feel" visuals built entirely from Container/Row/Expanded —
// deliberately NOT using a charting package, since pubspec.yaml doesn't
// have one and this doesn't need the weight of fl_chart for a bar strip
// and a segmented bar.
//
// NOTE ON Expanded.flex: flex must be a positive int. Amounts are doubles,
// so every flex value below is computed via a helper that scales to an int
// and floors at 1 — never pass a raw num.clamp() result straight into
// flex (that returns num, not int, and fails a strict build).

import 'package:flutter/material.dart';

int _scaledFlex(double amount, double maxAmount, {int scale = 1000}) {
  if (maxAmount <= 0) return 1;
  final raw = ((amount / maxAmount) * scale).round();
  return raw < 1 ? 1 : raw;
}

// ── 6-month trend strip: income vs expense bar pairs ────────────────────────

class MonthTrendPoint {
  final DateTime month;
  final double income;
  final double expenses;

  const MonthTrendPoint({required this.month, required this.income, required this.expenses});
}

class TrendStrip extends StatelessWidget {
  final List<MonthTrendPoint> points; // oldest first, expected length 6
  final bool isDark;

  const TrendStrip({super.key, required this.points, required this.isDark});

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxValue = points.fold<double>(
      0.0,
      (m, p) => [m, p.income, p.expenses].reduce((a, b) => a > b ? a : b),
    );
    const barAreaHeight = 84.0;
    const incomeColor = Color(0xFF4CAF50);
    const expenseColor = Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(color: incomeColor, label: 'Income'),
              const SizedBox(width: 14),
              _LegendDot(color: expenseColor, label: 'Expenses'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: barAreaHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final p in points)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TrendBar(
                            heightFraction: maxValue <= 0 ? 0 : p.income / maxValue,
                            maxHeight: barAreaHeight,
                            color: incomeColor,
                          ),
                          const SizedBox(width: 3),
                          _TrendBar(
                            heightFraction: maxValue <= 0 ? 0 : p.expenses / maxValue,
                            maxHeight: barAreaHeight,
                            color: expenseColor,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final p in points)
                Expanded(
                  child: Center(
                    child: Text(
                      _monthAbbr[p.month.month - 1],
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  final double heightFraction; // 0..1
  final double maxHeight;
  final Color color;

  const _TrendBar({required this.heightFraction, required this.maxHeight, required this.color});

  @override
  Widget build(BuildContext context) {
    final clamped = heightFraction.isNaN ? 0.0 : heightFraction.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: clamped),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Container(
        width: 8,
        height: (value * maxHeight).clamp(2.0, maxHeight),
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.55))),
      ],
    );
  }
}

// ── Status breakdown: stacked segmented bar + legend ────────────────────────
//
// Keyed generically by status name (via enum.name) rather than hardcoded
// PaymentStatus/QuoteStatus members, so it works regardless of exactly
// which status values invoice_data.dart / quote_data.dart define.

class StatusSegment {
  final String label; // e.g. 'paid', 'unpaid', 'overdue'
  final double amount;
  final Color color;

  const StatusSegment({required this.label, required this.amount, required this.color});
}

/// Deterministic palette so the same status name always gets the same
/// color across rebuilds/screens, without needing to know the enum ahead
/// of time.
Color colorForStatusLabel(String label) {
  const palette = [
    Color(0xFF4CAF50), // paid / issued / accepted — green
    Color(0xFFFF9800), // unpaid / sent / pending — amber
    Color(0xFFE53935), // overdue / declined — red
    Color(0xFF9E9E9E), // draft / other — grey
    Color(0xFF2196F3), // partial / expired — blue
  ];
  final lower = label.toLowerCase();
  if (lower.contains('paid') && !lower.contains('unpaid')) return palette[0];
  if (lower.contains('issue') || lower.contains('accept')) return palette[0];
  if (lower.contains('overdue') || lower.contains('declin')) return palette[2];
  if (lower.contains('draft') || lower.contains('other')) return palette[3];
  if (lower.contains('unpaid') || lower.contains('sent') || lower.contains('pending')) return palette[1];
  return palette[label.hashCode.abs() % palette.length];
}

class StatusBreakdownBar extends StatelessWidget {
  final String title;
  final List<StatusSegment> segments;
  final bool isDark;

  const StatusBreakdownBar({super.key, required this.title, required this.segments, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = segments.fold<double>(0.0, (s, seg) => s + seg.amount);

    if (segments.isEmpty || total <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final seg in segments)
                    Expanded(
                      flex: _scaledFlex(seg.amount, total),
                      child: Container(color: seg.color),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final seg in segments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: seg.color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(
                      '${seg.label[0].toUpperCase()}${seg.label.substring(1)} · ${seg.amount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.65)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
