// document_detail_header.dart
// lib/screens/saved_invoice_details_section/detail/document_detail_header.dart
//
// THEME-MATCH REDESIGN PASS (this update): previously this header used
// its own visual language — a flat per-type accent gradient for the
// no-logo branch, and an unrelated dark navy (0xFF1A1A2E flat) for the
// logo branch — neither of which matched the rest of the app. The home
// screen's hero banner (lib/widgets/hero_card.dart /
// home_screen.dart._buildHeroBanner) is the app's actual signature
// visual: a navy gradient (0xFF1A1A2E → 0xFF16213E → 0xFF0F3460), soft
// glow shadow, white-10% pill badges with a hairline border, bold white
// type with tight letter-spacing, and gradient icon tiles with a
// colored glow shadow matching each doc type's accent. This header now
// uses that exact gradient as its base in BOTH branches, so the detail
// screen reads as the same product as the home screen instead of a
// different app bolted on. The per-document accent color (invoice blue
// / quote purple / receipt green) is preserved as the identifying
// color — it now shows up as the type chip, the glow around the logo
// card, and the accent line under the status pill, rather than washing
// the entire header.
//
// No-logo branch: rebuilt as a clean, minimal panel over the navy hero
// gradient — a soft accent-tinted glow in one corner, a large ghost
// type icon watermark (subtle, same idea as the hero's mini doc icons),
// a pill status badge, bold title, and a compact type+date row styled
// like the hero's "Professional documents in minutes" pill. No busy
// decorative circles — flat/premium per your direction.
//
// FULL-BLEED LOGO PASS (this update): per feedback, a small white logo
// card floating over a blurred wash still didn't read as "the logo
// takes over this section" — it read as a logo NEXT TO a branded
// section. The logo is now the actual header background: a full-bleed,
// cover-fit Image.file filling the entire SliverAppBar edge-to-edge,
// full resolution, no blur. Legibility for the status pill/title/date
// row is handled with two separate scrims instead of one flat tint:
//   - A bottom-weighted gradient (near-transparent at the top, deepening
//     to ~88% navy at the very bottom) so the logo stays visible across
//     most of the header while the text — now anchored to the bottom of
//     the header via a Spacer, sitting on the darkest part of the scrim
//     — stays reliably readable regardless of the logo's own colors. A
//     drop shadow on the title text is a second safety net for busy/
//     bright logos.
//   - A short, separate top scrim (~90px, fading out) so the back/menu
//     buttons in the SliverAppBar's leading/actions stay legible too,
//     independent of the bottom scrim.
// The header's height grows slightly in this branch (260 vs 188) to
// give the full-bleed image more visible room above the text block.
//
// heightFor(hasLogo:) unchanged in spirit — still sizes the
// SliverAppBar per branch to avoid the old overflow bug.

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

/// The app's signature hero gradient (see lib/widgets/hero_card.dart and
/// home_screen.dart._buildHeroBanner). Reused here so the detail header
/// reads as the same product, not a bolted-on screen.
const List<Color> kHeroGradient = [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)];
const Color kHeroGlow = Color(0x401A1A2E);

class DocumentDetailHeader extends StatelessWidget {
  final Color accentColor;
  final File? logoFile;
  final String title;
  final String typeLabel;
  final IconData typeIcon;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final DateTime createdAt;

  const DocumentDetailHeader({
    super.key,
    required this.accentColor,
    required this.logoFile,
    required this.title,
    required this.typeLabel,
    required this.typeIcon,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.createdAt,
  });

  /// The SliverAppBar's expandedHeight for whichever branch is about to
  /// render — call this from the screen instead of hard-coding a single
  /// height for both branches, which is what caused the overflow.
  static double heightFor({required bool hasLogo}) => hasLogo ? 260 : 188;

  static const _shortMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  static String _formatDate(DateTime dt) => '${dt.day} ${_shortMonths[dt.month - 1]} ${dt.year}';

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoFile != null;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base — the app's hero gradient, always present so both
          // branches share one visual foundation.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: kHeroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (hasLogo) ...[
            // The logo now fills the ENTIRE header edge-to-edge as the
            // actual background image (cover-fit, full bleed) — not a
            // blurred wash and not confined to a small card. This is the
            // real logo the person uploaded, sharp, just cropped to fill
            // the header the way a cover photo would.
            Positioned.fill(
              child: Image.file(
                logoFile!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Bottom-weighted scrim only — strongest behind the title/
            // status text at the bottom, fading to nearly nothing at the
            // top so the logo itself stays fully visible across most of
            // the header while the text on top still reads clearly
            // regardless of the logo's own colors.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kHeroGradient[0].withValues(alpha: 0.05),
                      kHeroGradient[0].withValues(alpha: 0.15),
                      kHeroGradient[0].withValues(alpha: 0.55),
                      kHeroGradient[0].withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            // Thin scrim at the very top too, just enough for the
            // back/menu icon buttons in the SliverAppBar to stay legible
            // against a bright or busy logo.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kHeroGradient[0].withValues(alpha: 0.35),
                      kHeroGradient[0].withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // No-logo branch — soft single accent-tinted glow in one
            // corner (subtle, not a full wash) plus a large ghost type
            // icon watermark, echoing the hero banner's quiet decorative
            // touches without competing with the content.
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accentColor.withValues(alpha: 0.28), accentColor.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: -14,
              child: Icon(typeIcon, size: 116, color: Colors.white.withValues(alpha: 0.05)),
            ),
          ],

          // Foreground content — identical structure for both branches so
          // spacing never drifts between them.
          Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasLogo)
                const Spacer()
              else
                SizedBox(height: kToolbarHeight + 10),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, hasLogo ? 18 : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StatusPill(label: statusLabel, color: statusColor, icon: statusIcon),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: hasLogo ? 19 : 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                        height: 1.2,
                        shadows: hasLogo
                            ? const [Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 2))]
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    _TypeAndDateRow(
                      typeIcon: typeIcon,
                      typeLabel: typeLabel,
                      dateLabel: _formatDate(createdAt),
                      accentColor: accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusPill({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// Styled like the hero banner's "Professional documents in minutes" pill
// (white @10%, hairline border) so this row reads as the same design
// system, with the document's accent color used for the icon + type
// label to keep the per-type identity legible against the navy base.
class _TypeAndDateRow extends StatelessWidget {
  final IconData typeIcon;
  final String typeLabel;
  final String dateLabel;
  final Color accentColor;
  const _TypeAndDateRow({
    required this.typeIcon,
    required this.typeLabel,
    required this.dateLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeIcon, size: 11, color: accentColor),
          const SizedBox(width: 5),
          Text(typeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.1)),
          const SizedBox(width: 10),
          Container(width: 3, height: 3, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Icon(Icons.calendar_today_rounded, size: 10, color: Colors.white.withValues(alpha: 0.55)),
          const SizedBox(width: 4),
          Text(dateLabel, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
