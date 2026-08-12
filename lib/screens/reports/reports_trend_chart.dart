// reports_trend_chart.dart
// lib/screens/reports/reports_trend_chart.dart
//
// Collapsible "price"-style trend card for ReportsScreen. Replaces the old
// static 6-month TrendStrip. Lets the user pick a metric (Net / Income /
// Expenses) and a lookback range (1W up to 10Y), and shows a line+area
// chart with a stock-app-style +X% / -X% badge (green = up, red = down),
// hand-drawn with CustomPainter (no chart package dependency).
//
// Kept dependency-free (no provider reads in here), same pattern as
// reports_widgets.dart — the screen supplies a `pointsBuilder` callback
// that already has access to InvoiceProvider/QuoteProvider/ReceiptProvider/
// ExpenseProvider/ReportsPrefs, and this widget just calls it whenever the
// metric or range selection changes and renders whatever comes back.
//
// Bucketing (chosen by range, see TrendRangeX.bucketUnit/bucketCount):
//   1W / 1M  -> daily points   (7 / 30 points)
//   3M / 6M  -> weekly points  (13 / 26 points)
//   1Y / 2Y  -> monthly points (12 / 24 points)
//   5Y / 10Y -> yearly points  (5 / 10 points)
//
// Tap-and-drag on the chart scrubs a readout (value + date) instead of
// always showing the latest point — the header value/badge follow the
// touch position while dragging, and snap back to the latest point on
// release.
//
// The collapse icon in the header hides the metric chips, range chips, and
// chart body via AnimatedCrossFade, leaving just the compact header
// (label + value + % badge) visible — this is the "hide with an icon"
// behavior.

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Public data types ───────────────────────────────────────────────────

enum TrendMetric { net, income, expenses }

enum TrendRange { w1, m1, m3, m6, y1, y2, y5, y10 }

enum TrendBucketUnit { day, week, month, year }

extension TrendMetricX on TrendMetric {
  String get label {
    switch (this) {
      case TrendMetric.net:
        return 'Net';
      case TrendMetric.income:
        return 'Income';
      case TrendMetric.expenses:
        return 'Expenses';
    }
  }

  IconData get icon {
    switch (this) {
      case TrendMetric.net:
        return Icons.show_chart_rounded;
      case TrendMetric.income:
        return Icons.trending_up_rounded;
      case TrendMetric.expenses:
        return Icons.trending_down_rounded;
    }
  }
}

extension TrendRangeX on TrendRange {
  String get label {
    switch (this) {
      case TrendRange.w1:
        return '1W';
      case TrendRange.m1:
        return '1M';
      case TrendRange.m3:
        return '3M';
      case TrendRange.m6:
        return '6M';
      case TrendRange.y1:
        return '1Y';
      case TrendRange.y2:
        return '2Y';
      case TrendRange.y5:
        return '5Y';
      case TrendRange.y10:
        return '10Y';
    }
  }

  TrendBucketUnit get bucketUnit {
    switch (this) {
      case TrendRange.w1:
      case TrendRange.m1:
        return TrendBucketUnit.day;
      case TrendRange.m3:
      case TrendRange.m6:
        return TrendBucketUnit.week;
      case TrendRange.y1:
      case TrendRange.y2:
        return TrendBucketUnit.month;
      case TrendRange.y5:
      case TrendRange.y10:
        return TrendBucketUnit.year;
    }
  }

  int get bucketCount {
    switch (this) {
      case TrendRange.w1:
        return 7;
      case TrendRange.m1:
        return 30;
      case TrendRange.m3:
        return 13;
      case TrendRange.m6:
        return 26;
      case TrendRange.y1:
        return 12;
      case TrendRange.y2:
        return 24;
      case TrendRange.y5:
        return 5;
      case TrendRange.y10:
        return 10;
    }
  }
}

class TrendChartPoint {
  final DateTime date;
  final double value;
  const TrendChartPoint({required this.date, required this.value});
}

String _fmtAmount(double v) => v.toStringAsFixed(2);

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _fmtAxisDate(DateTime d, TrendBucketUnit unit) {
  switch (unit) {
    case TrendBucketUnit.day:
    case TrendBucketUnit.week:
      return '${d.day} ${_shortMonths[d.month - 1]}';
    case TrendBucketUnit.month:
      return '${_shortMonths[d.month - 1]} ${d.year}';
    case TrendBucketUnit.year:
      return '${d.year}';
  }
}

// ── Main card ────────────────────────────────────────────────────────────

class ReportsTrendChartCard extends StatefulWidget {
  /// Called whenever the metric or range selection changes. The screen
  /// owns the actual provider data; this widget just asks for points.
  final List<TrendChartPoint> Function(TrendMetric metric, TrendRange range) pointsBuilder;
  final bool isDark;
  final bool initiallyExpanded;

  const ReportsTrendChartCard({
    super.key,
    required this.pointsBuilder,
    required this.isDark,
    this.initiallyExpanded = true,
  });

  @override
  State<ReportsTrendChartCard> createState() => _ReportsTrendChartCardState();
}

class _ReportsTrendChartCardState extends State<ReportsTrendChartCard> {
  TrendMetric _metric = TrendMetric.net;
  TrendRange _range = TrendRange.m1;
  late bool _expanded = widget.initiallyExpanded;
  int? _touchIndex;

