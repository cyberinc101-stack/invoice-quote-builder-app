// footer_tagline.dart
// lib/models/footer_tagline.dart
//
// FOOTER TAGLINES PASS (new file): a footer tagline item is a single
// icon+text pair (e.g. Instagram icon + "@yourbusiness") rendered in a
// horizontal row at the bottom of the document, alongside the existing
// thank-you message. A document can show 3–6 of these, evenly spaced
// across the row regardless of count — see doc_footer.dart for the
// render side.
//
// FooterTaglineIcon is a small curated set rather than a full icon
// picker — common social/contact glyphs. Rendered via Flutter's
// built-in Icons for now (not brand-accurate logos — those would need
// bundled SVG/image assets); swap `icon` in the switch below if real
// brand marks are added later.

import 'package:flutter/material.dart';

enum FooterTaglineIcon {
  facebook,
  instagram,
  twitter,
  tiktok,
  linkedin,
  youtube,
  website,
  email,
  phone,
  location,
}

extension FooterTaglineIconX on FooterTaglineIcon {
  IconData get icon => switch (this) {
        FooterTaglineIcon.facebook => Icons.facebook_rounded,
        FooterTaglineIcon.instagram => Icons.camera_alt_rounded,
        FooterTaglineIcon.twitter => Icons.alternate_email_rounded,
        FooterTaglineIcon.tiktok => Icons.music_note_rounded,
        FooterTaglineIcon.linkedin => Icons.business_center_rounded,
        FooterTaglineIcon.youtube => Icons.play_circle_fill_rounded,
        FooterTaglineIcon.website => Icons.language_rounded,
        FooterTaglineIcon.email => Icons.email_rounded,
        FooterTaglineIcon.phone => Icons.phone_rounded,
        FooterTaglineIcon.location => Icons.location_on_rounded,
      };

  String get label => switch (this) {
        FooterTaglineIcon.facebook => 'Facebook',
        FooterTaglineIcon.instagram => 'Instagram',
        FooterTaglineIcon.twitter => 'X / Twitter',
        FooterTaglineIcon.tiktok => 'TikTok',
        FooterTaglineIcon.linkedin => 'LinkedIn',
        FooterTaglineIcon.youtube => 'YouTube',
        FooterTaglineIcon.website => 'Website',
        FooterTaglineIcon.email => 'Email',
        FooterTaglineIcon.phone => 'Phone',
        FooterTaglineIcon.location => 'Location',
      };

  /// Storage name — stable across app versions even if enum order
  /// changes; persisted in JSON instead of the enum index.
  String get storageName => name;
}

FooterTaglineIcon footerTaglineIconFromString(String s) =>
    FooterTaglineIcon.values.firstWhere(
      (v) => v.storageName == s,
      orElse: () => FooterTaglineIcon.website,
    );

/// Max character length for a footer tagline's text — kept short since
/// up to 6 of these sit side by side in one row.
const int kFooterTaglineMaxChars = 24;

/// Hard min/max item count for the footer taglines row. The whole
/// feature is a single on/off switch (Customise); when on, the
/// template author must keep between 3 and 6 items — add/remove
/// actions are disabled outside this range on the template sheet.
const int kFooterTaglinesMin = 3;
const int kFooterTaglinesMax = 6;

class FooterTaglineItem {
  FooterTaglineIcon icon;
  String text;

  FooterTaglineItem({
    this.icon = FooterTaglineIcon.website,
    this.text = '',
  });

  FooterTaglineItem copyWith({FooterTaglineIcon? icon, String? text}) =>
      FooterTaglineItem(icon: icon ?? this.icon, text: text ?? this.text);

  Map<String, dynamic> toJson() => {
        'icon': icon.storageName,
        'text': text,
      };

  factory FooterTaglineItem.fromJson(Map<String, dynamic> j) =>
      FooterTaglineItem(
        icon: footerTaglineIconFromString(j['icon'] as String? ?? 'website'),
        text: j['text'] as String? ?? '',
      );
}

List<Map<String, dynamic>> footerTaglinesToJson(List<FooterTaglineItem> items) =>
    items.map((i) => i.toJson()).toList();

List<FooterTaglineItem> footerTaglinesFromJson(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((e) => FooterTaglineItem.fromJson(e.cast<String, dynamic>()))
      .toList();
}
