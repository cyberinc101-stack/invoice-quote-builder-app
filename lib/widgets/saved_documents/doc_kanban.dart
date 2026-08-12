// doc_kanban.dart
// lib/widgets/saved_documents/doc_kanban.dart
//
// Part of saved_documents_section.dart — the kanban board layout, which
// groups entries into columns by statusLabel. Not selectable (no
// multi-select in this layout) — tap opens the document, and each card
// carries a 3-dot menu icon (always visible, since there's no
// selection-mode toggle to conflict with here).
//
// NEW (this pass): kanban cards now show the business logo via
// _DocLogoAvatar (doc_card_shared.dart, 18x18 — smallest of any layout,
// this board is already the tightest on space) in place of the icon that
// used to sit where the title now starts flush-left, plus the document's
// total amount on its own small line. Created date / item count are
// skipped here — the column is only 165 wide and the card already carries
// title, subtitle, last-edited date, and a progress bar; adding two more
// lines would either overflow or force everything down to unreadable
// font sizes.
//
// SHRINK (earlier pass, kept): whole board scaled down — column width 165,
// card padding/fonts trimmed, board height 380. The 3-dot icon's own size
// lives in _ThreeDotIcon (doc_card_shared.dart) which this file doesn't
// own, so it's wrapped in a Transform.scale here to shrink it in place
// without touching that shared widget.

part of 'saved_documents_section.dart';

class _DocKanbanBoard extends StatelessWidget {
  final List<_DocEntry> entries;
  const _DocKanbanBoard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<_DocEntry>> columns = {};
    for (final e in entries) {
      columns.putIfAbsent(e.statusLabel, () => []).add(e);
    }

    return SizedBox(
      height: 380,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns.entries
              .map((col) => _DocKanbanColumn(statusLabel: col.key, entries: col.value))
              .toList(),
        ),
      ),
    );
  }
}

class _DocKanbanColumn extends StatelessWidget {
  final String statusLabel;
  final List<_DocEntry> entries;
  const _DocKanbanColumn({required this.statusLabel, required this.entries});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = entries.isNotEmpty ? entries.first.accentColor : cs.primary;

    return Container(
      width: 165,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${entries.length}',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              itemBuilder: (context, index) => _DocKanbanCard(entry: entries[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocKanbanCard extends StatelessWidget {
  final _DocEntry entry;
  const _DocKanbanCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DocLogoAvatar(
                  logoPath: entry.logoPath,
                  businessName: entry.businessName,
                  accentColor: entry.accentColor,
                  size: 18,
                  iconSize: 10,
                  borderRadius: 6,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.title,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isPositiveStatus) _positiveDot(),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: _ThreeDotIcon(onTap: entry.onShowMenu),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              entry.subtitle,
              style: TextStyle(fontSize: 9, color: entry.accentColor, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.date,
                    style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.4)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatCardAmount(entry.totalAmount),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: entry.percent / 100,
                backgroundColor: cs.outline.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(entry.accentColor),
                minHeight: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
