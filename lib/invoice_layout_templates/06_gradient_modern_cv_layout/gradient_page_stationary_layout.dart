// gradient_page_stationary_layout.dart
// lib/cv_layout_templates/06_gradient_modern_cv_layout/gradient_page_stationary_layout.dart

import 'package:flutter/material.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'gradient_cv_logic_data.dart';

// ── Page geometry ─────────────────────────────────────────────────────────────
const double kGradPageW      = 595.0;
const double kGradPageH      = 842.0;
const double kGradHeaderH    = 140.0;
const double kGradSideBarW   = 210.0;
const double kGradSidePadH   =  16.0;
const double kGradSidePadV   =  16.0;
const double kGradSideW      = kGradSideBarW - kGradSidePadH * 2;
const double kGradMainPadH   =  18.0;
const double kGradMainPadV   =  16.0;
const double kGradMainW      = kGradPageW - kGradSideBarW - kGradMainPadH * 2;
const double kGradFooterH    =  20.0;
const double kGradBodyH      = kGradPageH - kGradFooterH;
const double kGradDividerW   =   1.0;

// ── Image size constants ──────────────────────────────────────────────────────
const double kGradImgSizeBase   = 12.0;
const double kGradImgSizePxBase = 72.0;

double _gradImgPxLayout(double imageSize) =>
    kGradImgSizePxBase * (imageSize / kGradImgSizeBase);

// ── Palette ───────────────────────────────────────────────────────────────────
const Color kGradBg           = Color(0xFFFFFFFF);
const Color kGradSideBg       = Color(0xFFF7F8FC);
const Color kGradHeaderStart  = Color(0xFF3B5BDB);
const Color kGradHeaderEnd    = Color(0xFF7048E8);
const Color kGradAccentTeal   = Color(0xFF1C9E8B);
const Color kGradAccentPurple = Color(0xFF7048E8);
const Color kGradText         = Color(0xFF1A1A2E);
const Color kGradMuted        = Color(0xFF555577);
const Color kGradLightMuted   = Color(0xFF888899);
const Color kGradDivider      = Color(0xFFE0E4F0);
const Color kGradBarBg        = Color(0xFFE8EAF6);
const Color kGradAccentLabel  = Color(0xFF3B5BDB);
const Color kGradTagBg        = Color(0xFFEEF0FB);

const List<Color> kGradHeaderColors = [kGradHeaderStart, kGradHeaderEnd];
const List<Color> kGradBarColors    = [Color(0xFF1C9E8B), Color(0xFF7048E8)];

const double kGradBaseFontSize = 12.0;

// ── Theme ─────────────────────────────────────────────────────────────────────
class GradTheme {
  final double fontScale;
  final String font;

  const GradTheme({this.fontScale = 1.0, this.font = 'sans-serif'});

  double fs(double base) => (base * fontScale).clamp(6.0, 32.0);
}

