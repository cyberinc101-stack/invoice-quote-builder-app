// doc_card_shared.dart
// lib/widgets/saved_documents/doc_card_shared.dart
//
// LOGO HIGHLIGHT / LOGO IMAGE TOGGLES (this pass): DocLogoAvatar and
// DocLogoBanner both gained two new optional params:
//   - showHighlight (default true): when false, the colored box-shadow
//     glow behind the logo (image OR fallback initial/icon) is omitted —
//     the box/banner renders flat, no shadow.
//   - showImage (default true): when false, the actual uploaded picture
//     is never drawn, even if one exists on disk — rendering falls
//     through to the same fallback initial/icon treatment used when
//     there's no logo at all.
// Both are driven by CardDisplayPrefs.showLogoHighlight/showLogoImage
// (see card_display_prefs.dart) and threaded in by every card file
// (doc_card_grid.dart, doc_card_list.dart, doc_card_compact.dart).
// Defaulting to true keeps every other call site (template previews,
// etc.) unchanged if it doesn't pass them.
//
// SECTION HEADER WRAP FIX (earlier pass): SectionHeader's toggle+count
// cluster previously sat in a SingleChildScrollView(reverse: true), which
// starts already scrolled to its right edge — so on a narrow screen where
// the full cluster (sort + layout + groupBy + displayOptions + count)
// doesn't fit, the toggles at the START of the row (sort, layout) sat
// off-screen to the left until the user manually scrolled it into view.
// That's what was showing up as the icon row looking randomly "cut off"
// or inconsistently sized between renders/screens — nothing was actually
// broken layout-wise, it was just scrolled past. Replaced with a Wrap:
// nothing is ever hidden behind a scroll offset. When everything fits on
// one line (the common case) it's visually identical to before; when it
// doesn't, the overflow drops to a second line instead of requiring a
// scroll gesture the user had no reason to know was needed.
//
// Everything else in this file is unchanged from the previous pass.

import 'dart:io';
import 'package:flutter/material.dart';
import '../shared_logo_picker.dart';

const double kDocChipRadius = 8.0;
const double kDocChipAlpha = 0.1;

const double kDocCardRadiusLarge = 18.0;  // List / Logo Banner
const double kDocCardRadiusMedium = 16.0; // Grid
const double kDocCardRadiusSmall = 10.0;  // Compact Grid / Compact Row

/// Avatar corner radius held at a constant ~22% of its size, so a 68px
/// List avatar and a 26px Compact Grid avatar look like the same shape
/// scaled down, not progressively rounder as they shrink.
double kDocAvatarRadius(double size) => size * 0.22;

/// Soft neutral background a contained (letterboxed) logo sits on, so it
/// doesn't look like it's floating on a hard white/dark rectangle. Mixed
/// with the document's own accent at low alpha so it still feels tied to
/// that document's colour, without competing with the logo itself. This
/// is the DEFAULT — used only when the client has no color assigned via
/// ClientColorPrefs (see client_color_prefs.dart).
Color kDocLogoLetterboxBg(Color accent) => accent.withValues(alpha: 0.05);

/// Same idea, but for a user-chosen client color (client_color_prefs.dart)
/// instead of the document's accent. Kept at a low, fixed alpha regardless
/// of how saturated the chosen swatch is, so the letterbox stays a subtle
/// backdrop rather than competing with the logo sitting on top of it —
/// and so a logo with its own baked-in solid background (a JPEG, say)
/// blends into a soft tint of the user's chosen color at the letterbox
/// margin, rather than sitting inside a full-strength color block.
Color kDocLogoClientBg(Color clientColor) => clientColor.withValues(alpha: 0.16);

class SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color accentColor;
  final Widget? sortToggle;
  final Widget? layoutToggle;
  final Widget? groupByToggle;
  final Widget? displayOptionsToggle;

  const SectionHeader({
    super.key,
    required this.label,
    required this.count,
    required this.accentColor,
    this.sortToggle,
    this.layoutToggle,
    this.groupByToggle,
    this.displayOptionsToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // LAYOUT (this pass): toggle icons (sort/layout/groupBy/display) sit on
    // their own row ABOVE the title, right-aligned -- Jesse felt them
    // sharing a line with the title looked cluttered/out of place. The
    // document count now sits beside the title instead of at the end of
    // the toggle row, since it's describing the title ("My Invoices — 3
    // documents"), not one of the toggle controls.
    //
    // ORDER (this pass): layoutToggle now comes FIRST (leftmost in the
    // right-aligned cluster), ahead of sortToggle — Jesse wanted the
    // layout filter container to appear first.
    final toggleIcons = <Widget>[
      if (layoutToggle != null) ...[layoutToggle!, const SizedBox(width: 8)],
      if (sortToggle != null) ...[sortToggle!, const SizedBox(width: 8)],
      if (groupByToggle != null) ...[groupByToggle!, const SizedBox(width: 8)],
      if (displayOptionsToggle != null) displayOptionsToggle!,
    ];
    // Drop the trailing spacer after the last icon, if any were added.
    if (toggleIcons.isNotEmpty && toggleIcons.last is SizedBox) {
      toggleIcons.removeLast();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (toggleIcons.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 6,
              children: toggleIcons,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count document${count == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Selection badge -- small check circle shown top-right of a card while
// selection mode is active. Shared by every card family.
class SelectionBadge extends StatelessWidget {
  final bool selected;
  final Color accent;

  const SelectionBadge({super.key, required this.selected, required this.accent});

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

// 3-dot options icon -- shared by every card layout in every card family.
class ThreeDotIcon extends StatelessWidget {
  final VoidCallback onTap;
  final Color? background;
  final Color? iconColor;
  const ThreeDotIcon({super.key, required this.onTap, this.background, this.iconColor});

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
// (Paid / Accepted / Issued). Reused inline in every card layout.
Widget positiveStatusDot() => Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(left: 6),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
    );

// Bold Accepted/Declined pill for quote cards.
Widget decisionBadge(String statusLabel, {double fontSize = 11}) {
  final isAccepted = statusLabel == 'Accepted';
  final isDeclined = statusLabel == 'Declined';
  if (!isAccepted && !isDeclined) return const SizedBox.shrink();

  final color = isAccepted ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
  final icon = isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded;
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

class DocLogoAvatar extends StatelessWidget {
  final String? logoPath;
  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;
  final String businessName;
  final Color accentColor;
  final double size;
  final double? width;
  final double? height;
  final double iconSize;
  final double borderRadius;
  final IconData fallbackIcon;
  final Color? clientColor;

  /// When false, the colored glow/box-shadow behind the avatar (image OR
  /// fallback initial/icon) is omitted — renders flat. Defaults to true.
  final bool showHighlight;

  /// When false, the actual uploaded logo picture is never drawn, even if
  /// one exists on disk — falls through to the same fallback initial/icon
  /// treatment used when there's no logo. Defaults to true.
  final bool showImage;

  const DocLogoAvatar({
    super.key,
    required this.logoPath,
    this.logoOffset = Offset.zero,
    this.logoScale = 1.0,
    this.logoShape = LogoShape.roundedSquare,
    required this.businessName,
    required this.accentColor,
    required this.size,
    this.width,
    this.height,
    this.iconSize = 24,
    this.borderRadius = 12,
    this.fallbackIcon = Icons.description_rounded,
    this.clientColor,
    this.showHighlight = true,
    this.showImage = true,
  });

  bool get _hasLogo => logoPath != null && logoPath!.isNotEmpty && File(logoPath!).existsSync();

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final letterboxBg = clientColor != null
        ? kDocLogoClientBg(clientColor!)
        : kDocLogoLetterboxBg(accentColor);
    final shadowColor = (clientColor ?? accentColor).withValues(alpha: 0.28);

    if (_hasLogo && showImage) {
      return Container(
        width: w,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: letterboxBg,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: showHighlight
              ? [BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(w * 0.08),
        child: Image.file(
          File(logoPath!),
          fit: BoxFit.contain,
        ),
      );
    }
    return _fallback(w, h);
  }

  Widget _fallback(double w, double h) {
    final trimmedName = businessName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : null;
    final effectiveColor = clientColor ?? accentColor;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showHighlight
            ? [BoxShadow(color: effectiveColor.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3))]
            : null,
      ),
      alignment: Alignment.center,
      child: initial != null
          ? Text(
              initial,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: iconSize * 0.62,
                fontWeight: FontWeight.w800,
                color: effectiveColor,
              ),
            )
          : Icon(fallbackIcon, color: effectiveColor, size: iconSize),
    );
  }
}

class DocLogoBanner extends StatelessWidget {
  final String? logoPath;
  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;
  final String businessName;
  final Color accentColor;
  final double height;
  final double topRadius;
  final IconData fallbackIcon;
  final Color? clientColor;

  /// When false, omits the colored glow treatment on the fallback banner
  /// (the gradient itself is the banner's base look either way — this
  /// only affects whether the fallback's tint gradient renders at full
  /// strength or is flattened to a neutral surface). Defaults to true.
  final bool showHighlight;

  /// When false, the actual uploaded logo picture is never drawn, even if
  /// one exists on disk — falls through to the fallback initial/icon
  /// banner used when there's no logo. Defaults to true.
  final bool showImage;

  const DocLogoBanner({
    super.key,
    required this.logoPath,
    this.logoOffset = Offset.zero,
    this.logoScale = 1.0,
    this.logoShape = LogoShape.roundedSquare,
    required this.businessName,
    required this.accentColor,
    this.height = 120,
    this.topRadius = 16,
    this.fallbackIcon = Icons.description_rounded,
    this.clientColor,
    this.showHighlight = true,
    this.showImage = true,
  });

  bool get _hasLogo => logoPath != null && logoPath!.isNotEmpty && File(logoPath!).existsSync();

  @override
  Widget build(BuildContext context) {
    if (_hasLogo && showImage) {
      final letterboxBg = clientColor != null
          ? kDocLogoClientBg(clientColor!)
          : kDocLogoLetterboxBg(accentColor);
      return ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
        child: Container(
          width: double.infinity,
          height: height,
          color: letterboxBg,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: height * 0.12, horizontal: 24),
          child: Image.file(
            File(logoPath!),
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    return _fallbackBanner();
  }

  Widget _fallbackBanner() {
    final effectiveColor = clientColor ?? accentColor;
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
        gradient: showHighlight
            ? LinearGradient(
                colors: [
                  effectiveColor.withValues(alpha: 0.16),
                  effectiveColor.withValues(alpha: 0.06),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: showHighlight ? null : effectiveColor.withValues(alpha: 0.06),
      ),
      child: _fallbackContent(effectiveColor),
    );
  }

  Widget _fallbackContent(Color effectiveColor) {
    final trimmedName = businessName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : null;
    return initial != null
        ? Text(
            initial,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: effectiveColor.withValues(alpha: 0.85),
            ),
          )
        : Icon(fallbackIcon, color: effectiveColor.withValues(alpha: 0.85), size: 44);
  }
}
