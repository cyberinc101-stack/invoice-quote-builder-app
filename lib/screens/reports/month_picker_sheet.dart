// month_picker_sheet.dart
// lib/screens/reports/month_picker_sheet.dart
//
// Month/day picker for the Reports screen — Single date / Date range toggle.
//
// FIX (this pass): range-highlight logic rewritten to compare plain
// (year, month, day) integers instead of DateTime objects. DateTime
// equality/isBefore/isAfter comparisons are timezone/DST-sensitive and can
// silently disagree across a setState rebuild even when the underlying
// calendar date is identical — that was the root cause of the start date's
// highlight dropping out as soon as the end date was picked. Packing each
// date into a single comparable int (_dayKey = year*10000 + month*100 + day)
// makes start/end/in-range checks pure integer comparisons with no
// ambiguity, so both endpoints now stay highlighted reliably, with days
// strictly between them getting a lighter tint.

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

// Packs a calendar date into a single comparable int, e.g. 2026-08-08 ->
// 20260808. Used everywhere range selection needs to compare "is this cell
// the start / the end / strictly between" — plain int comparison, no
// DateTime timezone/DST ambiguity.
int _dayKey(int year, int month, int day) => year * 10000 + month * 100 + day;
int _dayKeyOf(DateTime d) => _dayKey(d.year, d.month, d.day);

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

  // Range mode state — stored as plain (year, month, day) int keys, NOT
  // DateTime objects. This is the actual fix: comparing DateTime instances
  // for equality/ordering across a setState rebuild is timezone/DST
  // sensitive and was the source of the start-date highlight dropping out
  // as soon as the end date got picked. Ints have no such ambiguity.
  int? _rangeStartKey;
  int? _rangeEndKey;
  DateTime? _rangeStartDate; // kept alongside the key purely for display text
  DateTime? _rangeEndDate;

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

    _rangeStartDate = widget.initialRangeStart;
    _rangeEndDate = widget.initialRangeEnd;
    _rangeStartKey = widget.initialRangeStart != null ? _dayKeyOf(widget.initialRangeStart!) : null;
    _rangeEndKey = widget.initialRangeEnd != null ? _dayKeyOf(widget.initialRangeEnd!) : null;

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

  void _selectMonth(int month) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = _displayedYear;
      _selectedDay = _selectedDay.clamp(1, _daysInMonth(_selectedYear, _selectedMonth));
    });
  }

  void _selectDay(int day) {
    if (_mode == _PickerMode.single) {
      setState(() => _selectedDay = day);
      return;
    }

    final tappedDate = DateTime(_selectedYear, _selectedMonth, day);
    final tappedKey = _dayKey(_selectedYear, _selectedMonth, day);

    setState(() {
      final hasCompleteRange = _rangeStartKey != null && _rangeEndKey != null;

      if (_rangeStartKey == null || hasCompleteRange) {
        // Nothing picked yet, or a complete range already exists and the
        // user tapped again — start a fresh selection.
        _rangeStartKey = tappedKey;
        _rangeStartDate = tappedDate;
        _rangeEndKey = null;
        _rangeEndDate = null;
      } else {
        // Start is set, end isn't — this tap completes it. Swap if the
        // user tapped a date before the start.
        if (tappedKey < _rangeStartKey!) {
          _rangeEndKey = _rangeStartKey;
          _rangeEndDate = _rangeStartDate;
          _rangeStartKey = tappedKey;
          _rangeStartDate = tappedDate;
        } else {
          _rangeEndKey = tappedKey;
          _rangeEndDate = tappedDate;
        }
      }
    });
  }

  void _selectYearChip(int year) {
    setState(() => _displayedYear = year);
  }

  String _rangeStatusText() {
    String fmt(DateTime d) => '${_monthAbbr[d.month - 1]} ${d.day}, ${d.year}';
    if (_rangeStartDate == null) return 'Tap a day to pick the start date';
    if (_rangeEndDate == null) return 'Start: ${fmt(_rangeStartDate!)} — now tap an end date';
    return '${fmt(_rangeStartDate!)}  →  ${fmt(_rangeEndDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final daysInSelectedMonth = _daysInMonth(_selectedYear, _selectedMonth);
    final leadingBlanks = DateTime(_selectedYear, _selectedMonth, 1).weekday % 7;

    final canConfirm = _mode == _PickerMode.single || (_rangeStartKey != null && _rangeEndKey != null);

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
                  if (_rangeStartKey != null || _rangeEndKey != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _rangeStartKey = null;
                        _rangeEndKey = null;
                        _rangeStartDate = null;
                        _rangeEndDate = null;
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
              final cellKey = _dayKey(_selectedYear, _selectedMonth, day);
              final isToday = _displayedYear == now.year &&
                  _selectedMonth == now.month &&
                  _selectedYear == _displayedYear &&
                  day == now.day;

              bool isSelected = false;
              bool isInRange = false;
              if (_mode == _PickerMode.single) {
                isSelected = _selectedDay == day;
              } else {
                final isStart = _rangeStartKey != null && cellKey == _rangeStartKey;
                final isEnd = _rangeEndKey != null && cellKey == _rangeEndKey;
                isSelected = isStart || isEnd;
                isInRange = _rangeStartKey != null &&
                    _rangeEndKey != null &&
                    cellKey > _rangeStartKey! &&
                    cellKey < _rangeEndKey!;
              }

              return Material(
                key: ValueKey('day-cell-$cellKey'),
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
                              DatePickerResult.range(_rangeStartDate!, _rangeEndDate!),
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