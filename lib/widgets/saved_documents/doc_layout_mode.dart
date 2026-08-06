// doc_layout_mode.dart
// lib/widgets/saved_documents/doc_layout_mode.dart
//
// Part of saved_documents_section.dart — the DocLayoutMode enum (list /
// grid / compact grid / compact / kanban), its icon/label extension, and
// the popup-menu button used to switch between them.

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
      itemBuilder: (context) => DocLayoutMode.values.map((mode) {
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
          color: cs.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 15, color: cs.onSurface.withOpacity(0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
