// gradient_cv_logic_data.dart
// lib/cv_layout_templates/06_gradient_modern_cv_layout/gradient_cv_logic_data.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'gradient_page_stationary_layout.dart';

// ── Image size helper (independent of font scale) ─────────────────────────────
double _gradImgPx(double imageSize) => 72.0 * (imageSize / 12.0);

enum GradSection {
  summary, experience, education, certification,
  skill, language, hobby, reference,
}

class GradItem {
  final GradSection section;
  final int         index;
  final double      height;
  final bool        showLabel;
  final bool        isContinued;

  const GradItem({
    required this.section,
    required this.index,
    required this.height,
    this.showLabel   = true,
    this.isContinued = false,
  });
}

class _Page {
  final List<GradItem> main;
  final List<GradItem> side;
  const _Page({this.main = const [], this.side = const []});
}

class GradMeasureKeys {
  final Map<String, GlobalKey> _m = {};

  GlobalKey op(String id) =>
      _m.putIfAbsent(id, () => GlobalKey(debugLabel: 'grad_$id'));

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
    if (g('p1main') == null) return null;
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
const double _kSafetyMargin = 16.0;

List<_Page> _paginate(Map<String, double> h, CVTemplateData d) {
  final lm         = h['lm']!;
  final ls         = h['ls']!;
  final page1MainH = h['p1main']!;
  final mainBase   = kGradBodyH - kGradMainPadV * 2;
  final sideBase   = kGradBodyH - kGradSidePadV * 2;

  final mq = <GradItem>[
    if (d.summary.isNotEmpty)
      GradItem(section: GradSection.summary,       index: -1, height: h['sum'] ?? 0),
    for (int i = 0; i < d.experience.length;     i++)
      GradItem(section: GradSection.experience,    index: i,  height: h['e$i'] ?? 0),
    for (int i = 0; i < d.education.length;      i++)
      GradItem(section: GradSection.education,     index: i,  height: h['d$i'] ?? 0),
    for (int i = 0; i < d.certifications.length; i++)
      GradItem(section: GradSection.certification, index: i,  height: h['c$i'] ?? 0),
  ];

  final sq = <GradItem>[
    for (int i = 0; i < d.skills.length;     i++)
      GradItem(section: GradSection.skill,     index: i, height: h['sk$i'] ?? 0),
    for (int i = 0; i < d.languages.length;  i++)
      GradItem(section: GradSection.language,  index: i, height: h['la$i'] ?? 0),
    for (int i = 0; i < d.hobbies.length;    i++)
      GradItem(section: GradSection.hobby,     index: i, height: h['ho$i'] ?? 0),
    for (int i = 0; i < d.references.length; i++)
      GradItem(section: GradSection.reference, index: i, height: h['re$i'] ?? 0),
  ];

  final mp = _greedy(mq, lm, mainBase, page1MainH);
  final sp = _greedy(sq, ls, sideBase, page1MainH);
  final n  = mp.length > sp.length ? mp.length : sp.length;
  return List.generate(n, (i) => _Page(
    main: i < mp.length ? mp[i] : const [],
    side: i < sp.length ? sp[i] : const [],
  ));
}

List<List<GradItem>> _greedy(
    List<GradItem> q, double lblH, double baseH, double page1HeaderH) {
  final pages = <List<GradItem>>[];
  int qi = 0, pn = 1;
  final seen = <GradSection>{};

  while (qi < q.length && pn <= 30) {
    final pageH = pn == 1 ? baseH - page1HeaderH : baseH;
    double avail = pageH - _kSafetyMargin;
    final pg = <GradItem>[];
    GradSection? prev;

    while (qi < q.length) {
      final it   = q[qi];
      final nl   = it.section != prev;
      final cost = (nl ? lblH : 0) + it.height;
      if (avail < cost - _kFitTol && pg.isNotEmpty) break;
      avail -= cost;
      pg.add(GradItem(
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
// GradPreview — StatefulWidget
// ─────────────────────────────────────────────────────────────────────────────
class GradPreview extends StatefulWidget {
  final CVTemplateData      data;
  final void Function(int)? onPageCount;

  const GradPreview({
    super.key,
    required this.data,
    this.onPageCount,
  });

  @override
  State<GradPreview> createState() => _GradPreviewState();
}

class _GradPreviewState extends State<GradPreview> {
  List<_Page>? _pages;
  int          _gen          = 0;
  int          _retryCount   = 0;
  static const _kMaxRetries  = 20;
  DateTime     _lastKick     = DateTime(0);

  final GradMeasureKeys _k = GradMeasureKeys();

  // Cached theme — not recomputed on every build().
  late GradTheme _t;

  // Widget cache — fast-path bail when parent rebuilds but data unchanged.
  Widget?        _cachedBuild;
  int?           _cachedDataHash;

  @override
  void initState() {
    super.initState();
    _t = gradThemeFromData(widget.data);
    _kick();
  }

  @override
  void didUpdateWidget(GradPreview old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _t           = gradThemeFromData(widget.data);
      _cachedBuild = null;
      _cachedDataHash = null;

      // Debounce: collapse rapid slider ticks into a single deferred kick.
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

    // Fast path: return cached widget when nothing meaningful changed.
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
    final t = _t;
    return SizedBox(
      width: kGradPageW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: finite maxHeight (not double.infinity) avoids unbounded constraints.
          SizedBox(
            width: kGradPageW,
            height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: 0,
              maxHeight: 20000,
              minWidth: kGradPageW,
              maxWidth: kGradPageW,
              child: Offstage(
                child: _MeasureLayer(data: d, keys: _k, t: t),
              ),
            ),
          ),
          if (_pages == null)
            SizedBox(
              width: kGradPageW, height: kGradPageH,
              child: const ColoredBox(
                color: kGradBg,
                child: Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: kGradAccentTeal)),
              ),
            ),
          if (_pages != null)
            ...List.generate(_pages!.length, (i) {
              final last = i == _pages!.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                child: RepaintBoundary(
                  child: GradPageLayout(
                    key:        ValueKey('grad_page_$i'),
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
// MEASURE LAYER
// ─────────────────────────────────────────────────────────────────────────────
class _MeasureLayer extends StatelessWidget {
  final CVTemplateData  data;
  final GradMeasureKeys keys;
  final GradTheme       t;
  const _MeasureLayer(
      {required this.data, required this.keys, required this.t});

  @override
  Widget build(BuildContext context) {
    final imgPx = _gradImgPx(data.imageSize);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // FIX: label proxies include the inter-section spacing that _buildItems()
      // inserts (14px before main labels, 12px before side labels, 8px after
      // both). Without this the paginator undercounts and content overflows.
      SizedBox(width: kGradMainW, child: KeyedSubtree(key: keys.op('lm'),
          child: _MLabelMain(t: t))),
      SizedBox(width: kGradSideW, child: KeyedSubtree(key: keys.op('ls'),
          child: _MLabelSide(t: t))),

      SizedBox(width: kGradPageW, child: KeyedSubtree(key: keys.op('p1main'),
          child: _MPage1Header(data: data, t: t, imgPx: imgPx))),

      if (data.summary.isNotEmpty)
        SizedBox(width: kGradMainW, child: KeyedSubtree(key: keys.op('sum'),
            child: _MSumBlock(text: data.summary, t: t))),
      for (int i = 0; i < data.experience.length; i++)
        SizedBox(width: kGradMainW, child: KeyedSubtree(key: keys.op('e$i'),
            child: _MExpBlock(e: data.experience[i], t: t))),
      for (int i = 0; i < data.education.length; i++)
        SizedBox(width: kGradMainW, child: KeyedSubtree(key: keys.op('d$i'),
            child: _MEduBlock(e: data.education[i], t: t))),
      for (int i = 0; i < data.certifications.length; i++)
        SizedBox(width: kGradMainW, child: KeyedSubtree(key: keys.op('c$i'),
            child: _MCertBlock(s: data.certifications[i], t: t))),

      for (int i = 0; i < data.skills.length; i++)
        SizedBox(width: kGradSideW, child: KeyedSubtree(key: keys.op('sk$i'),
            child: _MSkillBlock(s: data.skills[i], t: t))),
      for (int i = 0; i < data.languages.length; i++)
        SizedBox(width: kGradSideW, child: KeyedSubtree(key: keys.op('la$i'),
            child: _MSimpleBlock(text: data.languages[i], t: t))),
      for (int i = 0; i < data.hobbies.length; i++)
        SizedBox(width: kGradSideW, child: KeyedSubtree(key: keys.op('ho$i'),
            child: _MSimpleBlock(text: data.hobbies[i], t: t))),
      for (int i = 0; i < data.references.length; i++)
        SizedBox(width: kGradSideW, child: KeyedSubtree(key: keys.op('re$i'),
            child: _MRefBlock(r: data.references[i], t: t))),
    ]);
  }
}

// ── Measure: page-1 header ────────────────────────────────────────────────────
// FIX: imgPx passed in so header height measures correctly when imageSize
// changes independently of fontSize.
class _MPage1Header extends StatelessWidget {
  final CVTemplateData data;
  final GradTheme      t;
  final double         imgPx;
  const _MPage1Header({required this.data, required this.t, required this.imgPx});

  @override
  Widget build(BuildContext ctx) {
    final initials = data.fullName
        .split(' ').where((s) => s.isNotEmpty)
        .map((s) => s[0]).take(2).join().toUpperCase();
    final initialsFontSize = (imgPx * 0.30).clamp(10.0, 32.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: kGradHeaderColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: imgPx, height: imgPx,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.18),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
          ),
          child: Center(child: Text(initials, style: TextStyle(
              fontSize: initialsFontSize, color: Colors.white,
              fontWeight: FontWeight.w300))),
        ),
        const SizedBox(width: 18),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.fullName, style: TextStyle(
                fontSize: t.fs(20), fontWeight: FontWeight.w700,
                color: Colors.white),
              softWrap: true, overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(data.jobTitle, style: TextStyle(
                  fontSize: t.fs(9.5), color: Colors.white),
                softWrap: true, overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 14, runSpacing: 4, children: [
              if (data.email.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.email_outlined, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(data.email, style: TextStyle(
                      fontSize: t.fs(9), color: Colors.white)),
                ]),
              if (data.phone.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.phone_outlined, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(data.phone, style: TextStyle(
                      fontSize: t.fs(9), color: Colors.white)),
                ]),
              if (data.location.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on_outlined, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(data.location, style: TextStyle(
                      fontSize: t.fs(9), color: Colors.white)),
                ]),
            ]),
          ],
        )),
      ]),
    );
  }
}

