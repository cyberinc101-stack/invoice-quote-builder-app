// brutalist_field_limits.dart
// lib/cv_layout_templates/09_brutalist_cv_layout/brutalist_field_limits.dart
//
// Character limits for Brutalist (template 9) input fields only.
//
// Geometry at max font (16 pt, sc = 16/12 ≈ 1.333):
//   Contact strip: 595px − 6px dividers = 589px over 9 flex units
//   H-padding per cell: 9*sc*2 ≈ 24px
//   Font: 9*sc ≈ 12px Roboto w600, avg glyph ≈ 6.5px (safe average)
//
//   email    flex:3 → 172px inner → 26 chars
//   phone    flex:2 → 107px inner → 16 chars
//   location flex:2 → 107px inner → 16 chars
//   website  flex:2 → 107px inner → 16 chars
//
//   Full name / job title both use FittedBox(scaleDown) in the header,
//   so they never overflow — limits below are UX/design caps only.

class BrutalistFieldLimits {
  // Personal info
  static const int fullName  = 35;  // FittedBox scales down — design cap
  static const int jobTitle  = 35;  // FittedBox scales down — design cap

  // Contact strip cells (hard layout limits at max font size)
  static const int email     = 26;
  static const int phone     = 16;
  static const int location  = 16;  // city / short location only
  static const int website   = 16;
  static const int linkedin  = 16;
}