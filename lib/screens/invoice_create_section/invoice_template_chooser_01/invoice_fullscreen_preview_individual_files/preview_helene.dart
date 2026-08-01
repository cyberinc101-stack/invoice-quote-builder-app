// cv_fullscreen_preview_individual_files/preview_helene.dart
// Full-screen scrollable preview for Template 16 – Helene
// Layout matches MiniPreview16Helene: left sidebar + right main content

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
  ('Stripe',  'Sr. Product Designer', '2021 – Present', [
    'Led redesign of core payment flows, increasing conversion by 23%',
    'Built and maintained a design system used by 40+ engineers',
    'Mentored 3 junior designers and ran weekly design critiques',
  ]),
  ('Airbnb',  'Product Designer',     '2018 – 2021', [
    'Designed host onboarding experience for 2M+ new hosts',
    'Collaborated with research team on 12 user studies',
    'Launched new messaging platform with 98% satisfaction score',
  ]),
  ('IDEO',    'UX Designer',          '2016 – 2018', [
    'Delivered human-centered solutions for healthcare & fintech clients',
    'Ran design sprints and stakeholder workshops across 6 countries',
  ]),
];

const _edu = [
  ('Rhode Island School of Design', 'BFA Graphic Design', '2016'),
  ('Stanford University',           'Certificate – HCI',  '2019'),
];

const _skills = [
  ('Figma',          0.95),
  ('Design Systems', 0.90),
  ('User Research',  0.85),
  ('Prototyping',    0.88),
  ('Sketch',         0.80),
  ('Motion Design',  0.70),
];

const _langs = ['English (Native)', 'Mandarin (Fluent)', 'French (Basic)'];
const _certs = ['Google UX Design Certificate', 'Interaction Design Foundation'];
const _refs = [
  ('James Smith', 'Engineering Manager', 'Acme Corp', 'j.smith@acme.com', '+1 555 010 1234'),
  ('Sarah Lee',   'Design Director',     'Globex',    's.lee@globex.com',  '+1 555 020 5678'),
];

// ── Colours (from MiniPreview16Helene) ───────────────────────────────────────
const _bg      = Color(0xFFFDF8F2);
const _card    = Color(0xFFF5EFE6);
const _ink     = Color(0xFF3D2E1E);
const _muted   = Color(0xFF7D6A56);
const _accent  = Color(0xFF8B7355);
const _soft    = Color(0xFFD4C5A9);
const _border  = Color(0xFFD5CCBF);

// ── Shared widgets ────────────────────────────────────────────────────────────

Widget _div() => Container(height: 0.8, color: _border);

Widget _sh(String t) => Align(
  alignment: Alignment.centerLeft,
  child: Text(t,
      style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: _accent,
          letterSpacing: 2.0)),
);

Widget _sc(IconData icon, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(children: [
    Icon(icon, size: 11, color: _accent),
    const SizedBox(width: 5),
    Expanded(child: Text(text,
        style: const TextStyle(fontSize: 10.5, color: _muted),
        overflow: TextOverflow.ellipsis)),
  ]),
);

Widget _rh(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Row(children: [
    Container(width: 16, height: 1.5, color: _accent),
    const SizedBox(width: 5),
    Text(t,
        style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: 2.0)),
  ]),
  const SizedBox(height: 4),
  Container(height: 0.5, color: _border),
]);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(width: 4, height: 4,
          decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 7),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 11.5, color: _muted, height: 1.5))),
  ]),
);

// ── Main widget ───────────────────────────────────────────────────────────────