GradTheme gradThemeFromData(CVTemplateData data) {
  final scale = (data.fontSize > 0 ? data.fontSize : kGradBaseFontSize) /
      kGradBaseFontSize;
  final font = data.fontFamily.isNotEmpty ? data.fontFamily : 'sans-serif';
  return GradTheme(fontScale: scale, font: font);
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: GradPageLayout
// Converted to StatefulWidget so the theme is cached and gradThemeFromData()
// is not recomputed on every build (e.g. every scroll/touch event).
// ─────────────────────────────────────────────────────────────────────────────
class GradPageLayout extends StatefulWidget {
  final CVTemplateData  data;
  final List<GradItem>  mainItems;
  final List<GradItem>  sideItems;
  final int             pageNum;
  final int             totalPages;

  const GradPageLayout({
    super.key,
    required this.data,
    required this.mainItems,
    required this.sideItems,
    required this.pageNum,
    required this.totalPages,
  });

  @override
  State<GradPageLayout> createState() => _GradPageLayoutState();
}

class _GradPageLayoutState extends State<GradPageLayout> {
  late GradTheme _t;

  @override
  void initState() {
    super.initState();
    _t = gradThemeFromData(widget.data);
  }

  @override
  void didUpdateWidget(GradPageLayout old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _t = gradThemeFromData(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p1   = widget.pageNum == 1;
    final t    = _t;
    final data = widget.data;
    final imgPx = _gradImgPxLayout(data.imageSize);

    // RepaintBoundary isolates each page from parent scroll/touch repaints.
    return RepaintBoundary(
      child: SizedBox(
        width:  kGradPageW,
        height: kGradPageH,
        child: Stack(children: [
          Positioned.fill(child: const ColoredBox(color: kGradBg)),

          Positioned.fill(
            bottom: kGradFooterH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (p1) _GradHeader(data: data, t: t, imgPx: imgPx),
                // FIX: replace LayoutBuilder with _PageBody using fixed constants.
                // LayoutBuilder re-fires on every layout pass (scroll, touch) —
                // unnecessary since page geometry is fully determined by constants.
                Expanded(
                  child: _PageBody(
                    data:      data,
                    mainItems: widget.mainItems,
                    sideItems: widget.sideItems,
                    t:         t,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0, height: kGradFooterH,
            child: Container(
              color: kGradBg,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Container(height: 0.5, color: kGradDivider)),
                  const SizedBox(width: 8),
                  Text('${widget.pageNum} / ${widget.totalPages}',
                      style: TextStyle(
                          fontSize: 8, color: kGradLightMuted,
                          fontFamily: t.font, letterSpacing: 1.0)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// Two-column body using fixed constants — no LayoutBuilder needed.
class _PageBody extends StatelessWidget {
  final CVTemplateData data;
  final List<GradItem> mainItems;
  final List<GradItem> sideItems;
  final GradTheme      t;

  const _PageBody({
    required this.data,
    required this.mainItems,
    required this.sideItems,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main column (left)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: kGradMainPadH,
                vertical:   kGradMainPadV),
            child: SizedBox(
              width: kGradMainW,
              child: ClipRect(
                child: _MainCol(data: data, items: mainItems, t: t),
              ),
            ),
          ),
        ),
        Container(width: kGradDividerW, color: kGradDivider),
        // Side column (right)
        SizedBox(
          width: kGradSideBarW,
          child: ColoredBox(
            color: kGradSideBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kGradSidePadH,
                  vertical:   kGradSidePadV),
              child: SizedBox(
                width: kGradSideW,
                child: ClipRect(
                  child: _SideCol(data: data, items: sideItems, t: t),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gradient header ───────────────────────────────────────────────────────────
class _GradHeader extends StatelessWidget {
  final CVTemplateData data;
  final GradTheme      t;
  final double         imgPx;
  const _GradHeader({required this.data, required this.t, required this.imgPx});

  @override
  Widget build(BuildContext context) {
    final initials = data.fullName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();
    final initialsFontSize = (imgPx * 0.30).clamp(10.0, 32.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: kGradHeaderColors,
          begin:  Alignment.centerLeft,
          end:    Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // FIX: avatar uses imgPx from data.imageSize, not fontScale
          data.profileImagePath != null
              ? data.buildProfileImage(
                  size: imgPx,
                  borderColor: Colors.white.withOpacity(0.7),
                  borderWidth: 2,
                  placeholderBg: Colors.white.withOpacity(0.15),
                )
              : Container(
                  width: imgPx, height: imgPx,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.6), width: 2),
                  ),
                  child: Center(child: Text(initials, style: TextStyle(
                      fontSize: initialsFontSize, color: Colors.white,
                      fontWeight: FontWeight.w300, fontFamily: t.font))),
                ),
          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.fullName, style: TextStyle(
                    fontSize: t.fs(20), fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: t.font,
                    letterSpacing: 0.3),
                  softWrap: true, overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(data.jobTitle, style: TextStyle(
                      fontSize: t.fs(9.5), color: Colors.white,
                      fontFamily: t.font, letterSpacing: 0.5),
                    softWrap: true, overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 14, runSpacing: 4, children: [
                  if (data.email.isNotEmpty)
                    _ContactChip(icon: Icons.email_outlined,
                        text: data.email, t: t),
                  if (data.phone.isNotEmpty)
                    _ContactChip(icon: Icons.phone_outlined,
                        text: data.phone, t: t),
                  if (data.location.isNotEmpty)
                    _ContactChip(icon: Icons.location_on_outlined,
                        text: data.location, t: t),
                  if (data.website.isNotEmpty)
                    _ContactChip(icon: Icons.link_outlined,
                        text: data.website, t: t),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData  icon;
  final String    text;
  final GradTheme t;
  const _ContactChip(
      {required this.icon, required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: Colors.white.withOpacity(0.85)),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(
          fontSize: t.fs(9), color: Colors.white.withOpacity(0.9),
          fontFamily: t.font)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN COLUMN
// ─────────────────────────────────────────────────────────────────────────────
class _MainCol extends StatelessWidget {
  final CVTemplateData data;
  final List<GradItem> items;
  final GradTheme      t;
  const _MainCol({required this.data, required this.items, required this.t});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: _buildItems(),
  );

  List<Widget> _buildItems() {
    final ws = <Widget>[];
    for (final it in items) {
      if (it.showLabel) {
        if (ws.isNotEmpty) ws.add(const SizedBox(height: 14));
        ws.add(_SecLabel(label: _mainLbl(it.section), t: t));
        ws.add(const SizedBox(height: 8));
      }
      ws.add(_block(it));
    }
    return ws;
  }

  Widget _block(GradItem it) => switch (it.section) {
    GradSection.summary       => _SumBlock(text: data.summary, t: t),
    GradSection.experience    => _ExpBlock(e: data.experience[it.index], t: t),
    GradSection.education     => _EduBlock(e: data.education[it.index], t: t),
    GradSection.certification => _CertMainBlock(s: data.certifications[it.index], t: t),
    _ => const SizedBox.shrink(),
  };

  String _mainLbl(GradSection s) => switch (s) {
    GradSection.summary       => 'ABOUT ME',
    GradSection.experience    => 'EXPERIENCE',
    GradSection.education     => 'EDUCATION',
    GradSection.certification => 'CERTIFICATIONS',
    _                         => 'SECTION',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDE COLUMN
// ─────────────────────────────────────────────────────────────────────────────
class _SideCol extends StatelessWidget {
  final CVTemplateData data;
  final List<GradItem> items;
  final GradTheme      t;
  const _SideCol({required this.data, required this.items, required this.t});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: _buildItems(),
  );

  List<Widget> _buildItems() {
    final ws = <Widget>[];
    for (final it in items) {
      if (it.showLabel) {
        if (ws.isNotEmpty) ws.add(const SizedBox(height: 12));
        ws.add(_SecLabel(label: _sideLbl(it.section), t: t));
        ws.add(const SizedBox(height: 8));
      }
      ws.add(_block(it));
    }
    return ws;
  }

  Widget _block(GradItem it) => switch (it.section) {
    GradSection.skill         => _SkillBlock(s: data.skills[it.index], t: t),
    GradSection.language      => _LangBlock(text: data.languages[it.index], t: t),
    GradSection.hobby         => _LangBlock(text: data.hobbies[it.index], t: t),
    GradSection.certification => _CertSideBlock(s: data.certifications[it.index], t: t),
    GradSection.reference     => _RefBlock(r: data.references[it.index], t: t),
    _ => const SizedBox.shrink(),
  };

  String _sideLbl(GradSection s) => switch (s) {
    GradSection.skill         => 'SKILLS',
    GradSection.language      => 'LANGUAGES',
    GradSection.hobby         => 'HOBBIES',
    GradSection.certification => 'CERTIFICATIONS',
    GradSection.reference     => 'PERSONAL REFERENCES',
    _                         => 'SECTION',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SecLabel extends StatelessWidget {
  final String    label;
  final GradTheme t;
  const _SecLabel({required this.label, required this.t});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 3, height: 16,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: kGradBarColors,
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 7),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(label, style: TextStyle(
              fontSize: t.fs(9.5), fontWeight: FontWeight.w700,
              color: kGradText, letterSpacing: 1.2,
              fontFamily: t.font)),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCKS — MAIN
// ─────────────────────────────────────────────────────────────────────────────
class _SumBlock extends StatelessWidget {
  final String    text;
  final GradTheme t;
  const _SumBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: TextStyle(
        fontSize: t.fs(9.5), color: kGradMuted,
        height: 1.65, fontFamily: t.font),
      softWrap: true, overflow: TextOverflow.visible,
    ),
  );
}

class _ExpBlock extends StatelessWidget {
  final CVTemplateExperience e;
  final GradTheme            t;
  const _ExpBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kGradBg,
        border: Border.all(color: kGradDivider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(e.role, style: TextStyle(
                fontSize: t.fs(11), fontWeight: FontWeight.w700,
                color: kGradText, fontFamily: t.font),
              softWrap: true, overflow: TextOverflow.visible,
            )),
            const SizedBox(width: 6),
            Text(e.duration, style: TextStyle(
                fontSize: t.fs(9), color: kGradLightMuted,
                fontFamily: t.font)),
          ]),
          const SizedBox(height: 2),
          Text(e.company, style: TextStyle(
              fontSize: t.fs(10), color: kGradAccentTeal,
              fontWeight: FontWeight.w600, fontFamily: t.font),
            softWrap: true, overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 5),
          ...e.bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 7),
                child: Container(width: 5, height: 5,
                    decoration: const BoxDecoration(
                        color: kGradAccentPurple, shape: BoxShape.circle)),
              ),
              Expanded(child: Text(b, style: TextStyle(
                  fontSize: t.fs(9.5), color: kGradMuted,
                  height: 1.5, fontFamily: t.font),
                softWrap: true, overflow: TextOverflow.visible,
              )),
            ]),
          )),
        ],
      ),
    ),
  );
}

class _EduBlock extends StatelessWidget {
  final CVTemplateEducation e;
  final GradTheme           t;
  const _EduBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: kGradBarColors,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(child: Text(
          e.period.length >= 4
              ? e.period.substring(e.period.length - 2) : e.period,
          style: TextStyle(fontSize: t.fs(9.5), color: Colors.white,
              fontWeight: FontWeight.w700, fontFamily: t.font),
        )),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.degree, style: TextStyle(
              fontSize: t.fs(10.5), fontWeight: FontWeight.w700,
              color: kGradText, fontFamily: t.font),
            softWrap: true, overflow: TextOverflow.visible,
          ),
          Text(e.institution, style: TextStyle(
              fontSize: t.fs(9.5), color: kGradMuted, fontFamily: t.font),
            softWrap: true, overflow: TextOverflow.visible,
          ),
          if (e.detail != null && e.detail!.isNotEmpty)
            Text(e.detail!, style: TextStyle(
                fontSize: t.fs(9), color: kGradAccentTeal, fontFamily: t.font),
              softWrap: true, overflow: TextOverflow.visible,
            ),
        ],
      )),
    ]),
  );
}

