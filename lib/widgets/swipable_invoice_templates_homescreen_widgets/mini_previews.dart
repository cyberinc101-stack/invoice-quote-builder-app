// lib/widgets/swipable_cv_templates_homescreen_widgets/mini_previews.dart
//
// Pixel-faithful scaled-down previews of each CV template.
// These are rendered at full size inside a Transform.scale so every
// font, colour, and layout detail matches the full preview modal.
//
// Design width = 320px (matches the card's intrinsic width before scaling).

import 'package:flutter/material.dart';
import 'template_data.dart';

/// Returns the mini-preview widget for [templateId].
Widget buildMiniPreview(int templateId) {
  switch (templateId) {
    case 1:  return const MiniExec();
    case 2:  return const MiniNordic();
    case 3:  return const MiniVibrant();
    case 4:  return const MiniTechDark();
    case 5:  return const MiniLuxury();
    default: return const MiniExec();
  }
}

// ─── shared tiny helpers ──────────────────────────────────────────────────────
Widget _b(double w, double h, Color c, {double r = 1.5}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

Widget _lines(int n, Color c, {double h = 2.5, double gap = 3.5, double? w}) =>
    Column(children: List.generate(n, (_) => Container(
      margin: EdgeInsets.only(bottom: gap),
      height: h,
      width: w ?? double.infinity,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(1)),
    )));

Widget _miniSkillBar(double pct, Color fill, Color bg) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Stack(children: [
    Container(height: 3, decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(1.5))),
    FractionallySizedBox(widthFactor: pct, child: Container(height: 3,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(1.5)))),
  ]),
);

Widget _label(String t, Color c, {double fs = 5.5, double spacing = 1.2}) =>
    Text(t, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w800,
        color: c, letterSpacing: spacing));

