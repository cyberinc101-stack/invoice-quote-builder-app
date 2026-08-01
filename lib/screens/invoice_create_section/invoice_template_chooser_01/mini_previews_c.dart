// mini_previews_c.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/mini_previews_c.dart
//
// Templates 9–12: Brutalist, Emerald, Infographic, Art Deco
// FIXES: All spaceBetween rows now use Expanded on the title/name child

import 'package:flutter/material.dart';
import 'dart:math' as math;

Widget _bar(double w, double h, Color c, {double r = 2}) =>
    Container(width: w, height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

Widget _textLine(double w, Color c, {double h = 3.0}) => _bar(w, h, c);

Widget _dot(double r, Color c) =>
    Container(width: r * 2, height: r * 2,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));

// T09 – Brutalist
class MiniPreview09Brutalist extends StatelessWidget {
  const MiniPreview09Brutalist({super.key});
  static const _black  = Color(0xFF000000);
  static const _yellow = Color(0xFFFFE500);
  static const _muted  = Color(0xFF444444);
  static const _grey   = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: Colors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(color: _black, padding: const EdgeInsets.all(10), child: Row(children: [
            Container(width: 44, height: 44, color: _yellow,
              child: const Center(child: Text('AC',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _black)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ALEXANDRA CHEN', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 0.5, height: 1.1)),
              const SizedBox(height: 3),
              Container(color: _yellow, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Text('SENIOR PRODUCT DESIGNER', style: const TextStyle(
                    fontSize: 4.5, fontWeight: FontWeight.w900, color: _black, letterSpacing: 1))),
            ])),
          ])),
          Container(
            decoration: const BoxDecoration(border: Border.symmetric(
                horizontal: BorderSide(color: _black, width: 2))),
            child: Row(children: [
              _contactCell('alex.chen@email.com', flex: 3),
              Container(width: 2, height: 20, color: _black),
              _contactCell('+1 555 234 5678', flex: 2),
              Container(width: 2, height: 20, color: _black),
              _contactCell('San Francisco', flex: 2),
            ]),
          ),
          Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 82,
              decoration: const BoxDecoration(border: Border(right: BorderSide(color: _black, width: 2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _sideHeader('SKILLS'),
                ...[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Sketch', 0.80), ('Motion', 0.70)].map((s) =>
                  Container(
                    decoration: const BoxDecoration(border: Border(
                        bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5))),
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                    // FIXED: Expanded on skill name
                    child: Row(children: [
                      Expanded(child: Text(s.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _black), overflow: TextOverflow.ellipsis)),
                      Text('${(s.$2 * 100).round()}%',
                          style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: _black)),
                    ]),
                  )),
                _sideHeader('EDUCATION'),
                ...[('BFA Graphic Design', 'RISD', '2016'), ('Certificate – HCI', 'Stanford', '2019')].map((e) =>
                  Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: _black)),
                      Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted)),
                      Container(margin: const EdgeInsets.only(top: 3, bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), color: _yellow,
                        child: Text(e.$3, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: _black))),
                    ]))),
                _sideHeader('LANGUAGES'),
                Padding(padding: const EdgeInsets.fromLTRB(8, 5, 8, 0), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ['English', 'Mandarin', 'French'].map((l) =>
                        Padding(padding: const EdgeInsets.only(bottom: 4),
                            child: Text(l, style: const TextStyle(fontSize: 6, color: _muted)))).toList())),
              ])),
            Expanded(child: Padding(padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _brutalHeader('PROFILE'), const SizedBox(height: 6),
                _textLine(double.infinity, _muted.withOpacity(0.45)), const SizedBox(height: 2.5),
                _textLine(150, _muted.withOpacity(0.4)), const SizedBox(height: 2.5),
                _textLine(160, _muted.withOpacity(0.4)), const SizedBox(height: 8),
                _brutalHeader('EXPERIENCE'), const SizedBox(height: 5),
                ...[('Sr. Product Designer', 'Stripe', '2021–Now'),
                    ('Product Designer', 'Airbnb', '2018–2021'),
                    ('UX Designer', 'IDEO', '2016–2018')].map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D0D0))),
                  child: Column(children: [
                    Container(color: _grey, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      // FIXED
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w900, color: _black)),
                          Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted, fontWeight: FontWeight.w600)),
                        ])),
                        Container(color: _yellow, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                          child: Text(e.$3, style: const TextStyle(fontSize: 5, fontWeight: FontWeight.w900, color: _black))),
                      ])),
                    Padding(padding: const EdgeInsets.all(7), child: Column(children: [
                      Row(children: [
                        Text('/ ', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: _black)),
                        Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.4))),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text('/ ', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: _black)),
                        Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.35))),
                      ]),
                    ])),
                  ]),
                )),
              ]),
            )),
          ])),
        ])),
      ),
    );
  }
  Widget _contactCell(String t, {int flex = 1}) => Expanded(flex: flex,
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
      child: Text(t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w600, color: _black),
          overflow: TextOverflow.ellipsis)));
  Widget _sideHeader(String t) => Container(padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
    color: _black, child: Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w900,
        color: Colors.white, letterSpacing: 1.5)));
  Widget _brutalHeader(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(border: Border.all(color: _black, width: 2)),
    child: Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w900, letterSpacing: 2, color: _black)));
}

