// filter_types.dart
// lib/filters/filter_types.dart
//
// Enums shared by the filter bar, filter_logic.dart, and home_screen.dart.
//
// UPDATED (this pass): QuickFilter gained three aging-bucket variants
// (overdue1to30 / overdue31to60 / overdue61plus) alongside the existing
// blanket "overdue"; added SortOption and DateRangePreset for the new
// sort control and date-range filter.

enum QuickFilter {
  none,
  needsAction,
  overdue,
  overdue1to30,
  overdue31to60,
  overdue61plus,
  drafts,
}

String quickFilterLabel(QuickFilter f) {
  switch (f) {
    case QuickFilter.needsAction:
      return 'Needs Action';
    case QuickFilter.overdue:
      return 'Overdue';
    case QuickFilter.overdue1to30:
      return 'Overdue 1-30d';
    case QuickFilter.overdue31to60:
      return 'Overdue 31-60d';
    case QuickFilter.overdue61plus:
      return 'Overdue 61+d';
    case QuickFilter.drafts:
      return 'Drafts';
    case QuickFilter.none:
      return '';
  }
}

enum SortOption { recentFirst, oldestFirst, alphabetical, amountHighLow, amountLowHigh }

String sortOptionLabel(SortOption o) {
  switch (o) {
    case SortOption.recentFirst:
      return 'Most Recent';
    case SortOption.oldestFirst:
      return 'Oldest First';
    case SortOption.alphabetical:
      return 'Alphabetical';
    case SortOption.amountHighLow:
      return 'Amount: High to Low';
    case SortOption.amountLowHigh:
      return 'Amount: Low to High';
  }
}

enum DateRangePreset { all, thisMonth, last30Days, thisQuarter, thisYear, custom }

String dateRangePresetLabel(DateRangePreset p) {
  switch (p) {
    case DateRangePreset.all:
      return 'All Time';
    case DateRangePreset.thisMonth:
      return 'This Month';
    case DateRangePreset.last30Days:
      return 'Last 30 Days';
    case DateRangePreset.thisQuarter:
      return 'This Quarter';
    case DateRangePreset.thisYear:
      return 'This Year';
    case DateRangePreset.custom:
      return 'Custom Range';
  }
}