// ═════════════════════════════════════════════════════════════════════════════
// T01 — Executive  (dark navy sidebar + gold accents + light main)
// ═════════════════════════════════════════════════════════════════════════════
class MiniExec extends StatelessWidget {
  const MiniExec({super.key});
  static const _navy = Color(0xFF0D1B2A);
  static const _gold = Color(0xFFC9A84C);
  static const _bg   = Color(0xFFF8F9FC);
  static const _ink  = Color(0xFF1A1A2E);
  static const _grey = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ── Sidebar ───────────────────────────────────────────────────
      Container(
        width: 72, color: _navy,
        padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Avatar
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 1.5),
              color: const Color(0xFF1B2E45),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white24, size: 15),
          ),
          const SizedBox(height: 9),
          _label('CONTACT', _gold, fs: 5, spacing: 1),
          _b(double.infinity, 1, _gold.withOpacity(0.4)),
          const SizedBox(height: 4),
          _lines(3, Colors.white24, h: 2, gap: 2.5),
          const SizedBox(height: 7),
          _label('SKILLS', _gold, fs: 5, spacing: 1),
          _b(double.infinity, 1, _gold.withOpacity(0.4)),
          const SizedBox(height: 4),
          for (final pct in [0.95, 0.90, 0.85, 0.88, 0.80, 0.70])
            _miniSkillBar(pct, _gold, Colors.white12),
          const SizedBox(height: 7),
          _label('LANGUAGES', _gold, fs: 5, spacing: 1),
          _b(double.infinity, 1, _gold.withOpacity(0.4)),
          const SizedBox(height: 4),
          _lines(3, Colors.white24, h: 2, gap: 2.5),
          const SizedBox(height: 7),
          _label('CERTS', _gold, fs: 5, spacing: 1),
          _b(double.infinity, 1, _gold.withOpacity(0.4)),
          const SizedBox(height: 4),
          _lines(2, Colors.white24, h: 2, gap: 2.5),
        ]),
      ),
      // ── Main ──────────────────────────────────────────────────────
      Expanded(child: Container(
        color: _bg,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ALEXANDRA CHEN', style: const TextStyle(
              fontSize: 8.5, fontWeight: FontWeight.w900,
              color: _ink, letterSpacing: 2)),
          const SizedBox(height: 2),
          _b(22, 2.5, _gold),
          const SizedBox(height: 2),
          Text(MockCv.title, style: const TextStyle(
              fontSize: 5.5, color: _grey, letterSpacing: 1)),
          const SizedBox(height: 10),
          // Profile section
          Row(children: [_b(2.5, 8, _gold), const SizedBox(width: 4),
            _label('PROFILE', _ink, fs: 5.5, spacing: 1.5)]),
          const SizedBox(height: 4),
          _lines(3, _grey.withOpacity(0.5), h: 2, gap: 2),
          const SizedBox(height: 8),
          // Experience section
          Row(children: [_b(2.5, 8, _gold), const SizedBox(width: 4),
            _label('EXPERIENCE', _ink, fs: 5.5, spacing: 1.5)]),
          const SizedBox(height: 5),
          for (final e in MockCv.exp) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 3),
                child: Container(width: 5, height: 5, decoration:
                    const BoxDecoration(color: _gold, shape: BoxShape.circle))),
              const SizedBox(width: 4),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.$1, style: const TextStyle(fontSize: 5.5,
                    fontWeight: FontWeight.w700, color: _ink)),
                Text(e.$2, style: const TextStyle(fontSize: 5,
                    color: _gold, fontWeight: FontWeight.w600)),
                _lines(2, _grey.withOpacity(0.4), h: 1.5, gap: 1.5),
              ])),
              Text(e.$3, style: const TextStyle(fontSize: 4.5, color: _grey)),
            ]),
            const SizedBox(height: 5),
          ],
          const SizedBox(height: 2),
          // Education section
          Row(children: [_b(2.5, 8, _gold), const SizedBox(width: 4),
            _label('EDUCATION', _ink, fs: 5.5, spacing: 1.5)]),
          const SizedBox(height: 5),
          for (final e in MockCv.edu) ...[
            Row(children: [
              Container(width: 5, height: 5, decoration:
                  const BoxDecoration(color: _gold, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.$1, style: const TextStyle(fontSize: 5.5,
                    fontWeight: FontWeight.w700, color: _ink)),
                Text(e.$2, style: const TextStyle(fontSize: 5, color: _gold)),
              ])),
            ]),
            const SizedBox(height: 4),
          ],
        ]),
      )),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// T02 — Nordic  (white background, blue accents, light & airy)
