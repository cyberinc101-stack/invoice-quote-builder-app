part of '../saved_documents_section.dart';

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
          borderRadius: BorderRadius.circular(kDocCardRadiusLarge),
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
            IntrinsicHeight(
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (prefs.showLogo) ...[
                  SizedBox(
                    width: 68,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            size: 68,
                            iconSize: 28,
                            borderRadius: kDocAvatarRadius(68),
                            showHighlight: prefs.showLogoHighlight,
                            showImage: prefs.showLogoImage,
                          ),
                        ),
                        if (prefs.showBusinessName)
                          Container(
                            width: 68,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: entry.accentColor.withValues(alpha: kDocChipAlpha + 0.02),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                entry.docTypeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  color: entry.accentColor,
                                ),
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
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
                              if (entry.isPositiveStatus) positiveStatusDot(),
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
                            decisionBadge(entry.statusLabel, fontSize: 11),
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
                            _CompletionProgressBar(percent: entry.percent),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!selectionMode)
                        ThreeDotIcon(onTap: entry.onShowMenu),
                      const Spacer(),
                      if (prefs.showStatusChip || prefs.showAmount)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (prefs.showStatusChip && !entry.statusHidden) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: entry.accentColor.withValues(alpha: kDocChipAlpha),
                                  borderRadius: BorderRadius.circular(kDocChipRadius),
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
                              const SizedBox(height: 6),
                            ],
                            if (prefs.showAmount)
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 110),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: _AmountLabel(
                                    amount: entry.totalAmount,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
            ),
            if (selectionMode)
              Positioned(
                top: -4,
                right: -4,
                child: SelectionBadge(selected: selected, accent: cs.primary),
              ),
          ],
        ),
      ),
    );
  }
}

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
    const double cardRadius = kDocCardRadiusLarge;
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
                    GestureDetector(
                      onLongPress: entry.onSetClientColor,
                      child: DocLogoBanner(
                        logoPath: entry.logoPath,
                        logoOffset: entry.logoOffset,
                        logoScale: entry.logoScale,
                        logoShape: entry.logoShape,
                        businessName: entry.businessName,
                        accentColor: entry.accentColor,
                        clientColor: entry.clientColor,
                        height: 110,
                        topRadius: cardRadius,
                        showHighlight: prefs.showLogoHighlight,
                        showImage: prefs.showLogoImage,
                      ),
                    ),
                    if (isDecision)
                      Positioned(
                        top: 10,
                        left: 12,
                        child: decisionBadge(entry.statusLabel, fontSize: 11),
                      )
                    else if (prefs.showStatusChip && !entry.statusHidden)
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(kDocChipRadius),
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
                        child: ThreeDotIcon(
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
                                if (entry.isPositiveStatus) positiveStatusDot(),
                              ],
                            ),
                          ),
                          if (prefs.showAmount)
                            Flexible(
                              child: _AmountLabel(
                                amount: entry.totalAmount,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
                              ),
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
                        _CompletionProgressBar(percent: entry.percent),
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
                child: SelectionBadge(selected: selected, accent: cs.primary),
              ),
          ],
        ),
      ),
    );
  }
}
