// editorial_page_stationary_layout.dart
// lib/cv_layout_templates/07_editorial_cv_layout/editorial_page_stationary_layout.dart

import 'package:flutter/material.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'editorial_cv_logic_data.dart';

// ── Page geometry ─────────────────────────────────────────────────────────────
const double kEditPageW      = 595.0;
const double kEditPageH      = 842.0;
const double kEditTopBarH    =   5.0;
const double kEditFooterH    =  26.0;
const double kEditSideBarW   = 200.0;
const double kEditSidePadH   =  18.0;
const double kEditSidePadV   =  16.0;
const double kEditSideW      = kEditSideBarW - kEditSidePadH * 2;
const double kEditMainPadH   =  22.0;
const double kEditMainPadV   =  16.0;
const double kEditMainW      = kEditPageW - kEditSideBarW - kEditMainPadH * 2;
const double kEditBodyH      = kEditPageH - kEditTopBarH - kEditFooterH;
const double kEditDividerW   =   0.5;

// ── Palette ───────────────────────────────────────────────────────────────────
const Color kEditPaper    = Color(0xFFFAF8F5);
const Color kEditInk      = Color(0xFF111111);
const Color kEditRed      = Color(0xFFD0021B);
const Color kEditMuted    = Color(0xFF777777);
const Color kEditRule     = Color(0xFFDDDDDD);
const Color kEditSkillBg  = Color(0xFFE5E5E5);
const Color kEditLightMut = Color(0xFF999999);

const double kEditBaseFontSize = 12.0;

// ── Theme ─────────────────────────────────────────────────────────────────────
class EditTheme {
  final double fontScale;
  final String font;
  final Color  accent;

  const EditTheme({
    this.fontScale = 1.0,
    this.font      = 'sans-serif',
    this.accent    = kEditRed,
  });

  double fs(double base) => (base * fontScale).clamp(6.0, 32.0);
}

