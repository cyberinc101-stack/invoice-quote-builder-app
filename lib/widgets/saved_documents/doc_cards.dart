// doc_cards.dart
// lib/widgets/saved_documents/doc_cards.dart
//
// Part of saved_documents_section.dart — the four standard (non-kanban)
// card layouts: list, grid, compact grid, and compact row. Each supports
// selection mode (long-press to enter, tap to toggle) and the 3-dot
// options menu when not in selection mode.
//
// DISPLAY OPTIONS PASS (this update): every layout now watches
// CardDisplayPrefs (card_display_prefs.dart) and conditionally renders:
// logo, amount, secondary date row, created-date+item-count row,
// progress bar, and status chip — each gated behind its own switch so a
// user can hide whichever fields they don't want cluttering the card.
// Flipping a switch in DisplayOptionsButton's sheet updates every visible
// card immediately since they all watch the same provider instance.
//
// LOGO FIX (this update): the List layout (_DocCard) now wraps its Row in
// IntrinsicHeight + CrossAxisAlignment.stretch and passes
// height: double.infinity to _DocLogoAvatar, so the logo image fills the
// card's full height edge-to-edge (BoxFit.cover) instead of sitting in a
// small fixed square. Grid/compactGrid/compact stay square — there isn't
// enough room at those sizes for a stretched rectangle to look right.
//
// Everything else (selection mode, 3-dot menu, secondary date labels,
// created date, item count, total amount) is unchanged in behaviour from
// the previous pass — only which of those fields actually render is new.

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
    final prefs  = context.watch<CardDisplayPrefs>();

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: prefs.showLogo
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.start,
                children: [
                  if (prefs.showLogo) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _DocLogoAvatar(
                        logoPath: entry.logoPath,
                        businessName: entry.businessName,
                        accentColor: entry.accentColor,
                        size: 64,
                        width: 64,
                        height: double.infinity,
                        iconSize: 26,
                        borderRadius: 12,
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
                          if (prefs.showSecondaryDate) ...[
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
                          ],
                          if (prefs.showCreatedAndItems) ...[
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(Icons.add_circle_outline_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                              const SizedBox(width: 4),
                              Text('Created ${entry.createdLabel}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface.withValues(alpha: 0.45))),
                              const SizedBox(width: 10),
                              Icon(Icons.receipt_long_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                              const SizedBox(width: 4),
                              Text('${entry.itemCount} item${entry.itemCount == 1 ? '' : 's'}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface.withValues(alpha: 0.45))),
                            ]),
                          ],
                          if (prefs.showProgress) ...[
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
                        Text(
                          _formatCardAmount(entry.totalAmount),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      if (prefs.showAmount && prefs.showStatusChip) const SizedBox(height: 6),
                      if (prefs.showStatusChip)
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
    final prefs  = context.watch<CardDisplayPrefs>();

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
      child: Container(
        padding: const EdgeInsets.all(10),
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
                if (prefs.showLogo) ...[
                  _DocLogoAvatar(
                    logoPath: entry.logoPath,
                    businessName: entry.businessName,
                    accentColor: entry.accentColor,
                    size: 40,
                    iconSize: 18,
                    borderRadius: 10,
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isPositiveStatus) _positiveDot(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: TextStyle(fontSize: 9.5, color: entry.accentColor, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (prefs.showSecondaryDate) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${entry.secondaryDateLabel}: ${entry.secondaryDateValue}',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Edited ${entry.date}',
                  style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.35)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (prefs.showCreatedAndItems) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Created ${entry.createdLabel} · ${entry.itemCount} item${entry.itemCount == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.35)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (prefs.showStatusChip)
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
                    const Spacer(),
                    if (prefs.showAmount)
                      Flexible(
                        child: Text(
                          _formatCardAmount(entry.totalAmount),
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
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
//
// Only the total amount is added beyond the base title/status — at
// ~80-90dp wide there's no room for more without forcing overflow.
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
    final prefs  = context.watch<CardDisplayPrefs>();

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
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
                  _DocLogoAvatar(
                    logoPath: entry.logoPath,
                    businessName: entry.businessName,
                    accentColor: entry.accentColor,
                    size: 26,
                    iconSize: 13,
                    borderRadius: 8,
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isPositiveStatus) _positiveDot(),
                  ],
                ),
                if (prefs.showSecondaryDate) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${entry.secondaryDateLabel}: ${entry.secondaryDateValue}',
                    style: TextStyle(fontSize: 8.5, color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (prefs.showAmount) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatCardAmount(entry.totalAmount),
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                if (prefs.showStatusChip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: entry.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.statusLabel,
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: entry.accentColor),
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
    final prefs  = context.watch<CardDisplayPrefs>();

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
                if (prefs.showLogo) ...[
                  _DocLogoAvatar(
                    logoPath: entry.logoPath,
                    businessName: entry.businessName,
                    accentColor: entry.accentColor,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefs.showAmount)
                      Text(
                        _formatCardAmount(entry.totalAmount),
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (prefs.showSecondaryDate)
                      Text(
                        '${entry.secondaryDateLabel} ${entry.secondaryDateValue}',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                if (prefs.showStatusChip) ...[
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
                ],
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