// ── Measure: section labels ───────────────────────────────────────────────────
// FIX: include the inter-section gap that _buildItems() adds before each label
// (14px main / 12px side) plus the 8px gap after — without this the paginator
// undercounts by that amount per section boundary, causing overflow.

class _MLabelMain extends StatelessWidget {
  final GradTheme t;
  const _MLabelMain({required this.t});
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 14), // inter-section gap before label
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: kGradBarColors,
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2),
            )),
        const SizedBox(width: 7),
        Text('EXPERIENCE', style: TextStyle(
            fontSize: t.fs(9.5), fontWeight: FontWeight.w700,
            color: kGradText, letterSpacing: 1.5)),
      ]),
      const SizedBox(height: 8), // gap after label
    ],
  );
}

class _MLabelSide extends StatelessWidget {
  final GradTheme t;
  const _MLabelSide({required this.t});
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 12), // inter-section gap before label
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: kGradBarColors,
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2),
            )),
        const SizedBox(width: 7),
        Text('SKILLS', style: TextStyle(
            fontSize: t.fs(9.5), fontWeight: FontWeight.w700,
            color: kGradText, letterSpacing: 1.5)),
      ]),
      const SizedBox(height: 8), // gap after label
    ],
  );
}

// ── Measure: content blocks ───────────────────────────────────────────────────
class _MSumBlock extends StatelessWidget {
  final String    text;
  final GradTheme t;
  const _MSumBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: TextStyle(
        fontSize: t.fs(9.5), color: kGradMuted, height: 1.65),
      softWrap: true, overflow: TextOverflow.visible,
    ),
  );
}

