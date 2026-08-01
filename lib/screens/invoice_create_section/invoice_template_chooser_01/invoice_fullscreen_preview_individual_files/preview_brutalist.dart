// cv_fullscreen_preview_individual_files/preview_brutalist.dart
// Full-screen scrollable preview for Template 09 – Brutalist
// Matches MiniPreview09Brutalist exactly

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
  ('Figma', 0.95), ('Design Systems', 0.90), ('User Research', 0.85),
  ('Prototyping', 0.88), ('Sketch', 0.80), ('Motion Design', 0.70),
];
const _langs = ['English', 'Mandarin', 'French'];
const _certs = ['Google UX Design Certificate', 'Interaction Design Foundation'];
const _refs = [
  ('James Smith', 'Engineering Manager', 'Acme Corp', 'j.smith@acme.com', '+1 555 010 1234'),
  ('Sarah Lee',   'Design Director',     'Globex',    's.lee@globex.com',  '+1 555 020 5678'),
];

const _black  = Color(0xFF000000);
const _yellow = Color(0xFFFFE500);
const _white  = Color(0xFFFFFFFF);
const _grey   = Color(0xFFF5F5F5);
const _muted  = Color(0xFF444444);
const _border = Color(0xFFD0D0D0);

// Bordered section header (main column style)
Widget _brutalHeader(String t) => Container(
  margin: const EdgeInsets.only(bottom: 14),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(border: Border.all(color: _black, width: 2)),
  child: Text(t, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w900,
      letterSpacing: 2.5, color: _black)),
);

// Solid black sidebar section header
Widget _sideHeader(String t) => Container(
  width: double.infinity,
  color: _black,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  margin: const EdgeInsets.only(bottom: 10),
  child: Text(t, style: const TextStyle(
      fontSize: 10, fontWeight: FontWeight.w900,
      color: _white, letterSpacing: 1.5)),
);

// Bullet for experience
Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('/  ', style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w900, color: _black)),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 12, color: _muted, height: 1.5))),
  ]),
);

class PreviewBrutalist extends StatelessWidget {
  const PreviewBrutalist({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 480,
            child: ColoredBox(
              color: _white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Black header with yellow AC avatar ─────────────────
                  Container(
                    color: _black,
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      // Yellow avatar square
                      Container(
                        width: 64, height: 64,
                        color: _yellow,
                        child: const Center(
                          child: Text('AC', style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: _black)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name.toUpperCase(), style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900,
                                color: _white, letterSpacing: 0.5, height: 1.1)),
                            const SizedBox(height: 6),
                            // Yellow badge for title
                            Container(
                              color: _yellow,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              child: Text(_title.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.w900,
                                      color: _black, letterSpacing: 1.2)),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),

                  // ── Contact bar with black dividers ────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      border: Border.symmetric(
                          horizontal: BorderSide(color: _black, width: 2)),
                    ),
                    child: Row(children: [
                      _contactCell(_email, flex: 3),
                      Container(width: 2, color: _black),
                      _contactCell(_phone, flex: 2),
                      Container(width: 2, color: _black),
                      _contactCell(_loc, flex: 2),
                      Container(width: 2, color: _black),
                      _contactCell(_web, flex: 2),
                    ]),
                  ),

                  // ── Two-column body ─────────────────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Left sidebar ──────────────────────────────────
                        Container(
                          width: 150,
                          decoration: const BoxDecoration(
                            border: Border(
                                right: BorderSide(color: _black, width: 2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Skills
                              _sideHeader('SKILLS'),
                              ..._skills.map((s) => Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFE0E0E0),
                                          width: 0.5)),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s.$1, style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _black)),
                                    Text('${(s.$2 * 100).round()}%',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: _black)),
                                  ],
                                ),
                              )),

                              const SizedBox(height: 8),

                              // Education
                              _sideHeader('EDUCATION'),
                              ..._edu.map((e) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 0, 12, 14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(e.$2, style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _black)),
                                    Text(e.$1, style: const TextStyle(
                                        fontSize: 10.5, color: _muted)),
                                    const SizedBox(height: 4),
                                    Container(
                                      color: _yellow,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      child: Text(e.$3,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: _black)),
                                    ),
                                  ],
                                ),
                              )),

                              const SizedBox(height: 8),

                              // Languages
                              _sideHeader('LANGUAGES'),
                              ..._langs.map((l) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 0, 12, 8),
                                child: Text(l, style: const TextStyle(
                                    fontSize: 11.5, color: _muted)),
                              )),

                              const SizedBox(height: 8),

                              // Certifications
                              _sideHeader('CERTIFICATIONS'),
                              ..._certs.map((c) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 0, 12, 8),
                                child: Text(c, style: const TextStyle(
                                    fontSize: 11, color: _muted,
                                    height: 1.4)),
                              )),

                              const SizedBox(height: 8),

                              // References
                              _sideHeader('REFERENCES'),
                              ..._refs.map((r) => Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.$1, style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _black)),
                                    // Yellow accent bar under name
                                    Container(
                                      width: 20, height: 2,
                                      color: _yellow,
                                      margin: const EdgeInsets.symmetric(vertical: 3),
                                    ),
                                    Text(r.$2, style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _muted)),
                                    if (r.$3.isNotEmpty)
                                      Text(r.$3, style: const TextStyle(
                                          fontSize: 10, color: _muted)),
                                    const SizedBox(height: 5),
                                    Row(children: [
                                      const Icon(Icons.email_outlined,
                                          size: 10, color: _black),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(r.$4,
                                          style: const TextStyle(
                                              fontSize: 9, color: _muted),
                                          overflow: TextOverflow.ellipsis)),
                                    ]),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      const Icon(Icons.phone_outlined,
                                          size: 10, color: _black),
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

                        // ── Main right column ─────────────────────────────
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile
                                _brutalHeader('PROFILE'),
                                Text(_summary, style: const TextStyle(
                                    fontSize: 12, color: _muted,
                                    height: 1.7)),
                                const SizedBox(height: 18),

                                // Experience
                                _brutalHeader('EXPERIENCE'),
                                ..._exp.map((e) => Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _border),
                                  ),
                                  child: Column(children: [
                                    // Grey card header
                                    Container(
                                      color: _grey,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(e.$2,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: _black)),
                                              Text(e.$1,
                                                  style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: _muted,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
                                          // Yellow date badge
                                          Container(
                                            color: _yellow,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                            child: Text(e.$3,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                    color: _black)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Bullet points
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: e.$4.map(_bullet).toList(),
                                      ),
                                    ),
                                  ]),
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
      ),
    );
  }

  Widget _contactCell(String t, {int flex = 1}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Text(t,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: _black),
          overflow: TextOverflow.ellipsis),
    ),
  );
}