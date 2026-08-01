// mini_previews_b.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/mini_previews_b.dart
//
// Templates 5–8: Luxury, Gradient, Editorial, Pastel
// FIXES: _goldSection Row wraps Text in Expanded; all spaceBetween rows use Expanded

import 'package:flutter/material.dart';

Widget _bar(double w, double h, Color c, {double r = 2}) =>
    Container(width: w, height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

Widget _textLine(double w, Color c, {double h = 3.0}) => _bar(w, h, c);

Widget _skillPct(double totalW, double pct, Color fill, Color bg, {double h = 2.5}) =>
    Stack(children: [_bar(totalW, h, bg, r: 1.5), _bar(totalW * pct, h, fill, r: 1.5)]);

Widget _dot(double r, Color c) =>
    Container(width: r * 2, height: r * 2,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));

// T05 – Luxury (jet black + warm gold)
class MiniPreview05Luxury extends StatelessWidget {
  const MiniPreview05Luxury({super.key});
  static const _black    = Color(0xFF0A0A0A);
  static const _charcoal = Color(0xFF1C1C1C);
  static const _gold     = Color(0xFFBFA46A);
  static const _goldL    = Color(0xFFD4B97A);
  static const _cream    = Color(0xFFF5F0E8);
  static const _muted    = Color(0xFF8A8272);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: _black, child: Column(children: [
          Container(height: 2.5, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xFF8A6B2E), Color(0xFFD4B97A), Color(0xFFBFA46A),
                Color(0xFFD4B97A), Color(0xFF8A6B2E)]))),
          Container(color: _charcoal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: _gold, width: 1.5), color: _black),
                child: const Center(child: Text('AC', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w300, color: Color(0xFFBFA46A), letterSpacing: 2)))),
              const SizedBox(height: 6),
              Text('ALEXANDRA CHEN', style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w300, color: _cream, letterSpacing: 4)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _bar(14, 0.5, _gold), const SizedBox(width: 6),
                Text('SENIOR PRODUCT DESIGNER', style: const TextStyle(
                    fontSize: 5, color: _gold, letterSpacing: 2, fontWeight: FontWeight.w500)),
                const SizedBox(width: 6), _bar(14, 0.5, _gold),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('alex.chen@email.com', style: const TextStyle(fontSize: 5, color: _muted)),
                Text('   ·   ', style: const TextStyle(color: _gold, fontSize: 6)),
                Text('+1 555 234 5678', style: const TextStyle(fontSize: 5, color: _muted)),
              ]),
            ])),
          Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 14),
              color: _gold.withOpacity(0.3)),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _goldSection('EXECUTIVE SUMMARY'), const SizedBox(height: 5),
                _textLine(150, _muted.withOpacity(0.5)), const SizedBox(height: 2.5),
                _textLine(130, _muted.withOpacity(0.45)), const SizedBox(height: 2.5),
                _textLine(145, _muted.withOpacity(0.4)), const SizedBox(height: 9),
                _goldSection('PROFESSIONAL EXPERIENCE'), const SizedBox(height: 5),
                ...[('Sr. Product Designer', 'Stripe', '2021–Present'),
                    ('Product Designer', 'Airbnb', '2018–2021'),
                    ('UX Designer', 'IDEO', '2016–2018')].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // FIXED: Expanded on title
                    Row(children: [
                      Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w600, color: _cream), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      Text(e.$3, style: const TextStyle(fontSize: 5, color: _gold)),
                    ]),
                    Text(e.$2, style: const TextStyle(fontSize: 6, color: _goldL)),
                    const SizedBox(height: 2.5),
                    _textLine(145, _muted.withOpacity(0.35)), const SizedBox(height: 2),
                    _textLine(118, _muted.withOpacity(0.3)),
                  ]),
                )),
                _goldSection('EDUCATION'), const SizedBox(height: 5),
                ...[('BFA Graphic Design', 'RISD', '2016'), ('Certificate – HCI', 'Stanford', '2019')].map((e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 26, height: 26,
                      decoration: BoxDecoration(border: Border.all(color: _gold.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(3)),
                      child: Center(child: Text(e.$3, style: const TextStyle(
                          fontSize: 6.5, color: _gold, fontWeight: FontWeight.w600)))),
                    const SizedBox(width: 7),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w600, color: _cream)),
                      Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted)),
                    ]),
                  ]))),
              ])),
              const SizedBox(width: 10),
              SizedBox(width: 62, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _goldSection('EXPERTISE'), const SizedBox(height: 5),
                ...[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Sketch', 0.80)].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: const TextStyle(fontSize: 5.5, color: _cream, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    _skillPct(60, s.$2, _goldL, const Color(0xFF1C1C1C)),
                  ]),
                )),
              ])),
            ]),
          )),
          Container(height: 2.5, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xFF8A6B2E), Color(0xFFD4B97A), Color(0xFFBFA46A),
                Color(0xFFD4B97A), Color(0xFF8A6B2E)]))),
        ])),
      ),
    );
  }

  // FIXED: Text wrapped in Expanded
  Widget _goldSection(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [_bar(8, 0.5, _gold), const SizedBox(width: 4),
      Expanded(child: Text(t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w600, color: _gold, letterSpacing: 1.8), overflow: TextOverflow.ellipsis))]),
    _bar(double.infinity, 0.3, _gold.withOpacity(0.2)),
  ]);
}

