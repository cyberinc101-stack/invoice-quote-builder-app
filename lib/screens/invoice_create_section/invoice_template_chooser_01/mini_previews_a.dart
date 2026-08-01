// mini_previews_a.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/mini_previews_a.dart
//
// Templates contained in this file:
//   T01   – Executive          (MiniPreview01Executive)
//   T01.5 – Archivist          (MiniPreview01p5Archivist)
//   T02   – Nordic             (MiniPreview02Nordic)
//   T02.5 – Diplomat           (MiniPreview02p5Diplomat)
//   T03   – Vibrant            (MiniPreview03Vibrant)
//   T03.5 – Scholar            (MiniPreview03p5Scholar)
//   T04   – Tech Dark          (MiniPreview04TechDark)
//   T04.5 – Vanguard           (MiniPreview04p5Vanguard)

import 'package:flutter/material.dart';

Widget _bar(double w, double h, Color c, {double r = 2}) =>
    Container(width: w, height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

Widget _textLine(double w, Color c, {double h = 3.0}) => _bar(w, h, c);

Widget _skillPct(double totalW, double pct, Color fill, Color bg, {double h = 2.5}) =>
    Stack(children: [_bar(totalW, h, bg), _bar(totalW * pct, h, fill)]);

Widget _dot(double r, Color c) =>
    Container(width: r * 2, height: r * 2,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));

Widget _avatarBox(double size, Color bg, Color iconColor,
    {Color? borderColor, IconData icon = Icons.person_rounded}) =>
    Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg, shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5) : null,
      ),
      child: Icon(icon, size: size * 0.45, color: iconColor),
    );

