// cv_fullscreen_preview_individual_files/preview_fashion.dart
// Full-screen scrollable preview for Template 20 – Blueprint
// Technical drawing aesthetic: white paper, cobalt ink, grid dots, precise geometry

import 'package:flutter/material.dart';
import 'dart:math' as math;

const _name    = 'Alexandra Chen';
const _title   = 'Senior Product Designer';
const _email   = 'alex.chen@email.com';
const _phone   = '+1 (555) 234-5678';
const _loc     = 'San Francisco, CA';
const _web     = 'alexchen.design';
const _summary =
    'Passionate product designer with 8+ years crafting user-centered '
    'experiences for Fortune 500 companies. Expert in design systems, '
    'prototyping, and cross-functional collaboration. Committed to shipping '
    'products that balance business goals with genuine human needs.';

const _exp = [
  ('Stripe', 'Senior Product Designer', '2021 - Present', [
    'Led redesign of core payment flows, increasing conversion by 23%',
    'Built and maintained a design system used by 40+ engineers',
    'Mentored 3 junior designers and ran weekly design critiques',
  ]),
  ('Airbnb', 'Product Designer', '2018 - 2021', [
    'Designed host onboarding experience for 2M+ new hosts',
    'Collaborated with research team on 12 user studies',
    'Launched new messaging platform with 98% satisfaction score',
  ]),
  ('IDEO', 'UX Designer', '2016 - 2018', [
    'Delivered human-centered solutions for healthcare & fintech clients',
    'Ran design sprints and stakeholder workshops across 6 countries',
  ]),
];
const _edu = [
  ('Rhode Island School of Design', 'BFA Graphic Design', '2016', 'Graduated with Honors'),
  ('Stanford University', 'Certificate - HCI', '2019', 'd.school'),
];
const _skills = [
  ('Figma', 0.95), ('Design Systems', 0.90), ('User Research', 0.85),
  ('Prototyping', 0.88), ('Sketch', 0.80), ('Motion Design', 0.70),
];
const _langs = ['English (Native)', 'Mandarin (Fluent)', 'French (Basic)'];
const _certs = ['Google UX Design Certificate', 'Interaction Design Foundation'];
const _refs = [
  ('James Smith', 'Engineering Manager', 'Acme Corp', 'j.smith@acme.com', '+1 555 010 1234'),
  ('Sarah Lee',   'Design Director',     'Globex',    's.lee@globex.com',  '+1 555 020 5678'),
];

// Blueprint palette
const _paper    = Color(0xFFFFFFFF);
const _cobalt   = Color(0xFF1A3A6B);
const _cobaltM  = Color(0xFF2555A0);
const _cobaltL  = Color(0xFF4A7FD4);
const _gridDot  = Color(0xFFDDE6F4);
const _rule     = Color(0xFFBDD0EA);
const _ink      = Color(0xFF0D2040);
const _muted    = Color(0xFF5C7499);

// Grid dot background painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _gridDot..strokeWidth = 1.5..style = PaintingStyle.fill;
    const spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// Corner bracket decorator
class _CornerBrackets extends StatelessWidget {
  final Widget child;
  final Color color;
  final double size;
  final double thickness;
  const _CornerBrackets({
    required this.child,
    this.color = _cobalt,
    this.size = 14,
    this.thickness = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      Positioned(top: 0, left: 0,    child: _bracket(false, false)),
      Positioned(top: 0, right: 0,   child: _bracket(false, true)),
      Positioned(bottom: 0, left: 0, child: _bracket(true,  false)),
      Positioned(bottom: 0, right: 0, child: _bracket(true, true)),
    ]);
  }

  Widget _bracket(bool flipV, bool flipH) => Transform.scale(
    scaleX: flipH ? -1 : 1,
    scaleY: flipV ? -1 : 1,
    child: SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _BracketPainter(color, thickness)),
    ),
  );
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double thickness;
  const _BracketPainter(this.color, this.thickness);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.6, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height * 0.6), paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

// Section heading
Widget _sectionHead(String label) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(children: [
    Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: _cobalt, width: 1.5),
        color: _cobalt,
      ),
      child: Center(
        child: Text(
          label.substring(0, 1),
          style: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w900,
            color: Colors.white, fontFamily: 'monospace',
          ),
        ),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9, fontWeight: FontWeight.w800,
          color: _cobalt, letterSpacing: 3,
          fontFamily: 'monospace',
        ),
      ),
      Container(height: 1, color: _rule),
    ])),
  ]),
);