// ═════════════════════════════════════════════════════════════════════════════
class MiniNordic extends StatelessWidget {
  const MiniNordic({super.key});
  static const _blue  = Color(0xFF2563EB);
  static const _ink   = Color(0xFF111111);
  static const _muted = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Alexandra Chen', style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w300,
                color: _ink, letterSpacing: -0.3, height: 1)),
            const SizedBox(height: 2.5),
            Text(MockCv.title, style: const TextStyle(
                fontSize: 5.5, color: _blue, fontWeight: FontWeight.w500)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(MockCv.email, style: const TextStyle(fontSize: 4.5, color: _muted)),
            Text(MockCv.phone, style: const TextStyle(fontSize: 4.5, color: _muted)),
            Text(MockCv.loc,   style: const TextStyle(fontSize: 4.5, color: _muted)),
          ]),
        ]),
        const SizedBox(height: 6),
        _b(double.infinity, 0.5, const Color(0xFFE0E0E0)),
        const SizedBox(height: 7),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Main col
          Expanded(flex: 6, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('ABOUT', _ink, spacing: 2),
            const SizedBox(height: 3),
            _lines(2, _muted.withOpacity(0.5), h: 2, gap: 2),
            const SizedBox(height: 7),
            _label('EXPERIENCE', _ink, spacing: 2),
            const SizedBox(height: 4),
            for (final e in MockCv.exp) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.$2, style: const TextStyle(fontSize: 5.5,
                    fontWeight: FontWeight.w600, color: _ink)),
                Text(e.$3, style: const TextStyle(fontSize: 4.5, color: _muted)),
              ]),
              Text(e.$1, style: const TextStyle(
                  fontSize: 5, color: _blue, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              _lines(2, _muted.withOpacity(0.4), h: 1.5, gap: 1.5),
              const SizedBox(height: 5),
            ],
            _label('EDUCATION', _ink, spacing: 2),
            const SizedBox(height: 4),
            for (final e in MockCv.edu) ...[
              Text(e.$2, style: const TextStyle(fontSize: 5.5,
                  fontWeight: FontWeight.w600, color: _ink)),
              Text(e.$1, style: const TextStyle(fontSize: 5, color: _muted)),
              const SizedBox(height: 4),
            ],
          ])),
          const SizedBox(width: 9),
          // Side col
          SizedBox(width: 52, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('SKILLS', _ink, spacing: 2),
            const SizedBox(height: 4),
            for (final s in MockCv.skills)
              Padding(padding: const EdgeInsets.only(bottom: 1),
                  child: _miniSkillBar(s.$2, _blue, const Color(0xFFE0E8FF))),
            const SizedBox(height: 7),
            _label('LANGUAGES', _ink, spacing: 2),
            const SizedBox(height: 4),
            _lines(3, _muted.withOpacity(0.5), h: 2, gap: 2.5),
            const SizedBox(height: 7),
            _label('CERTS', _ink, spacing: 2),
            const SizedBox(height: 4),
            _lines(2, _muted.withOpacity(0.4), h: 2, gap: 2.5),
          ])),
        ]),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// T03 — Vibrant  (coral header + white body + pale sidebar)
