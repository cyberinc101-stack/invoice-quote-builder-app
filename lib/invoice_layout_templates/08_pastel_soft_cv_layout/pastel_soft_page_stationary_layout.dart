// pastel_soft_page_stationary_layout.dart
// lib/cv_layout_templates/08_pastel_soft_cv_layout/pastel_soft_page_stationary_layout.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'pastel_soft_cv_logic_data.dart';

// ── Page geometry ─────────────────────────────────────────────────────────────
const double kPastelPageW    = 595.0;
const double kPastelPageH    = 842.0;
const double kPastelSideW    = 164.0;
const double kPastelSidePadH =  16.0;
const double kPastelSidePadV =  20.0;
const double kPastelSideInW  = kPastelSideW - kPastelSidePadH * 2;
const double kPastelMainPadH =  20.0;
const double kPastelMainPadV =  20.0;
const double kPastelMainW    = kPastelPageW - kPastelSideW - kPastelMainPadH * 2;
const double kPastelBodyH    = kPastelPageH;

// Safety margin subtracted from paginator budgets — prevents last item being
// clipped by the ClipRect. Set to 32px to absorb:
//   • sub-pixel rounding across many items
//   • inter-section gaps (SizedBox 14 + SizedBox 8 = 22px) added in _buildItems
//     that are not included in individual item height measurements
//   • any font-scale variance at the bottom of the column
const double kPastelSafetyMargin = 32.0;

// ── Image size ────────────────────────────────────────────────────────────────
double pastelImgPx(double imageSize) {
  if (imageSize <= 20) {
    return 40.0 + (imageSize - 10.0) / 10.0 * 80.0;
  }
  return imageSize.clamp(40.0, 120.0);
}

// ── Palette ───────────────────────────────────────────────────────────────────
const Color kPastelLavender  = Color(0xFFEDE7F6);
const Color kPastelLavD      = Color(0xFF7C5CBF);
const Color kPastelLavM      = Color(0xFFB39DDB);
const Color kPastelPeach     = Color(0xFFE8845D);
const Color kPastelInk       = Color(0xFF2D2D3A);
const Color kPastelMuted     = Color(0xFF7B7B8F);
const Color kPastelBg        = Color(0xFFFAFAFC);
const Color kPastelLavDBg12  = Color(0x1F7C5CBF);
const Color kPastelLavMBd50  = Color(0x80B39DDB);
const Color kPastelLavDSh07  = Color(0x127C5CBF);
const Color kPastelLavDSh05  = Color(0x0D7C5CBF);
const Color kPastelPeachBg   = Color(0x33E8845D);
const Color kPastelSkillTrk  = Color(0x1F7C5CBF);

const double kPastelBaseFontSize = 12.0;

// ── Theme ─────────────────────────────────────────────────────────────────────
class PastelTheme {
  final double fontScale;
  final String font;
  final Color  accent;

  const PastelTheme({
    this.fontScale = 1.0,
    this.font      = 'sans-serif',
    this.accent    = kPastelLavD,
  });

  double fs(double base) => (base * fontScale).clamp(6.0, 32.0);
}

PastelTheme pastelThemeFromData(CVTemplateData data) {
  final scale  = (data.fontSize > 0 ? data.fontSize : kPastelBaseFontSize) /
      kPastelBaseFontSize;
  final font   = data.fontFamily.isNotEmpty ? data.fontFamily : 'sans-serif';
  final accent = data.accentColor != Colors.transparent
      ? data.accentColor
      : kPastelLavD;
  return PastelTheme(fontScale: scale, font: font, accent: accent);
}

// ─────────────────────────────────────────────────────────────────────────────
// PastelPageLayout
// ─────────────────────────────────────────────────────────────────────────────
class PastelPageLayout extends StatelessWidget {
  final CVTemplateData   data;
  final List<PastelItem> mainItems;
  final List<PastelItem> sideItems;
  final int              pageNum;
  final int              totalPages;

