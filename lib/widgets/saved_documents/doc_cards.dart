// doc_cards.dart
// lib/widgets/saved_documents/doc_cards.dart
//
// Part of saved_documents_section.dart — the four standard (non-kanban)
// card layouts: list, grid, compact grid, and compact row. Each supports
// selection mode (long-press to enter, tap to toggle) and the 3-dot
// options menu when not in selection mode.
//
// FIX (this pass): every layout now surfaces entry.secondaryDateLabel /
// entry.secondaryDateValue (Due/Paid for invoices, Expires for quotes, Paid
// for receipts) alongside the existing last-edited `entry.date` — previously
// only last-edited was shown anywhere in these cards, and _DocCompactGridCard
// showed no date at all.

part of 'saved_documents_section.dart';

// -----------------------------------------------------------------------------
// _DocCard — LIST layout
// -----------------------------------------------------------------------------

class _DocCard extends StatelessWidget {
  final _DocEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const _DocCard({
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: entry.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description_rounded, color: entry.accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(entry.title,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (entry.isPositiveStatus) _positiveDot(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text(entry.subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: entry.accentColor,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Text('· Edited ${entry.date}',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.event_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Text('${entry.secondaryDateLabel}: ${entry.secondaryDateValue}',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.55))),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.percent / 100,
                          backgroundColor: cs.outline.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(entry.accentColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: entry.accentColor,
                        ),
                      ),
                    ),
                    if (!selectionMode) ...[
                      const SizedBox(height: 6),
                      _ThreeDotIcon(onTap: entry.onShowMenu),
                    ],
                  ],
                ),
              ],
            ),
            if (selectionMode)
              Positioned(
                top: -4,
                right: -4,
                child: _SelectionBadge(selected: selected, accent: cs.primary),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _DocGridCard — GRID layout
// -----------------------------------------------------------------------------

class _DocGridCard extends StatelessWidget {
  final _DocEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const _DocGridCard({
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: entry.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_rounded, color: entry.accentColor, size: 18),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isPositiveStatus) _positiveDot(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.subtitle,
                  style: TextStyle(fontSize: 10, color: entry.accentColor, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.secondaryDateLabel}: ${entry.secondaryDateValue}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Edited ${entry.date}',
                  style: TextStyle(fontSize: 9.5, color: cs.onSurface.withValues(alpha: 0.35)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: entry.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: entry.accentColor),
                  ),
                ),
              ],
            ),
            if (selectionMode)
              Positioned(
                top: -4,
                right: -4,
                child: _SelectionBadge(selected: selected, accent: cs.primary),
              )
            else
              Positioned(
                top: -4,
                right: -4,
                child: _ThreeDotIcon(onTap: entry.onShowMenu),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _DocCompactGridCard — COMPACT GRID layout
// -----------------------------------------------------------------------------

class _DocCompactGridCard extends StatelessWidget {
  final _DocEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const _DocCompactGridCard({
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
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
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: entry.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.description_rounded, color: entry.accentColor, size: 15),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isPositiveStatus) _positiveDot(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.secondaryDateLabel}: ${entry.secondaryDateValue}',
                  style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.statusLabel,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: entry.accentColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (selectionMode)
              Positioned(
                top: -4,
                right: -4,
                child: _SelectionBadge(selected: selected, accent: cs.primary),
              )
            else
              Positioned(
                top: -4,
                right: -4,
                child: _ThreeDotIcon(onTap: entry.onShowMenu),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _DocCompactRow — COMPACT layout
// -----------------------------------------------------------------------------

class _DocCompactRow extends StatelessWidget {
  final _DocEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const _DocCompactRow({
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      borderRadius: BorderRadius.circular(10),
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
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: entry.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description_rounded, color: entry.accentColor, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.title,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isPositiveStatus) _positiveDot(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.secondaryDateLabel} ${entry.secondaryDateValue}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: entry.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: entry.accentColor),
                  ),
                ),
                if (!selectionMode) ...[
                  const SizedBox(width: 6),
                  _ThreeDotIcon(onTap: entry.onShowMenu),
                ],
              ],
            ),
            if (selectionMode)
              Positioned(
                top: -6,
                right: -2,
                child: _SelectionBadge(selected: selected, accent: cs.primary),
              ),
          ],
        ),
      ),
    );
  }
}