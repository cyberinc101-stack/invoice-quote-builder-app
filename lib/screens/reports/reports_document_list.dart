// reports_document_list.dart
// lib/screens/reports/reports_document_list.dart
//
// EXPENSES-MERGED PASS (this update): ReportsDocType gained a fourth case
// — expense — so the "Documents in this period" section is now the single
// unified ledger for all four saved-document types, matching how real
// bookkeeping tools (and Home's own DocTypeFilter) treat "type" as a
// filter on one list rather than four separate silos. The old, plainer
// "Expenses in this period" section (reports_item_list.dart's
// ReportsListItem/ReportsItemSection) is retired from reports_screen.dart
// in this same pass — expenses now render with these exact same rich
// cards, just adapted where an expense genuinely has no equivalent:
//   - No completion percent -> the progress bar is skipped entirely for
//     expense items (an "always 100%" bar conveys nothing real).
//   - No payment/quote/receipt-style status -> the status chip only shows
//     for expenses when excludeFromReports is true ("Excluded"); a
//     non-excluded expense shows no chip, since the include/exclude
//     checkbox already communicates that state.
//   - No line items -> the "N items" segment is replaced by an optional
//     `referenceLabel` ("Ref: 12345") when the expense has a manually-
//     entered reference number, or omitted entirely when it doesn't.
//   - `templateName` carries the expense's category name instead (still
//     rendered in the accent color, same visual slot).
//   - `secondaryDateLabel`/`secondaryDateValue` become "Date" / the
//     expense's date, replacing Due/Expires/Paid.
// All of this is driven by `item.docType == ReportsDocType.expense` checks
// inside the three card widgets below — no new widget types, so list,
// grid, and compact layouts all support expenses automatically.
//
// ── Everything below this point (except the docType/referenceLabel
// additions and the conditional rendering noted above) is unchanged from
// the previous pass — see original header comments preserved below. ──
//
// THIS PASS (earlier):
//  - FIX: the "Created X · N items" and template/edited-date rows had no
//    Flexible/ellipsis wrapping and overflowed once the text got long
//    enough (RenderFlex overflow banner on real data). Every row that
//    combines a fixed icon + variable-length text is now wrapped so it
//    truncates with an ellipsis instead of overflowing.
//  - The hidden long-press toggle is gone. Every card now shows the same
//    visible ReportsIncludeCheckbox used by reports_item_list.dart's
//    expense cards (imported from there — one control, one behavior,
//    both card families).
//  - ReportsDocumentItem grew `docType` (ReportsDocType) and `sortDate` so
//    ReportsDocumentSection can offer the same category filter chips
//    (All/Invoices/Quotes/Receipts, with counts) and sort dropdown (Most
//    Recent/Oldest First/Alphabetical/Amount High-Low/Low-High) that Home's
//    "My Invoices"-style lists already have (SortOption, reused directly
//    from lib/filters/filter_types.dart — same enum Home's own sort
//    dropdown drives, so "Most Recent" means the same thing in both
//    places). ReportsDocumentSection is now a StatefulWidget holding its
//    own filter/sort selection, mirroring how
//    SavedDocumentsContainers/_SavedDocumentsContainersState owns that
//    same state on the home screen — it's a "how do I want to browse this
//    list" concern, independent of the accounting include/exclude
//    checkbox and independent of the Invoices/Quotes/Receipts
//    DataSourceToggleRow above it (that one controls what counts toward
//    Income; this one only controls what's currently visible here).
//
// Rich document cards for ReportsScreen's "Documents in this period"
// section, visually matching the Saved Documents cards (doc_cards.dart /
// doc_card_shared.dart in lib/widgets/saved_documents/) — same logo
// avatar, title + positive-status dot, template/edited-date subtitle,
// secondary date row, created+item-count row, completion progress bar,
// amount, and status chip.
//
// Not a literal reuse of those widgets: they're `part of
// 'saved_documents_section.dart'` (private to that library) and their
// long-press already means "enter multi-select," which conflicts with
// what Reports needs. Replicating the visual language here, with Reports'
// own controls, gets an identical look without fighting that library
// boundary or changing what long-press does on the Saved Documents screen
// itself.
//
// Grid/compact layouts intentionally skip a couple of the list layout's
// detail rows (created date, item count) — same reasoning doc_cards.dart
// gives for doing the same at those sizes: not enough room without
// forcing overflow or unreadable text.
//
// Reuses ReportsLayoutMode / ReportsLayoutToggleButton / ReportsIncludeCheckbox
// from reports_item_list.dart so the Documents and Expenses sections share
// one layout-dropdown control and one accounting-toggle control, even
// though their cards look different.

