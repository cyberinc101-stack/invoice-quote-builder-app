// cv_fullscreen_preview_individual_files/preview_rio.dart
// Full-screen scrollable preview for Template 14 – Rio Orange
// Matches MiniPreview14Rio exactly

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
  ('Sr. Product Designer', 'Stripe',  '2021 – Present', [
    'Led redesign of core payment flows, increasing conversion by 23%',
    'Built and maintained a design system used by 40+ engineers',
    'Mentored 3 junior designers and ran weekly design critiques',
  ]),
  ('Product Designer',    'Airbnb',  '2018 – 2021', [
    'Designed host onboarding experience for 2M+ new hosts',
    'Collaborated with research team on 12 user studies',
    'Launched new messaging platform with 98% satisfaction score',
  ]),
  ('UX Designer',         'IDEO',    '2016 – 2018', [
    'Delivered human-centered solutions for healthcare & fintech clients',
    'Ran design sprints and stakeholder workshops across 6 countries',
  ]),
];
const _edu = [
  ('BFA Graphic Design', 'Rhode Island School of Design', '2016'),
  ('Certificate – HCI',  'Stanford University',           '2019'),
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

// Colours matching MiniPreview14Rio exactly
const _dark   = Color(0xFF2B2B2B);
const _darker = Color(0xFF1E1E1E);
const _orange = Color(0xFFE8651A);
const _bg     = Color(0xFFF4F4F4);
const _ink    = Color(0xFF222222);
const _grey   = Color(0xFFAAAAAA);

// Pre-computed alphas
const _orangeBg10  = Color(0x1AE8651A);
const _orangeBdr30 = Color(0x4DE8651A);
const _ruleLine    = Color(0xFFDDDDDD);
const _white10     = Color(0x1AFFFFFF);

Widget _skillBar(String name, double pct) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(name, style: const TextStyle(color: _grey, fontSize: 11)),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(color: _orange, fontSize: 10)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(height: 4, child: Row(children: [
        Flexible(
          flex: (pct * 100).round(),
          child: const ColoredBox(color: _orange, child: SizedBox.expand()),
        ),
        Flexible(
          flex: 100 - (pct * 100).round(),
          child: const ColoredBox(color: _white10, child: SizedBox.expand()),
        ),
      ])),
    ),
  ]),
);

Widget _sideBlock(String t) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
  decoration: const BoxDecoration(
    color: _darker,
    border: Border(left: BorderSide(color: _orange, width: 3)),
  ),
  child: Text(t, style: const TextStyle(
      color: Colors.white, fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 1.5)),
);

Widget _contactRow(IconData icon, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(children: [
    Icon(icon, color: _orange, size: 13),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: const TextStyle(
        color: _grey, fontSize: 10.5), overflow: TextOverflow.ellipsis)),
  ]),
);

Widget _rightH(String t) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(children: [
      Container(width: 4, height: 16, color: _orange),
      const SizedBox(width: 8),
      Text(t, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: _ink, letterSpacing: 1.5)),
    ]),
    const SizedBox(height: 5),
    Container(height: 0.5, color: _ruleLine),
    const SizedBox(height: 10),
  ],
);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(width: 4, height: 4,
          decoration: const BoxDecoration(
              color: _orange, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 7),
    Expanded(child: Text(t, style: const TextStyle(
        fontSize: 11.5, color: Color(0xFF6B6B6B), height: 1.5))),
  ]),
);

class PreviewRio extends StatelessWidget {
  const PreviewRio({super.key});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Left dark sidebar ──────────────────────────────
                      Container(
                        width: 155,
                        color: _dark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Orange name block
                            Container(
                              width: double.infinity,
                              color: _orange,
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Alexandra', style: TextStyle(
                                      color: Colors.white, fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                                  Text('Chen', style: TextStyle(
                                      color: Colors.white70, fontSize: 15,
                                      fontWeight: FontWeight.w300)),
                                  SizedBox(height: 4),
                                  Text('Product Designer', style: TextStyle(
                                      color: Colors.white70, fontSize: 10)),
                                ],
                              ),
                            ),

                            // Circle avatar
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Container(
                                  width: 72, height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _orange, width: 2.5),
                                    color: const Color(0xFF3A3A3A),
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      color: Colors.white38, size: 34),
                                ),
                              ),
                            ),

                            // CONTACT block
                            _sideBlock('CONTACT'),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Column(children: [
                                _contactRow(Icons.email_outlined, _email),
                                _contactRow(Icons.phone_outlined, _phone),
                                _contactRow(Icons.location_on_outlined, _loc),
                              ]),
                            ),

                            // PRO SKILLS block
                            _sideBlock('PRO SKILLS'),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Column(
                                children: _skills
                                    .map((s) => _skillBar(s.$1, s.$2))
                                    .toList(),
                              ),
                            ),

                            // LANGUAGES block
                            _sideBlock('LANGUAGES'),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _langs.map((l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    Container(width: 5, height: 5,
                                        decoration: const BoxDecoration(
                                            color: _orange,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 7),
                                    Flexible(child: Text(l, style: const TextStyle(
                                        color: _grey, fontSize: 10.5))),
                                  ]),
                                )).toList(),
                              ),
                            ),

                            // CERTIFICATIONS block
                            _sideBlock('CERTIFICATIONS'),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _certs.map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(c, style: const TextStyle(
                                      color: _grey, fontSize: 10.5, height: 1.4)),
                                )).toList(),
                              ),
                            ),

                            // REFERENCES block
                            _sideBlock('REFERENCES'),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _refs.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.$1, style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(r.$2, style: const TextStyle(
                                          color: _orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                      if (r.$3.isNotEmpty)
                                        Text(r.$3, style: const TextStyle(
                                            color: _grey, fontSize: 10)),
                                      const SizedBox(height: 5),
                                      _contactRow(Icons.email_outlined, r.$4),
                                      _contactRow(Icons.phone_outlined, r.$5),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Right light column ─────────────────────────────
                      Expanded(
                        child: Container(
                          color: _bg,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // EXPERIENCE
                              _rightH('EXPERIENCE'),
                              ..._exp.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _orangeBg10,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: _orangeBdr30),
                                          ),
                                          child: Text(e.$3, style: const TextStyle(
                                              color: _orange, fontSize: 9.5,
                                              fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(e.$1, style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _ink)),
                                            Text(e.$2, style: const TextStyle(
                                                fontSize: 11.5, color: _orange,
                                                fontWeight: FontWeight.w500)),
                                          ],
                                        )),
                                      ],
                                    ),
                                    const SizedBox(height: 7),
                                    ...e.$4.map(_bullet),
                                    const SizedBox(height: 4),
                                    Container(height: 0.5, color: _ruleLine),
                                  ],
                                ),
                              )),

                              // EDUCATION
                              _rightH('EDUCATION'),
                              ..._edu.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _orangeBg10,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _orangeBdr30),
                                      ),
                                      child: Text(e.$3, style: const TextStyle(
                                          color: _orange, fontSize: 9.5,
                                          fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.$1, style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: _ink)),
                                        Text(e.$2, style: const TextStyle(
                                            fontSize: 11, color: _orange)),
                                      ],
                                    )),
                                  ],
                                ),
                              )),
                            ],
                          ),
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
    );
  }
}