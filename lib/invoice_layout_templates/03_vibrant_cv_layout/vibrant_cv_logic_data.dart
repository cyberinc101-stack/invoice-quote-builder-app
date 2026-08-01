// vibrant_cv_logic_data.dart
// lib/cv_layout_templates/03_vibrant_cv_layout/vibrant_cv_logic_data.dart
//
// Data types, measurement, pagination and the VibrantPreview entry point.
// Imports vibrant_page_stationary_layout.dart for rendering.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'vibrant_page_stationary_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum VibrantSection {
  summary, experience, education, certification,
  skill, language, hobby, reference,
}

class VibrantItem {
  final VibrantSection section;
  final int    index;
  final double height;
  final bool   showLabel;
  final bool   isContinued;

  const VibrantItem({
    required this.section,
    required this.index,
    required this.height,
    this.showLabel   = true,
    this.isContinued = false,
  });
}

// Internal page pair
class _Page {
  final List<VibrantItem> main;
  final List<VibrantItem> side;
  const _Page({this.main = const [], this.side = const []});
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENT KEYS
// ─────────────────────────────────────────────────────────────────────────────

class VibrantMeasureKeys {
  final Map<String, GlobalKey> _m = {};

  GlobalKey op(String id) =>
      _m.putIfAbsent(id, () => GlobalKey(debugLabel: 'vm_$id'));

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
// ─────────────────────────────────────────────────────────────────────────────

const double _kFitTol       = 0.5;
const double _kSafetyMargin = 4.0;

List<_Page> _paginate(Map<String, double> h, CVTemplateData d) {
  final sc        = d.fontSize / kBase;
  final imageSize = d.imageSize;
  final lm        = h['lm']!;
  final ls        = h['ls']!;

  final mq = <VibrantItem>[
    if (d.summary.isNotEmpty)
      VibrantItem(section: VibrantSection.summary,       index: -1, height: h['sum']  ?? 0),
    for (int i = 0; i < d.experience.length;     i++)
      VibrantItem(section: VibrantSection.experience,    index: i,  height: h['e$i']  ?? 0),
    for (int i = 0; i < d.education.length;      i++)
      VibrantItem(section: VibrantSection.education,     index: i,  height: h['d$i']  ?? 0),
    for (int i = 0; i < d.certifications.length; i++)
      VibrantItem(section: VibrantSection.certification, index: i,  height: h['c$i']  ?? 0),
  ];
  final sq = <VibrantItem>[
    for (int i = 0; i < d.skills.length;     i++)
      VibrantItem(section: VibrantSection.skill,     index: i, height: h['sk$i'] ?? 0),
    for (int i = 0; i < d.languages.length;  i++)
      VibrantItem(section: VibrantSection.language,  index: i, height: h['la$i'] ?? 0),
    for (int i = 0; i < d.hobbies.length;    i++)
      VibrantItem(section: VibrantSection.hobby,     index: i, height: h['ho$i'] ?? 0),
    for (int i = 0; i < d.references.length; i++)
      VibrantItem(section: VibrantSection.reference, index: i, height: h['re$i'] ?? 0),
  ];

  final mp = _greedy(mq, lm, sc, imageSize);
  final sp = _greedy(sq, ls, sc, imageSize);
  final n  = mp.length > sp.length ? mp.length : sp.length;
  return List.generate(n, (i) => _Page(
    main: i < mp.length ? mp[i] : const [],
    side: i < sp.length ? sp[i] : const [],
  ));
}

List<List<VibrantItem>> _greedy(
    List<VibrantItem> q,
    double lblH,
    double sc,
    double imageSize,
) {
  final pages = <List<VibrantItem>>[];
  int qi = 0, pn = 1;
  final seen = <VibrantSection>{};

  while (qi < q.length && pn <= 30) {
    double avail = pageBodyH(pn == 1, sc, imageSize) - _kSafetyMargin;
    final pg = <VibrantItem>[];
    VibrantSection? prev;

    while (qi < q.length) {
      final it   = q[qi];
      final nl   = it.section != prev;
      final cost = (nl ? lblH : 0) + it.height;
      if (avail < cost - _kFitTol && pg.isNotEmpty) break;
      avail -= cost;
      pg.add(VibrantItem(
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
// VibrantPreview  — public entry point
// ─────────────────────────────────────────────────────────────────────────────

class VibrantPreview extends StatefulWidget {
  final CVTemplateData data;
  final void Function(int)? onPageCount;
  const VibrantPreview({super.key, required this.data, this.onPageCount});

  @override
  State<VibrantPreview> createState() => _VibrantPreviewState();
}

class _VibrantPreviewState extends State<VibrantPreview> {
  List<_Page>? _pages;
  int          _gen = 0;
  final VibrantMeasureKeys _k = VibrantMeasureKeys();

  @override
  void initState() {
    super.initState();
    _kick();
  }

  @override
  void didUpdateWidget(VibrantPreview old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
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
    final d = widget.data;
    return SizedBox(
      width: kPageW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Off-screen measurement — zero layout height, bounded width
          SizedBox(
            width: kPageW,
            height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: 0,
              maxHeight: 20000,
              minWidth: kPageW,
              maxWidth: kPageW,
              child: Offstage(child: _MeasureLayer(data: d, keys: _k)),
            ),
          ),

          // Spinner while measuring
          if (_pages == null)
            SizedBox(
              width: kPageW, height: kPageH,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),

          // Pages
          if (_pages != null)
            ...List.generate(_pages!.length, (i) {
              final last = i == _pages!.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                child: VibrantPageLayout(
                  data:       d,
                  mainItems:  _pages![i].main,
                  sideItems:  _pages![i].side,
                  pageNum:    i + 1,
                  totalPages: _pages!.length,
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
// Mirrors every real block at exact column widths for accurate height reads.
// All text uses softWrap: true / overflow: visible to match render widgets.
// ─────────────────────────────────────────────────────────────────────────────

class _MeasureLayer extends StatelessWidget {
  final CVTemplateData data;
  final VibrantMeasureKeys keys;
  const _MeasureLayer({required this.data, required this.keys});

  @override
  Widget build(BuildContext context) {
    final sc = data.fontSize / kBase;
    final ff = data.fontFamily;
    final ac = data.accentColor;
    return Column(mainAxisSize: MainAxisSize.min, children: [

      // Label prototypes — one per column width
      SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('lm'),
          child: _MLabel(sc: sc, fontFamily: ff, ac: ac))),
      SizedBox(width: kSideW - kSidePadL, child: KeyedSubtree(key: keys.op('ls'),
          child: _MLabel(sc: sc, fontFamily: ff, ac: ac))),

      // Summary
      if (data.summary.isNotEmpty)
        SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('sum'),
            child: _MSum(text: data.summary, sc: sc, fontFamily: ff))),

      // Experience
      for (int i = 0; i < data.experience.length; i++)
        SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('e$i'),
            child: _MExp(e: data.experience[i], sc: sc, ac: ac, fontFamily: ff))),

      // Education
      for (int i = 0; i < data.education.length; i++)
        SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('d$i'),
            child: _MEdu(e: data.education[i], displayNum: i + 1,
                sc: sc, ac: ac, fontFamily: ff))),

      // Certifications
      for (int i = 0; i < data.certifications.length; i++)
        SizedBox(width: kMainW, child: KeyedSubtree(key: keys.op('c$i'),
            child: _MCert(s: data.certifications[i], sc: sc, ac: ac, fontFamily: ff))),

      // Skills
      for (int i = 0; i < data.skills.length; i++)
        SizedBox(width: kSideW - kSidePadL, child: KeyedSubtree(key: keys.op('sk$i'),
            child: _MSkill(s: data.skills[i], sc: sc, ac: ac, fontFamily: ff))),

      // Languages
      for (int i = 0; i < data.languages.length; i++)
        SizedBox(width: kSideW - kSidePadL, child: KeyedSubtree(key: keys.op('la$i'),
            child: _MSimple(t: data.languages[i], sc: sc, fontFamily: ff, ac: ac))),

      // Hobbies
      for (int i = 0; i < data.hobbies.length; i++)
        SizedBox(width: kSideW - kSidePadL, child: KeyedSubtree(key: keys.op('ho$i'),
            child: _MSimple(t: data.hobbies[i], sc: sc, fontFamily: ff, ac: ac))),

      // References
      for (int i = 0; i < data.references.length; i++)
        SizedBox(width: kSideW - kSidePadL, child: KeyedSubtree(key: keys.op('re$i'),
            child: _MRef(r: data.references[i], sc: sc, ac: ac, fontFamily: ff))),
    ]);
  }
}

// ── Measurement proxy widgets ─────────────────────────────────────────────────
// Every proxy MUST match the corresponding render widget exactly in layout
// so the measured heights are accurate. softWrap must be true on all Text.

class _MLabel extends StatelessWidget {
  final double sc; final String fontFamily; final Color ac;
  const _MLabel({required this.sc, required this.fontFamily, required this.ac});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 8 * sc),
    child: Row(children: [
      Container(width: 16 * sc, height: 2.5 * sc,
          decoration: BoxDecoration(
              color: ac, borderRadius: BorderRadius.circular(2 * sc))),
      SizedBox(width: 8 * sc),
      Expanded(
        child: Text('EXPERIENCE', style: TextStyle(
            fontSize: 8.5 * sc, fontWeight: FontWeight.w800,
            color: kDark, letterSpacing: 1.5, fontFamily: fontFamily),
            softWrap: true,
            overflow: TextOverflow.visible),
      ),
    ]),
  );
}

class _MSum extends StatelessWidget {
  final String text; final double sc; final String fontFamily;
  const _MSum({required this.text, required this.sc, required this.fontFamily});
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

class _MExp extends StatelessWidget {
  final CVTemplateExperience e; final double sc; final Color ac; final String fontFamily;
  const _MExp({required this.e, required this.sc, required this.ac, required this.fontFamily});
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
          Expanded(child: Text(b, style: TextStyle(
              fontSize: 9.5 * sc, color: kMid, height: 1.5,
              fontFamily: fontFamily),
              softWrap: true,
              overflow: TextOverflow.visible)),
        ]),
      )),
      Divider(color: const Color(0xFFF0F0F0), thickness: 1, height: 14 * sc),
    ]),
  );
}

