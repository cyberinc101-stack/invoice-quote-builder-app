// doc_layout_mode.dart
// lib/widgets/saved_documents/doc_layout_mode.dart
//
// Part of saved_documents_section.dart — the DocLayoutMode enum (list /
// grid / compact grid / compact / kanban), its icon/label extension, the
// popup-menu button used to switch between them, the matching
// _SortToggleButton for SortOption (recentFirst/oldestFirst/alphabetical/
// amountHighLow/amountLowHigh — defined in filter_types.dart, already wired
// end-to-end through DocumentFilterBar's Filters sheet), _FolderSortToggleButton
// for FolderSortOption, and _FolderLayoutToggleButton for FolderLayoutMode
// (both defined in folders_grid_view.dart) — used by the inline "browsing
// folders" header in saved_documents_section.dart. All four toggle buttons
// share the exact same small popup-chip visual (icon + chevron in a
// bordered pill) so they read as one consistent control family wherever
// they show up, rather than each section inventing its own filter-button
// look.
//
// KANBAN-FIRST PASS (this update): _LayoutToggleButton's popup menu now
// lists Kanban FIRST rather than last — Jesse wanted it as the top option.
// DocLayoutMode.values itself is untouched (still list/grid/compactGrid/
// compact/kanban in that declaration order, since other code — e.g.
// _fromShared/_toShared in saved_documents_section.dart — switches on the
// enum by name, not by position), so this reorders only the popup menu's
// DISPLAY order via an explicit list rather than iterating .values
// directly.
//
// UPDATED (earlier pass): FolderSortOption grew recentActivity/oldestActivity
// and FolderLayoutMode grew compactGrid/compact/kanban (both in
// folders_grid_view.dart) so folders now offer the same breadth of sort and
// layout options as the main document list. _FolderSortToggleButton and
// _FolderLayoutToggleButton already iterate over `.values`, so no changes
// were needed there — only the icon extensions below needed new cases
// added for the new enum members, matching the icon choices already used
// for the equivalent DocLayoutMode/SortOption members so the two dropdowns
// feel like the same control family.

part of 'saved_documents_section.dart';

enum DocLayoutMode { list, grid, compactGrid, compact, kanban }

extension on DocLayoutMode {
  IconData get icon {
    switch (this) {
      case DocLayoutMode.list:
        return Icons.view_agenda_rounded;
      case DocLayoutMode.grid:
        return Icons.grid_view_rounded;
      case DocLayoutMode.compactGrid:
        return Icons.apps_rounded;
      case DocLayoutMode.compact:
        return Icons.view_headline_rounded;
      case DocLayoutMode.kanban:
        return Icons.view_column_rounded;
    }
  }

  String get label {
    switch (this) {
      case DocLayoutMode.list:
        return 'List';
      case DocLayoutMode.grid:
        return 'Grid';
      case DocLayoutMode.compactGrid:
        return 'Compact Grid';
      case DocLayoutMode.compact:
        return 'Compact';
      case DocLayoutMode.kanban:
        return 'Kanban';
    }
  }
}

// Display order for the popup menu ONLY — Kanban first, per Jesse's ask.
// Kept separate from DocLayoutMode.values (whose declaration order other
// code relies on) so this is purely a presentation-order change.
const List<DocLayoutMode> _kLayoutMenuOrder = [
  DocLayoutMode.kanban,
  DocLayoutMode.list,
  DocLayoutMode.grid,
  DocLayoutMode.compactGrid,
  DocLayoutMode.compact,
];

class _LayoutToggleButton extends StatelessWidget {
  final DocLayoutMode selected;
  final ValueChanged<DocLayoutMode> onChanged;

