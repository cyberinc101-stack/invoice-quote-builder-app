// cv_fullscreen_preview_individual_files/preview_exec.dart
// Full-screen scrollable preview for Template 01 – Executive

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

const _navy  = Color(0xFF0D1B2A);
const _navyL = Color(0xFF1B2E45);
const _gold  = Color(0xFFC9A84C);
const _bg    = Color(0xFFF8F9FC);
const _ink   = Color(0xFF1A1A2E);
const _grey  = Color(0xFF64748B);

Widget _bar(double w, double h, Color c) => Container(
    width: w, height: h,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)));

Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(width: 5, height: 5,
          decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(t,
        style: const TextStyle(fontSize: 12, color: _grey, height: 1.5))),
  ]),
);

Widget _skillRow(String name, double pct) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(name, style: const TextStyle(
          fontSize: 11, color: Color(0xB3FFFFFF), fontWeight: FontWeight.w500))),
      Text('${(pct * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: Color(0x61FFFFFF))),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(height: 4, child: Row(children: [
        Flexible(flex: (pct * 100).round(),
            child: const ColoredBox(color: _gold, child: SizedBox.expand())),
        Flexible(flex: 100 - (pct * 100).round(),
            child: const ColoredBox(color: Color(0x1FFFFFFF),
                child: SizedBox.expand())),
      ])),
    ),
  ]),
);

Widget _sideHead(String t) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(t, style: const TextStyle(
        color: _gold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
    const SizedBox(height: 4),
    Container(height: 1, color: const Color(0x59C9A84C)),
    const SizedBox(height: 8),
  ],
);

Widget _mainHead(String t) => Row(children: [
  _bar(3, 16, _gold), const SizedBox(width: 8),
  Text(t, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 2)),
]);

class PreviewExec extends StatelessWidget {
  const PreviewExec({super.key});

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
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSidebar(),
                  Expanded(child: _buildMain()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 148,
      color: _navy,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 2),
              color: _navyL),
          child: const Icon(Icons.person_rounded, color: Color(0x4DFFFFFF), size: 36),
        )),
        const SizedBox(height: 18),
        _sideHead('CONTACT'),
        ...[
          (Icons.email_outlined,       _email),
          (Icons.phone_outlined,       _phone),
          (Icons.location_on_outlined, _loc),
          (Icons.language_outlined,    _web),
        ].map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(c.$1, color: _gold, size: 11),
            const SizedBox(width: 6),
            Expanded(child: Text(c.$2, style: const TextStyle(
                color: Color(0x99FFFFFF), fontSize: 10.5, height: 1.4))),
          ]),
        )),
        const SizedBox(height: 14),
        _sideHead('SKILLS'),
        ..._skills.map((s) => _skillRow(s.$1, s.$2)),
        const SizedBox(height: 14),
        _sideHead('LANGUAGES'),
        ..._langs.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(l, style: const TextStyle(
                color: Color(0x99FFFFFF), fontSize: 10.5)))),
        const SizedBox(height: 14),
        _sideHead('CERTIFICATIONS'),
        ..._certs.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 4),
                child: Container(width: 4, height: 4,
                    decoration: const BoxDecoration(
                        color: _gold, shape: BoxShape.circle))),
            const SizedBox(width: 6),
            Expanded(child: Text(c, style: const TextStyle(
                color: Color(0x8AFFFFFF), fontSize: 10.5, height: 1.35))),
          ]),
        )),
        const SizedBox(height: 14),
        _sideHead('PERSONAL REFERENCES'),
        ..._refs.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.$1, style: const TextStyle(
                color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 1),
            Text(r.$2, style: const TextStyle(
                color: _gold, fontSize: 10, fontWeight: FontWeight.w600)),
            if (r.$3.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(r.$3, style: const TextStyle(
                  color: Color(0x80FFFFFF), fontSize: 10)),
            ],
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.email_outlined, color: Color(0x80FFFFFF), size: 10),
              const SizedBox(width: 4),
              Expanded(child: Text(r.$4, style: const TextStyle(
                  color: Color(0x80FFFFFF), fontSize: 9.5),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.phone_outlined, color: Color(0x80FFFFFF), size: 10),
              const SizedBox(width: 4),
              Text(r.$5, style: const TextStyle(
                  color: Color(0x80FFFFFF), fontSize: 9.5)),
            ]),
          ]),
        )),
      ]),
    );
  }

  Widget _buildMain() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_name.toUpperCase(), style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900,
            color: _ink, letterSpacing: 3)),
        const SizedBox(height: 6),
        Text(_title, style: const TextStyle(
            fontSize: 12, color: _grey,
            letterSpacing: 1.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        _mainHead('PROFILE'), const SizedBox(height: 10),
        Text(_summary, style: const TextStyle(
            fontSize: 12, color: _grey, height: 1.7)),
        const SizedBox(height: 22),
        _mainHead('EXPERIENCE'), const SizedBox(height: 12),
        ..._exp.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 5),
                child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: _gold, shape: BoxShape.circle))),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(e.$2, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _ink))),
                const SizedBox(width: 6),
                Text(e.$3, style: const TextStyle(fontSize: 11, color: _grey)),
              ]),
              Text(e.$1, style: const TextStyle(
                  fontSize: 12, color: _gold, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...e.$4.map(_bullet),
            ])),
          ]),
        )),
        _mainHead('EDUCATION'), const SizedBox(height: 12),
        ..._edu.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 3),
                child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: _gold, shape: BoxShape.circle))),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(e.$2, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _ink))),
                const SizedBox(width: 6),
                Text(e.$3, style: const TextStyle(fontSize: 11, color: _grey)),
              ]),
              Text(e.$1, style: const TextStyle(fontSize: 12, color: _gold)),
              Text(e.$4, style: const TextStyle(
                  fontSize: 11, color: _grey, fontStyle: FontStyle.italic)),
            ])),
          ]),
        )),
      ]),
    );
  }
}