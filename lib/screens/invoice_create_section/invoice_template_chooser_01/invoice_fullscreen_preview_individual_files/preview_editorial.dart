// cv_fullscreen_preview_individual_files/preview_editorial.dart
// Full-screen scrollable preview for Template 07 – Editorial
// Matches the mini-preview style: cream paper, magazine masthead, no black header

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
  ('Figma', 0.95), ('Design Sys.', 0.90), ('Research', 0.85),
  ('Prototyping', 0.88), ('Motion', 0.70),
];
const _langs = ['English (Native)', 'Mandarin (Fluent)', 'French (Basic)'];
const _certs = ['Google UX Design Certificate', 'Interaction Design Foundation'];
const _refs = [
  ('James Smith', 'Engineering Manager', 'Acme Corp', 'j.smith@acme.com', '+1 555 010 1234'),
  ('Sarah Lee',   'Design Director',     'Globex',    's.lee@globex.com',  '+1 555 020 5678'),
];

const _paper  = Color(0xFFFAF8F5);
const _ink    = Color(0xFF111111);
const _red    = Color(0xFFD0021B);
const _muted  = Color(0xFF777777);
const _rule   = Color(0xFFDDDDDD);
const _barBg  = Color(0xFFE5E5E5);

Widget _sH(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w900,
        color: _ink, letterSpacing: 2.5)),
    const SizedBox(height: 3),
    Container(height: 0.5, color: _rule),
  ]),
);

Widget _skillBar(String name, double pct) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(name, style: const TextStyle(
        fontSize: 11, color: _ink, fontWeight: FontWeight.w500)),
    const SizedBox(height: 3),
    ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: SizedBox(
        height: 2.5,
        child: Row(children: [
          Flexible(
            flex: (pct * 100).round(),
            child: const ColoredBox(color: _red, child: SizedBox.expand()),
          ),
          Flexible(
            flex: 100 - (pct * 100).round(),
            child: const ColoredBox(color: _barBg, child: SizedBox.expand()),
          ),
        ]),
      ),
    ),
  ]),
);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('—  ', style: TextStyle(
        color: _red, fontSize: 13, fontWeight: FontWeight.w700)),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 12, color: _muted, height: 1.5))),
  ]),
);

class PreviewEditorial extends StatelessWidget {
  const PreviewEditorial({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _paper,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 480,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildPage()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    return ColoredBox(
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top red rule ─────────────────────────────────────────────
          Container(height: 5, color: _red),

          // ── Masthead header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name.split(' ')[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            height: 0.9,
                            letterSpacing: -1),
                      ),
                      Text(
                        _name.split(' ')[1].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            height: 0.9,
                            letterSpacing: -1),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(width: 20, height: 2.5, color: _red),
                        const SizedBox(width: 7),
                        Text(
                          _title.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              color: _red,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8),
                        ),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_email,
                        style: const TextStyle(fontSize: 10, color: _muted)),
                    const SizedBox(height: 2),
                    Text(_phone,
                        style: const TextStyle(fontSize: 10, color: _muted)),
                    const SizedBox(height: 2),
                    Text(_loc,
                        style: const TextStyle(fontSize: 10, color: _muted)),
                    const SizedBox(height: 2),
                    Text(_web,
                        style: const TextStyle(fontSize: 10, color: _muted)),
                  ],
                ),
              ],
            ),
          ),

          // ── Double rule ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
            child: Column(children: [
              Container(height: 2.5, color: _ink),
              const SizedBox(height: 3),
              Container(height: 0.5, color: _ink),
            ]),
          ),

          // ── Two-column body ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left sidebar ──────────────────────────────────
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sH('ABOUT'),
                        Text(_summary,
                            style: const TextStyle(
                                fontSize: 11,
                                color: _muted,
                                height: 1.65)),
                        const SizedBox(height: 18),

                        _sH('SKILLS'),
                        ..._skills.map((s) => _skillBar(s.$1, s.$2)),
                        const SizedBox(height: 18),

                        _sH('EDUCATION'),
                        ..._edu.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.$3}  ',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _red,
                                    fontWeight: FontWeight.w700),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(e.$2,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _ink)),
                                    Text(e.$1,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: _muted)),
                                    Text(e.$4,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: _red,
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 18),

                        // ── Personal References ───────────────────
                        _sH('REFERENCES'),
                        ..._refs.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                              const SizedBox(height: 1),
                              Text(r.$2,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: _red,
                                      fontWeight: FontWeight.w600)),
                              if (r.$3.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(r.$3,
                                    style: const TextStyle(
                                        fontSize: 10, color: _muted)),
                              ],
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.email_outlined,
                                    size: 10, color: _muted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(r.$4,
                                      style: const TextStyle(
                                          fontSize: 9.5, color: _muted),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ),
                              ]),
                              const SizedBox(height: 2),
                              Row(children: [
                                const Icon(Icons.phone_outlined,
                                    size: 10, color: _muted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(r.$5,
                                      style: const TextStyle(
                                          fontSize: 9.5, color: _muted),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ),
                              ]),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),

                  // ── Vertical rule ─────────────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    width: 0.5,
                    color: _rule,
                  ),

                  // ── Right column: Experience ──────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sH('EXPERIENCE'),
                        ..._exp.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.$2,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: _ink,
                                                height: 1.1)),
                                        Text(e.$1,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: _red,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _rule),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(e.$3,
                                        style: const TextStyle(
                                            fontSize: 9, color: _muted)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...e.$4.map(_bullet),
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
    );
  }
}