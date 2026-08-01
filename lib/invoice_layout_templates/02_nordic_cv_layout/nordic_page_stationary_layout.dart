// nordic_page_stationary_layout.dart
// lib/cv_layout_templates/02_nordic_cv_layout/nordic_page_stationary_layout.dart

import 'package:flutter/material.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'nordic_cv_logic_data.dart';

// ── Page geometry ─────────────────────────────────────────────────────────────
const double kPageW        = 595.0;
const double kPageH        = 842.0;
const double kPadH         = 36.0;
const double kInnerW       = kPageW - kPadH * 2;
const double kColGap       = 20.0;
const double kSideFrac     = 0.295;
const double kSideW        = kInnerW * kSideFrac;
const double kMainW        = kInnerW - kSideW - kColGap;

const double kHdr1H        = 155.0;
const double kHdrNH        =  52.0;
const double kFooterZoneH  =  26.0;
const double kFooterInsetB =  12.0;
const double kColTopGap    =  12.0;

// FIX: kClipInset removed — columns now use plain Column (like Vibrant)
// instead of OverflowBox, so there is nothing to clip-inset against.
// kClipInset is kept as 0 for any code that still references it.
const double kClipInset    =   0.0;

// Safety margin subtracted from the paginator budget — mirrors Vibrant's
// _kSafetyMargin (4.0) + an extra 4 px to absorb sub-pixel rounding.
const double kSafetyMargin =   8.0;

double pageBodyH(bool isPage1) =>
    kPageH - (isPage1 ? kHdr1H : kHdrNH) - kFooterZoneH;

// Used by the paginator — available height for content after top gap + safety.
double pageUsableH(bool isPage1) =>
    pageBodyH(isPage1) - kColTopGap - kSafetyMargin;

// ── Palette ───────────────────────────────────────────────────────────────────
const Color  kBlue  = Color(0xFF2563EB);
const Color  kInk   = Color(0xFF111111);
const Color  kMuted = Color(0xFF888888);
const Color  kRule  = Color(0xFFE0E0E0);
const Color  kSegBg = Color(0xFFE8E8E8);
const double kBase  = 12.0;

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: NordicPageLayout
// ─────────────────────────────────────────────────────────────────────────────

class NordicPageLayout extends StatelessWidget {
  final CVTemplateData   data;
  final List<NordicItem> mainItems;
  final List<NordicItem> sideItems;
  final int  pageNum;
  final int  totalPages;

