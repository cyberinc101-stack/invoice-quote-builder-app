// tech_cv_logic_data.dart
// lib/cv_layout_templates/04_tech_cv_layout/tech_cv_logic_data.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'tech_page_stationary_layout.dart';

enum TechSection {
  summary, experience, education, certification,
  skill, language, hobby, reference,
}

class TechItem {
  final TechSection section;
  final int         index;
  final double      height;
  final bool        showLabel;
  final bool        isContinued;

  const TechItem({
    required this.section,
    required this.index,
    required this.height,
    this.showLabel   = true,
    this.isContinued = false,
  });
}

class _Page {
  final List<TechItem> main;
  final List<TechItem> side;
  const _Page({this.main = const [], this.side = const []});
}

class TechMeasureKeys {
  final Map<String, GlobalKey> _m = {};

  GlobalKey op(String id) =>
      _m.putIfAbsent(id, () => GlobalKey(debugLabel: 'tm_$id'));

  void clear() => _m.clear();

  double? _h(String id) {
    final k = _m[id];
    if (k == null) return null;
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final h = box.size.height;
    if (h.isInfinite || h.isNaN || h <= 0) return null;
    return h;
  }

  Map<String, double>? readAll(CVTemplateData d) {
    final r = <String, double>{};
    double? g(String id) {
      final v = _h(id);
      if (v == null) return null;
      r[id] = v;
      return v;
    }

    if (g('lm') == null || g('ls') == null) return null;
    if (g('p1side') == null || g('p1main') == null) return null;
    if (d.summary.isNotEmpty && g('sum') == null) return null;
    for (int i = 0; i < d.experience.length;     i++) { if (g('e$i')  == null) return null; }
    for (int i = 0; i < d.education.length;      i++) { if (g('d$i')  == null) return null; }
    for (int i = 0; i < d.certifications.length; i++) { if (g('c$i')  == null) return null; }
    for (int i = 0; i < d.skills.length;         i++) { if (g('sk$i') == null) return null; }
    for (int i = 0; i < d.languages.length;      i++) { if (g('la$i') == null) return null; }
    for (int i = 0; i < d.hobbies.length;        i++) { if (g('ho$i') == null) return null; }
    for (int i = 0; i < d.references.length;     i++) { if (g('re$i') == null) return null; }
    return r;
  }
}

const double _kFitTol       = 0.5;
const double _kSafetyMargin = 18.0;

List<_Page> _paginate(Map<String, double> h, CVTemplateData d) {
  final lm               = h['lm']!;
  final ls               = h['ls']!;
  final page1SideHeaderH = h['p1side']!;
  final page1MainHeaderH = h['p1main']!;
  final base             = kTechBodyH - kTechSidePadV * 2;

  final mq = <TechItem>[
    if (d.summary.isNotEmpty)
      TechItem(section: TechSection.summary,       index: -1, height: h['sum']  ?? 0),
    for (int i = 0; i < d.experience.length;     i++)
      TechItem(section: TechSection.experience,    index: i,  height: h['e$i']  ?? 0),
    for (int i = 0; i < d.education.length;      i++)
      TechItem(section: TechSection.education,     index: i,  height: h['d$i']  ?? 0),
    for (int i = 0; i < d.certifications.length; i++)
      TechItem(section: TechSection.certification, index: i,  height: h['c$i']  ?? 0),
  ];

  final sq = <TechItem>[
    for (int i = 0; i < d.skills.length;     i++)
      TechItem(section: TechSection.skill,     index: i, height: h['sk$i'] ?? 0),
    for (int i = 0; i < d.languages.length;  i++)
      TechItem(section: TechSection.language,  index: i, height: h['la$i'] ?? 0),
    for (int i = 0; i < d.hobbies.length;    i++)
      TechItem(section: TechSection.hobby,     index: i, height: h['ho$i'] ?? 0),
    for (int i = 0; i < d.references.length; i++)
      TechItem(section: TechSection.reference, index: i, height: h['re$i'] ?? 0),
  ];

  final mp = _greedy(mq, lm, base, page1MainHeaderH);
  final sp = _greedy(sq, ls, base, page1SideHeaderH);
  final n  = mp.length > sp.length ? mp.length : sp.length;
  return List.generate(n, (i) => _Page(
    main: i < mp.length ? mp[i] : const [],
    side: i < sp.length ? sp[i] : const [],
  ));
}

