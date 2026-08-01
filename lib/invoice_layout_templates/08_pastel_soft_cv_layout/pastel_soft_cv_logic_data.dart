// pastel_soft_cv_logic_data.dart
// lib/cv_layout_templates/08_pastel_soft_cv_layout/pastel_soft_cv_logic_data.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'pastel_soft_page_stationary_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Section enum + item
// ─────────────────────────────────────────────────────────────────────────────
enum PastelSection {
  summary, experience, education, certification,
  skill, language, hobby, reference,
}

class PastelItem {
  final PastelSection section;
  final int           index;
  final double        height;
  final bool          showLabel;
  final bool          isContinued;
  final double? clipH;
  final double  alreadyShown;

  const PastelItem({
    required this.section,
    required this.index,
    required this.height,
    this.showLabel    = true,
    this.isContinued  = false,
    this.clipH        = null,
    this.alreadyShown = 0,
  });
}

class _SubItem {
  final double height;
  const _SubItem(this.height);
}

class _RawItem {
  final PastelSection  section;
  final int            index;
  final double         height;
  final List<_SubItem> subs;

  const _RawItem({
    required this.section,
    required this.index,
    required this.height,
    this.subs = const [],
  });

  bool get isAtomic => subs.isEmpty;
}

class _Page {
  final List<PastelItem> main;
  final List<PastelItem> side;
  const _Page({this.main = const [], this.side = const []});
}

// ─────────────────────────────────────────────────────────────────────────────
// Measure key manager
// ─────────────────────────────────────────────────────────────────────────────
class PastelMeasureKeys {
  final Map<String, GlobalKey> _m = {};

  GlobalKey op(String id) =>
      _m.putIfAbsent(id, () => GlobalKey(debugLabel: 'pastel_$id'));

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

    if (g('mlbl')  == null) return null;
    if (g('slbl')  == null) return null;
    if (g('p1hdr') == null) return null;
    if (d.summary.isNotEmpty && g('sum') == null) return null;

