// preview_diplomat.dart
// lib/screens/cv_edit_section/cv_template_chooser_01/cv_fullscreen_preview_individual_files/preview_diplomat.dart
//
// Full-screen hold-to-preview for the DIPLOMAT template (ID 22).
// Uses SingleChildScrollView + FittedBox(fitWidth) pattern — same as
// preview_art_deco.dart and preview_collins.dart — so no overflow occurs.
// Visual style: centred name header, double rule, shaded section boxes,
//  ·  diamond bullets with dotted leader lines. Tiffany Giroux sample data.

import 'package:flutter/material.dart';

// ── Sample data ───────────────────────────────────────────────────────────────
const _name  = 'Tiffany Giroux';
const _title = 'Freight & Logistics Analyst';
const _email = 'tiffgiroux@hotmail.com';
const _phone = '001 415 570 5567';
const _loc   = '18 Harmony Drive';

const _summary =
    'Results-oriented Freight & Logistics Analyst with over 12 years of experience '
    'in transportation management, cost reduction and cross-functional team leadership. '
    'Proven record of optimising supply-chain operations for Fortune 500 automotive clients.';

const _exp = [
  (' ·   Freight Audit & Logistics Analyst – Ford',
   'July 2014 – Current', [
    'Managed end-to-end freight audit process, recovering \$1.2M in overcharges annually.',
    'Designed KPI dashboards adopted company-wide, reducing reporting cycle to same-day.',
    'Led RFP process for international freight contracts valued at \$8M.',
  ]),
  (' ·   Senior Logistics Business Analyst – Honda',
   'May 2012 – June 2014', [
    'Delivered \$600K annual savings through carrier lane consolidation.',
    'Implemented TMS upgrade for 3 distribution centres on time and 15% under budget.',
  ]),
  (' ·   Senior Logistics Coordinator – Honda',
   'May 2011 – May 2012', [
    'Coordinated daily inbound/outbound shipments for 6 manufacturing plants.',
    'Reduced average transit time by 18% through route optimisation.',
  ]),
];

const _edu = [
  (' ·   Postgraduate Diploma – Management Studies',
   'Hertfordshire Business School', 'Sep 2009 – Sep 2010'),
  (' ·   Management Studies',
   'University of Hertfordshire', 'Sep 2007 – Sep 2009'),
];

const _skills = [
  'Freight Audit', 'TMS / WMS Systems', 'Contract Negotiation',
  'Data Analysis', 'Process Improvement',
];
const _langs = ['English (Native)', 'French (Conversational)'];
const _certs = ['Certified Transportation Professional (CTP)', 'Six Sigma Green Belt'];

// ── Palette ───────────────────────────────────────────────────────────────────
const _ink   = Color(0xFF1A1A1A);
const _mid   = Color(0xFF333333);
const _muted = Color(0xFF666666);
const _rule  = Color(0xFF888888);
const _shade = Color(0xFFF5F5F5);

// ── Shared helpers ────────────────────────────────────────────────────────────
Widget _doubleRule() => Column(children: [
  Container(height: 1.2, color: _rule),
  const SizedBox(height: 2),
  Container(height: 1.2, color: _rule),
]);

Widget _sectionBox(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Column(children: [
    _doubleRule(),
    const SizedBox(height: 3),
    Container(
      width: double.infinity,
      color: _shade,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: _ink, letterSpacing: 2.5)),
    ),
    const SizedBox(height: 10),
  ]),
);

Widget _expBlock(String title, String dates, List<String> bullets) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Diamond + dotted leader + dates row
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
          Flexible(child: Text(title,
              style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: _ink),
              overflow: TextOverflow.ellipsis, softWrap: false)),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CustomPaint(
                size: const Size(double.infinity, 8),
                painter: _DotsPainter()),
          )),
          Text(dates,
              style: const TextStyle(fontSize: 10, color: _muted)),
        ]),
        const SizedBox(height: 5),
        // First bullet = italic summary
        if (bullets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(bullets.first,
                style: const TextStyle(
                    fontSize: 10.5, height: 1.55,
                    fontStyle: FontStyle.italic, color: _mid)),
          ),
        // Remaining bullets
        ...bullets.skip(1).map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•  ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: _ink)),
            Expanded(child: Text(b,
                style: const TextStyle(
                    fontSize: 10.5, color: _mid, height: 1.45))),
          ]),
        )),
      ]),
    );

Widget _eduBlock(String title, String institution, String dates) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
          Flexible(child: Text(title,
              style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: _ink),
              overflow: TextOverflow.ellipsis, softWrap: false)),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CustomPaint(
                size: const Size(double.infinity, 8),
                painter: _DotsPainter()),
          )),
          Text(dates,
              style: const TextStyle(fontSize: 10, color: _muted)),
        ]),
        const SizedBox(height: 2),
        Text(institution,
            style: const TextStyle(fontSize: 10, color: _muted)),
      ]),
    );

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF999999).withOpacity(0.5)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(x + 0.5, size.height / 2), paint);
      x += 2.5;
    }
  }
  @override bool shouldRepaint(_DotsPainter old) => false;
}

// ── Main widget ───────────────────────────────────────────────────────────────
class PreviewDiplomat extends StatelessWidget {
  const PreviewDiplomat({super.key});

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
              padding: const EdgeInsets.fromLTRB(48, 22, 48, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Centred header ────────────────────────────────────
                  Column(children: [
                    Text(_name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: _ink, height: 1.1)),
                    const SizedBox(height: 4),
                    Text(_title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: _mid)),
                    const SizedBox(height: 6),
                    Text('$_loc  ·  $_phone  ·  $_email',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9.5, color: _muted, height: 1.4)),
                    const SizedBox(height: 10),
                    _doubleRule(),
                  ]),
                  const SizedBox(height: 12),

                  // ── Profile ───────────────────────────────────────────
                  _sectionBox('PROFILE'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(_summary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10.5, height: 1.6,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: _mid)),
                  ),

                  // ── Experience ────────────────────────────────────────
                  _sectionBox('EXPERIENCE'),
                  for (final e in _exp)
                    _expBlock(e.$1, e.$2, e.$3),

                  // ── Education ─────────────────────────────────────────
                  _sectionBox('EDUCATION'),
                  for (final e in _edu)
                    _eduBlock(e.$1, e.$2, e.$3),
                  const SizedBox(height: 6),

                  // ── Skills ────────────────────────────────────────────
                  _sectionBox('SKILLS'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Wrap(spacing: 24, runSpacing: 5,
                      children: _skills.map((s) => Text(s,
                          style: const TextStyle(
                              fontSize: 10.5, color: _mid))).toList()),
                  ),

                  // ── Languages ─────────────────────────────────────────
                  _sectionBox('LANGUAGES'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Wrap(spacing: 30, runSpacing: 5,
                      children: _langs.map((l) => Text(l,
                          style: const TextStyle(
                              fontSize: 10.5, color: _mid))).toList()),
                  ),

                  // ── Certifications ────────────────────────────────────
                  _sectionBox('CERTIFICATIONS'),
                  ...(_certs.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text(' ·   ',
                          style: TextStyle(fontSize: 10, color: _ink)),
                      Expanded(child: Text(c,
                          style: const TextStyle(
                              fontSize: 10.5, color: _mid))),
                    ]),
                  ))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}