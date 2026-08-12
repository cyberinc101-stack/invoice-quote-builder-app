// reports_item_list.dart
// lib/screens/reports/reports_item_list.dart
//
// VISIBLE ACCOUNTING TOGGLE (this pass): the hidden long-press-to-toggle
// gesture is gone. Every card now shows an actual checkbox (ReportsIncludeCheckbox,
// exported below) that the person can see and tap directly — no more
// "long-press and hope a snackbar confirms it worked." The checkbox reflects
// the MANUAL excludedFromReports flag (checked = included); the small
// label next to it still reflects the ACTUAL current countsTowardReports
// state, since for documents that also depends on completion% and can be
// "Not counted" even while the checkbox is checked (e.g. a still-draft
// invoice). ReportsDocumentSection (reports_document_list.dart) imports
// and reuses this same checkbox so both card families look and behave
// identically.
//
// Standalone (NOT part of saved_documents_section.dart) card system used
// only by ReportsScreen to show the actual documents/expenses behind the
// period's totals, with its own list/grid/compact layout dropdown. Kept
// separate from doc_cards.dart's card family deliberately — those are
// `part of` the saved_documents_section.dart library and carry
// selection-mode/folder-menu features Reports doesn't need; duplicating
// just the visual language here as a small, dependency-free widget set is
// simpler than fighting that library boundary.
//
// ReportsListItem is intentionally generic (not typed to
// SavedInvoice/SavedQuote/SavedReceipt/ExpenseEntry) so ReportsScreen can
// build one flat list mixing all three document types plus expenses
// without this file needing to import any of those models.
//
// Two related-but-distinct booleans per item:
//   - excludedFromReports: the person's manual "don't count this" flag.
//     The checkbox flips exactly this.
//   - countsTowardReports: whether the item ACTUALLY counts toward the
//     totals right now — for documents this also depends on being 100%
//     complete (see ReportsScreen._isReportable), so it can be false even
//     when excludedFromReports is false. The label reflects this one; the
//     checkbox always flips the other.

import 'package:flutter/material.dart';

enum ReportsLayoutMode { list, grid, compact }

extension on ReportsLayoutMode {
  IconData get icon {
    switch (this) {
      case ReportsLayoutMode.list:
        return Icons.view_agenda_rounded;
      case ReportsLayoutMode.grid:
        return Icons.grid_view_rounded;
      case ReportsLayoutMode.compact:
        return Icons.view_headline_rounded;
    }
  }

  String get label {
    switch (this) {
      case ReportsLayoutMode.list:
        return 'List';
      case ReportsLayoutMode.grid:
        return 'Grid';
      case ReportsLayoutMode.compact:
        return 'Compact';
    }
  }
}

// Same bordered-pill-with-chevron visual as _LayoutToggleButton in
// doc_layout_mode.dart, reimplemented here since that one is private to
// the saved_documents_section.dart library and can't be imported.
class ReportsLayoutToggleButton extends StatelessWidget {
  final ReportsLayoutMode selected;
  final ValueChanged<ReportsLayoutMode> onChanged;

