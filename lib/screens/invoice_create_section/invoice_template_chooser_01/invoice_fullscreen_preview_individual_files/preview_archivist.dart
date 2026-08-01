// preview_archivist.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/cv_fullscreen_preview_individual_files/preview_archivist.dart
//
// Full-screen hold-to-preview for the ARCHIVIST template (ID 21).
// Renders the real Archival layout using the same pattern as preview_art_deco.dart
// and preview_collins.dart — SingleChildScrollView + FittedBox(fitWidth) + fixed
// 480-wide SizedBox — so no Transform.scale overflow occurs.

import 'package:flutter/material.dart';

// ── Sample data ───────────────────────────────────────────────────────────────
const _name  = 'Jacqueline Thompson';
const _title = 'Results-Oriented Engineering Executive';
const _email = 'hello@reallygreatsite.com';
const _phone = '123-456-7890';
const _loc   = 'St. Any City';
const _web   = 'reallygreatsite.com';

const _summary =
    'Results-oriented Engineering Executive with a proven track record of optimising '
    'project outcomes. Skilled in strategic project management and team leadership. '
    'Seeking a challenging executive role to leverage technical expertise and drive '
    'engineering excellence.';

const _exp = [
  ('Engineering Executive', 'Borcelle Technologies', 'Jan 2023 – Present', [
    'Implemented cost-effective solutions, resulting in a 20% reduction in project expenses.',
    'Streamlined project workflows, enhancing overall efficiency by 25%.',
    'Led a team in successfully delivering a complex engineering project on time and within budget.',
  ]),
  ('Project Engineer', 'Safford & Co', 'Mar 2021 – Dec 2022', [
    'Managed project timelines, reducing delivery times by 30%.',
    'Spearheaded the adoption of cutting-edge engineering software, improving accuracy by 15%.',
    'Collaborated with cross-functional teams, enhancing project success rates by 10%.',
  ]),
  ('Engineering Manager', 'Amazon Industries', 'Feb 2020 – Jan 2021', [
    'Coordinated project tasks, ensuring adherence to engineering standards and regulations.',
    'Conducted comprehensive project analyses, identifying discrepancies in engineering designs.',
  ]),
];

const _edu = [
  ('Master of Science in Mechanical Engineering',
   'University of Engineering and Technology',
   'Sep 2019 – Oct 2020',
   'Specialisation: Precision Manufacturing.',
   'Thesis on "Innovations in Sustainable Engineering Practices".'),
  ('Bachelor of Science in Civil Engineering',
   'City College of Engineering',
   'Aug 2015 – Aug 2019',
   null,
   'Relevant coursework in Structural Design and Project Management.'),
];

const _skills = [
  'Python', 'Structural Analysis', 'Robotics & Automation', 'CAD',
];
const _langs  = ['English', 'Malay', 'German'];
const _certs  = [
  'Professional Engineer (PE) License',
  'Project Management Professional (PMP)',
  'Engineering Excellence Award – Borcelle Technologies',
];

// ── Palette (Archival: pure black/white, no accent colour) ───────────────────
const _ink   = Color(0xFF1A1A1A);
const _mid   = Color(0xFF3C3C3C);
const _muted = Color(0xFF888888);
const _rule  = Color(0xFFBBBBBB);
const _label = Color(0xFF2B2B2B);

// ── Shared helpers ────────────────────────────────────────────────────────────
const double _labelColW = 88.0;
const double _gap       = 14.0;

Widget _hRule() => Container(height: 0.7, color: _rule);

Widget _thinRule() => Container(height: 0.5, color: _rule);

/// Section row: left label col + right content col separated by a rule above.
Widget _sectionRow(String label, Widget content) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _hRule(),
    const SizedBox(height: 10),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: _labelColW,
        child: Text(label,
            style: const TextStyle(
                fontSize: 8, fontWeight: FontWeight.w700,
                color: _label, letterSpacing: 1.2)),
      ),
      const SizedBox(width: _gap),
      Expanded(child: content),
    ]),
    const SizedBox(height: 2),
  ],
);

