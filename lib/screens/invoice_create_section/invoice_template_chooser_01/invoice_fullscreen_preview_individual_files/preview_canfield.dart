// cv_fullscreen_preview_individual_files/preview_canfield.dart
// Full-screen scrollable preview for Template 17 – Canfield B&W
// Matches MiniPreview17Canfield exactly

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
  ('Rhode Island School of Design', 'BFA Graphic Design', '2016'),
  ('Stanford University', 'Certificate – HCI', '2019'),
];
const _skills = [
  ('Figma',        0.95),
  ('Design Sys.',  0.90),
  ('Research',     0.85),
  ('Prototyping',  0.88),
  ('Sketch',       0.80),
  ('Motion Design',0.70),
];
const _langs = ['English (Native)', 'Mandarin (Fluent)', 'French (Basic)'];
const _certs = ['Google UX Design Certificate', 'Interaction Design Foundation'];
const _refs = [
  ('James Smith', 'Engineering Manager', 'Acme Corp', 'j.smith@acme.com', '+1 555 010 1234'),
  ('Sarah Lee',   'Design Director',     'Globex',    's.lee@globex.com',  '+1 555 020 5678'),
];

// Colours matching MiniPreview17Canfield exactly
const _black = Color(0xFF0A0A0A);
const _dark  = Color(0xFF1A1A1A);
const _muted = Color(0xFF666666);
const _rule  = Color(0xFFE8E8E8);
const _bg    = Color(0xFFFAFAFA);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Container(width: 4, height: 4,
          decoration: const BoxDecoration(
              color: _muted, shape: BoxShape.circle)),
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
          fontSize: 11, color: _black,
          fontWeight: FontWeight.w600))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: _muted)),
    ]),
    const SizedBox(height: 4),
    SizedBox(height: 3, child: Row(children: [
      Flexible(
        flex: (pct * 100).round(),
        child: const ColoredBox(color: _black, child: SizedBox.expand()),
      ),
      Flexible(
        flex: 100 - (pct * 100).round(),
        child: ColoredBox(color: _rule, child: const SizedBox.expand()),
      ),
    ])),
  ]),
);

// Section header: bold uppercase label + short black underline + hairline rule
Widget _sh(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w900,
        color: _black, letterSpacing: 2.5)),
    const SizedBox(height: 3),
    Container(width: 20, height: 1.5, color: _black),
    const SizedBox(height: 2),
    Container(height: 0.4, color: _rule),
  ]),
);

class PreviewCanfield extends StatelessWidget {
  const PreviewCanfield({super.key});

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
                  // ── Black header ───────────────────────────────────────
                  Container(
                    color: _black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    child: Row(children: [
                      // Square avatar (no circle)
                      Container(
                        width: 64, height: 64,
                        color: const Color(0xFF333333),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white38, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name.toUpperCase(), style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 2.5)),
                          const SizedBox(height: 6),
                          Text(_title.toUpperCase(), style: const TextStyle(
                              fontSize: 9.5, color: Colors.white54,
                              letterSpacing: 3, fontWeight: FontWeight.w500)),
                        ],
                      )),
                    ]),
                  ),

                  // ── Contact bar ────────────────────────────────────────
                  Container(
                    color: _dark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Row(children: [
                      _contactItem(Icons.circle, _email),
                      _contactItem(Icons.circle, _phone),
                      _contactItem(Icons.circle, _loc),
                      _contactItem(Icons.circle, _web),
                    ]),
                  ),

                  // ── Body ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Main left column ───────────────────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // PROFILE
                                _sh('PROFILE'),
                                Text(_summary, style: const TextStyle(
                                    fontSize: 12, color: _muted, height: 1.7)),
                                const SizedBox(height: 20),

                                // WORK EXPERIENCE
                                _sh('WORK EXPERIENCE'),
                                ..._exp.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(child: Text(e.$2,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: _black))),
                                        // Black date badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          color: _black,
                                          child: Text(e.$3,
                                              style: const TextStyle(
                                                  fontSize: 9.5,
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ),
                                      ]),
                                      const SizedBox(height: 2),
                                      Text(e.$1, style: const TextStyle(
                                          fontSize: 11.5, color: _muted,
                                          fontStyle: FontStyle.italic)),
                                      const SizedBox(height: 7),
                                      ...e.$4.map(_bullet),
                                      const SizedBox(height: 4),
                                      Container(height: 0.4, color: _rule),
                                    ],
                                  ),
                                )),

                                // EDUCATION
                                _sh('EDUCATION'),
                                ..._edu.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(e.$2, style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: _black)),
                                          Text(e.$1, style: const TextStyle(
                                              fontSize: 11.5, color: _muted,
                                              fontStyle: FontStyle.italic)),
                                        ],
                                      )),
                                      Text(e.$3, style: const TextStyle(
                                          fontSize: 10, color: _muted)),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),

                          // ── Hairline divider ───────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Container(width: 0.5, color: _rule),
                          ),

                          // ── Right sidebar ──────────────────────────────
                          SizedBox(
                            width: 128,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sh('SKILLS'),
                                ..._skills.map((s) =>
                                    _skillBar(s.$1, s.$2)),
                                const SizedBox(height: 14),
                                _sh('LANGUAGES'),
                                ..._langs.map((l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(children: [
                                    const Icon(Icons.translate,
                                        size: 11, color: _muted),
                                    const SizedBox(width: 6),
                                    Flexible(child: Text(l,
                                        style: const TextStyle(
                                            fontSize: 11, color: _muted))),
                                  ]),
                                )),
                                const SizedBox(height: 14),
                                _sh('CERTIFICATIONS'),
                                ..._certs.map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(c, style: const TextStyle(
                                      fontSize: 11, color: _muted,
                                      height: 1.4)),
                                )),
                                const SizedBox(height: 14),
                                _sh('REFERENCES'),
                                ..._refs.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.$1, style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: _black)),
                                      const SizedBox(height: 3),
                                      // Black date-badge style for role
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        color: _black,
                                        child: Text(r.$2,
                                            style: const TextStyle(
                                                fontSize: 8.5,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                      if (r.$3.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(r.$3, style: const TextStyle(
                                            fontSize: 10,
                                            color: _muted,
                                            fontStyle: FontStyle.italic)),
                                      ],
                                      const SizedBox(height: 5),
                                      Row(children: [
                                        const Icon(Icons.email_outlined,
                                            size: 10, color: _muted),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(r.$4,
                                            style: const TextStyle(
                                                fontSize: 9, color: _muted),
                                            overflow: TextOverflow.ellipsis)),
                                      ]),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 10, color: _muted),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(r.$5,
                                            style: const TextStyle(
                                                fontSize: 9, color: _muted),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactItem(IconData icon, String text) => Expanded(
    child: Row(children: [
      const Icon(Icons.circle, size: 5, color: Colors.white38),
      const SizedBox(width: 5),
      Expanded(child: Text(text, style: const TextStyle(
          fontSize: 10, color: Colors.white54),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}