  const _LayoutToggleButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<DocLayoutMode>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Change layout',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => _kLayoutMenuOrder.map((mode) {
        final isSelected = mode == selected;
        return PopupMenuItem<DocLayoutMode>(
          value: mode,
          child: Row(
            children: [
              Icon(mode.icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mode.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Sort toggle ─────────────────────────────────────────────────────────
//
// SortOption (filter_types.dart) already covers what was asked for: most
// recent / oldest first / alphabetical / amount high-low / amount low-high.
// This just surfaces it as a quick dropdown next to _LayoutToggleButton,
// driving the exact same _selectedSort state SavedDocumentsSection already
// threads through to DocumentFilterBar's Filters sheet — picking a sort
// here or in that sheet always agree, since they're the same value.

extension on SortOption {
  IconData get icon {
    switch (this) {
      case SortOption.recentFirst:
        return Icons.arrow_downward_rounded;
      case SortOption.oldestFirst:
        return Icons.arrow_upward_rounded;
      case SortOption.alphabetical:
        return Icons.sort_by_alpha_rounded;
      case SortOption.amountHighLow:
        return Icons.trending_down_rounded;
      case SortOption.amountLowHigh:
        return Icons.trending_up_rounded;
    }
  }
}

class _SortToggleButton extends StatelessWidget {
  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  const _SortToggleButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<SortOption>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Sort by',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => SortOption.values.map((option) {
        final isSelected = option == selected;
        return PopupMenuItem<SortOption>(
          value: option,
          child: Row(
            children: [
              Icon(option.icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sortOptionLabel(option),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Folder sort toggle ───────────────────────────────────────────────────
//
// Same exact visual as _SortToggleButton/_LayoutToggleButton above — a
// small bordered pill showing the current option's icon + a chevron, that
// opens a PopupMenuButton listing every FolderSortOption with a checkmark
// on the active one. Used by saved_documents_section.dart's inline
// folder-count header (right above FoldersGridView), next to
// _FolderLayoutToggleButton. Drives _foldersSortOption, which
// SavedDocumentsSection threads straight into FoldersGridView's sortOption
// param.
//
// recentActivity/oldestActivity (this pass) reuse the same up/down-arrow
// icon language as SortOption.recentFirst/oldestFirst, since they mean the
// same thing conceptually — just ordering folders instead of documents.

extension on FolderSortOption {
  IconData get icon {
    switch (this) {
      case FolderSortOption.nameAsc:
        return Icons.arrow_downward_rounded;
      case FolderSortOption.nameDesc:
        return Icons.arrow_upward_rounded;
      case FolderSortOption.mostDocuments:
        return Icons.trending_down_rounded;
      case FolderSortOption.leastDocuments:
        return Icons.trending_up_rounded;
      case FolderSortOption.recentActivity:
        return Icons.schedule_rounded;
      case FolderSortOption.oldestActivity:
        return Icons.hourglass_bottom_rounded;
    }
  }
}

class _FolderSortToggleButton extends StatelessWidget {
  final FolderSortOption selected;
  final ValueChanged<FolderSortOption> onChanged;

  const _FolderSortToggleButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<FolderSortOption>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Sort folders',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => FolderSortOption.values.map((option) {
        final isSelected = option == selected;
        return PopupMenuItem<FolderSortOption>(
          value: option,
          child: Row(
            children: [
              Icon(option.icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  folderSortOptionLabel(option),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Folder layout toggle ────────────────────────────────────────────────
//
// FolderLayoutMode (grid/list/compactGrid/compact/kanban, defined in
// folders_grid_view.dart) equivalent of _LayoutToggleButton above —
// identical visual (bordered pill, current mode's icon + chevron,
// PopupMenuButton with a checkmark on the active item). Used right next to
// _FolderSortToggleButton in saved_documents_section.dart's inline
// folder-count header. Drives _foldersLayoutMode, which
// SavedDocumentsSection threads straight into FoldersGridView's layoutMode
// param.
//
// compactGrid/compact/kanban (this pass) reuse the exact same icons as
// their DocLayoutMode equivalents, so the two layout dropdowns read as one
// consistent icon language across folders and documents.

extension on FolderLayoutMode {
  IconData get icon {
    switch (this) {
      case FolderLayoutMode.grid:
        return Icons.grid_view_rounded;
      case FolderLayoutMode.list:
        return Icons.view_agenda_rounded;
      case FolderLayoutMode.compactGrid:
        return Icons.apps_rounded;
      case FolderLayoutMode.compact:
        return Icons.view_headline_rounded;
      case FolderLayoutMode.kanban:
        return Icons.view_column_rounded;
    }
  }
}

class _FolderLayoutToggleButton extends StatelessWidget {
  final FolderLayoutMode selected;
  final ValueChanged<FolderLayoutMode> onChanged;

  const _FolderLayoutToggleButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<FolderLayoutMode>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Change folder layout',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => FolderLayoutMode.values.map((mode) {
        final isSelected = mode == selected;
        return PopupMenuItem<FolderLayoutMode>(
          value: mode,
          child: Row(
            children: [
              Icon(mode.icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  folderLayoutModeLabel(mode),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
