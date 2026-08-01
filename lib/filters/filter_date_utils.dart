// filter_date_utils.dart
// lib/filters/filter_date_utils.dart
//
// dueDate / expiryDate / paymentDate are stored as free-text Strings on the
// data models, not DateTime. This tries a few common formats so "Overdue"
// and "Needs Action" can compare against today's date.
//
// ASSUMPTION: the date pickers elsewhere in the app write dates like
// "12 Jul 2026". If your actual date-entry widgets save a different
// format, add it to _kKnownFormats below. Un-parseable / empty strings are
// treated as "no date", not "overdue", so this fails safe.

import 'package:intl/intl.dart';
import 'filter_types.dart';

const List<String> _kKnownFormats = [
  'd MMM yyyy',
  'dd MMM yyyy',
  'yyyy-MM-dd',
  'MM/dd/yyyy',
  'dd/MM/yyyy',
];

DateTime? parseDocDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  for (final format in _kKnownFormats) {
    try {
      return DateFormat(format).parseStrict(trimmed);
    } catch (_) {
      // try the next format
    }
  }

  try {
    return DateTime.parse(trimmed);
  } catch (_) {
    return null;
  }
}

bool isPastDate(DateTime? date) {
  if (date == null) return false;
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  return dateOnly.isBefore(todayOnly);
}

bool isWithinDays(DateTime? date, int days) {
  if (date == null) return false;
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  final diff = dateOnly.difference(todayOnly).inDays;
  return diff >= 0 && diff <= days;
}

// Used by the new date-range filter. Operates on a real DateTime (we key
// off lastEditedAt), not the free-text dueDate/expiryDate/paymentDate
// fields above.
bool isInDateRange(
  DateTime? date,
  DateRangePreset preset, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  if (preset == DateRangePreset.all) return true;
  if (date == null) return false;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(date.year, date.month, date.day);

  switch (preset) {
    case DateRangePreset.all:
      return true;
    case DateRangePreset.thisMonth:
      return dateOnly.year == today.year && dateOnly.month == today.month;
    case DateRangePreset.last30Days:
      final diff = today.difference(dateOnly).inDays;
      return diff >= 0 && diff <= 30;
    case DateRangePreset.thisQuarter:
      final currentQuarter = (today.month - 1) ~/ 3;
      final dateQuarter = (dateOnly.month - 1) ~/ 3;
      return dateOnly.year == today.year && dateQuarter == currentQuarter;
    case DateRangePreset.thisYear:
      return dateOnly.year == today.year;
    case DateRangePreset.custom:
      if (customStart == null && customEnd == null) return true;
      if (customStart != null &&
          dateOnly.isBefore(DateTime(customStart.year, customStart.month, customStart.day))) {
        return false;
      }
      if (customEnd != null &&
          dateOnly.isAfter(DateTime(customEnd.year, customEnd.month, customEnd.day))) {
        return false;
      }
      return true;
  }
}