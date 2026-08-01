// mini_previews_d.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/mini_previews_d.dart
//
// Templates 13–16: Wina Dark Infographic, Rio Orange, Summer Minimal, Helene Beige
// FIX: T14 Rio skill name/pct rows now use Expanded

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

// T13 – Wina Dark Infographic
class MiniPreview13Wina extends StatelessWidget {
  const MiniPreview13Wina({super.key});
  static const _bg      = Color(0xFF1C1C1C);
  static const _card    = Color(0xFF272727);
  static const _orange  = Color(0xFFFF6B2B);
  static const _teal    = Color(0xFF00BCD4);
  static const _green   = Color(0xFF66BB6A);
  static const _yellow  = Color(0xFFFFCA28);
  static const _pink    = Color(0xFFEC407A);
  static const _muted   = Color(0xFF9E9E9E);
  static const _divider = Color(0xFF3A3A3A);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: _bg,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(color: _card,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children: [
                Container(width: 34, height: 34,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: _orange, width: 1.5), color: const Color(0xFF333333)),
                  child: const Icon(Icons.person_rounded, color: Colors.white38, size: 16)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Alexandra Chen', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(2)),
                    child: const Text('Senior Product Designer', style: TextStyle(fontSize: 4.5, color: Colors.white, fontWeight: FontWeight.w600))),
                ])),
                const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('alex.chen@email.com', style: TextStyle(color: Colors.white38, fontSize: 4.5)),
                  SizedBox(height: 1.5),
                  Text('San Francisco, CA', style: TextStyle(color: Colors.white38, fontSize: 4.5)),
                ]),
              ])),
            Container(color: const Color(0xFF222222),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _icoCircle(Icons.location_city, _teal),
                _icoCircle(Icons.text_fields, _orange),
                _icoCircle(Icons.menu_book, _yellow),
                _icoCircle(Icons.camera_alt, _pink),
                _icoCircle(Icons.music_note, _teal),
                _icoCircle(Icons.flight, _green),
                _icoCircle(Icons.park, _green),
                _icoCircle(Icons.people, _pink),
              ])),
            Expanded(child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _secLabel('EDUCATION', _teal), const SizedBox(height: 6),
                  _tlItem('BFA Graphic Design', 'RISD', '2016', _teal),
                  _tlItem('Certificate – HCI', 'Stanford', '2019', _teal),
                  const SizedBox(height: 6),
                  _secLabel('EXPERIENCE', _orange), const SizedBox(height: 6),
                  _tlItem('Sr. Product Designer', 'Stripe', '2021–Now', _orange),
                  _tlItem('Product Designer', 'Airbnb', '2018–2021', _orange),
                  _tlItem('UX Designer', 'IDEO', '2016–2018', _orange),
                ])),
                const SizedBox(width: 8),
                SizedBox(width: 60, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _secLabel('POWER', _yellow), const SizedBox(height: 6),
                  Wrap(spacing: 4, runSpacing: 8, children: [
                    _ring('Figma', 0.95, _orange), _ring('D.Sys', 0.90, _teal),
                    _ring('Res.', 0.85, _green), _ring('Proto', 0.88, _yellow),
                    _ring('Sketch', 0.80, _pink), _ring('Motion', 0.70, _teal),
                  ]),
                ])),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _icoCircle(IconData icon, Color color) => Container(
    width: 20, height: 20,
    decoration: BoxDecoration(shape: BoxShape.circle,
        color: color.withOpacity(0.15), border: Border.all(color: color.withOpacity(0.4))),
    child: Icon(icon, color: color, size: 10));

  Widget _secLabel(String t, Color c) => Row(children: [
    Container(width: 2, height: 8, color: c), const SizedBox(width: 4),
    Text(t, style: TextStyle(color: c, fontSize: 5.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
  ]);

  Widget _tlItem(String title, String sub, String date, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [_dot(4, c), Container(width: 1, height: 20, color: _divider)]),
      const SizedBox(width: 5),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          Text(date, style: TextStyle(color: c, fontSize: 4.5)),
        ]),
        Text(sub, style: const TextStyle(color: _muted, fontSize: 5)),
      ])),
    ]),
  );

  Widget _ring(String name, double level, Color color) => SizedBox(
    width: 25,
    child: Column(children: [
      SizedBox(width: 22, height: 22, child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: level, strokeWidth: 2.5,
            backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(color)),
        Text('${(level * 100).round()}', style: TextStyle(color: color, fontSize: 4.5, fontWeight: FontWeight.w700)),
      ])),
      const SizedBox(height: 2),
      Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 4, height: 1.1), overflow: TextOverflow.ellipsis),
    ]),
  );
}