// T06 – Gradient Modern (teal→violet header + cards)
class MiniPreview06Gradient extends StatelessWidget {
  const MiniPreview06Gradient({super.key});
  static const _teal   = Color(0xFF0F7EA8);
  static const _purple = Color(0xFF7C3AED);
  static const _bg     = Color(0xFFF1F5F9);
  static const _ink    = Color(0xFF0F172A);
  static const _muted  = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: _bg, child: Column(children: [
          Container(padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            decoration: const BoxDecoration(gradient: LinearGradient(
                colors: [Color(0xFF0F7EA8), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8)],
                    color: Colors.white.withOpacity(0.18)),
                child: const Icon(Icons.person_rounded, color: Colors.white60, size: 24)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Alexandra Chen', style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                const SizedBox(height: 3),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3))),
                  child: Text('Senior Product Designer',
                      style: const TextStyle(fontSize: 5.5, color: Colors.white, fontWeight: FontWeight.w500))),
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.email_outlined, color: Colors.white60, size: 8), const SizedBox(width: 3),
                  Text('alex.chen@email.com', style: const TextStyle(color: Colors.white60, fontSize: 5.5)),
                ]),
              ])),
            ])),
          Expanded(child: Padding(padding: const EdgeInsets.all(8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 6, child: Column(children: [
                _card('Professional Summary', Icons.person_outline_rounded,
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _textLine(double.infinity, _muted.withOpacity(0.45)), const SizedBox(height: 2.5),
                    _textLine(150, _muted.withOpacity(0.4)), const SizedBox(height: 2.5),
                    _textLine(160, _muted.withOpacity(0.35)),
                  ])),
                const SizedBox(height: 6),
                _card('Work Experience', Icons.work_outline_rounded,
                  Column(children: <Widget>[
                    for (final e in <(String, String, String)>[
                      ('Stripe', 'Sr. Product Designer', '2021–Now'),
                      ('Airbnb', 'Product Designer', '2018–2021'),
                      ('IDEO', 'UX Designer', '2016–2018'),
                    ])
                      Padding(padding: const EdgeInsets.only(bottom: 5),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // FIXED
                          Row(children: [
                            Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            Text(e.$3, style: const TextStyle(fontSize: 5, color: _muted)),
                          ]),
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(colors: [_teal, _purple]).createShader(b),
                            child: Text(e.$2, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                          const SizedBox(height: 2),
                          _textLine(double.infinity, _muted.withOpacity(0.35)),
                        ])),
                  ])),
                const SizedBox(height: 6),
                _card('Education', Icons.school_outlined,
                  Column(children: <Widget>[
                    for (final e in <(String, String, String)>[
                      ('RISD', 'BFA Graphic Design', '2016'),
                      ('Stanford', 'Certificate – HCI', '2019'),
                    ])
                      Padding(padding: const EdgeInsets.only(bottom: 5),
                        child: Row(children: [
                          Container(width: 26, height: 26,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE)]),
                              borderRadius: BorderRadius.circular(7)),
                            child: Center(child: Text(e.$3, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _teal)))),
                          const SizedBox(width: 7),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.$2, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink)),
                            Text(e.$1, style: const TextStyle(fontSize: 5.5, color: _muted)),
                          ]),
                        ])),
                  ])),
              ])),
              const SizedBox(width: 6),
              SizedBox(width: 72, child: _card('Skills', Icons.star_outline_rounded,
                Column(children: <Widget>[
                  for (final s in <(String, double)>[
                    ('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Sketch', 0.80),
                  ])
                    Padding(padding: const EdgeInsets.only(bottom: 5),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // FIXED
                        Row(children: [
                          Expanded(child: Text(s.$1, style: const TextStyle(fontSize: 5.5, color: _ink, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 2),
                          Text('${(s.$2 * 100).round()}%', style: const TextStyle(fontSize: 4.5, color: _muted)),
                        ]),
                        const SizedBox(height: 2),
                        ClipRRect(borderRadius: BorderRadius.circular(3),
                          child: Container(height: 4, color: const Color(0xFFE2E8F0),
                            child: FractionallySizedBox(alignment: Alignment.centerLeft,
                              widthFactor: s.$2,
                              child: Container(decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [_teal, _purple])))))),
                      ])),
                ]),
              )),
            ]),
          )),
        ])),
      ),
    );
  }

  Widget _card(String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 9, color: _teal), const SizedBox(width: 4),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis))]),
      Container(margin: const EdgeInsets.symmetric(vertical: 3.5), height: 1,
          decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [_teal, _purple, Colors.transparent]))),
      child,
    ]),
  );
}