// ─────────────────────────────────────────────────────────────────────────────
// T01 – Executive (navy sidebar + gold)
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview01Executive extends StatelessWidget {
  const MiniPreview01Executive({super.key});
  static const _navy   = Color(0xFF0D1B2A);
  static const _navyL  = Color(0xFF1B2E45);
  static const _gold   = Color(0xFFC9A84C);
  static const _bg     = Color(0xFFF8F9FC);
  static const _ink    = Color(0xFF1A1A2E);
  static const _grey   = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 80, color: _navy,
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: _avatarBox(34, _navyL, Colors.white38, borderColor: _gold)),
              const SizedBox(height: 8),
              _goldLabel('CONTACT'), const SizedBox(height: 5),
              ...[
                (Icons.email_outlined,       'alex.chen@email.com'),
                (Icons.phone_outlined,       '+1 555 234 5678'),
                (Icons.location_on_outlined, 'San Francisco, CA'),
                (Icons.language_outlined,    'alexchen.design'),
              ].map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(e.$1, color: _gold, size: 7), const SizedBox(width: 3),
                  Expanded(child: Text(e.$2,
                      style: const TextStyle(color: Colors.white60, fontSize: 6, height: 1.3),
                      overflow: TextOverflow.ellipsis)),
                ]),
              )),
              const SizedBox(height: 8),
              _goldLabel('SKILLS'), const SizedBox(height: 5),
              ...[('Figma', 0.95), ('Design Sys.', 0.90), ('User Research', 0.85),
                  ('Prototyping', 0.88), ('Sketch', 0.80), ('Motion', 0.70)].map((s) =>
                Padding(padding: const EdgeInsets.only(bottom: 5), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.$1, style: const TextStyle(color: Colors.white60, fontSize: 6, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  _skillPct(62, s.$2, _gold, Colors.white12),
                ]))),
              const SizedBox(height: 7),
              _goldLabel('LANGUAGES'), const SizedBox(height: 4),
              ...['English (Native)', 'Mandarin (Fluent)', 'French (Basic)'].map((l) =>
                  Padding(padding: const EdgeInsets.only(bottom: 3),
                      child: Text(l, style: const TextStyle(color: Colors.white54, fontSize: 5.5)))),
            ])),
          Expanded(child: Container(color: _bg,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ALEXANDRA CHEN', style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, color: _ink, letterSpacing: 1.5)),
              const SizedBox(height: 3), _bar(22, 2.5, _gold), const SizedBox(height: 3),
              Text('Senior Product Designer', style: TextStyle(fontSize: 6, color: _grey, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              _section('PROFILE'), const SizedBox(height: 4),
              _textLine(155, _grey.withOpacity(0.55)), const SizedBox(height: 2.5),
              _textLine(135, _grey.withOpacity(0.45)), const SizedBox(height: 2.5),
              _textLine(150, _grey.withOpacity(0.45)), const SizedBox(height: 2.5),
              _textLine(120, _grey.withOpacity(0.40)), const SizedBox(height: 10),
              _section('EXPERIENCE'), const SizedBox(height: 5),
              ...[('Sr. Product Designer', 'Stripe', '2021–Present'),
                  ('Product Designer', 'Airbnb', '2018–2021'),
                  ('UX Designer', 'IDEO', '2016–2018')].map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 3), child: _dot(3, _gold)),
                  const SizedBox(width: 5),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      Text(e.$3, style: TextStyle(fontSize: 5.5, color: _grey)),
                    ]),
                    Text(e.$2, style: const TextStyle(fontSize: 6, color: _gold, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2.5),
                    _textLine(140, _grey.withOpacity(0.4)), const SizedBox(height: 2),
                    _textLine(115, _grey.withOpacity(0.35)), const SizedBox(height: 2),
                    _textLine(130, _grey.withOpacity(0.35)),
                  ])),
                ]),
              )),
              _section('EDUCATION'), const SizedBox(height: 5),
              ...[('BFA Graphic Design', 'Rhode Island School of Design', '2016'),
                  ('Certificate – HCI', 'Stanford University', '2019')].map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 3), child: _dot(3, _gold)),
                  const SizedBox(width: 5),
                  Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink)),
                      Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _gold)),
                    ])),
                    Text(e.$3, style: TextStyle(fontSize: 5.5, color: _grey)),
                  ])),
                ]),
              )),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _goldLabel(String t) => Text(t,
      style: const TextStyle(color: _gold, fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 1.5));

  Widget _section(String t) => Row(children: [
    _bar(2.5, 10, _gold), const SizedBox(width: 5),
    Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 1.8)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// T01.5 – Archivist
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview01p5Archivist extends StatelessWidget {
  const MiniPreview01p5Archivist({super.key});
  static const _ink   = Color(0xFF1A1A1A);
  static const _mid   = Color(0xFF444444);
  static const _muted = Color(0xFF888888);
  static const _rule  = Color(0xFFCCCCCC);
  static const _label = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(
          color: Colors.white,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(
                  width: double.infinity,
                  child: Text('Christopher Carter, Accountant',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: _ink, height: 1.2)),
                ),
                const SizedBox(height: 5),
                Text('Rostov-on-Don  –  +7 928 912-70-24  –  mail@mail.com',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 5.5, color: _mid, height: 1.4)),
                const SizedBox(height: 8),
                Container(height: 0.6, color: _rule),
              ]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _twoColRow('PROFILE', [
                    _textLine(138, _mid.withOpacity(0.45)),
                    const SizedBox(height: 2),
                    _textLine(148, _mid.withOpacity(0.4)),
                    const SizedBox(height: 2),
                    _textLine(120, _mid.withOpacity(0.35)),
                  ]),
                  _ruleDivider(),
                  _twoColRow('EDUCATION', [
                    _expEntry('UX/UI courses, British Design High School', 'Moscow', '01/09/2015'),
                    const SizedBox(height: 5),
                    _expEntry('Institute of Art & Design', 'Rostov-on-Don', '01/09/2010'),
                  ]),
                  _ruleDivider(),
                  _twoColRow('EXPERIENCE', [
                    _expEntry('UX designer, Pentagram Group', 'Moscow', 'May 2015'),
                    const SizedBox(height: 5),
                    _expEntry('Graphic designer, Grizzly Agency', 'Rostov-on-Don', 'Oct. 2013'),
                    const SizedBox(height: 5),
                    _expEntry('Flash animator, Chulakov Studio', 'Rostov-on-Don', 'Nov. 2010'),
                  ]),
                  _ruleDivider(),
                  _twoColRow('SKILLS', [
                    Wrap(spacing: 10, runSpacing: 2, children: [
                      for (final s in ['UX/UI', 'Branding', 'Front-end', 'Wayfinding'])
                        Text(s, style: const TextStyle(fontSize: 5.5, color: _mid)),
                    ]),
                  ]),
                  _ruleDivider(),
                  _twoColRow('LANGUAGES', [
                    Text('English  ·  Russian',
                        style: const TextStyle(fontSize: 5.5, color: _mid)),
                  ]),
                  _ruleDivider(),
                  _twoColRow('HOBBIES', [
                    Text('Swimming, Watching TV shows, 3D printing',
                        style: const TextStyle(fontSize: 5.5, color: _mid)),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _ruleDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Container(height: 0.5, color: _rule),
  );

  Widget _twoColRow(String label, List<Widget> content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 5.5, fontWeight: FontWeight.w600,
                    color: _label, letterSpacing: 0.8)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: content)),
        ],
      ),
    );
  }

  Widget _expEntry(String title, String location, String date) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(title,
            style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink),
            overflow: TextOverflow.ellipsis)),
        Text(location, style: const TextStyle(fontSize: 5, color: _muted)),
      ]),
      Text(date, style: const TextStyle(fontSize: 5, color: _muted, fontStyle: FontStyle.italic)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// T02 – Nordic (white + blue)
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview02Nordic extends StatelessWidget {
  const MiniPreview02Nordic({super.key});
  static const _blue     = Color(0xFF2563EB);
  static const _ink      = Color(0xFF111111);
  static const _muted    = Color(0xFF888888);
  static const _rule     = Color(0xFFE0E0E0);
  static const _segEmpty = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Alexandra Chen',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300,
                            color: _ink, letterSpacing: -0.3, height: 1.0)),
                    const SizedBox(height: 4),
                    const Text('Senior Product Designer',
                        style: TextStyle(fontSize: 7.5, color: _blue, fontWeight: FontWeight.w500)),
                  ]),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('alex.chen@email.com',
                        style: const TextStyle(fontSize: 5.5, color: _muted),
                        overflow: TextOverflow.ellipsis),
                    Text('+1 (555) 234-5678',
                        style: const TextStyle(fontSize: 5.5, color: _muted),
                        overflow: TextOverflow.ellipsis),
                    Text('San Francisco, CA',
                        style: const TextStyle(fontSize: 5.5, color: _muted),
                        overflow: TextOverflow.ellipsis),
                    Text('alexchen.design',
                        style: const TextStyle(fontSize: 5.5, color: _muted),
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 0.5, color: _rule),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('ABOUT'), const SizedBox(height: 5),
                _textLine(155, _muted.withOpacity(0.5)), const SizedBox(height: 2.5),
                _textLine(135, _muted.withOpacity(0.45)), const SizedBox(height: 2.5),
                _textLine(148, _muted.withOpacity(0.45)), const SizedBox(height: 10),
                _label('EXPERIENCE'), const SizedBox(height: 6),
                ...[
                  ('Stripe', 'Sr. Product Designer', '2021–Present'),
                  ('Airbnb', 'Product Designer', '2018–2021'),
                  ('IDEO', 'UX Designer', '2016–2018'),
                ].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: _ink), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      Text(e.$3, style: const TextStyle(fontSize: 5.5, color: _muted)),
                    ]),
                    Text(e.$2, style: const TextStyle(fontSize: 6, color: _blue, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.only(top: 3.5), child: _dot(2.5, _blue)),
                      const SizedBox(width: 4),
                      Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.4))),
                    ]),
                    const SizedBox(height: 2),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.only(top: 3.5), child: _dot(2.5, _blue)),
                      const SizedBox(width: 4),
                      Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.35))),
                    ]),
                  ]),
                )),
                _label('EDUCATION'), const SizedBox(height: 5),
                ...[
                  ('RISD', 'BFA Graphic Design', '2016'),
                  ('Stanford', 'Certificate – HCI', '2019'),
                ].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w600, color: _ink), overflow: TextOverflow.ellipsis),
                      Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted)),
                    ])),
                    const SizedBox(width: 4),
                    Text(e.$3, style: const TextStyle(fontSize: 5.5, color: _muted)),
                  ]),
                )),
              ])),
              const SizedBox(width: 14),
              SizedBox(width: 68, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('SKILLS'), const SizedBox(height: 5),
                ...[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Sketch', 0.80), ('Motion', 0.70)].map((s) =>
                  Padding(padding: const EdgeInsets.only(bottom: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.$1, style: const TextStyle(fontSize: 6, color: _ink, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Row(children: List.generate(10, (i) => Container(
                        margin: const EdgeInsets.only(right: 1.5),
                        width: 4, height: 2.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1.5),
                          color: i < (s.$2 * 10).round() ? _blue : _segEmpty,
                        ),
                      ))),
                    ]))),
                const SizedBox(height: 6),
                _label('LANGUAGES'), const SizedBox(height: 5),
                ...['English (Native)', 'Mandarin (Fluent)', 'French (Basic)'].map((l) =>
                    Padding(padding: const EdgeInsets.only(bottom: 5),
                        child: Text(l, style: const TextStyle(fontSize: 5.5, color: _muted, height: 1.3)))),
              ])),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink, letterSpacing: 2));
}

