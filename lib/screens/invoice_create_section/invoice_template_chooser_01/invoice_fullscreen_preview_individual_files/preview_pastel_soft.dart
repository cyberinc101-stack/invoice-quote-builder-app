// cv_fullscreen_preview_individual_files/preview_pastel_soft.dart
// Full-screen scrollable preview for Template 08 – Pastel Soft
// Matches MiniPreview08Pastel exactly

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

// Colours matching MiniPreview08Pastel exactly
const _lavender = Color(0xFFEDE7F6);
const _lavD     = Color(0xFF7C5CBF);
const _lavM     = Color(0xFFB39DDB);
const _peach    = Color(0xFFE8845D);
const _ink      = Color(0xFF2D2D3A);
const _muted    = Color(0xFF7B7B8F);
const _mainBg   = Color(0xFFFAFAFC);

// Pre-computed alpha colours – replaces all withOpacity() calls
const _lavDAvatarBg  = Color(0x4DB39DDB);  // _lavM 30%
const _lavDBg12      = Color(0x1F7C5CBF);  // _lavD 12%
const _lavMBorder50  = Color(0x80B39DDB);  // _lavM 50%
const _lavDShadow07  = Color(0x127C5CBF);  // _lavD 7%
const _lavDShadow05  = Color(0x0D7C5CBF);  // _lavD 5%
const _lavDBg08      = Color(0x147C5CBF);  // _lavD 8%
const _lavMBg20      = Color(0x33B39DDB);  // _lavM 20%
const _avatarBorder  = Color(0xCCFFFFFF);  // white 80%
const _avatarFill    = Color(0x33FFFFFF);  // white 20%
const _titlePill     = Color(0x38FFFFFF);  // white 22%
const _chipText      = Color(0xCCFFFFFF);  // white 80%
const _waveDivL      = Color(0x99B39DDB);  // _lavM 60%
const _waveDivR      = Color(0x4D7C5CBF);  // _lavD 30%
const _skillTrack    = Color(0x1F7C5CBF);  // _lavD 12%

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Container(width: 5, height: 5,
          decoration: const BoxDecoration(color: _lavM, shape: BoxShape.circle)),
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
          fontSize: 11.5, color: _ink, fontWeight: FontWeight.w500))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: _muted)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(height: 6, child: Row(children: [
        Flexible(flex: (pct * 100).round(),
            child: const ColoredBox(color: _lavM, child: SizedBox.expand())),
        Flexible(flex: 100 - (pct * 100).round(),
            child: const ColoredBox(color: _skillTrack, child: SizedBox.expand())),
      ])),
    ),
  ]),
);

Widget _mainS(String t, Color c) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color((c.value & 0x00FFFFFF) | 0x1A000000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(t, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    ),
    const SizedBox(width: 10),
    Expanded(child: Container(height: 1,
        color: Color((c.value & 0x00FFFFFF) | 0x26000000))),
  ]),
);

Widget _sideS(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Column(children: [
    Text(t, style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: _lavD, letterSpacing: 2)),
    Container(height: 1, color: _lavMBorder50),
  ]),
);

class PreviewPastelSoft extends StatelessWidget {
  const PreviewPastelSoft({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _mainBg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 480,
            child: ColoredBox(
              color: _mainBg,
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // ── Lavender sidebar ──────────────────────────────────
                  Container(
                    width: 148,
                    color: _lavender,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      // Avatar
                      Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lavDAvatarBg,
                          border: Border.all(color: _lavD, width: 2.5),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: _lavD, size: 36),
                      ),
                      const SizedBox(height: 10),
                      const Text('Alexandra Chen',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              color: _ink, height: 1.3)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _lavDBg12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('Product Designer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 9, color: _lavD,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 16),
                      _sideS('CONTACT'),
                      const SizedBox(height: 8),
                      ...[
                        (Icons.email_outlined,       _email),
                        (Icons.phone_outlined,       _phone),
                        (Icons.location_on_outlined, _loc),
                        (Icons.language_outlined,    _web),
                      ].map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: _lavDBg12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(c.$1, size: 13, color: _lavD),
                          ),
                          const SizedBox(width: 7),
                          Expanded(child: Text(c.$2,
                              style: const TextStyle(
                                  fontSize: 9, color: _muted),
                              overflow: TextOverflow.ellipsis)),
                        ]),
                      )),
                      const SizedBox(height: 14),
                      _sideS('SKILLS'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5, runSpacing: 5,
                        alignment: WrapAlignment.center,
                        children: ['Figma', 'Design', 'UX', 'Proto.',
                          'Sketch', 'Motion'].map((s) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _lavMBorder50),
                            ),
                            child: Text(s, style: const TextStyle(
                                fontSize: 9, color: _ink,
                                fontWeight: FontWeight.w500)),
                          )).toList(),
                      ),
                      const SizedBox(height: 14),
                      _sideS('LANGUAGES'),
                      const SizedBox(height: 8),
                      ..._langs.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(l, textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 9, color: _muted, height: 1.4)),
                      )),
                      const SizedBox(height: 14),

                      // ── References ──────────────────────────────────
                      _sideS('REFERENCES'),
                      const SizedBox(height: 8),
                      ..._refs.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(r.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                    height: 1.3)),
                            const SizedBox(height: 2),
                            Text(r.$2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: _lavD,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3)),
                            if (r.$3.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(r.$3,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: _muted,
                                      height: 1.3)),
                            ],
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: _lavDBg12,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.email_outlined,
                                      size: 11, color: _lavD),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(r.$4,
                                      style: const TextStyle(
                                          fontSize: 8.5, color: _muted),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: _lavDBg12,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.phone_outlined,
                                      size: 11, color: _lavD),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(r.$5,
                                      style: const TextStyle(
                                          fontSize: 8.5, color: _muted),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                    ]),
                  ),

                  // ── Main area ─────────────────────────────────────────
                  Expanded(child: Container(
                    color: _mainBg,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // About Me
                      _mainS('About Me', _peach),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color(0x33E8845D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_summary, style: const TextStyle(
                            fontSize: 12, color: _muted, height: 1.7)),
                      ),
                      const SizedBox(height: 18),

                      // Experience
                      _mainS('Experience', _lavD),
                      ..._exp.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(
                            color: _lavDShadow07,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          )],
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Expanded(child: Text(e.$2, style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: _ink))),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _lavender,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(e.$3, style: const TextStyle(
                                  fontSize: 9, color: _lavD)),
                            ),
                          ]),
                          Text(e.$1, style: const TextStyle(
                              fontSize: 12, color: _peach,
                              fontWeight: FontWeight.w600)),
                          const SizedBox(height: 7),
                          ...e.$4.map(_bullet),
                        ]),
                      )),

                      // Education
                      _mainS('Education', _lavD),
                      ..._edu.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(
                            color: _lavDShadow05,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          )],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: _lavender,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(e.$3,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: _lavD))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(e.$2, style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700,
                                color: _ink)),
                            Text(e.$1, style: const TextStyle(
                                fontSize: 11.5, color: _muted)),
                            Text(e.$4, style: const TextStyle(
                                fontSize: 11, color: _lavD,
                                fontStyle: FontStyle.italic)),
                          ])),
                        ]),
                      )),

                      // Certifications
                      _mainS('Certifications', _lavD),
                      ..._certs.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: _lavM, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c, style: const TextStyle(
                              fontSize: 11.5, color: _muted, height: 1.4))),
                        ]),
                      )),
                    ]),
                  )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}