Widget _expBlock(
    String role, String company, String duration, List<String> bullets) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text('$role, $company',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _ink))),
      ]),
      const SizedBox(height: 2),
      Text(duration,
          style: const TextStyle(fontSize: 9.5, color: _muted,
              fontStyle: FontStyle.italic)),
      if (bullets.isNotEmpty) ...[
        const SizedBox(height: 5),
        ...bullets.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•  ',
                style: TextStyle(fontSize: 10, color: _mid)),
            Expanded(child: Text(b,
                style: const TextStyle(
                    fontSize: 10, color: _mid, height: 1.5))),
          ]),
        )),
      ],
    ]),
  );
}

Widget _eduBlock(
    String degree, String institution, String period,
    String? detail, String? bullet) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(degree,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
      Text(institution,
          style: const TextStyle(
              fontSize: 10, fontStyle: FontStyle.italic, color: _mid)),
      Text(period,
          style: const TextStyle(fontSize: 9.5, color: _muted)),
      if (detail != null) ...[
        const SizedBox(height: 3),
        Text(detail,
            style: const TextStyle(fontSize: 9.5, color: _muted)),
      ],
      if (bullet != null) ...[
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('1.  ',
              style: TextStyle(fontSize: 10, color: _mid)),
          Expanded(child: Text(bullet,
              style: const TextStyle(
                  fontSize: 10, color: _mid, height: 1.4))),
        ]),
      ],
    ]),
  );
}

// ── Main widget ───────────────────────────────────────────────────────────────
class PreviewArchivist extends StatelessWidget {
  const PreviewArchivist({super.key});

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
              padding: const EdgeInsets.fromLTRB(42, 28, 42, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Centred header ─────────────────────────────────────
                  Column(children: [
                    Text('$_name, $_title',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: _ink, height: 1.2)),
                    const SizedBox(height: 6),
                    Text('$_loc  –  $_phone  –  $_email  –  $_web',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9, color: _mid, height: 1.4)),
                    const SizedBox(height: 12),
                    _hRule(),
                  ]),
                  const SizedBox(height: 4),

                  // ── Profile ────────────────────────────────────────────
                  _sectionRow('PROFILE',
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_summary,
                          style: const TextStyle(
                              fontSize: 10, color: _mid, height: 1.6)),
                    ),
                  ),

                  // ── Education ─────────────────────────────────────────
                  _sectionRow('EDUCATION',
                    Column(children: [
                      for (final e in _edu)
                        _eduBlock(e.$1, e.$2, e.$3, e.$4, e.$5),
                    ]),
                  ),

                  // ── Experience ────────────────────────────────────────
                  _sectionRow('EXPERIENCE',
                    Column(children: [
                      for (final e in _exp)
                        _expBlock(e.$1, e.$2, e.$3, e.$4),
                    ]),
                  ),

                  // ── Skills ────────────────────────────────────────────
                  _sectionRow('SKILLS',
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Wrap(
                        spacing: 32,
                        runSpacing: 4,
                        children: _skills.map((s) => Text(s,
                            style: const TextStyle(
                                fontSize: 10, color: _ink,
                                fontWeight: FontWeight.w500))).toList(),
                      ),
                    ),
                  ),

                  // ── Languages ─────────────────────────────────────────
                  _sectionRow('LANGUAGES',
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Wrap(
                        spacing: 40,
                        children: _langs.map((l) => Text(l,
                            style: const TextStyle(
                                fontSize: 10, color: _ink))).toList(),
                      ),
                    ),
                  ),

                  // ── Certifications ────────────────────────────────────
                  _sectionRow('CERTIFICATIONS',
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _certs.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(c,
                              style: const TextStyle(
                                  fontSize: 10, color: _ink)),
                        )).toList(),
                      ),
                    ),
                  ),

                  // ── Footer rule ───────────────────────────────────────
                  const SizedBox(height: 8),
                  _thinRule(),
                  const SizedBox(height: 6),
                  Text('1 / 1',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 8, color: _muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}