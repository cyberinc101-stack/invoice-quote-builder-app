// lib/models/document_category.dart
//
// Lightweight category tag — used by ExpenseEntry (and reusable later for
// invoices/quotes if you want to tag those too). Deliberately has NO
// dependency on invoice_data.dart / quote_data.dart / receipt_data.dart.
//
// ICON HANDLING: categories store an `iconKey` (String), not a raw IconData
// codepoint. Flutter's icon tree-shaking (on by default in release builds)
// strips unused icon glyphs based on const IconData usage it can see at
// compile time — constructing IconData from an arbitrary int at runtime
// breaks that and either throws or shows a blank glyph in release mode.
// kCategoryIconChoices below is the single source of truth for the fixed
// set of icons a category can use; iconFor() maps a key back to the const
// IconData safely.

import 'package:flutter/material.dart';

class DocumentCategory {
  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final bool isCustom;

  const DocumentCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    this.isCustom = true,
  });

  Color get color => Color(colorValue);
  IconData get icon => iconFor(iconKey);

  DocumentCategory copyWith({String? name, int? colorValue, String? iconKey}) {
    return DocumentCategory(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      isCustom: isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'iconKey': iconKey,
        'isCustom': isCustom,
      };

  factory DocumentCategory.fromJson(Map<String, dynamic> j) => DocumentCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        colorValue: j['colorValue'] as int,
        iconKey: j['iconKey'] as String,
        isCustom: j['isCustom'] as bool? ?? true,
      );
}

// ── Fixed icon set (safe for release tree-shaking) ─────────────────────────

const Map<String, IconData> kCategoryIconChoices = {
  'directions_car': Icons.directions_car_rounded,
  'restaurant': Icons.restaurant_rounded,
  'flight': Icons.flight_rounded,
  'hotel': Icons.hotel_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'build': Icons.build_rounded,
  'devices': Icons.devices_rounded,
  'wifi': Icons.wifi_rounded,
  'local_gas_station': Icons.local_gas_station_rounded,
  'medical_services': Icons.medical_services_rounded,
  'school': Icons.school_rounded,
  'home_work': Icons.home_work_rounded,
  'phone_iphone': Icons.phone_iphone_rounded,
  'coffee': Icons.coffee_rounded,
  'more_horiz': Icons.more_horiz_rounded,
};

IconData iconFor(String key) => kCategoryIconChoices[key] ?? Icons.more_horiz_rounded;

// ── Defaults shipped with the app ───────────────────────────────────────────

const List<DocumentCategory> kDefaultCategories = [
  DocumentCategory(id: 'travel', name: 'Travel', colorValue: 0xFF2196F3, iconKey: 'flight', isCustom: false),
  DocumentCategory(id: 'meals', name: 'Meals', colorValue: 0xFFFF9800, iconKey: 'restaurant', isCustom: false),
  DocumentCategory(id: 'office', name: 'Office Supplies', colorValue: 0xFF9C27B0, iconKey: 'shopping_bag', isCustom: false),
  DocumentCategory(id: 'software', name: 'Software & Subscriptions', colorValue: 0xFF00897B, iconKey: 'wifi', isCustom: false),
  DocumentCategory(id: 'equipment', name: 'Equipment', colorValue: 0xFF5D4037, iconKey: 'devices', isCustom: false),
  DocumentCategory(id: 'fuel', name: 'Fuel & Transport', colorValue: 0xFF43A047, iconKey: 'local_gas_station', isCustom: false),
  DocumentCategory(id: 'other', name: 'Other', colorValue: 0xFF757575, iconKey: 'more_horiz', isCustom: false),
];
