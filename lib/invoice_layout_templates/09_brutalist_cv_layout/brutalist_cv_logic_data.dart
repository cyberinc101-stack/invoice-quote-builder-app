// brutalist_cv_logic_data.dart
// lib/cv_layout_templates/09_brutalist_cv_layout/brutalist_cv_logic_data.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'brutalist_page_stationary_layout.dart';

enum BrutSection {
  summary, experience, education,
  skill, language, certification, hobby, reference,
}

class BrutItem {
  final BrutSection section;
  final int    index;
  final double height;
  final bool   showLabel;
  final bool   isContinued;

  const BrutItem({
    required this.section,
    required this.index,
    required this.height,
    this.showLabel   = true,
    this.isContinued = false,
  });
}

class _Page {
  final List<BrutItem> main;
  final List<BrutItem> side;
  const _Page({this.main = const [], this.side = const []});
}

class BrutMeasureKeys {
  final Map<String, GlobalKey> _m = {};

  GlobalKey op(String id) =>
      _m.putIfAbsent(id, () => GlobalKey(debugLabel: 'bm_$id'));

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

    // Contact: fixed constant — avoids the old ~41px vs 32px mismatch.
    r['ct'] = kBrutContactH;

    if (d.summary.isNotEmpty && g('sum') == null) return null;
    for (int i = 0; i < d.experience.length;     i++) { if (g('e$i')  == null) return null; }
    for (int i = 0; i < d.skills.length;         i++) { if (g('sk$i') == null) return null; }
    for (int i = 0; i < d.languages.length;      i++) { if (g('la$i') == null) return null; }
    for (int i = 0; i < d.certifications.length; i++) { if (g('c$i')  == null) return null; }
    for (int i = 0; i < d.education.length;      i++) { if (g('d$i')  == null) return null; }
    for (int i = 0; i < d.hobbies.length;        i++) { if (g('ho$i') == null) return null; }
    for (int i = 0; i < d.references.length;     i++) { if (g('re$i') == null) return null; }
    return r;
  }
}

const double _kFitTol = 0.5;

List<_Page> _paginate(Map<String, double> h, CVTemplateData d) {
  final lm = h['lm']!;
  final ls = h['ls']!;
  final ct = h['ct']!;

  final mq = <BrutItem>[
    if (d.summary.isNotEmpty)
      BrutItem(section: BrutSection.summary,    index: 0, height: h['sum'] ?? 0),
    for (int i = 0; i < d.experience.length; i++)
      BrutItem(section: BrutSection.experience, index: i, height: h['e$i'] ?? 0),
  ];

  final sq = <BrutItem>[
    for (int i = 0; i < d.skills.length;         i++)
      BrutItem(section: BrutSection.skill,         index: i, height: h['sk$i'] ?? 0),
    for (int i = 0; i < d.languages.length;       i++)
      BrutItem(section: BrutSection.language,      index: i, height: h['la$i'] ?? 0),
    for (int i = 0; i < d.certifications.length;  i++)
      BrutItem(section: BrutSection.certification, index: i, height: h['c$i']  ?? 0),
    for (int i = 0; i < d.education.length;       i++)
      BrutItem(section: BrutSection.education,     index: i, height: h['d$i']  ?? 0),
    for (int i = 0; i < d.hobbies.length;         i++)
      BrutItem(section: BrutSection.hobby,         index: i, height: h['ho$i'] ?? 0),
    for (int i = 0; i < d.references.length;      i++)
      BrutItem(section: BrutSection.reference,     index: i, height: h['re$i'] ?? 0),
  ];

  final mp = _greedy(mq, lm, isMain: true,  contactH: 0);
  final sp = _greedy(sq, ls, isMain: false, contactH: ct);

  final n = mp.length > sp.length ? mp.length : sp.length;
  return List.generate(n, (i) => _Page(
    main: i < mp.length ? mp[i] : const [],
    side: i < sp.length ? sp[i] : const [],
  ));
}

