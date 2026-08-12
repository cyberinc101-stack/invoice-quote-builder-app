// reports_document_list.dart
// lib/screens/reports/reports_document_list.dart
//
// DISPLAY OPTIONS PASS (this update): the List/Grid/Compact cards here now
// watch CardDisplayPrefs (lib/widgets/saved_documents/card_display_prefs.
// dart) — the same instance Home's Invoices/Quotes/Receipts/Expenses
// sections read from — and conditionally render logo, amount, secondary
// date, created+ref row, progress bar, and status chip. One set of
// switches (DisplayOptionsButton, opened from Home) now controls every
// card family in the app, including this one.
//
// LOGO FIX (this update): _ReportsLogoAvatar gained independent width/
// height (defaulting to `size`), and the List card (_ReportsDocCard) now
// wraps its Row in IntrinsicHeight + CrossAxisAlignment.stretch, passing
// height: double.infinity so the logo fills the card's full height
// edge-to-edge instead of a small square. Grid/compact stay square.
//
// ── Everything below this point is unchanged from the previous pass
// except the CardDisplayPrefs gating and the List-avatar fill fix noted
// above. See original header comments preserved below. ──
//
// EXPENSES-MERGED PASS (earlier): ReportsDocType gained a fourth case —
// expense — so the "Documents in this period" section is the single
// unified ledger for all four saved-document types. Expenses skip the
// completion bar entirely (no real completion concept), only show a
// status chip when excludeFromReports is true, and the "N items" segment
// becomes an optional "Ref: ..." (referenceLabel) instead.
//
// Rich document cards for ReportsScreen's "Documents in this period"
// section, visually matching the Saved Documents cards (doc_cards.dart /
// doc_card_shared.dart in lib/widgets/saved_documents/) — same logo
// avatar, title + positive-status dot, template/edited-date subtitle,
// secondary date row, created+item-count row, completion progress bar,
// amount, and status chip. Not a literal reuse of those widgets (they're
// `part of` a different library with different long-press semantics) —
// replicated here with Reports' own controls.
//
// Reuses ReportsLayoutMode / ReportsLayoutToggleButton / ReportsIncludeCheckbox
// from reports_item_list.dart so the Documents and Expenses sections share
// one layout-dropdown control and one accounting-toggle control.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../filters/filter_types.dart' show SortOption, sortOptionLabel;
import '../../widgets/saved_documents/card_display_prefs.dart';
import '../../widgets/saved_documents/saved_layout_prefs.dart';
import 'reports_item_list.dart' show ReportsLayoutMode, ReportsIncludeCheckbox;

enum ReportsDocType { invoice, quote, receipt, expense }

const Color _kFilterInvoiceAccent = Color(0xFF1565C0);
const Color _kFilterQuoteAccent = Color(0xFF7B1FA2);
const Color _kFilterReceiptAccent = Color(0xFF2E7D32);
const Color _kFilterExpenseAccent = Color(0xFFE53935);

String _docTypeLabel(ReportsDocType t) {
  switch (t) {
    case ReportsDocType.invoice:
      return 'Invoices';
    case ReportsDocType.quote:
      return 'Quotes';
    case ReportsDocType.receipt:
      return 'Receipts';
    case ReportsDocType.expense:
      return 'Expenses';
  }
}

Color _docTypeAccent(ReportsDocType t) {
  switch (t) {
    case ReportsDocType.invoice:
      return _kFilterInvoiceAccent;
    case ReportsDocType.quote:
      return _kFilterQuoteAccent;
    case ReportsDocType.receipt:
      return _kFilterReceiptAccent;
    case ReportsDocType.expense:
      return _kFilterExpenseAccent;
  }
}

IconData _docTypeIcon(ReportsDocType t) {
  switch (t) {
    case ReportsDocType.invoice:
      return Icons.receipt_long_rounded;
    case ReportsDocType.quote:
      return Icons.request_quote_rounded;
    case ReportsDocType.receipt:
      return Icons.receipt_rounded;
    case ReportsDocType.expense:
      return Icons.payments_rounded;
  }
}