// T10 – Emerald
class MiniPreview10Emerald extends StatelessWidget {
  const MiniPreview10Emerald({super.key});
  static const _emerald   = Color(0xFF064E3B);
  static const _emeraldM  = Color(0xFF065F46);
  static const _emeraldLt = Color(0xFF10B981);
  static const _cream     = Color(0xFFF0FDF4);
  static const _ink       = Color(0xFF1C1C1E);
  static const _muted     = Color(0xFF6B7280);
  static const _border    = Color(0xFFD1FAE5);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: Colors.white, child: Column(children: [
          Container(color: _emerald, child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _DiagPainter())),
            Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child:
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Alexandra Chen', style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3, height: 1.1)),
                  const SizedBox(height: 4),
                  _bar(20, 1.5, _emeraldLt), const SizedBox(height: 4),
                  Text('Senior Product Designer', style: const TextStyle(fontSize: 6.5,
                      color: _emeraldLt, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.email_outlined, color: _emeraldLt, size: 8), const SizedBox(width: 3),
                    Text('alex.chen@email.com', style: const TextStyle(color: Colors.white60, fontSize: 5.5)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: _emeraldLt, size: 8), const SizedBox(width: 3),
                    Text('San Francisco, CA', style: const TextStyle(color: Colors.white60, fontSize: 5.5)),
                  ]),
                ])),
                const SizedBox(width: 10),
                Container(width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: _emeraldLt, width: 2), color: _emeraldM),
                  child: const Icon(Icons.person_rounded, color: Colors.white30, size: 22)),
              ])),
          ])),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _section('PROFESSIONAL SUMMARY'), const SizedBox(height: 5),
                Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _border)),
                  child: Column(children: [
                    _textLine(double.infinity, _muted.withOpacity(0.45)), const SizedBox(height: 2.5),
                    _textLine(140, _muted.withOpacity(0.4)), const SizedBox(height: 2.5),
                    _textLine(155, _muted.withOpacity(0.35)),
                  ])),
                const SizedBox(height: 8),
                _section('WORK EXPERIENCE'), const SizedBox(height: 6),
                ...[('Sr. Product Designer', 'Stripe', '2021–Present'),
                    ('Product Designer', 'Airbnb', '2018–2021'),
                    ('UX Designer', 'IDEO', '2016–2018')].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      _dot(5, _emeraldLt), _bar(1.5, 48, _border, r: 1),
                    ]),
                    const SizedBox(width: 6),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // FIXED
                      Row(children: [
                        Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        Text(e.$3, style: const TextStyle(fontSize: 5, color: _muted)),
                      ]),
                      Text(e.$2, style: const TextStyle(fontSize: 6, color: _emeraldM, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2.5),
                      _textLine(double.infinity, _muted.withOpacity(0.35)), const SizedBox(height: 2),
                      _textLine(130, _muted.withOpacity(0.3)), const SizedBox(height: 2),
                      _textLine(140, _muted.withOpacity(0.25)),
                    ])),
                  ]),
                )),
              ])),
              const SizedBox(width: 10),
              SizedBox(width: 66, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _section('SKILLS'), const SizedBox(height: 5),
                ...[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Sketch', 0.80)].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // FIXED
                    Row(children: [
                      Expanded(child: Text(s.$1, style: const TextStyle(fontSize: 5.5, color: _ink, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 2),
                      Text('${(s.$2 * 100).round()}%', style: const TextStyle(fontSize: 4.5, color: _muted)),
                    ]),
                    const SizedBox(height: 2),
                    ClipRRect(borderRadius: BorderRadius.circular(3),
                      child: Container(height: 4, color: _border,
                        child: FractionallySizedBox(alignment: Alignment.centerLeft,
                          widthFactor: s.$2,
                          child: Container(color: _emeraldLt)))),
                  ]),
                )),
                const SizedBox(height: 6),
                _section('EDUCATION'), const SizedBox(height: 5),
                ...[('BFA\nGraphic Design', 'RISD', '16'), ('Certificate\nHCI', 'Stanford', '19')].map((e) =>
                  Container(margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _border)),
                    child: Row(children: [
                      Container(width: 22, height: 22,
                        decoration: BoxDecoration(color: _emerald, borderRadius: BorderRadius.circular(5)),
                        child: Center(child: Text(e.$3,
                            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white)))),
                      const SizedBox(width: 5),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.$1, style: const TextStyle(fontSize: 5, fontWeight: FontWeight.w700, color: _ink, height: 1.2)),
                        Text(e.$2, style: const TextStyle(fontSize: 5, color: _muted)),
                      ])),
                    ]))),
              ])),
            ]),
          )),
        ])),
      ),
    );
  }
  Widget _section(String t) => Row(children: [
    _bar(2, 10, _emeraldLt), const SizedBox(width: 5),
    Text(t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800,
        color: _emerald, letterSpacing: 1.5)),
  ]);
}

