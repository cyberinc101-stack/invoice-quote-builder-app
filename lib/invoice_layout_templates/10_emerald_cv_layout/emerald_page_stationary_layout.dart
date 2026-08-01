// emerald_page_stationary_layout.dart
// lib/cv_layout_templates/10_emerald_cv_layout/emerald_page_stationary_layout.dart
//
// Single A4 page renderer for the Emerald Professional template.
// NO state, NO pagination, NO measurement.
//
// FIXES:
//  1. Image size driven by data.imageSize slider (independent of font scale).
//     _eImgPx() mirrors Executive's _imgPx() pattern.
//  2. Header Column uses mainAxisSize.min + fixed (non-sc) vertical padding
//     so content never overflows the fixed kEHdr1H = 148 zone.
//  3. All header Text widgets: softWrap:true + overflow:visible so long
//     names / job titles wrap to a new line rather than clipping.
//  4. _EHdrContact text: overflow:ellipsis to prevent text running behind image.
//  5. Contact rows now use Flexible children so they never overflow past
//     the available width (i.e. never behind the profile photo).
//  6. All body Text widgets: softWrap:true + overflow:visible.
//  7. _ESkillBar uses LayoutBuilder to avoid infinite-width errors.
//  8. _EMainLabel Row wraps label text in Expanded so very long section
//     titles don't overflow.
//  9. FIX: Contact row width is constrained to (innerWidth - imgPx - spacing)
//     so text is guaranteed to stay left of the profile image.
// 10. FIX: ePageUsableH subtracts an extra 1.0 px safety buffer to absorb
//     sub-pixel text measurement rounding (Flutter text engine can produce
//     ±0.5 px) and prevent bottom overflow on page render.

import 'package:flutter/material.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'emerald_cv_logic_data.dart';

// ── Page geometry ─────────────────────────────────────────────────────────────
const double kEPageW        = 595.0;
const double kEPageH        = 842.0;
const double kEMainW        = 380.0;
const double kESideW        = kEPageW - kEMainW;        // 215
const double kEHdr1H        = 172.0;
const double kEHdrNH        =  52.0;
const double kEFooterZoneH  =  24.0;
const double kEFooterInsetB =  10.0;
const double kEBase         =  12.0;
const double kEMainPadH     =  22.0;
const double kESidePadH     =  18.0;
const double kEColTopGap    =  14.0;
const double kEClipInset    =   6.0;

const double kEMainInnerW   = kEMainW - kEMainPadH * 2;   // 336
const double kESideInnerW   = kESideW - kESidePadH * 2;   // 179

// ── Image size constants (independent of font scale) ─────────────────────────
// slider range 10–16, base 12 → 72 px at default.
// Mirrors Executive's kImgSizeBase / kImgSizePxBase pattern exactly.
const double _kEImgBase   = 12.0;
const double _kEImgPxBase = 72.0;
double _eImgPx(double imageSize) => _kEImgPxBase * (imageSize / _kEImgBase);

/// Raw body height below header, above footer.
double ePageBodyH(bool isPage1) =>
    kEPageH - (isPage1 ? kEHdr1H : kEHdrNH) - kEFooterZoneH;

/// Paginator budget.
/// The extra 1.0 px safety buffer absorbs sub-pixel rounding from Flutter's
/// text layout engine (±0.5 px) so items that measure at the boundary never
/// produce a visible bottom overflow in the rendered ClipRect zone.
double ePageUsableH(bool isPage1) =>
    ePageBodyH(isPage1) - kEColTopGap - kEClipInset - 1.0;

// ── Palette ───────────────────────────────────────────────────────────────────
const Color kEEmerald      = Color(0xFF064E3B);
const Color kEEmeraldMid   = Color(0xFF065F46);
const Color kEEmeraldLight = Color(0xFF10B981);
const Color kECream        = Color(0xFFF0FDF4);
const Color kEWhite        = Colors.white;
const Color kEInk          = Color(0xFF1C1C1E);
const Color kEMuted        = Color(0xFF6B7280);
const Color kEBorder       = Color(0xFFD1FAE5);
const Color kERule         = Color(0xFFE5E7EB);