class ReportsDocumentItem {
  final String key;
  final ReportsDocType docType;
  final String title;
  final String templateName;
  final String editedLabel;
  final String secondaryDateLabel;
  final String secondaryDateValue;
  final String createdLabel;
  final int itemCount;
  final int completionPercent;
  final double amount;
  final String statusLabel;
  final Color statusColor;
  final Color accentColor;
  final String? logoPath;
  final String businessName;
  final bool isPositiveStatus;
  final bool excludedFromReports;
  final bool countsTowardReports;
  final DateTime sortDate;
  final String? referenceLabel;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleExclude;

  const ReportsDocumentItem({
    required this.key,
    required this.docType,
    required this.title,
    required this.templateName,
    required this.editedLabel,
    required this.secondaryDateLabel,
    required this.secondaryDateValue,
    required this.createdLabel,
    required this.itemCount,
    required this.completionPercent,
    required this.amount,
    required this.statusLabel,
    required this.statusColor,
    required this.accentColor,
    required this.logoPath,
    required this.businessName,
    required this.isPositiveStatus,
    required this.excludedFromReports,
    required this.countsTowardReports,
    required this.sortDate,
    required this.onTap,
    required this.onToggleExclude,
    this.referenceLabel,
  });

  bool get _showCompletion => docType != ReportsDocType.expense;
}

String _fmtAmount(double v) => v.toStringAsFixed(2);

Widget _positiveDot() => Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(left: 6),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
    );

// Three-tier fallback: logo file -> initials monogram -> generic icon.
// width/height default to `size`; pass them independently (e.g.
// width: 64, height: double.infinity inside an IntrinsicHeight row) to
// have the logo fill the card's full height edge-to-edge.
class _ReportsLogoAvatar extends StatelessWidget {
  final String? logoPath;
  final String businessName;
  final Color accentColor;
  final double size;
  final double? width;
  final double? height;
  final double iconSize;
  final double borderRadius;

  const _ReportsLogoAvatar({
    required this.logoPath,
    required this.businessName,
    required this.accentColor,
    required this.size,
    this.width,
    this.height,
    this.iconSize = 24,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final path = logoPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: w,
            height: h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(w, h),
          ),
        );
      }
    }
    return _fallback(w, h);
  }

  Widget _fallback(double w, double h) {
    final trimmedName = businessName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : null;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(fontSize: iconSize * 0.62, fontWeight: FontWeight.w800, color: accentColor),
            )
          : Icon(Icons.description_rounded, color: accentColor, size: iconSize),
    );
  }
}

// ── Sort dropdown ──────────────────────────────────────────────────────

extension _ReportsSortIconX on SortOption {
  IconData get _icon {
    switch (this) {
      case SortOption.recentFirst:
        return Icons.arrow_downward_rounded;
      case SortOption.oldestFirst:
        return Icons.arrow_upward_rounded;
      case SortOption.alphabetical:
        return Icons.sort_by_alpha_rounded;
      case SortOption.amountHighLow:
        return Icons.trending_down_rounded;
      case SortOption.amountLowHigh:
        return Icons.trending_up_rounded;
    }
  }
}