import 'dart:io';
import 'package:flutter/material.dart';

import '../../filters/filter_types.dart' show SortOption, sortOptionLabel;
import 'reports_item_list.dart'
    show ReportsLayoutMode, ReportsLayoutToggleButton, ReportsIncludeCheckbox;

enum ReportsDocType { invoice, quote, receipt, expense }

// Local copies of the accent colors reports_screen.dart uses for
// _kDocsInvoiceAccent/_kDocsQuoteAccent/_kDocsReceiptAccent, plus the
// Expenses screen's own accent (kExpenseAccent in expense_card_shared.
// dart) — needed here so the filter chips have a color to show even for a
// category with zero items in the current period (where no
// ReportsDocumentItem exists to borrow a color from). Keep these in sync
// with reports_screen.dart / expense_card_shared.dart if those ever
// change.
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
  final String editedLabel; // e.g. "8 Aug 2026" — rendered as "· Edited 8 Aug 2026"
  final String secondaryDateLabel; // "Due" / "Expires" / "Paid" / "Date"
  final String secondaryDateValue;
  final String createdLabel;
  final int itemCount;
  final int completionPercent;
  final double amount;
  final String statusLabel; // empty string = no status chip rendered
  final Color statusColor;
  final Color accentColor;
  final String? logoPath;
  final String businessName;
  final bool isPositiveStatus;
  final bool excludedFromReports; // manual flag — checkbox flips this
  final bool countsTowardReports; // actual current reportable state (drives badge/dim)
  final DateTime sortDate; // last-edited date — powers Most Recent/Oldest First
  // Expense-only: replaces the "N items" segment with e.g. "Ref: 12345"
  // when set. Null/omitted for invoices/quotes/receipts, and for
  // expenses with no reference number entered.
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

  // Expenses have no completion concept — an "always 100%" bar would be
  // pure decoration, so it's skipped entirely rather than shown as a
  // meaningless full bar.
  bool get _showCompletion => docType != ReportsDocType.expense;
}

String _fmtAmount(double v) => v.toStringAsFixed(2);

Widget _positiveDot() => Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(left: 6),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
    );

