// cv_fullscreen_preview_individual_files/preview_art_deco.dart
// Full-screen scrollable preview for Template 12 – Art Deco
// Matches MiniPreview12ArtDeco exactly

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
  ('BFA Graphic Design', 'Rhode Island School of Design', '2016'),
  ('Certificate – HCI', 'Stanford University', '2019'),
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

const _bg        = Color(0xFFFBF8F1);
const _darkBrown = Color(0xFF1A1208);
const _gold      = Color(0xFFC8973A);
const _goldL     = Color(0xFFDEB96E);
const _goldPale  = Color(0xFFF5E6C8);
const _muted     = Color(0xFF6B5C3E);

Widget _bar(double w, double h, Color c, {double r = 0}) =>
    Container(width: w, height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

Widget _decoBand({bool thin = false}) =>
    _bar(double.infinity, thin ? 0.8 : 2.5, _gold);

// Section header matching mini: gold bar + label + expanding pale line
Widget _decoS(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(children: [
    _bar(8, 1.5, _gold),
    const SizedBox(width: 5),
    Text(t, style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w800,
        color: _darkBrown, letterSpacing: 2)),
    const SizedBox(width: 5),
    Expanded(child: _bar(double.infinity, 0.5, _goldPale)),
  ]),
);

// Diamond bullet for career section
Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(' ·   ', style: const TextStyle(fontSize: 8, color: _goldL)),
    ),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 12, color: _muted, height: 1.5))),
  ]),
);

class PreviewArtDeco extends StatelessWidget {
  const PreviewArtDeco({super.key});

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
                  // ── Top deco bands ─────────────────────────────────────
                  _decoBand(),
                  const SizedBox(height: 4),
                  _decoBand(thin: true),

