// editorial_cv_logic_data.dart
// lib/cv_layout_templates/07_editorial_cv_layout/editorial_cv_logic_data.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'editorial_page_stationary_layout.dart';

enum EditSection {
  summary, experience, education,
  certification, skill, language, hobby, reference,
}

class EditItem {
  final EditSection section;
  final int         index;
  final double      height;
  final bool        showLabel;
  final bool        isContinued;

  const EditItem({
    required this.section,
    required this.index,
    required this.height,
    this.showLabel   = true,
    this.isContinued = false,
  });
}

class _Page {
  final List<EditItem> main;
  final List<EditItem> side;
  const _Page({this.main = const [], this.side = const []});
}

// ─────────────────────────────────────────────────────────────────────────────
// Measure key manager
// ─────────────────────────────────────────────────────────────────────────────
class EditMeasureKeys {
  final Map<String, GlobalKey> _m = {};

  GlobalKey op(String id) =>
      _m.putIfAbsent(id, () => GlobalKey(debugLabel: 'edit_$id'));

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

    if (g('lm')     == null) return null;
    if (g('ls')     == null) return null;
    if (g('p1hdr')  == null) return null;
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
// Pagination
// ─────────────────────────────────────────────────────────────────────────────
const double _kFitTol       = 0.5;
// Safety margin reduced from 64 → 8: the old value was eating 64 px of usable
// space per page, causing the paginator to push items to the next page even
// though they fit, then the last overflowed because the math was off.
const double _kSafetyMargin = 8.0;

List<_Page> _paginate(Map<String, double> h, CVTemplateData d) {
  final lm         = h['lm']!;
  final ls         = h['ls']!;
  final hdrH       = h['p1hdr']!;
  final mainBase   = kEditBodyH - kEditMainPadV * 2;
  final sideBase   = kEditBodyH - kEditSidePadV * 2;

  // Main queue: experience, certifications
  final mq = <EditItem>[
    for (int i = 0; i < d.experience.length;     i++)
      EditItem(section: EditSection.experience,    index: i, height: h['e$i'] ?? 0),
    for (int i = 0; i < d.certifications.length; i++)
      EditItem(section: EditSection.certification, index: i, height: h['c$i'] ?? 0),
  ];

  // Side queue: summary, skills, languages, hobbies, education, references
  final sq = <EditItem>[
    if (d.summary.isNotEmpty)
      EditItem(section: EditSection.summary,   index: -1, height: h['sum'] ?? 0),
    for (int i = 0; i < d.skills.length;     i++)
      EditItem(section: EditSection.skill,     index: i,  height: h['sk$i'] ?? 0),
    for (int i = 0; i < d.languages.length;  i++)
      EditItem(section: EditSection.language,  index: i,  height: h['la$i'] ?? 0),
    for (int i = 0; i < d.hobbies.length;    i++)
      EditItem(section: EditSection.hobby,     index: i,  height: h['ho$i'] ?? 0),
    for (int i = 0; i < d.education.length;  i++)
      EditItem(section: EditSection.education, index: i,  height: h['d$i'] ?? 0),
    for (int i = 0; i < d.references.length; i++)
      EditItem(section: EditSection.reference, index: i,  height: h['re$i'] ?? 0),
  ];

  final mp = _greedy(mq, lm, mainBase, hdrH);
  final sp = _greedy(sq, ls, sideBase, hdrH);
  final n  = mp.length > sp.length ? mp.length : sp.length;
  return List.generate(n, (i) => _Page(
    main: i < mp.length ? mp[i] : const [],
    side: i < sp.length ? sp[i] : const [],
  ));
}

List<List<EditItem>> _greedy(
    List<EditItem> q, double lblH, double baseH, double page1HeaderH) {
  final pages = <List<EditItem>>[];
  int qi = 0, pn = 1;
  final seen = <EditSection>{};

  while (qi < q.length && pn <= 30) {
    final pageH = pn == 1 ? baseH - page1HeaderH : baseH;
    double avail = pageH - _kSafetyMargin;
    final pg = <EditItem>[];
    EditSection? prev;

    while (qi < q.length) {
      final it   = q[qi];
      final nl   = it.section != prev;
      final cost = (nl ? lblH : 0) + it.height;
      if (avail < cost - _kFitTol && pg.isNotEmpty) break;
      avail -= cost;
      pg.add(EditItem(
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
// EditPreview — StatefulWidget
// ─────────────────────────────────────────────────────────────────────────────
class EditPreview extends StatefulWidget {
  final CVTemplateData      data;
  final void Function(int)? onPageCount;

  const EditPreview({
    super.key,
    required this.data,
    this.onPageCount,
  });

  @override
  State<EditPreview> createState() => _EditPreviewState();
}

class _EditPreviewState extends State<EditPreview> {
  List<_Page>? _pages;
  int          _gen = 0;
  final EditMeasureKeys _k = EditMeasureKeys();

  @override
  void initState() { super.initState(); _kick(); }

  @override
  void didUpdateWidget(EditPreview old) {
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
    final t = editThemeFromData(d);

    return SizedBox(
      width: kEditPageW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Off-screen measure layer
          SizedBox(
            height: 0,
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: kEditPageW,
                child: Offstage(
                    child: _MeasureLayer(data: d, keys: _k, t: t)),
              ),
            ),
          ),

          // Loading state
          if (_pages == null)
            SizedBox(
              width: kEditPageW, height: kEditPageH,
              child: const ColoredBox(
                color: kEditPaper,
                child: Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: kEditRed)),
              ),
            ),

          // Pages
          if (_pages != null)
            ...List.generate(_pages!.length, (i) {
              final last = i == _pages!.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                child: EditPageLayout(
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
// MEASURE LAYER
// ─────────────────────────────────────────────────────────────────────────────
class _MeasureLayer extends StatelessWidget {
  final CVTemplateData  data;
  final EditMeasureKeys keys;
  final EditTheme       t;
  const _MeasureLayer(
      {required this.data, required this.keys, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Label heights (main and side use same label widget)
      SizedBox(width: kEditMainW, child: KeyedSubtree(key: keys.op('lm'),
          child: _MLabelMain(t: t))),
      SizedBox(width: kEditSideW, child: KeyedSubtree(key: keys.op('ls'),
          child: _MLabelSide(t: t))),

      // Page-1 header height (full-width for accuracy)
      SizedBox(width: kEditPageW, child: KeyedSubtree(key: keys.op('p1hdr'),
          child: _MPage1Header(data: data, t: t))),

      // Side blocks
      if (data.summary.isNotEmpty)
        SizedBox(width: kEditSideW, child: KeyedSubtree(key: keys.op('sum'),
            child: _MSumBlock(text: data.summary, t: t))),
      for (int i = 0; i < data.skills.length; i++)
        SizedBox(width: kEditSideW, child: KeyedSubtree(key: keys.op('sk$i'),
            child: _MSkillBlock(s: data.skills[i], t: t))),
      for (int i = 0; i < data.languages.length; i++)
        SizedBox(width: kEditSideW, child: KeyedSubtree(key: keys.op('la$i'),
            child: _MSimpleBlock(text: data.languages[i], t: t))),
      for (int i = 0; i < data.hobbies.length; i++)
        SizedBox(width: kEditSideW, child: KeyedSubtree(key: keys.op('ho$i'),
            child: _MSimpleBlock(text: data.hobbies[i], t: t))),
      for (int i = 0; i < data.education.length; i++)
        SizedBox(width: kEditSideW, child: KeyedSubtree(key: keys.op('d$i'),
            child: _MEduBlock(e: data.education[i], t: t))),
      for (int i = 0; i < data.references.length; i++)
        SizedBox(width: kEditSideW, child: KeyedSubtree(key: keys.op('re$i'),
            child: _MRefBlock(r: data.references[i], t: t))),

      // Main blocks
      for (int i = 0; i < data.experience.length; i++)
        SizedBox(width: kEditMainW, child: KeyedSubtree(key: keys.op('e$i'),
            child: _MExpBlock(e: data.experience[i], t: t))),
      for (int i = 0; i < data.certifications.length; i++)
        SizedBox(width: kEditMainW, child: KeyedSubtree(key: keys.op('c$i'),
            child: _MCertBlock(s: data.certifications[i], t: t))),
    ]);
  }
}

// ── Measure: page-1 header ────────────────────────────────────────────────────
class _MPage1Header extends StatelessWidget {
  final CVTemplateData data;
  final EditTheme      t;
  const _MPage1Header({required this.data, required this.t});
  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 55, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(data.fullName.toUpperCase(), style: TextStyle(
                        fontSize: t.fs(28), fontWeight: FontWeight.w900,
                        color: kEditInk, height: 0.92, letterSpacing: -0.8)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(width: 22, height: 3, color: t.accent),
                      const SizedBox(width: 10),
                      Flexible(child: Text(data.jobTitle.toUpperCase(), style: TextStyle(
                          fontSize: t.fs(8.5), color: t.accent,
                          fontWeight: FontWeight.w700, letterSpacing: 2))),
                    ]),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(flex: 45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.email.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(bottom: 4),
                            child: Text(data.email, textAlign: TextAlign.end,
                                softWrap: true,
                                style: TextStyle(fontSize: t.fs(9.5), color: kEditMuted))),
                      if (data.phone.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(bottom: 4),
                            child: Text(data.phone, textAlign: TextAlign.end,
                                style: TextStyle(fontSize: t.fs(9.5), color: kEditMuted))),
                      if (data.location.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(bottom: 4),
                            child: Text(data.location, textAlign: TextAlign.end,
                                softWrap: true,
                                style: TextStyle(fontSize: t.fs(9.5), color: kEditMuted))),
                      if (data.website.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(bottom: 4),
                            child: Text(data.website, textAlign: TextAlign.end,
                                softWrap: true,
                                style: TextStyle(fontSize: t.fs(9.5), color: kEditMuted))),
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

// ── Measure: section labels ───────────────────────────────────────────────────
class _MLabelMain extends StatelessWidget {
  final EditTheme t;
  const _MLabelMain({required this.t});
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('EXPERIENCE', style: TextStyle(
          fontSize: t.fs(8.5), fontWeight: FontWeight.w900,
          color: kEditInk, letterSpacing: 2.5)),
      const SizedBox(height: 4),
      Container(height: 0.5, color: kEditRule),
      const SizedBox(height: 10),
    ],
  );
}

class _MLabelSide extends StatelessWidget {
  final EditTheme t;
  const _MLabelSide({required this.t});
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('SKILLS', style: TextStyle(
          fontSize: t.fs(8.5), fontWeight: FontWeight.w900,
          color: kEditInk, letterSpacing: 2.5)),
      const SizedBox(height: 4),
      Container(height: 0.5, color: kEditRule),
      const SizedBox(height: 8),
    ],
  );
}

// ── Measure: content blocks ───────────────────────────────────────────────────
class _MSumBlock extends StatelessWidget {
  final String    text;
  final EditTheme t;
  const _MSumBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, softWrap: true, style: TextStyle(
        fontSize: t.fs(10.5), color: kEditMuted, height: 1.75)),
  );
}

class _MSkillBlock extends StatelessWidget {
  final CVTemplateSkill s;
  final EditTheme       t;
  const _MSkillBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.name, style: TextStyle(fontSize: t.fs(10), color: kEditInk)),
        const SizedBox(height: 3),
        Container(height: 2, color: kEditSkillBg),
      ],
    ),
  );
}

