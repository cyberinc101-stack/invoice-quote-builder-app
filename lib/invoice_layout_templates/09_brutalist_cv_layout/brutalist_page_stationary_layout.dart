// brutalist_page_stationary_layout.dart
// lib/cv_layout_templates/09_brutalist_cv_layout/brutalist_page_stationary_layout.dart
//
// Single A4 page renderer. NO state. NO pagination. NO measurement.
//
// ═══════════════════════════════════════════════════════════════
//  OVERFLOW PREVENTION RULES  (do not relax these)
// ═══════════════════════════════════════════════════════════════
//  1. Outer SizedBox(595 × 842) + ClipRect = absolute hard wall.
//  2. Every Positioned zone has an explicit `height:` value.
//  3. Header    → ClipRect + FittedBox on name & title pill.
//  4. Contact   → FittedBox scaleDown — text shrinks to fit, never truncates.
//  5. Body cols → OverflowBox(maxHeight:∞) inside ClipRect.
//               ClipRect clips visually; OverflowBox suppresses
//               the RenderFlex overflow error entirely.
// ═══════════════════════════════════════════════════════════════
//
// Zone map (595 × 842 pts):
//   A  top:0        h: kBrutHdr1H(108) or kBrutHdrNH(48)
//   B  top:hH       h: kBrutContactH(32)            [page 1 only]
//   C  body left:0  w: kBrutSideW(185)              [sidebar]
//   D  body left:185 w: kBrutContentW(410)          [main]
//   E  bottom:0     h: kBrutFooterZoneH(24)         [footer]

import 'package:flutter/material.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'brutalist_cv_logic_data.dart';

// ── Page geometry ────────────────────────────────────────────────────────────
const double kBrutPageW         = 595.0;
const double kBrutPageH         = 842.0;
const double kBrutSideW         = 185.0;
const double kBrutContentW      = kBrutPageW - kBrutSideW;           // 410
const double kBrutHdr1H         = 108.0;
const double kBrutHdrNH         =  48.0;
const double kBrutContactH      =  32.0;
const double kBrutFooterZoneH   =  24.0;
const double kBrutFooterInsetB  =  10.0;
const double kBrutBase          =  12.0;
const double kBrutContentPadH   =  20.0;
const double kBrutColTopGap     =  10.0;
const double kBrutSideInnerW    = kBrutSideW;                            // 185
const double kBrutContentInnerW = kBrutContentW - kBrutContentPadH * 2; // 370
const double kBrutClipInset     =   6.0;

// Image size — slider-controlled, independent of font size
const double kBrutImgSizeBase   = 12.0;
const double kBrutImgPxBase     = 60.0;
double brutImgPx(double s) => kBrutImgPxBase * (s / kBrutImgSizeBase);

// Usable page heights for paginator
double brutPageBodyH(bool isPage1) =>
    kBrutPageH
    - (isPage1 ? kBrutHdr1H + kBrutContactH : kBrutHdrNH)
    - kBrutFooterZoneH;

double brutPageUsableH(bool isPage1) =>
    brutPageBodyH(isPage1) - kBrutColTopGap - kBrutClipInset;

// ── Palette ──────────────────────────────────────────────────────────────────
const Color kBrutBlack  = Color(0xFF000000);
const Color kBrutWhite  = Color(0xFFFFFFFF);
const Color kBrutYellow = Color(0xFFFFE500);
const Color kBrutMuted  = Color(0xFF444444);
const Color kBrutBorder = Color(0xFFD0D0D0);
const Color kBrutLight  = Color(0xFFE0E0E0);
const Color kBrutRowBg  = Color(0xFFF5F5F5);
const Color kBrutRule   = Color(0xFFE0E0E0);
const Color kBrutGrey   = Color(0xFF64748B);
const Color kBrutSubtle = Color(0xFF666666);