// T07 – Editorial (cream + red magazine)
class MiniPreview07Editorial extends StatelessWidget {
  const MiniPreview07Editorial({super.key});
  static const _paper = Color(0xFFFAF8F5);
  static const _ink   = Color(0xFF111111);
  static const _red   = Color(0xFFD0021B);
  static const _muted = Color(0xFF777777);
  static const _rule  = Color(0xFFDDDDDD);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: _paper, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _bar(double.infinity, 3, _red, r: 0),
          Padding(padding: const EdgeInsets.fromLTRB(14, 9, 14, 0), child:
            Row(crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ALEXANDRA', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                    color: _ink, height: 0.9, letterSpacing: -0.5)),
                Text('CHEN', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                    color: _ink, height: 0.9, letterSpacing: -0.5)),
                const SizedBox(height: 5),
                Row(children: [
                  _bar(12, 2, _red), const SizedBox(width: 5),
                  Text('SR. PRODUCT DESIGNER', style: const TextStyle(
                      fontSize: 5, color: _red, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ]),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('alex.chen@email.com', style: const TextStyle(fontSize: 5, color: _muted)),
                Text('+1 555 234 5678',     style: const TextStyle(fontSize: 5, color: _muted)),
                Text('San Francisco, CA',   style: const TextStyle(fontSize: 5, color: _muted)),
                Text('alexchen.design',     style: const TextStyle(fontSize: 5, color: _muted)),
              ]),
            ])),
          Padding(padding: const EdgeInsets.fromLTRB(14, 6, 14, 0), child: Column(children: [
            _bar(double.infinity, 1.5, _ink, r: 0), const SizedBox(height: 2),
            _bar(double.infinity, 0.3, _ink, r: 0),
          ])),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(14, 7, 14, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 72, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sH('ABOUT'), const SizedBox(height: 4),
                _textLine(64, _muted.withOpacity(0.5)), const SizedBox(height: 2.5),
                _textLine(55, _muted.withOpacity(0.45)), const SizedBox(height: 2.5),
                _textLine(60, _muted.withOpacity(0.4)), const SizedBox(height: 8),
                _sH('SKILLS'), const SizedBox(height: 4),
                ...[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Motion', 0.70)].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: const TextStyle(fontSize: 5.5, color: _ink, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 1.5),
                    Stack(children: [_bar(62, 2, const Color(0xFFE5E5E5)), _bar(62 * s.$2, 2, _red)]),
                  ]))),
                const SizedBox(height: 6),
                _sH('EDUCATION'), const SizedBox(height: 4),
                ...[('BFA Graphic Design', 'RISD', '2016'), ('Certificate – HCI', 'Stanford', '2019')].map((e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
                    Text('${e.$3}  ', style: const TextStyle(fontSize: 5, color: _red, fontWeight: FontWeight.w700)),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w700, color: _ink)),
                      Text(e.$2, style: const TextStyle(fontSize: 5, color: _muted)),
                    ])),
                  ]))),
              ])),
              Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 0.5, color: _rule),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sH('EXPERIENCE'), const SizedBox(height: 5),
                ...[('Sr. Product Designer', 'Stripe', '2021–Present'),
                    ('Product Designer', 'Airbnb', '2018–2021'),
                    ('UX Designer', 'IDEO', '2016–2018')].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.$1, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800,
                            color: _ink, height: 1.1)),
                        Text(e.$2, style: const TextStyle(fontSize: 6, color: _red, fontWeight: FontWeight.w600)),
                      ])),
                      Container(margin: const EdgeInsets.only(top: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: _rule), borderRadius: BorderRadius.circular(1.5)),
                        child: Text(e.$3, style: const TextStyle(fontSize: 4.5, color: _muted))),
                    ]),
                    const SizedBox(height: 3),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('—  ', style: const TextStyle(color: _red, fontSize: 7, fontWeight: FontWeight.w700)),
                      Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.4))),
                    ]),
                    const SizedBox(height: 2),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('—  ', style: const TextStyle(color: _red, fontSize: 7, fontWeight: FontWeight.w700)),
                      Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.35))),
                    ]),
                  ]),
                )),
              ])),
            ]),
          )),
        ])),
      ),
    );
  }
  Widget _sH(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: _ink, letterSpacing: 2)),
    _bar(double.infinity, 0.5, _rule, r: 0),
  ]);
}

