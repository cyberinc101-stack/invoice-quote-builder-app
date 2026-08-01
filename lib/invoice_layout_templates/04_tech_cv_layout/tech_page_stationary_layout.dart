// tech_page_stationary_layout.dart
// lib/cv_layout_templates/04_tech_cv_layout/tech_page_stationary_layout.dart

import 'package:flutter/material.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'tech_cv_logic_data.dart';

// ── Page geometry ─────────────────────────────────────────────────────────────
const double kTechPageW    = 595.0;
const double kTechPageH    = 842.0;
const double kTechSideBarW = 182.0;
const double kTechSidePadH =  16.0;
const double kTechSidePadV =  16.0;
const double kTechSideW    = kTechSideBarW - kTechSidePadH * 2;
const double kTechMainPadH =  16.0;
const double kTechMainPadV =  16.0;
const double kTechMainW    = kTechPageW - kTechSideBarW - kTechMainPadH * 2;
const double kTechFooterH  =  20.0;
const double kTechBodyH    = kTechPageH - kTechFooterH;

// ── Image size constants ──────────────────────────────────────────────────────
// imageSize from CVData is in the range 10–16, independent of fontSize.
const double _kTechImgBase   = 12.0;  // imageSize == 12 → 64 px
const double _kTechImgPxBase = 64.0;

/// Pixel diameter of the profile photo for a given imageSize value.
double techImgPx(double imageSize) => _kTechImgPxBase * (imageSize / _kTechImgBase);

/// Available body height for paginated content on a given page/column.
double techPageBodyH(bool isPage1, {bool isSide = false}) {
  final base = kTechBodyH - kTechSidePadV * 2;
  if (!isPage1) return base;
  // Page-1 header heights are measured dynamically; these constants are
  // only used as fall-back references — real pagination uses measured values.
  return base;
}

// ── Dark theme palette ────────────────────────────────────────────────────────
const Color kTechBg      = Color(0xFF0D1117);
const Color kTechSurface = Color(0xFF161B22);
const Color kTechBorder  = Color(0xFF30363D);
const Color kTechGreen   = Color(0xFF3FB950);
const Color kTechBlue    = Color(0xFF58A6FF);
const Color kTechYellow  = Color(0xFFE3B341);
const Color kTechWhite   = Color(0xFFE6EDF3);
const Color kTechMuted   = Color(0xFF8B949E);
const Color _greenBorder = Color(0x803FB950);

// ── Light theme palette ───────────────────────────────────────────────────────
const Color kTechLightBg      = Color(0xFFFFFFFF);
const Color kTechLightSurface = Color(0xFFF6F8FA);
const Color kTechLightBorder  = Color(0xFFD0D7DE);
const Color kTechLightGreen   = kTechGreen;
const Color kTechLightBlue    = kTechBlue;
const Color kTechLightYellow  = kTechYellow;
const Color kTechLightText    = Color(0xFF1F2328);
const Color kTechLightMuted   = Color(0xFF444444);
const Color _lightGreenBorder = Color(0x803FB950);

const double kTechBaseFontSize = 12.0;

// ─────────────────────────────────────────────────────────────────────────────
// Theme helper
// ─────────────────────────────────────────────────────────────────────────────
class TechTheme {
  final bool   isLight;
  final double fontScale;
  final String font;

  const TechTheme({
    required this.isLight,
    this.fontScale = 1.0,
    this.font      = 'monospace',
  });

  Color get bg          => isLight ? kTechLightBg      : kTechBg;
  Color get surface     => isLight ? kTechLightSurface : kTechSurface;
  Color get border      => isLight ? kTechLightBorder  : kTechBorder;
  Color get green       => isLight ? kTechLightGreen   : kTechGreen;
  Color get blue        => isLight ? kTechLightBlue    : kTechBlue;
  Color get yellow      => isLight ? kTechLightYellow  : kTechYellow;
  Color get white       => isLight ? kTechLightText    : kTechWhite;
  Color get muted       => isLight ? kTechLightMuted   : kTechMuted;
  Color get greenBorder => isLight ? _lightGreenBorder : _greenBorder;
  Color get sidebarBg   => isLight ? kTechLightSurface : kTechSurface;
  Color get footerBg    => isLight ? const Color(0xFFEAEEF2) : kTechSurface;