class _MExpBlock extends StatelessWidget {
  final CVTemplateExperience e;
  final GradTheme            t;
  const _MExpBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kGradBg,
        border: Border.all(color: kGradDivider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(e.role, style: TextStyle(
              fontSize: t.fs(11), fontWeight: FontWeight.w700,
              color: kGradText),
            softWrap: true, overflow: TextOverflow.visible,
          )),
          const SizedBox(width: 6),
          Text(e.duration, style: TextStyle(
              fontSize: t.fs(9), color: kGradLightMuted)),
        ]),
        const SizedBox(height: 2),
        Text(e.company, style: TextStyle(
            fontSize: t.fs(10), color: kGradAccentTeal,
            fontWeight: FontWeight.w600),
          softWrap: true, overflow: TextOverflow.visible,
        ),
        const SizedBox(height: 5),
        ...e.bullets.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 5, right: 7),
                child: Container(width: 5, height: 5,
                    decoration: const BoxDecoration(
                        color: kGradAccentPurple, shape: BoxShape.circle))),
            Expanded(child: Text(b, style: TextStyle(
                fontSize: t.fs(9.5), color: kGradMuted, height: 1.5),
              softWrap: true, overflow: TextOverflow.visible,
            )),
          ]),
        )),
      ]),
    ),
  );
}

