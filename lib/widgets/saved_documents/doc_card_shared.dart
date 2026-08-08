// doc_card_shared.dart
// lib/widgets/saved_documents/doc_card_shared.dart
//
// Part of saved_documents_section.dart — small widgets shared across every
// card layout: the section header row, the selection-mode check badge, the
// 3-dot options icon, and the green "positive status" dot.

part of 'saved_documents_section.dart';

class _SectionHeader extends StatelessWidget {
  final String label;
  final int    count;
  final Color  accentColor;
  final Widget? layoutToggle;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.accentColor,
    this.layoutToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const Spacer(),
        if (layoutToggle != null) ...[
          layoutToggle!,
          const SizedBox(width: 10),
        ],
        Text(
          '$count document${count == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

// Selection badge — small check circle shown top-right of a card while
// selection mode is active. Shared by all selectable card types.
class _SelectionBadge extends StatelessWidget {
  final bool selected;
  final Color accent;

  const _SelectionBadge({required this.selected, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : Colors.white,
        border: Border.all(color: selected ? accent : Colors.grey.shade400, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
    );
  }
}

// 3-dot options icon — shared by all card layouts. Rendered instead of the
// selection badge when NOT in selection mode (list/grid/compactGrid/
// compact), or always (kanban, which has no selection mode).
class _ThreeDotIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _ThreeDotIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_vert_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.65)),
      ),
    );
  }
}

// Small green dot shown next to a title when the entry's status is "good"
// (Paid / Accepted / Issued). One-liner, reused inline in every card layout.
Widget _positiveDot() => Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(left: 6),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
    );
