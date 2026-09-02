// lib/screens/history_screen.dart
//
// FILTERS PASS (this update): added two more filter dimensions alongside
// the existing event-type chips (All/Created/Shared/Downloaded/Sent/
// Printed):
//   1. Document type — All/Invoices/Quotes/Receipts, a second chip row.
//   2. Date range — a compact button opening a bottom sheet of presets
//      (Today/Yesterday/This Week/This Month/All Time) plus a "Custom
//      range..." option that opens showDateRangePicker.
// All three filters combine (AND) via _filteredEvents(), applied on top
// of history.eventsOfType(_eventTypeFilter) — HistoryProvider itself is
// unchanged; filtering the doc-type/date dimensions happens here since
// the event list is small (capped at 300) and doesn't need provider-side
// filtering. Grouping-by-day and the empty state both now reflect the
// combined filter set, not just event type.
//
// ACTIVITY LOG REWRITE (earlier): HistoryScreen used to just re-show
// SavedDocumentsContainers sorted a different way — not actual history.
// It's now a real activity feed backed by HistoryProvider: every
// created/shared/downloaded/sent/printed/deleted event, newest first,
// grouped by day, each with a "send again" action when a cached file is
// still available. No longer depends on lang_helper's t[...]! lookups
// (that was the source of the null-check crash — history_sort_* keys
// were never added to the language files) so this screen can't crash on
// a missing translation key anymore.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/history_event.dart';
import '../providers/history_provider.dart';
import '../widgets/very_top_header.dart';
import 'settings_screen.dart';

// ── Date-range presets ──────────────────────────────────────────────────

enum _DateRangePreset { allTime, today, yesterday, thisWeek, thisMonth, custom }

class _DateRangeFilter {
  final _DateRangePreset preset;
  final DateTimeRange? customRange;

  const _DateRangeFilter(this.preset, [this.customRange]);

  static const allTime = _DateRangeFilter(_DateRangePreset.allTime);

  String get label {
    switch (preset) {
      case _DateRangePreset.allTime:
        return 'All Time';
      case _DateRangePreset.today:
        return 'Today';
      case _DateRangePreset.yesterday:
        return 'Yesterday';
      case _DateRangePreset.thisWeek:
        return 'This Week';
      case _DateRangePreset.thisMonth:
        return 'This Month';
      case _DateRangePreset.custom:
        if (customRange == null) return 'Custom';
        final s = customRange!.start;
        final e = customRange!.end;
        String fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
        return '${fmt(s)} - ${fmt(e)}';
    }
  }

  bool matches(DateTime ts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case _DateRangePreset.allTime:
        return true;
      case _DateRangePreset.today:
        final d = DateTime(ts.year, ts.month, ts.day);
        return d == today;
      case _DateRangePreset.yesterday:
        final d = DateTime(ts.year, ts.month, ts.day);
        return d == today.subtract(const Duration(days: 1));
      case _DateRangePreset.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return !ts.isBefore(startOfWeek);
      case _DateRangePreset.thisMonth:
        return ts.year == now.year && ts.month == now.month;
      case _DateRangePreset.custom:
        if (customRange == null) return true;
        final d = DateTime(ts.year, ts.month, ts.day);
        final start = DateTime(customRange!.start.year, customRange!.start.month, customRange!.start.day);
        final end = DateTime(customRange!.end.year, customRange!.end.month, customRange!.end.day);
        return !d.isBefore(start) && !d.isAfter(end);
    }
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryEventType? _eventTypeFilter; // null = All
  HistoryDocType? _docTypeFilter; // null = All
  _DateRangeFilter _dateFilter = _DateRangeFilter.allTime;

  List<HistoryEvent> _filteredEvents(HistoryProvider history) {
    return history
        .eventsOfType(_eventTypeFilter)
        .where((e) => _docTypeFilter == null || e.docType == _docTypeFilter)
        .where((e) => _dateFilter.matches(e.timestamp))
        .toList();
  }