// ─────────────────────────────────────────────────────────────────────────────
// T02.5 – Diplomat
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview02p5Diplomat extends StatelessWidget {
  const MiniPreview02p5Diplomat({super.key});
  static const _ink   = Color(0xFF1A1A1A);
  static const _mid   = Color(0xFF333333);
  static const _muted = Color(0xFF666666);
  static const _rule  = Color(0xFF888888);
  static const _shade = Color(0xFFEAEAEA);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: ClipRect(
        child: SizedBox(width: 260, height: 600,
          child: Container(
            color: Colors.white,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text('Tiffany Giroux',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: _ink, height: 1.1)),
                  ),
                  const SizedBox(height: 3),
                  Text('Freight & Logistics Analyst',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 6.5, color: _mid)),
                  const SizedBox(height: 3),
                  Text('18 Harmony Drive, Orlando, Florida  ·  001 415 570 5567  ·  tiffgiroux@hotmail.com',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 4.8, color: _muted, height: 1.3)),
                  const SizedBox(height: 6),
                  Container(height: 1.0, color: _rule),
                  const SizedBox(height: 1.5),
                  Container(height: 1.0, color: _rule),
                ]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionBox('PROFILE'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Column(children: [
                        _textLine(double.infinity, _mid.withOpacity(0.45)),
                        const SizedBox(height: 2.5),
                        _textLine(double.infinity, _mid.withOpacity(0.4)),
                        const SizedBox(height: 2.5),
                        _textLine(180, _mid.withOpacity(0.35)),
                      ]),
                    ),
                    _sectionBox('EXPERIENCE'),
                    ...[
                      (' ·   Freight Audit & Logistics Analyst - Ford', 'July 2014 - Current', 'Detroit, USA'),
                      (' ·   Senior Logistics Business Analyst - Honda', 'May 2012 - June 2014', 'Clermont, USA'),
                      (' ·   Senior Logistics Coordinator - Honda', 'May 2011 - May 2012', 'Clermont, USA'),
                    ].map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                          Flexible(child: Text(e.$1,
                              style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink),
                              overflow: TextOverflow.ellipsis, softWrap: false)),
                          Expanded(child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _DottedLeader(),
                          )),
                          Text(e.$2, style: const TextStyle(fontSize: 5, color: _muted)),
                        ]),
                        Text(e.$3, style: const TextStyle(fontSize: 5, color: _muted, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 2),
                        _textLine(double.infinity, _mid.withOpacity(0.35)),
                        const SizedBox(height: 1.5),
                        _textLine(180, _mid.withOpacity(0.3)),
                      ]),
                    )),
                    _sectionBox('EDUCATION'),
                    ...[
                      (' ·   Postgraduate Diploma Management Studies', 'Sep 2009 - Sep 2010'),
                      (' ·   Management Studies, Univ. of Hertfordshire', 'Sep 2007 - Sep 2009'),
                    ].map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                        Flexible(child: Text(e.$1,
                            style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink),
                            overflow: TextOverflow.ellipsis, softWrap: false)),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _DottedLeader(),
                        )),
                        Text(e.$2, style: const TextStyle(fontSize: 5, color: _muted)),
                      ]),
                    )),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionBox(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 0.8, color: _rule),
        const SizedBox(height: 1),
        Container(height: 0.8, color: _rule),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          color: _shade,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 6, fontWeight: FontWeight.w600,
                  color: _ink, letterSpacing: 2)),
        ),
        const SizedBox(height: 5),
      ]),
    );
  }
}

