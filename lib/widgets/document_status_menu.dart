// document_status_menu.dart
// lib/widgets/document_status_menu.dart
//
// Shared 3-dot options menu used by every saved-document card (list, grid,
// compact grid, compact row, kanban) across Invoices/Quotes/Receipts.
// Callers build a list of StatusOption (one per possible status value for
// that doc type) plus Rename/Move to Folder/Delete callbacks. Kept as a
// standalone widget so saved_documents_section.dart doesn't have to define
// this sheet five times over.

import 'package:flutter/material.dart';

class StatusOption {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onSelect;

  const StatusOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelect,
  });
}

void showDocumentOptionsMenu(
  BuildContext context, {
  required String title,
  required Color accent,
  required List<StatusOption> statusOptions,
  required VoidCallback onRename,
  required VoidCallback onMoveToFolder,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),
              Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.45),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              ...statusOptions.map((opt) => _StatusRadioTile(option: opt)),
              const SizedBox(height: 10),
              Divider(color: cs.outline.withOpacity(0.15)),
              const SizedBox(height: 6),
              _MenuTile(
                icon: Icons.drive_file_rename_outline_rounded,
                label: 'Rename',
                color: const Color(0xFFFF9800),
                onTap: () {
                  Navigator.pop(ctx);
                  onRename();
                },
              ),
              _MenuTile(
                icon: Icons.folder_outlined,
                label: 'Move to Folder',
                color: accent,
                onTap: () {
                  Navigator.pop(ctx);
                  onMoveToFolder();
                },
              ),
              _MenuTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: const Color(0xFFF44336),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _StatusRadioTile extends StatelessWidget {
  final StatusOption option;
  const _StatusRadioTile({required this.option});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: option.onSelect,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: option.selected ? option.color : cs.outline.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: option.selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: option.color),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: option.color),
            ),
            const SizedBox(width: 8),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: option.selected ? FontWeight.w700 : FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}
