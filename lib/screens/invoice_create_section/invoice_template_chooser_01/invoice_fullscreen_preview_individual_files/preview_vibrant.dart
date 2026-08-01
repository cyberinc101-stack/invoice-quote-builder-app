// cv_fullscreen_preview_individual_files/preview_vibrant.dart
// Full-screen scrollable preview for Template 03 – Vibrant
// Matches MiniPreview03Vibrant exactly

import 'package:flutter/material.dart';

const _name    = 'Alexandra Chen';
const _title   = 'Senior Product Designer';
const _email   = 'alex.chen@email.com';
const _phone   = '+1 (555) 234-5678';
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
const _certs = ['Google UX Design Certificate', 'Interaction Design Foundation'];
const _refs = [
  ('James Smith', 'Engineering Manager', 'Acme Corp', 'j.smith@acme.com', '+1 555 010 1234'),
  ('Sarah Lee',   'Design Director',     'Globex',    's.lee@globex.com',  '+1 555 020 5678'),
];

// Colours matching MiniPreview03Vibrant exactly
const _coral        = Color(0xFFFF5C35);
const _pale         = Color(0xFFFFF1EE);
const _dark         = Color(0xFF1A1A1A);
const _mid          = Color(0xFF555555);
const _avatarFill   = Color(0x2EFFFFFF);
const _coralBg10    = Color(0x1AFF5C35);
const _coralBorder30= Color(0x4DFF5C35);

// ── Section heading ───────────────────────────────────────────────────────────
Widget _sectionHead(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(children: [
    Container(
      width: 16, height: 2.5,
      decoration: BoxDecoration(
          color: _coral, borderRadius: BorderRadius.circular(2)),
    ),
    const SizedBox(width: 8),
    Flexible(child: Text(t, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w800,
        color: _dark, letterSpacing: 1.5))),
  ]),
);

// ── Bullet row for main content ───────────────────────────────────────────────
Widget _bullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(width: 5, height: 5,
          decoration: const BoxDecoration(
              color: _coral, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(t, style: const TextStyle(
        fontSize: 12, color: _mid, height: 1.5))),
  ]),
);

// ── Sidebar bullet row ────────────────────────────────────────────────────────
Widget _sidebarBullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 9),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(width: 5, height: 5,
          decoration: const BoxDecoration(
              color: _coral, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 7),
    Flexible(child: Text(t, style: const TextStyle(
        fontSize: 11.5, color: _mid, height: 1.5))),
  ]),
);

// ── Cert row ─────────────────────────────────────────────────────────────────
Widget _certBullet(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(width: 5, height: 5,
          decoration: const BoxDecoration(
              color: _coral, shape: BoxShape.circle)),
    ),
    const SizedBox(width: 7),
    Flexible(child: Text(t, style: const TextStyle(
        fontSize: 11, color: _mid, height: 1.5))),
  ]),
);

// ── Personal reference row — matches certifications style ─────────────────────
Widget _refRow(
    String name, String title, String company, String email, String phone) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(width: 5, height: 5,
              decoration: const BoxDecoration(
                  color: _coral, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: _dark)),
              const SizedBox(height: 1),
              Text(title, style: const TextStyle(
                  fontSize: 11, color: _coral, fontWeight: FontWeight.w600)),
              if (company.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(company, style: const TextStyle(
                    fontSize: 10.5, color: _mid)),
              ],
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.email_outlined, size: 10, color: _mid),
                const SizedBox(width: 4),
                Expanded(child: Text(email,
                    style: const TextStyle(fontSize: 10, color: _mid),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.phone_outlined, size: 10, color: _mid),
                const SizedBox(width: 4),
                Expanded(child: Text(phone,
                    style: const TextStyle(fontSize: 10, color: _mid),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1)),
              ]),
            ],
          ),
        ),
      ]),
    );

// ─────────────────────────────────────────────────────────────────────────────

class PreviewVibrant extends StatelessWidget {
  const PreviewVibrant({super.key});

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
            child: Column(children: [

              // ── Coral header ─────────────────────────────────────────────
              Container(
                color: _coral,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Row(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarFill,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white60, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name, style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w900,
                            color: Colors.white, height: 1.1)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_title, style: const TextStyle(
                              fontSize: 12, color: _coral,
                              fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.email_outlined,
                              color: Colors.white60, size: 13),
                          const SizedBox(width: 5),
                          Flexible(child: Text(_email, style: const TextStyle(
                              color: Colors.white70, fontSize: 11))),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.phone_outlined,
                              color: Colors.white60, size: 13),
                          const SizedBox(width: 5),
                          Text(_phone, style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.white60, size: 13),
                          const SizedBox(width: 5),
                          Text(_loc, style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                        ]),
                      ],
                    ),
                  ),
                ]),
              ),

              // ── Body ─────────────────────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Main content ────────────────────────────────────────
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            _sectionHead('ABOUT ME'),
                            Text(_summary, style: const TextStyle(
                                fontSize: 12, color: _mid, height: 1.7)),
                            const SizedBox(height: 20),

                            _sectionHead('WORK EXPERIENCE'),
                            ..._exp.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(child: Text(e.$2,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _dark))),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _coralBg10,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(e.$3, style: const TextStyle(
                                          fontSize: 10.5, color: _coral,
                                          fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text(e.$1, style: const TextStyle(
                                      fontSize: 12, color: _coral,
                                      fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 7),
                                  ...e.$4.map(_bullet),
                                  Divider(color: Colors.grey.shade100,
                                      thickness: 1, height: 20),
                                ],
                              ),
                            )),
                            const SizedBox(height: 4),

                            _sectionHead('EDUCATION'),
                            ..._edu.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: _coralBg10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(child: Text(
                                      e.$3.substring(2),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _coral))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.$2, style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _dark)),
                                    const SizedBox(height: 2),
                                    Text(e.$1, style: const TextStyle(
                                        fontSize: 11.5, color: _mid)),
                                    const SizedBox(height: 2),
                                    Text(e.$4, style: const TextStyle(
                                        fontSize: 11, color: _coral,
                                        fontStyle: FontStyle.italic)),
                                  ],
                                )),
                              ]),
                            )),
                          ],
                        ),
                      ),
                    ),

                    // ── Sidebar ─────────────────────────────────────────────
                    Container(
                      width: 150,
                      color: _pale,
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Skills
                          _sectionHead('SKILLS'),
                          ..._skills.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _coralBorder30),
                              ),
                              child: Text(s.$1, style: const TextStyle(
                                  fontSize: 11.5, color: _dark,
                                  fontWeight: FontWeight.w500)),
                            ),
                          )),
                          const SizedBox(height: 18),

                          // Languages
                          _sectionHead('LANGUAGES'),
                          ..._langs.map((l) => _sidebarBullet(l)),
                          const SizedBox(height: 18),

                          // Certifications
                          _sectionHead('CERTIFICATIONS'),
                          ..._certs.map((c) => _certBullet(c)),
                          const SizedBox(height: 18),

                          // Personal References
                          _sectionHead('PERSONAL REFERENCES'),
                          ..._refs.map((r) => _refRow(
                              r.$1, r.$2, r.$3, r.$4, r.$5)),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}