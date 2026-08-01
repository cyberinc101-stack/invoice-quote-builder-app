// cv_fullscreen_preview_individual_files/preview_infographic.dart
// Full-screen scrollable preview for Template 11 – Infographic
// Matches MiniPreview11Infographic exactly

import 'package:flutter/material.dart';
import 'dart:math' as math;

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

// Colours matching MiniPreview11Infographic exactly
const _bg      = Color(0xFF1E293B);
const _surface = Color(0xFF253044);
const _cyan    = Color(0xFF06B6D4);
const _violet  = Color(0xFF8B5CF6);
const _orange  = Color(0xFFF59E0B);
const _muted   = Color(0xFF94A3B8);
const _white   = Color(0xFFE6EDF3);

// Replaces withOpacity – pre-computed alpha colours
const _cyanBg15     = Color(0x26C3E4F0);
const _cyanBorder   = Color(0x4006B6D4);
const _cyanBorder40 = Color(0x6606B6D4);
const _violetGlow   = Color(0x808B5CF6);
const _orangeBg15   = Color(0x26F59E0B);
const _surfaceBorder= Color(0x0AFFFFFF);
const _mutedLine    = Color(0x80C3CCD4);
const _mutedLine45  = Color(0x7394A3B8);
const _mutedLine40  = Color(0x6694A3B8);
const _mutedLine35  = Color(0x5994A3B8);
const _mutedLine30  = Color(0x4D94A3B8);
const _mutedLine25  = Color(0x4094A3B8);
const _gradDivL     = Color(0x0006B6D4);
const _gradDivR     = Color(0x0006B6D4);

// References card style – cyan left border on surface
const _cyanLeftBorder = Color(0xFF06B6D4);

Widget _bar(double w, double h, Color c, {double r = 2}) =>
    Container(
      width: w, height: h,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
    );

Widget _textLine(double w, Color c, {double h = 3.0}) => _bar(w, h, c);

Widget _dot(double r, Color c) =>
    Container(
      width: r * 2, height: r * 2,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;
  const _RingPainter(this.progress, this.color, {this.bg = _bg});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    canvas.drawCircle(c, r,
        Paint()..color = bg..strokeWidth = 3..style = PaintingStyle.stroke);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

Widget _pill(IconData icon, String t) => Container(
  margin: const EdgeInsets.only(bottom: 5),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _cyanBorder),
  ),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: _cyan),
    const SizedBox(width: 5),
    Text(t, style: const TextStyle(fontSize: 11, color: _muted)),
  ]),
);

Widget _infoH(String t, Color c) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(children: [
    _bar(3, 16, c, r: 1),
    const SizedBox(width: 7),
    Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c, letterSpacing: 2)),
  ]),
);

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(top: 6), child: _dot(3, _cyan)),
    const SizedBox(width: 8),
    Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: _muted, height: 1.5))),
  ]),
);