    for (int i = 0; i < d.experience.length; i++) {
      if (g('e$i')  == null) return null;
      if (g('ef$i') == null) return null;
      for (int j = 0; j < d.experience[i].bullets.length; j++) {
        if (g('eb${i}_$j') == null) return null;
      }
    }
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
// Cut-point finder
// ─────────────────────────────────────────────────────────────────────────────
double _cutPoint(List<_SubItem> subs, double totalH, double maxH,
    {double buffer = 1.5}) {
  if (totalH <= maxH) return totalH;
  if (subs.isEmpty) return 0;

  final safeMax = maxH - buffer;
  double acc     = 0;
  double lastCut = 0;
  for (int i = 0; i < subs.length; i++) {
    acc += subs[i].height;
    if (acc > safeMax) break;
    if (i == 0 && subs.length > 1) lastCut = acc;
    if (i >= 1) lastCut = acc;
  }
  return lastCut;
}

int _subsUpTo(List<_SubItem> subs, double alreadyShown) {
  double acc = 0;
  for (int i = 0; i < subs.length; i++) {
    acc += subs[i].height;
    if (acc >= alreadyShown - 0.5) return i + 1;
  }
  return subs.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Budgets
//
// FIX: The _buildItems() method in both _SideCol and _MainCol adds inter-section
// gaps that are NOT included in individual item measurements:
//   • SizedBox(height: 14) before each section label (except first)
//   • SizedBox(height: 8)  after each section label
//   = 22px overhead per section boundary
//
// With up to 4 side sections (skills/languages/interests/references) that's
// up to 88px of unmeasured overhead. The previous _scaledSafetyMargin(8) was
// far too small. We now use a fixed 96px safety that covers:
//   • 4 × 22px = 88px max inter-section gaps
//   • 8px sub-pixel / font-scale rounding buffer
// ─────────────────────────────────────────────────────────────────────────────

// Per-section gap: 14px (before label) + 8px (after label) = 22px.
// Used to estimate overhead for sections that will appear on a given page.
const double _kLabelGapOverhead = 22.0;

// Base safety margin independent of section count.
const double _kBaseSafety = 8.0;

double _scaledCutBuffer(double sc) => (2.0 * sc).clamp(2.0, 8.0);

// Compute budget for a side column page.
// maxSections: worst-case number of section boundaries on this page.
double _sideBudget(bool isPage1, double hdrH, double sc,
    {int maxSections = 4}) {
  final safety = _kBaseSafety + maxSections * _kLabelGapOverhead;
  final base   = kPastelPageH - kPastelSidePadV * 2 - safety;
  return isPage1 ? base - hdrH : base;
}

// Compute budget for a main column page.
// maxSections: worst-case number of section boundaries (summary/exp/edu/cert = 4).
double _mainBudget(bool isPage1, double sc, {int maxSections = 4}) {
  final safety = _kBaseSafety + maxSections * _kLabelGapOverhead;
  return kPastelPageH - kPastelMainPadV * 2 - safety;
}

// ─────────────────────────────────────────────────────────────────────────────
// Split-aware paginator (single column)
// ─────────────────────────────────────────────────────────────────────────────
List<List<PastelItem>> _splitPaginate(
    List<_RawItem> q,
    double lblH,
    double hdrH,
    double sc, {
    bool isMain = true,
}) {
  final pages          = <List<PastelItem>>[];
  int qi               = 0;
  int pn               = 1;
  final seen           = <PastelSection>{};
  double? carryAlready;
  double? carryRemaining;
  List<_SubItem>? carrySubs;

  while ((qi < q.length || carryRemaining != null) && pn <= 60) {
    double avail = isMain
        ? _mainBudget(pn == 1, sc)
        : _sideBudget(pn == 1, hdrH, sc);
    if (avail <= 0) { pn++; continue; }

    final pg     = <PastelItem>[];
    PastelSection? prev;

    // ── Carry-over from previous page ──
    if (carryRemaining != null) {
      final it           = q[qi - 1];
      final remaining    = carryRemaining!;
      final alreadyShown = carryAlready!;
      final subs         = carrySubs ?? [];

      avail -= lblH;
      if (avail <= 0) { pn++; continue; }

      final fits = remaining <= avail;
      double renderH;
      if (fits) {
        renderH = remaining;
      } else if (subs.isEmpty) {
        pn++; continue;
      } else {
        final shownSubs = _subsUpTo(subs, alreadyShown);
        final remSubs   = subs.sublist(shownSubs);
        final cut = _cutPoint(remSubs, remaining, avail,
            buffer: _scaledCutBuffer(sc));
        if (cut == 0) { pn++; continue; }
        renderH = cut;
      }

      pg.add(PastelItem(
        section:       it.section,
        index:         it.index,
        height:        it.height,
        clipH:         fits ? null : renderH,
        alreadyShown:  alreadyShown,
        showLabel:     true,
        isContinued:   true,
      ));
      if (!seen.contains(it.section)) seen.add(it.section);
      avail -= renderH;
      prev   = it.section;

      if (fits) {
        carryRemaining = null;
        carryAlready   = null;
        carrySubs      = null;
      } else {
        carryAlready   = alreadyShown + renderH;
        carryRemaining = remaining - renderH;
        pages.add(pg); pn++; continue;
      }
    }

    // ── Normal greedy fill ──
    while (qi < q.length) {
      final it       = q[qi];
      final nl       = it.section != prev;
      final lblCost  = nl ? lblH : 0.0;
      if (avail <= lblCost) break;
      final contentAvail = avail - lblCost;

      final fits = it.height <= contentAvail;

      if (!fits && !it.isAtomic) {
        final cut = _cutPoint(it.subs, it.height, contentAvail,
            buffer: _scaledCutBuffer(sc));
        if (cut == 0) {
          if (pg.isNotEmpty) break;
          pg.add(PastelItem(
            section:    it.section,
            index:      it.index,
            height:     it.height,
            showLabel:  nl,
            isContinued: nl && seen.contains(it.section),
          ));
          if (nl) seen.add(it.section);
          prev  = it.section;
          avail -= lblCost + it.height;
          qi++;
          break;
        }
        pg.add(PastelItem(
          section:    it.section,
          index:      it.index,
          height:     it.height,
          clipH:      cut,
          showLabel:  nl,
          isContinued: nl && seen.contains(it.section),
        ));
        if (nl) seen.add(it.section);
        prev           = it.section;
        avail         -= lblCost + cut;
        qi++;
        carryAlready   = cut;
        carryRemaining = it.height - cut;
        carrySubs      = it.subs;
        break;
      }

      if (!fits) {
        if (pg.isNotEmpty) break;
      }

      pg.add(PastelItem(
        section:    it.section,
        index:      it.index,
        height:     it.height,
        showLabel:  nl,
        isContinued: nl && seen.contains(it.section),
      ));
      if (nl) seen.add(it.section);
      prev  = it.section;
      avail -= lblCost + it.height;
      qi++;
    }

    if (pg.isNotEmpty) pages.add(pg);
    pn++;
  }
  return pages;
}

// ─────────────────────────────────────────────────────────────────────────────
// Build raw item queues
// ─────────────────────────────────────────────────────────────────────────────
List<_RawItem> _buildMainQueue(Map<String, double> h, CVTemplateData d) {
  final items = <_RawItem>[];

  if (d.summary.isNotEmpty) {
    items.add(_RawItem(
      section: PastelSection.summary,
      index:   -1,
      height:  h['sum'] ?? 0,
      subs:    [],
    ));
  }

  for (int i = 0; i < d.experience.length; i++) {
    final headerH = h['ef$i'] ?? 0.0;
    const cardPadTop    = 14.0;
    const cardPadBottom = 14.0;
    const cardMarginB   = 8.0;
    final subs = <_SubItem>[
      _SubItem(cardPadTop + headerH + cardPadBottom + cardMarginB),
      for (int j = 0; j < d.experience[i].bullets.length; j++)
        _SubItem(h['eb${i}_$j'] ?? 0.0),
    ];
    items.add(_RawItem(
      section: PastelSection.experience,
      index:   i,
      height:  h['e$i'] ?? 0,
      subs:    subs,
    ));
  }

  for (int i = 0; i < d.education.length; i++) {
    items.add(_RawItem(
      section: PastelSection.education,
      index:   i,
      height:  h['d$i'] ?? 0,
      subs:    [],
    ));
  }

  for (int i = 0; i < d.certifications.length; i++) {
    items.add(_RawItem(
      section: PastelSection.certification,
      index:   i,
      height:  h['c$i'] ?? 0,
      subs:    [],
    ));
  }

  return items;
}

List<_RawItem> _buildSideQueue(Map<String, double> h, CVTemplateData d) {
  final items = <_RawItem>[];
  for (int i = 0; i < d.skills.length;     i++)
    items.add(_RawItem(section: PastelSection.skill,     index: i, height: h['sk$i'] ?? 0));
  for (int i = 0; i < d.languages.length;  i++)
    items.add(_RawItem(section: PastelSection.language,  index: i, height: h['la$i'] ?? 0));
  for (int i = 0; i < d.hobbies.length;    i++)
    items.add(_RawItem(section: PastelSection.hobby,     index: i, height: h['ho$i'] ?? 0));
  for (int i = 0; i < d.references.length; i++)
    items.add(_RawItem(section: PastelSection.reference, index: i, height: h['re$i'] ?? 0));
  return items;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination entry point
// ─────────────────────────────────────────────────────────────────────────────
List<_Page> _paginate(Map<String, double> h, CVTemplateData d) {
  final mlbl = h['mlbl']!;
  final slbl = h['slbl']!;
  final hdrH = h['p1hdr']!;
  final sc   = (d.fontSize > 0 ? d.fontSize : kPastelBaseFontSize) / kPastelBaseFontSize;

  final mq = _buildMainQueue(h, d);
  final sq = _buildSideQueue(h, d);

  final mp = _splitPaginate(mq, mlbl, hdrH, sc, isMain: true);
  final sp = _splitPaginate(sq, slbl, hdrH, sc, isMain: false);

  final n = mp.length > sp.length ? mp.length : sp.length;
  return List.generate(n, (i) => _Page(
    main: i < mp.length ? mp[i] : const [],
    side: i < sp.length ? sp[i] : const [],
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// PastelPreview — StatefulWidget
// ─────────────────────────────────────────────────────────────────────────────
class PastelPreview extends StatefulWidget {
  final CVTemplateData      data;
  final void Function(int)? onPageCount;

  const PastelPreview({
    super.key,
    required this.data,
    this.onPageCount,
  });

  @override
  State<PastelPreview> createState() => _PastelPreviewState();
}

class _PastelPreviewState extends State<PastelPreview> {
  List<_Page>?    _pages;
  int             _gen        = 0;
  int             _retryCount = 0;
  static const    _kMaxRetries = 20;
  DateTime        _lastKick   = DateTime(0);

  final PastelMeasureKeys _k = PastelMeasureKeys();

  Widget? _cachedBuild;
  int?    _cachedDataHash;

  @override
  void initState() {
    super.initState();
    _kick();
  }

  @override
  void didUpdateWidget(PastelPreview old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _cachedBuild    = null;
      _cachedDataHash = null;
      final now = DateTime.now();
      final gap = now.difference(_lastKick).inMilliseconds;
      if (gap < 80) {
        final pg = _gen + 1;
        Future.delayed(Duration(milliseconds: 80 - gap), () {
          if (mounted && _gen < pg) _kickNow();
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
    final t = pastelThemeFromData(d);
    return SizedBox(
      width: kPastelPageW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: kPastelPageW,
            height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: 0,
              maxHeight: 20000,
              minWidth:  kPastelPageW,
              maxWidth:  kPastelPageW,
              child: Offstage(
                child: _MeasureLayer(data: d, keys: _k, t: t),
              ),
            ),
          ),

          if (_pages == null)
            SizedBox(
              width: kPastelPageW, height: kPastelPageH,
              child: ColoredBox(
                color: kPastelBg,
                child: Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: t.accent)),
              ),
            ),

          if (_pages != null)
            ...List.generate(_pages!.length, (i) {
              final last = i == _pages!.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                child: PastelPageLayout(
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
  final CVTemplateData    data;
  final PastelMeasureKeys keys;
  final PastelTheme       t;
  const _MeasureLayer({required this.data, required this.keys, required this.t});

  @override
  Widget build(BuildContext context) {
    const cardPadH     = 14.0 * 2;
    const bulletIndent = 5.0 + 7.0;
    final headerW = kPastelMainW - cardPadH;
    final bulletW = kPastelMainW - cardPadH - bulletIndent;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: kPastelMainW,   child: KeyedSubtree(key: keys.op('mlbl'),
          child: _MMainLabel(t: t))),
      SizedBox(width: kPastelSideInW, child: KeyedSubtree(key: keys.op('slbl'),
          child: _MSideLabel(t: t))),
      SizedBox(width: kPastelSideInW, child: KeyedSubtree(key: keys.op('p1hdr'),
          child: _MSideHeader(data: data, t: t))),

      for (int i = 0; i < data.skills.length; i++)
        SizedBox(width: kPastelSideInW, child: KeyedSubtree(key: keys.op('sk$i'),
            child: _MSkillTag(name: data.skills[i].name, t: t))),
      for (int i = 0; i < data.languages.length; i++)
        SizedBox(width: kPastelSideInW, child: KeyedSubtree(key: keys.op('la$i'),
            child: _MLangItem(text: data.languages[i], t: t))),
      for (int i = 0; i < data.hobbies.length; i++)
        SizedBox(width: kPastelSideInW, child: KeyedSubtree(key: keys.op('ho$i'),
            child: _MLangItem(text: data.hobbies[i], t: t))),
      for (int i = 0; i < data.references.length; i++)
        SizedBox(width: kPastelSideInW, child: KeyedSubtree(key: keys.op('re$i'),
            child: _MRefBlock(r: data.references[i], t: t))),

      if (data.summary.isNotEmpty)
        SizedBox(width: kPastelMainW, child: KeyedSubtree(key: keys.op('sum'),
            child: _MSummaryBlock(text: data.summary, t: t))),

      for (int i = 0; i < data.experience.length; i++) ...[
        SizedBox(width: kPastelMainW, child: KeyedSubtree(key: keys.op('e$i'),
            child: _MExpCard(e: data.experience[i], t: t))),
        SizedBox(width: headerW, child: KeyedSubtree(key: keys.op('ef$i'),
            child: _MExpCardHeader(e: data.experience[i], t: t))),
        for (int j = 0; j < data.experience[i].bullets.length; j++)
          SizedBox(width: bulletW, child: KeyedSubtree(key: keys.op('eb${i}_$j'),
              child: _MBulletRow(text: data.experience[i].bullets[j], t: t))),
      ],

      for (int i = 0; i < data.education.length; i++)
        SizedBox(width: kPastelMainW, child: KeyedSubtree(key: keys.op('d$i'),
            child: _MEduCard(e: data.education[i], t: t))),
      for (int i = 0; i < data.certifications.length; i++)
        SizedBox(width: kPastelMainW, child: KeyedSubtree(key: keys.op('c$i'),
            child: _MCertItem(text: data.certifications[i], t: t))),
    ]);
  }
}

// ── Measure proxy widgets ──────────────────────────────────────────────────────
class _MMainLabel extends StatelessWidget {
  final PastelTheme t;
  const _MMainLabel({required this.t});
  @override
  Widget build(BuildContext ctx) => Row(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: kPastelLavDBg12, borderRadius: BorderRadius.circular(16)),
      child: Text('Experience', softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(11), fontWeight: FontWeight.w700,
              color: kPastelLavD, fontFamily: t.font)),
    ),
    const SizedBox(width: 10),
    Expanded(child: Container(height: 1, color: kPastelLavDBg12)),
  ]);
}

class _MSideLabel extends StatelessWidget {
  final PastelTheme t;
  const _MSideLabel({required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SKILLS', softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(9.5), fontWeight: FontWeight.w700,
              color: kPastelLavD, letterSpacing: 2, fontFamily: t.font)),
      const SizedBox(height: 4),
      Container(height: 1, color: kPastelLavMBd50),
    ]),
  );
}