// T14 – Rio Orange Sidebar
class MiniPreview14Rio extends StatelessWidget {
  const MiniPreview14Rio({super.key});
  static const _dark   = Color(0xFF2B2B2B);
  static const _darker = Color(0xFF1E1E1E);
  static const _orange = Color(0xFFE8651A);
  static const _bg     = Color(0xFFF4F4F4);
  static const _ink    = Color(0xFF222222);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 80, color: _dark,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(color: _orange, width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Alexandra', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                  Text('Chen', style: TextStyle(color: Colors.white70, fontSize: 6.5, fontWeight: FontWeight.w300)),
                  SizedBox(height: 2),
                  Text('Product Designer', style: TextStyle(color: Colors.white60, fontSize: 4.5)),
                ])),
              Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: _orange, width: 1.5), color: const Color(0xFF3A3A3A)),
                  child: const Icon(Icons.person_rounded, color: Colors.white38, size: 18)))),
              _sideBlock('CONTACT'),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                child: Column(children: [
                  _contact(Icons.email_outlined, 'alex.chen@email.com'),
                  _contact(Icons.phone_outlined, '+1 555 234 5678'),
                  _contact(Icons.location_on_outlined, 'San Francisco'),
                ])),
              _sideBlock('PRO SKILLS'),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                child: Column(children: [
                  for (final s in <(String, double)>[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85), ('Prototyping', 0.88), ('Sketch', 0.80)])
                    Padding(padding: const EdgeInsets.only(bottom: 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // FIXED: Expanded on skill name
                        Row(children: [
                          Expanded(child: Text(s.$1, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 5.5), overflow: TextOverflow.ellipsis)),
                          Text('${(s.$2 * 100).round()}%', style: const TextStyle(color: _orange, fontSize: 5)),
                        ]),
                        const SizedBox(height: 2),
                        _skillPct(62, s.$2, _orange, Colors.white10),
                      ])),
                ])),
            ])),
          Expanded(child: Container(color: _bg,
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _rightH('EXPERIENCE'), const SizedBox(height: 4),
              for (final e in <(String, String, String)>[
                ('Sr. Product Designer', 'Stripe', '2021–Now'),
                ('Product Designer', 'Airbnb', '2018–2021'),
                ('UX Designer', 'IDEO', '2016–2018')])
                Padding(padding: const EdgeInsets.only(bottom: 7),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: _orange.withOpacity(0.1), borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: _orange.withOpacity(0.3))),
                      child: Text(e.$3, style: const TextStyle(color: _orange, fontSize: 4.5, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 5),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink)),
                      Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _orange, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      _textLine(double.infinity, const Color(0xFF888888).withOpacity(0.35)),
                    ])),
                  ])),
              _rightH('EDUCATION'), const SizedBox(height: 4),
              for (final e in <(String, String, String)>[
                ('BFA Graphic Design', 'RISD', '2016'),
                ('Certificate – HCI', 'Stanford', '2019')])
                Padding(padding: const EdgeInsets.only(bottom: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: _orange.withOpacity(0.1), borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: _orange.withOpacity(0.3))),
                      child: Text(e.$3, style: const TextStyle(color: _orange, fontSize: 4.5, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 5),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink)),
                      Text(e.$2, style: const TextStyle(fontSize: 5, color: _orange)),
                    ])),
                  ])),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _sideBlock(String t) => Container(width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(color: _darker, border: const Border(left: BorderSide(color: _orange, width: 2))),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w700, letterSpacing: 1.5)));

  Widget _contact(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 3.5),
    child: Row(children: [
      Icon(icon, color: _orange, size: 7), const SizedBox(width: 3),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 5), overflow: TextOverflow.ellipsis)),
    ]));

  Widget _rightH(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 2.5, height: 10, color: _orange), const SizedBox(width: 5),
      Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 1.2))]),
    const SizedBox(height: 3), Container(height: 0.5, color: const Color(0xFFDDDDDD)), const SizedBox(height: 5),
  ]);
}

