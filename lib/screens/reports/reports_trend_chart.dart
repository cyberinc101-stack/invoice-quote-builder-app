// reports_trend_chart.dart
// lib/screens/reports/reports_trend_chart.dart
//
// Collapsible "price"-style trend card for ReportsScreen. Lets the user
// pick a metric (Net / Income / Expenses) and a lookback range (1W up to
// 10Y), and shows a smooth gradient line+area chart with a stock-app-style
// +X% / -X% badge (green = up, red = down), hand-drawn with CustomPainter
// (no chart package dependency).
//
// MODERN-UI PASS (this update): visual rebuild only — the public API
// (ReportsTrendChartCard(pointsBuilder:, isDark:, initiallyExpanded:)) is
// unchanged, so reports_screen.dart does not need to change. What's new:
//   - Catmull-Rom smoothed curve instead of straight line segments
//   - Multi-stop gradient area fill + soft blurred glow under the line
//   - Animated count-up on the headline value (TweenAnimationBuilder)
//   - Sliding-pill segmented control for the metric toggle
//   - Gradient pill range chips with a pressed-scale tap animation
//   - Floating scrub tooltip bubble (real widget, not canvas text) that
//     follows the touch position, with a connecting gradient guide line
//   - Faint min/max value labels drawn in-canvas at the chart corners
//   - Comma-grouped amount formatting (no intl dependency)
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
// The collapse icon in the header hides the metric control, range chips,
// and chart body via AnimatedCrossFade, leaving just the compact header
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

