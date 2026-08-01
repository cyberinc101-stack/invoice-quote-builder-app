// preview_momentum.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/cv_fullscreen_preview_individual_files/preview_momentum.dart
//
// Full-screen hold-to-preview for the VANGUARD / MOMENTUM template (ID 24).
// Uses SingleChildScrollView + FittedBox(fitWidth) pattern — same as
// preview_art_deco.dart and preview_collins.dart — so no overflow occurs.
// Visual style: large bold name, accent job title, icon contact row,
// ALL-CAPS bold section labels, timeline layout with date + dot + content.
// Vivian Jennings Head of Sales sample data.

import 'package:flutter/material.dart';

// ── Sample data ───────────────────────────────────────────────────────────────
const _name  = 'Vivian Jennings';
const _title = 'Head of Sales';
const _email = 'vivian@enhancv.com';
const _phone = '+1-000-000';
const _loc   = 'Detroit, MI';
const _web   = 'linkedin.com/in/vivian-jennings';

const _exp = [
  ('2018 – Present', 'Detroit, MI', 'Sales Director', 'AY Security Services', [
    'Developed talent management plan reducing department turnover by 20% and '
    'increasing quota surpass by 25%',
    'Developed growth strategy for a new technical sales department with \$3M annual sales',
    'Revamped account executive system — 30% growth in key partnerships, '
    '7 new Fortune 500 clients',
  ]),
  ('2015 – 2018', 'Detroit, MI', 'National Sales Director', 'AY Security Services', [
    'Expanded technical sales department over 20 new states and 15 countries',
    'Led enterprise-wide sales software update reducing support cost by 30% per client',
  ]),
  ('2012 – 2015', 'Detroit, MI', 'Regional Sales Manager – MENA', 'Heller', [
    'Improved parts logistics by setting up 2 additional PDCs (from 1 to 3)',
    'Closed Revenue USD 22M in Professional Services and USD 10M in Licenses',
    'Achieved 14% growth in specification sales to Architects and End-Users',
  ]),
  ('2008 – 2012', 'Detroit, MI', 'Sales Executive', 'Renner-Kub', [
    'Appointed member of Avanade Global Sales Advisory Panel',
    'Developed robust pipeline (>\$3.2M) within 90 days upon arrival',
    'Increased merchandise sales by 800% in 3 years',
  ]),
];

const _edu = [
  ('2011 – 2012', 'MBA in Marketing',      'University of Pittsburgh'),
  ('2006 – 2010', 'Bachelor of Marketing', 'University of Pennsylvania'),
];

const _skills = [
  'Sales Leadership', 'Team Management', 'Revenue Growth', 'Strategic Planning',
];

// ── Palette (Momentum: green accent, white bg) ────────────────────────────────
const _accent = Color(0xFF1A7A4A);
const _ink    = Color(0xFF1A1A1A);
const _mid    = Color(0xFF333333);
const _muted  = Color(0xFF777777);
const _rule   = Color(0xFFD0D0D0);

// ── Shared helpers ────────────────────────────────────────────────────────────
const double _dateColW = 82.0;
const double _dotColW  = 20.0;
const double _gapCol   =  8.0;

Widget _sectionLabel(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: _ink, letterSpacing: 1.5)),
    const SizedBox(height: 5),
    Container(height: 0.7, color: _rule),
    const SizedBox(height: 6),
  ]),
);

Widget _timelineExp(
    String date, String location, String role, String company,
    List<String> bullets) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date + location col
        SizedBox(
          width: _dateColW,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(date,
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 2),
            Text(location,
                style: const TextStyle(fontSize: 8.5, color: _muted)),
          ]),
        ),
        const SizedBox(width: _gapCol),
        // Dot
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
                color: _accent, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5)),
          ),
        ),
        const SizedBox(width: _gapCol),
        // Content
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(role,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 1),
          Text(company,
              style: const TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, color: _accent)),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 5),
            ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(width: 4, height: 4,
                      decoration: BoxDecoration(
                          color: _muted.withOpacity(0.5),
                          shape: BoxShape.circle)),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(b,
                    style: const TextStyle(
                        fontSize: 10.5, color: _mid, height: 1.5))),
              ]),
            )),
          ],
        ])),
      ]),
    );

Widget _timelineEdu(String date, String degree, String institution) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: _dateColW,
          child: Text(date,
              style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: _ink)),
        ),
        const SizedBox(width: _gapCol),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
                color: _accent, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5)),
          ),
        ),
        const SizedBox(width: _gapCol),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(degree,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
          Text(institution,
              style: const TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, color: _accent)),
        ])),
      ]),
    );

// ── Main widget ───────────────────────────────────────────────────────────────
class PreviewMomentum extends StatelessWidget {
  const PreviewMomentum({super.key});

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
              padding: const EdgeInsets.fromLTRB(40, 24, 40, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Header ────────────────────────────────────────────
                  Text(_name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900,
                          color: _ink, height: 1.05)),
                  const SizedBox(height: 3),
                  Text(_title,
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600,
                          color: _accent)),
                  const SizedBox(height: 8),
                  // Icon contact row
                  Wrap(spacing: 16, runSpacing: 4,
                    children: [
                      _contactChip(Icons.phone_outlined, _phone),
                      _contactChip(Icons.email_outlined, _email),
                      _contactChip(Icons.location_on_outlined, _loc),
                      _contactChip(Icons.link, _web),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1.2,
                      color: _accent.withOpacity(0.25)),
                  const SizedBox(height: 16),

                  // ── Experience ────────────────────────────────────────
                  _sectionLabel('EXPERIENCE'),
                  for (final e in _exp)
                    _timelineExp(e.$1, e.$2, e.$3, e.$4, e.$5),

                  const SizedBox(height: 4),

                  // ── Education ─────────────────────────────────────────
                  _sectionLabel('EDUCATION'),
                  for (final e in _edu)
                    _timelineEdu(e.$1, e.$2, e.$3),

                  const SizedBox(height: 4),

                  // ── Skills ────────────────────────────────────────────
                  _sectionLabel('SKILLS'),
                  Wrap(spacing: 10, runSpacing: 8,
                    children: _skills.map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: _accent.withOpacity(0.35)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 10.5, color: _mid)),
                    )).toList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactChip(IconData icon, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: _accent),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 9.5, color: _muted)),
      ]);
}