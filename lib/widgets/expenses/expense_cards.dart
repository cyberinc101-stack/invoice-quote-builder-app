// expense_cards.dart
// lib/widgets/expenses/expense_cards.dart
//
// DISPLAY OPTIONS PASS (this update): all four layouts now watch
// CardDisplayPrefs (lib/widgets/saved_documents/card_display_prefs.dart —
// the same instance the Saved Documents and Reports cards read from) and
// conditionally render: logo, amount, date row, and the "Excluded" chip
// slot follows the status-chip toggle. This is the same provider Home's
// Invoices/Quotes/Receipts sections use, so one set of switches controls
// every card family in the app.
//
// LOGO FIX (this update): ExpenseListCard now wraps its Row in
// IntrinsicHeight + CrossAxisAlignment.stretch and passes
// height: double.infinity to ExpenseGradientAvatar, so the logo/photo
// fills the card's full height edge-to-edge instead of a small square.
// Grid/compactGrid/compact stay square — not enough room at those sizes.
//
// Selection mode, the 3-dot options menu, folder tags, and the logo/photo
// system are all unchanged in behaviour — only what renders (per prefs)
// and the List avatar's fill behaviour changed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../saved_documents/card_display_prefs.dart';
import 'expense_card_shared.dart';

// -----------------------------------------------------------------------------
// ExpenseListCard — LIST layout
// -----------------------------------------------------------------------------

