// cv_fullscreen_preview_individual_files/preview_nordic.dart
// Full-screen scrollable preview for Template 02 – Nordic
// Matches MiniPreview02Nordic exactly: white bg, blue accent only, no yellow

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

// Nordic palette — blue accent only, matching MiniPreview02Nordic
const _blue     = Color(0xFF2563EB);
const _ink      = Color(0xFF111111);
const _muted    = Color(0xFF888888);
const _rule     = Color(0xFFE0E0E0);
const _segEmpty = Color(0xFFE8E8E8);

Widget _divider() => Container(height: 0.5, color: _rule);

Widget _label(String t) => Text(t,
    style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700, color: _ink, letterSpacing: 2.5));

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 12, color: _ink, height: 1.5))),
  ]),
);

Widget _skillBar(String name, double pct) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(name,
          style: const TextStyle(
              fontSize: 11.5, color: _ink, fontWeight: FontWeight.w500))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: _muted)),
    ]),
    const SizedBox(height: 5),
    Row(
      children: List.generate(10, (i) => Container(
        margin: const EdgeInsets.only(right: 3),
        width: 9,
        height: 5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.5),
          color: i < (pct * 10).round() ? _blue : _segEmpty,
        ),
      )),
    ),
  ]),
);

class PreviewNordic extends StatelessWidget {
  const PreviewNordic({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 480,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(32, 30, 32, 36),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Header ──────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_name,
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: _ink,
                              letterSpacing: -0.5,
                              height: 1.0)),
                      const SizedBox(height: 6),
                      Text(_title,
                          style: const TextStyle(
                              fontSize: 13,
                              color: _blue,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5)),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_email, style: const TextStyle(fontSize: 11, color: _muted)),
                    Text(_phone, style: const TextStyle(fontSize: 11, color: _muted)),
                    Text(_loc,   style: const TextStyle(fontSize: 11, color: _muted)),
                    Text(_web,   style: const TextStyle(fontSize: 11, color: _muted)),
                  ]),
                ],
              ),
              const SizedBox(height: 20),
              _divider(),
              const SizedBox(height: 20),

              // ── Body ────────────────────────────────────────────────────
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Main column
                  Expanded(
                    flex: 6,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _label('ABOUT'),
                      const SizedBox(height: 8),
                      Text(_summary,
                          style: const TextStyle(
                              fontSize: 12, color: _muted, height: 1.8)),
                      const SizedBox(height: 20),

                      _label('EXPERIENCE'),
                      const SizedBox(height: 12),
                      ..._exp.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(e.$1,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _ink))),
                              const SizedBox(width: 8),
                              Text(e.$3,
                                  style: const TextStyle(
                                      fontSize: 11, color: _muted)),
                            ]),
                            Text(e.$2,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: _muted,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            ...e.$4.map(_bullet),
                          ],
                        ),
                      )),

                      _label('EDUCATION'),
                      const SizedBox(height: 12),
                      ..._edu.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.$1,
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: _ink)),
                                      Text(e.$2,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _muted,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(e.$3,
                                    style: const TextStyle(
                                        fontSize: 11, color: _muted)),
                              ],
                            ),
                            // Detail line: blue bullet + black text, matching real CV
                            if (e.$4.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Container(
                                        width: 5, height: 5,
                                        decoration: const BoxDecoration(
                                            color: _blue,
                                            shape: BoxShape.circle),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(e.$4,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _ink,
                                              height: 1.4)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )),
                    ]),
                  ),

                  const SizedBox(width: 28),

                  // Sidebar
                  SizedBox(
                    width: 130,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _label('SKILLS'),
                      const SizedBox(height: 10),
                      ..._skills.map((s) => _skillBar(s.$1, s.$2)),

                      const SizedBox(height: 16),
                      _label('LANGUAGES'),
                      const SizedBox(height: 10),
                      ..._langs.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(l,
                              style: const TextStyle(
                                  fontSize: 11.5, color: _muted, height: 1.4)))),

                      const SizedBox(height: 16),
                      _label('CERTIFICATIONS'),
                      const SizedBox(height: 10),
                      ..._certs.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(c,
                              style: const TextStyle(
                                  fontSize: 11, color: _muted, height: 1.4)))),

                      const SizedBox(height: 16),
                      _label('PERSONAL REFERENCES'),
                      const SizedBox(height: 10),
                      ..._refs.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.$1,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: _ink)),
                            const SizedBox(height: 1),
                            Text(r.$2,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _blue,
                                    fontWeight: FontWeight.w500)),
                            if (r.$3.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(r.$3,
                                  style: const TextStyle(
                                      fontSize: 10.5, color: _muted)),
                            ],
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.email_outlined,
                                  size: 10, color: _muted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(r.$4,
                                    style: const TextStyle(
                                        fontSize: 10, color: _muted),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.phone_outlined,
                                  size: 10, color: _muted),
                              const SizedBox(width: 4),
                              Text(r.$5,
                                  style: const TextStyle(
                                      fontSize: 10, color: _muted)),
                            ]),
                          ],
                        ),
                      )),
                    ]),
                  ),

                ]),
              ),

            ]),
          ),
        ),
      ),
    );
  }
}