class PreviewInfographic extends StatelessWidget {
  const PreviewInfographic({super.key});

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
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // ── Header ────────────────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 8),
                // Gradient divider
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _gradDivL, _cyan, _violet, _gradDivR,
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Body ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Left col – skills + education + references
                      SizedBox(width: 148, child: _buildLeftCol()),
                      const SizedBox(width: 18),
                      // Right col – about + experience + languages
                      Expanded(child: _buildRightCol()),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: Row(children: [
        // Avatar with ring
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 76, height: 76,
            child: CustomPaint(painter: _RingPainter(0.82, _cyan, bg: _surface)),
          ),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _cyanBorder40, width: 1.5),
              color: _surface,
            ),
            child: const Icon(Icons.person_rounded, color: _cyan, size: 28),
          ),
        ]),
        const SizedBox(height: 16),
        const SizedBox(width: 16),
        // Name + title
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: const TextSpan(children: [
            TextSpan(text: 'Alexandra ', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: _white,
                letterSpacing: -0.3, height: 1.1)),
            TextSpan(text: 'Chen', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: _cyan,
                letterSpacing: -0.3, height: 1.1)),
          ])),
          const SizedBox(height: 4),
          Text(_title, style: const TextStyle(fontSize: 11, color: _muted, letterSpacing: 0.5)),
        ])),
        const SizedBox(width: 16),
        // Contact pills
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _pill(Icons.email_outlined, _email),
          _pill(Icons.phone_outlined, _phone),
          _pill(Icons.location_on_outlined, _loc),
          _pill(Icons.language_outlined, _web),
        ]),
      ]),
    );
  }

  Widget _buildLeftCol() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Skills with circular ring indicators
      _infoH('EXPERTISE', _cyan),
      const SizedBox(height: 4),
      ..._skills.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          SizedBox(
            width: 38, height: 38,
            child: CustomPaint(
              painter: _RingPainter(s.$2, _cyan, bg: _surface),
              child: Center(child: Text(
                '${(s.$2 * 100).round()}',
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800, color: _cyan),
              )),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(s.$1, style: const TextStyle(
              fontSize: 12, color: _white, fontWeight: FontWeight.w500))),
        ]),
      )),
      const SizedBox(height: 10),
      // Education
      _infoH('EDUCATION', _orange),
      const SizedBox(height: 4),
      ..._edu.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(7),
          border: const Border(left: BorderSide(color: _orange, width: 3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.$2, style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _white)),
          Text(e.$1, style: const TextStyle(fontSize: 10, color: _muted)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _orangeBg15,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(e.$3, style: const TextStyle(
                fontSize: 10, color: _orange, fontWeight: FontWeight.w700)),
          ),
          Text(e.$4, style: const TextStyle(
              fontSize: 10, color: _muted, fontStyle: FontStyle.italic)),
        ]),
      )),
      const SizedBox(height: 10),
      // Certifications
      _infoH('CERTIFICATIONS', _orange),
      const SizedBox(height: 4),
      ..._certs.map((c) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(7),
          border: const Border(left: BorderSide(color: _orange, width: 3)),
        ),
        child: Text(c, style: const TextStyle(
            fontSize: 10.5, color: _muted, height: 1.4)),
      )),
      const SizedBox(height: 10),
      // References
      _infoH('REFERENCES', _cyan),
      const SizedBox(height: 4),
      ..._refs.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(7),
          border: const Border(left: BorderSide(color: _cyanLeftBorder, width: 3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.$1, style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _white)),
          const SizedBox(height: 2),
          Text(r.$2, style: const TextStyle(
              fontSize: 10, color: _cyan, fontWeight: FontWeight.w600)),
          if (r.$3.isNotEmpty)
            Text(r.$3, style: const TextStyle(fontSize: 10, color: _muted)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.email_outlined, size: 10, color: _cyan),
            const SizedBox(width: 4),
            Expanded(child: Text(r.$4,
                style: const TextStyle(fontSize: 9, color: _muted),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.phone_outlined, size: 10, color: _cyan),
            const SizedBox(width: 4),
            Expanded(child: Text(r.$5,
                style: const TextStyle(fontSize: 9, color: _muted),
                overflow: TextOverflow.ellipsis)),
          ]),
        ]),
      )),
    ]);
  }

  Widget _buildRightCol() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // About
      _infoH('ABOUT', _cyan),
      Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cyanBorder),
        ),
        child: Text(_summary, style: const TextStyle(
            fontSize: 12, color: _muted, height: 1.7)),
      ),
      // Experience with violet timeline
      _infoH('EXPERIENCE', _violet),
      const SizedBox(height: 4),
      ..._exp.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Timeline dot + line
          Column(children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: _violet,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: _violetGlow,
                  blurRadius: 8,
                  spreadRadius: 2,
                )],
              ),
            ),
            Container(
              width: 2, height: 90,
              decoration: BoxDecoration(
                color: const Color(0x338B5CF6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          // Card
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _surfaceBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(e.$2, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: _cyan))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _cyanBg15,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(e.$3, style: const TextStyle(
                      fontSize: 9.5, color: _cyan)),
                ),
              ]),
              Text(e.$1, style: const TextStyle(
                  fontSize: 11.5, color: _muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              ...e.$4.map(_bullet),
            ]),
          )),
        ]),
      )),
      const SizedBox(height: 6),
      // Languages
      _infoH('LANGUAGES', _cyan),
      const SizedBox(height: 4),
      Wrap(spacing: 10, runSpacing: 8, children: _langs.map((l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cyanBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(4, _cyan),
          const SizedBox(width: 6),
          Text(l, style: const TextStyle(fontSize: 11.5, color: _muted)),
        ]),
      )).toList()),
    ]);
  }
}