  const PastelPageLayout({
    super.key,
    required this.data,
    required this.mainItems,
    required this.sideItems,
    required this.pageNum,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final t  = pastelThemeFromData(data);
    final p1 = pageNum == 1;

    return SizedBox(
      width:  kPastelPageW,
      height: kPastelPageH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Lavender sidebar ───────────────────────────────────────────────
          // FIX: replaced SizedBox > ClipRect > ColoredBox > Padding >
          //      SizedBox > OverflowBox with ClipRect > ColoredBox > Padding >
          //      Column. OverflowBox(maxHeight: infinity) was removing the
          //      height constraint, allowing content to render past the ClipRect
          //      boundary and get clipped horizontally at the bottom.
          SizedBox(
            width: kPastelSideW,
            child: ClipRect(
              child: ColoredBox(
                color: kPastelLavender,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kPastelSidePadH,
                    vertical:   kPastelSidePadV,
                  ),
                  // FIX: SizedBox with fixed height so content that slightly
                  // exceeds budget is silently clipped by the parent ClipRect
                  // rather than throwing a RenderFlex overflow error.
                  child: SizedBox(
                    width:  kPastelSideInW,
                    height: kPastelPageH - kPastelSidePadV * 2,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxWidth:  kPastelSideInW,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: _SideCol(
                        data: data, items: sideItems, t: t, isPage1: p1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          Expanded(
            child: ClipRect(
              child: ColoredBox(
                color: kPastelBg,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kPastelMainPadH,
                    vertical:   kPastelMainPadV,
                  ),
                  // FIX: same pattern — SizedBox bounds the content area,
                  // OverflowBox lets the Column grow naturally inside it,
                  // parent ClipRect silently clips anything that exceeds.
                  child: SizedBox(
                    width:  kPastelMainW,
                    height: kPastelPageH - kPastelMainPadV * 2,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxWidth:  kPastelMainW,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: _MainCol(
                        data: data, items: mainItems, t: t, isPage1: p1,
                      ),
                    ),
                  ),
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
// Helper: wrap a widget with clip+translate when it is a split fragment
// ─────────────────────────────────────────────────────────────────────────────
Widget _wrapSplit(Widget child, PastelItem it, double innerW) {
  if (it.clipH == null && it.alreadyShown == 0) return child;
  final windowH = it.clipH ?? (it.height - it.alreadyShown);
  return SizedBox(
    height: windowH,
    child: ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minHeight: 0,
        maxHeight: double.infinity,
        minWidth:  innerW,
        maxWidth:  innerW,
        child: Transform.translate(
          offset: Offset(0, -it.alreadyShown),
          child: child,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDE COLUMN — plain Column, width constrained by parent Padding/SizedBox
// ─────────────────────────────────────────────────────────────────────────────
class _SideCol extends StatelessWidget {
  final CVTemplateData   data;
  final List<PastelItem> items;
  final PastelTheme      t;
  final bool             isPage1;

  const _SideCol({
    required this.data,
    required this.items,
    required this.t,
    required this.isPage1,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isPage1) ..._buildHeader(),
      ..._buildItems(),
    ],
  );

  List<Widget> _buildHeader() {
    final imgPx = pastelImgPx(data.imageSize);
    return [
      Center(
        child: data.profileImagePath != null
            ? ClipOval(
                child: SizedBox(
                  width: imgPx, height: imgPx,
                  child: Image.file(
                      File(data.profileImagePath!), fit: BoxFit.cover),
                ),
              )
            : Container(
                width: imgPx, height: imgPx,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPastelLavDBg12,
                  border: Border.all(color: t.accent, width: 2.5),
                ),
                child: Icon(Icons.person_rounded, color: t.accent,
                    size: (imgPx * 0.45).clamp(16.0, 52.0)),
              ),
      ),
      const SizedBox(height: 10),
      Text(data.fullName,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(12), fontWeight: FontWeight.w800,
              color: kPastelInk, height: 1.3, fontFamily: t.font)),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: kPastelLavDBg12,
            borderRadius: BorderRadius.circular(16)),
        child: Text(data.jobTitle,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(9), color: t.accent,
                fontWeight: FontWeight.w600, fontFamily: t.font)),
      ),
      const SizedBox(height: 16),
      _SideLabel(label: 'CONTACT', t: t),
      const SizedBox(height: 8),
      if (data.email.isNotEmpty)
        _ContactRow(icon: Icons.email_outlined,       text: data.email,    t: t),
      if (data.phone.isNotEmpty)
        _ContactRow(icon: Icons.phone_outlined,       text: data.phone,    t: t),
      if (data.location.isNotEmpty)
        _ContactRow(icon: Icons.location_on_outlined, text: data.location, t: t),
      if (data.website.isNotEmpty)
        _ContactRow(icon: Icons.language_outlined,    text: data.website,  t: t),
      const SizedBox(height: 6),
    ];
  }

  List<Widget> _buildItems() {
    final ws = <Widget>[];
    for (final it in items) {
      if (it.showLabel) {
        if (ws.isNotEmpty) ws.add(const SizedBox(height: 14));
        ws.add(_SideLabel(label: _lbl(it.section), t: t, cont: it.isContinued));
        ws.add(const SizedBox(height: 8));
      }
      ws.add(_wrapSplit(_block(it), it, kPastelSideInW));
    }
    return ws;
  }

  Widget _block(PastelItem it) => switch (it.section) {
    PastelSection.skill     => _SkillTag(name: data.skills[it.index].name, t: t),
    PastelSection.language  => _LangItem(text: data.languages[it.index],   t: t),
    PastelSection.hobby     => _LangItem(text: data.hobbies[it.index],     t: t),
    PastelSection.reference => _RefBlock(r: data.references[it.index],     t: t),
    _                       => const SizedBox.shrink(),
  };

  String _lbl(PastelSection s) => switch (s) {
    PastelSection.skill     => 'SKILLS',
    PastelSection.language  => 'LANGUAGES',
    PastelSection.hobby     => 'INTERESTS',
    PastelSection.reference => 'REFERENCES',
    _                       => 'SECTION',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN COLUMN — plain Column, width constrained by parent Padding
// ─────────────────────────────────────────────────────────────────────────────
class _MainCol extends StatelessWidget {
  final CVTemplateData   data;
  final List<PastelItem> items;
  final PastelTheme      t;
  final bool             isPage1;

  const _MainCol({
    required this.data,
    required this.items,
    required this.t,
    required this.isPage1,
  });

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
        if (ws.isNotEmpty) ws.add(const SizedBox(height: 10));
        ws.add(_MainLabel(
          label: _lbl(it.section),
          color: _lblColor(it.section),
          t:     t,
          cont:  it.isContinued,
        ));
        ws.add(const SizedBox(height: 6));
      }
      ws.add(_wrapSplit(_block(it), it, kPastelMainW));
    }
    return ws;
  }

  Widget _block(PastelItem it) => switch (it.section) {
    PastelSection.summary       => _SummaryBlock(text: data.summary,                  t: t),
    PastelSection.experience    => _ExpCard(e: data.experience[it.index],             t: t),
    PastelSection.education     => _EduCard(e: data.education[it.index],              t: t),
    PastelSection.certification => _CertItem(text: data.certifications[it.index],     t: t),
    _                           => const SizedBox.shrink(),
  };

  String _lbl(PastelSection s) => switch (s) {
    PastelSection.summary       => 'About Me',
    PastelSection.experience    => 'Experience',
    PastelSection.education     => 'Education',
    PastelSection.certification => 'Certifications',
    _                           => 'Section',
  };

  Color _lblColor(PastelSection s) => switch (s) {
    PastelSection.summary       => kPastelPeach,
    PastelSection.experience    => kPastelLavD,
    PastelSection.education     => kPastelLavD,
    PastelSection.certification => kPastelLavD,
    _                           => kPastelLavD,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SideLabel extends StatelessWidget {
  final String      label;
  final PastelTheme t;
  final bool        cont;
  const _SideLabel({required this.label, required this.t, this.cont = false});

  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(cont ? '$label (CONT.)' : label,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(9.5), fontWeight: FontWeight.w700,
              color: kPastelLavD, letterSpacing: 2, fontFamily: t.font)),
      const SizedBox(height: 4),
      Container(height: 1, color: kPastelLavMBd50),
    ],
  );
}

class _ContactRow extends StatelessWidget {
  final IconData    icon;
  final String      text;
  final PastelTheme t;
  const _ContactRow({required this.icon, required this.text, required this.t});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(color: kPastelLavDBg12,
            borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 12, color: kPastelLavD),
      ),
      const SizedBox(width: 7),
      Expanded(child: Text(text,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(9), color: kPastelMuted,
              height: 1.35, fontFamily: t.font))),
    ]),
  );
}