  double fs(double base) => (base * fontScale).clamp(6.0, 32.0);
}

TechTheme techThemeFromData(CVTemplateData data, {bool isLight = false}) {
  final scale = (data.fontSize > 0 ? data.fontSize : kTechBaseFontSize) /
      kTechBaseFontSize;
  final font  = data.fontFamily.isNotEmpty ? data.fontFamily : 'monospace';
  return TechTheme(isLight: isLight, fontScale: scale, font: font);
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: TechPageLayout
// ─────────────────────────────────────────────────────────────────────────────

class TechPageLayout extends StatelessWidget {
  final CVTemplateData data;
  final List<TechItem> mainItems;
  final List<TechItem> sideItems;
  final int  pageNum;
  final int  totalPages;
  final bool isLight;

  const TechPageLayout({
    super.key,
    required this.data,
    required this.mainItems,
    required this.sideItems,
    required this.pageNum,
    required this.totalPages,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p1 = pageNum == 1;
    final t  = techThemeFromData(data, isLight: isLight);

    return SizedBox(
      width:  kTechPageW,
      height: kTechPageH,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: t.bg)),

          // ── ZONE A: Sidebar ───────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, width: kTechSideBarW, bottom: kTechFooterH,
            child: Container(
              decoration: BoxDecoration(
                color: t.sidebarBg,
                border: Border(right: BorderSide(color: t.border, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: kTechSidePadH, vertical: kTechSidePadV),
              child: _SideCol(data: data, items: sideItems, isPage1: p1, t: t),
            ),
          ),

          // ── ZONE B: Main content ──────────────────────────────────────────
          Positioned(
            top: 0, left: kTechSideBarW, right: 0, bottom: kTechFooterH,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kTechMainPadH, vertical: kTechMainPadV),
              child: _MainCol(data: data, items: mainItems, isPage1: p1, t: t),
            ),
          ),

          // ── ZONE D: Footer ────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0, height: kTechFooterH,
            child: Container(
              color: t.footerBg,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Container(height: 0.5, color: t.border)),
                  const SizedBox(width: 8),
                  Text('$pageNum / $totalPages',
                      style: TextStyle(
                          fontSize: 8, color: t.muted,
                          fontFamily: t.font, letterSpacing: 1.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE A — SIDEBAR COLUMN
// ─────────────────────────────────────────────────────────────────────────────

class _SideCol extends StatelessWidget {
  final CVTemplateData data;
  final List<TechItem> items;
  final bool isPage1;
  final TechTheme t;
  const _SideCol({required this.data, required this.items,
      required this.isPage1, required this.t});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width:  constraints.maxWidth,
          height: constraints.maxHeight,
          child: ClipRect(
            child: OverflowBox(
              alignment:  Alignment.topLeft,
              maxWidth:   constraints.maxWidth,
              maxHeight:  double.infinity,
              minWidth:   constraints.maxWidth,
              minHeight:  0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _buildContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildContent() {
    return [
          if (isPage1) ...[
            Row(children: [
              _dot(const Color(0xFFFF5F57)),
              const SizedBox(width: 5),
              _dot(const Color(0xFFFFBD2E)),
              const SizedBox(width: 5),
              _dot(const Color(0xFF27C840)),
            ]),
            const SizedBox(height: 14),
            Center(
              child: data.buildProfileImage(
                size:          techImgPx(data.imageSize),
                borderColor:   t.green,
                borderWidth:   2,
                placeholderBg: t.bg,
              ),
            ),
            const SizedBox(height: 12),
            Text(data.fullName,
                style: TextStyle(
                    fontSize:   t.fs(11),
                    fontWeight: FontWeight.w700,
                    color:      t.white,
                    fontFamily: t.font,
                    height:     1.3),
                softWrap: true,
                overflow: TextOverflow.visible),
            const SizedBox(height: 14),
            _secLabel('// CONTACT'),
            const SizedBox(height: 8),
            if (data.email.isNotEmpty)    _contactLine('email', data.email),
            if (data.phone.isNotEmpty)    _contactLine('phone', data.phone),
            if (data.location.isNotEmpty) _contactLine('loc',   data.location),
            if (data.website.isNotEmpty)  _contactLine('web',   data.website),
            const SizedBox(height: 14),
          ],
          ..._buildItems(),
        ];
  }

  List<Widget> _buildItems() {
    final ws = <Widget>[];
    for (final it in items) {
      if (it.showLabel) {
        if (ws.isNotEmpty) ws.add(const SizedBox(height: 10));
        // No "(CONT.)" — label is always the plain section title
        ws.add(_secLabel(_sideLbl(it.section)));
        ws.add(const SizedBox(height: 8));
      }
      ws.add(_block(it));
    }
    return ws;
  }

  Widget _block(TechItem it) => switch (it.section) {
    TechSection.skill     => _SkillBlock(s: data.skills[it.index],              t: t),
    TechSection.language  => _SimpleBlock(t2: data.languages[it.index], prefix: '> ', t: t),
    TechSection.hobby     => _SimpleBlock(t2: data.hobbies[it.index],   prefix: '> ', t: t),
    TechSection.reference => _RefBlock(r: data.references[it.index],            t: t),
    _ => const SizedBox.shrink(),
  };

  String _sideLbl(TechSection s) => switch (s) {
    TechSection.skill     => '// SKILLS',
    TechSection.language  => '// LANGUAGES',
    TechSection.hobby     => '// HOBBIES',
    TechSection.reference => '// REFERENCES',
    _                     => '// SECTION',
  };

  Widget _dot(Color c) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _secLabel(String txt) => Text(txt,
      style: TextStyle(
          fontSize:   t.fs(9.5),
          fontWeight: FontWeight.w700,
          color:      t.yellow,
          fontFamily: t.font),
      softWrap: true,
      overflow: TextOverflow.visible);

  Widget _contactLine(String key, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$key: ', style: TextStyle(
          fontSize: t.fs(9.5), color: t.blue, fontFamily: t.font)),
      Expanded(child: Text(value, style: TextStyle(
          fontSize: t.fs(9.5), color: t.muted, fontFamily: t.font),
          softWrap: true,
          overflow: TextOverflow.visible)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE B — MAIN CONTENT COLUMN
// ─────────────────────────────────────────────────────────────────────────────

class _MainCol extends StatelessWidget {
  final CVTemplateData data;
  final List<TechItem> items;
  final bool isPage1;
  final TechTheme t;
  const _MainCol({required this.data, required this.items,
      required this.isPage1, required this.t});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width:  constraints.maxWidth,
          height: constraints.maxHeight,
          child: ClipRect(
            child: OverflowBox(
              alignment:  Alignment.topLeft,
              maxWidth:   constraints.maxWidth,
              maxHeight:  double.infinity,
              minWidth:   constraints.maxWidth,
              minHeight:  0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPage1) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: t.border, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(r'$ whoami', style: TextStyle(
                              fontSize: t.fs(10), color: t.green, fontFamily: t.font)),
                          const SizedBox(height: 4),
                          Text(data.fullName, style: TextStyle(
                              fontSize:   t.fs(18),
                              fontWeight: FontWeight.w700,
                              color:      t.blue,
                              fontFamily: t.font),
                              softWrap: true,
                              overflow: TextOverflow.visible),
                          const SizedBox(height: 2),
                          Text(data.jobTitle, style: TextStyle(
                              fontSize: t.fs(10.5), color: t.yellow, fontFamily: t.font),
                              softWrap: true,
                              overflow: TextOverflow.visible),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ..._buildItems(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildItems() {
    final ws = <Widget>[];
    for (final it in items) {
      if (it.showLabel) {
        if (ws.isNotEmpty) ws.add(const SizedBox(height: 4));
        // No "(CONT.)" — label is always the plain section title
        ws.add(Text(_mainLbl(it.section),
            style: TextStyle(
                fontSize:   t.fs(10),
                fontWeight: FontWeight.w700,
                color:      t.yellow,
                fontFamily: t.font),
            softWrap: true,
            overflow: TextOverflow.visible));
        ws.add(const SizedBox(height: 8));
      }
      ws.add(_block(it));
    }
    return ws;
  }

  Widget _block(TechItem it) => switch (it.section) {
    TechSection.summary       => _SumBlock(text: data.summary,                t: t),
    TechSection.experience    => _ExpBlock(e: data.experience[it.index],      t: t),
    TechSection.education     => _EduBlock(e: data.education[it.index],       t: t),
    TechSection.certification => _CertBlock(s: data.certifications[it.index], t: t),
    _ => const SizedBox.shrink(),
  };

  String _mainLbl(TechSection s) => switch (s) {
    TechSection.summary       => '// SUMMARY',
    TechSection.experience    => '// EXPERIENCE',
    TechSection.education     => '// EDUCATION',
    TechSection.certification => '// CERTIFICATIONS',
    _                         => '// SECTION',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCKS — MAIN
// ─────────────────────────────────────────────────────────────────────────────

class _SumBlock extends StatelessWidget {
  final String  text;
  final TechTheme t;
  const _SumBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: const BorderRadius.only(
        topRight:    Radius.circular(6),
        bottomRight: Radius.circular(6),
      ),
      border: Border(left: BorderSide(color: t.green, width: 3)),
    ),
    child: Text(text, style: TextStyle(
        fontSize:   t.fs(9.5),
        color:      t.muted,
        fontFamily: t.font,
        height:     1.6),
        softWrap: true,
        overflow: TextOverflow.visible),
  );
}

class _ExpBlock extends StatelessWidget {
  final CVTemplateExperience e;
  final TechTheme t;
  const _ExpBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: t.border, width: 0.8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(e.company, style: TextStyle(
            fontSize:   t.fs(11),
            fontWeight: FontWeight.w700,
            color:      t.blue,
            fontFamily: t.font),
            softWrap: true,
            overflow: TextOverflow.visible)),
        const SizedBox(width: 8),
        Text(e.duration, style: TextStyle(
            fontSize: t.fs(9), color: t.muted, fontFamily: t.font)),
      ]),
      const SizedBox(height: 2),
      Text(e.role, style: TextStyle(
          fontSize: t.fs(10), color: t.green, fontFamily: t.font),
          softWrap: true,
          overflow: TextOverflow.visible),
      const SizedBox(height: 6),
      ...e.bullets.map((b) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('- ', style: TextStyle(
              fontSize: t.fs(9.5), color: t.green, fontFamily: t.font)),
          Expanded(child: Text(b, style: TextStyle(
              fontSize:   t.fs(9.5),
              color:      t.muted,
              height:     1.5,
              fontFamily: t.font),
              softWrap: true,
              overflow: TextOverflow.visible)),
        ]),
      )),
    ]),
  );
}

