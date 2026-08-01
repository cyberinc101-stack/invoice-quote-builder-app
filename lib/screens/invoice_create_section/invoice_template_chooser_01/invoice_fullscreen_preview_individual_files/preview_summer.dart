// cv_fullscreen_preview_individual_files/preview_summer.dart
// Full-screen scrollable preview for Template 15 – Summer Clean Minimal
// Matches MiniPreview15Summer exactly

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

// Colours matching MiniPreview15Summer exactly
const _ink    = Color(0xFF1A1A1A);
const _muted  = Color(0xFF6B7280);
const _light  = Color(0xFF9CA3AF);
const _rule   = Color(0xFFE5E7EB);
const _accent = Color(0xFF374151);

// Pre-computed alpha colours – replaces all withOpacity() calls
const _accentTrack  = Color(0x1F374151);  // _accent 12%
const _ruleLight    = Color(0x4D9CA3AF);  // _light  30%
const _accentBorder = Color(0x66374151);  // _accent 40%

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Container(width: 5, height: 5,
          decoration: const BoxDecoration(
              color: _muted, shape: BoxShape.circle)),
    ),
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
          fontSize: 11.5, color: _accent,
          fontWeight: FontWeight.w500))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: _muted)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(height: 5, child: Row(children: [
        Flexible(
          flex: (pct * 100).round(),
          child: const ColoredBox(color: _accent, child: SizedBox.expand()),
        ),
        Flexible(
          flex: 100 - (pct * 100).round(),
          child: const ColoredBox(color: _accentTrack, child: SizedBox.expand()),
        ),
      ])),
    ),
  ]),
);

Widget _sectionHead(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(children: [
    Text(t, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w800,
        color: _ink, letterSpacing: 2)),
    const SizedBox(width: 10),
    Expanded(child: Container(height: 0.5, color: _ruleLight)),
  ]),
);

class PreviewSummer extends StatelessWidget {
  const PreviewSummer({super.key});

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
            child: ColoredBox(
              color: Colors.white,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // ── Clean header ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        bottom: BorderSide(color: _rule)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 52, height: 52,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: _rule),
                        child: const Icon(Icons.person_rounded,
                            color: _light, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text(_name, style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: _ink)),
                        const SizedBox(height: 3),
                        const Text(_title, style: TextStyle(
                            fontSize: 12, color: _muted)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 14, runSpacing: 4, children: [
                          _meta(Icons.email_outlined, _email),
                          _meta(Icons.phone_outlined, _phone),
                          _meta(Icons.location_on_outlined, _loc),
                          _meta(Icons.language_outlined, _web),
                        ]),
                      ])),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Main column
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _sectionHead('SUMMARY'),
                        const Text(_summary, style: TextStyle(
                            fontSize: 12, color: _muted, height: 1.7)),
                        const SizedBox(height: 20),
                        _sectionHead('EXPERIENCE'),
                        ..._exp.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(child: Text(e.$2, style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: _ink))),
                              Text(e.$3, style: const TextStyle(
                                  fontSize: 10.5, color: _light)),
                            ]),
                            Text(e.$1, style: const TextStyle(
                                fontSize: 12, color: _muted)),
                            const SizedBox(height: 7),
                            ...e.$4.map(_bullet),
                            Container(
                              height: 1,
                              margin: const EdgeInsets.only(top: 10),
                              color: _rule,
                            ),
                          ]),
                        )),
                        _sectionHead('EDUCATION'),
                        ..._edu.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _accentBorder),
                              ),
                              child: Center(child: Text(e.$3.substring(2),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _accent))),
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
                                  fontSize: 11, color: _light,
                                  fontStyle: FontStyle.italic)),
                            ])),
                          ]),
                        )),
                      ])),
                      const SizedBox(width: 20),

                      // Sidebar
                      SizedBox(width: 134, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _sectionHead('SKILLS'),
                        ..._skills.map((s) => _skillBar(s.$1, s.$2)),
                        const SizedBox(height: 14),
                        _sectionHead('LANGUAGES'),
                        ..._langs.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(children: [
                            Container(width: 5, height: 5,
                                decoration: const BoxDecoration(
                                    color: _muted, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Flexible(child: Text(l, style: const TextStyle(
                                fontSize: 11.5, color: _muted))),
                          ]),
                        )),
                        const SizedBox(height: 14),
                        _sectionHead('CERTIFICATIONS'),
                        ..._certs.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(c, style: const TextStyle(
                              fontSize: 11, color: _muted, height: 1.4)),
                        )),
                        const SizedBox(height: 14),
                        _sectionHead('REFERENCES'),
                        ..._refs.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1, style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                              const SizedBox(height: 2),
                              Text(r.$2, style: const TextStyle(
                                  fontSize: 10,
                                  color: _accent,
                                  fontWeight: FontWeight.w600)),
                              if (r.$3.isNotEmpty)
                                Text(r.$3, style: const TextStyle(
                                    fontSize: 10, color: _muted)),
                              const SizedBox(height: 5),
                              Row(children: [
                                const Icon(Icons.email_outlined,
                                    size: 10, color: _light),
                                const SizedBox(width: 4),
                                Expanded(child: Text(r.$4,
                                    style: const TextStyle(
                                        fontSize: 9.5, color: _muted),
                                    overflow: TextOverflow.ellipsis)),
                              ]),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.phone_outlined,
                                    size: 10, color: _light),
                                const SizedBox(width: 4),
                                Expanded(child: Text(r.$5,
                                    style: const TextStyle(
                                        fontSize: 9.5, color: _muted),
                                    overflow: TextOverflow.ellipsis)),
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

  Widget _meta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _light, size: 11),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10.5, color: _muted)),
    ],
  );
}