  bool get _hasActiveFilters =>
      _eventTypeFilter != null ||
      _docTypeFilter != null ||
      _dateFilter.preset != _DateRangePreset.allTime;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final events = _filteredEvents(history);

    return Scaffold(
      appBar: VeryTopHeader(
        showBackButton: true,
        onHomeTap: () => Navigator.pop(context),
        onPremiumTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium features coming soon')),
          );
        },
        onSettingsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventTypeBar(context, history),
          _buildSecondaryFilterBar(context),
          Expanded(
            child: !history.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : events.isEmpty
                    ? _buildEmptyState(context)
                    : _buildEventList(context, events),
          ),
        ],
      ),
    );
  }

  // ── Filter bar 1: event type ─────────────────────────────────────────────

  Widget _buildEventTypeBar(BuildContext context, HistoryProvider history) {
    final colorScheme = Theme.of(context).colorScheme;

    final chips = <MapEntry<String, HistoryEventType?>>[
      const MapEntry('All', null),
      const MapEntry('Created', HistoryEventType.created),
      const MapEntry('Shared', HistoryEventType.shared),
      const MapEntry('Downloaded', HistoryEventType.downloaded),
      const MapEntry('Sent', HistoryEventType.sent),
      const MapEntry('Printed', HistoryEventType.printed),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips.map((entry) {
                  final selected = _eventTypeFilter == entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.key),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _eventTypeFilter = entry.value),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (history.events.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              onPressed: () => _confirmClearAll(context, history),
            ),
        ],
      ),
    );
  }

  // ── Filter bar 2: document type + date range ─────────────────────────────

  Widget _buildSecondaryFilterBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final docChips = <MapEntry<String, HistoryDocType?>>[
      const MapEntry('All Docs', null),
      const MapEntry('Invoices', HistoryDocType.invoice),
      const MapEntry('Quotes', HistoryDocType.quote),
      const MapEntry('Receipts', HistoryDocType.receipt),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...docChips.map((entry) {
                    final selected = _docTypeFilter == entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.key),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _docTypeFilter = entry.value),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surface,
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.25),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showDateFilterSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _dateFilter.preset != _DateRangePreset.allTime
                            ? colorScheme.primary
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _dateFilter.preset != _DateRangePreset.allTime
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: _dateFilter.preset != _DateRangePreset.allTime
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _dateFilter.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _dateFilter.preset != _DateRangePreset.allTime
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hasActiveFilters)
            TextButton(
              onPressed: () => setState(() {
                _eventTypeFilter = null;
                _docTypeFilter = null;
                _dateFilter = _DateRangeFilter.allTime;
              }),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Reset', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _showDateFilterSheet(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final presets = <MapEntry<String, _DateRangePreset>>[
      const MapEntry('All Time', _DateRangePreset.allTime),
      const MapEntry('Today', _DateRangePreset.today),
      const MapEntry('Yesterday', _DateRangePreset.yesterday),
      const MapEntry('This Week', _DateRangePreset.thisWeek),
      const MapEntry('This Month', _DateRangePreset.thisMonth),
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Filter by date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              ...presets.map((p) {
                final selected = _dateFilter.preset == p.value;
                return ListTile(
                  leading: Icon(
                    selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  title: Text(p.key),
                  onTap: () {
                    setState(() => _dateFilter = _DateRangeFilter(p.value));
                    Navigator.pop(sheetContext);
                  },
                );
              }),
              ListTile(
                leading: Icon(
                  _dateFilter.preset == _DateRangePreset.custom
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: _dateFilter.preset == _DateRangePreset.custom
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                title: const Text('Custom range...'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 5),
                    lastDate: now,
                    initialDateRange: _dateFilter.customRange ??
                        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
                  );
                  if (picked != null) {
                    setState(() => _dateFilter = _DateRangeFilter(_DateRangePreset.custom, picked));
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClearAll(
      BuildContext context, HistoryProvider history) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
            'This removes your activity log. It does not delete any invoices, quotes, or receipts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await history.clearAll();
    }
  }

  // ── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 48, color: colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters ? 'Nothing matches these filters' : 'No activity yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _hasActiveFilters
                  ? 'Try a different filter, or reset above.'
                  : 'Documents you create, share, download, or send will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Event list, grouped by day ───────────────────────────────────────────

  Widget _buildEventList(BuildContext context, List<HistoryEvent> events) {
    final groups = <String, List<HistoryEvent>>{};
    for (final e in events) {
      final label = _dayLabel(e.timestamp);
      groups.putIfAbsent(label, () => []).add(e);
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final label = groups.keys.elementAt(groupIndex);
        final groupEvents = groups[label]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
            ...groupEvents.map((e) => _HistoryTile(event: e)),
          ],
        );
      },
    );
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// -----------------------------------------------------------------------------
// _HistoryTile — one activity-feed row
// -----------------------------------------------------------------------------