class _MSideHeader extends StatelessWidget {
  final CVTemplateData data;
  final PastelTheme    t;
  const _MSideHeader({required this.data, required this.t});
  @override
  Widget build(BuildContext ctx) {
    final imgPx = pastelImgPx(data.imageSize);
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Center(child: SizedBox(width: imgPx, height: imgPx)),
      const SizedBox(height: 10),
      Text(data.fullName, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(12), fontWeight: FontWeight.w800,
              color: kPastelInk, height: 1.3, fontFamily: t.font)),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: kPastelLavDBg12,
            borderRadius: BorderRadius.circular(16)),
        child: Text(data.jobTitle, softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(9), color: t.accent,
                fontWeight: FontWeight.w600, fontFamily: t.font)),
      ),
      const SizedBox(height: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONTACT', softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(9.5), fontWeight: FontWeight.w700,
                color: kPastelLavD, letterSpacing: 2, fontFamily: t.font)),
        const SizedBox(height: 4),
        Container(height: 1, color: kPastelLavMBd50),
      ]),
      const SizedBox(height: 8),
      if (data.email.isNotEmpty)    _MContactRow(text: data.email,    t: t),
      if (data.phone.isNotEmpty)    _MContactRow(text: data.phone,    t: t),
      if (data.location.isNotEmpty) _MContactRow(text: data.location, t: t),
      if (data.website.isNotEmpty)  _MContactRow(text: data.website,  t: t),
      const SizedBox(height: 6),
    ]);
  }
}

