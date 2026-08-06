// doc_kanban.dart
// lib/widgets/saved_documents/doc_kanban.dart
//
// Part of saved_documents_section.dart — the kanban board layout, which
// groups entries into columns by statusLabel. Not selectable (no
// multi-select in this layout) — tap opens the document, and each card
// carries a 3-dot menu icon (always visible, since there's no
// selection-mode toggle to conflict with here).

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
      height: 420,
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
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${entries.length}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.4)),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
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
                ),
                _ThreeDotIcon(onTap: entry.onShowMenu),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.subtitle,
              style: TextStyle(fontSize: 10.5, color: entry.accentColor, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              entry.date,
              style: TextStyle(fontSize: 10.5, color: cs.onSurface.withOpacity(0.4)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: entry.percent / 100,
                backgroundColor: cs.outline.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(entry.accentColor),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
