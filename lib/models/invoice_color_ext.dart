// lib/models/invoice_color_ext.dart
//
// Adds primaryColor / accentColor int getters to InvoiceColor
// so the color-scheme picker grid in step_create_invoice can work.
// Keep this in a separate file to avoid modifying invoice_data.dart.

import 'invoice_data.dart';

extension InvoiceColorExt on InvoiceColor {
  /// ARGB int suitable for Color(...)
  int get primaryColor {
    switch (this) {
      case InvoiceColor.blue:   return 0xFF1565C0;
      case InvoiceColor.green:  return 0xFF2E7D32;
      case InvoiceColor.purple: return 0xFF6A1B9A;
      case InvoiceColor.orange: return 0xFFE65100;
      case InvoiceColor.red:    return 0xFFC62828;
      case InvoiceColor.teal:   return 0xFF00695C;
      case InvoiceColor.black:  return 0xFF212121;
      case InvoiceColor.indigo: return 0xFF283593;
    }
  }

  int get accentColor {
    switch (this) {
      case InvoiceColor.blue:   return 0xFF42A5F5;
      case InvoiceColor.green:  return 0xFF66BB6A;
      case InvoiceColor.purple: return 0xFFAB47BC;
      case InvoiceColor.orange: return 0xFFFFA726;
      case InvoiceColor.red:    return 0xFFEF5350;
      case InvoiceColor.teal:   return 0xFF26A69A;
      case InvoiceColor.black:  return 0xFF757575;
      case InvoiceColor.indigo: return 0xFF5C6BC0;
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceColor.blue:   return 'Ocean Blue';
      case InvoiceColor.green:  return 'Forest Green';
      case InvoiceColor.purple: return 'Royal Purple';
      case InvoiceColor.orange: return 'Sunset Orange';
      case InvoiceColor.red:    return 'Crimson Red';
      case InvoiceColor.teal:   return 'Deep Teal';
      case InvoiceColor.black:  return 'Charcoal';
      case InvoiceColor.indigo: return 'Midnight Indigo';
    }
  }
}