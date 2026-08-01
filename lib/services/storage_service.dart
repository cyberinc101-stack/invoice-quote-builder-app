// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_info.dart';
import '../models/invoice_data.dart'; // ← ADDED: required for InvoiceColor

const _kInvoiceListKey = 'saved_invoice_list_v1';

class StorageService {
  // ── Generic key-value ──────────────────────────────────────────────────────

  Future<void> save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // ── Invoice persistence ────────────────────────────────────────────────────

  /// Saves (or updates) an [Invoice] in the persisted list.
  /// Matches on [Invoice.id]; if found it replaces the entry, otherwise appends.
  Future<void> saveInvoice(Invoice invoice) async {
    final list = await loadInvoices();
    final idx = list.indexWhere((i) => i.id == invoice.id);
    if (idx >= 0) {
      list[idx] = invoice;
    } else {
      list.add(invoice);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kInvoiceListKey,
      jsonEncode(list.map((i) => i.toJson()).toList()),
    );
  }

  /// Loads all persisted [Invoice] objects. Returns [] on failure.
  Future<List<Invoice>> loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kInvoiceListKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _invoiceFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Deletes a single invoice by [id].
  Future<void> deleteInvoice(String id) async {
    final list = await loadInvoices();
    list.removeWhere((i) => i.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kInvoiceListKey,
      jsonEncode(list.map((i) => i.toJson()).toList()),
    );
  }

  // ── Private deserialiser ───────────────────────────────────────────────────
  // We keep this local to avoid making Invoice.fromJson() public on the model,
  // which would create a circular dependency with LineItem.

  Invoice _invoiceFromJson(Map<String, dynamic> j) {
    return Invoice(
      id:            j['id']            as String? ?? '',
      invoiceNumber: j['invoiceNumber'] as String? ?? '',
      barcodeNumber: j['barcodeNumber'] as String?,
      date:     DateTime.tryParse(j['date']    as String? ?? '') ?? DateTime.now(),
      dueDate:  DateTime.tryParse(j['dueDate'] as String? ?? '') ?? DateTime.now(),
      businessInfo: BusinessInfo.fromJson(
          j['businessInfo'] as Map<String, dynamic>? ?? {}),
      customer: ClientInfo.fromJson(
          j['customer'] as Map<String, dynamic>? ?? {}),
      items: [], // line items are not needed for list view; skip re-hydrating
      taxRate:       (j['taxRate']      as num?)?.toDouble() ?? 0,
      discountRate:  (j['discountRate'] as num?)?.toDouble() ?? 0,
      notes:         j['notes']           as String? ?? '',
      thankYouMessage: j['thankYouMessage'] as String? ?? '',
      enabledFields: (j['enabledFields'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as bool? ?? true)),
      colorScheme: _colorFromName(j['colorScheme'] as String? ?? ''),
      businessLogoPath: j['businessLogoPath'] as String?,
      currency:    j['currency']    as String? ?? 'USD',
    );
  }

  // Reuse InvoiceColor from invoice_data.dart (exported via invoice_models.dart)
}

// Top-level helper so the deserialiser above can reference it without a circular import.
// invoice_data.dart is imported transitively via client_info.dart → invoice_data.dart.
InvoiceColor _colorFromName(String name) {
  return InvoiceColor.values.firstWhere(
    (c) => c.name == name,
    orElse: () => InvoiceColor.blue,
  );
}