class _MSimpleBlock extends StatelessWidget {
  final String    text;
  final EditTheme t;
  const _MSimpleBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, softWrap: true, style: TextStyle(
        fontSize: t.fs(10.5), color: kEditMuted, height: 1.5)),
  );
}

class _MEduBlock extends StatelessWidget {
  final CVTemplateEducation e;
  final EditTheme           t;
  const _MEduBlock({required this.e, required this.t});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(e.period, style: TextStyle(
            fontSize: t.fs(10), color: t.accent,
            fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        const SizedBox(height: 3),
        Text(e.degree, style: TextStyle(
            fontSize: t.fs(10.5), fontWeight: FontWeight.w700,
            height: 1.3)),
        const SizedBox(height: 2),
        Text(e.institution, style: TextStyle(
            fontSize: t.fs(10), height: 1.4)),
        if (e.detail != null && e.detail!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(e.detail!, style: TextStyle(
              fontSize: t.fs(9.5), color: kEditMuted, height: 1.45)),
        ],
      ],
    ),
  );
}

class _MRefBlock extends StatelessWidget {
  final CVTemplateReferee r;
  final EditTheme         t;
  const _MRefBlock({required this.r, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(r.name, style: TextStyle(
            fontSize: t.fs(10), fontWeight: FontWeight.w700)),
        Text(r.title, style: TextStyle(fontSize: t.fs(9.5))),
        if (r.company != null && r.company!.isNotEmpty)
          Text(r.company!, style: TextStyle(fontSize: t.fs(9.5))),
        if (r.email.isNotEmpty) Text(r.email, style: TextStyle(fontSize: t.fs(9))),
        if (r.phone.isNotEmpty) Text(r.phone, style: TextStyle(fontSize: t.fs(9))),
      ],
    ),
  );
}

class _MExpBlock extends StatelessWidget {
  final CVTemplateExperience e;
  final EditTheme            t;
  const _MExpBlock({required this.e, required this.t});
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
                    color: kEditInk, height: 1.2)),
                Text(e.company, style: TextStyle(
                    fontSize: t.fs(11), color: t.accent,
                    fontWeight: FontWeight.w600)),
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
                  fontSize: t.fs(9), color: kEditMuted)),
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
                fontSize: t.fs(10.5), color: kEditMuted, height: 1.5))),
          ]),
        )),
      ],
    ),
  );
}

class _MCertBlock extends StatelessWidget {
  final String    s;
  final EditTheme t;
  const _MCertBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('→  ', style: TextStyle(
          fontSize: t.fs(10.5), color: t.accent, fontWeight: FontWeight.w700)),
      Expanded(child: Text(s, style: TextStyle(
          fontSize: t.fs(10.5), color: kEditMuted, height: 1.4))),
    ]),
  );
}