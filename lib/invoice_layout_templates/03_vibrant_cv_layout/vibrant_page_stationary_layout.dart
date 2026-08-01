// vibrant_page_stationary_layout.dart
// lib/cv_layout_templates/03_vibrant_cv_layout/vibrant_page_stationary_layout.dart
//
// Single A4 page renderer. NO state, NO pagination, NO measurement.
//
// FOOTER IS ALWAYS STATIONARY:
//   Positioned(bottom: 0, height: kFooterZoneH)
//   It is a Stack sibling of the content zones — content can never push it.
//
// Zone map (all Positioned inside SizedBox 595×842):
//   A: top:0              height:hdr1H(sc,imgSz) or kHdrNH   ← coral header band
//   B: top:hH  left       height:bodyH  width:kMainW          ← white main column
//   C: top:hH  right      height:bodyH  width:kSideW          ← pale sidebar
//   D: bottom:0           height:kFooterZoneH(26)             ← NEVER MOVES

import 'package:flutter/material.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'vibrant_cv_logic_data.dart';

// ── Page geometry ─────────────────────────────────────────────────────────────
const double kPageW        = 595.0;
const double kPageH        = 842.0;
const double kPadH         = 28.0;   // horizontal page padding
const double kBodyPadV     = 16.0;   // top padding for body columns (reduced)
const double kInnerW       = kPageW - kPadH * 2;     // 539
const double kColGap       = 16.0;
const double kSideFrac     = 0.295;
const double kSideW        = kInnerW * kSideFrac;     // ≈159
const double kMainW        = kInnerW - kSideW - kColGap; // ≈364

// ── Image size constants ──────────────────────────────────────────────────────
// imageSize from CVData is in the range 10–16. We map it to a pixel size
// independently of fontSize / sc so the two sliders are decoupled.
const double kImgSizeBase   = 12.0;   // imageSize == 12 → kImgSizePxBase px
const double kImgSizePxBase = 68.0;   // vibrant default avatar diameter

double _imgPx(double imageSize) => kImgSizePxBase * (imageSize / kImgSizeBase);

/// First-page header height — grows with font scale AND image size.
double hdr1H(double sc, double imageSize) {
  // Avatar drives minimum height (diameter + top + bottom padding)
  final fromImage = _imgPx(imageSize) + 14.0 + 14.0;

  // Text column worst-case height (address may wrap to 2 lines)
  final fromText = 14.0                    // top padding (Container)
      + 19.0 * sc * 1.2                    // name text height
      + 4.0  * sc                          // gap
      + (8.5  * sc * 1.2 + 5.0)           // job-title badge
      + 6.0  * sc                          // gap
      + 8.5  * sc * 1.35 * 2              // inline contact row (up to 2 run lines)
      + 4.0  * sc                          // gap
      + 8.5  * sc * 1.4  * 2              // address (up to 2 lines)
      + 14.0;                              // bottom padding

  return (fromImage > fromText ? fromImage : fromText) + 22.0; // safety
}

const double kHdrNH        =  64.0;  // continuation-page compact header
const double kFooterZoneH  =  24.0;
const double kFooterInsetB =  10.0;
const double kSidePadL     =  12.0;  // left inner padding for side column content

/// Available body height for content columns.
double pageBodyH(bool isPage1, double sc, double imageSize) =>
    kPageH
    - (isPage1 ? hdr1H(sc, imageSize) : kHdrNH)
    - kFooterZoneH
    - kBodyPadV;

// ── Palette ───────────────────────────────────────────────────────────────────
const Color  kCoral = Color(0xFFFF5C35);
const Color  kPale  = Color(0xFFFFF1EE);
const Color  kDark  = Color(0xFF1A1A1A);
const Color  kMid   = Color(0xFF555555);
const double kBase  = 12.0;
const Color  kRule  = Color(0xFFF0F0F0);

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: VibrantPageLayout
// ─────────────────────────────────────────────────────────────────────────────

class VibrantPageLayout extends StatelessWidget {
  final CVTemplateData    data;
  final List<VibrantItem> mainItems;
  final List<VibrantItem> sideItems;
  final int  pageNum;
  final int  totalPages;