  const NordicPageLayout({
    super.key,
    required this.data,
    required this.mainItems,
    required this.sideItems,
    required this.pageNum,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final p1  = pageNum == 1;
    final hH  = p1 ? kHdr1H : kHdrNH;
    final bH  = pageBodyH(p1);
    final sc  = data.fontSize / kBase;
    final ac  = data.accentColor;

    return SizedBox(
      width: kPageW,
      height: kPageH,
      child: ClipRect(
        child: Stack(
          children: [

            const Positioned.fill(child: ColoredBox(color: Colors.white)),

            // ── Header ────────────────────────────────────────────────────
            Positioned(
              top: 0, left: kPadH, right: kPadH, height: hH,
              child: ClipRect(
                child: p1
                    ? _Page1Header(data: data, sc: sc, ac: ac)
                    : _CompactHeader(data: data, sc: sc),
              ),
            ),

            // ── Main column ───────────────────────────────────────────────
            // FIX: ClipRect with plain Column — identical approach to Vibrant.
            // OverflowBox was causing horizontal text clipping because it
            // escaped the ClipRect boundary. Plain Column stays inside it.
            Positioned(
              top: hH, left: kPadH, width: kMainW, height: bH,
              child: ClipRect(
                child: _ContentCol(
                  data: data, items: mainItems, sc: sc,
                  colW: kMainW, isMain: true,
                ),
              ),
            ),

            // ── Side column ───────────────────────────────────────────────
            Positioned(
              top: hH, right: kPadH, width: kSideW, height: bH,
              child: ClipRect(
                child: _ContentCol(
                  data: data, items: sideItems, sc: sc,
                  colW: kSideW, isMain: false,
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            Positioned(
              bottom: 0, left: kPadH, right: kPadH, height: kFooterZoneH,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: kFooterInsetB),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: Container(height: 0.5, color: kRule)),
                      const SizedBox(width: 8),
                      Text(
                        '$pageNum / $totalPages',
                        style: const TextStyle(
                            fontSize: 8.5, color: kMuted, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADERS
// ─────────────────────────────────────────────────────────────────────────────

class _Page1Header extends StatelessWidget {
  final CVTemplateData data;
  final double sc;
  final Color ac;
  const _Page1Header({required this.data, required this.sc, required this.ac});

  @override
  Widget build(BuildContext context) {
    const double contactColW = kInnerW * 0.38;
    final nameFz = sc > 1.15
        ? (22 * sc).clamp(0.0, 28.0)
        : (26 * sc).clamp(0.0, 32.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.fullName,
                  style: TextStyle(fontSize: nameFz, fontWeight: FontWeight.w300,
                      color: kInk, height: 1.15, fontFamily: data.fontFamily),
                  softWrap: true, maxLines: 2, overflow: TextOverflow.clip),
                SizedBox(height: 4 * sc),
                Text(data.jobTitle,
                  style: TextStyle(fontSize: 11.5 * sc, color: ac,
                      fontWeight: FontWeight.w500, fontFamily: data.fontFamily),
                  softWrap: true, maxLines: 2, overflow: TextOverflow.clip),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: contactColW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: data.contactLines.map((l) => Text(l,
                style: TextStyle(fontSize: 9 * sc, color: kMuted,
                    fontFamily: data.fontFamily),
                textAlign: TextAlign.start, softWrap: true,
                maxLines: 2, overflow: TextOverflow.ellipsis)).toList(),
            ),
          ),
        ]),
        SizedBox(height: 10 * sc),
        Container(height: 0.5, color: kRule),
        SizedBox(height: 8 * sc),
      ],
    );
  }
}

class _CompactHeader extends StatelessWidget {
  final CVTemplateData data; final double sc;
  const _CompactHeader({required this.data, required this.sc});

  @override
  Widget build(BuildContext context) {
    final nameFz = (15 * sc).clamp(0.0, 18.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(data.fullName,
                style: TextStyle(fontSize: nameFz, fontWeight: FontWeight.w300,
                    color: kInk, fontFamily: data.fontFamily),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 12),
            Text(data.jobTitle,
                style: TextStyle(fontSize: (9 * sc).clamp(0.0, 11.0),
                    color: data.accentColor, fontWeight: FontWeight.w500,
                    fontFamily: data.fontFamily),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        SizedBox(height: 6 * sc),
        Container(height: 0.5, color: kRule),
        SizedBox(height: 8 * sc),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT COLUMN
// FIX: Uses plain Column (not OverflowBox) — identical to Vibrant's approach.
// OverflowBox caused horizontal text clipping: text that wrapped beyond
// the OverflowBox's unconstrained width would escape the parent ClipRect.
// Plain Column respects the Positioned width constraint, so text wraps
// correctly within the column bounds and is never clipped horizontally.
// ─────────────────────────────────────────────────────────────────────────────

class _ContentCol extends StatelessWidget {
  final CVTemplateData   data;
  final List<NordicItem> items;
  final double           sc;
  final double           colW;
  final bool             isMain;
  const _ContentCol({required this.data, required this.items,
      required this.sc, required this.colW, required this.isMain});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final ws = <Widget>[const SizedBox(height: kColTopGap)];
    for (final it in items) {
      if (it.showLabel) {
        ws.add(_Lbl(
          text:       _lbl(it.section),
          sc:         sc,
          fontFamily: data.fontFamily,
          cont:       it.isContinued,
        ));
      }
      ws.add(_block(it));
    }

    // Plain Column — same as Vibrant. Width is already constrained by the
    // parent Positioned widget, so text wraps within colW correctly.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ws,
    );
  }

  Widget _block(NordicItem it) => switch (it.section) {
    NordicSection.summary       => _Sum(text: data.summary,                        sc: sc, fontFamily: data.fontFamily),
    NordicSection.experience    => _Exp(e: data.experience[it.index],              sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    NordicSection.education     => _Edu(e: data.education[it.index],               sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    NordicSection.certification => _Cert(s: data.certifications[it.index],         sc: sc, c: data.accentColor, fontFamily: data.fontFamily),
    NordicSection.skill         => _Skill(s: data.skills[it.index],                sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    NordicSection.language      => _Simple(t: data.languages[it.index],            sc: sc, fontFamily: data.fontFamily, colW: colW),
    NordicSection.hobby         => _Simple(t: data.hobbies[it.index],              sc: sc, fontFamily: data.fontFamily, colW: colW),
    NordicSection.reference     => _Ref(r: data.references[it.index],              sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
  };

  String _lbl(NordicSection s) => switch (s) {
    NordicSection.summary       => 'ABOUT',
    NordicSection.experience    => 'EXPERIENCE',
    NordicSection.education     => 'EDUCATION',
    NordicSection.certification => 'CERTIFICATIONS',
    NordicSection.skill         => 'SKILLS',
    NordicSection.language      => 'LANGUAGES',
    NordicSection.hobby         => 'HOBBIES',
    NordicSection.reference     => 'REFERENCES',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCKS
// ─────────────────────────────────────────────────────────────────────────────

class _Lbl extends StatelessWidget {
  final String text; final double sc; final bool cont; final String fontFamily;
  const _Lbl({required this.text, required this.sc,
      this.cont = false, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 7 * sc),
    child: Text(cont ? '$text (CONT.)' : text,
        style: TextStyle(fontSize: 8 * sc, fontWeight: FontWeight.w700,
            color: kInk, letterSpacing: 2.2, fontFamily: fontFamily),
        softWrap: true, overflow: TextOverflow.visible));
}

class _Sum extends StatelessWidget {
  final String text; final double sc; final String fontFamily;
  const _Sum({required this.text, required this.sc, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 14 * sc),
    child: Text(text, style: TextStyle(fontSize: 10 * sc, color: kMuted,
        height: 1.65, fontFamily: fontFamily),
        softWrap: true, overflow: TextOverflow.visible));
}

class _Exp extends StatelessWidget {
  final CVTemplateExperience e; final double sc; final Color ac; final String fontFamily;
  const _Exp({required this.e, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 13 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(e.company, style: TextStyle(fontSize: 11 * sc,
            fontWeight: FontWeight.w600, color: kInk, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible)),
        const SizedBox(width: 6),
        Text(e.duration, style: TextStyle(fontSize: 9 * sc,
            color: kMuted, fontFamily: fontFamily),
            softWrap: false, overflow: TextOverflow.ellipsis),
      ]),
      SizedBox(height: 1.5 * sc),
      Text(e.role, style: TextStyle(fontSize: 10 * sc,
          color: kMuted, fontWeight: FontWeight.w500, fontFamily: fontFamily),
          softWrap: true, overflow: TextOverflow.visible),
      if (e.location.isNotEmpty)
        Text(e.location, style: TextStyle(fontSize: 8.5 * sc,
            color: kMuted, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible),
      SizedBox(height: 4 * sc),
      ...e.bullets.take(8).map((b) => Padding(
        padding: EdgeInsets.only(bottom: 3 * sc),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.only(top: 4.5 * sc),
              child: Container(width: 3.5 * sc, height: 3.5 * sc,
                  decoration: BoxDecoration(color: ac, shape: BoxShape.circle))),
          SizedBox(width: 5 * sc),
          Expanded(child: Text(b, style: TextStyle(fontSize: 9 * sc,
              color: kInk, height: 1.4, fontFamily: fontFamily),
              softWrap: true, overflow: TextOverflow.visible)),
        ]),
      )),
    ]));
}

class _Edu extends StatelessWidget {
  final CVTemplateEducation e; final double sc; final Color ac; final String fontFamily;
  const _Edu({required this.e, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 11 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(e.degree, style: TextStyle(fontSize: 10.5 * sc,
            fontWeight: FontWeight.w600, color: kInk, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible)),
        SizedBox(width: 5 * sc),
        Text(e.period, style: TextStyle(fontSize: 9 * sc,
            color: kMuted, fontFamily: fontFamily),
            softWrap: false, overflow: TextOverflow.ellipsis),
      ]),
      Text(e.institution, style: TextStyle(fontSize: 10 * sc, color: kMuted,
          fontWeight: FontWeight.w500, fontFamily: fontFamily),
          softWrap: true, overflow: TextOverflow.visible),
      if (e.detail != null && e.detail!.isNotEmpty)
        Padding(padding: EdgeInsets.only(top: 2 * sc),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: EdgeInsets.only(top: 4 * sc),
                child: Container(width: 3.5 * sc, height: 3.5 * sc,
                    decoration: BoxDecoration(color: ac, shape: BoxShape.circle))),
            SizedBox(width: 5 * sc),
            Expanded(child: Text(e.detail!, style: TextStyle(fontSize: 9 * sc,
                color: kInk, height: 1.4, fontFamily: fontFamily),
                softWrap: true, overflow: TextOverflow.visible)),
          ])),
    ]));
}

class _Cert extends StatelessWidget {
  final String s; final double sc; final Color c; final String fontFamily;
  const _Cert({required this.s, required this.sc, required this.c, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) {
    final p    = s.split(RegExp(r'\s+·\s+'));
    final name = p.isNotEmpty ? p[0].trim() : s;
    final by   = p.length > 1 ? p[1].trim() : '';
    final desc = p.length > 2 ? p.sublist(2).join(' · ').trim() : '';
    return Padding(padding: EdgeInsets.only(bottom: 8 * sc),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.only(top: 4 * sc),
              child: Container(width: 3.5 * sc, height: 3.5 * sc,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle))),
          SizedBox(width: 5 * sc),
          Expanded(child: Text(name, style: TextStyle(fontSize: 9.5 * sc,
              color: kInk, height: 1.3, fontFamily: fontFamily),
              softWrap: true, overflow: TextOverflow.visible)),
        ]),
        if (by.isNotEmpty)
          Padding(padding: EdgeInsets.only(left: 8.5 * sc),
            child: Text(by, style: TextStyle(fontSize: 8.5 * sc, color: kMuted,
                fontWeight: FontWeight.w500, height: 1.3, fontFamily: fontFamily),
                softWrap: true, overflow: TextOverflow.visible)),
        if (desc.isNotEmpty)
          Padding(padding: EdgeInsets.only(left: 8.5 * sc),
            child: Text(desc, style: TextStyle(fontSize: 8.5 * sc, color: kMuted,
                fontStyle: FontStyle.italic, height: 1.3, fontFamily: fontFamily),
                softWrap: true, overflow: TextOverflow.visible)),
      ]));
  }
}

