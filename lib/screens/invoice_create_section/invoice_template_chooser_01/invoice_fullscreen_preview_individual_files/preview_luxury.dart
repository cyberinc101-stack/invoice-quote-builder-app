// cv_fullscreen_preview_individual_files/preview_luxury.dart
// Full-screen scrollable preview for Template 05 – Luxury
// Matches MiniPreview05Luxury exactly

import 'package:flutter/material.dart';

const _name    = 'Alexandra Chen';
const _title   = 'Senior Product Designer';
const _email   = 'alex.chen@email.com';
const _phone   = '+1 (555) 234-5678';
const _loc     = 'San Francisco, CA';
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

const _black    = Color(0xFF0A0A0A);
const _charcoal = Color(0xFF1C1C1C);
const _gold     = Color(0xFFBFA46A);
const _goldL    = Color(0xFFD4B97A);
const _cream    = Color(0xFFF5F0E8);
const _muted    = Color(0xFF8A8272);

const _goldRule     = Color(0x33BFA46A);
const _goldBorder40 = Color(0x66BFA46A);
const _goldBorder25 = Color(0x40BFA46A);
const _goldDivider  = Color(0x4DBFA46A);

Widget _gradBand() => Container(
  height: 4,
  decoration: const BoxDecoration(
    gradient: LinearGradient(colors: [
      Color(0xFF8A6B2E), Color(0xFFD4B97A), Color(0xFFBFA46A),
      Color(0xFFD4B97A), Color(0xFF8A6B2E),
    ]),
  ),
);

Widget _section(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 14, height: 0.5, color: _gold),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          t,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _gold,
              letterSpacing: 2.5),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]),
    Container(height: 0.3, color: _goldRule),
  ]),
);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(width: 4, height: 4,
          decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 12, color: _muted, height: 1.5))),
  ]),
);

Widget _skillBar(String name, double pct) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(name, style: const TextStyle(
          fontSize: 11, color: _cream, fontWeight: FontWeight.w500))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: _muted)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(height: 4, child: Row(children: [
        Flexible(flex: (pct * 100).round(),
            child: const ColoredBox(color: _goldL, child: SizedBox.expand())),
        Flexible(flex: 100 - (pct * 100).round(),
            child: const ColoredBox(color: _charcoal, child: SizedBox.expand())),
      ])),
    ),
  ]),
);

