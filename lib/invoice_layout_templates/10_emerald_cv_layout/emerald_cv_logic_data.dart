// emerald_cv_logic_data.dart
// lib/cv_layout_templates/10_emerald_cv_layout/emerald_cv_logic_data.dart
//
// Data types, measurement, pagination and the EmeraldPreview entry point.
// Imports emerald_page_stationary_layout.dart for rendering.
//
// Layout: Forest-green diagonal-stripe header, white body.
// Main column (left, 380 px): Professional Summary + Work Experience + Education (overflow)
// Side column (right, 215 px): Skills + Education + Languages + Certifications + Hobbies + References
//
// KEY NOTES:
//  1. Label heights measured per-column-width, included in page-budget.
//  2. isContinued flag set correctly — "(CONT.)" appears on resume sections.
//  3. Font-size changes trigger full re-measure (keys cleared on didUpdateWidget).
//  4. Greedy paginator: avail -= (labelH if newSection) + itemH
//  5. Measurement uses data.fontFamily + FontWeight.w400 (only bundled weight).
//
// FIXES vs previous version:
//  • EmeraldPreview gains debounce (80 ms), retry cap (20), RepaintBoundary
//    per page, and build-result cache — matching ExecutivePreview quality.
//  • _EMExp measurement proxy removes the hardcoded height:60*sc timeline
//    line that forced an incorrect tall minimum — the line is now 0-height
//    in the proxy so only the actual text content is measured.
//  • All measurement proxy Text widgets gain softWrap:true + overflow:visible
//    so they measure at the same height as their render counterparts.
//  • _EMCert proxy updated to match real _ECertItem dot layout exactly
//    (Container dot with margin, not SizedBox placeholder) — fixes 12px
//    bottom overflow in certifications/hobbies sections.
//  • _kEFitTol set to 0.0 — items must fully fit within the page budget with
//    no rounding allowance. Combined with the 1.0 px safety buffer in
//    ePageUsableH this eliminates sub-pixel bottom overflow at all font sizes.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../cv_template_data/cv_template_data.dart';
import 'emerald_page_stationary_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum EmeraldSection {
  summary, experience, education,
  skill, language, certification, hobby, reference,
}

class EmeraldItem {
  final EmeraldSection section;
  final int    index;
  final double height;
  final bool   showLabel;
  final bool   isContinued;

  const EmeraldItem({
    required this.section,
    required this.index,
    required this.height,
    this.showLabel   = true,
    this.isContinued = false,
  });
}

class _EPage {
  final List<EmeraldItem> main;
  final List<EmeraldItem> side;
  const _EPage({this.main = const [], this.side = const []});
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENT KEYS
// ─────────────────────────────────────────────────────────────────────────────

class EmeraldMeasureKeys {
  final Map<String, GlobalKey> _m = {};

  GlobalKey op(String id) =>
      _m.putIfAbsent(id, () => GlobalKey(debugLabel: 'em10_$id'));

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