Color emeraldAccent(CVTemplateData d) => kEEmeraldLight;

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: EmeraldPageLayout
// ─────────────────────────────────────────────────────────────────────────────

class EmeraldPageLayout extends StatelessWidget {
  final CVTemplateData    data;
  final List<EmeraldItem> mainItems;
  final List<EmeraldItem> sideItems;
  final int  pageNum;
  final int  totalPages;

  const EmeraldPageLayout({
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
    final hH = p1 ? kEHdr1H : kEHdrNH;
    final bH = ePageBodyH(p1);
    final sc = data.fontSize / kEBase;

    return SizedBox(
      width: kEPageW,
      height: kEPageH,
      child: ClipRect(
        child: Stack(
          children: [

            // Full-page white background
            Positioned.fill(child: Container(color: kEWhite)),

            // ── ZONE A: Header ────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0, height: hH,
              child: p1
                  ? _EPage1Header(data: data, sc: sc)
                  : _EPage2Header(data: data, sc: sc),
            ),

            // ── ZONE B: Main content body ─────────────────────────────────
            Positioned(
              top: hH, left: 0, width: kEMainW,
              height: bH - kEClipInset,
              child: ClipRect(
                child: _EMainCol(data: data, items: mainItems, sc: sc),
              ),
            ),

            // ── ZONE C: Sidebar body ──────────────────────────────────────
            Positioned(
              top: hH, left: kEMainW, width: kESideW,
              height: bH - kEClipInset,
              child: ClipRect(
                child: _ESideCol(data: data, items: sideItems, sc: sc),
              ),
            ),

            // ── ZONE D: Footer ────────────────────────────────────────────
            Positioned(
              bottom: 0, left: kEMainPadH, right: kESidePadH,
              height: kEFooterZoneH,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: kEFooterInsetB),
                  child: Row(children: [
                    Expanded(child: Container(height: 0.5, color: kERule)),
                    const SizedBox(width: 8),
                    Text('$pageNum / $totalPages',
                        style: const TextStyle(
                            fontSize: 8.5, color: kEMuted, letterSpacing: 1.0)),
                  ]),
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
// ZONE A — HEADERS
// ─────────────────────────────────────────────────────────────────────────────

class _EPage1Header extends StatelessWidget {
  final CVTemplateData data;
  final double sc;
  const _EPage1Header({required this.data, required this.sc});

  @override
  Widget build(BuildContext context) {
    final imgPx = _eImgPx(data.imageSize);
    const double padH = kEMainPadH;
    const double padV = 16.0;
    // Total horizontal space taken by image + spacing + outer padding
    final double imgReserve = imgPx + 12 * sc + padH;
    // Width available for the left text block
    final double textColW = kEPageW - padH - imgReserve;
    // Inner usable height after fixed padding
    final double innerH = kEHdr1H - padV * 2;

    return SizedBox(
      width: kEPageW,
      height: kEHdr1H,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: kEEmerald)),
          Positioned.fill(child: CustomPaint(painter: _EDiagonalPainter())),

          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: padH, vertical: padV),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── LEFT: fixed width, natural height — no ClipRect cutting
                  //    content. Column fills innerH and pushes Wrap to bottom.
                  SizedBox(
                    width: textColW,
                    height: innerH,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name — up to 2 lines
                        Text(
                          data.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 17 * sc,
                              fontWeight: FontWeight.w800,
                              color: kEWhite,
                              letterSpacing: -0.3,
                              height: 1.1,
                              fontFamily: data.fontFamily),
                        ),
                        SizedBox(height: 3 * sc),
                        Container(
                            width: 28 * sc,
                            height: 2,
                            color: kEEmeraldLight),
                        SizedBox(height: 3 * sc),
                        // Job title
                        Text(
                          data.jobTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 9 * sc,
                              color: kEEmeraldLight,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                              fontFamily: data.fontFamily),
                        ),
                        SizedBox(height: 6 * sc),
                        // ── Contact chips in a Wrap so they flow to next line.
                        //    No ClipRect — the outer SizedBox height keeps it
                        //    bounded and nothing gets cut mid-line.
                        Wrap(
                          spacing: 10 * sc,
                          runSpacing: 4 * sc,
                          children: [
                            if (data.email.isNotEmpty)
                              _EHdrContact(Icons.email_outlined,
                                  data.email, sc, data.fontFamily),
                            if (data.phone.isNotEmpty)
                              _EHdrContact(Icons.phone_outlined,
                                  data.phone, sc, data.fontFamily),
                            if (data.location.isNotEmpty)
                              _EHdrContact(Icons.location_on_outlined,
                                  data.location, sc, data.fontFamily),
                            for (final w in data.websites)
                              _EHdrContact(Icons.language_outlined,
                                  w, sc, data.fontFamily),
                            if (data.linkedin.isNotEmpty)
                              _EHdrContact(Icons.badge_outlined,
                                  data.linkedin, sc, data.fontFamily),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Spacer between text and photo
                  SizedBox(width: 12 * sc),

                  // ── RIGHT: Profile photo
                  data.buildProfileImage(
                    size: imgPx,
                    borderColor: kEEmeraldLight,
                    borderWidth: 2.5,
                    placeholderBg: kEEmeraldMid,
                  ),

                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _EPage2Header extends StatelessWidget {
  final CVTemplateData data;
  final double sc;
  const _EPage2Header({required this.data, required this.sc});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kEPageW,
      height: kEHdrNH,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: kEEmerald)),
          Positioned.fill(child: CustomPaint(painter: _EDiagonalPainter())),

          // ClipRect prevents the 1.3 px overflow warning.
          Positioned.fill(
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kEMainPadH, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.fullName,
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 8.5 * sc,
                          fontWeight: FontWeight.w800,
                          color: kEWhite,
                          letterSpacing: 0.8,
                          fontFamily: data.fontFamily),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.jobTitle,
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 7.5 * sc,
                          color: kEEmeraldLight,
                          fontFamily: data.fontFamily),
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
// ZONE B — MAIN COLUMN
// ─────────────────────────────────────────────────────────────────────────────

class _EMainCol extends StatelessWidget {
  final CVTemplateData    data;
  final List<EmeraldItem> items;
  final double            sc;
  const _EMainCol({required this.data, required this.items, required this.sc});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kEMainPadH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: kEColTopGap),
          for (final it in items) ...[
            if (it.showLabel)
              _EMainLabel(
                  text: _lbl(it.section),
                  sc: sc,
                  cont: it.isContinued,
                  ff: data.fontFamily),
            _blk(it),
          ],
        ],
      ),
    );
  }