class _DottedLeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 6),
      painter: _DottedPainter(),
    );
  }
}

class _DottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF999999).withOpacity(0.5)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, size.height / 2), Offset(x + 0.5, size.height / 2), paint);
      x += 2.5;
    }
  }

  @override
  bool shouldRepaint(_DottedPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// T03 – Vibrant (coral header + pill skills)
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview03Vibrant extends StatelessWidget {
  const MiniPreview03Vibrant({super.key});
  static const _coral = Color(0xFFFF5C35);
  static const _pale  = Color(0xFFFFF1EE);
  static const _dark  = Color(0xFF1A1A1A);
  static const _mid   = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: ClipRect(
        child: SizedBox(width: 260, height: 600,
          child: Column(children: [
            Container(color: _coral,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.person_rounded, color: Colors.white60, size: 22)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Alexandra Chen', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                  const SizedBox(height: 3),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
                    child: const Text('Senior Product Designer',
                        style: TextStyle(fontSize: 5.5, color: _coral, fontWeight: FontWeight.w700))),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.email_outlined, color: Colors.white60, size: 8),
                    const SizedBox(width: 3),
                    const Text('alex.chen@email.com', style: TextStyle(color: Colors.white60, fontSize: 5.5)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white60, size: 8),
                    const SizedBox(width: 3),
                    const Text('San Francisco, CA', style: TextStyle(color: Colors.white60, fontSize: 5.5)),
                  ]),
                ])),
              ])),
            Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

              // ── Main content ──────────────────────────────────────────────
              Expanded(flex: 6, child: Container(color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _coralLabel('ABOUT ME'), const SizedBox(height: 4),
                  _textLine(145, _mid.withOpacity(0.4)), const SizedBox(height: 2.5),
                  _textLine(130, _mid.withOpacity(0.35)), const SizedBox(height: 2.5),
                  _textLine(140, _mid.withOpacity(0.35)), const SizedBox(height: 8),
                  _coralLabel('WORK EXPERIENCE'), const SizedBox(height: 5),
                  ...[('Sr. Product Designer', 'Stripe', '2021–Now'),
                      ('Product Designer', 'Airbnb', '2018–2021'),
                      ('UX Designer', 'IDEO', '2016–2018')].map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(e.$1,
                            style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _dark),
                            overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(color: _coral.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                          child: Text(e.$3, style: const TextStyle(fontSize: 5, color: _coral, fontWeight: FontWeight.w600))),
                      ]),
                      Text(e.$2, style: const TextStyle(fontSize: 6, color: _coral, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2.5),
                      _textLine(140, _mid.withOpacity(0.35)), const SizedBox(height: 2),
                      _textLine(115, _mid.withOpacity(0.3)),
                      Divider(color: Colors.grey.shade100, thickness: 0.5, height: 8),
                    ]),
                  )),
                  _coralLabel('EDUCATION'), const SizedBox(height: 4),
                  ...[('BFA Graphic Design', 'RISD', '2016'),
                      ('Certificate – HCI', 'Stanford', '2019')].map((e) =>
                    Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [
                      Container(width: 24, height: 24,
                        decoration: BoxDecoration(color: _coral.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                        child: Center(child: Text(e.$3, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w700, color: _coral)))),
                      const SizedBox(width: 6),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _dark)),
                        Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _mid)),
                      ]),
                    ]))),
                ]))),

              // ── Sidebar ───────────────────────────────────────────────────
              Container(width: 70, color: _pale,
                padding: const EdgeInsets.fromLTRB(7, 8, 6, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _coralLabel('SKILLS'), const SizedBox(height: 6),
                  ...['Figma', 'Design Sys.', 'Research', 'Prototyping', 'Sketch'].map((s) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _coral.withOpacity(0.25)),
                            ),
                            child: Text(s,
                              style: const TextStyle(fontSize: 5.5, color: _dark, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  _coralLabel('LANGUAGES'), const SizedBox(height: 5),
                  ...['English (Native)', 'Mandarin', 'French'].map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      _dot(3, _coral), const SizedBox(width: 4),
                      Expanded(child: Text(l,
                          style: const TextStyle(fontSize: 5.5, color: _mid),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                    ]),
                  )),
                ])),
            ])),
          ]),
        ),
      ),
    );
  }

  // ── THE REAL FIX ──────────────────────────────────────────────────────────
  // The previous version was:
  //   Row(children: [_bar(...), SizedBox(width:5), Text(t)])
  //
  // A bare Text inside a Row has no upper-bound width constraint. In the
  // 57 px usable sidebar space (70 px container − 13 px padding), "LANGUAGES"
  // at fontSize 6 with letterSpacing 1.2 measures ~60 px → 3.1 px overflow.
  //
  // Fix: wrap Text in Expanded so it is constrained to the remaining row
  // width, and add ellipsis so it clips gracefully rather than asserting.
  Widget _coralLabel(String t) => Row(children: [
    _bar(10, 2, _coral),
    const SizedBox(width: 5),
    Expanded(
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 6,
          fontWeight: FontWeight.w800,
          color: _dark,
          letterSpacing: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// T03.5 – Scholar
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview03p5Scholar extends StatelessWidget {
  const MiniPreview03p5Scholar({super.key});
  static const _blue  = Color(0xFF2563EB);
  static const _ink   = Color(0xFF1A1A1A);
  static const _mid   = Color(0xFF333333);
  static const _muted = Color(0xFF777777);
  static const _rule  = Color(0xFFCCCCCC);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(
          color: Colors.white,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(
                  width: double.infinity,
                  child: Text('THOMAS EASTWOOD',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900,
                          color: _ink, letterSpacing: 1.5, height: 1.1)),
                ),
                const SizedBox(height: 3),
                Text('Full Stack Developer',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 6.5, color: _blue, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Wrap(alignment: WrapAlignment.center, children: [
                  for (final (i, part) in [
                    '+1-555-555-5555', 'thomas@gmail.com',
                    'github.io/thom.east', 'San Francisco, CA'
                  ].indexed) ...[
                    if (i > 0)
                      const Text('  •  ', style: TextStyle(fontSize: 5.5, color: _muted)),
                    Text(part, style: const TextStyle(fontSize: 5.5, color: _muted)),
                  ],
                ]),
                const SizedBox(height: 8),
                Container(height: 0.6, color: _rule),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _centredHeader('Summary'),
                  _textLine(double.infinity, _mid.withOpacity(0.4)),
                  const SizedBox(height: 2),
                  _textLine(200, _mid.withOpacity(0.35)),
                  const SizedBox(height: 8),
                  _centredHeader('Experience'),
                  ...[
                    ('Boyle', 'Senior Full Stack Developer', '2018 - Present'),
                    ('Lauzon', 'Full Stack Developer', '2013 - 2018'),
                  ].map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1,
                          style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: _blue)),
                      Row(children: [
                        Expanded(child: Text(e.$2, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w500, color: _ink), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        Text(e.$3, style: const TextStyle(fontSize: 5, color: _muted)),
                      ]),
                      const SizedBox(height: 2),
                      ...List.generate(2, (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 1.5),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('•  ', style: TextStyle(fontSize: 5.5, color: _mid)),
                          Expanded(child: _textLine(double.infinity, _mid.withOpacity(0.35))),
                        ]),
                      )),
                    ]),
                  )),
                  _centredHeader('Education'),
                  Row(children: [
                    Expanded(child: Text('Stanford University',
                        style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: _blue),
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Text('2008 - 2009', style: TextStyle(fontSize: 5, color: _muted)),
                  ]),
                  const Text('M.S. in Computer Science',
                      style: TextStyle(fontSize: 6, color: _ink)),
                  const SizedBox(height: 7),
                  _centredHeader('Skills'),
                  Wrap(spacing: 6, runSpacing: 2, children: [
                    for (final s in ['HTML', 'CSS', 'JS', 'React', 'Python', 'NodeJS', 'AWS', 'SQL'])
                      Text(s, style: const TextStyle(fontSize: 5.5, color: _mid)),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _centredHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: double.infinity,
          child: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w700,
                  color: _blue)),
        ),
        const SizedBox(height: 2),
        Container(height: 0.6, color: _rule),
        const SizedBox(height: 4),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// T04 – Tech Dark (GitHub dark + monospace green)
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview04TechDark extends StatelessWidget {
  const MiniPreview04TechDark({super.key});
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
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: _bg,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 82,
              decoration: const BoxDecoration(
                color: _surface,
                border: Border(right: BorderSide(color: _border, width: 0.5)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _dot(4, const Color(0xFFFF5F57)), const SizedBox(width: 3),
                  _dot(4, const Color(0xFFFFBD2E)), const SizedBox(width: 3),
                  _dot(4, const Color(0xFF27C840)),
                ]),
                const SizedBox(height: 8),
                Center(child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: _green, width: 1.5), color: _bg),
                  child: const Icon(Icons.terminal, color: _green, size: 17))),
                const SizedBox(height: 7),
                const Center(child: Text('Alex Chen', style: TextStyle(
                    fontFamily: 'monospace', fontSize: 6.5, fontWeight: FontWeight.w700, color: _white))),
                const SizedBox(height: 8),
                _mono('// CONTACT', _yellow), const SizedBox(height: 4),
                ...[('email', 'alex.chen@\nemail.com'), ('phone', '+1 555 234 5678'),
                    ('location', 'San Francisco'), ('web', 'alexchen.design')].map((e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 3.5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${e.$1}: ', style: const TextStyle(fontFamily: 'monospace', fontSize: 5, color: _blue)),
                      Expanded(child: Text(e.$2, style: const TextStyle(fontFamily: 'monospace', fontSize: 5, color: _muted),
                          overflow: TextOverflow.ellipsis)),
                    ]))),
                const SizedBox(height: 8),
                _mono('// SKILLS', _yellow), const SizedBox(height: 4),
                ...[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85), ('Prototyping', 0.88)].map((s) =>
                  Padding(padding: const EdgeInsets.only(bottom: 5), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(s.$1, style: const TextStyle(fontFamily: 'monospace', fontSize: 5.5, color: _white), overflow: TextOverflow.ellipsis)),
                      Text('${(s.$2 * 100).round()}%',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 5, color: _green)),
                    ]),
                    const SizedBox(height: 1.5),
                    Stack(children: [
                      _bar(66, 2, _border, r: 1),
                      ClipRRect(borderRadius: BorderRadius.circular(1),
                        child: Container(width: 66 * s.$2, height: 2,
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [_green, _blue])))),
                    ]),
                  ]))),
              ])),
            Expanded(child: Padding(padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _border, width: 0.5)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('\$ whoami', style: TextStyle(fontFamily: 'monospace', fontSize: 6, color: _green)),
                    const SizedBox(height: 2),
                    const Text('Alexandra Chen', style: TextStyle(fontFamily: 'monospace', fontSize: 11,
                        fontWeight: FontWeight.w700, color: _blue)),
                    const Text('Senior Product Designer', style: TextStyle(fontFamily: 'monospace', fontSize: 6, color: _yellow)),
                  ])),
                const SizedBox(height: 8),
                _mono('// SUMMARY', _yellow), const SizedBox(height: 4),
                Container(padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: _surface, borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                      border: Border(left: BorderSide(color: _green, width: 2))),
                  child: Column(children: [
                    _textLine(double.infinity, _muted), const SizedBox(height: 2.5),
                    _textLine(double.infinity, _muted), const SizedBox(height: 2.5),
                    _textLine(120, _muted),
                  ])),
                const SizedBox(height: 8),
                _mono('// EXPERIENCE', _yellow), const SizedBox(height: 5),
                ...[('Stripe', 'Sr. Product Designer', '2021–Present'),
                    ('Airbnb', 'Product Designer', '2018–2021'),
                    ('IDEO', 'UX Designer', '2016–2018')].map((e) =>
                  Container(margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _border, width: 0.5)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(e.$1, style: const TextStyle(fontFamily: 'monospace', fontSize: 6.5,
                            fontWeight: FontWeight.w700, color: _blue), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        Text(e.$3, style: const TextStyle(fontFamily: 'monospace', fontSize: 5, color: _muted)),
                      ]),
                      Text(e.$2, style: const TextStyle(fontFamily: 'monospace', fontSize: 5.5, color: _green)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Text('- ', style: TextStyle(fontFamily: 'monospace', fontSize: 5.5, color: _green)),
                        Expanded(child: _textLine(double.infinity, _muted)),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Text('- ', style: TextStyle(fontFamily: 'monospace', fontSize: 5.5, color: _green)),
                        Expanded(child: _textLine(double.infinity, _muted)),
                      ]),
                    ]))),
              ]))),
          ]),
        ),
      ),
    );
  }
  Widget _mono(String t, Color c) => Text(t,
      style: TextStyle(fontFamily: 'monospace', fontSize: 6, color: c, fontWeight: FontWeight.w700));
}