  const VibrantPageLayout({
    super.key,
    required this.data,
    required this.mainItems,
    required this.sideItems,
    required this.pageNum,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final p1 = pageNum == 1;
    final sc = data.fontSize / kBase;
    final hH = p1 ? hdr1H(sc, data.imageSize) : kHdrNH;
    final bH = pageBodyH(p1, sc, data.imageSize);
    final ac = data.accentColor;

    return SizedBox(
      width: kPageW,
      height: kPageH,
      child: Stack(
        children: [

          // Background
          const Positioned.fill(child: ColoredBox(color: Colors.white)),

          // ── ZONE A: Coral header ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0, height: hH,
            child: ClipRect(
              child: p1
                  ? _Page1Header(data: data, sc: sc, ac: ac)
                  : _CompactHeader(data: data, sc: sc, ac: ac),
            ),
          ),

          // ── ZONE B: Main column (white) ───────────────────────────────────
          Positioned(
            top: hH + kBodyPadV, left: kPadH, width: kMainW, height: bH,
            child: ClipRect(
              child: _ContentCol(
                  data: data, items: mainItems, sc: sc, isMain: true),
            ),
          ),

          // ── ZONE C: Side column (pale) ────────────────────────────────────
          Positioned(
            top: hH, right: 0, width: kSideW + kPadH,
            height: bH + kBodyPadV + kFooterZoneH,
            child: const ColoredBox(color: kPale),
          ),
          Positioned(
            top: hH + kBodyPadV, right: kPadH, width: kSideW, height: bH,
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.only(left: kSidePadL),
                child: _ContentCol(
                    data: data, items: sideItems, sc: sc, isMain: false),
              ),
            ),
          ),

          // ── ZONE D: Footer ────────────────────────────────────────────────
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
                      style: TextStyle(
                          fontSize: 8.0, color: kMid.withOpacity(0.6),
                          letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE A — HEADERS
// ─────────────────────────────────────────────────────────────────────────────

// ── Contact type classifier ───────────────────────────────────────────────────
enum _ContactType { email, phone, website, address }

_ContactType _classifyContact(String text) {
  if (text.contains('@'))                                 return _ContactType.email;
  if (RegExp(r'[\d\+][\d\s\-\(\)]{4,}').hasMatch(text)) return _ContactType.phone;
  if (text.contains('.') && !text.contains(' '))         return _ContactType.website;
  return _ContactType.address;
}

IconData _contactIcon(_ContactType t) => switch (t) {
  _ContactType.email   => Icons.email_outlined,
  _ContactType.phone   => Icons.phone_outlined,
  _ContactType.website => Icons.language_outlined,
  _ContactType.address => Icons.location_on_outlined,
};

class _Page1Header extends StatelessWidget {
  final CVTemplateData data;
  final double sc;
  final Color ac;
  const _Page1Header({required this.data, required this.sc, required this.ac});

  @override
  Widget build(BuildContext context) {
    final lines = data.contactLines;

    final emails    = lines.where((l) => _classifyContact(l) == _ContactType.email).toList();
    final phones    = lines.where((l) => _classifyContact(l) == _ContactType.phone).toList();
    final websites  = lines.where((l) => _classifyContact(l) == _ContactType.website).toList();
    final addresses = lines.where((l) => _classifyContact(l) == _ContactType.address).toList();
    final inlineItems = [...emails, ...phones, ...websites];

    // Image size controlled by imageSize slider, NOT font scale
    final imgPx = _imgPx(data.imageSize);

    return Container(
      color: ac,
      padding: const EdgeInsets.fromLTRB(kPadH, 14, kPadH, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar — sized by imageSize, independent of font scale
          data.buildProfileImage(
            size:          imgPx,
            borderColor:   Colors.white,
            borderWidth:   2.5,
            placeholderBg: Colors.white.withOpacity(0.18),
          ),
          SizedBox(width: 13 * sc),
          // Name / title / contact — must never be clipped, always wrap
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name — wraps if too long, never truncates
                Text(
                  data.fullName,
                  style: TextStyle(
                    fontSize: 19 * sc, fontWeight: FontWeight.w900,
                    color: Colors.white, height: 1.1,
                    fontFamily: data.fontFamily,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                SizedBox(height: 4 * sc),
                // Job title badge — intrinsic width, wraps text
                IntrinsicWidth(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 7 * sc, vertical: 2.5 * sc),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data.jobTitle,
                      style: TextStyle(
                        fontSize: 8.5 * sc, color: ac,
                        fontWeight: FontWeight.w700,
                        fontFamily: data.fontFamily,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
                if (inlineItems.isNotEmpty) ...[
                  SizedBox(height: 6 * sc),
                  // ── Row 1: email + phone + website (wraps naturally) ──────
                  Wrap(
                    spacing: 12 * sc,
                    runSpacing: 3 * sc,
                    children: inlineItems.map((t) {
                      final type = _classifyContact(t);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_contactIcon(type),
                              color: Colors.white60, size: 8.5 * sc),
                          SizedBox(width: 3 * sc),
                          Text(t,
                            style: TextStyle(fontSize: 8.5 * sc,
                                color: Colors.white70,
                                fontFamily: data.fontFamily),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                // ── Row 2: address — wraps across full width ──────────────
                if (addresses.isNotEmpty) ...[
                  SizedBox(height: 4 * sc),
                  ...addresses.map((a) => Padding(
                    padding: EdgeInsets.only(bottom: 2 * sc),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1.5 * sc),
                          child: Icon(Icons.location_on_outlined,
                              color: Colors.white60, size: 8.5 * sc),
                        ),
                        SizedBox(width: 3 * sc),
                        Expanded(
                          child: Text(a,
                            style: TextStyle(fontSize: 8.5 * sc,
                                color: Colors.white70,
                                fontFamily: data.fontFamily,
                                height: 1.4),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  final CVTemplateData data; final double sc; final Color ac;
  const _CompactHeader({required this.data, required this.sc, required this.ac});

  @override
  Widget build(BuildContext context) => Container(
    color: ac,
    constraints: const BoxConstraints(minHeight: kHdrNH),
    padding: EdgeInsets.symmetric(horizontal: kPadH, vertical: 10 * sc),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Name wraps rather than truncates
        Expanded(child: Text(data.fullName,
            style: TextStyle(
                fontSize: 14 * sc, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.2,
                fontFamily: data.fontFamily),
            softWrap: true,
            overflow: TextOverflow.visible)),
        SizedBox(width: 8 * sc),
        // Badge uses Flexible + ConstrainedBox to prevent overflow
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: kMainW * 0.5),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8 * sc, vertical: 3 * sc),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(4 * sc),
              ),
              child: Text(data.jobTitle,
                  style: TextStyle(
                      fontSize: 8.5 * sc, color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: data.fontFamily),
                  softWrap: true,
                  overflow: TextOverflow.visible),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE B / C — CONTENT COLUMN
// ─────────────────────────────────────────────────────────────────────────────

class _ContentCol extends StatelessWidget {
  final CVTemplateData    data;
  final List<VibrantItem> items;
  final double            sc;
  final bool              isMain;
  const _ContentCol({required this.data, required this.items,
      required this.sc, required this.isMain});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final ws = <Widget>[];
    for (final it in items) {
      if (it.showLabel) {
        ws.add(_Lbl(text: _lbl(it.section), sc: sc,
            ac: data.accentColor, fontFamily: data.fontFamily));
      }
      ws.add(_block(it));
    }
    return Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: ws);
  }

  Widget _block(VibrantItem it) => switch (it.section) {
    VibrantSection.summary       => _Sum(text: data.summary, sc: sc, fontFamily: data.fontFamily),
    VibrantSection.experience    => _Exp(e: data.experience[it.index], sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    VibrantSection.education     => _Edu(e: data.education[it.index], displayNum: it.index + 1, sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    VibrantSection.certification => _Cert(s: data.certifications[it.index], sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    VibrantSection.skill         => _Skill(s: data.skills[it.index], sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    VibrantSection.language      => _Simple(t: data.languages[it.index], sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    VibrantSection.hobby         => _Simple(t: data.hobbies[it.index], sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
    VibrantSection.reference     => _Ref(r: data.references[it.index], sc: sc, ac: data.accentColor, fontFamily: data.fontFamily),
  };

  String _lbl(VibrantSection s) => switch (s) {
    VibrantSection.summary       => 'ABOUT ME',
    VibrantSection.experience    => 'WORK EXPERIENCE',
    VibrantSection.education     => 'EDUCATION',
    VibrantSection.certification => 'CERTIFICATIONS',
    VibrantSection.skill         => 'SKILLS',
    VibrantSection.language      => 'LANGUAGES',
    VibrantSection.hobby         => 'HOBBIES',
    VibrantSection.reference     => 'REFERENCES',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCKS
// ─────────────────────────────────────────────────────────────────────────────

class _Lbl extends StatelessWidget {
  final String text; final double sc;
  final Color ac; final String fontFamily;
  // NOTE: isContinued / "cont" removed — section label is always the plain title
  const _Lbl({required this.text, required this.sc,
      required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 8 * sc),
    child: Row(children: [
      Container(
        width: 16 * sc, height: 2.5 * sc,
        decoration: BoxDecoration(
            color: ac, borderRadius: BorderRadius.circular(2 * sc)),
      ),
      SizedBox(width: 8 * sc),
      Expanded(
        child: Text(text,
            style: TextStyle(fontSize: 8.5 * sc, fontWeight: FontWeight.w800,
                color: kDark, letterSpacing: 1.5, fontFamily: fontFamily),
            softWrap: true,
            overflow: TextOverflow.visible),
      ),
    ]),
  );
}

class _Sum extends StatelessWidget {
  final String text; final double sc; final String fontFamily;
  const _Sum({required this.text, required this.sc, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 16 * sc),
    child: Text(text,
        style: TextStyle(fontSize: 10 * sc, color: kMid, height: 1.7,
            fontFamily: fontFamily),
        softWrap: true,
        overflow: TextOverflow.visible),
  );
}

class _Exp extends StatelessWidget {
  final CVTemplateExperience e; final double sc; final Color ac; final String fontFamily;
  const _Exp({required this.e, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 4 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(e.role, style: TextStyle(fontSize: 11 * sc,
            fontWeight: FontWeight.w700, color: kDark, fontFamily: fontFamily),
            softWrap: true,
            overflow: TextOverflow.visible)),
        SizedBox(width: 6 * sc),
        Flexible(
          flex: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 7 * sc, vertical: 2.5 * sc),
            decoration: BoxDecoration(
              color: ac.withOpacity(0.10),
              borderRadius: BorderRadius.circular(4 * sc),
            ),
            child: Text(e.duration, style: TextStyle(fontSize: 8.5 * sc,
                color: ac, fontWeight: FontWeight.w600, fontFamily: fontFamily),
                softWrap: true,
                overflow: TextOverflow.visible),
          ),
        ),
      ]),
      SizedBox(height: 2 * sc),
      Text(e.company, style: TextStyle(fontSize: 10 * sc, color: ac,
          fontWeight: FontWeight.w600, fontFamily: fontFamily),
          softWrap: true,
          overflow: TextOverflow.visible),
      SizedBox(height: 5 * sc),
      ...e.bullets.map((b) => Padding(
        padding: EdgeInsets.only(bottom: 4 * sc),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.only(top: 5 * sc),
            child: Container(width: 4 * sc, height: 4 * sc,
                decoration: BoxDecoration(color: ac, shape: BoxShape.circle))),
          SizedBox(width: 7 * sc),
          Expanded(child: Text(b,
              style: TextStyle(fontSize: 9.5 * sc, color: kMid, height: 1.5,
                  fontFamily: fontFamily),
              softWrap: true,
              overflow: TextOverflow.visible)),
        ]),
      )),
      Divider(color: kRule, thickness: 1, height: 14 * sc),
    ]),
  );
}

class _Edu extends StatelessWidget {
  final CVTemplateEducation e;
  final int    displayNum;
  final double sc;
  final Color  ac;
  final String fontFamily;
  const _Edu({
    required this.e,
    required this.displayNum,
    required this.sc,
    required this.ac,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 12 * sc),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36 * sc, height: 36 * sc,
        decoration: BoxDecoration(
          color: ac.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8 * sc),
        ),
        child: Center(child: Text(
          '$displayNum',
          style: TextStyle(fontSize: 13 * sc, fontWeight: FontWeight.w800,
              color: ac, fontFamily: fontFamily),
        )),
      ),
      SizedBox(width: 10 * sc),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Text(e.degree, style: TextStyle(fontSize: 10.5 * sc,
            fontWeight: FontWeight.w700, color: kDark, fontFamily: fontFamily),
            softWrap: true,
            overflow: TextOverflow.visible),
        SizedBox(height: 2 * sc),
        Text(e.institution, style: TextStyle(fontSize: 10 * sc,
            color: kMid, fontFamily: fontFamily),
            softWrap: true,
            overflow: TextOverflow.visible),
        if (e.detail != null && e.detail!.isNotEmpty) ...[
          SizedBox(height: 2 * sc),
          Text(e.detail!, style: TextStyle(fontSize: 9.5 * sc, color: kDark,
              fontFamily: fontFamily),
              softWrap: true,
              overflow: TextOverflow.visible),
        ],
      ])),
    ]),
  );
}

class _Cert extends StatelessWidget {
  final String s; final double sc; final Color ac; final String fontFamily;
  const _Cert({required this.s, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) {
    final p    = s.split(RegExp(r'\s+·\s+'));
    final name = p.isNotEmpty ? p[0].trim() : s;
    final by   = p.length > 1 ? p[1].trim() : '';
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * sc),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(top: 4.5 * sc),
          child: Container(width: 5 * sc, height: 5 * sc,
              decoration: BoxDecoration(color: ac, shape: BoxShape.circle))),
        SizedBox(width: 7 * sc),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
          Text(name, style: TextStyle(fontSize: 9.5 * sc, color: kDark,
              height: 1.4, fontFamily: fontFamily),
              softWrap: true,
              overflow: TextOverflow.visible),
          if (by.isNotEmpty)
            Text(by, style: TextStyle(fontSize: 9 * sc, color: kMid,
                height: 1.3, fontFamily: fontFamily),
                softWrap: true,
                overflow: TextOverflow.visible),
        ])),
      ]),
    );
  }
}

