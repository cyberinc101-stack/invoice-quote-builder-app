// doc_card_shared.dart
// lib/widgets/saved_documents/doc_card_shared.dart
//
// Part of saved_documents_section.dart — small widgets shared across every
// card layout: the section header row, the selection-mode check badge, the
// 3-dot options icon, the green "positive status" dot, and the business
// logo avatar.
//
// LOGO FIX (this pass): _DocLogoAvatar now supports independent width/
// height instead of a single forced-square `size`. Previously every call
// site passed one `size` value used for both dimensions, so the logo
// always rendered as a small square icon-box regardless of how much
// vertical room the card actually had — on the List layout in particular
// this looked cramped and unprofessional next to a full row of text.
// `width`/`height` now default to `size` for callers that still want a
// square (grid/compactGrid/compact, which are genuinely tight on space),
// but the List layout passes an explicit `height: double.infinity` inside
// an IntrinsicHeight + CrossAxisAlignment.stretch row (see doc_cards.dart)
// so the logo image fills the card's full available height edge-to-edge,
// with BoxFit.cover, instead of sitting in a little padded square.
//
// Three-tier fallback unchanged: logo file exists -> real image; no logo
// but a business name -> colored initial monogram; neither -> generic
// document icon. Uses File.existsSync() (sync, not async) since this
// check needs to happen inline during build() for dozens of cards in a
// grid — avoids FutureBuilder flicker on every scroll.

part of 'saved_documents_section.dart';

class _SectionHeader extends StatelessWidget {
  final String label;
  final int    count;
  final Color  accentColor;
  final Widget? sortToggle;
  final Widget? layoutToggle;
  final Widget? displayOptionsToggle;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.accentColor,
    this.sortToggle,
    this.layoutToggle,
    this.displayOptionsToggle,
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
        if (sortToggle != null) ...[
          sortToggle!,
          const SizedBox(width: 8),
        ],
        if (layoutToggle != null) ...[
          layoutToggle!,
          const SizedBox(width: 8),
        ],
        if (displayOptionsToggle != null) ...[
          displayOptionsToggle!,
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

// Business logo avatar — replaces the old plain description-icon box on
// every card layout. Three-tier fallback:
//   1. logoPath set AND file still exists on disk  -> the actual logo image
//   2. logoPath missing/stale, businessName present -> colored initial monogram
//   3. neither available                            -> generic document icon
//
// width/height default to `size` (a square) for layouts that are tight on
// space. Pass them independently (e.g. width: 64, height: double.infinity
// inside an IntrinsicHeight row) to have the logo fill the card's full
// height edge-to-edge instead of sitting in a small square.
class _DocLogoAvatar extends StatelessWidget {
  final String? logoPath;
  final String businessName;
  final Color accentColor;
  final double size;
  final double? width;
  final double? height;
  final double iconSize;
  final double borderRadius;

  const _DocLogoAvatar({
    required this.logoPath,
    required this.businessName,
    required this.accentColor,
    required this.size,
    this.width,
    this.height,
    this.iconSize = 24,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final path = logoPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: w,
            height: h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(w, h),
          ),
        );
      }
    }
    return _fallback(w, h);
  }

  Widget _fallback(double w, double h) {
    final trimmedName = businessName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : null;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: iconSize * 0.62,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            )
          : Icon(Icons.description_rounded, color: accentColor, size: iconSize),
    );
  }
}