Color brutAccent(CVTemplateData d) {
  final v = d.accentColor.value;
  if (v == 0xFFFFFFFF || v == 0x00000000 || v == 0xFF000000) return kBrutYellow;
  return d.accentColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// BrutPageLayout — public root widget
// ─────────────────────────────────────────────────────────────────────────────

class BrutPageLayout extends StatefulWidget {
  final CVTemplateData data;
  final List<BrutItem> mainItems;
  final List<BrutItem> sideItems;
  final int  pageNum;
  final int  totalPages;

  const BrutPageLayout({
    super.key,
    required this.data,
    required this.mainItems,
    required this.sideItems,
    required this.pageNum,
    required this.totalPages,
  });

  @override
  State<BrutPageLayout> createState() => _BrutPageLayoutState();
}

class _BrutPageLayoutState extends State<BrutPageLayout> {
  late double _sc;
  late Color  _ac;

  @override
  void initState() {
    super.initState();
    _sc = widget.data.fontSize / kBrutBase;
    _ac = brutAccent(widget.data);
  }

  @override
  void didUpdateWidget(BrutPageLayout old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _sc = widget.data.fontSize / kBrutBase;
      _ac = brutAccent(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p1      = widget.pageNum == 1;
    final hH      = p1 ? kBrutHdr1H : kBrutHdrNH;
    final bodyTop = p1 ? hH + kBrutContactH : hH;
    final bH      = brutPageBodyH(p1);
    final zoneH   = bH - kBrutClipInset;
    final sc = _sc; final ac = _ac; final data = widget.data;

    return RepaintBoundary(
      child: SizedBox(
        width:  kBrutPageW,
        height: kBrutPageH,
        child: ClipRect(
          child: Stack(children: [

            // White background
            Positioned.fill(child: Container(color: kBrutWhite)),

            // ── ZONE A: Header ──────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0, height: hH,
              child: ClipRect(
                child: p1
                    ? _Brut1Header(data: data, sc: sc, ac: ac)
                    : _BrutNHeader(data: data, sc: sc, ac: ac),
              ),
            ),

            // ── ZONE B: Contact strip (page 1 only) ─────────────────────────
            if (p1)
              Positioned(
                top: hH, left: 0, right: 0, height: kBrutContactH,
                child: _BrutContactRow(data: data, sc: sc),
              ),

            // Sidebar right border
            Positioned(
              top: bodyTop,
              left: kBrutSideW - 3,
              width: 3,
              height: zoneH,
              child: Container(color: kBrutBlack),
            ),

            // ── ZONE C: Sidebar ──────────────────────────────────────────────
            // ClipRect clips visually to zoneH.
            // OverflowBox(maxHeight:∞) lets the Column lay out freely so
            // Flutter never throws a RenderFlex overflow error here.
            Positioned(
              top: bodyTop, left: 0, width: kBrutSideW, height: zoneH,
              child: ClipRect(
                child: OverflowBox(
                  alignment:  Alignment.topLeft,
                  minHeight:  0,
                  maxHeight:  double.infinity,
                  minWidth:   kBrutSideW,
                  maxWidth:   kBrutSideW,
                  child: _BrutSideCol(
                    data: data, items: widget.sideItems,
                    isPage1: p1, sc: sc, ac: ac,
                  ),
                ),
              ),
            ),

            // ── ZONE D: Main content ─────────────────────────────────────────
            Positioned(
              top: bodyTop, left: kBrutSideW, width: kBrutContentW, height: zoneH,
              child: ClipRect(
                child: OverflowBox(
                  alignment:  Alignment.topLeft,
                  minHeight:  0,
                  maxHeight:  double.infinity,
                  minWidth:   kBrutContentW,
                  maxWidth:   kBrutContentW,
                  child: _BrutContentCol(
                    data: data, items: widget.mainItems, sc: sc, ac: ac,
                  ),
                ),
              ),
            ),

            // ── ZONE E: Footer ───────────────────────────────────────────────
            Positioned(
              bottom: 0, left: kBrutContentPadH, right: kBrutContentPadH,
              height: kBrutFooterZoneH,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: kBrutFooterInsetB),
                  child: Row(children: [
                    Expanded(child: Container(height: 0.5, color: kBrutRule)),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.pageNum} / ${widget.totalPages}',
                      style: const TextStyle(
                          fontSize: 8.5, color: kBrutGrey, letterSpacing: 1.0),
                    ),
                  ]),
                ),
              ),
            ),

          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE A — PAGE 1 HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Brut1Header extends StatelessWidget {
  final CVTemplateData data;
  final double sc;
  final Color  ac;
  const _Brut1Header({required this.data, required this.sc, required this.ac});

  @override
  Widget build(BuildContext context) {
    final initials = data.fullName
        .split(' ')
        .where((n) => n.isNotEmpty)
        .map((n) => n[0].toUpperCase())
        .take(2)
        .join();

    final boxPx  = brutImgPx(data.imageSize);
    const hPad   = 20.0;
    const boxGap = 14.0;

    return SizedBox(
      width:  kBrutPageW,
      height: kBrutHdr1H,
      child: Container(
        color: kBrutBlack,
        child: Stack(children: [

          Positioned(
            left:   hPad,
            top:    (kBrutHdr1H - boxPx) / 2.0,
            width:  boxPx,
            height: boxPx,
            child: Container(
              color:     ac,
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                    fontSize:   boxPx * 0.36,
                    fontWeight: FontWeight.w900,
                    color:      kBrutBlack,
                    fontFamily: data.fontFamily),
              ),
            ),
          ),

          Positioned(
            left:   hPad + boxPx + boxGap,
            right:  hPad,
            top:    0,
            bottom: 0,
            child: Column(
              mainAxisAlignment:  MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [

                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit:       BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.fullName.toUpperCase(),
                      maxLines: 1,
                      style: TextStyle(
                          fontSize:      22 * sc,
                          fontWeight:    FontWeight.w900,
                          color:         kBrutWhite,
                          letterSpacing: 0.8,
                          height:        1.1,
                          fontFamily:    data.fontFamily),
                    ),
                  ),
                ),

                SizedBox(height: 6 * sc),

                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit:       BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      color:   ac,
                      padding: EdgeInsets.symmetric(
                          horizontal: 8 * sc, vertical: 3 * sc),
                      child: Text(
                        data.jobTitle.toUpperCase(),
                        maxLines: 1,
                        style: TextStyle(
                            fontSize:      9 * sc,
                            fontWeight:    FontWeight.w900,
                            color:         kBrutBlack,
                            letterSpacing: 1.5,
                            fontFamily:    data.fontFamily),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),

        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE A — PAGE N HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _BrutNHeader extends StatelessWidget {
  final CVTemplateData data;
  final double sc;
  final Color  ac;
  const _BrutNHeader({required this.data, required this.sc, required this.ac});

  @override
  Widget build(BuildContext context) => SizedBox(
    width:  kBrutPageW,
    height: kBrutHdrNH,
    child: Container(
      color:   kBrutBlack,
      padding: EdgeInsets.symmetric(horizontal: 20 * sc, vertical: 8 * sc),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              fit:       BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.fullName.toUpperCase(),
                maxLines: 1,
                style: TextStyle(
                    fontSize:      14 * sc,
                    fontWeight:    FontWeight.w900,
                    color:         kBrutWhite,
                    letterSpacing: 1.0,
                    fontFamily:    data.fontFamily),
              ),
            ),
          ),
          SizedBox(width: 12 * sc),
          Container(
            color:   ac,
            padding: EdgeInsets.symmetric(horizontal: 8 * sc, vertical: 4 * sc),
            child: Text(
              data.jobTitle.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize:      8 * sc,
                  fontWeight:    FontWeight.w900,
                  color:         kBrutBlack,
                  letterSpacing: 1.5,
                  fontFamily:    data.fontFamily),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE B — CONTACT STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _BrutContactRow extends StatelessWidget {
  final CVTemplateData data;
  final double sc;
  const _BrutContactRow({required this.data, required this.sc});

  Widget _cell(String text, {int flex = 1}) => Expanded(
    flex: flex,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 9 * sc),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit:       BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
                fontSize:   9 * sc,
                fontWeight: FontWeight.w600,
                color:      kBrutBlack,
                fontFamily: data.fontFamily),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final website =
        data.websites.isNotEmpty ? data.websites.first : data.linkedin;
    return SizedBox(
      height: kBrutContactH,
      child: Container(
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: kBrutBlack, width: 2.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cell(data.email,    flex: 3),
            Container(width: 2, color: kBrutBlack),
            _cell(data.phone,    flex: 2),
            Container(width: 2, color: kBrutBlack),
            _cell(data.location, flex: 2),
            Container(width: 2, color: kBrutBlack),
            _cell(website,       flex: 2),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE C — SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────

class _BrutSideCol extends StatelessWidget {
  final CVTemplateData data;
  final List<BrutItem> items;
  final bool   isPage1;
  final double sc;
  final Color  ac;
  const _BrutSideCol({
    required this.data, required this.items,
    required this.isPage1, required this.sc, required this.ac,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize:       MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: kBrutColTopGap),
      for (final it in items) ...[
        if (it.showLabel) _SideLabel(
            text: _lbl(it.section), sc: sc,
            cont: it.isContinued, ff: data.fontFamily),
        _block(it),
      ],
    ],
  );

  Widget _block(BrutItem it) => switch (it.section) {
    BrutSection.skill         => _SkillRow(s: data.skills[it.index],           sc: sc, ff: data.fontFamily),
    BrutSection.language      => _SideSimple(t: data.languages[it.index],      sc: sc, ff: data.fontFamily),
    BrutSection.certification => _SideSimple(t: data.certifications[it.index], sc: sc, ff: data.fontFamily),
    BrutSection.education     => _EduBlock(e: data.education[it.index],        sc: sc, ac: ac, ff: data.fontFamily),
    BrutSection.hobby         => _SideSimple(t: data.hobbies[it.index],        sc: sc, ff: data.fontFamily),
    BrutSection.reference     => _RefCard(r: data.references[it.index],        sc: sc, ac: ac, ff: data.fontFamily),
    _                         => const SizedBox.shrink(),
  };

  String _lbl(BrutSection s) => switch (s) {
    BrutSection.skill         => 'SKILLS',
    BrutSection.language      => 'LANGUAGES',
    BrutSection.certification => 'CERTIFICATIONS',
    BrutSection.education     => 'EDUCATION',
    BrutSection.hobby         => 'INTERESTS',
    BrutSection.reference     => 'REFERENCES',
    _                         => '',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE D — MAIN CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _BrutContentCol extends StatelessWidget {
  final CVTemplateData data;
  final List<BrutItem> items;
  final double sc;
  final Color  ac;
  const _BrutContentCol({
    required this.data, required this.items, required this.sc, required this.ac,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kBrutContentPadH),
      child: Column(
        mainAxisSize:       MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: kBrutColTopGap),
          for (final it in items) ...[
            if (it.showLabel) _MainLabel(
                text: _lbl(it.section), sc: sc,
                cont: it.isContinued, ff: data.fontFamily),
            _block(it),
          ],
        ],
      ),
    );
  }

  Widget _block(BrutItem it) => switch (it.section) {
    BrutSection.summary    => _SumBlock(text: data.summary,                     sc: sc, ff: data.fontFamily),
    BrutSection.experience => _ExpBlock(e: data.experience[it.index], sc: sc, ac: ac, ff: data.fontFamily),
    _                      => const SizedBox.shrink(),
  };

  String _lbl(BrutSection s) => switch (s) {
    BrutSection.summary    => 'PROFILE',
    BrutSection.experience => 'EXPERIENCE',
    _                      => '',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

// Sidebar section label — black bg, white text
class _SideLabel extends StatelessWidget {
  final String text; final double sc; final bool cont; final String ff;
  const _SideLabel({required this.text, required this.sc, this.cont = false, required this.ff});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(14 * sc, 9 * sc, 14 * sc, 7 * sc),
    color: kBrutBlack,
    child: Text(
      cont ? '$text (CONT.)' : text,
      softWrap: true, overflow: TextOverflow.visible,
      style: TextStyle(
          fontSize:      10 * sc, fontWeight: FontWeight.w900,
          color:         kBrutWhite, letterSpacing: 2.0, fontFamily: ff),
    ),
  );
}

// Main section label — bordered box
class _MainLabel extends StatelessWidget {
  final String text; final double sc; final bool cont; final String ff;
  const _MainLabel({required this.text, required this.sc, this.cont = false, required this.ff});

  @override
  Widget build(BuildContext context) => Container(
    margin:  EdgeInsets.only(bottom: 10 * sc),
    padding: EdgeInsets.symmetric(horizontal: 10 * sc, vertical: 6 * sc),
    decoration: BoxDecoration(border: Border.all(color: kBrutBlack, width: 2.5)),
    child: Text(
      cont ? '$text (CONT.)' : text,
      softWrap: true, overflow: TextOverflow.visible,
      style: TextStyle(
          fontSize:      10 * sc, fontWeight: FontWeight.w900,
          letterSpacing: 2.5, color: kBrutBlack, fontFamily: ff),
    ),
  );
}

// Skill row — name left, % right, bottom divider
class _SkillRow extends StatelessWidget {
  final CVTemplateSkill s; final double sc; final String ff;
  const _SkillRow({required this.s, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBrutLight))),
    padding: EdgeInsets.fromLTRB(14 * sc, 9 * sc, 14 * sc, 9 * sc),
    child: Row(children: [
      Expanded(child: Text(s.name, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 10 * sc, fontWeight: FontWeight.w600,
              color: kBrutBlack, fontFamily: ff))),
      SizedBox(width: 4 * sc),
      Text(s.percentLabel,
          style: TextStyle(fontSize: 10 * sc, fontWeight: FontWeight.w900,
              color: kBrutBlack, fontFamily: ff)),
    ]),
  );
}

// Simple text item (language / certification / hobby / interest)
// top and bottom padding are equal so the item has balanced whitespace.
class _SideSimple extends StatelessWidget {
  final String t; final double sc; final String ff;
  const _SideSimple({required this.t, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) => Padding(
    // ← bottom now equals top (7*sc) so spacing is balanced above and below.
    padding: EdgeInsets.fromLTRB(14 * sc, 7 * sc, 14 * sc, 7 * sc),
    child: Text(t, softWrap: true, overflow: TextOverflow.visible,
        style: TextStyle(fontSize: 10 * sc, color: kBrutMuted, fontFamily: ff)),
  );
}

// Education block
class _EduBlock extends StatelessWidget {
  final CVTemplateEducation e; final double sc; final Color ac; final String ff;
  const _EduBlock({required this.e, required this.sc, required this.ac, required this.ff});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(14 * sc, 9 * sc, 14 * sc, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(e.degree, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 10 * sc, fontWeight: FontWeight.w800,
              color: kBrutBlack, fontFamily: ff)),
      Text(e.location.isNotEmpty
          ? '${e.institution}  ·  ${e.location}' : e.institution,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 9.5 * sc, color: kBrutMuted, fontFamily: ff)),
      Padding(
        padding: EdgeInsets.only(top: 3 * sc, bottom: 9 * sc),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * sc, vertical: 2 * sc),
          color: ac,
          child: Text(e.period,
              style: TextStyle(fontSize: 9 * sc, fontWeight: FontWeight.w900,
                  color: kBrutBlack, fontFamily: ff)),
        ),
      ),
    ]),
  );
}

// Reference card
class _RefCard extends StatelessWidget {
  final CVTemplateReferee r; final double sc; final Color ac; final String ff;
  const _RefCard({required this.r, required this.sc, required this.ac, required this.ff});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(14 * sc, 9 * sc, 14 * sc, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(r.name, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 10 * sc, fontWeight: FontWeight.w800,
              color: kBrutBlack, fontFamily: ff)),
      Container(
          margin: EdgeInsets.only(top: 2 * sc, bottom: 3 * sc),
          height: 2.5, width: 26 * sc, color: ac),
      Text(r.title, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 9 * sc, color: kBrutMuted, fontFamily: ff)),
      if (r.company != null && r.company!.isNotEmpty) ...[
        SizedBox(height: 1 * sc),
        Text(r.company!, softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 8.5 * sc, color: kBrutSubtle, fontFamily: ff)),
      ],
      SizedBox(height: 4 * sc),
      if (r.email.isNotEmpty) _IconRow(icon: Icons.email_outlined, text: r.email, sc: sc, ff: ff),
      if (r.phone.isNotEmpty) _IconRow(icon: Icons.phone_outlined, text: r.phone, sc: sc, ff: ff),
      SizedBox(height: 6 * sc),
    ]),
  );
}