  Widget _blk(EmeraldItem it) => switch (it.section) {
    EmeraldSection.summary =>
        _ESumBlock(text: data.summary, sc: sc, ff: data.fontFamily),
    EmeraldSection.experience =>
        _EExpBlock(e: data.experience[it.index], sc: sc, ff: data.fontFamily),
    EmeraldSection.education =>
        _EEduBlock(e: data.education[it.index], sc: sc, ff: data.fontFamily),
    _ => const SizedBox.shrink(),
  };

  String _lbl(EmeraldSection s) => switch (s) {
    EmeraldSection.summary    => 'PROFESSIONAL SUMMARY',
    EmeraldSection.experience => 'WORK EXPERIENCE',
    EmeraldSection.education  => 'EDUCATION',
    _ => '',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE C — SIDE COLUMN
// ─────────────────────────────────────────────────────────────────────────────

class _ESideCol extends StatelessWidget {
  final CVTemplateData    data;
  final List<EmeraldItem> items;
  final double            sc;
  const _ESideCol({required this.data, required this.items, required this.sc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kESidePadH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: kEColTopGap),
          for (final it in items) ...[
            if (it.showLabel)
              _EMainLabel(
                  text: _lbl(it.section),
                  sc: sc,
                  cont: it.isContinued,
                  ff: data.fontFamily),
            _blk(it),
          ],
        ],
      ),
    );
  }

  Widget _blk(EmeraldItem it) => switch (it.section) {
    EmeraldSection.skill =>
        _ESkillBar(s: data.skills[it.index], sc: sc, ff: data.fontFamily),
    EmeraldSection.education =>
        _EEduBlock(e: data.education[it.index], sc: sc, ff: data.fontFamily),
    EmeraldSection.language =>
        _ELanguageChip(text: data.languages[it.index], sc: sc, ff: data.fontFamily),
    EmeraldSection.certification =>
        _ECertItem(text: data.certifications[it.index], sc: sc, ff: data.fontFamily),
    EmeraldSection.hobby =>
        _ECertItem(text: data.hobbies[it.index], sc: sc, ff: data.fontFamily),
    EmeraldSection.reference =>
        _ERefCard(r: data.references[it.index], sc: sc, ff: data.fontFamily),
    _ => const SizedBox.shrink(),
  };

  String _lbl(EmeraldSection s) => switch (s) {
    EmeraldSection.skill         => 'SKILLS',
    EmeraldSection.education     => 'EDUCATION',
    EmeraldSection.language      => 'LANGUAGES',
    EmeraldSection.certification => 'CERTIFICATIONS',
    EmeraldSection.hobby         => 'INTERESTS',
    EmeraldSection.reference     => 'REFERENCES',
    _ => '',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _EMainLabel extends StatelessWidget {
  final String text;
  final double sc;
  final bool   cont;
  final String ff;
  const _EMainLabel(
      {required this.text, required this.sc, this.cont = false, required this.ff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * sc),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(width: 3, height: 14 * sc, color: kEEmeraldLight),
            SizedBox(width: 8 * sc),
            // Expanded prevents long "(CONT.)" labels overflowing
            Expanded(
              child: Text(
                cont ? '$text (CONT.)' : text,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(
                    fontSize: 8.5 * sc,
                    fontWeight: FontWeight.w800,
                    color: kEEmerald,
                    letterSpacing: 1.8,
                    fontFamily: ff),
              ),
            ),
          ]),
          SizedBox(height: 5 * sc),
          Container(height: 0.5, color: kEBorder),
          SizedBox(height: 8 * sc),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCK WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Contact chip used in the header.
/// Lives inside a Wrap that is bounded by textColW, so no extra maxWidth
/// constraint needed — text shows in full on one line and the Wrap handles
/// reflowing if the whole row is too wide.
class _EHdrContact extends StatelessWidget {
  final IconData icon;
  final String   text;
  final double   sc;
  final String   ff;
  const _EHdrContact(this.icon, this.text, this.sc, this.ff);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: kEEmeraldLight, size: 8 * sc),
      SizedBox(width: 3 * sc),
      Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: TextStyle(
            color: Colors.white70, fontSize: 7.5 * sc, fontFamily: ff),
      ),
    ],
  );
}