  /// Returns a complete height map, or null if any key is not yet measured.
  Map<String, double>? readAll(CVTemplateData d) {
    final r = <String, double>{};
    double? g(String id) {
      final v = _h(id);
      if (v == null) return null;
      r[id] = v;
      return v;
    }

    // Label prototypes — one per column
    if (g('lm') == null || g('ls') == null) return null;
    // Summary
    if (d.summary.isNotEmpty && g('sum') == null) return null;
    // Main items
    for (int i = 0; i < d.experience.length;     i++) { if (g('e$i')  == null) return null; }
    for (int i = 0; i < d.education.length;      i++) { if (g('d$i')  == null) return null; }
    // Side items
    for (int i = 0; i < d.skills.length;         i++) { if (g('sk$i') == null) return null; }
    for (int i = 0; i < d.languages.length;      i++) { if (g('la$i') == null) return null; }
    for (int i = 0; i < d.certifications.length; i++) { if (g('c$i')  == null) return null; }
    for (int i = 0; i < d.hobbies.length;        i++) { if (g('ho$i') == null) return null; }
    for (int i = 0; i < d.references.length;     i++) { if (g('re$i') == null) return null; }
    return r;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGINATOR
// ─────────────────────────────────────────────────────────────────────────────

// FIX: 0.0 instead of 0.5 — items must fully fit within budget.
// The 1.0 px safety buffer in ePageUsableH absorbs sub-pixel measurement
// rounding, so this stricter tolerance is safe at all font sizes.
const double _kEFitTol = 0.0;

List<_EPage> _paginate(Map<String, double> h, CVTemplateData d) {
  final lm = h['lm']!;
  final ls = h['ls']!;

  // ── Main queue ────────────────────────────────────────────────────────────
  final mq = <EmeraldItem>[
    if (d.summary.isNotEmpty)
      EmeraldItem(section: EmeraldSection.summary,    index: 0,  height: h['sum']  ?? 0),
    for (int i = 0; i < d.experience.length; i++)
      EmeraldItem(section: EmeraldSection.experience, index: i,  height: h['e$i']  ?? 0),
    for (int i = 0; i < d.education.length;  i++)
      EmeraldItem(section: EmeraldSection.education,  index: i,  height: h['d$i']  ?? 0),
  ];

  // ── Side queue ────────────────────────────────────────────────────────────
  final sq = <EmeraldItem>[
    for (int i = 0; i < d.skills.length;         i++)
      EmeraldItem(section: EmeraldSection.skill,         index: i, height: h['sk$i'] ?? 0),
    for (int i = 0; i < d.languages.length;       i++)
      EmeraldItem(section: EmeraldSection.language,      index: i, height: h['la$i'] ?? 0),
    for (int i = 0; i < d.certifications.length;  i++)
      EmeraldItem(section: EmeraldSection.certification, index: i, height: h['c$i']  ?? 0),
    for (int i = 0; i < d.hobbies.length;         i++)
      EmeraldItem(section: EmeraldSection.hobby,         index: i, height: h['ho$i'] ?? 0),
    for (int i = 0; i < d.references.length;      i++)
      EmeraldItem(section: EmeraldSection.reference,     index: i, height: h['re$i'] ?? 0),
  ];

  final mp = _eGreedy(mq, lm);
  final sp = _eGreedy(sq, ls);

  final n = mp.length > sp.length ? mp.length : sp.length;
  return List.generate(n, (i) => _EPage(
    main: i < mp.length ? mp[i] : const [],
    side: i < sp.length ? sp[i] : const [],
  ));
}

List<List<EmeraldItem>> _eGreedy(List<EmeraldItem> q, double lblH) {
  final pages = <List<EmeraldItem>>[];
  int qi = 0, pn = 1;
  final seen = <EmeraldSection>{};

  while (qi < q.length && pn <= 30) {
    double avail = ePageUsableH(pn == 1);
    final pg = <EmeraldItem>[];
    EmeraldSection? prev;

    while (qi < q.length) {
      final it   = q[qi];
      final nl   = it.section != prev;
      final cost = (nl ? lblH : 0) + it.height;
      if (avail < cost - _kEFitTol && pg.isNotEmpty) break;
      avail -= cost;
      pg.add(EmeraldItem(
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
// EmeraldPreview  — public entry point
// Upgraded to match ExecutivePreview: debounce, retry cap, RepaintBoundary,
// build-result cache.
// ─────────────────────────────────────────────────────────────────────────────

class EmeraldPreview extends StatefulWidget {
  final CVTemplateData data;
  final void Function(int)? onPageCount;
  const EmeraldPreview({super.key, required this.data, this.onPageCount});

  @override
  State<EmeraldPreview> createState() => _EmeraldPreviewState();
}

class _EmeraldPreviewState extends State<EmeraldPreview> {
  List<_EPage>? _pages;
  int           _gen          = 0;
  int           _retryCount   = 0;
  static const  _kMaxRetries  = 20;
  DateTime      _lastKick     = DateTime(0);

  final EmeraldMeasureKeys _k = EmeraldMeasureKeys();

  // Build-result cache — fast path when parent rebuilds but data unchanged.
  Widget? _cachedBuild;
  int?    _cachedDataHash;

  @override
  void initState() {
    super.initState();
    _kick();
  }

  @override
  void didUpdateWidget(EmeraldPreview old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _cachedBuild    = null;
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
    // Fallback: show blank page if measurement never completes.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && g == _gen && _pages == null) {
        setState(() => _pages = [const _EPage()]);
      }
    });
  }

  void _attempt(int g) {
    if (!mounted || g != _gen) return;
    // Hard cap — prevents infinite postFrameCallback chains on slow devices.
    if (_retryCount >= _kMaxRetries) {
      if (_pages == null) setState(() => _pages = [const _EPage()]);
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

    // Fast path: parent rebuilt us but nothing meaningful changed.
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
      width: kEPageW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Off-screen measurement layer ───────────────────────────────────
          SizedBox(
            width: kEPageW,
            height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: 0,
              maxHeight: 20000,
              minWidth: kEPageW,
              maxWidth: kEPageW,
              child: Offstage(child: _EMeasureLayer(data: d, keys: _k)),
            ),
          ),

          // ── Spinner while measuring ────────────────────────────────────────
          if (_pages == null)
            SizedBox(
              width: kEPageW, height: kEPageH,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),

          // ── Pages ──────────────────────────────────────────────────────────
          if (_pages != null)
            ...List.generate(_pages!.length, (i) {
              final last = i == _pages!.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                // RepaintBoundary isolates each page from parent repaints.
                child: RepaintBoundary(
                  child: EmeraldPageLayout(
                    key:        ValueKey('emerald_page_$i'),
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
// Mirrors every real block at exact column widths for accurate height reads.
// Uses data.fontFamily + FontWeight.w400 — Flutter synthesises bold from the
// Regular file so measure and render heights match exactly.
//
// FIX: _EMExp no longer has a fixed-height timeline line (was height:60*sc).
// The proxy only measures the text content — the decorative line contributes
// no layout height in the real widget either (it's inside a non-Expanded Row).
// ─────────────────────────────────────────────────────────────────────────────

class _EMeasureLayer extends StatelessWidget {
  final CVTemplateData     data;
  final EmeraldMeasureKeys keys;
  const _EMeasureLayer({required this.data, required this.keys});

  @override
  Widget build(BuildContext context) {
    final sc = data.fontSize / kEBase;
    final ff = data.fontFamily;

    return Column(mainAxisSize: MainAxisSize.min, children: [

      // Label prototypes — one per column width
      SizedBox(width: kEMainInnerW, child: KeyedSubtree(key: keys.op('lm'),
          child: _EMLabelMain(sc: sc, ff: ff))),
      SizedBox(width: kESideInnerW, child: KeyedSubtree(key: keys.op('ls'),
          child: _EMLabelSide(sc: sc, ff: ff))),

      // Summary
      if (data.summary.isNotEmpty)
        SizedBox(width: kEMainInnerW, child: KeyedSubtree(key: keys.op('sum'),
            child: _EMSum(text: data.summary, sc: sc, ff: ff))),

      // Experience
      for (int i = 0; i < data.experience.length; i++)
        SizedBox(width: kEMainInnerW, child: KeyedSubtree(key: keys.op('e$i'),
            child: _EMExp(e: data.experience[i], sc: sc, ff: ff))),

      // Education (main column overflow)
      for (int i = 0; i < data.education.length; i++)
        SizedBox(width: kEMainInnerW, child: KeyedSubtree(key: keys.op('d$i'),
            child: _EMEdu(e: data.education[i], sc: sc, ff: ff))),

      // Skills
      for (int i = 0; i < data.skills.length; i++)
        SizedBox(width: kESideInnerW, child: KeyedSubtree(key: keys.op('sk$i'),
            child: _EMSkill(s: data.skills[i], sc: sc, ff: ff))),

      // Languages
      for (int i = 0; i < data.languages.length; i++)
        SizedBox(width: kESideInnerW, child: KeyedSubtree(key: keys.op('la$i'),
            child: _EMLanguage(t: data.languages[i], sc: sc, ff: ff))),

      // Certifications
      for (int i = 0; i < data.certifications.length; i++)
        SizedBox(width: kESideInnerW, child: KeyedSubtree(key: keys.op('c$i'),
            child: _EMCert(t: data.certifications[i], sc: sc, ff: ff))),

      // Hobbies
      for (int i = 0; i < data.hobbies.length; i++)
        SizedBox(width: kESideInnerW, child: KeyedSubtree(key: keys.op('ho$i'),
            child: _EMCert(t: data.hobbies[i], sc: sc, ff: ff))),

      // References
      for (int i = 0; i < data.references.length; i++)
        SizedBox(width: kESideInnerW, child: KeyedSubtree(key: keys.op('re$i'),
            child: _EMRef(r: data.references[i], sc: sc, ff: ff))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENT PROXY WIDGETS
// All use FontWeight.w400 (only bundled weight). Bold is synthesised from
// Regular — identical line metrics so measure == render height exactly.
// All Text widgets have softWrap:true + overflow:visible to match render.
// ─────────────────────────────────────────────────────────────────────────────

class _EMLabelMain extends StatelessWidget {
  final double sc; final String ff;
  const _EMLabelMain({required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 8 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(width: 3, height: 14 * sc, color: Colors.black),
        SizedBox(width: 8 * sc),
        Expanded(child: Text('PROFESSIONAL SUMMARY',
            style: TextStyle(fontSize: 8.5 * sc, fontWeight: FontWeight.w400,
                letterSpacing: 1.8, fontFamily: ff),
            softWrap: true, overflow: TextOverflow.visible)),
      ]),
      SizedBox(height: 5 * sc),
      Container(height: 0.5, color: Colors.black12),
      SizedBox(height: 8 * sc),
    ]),
  );
}

class _EMLabelSide extends StatelessWidget {
  final double sc; final String ff;
  const _EMLabelSide({required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 8 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(width: 3, height: 14 * sc, color: Colors.black),
        SizedBox(width: 8 * sc),
        Expanded(child: Text('SKILLS',
            style: TextStyle(fontSize: 8.5 * sc, fontWeight: FontWeight.w400,
                letterSpacing: 1.8, fontFamily: ff),
            softWrap: true, overflow: TextOverflow.visible)),
      ]),
      SizedBox(height: 5 * sc),
      Container(height: 0.5, color: Colors.black12),
      SizedBox(height: 8 * sc),
    ]),
  );
}

class _EMSum extends StatelessWidget {
  final String text; final double sc; final String ff;
  const _EMSum({required this.text, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 18 * sc),
    child: Container(
      padding: EdgeInsets.all(12 * sc),
      child: Text(text,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 9.5 * sc, height: 1.65,
              fontFamily: ff, fontWeight: FontWeight.w400)),
    ),
  );
}

class _EMExp extends StatelessWidget {
  final CVTemplateExperience e; final double sc; final String ff;
  const _EMExp({required this.e, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 16 * sc),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // FIX: timeline column has 0-height line so only text is measured.
      // The decorative line in the real widget sits beside the Expanded text
      // and does not add to the layout height that the paginator needs.
      Column(children: [
        Container(width: 9 * sc, height: 9 * sc,
            margin: EdgeInsets.only(top: 2 * sc),
            decoration: const BoxDecoration(shape: BoxShape.circle,
                color: Colors.black)),
        // Removed hardcoded height:60*sc — was causing inflated measurements
      ]),
      SizedBox(width: 10 * sc),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(e.role,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: 11 * sc, fontWeight: FontWeight.w400,
                  fontFamily: ff))),
          SizedBox(width: 6 * sc),
          Text(e.duration, style: TextStyle(fontSize: 9 * sc,
              fontFamily: ff, fontWeight: FontWeight.w400)),
        ]),
        Text(e.location.isNotEmpty
            ? '${e.company}  ·  ${e.location}' : e.company,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 10 * sc, fontWeight: FontWeight.w400,
                fontFamily: ff)),
        if (e.bullets.isNotEmpty) ...[
          SizedBox(height: 5 * sc),
          ...e.bullets.map((b) => Padding(
            padding: EdgeInsets.only(bottom: 3 * sc),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: EdgeInsets.only(top: 4.5 * sc),
                  width: 3 * sc, height: 3 * sc,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                      color: Colors.black)),
              SizedBox(width: 6 * sc),
              Expanded(child: Text(b,
                  softWrap: true, overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: 9.5 * sc,
                      height: 1.4, fontFamily: ff, fontWeight: FontWeight.w400))),
            ]),
          )),
        ],
      ])),
    ]),
  );
}