class _Skill extends StatelessWidget {
  final CVTemplateSkill s; final double sc; final Color ac; final String fontFamily;
  const _Skill({required this.s, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 8 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: Text(s.name, style: TextStyle(fontSize: 10 * sc,
            color: kInk, fontWeight: FontWeight.w500, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible)),
        SizedBox(width: 4 * sc),
        Text(s.percentLabel, style: TextStyle(fontSize: 8.5 * sc,
            color: kMuted, fontFamily: fontFamily)),
      ]),
      SizedBox(height: 3.5 * sc),
      LayoutBuilder(builder: (_, c) {
        const n = 10;
        final gap = 2.5 * sc;
        final sw = (c.maxWidth - gap * (n - 1)) / n;
        if (sw <= 0) return const SizedBox.shrink();
        return Row(children: List.generate(n, (i) => Container(
          margin: i < n - 1 ? EdgeInsets.only(right: gap) : EdgeInsets.zero,
          width: sw, height: 4 * sc,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2 * sc),
            color: i < s.levelOutOf10 ? ac : kSegBg,
          ),
        )));
      }),
    ]));
}

class _Simple extends StatelessWidget {
  final String t; final double sc; final String fontFamily; final double colW;
  const _Simple({required this.t, required this.sc,
      required this.fontFamily, required this.colW});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 5 * sc),
    child: Text(t, style: TextStyle(fontSize: 10 * sc, color: kMuted,
        height: 1.35, fontFamily: fontFamily),
        softWrap: true, overflow: TextOverflow.visible));
}

