part of '../saved_documents_section.dart';

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
          borderRadius: BorderRadius.circular(kDocCardRadiusSmall),
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
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (prefs.showLogo) ...[
                      GestureDetector(
                        onLongPress: entry.onSetClientColor,
                        child: DocLogoAvatar(
                          logoPath: entry.logoPath,
                          logoOffset: entry.logoOffset,
                          logoScale: entry.logoScale,
                          logoShape: entry.logoShape,
                          businessName: entry.businessName,
                          accentColor: entry.accentColor,
                          clientColor: entry.clientColor,
                          size: 26,
                          iconSize: 13,
                          borderRadius: kDocAvatarRadius(26),
                          showHighlight: prefs.showLogoHighlight,
                          showImage: prefs.showLogoImage,
                        ),
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
                        if (entry.isPositiveStatus) positiveStatusDot(),
                      ],
                    ),
                    if (isDecision) ...[
                      const SizedBox(height: 3),
                      decisionBadge(entry.statusLabel, fontSize: 8),
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
                    // FIX: showCreatedAndItems previously had zero effect on
                    // this layout — the toggle existed but no widget in this
                    // file ever read it. Single condensed line (not the
                    // two-line "Created X · N items" the larger layouts use)
                    // since this card is only ~120px tall total.
                    if (prefs.showCreatedAndItems) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${entry.createdLabel} · ${entry.itemCount}',
                        style: TextStyle(fontSize: 8, color: cs.onSurface.withValues(alpha: 0.4)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (!isDecision && prefs.showStatusChip && !entry.statusHidden)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.accentColor.withValues(alpha: kDocChipAlpha),
                          borderRadius: BorderRadius.circular(kDocChipRadius),
                        ),
                        child: Text(
                          entry.statusLabel,
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: entry.accentColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (prefs.showAmount) ...[
                      const SizedBox(height: 4),
                      _AmountLabel(
                        amount: entry.totalAmount,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                      ),
                    ],
                    // FIX: showProgress previously had zero effect on this
                    // layout. Thin bar, no label — matches the compact
                    // footprint everything else on this card already uses.
                    if (prefs.showProgress) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: entry.percent / 100,
                          backgroundColor: cs.outline.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(entry.accentColor),
                          minHeight: 2.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (selectionMode)
              Positioned(
                top: -4,
                right: -4,
                child: SelectionBadge(selected: selected, accent: cs.primary),
              )
            else
              Positioned(
                top: -4,
                right: -4,
                child: ThreeDotIcon(onTap: entry.onShowMenu),
              ),
          ],
        ),
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(kDocCardRadiusSmall),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(kDocCardRadiusSmall),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (prefs.showLogo) ...[
                      GestureDetector(
                        onLongPress: entry.onSetClientColor,
                        child: DocLogoAvatar(
                          logoPath: entry.logoPath,
                          logoOffset: entry.logoOffset,
                          logoScale: entry.logoScale,
                          logoShape: entry.logoShape,
                          businessName: entry.businessName,
                          accentColor: entry.accentColor,
                          clientColor: entry.clientColor,
                          size: 28,
                          iconSize: 15,
                          borderRadius: kDocAvatarRadius(28),
                          showHighlight: prefs.showLogoHighlight,
                          showImage: prefs.showLogoImage,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.title,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (entry.isPositiveStatus) positiveStatusDot(),
                            ],
                          ),
                          Text(
                            'Edited ${entry.date}',
                            style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // FIX: showCreatedAndItems previously had zero
                          // effect on this layout. Kept on its own line
                          // under "Edited ..." rather than crammed into
                          // the same row, so it doesn't compete for width
                          // with the title/amount columns either side.
                          if (prefs.showCreatedAndItems)
                            Text(
                              'Created ${entry.createdLabel} · ${entry.itemCount} item${entry.itemCount == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 9.5, color: cs.onSurface.withValues(alpha: 0.35)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isDecision)
                      decisionBadge(entry.statusLabel, fontSize: 9)
                    else if (prefs.showStatusChip && !entry.statusHidden)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: entry.accentColor.withValues(alpha: kDocChipAlpha),
                          borderRadius: BorderRadius.circular(kDocChipRadius),
                        ),
                        child: Text(
                          entry.statusLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: entry.accentColor),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (prefs.showAmount)
                            _AmountLabel(
                              amount: entry.totalAmount,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
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
                    ),
                    if (!selectionMode) ...[
                      const SizedBox(width: 6),
                      ThreeDotIcon(onTap: entry.onShowMenu),
                    ],
                  ],
                ),
                // FIX: showProgress previously had zero effect on this
                // layout. Full-width thin bar under the row, indented to
                // align with the title text rather than starting at the
                // card's left edge (which would sit under the logo).
                if (prefs.showProgress)
                  Padding(
                    padding: EdgeInsets.only(top: 6, left: prefs.showLogo ? 38 : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: entry.percent / 100,
                        backgroundColor: cs.outline.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(entry.accentColor),
                        minHeight: 2.5,
                      ),
                    ),
                  ),
              ],
            ),
            if (selectionMode)
              Positioned(
                top: -6,
                right: -2,
                child: SelectionBadge(selected: selected, accent: cs.primary),
              ),
          ],
        ),
      ),
    );
  }
}