Widget _skillBar(String name, double pct) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
        child: Text(name, style: const TextStyle(
            fontSize: 11, color: _ink, fontWeight: FontWeight.w500,
            fontFamily: 'monospace')),
      ),
      const SizedBox(width: 4),
      Text('${(pct * 100).round()}%', style: const TextStyle(
          fontSize: 9.5, color: _cobaltL, fontFamily: 'monospace',
          fontWeight: FontWeight.w700)),
    ]),
    const SizedBox(height: 4),
    Stack(children: [
      Container(height: 4, decoration: const BoxDecoration(color: _gridDot)),
      FractionallySizedBox(
        widthFactor: pct,
        child: Container(
          height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_cobaltL, _cobalt]),
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(11, (i) => Container(
          width: 1, height: i % 5 == 0 ? 8 : 4,
          color: _rule,
        )),
      ),
    ]),
  ]),
);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Container(width: 6, height: 1, color: _cobaltL),
        Container(width: 4, height: 4, decoration: BoxDecoration(
          border: Border.all(color: _cobaltL, width: 1),
          shape: BoxShape.rectangle,
        )),
      ]),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(t, style: const TextStyle(fontSize: 12, color: _muted, height: 1.5))),
  ]),
);

Widget _coord(String t) => Text(
  t,
  style: const TextStyle(
      fontSize: 9, color: _cobaltL, fontFamily: 'monospace', letterSpacing: 0.5),
);