List<List<TechItem>> _greedy(
    List<TechItem> q, double lblH, double baseH, double page1HeaderH) {
  final pages = <List<TechItem>>[];
  int qi = 0, pn = 1;
  final seen = <TechSection>{};

  while (qi < q.length && pn <= 30) {
    final pageH = pn == 1 ? baseH - page1HeaderH : baseH;
    double avail = pageH - _kSafetyMargin;
    final pg = <TechItem>[];
    TechSection? prev;

    while (qi < q.length) {
      final it   = q[qi];
      final nl   = it.section != prev;
      final cost = (nl ? lblH : 0) + it.height;
      if (avail < cost - _kFitTol && pg.isNotEmpty) break;
      avail -= cost;
      pg.add(TechItem(
        section:     it.section,
        index:       it.index,
        height:      it.height,
        showLabel:   nl,
        isContinued: nl && seen.contains(it.section),
      ));
      if (nl) seen.add(it.section);
      prev = it.section;
      qi++;
    }

    if (pg.isNotEmpty) pages.add(pg);
    pn++;
  }
  return pages;
}

class TechPreview extends StatefulWidget {
  final CVTemplateData      data;
  final bool                isLight;
  final void Function(int)? onPageCount;
  const TechPreview({
    super.key,
    required this.data,
    this.isLight = false,
    this.onPageCount,
  });

  @override
  State<TechPreview> createState() => _TechPreviewState();
}

class _TechPreviewState extends State<TechPreview> {
  List<_Page>? _pages;
  int          _gen = 0;
  final TechMeasureKeys _k = TechMeasureKeys();

  @override
  void initState() { super.initState(); _kick(); }