// ═════════════════════════════════════════════════════════════════════════════
class MiniVibrant extends StatelessWidget {
  const MiniVibrant({super.key});
  static const _coral = Color(0xFFFF5C35);
  static const _pale  = Color(0xFFFFF1EE);
  static const _dark  = Color(0xFF1A1A1A);
  static const _mid   = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ── Header ────────────────────────────────────────────────────
      Container(
        color: _coral,
        padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              color: Colors.white.withOpacity(0.18),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white60, size: 16),
          ),
          const SizedBox(width: 7),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Alexandra Chen', style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(2)),
              child: Text(MockCv.title, style: const TextStyle(
                  fontSize: 4.5, color: _coral, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.email_outlined, color: Colors.white60, size: 7),
              const SizedBox(width: 2),
              Text(MockCv.email, style: const TextStyle(
                  fontSize: 4.5, color: Colors.white70)),
            ]),
            const SizedBox(height: 1),
            Row(children: [
              const Icon(Icons.location_on_outlined, color: Colors.white60, size: 7),
              const SizedBox(width: 2),
              Text(MockCv.loc, style: const TextStyle(
                  fontSize: 4.5, color: Colors.white70)),
            ]),
          ])),
        ]),
      ),
      // ── Body ──────────────────────────────────────────────────────
      Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Main
        Expanded(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _coralSectionHead('ABOUT ME'),
            const SizedBox(height: 3),
            _lines(2, _mid.withOpacity(0.35), h: 2, gap: 2),
            const SizedBox(height: 6),
            _coralSectionHead('EXPERIENCE'),
            const SizedBox(height: 3),
            for (final e in MockCv.exp) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.$1, style: const TextStyle(fontSize: 5.5,
                    fontWeight: FontWeight.w700, color: _dark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: _coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2)),
                  child: Text(e.$3, style: const TextStyle(
                      fontSize: 4, color: _coral, fontWeight: FontWeight.w600)),
                ),
              ]),
              Text(e.$2, style: const TextStyle(fontSize: 5,
                  color: _coral, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              _lines(2, _mid.withOpacity(0.3), h: 1.5, gap: 1.5),
              Divider(color: Colors.grey.shade100, height: 8, thickness: 0.5),
            ],
            _coralSectionHead('EDUCATION'),
            const SizedBox(height: 3),
            for (final e in MockCv.edu) ...[
              Row(children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                      color: _coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4)),
                  child: Center(child: Text('16', style: const TextStyle(
                      fontSize: 4.5, fontWeight: FontWeight.w700, color: _coral))),
                ),
                const SizedBox(width: 4),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.$1, style: const TextStyle(fontSize: 5.5,
                      fontWeight: FontWeight.w700, color: _dark)),
                  Text(e.$2, style: const TextStyle(fontSize: 4.5, color: _mid)),
                ]),
              ]),
              const SizedBox(height: 5),
            ],
          ]),
        )),
        // Sidebar
        Container(
          width: 64, color: _pale,
          padding: const EdgeInsets.all(7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _coralSectionHead('SKILLS'),
            const SizedBox(height: 4),
            for (final s in MockCv.skills)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _coral.withOpacity(0.3))),
                child: Text(s.$1, style: const TextStyle(
                    fontSize: 4.5, color: _dark, fontWeight: FontWeight.w500)),
              ),
            const SizedBox(height: 5),
            _coralSectionHead('LANGS'),
            const SizedBox(height: 4),
            for (final l in MockCv.langs)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  Container(width: 3.5, height: 3.5,
                      decoration: const BoxDecoration(color: _coral, shape: BoxShape.circle)),
                  const SizedBox(width: 3),
                  Flexible(child: Text(l.split(' ')[0], style: const TextStyle(
                      fontSize: 4.5, color: _mid))),
                ]),
              ),
          ]),
        ),
      ])),
    ]);
  }

  Widget _coralSectionHead(String t) => Row(children: [
    _b(10, 2, _coral), const SizedBox(width: 4),
    Text(t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800,
        color: _dark, letterSpacing: 1)),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// T04 — Tech Dark  (github-style dark bg, green/blue/yellow terminal palette)
// ═════════════════════════════════════════════════════════════════════════════
class MiniTechDark extends StatelessWidget {
  const MiniTechDark({super.key});
  static const _bg      = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF30363D);
  static const _green   = Color(0xFF3FB950);
  static const _blue    = Color(0xFF58A6FF);
  static const _yellow  = Color(0xFFE3B341);
  static const _white   = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Sidebar ─────────────────────────────────────────────────
        Container(
          width: 76,
          color: _surface,
          decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: _border, width: 0.5))),
          padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Traffic lights
            Row(children: [
              for (final c in [Color(0xFFFF5F57), Color(0xFFFFBD2E), Color(0xFF27C840)])
                Container(margin: const EdgeInsets.only(right: 3),
                    width: 5, height: 5,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 8),
            Center(child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _green, width: 1.2),
                  color: _bg),
              child: const Icon(Icons.terminal, color: _green, size: 12),
            )),
            const SizedBox(height: 8),
            Text('// CONTACT', style: TextStyle(
                fontFamily: 'monospace', fontSize: 5, color: _yellow,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            for (final row in [
              ('email', MockCv.email.split('@')[0]),
              ('phone', MockCv.phone),
              ('loc',   MockCv.loc),
              ('web',   MockCv.web),
            ])
              Padding(padding: const EdgeInsets.only(bottom: 2),
                  child: Row(children: [
                    Text('${row.$1}: ', style: TextStyle(fontFamily: 'monospace',
                        fontSize: 4.5, color: _blue)),
                    Flexible(child: Text(row.$2, style: TextStyle(
                        fontFamily: 'monospace', fontSize: 4.5, color: _muted),
                        overflow: TextOverflow.ellipsis)),
                  ])),
            const SizedBox(height: 7),
            Text('// SKILLS', style: TextStyle(
                fontFamily: 'monospace', fontSize: 5, color: _yellow,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            for (final s in MockCv.skills)
              Padding(padding: const EdgeInsets.only(bottom: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      Text(s.$1, style: TextStyle(fontFamily: 'monospace',
                          fontSize: 4.5, color: _white)),
                      Text('${(s.$2 * 100).round()}%', style: TextStyle(
                          fontFamily: 'monospace', fontSize: 4, color: _green)),
                    ]),
                    const SizedBox(height: 1.5),
                    Stack(children: [
                      _b(double.infinity, 2.5, _border, r: 1),
                      FractionallySizedBox(widthFactor: s.$2, child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_green, _blue]),
                              borderRadius: BorderRadius.circular(1)))),
                    ]),
                  ])),
            const SizedBox(height: 5),
            Text('// LANGS', style: TextStyle(fontFamily: 'monospace',
                fontSize: 5, color: _yellow, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            for (final l in MockCv.langs)
              Padding(padding: const EdgeInsets.only(bottom: 2),
                  child: Row(children: [
                    Text('> ', style: TextStyle(
                        fontFamily: 'monospace', fontSize: 5, color: _green)),
                    Flexible(child: Text(l.split(' ')[0], style: TextStyle(
                        fontFamily: 'monospace', fontSize: 4.5, color: _muted))),
                  ])),
          ]),
        ),
        // ── Main ────────────────────────────────────────────────────
        Expanded(child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // whoami card
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: _border, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r'$ whoami', style: TextStyle(
                    fontFamily: 'monospace', fontSize: 5, color: _green)),
                const SizedBox(height: 2),
                Text('Alexandra Chen', style: TextStyle(
                    fontFamily: 'monospace', fontSize: 9,
                    fontWeight: FontWeight.w700, color: _blue)),
                Text(MockCv.title, style: TextStyle(
                    fontFamily: 'monospace', fontSize: 5, color: _yellow)),
              ]),
            ),
            const SizedBox(height: 7),
            Text('// SUMMARY', style: TextStyle(fontFamily: 'monospace',
                fontSize: 5.5, color: _yellow, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _surface, borderRadius: BorderRadius.circular(4),
                  border: const Border(
                      left: BorderSide(color: _green, width: 2))),
              child: _lines(3, _muted.withOpacity(0.6), h: 2, gap: 2),
            ),
            const SizedBox(height: 7),
            Text('// EXPERIENCE', style: TextStyle(fontFamily: 'monospace',
                fontSize: 5.5, color: _yellow, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            for (final e in MockCv.exp)
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _border, width: 0.5)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(e.$2, style: TextStyle(fontFamily: 'monospace',
                        fontSize: 6, fontWeight: FontWeight.w700, color: _blue)),
                    Text(e.$3, style: TextStyle(fontFamily: 'monospace',
                        fontSize: 4.5, color: _muted)),
                  ]),
                  Text(e.$1, style: TextStyle(fontFamily: 'monospace',
                      fontSize: 5, color: _green)),
                  const SizedBox(height: 2),
                  _lines(2, _muted.withOpacity(0.4), h: 1.5, gap: 1.5),
                ]),
              ),
          ]),
        )),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// T05 — Luxury  (jet black bg, gold accents, cream text, centred header)