class _MContactRow extends StatelessWidget {
  final String text; final PastelTheme t;
  const _MContactRow({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 24, height: 24,
          decoration: BoxDecoration(color: kPastelLavDBg12,
              borderRadius: BorderRadius.circular(7))),
      const SizedBox(width: 7),
      Expanded(child: Text(text, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(9), color: kPastelMuted,
              height: 1.35, fontFamily: t.font))),
    ]),
  );
}

class _MSkillTag extends StatelessWidget {
  final String name; final PastelTheme t;
  const _MSkillTag({required this.name, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPastelLavMBd50)),
      child: Text(name, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(9.5), color: kPastelInk,
              fontWeight: FontWeight.w500, fontFamily: t.font)),
    ),
  );
}

class _MLangItem extends StatelessWidget {
  final String text; final PastelTheme t;
  const _MLangItem({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, softWrap: true, overflow: TextOverflow.visible,
        style: TextStyle(fontSize: t.fs(9.5), color: kPastelMuted,
            height: 1.4, fontFamily: t.font)),
  );
}

class _MRefBlock extends StatelessWidget {
  final CVTemplateReferee r; final PastelTheme t;
  const _MRefBlock({required this.r, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(r.name, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(10), fontWeight: FontWeight.w700,
              color: kPastelInk, height: 1.3, fontFamily: t.font)),
      const SizedBox(height: 2),
      Text(r.title, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(9), color: kPastelLavD,
              fontWeight: FontWeight.w600, height: 1.3, fontFamily: t.font)),
      if (r.company != null && r.company!.isNotEmpty) ...[
        const SizedBox(height: 1),
        Text(r.company!, softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(9), color: kPastelMuted,
                height: 1.3, fontFamily: t.font)),
      ],
      const SizedBox(height: 5),
      if (r.email.isNotEmpty) _MRefContactRow(text: r.email, t: t),
      if (r.phone.isNotEmpty) ...[
        const SizedBox(height: 4),
        _MRefContactRow(text: r.phone, t: t),
      ],
    ]),
  );
}

