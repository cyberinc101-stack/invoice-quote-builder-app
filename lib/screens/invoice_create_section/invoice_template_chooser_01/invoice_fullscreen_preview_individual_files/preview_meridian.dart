// preview_meridian.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/cv_fullscreen_preview_individual_files/preview_meridian.dart
//
// Full-screen hold-to-preview for the SCHOLAR / MERIDIAN template (ID 23).
// Uses SingleChildScrollView + FittedBox(fitWidth) pattern — same as
// preview_art_deco.dart and preview_collins.dart — so no overflow occurs.
// Visual style: ALL-CAPS bold centred name, accent job title, bullet-separated
// contact row, centred accent section headers with underline rule.
// Thomas Eastwood Full Stack Developer sample data.

import 'package:flutter/material.dart';

// ── Sample data ───────────────────────────────────────────────────────────────
const _name  = 'Thomas Eastwood';
const _title = 'Full Stack Developer';
const _email = 'thomas.eastwood@gmail.com';
const _phone = '+1-555-555-5555';
const _loc   = 'San Francisco, CA';
const _web   = 'github.io/thom.east';

const _summary =
    'Full Stack Developer with over 10 years of experience in Java/JS, Angular, Vue, '
    'React, Python, NumPy, SciPy, Scikit-learn. Led development of \$500K research '
    'project which was deemed a "gold standard" by the client. Increased client\'s '
    'revenue 2-fold after fine-tuning AI/ML-based algorithms.';

const _exp = [
  ('Boyle', 'Senior Full Stack Developer', '2018 – Present', [
    'Hired, trained and leading an Agile team of 7 full-stack developers',
    'Developed indexed database architecture using SQL procedures and triggers '
    'for 10 different applications',
    'Worked with Core Java to develop automated solutions including web '
    'interfaces using HTML, CSS, JavaScript and Web services',
    'Worked with a committee of 6 members to organize employee activities',
  ]),
  ('Lauzon', 'Full Stack Developer', '2013 – 2018', [
    'Hired, trained and lead Agile team of 7 full-stack developers',
    'Created & maintained scheduled jobs in SQL Server for space maintenance '
    'and daily backups for 10 clients',
    'Increased company revenue by 30% within 2 months after implementing '
    'business logic for over 20 features',
    'Designed UI for over 15 clients; websites scoring over 85 on Lighthouse',
  ]),
];

const _edu = [
  ('Stanford University', 'M.S. in Computer Science', '2008 – 2009'),
];

const _skills = [
  'HTML · CSS · JS', 'Angular · React · Vue',
  'Python · NumPy · SciPy', 'TensorFlow · Keras',
  'NodeJS · AWS · SQL', 'JUnit · Scrum · Agile',
];
const _langs = ['English (Native)', 'French (Intermediate)'];

// ── Palette (Meridian: accent blue, clean white) ──────────────────────────────
const _accent = Color(0xFF2563EB);
const _ink    = Color(0xFF1A1A1A);
const _mid    = Color(0xFF333333);
const _muted  = Color(0xFF777777);
const _rule   = Color(0xFFCCCCCC);

// ── Shared helpers ────────────────────────────────────────────────────────────
Widget _sectionHeader(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(children: [
    Text(title,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: _accent)),
    const SizedBox(height: 4),
    Container(height: 0.8, color: _rule),
    const SizedBox(height: 6),
  ]),
);

Widget _expBlock(
    String company, String role, String dates, List<String> bullets) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(company,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _accent)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(role,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: _ink))),
          const SizedBox(width: 8),
          Text(dates,
              style: const TextStyle(fontSize: 9.5, color: _muted)),
        ]),
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 5),
          ...bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('•  ',
                  style: TextStyle(fontSize: 10, color: _mid)),
              Expanded(child: Text(b,
                  style: const TextStyle(
                      fontSize: 10.5, color: _mid, height: 1.5))),
            ]),
          )),
        ],
      ]),
    );

Widget _eduBlock(String institution, String degree, String period) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(institution,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _accent)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(degree,
              style: const TextStyle(fontSize: 11, color: _ink))),
          const SizedBox(width: 8),
          Text(period,
              style: const TextStyle(fontSize: 9.5, color: _muted)),
        ]),
      ]),
    );

// ── Main widget ───────────────────────────────────────────────────────────────
class PreviewMeridian extends StatelessWidget {
  const PreviewMeridian({super.key});

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
              padding: const EdgeInsets.fromLTRB(44, 22, 44, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Centred header ────────────────────────────────────
                  Column(children: [
                    Text(_name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900,
                            color: _ink, letterSpacing: 1.5, height: 1.1)),
                    const SizedBox(height: 4),
                    Text(_title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: _accent,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 7),
                    // Bullet-separated contact row
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        for (final (i, part) in [
                          _phone, _email, _web, _loc
                        ].indexed) ...[
                          if (i > 0)
                            const Text('  •  ',
                                style: TextStyle(
                                    fontSize: 9.5, color: _muted)),
                          Text(part,
                              style: const TextStyle(
                                  fontSize: 9.5, color: _muted)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 0.7, color: _rule),
                  ]),
                  const SizedBox(height: 14),

                  // ── Summary ───────────────────────────────────────────
                  _sectionHeader('Summary'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_summary,
                        style: const TextStyle(
                            fontSize: 10.5, color: _mid, height: 1.55)),
                  ),

                  // ── Experience ────────────────────────────────────────
                  _sectionHeader('Experience'),
                  for (final e in _exp)
                    _expBlock(e.$1, e.$2, e.$3, e.$4),

                  // ── Education ─────────────────────────────────────────
                  _sectionHeader('Education'),
                  for (final e in _edu)
                    _eduBlock(e.$1, e.$2, e.$3),
                  const SizedBox(height: 8),

                  // ── Skills ────────────────────────────────────────────
                  _sectionHeader('Skills'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Wrap(spacing: 8, runSpacing: 6,
                      children: _skills.map((s) => Text(s,
                          style: const TextStyle(
                              fontSize: 10.5, color: _mid))).toList()),
                  ),

                  // ── Languages ─────────────────────────────────────────
                  _sectionHeader('Languages'),
                  Wrap(spacing: 20, runSpacing: 5,
                    children: _langs.map((l) => Text(l,
                        style: const TextStyle(
                            fontSize: 10.5, color: _mid))).toList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}