// ═════════════════════════════════════════════════════════════════════════════
class MiniLuxury extends StatelessWidget {
  const MiniLuxury({super.key});
  static const _black    = Color(0xFF0A0A0A);
  static const _charcoal = Color(0xFF1C1C1C);
  static const _gold     = Color(0xFFBFA46A);
  static const _goldL    = Color(0xFFD4B97A);
  static const _cream    = Color(0xFFF5F0E8);
  static const _muted    = Color(0xFF8A8272);

  Widget _gradBand() => Container(
      height: 2.5,
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
        Color(0xFF8A6B2E), Color(0xFFD4B97A),
        Color(0xFFBFA46A), Color(0xFFD4B97A), Color(0xFF8A6B2E),
      ])));

  Widget _gs(String t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        _b(8, 0.5, _gold), const SizedBox(width: 4),
        Text(t, style: const TextStyle(fontSize: 4.5, fontWeight: FontWeight.w600,
            color: _gold, letterSpacing: 2)),
      ]),
      _b(double.infinity, 0.3, _gold.withOpacity(0.2)),
      const SizedBox(height: 4),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _black,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _gradBand(),
        // ── Header ────────────────────────────────────────────────────
        Container(
          color: _charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 1.5),
                  color: _black),
              child: const Center(child: Text('AC', style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w300,
                  color: _gold, letterSpacing: 1.5))),
            ),
            const SizedBox(height: 5),
            Text('ALEXANDRA CHEN', style: const TextStyle(
                fontSize: 8, fontWeight: FontWeight.w300,
                color: _cream, letterSpacing: 3)),
            const SizedBox(height: 3),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _b(10, 0.5, _gold), const SizedBox(width: 5),
              Text(MockCv.title.toUpperCase(), style: const TextStyle(
                  fontSize: 4, color: _gold, letterSpacing: 1.5,
                  fontWeight: FontWeight.w500)),
              const SizedBox(width: 5), _b(10, 0.5, _gold),
            ]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(MockCv.email, style: const TextStyle(fontSize: 4.5, color: _muted)),
              const Text('   ·   ', style: TextStyle(color: _gold, fontSize: 4)),
              Text(MockCv.loc, style: const TextStyle(fontSize: 4.5, color: _muted)),
            ]),
          ]),
        ),
        _b(double.infinity, 0.3, _gold.withOpacity(0.25)),
        // ── Body ──────────────────────────────────────────────────────
        Expanded(child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Main column
            Expanded(flex: 6, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              _gs('EXECUTIVE SUMMARY'),
              _lines(3, _muted.withOpacity(0.5), h: 2, gap: 2),
              const SizedBox(height: 8),
              _gs('PROFESSIONAL EXPERIENCE'),
              for (final e in MockCv.exp) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.$1, style: const TextStyle(fontSize: 5.5,
                      fontWeight: FontWeight.w600, color: _cream)),
                  Text(e.$3, style: const TextStyle(fontSize: 4.5, color: _gold)),
                ]),
                Text(e.$2, style: const TextStyle(fontSize: 5, color: _goldL)),
                const SizedBox(height: 2),
                _lines(2, _muted.withOpacity(0.4), h: 1.5, gap: 1.5),
                const SizedBox(height: 5),
              ],
              _gs('EDUCATION'),
              for (final e in MockCv.edu) ...[
                Row(children: [
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                        border: Border.all(color: _gold.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(3)),
                    child: Center(child: Text('16', style: const TextStyle(
                        fontSize: 4.5, color: _gold, fontWeight: FontWeight.w600))),
                  ),
                  const SizedBox(width: 5),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.$1, style: const TextStyle(fontSize: 5.5,
                        fontWeight: FontWeight.w600, color: _cream)),
                    Text(e.$2, style: const TextStyle(fontSize: 4.5, color: _muted)),
                  ]),
                ]),
                const SizedBox(height: 5),
              ],
            ])),
            const SizedBox(width: 10),
            // Side column
            SizedBox(width: 56, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              _gs('EXPERTISE'),
              for (final s in MockCv.skills)
                Padding(padding: const EdgeInsets.only(bottom: 1),
                    child: _miniSkillBar(s.$2, _goldL, _charcoal)),
              const SizedBox(height: 6),
              _gs('LANGUAGES'),
              for (final l in MockCv.langs)
                Padding(padding: const EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      Container(width: 3, height: 3,
                          decoration: const BoxDecoration(
                              color: _gold, shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Flexible(child: Text(l.split(' ')[0], style: const TextStyle(
                          fontSize: 4.5, color: _muted))),
                    ])),
              const SizedBox(height: 6),
              _gs('CERTS'),
              for (final c in ['Google UX', 'IDF']) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      border: Border.all(color: _gold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(3)),
                  child: Text(c, style: const TextStyle(
                      fontSize: 4.5, color: _muted)),
                ),
              ],
            ])),
          ]),
        )),
        _gradBand(),
      ]),
    );
  }
}