class _EduBlock extends StatelessWidget {
  final CVTemplateEducation e;
  final TechTheme t;
  const _EduBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: t.border, width: 0.8),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: t.greenBorder),
        ),
        child: Center(child: Text(
          e.period.length >= 4
              ? e.period.substring(e.period.length - 2)
              : e.period,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize:   t.fs(9),
              color:      t.green,
              fontWeight: FontWeight.w700,
              fontFamily: t.font),
        )),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Text(e.degree, style: TextStyle(
            fontSize:   t.fs(10),
            fontWeight: FontWeight.w700,
            color:      t.white,
            fontFamily: t.font),
            softWrap: true,
            overflow: TextOverflow.visible),
        Text(e.institution, style: TextStyle(
            fontSize: t.fs(9.5), color: t.muted, fontFamily: t.font),
            softWrap: true,
            overflow: TextOverflow.visible),
        if (e.detail != null && e.detail!.isNotEmpty)
          Text(e.detail!, style: TextStyle(
              fontSize: t.fs(9.5), color: t.green, fontFamily: t.font),
              softWrap: true,
              overflow: TextOverflow.visible),
      ])),
    ]),
  );
}

class _CertBlock extends StatelessWidget {
  final String  s;
  final TechTheme t;
  const _CertBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) {
    final p    = s.split(RegExp(r'\s+·\s+'));
    final name = p.isNotEmpty ? p[0].trim() : s;
    final by   = p.length > 1 ? p[1].trim() : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('# ', style: TextStyle(
            fontSize: t.fs(9.5), color: t.blue, fontFamily: t.font)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
          Text(name, style: TextStyle(
              fontSize:   t.fs(9.5),
              color:      t.muted,
              fontFamily: t.font,
              height:     1.4),
              softWrap: true,
              overflow: TextOverflow.visible),
          if (by.isNotEmpty) Text(by, style: TextStyle(
              fontSize: t.fs(9), color: t.green, fontFamily: t.font),
              softWrap: true,
              overflow: TextOverflow.visible),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCKS — SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────

class _SkillBlock extends StatelessWidget {
  final CVTemplateSkill s;
  final TechTheme t;
  const _SkillBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: Text(s.name, style: TextStyle(
            fontSize: t.fs(9.5), color: t.white, fontFamily: t.font),
            softWrap: true,
            overflow: TextOverflow.visible)),
        Text('${s.levelOutOf10 * 10}%', style: TextStyle(
            fontSize: t.fs(9), color: t.green, fontFamily: t.font)),
      ]),
      const SizedBox(height: 3),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(height: 3, child: Row(children: [
          Flexible(flex: s.levelOutOf10, child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.green, t.blue]),
            ),
          )),
          Flexible(flex: 10 - s.levelOutOf10,
              child: ColoredBox(color: t.border,
                  child: const SizedBox(height: 3))),
        ])),
      ),
    ]),
  );
}

