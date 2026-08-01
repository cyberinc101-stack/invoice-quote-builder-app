// cv_fullscreen_preview_individual_files/preview_wina.dart
// Full-screen scrollable preview for Template 13 – Wina Dark Infographic
// Matches MiniPreview13Wina exactly

import 'package:flutter/material.dart';

const _name  = 'Alexandra Chen';
const _title = 'Senior Product Designer';
const _email = 'alex.chen@email.com';
const _phone = '+1 (555) 234-5678';
const _loc   = 'San Francisco, CA';

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
  ('BFA Graphic Design', 'Rhode Island School of Design', '2016'),
  ('Certificate – HCI', 'Stanford University', '2019'),
];
const _refs = [
  ('James Smith', 'Engineering Manager', 'Acme Corp', 'j.smith@acme.com', '+1 555 010 1234'),
  ('Sarah Lee',   'Design Director',     'Globex',    's.lee@globex.com',  '+1 555 020 5678'),
];

// Colours matching MiniPreview13Wina exactly
const _bg     = Color(0xFF1C1C1C);
const _card   = Color(0xFF272727);
const _strip  = Color(0xFF222222);
const _divCol = Color(0xFF3A3A3A);
const _orange = Color(0xFFFF6B2B);
const _teal   = Color(0xFF00BCD4);
const _green  = Color(0xFF66BB6A);
const _yellow = Color(0xFFFFCA28);
const _pink   = Color(0xFFEC407A);
const _muted  = Color(0xFF9E9E9E);

const _skillData = [
  ('Figma',    0.95, _orange),
  ('D.Sys',    0.90, _teal),
  ('Research', 0.85, _green),
  ('Proto',    0.88, _yellow),
  ('Sketch',   0.80, _pink),
  ('Motion',   0.70, _teal),
];

const _icoData = [
  (Icons.location_city, _teal),
  (Icons.text_fields,   _orange),
  (Icons.menu_book,     _yellow),
  (Icons.camera_alt,    _pink),
  (Icons.music_note,    _teal),
  (Icons.flight,        _green),
  (Icons.park,          _green),
  (Icons.people,        _pink),
];

Widget _secLabel(String t, Color c) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(children: [
    Container(width: 3, height: 16, color: c),
    const SizedBox(width: 7),
    Text(t, style: TextStyle(
        color: c, fontSize: 11,
        fontWeight: FontWeight.w800, letterSpacing: 1.8)),
  ]),
);

Widget _tlItem(String title, String sub, String date, Color c,
    {List<String> bullets = const []}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          Container(width: 1.5,
              height: bullets.isEmpty ? 34 : 34 + bullets.length * 20.0,
              color: _divCol),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(title, style: const TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
            Text(date, style: TextStyle(color: c, fontSize: 10)),
          ]),
          Text(sub, style: const TextStyle(color: _muted, fontSize: 10.5)),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 5),
            ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 5),
                    child: Container(width: 4, height: 4,
                        decoration: BoxDecoration(
                            color: c, shape: BoxShape.circle))),
                const SizedBox(width: 7),
                Expanded(child: Text(b, style: const TextStyle(
                    color: _muted, fontSize: 10.5, height: 1.4))),
              ]),
            )),
          ],
        ])),
      ]),
    );

Widget _ring(String name, double level, Color color) => SizedBox(
  width: 68,
  child: Column(children: [
    SizedBox(width: 58, height: 58,
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(
          value: level, strokeWidth: 5,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        Text('${(level * 100).round()}',
            style: TextStyle(color: color, fontSize: 12,
                fontWeight: FontWeight.w700)),
      ])),
    const SizedBox(height: 5),
    Text(name, textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
        overflow: TextOverflow.ellipsis),
  ]),
);

Widget _icoCircle(IconData icon, Color color) => Container(
  width: 36, height: 36,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: color.withOpacity(0.15),
    border: Border.all(color: color.withOpacity(0.4)),
  ),
  child: Icon(icon, color: color, size: 17),
);

class PreviewWina extends StatelessWidget {
  const PreviewWina({super.key});

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Card header ────────────────────────────────────────
                  Container(
                    color: _card,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 58, height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _orange, width: 2.5),
                          color: const Color(0xFF333333),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white38, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name, style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(_title, style: const TextStyle(
                                fontSize: 9.5, color: Colors.white,
                                fontWeight: FontWeight.w600)),
                          ),
                        ],
                      )),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_email, style: const TextStyle(
                              color: Colors.white38, fontSize: 9)),
                          const SizedBox(height: 3),
                          Text(_phone, style: const TextStyle(
                              color: Colors.white38, fontSize: 9)),
                          const SizedBox(height: 3),
                          Text(_loc, style: const TextStyle(
                              color: Colors.white38, fontSize: 9)),
                        ],
                      ),
                    ]),
                  ),

                  // ── Icon strip ─────────────────────────────────────────
                  Container(
                    color: _strip,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _icoData
                          .map((d) => _icoCircle(d.$1, d.$2))
                          .toList(),
                    ),
                  ),

                  // ── Two-column body ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Education + Experience + References timelines
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _secLabel('EDUCATION', _teal),
                              ..._edu.map((e) =>
                                  _tlItem(e.$1, e.$2, e.$3, _teal)),
                              const SizedBox(height: 8),
                              _secLabel('EXPERIENCE', _orange),
                              ..._exp.map((e) => _tlItem(
                                  e.$2, e.$1, e.$3, _orange,
                                  bullets: e.$4)),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Right: Skill rings + References
                        SizedBox(
                          width: 156,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _secLabel('POWER', _yellow),
                              Wrap(
                                spacing: 8,
                                runSpacing: 14,
                                children: _skillData
                                    .map((s) => _ring(s.$1, s.$2, s.$3))
                                    .toList(),
                              ),
                              const SizedBox(height: 20),
                              _secLabel('REFERENCES', _green),
                              ..._refs.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(children: [
                                      Container(
                                        width: 10, height: 10,
                                        decoration: const BoxDecoration(
                                            color: _green,
                                            shape: BoxShape.circle),
                                      ),
                                      Container(
                                          width: 1.5, height: 60,
                                          color: _divCol),
                                    ]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(r.$1,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700),
                                              overflow: TextOverflow.ellipsis),
                                          Text(r.$2,
                                              style: const TextStyle(
                                                  color: _green, fontSize: 10,
                                                  fontWeight: FontWeight.w600)),
                                          Text(r.$3,
                                              style: const TextStyle(
                                                  color: _muted, fontSize: 9.5)),
                                          const SizedBox(height: 4),
                                          Row(children: [
                                            const Icon(Icons.email_outlined,
                                                size: 10, color: _green),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(r.$4,
                                                style: const TextStyle(
                                                    color: _muted, fontSize: 9),
                                                overflow: TextOverflow.ellipsis)),
                                          ]),
                                          const SizedBox(height: 2),
                                          Row(children: [
                                            const Icon(Icons.phone_outlined,
                                                size: 10, color: _green),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(r.$5,
                                                style: const TextStyle(
                                                    color: _muted, fontSize: 9),
                                                overflow: TextOverflow.ellipsis)),
                                          ]),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}