class _Skill extends StatelessWidget {
  final CVTemplateSkill s; final double sc; final Color ac; final String fontFamily;
  const _Skill({required this.s, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 7 * sc),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10 * sc, vertical: 6 * sc),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * sc),
        border: Border.all(color: ac.withOpacity(0.30)),
      ),
      child: Text(s.name, style: TextStyle(
          fontSize: 10 * sc, color: kDark,
          fontWeight: FontWeight.w500, fontFamily: fontFamily),
          softWrap: true,
          overflow: TextOverflow.visible),
    ),
  );
}

class _Simple extends StatelessWidget {
  final String t; final double sc; final Color ac; final String fontFamily;
  const _Simple({required this.t, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 8 * sc),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(top: 4.5 * sc),
        child: Container(width: 5 * sc, height: 5 * sc,
            decoration: BoxDecoration(color: ac, shape: BoxShape.circle))),
      SizedBox(width: 7 * sc),
      Expanded(child: Text(t,
          style: TextStyle(fontSize: 10 * sc, color: kMid, height: 1.5,
              fontFamily: fontFamily),
          softWrap: true,
          overflow: TextOverflow.visible)),
    ]),
  );
}

class _Ref extends StatelessWidget {
  final CVTemplateReferee r; final double sc; final Color ac; final String fontFamily;
  const _Ref({required this.r, required this.sc, required this.ac, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 10 * sc),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(top: 4.5 * sc),
        child: Container(width: 5 * sc, height: 5 * sc,
            decoration: BoxDecoration(color: ac, shape: BoxShape.circle))),
      SizedBox(width: 7 * sc),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Text(r.name, style: TextStyle(fontSize: 10 * sc,
            fontWeight: FontWeight.w700, color: kDark, fontFamily: fontFamily),
            softWrap: true,
            overflow: TextOverflow.visible),
        SizedBox(height: sc),
        Text(r.title, style: TextStyle(fontSize: 9.5 * sc, color: ac,
            fontWeight: FontWeight.w600, fontFamily: fontFamily),
            softWrap: true,
            overflow: TextOverflow.visible),
        if (r.company != null && r.company!.isNotEmpty) ...[
          SizedBox(height: sc),
          Text(r.company!, style: TextStyle(fontSize: 9 * sc, color: kMid,
              fontFamily: fontFamily),
              softWrap: true,
              overflow: TextOverflow.visible),
        ],
        SizedBox(height: 4 * sc),
        // Fixed icon size (not sc-scaled) to prevent row overflow in narrow side column
        if (r.email.isNotEmpty) Padding(
          padding: EdgeInsets.only(bottom: 2 * sc),
          child: Row(children: [
            const Icon(Icons.email_outlined, size: 9.0, color: Color(0xFF555555)),
            const SizedBox(width: 4),
            Expanded(child: Text(r.email, style: TextStyle(fontSize: 8.5 * sc,
                color: kMid, fontFamily: fontFamily),
                softWrap: true,
                overflow: TextOverflow.visible)),
          ]),
        ),
        if (r.phone.isNotEmpty) Padding(
          padding: EdgeInsets.only(bottom: 2 * sc),
          child: Row(children: [
            const Icon(Icons.phone_outlined, size: 9.0, color: Color(0xFF555555)),
            const SizedBox(width: 4),
            Expanded(child: Text(r.phone, style: TextStyle(fontSize: 8.5 * sc,
                color: kMid, fontFamily: fontFamily),
                softWrap: true,
                overflow: TextOverflow.visible)),
          ]),
        ),
      ])),
    ]),
  );
}