// T15 – Summer Clean Minimal (no changes needed — already uses Expanded)
class MiniPreview15Summer extends StatelessWidget {
  const MiniPreview15Summer({super.key});
  static const _ink    = Color(0xFF1A1A1A);
  static const _muted  = Color(0xFF6B7280);
  static const _light  = Color(0xFF9CA3AF);
  static const _rule   = Color(0xFFE5E7EB);
  static const _accent = Color(0xFF374151);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 32, height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: _rule),
                child: const Icon(Icons.person_rounded, color: _light, size: 16)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Alexandra Chen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 2),
                const Text('Senior Product Designer', style: TextStyle(fontSize: 5.5, color: _muted)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.email_outlined, size: 7, color: _light), const SizedBox(width: 2),
                  const Text('alex.chen@email.com', style: TextStyle(fontSize: 5, color: _muted)),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on_outlined, size: 7, color: _light), const SizedBox(width: 2),
                  const Text('San Francisco', style: TextStyle(fontSize: 5, color: _muted)),
                ]),
              ])),
            ]),
            const SizedBox(height: 8),
            Container(height: 0.6, color: _rule), const SizedBox(height: 7),
            _h('SUMMARY'), const SizedBox(height: 3),
            _textLine(double.infinity, _muted.withOpacity(0.4)), const SizedBox(height: 2),
            _textLine(200, _muted.withOpacity(0.35)), const SizedBox(height: 8),
            Container(height: 0.6, color: _rule), const SizedBox(height: 7),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 7, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _h('EXPERIENCE'), const SizedBox(height: 5),
                for (final e in <(String, String, String)>[
                  ('Sr. Product Designer', 'Stripe', '2021–Now'),
                  ('Product Designer', 'Airbnb', '2018–2021'),
                  ('UX Designer', 'IDEO', '2016–2018')])
                  Padding(padding: const EdgeInsets.only(bottom: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis)),
                      Text(e.$3, style: const TextStyle(fontSize: 5, color: _light)),
                    ]),
                    Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted)),
                    const SizedBox(height: 2),
                    _textLine(double.infinity, _muted.withOpacity(0.3)),
                  ])),
                _h('EDUCATION'), const SizedBox(height: 5),
                for (final e in <(String, String, String)>[
                  ('BFA Graphic Design', 'RISD', '2016'),
                  ('Certificate – HCI', 'Stanford', '2019')])
                  Padding(padding: const EdgeInsets.only(bottom: 5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis)),
                      Text(e.$3, style: const TextStyle(fontSize: 5, color: _light)),
                    ]),
                    Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted)),
                  ])),
              ])),
              const SizedBox(width: 10),
              SizedBox(width: 60, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _h('SKILLS'), const SizedBox(height: 5),
                for (final s in <(String, double)>[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85), ('Prototyping', 0.88), ('Sketch', 0.80)])
                  Padding(padding: const EdgeInsets.only(bottom: 5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: const TextStyle(fontSize: 5.5, color: _accent), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    _skillPct(double.infinity, s.$2, _accent, _rule, h: 2),
                  ])),
                const SizedBox(height: 5),
                _h('LANGUAGES'), const SizedBox(height: 4),
                for (final l in ['English', 'Mandarin', 'French'])
                  Padding(padding: const EdgeInsets.only(bottom: 3.5), child: Row(children: [
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: _muted, shape: BoxShape.circle)),
                    const SizedBox(width: 3),
                    Expanded(child: Text(l, style: const TextStyle(fontSize: 5, color: _muted), overflow: TextOverflow.ellipsis)),
                  ])),
              ])),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _h(String t) => Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 1.8));
}