class _SkillTag extends StatelessWidget {
  final String      name;
  final PastelTheme t;
  const _SkillTag({required this.name, required this.t});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPastelLavMBd50)),
      child: Text(name,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(9.5), color: kPastelInk,
              fontWeight: FontWeight.w500, fontFamily: t.font)),
    ),
  );
}

class _LangItem extends StatelessWidget {
  final String      text;
  final PastelTheme t;
  const _LangItem({required this.text, required this.t});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text,
        softWrap: true, overflow: TextOverflow.visible,
        style: TextStyle(fontSize: t.fs(9.5), color: kPastelMuted,
            height: 1.4, fontFamily: t.font)),
  );
}

class _RefBlock extends StatelessWidget {
  final CVTemplateReferee r;
  final PastelTheme       t;
  const _RefBlock({required this.r, required this.t});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(r.name,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(10), fontWeight: FontWeight.w700,
                color: kPastelInk, height: 1.3, fontFamily: t.font)),
        const SizedBox(height: 2),
        Text(r.title,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(9), color: kPastelLavD,
                fontWeight: FontWeight.w600, height: 1.3, fontFamily: t.font)),
        if (r.company != null && r.company!.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(r.company!,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: t.fs(9), color: kPastelMuted,
                  height: 1.3, fontFamily: t.font)),
        ],
        const SizedBox(height: 5),
        if (r.email.isNotEmpty)
          _RefContactRow(icon: Icons.email_outlined, text: r.email, t: t),
        if (r.phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          _RefContactRow(icon: Icons.phone_outlined, text: r.phone, t: t),
        ],
      ],
    ),
  );
}

