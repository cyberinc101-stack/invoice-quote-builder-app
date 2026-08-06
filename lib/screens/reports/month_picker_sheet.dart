// month_picker_sheet.dart
// lib/screens/reports/month_picker_sheet.dart
//
// Month/day picker for the Reports screen — now with a Single date / Date
// range mode toggle.
//
// FIX (this pass): range mode previously wasn't supported at all — picking
// a second date just overwrote the first because there was only ever one
// _selectedDay tracked. Range mode now tracks _rangeStart/_rangeEnd as real
// DateTimes (not just a day-of-month int), so navigating to a different
// month to pick the end date doesn't lose the start selection. Both ends
// stay highlighted, with days in between lightly tinted.
//
// Returns a DatePickerResult instead of a bare DateTime — either a single
// month (unchanged behavior) or a start/end range. ReportsScreen decides
// what to do with whichever shape comes back.

import 'package:flutter/material.dart';

// ── Result type ──────────────────────────────────────────────────────────

class DatePickerResult {
  final DateTime? month;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  const DatePickerResult.month(DateTime m)
      : month = m,
        rangeStart = null,
        rangeEnd = null;

  const DatePickerResult.range(DateTime start, DateTime end)
      : month = null,
        rangeStart = start,
        rangeEnd = end;

  bool get isRange => rangeStart != null && rangeEnd != null;
}

enum _PickerMode { single, range }

