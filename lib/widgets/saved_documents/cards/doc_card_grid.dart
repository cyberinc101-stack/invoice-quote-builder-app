part of '../saved_documents_section.dart';

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
          borderRadius: BorderRadius.circular(kDocCardRadiusMedium),
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
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (prefs.showLogo) ...[
                      Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                                  size: 40,
                                  iconSize: 18,
                                  borderRadius: kDocAvatarRadius(40),
                                  showHighlight: prefs.showLogoHighlight,
                                  showImage: prefs.showLogoImage,
                                ),
                              ),
                              if (prefs.showBusinessName) ...[
                                const SizedBox(height: 3),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: entry.accentColor.withValues(alpha: kDocChipAlpha + 0.02),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      entry.docTypeLabel,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: entry.accentColor,
                                      ),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                        if (entry.isPositiveStatus) positiveStatusDot(),
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
                      decisionBadge(entry.statusLabel, fontSize: 9),
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
                    if (prefs.showProgress) ...[
                      const SizedBox(height: 6),
                      _CompletionProgressBar(percent: entry.percent),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (!isDecision && prefs.showStatusChip && !entry.statusHidden)
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
                        const Spacer(),
                        if (prefs.showAmount)
                          Flexible(
                            child: _AmountLabel(
                              amount: entry.totalAmount,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                            ),
                          ),
                      ],
                    ),
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
