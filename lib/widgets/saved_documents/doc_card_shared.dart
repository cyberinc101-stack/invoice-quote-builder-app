// doc_card_shared.dart
// lib/widgets/saved_documents/doc_card_shared.dart
//
// Part of saved_documents_section.dart — small widgets shared across every
// card layout: the section header row, the selection-mode check badge, the
// 3-dot options icon, the green "positive status" dot, the business logo
// avatar, the full-width logo banner used by CardStyle.logoBanner, and the
// bold Accepted/Declined decision badge used on quote cards.
//
// NO-BACKGROUND LOGO PASS (this update): _DocLogoAvatar and _DocLogoBanner
// previously wrapped the real logo image in a tinted Container (a soft
// accent-colored backing) so contain-fit logos wouldn't look like they were
// floating on nothing. Per feedback, that background reads as clutter — the
// image itself should just fill/sit centered in the card slot with nothing
// behind it. Both widgets now render the plain Image.file directly with
// BoxFit.contain + Alignment.center, no Container/tint/padding wrapper, when
// a real logo file exists. The colored tint is ONLY still used for the
// fallback state (no logo file — initials monogram or generic icon), since
// there's no actual image there and a bare icon/letter on a transparent
// background would look broken, not clean.
//
// DECISION BADGE (this update): added `_decisionBadge(statusLabel)` — a
// small bold, high-contrast pill only rendered when statusLabel is exactly
// 'Accepted' or 'Declined' (the two QuoteStatus states callers care about
// seeing at a glance). Returns SizedBox.shrink() for every other status, so
// it's a no-op / safe to drop into any card layout without special-casing
// document type. Solid fill (not the usual soft-tint chip) so it reads
// clearly even at a glance in a scrolled list.

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
//
// `background`/`iconColor` overrides let the Logo Banner list card render
// this icon as a translucent-white pill on top of an image background,
// instead of the default subtle-on-surface tint that would be invisible
// there.
class _ThreeDotIcon extends StatelessWidget {
  final VoidCallback onTap;
  final Color? background;
  final Color? iconColor;
  const _ThreeDotIcon({required this.onTap, this.background, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: background ?? cs.onSurface.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: 16,
          color: iconColor ?? cs.onSurface.withValues(alpha: 0.65),
        ),
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

// Bold Accepted/Declined pill for quote cards. No-op (SizedBox.shrink) for
// every status label other than exactly 'Accepted' or 'Declined', so it's
// safe to drop into any card layout unconditionally — invoices/receipts
// never carry those two labels so this never renders for them.
Widget _decisionBadge(String statusLabel, {double fontSize = 11}) {
  final isAccepted = statusLabel == 'Accepted';
  final isDeclined = statusLabel == 'Declined';
  if (!isAccepted && !isDeclined) return const SizedBox.shrink();

  final color = isAccepted ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
  final icon  = isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded;
  final label = isAccepted ? 'ACCEPTED' : 'DECLINED';

  return Container(
    padding: EdgeInsets.symmetric(horizontal: fontSize * 0.8, vertical: fontSize * 0.35),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(fontSize),
      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: fontSize + 2, color: Colors.white),
        SizedBox(width: fontSize * 0.35),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// Business logo avatar. Three-tier fallback:
//   1. logoPath set AND file still exists on disk  -> the actual logo image,
//      rendered plain (no background) — BoxFit.contain, centered, nothing
//      behind it.
//   2. logoPath missing/stale, businessName present -> colored initial
//      monogram (tint kept here — there's no image to show plainly).
//   3. neither available                            -> generic document
//      icon (tint kept here too, same reasoning).
class _DocLogoAvatar extends StatelessWidget {
  final String? logoPath;
  final String businessName;
  final Color accentColor;
  final double size;
  final double? width;
  final double? height;
  final double iconSize;
  final double borderRadius;
  final BoxFit fit;

  const _DocLogoAvatar({
    required this.logoPath,
    required this.businessName,
    required this.accentColor,
    required this.size,
    this.width,
    this.height,
    this.iconSize = 24,
    this.borderRadius = 12,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final path = logoPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        // Plain image, no tint/background container — just sized, clipped
        // to match the card's corner radius, centered and fully contained.
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: w,
            height: h,
            child: Image.file(
              file,
              fit: fit,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => _fallback(w, h),
            ),
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
              textAlign: TextAlign.center,
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

// Full-width logo banner — top band of the List card when
// CardDisplayPrefs.cardStyle == CardStyle.logoBanner.
//
// NO-BACKGROUND PASS: when a real logo file exists, this now renders the
// plain image (contain, centered) filling the banner height with no tint/
// gradient behind it — just the image itself against the card's own
// background. The soft accent gradient is kept ONLY for the fallback state
// (no logo file), where a bare monogram/icon needs some visual weight
// behind it to not look like an empty card.
class _DocLogoBanner extends StatelessWidget {
  final String? logoPath;
  final String businessName;
  final Color accentColor;
  final double height;
  final double topRadius;

  const _DocLogoBanner({
    required this.logoPath,
    required this.businessName,
    required this.accentColor,
    this.height = 120,
    this.topRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final path = logoPath;

    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Image.file(
              file,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => _fallbackBanner(),
            ),
          ),
        );
      }
    }
    return _fallbackBanner();
  }

  Widget _fallbackBanner() {
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.16),
            accentColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _fallbackContent(),
    );
  }

  Widget _fallbackContent() {
    final trimmedName = businessName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : null;
    return initial != null
        ? Text(
            initial,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: accentColor.withValues(alpha: 0.85),
            ),
          )
        : Icon(Icons.description_rounded, color: accentColor.withValues(alpha: 0.85), size: 44);
  }
}