Future<DatePickerResult?> showMonthPickerSheet(
  BuildContext context, {
  required DateTime initialMonth,
  DateTime? initialRangeStart,
  DateTime? initialRangeEnd,
  Color accent = const Color(0xFF00897B),
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<DatePickerResult>(
    context: context,
    backgroundColor: colorScheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
      child: SingleChildScrollView(
        child: _MonthPickerSheet(
          initialMonth: initialMonth,
          initialRangeStart: initialRangeStart,
          initialRangeEnd: initialRangeEnd,
          accent: accent,
        ),
      ),
    ),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime? initialRangeStart;
  final DateTime? initialRangeEnd;
  final Color accent;

  const _MonthPickerSheet({
    required this.initialMonth,
    this.initialRangeStart,
    this.initialRangeEnd,
    required this.accent,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late _PickerMode _mode;
  late int _displayedYear;
  late int _selectedMonth; // focused month for the day grid — used in both modes
  late int _selectedYear;  // focused year for the day grid — used in both modes
  late int _selectedDay;   // single mode only

  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  final ScrollController _yearStripController = ScrollController();

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _weekdayAbbr = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  void initState() {
    super.initState();
    _mode = (widget.initialRangeStart != null && widget.initialRangeEnd != null)
        ? _PickerMode.range
        : _PickerMode.single;
    _rangeStart = widget.initialRangeStart;
    _rangeEnd = widget.initialRangeEnd;

    final focusBasis = widget.initialRangeStart ?? widget.initialMonth;
    _displayedYear = focusBasis.year;
    _selectedYear = focusBasis.year;
    _selectedMonth = focusBasis.month;
    _selectedDay = widget.initialMonth.day.clamp(1, _daysInMonth(_selectedYear, _selectedMonth));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_yearStripController.hasClients) return;
      final index = _selectedYear - (DateTime.now().year - 15);
      final target = (index * 64.0) - 100;
      _yearStripController.jumpTo(target.clamp(0.0, _yearStripController.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _yearStripController.dispose();
    super.dispose();
  }

  static int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _selectMonth(int month) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = _displayedYear;
      _selectedDay = _selectedDay.clamp(1, _daysInMonth(_selectedYear, _selectedMonth));
    });
  }

  void _selectDay(int day) {
    final tapped = DateTime(_selectedYear, _selectedMonth, day);

    if (_mode == _PickerMode.single) {
      setState(() => _selectedDay = day);
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Nothing picked yet, or a complete range already exists and the
        // user tapped again — start a fresh selection.
        _rangeStart = tapped;
        _rangeEnd = null;
      } else {
        // Start is set, end isn't — this tap completes it. Swap if the
        // user tapped a date before the start.
        if (tapped.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = tapped;
        } else {
          _rangeEnd = tapped;
        }
      }
    });
  }

  void _selectYearChip(int year) {
    setState(() => _displayedYear = year);
  }

  String _rangeStatusText() {
    String fmt(DateTime d) => '${_monthAbbr[d.month - 1]} ${d.day}, ${d.year}';
    if (_rangeStart == null) return 'Tap a day to pick the start date';
    if (_rangeEnd == null) return 'Start: ${fmt(_rangeStart!)} — now tap an end date';
    return '${fmt(_rangeStart!)}  →  ${fmt(_rangeEnd!)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final daysInSelectedMonth = _daysInMonth(_selectedYear, _selectedMonth);
    final leadingBlanks = DateTime(_selectedYear, _selectedMonth, 1).weekday % 7;

    final canConfirm = _mode == _PickerMode.single || (_rangeStart != null && _rangeEnd != null);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 18),
          Text(
            'Select date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 14),

          // ── Single / Range mode toggle ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235) : const Color(0xFFF3F4F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    label: 'Single date',
                    selected: _mode == _PickerMode.single,
                    accent: widget.accent,
                    onTap: () => setState(() => _mode = _PickerMode.single),
                  ),
                ),
                Expanded(
                  child: _ModeTab(
                    label: 'Date range',
                    selected: _mode == _PickerMode.range,
                    accent: widget.accent,
                    onTap: () => setState(() => _mode = _PickerMode.range),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Year navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _displayedYear--),
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '$_displayedYear',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() => _displayedYear++),
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              controller: _yearStripController,
              scrollDirection: Axis.horizontal,
              itemCount: 21,
              itemBuilder: (context, index) {
                final year = (now.year - 15) + index;
                final isDisplayed = year == _displayedYear;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isDisplayed
                        ? widget.accent.withOpacity(0.14)
                        : (isDark ? const Color(0xFF1E2235) : const Color(0xFFF3F4F8)),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _selectYearChip(year),
                      child: Container(
                        width: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDisplayed ? widget.accent : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDisplayed ? widget.accent : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Month grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = _selectedYear == _displayedYear && _selectedMonth == month;
              final isCurrent = _displayedYear == now.year && month == now.month;

              return Material(
                color: isSelected
                    ? widget.accent
                    : (isDark ? const Color(0xFF1E2235) : const Color(0xFFF3F4F8)),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectMonth(month),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent && !isSelected
                          ? Border.all(color: widget.accent.withOpacity(0.5), width: 1.2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthAbbr[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          if (_mode == _PickerMode.range) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 14, color: widget.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _rangeStatusText(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  if (_rangeStart != null || _rangeEnd != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _rangeStart = null;
                        _rangeEnd = null;
                      }),
                      child: Text(
                        'Clear',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.accent),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Day grid — calendar style, Sunday-first
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final w in _weekdayAbbr)
                SizedBox(
                  width: 32,
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInSelectedMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final cellDate = DateTime(_selectedYear, _selectedMonth, day);
              final isToday = _displayedYear == now.year &&
                  _selectedMonth == now.month &&
                  _selectedYear == _displayedYear &&
                  day == now.day;

              bool isSelected = false;
              bool isInRange = false;
              if (_mode == _PickerMode.single) {
                isSelected = _selectedDay == day;
              } else {
                final isStart = _rangeStart != null && _isSameDate(cellDate, _rangeStart!);
                final isEnd = _rangeEnd != null && _isSameDate(cellDate, _rangeEnd!);
                isSelected = isStart || isEnd;
                isInRange = _rangeStart != null &&
                    _rangeEnd != null &&
                    cellDate.isAfter(_rangeStart!) &&
                    cellDate.isBefore(_rangeEnd!);
              }

              return Material(
                color: isSelected
                    ? widget.accent
                    : (isInRange ? widget.accent.withOpacity(0.18) : Colors.transparent),
                shape: isInRange && !isSelected
                    ? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)))
                    : const CircleBorder(),
                child: InkWell(
                  customBorder: isInRange && !isSelected ? null : const CircleBorder(),
                  onTap: () => _selectDay(day),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: isInRange && !isSelected ? BoxShape.rectangle : BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: widget.accent.withOpacity(0.5), width: 1.2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: canConfirm
                      ? () {
                          if (_mode == _PickerMode.single) {
                            Navigator.pop(
                              context,
                              DatePickerResult.month(DateTime(_selectedYear, _selectedMonth, _selectedDay)),
                            );
                          } else {
                            Navigator.pop(
                              context,
                              DatePickerResult.range(_rangeStart!, _rangeEnd!),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: widget.accent.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ModeTab({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