  const ReportsLayoutToggleButton({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<ReportsLayoutMode>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Change layout',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => ReportsLayoutMode.values.map((mode) {
        final isSelected = mode == selected;
        return PopupMenuItem<ReportsLayoutMode>(
          value: mode,
          child: Row(
            children: [
              Icon(mode.icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mode.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// Generic row: one document (invoice/quote/receipt) or one expense,
// reduced to exactly what the Reports card needs to render + toggle.
class ReportsListItem {
  final String key; // unique across the whole combined list
  final String title;
  final String subtitle; // e.g. "Invoice · Paid", "Travel"
  final String dateLabel; // e.g. "3 Aug 2026"
  final double amount;
  final Color accentColor;
  final bool excludedFromReports; // the manual flag — checkbox flips this
  final bool countsTowardReports; // actual current reportable state (drives label)
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleExclude; // called with the NEW exclude value

  const ReportsListItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.amount,
    required this.accentColor,
    required this.excludedFromReports,
    required this.countsTowardReports,
    required this.onTap,
    required this.onToggleExclude,
  });
}

String _fmtAmount(double v) => v.toStringAsFixed(2);

void _showToggleSnack(BuildContext context, String title, bool newExcludeValue) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(newExcludeValue
          ? '"$title" excluded from Reports'
          : '"$title" included in Reports'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

// ── Visible accounting-inclusion checkbox ─────────────────────────────────
//
// Exported so reports_document_list.dart's rich document cards use this
// exact same control (same visual, same behavior) instead of duplicating
// it. `included` is !excludedFromReports (checked = counts toward the
// totals, so far as the person controls it). `countsTowardReports` only
// affects the color/label — the checkbox itself is always interactive.
class ReportsIncludeCheckbox extends StatelessWidget {
  final bool included;
  final bool countsTowardReports;
  final String itemTitle;
  final ValueChanged<bool> onToggleExclude; // called with the NEW exclude value

  const ReportsIncludeCheckbox({
    super.key,
    required this.included,
    required this.countsTowardReports,
    required this.itemTitle,
    required this.onToggleExclude,
  });

  @override
  Widget build(BuildContext context) {
    final color = countsTowardReports ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E);

    void handleToggle(bool newIncluded) {
      final newExclude = !newIncluded;
      onToggleExclude(newExclude);
      _showToggleSnack(context, itemTitle, newExclude);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => handleToggle(!included),
      child: Container(
        padding: const EdgeInsets.only(left: 2, right: 7, top: 2, bottom: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: included,
                onChanged: (v) => handleToggle(v ?? false),
                activeColor: color,
                checkColor: Colors.white,
                side: BorderSide(color: color, width: 1.4),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            Text(countsTowardReports ? 'Counted' : 'Not counted',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper: header (title + count + layout toggle) + the cards ───

class ReportsItemSection extends StatelessWidget {
  final String title;
  final List<ReportsListItem> items;
  final ReportsLayoutMode layoutMode;
  final ValueChanged<ReportsLayoutMode> onLayoutChanged;
  final bool isDark;
  final String emptyLabel;

  const ReportsItemSection({
    super.key,
    required this.title,
    required this.items,
    required this.layoutMode,
    required this.onLayoutChanged,
    required this.isDark,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const Spacer(),
            ReportsLayoutToggleButton(selected: layoutMode, onChanged: onLayoutChanged),
            const SizedBox(width: 8),
            Text('${items.length}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap the checkbox to include or exclude it from the totals above.',
          style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(emptyLabel, style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.45))),
          )
        else
          _buildItems(),
      ],
    );
  }

  Widget _buildItems() {
    switch (layoutMode) {
      case ReportsLayoutMode.list:
        return Column(children: items.map((e) => _ReportsListCard(item: e, isDark: isDark)).toList());
      case ReportsLayoutMode.compact:
        return Column(children: items.map((e) => _ReportsCompactRow(item: e, isDark: isDark)).toList());
      case ReportsLayoutMode.grid:
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 116,
          ),
          children: items.map((e) => _ReportsGridCard(item: e, isDark: isDark)).toList(),
        );
    }
  }
}

class _ReportsListCard extends StatelessWidget {
  final ReportsListItem item;
  final bool isDark;
  const _ReportsListCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: item.onTap,
      child: Opacity(
        opacity: item.countsTowardReports ? 1.0 : 0.55,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: item.accentColor, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${item.subtitle} · ${item.dateLabel}',
                        style: TextStyle(fontSize: 11.5, color: cs.onSurface.withValues(alpha: 0.5)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtAmount(item.amount), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  const SizedBox(height: 4),
                  ReportsIncludeCheckbox(
                    included: !item.excludedFromReports,
                    countsTowardReports: item.countsTowardReports,
                    itemTitle: item.title,
                    onToggleExclude: item.onToggleExclude,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsCompactRow extends StatelessWidget {
  final ReportsListItem item;
  final bool isDark;
  const _ReportsCompactRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: item.onTap,
      child: Opacity(
        opacity: item.countsTowardReports ? 1.0 : 0.55,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: item.accentColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.title,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(_fmtAmount(item.amount), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(width: 8),
              ReportsIncludeCheckbox(
                included: !item.excludedFromReports,
                countsTowardReports: item.countsTowardReports,
                itemTitle: item.title,
                onToggleExclude: item.onToggleExclude,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsGridCard extends StatelessWidget {
  final ReportsListItem item;
  final bool isDark;
  const _ReportsGridCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: item.onTap,
      child: Opacity(
        opacity: item.countsTowardReports ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: item.accentColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.title,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(item.subtitle,
                  style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmtAmount(item.amount), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  ReportsIncludeCheckbox(
                    included: !item.excludedFromReports,
                    countsTowardReports: item.countsTowardReports,
                    itemTitle: item.title,
                    onToggleExclude: item.onToggleExclude,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}