class _DiagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.04)..strokeWidth = 18..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// T11 – Infographic
class MiniPreview11Infographic extends StatelessWidget {
  const MiniPreview11Infographic({super.key});
  static const _bg      = Color(0xFF1E293B);
  static const _surface = Color(0xFF253044);
  static const _cyan    = Color(0xFF06B6D4);
  static const _violet  = Color(0xFF8B5CF6);
  static const _orange  = Color(0xFFF59E0B);
  static const _muted   = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 260, height: 600,
        child: Container(
          color: _bg,
          child: Column(children: [
            _buildHeader(),
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14), height: 0.5,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [
                _cyan.withOpacity(0), _cyan, _violet, _cyan.withOpacity(0)])),
            ),
            const SizedBox(height: 8),
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildLeftCol(),
                const SizedBox(width: 10),
                Expanded(child: _buildRightCol()),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 46, height: 46,
            child: CustomPaint(painter: _RingPainter(0.82, _cyan))),
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _cyan.withOpacity(0.3), width: 1),
              color: _surface,
            ),
            child: const Icon(Icons.person_rounded, color: _cyan, size: 17)),
        ]),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: const TextSpan(children: [
            TextSpan(text: 'Alexandra ', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white,
                letterSpacing: -0.3, height: 1.1)),
            TextSpan(text: 'Chen', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: _cyan,
                letterSpacing: -0.3, height: 1.1)),
          ])),
          Text('Senior Product Designer',
              style: const TextStyle(fontSize: 5.5, color: _muted, letterSpacing: 0.5)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _pill(Icons.email_outlined, 'alex.chen@email.com'),
          _pill(Icons.phone_outlined, '+1 555 234 5678'),
          _pill(Icons.location_on_outlined, 'San Francisco'),
        ]),
      ]),
    );
  }

  Widget _buildLeftCol() {
    final skills = [
      ('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
      ('Prototyping', 0.88), ('Sketch', 0.80), ('Motion', 0.70),
    ];
    final edu = [
      ('BFA Graphic Design', 'RISD', '2016'),
      ('Certificate HCI', 'Stanford', '2019'),
    ];
    return SizedBox(
      width: 85,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoH('EXPERTISE', _cyan), const SizedBox(height: 5),
        for (final s in skills)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              SizedBox(width: 22, height: 22,
                child: CustomPaint(
                  painter: _RingPainter(s.$2, _cyan, bg: _surface),
                  child: Center(child: Text('${(s.$2 * 100).round()}',
                      style: const TextStyle(fontSize: 4.5,
                          fontWeight: FontWeight.w800, color: _cyan))))),
              const SizedBox(width: 7),
              Expanded(child: Text(s.$1, style: const TextStyle(
                  fontSize: 6, color: Colors.white, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ),
        const SizedBox(height: 6),
        _infoH('EDUCATION', _orange), const SizedBox(height: 5),
        for (final e in edu)
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(5),
              border: Border(left: BorderSide(color: _orange, width: 2.5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.$1, style: const TextStyle(
                  fontSize: 5.5, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(e.$2, style: const TextStyle(fontSize: 5, color: _muted)),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(e.$3, style: const TextStyle(
                    fontSize: 5, color: _orange, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _buildRightCol() {
    final exp = [
      ('Stripe', 'Sr. Product Designer', '2021–Present'),
      ('Airbnb', 'Product Designer', '2018–2021'),
      ('IDEO', 'UX Designer', '2016–2018'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _infoH('ABOUT', _cyan), const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _cyan.withOpacity(0.15)),
        ),
        child: Column(children: [
          _textLine(double.infinity, _muted.withOpacity(0.5)), const SizedBox(height: 2.5),
          _textLine(130, _muted.withOpacity(0.45)), const SizedBox(height: 2.5),
          _textLine(145, _muted.withOpacity(0.4)),
        ]),
      ),
      const SizedBox(height: 8),
      _infoH('EXPERIENCE', _violet), const SizedBox(height: 6),
      for (final e in exp)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(width: 7, height: 7,
                decoration: BoxDecoration(
                  color: _violet, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: _violet.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)],
                )),
              _bar(1.5, 42, _violet.withOpacity(0.2), r: 1),
            ]),
            const SizedBox(width: 6),
            Expanded(child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // FIXED
                Row(children: [
                  Expanded(child: Text(e.$1, style: const TextStyle(
                      fontSize: 6.5, fontWeight: FontWeight.w800, color: _cyan),
                      overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  Text(e.$3, style: const TextStyle(fontSize: 4.5, color: _muted)),
                ]),
                Text(e.$2, style: const TextStyle(
                    fontSize: 5.5, color: _muted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                _textLine(double.infinity, _muted.withOpacity(0.35)),
                const SizedBox(height: 2),
                _textLine(110, _muted.withOpacity(0.3)),
              ]),
            )),
          ]),
        ),
    ]);
  }

  Widget _pill(IconData icon, String t) => Container(
    margin: const EdgeInsets.only(bottom: 3),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cyan.withOpacity(0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 7, color: _cyan), const SizedBox(width: 3),
      Text(t, style: const TextStyle(fontSize: 5, color: _muted), overflow: TextOverflow.ellipsis),
    ]));
  Widget _infoH(String t, Color c) => Row(children: [
    _bar(2, 10, c, r: 1), const SizedBox(width: 5),
    Text(t, style: TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: c, letterSpacing: 1.5)),
  ]);
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;
  _RingPainter(this.progress, this.color, {this.bg = const Color(0xFF1E293B)});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1.5;
    canvas.drawCircle(c, r, Paint()..color = bg..strokeWidth = 2..style = PaintingStyle.stroke);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
        2 * math.pi * progress, false,
        Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(_) => false;
}