class _EMEdu extends StatelessWidget {
  final CVTemplateEducation e; final double sc; final String ff;
  const _EMEdu({required this.e, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: EdgeInsets.only(bottom: 9 * sc),
    padding: EdgeInsets.all(11 * sc),
    child: Row(children: [
      Container(width: 38 * sc, height: 38 * sc),
      SizedBox(width: 10 * sc),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Text(e.degree,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 10.5 * sc,
                fontWeight: FontWeight.w400, fontFamily: ff)),
        Text(e.location.isNotEmpty
            ? '${e.institution}  ·  ${e.location}' : e.institution,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 9.5 * sc,
                fontFamily: ff, fontWeight: FontWeight.w400)),
        if (e.detail != null && e.detail!.isNotEmpty) ...[
          SizedBox(height: 2 * sc),
          Text(e.detail!,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: 9 * sc,
                  height: 1.3, fontFamily: ff, fontWeight: FontWeight.w400)),
        ],
      ])),
    ]),
  );
}

class _EMSkill extends StatelessWidget {
  final CVTemplateSkill s; final double sc; final String ff;
  const _EMSkill({required this.s, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 10 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: Text(s.name,
            overflow: TextOverflow.ellipsis, maxLines: 1,
            style: TextStyle(fontSize: 9.5 * sc,
                fontWeight: FontWeight.w400, fontFamily: ff))),
        SizedBox(width: 4 * sc),
        Text(s.percentLabel, style: TextStyle(fontSize: 8 * sc,
            fontFamily: ff, fontWeight: FontWeight.w400)),
      ]),
      SizedBox(height: 4 * sc),
      // bar height only — matches render widget
      SizedBox(height: 5 * sc),
    ]),
  );
}