class _RefContactRow extends StatelessWidget {
  final IconData    icon;
  final String      text;
  final PastelTheme t;
  const _RefContactRow({required this.icon, required this.text, required this.t});

  @override
  Widget build(BuildContext ctx) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(color: kPastelLavDBg12,
            borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 11, color: kPastelLavD),
      ),
      const SizedBox(width: 5),
      Expanded(child: Text(text,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(8.5), color: kPastelMuted,
              height: 1.35, fontFamily: t.font))),
    ],
  );
}

class _MainLabel extends StatelessWidget {
  final String      label;
  final Color       color;
  final PastelTheme t;
  final bool        cont;
  const _MainLabel({required this.label, required this.color,
      required this.t, this.cont = false});

  @override
  Widget build(BuildContext ctx) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color.fromRGBO(color.red, color.green, color.blue, 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(cont ? '$label (cont.)' : label,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(11), fontWeight: FontWeight.w700,
                color: color, fontFamily: t.font)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1,
          color: Color.fromRGBO(color.red, color.green, color.blue, 0.15))),
    ],
  );
}

class _SummaryBlock extends StatelessWidget {
  final String      text;
  final PastelTheme t;
  const _SummaryBlock({required this.text, required this.t});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPastelPeachBg,
          borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
              height: 1.7, fontFamily: t.font)),
    ),
  );
}

class _ExpCard extends StatelessWidget {
  final CVTemplateExperience e;
  final PastelTheme          t;
  const _ExpCard({required this.e, required this.t});

  @override
  Widget build(BuildContext ctx) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(
          color: kPastelLavDSh07, blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(e.role,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: t.fs(12), fontWeight: FontWeight.w700,
                  color: kPastelInk, fontFamily: t.font))),
          const SizedBox(width: 8),
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: kPastelLavender,
                  borderRadius: BorderRadius.circular(14)),
              child: Text(e.duration,
                  softWrap: false, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: t.fs(9), color: kPastelLavD,
                      fontFamily: t.font)),
            ),
          ),
        ]),
        const SizedBox(height: 3),
        Text(e.company,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(11), color: kPastelPeach,
                fontWeight: FontWeight.w600, fontFamily: t.font)),
        if (e.bullets.isNotEmpty) ...[
          const SizedBox(height: 7),
          ...e.bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 5),
                  child: Container(width: 5, height: 5,
                      decoration: const BoxDecoration(
                          color: kPastelLavM, shape: BoxShape.circle))),
              const SizedBox(width: 7),
              Expanded(child: Text(b,
                  softWrap: true, overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
                      height: 1.4, fontFamily: t.font))),
            ]),
          )),
        ],
      ],
    ),
  );
}

class _EduCard extends StatelessWidget {
  final CVTemplateEducation e;
  final PastelTheme         t;
  const _EduCard({required this.e, required this.t});

  @override
  Widget build(BuildContext ctx) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(
          color: kPastelLavDSh05, blurRadius: 10, offset: Offset(0, 3))],
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: kPastelLavender,
            borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(
          e.period.split('–').last.trim().split(' ').last,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: t.fs(10), fontWeight: FontWeight.w700,
              color: kPastelLavD, fontFamily: t.font)))),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.degree,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: t.fs(12), fontWeight: FontWeight.w700,
                  color: kPastelInk, fontFamily: t.font)),
          Text(e.institution,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
                  fontFamily: t.font)),
          if (e.detail != null && e.detail!.isNotEmpty)
            Text(e.detail!,
                softWrap: true, overflow: TextOverflow.visible,
                style: TextStyle(fontSize: t.fs(10), color: kPastelMuted,
                    fontFamily: t.font)),
        ],
      )),
    ]),
  );
}

class _CertItem extends StatelessWidget {
  final String      text;
  final PastelTheme t;
  const _CertItem({required this.text, required this.t});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 5),
          child: Container(width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: kPastelLavM, shape: BoxShape.circle))),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
              height: 1.4, fontFamily: t.font))),
    ]),
  );
}