// T16 – Helene Beige Elegant (no changes needed — already uses Expanded)
class MiniPreview16Helene extends StatelessWidget {
  const MiniPreview16Helene({super.key});
  static const _bg     = Color(0xFFF0EDE8);
  static const _card   = Color(0xFFE8E3DC);
  static const _ink    = Color(0xFF2C2C2C);
  static const _muted  = Color(0xFF7A7368);
  static const _accent = Color(0xFF8B7355);
  static const _soft   = Color(0xFFBDB0A0);
  static const _border = Color(0xFFD5CCBF);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 80, color: _card,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: _soft, width: 2), color: _soft.withOpacity(0.3)),
                child: Icon(Icons.person_rounded, color: _soft, size: 18)),
              const SizedBox(height: 5),
              const Text('Alexandra', textAlign: TextAlign.center, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: _ink)),
              const Text('Chen', textAlign: TextAlign.center, style: TextStyle(fontSize: 5.5, color: _muted)),
              const SizedBox(height: 3),
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withOpacity(0.3))),
                child: const Text('Designer', textAlign: TextAlign.center, style: TextStyle(fontSize: 4.5, color: _accent, fontWeight: FontWeight.w600))),
              const SizedBox(height: 8),
              _div(), const SizedBox(height: 7),
              _sh('CONTACT'), const SizedBox(height: 4),
              _sc(Icons.email_outlined, 'alex.chen@email.com'),
              _sc(Icons.phone_outlined, '+1 555 234 5678'),
              _sc(Icons.location_on_outlined, 'San Francisco'),
              const SizedBox(height: 7),
              _div(), const SizedBox(height: 7),
              _sh('SKILL'), const SizedBox(height: 5),
              for (final s in <(String, double)>[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85), ('Prototyping', 0.88)])
                Padding(padding: const EdgeInsets.only(bottom: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.$1, style: const TextStyle(fontSize: 5, color: _muted), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1.5),
                  _skillPct(62, s.$2, _accent, _soft.withOpacity(0.35)),
                ])),
              const SizedBox(height: 7),
              _div(), const SizedBox(height: 7),
              _sh('LANGUAGE'), const SizedBox(height: 4),
              for (final l in ['English', 'Mandarin', 'French'])
                Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(children: [
                  _dot(3, _accent), const SizedBox(width: 4),
                  Expanded(child: Text(l, style: const TextStyle(fontSize: 5, color: _muted), overflow: TextOverflow.ellipsis)),
                ])),
            ])),
          Expanded(child: Container(color: _bg,
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 14, height: 2, color: _accent),
                const SizedBox(width: 3), Container(width: 5, height: 2, color: _soft)]),
              const SizedBox(height: 7),
              _rh('MY PROFILE'), const SizedBox(height: 4),
              _textLine(double.infinity, _muted.withOpacity(0.4)), const SizedBox(height: 2),
              _textLine(150, _muted.withOpacity(0.35)), const SizedBox(height: 8),
              _rh('EXPERIENCE'), const SizedBox(height: 5),
              for (final e in <(String, String, String)>[
                ('Sr. Product Designer', 'Stripe', '2021–Now'),
                ('Product Designer', 'Airbnb', '2018–2021'),
                ('UX Designer', 'IDEO', '2016–2018')])
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _bg, shape: BoxShape.circle, border: Border.all(color: _accent, width: 1))),
                    Container(width: 1, height: 22, color: _border),
                  ]),
                  const SizedBox(width: 6),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis)),
                      Text(e.$3, style: const TextStyle(fontSize: 5, color: _soft)),
                    ]),
                    Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _accent)),
                    const SizedBox(height: 2),
                    _textLine(double.infinity, _muted.withOpacity(0.35)),
                  ])),
                ])),
              _rh('EDUCATION'), const SizedBox(height: 5),
              for (final e in <(String, String, String)>[
                ('BFA Graphic Design', 'RISD', '2016'),
                ('Certificate – HCI', 'Stanford', '2019')])
                Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(color: _bg, shape: BoxShape.circle, border: Border.all(color: _accent, width: 1))),
                  const SizedBox(width: 6),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis),
                    Text(e.$2, style: const TextStyle(fontSize: 5, color: _accent)),
                  ])),
                  Text(e.$3, style: const TextStyle(fontSize: 5, color: _soft)),
                ])),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _div() => Container(height: 0.8, color: _border);
  Widget _sh(String t) => Align(alignment: Alignment.centerLeft,
      child: Text(t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800, color: _accent, letterSpacing: 1.8)));
  Widget _sc(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 3.5),
    child: Row(children: [Icon(icon, size: 7, color: _accent), const SizedBox(width: 3),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 5, color: _muted), overflow: TextOverflow.ellipsis))]));
  Widget _rh(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 10, height: 1, color: _accent), const SizedBox(width: 5),
      Text(t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 1.5))]),
    const SizedBox(height: 3), Container(height: 0.4, color: _border),
  ]);
}