// Same three-tier fallback as _DocLogoAvatar in doc_card_shared.dart:
// logo file -> initials monogram -> generic icon.
class _ReportsLogoAvatar extends StatelessWidget {
  final String? logoPath;
  final String businessName;
  final Color accentColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  const _ReportsLogoAvatar({
    required this.logoPath,
    required this.businessName,
    required this.accentColor,
    required this.size,
    this.iconSize = 24,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final path = logoPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          ),
        );
      }
    }
    return _fallback();
  }

  Widget _fallback() {
    final trimmedName = businessName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : null;
    return Container(
      width: size,
      height: size,
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

// ── Sort dropdown — same visual as ReportsLayoutToggleButton, reusing the
// SortOption enum Home's own dropdown already drives (filter_types.dart)
// so "Most Recent" etc. mean exactly the same thing in both places. ──────

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

// ── Category filter chips — same "All · N / Invoices · N / ..." bar as
// Home's unified document view, now including Expenses as a fourth chip. ─

class _ReportsDocFilterBar extends StatelessWidget {
  final ReportsDocType? selected; // null = All
  final ValueChanged<ReportsDocType?> onChanged;
  final Map<ReportsDocType, int> counts;

  const _ReportsDocFilterBar({required this.selected, required this.onChanged, required this.counts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = counts.values.fold<int>(0, (s, v) => s + v);

    Widget chip({required bool isSelected, required String label, required int count, required Color color, required VoidCallback onTap}) {
      final chipBg = isSelected ? color : (isDark ? cs.surfaceContainerHighest : const Color(0xFFF5F5F5));
      final textColor = isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.55);
      final badgeBg = isSelected ? Colors.white.withValues(alpha: 0.2) : cs.onSurface.withValues(alpha: 0.1);
      final badgeText = isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.45);
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: textColor)),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeText)),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(isSelected: selected == null, label: 'All', count: total, color: cs.primary, onTap: () => onChanged(null)),
          const SizedBox(width: 8),
          for (final t in ReportsDocType.values) ...[
            chip(
              isSelected: selected == t,
              label: _docTypeLabel(t),
              count: counts[t] ?? 0,
              color: _docTypeAccent(t),
              onTap: () => onChanged(t),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ── Section wrapper — header (title + sort + layout + count), filter
// chips, then cards. Owns its own filter/sort selection (StatefulWidget),
// same as Home's SavedDocumentsContainers owns its filter state. ─────────

class ReportsDocumentSection extends StatefulWidget {
  final String title;
  final List<ReportsDocumentItem> items;
  final ReportsLayoutMode layoutMode;
  final ValueChanged<ReportsLayoutMode> onLayoutChanged;
  final bool isDark;
  final String emptyLabel;

  const ReportsDocumentSection({
    super.key,
    required this.title,
    required this.items,
    required this.layoutMode,
    required this.onLayoutChanged,
    required this.isDark,
    required this.emptyLabel,
  });

  @override
  State<ReportsDocumentSection> createState() => _ReportsDocumentSectionState();
}

class _ReportsDocumentSectionState extends State<ReportsDocumentSection> {
  ReportsDocType? _selectedFilter; // null = All
  SortOption _sortOption = SortOption.recentFirst;

  List<ReportsDocumentItem> _filtered() {
    if (_selectedFilter == null) return widget.items;
    return widget.items.where((i) => i.docType == _selectedFilter).toList();
  }

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

    final counts = <ReportsDocType, int>{
      for (final t in ReportsDocType.values) t: widget.items.where((i) => i.docType == t).length,
    };

    final visible = _sorted(_filtered());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const Spacer(),
            _ReportsSortToggleButton(selected: _sortOption, onChanged: (v) => setState(() => _sortOption = v)),
            const SizedBox(width: 6),
            ReportsLayoutToggleButton(selected: widget.layoutMode, onChanged: widget.onLayoutChanged),
            const SizedBox(width: 8),
            Text('${visible.length}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 10),
        _ReportsDocFilterBar(selected: _selectedFilter, onChanged: (v) => setState(() => _selectedFilter = v), counts: counts),
        const SizedBox(height: 8),
        Text(
          'Tap the checkbox to include or exclude it from the totals above.',
          style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(widget.emptyLabel, style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.45))),
          )
        else
          _buildItems(visible),
      ],
    );
  }

  Widget _buildItems(List<ReportsDocumentItem> items) {
    switch (widget.layoutMode) {
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
    final isExpense = item.docType == ReportsDocType.expense;
    // Expense-only: "N items" becomes "Ref: 12345" when set, or the whole
    // trailing segment (icon + separator + text) is simply omitted.
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
          padding: const EdgeInsets.all(16),
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
              _ReportsLogoAvatar(
                logoPath: item.logoPath,
                businessName: item.businessName,
                accentColor: item.accentColor,
                size: 48,
                iconSize: 24,
                borderRadius: 12,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (item._showCompletion) ...[
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
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtAmount(item.amount), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  if (item.statusLabel.isNotEmpty) ...[
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
              const SizedBox(height: 2),
              Text('${item.secondaryDateLabel}: ${item.secondaryDateValue}',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                children: [
                  if (item.statusLabel.isNotEmpty)
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
              _ReportsLogoAvatar(
                logoPath: item.logoPath,
                businessName: item.businessName,
                accentColor: item.accentColor,
                size: 28,
                iconSize: 15,
                borderRadius: 8,
              ),
              const SizedBox(width: 10),
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
                  Text(_fmtAmount(item.amount),
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