class _HistoryTile extends StatelessWidget {
  final HistoryEvent event;
  const _HistoryTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _metaFor(event.type);
    final canReshare = event.filePath != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, size: 18, color: meta.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_docTypeLabel(event.docType)} ${event.docNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(event),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeLabel(event.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: canReshare ? 'Send again' : 'File no longer available',
                  icon: Icon(
                    Icons.ios_share_rounded,
                    size: 18,
                    color: canReshare
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                  onPressed: canReshare ? () => _reshare(context) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reshare(BuildContext context) async {
    final path = event.filePath;
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That file is no longer available.')),
        );
      }
      return;
    }
    await Share.shareXFiles(
      [XFile(path, mimeType: _mimeFor(path))],
      subject: '${_docTypeLabel(event.docType)} ${event.docNumber}',
    );
  }

  String? _mimeFor(String path) {
    if (path.endsWith('.pdf')) return 'application/pdf';
    if (path.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (path.endsWith('.csv')) return 'text/csv';
    return null;
  }

  String _docTypeLabel(HistoryDocType t) {
    switch (t) {
      case HistoryDocType.invoice:
        return 'Invoice';
      case HistoryDocType.quote:
        return 'Quote';
      case HistoryDocType.receipt:
        return 'Receipt';
    }
  }

  String _subtitle(HistoryEvent e) {
    final parts = <String>[_metaFor(e.type).verb];
    if (e.clientName != null && e.clientName!.isNotEmpty) parts.add(e.clientName!);
    if (e.amount != null) parts.add(_formatAmount(e.amount!, e.currency));
    return parts.join(' • ');
  }

  String _formatAmount(double amount, String? currency) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    final prefix = (currency == null || currency.isEmpty) ? '' : '$currency ';
    return '$prefix$whole.${parts[1]}';
  }

  String _timeLabel(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  _EventMeta _metaFor(HistoryEventType type) {
    switch (type) {
      case HistoryEventType.created:
        return _EventMeta(Icons.add_circle_outline_rounded, const Color(0xFF2196F3), 'Created');
      case HistoryEventType.shared:
        return _EventMeta(Icons.ios_share_rounded, const Color(0xFF7B1FA2), 'Shared');
      case HistoryEventType.downloaded:
        return _EventMeta(Icons.download_rounded, const Color(0xFF00897B), 'Downloaded');
      case HistoryEventType.sent:
        return _EventMeta(Icons.send_rounded, const Color(0xFF43A047), 'Sent');
      case HistoryEventType.printed:
        return _EventMeta(Icons.print_rounded, const Color(0xFFFB8C00), 'Printed');
      case HistoryEventType.deleted:
        return _EventMeta(Icons.delete_outline_rounded, const Color(0xFFD32F2F), 'Deleted');
    }
  }
}

class _EventMeta {
  final IconData icon;
  final Color color;
  final String verb;
  const _EventMeta(this.icon, this.color, this.verb);
}