class ExpenseListCard extends StatelessWidget {
  final ExpenseCardEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const ExpenseListCard({
    super.key,
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = context.watch<CardDisplayPrefs>();
    final accent = entry.category.color;
    final cardColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? accent.withValues(alpha: 0.18) : const Color(0xFFF0F0F0);

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Opacity(
        opacity: entry.excluded ? 0.65 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: isDark ? 0.12 : 0.08), blurRadius: 12, offset: const Offset(0, 4)),
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04), blurRadius: 4, offset: const Offset(0, 1)),
            ],
            border: Border.all(
              color: selected ? cs.primary : borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: prefs.showLogo
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.center,
                    children: [
                      if (prefs.showLogo) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ExpenseGradientAvatar(
                            logoPath: entry.logoPath,
                            logoOffset: entry.logoOffset,
                            logoScale: entry.logoScale,
                            logoShape: entry.logoShape,
                            category: entry.category,
                            size: 64,
                            width: 64,
                            height: double.infinity,
                            iconSize: 26,
                            borderRadius: 14,
                          ),
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
                              Text(entry.title,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.label_rounded, size: 12, color: accent),
                                  const SizedBox(width: 4),
                                  Text(entry.category.name,
                                      style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(width: 8),
                                  Icon(Icons.access_time_rounded, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text('Edited ${entry.editedLabel}',
                                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.35)),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              if (prefs.showSecondaryDate) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.event_rounded, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                                    const SizedBox(width: 3),
                                    Text('Date: ${entry.dateLabel}',
                                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ],
                              if (prefs.showCreatedAndItems &&
                                  entry.folderName != null &&
                                  entry.folderName!.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.folder_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(entry.folderName!,
                                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                              if (prefs.showCreatedAndItems &&
                                  entry.referenceNumber != null &&
                                  entry.referenceNumber!.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.confirmation_number_outlined, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text('Ref: ${entry.referenceNumber}',
                                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                              if (prefs.showAmount) ...[
                                const SizedBox(height: 8),
                                Text(entry.amountLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
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
                          if (entry.excluded && prefs.showStatusChip) excludedChip(),
                          if (entry.excluded && prefs.showStatusChip && !selectionMode) const SizedBox(height: 8),
                          if (!selectionMode) ExpenseThreeDotIcon(onTap: entry.onShowMenu),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (selectionMode)
                Positioned(top: 10, right: 10, child: ExpenseSelectionBadge(selected: selected, accent: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ExpenseGridCard — GRID layout
// -----------------------------------------------------------------------------

class ExpenseGridCard extends StatelessWidget {
  final ExpenseCardEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const ExpenseGridCard({
    super.key,
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = context.watch<CardDisplayPrefs>();
    final accent = entry.category.color;
    final cardColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? accent.withValues(alpha: 0.18) : const Color(0xFFF0F0F0);

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Opacity(
        opacity: entry.excluded ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: isDark ? 0.12 : 0.08), blurRadius: 10, offset: const Offset(0, 3)),
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04), blurRadius: 4, offset: const Offset(0, 1)),
            ],
            border: Border.all(
              color: selected ? cs.primary : borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prefs.showLogo) ...[
                    ExpenseGradientAvatar(
                      logoPath: entry.logoPath,
                      logoOffset: entry.logoOffset,
                      logoScale: entry.logoScale,
                      logoShape: entry.logoShape,
                      category: entry.category,
                      size: 36,
                      iconSize: 18,
                      borderRadius: 11,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(entry.title,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.label_rounded, size: 9, color: accent),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(entry.category.name,
                            style: TextStyle(fontSize: 9.5, color: accent, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (prefs.showSecondaryDate) ...[
                    const SizedBox(height: 3),
                    Text('Date: ${entry.dateLabel}',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (entry.excluded && prefs.showStatusChip) excludedChipCompact() else const SizedBox.shrink(),
                      const Spacer(),
                      if (prefs.showAmount)
                        Flexible(
                          child: Text(entry.amountLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ],
              ),
              if (selectionMode)
                Positioned(top: -4, right: -4, child: ExpenseSelectionBadge(selected: selected, accent: cs.primary))
              else
                Positioned(top: -4, right: -4, child: ExpenseThreeDotIcon(onTap: entry.onShowMenu)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ExpenseCompactGridCard — COMPACT GRID layout (4-across)
// -----------------------------------------------------------------------------

class ExpenseCompactGridCard extends StatelessWidget {
  final ExpenseCardEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const ExpenseCompactGridCard({
    super.key,
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = context.watch<CardDisplayPrefs>();
    final accent = entry.category.color;
    final cardColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? accent.withValues(alpha: 0.16) : const Color(0xFFF0F0F0);

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Opacity(
        opacity: entry.excluded ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: isDark ? 0.1 : 0.06), blurRadius: 6, offset: const Offset(0, 2)),
            ],
            border: Border.all(
              color: selected ? cs.primary : borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prefs.showLogo) ...[
                    ExpenseGradientAvatar(
                      logoPath: entry.logoPath,
                      logoOffset: entry.logoOffset,
                      logoScale: entry.logoScale,
                      logoShape: entry.logoShape,
                      category: entry.category,
                      size: 26,
                      iconSize: 13,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(entry.title,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (prefs.showSecondaryDate) ...[
                    const SizedBox(height: 3),
                    Text('Date: ${entry.dateLabel}',
                        style: TextStyle(fontSize: 8.5, color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (prefs.showAmount) ...[
                    const SizedBox(height: 2),
                    Text(entry.amountLabel,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const Spacer(),
                  if (entry.excluded && prefs.showStatusChip) excludedChipCompact(),
                ],
              ),
              if (selectionMode)
                Positioned(top: -4, right: -4, child: ExpenseSelectionBadge(selected: selected, accent: cs.primary))
              else
                Positioned(top: -4, right: -4, child: ExpenseThreeDotIcon(onTap: entry.onShowMenu)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ExpenseCompactRow — COMPACT layout
// -----------------------------------------------------------------------------

class ExpenseCompactRow extends StatelessWidget {
  final ExpenseCardEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const ExpenseCompactRow({
    super.key,
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = context.watch<CardDisplayPrefs>();
    final accent = entry.category.color;
    final cardColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? accent.withValues(alpha: 0.14) : const Color(0xFFF0F0F0);

    return InkWell(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: entry.excluded ? 0.65 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: isDark ? 0.08 : 0.05), blurRadius: 5, offset: const Offset(0, 1)),
            ],
            border: Border.all(
              color: selected ? cs.primary : borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  if (prefs.showLogo) ...[
                    ExpenseGradientAvatar(
                      logoPath: entry.logoPath,
                      logoOffset: entry.logoOffset,
                      logoScale: entry.logoScale,
                      logoShape: entry.logoShape,
                      category: entry.category,
                      size: 30,
                      iconSize: 15,
                      borderRadius: 9,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(entry.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (prefs.showAmount)
                        Text(entry.amountLabel,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (prefs.showSecondaryDate)
                        Text(entry.dateLabel,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  if (entry.excluded && prefs.showStatusChip) ...[
                    const SizedBox(width: 8),
                    excludedChipCompact(),
                  ],
                  if (!selectionMode) ...[
                    const SizedBox(width: 6),
                    ExpenseThreeDotIcon(onTap: entry.onShowMenu),
                  ],
                ],
              ),
              if (selectionMode)
                Positioned(top: -6, right: -2, child: ExpenseSelectionBadge(selected: selected, accent: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
