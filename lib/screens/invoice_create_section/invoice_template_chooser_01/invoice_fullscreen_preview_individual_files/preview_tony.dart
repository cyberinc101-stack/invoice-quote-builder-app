// cv_fullscreen_preview_individual_files/preview_tony.dart
// Full-screen scrollable preview for Template 19 – Tony Dark Orange
// Matches MiniPreview19Tony exactly

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

// Colours matching MiniPreview19Tony exactly
const _bg      = Color(0xFF1E1E1E);
const _panel   = Color(0xFF272727);
const _orange  = Color(0xFFFF6D00);
const _muted   = Color(0xFFAAAAAA);
const _divider = Color(0xFF383838);

// Pre-computed alpha colours
const _orangeBorder50 = Color(0x80FF6D00);
const _orangeGlow20   = Color(0x33FF6D00);
const _orangeDate80   = Color(0xCCFF6D00);
const _blackRule15    = Color(0x26000000);
const _white10        = Color(0x1AFFFFFF);
const _white40        = Color(0x66FFFFFF);
const _white50        = Color(0x80FFFFFF);
const _white60        = Color(0x99FFFFFF);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Container(width: 5, height: 5,
          decoration: const BoxDecoration(
              color: _orange, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(t, style: const TextStyle(
        fontSize: 12, color: _muted, height: 1.5))),
  ]),
);

Widget _skillBar(String name, double pct) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(name, style: const TextStyle(
          fontSize: 11.5, color: _muted,
          fontWeight: FontWeight.w500))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: _orange)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(height: 5, child: Row(children: [
        Flexible(
          flex: (pct * 100).round(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFFF9E40), Color(0xFFFF6D00)]),
            ),
          ),
        ),
        Flexible(
          flex: 100 - (pct * 100).round(),
          child: const ColoredBox(color: _divider, child: SizedBox.expand()),
        ),
      ])),
    ),
  ]),
);

Widget _sectionHead(String t, {bool light = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 3, height: 16, color: _orange),
      const SizedBox(width: 6),
      Text(t, style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w800,
          color: _orange, letterSpacing: 2)),
    ]),
    const SizedBox(height: 3),
    Container(height: 0.4,
        color: light ? _blackRule15 : _divider),
  ]),
);

class PreviewTony extends StatelessWidget {
  const PreviewTony({super.key});

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
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // ── Header ──────────────────────────────────────────────
                Container(
                  color: _panel,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 18),
                  child: Row(children: [
                    Stack(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: _panel,
                          shape: BoxShape.circle,
                          border: Border.all(color: _orange, width: 2.5),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: _white40, size: 32),
                      ),
                      Positioned(bottom: 0, left: 0,
                        child: Container(
                            width: 18, height: 3, color: _orange)),
                    ]),
                    const SizedBox(width: 18),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text(_name, style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900,
                          color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(width: 14, height: 2, color: _orange),
                        const SizedBox(width: 6),
                        Text(_title, style: const TextStyle(
                            color: _orange, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                      ]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                      Text(_email, style: const TextStyle(
                          color: _white60, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(_phone, style: const TextStyle(
                          color: _white60, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(_loc, style: const TextStyle(
                          color: _white60, fontSize: 10)),
                    ]),
                  ]),
                ),

                // ── Body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Left – skills + languages + certifications + references
                      SizedBox(width: 148,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _sectionHead('PRO SKILLS'),
                          ..._skills.map((s) => _skillBar(s.$1, s.$2)),
                          const SizedBox(height: 14),
                          _sectionHead('LANGUAGES'),
                          ..._langs.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(children: [
                              Container(width: 5, height: 5,
                                  decoration: const BoxDecoration(
                                      color: _orange,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Flexible(child: Text(l, style: const TextStyle(
                                  fontSize: 11, color: _muted))),
                            ]),
                          )),
                          const SizedBox(height: 14),
                          _sectionHead('CERTIFICATIONS'),
                          ..._certs.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(c, style: const TextStyle(
                                fontSize: 11,
                                color: _white40,
                                height: 1.4)),
                          )),
                          const SizedBox(height: 14),
                          _sectionHead('REFERENCES'),
                          ..._refs.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _panel,
                                borderRadius: BorderRadius.circular(4),
                                border: const Border(
                                    left: BorderSide(
                                        color: _orange, width: 3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.$1, style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text(r.$2, style: const TextStyle(
                                      fontSize: 10,
                                      color: _orange,
                                      fontWeight: FontWeight.w600)),
                                  if (r.$3.isNotEmpty)
                                    Text(r.$3, style: const TextStyle(
                                        fontSize: 10, color: _muted)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.email_outlined,
                                        size: 10, color: _orange),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(r.$4,
                                        style: const TextStyle(
                                            fontSize: 9, color: _muted),
                                        overflow: TextOverflow.ellipsis)),
                                  ]),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 10, color: _orange),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(r.$5,
                                        style: const TextStyle(
                                            fontSize: 9, color: _muted),
                                        overflow: TextOverflow.ellipsis)),
                                  ]),
                                ],
                              ),
                            ),
                          )),
                        ]),
                      ),
                      const SizedBox(width: 18),

                      // Right – about + education + experience
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _sectionHead('ABOUT ME'),
                        const Text(_summary, style: TextStyle(
                            fontSize: 12, color: _muted, height: 1.7)),
                        const SizedBox(height: 18),

                        _sectionHead('EDUCATION'),
                        ..._edu.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _panel,
                              borderRadius: BorderRadius.circular(4),
                              border: const Border(
                                  left: BorderSide(
                                      color: _orange, width: 3)),
                            ),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                              Expanded(child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(e.$2, style: const TextStyle(
                                    color: Colors.white, fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                                Text(e.$1, style: const TextStyle(
                                    color: _muted, fontSize: 10.5)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _orangeGlow20,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(e.$3, style: const TextStyle(
                                    color: _orange, fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          ),
                        )),
                        const SizedBox(height: 4),

                        _sectionHead('EXPERIENCE'),
                        ..._exp.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(child: Text(e.$2, style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white))),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _orangeGlow20,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(e.$3, style: const TextStyle(
                                    color: _orange, fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                              ),
                            ]),
                            Text(e.$1, style: const TextStyle(
                                fontSize: 12, color: _orange,
                                fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            ...e.$4.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                const Text(' ·  ', style: TextStyle(
                                    color: _orange, fontSize: 11)),
                                Expanded(child: Text(b, style: const TextStyle(
                                    fontSize: 11, color: _muted,
                                    height: 1.5))),
                              ]),
                            )),
                          ]),
                        )),
                      ])),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}