  double? _pctChange(List<TrendChartPoint> points) {
    if (points.length < 2) return null;
    final first = points.first.value;
    final last = points.last.value;
    if (first != 0) return ((last - first) / first.abs()) * 100;
    if (last != 0) return last > 0 ? 100 : -100;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final points = widget.pointsBuilder(_metric, _range);
    final pctChange = _pctChange(points);
    final isUp = (pctChange ?? 0) >= 0;
    final lineColor = pctChange == null
        ? cs.onSurface.withValues(alpha: 0.35)
        : (isUp ? const Color(0xFF4CAF50) : const Color(0xFFE53935));

    final hasTouch = _touchIndex != null && _touchIndex! >= 0 && _touchIndex! < points.length;
    final displayValue = hasTouch ? points[_touchIndex!].value : (points.isNotEmpty ? points.last.value : 0.0);
    final displayDate = hasTouch
        ? points[_touchIndex!].date
        : (points.isNotEmpty ? points.last.date : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: lineColor.withValues(alpha: widget.isDark ? 0.12 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header — always visible, even when collapsed ─────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lineColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_metric.icon, size: 16, color: lineColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_metric.label} trend',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _fmtAmount(displayValue),
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: cs.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pctChange != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: lineColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 11, color: lineColor),
                                const SizedBox(width: 2),
                                Text(
                                  '${pctChange.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: lineColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (displayDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        hasTouch ? _fmtAxisDate(displayDate, _range.bucketUnit) : '${_range.label} · ${_fmtAxisDate(displayDate, _range.bucketUnit)}',
                        style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: cs.onSurface.withValues(alpha: 0.5)),
                tooltip: _expanded ? 'Hide chart' : 'Show chart',
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Row(
                  children: TrendMetric.values.map((m) {
                    final selected = m == _metric;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: m != TrendMetric.values.last ? 8 : 0),
                        child: _TrendChip(
                          label: m.label,
                          selected: selected,
                          accent: m == TrendMetric.expenses ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                          onTap: () => setState(() {
                            _metric = m;
                            _touchIndex = null;
                          }),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                points.length < 2
                    ? Container(
                        height: 140,
                        alignment: Alignment.center,
                        child: Text(
                          'Not enough data yet for this range.',
                          style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          void updateTouch(Offset localPosition) {
                            final width = constraints.maxWidth;
                            if (width <= 0) return;
                            final n = points.length;
                            final idx = ((localPosition.dx / width) * (n - 1)).round().clamp(0, n - 1);
                            setState(() => _touchIndex = idx);
                          }

                          return GestureDetector(
                            onPanDown: (d) => updateTouch(d.localPosition),
                            onPanUpdate: (d) => updateTouch(d.localPosition),
                            onPanEnd: (_) => setState(() => _touchIndex = null),
                            onPanCancel: () => setState(() => _touchIndex = null),
                            child: SizedBox(
                              height: 140,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _TrendChartPainter(
                                  points: points,
                                  lineColor: lineColor,
                                  isDark: widget.isDark,
                                  touchIndex: _touchIndex,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                if (points.length >= 2) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmtAxisDate(points.first.date, _range.bucketUnit),
                          style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.35))),
                      Text(_fmtAxisDate(points.last.date, _range.bucketUnit),
                          style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.35))),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: TrendRange.values.map((r) {
                      final selected = r == _range;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TrendChip(
                          label: r.label,
                          selected: selected,
                          accent: lineColor,
                          compact: true,
                          onTap: () => setState(() {
                            _range = r;
                            _touchIndex = null;
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small chip used for both metric and range selectors ───────────────────

class _TrendChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool compact;
  final VoidCallback onTap;

  const _TrendChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(compact ? 20 : 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 20 : 10),
        onTap: onTap,
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
              : const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 20 : 10),
            border: Border.all(
              color: selected ? accent : cs.onSurface.withValues(alpha: 0.12),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12 : 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? accent : cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painter — line + gradient area + gridlines + touch scrub indicator ────

class _TrendChartPainter extends CustomPainter {
  final List<TrendChartPoint> points;
  final Color lineColor;
  final bool isDark;
  final int? touchIndex;

  _TrendChartPainter({
    required this.points,
    required this.lineColor,
    required this.isDark,
    this.touchIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final values = points.map((p) => p.value).toList();
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if (minV == maxV) {
      minV -= 1;
      maxV += 1;
    }
    final pad = (maxV - minV) * 0.12;
    minV -= pad;
    maxV += pad;

    final n = points.length;
    Offset offsetFor(int i) {
      final x = n == 1 ? 0.0 : (i / (n - 1)) * size.width;
      final t = (values[i] - minV) / (maxV - minV);
      final y = size.height - t * size.height;
      return Offset(x, y);
    }

    // Gridlines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int g = 1; g < 4; g++) {
      final y = size.height * g / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line + area
    final linePath = Path();
    final areaPath = Path();
    for (int i = 0; i < n; i++) {
      final o = offsetFor(i);
      if (i == 0) {
        linePath.moveTo(o.dx, o.dy);
        areaPath.moveTo(o.dx, size.height);
        areaPath.lineTo(o.dx, o.dy);
      } else {
        linePath.lineTo(o.dx, o.dy);
        areaPath.lineTo(o.dx, o.dy);
      }
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.22), lineColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Last-point marker
    final lastO = offsetFor(n - 1);
    canvas.drawCircle(lastO, 7, Paint()..color = lineColor.withValues(alpha: 0.22));
    canvas.drawCircle(lastO, 3.5, Paint()..color = lineColor);

    // Touch scrub indicator
    final ti = touchIndex;
    if (ti != null && ti >= 0 && ti < n) {
      final o = offsetFor(ti);
      final dashPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.55)
        ..strokeWidth = 1;
      double y = 0;
      while (y < size.height) {
        canvas.drawLine(Offset(o.dx, y), Offset(o.dx, math.min(y + 4, size.height)), dashPaint);
        y += 8;
      }
      canvas.drawCircle(o, 5, Paint()..color = lineColor);
      canvas.drawCircle(o, 5, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.touchIndex != touchIndex ||
      oldDelegate.isDark != isDark;
}