// ─────────────────────────────────────────────────────────────────────────────
// T04.5 – Vanguard
// ─────────────────────────────────────────────────────────────────────────────
class MiniPreview04p5Vanguard extends StatelessWidget {
  const MiniPreview04p5Vanguard({super.key});
  static const _green = Color(0xFF1A7A4A);
  static const _ink   = Color(0xFF0D0D0D);
  static const _mid   = Color(0xFF333333);
  static const _muted = Color(0xFF777777);
  static const _rule  = Color(0xFFDDDDDD);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('VIVIAN JENNINGS',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900,
                    color: _ink, letterSpacing: 0.5, height: 1.0)),
            const SizedBox(height: 2),
            const Text('Head of Sales',
                style: TextStyle(
                    fontSize: 7.5, color: _green, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Wrap(spacing: 12, runSpacing: 2, children: [
              _contactChip(Icons.phone, '+1-000-000'),
              _contactChip(Icons.email_outlined, 'vivian@enhancv.com'),
              _contactChip(Icons.link, 'linkedin.com/in/vivian'),
            ]),
            const SizedBox(height: 10),
            const Text('KEY ACHIEVEMENTS',
                style: TextStyle(
                    fontSize: 6.5, fontWeight: FontWeight.w800,
                    color: _ink, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _achievementBox(
                Icons.diamond_outlined,
                'I am proud of',
                'Formed technical sales dept with \$3M annual sales in 6 months',
              )),
              const SizedBox(width: 8),
              Expanded(child: _achievementBox(
                Icons.bar_chart,
                'Doubled down on turnover',
                'Increased sales dept turnover by 30% in talent demanding niche',
              )),
            ]),
            const SizedBox(height: 10),
            const Text('EXPERIENCE',
                style: TextStyle(
                    fontSize: 6.5, fontWeight: FontWeight.w800,
                    color: _ink, letterSpacing: 1.2)),
            const SizedBox(height: 5),
            ...[
              ('2018 - Present', 'Sales Director', 'AY Security Services', 'Detroit, MI'),
              ('2015 - 2018', 'National Sales Director', 'AY Security Services', 'Detroit, MI'),
              ('2012 - 2015', 'Regional Sales Manager', 'Heller', 'Detroit, MI'),
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 50,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.$1, style: const TextStyle(
                        fontSize: 5, fontWeight: FontWeight.w600, color: _green)),
                    const SizedBox(height: 2),
                    Text(e.$4, style: const TextStyle(fontSize: 4.5, color: _muted)),
                  ]),
                ),
                Column(children: [
                  const SizedBox(height: 1),
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                        color: _green, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1)),
                  ),
                ]),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.$2, style: const TextStyle(
                      fontSize: 7, fontWeight: FontWeight.w700, color: _ink)),
                  Text(e.$3, style: const TextStyle(
                      fontSize: 6, color: _green, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  _textLine(double.infinity, _mid.withOpacity(0.35)),
                  const SizedBox(height: 1.5),
                  _textLine(140, _mid.withOpacity(0.3)),
                ])),
              ]),
            )),
            const SizedBox(height: 4),
            const Text('EDUCATION',
                style: TextStyle(
                    fontSize: 6.5, fontWeight: FontWeight.w800,
                    color: _ink, letterSpacing: 1.2)),
            const SizedBox(height: 5),
            ...[
              ('2011 - 2012', 'MBA In Marketing', 'University of Pittsburgh'),
              ('2006 - 2010', 'Bachelor of Marketing', 'University of Pennsylvania'),
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 50,
                  child: Text(e.$1, style: const TextStyle(
                      fontSize: 5, fontWeight: FontWeight.w600, color: _green)),
                ),
                Column(children: [
                  const SizedBox(height: 1),
                  Container(width: 7, height: 7,
                      decoration: BoxDecoration(color: _green, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1))),
                ]),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.$2, style: const TextStyle(
                      fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink)),
                  Text(e.$3, style: const TextStyle(
                      fontSize: 5.5, color: _green, fontWeight: FontWeight.w500)),
                ])),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _contactChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 7, color: _green),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 5.5, color: _muted)),
    ]);
  }

  Widget _achievementBox(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 8, color: _green),
          const SizedBox(width: 3),
          Expanded(child: Text(title,
              style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w700, color: _ink),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 3),
        Text(body, style: const TextStyle(fontSize: 5, color: _mid, height: 1.3)),
      ]),
    );
  }
}