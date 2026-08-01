// cv_fullscreen_preview_individual_files/preview_emerald.dart
// Full-screen scrollable preview for Template 10 – Emerald
// Layout mirrors MiniPreview10Emerald exactly.

import 'package:flutter/material.dart';

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
  ('Stripe', 'Senior Product Designer', '2021 – Present', [
    'Led redesign of core payment flows, increasing conversion by 23%',
    'Built and maintained a design system used by 40+ engineers',
    'Mentored 3 junior designers and ran weekly design critiques',
  ]),
  ('Airbnb', 'Product Designer', '2018 – 2021', [
    'Designed host onboarding experience for 2M+ new hosts',
    'Collaborated with research team on 12 user studies',
    'Launched new messaging platform with 98% satisfaction score',
  ]),
  ('IDEO', 'UX Designer', '2016 – 2018', [
    'Delivered human-centered solutions for healthcare & fintech clients',
    'Ran design sprints and stakeholder workshops across 6 countries',
  ]),
];
const _edu = [
  ('Rhode Island School of Design', 'BFA Graphic Design', '2016', 'Graduated with Honors'),
  ('Stanford University', 'Certificate – HCI', '2019', 'd.school'),
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

// Colours matched to MiniPreview10Emerald
const _forest  = Color(0xFF064E3B);
const _forestM = Color(0xFF065F46);
const _emerald = Color(0xFF10B981);
const _border  = Color(0xFFD1FAE5);
const _ink     = Color(0xFF1C1C1E);
const _muted   = Color(0xFF6B7280);
const _bg      = Color(0xFFF0FDF4);

Widget _bar(double w, double h, Color c, {double r = 2}) =>
    Container(width: w, height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

Widget _dot(double radius, Color c) =>
    Container(width: radius * 2, height: radius * 2,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));

Widget _sectionLabel(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(children: [
    _bar(3, 16, _emerald),
    const SizedBox(width: 8),
    Flexible(
      child: Text(t, style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w800,
          color: _forest, letterSpacing: 1.5),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ]),
);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(top: 7), child: _dot(3, _muted)),
    const SizedBox(width: 8),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 11.5, color: _muted, height: 1.5))),
  ]),
);

Widget _skillBar(String name, double pct) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(name, style: const TextStyle(
          fontSize: 11, color: _ink, fontWeight: FontWeight.w500))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: _muted)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 5,
        color: _border,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: pct,
          child: Container(color: _emerald),
        ),
      ),
    ),
  ]),
);

class _DiagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width; i += 36) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class PreviewEmerald extends StatelessWidget {
  const PreviewEmerald({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 480,
            child: ColoredBox(
              color: _bg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── HEADER: name/info LEFT, avatar RIGHT ────────────────
                  Container(
                    decoration: const BoxDecoration(color: _forest),
                    child: Stack(children: [
                      Positioned.fill(child: CustomPaint(painter: _DiagPainter())),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
                        child: Row(children: [
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(_name, style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5, height: 1.1)),
                            const SizedBox(height: 6),
                            _bar(28, 2, _emerald),
                            const SizedBox(height: 6),
                            Text(_title, style: const TextStyle(
                                fontSize: 12, color: _emerald,
                                fontWeight: FontWeight.w500)),
                            const SizedBox(height: 14),
                            Row(children: [
                              const Icon(Icons.email_outlined, color: _emerald, size: 13),
                              const SizedBox(width: 5),
                              Text(_email, style: const TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.phone_outlined, color: _emerald, size: 13),
                              const SizedBox(width: 5),
                              Text(_phone, style: const TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, color: _emerald, size: 13),
                              const SizedBox(width: 5),
                              Text(_loc, style: const TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                            ]),
                          ])),
                          const SizedBox(width: 24),
                          Container(
                            width: 86, height: 86,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _emerald, width: 2.5),
                                color: _forestM),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white30, size: 42),
                          ),
                        ]),
                      ),
                    ]),
                  ),

                  // Emerald gradient divider
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [_emerald, Color(0xFF34D399)]),
                    ),
                  ),

                  // ── BODY ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // LEFT: Summary + Experience
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('PROFESSIONAL SUMMARY'),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _border)),
                                child: Text(_summary, style: const TextStyle(
                                    fontSize: 11.5, color: _muted, height: 1.7)),
                              ),
                              const SizedBox(height: 22),

                              _sectionLabel('WORK EXPERIENCE'),
                              ..._exp.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(children: [
                                      _dot(9, _emerald),
                                      _bar(1.5, 80, _border, r: 1),
                                    ]),
                                    const SizedBox(width: 14),
                                    Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text(e.$2, style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _ink))),
                                          Text(e.$3, style: const TextStyle(
                                              fontSize: 10, color: _muted)),
                                        ],
                                      ),
                                      Text(e.$1, style: const TextStyle(
                                          fontSize: 11.5, color: _forestM,
                                          fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      ...e.$4.map(_bullet),
                                    ])),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // RIGHT sidebar: Skills + Education + Languages + Certs + References
                        SizedBox(
                          width: 148,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('SKILLS'),
                              ..._skills.map((s) => _skillBar(s.$1, s.$2)),

                              const SizedBox(height: 20),

                              _sectionLabel('EDUCATION'),
                              ..._edu.map((e) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _border)),
                                child: Row(children: [
                                  // Dark green year badge
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                        color: _forest,
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Center(child: Text(
                                        e.$3.substring(2),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white))),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Text(e.$2, style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: _ink, height: 1.2)),
                                    Text(e.$1, style: const TextStyle(
                                        fontSize: 10, color: _muted)),
                                    Text(e.$4, style: const TextStyle(
                                        fontSize: 9.5, color: _emerald,
                                        fontStyle: FontStyle.italic)),
                                  ])),
                                ]),
                              )),

                              const SizedBox(height: 8),

                              _sectionLabel('LANGUAGES'),
                              ..._langs.map((l) => Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Row(children: [
                                  _dot(5, _emerald),
                                  const SizedBox(width: 8),
                                  Flexible(child: Text(l, style: const TextStyle(
                                      fontSize: 11, color: _muted))),
                                ]),
                              )),

                              const SizedBox(height: 8),

                              _sectionLabel('CERTIFICATIONS'),
                              ..._certs.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _dot(4, _emerald)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(c, style: const TextStyle(
                                      fontSize: 11, color: _muted,
                                      height: 1.4))),
                                ]),
                              )),

                              const SizedBox(height: 8),

                              // References
                              _sectionLabel('REFERENCES'),
                              ..._refs.map((r) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _border)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.$1, style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _ink)),
                                    const SizedBox(height: 2),
                                    Text(r.$2, style: const TextStyle(
                                        fontSize: 10,
                                        color: _forestM,
                                        fontWeight: FontWeight.w600)),
                                    if (r.$3.isNotEmpty)
                                      Text(r.$3, style: const TextStyle(
                                          fontSize: 10, color: _muted)),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      const Icon(Icons.email_outlined,
                                          size: 10, color: _emerald),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(r.$4,
                                          style: const TextStyle(
                                              fontSize: 9.5, color: _muted),
                                          overflow: TextOverflow.ellipsis)),
                                    ]),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      const Icon(Icons.phone_outlined,
                                          size: 10, color: _emerald),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(r.$5,
                                          style: const TextStyle(
                                              fontSize: 9.5, color: _muted),
                                          overflow: TextOverflow.ellipsis)),
                                    ]),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}