// T08 – Pastel Soft (lavender sidebar + rounded cards)
class MiniPreview08Pastel extends StatelessWidget {
  const MiniPreview08Pastel({super.key});
  static const _lavender = Color(0xFFEDE7F6);
  static const _lavD     = Color(0xFF7C5CBF);
  static const _lavM     = Color(0xFFB39DDB);
  static const _peach    = Color(0xFFE8845D);
  static const _ink      = Color(0xFF2D2D3A);
  static const _muted    = Color(0xFF7B7B8F);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 80, color: _lavender,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(width: 46, height: 46,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: _lavM.withOpacity(0.3), border: Border.all(color: _lavD, width: 1.5)),
                child: const Icon(Icons.person_rounded, color: _lavD, size: 22)),
              const SizedBox(height: 6),
              Text('Alexandra Chen', textAlign: TextAlign.center, style: const TextStyle(
                  fontSize: 6.5, fontWeight: FontWeight.w800, color: _ink, height: 1.3)),
              const SizedBox(height: 3),
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: _lavD.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text('Product Designer', textAlign: TextAlign.center, style: const TextStyle(
                    fontSize: 4.5, color: _lavD, fontWeight: FontWeight.w600))),
              const SizedBox(height: 9),
              _sideS('CONTACT'), const SizedBox(height: 5),
              ...[
                (Icons.email_outlined,       'alex.chen@email.com'),
                (Icons.phone_outlined,       '+1 555 234 5678'),
                (Icons.location_on_outlined, 'San Francisco, CA'),
                (Icons.language_outlined,    'alexchen.design'),
              ].map((c) => Padding(padding: const EdgeInsets.only(bottom: 4.5),
                child: Row(children: [
                  Container(width: 16, height: 16,
                    decoration: BoxDecoration(color: _lavD.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                    child: Icon(c.$1, size: 8, color: _lavD)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(c.$2, style: const TextStyle(fontSize: 4.5, color: _muted),
                      overflow: TextOverflow.ellipsis)),
                ]))),
              const SizedBox(height: 8),
              _sideS('SKILLS'), const SizedBox(height: 5),
              Wrap(spacing: 3, runSpacing: 3, alignment: WrapAlignment.center,
                children: ['Figma', 'Design', 'UX', 'Proto.', 'Sketch', 'Motion'].map((s) =>
                  Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _lavM.withOpacity(0.5))),
                    child: Text(s, style: const TextStyle(fontSize: 4.5, color: _ink, fontWeight: FontWeight.w500)))).toList()),
              const SizedBox(height: 8),
              _sideS('LANGUAGES'), const SizedBox(height: 4),
              ...['English (Native)', 'Mandarin (Fluent)', 'French (Basic)'].map((l) =>
                  Padding(padding: const EdgeInsets.only(bottom: 3.5),
                      child: Text(l, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 4.5, color: _muted, height: 1.3)))),
            ])),
          Expanded(child: Container(color: const Color(0xFFFAFAFC),
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _mainS('About Me', _peach), const SizedBox(height: 5),
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _peach.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  _textLine(double.infinity, _muted.withOpacity(0.45)), const SizedBox(height: 2.5),
                  _textLine(150, _muted.withOpacity(0.4)), const SizedBox(height: 2.5),
                  _textLine(160, _muted.withOpacity(0.35)),
                ])),
              const SizedBox(height: 8),
              _mainS('Experience', _lavD), const SizedBox(height: 5),
              ...[('Sr. Product Designer', 'Stripe', '2021–Now'),
                  ('Product Designer', 'Airbnb', '2018–2021'),
                  ('UX Designer', 'IDEO', '2016–2018')].map((e) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: _lavD.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // FIXED
                  Row(children: [
                    Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(color: _lavender, borderRadius: BorderRadius.circular(10)),
                      child: Text(e.$3, style: const TextStyle(fontSize: 4.5, color: _lavD))),
                  ]),
                  Text(e.$2, style: const TextStyle(fontSize: 6, color: _peach, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  _textLine(double.infinity, _muted.withOpacity(0.35)), const SizedBox(height: 2),
                  _textLine(120, _muted.withOpacity(0.3)),
                ]),
              )),
              _mainS('Education', _lavD), const SizedBox(height: 5),
              ...[('BFA Graphic Design', 'RISD', '2016'), ('Certificate – HCI', 'Stanford', '2019')].map((e) =>
                Container(margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: _lavD.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    Container(width: 28, height: 28,
                      decoration: BoxDecoration(color: _lavender, borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(e.$3, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _lavD)))),
                    const SizedBox(width: 6),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink)),
                      Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted)),
                    ]),
                  ]))),
            ]))),
        ]),
      ),
    );
  }
  Widget _sideS(String t) => Column(children: [
    Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _lavD, letterSpacing: 1.5)),
    _bar(double.infinity, 1, _lavM.withOpacity(0.4), r: 0),
  ]);
  Widget _mainS(String t, Color c) => Row(children: [
    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(t, style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: c))),
    const SizedBox(width: 6),
    Expanded(child: _bar(double.infinity, 0.8, c.withOpacity(0.15))),
  ]);
}