class _ESumBlock extends StatelessWidget {
  final String text; final double sc; final String ff;
  const _ESumBlock({required this.text, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 18 * sc),
    child: Container(
      padding: EdgeInsets.all(12 * sc),
      decoration: BoxDecoration(
        color: kECream,
        borderRadius: BorderRadius.circular(7 * sc),
        border: Border.all(color: kEBorder),
      ),
      child: Text(
        text,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: TextStyle(fontSize: 9.5 * sc, color: kEMuted,
            height: 1.65, fontFamily: ff),
      ),
    ),
  );
}

class _EExpBlock extends StatelessWidget {
  final CVTemplateExperience e; final double sc; final String ff;
  const _EExpBlock({required this.e, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * sc),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline — decorative only.
          Column(
            children: [
              Container(
                width: 9 * sc, height: 9 * sc,
                margin: EdgeInsets.only(top: 2 * sc),
                decoration: const BoxDecoration(
                    color: kEEmeraldLight, shape: BoxShape.circle),
              ),
              Container(width: 1.5, height: 60 * sc, color: kEBorder),
            ],
          ),
          SizedBox(width: 10 * sc),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(
                      e.role,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: TextStyle(fontSize: 11 * sc,
                          fontWeight: FontWeight.w700,
                          color: kEInk, fontFamily: ff),
                    )),
                    SizedBox(width: 6 * sc),
                    Text(e.duration,
                        style: TextStyle(fontSize: 9 * sc,
                            color: kEMuted, fontFamily: ff)),
                  ],
                ),
                Text(
                  e.location.isNotEmpty
                      ? '${e.company}  ·  ${e.location}' : e.company,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: 10 * sc, color: kEEmeraldMid,
                      fontWeight: FontWeight.w600, fontFamily: ff),
                ),
                if (e.bullets.isNotEmpty) ...[
                  SizedBox(height: 5 * sc),
                  ...e.bullets.map((b) => Padding(
                    padding: EdgeInsets.only(bottom: 3 * sc),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 4.5 * sc),
                          width: 3 * sc, height: 3 * sc,
                          decoration: const BoxDecoration(
                              color: kEEmeraldLight, shape: BoxShape.circle),
                        ),
                        SizedBox(width: 6 * sc),
                        Expanded(child: Text(
                          b,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(fontSize: 9.5 * sc,
                              color: kEMuted, height: 1.4, fontFamily: ff),
                        )),
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

class _EEduBlock extends StatelessWidget {
  final CVTemplateEducation e; final double sc; final String ff;
  const _EEduBlock({required this.e, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) {
    final yr = e.period.length >= 4
        ? e.period.substring(e.period.length - 4)
        : e.period;
    final yr2 = yr.length >= 2 ? yr.substring(yr.length - 2) : yr;

    return Container(
      margin: EdgeInsets.only(bottom: 9 * sc),
      padding: EdgeInsets.all(11 * sc),
      decoration: BoxDecoration(
        color: kECream,
        borderRadius: BorderRadius.circular(7 * sc),
        border: Border.all(color: kEBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38 * sc, height: 38 * sc,
            decoration: BoxDecoration(
              color: kEEmerald,
              borderRadius: BorderRadius.circular(7 * sc),
            ),
            child: Center(child: Text(yr2,
                style: TextStyle(fontSize: 11 * sc,
                    fontWeight: FontWeight.w800,
                    color: kEWhite, fontFamily: ff))),
          ),
          SizedBox(width: 10 * sc),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.degree,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: 10.5 * sc,
                      fontWeight: FontWeight.w700,
                      color: kEInk, fontFamily: ff),
                ),
                Text(
                  e.location.isNotEmpty
                      ? '${e.institution}  ·  ${e.location}' : e.institution,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: 9.5 * sc,
                      color: kEMuted, fontFamily: ff),
                ),
                if (e.detail != null && e.detail!.isNotEmpty) ...[
                  SizedBox(height: 2 * sc),
                  Text(
                    e.detail!,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(fontSize: 9 * sc,
                        color: kEEmeraldMid, fontStyle: FontStyle.italic,
                        height: 1.3, fontFamily: ff),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ESkillBar extends StatelessWidget {
  final CVTemplateSkill s; final double sc; final String ff;
  const _ESkillBar({required this.s, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * sc),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(s.name,
                  style: TextStyle(fontSize: 9.5 * sc, color: kEInk,
                      fontWeight: FontWeight.w500, fontFamily: ff),
                  overflow: TextOverflow.ellipsis, maxLines: 1)),
              SizedBox(width: 4 * sc),
              Text(s.percentLabel,
                  style: TextStyle(fontSize: 8 * sc,
                      color: kEMuted, fontFamily: ff)),
            ],
          ),
          SizedBox(height: 4 * sc),
          LayoutBuilder(builder: (ctx, bc) {
            final totalW = bc.maxWidth.isInfinite ? kESideInnerW : bc.maxWidth;
            final fillW  = totalW * s.levelOutOf10 / 10.0;
            return ClipRRect(
              borderRadius: BorderRadius.circular(3 * sc),
              child: SizedBox(
                height: 5 * sc, width: totalW,
                child: Row(children: [
                  Container(width: fillW,          height: 5 * sc, color: kEEmeraldLight),
                  Container(width: totalW - fillW, height: 5 * sc, color: kEBorder),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ELanguageChip extends StatelessWidget {
  final String text; final double sc; final String ff;
  const _ELanguageChip({required this.text, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: 6 * sc),
    padding: EdgeInsets.symmetric(horizontal: 9 * sc, vertical: 5 * sc),
    decoration: BoxDecoration(
      color: kECream,
      borderRadius: BorderRadius.circular(5 * sc),
      border: Border.all(color: kEBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6 * sc, height: 6 * sc,
          decoration: const BoxDecoration(
              color: kEEmeraldLight, shape: BoxShape.circle),
        ),
        SizedBox(width: 6 * sc),
        Flexible(
          child: Text(
            text,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 9 * sc,
                color: kEMuted, fontFamily: ff),
          ),
        ),
      ],
    ),
  );
}

class _ECertItem extends StatelessWidget {
  final String text; final double sc; final String ff;
  const _ECertItem({required this.text, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 7 * sc),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 3.5 * sc),
          width: 6 * sc,
          height: 6 * sc,
          decoration: const BoxDecoration(
            color: kEEmeraldLight,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6 * sc),
        Expanded(child: Text(
          text,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 9 * sc, color: kEMuted,
              height: 1.3, fontFamily: ff),
        )),
      ],
    ),
  );
}

class _ERefCard extends StatelessWidget {
  final CVTemplateReferee r; final double sc; final String ff;
  const _ERefCard({required this.r, required this.sc, required this.ff});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 10 * sc),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          r.name,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 9.5 * sc,
              fontWeight: FontWeight.w700,
              color: kEInk, fontFamily: ff),
        ),
        SizedBox(height: 2 * sc),
        Text(
          r.title,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 8.5 * sc,
              color: kEEmeraldMid, fontFamily: ff),
        ),
        if (r.company != null && r.company!.isNotEmpty) ...[
          SizedBox(height: 1 * sc),
          Text(
            r.company!,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 8 * sc,
                color: kEMuted, fontFamily: ff),
          ),
        ],
        if (r.email.isNotEmpty) ...[
          SizedBox(height: 4 * sc),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1 * sc),
                child: Icon(Icons.email_outlined, size: 8 * sc, color: kEMuted),
              ),
              SizedBox(width: 4 * sc),
              Expanded(child: Text(
                r.email,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(fontSize: 8 * sc,
                    color: kEMuted, fontFamily: ff),
              )),
            ],
          ),
        ],
        if (r.phone.isNotEmpty) ...[
          SizedBox(height: 2 * sc),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1 * sc),
                child: Icon(Icons.phone_outlined, size: 8 * sc, color: kEMuted),
              ),
              SizedBox(width: 4 * sc),
              Expanded(child: Text(
                r.phone,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(fontSize: 8 * sc,
                    color: kEMuted, fontFamily: ff),
              )),
            ],
          ),
        ],
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIAGONAL STRIPE PAINTER (header decoration)
// ─────────────────────────────────────────────────────────────────────────────

class _EDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width + size.height; i += 48) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}