// Proxy mirrors real _ELanguageChip exactly:
// Container(margin bottom:6*sc, padding H:9*sc V:5*sc, border:1px) 
// containing dot + text — so paginator budgets the correct height.
class _EMLanguage extends StatelessWidget {
  final String t; final double sc; final String ff;
  const _EMLanguage({required this.t, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: EdgeInsets.only(bottom: 6 * sc),
    padding: EdgeInsets.symmetric(horizontal: 9 * sc, vertical: 5 * sc),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6 * sc, height: 6 * sc,
          decoration: const BoxDecoration(
              color: Colors.black, shape: BoxShape.circle),
        ),
        SizedBox(width: 6 * sc),
        Text(t,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 9 * sc,
                fontFamily: ff, fontWeight: FontWeight.w400)),
      ],
    ),
  );
}

// FIX: proxy now mirrors real _ECertItem exactly —
// Container dot (width/height 6*sc, top margin 3.5*sc) + SizedBox(width 6*sc)
// instead of the old SizedBox(11*sc) placeholder that caused 12px overflow.
class _EMCert extends StatelessWidget {
  final String t; final double sc; final String ff;
  const _EMCert({required this.t, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 7 * sc),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: EdgeInsets.only(top: 3.5 * sc),
        width: 6 * sc,
        height: 6 * sc,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 6 * sc),
      Expanded(child: Text(t,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 9 * sc,
              height: 1.3, fontFamily: ff, fontWeight: FontWeight.w400))),
    ]),
  );
}