class _ReportsSortToggleButton extends StatelessWidget {
  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  const _ReportsSortToggleButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<SortOption>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Sort by',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => SortOption.values.map((option) {
        final isSelected = option == selected;
        return PopupMenuItem<SortOption>(
          value: option,
          child: Row(
            children: [
              Icon(option._icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sortOptionLabel(option),
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
            Icon(selected._icon, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Shared-layout mapping ──────────────────────────────────────────────
// Converts the cross-screen SharedDocLayout (persisted via
// SavedLayoutPrefs, also read/written by saved_documents_section.dart on
// Home) into this file's own ReportsLayoutMode. Reports has no
// "Compact Grid" card variant of its own, so that shared value collapses
// to the nearest visual equivalent, Grid, when displayed here — picking
// Compact Grid on Home still shows *something* sensible on Reports rather
// than crashing or silently ignoring the preference.
ReportsLayoutMode _reportsLayoutFromShared(SharedDocLayout s) {
  switch (s) {
    case SharedDocLayout.list:
      return ReportsLayoutMode.list;
    case SharedDocLayout.grid:
    case SharedDocLayout.compactGrid:
      return ReportsLayoutMode.grid;
    case SharedDocLayout.compact:
      return ReportsLayoutMode.compact;
  }
}

SharedDocLayout _sharedFromReportsLayout(ReportsLayoutMode m) {
  switch (m) {
    case ReportsLayoutMode.list:
      return SharedDocLayout.list;
    case ReportsLayoutMode.grid:
      return SharedDocLayout.grid;
    case ReportsLayoutMode.compact:
      return SharedDocLayout.compact;
  }
}

// Same bordered-pill-with-chevron visual as every other layout dropdown in
// the app, driving the SHARED preference directly (via SavedLayoutPrefs)
// instead of local state — picking a layout here updates Home's Saved
// Documents section too, and vice versa.
class _SharedReportsLayoutToggleButton extends StatelessWidget {
  final ReportsLayoutMode selected;
  final ValueChanged<ReportsLayoutMode> onChanged;

  const _SharedReportsLayoutToggleButton({required this.selected, required this.onChanged});

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
        final icon = switch (mode) {
          ReportsLayoutMode.list => Icons.view_agenda_rounded,
          ReportsLayoutMode.grid => Icons.grid_view_rounded,
          ReportsLayoutMode.compact => Icons.view_headline_rounded,
        };
        final label = switch (mode) {
          ReportsLayoutMode.list => 'List',
          ReportsLayoutMode.grid => 'Grid',
          ReportsLayoutMode.compact => 'Compact',
        };
        return PopupMenuItem<ReportsLayoutMode>(
          value: mode,
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
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
            Icon(
              switch (selected) {
                ReportsLayoutMode.list => Icons.view_agenda_rounded,
                ReportsLayoutMode.grid => Icons.grid_view_rounded,
                ReportsLayoutMode.compact => Icons.view_headline_rounded,
              },
              size: 15,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// Plain category-group header — label + count, no colored bar, matching
// Home's "My Invoices" / "My Quotes" / "My Receipts" / "My Expenses"
// section headers exactly, so the two screens read as the same layout
// language rather than two different list styles.
class _ReportsGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _ReportsGroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
        const Spacer(),
        Text('$count document${count == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }
}

// ── Section wrapper ─────────────────────────────────────────────────────
//
// GROUPED PASS (this update): "Documents in this period" no longer renders
// as one flat, filterable list with category chips — it's now split into
// per-type sections (My Invoices / My Quotes / My Receipts / My Expenses),
// each with its own header + count, exactly matching how the Saved
// Documents section groups things on Home. A category with zero items in
// the period is simply omitted, same as Home omits an empty section. Card
// shape (list/grid/compact) is now a single SHARED control at the top —
// driven by SavedLayoutPrefs, the same preference Home's dropdown writes
// to — instead of a separate local toggle, so picking Grid here shows
// Grid on Home too. Sort still applies uniformly within each group.

class ReportsDocumentSection extends StatefulWidget {
  final String title;
  final List<ReportsDocumentItem> items;
  final bool isDark;
  final String emptyLabel;

  const ReportsDocumentSection({
    super.key,
    required this.title,
    required this.items,
    required this.isDark,
    required this.emptyLabel,
  });

  @override
  State<ReportsDocumentSection> createState() => _ReportsDocumentSectionState();
}

class _ReportsDocumentSectionState extends State<ReportsDocumentSection> {
  SortOption _sortOption = SortOption.recentFirst;

  List<ReportsDocumentItem> _sorted(List<ReportsDocumentItem> items) {
    final list = List<ReportsDocumentItem>.from(items);
    switch (_sortOption) {
      case SortOption.recentFirst:
        list.sort((a, b) => b.sortDate.compareTo(a.sortDate));
        break;
      case SortOption.oldestFirst:
        list.sort((a, b) => a.sortDate.compareTo(b.sortDate));
        break;
      case SortOption.alphabetical:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.amountHighLow:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountLowHigh:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layoutPrefs = context.watch<SavedLayoutPrefs>();
    final layoutMode = _reportsLayoutFromShared(layoutPrefs.layout);

    final invoiceItems = _sorted(widget.items.where((i) => i.docType == ReportsDocType.invoice).toList());
    final quoteItems = _sorted(widget.items.where((i) => i.docType == ReportsDocType.quote).toList());
    final receiptItems = _sorted(widget.items.where((i) => i.docType == ReportsDocType.receipt).toList());
    final expenseItems = _sorted(widget.items.where((i) => i.docType == ReportsDocType.expense).toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const Spacer(),
            _ReportsSortToggleButton(selected: _sortOption, onChanged: (v) => setState(() => _sortOption = v)),
            const SizedBox(width: 6),
            _SharedReportsLayoutToggleButton(
              selected: layoutMode,
              onChanged: (m) => context.read<SavedLayoutPrefs>().setLayout(_sharedFromReportsLayout(m)),
            ),
            const SizedBox(width: 8),
            Text('${widget.items.length}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tap the checkbox to include or exclude an item from the totals above.',
          style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 12),
        if (widget.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(widget.emptyLabel, style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.45))),
          )
        else ...[
          if (invoiceItems.isNotEmpty) ...[
            _ReportsGroupHeader(label: 'My Invoices', count: invoiceItems.length),
            const SizedBox(height: 10),
            _buildItems(invoiceItems, layoutMode),
            const SizedBox(height: 20),
          ],
          if (quoteItems.isNotEmpty) ...[
            _ReportsGroupHeader(label: 'My Quotes', count: quoteItems.length),
            const SizedBox(height: 10),
            _buildItems(quoteItems, layoutMode),
            const SizedBox(height: 20),
          ],
          if (receiptItems.isNotEmpty) ...[
            _ReportsGroupHeader(label: 'My Receipts', count: receiptItems.length),
            const SizedBox(height: 10),
            _buildItems(receiptItems, layoutMode),
            if (expenseItems.isNotEmpty) const SizedBox(height: 20),
          ],
          if (expenseItems.isNotEmpty) ...[
            _ReportsGroupHeader(label: 'My Expenses', count: expenseItems.length),
            const SizedBox(height: 10),
            _buildItems(expenseItems, layoutMode),
          ],
        ],
      ],
    );
  }

  Widget _buildItems(List<ReportsDocumentItem> items, ReportsLayoutMode layoutMode) {
    switch (layoutMode) {
      case ReportsLayoutMode.list:
        return Column(children: items.map((e) => _ReportsDocCard(item: e, isDark: widget.isDark)).toList());
      case ReportsLayoutMode.compact:
        return Column(children: items.map((e) => _ReportsDocCompactRow(item: e, isDark: widget.isDark)).toList());
      case ReportsLayoutMode.grid:
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 190,
          ),
          children: items.map((e) => _ReportsDocGridCard(item: e, isDark: widget.isDark)).toList(),
        );
    }
  }
}
// ── List card — mirrors _DocCard in doc_cards.dart ──────────────────────

class _ReportsDocCard extends StatelessWidget {
  final ReportsDocumentItem item;
  final bool isDark;
  const _ReportsDocCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = context.watch<CardDisplayPrefs>();
    final isExpense = item.docType == ReportsDocType.expense;
    final trailingLabel = isExpense
        ? item.referenceLabel
        : '${item.itemCount} item${item.itemCount == 1 ? '' : 's'}';
    final trailingIcon = isExpense ? Icons.confirmation_number_outlined : Icons.receipt_long_rounded;

    return GestureDetector(
      onTap: item.onTap,
      child: Opacity(
        opacity: item.countsTowardReports ? 1.0 : 0.55,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (prefs.showLogo) ...[
                _ReportsLogoAvatar(
                  logoPath: item.logoPath,
                  businessName: item.businessName,
                  accentColor: item.accentColor,
                  size: 72,
                  width: 72,
                  height: 96,
                  iconSize: 30,
                  borderRadius: 14,
                ),
                const SizedBox(width: 14),
              ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(item.title,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (item.isPositiveStatus) _positiveDot(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text(item.templateName,
                              style: TextStyle(fontSize: 12, color: item.accentColor, fontWeight: FontWeight.w600),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('· Edited ${item.editedLabel}',
                                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        if (prefs.showSecondaryDate) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.event_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.35)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('${item.secondaryDateLabel}: ${item.secondaryDateValue}',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ],
                        if (prefs.showCreatedAndItems) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.add_circle_outline_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text('Created ${item.createdLabel}',
                                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (trailingLabel != null && trailingLabel.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Icon(trailingIcon, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(trailingLabel,
                                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ]),
                        ],
                        if (prefs.showProgress && item._showCompletion) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.completionPercent / 100,
                              backgroundColor: cs.outline.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(item.accentColor),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (prefs.showAmount)
                      Text(_fmtAmount(item.amount), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: cs.onSurface)),
                    if (prefs.showStatusChip && item.statusLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: item.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(item.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.statusColor)),
                      ),
                    ],
                    const SizedBox(height: 6),
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

// ── Grid card — mirrors _DocGridCard in doc_cards.dart ──────────────────

class _ReportsDocGridCard extends StatelessWidget {
  final ReportsDocumentItem item;
  final bool isDark;
  const _ReportsDocGridCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = context.watch<CardDisplayPrefs>();
    return GestureDetector(
      onTap: item.onTap,
      child: Opacity(
        opacity: item.countsTowardReports ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (prefs.showLogo)
                    _ReportsLogoAvatar(
                      logoPath: item.logoPath,
                      businessName: item.businessName,
                      accentColor: item.accentColor,
                      size: 32,
                      iconSize: 16,
                      borderRadius: 9,
                    ),
                  const Spacer(),
                  Icon(_docTypeIcon(item.docType), size: 13, color: item.accentColor),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(item.title,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  if (item.isPositiveStatus) _positiveDot(),
                ],
              ),
              const SizedBox(height: 2),
              Text(item.templateName,
                  style: TextStyle(fontSize: 9.5, color: item.accentColor, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (prefs.showSecondaryDate) ...[
                const SizedBox(height: 2),
                Text('${item.secondaryDateLabel}: ${item.secondaryDateValue}',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const Spacer(),
              Row(
                children: [
                  if (prefs.showStatusChip && item.statusLabel.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: item.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(item.statusLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: item.statusColor),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  const Spacer(),
                  if (prefs.showAmount)
                    Flexible(
                      child: Text(_fmtAmount(item.amount),
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: ReportsIncludeCheckbox(
                  included: !item.excludedFromReports,
                  countsTowardReports: item.countsTowardReports,
                  itemTitle: item.title,
                  onToggleExclude: item.onToggleExclude,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact row — mirrors _DocCompactRow in doc_cards.dart ──────────────

class _ReportsDocCompactRow extends StatelessWidget {
  final ReportsDocumentItem item;
  final bool isDark;
  const _ReportsDocCompactRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = context.watch<CardDisplayPrefs>();
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
              if (prefs.showLogo) ...[
                _ReportsLogoAvatar(
                  logoPath: item.logoPath,
                  businessName: item.businessName,
                  accentColor: item.accentColor,
                  size: 28,
                  iconSize: 15,
                  borderRadius: 8,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(item.title,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (item.isPositiveStatus) _positiveDot(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prefs.showAmount)
                    Text(_fmtAmount(item.amount),
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (prefs.showSecondaryDate)
                    Text('${item.secondaryDateLabel} ${item.secondaryDateValue}',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
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