class _CertMainBlock extends StatelessWidget {
  final String    s;
  final GradTheme t;
  const _CertMainBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 5, right: 7),
        child: Container(width: 5, height: 5,
            decoration: const BoxDecoration(
                color: kGradAccentPurple, shape: BoxShape.circle)),
      ),
      Expanded(child: Text(s, style: TextStyle(
          fontSize: t.fs(9.5), color: kGradMuted,
          height: 1.4, fontFamily: t.font),
        softWrap: true, overflow: TextOverflow.visible,
      )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCKS — SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────

// FIX: LayoutBuilder replaces Flexible+SizedBox.expand() to prevent
// infinite-width layout errors. The bar uses exact pixel widths.
class _SkillBlock extends StatelessWidget {
  final CVTemplateSkill s;
  final GradTheme       t;
  const _SkillBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(child: Text(s.name, style: TextStyle(
              fontSize: t.fs(9.5), color: kGradText,
              fontWeight: FontWeight.w500, fontFamily: t.font),
            softWrap: true, overflow: TextOverflow.visible,
          )),
          Text('${s.levelOutOf10 * 10}%', style: TextStyle(
              fontSize: t.fs(9), color: kGradLightMuted, fontFamily: t.font)),
        ]),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (ctx, bc) {
          final totalW = bc.maxWidth.isInfinite ? kGradSideW : bc.maxWidth;
          final fillW  = totalW * s.levelOutOf10 / 10;
          return ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5, width: totalW,
              child: Row(children: [
                Container(
                  width: fillW, height: 5,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: kGradBarColors)),
                ),
                Container(width: totalW - fillW, height: 5, color: kGradBarBg),
              ]),
            ),
          );
        }),
      ],
    ),
  );
}