class PreviewFashion extends StatelessWidget {
  const PreviewFashion({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _paper,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 480,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                // HEADER
                Container(
                  decoration: BoxDecoration(
                    color: _cobalt,
                    border: Border.all(color: _cobaltL.withOpacity(0.3), width: 1),
                  ),
                  child: Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: _DiagLinePainter())),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 30, 32, 26),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _CornerBrackets(
                          color: _cobaltL,
                          size: 18,
                          thickness: 2.5,
                          child: Container(
                            width: 80, height: 80,
                            color: _cobaltM,
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white24, size: 44),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _coord('// IDENTITY'),
                          const SizedBox(height: 6),
                          Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 1, height: 1.0,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(width: 32, height: 2, color: _cobaltL),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _title.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10, color: _cobaltL,
                                  letterSpacing: 2.5, fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          Wrap(spacing: 18, runSpacing: 6, children: [
                            _headerMeta(Icons.alternate_email, _email),
                            _headerMeta(Icons.phone_outlined, _phone),
                            _headerMeta(Icons.location_on_outlined, _loc),
                            _headerMeta(Icons.language_outlined, _web),
                          ]),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          _coord('REF: AC-2024'),
                          const SizedBox(height: 4),
                          _coord('SCALE: 1:1'),
                          const SizedBox(height: 4),
                          _coord('REV: 08'),
                        ]),
                      ]),
                    ),
                  ]),
                ),

                // TITLE BLOCK
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: _gridDot,
                    border: Border(
                      bottom: BorderSide(color: _rule, width: 1),
                      top: BorderSide(color: _cobalt.withOpacity(0.3), width: 1),
                    ),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 32),
                    for (final item in [
                      ('DESIGNED BY', _name),
                      ('DISCIPLINE', 'PRODUCT DESIGN'),
                      ('YEARS EXP.', '8+'),
                      ('STATUS', 'AVAILABLE'),
                    ]) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(children: [
                            Flexible(
                              child: Text(
                                '${item.$1}: ',
                                style: const TextStyle(
                                    fontSize: 8, color: _muted,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                item.$2,
                                style: const TextStyle(
                                    fontSize: 8, color: _cobalt,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      Container(width: 1, height: 28, color: _rule),
                    ],
                  ]),
                ),

                // BODY
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 26, 32, 32),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Left column – profile + experience + education
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                      _sectionHead('PROFILE'),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: _rule),
                          color: Colors.white,
                        ),
                        child: Stack(children: [
                          Positioned(top: 0, right: 0, child: _coord('S 01')),
                          Text(_summary, style: const TextStyle(
                              fontSize: 12, color: _muted, height: 1.7)),
                        ]),
                      ),
                      const SizedBox(height: 22),

                      _sectionHead('EXPERIENCE'),
                      ..._exp.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: IntrinsicHeight(
                          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Column(children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                  color: _cobalt,
                                  border: Border.all(color: _cobaltL, width: 1.5),
                                ),
                              ),
                              Expanded(child: Container(width: 1.5, color: _rule)),
                            ]),
                            const SizedBox(width: 14),
                            Expanded(child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: _rule),
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Expanded(child: Text(e.$2, style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: _ink))),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _cobalt),
                                      color: _gridDot,
                                    ),
                                    child: Text(e.$3, style: const TextStyle(
                                        fontSize: 9, color: _cobalt,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w700)),
                                  ),
                                ]),
                                const SizedBox(height: 3),
                                Row(children: [
                                  Container(width: 10, height: 1.5, color: _cobaltL),
                                  const SizedBox(width: 5),
                                  Text(e.$1, style: const TextStyle(
                                      fontSize: 11, color: _cobaltM,
                                      fontWeight: FontWeight.w600)),
                                ]),
                                const SizedBox(height: 8),
                                ...e.$4.map(_bullet),
                              ]),
                            )),
                          ]),
                        ),
                      )),

                      _sectionHead('EDUCATION'),
                      ..._edu.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              left: const BorderSide(color: _cobalt, width: 3),
                              top: BorderSide(color: _rule),
                              right: BorderSide(color: _rule),
                              bottom: BorderSide(color: _rule),
                            ),
                          ),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                border: Border.all(color: _cobalt, width: 1.5),
                                color: _gridDot,
                              ),
                              child: Center(child: Text(
                                e.$3,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w900,
                                    color: _cobalt, fontFamily: 'monospace'),
                              )),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(e.$2, style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: _ink)),
                              Text(e.$1, style: const TextStyle(
                                  fontSize: 11, color: _muted)),
                              Text(e.$4, style: const TextStyle(
                                  fontSize: 10, color: _cobaltL,
                                  fontStyle: FontStyle.italic)),
                            ])),
                          ]),
                        ),
                      )),
                    ])),

                    // Vertical rule
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(children: [
                        _coord('T'),
                        Container(width: 1, height: 800, color: _rule),
                        _coord('B'),
                      ]),
                    ),

                    // Right column – skills + languages + certs + references
                    SizedBox(width: 136, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                      _sectionHead('SKILLS'),
                      ..._skills.map((s) => _skillBar(s.$1, s.$2)),
                      const SizedBox(height: 14),

                      _sectionHead('LANGUAGES'),
                      ..._langs.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              border: Border.all(color: _cobalt, width: 1.5),
                              color: _cobalt,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: Text(l, style: const TextStyle(
                              fontSize: 11, color: _ink, height: 1.4))),
                        ]),
                      )),
                      const SizedBox(height: 14),

                      _sectionHead('CERTIFICATIONS'),
                      ..._certs.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(width: 5, height: 5, color: _cobaltL),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c, style: const TextStyle(
                              fontSize: 11, color: _ink, height: 1.4))),
                        ]),
                      )),
                      const SizedBox(height: 14),

                      // REFERENCES
                      _sectionHead('REFERENCES'),
                      ..._refs.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              left: const BorderSide(color: _cobalt, width: 3),
                              top: BorderSide(color: _rule),
                              right: BorderSide(color: _rule),
                              bottom: BorderSide(color: _rule),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1, style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                  fontFamily: 'monospace')),
                              const SizedBox(height: 2),
                              // Blueprint-style role badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _cobalt),
                                  color: _gridDot,
                                ),
                                child: Text(r.$2, style: const TextStyle(
                                    fontSize: 8.5, color: _cobalt,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700)),
                              ),
                              if (r.$3.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(r.$3, style: const TextStyle(
                                    fontSize: 9.5, color: _muted)),
                              ],
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.email_outlined,
                                    size: 10, color: _cobaltL),
                                const SizedBox(width: 4),
                                Expanded(child: Text(r.$4,
                                    style: const TextStyle(
                                        fontSize: 9, color: _muted,
                                        fontFamily: 'monospace'),
                                    overflow: TextOverflow.ellipsis)),
                              ]),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.phone_outlined,
                                    size: 10, color: _cobaltL),
                                const SizedBox(width: 4),
                                Expanded(child: Text(r.$5,
                                    style: const TextStyle(
                                        fontSize: 9, color: _muted,
                                        fontFamily: 'monospace'),
                                    overflow: TextOverflow.ellipsis)),
                              ]),
                            ],
                          ),
                        ),
                      )),
                    ])),
                  ]),
                ),

                // FOOTER TITLE BLOCK
                Container(
                  height: 24,
                  color: _cobalt,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    _coord2('CURRICULUM VITAE'),
                    _coord2('ALEXANDRA CHEN  PRODUCT DESIGNER'),
                    _coord2('SHEET 1 OF 1'),
                  ]),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _headerMeta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _cobaltL, size: 11),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
    ],
  );

  Widget _coord2(String t) => Text(
    t,
    style: const TextStyle(
        fontSize: 8, color: _cobaltL, fontFamily: 'monospace', letterSpacing: 1),
  );
}

class _DiagLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width + size.height; i += 36) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}