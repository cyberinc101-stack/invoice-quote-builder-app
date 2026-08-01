// cv_fullscreen_preview_individual_files/preview_placeholder_base.dart
// Shared base used by templates that haven't yet received a dedicated preview

import 'package:flutter/material.dart';

const _name    = 'Alexandra Chen';
const _title   = 'Senior Product Designer';
const _email   = 'alex.chen@email.com';
const _loc     = 'San Francisco, CA';
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

// Fixed semi-transparent whites – replaces Colors.white.withOpacity(x)
const _white70  = Color(0xB3FFFFFF); // white 70%
const _white15  = Color(0x26FFFFFF); // white 15%
const _white85  = Color(0xD9FFFFFF); // white 85%
const _white60  = Color(0x99FFFFFF); // white 60%
const _white70b = Color(0xB3FFFFFF); // white 70% (text)

/// Returns a copy of [c] with alpha set to [opacity] * 255,
/// without using the deprecated withOpacity() method.
Color _alpha(Color c, double opacity) => Color.fromRGBO(
  (c.r * 255).round(),
  (c.g * 255).round(),
  (c.b * 255).round(),
  opacity,
);

class PreviewPlaceholderBase extends StatelessWidget {
  final Color headerColor1;
  final Color headerColor2;
  final Color accentColor;
  final bool lightBg;

  const PreviewPlaceholderBase({
    super.key,
    required this.headerColor1,
    required this.headerColor2,
    required this.accentColor,
    this.lightBg = false,
  });

  @override
  Widget build(BuildContext context) {
    final textC  = lightBg ? const Color(0xFF1A1A2E) : Colors.white;
    final mutedC = lightBg ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final bgC    = lightBg ? Colors.white : _alpha(headerColor1, 0.97);

    Widget sectionHead(String t) => Row(children: [
      Container(
        width: 3, height: 14,
        decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 8),
      Text(t, style: TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w800,
          color: lightBg ? const Color(0xFF1A1A2E) : Colors.white,
          letterSpacing: 2)),
    ]);

    Widget bullet(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(width: 5, height: 5,
              decoration: BoxDecoration(
                  color: accentColor, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: TextStyle(
            fontSize: 12, color: mutedC, height: 1.5))),
      ]),
    );

    Widget skillBar(String name, double pct) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: TextStyle(
              fontSize: 11.5, color: textC,
              fontWeight: FontWeight.w500))),
          Text('${(pct * 100).round()}%',
              style: TextStyle(fontSize: 10, color: mutedC)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(height: 4, child: Row(children: [
            Flexible(
              flex: (pct * 100).round(),
              child: ColoredBox(
                  color: accentColor, child: const SizedBox.expand()),
            ),
            Flexible(
              flex: 100 - (pct * 100).round(),
              child: ColoredBox(
                  color: _alpha(accentColor, 0.15),
                  child: const SizedBox.expand()),
            ),
          ])),
        ),
      ]),
    );

    return Material(
      color: bgC,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 480,
            child: ColoredBox(
              color: bgC,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // ── Gradient header ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [headerColor1, headerColor2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _white70, width: 2.5),
                        color: _white15,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: _white60, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text(_name, style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: Colors.white, height: 1.1)),
                      const SizedBox(height: 5),
                      const Text(_title, style: TextStyle(
                          fontSize: 12.5, color: _white85)),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.email_outlined,
                            color: _white60, size: 12),
                        const SizedBox(width: 5),
                        const Flexible(child: Text(_email,
                            style: TextStyle(
                                color: _white70b, fontSize: 11))),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            color: _white60, size: 12),
                        const SizedBox(width: 5),
                        const Text(_loc, style: TextStyle(
                            color: _white70b, fontSize: 11)),
                      ]),
                    ])),
                  ]),
                ),

                // ── Body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Main column
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        sectionHead('ABOUT'), const SizedBox(height: 8),
                        Text(_summary, style: TextStyle(
                            fontSize: 12, color: mutedC, height: 1.7)),
                        const SizedBox(height: 20),
                        sectionHead('EXPERIENCE'),
                        const SizedBox(height: 12),
                        ..._exp.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(child: Text(e.$2, style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textC))),
                              const SizedBox(width: 8),
                              Text(e.$3, style: TextStyle(
                                  fontSize: 11, color: mutedC)),
                            ]),
                            Text(e.$1, style: TextStyle(
                                fontSize: 12, color: accentColor,
                                fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            ...e.$4.map(bullet),
                          ]),
                        )),
                        sectionHead('EDUCATION'),
                        const SizedBox(height: 12),
                        ..._edu.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: _alpha(accentColor, 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: Text(e.$3.substring(2),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(e.$2, style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textC)),
                              Text(e.$1, style: TextStyle(
                                  fontSize: 11.5, color: mutedC)),
                            ])),
                          ]),
                        )),
                      ])),
                      const SizedBox(width: 20),
                      // Sidebar
                      SizedBox(width: 128, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        sectionHead('SKILLS'),
                        const SizedBox(height: 10),
                        ..._skills.map((s) => skillBar(s.$1, s.$2)),
                        const SizedBox(height: 14),
                        sectionHead('LANGUAGES'),
                        const SizedBox(height: 10),
                        ..._langs.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(children: [
                            Container(width: 5, height: 5,
                                decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Flexible(child: Text(l, style: TextStyle(
                                fontSize: 11.5, color: mutedC))),
                          ]),
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
}