// lib/widgets/swipable_cv_templates_homescreen_widgets/template_data.dart
//
// Data models for swipable carousel.
// templateId maps 1:1 to TemplateCardInfo.id used by showTemplateFullPreview().
//
// Translation: SwipeTemplate now stores nameKey/tagKey/descKey alongside the
// hardcoded English fallback strings. Callers resolve display text via:
//   t[tpl.nameKey] ?? tpl.name

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class SwipeTemplate {
  final int    id;
  final String name;        // English fallback
  final String tag;         // English fallback
  final String description; // English fallback
  final String nameKey;     // translation map key → 'tpl_xxx_name'
  final String tagKey;      // translation map key → 'tpl_xxx_tag'
  final String descKey;     // translation map key → 'tpl_xxx_desc'
  final Color  tagColor;
  final Color  accentColor;
  final bool   isPremium;
  final bool   hasPhoto;

  const SwipeTemplate({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.nameKey,
    required this.tagKey,
    required this.descKey,
    required this.tagColor,
    required this.accentColor,
    required this.isPremium,
    this.hasPhoto = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Template list
// ─────────────────────────────────────────────────────────────────────────────
const kSwipeTemplates = <SwipeTemplate>[
  SwipeTemplate(
    id:          1,
    name:        'Executive',
    tag:         'Most Popular',
    description: 'Bold & authoritative for senior roles',
    nameKey:     'tpl_executive_name',
    tagKey:      'tpl_executive_tag',
    descKey:     'tpl_executive_desc',
    tagColor:    Color(0xFF2196F3),
    accentColor: Color(0xFF0D1B2A),
    isPremium:   false,
    hasPhoto:    true,
  ),
  SwipeTemplate(
    id:          2,
    name:        'Nordic',
    tag:         'Clean',
    description: 'Minimal clarity trusted by top firms',
    nameKey:     'tpl_nordic_name',
    tagKey:      'tpl_nordic_tag',
    descKey:     'tpl_nordic_desc',
    tagColor:    Color(0xFF4CAF50),
    accentColor: Color(0xFF2563EB),
    isPremium:   false,
    hasPhoto:    false,
  ),
  SwipeTemplate(
    id:          3,
    name:        'Vibrant',
    tag:         'Creative',
    description: 'Stand out with energy and colour',
    nameKey:     'tpl_vibrant_name',
    tagKey:      'tpl_vibrant_tag',
    descKey:     'tpl_vibrant_desc',
    tagColor:    Color(0xFFFF5722),
    accentColor: Color(0xFFFF5C35),
    isPremium:   true,
    hasPhoto:    true,
  ),
  SwipeTemplate(
    id:          4,
    name:        'Tech Dark',
    tag:         'PRO',
    description: 'Terminal aesthetic for developers',
    nameKey:     'tpl_tech_dark_name',
    tagKey:      'tpl_tech_dark_tag',
    descKey:     'tpl_tech_dark_desc',
    tagColor:    Color(0xFF3FB950),
    accentColor: Color(0xFF0D1117),
    isPremium:   true,
    hasPhoto:    false,
  ),
  SwipeTemplate(
    id:          5,
    name:        'Luxury',
    tag:         'Elite',
    description: 'Gold-accented prestige on black',
    nameKey:     'tpl_luxury_name',
    tagKey:      'tpl_luxury_tag',
    descKey:     'tpl_luxury_desc',
    tagColor:    Color(0xFFBFA46A),
    accentColor: Color(0xFF1C1C1C),
    isPremium:   true,
    hasPhoto:    true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Shared mock CV content (decorative — intentionally not translated)
// These strings appear only inside pixel-faithful template illustrations and
// must match the full preview modal exactly.
// ─────────────────────────────────────────────────────────────────────────────
class MockCv {
  static const name    = 'Alexandra Chen';
  static const title   = 'Senior Product Designer';
  static const email   = 'alex.chen@email.com';
  static const phone   = '+1 (555) 234-5678';
  static const loc     = 'San Francisco, CA';
  static const web     = 'alexchen.design';
  static const summary =
      'Passionate product designer with 8+ years crafting user-centered '
      'experiences for Fortune 500 companies. Expert in design systems, '
      'prototyping, and cross-functional collaboration.';

  static const List<(String, String, String)> exp = [
    ('Senior Product Designer', 'Stripe', '2021 – Present'),
    ('Product Designer',        'Airbnb', '2018 – 2021'),
    ('UX Designer',             'IDEO',   '2016 – 2018'),
  ];

  static const List<(String, String)> edu = [
    ('BFA Graphic Design', 'Rhode Island School of Design'),
    ('Certificate – HCI',  'Stanford University'),
  ];

  static const List<(String, double)> skills = [
    ('Figma',          0.95),
    ('Design Systems', 0.90),
    ('User Research',  0.85),
    ('Prototyping',    0.88),
    ('Sketch',         0.80),
    ('Motion Design',  0.70),
  ];

  static const List<String> langs = [
    'English (Native)',
    'Mandarin (Fluent)',
    'French (Basic)',
  ];
}