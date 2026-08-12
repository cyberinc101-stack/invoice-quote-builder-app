// reports_prefs.dart
// lib/screens/reports/reports_prefs.dart
//
// Per-user toggle state for the Reports screen's "data sources" row
// (Invoices / Quotes / Receipts / Expenses), plus the tax set-aside rate
// used by TaxSetAsideCard. Mirrors lib/alerts/alert_prefs.dart's shape
// exactly: a ChangeNotifier with a load() called once at startup in
// main.dart, plain fields, and SharedPreferences persistence.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kIncludeInvoicesKey = 'reports_include_invoices_v1';
const String _kIncludeQuotesKey = 'reports_include_quotes_v1';
const String _kIncludeReceiptsKey = 'reports_include_receipts_v1';
const String _kIncludeExpensesKey = 'reports_include_expenses_v1';
const String _kTaxRatePercentKey = 'reports_tax_rate_percent_v1';
const double _kDefaultTaxRatePercent = 25.0;

class ReportsPrefs extends ChangeNotifier {
  bool _includeInvoices = true;
  bool _includeQuotes = true;
  bool _includeReceipts = true;
  bool _includeExpenses = true;
  double _taxRatePercent = _kDefaultTaxRatePercent;
  bool _loaded = false;

  bool get includeInvoices => _includeInvoices;
  bool get includeQuotes => _includeQuotes;
  bool get includeReceipts => _includeReceipts;
  bool get includeExpenses => _includeExpenses;
  double get taxRatePercent => _taxRatePercent;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _includeInvoices = prefs.getBool(_kIncludeInvoicesKey) ?? true;
    _includeQuotes = prefs.getBool(_kIncludeQuotesKey) ?? true;
    _includeReceipts = prefs.getBool(_kIncludeReceiptsKey) ?? true;
    _includeExpenses = prefs.getBool(_kIncludeExpensesKey) ?? true;
    _taxRatePercent = prefs.getDouble(_kTaxRatePercentKey) ?? _kDefaultTaxRatePercent;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setIncludeInvoices(bool value) async {
    _includeInvoices = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIncludeInvoicesKey, value);
  }

  Future<void> setIncludeQuotes(bool value) async {
    _includeQuotes = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIncludeQuotesKey, value);
  }

  Future<void> setIncludeReceipts(bool value) async {
    _includeReceipts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIncludeReceiptsKey, value);
  }

  Future<void> setIncludeExpenses(bool value) async {
    _includeExpenses = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIncludeExpensesKey, value);
  }

  Future<void> setTaxRatePercent(double value) async {
    final clamped = value.clamp(0.0, 60.0);
    _taxRatePercent = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTaxRatePercentKey, clamped);
  }
}
