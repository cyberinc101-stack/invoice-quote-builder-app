// month_picker_sheet.dart
// lib/screens/reports/month_picker_sheet.dart
//
// Month/day picker for the Reports screen — Single date / Date range toggle.
//
// DAY-COUNT + LONG-RANGE-YEAR PASS (this update):
//   - The range status pill now shows how many days the selected range
//     spans (inclusive of both endpoints — Feb 5 -> Feb 5 reads "1 day",
//     Feb 5 -> Feb 6 reads "2 days"), right under the start/end date text,
//     so the length of a range is visible without doing the subtraction
//     yourself.
//   - The year strip previously only ever rendered a fixed window of 21
//     years around whatever "now" was when the sheet first opened
//     ((now.year - 15) to (now.year + 5)). Tapping the chevrons or typing
//     a year further back than that (via the year-input dialog, which
//     already allowed up to 100 years back) moved _displayedYear correctly
//     but the strip had no chip for it and didn't scroll — the highlighted
//     year silently fell off the edge of the list. The strip now spans a
//     full 100 years back / 50 forward (itemCount 151, matching the
//     dialog's own validator bounds) and _selectYearChip always animates
//     the strip to bring the newly-selected year chip into view, so
//     chevron-stepping or typing back a full 10 years (or more) always
//     keeps the selection visible on-screen instead of just updating a
//     label above an unscrolled strip.
//
// CONNECTED RANGE BAND (earlier pass): the range-mode day grid now renders a
// thin horizontal band behind each day that falls inside the selected
// range — start, end, and everything between — so a multi-day range reads
// as one continuous connected bar, with the start/end days themselves
// drawn as solid filled circles sitting on top of that band (matching the
// familiar Airbnb-style date-range picker look). Previously start/end/
// in-between all shared one rounded-rectangle shape with no visual link
// between adjacent days; that's replaced here with:
//   - Strictly-between days: a plain rectangular band segment, no visible
//     circle, in the accent color at low opacity.
//   - The start day: a band segment (rounded on the left, square on the
//     right so it flows into the next day) UNDER a solid accent circle
//     for the day number itself.
//   - The end day: mirrored — square on the left, rounded on the right —
//     under its own solid circle.
//   - A single-day "range" (start == end, e.g. tapping the same day
//     twice) renders with no band at all, just the one solid circle.
// Single-date mode is completely unchanged — still a plain circle, no
// band logic applies there.
//
// TAP-TO-ENTER-YEAR (earlier pass): the year label between the chevrons is
// tappable — opens a small dialog with a numeric text field so a user can
// type a year directly instead of scrolling the year strip or tapping the
// chevrons one year at a time. Routes through the same _selectYearChip()
// the strip and chevrons already use.
//
// FIX (earlier pass): the day grid was driven by a separate `_selectedYear`
// that only got updated when a month chip was tapped (_selectMonth), NOT
// when the year strip was tapped. Navigating to a different year via the
// year strip, then tapping a day WITHOUT first re-tapping a month, meant
// the tap's date was computed against the stale old year — silently
// producing a wrong start/end date and broken-looking range highlighting.
// Fixed by removing `_selectedYear` entirely and always deriving the day
// grid from `_displayedYear` (the single source of truth the year strip
// already controls), so the two can never drift apart again. Year
// chevrons now also route through `_selectYearChip` (previously they
// mutated `_displayedYear` directly and skipped the day-clamp step).

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

  // Single source of truth for "what year is the day grid showing" —
  // drives the year strip highlight AND the day grid. Previously there
  // was also a separate `_selectedYear` that only synced on month-tap;
  // that split was the root cause of the range-picker bug (see file
  // header) — always read/write _displayedYear, never reintroduce a
  // second year field.
  late int _displayedYear;
  late int _selectedMonth; // focused month for the day grid — used in both modes
  late int _selectedDay;   // single mode only

  // Range mode state — stored as plain (year, month, day) int keys, NOT
  // DateTime objects. Comparing DateTime instances for equality/ordering
  // across a setState rebuild is timezone/DST sensitive; ints have no
  // such ambiguity.
  int? _rangeStartKey;
  int? _rangeEndKey;
  DateTime? _rangeStartDate; // kept alongside the key purely for display text
  DateTime? _rangeEndDate;

  final ScrollController _yearStripController = ScrollController();

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _weekdayAbbr = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  // Year strip bounds — 100 years back, 50 forward from "now" (fixed once
  // at the moment the sheet opens, so the strip's item count/positions
  // don't shift under the user mid-session). Matches the year-input
  // dialog's own validator bounds exactly, so anything typeable there is
  // guaranteed to also have a chip in the strip to scroll to.
  late final int _yearStripFirst;
  static const int _yearStripYearsBack = 100;
  static const int _yearStripYearsForward = 50;
  int get _yearStripCount => _yearStripYearsBack + _yearStripYearsForward + 1;

  static const double _yearChipWidth = 56.0;
  static const double _yearChipGap = 8.0;

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
    _selectedMonth = focusBasis.month;
    _selectedDay = widget.initialMonth.day.clamp(1, _daysInMonth(_displayedYear, _selectedMonth));

    _yearStripFirst = DateTime.now().year - _yearStripYearsBack;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollYearStripTo(_displayedYear, animate: false));
  }

  @override
  void dispose() {
    _yearStripController.dispose();
    super.dispose();
  }

  static int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  // Centers (as best it can within scroll bounds) the given year's chip in
  // the visible strip. Called on init AND every time _displayedYear
  // changes via chevrons/strip tap/typed-year dialog, so the highlighted
  // chip is never left scrolled out of view — the bug this pass fixes for
  // jumps of many years at once (e.g. chevron-stepping or typing back a
  // decade or more).
  void _scrollYearStripTo(int year, {bool animate = true}) {
    if (!_yearStripController.hasClients) return;
    final index = year - _yearStripFirst;
    if (index < 0 || index >= _yearStripCount) return;
    const viewportChipsApprox = 5;
    final target = (index * (_yearChipWidth + _yearChipGap)) -
        ((viewportChipsApprox / 2) * (_yearChipWidth + _yearChipGap));
    final clamped = target.clamp(0.0, _yearStripController.position.maxScrollExtent);
    if (animate) {
      _yearStripController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      _yearStripController.jumpTo(clamped);
    }
  }

  void _selectMonth(int month) {
    setState(() {
      _selectedMonth = month;
      _selectedDay = _selectedDay.clamp(1, _daysInMonth(_displayedYear, _selectedMonth));
    });
  }

  void _selectDay(int day) {
    if (_mode == _PickerMode.single) {
      setState(() => _selectedDay = day);
      return;
    }

    final tappedDate = DateTime(_displayedYear, _selectedMonth, day);
    final tappedKey = _dayKey(_displayedYear, _selectedMonth, day);

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
    setState(() {
      _displayedYear = year;
      // Re-clamp in case the new year changes days-in-month (leap year).
      _selectedDay = _selectedDay.clamp(1, _daysInMonth(_displayedYear, _selectedMonth));
    });
    _scrollYearStripTo(year);
  }

  // Opens a small dialog with a numeric field so a year can be typed
  // directly (e.g. jumping straight to 1998, or 10+ years back) instead
  // of scrolling the year strip or tapping the chevrons one year at a
  // time. Routes through _selectYearChip on confirm — same single source
  // of truth the strip and chevrons already use, so the strip always
  // scrolls to reveal the typed year too.
  Future<void> _openYearInputDialog() async {
    final controller = TextEditingController(text: '$_displayedYear');
    final formKey = GlobalKey<FormState>();
    final now = DateTime.now();

    final entered = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Go to year', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(counterText: '', hintText: 'YYYY'),
            validator: (v) {
              final year = int.tryParse((v ?? '').trim());
              if (year == null || v!.trim().length != 4) return 'Enter a 4-digit year';
              if (year < now.year - 100 || year > now.year + 50) return 'Enter a realistic year';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.accent, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, int.parse(controller.text.trim()));
              }
            },
            child: const Text('Go', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (entered != null) _selectYearChip(entered);
  }

  String _rangeStatusText() {
    String fmt(DateTime d) => '${_monthAbbr[d.month - 1]} ${d.day}, ${d.year}';
    if (_rangeStartDate == null) return 'Tap a day to pick the start date';
    if (_rangeEndDate == null) return 'Start: ${fmt(_rangeStartDate!)} — now tap an end date';
    return '${fmt(_rangeStartDate!)}  →  ${fmt(_rangeEndDate!)}';
  }

  // Inclusive day count for the active range — Feb 5 -> Feb 5 is 1 day,
  // Feb 5 -> Feb 6 is 2 days. Returns null until both endpoints are set,
  // so callers can hide the "N days" line entirely until there's a
  // complete range to describe.
  int? _rangeDayCount() {
    if (_rangeStartDate == null || _rangeEndDate == null) return null;
    final start = DateTime(_rangeStartDate!.year, _rangeStartDate!.month, _rangeStartDate!.day);
    final end = DateTime(_rangeEndDate!.year, _rangeEndDate!.month, _rangeEndDate!.day);
    return end.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final daysInSelectedMonth = _daysInMonth(_displayedYear, _selectedMonth);
    final leadingBlanks = DateTime(_displayedYear, _selectedMonth, 1).weekday % 7;

    final canConfirm = _mode == _PickerMode.single || (_rangeStartKey != null && _rangeEndKey != null);
    final rangeDayCount = _mode == _PickerMode.range ? _rangeDayCount() : null;

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

          // Year navigation — the year label itself is tappable, opening a
          // dialog to type a year directly.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _selectYearChip(_displayedYear - 1),
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              InkWell(
                onTap: _openYearInputDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_displayedYear',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.edit_rounded, size: 13, color: colorScheme.onSurface.withValues(alpha: 0.35)),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _selectYearChip(_displayedYear + 1),
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              controller: _yearStripController,
              scrollDirection: Axis.horizontal,
              itemCount: _yearStripCount,
              itemBuilder: (context, index) {
                final year = _yearStripFirst + index;
                final isDisplayed = year == _displayedYear;
                return Padding(
                  padding: const EdgeInsets.only(right: _yearChipGap),
                  child: Material(
                    color: isDisplayed
                        ? widget.accent
                        : (isDark ? const Color(0xFF1E2235) : const Color(0xFFF3F4F8)),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _selectYearChip(year),
                      child: Container(
                        width: _yearChipWidth,
                        alignment: Alignment.center,
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDisplayed ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
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
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = _selectedMonth == month;
                final isCurrent = _displayedYear == now.year && month == now.month;

                // Month-level equivalent of the day grid's connecting band —
                // in range mode, the months strictly between the start
                // date's month and the end date's month get a light accent
                // fill so a multi-month range (e.g. May -> December) reads
                // as one continuous highlighted stretch, not just two
                // isolated endpoint boxes. Comparable via a plain
                // (year*100 + month) int key, same reasoning as _dayKey —
                // no DateTime ordering ambiguity.
                int monthKey(int year, int mo) => year * 100 + mo;
                final startMonthKey =
                    _mode == _PickerMode.range && _rangeStartDate != null
                        ? monthKey(_rangeStartDate!.year, _rangeStartDate!.month)
                        : null;
                final endMonthKey = _mode == _PickerMode.range && _rangeEndDate != null
                    ? monthKey(_rangeEndDate!.year, _rangeEndDate!.month)
                    : null;
                final cellMonthKey = monthKey(_displayedYear, month);

                final isRangeStartMonth = startMonthKey != null && cellMonthKey == startMonthKey;
                final isRangeEndMonth = endMonthKey != null && cellMonthKey == endMonthKey;
                final isRangeBetweenMonth = startMonthKey != null &&
                    endMonthKey != null &&
                    cellMonthKey > startMonthKey &&
                    cellMonthKey < endMonthKey;

                // SINGLE-MODE FIX: in Single date mode, "today's month"
                // must never render as a second solid box alongside
                // whichever month is actually selected/focused — only one
                // box should ever appear filled. "Current month" now only
                // ever earns a thin outline (and only when it isn't
                // otherwise highlighted), same treatment the day grid
                // already gives "today". In Date range mode, BOTH the
                // start month and end month are correctly meant to show
                // filled — that's intentional, not a bug — so isCurrent
                // still never contributes a second solid fill there
                // either, it's irrelevant to range coloring.
                final isHighlighted = _mode == _PickerMode.single
                    ? isSelected
                    : (isSelected || isRangeStartMonth || isRangeEndMonth);
                final showCurrentOutline = isCurrent && !isHighlighted;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isHighlighted
                        ? widget.accent
                        : isRangeBetweenMonth
                            ? widget.accent.withValues(alpha: 0.18)
                            : (isDark ? const Color(0xFF1E2235) : const Color(0xFFF3F4F8)),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _selectMonth(month),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: showCurrentOutline
                              ? Border.all(color: widget.accent.withValues(alpha: 0.5), width: 1.2)
                              : null,
                        ),
                        child: Text(
                          _monthAbbr[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isHighlighted ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          if (_mode == _PickerMode.range) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  // Inclusive day count for the completed range — hidden
                  // until both a start and an end date are picked, same
                  // as the "now tap an end date" prompt above it.
                  if (rangeDayCount != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Text(
                        '$rangeDayCount day${rangeDayCount == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
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
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withValues(alpha: 0.4)),
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
              final cellKey = _dayKey(_displayedYear, _selectedMonth, day);
              final isToday = _displayedYear == now.year &&
                  _selectedMonth == now.month &&
                  day == now.day;

              if (_mode == _PickerMode.single) {
                final isSelected = _selectedDay == day;
                return Material(
                  key: ValueKey('day-cell-$cellKey'),
                  color: isSelected ? widget.accent : Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _selectDay(day),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: widget.accent.withValues(alpha: 0.5), width: 1.2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // ── Range mode — connected bar + matching box endpoints ───
              final isStart = _rangeStartKey != null && cellKey == _rangeStartKey;
              final isEnd = _rangeEndKey != null && cellKey == _rangeEndKey;
              final isEndpoint = isStart || isEnd;
              final isBetween = _rangeStartKey != null &&
                  _rangeEndKey != null &&
                  cellKey > _rangeStartKey! &&
                  cellKey < _rangeEndKey!;
              // A single-day range (start == end, e.g. tapping the same
              // day twice) gets no connecting bar — just its own box,
              // same as an endpoint with nothing to connect to.
              final isSingleDayRange = isStart && isEnd;

              // Bar is a clearly-visible mid-tone fill (not a faint wash)
              // so the connection between start and end reads at a
              // glance, distinct from the solid dark endpoint boxes.
              final barColor = widget.accent.withValues(alpha: 0.32);
              // Which half(s) of this cell the bar covers. Strictly-
              // between days get both halves (bar flows edge-to-edge,
              // connecting to neighbors on both sides). The start day
              // gets the right half only (nothing to connect to on the
              // left); the end day gets the left half only.
              final barLeft = (isBetween || isEnd) && !isSingleDayRange;
              final barRight = (isBetween || isStart) && !isSingleDayRange;

              return Stack(
                key: ValueKey('day-cell-$cellKey'),
                alignment: Alignment.center,
                children: [
                  if (barLeft || barRight)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        heightFactor: 0.85,
                        child: Row(
                          children: [
                            Expanded(
                              child: barLeft
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: isEnd
                                            ? const BorderRadius.horizontal(left: Radius.circular(8))
                                            : BorderRadius.zero,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            Expanded(
                              child: barRight
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: isStart
                                            ? const BorderRadius.horizontal(right: Radius.circular(8))
                                            : BorderRadius.zero,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Start and end both render as the SAME solid dark
                  // rounded-box shape (not a circle) so the two ends of
                  // the range look identical, sitting on top of the
                  // lighter connecting bar.
                  Material(
                    color: isEndpoint ? widget.accent : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onTap: () => _selectDay(day),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isEndpoint
                              ? Border.all(color: widget.accent.withValues(alpha: 0.5), width: 1.2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isEndpoint ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                  child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
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
                              DatePickerResult.month(DateTime(_displayedYear, _selectedMonth, _selectedDay)),
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
                    disabledBackgroundColor: widget.accent.withValues(alpha: 0.3),
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
            color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}