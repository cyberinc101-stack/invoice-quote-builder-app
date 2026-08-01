// cv_fullscreen_preview_individual_files/preview_collins.dart
// Full-screen scrollable preview for Template 18 – Collins
// Layout matches MiniPreview18Collins: centred header, full-width sections, 3-col footer

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
  'Figma', 'Design Systems', 'User Research', 'Prototyping', 'Sketch', 'Motion Design',
];
const _langs = ['English (Native)', 'Mandarin (Fluent)', 'French (Basic)'];
const _certs = ['Google UX Design Certificate', 'Interaction Design Foundation', 'NN/g UX'];
const _refs = [
  ('James Smith', 'Engineering Manager', 'Acme Corp', 'j.smith@acme.com', '+1 555 010 1234'),
  ('Sarah Lee',   'Design Director',     'Globex',    's.lee@globex.com',  '+1 555 020 5678'),
];

// ── Colours (from MiniPreview18Collins) ──────────────────────────────────────
const _ink   = Color(0xFF111111);
const _muted = Color(0xFF555555);
const _light = Color(0xFF888888);
const _rule  = Color(0xFFCCCCCC);

// ── Shared widgets ────────────────────────────────────────────────────────────

Widget _sec(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: 2.5)),
    const SizedBox(height: 3),
    Container(height: 0.8, color: _rule),
  ]),
);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Padding(
      padding: EdgeInsets.only(top: 6),
      child: Text('• ', style: TextStyle(color: _muted, fontSize: 13)),
    ),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 12, color: _muted, height: 1.5))),
  ]),
);

// ── Main widget ───────────────────────────────────────────────────────────────

class PreviewCollins extends StatelessWidget {
  const PreviewCollins({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 480,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── CENTRED NAME BLOCK ───────────────────────────────────
                  Column(children: [
                    Text(_name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            letterSpacing: 5)),
                    const SizedBox(height: 5),
                    Text(_title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            color: _muted,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 4,
                      children: [
                        _contact(_email),
                        _contact(_phone),
                        _contact(_loc),
                        _contact(_web),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 14),
                  Container(height: 1.5, color: _ink),
                  const SizedBox(height: 20),

                  // ── PROFESSIONAL SUMMARY ─────────────────────────────────
                  _sec('PROFESSIONAL SUMMARY'),
                  Text(_summary,
                      style: const TextStyle(
                          fontSize: 12, color: _muted, height: 1.7)),
                  const SizedBox(height: 22),

                  // ── WORK EXPERIENCE ──────────────────────────────────────
                  _sec('WORK EXPERIENCE'),
                  for (final e in _exp)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(e.$2,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _ink),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text(e.$3,
                                  style: const TextStyle(
                                      fontSize: 11, color: _light)),
                            ],
                          ),
                          Text(e.$1,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                  fontStyle: FontStyle.italic)),
                          const SizedBox(height: 6),
                          ...e.$4.map(_bullet),
                        ],
                      ),
                    ),

                  const SizedBox(height: 4),

                  // ── EDUCATION ────────────────────────────────────────────
                  _sec('EDUCATION'),
                  for (final e in _edu)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.$2,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                              Text(e.$1,
                                  style: const TextStyle(
                                      fontSize: 12, color: _muted)),
                            ],
                          ),
                          Text(e.$3,
                              style: const TextStyle(
                                  fontSize: 11, color: _light)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 4),

                  // ── SKILLS ───────────────────────────────────────────────
                  _sec('SKILLS'),
                  Wrap(
                    spacing: 20,
                    runSpacing: 5,
                    children: [
                      for (final s in _skills)
                        Text(s, style: const TextStyle(
                            fontSize: 11.5, color: _muted)),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── LANGUAGES ────────────────────────────────────────────
                  _sec('LANGUAGES'),
                  Wrap(
                    spacing: 20,
                    runSpacing: 5,
                    children: [
                      for (final l in _langs)
                        Text(l, style: const TextStyle(
                            fontSize: 11.5, color: _muted)),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── CERTIFICATIONS ───────────────────────────────────────
                  _sec('CERTIFICATIONS'),
                  for (final c in _certs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(c, style: const TextStyle(
                          fontSize: 11.5, color: _muted, height: 1.4)),
                    ),
                  const SizedBox(height: 22),

                  // ── REFERENCES ───────────────────────────────────────────
                  _sec('REFERENCES'),
                  for (final r in _refs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1, style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                              Text(r.$2, style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                  fontStyle: FontStyle.italic)),
                              if (r.$3.isNotEmpty)
                                Text(r.$3, style: const TextStyle(
                                    fontSize: 12, color: _muted)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(r.$4, style: const TextStyle(
                                  fontSize: 11, color: _light)),
                              Text(r.$5, style: const TextStyle(
                                  fontSize: 11, color: _light)),
                            ],
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

  Widget _contact(String label) => Text(label,
      style: const TextStyle(fontSize: 11, color: _light));
}