// doc_cards.dart
// lib/widgets/saved_documents/doc_cards.dart
//
// Part of saved_documents_section.dart — the four standard (non-kanban)
// card layouts: list, grid, compact grid, and compact row. Each supports
// selection mode (long-press to enter, tap to toggle) and the 3-dot
// options menu when not in selection mode.
//
// DECISION BADGE PASS (this update): every layout now renders
// _decisionBadge(entry.statusLabel) next to the title. It's a no-op for
// every status except exactly 'Accepted'/'Declined' (see doc_card_shared.
// dart), so this shows up automatically on quote cards only, with zero
// special-casing for document type needed at the call site.
//
// Everything else (CardStyle dispatch for List, selection mode, 3-dot
// menu, secondary date labels, created date, item count, total amount,
// which fields render per CardDisplayPrefs, logo rendering with no
// background per doc_card_shared.dart) is unchanged in behaviour from the
// previous pass.

part of 'saved_documents_section.dart';

// -----------------------------------------------------------------------------
// _DocCard — LIST layout (dispatches to standard or logo-banner style)
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
    final prefs = context.watch<CardDisplayPrefs>();

    if (prefs.cardStyle == CardStyle.logoBanner && prefs.showLogo) {
      return _LogoBannerDocCard(
        entry: entry,
        selectionMode: selectionMode,
        selected: selected,
        onToggleSelect: onToggleSelect,
        onEnterSelection: onEnterSelection,
      );
    }

    return _StandardDocCard(
      entry: entry,
      selectionMode: selectionMode,
      selected: selected,
      onToggleSelect: onToggleSelect,
      onEnterSelection: onEnterSelection,
    );
  }
}

// -----------------------------------------------------------------------------
// _StandardDocCard — the original side-by-side logo + text List layout.
// -----------------------------------------------------------------------------

class _StandardDocCard extends StatelessWidget {
  final _DocEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const _StandardDocCard({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.14),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: entry.accentColor.withValues(alpha: isDark ? 0.1 : 0.06),
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
                  _DocLogoAvatar(
                    logoPath: entry.logoPath,
                    businessName: entry.businessName,
                    accentColor: entry.accentColor,
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
                          const SizedBox(height: 3),
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
                          if (entry.statusLabel == 'Accepted' || entry.statusLabel == 'Declined') ...[
                            const SizedBox(height: 6),
                            _decisionBadge(entry.statusLabel, fontSize: 11),
                          ],
                          if (prefs.showSecondaryDate) ...[
                            const SizedBox(height: 4),
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
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.add_circle_outline_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('Created ${entry.createdLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurface.withValues(alpha: 0.45))),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.receipt_long_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('${entry.itemCount} item${entry.itemCount == 1 ? '' : 's'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurface.withValues(alpha: 0.45))),
                              ),
                            ]),
                          ],
                          if (prefs.showProgress) ...[
                            const SizedBox(height: 9),
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
// _LogoBannerDocCard — List layout variant used when CardStyle.logoBanner
// is selected.
// -----------------------------------------------------------------------------

class _LogoBannerDocCard extends StatelessWidget {
  final _DocEntry entry;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onEnterSelection;

  const _LogoBannerDocCard({
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
    const double cardRadius = 18;
    final isDecision = entry.statusLabel == 'Accepted' || entry.statusLabel == 'Declined';

    return GestureDetector(
      onTap: () => selectionMode ? onToggleSelect(entry.key) : entry.onTap(),
      onLongPress: () => onEnterSelection(entry.key),
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
              color: entry.accentColor.withValues(alpha: isDark ? 0.12 : 0.07),
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
                    _DocLogoBanner(
                      logoPath: entry.logoPath,
                      businessName: entry.businessName,
                      accentColor: entry.accentColor,
                      height: 110,
                      topRadius: cardRadius,
                    ),
                    if (isDecision)
                      Positioned(
                        top: 10,
                        left: 12,
                        child: _decisionBadge(entry.statusLabel, fontSize: 11),
                      )
                    else if (prefs.showStatusChip)
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
                          child: Text(
                            entry.statusLabel,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: entry.accentColor),
                          ),
                        ),
                      ),
                    if (!selectionMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _ThreeDotIcon(
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
                            child: Row(
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
                          ),
                          if (prefs.showAmount)
                            Text(
                              _formatCardAmount(entry.totalAmount),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        Text(entry.subtitle,
                            style: TextStyle(fontSize: 12, color: entry.accentColor, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Text('· Edited ${entry.date}',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                      ]),
                      if (prefs.showSecondaryDate) ...[
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.add_circle_outline_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text('Created ${entry.createdLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.receipt_long_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.32)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text('${entry.itemCount} item${entry.itemCount == 1 ? '' : 's'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
                          ),
                        ]),
                      ],
                      if (prefs.showProgress) ...[
                        const SizedBox(height: 9),
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
    final prefs  = context.watch<CardDisplayPrefs>();
    final isDecision = entry.statusLabel == 'Accepted' || entry.statusLabel == 'Declined';

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
                if (isDecision) ...[
                  const SizedBox(height: 4),
                  _decisionBadge(entry.statusLabel, fontSize: 9),
                ],
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
                    if (!isDecision && prefs.showStatusChip)
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
    final isDecision = entry.statusLabel == 'Accepted' || entry.statusLabel == 'Declined';

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
                if (isDecision) ...[
                  const SizedBox(height: 3),
                  _decisionBadge(entry.statusLabel, fontSize: 8),
                ],
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
                if (!isDecision && prefs.showStatusChip)
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
    final isDecision = entry.statusLabel == 'Accepted' || entry.statusLabel == 'Declined';

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
                const SizedBox(width: 8),
                if (isDecision)
                  _decisionBadge(entry.statusLabel, fontSize: 9)
                else if (prefs.showStatusChip)
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