class _EMRef extends StatelessWidget {
  final CVTemplateReferee r; final double sc; final String ff;
  const _EMRef({required this.r, required this.sc, required this.ff});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: 10 * sc),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(r.name,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 9.5 * sc,
              fontWeight: FontWeight.w400, fontFamily: ff)),
      SizedBox(height: 2 * sc),
      Text(r.title,
          softWrap: true, overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 8.5 * sc,
              fontFamily: ff, fontWeight: FontWeight.w400)),
      if (r.company != null && r.company!.isNotEmpty) ...[
        SizedBox(height: 1 * sc),
        Text(r.company!,
            softWrap: true, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 8 * sc,
                fontFamily: ff, fontWeight: FontWeight.w400)),
      ],
      if (r.email.isNotEmpty) ...[
        SizedBox(height: 4 * sc),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 8 * sc, height: 8 * sc),
          SizedBox(width: 4 * sc),
          Expanded(child: Text(r.email,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: 8 * sc,
                  fontFamily: ff, fontWeight: FontWeight.w400))),
        ]),
      ],
      if (r.phone.isNotEmpty) ...[
        SizedBox(height: 2 * sc),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 8 * sc, height: 8 * sc),
          SizedBox(width: 4 * sc),
          Expanded(child: Text(r.phone,
              softWrap: true, overflow: TextOverflow.visible,
              style: TextStyle(fontSize: 8 * sc,
                  fontFamily: ff, fontWeight: FontWeight.w400))),
        ]),
      ],
    ]),
  );
}