class _IconRow extends StatelessWidget {
  final IconData icon; final String text; final double sc; final String ff;
  const _IconRow({required this.icon, required this.text, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 2 * sc),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.only(top: 1 * sc),
        child: Icon(icon, size: 9 * sc, color: const Color(0xFF888888)),
      ),
      SizedBox(width: 4 * sc),
      Expanded(child: Text(text, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 8.5 * sc, color: kBrutMuted,
              fontFamily: ff, height: 1.3))),
    ]),
  );
}

// Profile summary block
class _SumBlock extends StatelessWidget {
  final String text; final double sc; final String ff;
  const _SumBlock({required this.text, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 16 * sc),
    child: Text(text, softWrap: true, overflow: TextOverflow.visible,
        style: TextStyle(fontSize: 11 * sc, color: kBrutMuted,
            height: 1.6, fontFamily: ff)),
  );
}

// Experience card — grey header + accent date pill + "/" bullets
class _ExpBlock extends StatelessWidget {
  final CVTemplateExperience e; final double sc; final Color ac; final String ff;
  const _ExpBlock({required this.e, required this.sc, required this.ac, required this.ff});

  @override
  Widget build(BuildContext context) => Container(
    margin:     EdgeInsets.only(bottom: 14 * sc),
    decoration: BoxDecoration(border: Border.all(color: kBrutBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Container(
        color:   kBrutRowBg,
        padding: EdgeInsets.symmetric(horizontal: 12 * sc, vertical: 8 * sc),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.role, softWrap: true, overflow: TextOverflow.visible,
                style: TextStyle(fontSize: 12 * sc, fontWeight: FontWeight.w900,
                    color: kBrutBlack, fontFamily: ff)),
            Text(
              e.location.isNotEmpty
                  ? '${e.company}  ·  ${e.location}' : e.company,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: 10 * sc, color: kBrutMuted, fontFamily: ff),
            ),
          ])),
          SizedBox(width: 8 * sc),
          Container(
            color:   ac,
            padding: EdgeInsets.symmetric(horizontal: 8 * sc, vertical: 4 * sc),
            child: Text(e.duration, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9.5 * sc, fontWeight: FontWeight.w900,
                    color: kBrutBlack, fontFamily: ff)),
          ),
        ]),
      ),

      if (e.bullets.isNotEmpty)
        Padding(
          padding: EdgeInsets.all(12 * sc),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: e.bullets.map((b) => Padding(
              padding: EdgeInsets.only(bottom: 4 * sc),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('/ ', style: TextStyle(fontSize: 11 * sc,
                    fontWeight: FontWeight.w900, color: kBrutBlack, fontFamily: ff)),
                Expanded(child: Text(b, softWrap: true, overflow: TextOverflow.visible,
                    style: TextStyle(fontSize: 10.5 * sc, color: kBrutMuted,
                        height: 1.4, fontFamily: ff))),
              ]),
            )).toList(),
          ),
        ),

    ]),
  );
}