class _MEduBlock extends StatelessWidget {
  final CVTemplateEducation e;
  final GradTheme           t;
  const _MEduBlock({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: kGradBarColors,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(child: Text(
            e.period.length >= 4
                ? e.period.substring(e.period.length - 2) : e.period,
            style: TextStyle(fontSize: t.fs(9.5), color: Colors.white,
                fontWeight: FontWeight.w700)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Text(e.degree, style: TextStyle(
            fontSize: t.fs(10.5), fontWeight: FontWeight.w700,
            color: kGradText),
          softWrap: true, overflow: TextOverflow.visible,
        ),
        Text(e.institution, style: TextStyle(
            fontSize: t.fs(9.5), color: kGradMuted),
          softWrap: true, overflow: TextOverflow.visible,
        ),
        if (e.detail != null && e.detail!.isNotEmpty)
          Text(e.detail!, style: TextStyle(
              fontSize: t.fs(9), color: kGradAccentTeal),
            softWrap: true, overflow: TextOverflow.visible,
          ),
      ])),
    ]),
  );
}

class _MCertBlock extends StatelessWidget {
  final String    s;
  final GradTheme t;
  const _MCertBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 5, right: 7),
          child: Container(width: 5, height: 5,
              decoration: const BoxDecoration(
                  color: kGradAccentPurple, shape: BoxShape.circle))),
      Expanded(child: Text(s, style: TextStyle(
          fontSize: t.fs(9.5), color: kGradMuted, height: 1.4),
        softWrap: true, overflow: TextOverflow.visible,
      )),
    ]),
  );
}

// FIX: _MSkillBlock — replace Flexible+SizedBox.expand() with LayoutBuilder
// to avoid infinite-width crash in the unconstrained measure layer column.
class _MSkillBlock extends StatelessWidget {
  final CVTemplateSkill s;
  final GradTheme       t;
  const _MSkillBlock({required this.s, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: Text(s.name, style: TextStyle(
            fontSize: t.fs(9.5), color: kGradText,
            fontWeight: FontWeight.w500),
          softWrap: true, overflow: TextOverflow.visible,
        )),
        Text('${s.levelOutOf10 * 10}%', style: TextStyle(
            fontSize: t.fs(9), color: kGradLightMuted)),
      ]),
      const SizedBox(height: 4),
      LayoutBuilder(builder: (ctx, bc) {
        final totalW = bc.maxWidth.isInfinite ? kGradSideW : bc.maxWidth;
        final fillW  = totalW * s.levelOutOf10 / 10;
        return ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 5, width: totalW,
            child: Row(children: [
              Container(
                width: fillW, height: 5,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: kGradBarColors)),
              ),
              Container(
                width: totalW - fillW, height: 5,
                color: kGradBarBg,
              ),
            ]),
          ),
        );
      }),
    ]),
  );
}

// FIX: _MSimpleBlock (languages, hobbies) — Flexible → Expanded + softWrap
// so long text wraps and measures correctly instead of being clipped.
class _MSimpleBlock extends StatelessWidget {
  final String    text;
  final GradTheme t;
  const _MSimpleBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Container(width: 6, height: 6,
            decoration: const BoxDecoration(
                color: kGradAccentTeal, shape: BoxShape.circle)),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(
          fontSize: t.fs(9.5), color: kGradMuted),
        softWrap: true, overflow: TextOverflow.visible,
      )),
    ]),
  );
}

// FIX: _MRefBlock — email/phone used ellipsis which clips and under-reports
// height to the paginator. Changed to softWrap + visible so measured height
// includes all wrapped lines, matching the real layout.
class _MRefBlock extends StatelessWidget {
  final CVTemplateReferee r;
  final GradTheme         t;
  const _MRefBlock({required this.r, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(r.name, style: TextStyle(
          fontSize: t.fs(10), fontWeight: FontWeight.w700,
          color: kGradText),
        softWrap: true, overflow: TextOverflow.visible,
      ),
      const SizedBox(height: 2),
      Text(r.title, style: TextStyle(
          fontSize: t.fs(9.5), color: kGradAccentTeal,
          fontWeight: FontWeight.w600),
        softWrap: true, overflow: TextOverflow.visible,
      ),
      if (r.company != null && r.company!.isNotEmpty)
        Text(r.company!, style: TextStyle(
            fontSize: t.fs(9), color: kGradLightMuted),
          softWrap: true, overflow: TextOverflow.visible,
        ),
      const SizedBox(height: 4),
      if (r.email.isNotEmpty) Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(width: 5, height: 5,
                decoration: const BoxDecoration(
                    color: kGradAccentTeal, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(r.email, style: TextStyle(
              fontSize: t.fs(9), color: kGradMuted, height: 1.35),
            softWrap: true, overflow: TextOverflow.visible,
          )),
        ]),
      ),
      if (r.phone.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(width: 5, height: 5,
              decoration: const BoxDecoration(
                  color: kGradAccentTeal, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(r.phone, style: TextStyle(
            fontSize: t.fs(9), color: kGradMuted, height: 1.35),
          softWrap: true, overflow: TextOverflow.visible,
        )),
      ]),
    ]),
  );
}