class PreviewHelene extends StatelessWidget {
  const PreviewHelene({super.key});

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
                      // ── LEFT SIDEBAR ─────────────────────────────────────
                      Container(
                        width: 148,
                        color: _card,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _soft, width: 2),
                                color: _soft.withOpacity(0.3),
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: _soft, size: 34),
                            ),
                            const SizedBox(height: 10),

                            // Name
                            const Text('Alexandra',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _ink)),
                            const Text('Chen',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _muted,
                                    fontWeight: FontWeight.w300)),
                            const SizedBox(height: 6),

                            // Title badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _accent.withOpacity(0.3)),
                              ),
                              child: const Text('Designer',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _accent,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 16),
                            _div(),
                            const SizedBox(height: 14),

                            // CONTACT
                            _sh('CONTACT'),
                            const SizedBox(height: 8),
                            _sc(Icons.email_outlined, _email),
                            _sc(Icons.phone_outlined, _phone),
                            _sc(Icons.location_on_outlined, _loc),
                            const SizedBox(height: 14),
                            _div(),
                            const SizedBox(height: 14),

                            // SKILLS
                            _sh('SKILL'),
                            const SizedBox(height: 10),
                            for (final s in _skills)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(s.$1,
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              color: _muted),
                                          overflow: TextOverflow.ellipsis)),
                                      Text('${(s.$2 * 100).round()}%',
                                          style: const TextStyle(
                                              fontSize: 9.5, color: _accent)),
                                    ]),
                                    const SizedBox(height: 3),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: SizedBox(
                                        height: 4,
                                        child: Row(children: [
                                          Flexible(
                                            flex: (s.$2 * 100).round(),
                                            child: const ColoredBox(
                                                color: _accent,
                                                child: SizedBox.expand()),
                                          ),
                                          Flexible(
                                            flex: 100 - (s.$2 * 100).round(),
                                            child: ColoredBox(
                                                color: _soft.withOpacity(0.35),
                                                child: const SizedBox.expand()),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 14),
                            _div(),
                            const SizedBox(height: 14),

                            // LANGUAGES
                            _sh('LANGUAGE'),
                            const SizedBox(height: 8),
                            for (final l in _langs)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(children: [
                                  Container(
                                      width: 6, height: 6,
                                      decoration: const BoxDecoration(
                                          color: _accent,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(l,
                                      style: const TextStyle(
                                          fontSize: 10.5, color: _muted),
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                              ),
                            const SizedBox(height: 14),
                            _div(),
                            const SizedBox(height: 14),

                            // REFERENCES
                            _sh('REFERENCES'),
                            const SizedBox(height: 8),
                            for (final r in _refs)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.$1,
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: _ink)),
                                    const SizedBox(height: 2),
                                    Text(r.$2,
                                        style: const TextStyle(
                                            fontSize: 9.5,
                                            color: _accent,
                                            fontWeight: FontWeight.w600)),
                                    if (r.$3.isNotEmpty)
                                      Text(r.$3,
                                          style: const TextStyle(
                                              fontSize: 9.5, color: _muted)),
                                    const SizedBox(height: 5),
                                    _sc(Icons.email_outlined, r.$4),
                                    _sc(Icons.phone_outlined, r.$5),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── RIGHT MAIN CONTENT ───────────────────────────────
                      Expanded(
                        child: Container(
                          color: _bg,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Decorative accent lines
                              Row(children: [
                                Container(width: 26, height: 3, color: _accent),
                                const SizedBox(width: 5),
                                Container(width: 10, height: 3, color: _soft),
                              ]),
                              const SizedBox(height: 14),

                              // MY PROFILE
                              _rh('MY PROFILE'),
                              const SizedBox(height: 10),
                              Text(_summary,
                                  style: const TextStyle(
                                      fontSize: 11.5, color: _muted, height: 1.7)),
                              const SizedBox(height: 18),

                              // EXPERIENCE
                              _rh('EXPERIENCE'),
                              const SizedBox(height: 12),
                              for (final e in _exp)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(children: [
                                        Container(
                                          width: 10, height: 10,
                                          decoration: BoxDecoration(
                                            color: _bg,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: _accent, width: 1.5),
                                          ),
                                        ),
                                        Container(
                                            width: 1.5,
                                            height: 70,
                                            color: _border),
                                      ]),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(child: Text(e.$2,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: _ink),
                                                    overflow:
                                                        TextOverflow.ellipsis)),
                                                Text(e.$3,
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: _soft,
                                                        fontStyle:
                                                            FontStyle.italic)),
                                              ],
                                            ),
                                            Text(e.$1,
                                                style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: _accent,
                                                    fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 5),
                                            ...e.$4.map(_bullet),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // EDUCATION
                              _rh('EDUCATION'),
                              const SizedBox(height: 12),
                              for (final e in _edu)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 10, height: 10,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: _bg,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: _accent, width: 1.5),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(e.$2,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: _ink)),
                                            Text(e.$1,
                                                style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: _accent)),
                                          ],
                                        ),
                                      ),
                                      Text(e.$3,
                                          style: const TextStyle(
                                              fontSize: 10.5, color: _soft)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}