// Comma-grouped "1,234.56" formatting, no intl dependency.
String _fmtAmount(double v) {
  final negative = v < 0;
  final fixed = v.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    final fromEnd = intPart.length - i;
    if (i > 0 && fromEnd % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '${negative ? '-' : ''}$buf.${parts[1]}';
}

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

  static const _positive = Color(0xFF16C784); // brighter, more "fintech" green
  static const _negative = Color(0xFFEF4655); // brighter, more "fintech" red

  double? _pctChange(List<TrendChartPoint> points) {
    if (points.length < 2) return null;
    final first = points.first.value;
    final last = points.last.value;
    if (first != 0) return ((last - first) / first.abs()) * 100;
    if (last != 0) return last > 0 ? 100 : -100;
    return null;
  }

  Color _accentFor(TrendMetric m) => m == TrendMetric.expenses ? _negative : _positive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final points = widget.pointsBuilder(_metric, _range);
    final pctChange = _pctChange(points);
    final isUp = (pctChange ?? 0) >= 0;
    final lineColor = pctChange == null ? cs.onSurface.withValues(alpha: 0.35) : (isUp ? _positive : _negative);

    final hasTouch = _touchIndex != null && _touchIndex! >= 0 && _touchIndex! < points.length;
    final displayValue = hasTouch ? points[_touchIndex!].value : (points.isNotEmpty ? points.last.value : 0.0);
    final displayDate = hasTouch ? points[_touchIndex!].date : (points.isNotEmpty ? points.last.date : null);

    final bg = widget.isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2235), Color(0xFF191C2B)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFBFCFE)],
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: lineColor.withValues(alpha: widget.isDark ? 0.16 : 0.08),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [lineColor.withValues(alpha: 0.22), lineColor.withValues(alpha: 0.08)],
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: _AnimatedAmount(
                            value: displayValue,
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pctChange != null) _ChangeBadge(pct: pctChange, isUp: isUp, color: lineColor),
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
              _CollapseButton(
                expanded: _expanded,
                color: cs.onSurface.withValues(alpha: 0.55),
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _SegmentedControl<TrendMetric>(
                  items: TrendMetric.values,
                  selected: _metric,
                  labelFor: (m) => m.label,
                  accentFor: _accentFor,
                  onChanged: (m) => setState(() {
                    _metric = m;
                    _touchIndex = null;
                  }),
                ),
                const SizedBox(height: 14),
                points.length < 2
                    ? Container(
                        height: 160,
                        alignment: Alignment.center,
                        child: Text(
                          'Not enough data yet for this range.',
                          style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      )
                    : _TrendChartArea(
                        points: points,
                        lineColor: lineColor,
                        isDark: widget.isDark,
                        range: _range,
                        touchIndex: _touchIndex,
                        onTouchChanged: (i) => setState(() => _touchIndex = i),
                      ),
                if (points.length >= 2) ...[
                  const SizedBox(height: 8),
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
                const SizedBox(height: 14),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: TrendRange.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final r = TrendRange.values[i];
                      return _RangePill(
                        label: r.label,
                        selected: r == _range,
                        accent: lineColor,
                        onTap: () => setState(() {
                          _range = r;
                          _touchIndex = null;
                        }),
                      );
                    },
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

// ── Animated headline value — counts up/down between old and new value ───

class _AnimatedAmount extends StatefulWidget {
  final double value;
  final TextStyle? style;
  const _AnimatedAmount({required this.value, this.style});

  @override
  State<_AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<_AnimatedAmount> {
  double _oldValue = 0;

  @override
  void didUpdateWidget(covariant _AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    _oldValue = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _oldValue, end: widget.value),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(_fmtAmount(v), style: widget.style, overflow: TextOverflow.ellipsis),
    );
  }
}

// ── % change badge ─────────────────────────────────────────────────────

class _ChangeBadge extends StatelessWidget {
  final double pct;
  final bool isUp;
  final Color color;
  const _ChangeBadge({required this.pct, required this.isUp, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.09)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 11, color: color),
          const SizedBox(width: 2),
          Text(
            '${pct.abs().toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Collapse/expand button ─────────────────────────────────────────────

class _CollapseButton extends StatelessWidget {
  final bool expanded;
  final Color color;
  final VoidCallback onTap;
  const _CollapseButton({required this.expanded, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Sliding-pill segmented control (used for the metric toggle) ──────────

class _SegmentedControl<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final String Function(T) labelFor;
  final Color Function(T) accentFor;
  final ValueChanged<T> onChanged;

  const _SegmentedControl({
    required this.items,
    required this.selected,
    required this.labelFor,
    required this.accentFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final index = items.indexOf(selected);
    final accent = accentFor(selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final segW = constraints.maxWidth / items.length;
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: segW * index,
                top: 0,
                bottom: 0,
                width: segW,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent.withValues(alpha: 0.95), accent.withValues(alpha: 0.72)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                  ),
                ),
              ),
              Row(
                children: items.map((item) {
                  final sel = item == selected;
                  return SizedBox(
                    width: segW,
                    height: double.infinity,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onChanged(item),
                        child: Center(
                          child: Text(
                            labelFor(item),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: sel ? Colors.white : cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Range pill chip — gradient fill + press-scale when selected ──────────

class _RangePill extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _RangePill({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  State<_RangePill> createState() => _RangePillState();
}

class _RangePillState extends State<_RangePill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sel = widget.selected;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: sel
                ? LinearGradient(colors: [widget.accent.withValues(alpha: 0.95), widget.accent.withValues(alpha: 0.72)])
                : null,
            color: sel ? null : cs.onSurface.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(20),
            border: sel ? null : Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
            boxShadow: sel
                ? [BoxShadow(color: widget.accent.withValues(alpha: 0.32), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: sel ? Colors.white : cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chart area — gesture layer + canvas painter + floating scrub tooltip ─

class _TrendChartArea extends StatelessWidget {
  final List<TrendChartPoint> points;
  final Color lineColor;
  final bool isDark;
  final TrendRange range;
  final int? touchIndex;
  final ValueChanged<int?> onTouchChanged;

  static const double _height = 160;

  const _TrendChartArea({
    required this.points,
    required this.lineColor,
    required this.isDark,
    required this.range,
    required this.touchIndex,
    required this.onTouchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final n = points.length;

        void updateTouch(Offset localPosition) {
          if (width <= 0) return;
          final idx = ((localPosition.dx / width) * (n - 1)).round().clamp(0, n - 1);
          onTouchChanged(idx);
        }

        final ti = touchIndex;
        final showTooltip = ti != null && ti >= 0 && ti < n;
        final tooltipX = showTooltip ? (n == 1 ? 0.0 : (ti / (n - 1)) * width) : 0.0;

        return SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onPanDown: (d) => updateTouch(d.localPosition),
                onPanUpdate: (d) => updateTouch(d.localPosition),
                onPanEnd: (_) => onTouchChanged(null),
                onPanCancel: () => onTouchChanged(null),
                child: CustomPaint(
                  size: Size(width, _height),
                  painter: _TrendChartPainter(
                    points: points,
                    lineColor: lineColor,
                    isDark: isDark,
                    touchIndex: touchIndex,
                  ),
                ),
              ),
              if (showTooltip)
                Positioned(
                  top: 0,
                  left: (tooltipX - 46).clamp(0.0, math.max(0.0, width - 92)),
                  child: IgnorePointer(
                    child: _ScrubTooltip(
                      value: points[ti].value,
                      date: points[ti].date,
                      unit: range.bucketUnit,
                      color: lineColor,
                      isDark: isDark,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ScrubTooltip extends StatelessWidget {
  final double value;
  final DateTime date;
  final TrendBucketUnit unit;
  final Color color;
  final bool isDark;

  const _ScrubTooltip({
    required this.value,
    required this.date,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262B44) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_fmtAmount(value), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 1),
          Text(_fmtAxisDate(date, unit), style: TextStyle(fontSize: 9.5, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45))),
        ],
      ),
    );
  }
}

// ── Painter — smoothed line + gradient area + glow + gridlines + scrub ───

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

  // Catmull-Rom -> cubic Bezier smoothing (tension 1/6), standard approach
  // for turning a polyline into a smooth curve without external packages.
  Path _smoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts[0].dx, pts[0].dy);
    if (pts.length == 1) return path;
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = (i + 2 < pts.length) ? pts[i + 2] : p2;
      final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

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
    final pad = (maxV - minV) * 0.14;
    minV -= pad;
    maxV += pad;

    final n = points.length;
    Offset offsetFor(int i) {
      final x = n == 1 ? 0.0 : (i / (n - 1)) * size.width;
      final t = (values[i] - minV) / (maxV - minV);
      final y = size.height - t * size.height;
      return Offset(x, y);
    }

    final offsets = List.generate(n, offsetFor);

    // Dashed horizontal gridlines.
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int g = 1; g < 4; g++) {
      final y = size.height * g / 4;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, size.width), y), gridPaint);
        x += 9;
      }
    }

    final linePath = _smoothPath(offsets);

    // Multi-stop gradient area fill under the smoothed curve.
    final areaPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.30),
          lineColor.withValues(alpha: 0.12),
          lineColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    // Soft blurred glow behind the line for a "neon" fintech feel.
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(linePath, glowPaint);

    // Crisp line on top of the glow.
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Last-point marker with a soft halo.
    final lastO = offsets.last;
    canvas.drawCircle(lastO, 9, Paint()..color = lineColor.withValues(alpha: 0.16));
    canvas.drawCircle(lastO, 4, Paint()..color = lineColor);
    canvas.drawCircle(lastO, 4, Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);

    // Faint min/max value labels at the chart corners.
    _drawLabel(canvas, _fmtAmount(maxV - pad), Offset(2, 2), isDark);
    _drawLabel(canvas, _fmtAmount(minV + pad), Offset(2, size.height - 14), isDark);

    // Touch scrub indicator — gradient guide line + halo dot.
    final ti = touchIndex;
    if (ti != null && ti >= 0 && ti < n) {
      final o = offsets[ti];
      final guidePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withValues(alpha: 0.0), lineColor.withValues(alpha: 0.6)],
        ).createShader(Rect.fromLTWH(o.dx - 1, 0, 2, size.height))
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(o.dx, 0), Offset(o.dx, size.height), guidePaint);
      canvas.drawCircle(o, 7, Paint()..color = lineColor.withValues(alpha: 0.22));
      canvas.drawCircle(o, 4.5, Paint()..color = lineColor);
      canvas.drawCircle(o, 4.5, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, bool isDark) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.28)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.touchIndex != touchIndex ||
      oldDelegate.isDark != isDark;
}