                  // ── Centered header on cream background ────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 18),
                    child: Column(
                      children: [
                        // Diamond + flanking lines
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _bar(28, 0.5, _gold),
                            const SizedBox(width: 8),
                            Transform.rotate(
                              angle: math.pi / 4,
                              child: _bar(10, 10, _gold),
                            ),
                            const SizedBox(width: 8),
                            _bar(28, 0.5, _gold),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // AC monogram with corner brackets
                        SizedBox(
                          width: 72, height: 72,
                          child: Stack(children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                  border: Border.all(color: _gold, width: 1.5)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                color: _darkBrown,
                                child: const Center(
                                  child: Text('AC', style: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.w300,
                                      color: _gold, letterSpacing: 4)),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0, top: 0,
                              child: Column(children: [
                                _bar(12, 2.5, _gold),
                                _bar(2.5, 12, _gold),
                              ]),
                            ),
                            Positioned(
                              right: 0, bottom: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _bar(2.5, 12, _gold),
                                  _bar(12, 2.5, _gold),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),

                        // Name
                        Text(_name.toUpperCase(), style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: _darkBrown, letterSpacing: 5)),
                        const SizedBox(height: 6),

                        // Title with flanking lines
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _bar(20, 0.5, _goldL),
                            const SizedBox(width: 8),
                            Text(_title.toUpperCase(), style: const TextStyle(
                                fontSize: 9, color: _gold,
                                letterSpacing: 2.5, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            _bar(20, 0.5, _goldL),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Contact line
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_email, style: const TextStyle(
                                fontSize: 10, color: _muted)),
                            const Text('   ·   ', style: TextStyle(
                                color: _gold, fontSize: 9)),
                            Text(_loc, style: const TextStyle(
                                fontSize: 10, color: _muted)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Closing deco bands ─────────────────────────────────
                  _decoBand(thin: true),
                  const SizedBox(height: 3),
                  _decoBand(),
                  const SizedBox(height: 12),

                  // ── Two-column body ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Left sidebar: Mastery + Education ──────────
                          SizedBox(
                            width: 148,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _decoS('MASTERY'),
                                const SizedBox(height: 4),

                                // Skill dot-grid bars
                                ..._skills.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.$1, style: const TextStyle(
                                          fontSize: 10,
                                          color: _darkBrown,
                                          fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: List.generate(10, (i) =>
                                          Container(
                                            margin: const EdgeInsets.only(
                                                right: 2),
                                            width: 9, height: 6,
                                            color: i < (s.$2 * 10).round()
                                                ? _gold
                                                : _goldPale,
                                          )),
                                      ),
                                    ],
                                  ),
                                )),

                                const SizedBox(height: 6),
                                _decoS('EDUCATION'),
                                const SizedBox(height: 4),

                                ..._edu.map((e) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: _goldL.withOpacity(0.5)),
                                    color: _goldPale.withOpacity(0.3),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.$1, style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: _darkBrown)),
                                      Text(e.$2, style: const TextStyle(
                                          fontSize: 9.5, color: _muted)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        color: _gold,
                                        child: Text(e.$3,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: _bg)),
                                      ),
                                    ],
                                  ),
                                )),

                                const SizedBox(height: 6),
                                _decoS('REFERENCES'),
                                const SizedBox(height: 4),

                                ..._refs.map((r) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: _goldL.withOpacity(0.5)),
                                    color: _goldPale.withOpacity(0.3),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text(' ·   ', style: const TextStyle(
                                            fontSize: 8, color: _gold)),
                                        Expanded(child: Text(r.$1,
                                            style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: _darkBrown))),
                                      ]),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        color: _gold,
                                        child: Text(r.$2,
                                            style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: _bg)),
                                      ),
                                      if (r.$3.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(r.$3, style: const TextStyle(
                                            fontSize: 9.5, color: _muted)),
                                      ],
                                      const SizedBox(height: 5),
                                      Row(children: [
                                        const Icon(Icons.email_outlined,
                                            size: 10, color: _goldL),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(r.$4,
                                            style: const TextStyle(
                                                fontSize: 9, color: _muted),
                                            overflow: TextOverflow.ellipsis)),
                                      ]),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 10, color: _goldL),
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

                          // ── Gold vertical divider ───────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            child: Column(
                              children: [
                                _bar(8, 8, _gold),
                                Expanded(
                                  child: Container(
                                    width: 1,
                                    color: _goldL.withOpacity(0.4),
                                  ),
                                ),
                                _bar(8, 8, _gold),
                              ],
                            ),
                          ),

                          // ── Right column: Career + Languages + Certs + References ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _decoS('CAREER'),
                                const SizedBox(height: 6),

                                ..._exp.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Transform.rotate(
                                          angle: math.pi / 4,
                                          child: _bar(7, 7, _gold),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(child: Text(e.$2,
                                                  style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: _darkBrown))),
                                              Text(e.$3,
                                                  style: const TextStyle(
                                                      fontSize: 9,
                                                      color: _gold,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ]),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 15),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _bar(1, 3, _goldL.withOpacity(0.5)),
                                            Text(e.$1,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: _gold,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(height: 5),
                                            ...e.$4.map(_bullet),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),

                                const SizedBox(height: 8),
                                _decoS('LANGUAGES'),
                                const SizedBox(height: 4),
                                ..._langs.map((l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    Text(' ·   ', style: const TextStyle(
                                        fontSize: 8, color: _goldL)),
                                    Text(l, style: const TextStyle(
                                        fontSize: 11.5, color: _muted)),
                                  ]),
                                )),

                                const SizedBox(height: 12),
                                _decoS('CERTIFICATIONS'),
                                const SizedBox(height: 4),
                                ..._certs.map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    Text(' ·   ', style: const TextStyle(
                                        fontSize: 8, color: _goldL)),
                                    Expanded(child: Text(c,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: _muted,
                                            height: 1.4))),
                                  ]),
                                )),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom deco bands ──────────────────────────────────
                  _decoBand(thin: true),
                  const SizedBox(height: 3),
                  _decoBand(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}