List<List<BrutItem>> _greedy(
    List<BrutItem> q, double lblH,
    {required bool isMain, required double contactH}) {
  final pages = <List<BrutItem>>[];
  int qi = 0, pn = 1;
  final seen = <BrutSection>{};

  while (qi < q.length && pn <= 30) {
    double avail = brutPageUsableH(pn == 1);
    if (!isMain && pn == 1) avail -= contactH;

    final pg = <BrutItem>[];
    BrutSection? prev;

    while (qi < q.length) {
      final it   = q[qi];
      final nl   = it.section != prev;
      final cost = (nl ? lblH : 0) + it.height;
      if (avail < cost - _kFitTol && pg.isNotEmpty) break;
      avail -= cost;
      pg.add(BrutItem(
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

class BrutalistPreview extends StatefulWidget {
  final CVTemplateData data;
  final void Function(int)? onPageCount;
  const BrutalistPreview({super.key, required this.data, this.onPageCount});

  @override
  State<BrutalistPreview> createState() => _BrutalistPreviewState();
}

class _BrutalistPreviewState extends State<BrutalistPreview> {
  List<_Page>? _pages;
  int          _gen         = 0;
  int          _retryCount  = 0;
  static const _kMaxRetries = 20;
  DateTime     _lastKick    = DateTime(0);

  final BrutMeasureKeys _k = BrutMeasureKeys();

  late double _sc;
  late Color  _ac;

  Widget? _cachedBuild;
  int?    _cachedDataHash;

  @override
  void initState() {
    super.initState();
    _sc = widget.data.fontSize / kBrutBase;
    _ac = brutAccent(widget.data);
    _kick();
  }

  @override
  void didUpdateWidget(BrutalistPreview old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _sc             = widget.data.fontSize / kBrutBase;
      _ac             = brutAccent(widget.data);
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
    if (_cachedBuild != null && _cachedDataHash == dataHash) {
      return _cachedBuild!;
    }
    final result = _buildContent(d);
    _cachedBuild    = result;
    _cachedDataHash = dataHash;
    return result;
  }

  Widget _buildContent(CVTemplateData d) {
    return SizedBox(
      width: kBrutPageW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: kBrutPageW,
            height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: 0,
              maxHeight: 20000,
              minWidth: kBrutPageW,
              maxWidth: kBrutPageW,
              child: Offstage(
                child: _BrutMeasureLayer(data: d, keys: _k),
              ),
            ),
          ),

          if (_pages == null)
            SizedBox(
              width: kBrutPageW, height: kBrutPageH,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),

          if (_pages != null)
            ...List.generate(_pages!.length, (i) {
              final last = i == _pages!.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                child: RepaintBoundary(
                  child: BrutPageLayout(
                    key:        ValueKey('brut_page_$i'),
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

class _BrutMeasureLayer extends StatelessWidget {
  final CVTemplateData  data;
  final BrutMeasureKeys keys;
  const _BrutMeasureLayer({required this.data, required this.keys});

  @override
  Widget build(BuildContext context) {
    final sc = data.fontSize / kBrutBase;
    final ff = data.fontFamily;

    return Column(mainAxisSize: MainAxisSize.min, children: [

      SizedBox(width: kBrutContentInnerW, child: KeyedSubtree(key: keys.op('lm'),
          child: _BMLabelMain(sc: sc, ff: ff))),
      SizedBox(width: kBrutSideInnerW, child: KeyedSubtree(key: keys.op('ls'),
          child: _BMLabelSide(sc: sc, ff: ff))),

      // Contact: not measured — readAll() injects kBrutContactH directly.

      if (data.summary.isNotEmpty)
        SizedBox(width: kBrutContentInnerW, child: KeyedSubtree(key: keys.op('sum'),
            child: _BMSum(text: data.summary, sc: sc, ff: ff))),

      for (int i = 0; i < data.experience.length; i++)
        SizedBox(width: kBrutContentInnerW, child: KeyedSubtree(key: keys.op('e$i'),
            child: _BMExp(e: data.experience[i], sc: sc, ff: ff))),

      for (int i = 0; i < data.skills.length; i++)
        SizedBox(width: kBrutSideInnerW, child: KeyedSubtree(key: keys.op('sk$i'),
            child: _BMSkill(s: data.skills[i], sc: sc, ff: ff))),

      for (int i = 0; i < data.languages.length; i++)
        SizedBox(width: kBrutSideInnerW, child: KeyedSubtree(key: keys.op('la$i'),
            child: _BMSimple(t: data.languages[i], sc: sc, ff: ff))),

      for (int i = 0; i < data.certifications.length; i++)
        SizedBox(width: kBrutSideInnerW, child: KeyedSubtree(key: keys.op('c$i'),
            child: _BMSimple(t: data.certifications[i], sc: sc, ff: ff))),

      for (int i = 0; i < data.education.length; i++)
        SizedBox(width: kBrutSideInnerW, child: KeyedSubtree(key: keys.op('d$i'),
            child: _BMEdu(e: data.education[i], sc: sc, ff: ff))),

      for (int i = 0; i < data.hobbies.length; i++)
        SizedBox(width: kBrutSideInnerW, child: KeyedSubtree(key: keys.op('ho$i'),
            child: _BMSimple(t: data.hobbies[i], sc: sc, ff: ff))),

      for (int i = 0; i < data.references.length; i++)
        SizedBox(width: kBrutSideInnerW, child: KeyedSubtree(key: keys.op('re$i'),
            child: _BMRef(r: data.references[i], sc: sc, ff: ff))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENT PROXIES — must exactly mirror layout widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BMLabelMain extends StatelessWidget {
  final double sc; final String ff;
  const _BMLabelMain({required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: EdgeInsets.only(bottom: 10 * sc),
    padding: EdgeInsets.symmetric(horizontal: 10 * sc, vertical: 6 * sc),
    decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2.5)),
    child: Text('EXPERIENCE',
        style: TextStyle(fontSize: 10 * sc, fontWeight: FontWeight.w900,
            letterSpacing: 2.5, color: Colors.black, fontFamily: ff),
        softWrap: true, overflow: TextOverflow.visible),
  );
}

class _BMLabelSide extends StatelessWidget {
  final double sc; final String ff;
  const _BMLabelSide({required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Container(
    // Mirrors _SideLabel exactly: fromLTRB(14*sc, 9*sc, 14*sc, 7*sc)
    padding: EdgeInsets.fromLTRB(14 * sc, 9 * sc, 14 * sc, 7 * sc),
    color: Colors.black,
    child: Text('SKILLS',
        style: TextStyle(fontSize: 10 * sc, fontWeight: FontWeight.w900,
            color: Colors.white, letterSpacing: 2.0, fontFamily: ff),
        softWrap: true, overflow: TextOverflow.visible),
  );
}

class _BMSum extends StatelessWidget {
  final String text; final double sc; final String ff;
  const _BMSum({required this.text, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 22 * sc),
    child: Text(text,
        style: TextStyle(fontSize: 11 * sc, height: 1.6, fontFamily: ff,
            fontWeight: FontWeight.w400, color: const Color(0xFF444444)),
        softWrap: true, overflow: TextOverflow.visible),
  );
}

class _BMExp extends StatelessWidget {
  final CVTemplateExperience e; final double sc; final String ff;
  const _BMExp({required this.e, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: EdgeInsets.only(bottom: 14 * sc),
    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D0D0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Container(
        color: const Color(0xFFF5F5F5),
        padding: EdgeInsets.symmetric(horizontal: 12 * sc, vertical: 8 * sc),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
            Text(e.role, style: TextStyle(fontSize: 12 * sc,
                fontWeight: FontWeight.w900, color: Colors.black, fontFamily: ff),
                softWrap: true, overflow: TextOverflow.visible),
            Text(e.location.isNotEmpty
                ? '${e.company}  ·  ${e.location}' : e.company,
                style: TextStyle(fontSize: 10 * sc,
                    color: const Color(0xFF444444), fontFamily: ff),
                softWrap: true, overflow: TextOverflow.visible),
          ])),
          SizedBox(width: 6 * sc),
          Container(
            color: const Color(0xFFFFE500),
            padding: EdgeInsets.symmetric(horizontal: 8 * sc, vertical: 4 * sc),
            child: Text(e.duration, style: TextStyle(fontSize: 9.5 * sc,
                fontWeight: FontWeight.w900, color: Colors.black, fontFamily: ff),
                softWrap: true, overflow: TextOverflow.visible),
          ),
        ]),
      ),
      if (e.bullets.isNotEmpty)
        Padding(
          padding: EdgeInsets.all(12 * sc),
          child: Column(mainAxisSize: MainAxisSize.min,
              children: e.bullets.map((b) => Padding(
                padding: EdgeInsets.only(bottom: 4 * sc),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('/ ', style: TextStyle(fontSize: 11 * sc,
                      fontWeight: FontWeight.w900, color: Colors.black, fontFamily: ff)),
                  Expanded(child: Text(b, style: TextStyle(fontSize: 10.5 * sc,
                      color: const Color(0xFF444444), height: 1.4, fontFamily: ff),
                      softWrap: true, overflow: TextOverflow.visible)),
                ]),
              )).toList()),
        ),
    ]),
  );
}

class _BMSkill extends StatelessWidget {
  final CVTemplateSkill s; final double sc; final String ff;
  const _BMSkill({required this.s, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Container(
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
    padding: EdgeInsets.fromLTRB(14 * sc, 9 * sc, 14 * sc, 9 * sc),
    child: Row(children: [
      Expanded(child: Text(s.name, style: TextStyle(fontSize: 10 * sc,
          fontWeight: FontWeight.w600, color: Colors.black, fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible)),
      SizedBox(width: 4 * sc),
      Text(s.percentLabel, style: TextStyle(fontSize: 10 * sc,
          fontWeight: FontWeight.w900, color: Colors.black, fontFamily: ff)),
    ]),
  );
}

// Mirrors _SideSimple: balanced top + bottom padding (7*sc each).
class _BMSimple extends StatelessWidget {
  final String t; final double sc; final String ff;
  const _BMSimple({required this.t, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.fromLTRB(14 * sc, 7 * sc, 14 * sc, 7 * sc),
    child: Text(t, style: TextStyle(fontSize: 10 * sc,
        color: const Color(0xFF444444), fontFamily: ff),
        softWrap: true, overflow: TextOverflow.visible),
  );
}

class _BMEdu extends StatelessWidget {
  final CVTemplateEducation e; final double sc; final String ff;
  const _BMEdu({required this.e, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.fromLTRB(14 * sc, 9 * sc, 14 * sc, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(e.degree, style: TextStyle(fontSize: 10 * sc,
          fontWeight: FontWeight.w800, color: Colors.black, fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible),
      Text(e.location.isNotEmpty
          ? '${e.institution}  ·  ${e.location}' : e.institution,
          style: TextStyle(fontSize: 9.5 * sc,
              color: const Color(0xFF444444), fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible),
      Padding(
        padding: EdgeInsets.only(top: 4 * sc, bottom: 10 * sc),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * sc, vertical: 2 * sc),
          color: const Color(0xFFFFE500),
          child: Text(e.period, style: TextStyle(fontSize: 9 * sc,
              fontWeight: FontWeight.w900, color: Colors.black, fontFamily: ff)),
        ),
      ),
    ]),
  );
}

class _BMRef extends StatelessWidget {
  final CVTemplateReferee r; final double sc; final String ff;
  const _BMRef({required this.r, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.fromLTRB(14 * sc, 9 * sc, 14 * sc, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(r.name, style: TextStyle(fontSize: 10 * sc,
          fontWeight: FontWeight.w800, color: Colors.black, fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible),
      Container(
        margin: EdgeInsets.only(top: 2 * sc, bottom: 4 * sc),
        height: 2.5, width: 28 * sc,
        color: const Color(0xFFFFE500),
      ),
      Text(r.title, style: TextStyle(fontSize: 9 * sc,
          color: const Color(0xFF444444), fontFamily: ff),
          softWrap: true, overflow: TextOverflow.visible),
      if (r.company != null && r.company!.isNotEmpty) ...[
        SizedBox(height: 1 * sc),
        Text(r.company!, style: TextStyle(fontSize: 8.5 * sc,
            color: const Color(0xFF666666), fontFamily: ff),
            softWrap: true, overflow: TextOverflow.visible),
      ],
      SizedBox(height: 5 * sc),
      if (r.email.isNotEmpty) Padding(
        padding: EdgeInsets.only(bottom: 2 * sc),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.email_outlined, size: 9 * sc, color: const Color(0xFF888888)),
          SizedBox(width: 4 * sc),
          Expanded(child: Text(r.email, style: TextStyle(fontSize: 8.5 * sc,
              color: const Color(0xFF444444), fontFamily: ff, height: 1.3),
              softWrap: true, overflow: TextOverflow.visible)),
        ]),
      ),
      if (r.phone.isNotEmpty) Padding(
        padding: EdgeInsets.only(bottom: 10 * sc),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.phone_outlined, size: 9 * sc, color: const Color(0xFF888888)),
          SizedBox(width: 4 * sc),
          Expanded(child: Text(r.phone, style: TextStyle(fontSize: 8.5 * sc,
              color: const Color(0xFF444444), fontFamily: ff, height: 1.3),
              softWrap: true, overflow: TextOverflow.visible)),
        ]),
      ),
    ]),
  );
}