class _MEdu extends StatelessWidget {
  final CVTemplateEducation e;
  final int    displayNum;
  final double sc;
  final Color  ac;
  final String fontFamily;
  const _MEdu({
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
          Text(e.detail!, style: TextStyle(fontSize: 9.5 * sc, color: ac,
              fontStyle: FontStyle.italic, fontFamily: fontFamily),
              softWrap: true,
              overflow: TextOverflow.visible),
        ],
      ])),
    ]),
  );
}

class _MCert extends StatelessWidget {
  final String s; final double sc; final Color ac; final String fontFamily;
  const _MCert({required this.s, required this.sc, required this.ac, required this.fontFamily});
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

class _MSkill extends StatelessWidget {
  final CVTemplateSkill s; final double sc; final Color ac; final String fontFamily;
  const _MSkill({required this.s, required this.sc, required this.ac, required this.fontFamily});
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

class _MSimple extends StatelessWidget {
  final String t; final double sc; final String fontFamily; final Color ac;
  const _MSimple({required this.t, required this.sc, required this.fontFamily, required this.ac});
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

class _MRef extends StatelessWidget {
  final CVTemplateReferee r; final double sc; final Color ac; final String fontFamily;
  const _MRef({required this.r, required this.sc, required this.ac, required this.fontFamily});
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