class PreviewLuxury extends StatelessWidget {
  const PreviewLuxury({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _black,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 480,
            child: ColoredBox(
              color: _black,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                _gradBand(),

                // ── Centred header ─────────────────────────────────────
                Container(
                  color: _charcoal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 28, height: 0.5, color: _gold),
                      const SizedBox(width: 8),
                      const Text(' ·    ·    · ',
                          style: TextStyle(fontSize: 8, color: _gold, letterSpacing: 4)),
                      const SizedBox(width: 8),
                      Container(width: 28, height: 0.5, color: _gold),
                    ]),
                    const SizedBox(height: 14),

                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _gold, width: 2),
                        color: _black,
                      ),
                      child: const Center(child: Text('AC', style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w300,
                          color: _gold, letterSpacing: 3))),
                    ),
                    const SizedBox(height: 12),

                    Text(_name.toUpperCase(), style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w300,
                        color: _cream, letterSpacing: 5, height: 1.0)),
                    const SizedBox(height: 8),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 20, height: 0.5, color: _gold),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(_title.toUpperCase(), style: const TextStyle(
                            fontSize: 9, color: _gold,
                            letterSpacing: 2.5, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 20, height: 0.5, color: _gold),
                    ]),
                    const SizedBox(height: 12),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(_email,
                            style: const TextStyle(fontSize: 10.5, color: _muted)),
                        const Text(' · ',
                            style: TextStyle(color: _gold, fontSize: 9)),
                        Text(_phone,
                            style: const TextStyle(fontSize: 10.5, color: _muted)),
                        const Text(' · ',
                            style: TextStyle(color: _gold, fontSize: 9)),
                        Text(_loc,
                            style: const TextStyle(fontSize: 10.5, color: _muted)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 28, height: 0.5, color: _gold),
                      const SizedBox(width: 8),
                      const Text(' ·    ·    · ',
                          style: TextStyle(fontSize: 8, color: _gold, letterSpacing: 4)),
                      const SizedBox(width: 8),
                      Container(width: 28, height: 0.5, color: _gold),
                    ]),
                  ]),
                ),

                Container(
                  height: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: _goldDivider,
                ),

                // ── Body ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  child: IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // ── Main column ──────────────────────────────────
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _section('EXECUTIVE SUMMARY'),
                            Text(_summary, style: const TextStyle(
                                fontSize: 12, color: _muted, height: 1.8)),
                            const SizedBox(height: 20),

                            _section('PROFESSIONAL EXPERIENCE'),
                            ..._exp.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text(e.$2,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _cream))),
                                    const SizedBox(width: 6),
                                    Text(e.$3, style: const TextStyle(
                                        fontSize: 10.5, color: _gold)),
                                  ],
                                ),
                                Text(e.$1, style: const TextStyle(
                                    fontSize: 12, color: _goldL,
                                    fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                ...e.$4.map(_bullet),
                              ]),
                            )),

                            _section('EDUCATION'),
                            ..._edu.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _goldBorder40),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(child: Text(e.$3,
                                        style: const TextStyle(
                                            fontSize: 11, color: _gold,
                                            fontWeight: FontWeight.w600))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(e.$2, style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: _cream)),
                                    Text(e.$1, style: const TextStyle(
                                        fontSize: 11.5, color: _muted)),
                                    Text(e.$4, style: const TextStyle(
                                        fontSize: 11, color: _gold,
                                        fontStyle: FontStyle.italic)),
                                  ])),
                                ],
                              ),
                            )),
                          ]),
                        ),
                      ),

                      // ── Side column ──────────────────────────────────
                      SizedBox(
                        width: 126,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _section('EXPERTISE'),
                          ..._skills.map((s) => _skillBar(s.$1, s.$2)),
                          const SizedBox(height: 14),

                          _section('LANGUAGES'),
                          ..._langs.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(children: [
                              Container(width: 4, height: 4,
                                  decoration: const BoxDecoration(
                                      color: _gold, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Flexible(child: Text(l, style: const TextStyle(
                                  fontSize: 11, color: _muted))),
                            ]),
                          )),
                          const SizedBox(height: 14),

                          _section('CERTIFICATIONS'),
                          ..._certs.map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              border: Border.all(color: _goldBorder25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(c, style: const TextStyle(
                                fontSize: 10.5, color: _muted, height: 1.4)),
                          )),
                          const SizedBox(height: 14),

                          // ── Personal References ────────────────────
                          _section('REFERENCES'),
                          ..._refs.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.$1, style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _cream)),
                                const SizedBox(height: 2),
                                Text(r.$2, style: const TextStyle(
                                    fontSize: 10.5,
                                    color: _gold,
                                    fontWeight: FontWeight.w500)),
                                if (r.$3.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(r.$3, style: const TextStyle(
                                      fontSize: 10, color: _muted)),
                                ],
                                const SizedBox(height: 5),
                                Row(children: [
                                  Container(width: 4, height: 4,
                                      decoration: const BoxDecoration(
                                          color: _gold,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(r.$4,
                                      style: const TextStyle(
                                          fontSize: 10, color: _muted),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1)),
                                ]),
                                const SizedBox(height: 3),
                                Row(children: [
                                  Container(width: 4, height: 4,
                                      decoration: const BoxDecoration(
                                          color: _gold,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(r.$5,
                                      style: const TextStyle(
                                          fontSize: 10, color: _muted),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1)),
                                ]),
                              ],
                            ),
                          )),
                        ]),
                      ),
                    ]),
                  ),
                ),

                _gradBand(),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}