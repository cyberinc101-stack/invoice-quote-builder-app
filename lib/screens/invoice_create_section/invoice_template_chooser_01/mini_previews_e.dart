// mini_previews_e.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/mini_previews_e.dart
//
// Templates 17–20: Canfield B&W, Collins Classic, Tony Dark Orange, Fashion

import 'package:flutter/material.dart';
import 'dart:math' as math;

Widget _bar(double w, double h, Color c, {double r = 2}) =>
    Container(width: w, height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

Widget _textLine(double w, Color c, {double h = 3.0}) => _bar(w, h, c);

Widget _skillPct(double totalW, double pct, Color fill, Color bg, {double h = 2.5}) =>
    Stack(children: [_bar(totalW, h, bg), _bar(totalW * pct, h, fill)]);

Widget _dot(double r, Color c) =>
    Container(width: r * 2, height: r * 2,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));

// ─────────────────────────────────────────────────────────────────────────────
// T17 – Canfield Stark Black & White
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview17Canfield extends StatelessWidget {
  const MiniPreview17Canfield({super.key});
  static const _black = Color(0xFF0A0A0A);
  static const _dark  = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF666666);
  static const _rule  = Color(0xFFE8E8E8);
  static const _bg    = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: _bg,
          child: Column(children: [
            Container(color: _black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Container(width: 36, height: 36, color: const Color(0xFF333333),
                  child: const Icon(Icons.person_rounded, color: Colors.white38, size: 18)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ALEXANDRA CHEN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 1.5)),
                  const SizedBox(height: 3),
                  const Text('SENIOR PRODUCT DESIGNER', style: TextStyle(fontSize: 4.5,
                      color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.w500)),
                ])),
              ])),
            Container(color: _dark,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(children: [
                for (final t in ['alex.chen@email.com', '+1 555 234 5678', 'San Francisco'])
                  Expanded(child: Row(children: [
                    const Icon(Icons.circle, size: 4, color: Colors.white38), const SizedBox(width: 3),
                    Expanded(child: Text(t, style: const TextStyle(fontSize: 4.5, color: Colors.white54),
                        overflow: TextOverflow.ellipsis)),
                  ])),
              ])),
            Expanded(child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 7, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sh('PROFILE'), const SizedBox(height: 4),
                  _textLine(double.infinity, _muted.withOpacity(0.4)), const SizedBox(height: 2),
                  _textLine(150, _muted.withOpacity(0.35)), const SizedBox(height: 8),
                  _sh('WORK EXPERIENCE'), const SizedBox(height: 5),
                  for (final e in <(String, String, String)>[
                    ('Sr. Product Designer', 'Stripe', '2021–Now'),
                    ('Product Designer', 'Airbnb', '2018–2021'),
                    ('UX Designer', 'IDEO', '2016–2018')])
                    Padding(padding: const EdgeInsets.only(bottom: 7),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5,
                              fontWeight: FontWeight.w900, color: _black), overflow: TextOverflow.ellipsis)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            color: _black,
                            child: Text(e.$3, style: const TextStyle(color: Colors.white,
                                fontSize: 4.5, fontWeight: FontWeight.w700))),
                        ]),
                        Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted,
                            fontStyle: FontStyle.italic)),
                        const SizedBox(height: 2),
                        _textLine(double.infinity, _muted.withOpacity(0.35)),
                        const SizedBox(height: 1.5),
                        _textLine(140, _muted.withOpacity(0.3)),
                      ])),
                  _sh('EDUCATION'), const SizedBox(height: 5),
                  for (final e in <(String, String, String)>[
                    ('BFA Graphic Design', 'RISD', '2016'),
                    ('Certificate – HCI', 'Stanford', '2019')])
                    Padding(padding: const EdgeInsets.only(bottom: 5),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w900,
                              color: _black), overflow: TextOverflow.ellipsis),
                          Text(e.$2, style: const TextStyle(fontSize: 5, color: _muted,
                              fontStyle: FontStyle.italic)),
                        ])),
                        Text(e.$3, style: const TextStyle(fontSize: 5, color: _muted)),
                      ])),
                ])),
                const SizedBox(width: 8),
                SizedBox(width: 58, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sh('SKILLS'), const SizedBox(height: 5),
                  for (final s in <(String, double)>[
                    ('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Sketch', 0.80)])
                    Padding(padding: const EdgeInsets.only(bottom: 5),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.$1, style: const TextStyle(fontSize: 5.5, color: _black,
                            fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        _skillPct(double.infinity, s.$2, _black, _rule, h: 2.5),
                      ])),
                  const SizedBox(height: 5),
                  _sh('LANGUAGES'), const SizedBox(height: 4),
                  for (final l in ['English', 'Mandarin', 'French'])
                    Padding(padding: const EdgeInsets.only(bottom: 3.5), child: Row(children: [
                      const Icon(Icons.translate, size: 7, color: _muted), const SizedBox(width: 3),
                      Expanded(child: Text(l, style: const TextStyle(fontSize: 5, color: _muted),
                          overflow: TextOverflow.ellipsis)),
                    ])),
                ])),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _sh(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w900,
        color: _black, letterSpacing: 2)),
    const SizedBox(height: 2),
    Container(width: 16, height: 1.5, color: _black),
    const SizedBox(height: 2),
    Container(height: 0.4, color: _rule),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// T18 – Collins Classic ATS
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview18Collins extends StatelessWidget {
  const MiniPreview18Collins({super.key});
  static const _ink   = Color(0xFF111111);
  static const _muted = Color(0xFF555555);
  static const _light = Color(0xFF888888);
  static const _rule  = Color(0xFFCCCCCC);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Column(children: [
              const Text('ALEXANDRA CHEN', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w900, color: _ink, letterSpacing: 3)),
              const SizedBox(height: 2),
              const Text('Senior Product Designer', style: TextStyle(fontSize: 5.5,
                  color: _muted, letterSpacing: 1)),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final t in ['alex.chen@email.com', '+1 555 234 5678', 'San Francisco'])
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(t, style: const TextStyle(fontSize: 4.5, color: _light))),
              ]),
            ])),
            const SizedBox(height: 7),
            Container(height: 1.5, color: _ink), const SizedBox(height: 7),
            _sec('PROFESSIONAL SUMMARY'), const SizedBox(height: 5),
            _textLine(double.infinity, _muted.withOpacity(0.4)), const SizedBox(height: 2),
            _textLine(220, _muted.withOpacity(0.35)), const SizedBox(height: 8),
            _sec('WORK EXPERIENCE'), const SizedBox(height: 5),
            for (final e in <(String, String, String)>[
              ('Sr. Product Designer', 'Stripe', '2021–Now'),
              ('Product Designer', 'Airbnb', '2018–2021'),
              ('UX Designer', 'IDEO', '2016–2018')])
              Padding(padding: const EdgeInsets.only(bottom: 7),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5,
                        fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis)),
                    Text(e.$3, style: const TextStyle(fontSize: 5, color: _light)),
                  ]),
                  Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted,
                      fontStyle: FontStyle.italic)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Text('• ', style: TextStyle(color: _muted, fontSize: 7)),
                    Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.35))),
                  ]),
                ])),
            _sec('EDUCATION'), const SizedBox(height: 5),
            for (final e in <(String, String, String)>[
              ('BFA Graphic Design', 'RISD', '2016'),
              ('Certificate – HCI', 'Stanford', '2019')])
              Padding(padding: const EdgeInsets.only(bottom: 5),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700,
                        color: _ink), overflow: TextOverflow.ellipsis),
                    Text(e.$2, style: const TextStyle(fontSize: 5, color: _muted)),
                  ])),
                  Text(e.$3, style: const TextStyle(fontSize: 5, color: _light)),
                ])),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sec('SKILLS'), const SizedBox(height: 4),
                for (final s in ['Figma', 'Design Sys.', 'Research', 'Prototyping'])
                  Padding(padding: const EdgeInsets.only(bottom: 2.5),
                    child: Text(s, style: const TextStyle(fontSize: 5.5, color: _muted),
                        overflow: TextOverflow.ellipsis)),
              ])),
              const SizedBox(width: 6),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sec('LANGUAGES'), const SizedBox(height: 4),
                for (final l in ['English (Native)', 'Mandarin', 'French'])
                  Padding(padding: const EdgeInsets.only(bottom: 2.5),
                    child: Text(l, style: const TextStyle(fontSize: 5.5, color: _muted),
                        overflow: TextOverflow.ellipsis)),
              ])),
              const SizedBox(width: 6),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sec('CERTIFICATIONS'), const SizedBox(height: 4),
                for (final c in ['Google UX Design', 'IDF', 'NN/g UX'])
                  Padding(padding: const EdgeInsets.only(bottom: 2.5),
                    child: Text(c, style: const TextStyle(fontSize: 5.5, color: _muted),
                        overflow: TextOverflow.ellipsis)),
              ])),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _sec(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w900,
        color: _ink, letterSpacing: 2)),
    const SizedBox(height: 2),
    Container(height: 0.6, color: _rule),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// T19 – Tony Dark Orange Infographic
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview19Tony extends StatelessWidget {
  const MiniPreview19Tony({super.key});
  static const _bg      = Color(0xFF1E1E1E);
  static const _panel   = Color(0xFF272727);
  static const _orange  = Color(0xFFFF6D00);
  static const _muted   = Color(0xFFAAAAAA);
  static const _divider = Color(0xFF383838);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: _bg,
          child: Column(children: [
            Container(color: _panel,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children: [
                Stack(children: [
                  Container(width: 36, height: 36, color: const Color(0xFF333333),
                    child: const Icon(Icons.person_rounded, color: Colors.white38, size: 17)),
                  Positioned(bottom: 0, left: 0,
                    child: Container(width: 10, height: 2.5, color: _orange)),
                ]),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Alexandra Chen', style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Container(width: 10, height: 1.5, color: _orange),
                    const SizedBox(width: 4),
                    const Text('Senior Product Designer', style: TextStyle(color: _orange,
                        fontSize: 5.5, fontWeight: FontWeight.w600)),
                  ]),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('alex.chen@email.com', style: TextStyle(color: Colors.white60, fontSize: 4.5)),
                  const SizedBox(height: 1.5),
                  const Text('San Francisco, CA', style: TextStyle(color: Colors.white60, fontSize: 4.5)),
                ]),
              ])),
            Expanded(child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 70, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sh('PRO SKILLS', _orange), const SizedBox(height: 6),
                  for (final s in <(String, double)>[
                    ('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Sketch', 0.80)])
                    Padding(padding: const EdgeInsets.only(bottom: 6),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(s.$1, style: const TextStyle(color: _muted, fontSize: 5.5),
                              overflow: TextOverflow.ellipsis),
                          Text('${(s.$2 * 100).round()}%',
                              style: const TextStyle(color: _orange, fontSize: 5)),
                        ]),
                        const SizedBox(height: 2.5),
                        Stack(children: [
                          Container(height: 4, decoration: BoxDecoration(
                              color: _divider, borderRadius: BorderRadius.circular(2))),
                          FractionallySizedBox(widthFactor: s.$2, child: Container(height: 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFFFF9E40), Color(0xFFFF6D00)]),
                              borderRadius: BorderRadius.circular(2),
                            ))),
                        ]),
                      ])),
                  const SizedBox(height: 6),
                  _sh('LANGUAGES', _muted), const SizedBox(height: 5),
                  for (final l in ['English', 'Mandarin', 'French'])
                    Padding(padding: const EdgeInsets.only(bottom: 3.5), child: Row(children: [
                      _dot(3, _orange), const SizedBox(width: 4),
                      Expanded(child: Text(l, style: const TextStyle(color: _muted, fontSize: 5),
                          overflow: TextOverflow.ellipsis)),
                    ])),
                ])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sh('ABOUT ME', _orange), const SizedBox(height: 5),
                  _textLine(double.infinity, _muted.withOpacity(0.4)), const SizedBox(height: 2),
                  _textLine(130, _muted.withOpacity(0.35)), const SizedBox(height: 7),
                  _sh('EDUCATION', _orange), const SizedBox(height: 5),
                  for (final e in <(String, String, String)>[
                    ('BFA Graphic Design', 'RISD', '2016'),
                    ('Certificate – HCI', 'Stanford', '2019')])
                    Padding(padding: const EdgeInsets.only(bottom: 5), child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: _panel,
                          borderRadius: BorderRadius.circular(3),
                          border: const Border(left: BorderSide(color: _orange, width: 2))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.$1, style: const TextStyle(color: Colors.white, fontSize: 5.5,
                              fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                          Text(e.$2, style: const TextStyle(color: _muted, fontSize: 5)),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: _orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2)),
                          child: Text(e.$3, style: const TextStyle(color: _orange, fontSize: 5,
                              fontWeight: FontWeight.w700))),
                      ]),
                    )),
                  _sh('EXPERIENCE', _orange), const SizedBox(height: 5),
                  for (final e in <(String, String, String)>[
                    ('Sr. Product Designer', 'Stripe', '2021–Now'),
                    ('Product Designer', 'Airbnb', '2018–2021'),
                    ('UX Designer', 'IDEO', '2016–2018')])
                    Padding(padding: const EdgeInsets.only(bottom: 5),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(e.$1, style: const TextStyle(color: Colors.white,
                              fontSize: 6, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: _orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(2)),
                            child: Text(e.$3, style: const TextStyle(color: _orange, fontSize: 5,
                                fontWeight: FontWeight.w700))),
                        ]),
                        Text(e.$2, style: const TextStyle(color: _orange, fontSize: 5.5)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Text(' ·  ', style: TextStyle(color: _orange, fontSize: 5)),
                          Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.35))),
                        ]),
                      ])),
                ])),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _sh(String t, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 2, height: 10, color: c), const SizedBox(width: 4),
      Text(t, style: TextStyle(color: c, fontSize: 5.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
    ]),
    const SizedBox(height: 2),
    Container(height: 0.4, color: _divider),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// T20 – Fashion (technical drawing aesthetic — cobalt on white grid)
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview20Fashion extends StatelessWidget {
  const MiniPreview20Fashion({super.key});
  static const _cobalt  = Color(0xFF1A3A6B);
  static const _cobaltM = Color(0xFF2555A0);
  static const _cobaltL = Color(0xFF4A7FD4);
  static const _grid    = Color(0xFFDDE6F4);
  static const _rule    = Color(0xFFBDD0EA);
  static const _ink     = Color(0xFF0D2040);
  static const _muted   = Color(0xFF5C7499);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Stack(children: [
          Container(color: Colors.white),
          Positioned.fill(child: CustomPaint(painter: _MiniGridPainter())),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              color: _cobalt,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Stack(children: [
                  Container(width: 40, height: 40, color: _cobaltM,
                    child: const Icon(Icons.person_rounded, color: Colors.white24, size: 20)),
                  Positioned(top: 0, left: 0, child: _miniCorner()),
                  Positioned(top: 0, right: 0,
                    child: Transform.scale(scaleX: -1, child: _miniCorner())),
                  Positioned(bottom: 0, left: 0,
                    child: Transform.scale(scaleY: -1, child: _miniCorner())),
                  Positioned(bottom: 0, right: 0,
                    child: Transform.scale(scaleX: -1, scaleY: -1, child: _miniCorner())),
                ]),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('// IDENTITY', style: TextStyle(
                      fontFamily: 'monospace', fontSize: 4.5, color: _cobaltL)),
                  const SizedBox(height: 2),
                  const Text('Alexandra Chen', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white,
                      fontFamily: 'monospace', height: 1.1)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(width: 14, height: 1.5, color: _cobaltL),
                    const SizedBox(width: 4),
                    const Text('PRODUCT DESIGNER', style: TextStyle(
                        fontSize: 4.5, color: _cobaltL, fontFamily: 'monospace', letterSpacing: 1)),
                  ]),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('REF: AC-24', style: TextStyle(
                      fontFamily: 'monospace', fontSize: 4, color: _cobaltL)),
                  const SizedBox(height: 2),
                  const Text('REV: 08', style: TextStyle(
                      fontFamily: 'monospace', fontSize: 4, color: _cobaltL)),
                ]),
              ]),
            ),
            Container(height: 14, color: _grid,
              child: Row(children: [
                const SizedBox(width: 6),
                for (final item in [
                  ('EXP', '8+ YRS'), ('STATUS', 'OPEN'), ('SPEC', 'UX/UI'),
                ]) ...[
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(children: [
                      Text('${item.$1}: ', style: const TextStyle(
                          fontSize: 4, color: _muted, fontFamily: 'monospace')),
                      Text(item.$2, style: const TextStyle(
                          fontSize: 4, color: _cobalt, fontFamily: 'monospace',
                          fontWeight: FontWeight.w800)),
                    ])),
                  Container(width: 0.5, height: 14, color: _rule),
                ],
              ])),
            Expanded(child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _bpSection('SUMMARY'), const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.white, border: Border.all(color: _rule)),
                      child: Column(children: [
                        _textLine(double.infinity, _muted.withOpacity(0.45)),
                        const SizedBox(height: 2),
                        _textLine(130, _muted.withOpacity(0.4)),
                        const SizedBox(height: 2),
                        _textLine(150, _muted.withOpacity(0.35)),
                      ])),
                    const SizedBox(height: 6),
                    _bpSection('EXPERIENCE'), const SizedBox(height: 4),
                    for (final e in <(String, String, String)>[
                      ('Sr. Product Designer', 'Stripe', '2021–Now'),
                      ('Product Designer', 'Airbnb', '2018–2021'),
                      ('UX Designer', 'IDEO', '2016–2018')])
                      Padding(padding: const EdgeInsets.only(bottom: 4),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Column(children: [
                            Container(width: 5, height: 5, color: _cobalt),
                            Container(width: 1, height: 22, color: _rule),
                          ]),
                          const SizedBox(width: 5),
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: Colors.white, border: Border.all(color: _rule)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6,
                                    fontWeight: FontWeight.w700, color: _ink),
                                    overflow: TextOverflow.ellipsis)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: _cobalt), color: _grid),
                                  child: Text(e.$3, style: const TextStyle(fontSize: 4, color: _cobalt,
                                      fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                                ),
                              ]),
                              const SizedBox(height: 1.5),
                              Row(children: [
                                Container(width: 6, height: 1, color: _cobaltL),
                                const SizedBox(width: 3),
                                Text(e.$2, style: const TextStyle(fontSize: 5.5,
                                    color: _cobaltM, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 2),
                              _textLine(double.infinity, _muted.withOpacity(0.35)),
                            ]),
                          )),
                        ])),
                    _bpSection('EDUCATION'), const SizedBox(height: 3),
                    for (final e in <(String, String, String)>[
                      ('BFA Graphic Design', 'RISD', '2016'),
                      ('Certificate – HCI', 'Stanford', '2019')])
                      Padding(padding: const EdgeInsets.only(bottom: 3), child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: const BorderSide(color: _cobalt, width: 2.5),
                            top: BorderSide(color: _rule),
                            right: BorderSide(color: _rule),
                            bottom: BorderSide(color: _rule),
                          ),
                        ),
                        child: Row(children: [
                          Container(width: 20, height: 20,
                            decoration: BoxDecoration(
                                border: Border.all(color: _cobalt), color: _grid),
                            child: Center(child: Text(e.$3, style: const TextStyle(fontSize: 5.5,
                                fontWeight: FontWeight.w900, color: _cobalt,
                                fontFamily: 'monospace')))),
                          const SizedBox(width: 5),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(e.$1, style: const TextStyle(fontSize: 5.5,
                                fontWeight: FontWeight.w700, color: _ink),
                                overflow: TextOverflow.ellipsis),
                            Text(e.$2, style: const TextStyle(fontSize: 4.5, color: _muted)),
                          ])),
                        ]),
                      )),
                  ])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(children: [
                      Text('┬', style: const TextStyle(fontSize: 6, color: _rule)),
                      Container(width: 0.5, height: 200, color: _rule),
                      Text('┴', style: const TextStyle(fontSize: 6, color: _rule)),
                    ]),
                  ),
                  SizedBox(width: 62, child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _bpSection('SKILLS'), const SizedBox(height: 5),
                    for (final s in <(String, double)>[
                      ('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                      ('Prototyping', 0.88), ('Sketch', 0.80),
                    ])
                      Padding(padding: const EdgeInsets.only(bottom: 6),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text(s.$1, style: const TextStyle(fontSize: 5,
                                color: _ink, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis)),
                            Text('${(s.$2 * 100).round()}%', style: const TextStyle(fontSize: 4.5,
                                color: _cobaltL, fontFamily: 'monospace',
                                fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: SizedBox(
                              height: 3,
                              child: Row(children: [
                                Flexible(
                                  flex: (s.$2 * 100).round(),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(colors: [_cobaltL, _cobalt]),
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                Flexible(
                                  flex: 100 - (s.$2 * 100).round(),
                                  child: const ColoredBox(
                                      color: _grid, child: SizedBox.expand()),
                                ),
                              ]),
                            ),
                          ),
                        ])),
                    const SizedBox(height: 5),
                    _bpSection('LANGUAGES'), const SizedBox(height: 4),
                    for (final l in ['English', 'Mandarin', 'French'])
                      Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
                        Container(width: 5, height: 5, color: _cobalt),
                        const SizedBox(width: 4),
                        Expanded(child: Text(l, style: const TextStyle(fontSize: 5,
                            color: _muted, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis)),
                      ])),
                  ])),
                ]),
              ),
            )),
            Container(height: 12, color: _cobalt,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('CURRICULUM VITAE', style: TextStyle(
                    fontSize: 4, color: _cobaltL, fontFamily: 'monospace')),
                const Text('SHEET 1 OF 1', style: TextStyle(
                    fontSize: 4, color: _cobaltL, fontFamily: 'monospace')),
              ])),
          ]),
        ]),
      ),
    );
  }

  static Widget _miniCorner() => SizedBox(
    width: 8, height: 8,
    child: CustomPaint(painter: _MiniCornerPainter()),
  );

  static Widget _bpSection(String t) => Row(children: [
    Container(width: 8, height: 8, color: _cobalt,
      child: Center(child: Text(t.substring(0, 1), style: const TextStyle(
          fontSize: 4.5, fontWeight: FontWeight.w900,
          color: Colors.white, fontFamily: 'monospace')))),
    const SizedBox(width: 4),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800,
          color: _cobalt, letterSpacing: 2, fontFamily: 'monospace')),
      Container(height: 0.5, color: _rule),
    ])),
  ]);
}

class _MiniGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDE6F4)
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    const spacing = 12.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _MiniCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A7FD4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.7, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height * 0.7), paint);
  }
  @override
  bool shouldRepaint(_) => false;
}