class _MRefContactRow extends StatelessWidget {
  final String text; final PastelTheme t;
  const _MRefContactRow({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(width: 20, height: 20,
          decoration: BoxDecoration(color: kPastelLavDBg12,
              borderRadius: BorderRadius.circular(6))),
      const SizedBox(width: 5),
      Expanded(child: Text(text, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(8.5), color: kPastelMuted,
              height: 1.35, fontFamily: t.font))),
    ],
  );
}

class _MSummaryBlock extends StatelessWidget {
  final String text; final PastelTheme t;
  const _MSummaryBlock({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPastelPeachBg,
          borderRadius: BorderRadius.circular(12)),
      child: Text(text, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
              height: 1.7, fontFamily: t.font)),
    ),
  );
}

class _MExpCard extends StatelessWidget {
  final CVTemplateExperience e; final PastelTheme t;
  const _MExpCard({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(e.role, softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(12), fontWeight: FontWeight.w700,
                color: kPastelInk, fontFamily: t.font))),
        const SizedBox(width: 8),
        IntrinsicWidth(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: kPastelLavender,
              borderRadius: BorderRadius.circular(14)),
          child: Text(e.duration, softWrap: false, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: t.fs(9), color: kPastelLavD,
                  fontFamily: t.font)),
        )),
      ]),
      const SizedBox(height: 3),
      Text(e.company, softWrap: true, overflow: TextOverflow.visible,
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
            Expanded(child: Text(b, softWrap: true, overflow: TextOverflow.visible,
                style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
                    height: 1.4, fontFamily: t.font))),
          ]),
        )),
      ],
    ]),
  );
}

