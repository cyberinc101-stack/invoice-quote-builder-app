// cv_fullscreen_preview_individual_files/preview_gradient_modern.dart
// Full-screen scrollable preview for Template 06 – Gradient Modern

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

const _teal   = Color(0xFF0F7EA8);
const _purple = Color(0xFF7C3AED);
const _ink    = Color(0xFF1A1A2E);
const _muted  = Color(0xFF64748B);
const _bg     = Color(0xFFF8FAFC);

Widget _bullet(String t, Color accent) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(top: 6),
        child: Container(width: 5, height: 5,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle))),
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
          fontSize: 11.5, color: _ink, fontWeight: FontWeight.w500))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: _muted)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: Stack(children: [
          Container(color: const Color(0xFFE2E8F0)),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_teal, _purple]),
              ),
            ),
          ),
        ]),
      ),
    ),
  ]),
);

Widget _sectionLabel(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(children: [
    ShaderMask(
      shaderCallback: (b) => const LinearGradient(
          colors: [_teal, _purple]).createShader(b),
      child: Container(width: 4, height: 16,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2))),
    ),
    const SizedBox(width: 8),
    Flexible(
      child: Text(t, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: _ink, letterSpacing: 1.8)),
    ),
  ]),
);

class PreviewGradientModern extends StatelessWidget {
  const PreviewGradientModern({super.key});

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
              child: Column(children: [
                // ── Gradient header ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_teal, _purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 78, height: 78,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                              BorderSide(color: Colors.white, width: 2.5)),
                          color: Color(0x26FFFFFF)),
                      child: const Icon(Icons.person_rounded,
                          color: Color(0x99FFFFFF), size: 38),
                    ),
                    const SizedBox(width: 18),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_name, style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800,
                          color: Colors.white, height: 1.1)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(_title, style: const TextStyle(
                            fontSize: 12, color: Colors.white,
                            fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 14, children: [
                        _contactChip(Icons.email_outlined, _email),
                        _contactChip(Icons.phone_outlined, _phone),
                        _contactChip(Icons.location_on_outlined, _loc),
                      ]),
                    ])),
                  ]),
                ),

                // ── Body ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // ── Main column ──────────────────────────────────
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionLabel('ABOUT ME'),
                        Text(_summary, style: const TextStyle(
                            fontSize: 12, color: _muted, height: 1.7)),
                        const SizedBox(height: 20),
                        _sectionLabel('EXPERIENCE'),
                        ..._exp.map((e) => _expCard(e)),
                        const SizedBox(height: 4),
                        _sectionLabel('EDUCATION'),
                        ..._edu.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [_teal, _purple]),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text(e.$3.substring(2),
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: Colors.white))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(e.$2, style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: _ink)),
                              Text(e.$1, style: const TextStyle(
                                  fontSize: 11.5, color: _muted)),
                              Text(e.$4, style: const TextStyle(
                                  fontSize: 11, color: _teal,
                                  fontStyle: FontStyle.italic)),
                            ])),
                          ]),
                        )),
                      ])),

                      const SizedBox(width: 20),

                      // ── Right sidebar ─────────────────────────────────
                      SizedBox(width: 138, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionLabel('SKILLS'),
                        ..._skills.map((s) => _skillBar(s.$1, s.$2)),
                        const SizedBox(height: 14),

                        _sectionLabel('LANGUAGES'),
                        ..._langs.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(children: [
                            Container(width: 5, height: 5,
                                decoration: const BoxDecoration(
                                    color: _teal, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Flexible(child: Text(l, style: const TextStyle(
                                fontSize: 11.5, color: _muted))),
                          ]),
                        )),
                        const SizedBox(height: 14),

                        _sectionLabel('CERTIFICATIONS'),
                        ..._certs.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0x140F7EA8),
                                    Color(0x147C3AED),
                                  ])),
                          child: Text(c, style: const TextStyle(
                              fontSize: 11, color: _ink, height: 1.4)),
                        )),
                        const SizedBox(height: 14),

                        // ── Personal References ──────────────────────
                        _sectionLabel('PERSONAL REFERENCES'),
                        ..._refs.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1, style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                              const SizedBox(height: 1),
                              Text(r.$2, style: const TextStyle(
                                  fontSize: 11,
                                  color: _teal,
                                  fontWeight: FontWeight.w600)),
                              if (r.$3.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(r.$3, style: const TextStyle(
                                    fontSize: 10.5, color: _muted)),
                              ],
                              const SizedBox(height: 4),
                              Row(children: [
                                Container(width: 5, height: 5,
                                    decoration: const BoxDecoration(
                                        color: _teal, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Expanded(child: Text(r.$4,
                                    style: const TextStyle(
                                        fontSize: 10, color: _muted),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1)),
                              ]),
                              const SizedBox(height: 3),
                              Row(children: [
                                Container(width: 5, height: 5,
                                    decoration: const BoxDecoration(
                                        color: _teal, shape: BoxShape.circle)),
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

  Widget _contactChip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: const Color(0xB3FFFFFF), size: 12),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
          color: Color(0xCCFFFFFF), fontSize: 11)),
    ],
  );

  Widget _expCard((String, String, String, List<String>) e) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x120F7EA8),
              blurRadius: 12, offset: Offset(0, 4))
        ]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(e.$2, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: _ink))),
        const SizedBox(width: 6),
        Text(e.$3, style: const TextStyle(fontSize: 11, color: _muted)),
      ]),
      Text(e.$1, style: const TextStyle(
          fontSize: 12, color: _teal, fontWeight: FontWeight.w600)),
      const SizedBox(height: 7),
      ...e.$4.map((b) => _bullet(b, _teal)),
    ]),
  );
}