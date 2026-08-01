// nordic_cv_logic_data.dart
// lib/cv_layout_templates/02_nordic_cv_layout/nordic_cv_logic_data.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'nordic_page_stationary_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum NordicSection {
  summary, experience, education, certification,
  skill, language, hobby, reference,
}

class NordicItem {
  final NordicSection section;
  final int    index;
  final double height;
  final bool   showLabel;
  final bool   isContinued;

  const NordicItem({
    required this.section,
    required this.index,
    required this.height,
    this.showLabel   = true,
    this.isContinued = false,
  });
}

class _Page {
  final List<NordicItem> main;
  final List<NordicItem> side;
  const _Page({this.main = const [], this.side = const []});
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENT KEYS
// ─────────────────────────────────────────────────────────────────────────────

class NordicMeasureKeys {
  final Map<String, GlobalKey> _m = {};

  GlobalKey op(String id) =>
      _m.putIfAbsent(id, () => GlobalKey(debugLabel: 'nm_$id'));

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
    if (g('hdr') == null) return null;
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

// ─────────────────────────────────────────────────────────────────────────────
// PAGINATOR
// FIX: Budget now uses pageUsableH() which subtracts kColTopGap + kSafetyMargin.
// Previously _kFitTol = 16.0 was a workaround; now the budget is correct and
// _kFitTol can be a small sub-pixel tolerance (mirrors Vibrant's 0.5).
// ─────────────────────────────────────────────────────────────────────────────

const double _kFitTol = 0.5;

List<_Page> _paginate(Map<String, double> h, CVTemplateData d) {
  final lm    = h['lm']!;
  final ls    = h['ls']!;
  final hdr1H = h['hdr']!;

  // page 1 header height may differ from the constant kHdr1H when font scale
  // pushes it taller — use the measured value for page 1 budget only.
  double usableH(bool isPage1) {
    if (isPage1) {
      return kPageH - hdr1H - kFooterZoneH - kColTopGap - kSafetyMargin;
    }
    return pageUsableH(false);
  }

  final mq = <NordicItem>[
    if (d.summary.isNotEmpty)
      NordicItem(section: NordicSection.summary,       index: -1, height: h['sum']  ?? 0),
    for (int i = 0; i < d.experience.length;     i++)
      NordicItem(section: NordicSection.experience,    index: i,  height: h['e$i']  ?? 0),
    for (int i = 0; i < d.education.length;      i++)
      NordicItem(section: NordicSection.education,     index: i,  height: h['d$i']  ?? 0),
    for (int i = 0; i < d.certifications.length; i++)
      NordicItem(section: NordicSection.certification, index: i,  height: h['c$i']  ?? 0),
  ];
  final sq = <NordicItem>[
    for (int i = 0; i < d.skills.length;     i++)
      NordicItem(section: NordicSection.skill,     index: i, height: h['sk$i'] ?? 0),
    for (int i = 0; i < d.languages.length;  i++)
      NordicItem(section: NordicSection.language,  index: i, height: h['la$i'] ?? 0),
    for (int i = 0; i < d.hobbies.length;    i++)
      NordicItem(section: NordicSection.hobby,     index: i, height: h['ho$i'] ?? 0),
    for (int i = 0; i < d.references.length; i++)
      NordicItem(section: NordicSection.reference, index: i, height: h['re$i'] ?? 0),
  ];

  final mp = _greedy(mq, lm, usableH);
  final sp = _greedy(sq, ls, usableH);
  final n  = mp.length > sp.length ? mp.length : sp.length;
  return List.generate(n, (i) => _Page(
    main: i < mp.length ? mp[i] : const [],
    side: i < sp.length ? sp[i] : const [],
  ));
}

List<List<NordicItem>> _greedy(
  List<NordicItem> q,
  double lblH,
  double Function(bool isPage1) usableH,
) {
  final pages = <List<NordicItem>>[];
  int qi = 0, pn = 1;
  final seen = <NordicSection>{};

  while (qi < q.length && pn <= 30) {
    double avail = usableH(pn == 1);
    final pg = <NordicItem>[];
    NordicSection? prev;

    while (qi < q.length) {
      final it   = q[qi];
      final nl   = it.section != prev;
      final cost = (nl ? lblH : 0) + it.height;
      if (avail < cost - _kFitTol && pg.isNotEmpty) break;
      avail -= cost;
      pg.add(NordicItem(
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

// ─────────────────────────────────────────────────────────────────────────────
// NordicPreview — public entry point
// ─────────────────────────────────────────────────────────────────────────────

class NordicPreview extends StatefulWidget {
  final CVTemplateData data;
  final void Function(int)? onPageCount;
  const NordicPreview({super.key, required this.data, this.onPageCount});

  @override
  State<NordicPreview> createState() => _NordicPreviewState();
}

class _NordicPreviewState extends State<NordicPreview> {
  List<_Page>? _pages;
  int          _gen          = 0;
  int          _retryCount   = 0;
  static const _kMaxRetries  = 20;
  DateTime     _lastKick     = DateTime(0);

  final NordicMeasureKeys _k = NordicMeasureKeys();
  late double _sc;
  Widget? _cachedBuild;
  int?    _cachedDataHash;

  @override
  void initState() {
    super.initState();
    _sc = widget.data.fontSize / kBase;
    _kick();
  }

  @override
  void didUpdateWidget(NordicPreview old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _sc             = widget.data.fontSize / kBase;
      _cachedBuild    = null;
      _cachedDataHash = null;
      final now = DateTime.now();
      final gap = now.difference(_lastKick).inMilliseconds;
      if (gap < 80) {
        final pendingGen = _gen + 1;
        Future.delayed(Duration(milliseconds: 80 - gap), () {
          if (mounted && _gen < pendingGen) _kickNow();
        });
        return;
      }
      _kickNow();
    }
  }

  void _kick() => _kickNow();

  void _kickNow() {
    _lastKick       = DateTime.now();
    _retryCount     = 0;
    _gen++;
    _k.clear();
    _cachedBuild    = null;
    _cachedDataHash = null;
    if (mounted) setState(() => _pages = null);
    final g = _gen;
    SchedulerBinding.instance.addPostFrameCallback((_) => _attempt(g));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && g == _gen && _pages == null) {
        setState(() => _pages = [const _Page()]);
      }
    });
  }

  void _attempt(int g) {
    if (!mounted || g != _gen) return;
    if (_retryCount >= _kMaxRetries) {
      if (_pages == null) setState(() => _pages = [const _Page()]);
      return;
    }
    final h = _k.readAll(widget.data);
    if (h == null) {
      _retryCount++;
      SchedulerBinding.instance.addPostFrameCallback((_) => _attempt(g));
      return;
    }
    if (!mounted || g != _gen) return;
    final pages = _paginate(h, widget.data);
    _cachedBuild    = null;
    _cachedDataHash = null;
    setState(() => _pages = pages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPageCount?.call(pages.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final dataHash = Object.hash(d.hashCode, _pages?.length ?? -1);
    if (_cachedBuild != null && _cachedDataHash == dataHash) return _cachedBuild!;
    final result = _buildContent(d);
    _cachedBuild    = result;
    _cachedDataHash = dataHash;
    return result;
  }

  Widget _buildContent(CVTemplateData d) {
    return SizedBox(
      width: kPageW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: kPageW, height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: 0, maxHeight: 20000,
              minWidth: kPageW, maxWidth: kPageW,
              child: Offstage(child: _MeasureLayer(data: d, keys: _k)),
            ),
          ),
          if (_pages == null)
            SizedBox(width: kPageW, height: kPageH,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
          if (_pages != null)
            ...List.generate(_pages!.length, (i) {
              final last = i == _pages!.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                child: RepaintBoundary(
                  child: NordicPageLayout(
                    key:        ValueKey('nordic_page_$i'),
                    data:       d,
                    mainItems:  _pages![i].main,
                    sideItems:  _pages![i].side,
                    pageNum:    i + 1,
                    totalPages: _pages!.length,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENT LAYER
// ─────────────────────────────────────────────────────────────────────────────

class _MeasureLayer extends StatelessWidget {
  final CVTemplateData    data;
  final NordicMeasureKeys keys;
  const _MeasureLayer({required this.data, required this.keys});

  @override
  Widget build(BuildContext context) {
    final sc = data.fontSize / kBase;
    final ff = data.fontFamily;
    final ac = data.accentColor;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: kInnerW, child: KeyedSubtree(key: keys.op('hdr'),
          child: _MPage1Header(data: data, sc: sc))),
      SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('lm'),
          child: _MLabel(sc: sc, fontFamily: ff))),
      SizedBox(width: kSideW, child: KeyedSubtree(key: keys.op('ls'),
          child: _MLabel(sc: sc, fontFamily: ff))),
      if (data.summary.isNotEmpty)
        SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('sum'),
            child: _MSum(text: data.summary, sc: sc, fontFamily: ff))),
      for (int i = 0; i < data.experience.length; i++)
        SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('e$i'),
            child: _MExp(e: data.experience[i], sc: sc, ac: ac, fontFamily: ff))),
      for (int i = 0; i < data.education.length; i++)
        SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('d$i'),
            child: _MEdu(e: data.education[i], sc: sc, ac: ac, fontFamily: ff))),
      for (int i = 0; i < data.certifications.length; i++)
        SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('c$i'),
            child: _MCert(s: data.certifications[i], sc: sc, c: ac, fontFamily: ff))),
      for (int i = 0; i < data.skills.length; i++)
        SizedBox(width: kSideW, child: KeyedSubtree(key: keys.op('sk$i'),
            child: _MSkill(s: data.skills[i], sc: sc, ac: ac, fontFamily: ff))),
      for (int i = 0; i < data.languages.length; i++)
        SizedBox(width: kSideW, child: KeyedSubtree(key: keys.op('la$i'),
            child: _MSimple(t: data.languages[i], sc: sc, fontFamily: ff))),
      for (int i = 0; i < data.hobbies.length; i++)
        SizedBox(width: kSideW, child: KeyedSubtree(key: keys.op('ho$i'),
            child: _MSimple(t: data.hobbies[i], sc: sc, fontFamily: ff))),
      for (int i = 0; i < data.references.length; i++)
        SizedBox(width: kSideW, child: KeyedSubtree(key: keys.op('re$i'),
            child: _MRef(r: data.references[i], sc: sc, fontFamily: ff))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENT PROXY WIDGETS
// Must exactly match the render widgets in structure and text styling.
// ─────────────────────────────────────────────────────────────────────────────

class _MPage1Header extends StatelessWidget {
  final CVTemplateData data; final double sc;
  const _MPage1Header({required this.data, required this.sc});

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
                  style: TextStyle(fontSize: 11.5 * sc, color: data.accentColor,
                      fontWeight: FontWeight.w500, fontFamily: data.fontFamily),
                  softWrap: true, maxLines: 2, overflow: TextOverflow.clip),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: contactColW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: data.contactLines.map((l) => Text(l,
                style: TextStyle(fontSize: 9 * sc, color: kMuted,
                    fontFamily: data.fontFamily),
                textAlign: TextAlign.end, softWrap: true,
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

class _MLabel extends StatelessWidget {
  final double sc; final String fontFamily;
  const _MLabel({required this.sc, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 7 * sc),
    child: Text('EXPERIENCE', style: TextStyle(fontSize: 8 * sc,
        fontWeight: FontWeight.w700, color: kInk, letterSpacing: 2.2,
        fontFamily: fontFamily), softWrap: true, overflow: TextOverflow.visible));
}

class _MSum extends StatelessWidget {
  final String text; final double sc; final String fontFamily;
  const _MSum({required this.text, required this.sc, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 14 * sc),
    child: Text(text, style: TextStyle(fontSize: 10 * sc, color: kMuted,
        height: 1.65, fontFamily: fontFamily),
        softWrap: true, overflow: TextOverflow.visible));
}

class _MExp extends StatelessWidget {
  final CVTemplateExperience e; final double sc; final Color ac; final String fontFamily;
  const _MExp({required this.e, required this.sc, required this.ac, required this.fontFamily});
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
        Text(e.duration, style: TextStyle(fontSize: 9 * sc, color: kMuted,
            fontFamily: fontFamily), softWrap: false, overflow: TextOverflow.ellipsis),
      ]),
      SizedBox(height: 1.5 * sc),
      Text(e.role, style: TextStyle(fontSize: 10 * sc, color: kMuted,
          fontWeight: FontWeight.w500, fontFamily: fontFamily),
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

class _MEdu extends StatelessWidget {
  final CVTemplateEducation e; final double sc; final Color ac; final String fontFamily;
  const _MEdu({required this.e, required this.sc, required this.ac, required this.fontFamily});
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
        Text(e.period, style: TextStyle(fontSize: 9 * sc, color: kMuted,
            fontFamily: fontFamily), softWrap: false, overflow: TextOverflow.ellipsis),
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

class _MCert extends StatelessWidget {
  final String s; final double sc; final Color c; final String fontFamily;
  const _MCert({required this.s, required this.sc, required this.c, required this.fontFamily});
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

class _MSkill extends StatelessWidget {
  final CVTemplateSkill s; final double sc; final Color ac; final String fontFamily;
  const _MSkill({required this.s, required this.sc, required this.ac, required this.fontFamily});
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
      SizedBox(height: 4 * sc), // bar placeholder height
    ]));
}

class _MSimple extends StatelessWidget {
  final String t; final double sc; final String fontFamily;
  const _MSimple({required this.t, required this.sc, required this.fontFamily});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 5 * sc),
    child: SizedBox(
      width: kSideW,
      child: Text(t, style: TextStyle(fontSize: 10 * sc, color: kMuted,
          height: 1.35, fontFamily: fontFamily),
          softWrap: true, overflow: TextOverflow.visible),
    ));
}

class _MRef extends StatelessWidget {
  final CVTemplateReferee r; final double sc; final String fontFamily;
  const _MRef({required this.r, required this.sc, required this.fontFamily});
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
          color: kBlue, fontWeight: FontWeight.w500, fontFamily: fontFamily),
          softWrap: true, overflow: TextOverflow.visible),
      if (r.company != null && r.company!.isNotEmpty)
        Text(r.company!, style: TextStyle(fontSize: 9 * sc,
            color: kMuted, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible),
      SizedBox(height: 3 * sc),
      if (r.email.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(top: 1.5 * sc),
          child: Icon(Icons.email_outlined, size: 8.5 * sc, color: kMuted)),
        SizedBox(width: 3 * sc),
        Expanded(child: Text(r.email, style: TextStyle(fontSize: 8.5 * sc,
            color: kMuted, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible)),
      ]),
      if (r.phone.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(top: 1.5 * sc),
          child: Icon(Icons.phone_outlined, size: 8.5 * sc, color: kMuted)),
        SizedBox(width: 3 * sc),
        Expanded(child: Text(r.phone, style: TextStyle(fontSize: 8.5 * sc,
            color: kMuted, fontFamily: fontFamily),
            softWrap: true, overflow: TextOverflow.visible)),
      ]),
    ]));
}