class _MExpCardHeader extends StatelessWidget {
  final CVTemplateExperience e; final PastelTheme t;
  const _MExpCardHeader({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(e.role, softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(12), fontWeight: FontWeight.w700,
                color: kPastelInk, fontFamily: t.font))),
        const SizedBox(width: 8),
        IntrinsicWidth(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: kPastelLavender,
              borderRadius: BorderRadius.circular(14)),
          child: Text(e.duration, softWrap: false, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: t.fs(9), color: kPastelLavD,
                  fontFamily: t.font)),
        )),
      ]),
      const SizedBox(height: 3),
      Text(e.company, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(11), color: kPastelPeach,
              fontWeight: FontWeight.w600, fontFamily: t.font)),
      if (e.bullets.isNotEmpty) const SizedBox(height: 7),
    ],
  );
}

class _MBulletRow extends StatelessWidget {
  final String text; final PastelTheme t;
  const _MBulletRow({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 5),
          child: Container(width: 5, height: 5,
              decoration: const BoxDecoration(
                  color: kPastelLavM, shape: BoxShape.circle))),
      const SizedBox(width: 7),
      Expanded(child: Text(text, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
              height: 1.4, fontFamily: t.font))),
    ]),
  );
}

class _MEduCard extends StatelessWidget {
  final CVTemplateEducation e; final PastelTheme t;
  const _MEduCard({required this.e, required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(color: kPastelLavender,
              borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(
            e.period.split('–').last.trim().split(' ').last,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: t.fs(10), fontWeight: FontWeight.w700,
                color: kPastelLavD, fontFamily: t.font)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Text(e.degree, softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(12), fontWeight: FontWeight.w700,
                color: kPastelInk, fontFamily: t.font)),
        Text(e.institution, softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
                fontFamily: t.font)),
        if (e.detail != null && e.detail!.isNotEmpty)
          Text(e.detail!, softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: t.fs(10), color: kPastelMuted,
                  fontFamily: t.font)),
      ])),
    ]),
  );
}

class _MCertItem extends StatelessWidget {
  final String text; final PastelTheme t;
  const _MCertItem({required this.text, required this.t});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 5),
          child: Container(width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: kPastelLavM, shape: BoxShape.circle))),
      const SizedBox(width: 8),
      Expanded(child: Text(text, softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: t.fs(11), color: kPastelMuted,
              height: 1.4, fontFamily: t.font))),
    ]),
  );
}