  @override
  void didUpdateWidget(TechPreview old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data || old.isLight != widget.isLight) {
      _k.clear();
      setState(() => _pages = null);
      _kick();
    }
  }

  void _kick() {
    _gen++;
    final g = _gen;
    SchedulerBinding.instance.addPostFrameCallback((_) => _attempt(g));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && g == _gen && _pages == null) {
        setState(() => _pages = [const _Page()]);
      }
    });
  }

  void _attempt(int g) {
    if (!mounted || g != _gen) return;
    final h = _k.readAll(widget.data);
    if (h == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _attempt(g));
      return;
    }
    if (!mounted || g != _gen) return;
    final pages = _paginate(h, widget.data);
    setState(() => _pages = pages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPageCount?.call(pages.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d           = widget.data;
    final t           = techThemeFromData(d, isLight: widget.isLight);
    final spinnerColor = t.green;
    final spinnerBg    = t.bg;

    return SizedBox(
      width: kTechPageW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Off-screen measurement — MUST use explicit bounded constraints ──
          // OverflowBox with minWidth/maxWidth prevents infinite layout crashes.
          SizedBox(
            width: kTechPageW,
            height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: 0,
              maxHeight: 20000,
              minWidth:  kTechPageW,
              maxWidth:  kTechPageW,
              child: Offstage(
                child: _MeasureLayer(data: d, keys: _k, t: t),
              ),
            ),
          ),

          if (_pages == null)
            SizedBox(
              width: kTechPageW, height: kTechPageH,
              child: ColoredBox(
                color: spinnerBg,
                child: Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: spinnerColor)),
              ),
            ),

          if (_pages != null)
            ...List.generate(_pages!.length, (i) {
              final last = i == _pages!.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                child: TechPageLayout(
                  data:       d,
                  mainItems:  _pages![i].main,
                  sideItems:  _pages![i].side,
                  pageNum:    i + 1,
                  totalPages: _pages!.length,
                  isLight:    widget.isLight,
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASURE LAYER
// All text MUST use softWrap: true / overflow: TextOverflow.visible to match
// the render widgets so pagination heights are accurate.
// ─────────────────────────────────────────────────────────────────────────────

class _MeasureLayer extends StatelessWidget {
  final CVTemplateData  data;
  final TechMeasureKeys keys;
  final TechTheme       t;
  const _MeasureLayer({required this.data, required this.keys, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [

      SizedBox(width: kTechMainW, child: KeyedSubtree(key: keys.op('lm'),
          child: _MLabel(isMain: true, t: t))),
      SizedBox(width: kTechSideW, child: KeyedSubtree(key: keys.op('ls'),
          child: _MLabel(isMain: false, t: t))),

      SizedBox(width: kTechSideW, child: KeyedSubtree(key: keys.op('p1side'),
          child: _MPage1SideHeader(data: data, t: t))),
      SizedBox(width: kTechMainW, child: KeyedSubtree(key: keys.op('p1main'),
          child: _MPage1MainHeader(data: data, t: t))),

      if (data.summary.isNotEmpty)
        SizedBox(width: kTechMainW, child: KeyedSubtree(key: keys.op('sum'),
            child: _MSumBlock(text: data.summary, t: t))),
      for (int i = 0; i < data.experience.length; i++)
        SizedBox(width: kTechMainW, child: KeyedSubtree(key: keys.op('e$i'),
            child: _MExpBlock(e: data.experience[i], t: t))),
      for (int i = 0; i < data.education.length; i++)
        SizedBox(width: kTechMainW, child: KeyedSubtree(key: keys.op('d$i'),
            child: _MEduBlock(e: data.education[i], t: t))),
      for (int i = 0; i < data.certifications.length; i++)
        SizedBox(width: kTechMainW, child: KeyedSubtree(key: keys.op('c$i'),
            child: _MCertBlock(s: data.certifications[i], t: t))),
      for (int i = 0; i < data.skills.length; i++)
        SizedBox(width: kTechSideW, child: KeyedSubtree(key: keys.op('sk$i'),
            child: _MSkillBlock(s: data.skills[i], t: t))),
      for (int i = 0; i < data.languages.length; i++)
        SizedBox(width: kTechSideW, child: KeyedSubtree(key: keys.op('la$i'),
            child: _MSimpleBlock(text: data.languages[i], t: t))),
      for (int i = 0; i < data.hobbies.length; i++)
        SizedBox(width: kTechSideW, child: KeyedSubtree(key: keys.op('ho$i'),
            child: _MSimpleBlock(text: data.hobbies[i], t: t))),
      for (int i = 0; i < data.references.length; i++)
        SizedBox(width: kTechSideW, child: KeyedSubtree(key: keys.op('re$i'),
            child: _MRefBlock(r: data.references[i], t: t))),
    ]);
  }
}

// ── Measure: page-1 sidebar header ───────────────────────────────────────────

class _MPage1SideHeader extends StatelessWidget {
  final CVTemplateData data;
  final TechTheme t;
  const _MPage1SideHeader({required this.data, required this.t});
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(children: [
        _dot(const Color(0xFFFF5F57)),
        const SizedBox(width: 5),
        _dot(const Color(0xFFFFBD2E)),
        const SizedBox(width: 5),
        _dot(const Color(0xFF27C840)),
      ]),
      const SizedBox(height: 14),
      // Placeholder matching the avatar size driven by imageSize
      Center(child: SizedBox(
        width:  techImgPx(data.imageSize),
        height: techImgPx(data.imageSize),
      )),
      const SizedBox(height: 12),
      Text(data.fullName, style: TextStyle(
          fontSize:   t.fs(11),
          fontWeight: FontWeight.w700,
          color:      t.white,
          fontFamily: t.font,
          height:     1.3),
          softWrap: true,
          overflow: TextOverflow.visible),
      const SizedBox(height: 14),
      Text('// CONTACT', style: TextStyle(
          fontSize:   t.fs(9.5),
          fontWeight: FontWeight.w700,
          color:      t.yellow,
          fontFamily: t.font)),
      const SizedBox(height: 8),
      if (data.email.isNotEmpty)    _cLine('email', data.email),
      if (data.phone.isNotEmpty)    _cLine('phone', data.phone),
      if (data.location.isNotEmpty) _cLine('loc',   data.location),
      if (data.website.isNotEmpty)  _cLine('web',   data.website),
      const SizedBox(height: 14),
    ],
  );
  Widget _dot(Color c) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  Widget _cLine(String key, String value) => Padding(
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

// ── Measure: page-1 main header ───────────────────────────────────────────────

class _MPage1MainHeader extends StatelessWidget {
  final CVTemplateData data;
  final TechTheme t;
  const _MPage1MainHeader({required this.data, required this.t});
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        t.surface,
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(color: t.border, width: 0.8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ),
      const SizedBox(height: 12),
    ],
  );
}

// ── Measure: section label ────────────────────────────────────────────────────

class _MLabel extends StatelessWidget {
  final bool      isMain;
  final TechTheme t;
  const _MLabel({required this.isMain, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text('// EXPERIENCE', style: TextStyle(
        fontSize:   t.fs(10),
        fontWeight: FontWeight.w700,
        color:      t.yellow,
        fontFamily: t.font),
        softWrap: true,
        overflow: TextOverflow.visible),
  );
}

// ── Measure: content blocks ───────────────────────────────────────────────────

class _MSumBlock extends StatelessWidget {
  final String  text;
  final TechTheme t;
  const _MSumBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color:  t.surface,
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

class _MExpBlock extends StatelessWidget {
  final CVTemplateExperience e;
  final TechTheme t;
  const _MExpBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.border, width: 0.8)),
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

class _MEduBlock extends StatelessWidget {
  final CVTemplateEducation e;
  final TechTheme t;
  const _MEduBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.border, width: 0.8)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: t.greenBorder)),
          child: Center(child: Text(
            e.period.length >= 4
                ? e.period.substring(e.period.length - 2)
                : e.period,
            style: TextStyle(
                fontSize:   t.fs(9),
                color:      t.green,
                fontWeight: FontWeight.w700,
                fontFamily: t.font),
          ))),
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

class _MCertBlock extends StatelessWidget {
  final String  s;
  final TechTheme t;
  const _MCertBlock({required this.s, required this.t});
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

class _MSkillBlock extends StatelessWidget {
  final CVTemplateSkill s;
  final TechTheme t;
  const _MSkillBlock({required this.s, required this.t});
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
      SizedBox(height: 3, child: Row(children: [
        Flexible(flex: s.levelOutOf10, child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.green, t.blue])))),
        Flexible(flex: 10 - s.levelOutOf10,
            child: ColoredBox(color: t.border, child: const SizedBox(height: 3))),
      ])),
    ]),
  );
}

class _MSimpleBlock extends StatelessWidget {
  final String  text;
  final TechTheme t;
  const _MSimpleBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('> ', style: TextStyle(
          fontSize: t.fs(9.5), color: t.green, fontFamily: t.font)),
      Expanded(child: Text(text, style: TextStyle(
          fontSize: t.fs(9.5), color: t.muted, fontFamily: t.font),
          softWrap: true,
          overflow: TextOverflow.visible)),
    ]),
  );
}

class _MRefBlock extends StatelessWidget {
  final CVTemplateReferee r;
  final TechTheme t;
  const _MRefBlock({required this.r, required this.t});
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