class _SimpleBlock extends StatelessWidget {
  final String  t2;
  final String  prefix;
  final TechTheme t;
  const _SimpleBlock({required this.t2, required this.prefix, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(prefix, style: TextStyle(
          fontSize: t.fs(9.5), color: t.green, fontFamily: t.font)),
      Expanded(child: Text(t2, style: TextStyle(
          fontSize: t.fs(9.5), color: t.muted, fontFamily: t.font),
          softWrap: true,
          overflow: TextOverflow.visible)),
    ]),
  );
}

class _RefBlock extends StatelessWidget {
  final CVTemplateReferee r;
  final TechTheme t;
  const _RefBlock({required this.r, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(r.name, style: TextStyle(
          fontSize:   t.fs(10),
          fontWeight: FontWeight.w700,
          color:      t.white,
          fontFamily: t.font),
          softWrap: true,
          overflow: TextOverflow.visible),
      const SizedBox(height: 2),
      Text(r.title, style: TextStyle(
          fontSize: t.fs(9.5), color: t.green, fontFamily: t.font),
          softWrap: true,
          overflow: TextOverflow.visible),
      if (r.company != null && r.company!.isNotEmpty)
        Text(r.company!, style: TextStyle(
            fontSize: t.fs(9), color: t.muted, fontFamily: t.font),
            softWrap: true,
            overflow: TextOverflow.visible),
      const SizedBox(height: 4),
      if (r.email.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('@ ', style: TextStyle(
            fontSize: t.fs(9.5), color: t.blue, fontFamily: t.font)),
        Expanded(child: Text(r.email, style: TextStyle(
            fontSize: t.fs(9), color: t.muted, fontFamily: t.font),
            softWrap: true,
            overflow: TextOverflow.visible)),
      ]),
      if (r.phone.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('# ', style: TextStyle(
            fontSize: t.fs(9.5), color: t.blue, fontFamily: t.font)),
        Expanded(child: Text(r.phone, style: TextStyle(
            fontSize: t.fs(9), color: t.muted, fontFamily: t.font),
            softWrap: true,
            overflow: TextOverflow.visible)),
      ]),
    ]),
  );
}