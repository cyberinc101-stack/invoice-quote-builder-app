// expense_cards.dart
// lib/widgets/expenses/expense_cards.dart
//
// LOGO BANNER PASS (this update): ExpenseListCard now dispatches between
// the original side-by-side Standard layout and a new
// _LogoBannerExpenseCard (full-width top image band, mirroring
// doc_cards.dart's _LogoBannerDocCard) based on
// CardDisplayPrefs.cardStyle — exactly the same dispatch _DocCard already
// does in doc_cards.dart. Previously ExpenseListCard had ONLY the
// Standard layout, so selecting Logo Banner switched invoices/quotes/
// receipts to the full-width-image style while expenses stayed in the
// old side-by-side layout — that mismatch is what made expense cards
// visibly not match the rest of the saved-document family whenever Logo
// Banner was active. Grid/CompactGrid/Compact are unaffected, same as
// doc cards (no room for a banner at those sizes).
//
// OVERFLOW FIX (this update): the amount text in every layout's
// right-side column is now wrapped so a very large number (or a long
// currency code) can't push the card past its bounds — `Flexible` +
// `overflow: TextOverflow.ellipsis` + `maxLines: 1` on every amount
// Text, matching the safety already present on the title/category/date
// text elsewhere. This is what caused the "RIGHT OVERFLOWED BY N PIXELS"
// error banner with sufficiently large test amounts.
//
// UI-PARITY PASS (earlier): every layout's container styling (corner
// radius, shadow recipe, border color/width) matches the equivalent tier
// in doc_cards.dart exactly.
//
// Everything else — selection mode, the 3-dot menu, folder tags, the
// logo/photo system (ExpenseGradientAvatar's pan/zoom photo handling is
// intentionally different from a business logo and untouched), which
// fields render per CardDisplayPrefs — is unchanged in behaviour from the
// previous pass.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../saved_documents/card_display_prefs.dart';
import 'expense_card_shared.dart';

// -----------------------------------------------------------------------------
// ExpenseListCard — LIST layout (dispatches to standard or logo-banner style)
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
    final prefs = context.watch<CardDisplayPrefs>();

    if (prefs.cardStyle == CardStyle.logoBanner && prefs.showLogo) {
      return _LogoBannerExpenseCard(
        entry: entry,
        selectionMode: selectionMode,
        selected: selected,
        onToggleSelect: onToggleSelect,
        onEnterSelection: onEnterSelection,
      );
    }

    return _StandardExpenseCard(
      entry: entry,
      selectionMode: selectionMode,
      selected: selected,
      onToggleSelect: onToggleSelect,
      onEnterSelection: onEnterSelection,
    );
  }
}

// -----------------------------------------------------------------------------
// _StandardExpenseCard — the original side-by-side logo + text List layout.
// -----------------------------------------------------------------------------

class _StandardExpenseCard extends StatelessWidget {
  final ExpenseCardEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const _StandardExpenseCard({
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

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Opacity(
        opacity: entry.excluded ? 0.65 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.14),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.1 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prefs.showLogo) ...[
                    ExpenseGradientAvatar(
                      logoPath: entry.logoPath,
                      logoOffset: entry.logoOffset,
                      logoScale: entry.logoScale,
                      logoShape: entry.logoShape,
                      category: entry.category,
                      size: 68,
                      iconSize: 28,
                      borderRadius: 15,
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
                              Flexible(
                                child: Text(entry.category.name,
                                    style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time_rounded, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text('Edited ${entry.editedLabel}',
                                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.35)),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          if (prefs.showSecondaryDate) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.event_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.35)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text('Date: ${entry.dateLabel}',
                                      style: TextStyle(
                                          fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                          if (prefs.showCreatedAndItems &&
                              entry.folderName != null &&
                              entry.folderName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
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
                            const SizedBox(height: 4),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (prefs.showAmount)
                          Text(
                            entry.amountLabel,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        if (prefs.showAmount && entry.excluded && prefs.showStatusChip) const SizedBox(height: 6),
                        if (entry.excluded && prefs.showStatusChip) excludedChip(),
                        if (!selectionMode) ...[
                          const SizedBox(height: 6),
                          ExpenseThreeDotIcon(onTap: entry.onShowMenu),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (selectionMode)
                Positioned(top: -4, right: -4, child: ExpenseSelectionBadge(selected: selected, accent: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _LogoBannerExpenseCard — List layout variant used when
// CardDisplayPrefs.cardStyle == CardStyle.logoBanner. Mirrors
// doc_cards.dart's _LogoBannerDocCard: full-width ExpenseLogoBanner on
// top, stat block underneath, Excluded chip + 3-dot overlaid on the
// banner itself.
// -----------------------------------------------------------------------------

class _LogoBannerExpenseCard extends StatelessWidget {
  final ExpenseCardEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const _LogoBannerExpenseCard({
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
    const double cardRadius = 18;

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Opacity(
        opacity: entry.excluded ? 0.65 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.14),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      ExpenseLogoBanner(
                        logoPath: entry.logoPath,
                        logoOffset: entry.logoOffset,
                        logoScale: entry.logoScale,
                        logoShape: entry.logoShape,
                        category: entry.category,
                        height: 110,
                        topRadius: cardRadius,
                      ),
                      if (entry.excluded && prefs.showStatusChip)
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off_rounded, size: 10, color: kExpenseAccent),
                                SizedBox(width: 4),
                                Text('Excluded',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kExpenseAccent)),
                              ],
                            ),
                          ),
                        ),
                      if (!selectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: ExpenseThreeDotIcon(
                            onTap: entry.onShowMenu,
                            background: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.82),
                            iconColor: cs.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(entry.title,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (prefs.showAmount) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  entry.amountLabel,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.label_rounded, size: 12, color: accent),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(entry.category.name,
                                  style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text('· Edited ${entry.editedLabel}',
                                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        if (prefs.showSecondaryDate) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.event_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.35)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('Date: ${entry.dateLabel}',
                                    style: TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                        if (prefs.showCreatedAndItems &&
                            entry.folderName != null &&
                            entry.folderName!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 4),
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
                      ],
                    ),
                  ),
                ],
              ),
              if (selectionMode)
                Positioned(top: -4, right: -4, child: ExpenseSelectionBadge(selected: selected, accent: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ExpenseGridCard — GRID layout (unaffected by Card Style — square, tight
// on space, same as doc cards)
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

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Opacity(
        opacity: entry.excluded ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                      size: 40,
                      iconSize: 18,
                      borderRadius: 10,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(entry.title,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(entry.category.name,
                      style: TextStyle(fontSize: 9.5, color: accent, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (prefs.showSecondaryDate) ...[
                    const SizedBox(height: 2),
                    Text('Date: ${entry.dateLabel}',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 2),
                  Text('Edited ${entry.editedLabel}',
                      style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.35)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (entry.excluded && prefs.showStatusChip) excludedChipCompact() else const SizedBox.shrink(),
                      const Spacer(),
                      if (prefs.showAmount)
                        Flexible(
                          child: Text(entry.amountLabel,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: cs.onSurface),
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

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Opacity(
        opacity: entry.excluded ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
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
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15),
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
                      size: 28,
                      iconSize: 15,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(entry.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prefs.showAmount)
                          Text(entry.amountLabel,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                        if (prefs.showSecondaryDate)
                          Text(entry.dateLabel,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                      ],
                    ),
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