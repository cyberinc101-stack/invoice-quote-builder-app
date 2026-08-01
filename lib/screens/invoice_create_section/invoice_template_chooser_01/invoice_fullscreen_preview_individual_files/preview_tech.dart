// cv_fullscreen_preview_individual_files/preview_tech.dart
// Full-screen scrollable preview for Template 04 – Tech Dark
// Matches MiniPreview04TechDark exactly

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

// Colours matching MiniPreview04TechDark exactly
const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border  = Color(0xFF30363D);
const _green   = Color(0xFF3FB950);
const _blue    = Color(0xFF58A6FF);
const _yellow  = Color(0xFFE3B341);
const _white   = Color(0xFFE6EDF3);
const _muted   = Color(0xFF8B949E);

// Pre-computed alpha colour – replaces withOpacity()
const _greenBorder50 = Color(0x803FB950);  // _green 50%

Widget _mono(String t, Color c, {double size = 12, FontWeight? weight}) =>
    Text(t, style: TextStyle(
        fontFamily: 'monospace', fontSize: size, color: c,
        fontWeight: weight ?? FontWeight.normal));

Widget _trafficDot(Color c) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle));

Widget _card({required Widget child, EdgeInsets? padding}) => Container(
  margin: const EdgeInsets.only(bottom: 10),
  padding: padding ?? const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: _border, width: 0.8),
  ),
  child: child,
);

class PreviewTech extends StatelessWidget {
  const PreviewTech({super.key});

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
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // ── Sidebar ────────────────────────────────────────────
                  Container(
                    width: 160,
                    decoration: const BoxDecoration(
                      color: _surface,
                      border: Border(
                          right: BorderSide(color: _border)),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Traffic lights
                      Row(children: [
                        _trafficDot(const Color(0xFFFF5F57)),
                        const SizedBox(width: 5),
                        _trafficDot(const Color(0xFFFFBD2E)),
                        const SizedBox(width: 5),
                        _trafficDot(const Color(0xFF27C840)),
                      ]),
                      const SizedBox(height: 14),
                      Center(child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _green, width: 2),
                          color: _bg,
                        ),
                        child: const Icon(Icons.terminal,
                            color: _green, size: 30),
                      )),
                      const SizedBox(height: 14),
                      _mono('// CONTACT', _yellow, weight: FontWeight.w700),
                      const SizedBox(height: 8),
                      ...[
                        ('email', _email),
                        ('phone', _phone),
                        ('loc',   _loc),
                        ('web',   _web),
                      ].map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _mono('${c.$1}: ', _blue, size: 10),
                          Expanded(child: _mono(c.$2, _muted, size: 10)),
                        ]),
                      )),
                      const SizedBox(height: 14),
                      _mono('// SKILLS', _yellow, weight: FontWeight.w700),
                      const SizedBox(height: 8),
                      ..._skills.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Expanded(child: _mono(s.$1, _white, size: 11)),
                            _mono('${(s.$2 * 100).round()}%',
                                _green, size: 10),
                          ]),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(height: 3, child: Row(children: [
                              Flexible(
                                flex: (s.$2 * 100).round(),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [_green, _blue]),
                                  ),
                                ),
                              ),
                              Flexible(
                                flex: 100 - (s.$2 * 100).round(),
                                child: const ColoredBox(
                                    color: _border,
                                    child: SizedBox.expand()),
                              ),
                            ])),
                          ),
                        ]),
                      )),
                      const SizedBox(height: 10),
                      _mono('// LANGUAGES', _yellow, weight: FontWeight.w700),
                      const SizedBox(height: 8),
                      ..._langs.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(children: [
                          _mono('> ', _green, size: 11),
                          Expanded(child: _mono(l, _muted, size: 10.5)),
                        ]),
                      )),
                      const SizedBox(height: 10),
                      _mono('// CERTIFICATIONS', _yellow,
                          weight: FontWeight.w700),
                      const SizedBox(height: 8),
                      ..._certs.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _mono('# ', _blue, size: 11),
                          Expanded(child: _mono(c, _muted, size: 10)),
                        ]),
                      )),
                      const SizedBox(height: 10),
                      // ── Personal References ──────────────────────────
                      _mono('// REFERENCES', _yellow, weight: FontWeight.w700),
                      const SizedBox(height: 8),
                      ..._refs.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _mono(r.$1, _white, size: 10.5,
                                weight: FontWeight.w700),
                            const SizedBox(height: 2),
                            _mono(r.$2, _green, size: 10),
                            if (r.$3.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              _mono(r.$3, _muted, size: 10),
                            ],
                            const SizedBox(height: 4),
                            Row(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _mono('@ ', _blue, size: 10),
                              Expanded(child: _mono(r.$4, _muted, size: 9.5)),
                            ]),
                            const SizedBox(height: 2),
                            Row(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _mono('# ', _blue, size: 10),
                              Expanded(child: _mono(r.$5, _muted, size: 9.5)),
                            ]),
                          ],
                        ),
                      )),
                    ]),
                  ),

                  // ── Main ──────────────────────────────────────────────
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // whoami card
                      _card(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _mono(r'$ whoami', _green, size: 11),
                          const SizedBox(height: 4),
                          _mono(_name, _blue, size: 20,
                              weight: FontWeight.w700),
                          _mono(_title, _yellow, size: 12),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      _mono('// SUMMARY', _yellow, weight: FontWeight.w700),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6),
                              bottomRight: Radius.circular(6)),
                          border: Border(
                              left: BorderSide(color: _green, width: 3)),
                        ),
                        child: Text(_summary, style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 11,
                            color: _muted, height: 1.6)),
                      ),
                      _mono('// EXPERIENCE', _yellow,
                          weight: FontWeight.w700),
                      const SizedBox(height: 8),
                      ..._exp.map((e) => _card(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Expanded(child: _mono(e.$1, _blue, size: 13,
                                weight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            _mono(e.$3, _muted, size: 10),
                          ]),
                          _mono(e.$2, _green, size: 11),
                          const SizedBox(height: 6),
                          ...e.$4.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _mono('- ', _green, size: 12),
                              Expanded(child: Text(b, style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 11,
                                  color: _muted, height: 1.5))),
                            ]),
                          )),
                        ]),
                      )),
                      const SizedBox(height: 4),
                      _mono('// EDUCATION', _yellow, weight: FontWeight.w700),
                      const SizedBox(height: 8),
                      ..._edu.map((e) => _card(
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _greenBorder50),
                            ),
                            child: Center(child: Text(e.$3,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9, color: _green,
                                    fontWeight: FontWeight.w700))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _mono(e.$2, _white, size: 11,
                                weight: FontWeight.w700),
                            _mono(e.$1, _muted, size: 10),
                            _mono(e.$4, _green, size: 10),
                          ])),
                        ]),
                      )),
                    ]),
                  )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}