class _Ref extends StatelessWidget {
  final CVTemplateReferee r; final double sc; final Color ac; final String fontFamily;
  const _Ref({required this.r, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 11 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(r.name, style: TextStyle(fontSize: 10 * sc,
          fontWeight: FontWeight.w600, color: kInk, fontFamily: fontFamily),
          softWrap: true, overflow: TextOverflow.visible),
      SizedBox(height: sc),
      Text(r.title, style: TextStyle(fontSize: 9.5 * sc,
          color: ac, fontWeight: FontWeight.w500, fontFamily: fontFamily),
          softWrap: true, overflow: TextOverflow.visible),
      if (r.company != null && r.company!.isNotEmpty)
        Text(r.company!, style: TextStyle(fontSize: 9 * sc, color: kMuted,
            fontFamily: fontFamily), softWrap: true, overflow: TextOverflow.visible),
      SizedBox(height: 3 * sc),
      if (r.email.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(padding: EdgeInsets.only(top: 1.5 * sc),
          child: Icon(Icons.email_outlined, size: 8.5 * sc, color: kMuted)),
        SizedBox(width: 3 * sc),
        Expanded(child: Text(r.email, style: TextStyle(fontSize: 8.5 * sc,
            color: kMuted, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible)),
      ]),
      if (r.phone.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(padding: EdgeInsets.only(top: 1.5 * sc),
          child: Icon(Icons.phone_outlined, size: 8.5 * sc, color: kMuted)),
        SizedBox(width: 3 * sc),
        Expanded(child: Text(r.phone, style: TextStyle(fontSize: 8.5 * sc,
            color: kMuted, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible)),
      ]),
    ]));
}