EditTheme editThemeFromData(CVTemplateData data) {
  final scale = (data.fontSize > 0 ? data.fontSize : kEditBaseFontSize) /
      kEditBaseFontSize;
  final font   = data.fontFamily.isNotEmpty ? data.fontFamily : 'sans-serif';
  final accent = data.accentColor != Colors.transparent
      ? data.accentColor
      : kEditRed;
  return EditTheme(fontScale: scale, font: font, accent: accent);
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: EditPageLayout
// ─────────────────────────────────────────────────────────────────────────────
class EditPageLayout extends StatelessWidget {
  final CVTemplateData  data;
  final List<EditItem>  mainItems;
  final List<EditItem>  sideItems;
  final int             pageNum;
  final int             totalPages;

  const EditPageLayout({
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
    final t  = editThemeFromData(data);

    return SizedBox(
      width:  kEditPageW,
      height: kEditPageH,
      child: Stack(children: [
        // Paper background
        Positioned.fill(child: ColoredBox(color: kEditPaper)),

        // Top red bar
        Positioned(
          top: 0, left: 0, right: 0, height: kEditTopBarH,
          child: ColoredBox(color: t.accent),
        ),

        // Body (between top bar and footer)
        Positioned(
          top:    kEditTopBarH,
          bottom: kEditFooterH,
          left:   0,
          right:  0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (page 1 only)
              if (p1) _EditHeader(data: data, t: t),

              // Two-column body
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bodyH = constraints.maxHeight;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Side column (left)
                        SizedBox(
                          width:  kEditSideBarW,
                          height: bodyH,
                          child: ClipRect(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kEditSidePadH,
                                  vertical:   kEditSidePadV),
                              child: SizedBox(
                                width:  kEditSideW,
                                height: bodyH - kEditSidePadV * 2,
                                child: OverflowBox(
                                  alignment:  Alignment.topLeft,
                                  minHeight:  0,
                                  maxHeight:  double.infinity,
                                  maxWidth:   kEditSideW,
                                  child: _SideCol(
                                      data: data, items: sideItems, t: t),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Vertical rule
                        Container(width: kEditDividerW, color: kEditRule),

                        // Main column (right)
                        Expanded(
                          child: ClipRect(
                            child: SizedBox(
                              height: bodyH,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: kEditMainPadH,
                                    vertical:   kEditMainPadV),
                                child: SizedBox(
                                  width:  kEditMainW,
                                  height: bodyH - kEditMainPadV * 2,
                                  child: OverflowBox(
                                    alignment:  Alignment.topLeft,
                                    minHeight:  0,
                                    maxHeight:  double.infinity,
                                    maxWidth:   kEditMainW,
                                    child: _MainCol(
                                        data: data, items: mainItems, t: t),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Footer
        Positioned(
          bottom: 0, left: 0, right: 0, height: kEditFooterH,
          child: Container(
            color: kEditPaper,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.fullName, style: TextStyle(
                    fontSize: 9, color: kEditMuted,
                    fontWeight: FontWeight.w600, letterSpacing: 1,
                    fontFamily: t.font)),
                Row(children: [
                  Container(
                    width: 4, height: 4,
                    decoration: BoxDecoration(
                        color: t.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('$pageNum / $totalPages', style: TextStyle(
                      fontSize: 9, color: kEditMuted, fontFamily: t.font)),
                ]),
                Text(data.email, style: TextStyle(
                    fontSize: 9, color: kEditMuted, fontFamily: t.font)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Editorial header ──────────────────────────────────────────────────────────
class _EditHeader extends StatelessWidget {
  final CVTemplateData data;
  final EditTheme      t;
  const _EditHeader({required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              // FIX: changed from CrossAxisAlignment.end → .start
              // so the name anchors to the top of the header row
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: name + job title
                Expanded(
                  flex: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // FIX: changed from MainAxisAlignment.end → .start
                    // so the name sits at the top rather than the bottom
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        data.fullName.toUpperCase(),
                        style: TextStyle(
                          fontSize:   t.fs(28),
                          fontWeight: FontWeight.w900,
                          color:      kEditInk,
                          height:     0.92,
                          letterSpacing: -0.8,
                          fontFamily: t.font,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Container(width: 22, height: 3, color: t.accent),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(data.jobTitle.toUpperCase(), style: TextStyle(
                              fontSize:   t.fs(8.5),
                              color:      t.accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              fontFamily: t.font)),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: contact block
                Expanded(
                  flex: 45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // FIX: changed from MainAxisAlignment.end → .start
                    // so contact lines align with the top of the name
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.email.isNotEmpty)    _ContactLine(text: data.email,    t: t),
                      if (data.phone.isNotEmpty)    _ContactLine(text: data.phone,    t: t),
                      if (data.location.isNotEmpty) _ContactLine(text: data.location, t: t),
                      if (data.website.isNotEmpty)  _ContactLine(text: data.website,  t: t),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1.0, color: kEditInk),
          const SizedBox(height: 3),
          Container(height: 0.3, color: kEditInk),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final String    text;
  final EditTheme t;
  const _ContactLine({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      textAlign: TextAlign.end,
      softWrap:  true,
      overflow:  TextOverflow.visible,
      style: TextStyle(
          fontSize: t.fs(9.5), color: kEditMuted,
          letterSpacing: 0.2, height: 1.4, fontFamily: t.font),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: Section label
// ─────────────────────────────────────────────────────────────────────────────
class EditSecLabel extends StatelessWidget {
  final String    label;
  final EditTheme t;
  const EditSecLabel({required this.label, required this.t});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(
          fontSize: t.fs(8.5), fontWeight: FontWeight.w900,
          color: kEditInk, letterSpacing: 2.5, fontFamily: t.font)),
      const SizedBox(height: 4),
      Container(height: 0.5, color: kEditRule),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDE COLUMN (left): About, Skills, Languages, Hobbies, Education, References
// ─────────────────────────────────────────────────────────────────────────────
class _SideCol extends StatelessWidget {
  final CVTemplateData data;
  final List<EditItem> items;
  final EditTheme      t;
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
        if (ws.isNotEmpty) ws.add(const SizedBox(height: 18));
        ws.add(EditSecLabel(label: _sideLbl(it.section), t: t));
        ws.add(const SizedBox(height: 8));
      }
      ws.add(_block(it));
    }
    return ws;
  }

  Widget _block(EditItem it) => switch (it.section) {
    EditSection.summary   => _SumBlock(text: data.summary, t: t),
    EditSection.skill     => _SkillBlock(s: data.skills[it.index], t: t),
    EditSection.language  => _SimpleBlock(text: data.languages[it.index], t: t),
    EditSection.hobby     => _SimpleBlock(text: data.hobbies[it.index], t: t),
    EditSection.education => _EduBlock(e: data.education[it.index], t: t),
    EditSection.reference => _RefBlock(r: data.references[it.index], t: t),
    _                     => const SizedBox.shrink(),
  };

  String _sideLbl(EditSection s) => switch (s) {
    EditSection.summary   => 'ABOUT',
    EditSection.skill     => 'SKILLS',
    EditSection.language  => 'LANGUAGES',
    EditSection.hobby     => 'HOBBIES',
    EditSection.education => 'EDUCATION',
    EditSection.reference => 'REFERENCES',
    _                     => 'SECTION',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN COLUMN (right): Experience, Certifications
// ─────────────────────────────────────────────────────────────────────────────
class _MainCol extends StatelessWidget {
  final CVTemplateData data;
  final List<EditItem> items;
  final EditTheme      t;
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
        ws.add(EditSecLabel(label: _mainLbl(it.section), t: t));
        ws.add(const SizedBox(height: 10));
      }
      ws.add(_block(it));
    }
    return ws;
  }

  Widget _block(EditItem it) => switch (it.section) {
    EditSection.experience    => _ExpBlock(e: data.experience[it.index], t: t),
    EditSection.certification => _CertBlock(s: data.certifications[it.index], t: t),
    _                         => const SizedBox.shrink(),
  };

  String _mainLbl(EditSection s) => switch (s) {
    EditSection.experience    => 'EXPERIENCE',
    EditSection.certification => 'CERTIFICATIONS',
    _                         => 'SECTION',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCKS — SIDE
// ─────────────────────────────────────────────────────────────────────────────
class _SumBlock extends StatelessWidget {
  final String    text;
  final EditTheme t;
  const _SumBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      softWrap: true,
      style: TextStyle(
          fontSize: t.fs(10.5), color: kEditMuted,
          height: 1.75, fontFamily: t.font),
    ),
  );
}

class _SkillBlock extends StatelessWidget {
  final CVTemplateSkill s;
  final EditTheme       t;
  const _SkillBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.name, style: TextStyle(
            fontSize: t.fs(10), color: kEditInk,
            fontWeight: FontWeight.w500, fontFamily: t.font)),
        const SizedBox(height: 3),
        SizedBox(
          height: 2,
          child: Stack(children: [
            Positioned.fill(child: ColoredBox(color: kEditSkillBg)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (s.levelOutOf10 / 10.0).clamp(0.0, 1.0),
              child: ColoredBox(color: t.accent),
            ),
          ]),
        ),
      ],
    ),
  );
}

class _SimpleBlock extends StatelessWidget {
  final String    text;
  final EditTheme t;
  const _SimpleBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        softWrap: true,
        style: TextStyle(
        fontSize: t.fs(10.5), color: kEditMuted,
        height: 1.5, fontFamily: t.font)),
  );
}

class _EduBlock extends StatelessWidget {
  final CVTemplateEducation e;
  final EditTheme           t;
  const _EduBlock({required this.e, required this.t});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(e.period, style: TextStyle(
            fontSize: t.fs(10), color: t.accent,
            fontWeight: FontWeight.w700, letterSpacing: 0.4,
            fontFamily: t.font)),
        const SizedBox(height: 3),
        Text(e.degree, style: TextStyle(
            fontSize: t.fs(10.5), fontWeight: FontWeight.w700,
            color: kEditInk, height: 1.3, fontFamily: t.font)),
        const SizedBox(height: 2),
        Text(e.institution, style: TextStyle(
            fontSize: t.fs(10), color: kEditMuted,
            height: 1.4, fontFamily: t.font)),
        if (e.detail != null && e.detail!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(e.detail!, style: TextStyle(
              fontSize: t.fs(9.5), color: kEditMuted,
              height: 1.45, fontFamily: t.font)),
        ],
      ],
    ),
  );
}

class _RefBlock extends StatelessWidget {
  final CVTemplateReferee r;
  final EditTheme         t;
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
            color: kEditInk, fontFamily: t.font)),
        Text(r.title, style: TextStyle(
            fontSize: t.fs(9.5), color: t.accent,
            fontWeight: FontWeight.w600, fontFamily: t.font)),
        if (r.company != null && r.company!.isNotEmpty)
          Text(r.company!, style: TextStyle(
              fontSize: t.fs(9.5), color: kEditMuted, fontFamily: t.font)),
        if (r.email.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(r.email, style: TextStyle(
              fontSize: t.fs(9), color: kEditMuted, fontFamily: t.font),
              overflow: TextOverflow.ellipsis),
        ],
        if (r.phone.isNotEmpty)
          Text(r.phone, style: TextStyle(
              fontSize: t.fs(9), color: kEditMuted, fontFamily: t.font)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT BLOCKS — MAIN
// ─────────────────────────────────────────────────────────────────────────────
class _ExpBlock extends StatelessWidget {
  final CVTemplateExperience e;
  final EditTheme            t;
  const _ExpBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.role, style: TextStyle(
                    fontSize: t.fs(12.5), fontWeight: FontWeight.w800,
                    color: kEditInk, height: 1.2, fontFamily: t.font)),
                Text(e.company, style: TextStyle(
                    fontSize: t.fs(11), color: t.accent,
                    fontWeight: FontWeight.w600, fontFamily: t.font)),
              ],
            )),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: kEditRule),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(e.duration, style: TextStyle(
                  fontSize: t.fs(9), color: kEditMuted,
                  fontFamily: t.font)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...e.bullets.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('—  ', style: TextStyle(
                color: t.accent, fontSize: t.fs(10.5),
                fontWeight: FontWeight.w700)),
            Expanded(child: Text(b, style: TextStyle(
                fontSize: t.fs(10.5), color: kEditMuted,
                height: 1.5, fontFamily: t.font))),
          ]),
        )),
      ],
    ),
  );
}

class _CertBlock extends StatelessWidget {
  final String    s;
  final EditTheme t;
  const _CertBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('→  ', style: TextStyle(
          fontSize: t.fs(10.5), color: t.accent,
          fontWeight: FontWeight.w700)),
      Expanded(child: Text(s, style: TextStyle(
          fontSize: t.fs(10.5), color: kEditMuted,
          height: 1.4, fontFamily: t.font))),
    ]),
  );
}