// T12 – Art Deco
class MiniPreview12ArtDeco extends StatelessWidget {
  const MiniPreview12ArtDeco({super.key});
  static const _bg        = Color(0xFFFBF8F1);
  static const _darkBrown = Color(0xFF1A1208);
  static const _gold      = Color(0xFFC8973A);
  static const _goldL     = Color(0xFFDEB96E);
  static const _goldPale  = Color(0xFFF5E6C8);
  static const _muted     = Color(0xFF6B5C3E);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth, alignment: Alignment.topLeft,
      child: SizedBox(width: 260, height: 600,
        child: Container(color: _bg, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _decoBand(), const SizedBox(height: 4), _decoBand(thin: true),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), child:
            Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _bar(20, 0.5, _gold), const SizedBox(width: 8),
                Transform.rotate(angle: math.pi / 4, child: _bar(8, 8, _gold, r: 0)),
                const SizedBox(width: 8), _bar(20, 0.5, _gold),
              ]),
              const SizedBox(height: 8),
              SizedBox(width: 52, height: 52, child: Stack(children: [
                Container(width: 52, height: 52,
                    decoration: BoxDecoration(border: Border.all(color: _gold, width: 1.5))),
                Padding(padding: const EdgeInsets.all(3),
                  child: Container(color: _darkBrown,
                    child: const Center(child: Text('AC', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w300, color: Color(0xFFC8973A), letterSpacing: 3))))),
                Positioned(left: 0, top: 0, child: Column(children: [_bar(8, 2, _gold), _bar(2, 8, _gold)])),
                Positioned(right: 0, bottom: 0, child: Column(mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end, children: [_bar(2, 8, _gold), _bar(8, 2, _gold)])),
              ])),
              const SizedBox(height: 7),
              Text('ALEXANDRA CHEN', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                  color: _darkBrown, letterSpacing: 4)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _bar(16, 0.5, _goldL), const SizedBox(width: 7),
                Text('SENIOR PRODUCT DESIGNER', style: const TextStyle(
                    fontSize: 5, color: _gold, letterSpacing: 2.5, fontWeight: FontWeight.w600)),
                const SizedBox(width: 7), _bar(16, 0.5, _goldL),
              ]),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('alex.chen@email.com', style: const TextStyle(fontSize: 5, color: _muted)),
                Text('   ·   ', style: const TextStyle(color: _gold, fontSize: 6)),
                Text('San Francisco', style: const TextStyle(fontSize: 5, color: _muted)),
              ]),
            ])),
          _decoBand(thin: true), const SizedBox(height: 3), _decoBand(), const SizedBox(height: 8),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 74, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _decoS('MASTERY'), const SizedBox(height: 5),
                ...[('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
                    ('Prototyping', 0.88), ('Sketch', 0.80)].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: const TextStyle(fontSize: 6, color: _darkBrown, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(children: List.generate(10, (i) => Container(
                      margin: const EdgeInsets.only(right: 1.2),
                      width: 4.5, height: 4,
                      color: i < (s.$2 * 10).round() ? _gold : _goldPale,
                    ))),
                  ]),
                )),
                const SizedBox(height: 5),
                _decoS('EDUCATION'), const SizedBox(height: 5),
                ...[('BFA Graphic Design', 'RISD', '2016'), ('Certificate HCI', 'Stanford', '2019')].map((e) =>
                  Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(border: Border.all(color: _goldL.withOpacity(0.5)),
                        color: _goldPale.withOpacity(0.3)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _darkBrown)),
                      Text(e.$2, style: const TextStyle(fontSize: 5.5, color: _muted)),
                      const SizedBox(height: 3),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        color: _gold,
                        child: Text(e.$3, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w900, color: Colors.white))),
                    ]))),
              ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Column(children: [
                _bar(7, 7, _gold, r: 0),
                _bar(1, 200, _goldL.withOpacity(0.4), r: 0),
                _bar(7, 7, _gold, r: 0),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _decoS('CAREER'), const SizedBox(height: 5),
                ...[('Sr. Product Designer', 'Stripe', '2021–Present'),
                    ('Product Designer', 'Airbnb', '2018–2021'),
                    ('UX Designer', 'IDEO', '2016–2018')].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Transform.rotate(angle: math.pi / 4, child: _bar(5, 5, _gold, r: 0)),
                      const SizedBox(width: 6),
                      // FIXED
                      Expanded(child: Row(children: [
                        Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: _darkBrown), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        Text(e.$3, style: const TextStyle(fontSize: 5, color: _gold, fontWeight: FontWeight.w600)),
                      ])),
                    ]),
                    Padding(padding: const EdgeInsets.only(left: 11), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _bar(1, 3, _goldL.withOpacity(0.5), r: 0),
                      Text(e.$2, style: const TextStyle(fontSize: 6, color: _gold, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2.5),
                      Row(children: [
                        Text(' ·   ', style: const TextStyle(fontSize: 5, color: _goldL)),
                        Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.4))),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text(' ·   ', style: const TextStyle(fontSize: 5, color: _goldL)),
                        Expanded(child: _textLine(double.infinity, _muted.withOpacity(0.35))),
                      ]),
                    ])),
                  ]),
                )),
              ])),
            ]),
          )),
          const SizedBox(height: 8),
          _decoBand(thin: true), const SizedBox(height: 3), _decoBand(), const SizedBox(height: 6),
        ])),
      ),
    );
  }
  Widget _decoBand({bool thin = false}) => _bar(double.infinity, thin ? 0.8 : 2.5, _gold, r: 0);
  Widget _decoS(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [_bar(8, 1.5, _gold), const SizedBox(width: 5),
      Text(t, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: _darkBrown, letterSpacing: 2)),
      const SizedBox(width: 5), Expanded(child: _bar(double.infinity, 0.5, _goldPale))]),
  ]);
}