// FIX: Flexible → Expanded + softWrap so long language/hobby text wraps.
class _LangBlock extends StatelessWidget {
  final String    text;
  final GradTheme t;
  const _LangBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Container(width: 6, height: 6,
            decoration: const BoxDecoration(
                color: kGradAccentTeal, shape: BoxShape.circle)),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(
          fontSize: t.fs(9.5), color: kGradMuted, fontFamily: t.font),
        softWrap: true, overflow: TextOverflow.visible,
      )),
    ]),
  );
}

class _CertSideBlock extends StatelessWidget {
  final String    s;
  final GradTheme t;
  const _CertSideBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: kGradTagBg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(s, style: TextStyle(
        fontSize: t.fs(9.5), color: kGradMuted,
        height: 1.4, fontFamily: t.font),
      softWrap: true, overflow: TextOverflow.visible,
    ),
  );
}

// FIX: email/phone changed from ellipsis to softWrap+visible so long
// addresses wrap onto the next line instead of being cut off.
class _RefBlock extends StatelessWidget {
  final CVTemplateReferee r;
  final GradTheme         t;
  const _RefBlock({required this.r, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(r.name, style: TextStyle(
            fontSize: t.fs(10), fontWeight: FontWeight.w700,
            color: kGradText, fontFamily: t.font),
          softWrap: true, overflow: TextOverflow.visible,
        ),
        const SizedBox(height: 2),
        Text(r.title, style: TextStyle(
            fontSize: t.fs(9.5), color: kGradAccentTeal,
            fontWeight: FontWeight.w600, fontFamily: t.font),
          softWrap: true, overflow: TextOverflow.visible,
        ),
        if (r.company != null && r.company!.isNotEmpty)
          Text(r.company!, style: TextStyle(
              fontSize: t.fs(9), color: kGradLightMuted, fontFamily: t.font),
            softWrap: true, overflow: TextOverflow.visible,
          ),
        const SizedBox(height: 4),
        if (r.email.isNotEmpty) Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(width: 5, height: 5,
                  decoration: const BoxDecoration(
                      color: kGradAccentTeal, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(r.email, style: TextStyle(
                fontSize: t.fs(9), color: kGradMuted,
                fontFamily: t.font, height: 1.35),
              softWrap: true, overflow: TextOverflow.visible,
            )),
          ]),
        ),
        if (r.phone.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(width: 5, height: 5,
                decoration: const BoxDecoration(
                    color: kGradAccentTeal, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(r.phone, style: TextStyle(
              fontSize: t.fs(9), color: kGradMuted,
              fontFamily: t.font, height: 1.35),
            softWrap: true, overflow: TextOverflow.visible,
          )),
        ]),
      ],
    ),
  );
}