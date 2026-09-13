// reports_prefs.dart
// lib/screens/reports/reports_prefs.dart
//
// TAX PAYABLE PASS (this update): added taxTypeLabel (free-text, default
// 'GST' — same free-text-not-a-fixed-list philosophy as the currency
// fields on InvoiceData/QuoteData/ReceiptData, since which tax a person
// deals with, GST/VAT/sales tax/something else, isn't ours to enumerate)
// and includeInputCreditsInTaxPayable (bool, default false — a genuine
// accounting choice the person needs to opt into, not something to
// silently assume on their behalf). Both back the new TaxPayableCard
// (reports_widgets.dart), which reads output tax straight off existing
// InvoiceData/ReceiptData tax fields and, when the toggle is on, nets it
// against ExpenseEntry.taxAmount (expense_data.dart's new INPUT TAX
// CREDIT PASS) — no new document-model tax fields needed for this pass;
// see reports_screen.dart's _outputTaxCollected/_inputTaxPaid.
//
// Per-user toggle state for the Reports screen's "data sources" row
// (Invoices / Quotes / Receipts / Expenses), plus the tax set-aside rate
// used by TaxSetAsideCard, and the monthly income goal used by
// IncomeGoalCard. Mirrors lib/alerts/alert_prefs.dart's shape exactly: a
// ChangeNotifier with a load() called once at startup in main.dart, plain
// fields, and SharedPreferences persistence.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kIncludeInvoicesKey = 'reports_include_invoices_v1';
const String _kIncludeQuotesKey = 'reports_include_quotes_v1';
const String _kIncludeReceiptsKey = 'reports_include_receipts_v1';
const String _kIncludeExpensesKey = 'reports_include_expenses_v1';
const String _kTaxRatePercentKey = 'reports_tax_rate_percent_v1';
const String _kMonthlyIncomeGoalKey = 'reports_monthly_income_goal_v1';
const String _kTaxTypeLabelKey = 'reports_tax_type_label_v1';
const String _kIncludeInputCreditsKey = 'reports_include_input_credits_v1';
const double _kDefaultTaxRatePercent = 25.0;
const String _kDefaultTaxTypeLabel = 'GST';

class ReportsPrefs extends ChangeNotifier {
  bool _includeInvoices = true;
  bool _includeQuotes = true;
  bool _includeReceipts = true;
  bool _includeExpenses = true;
  double _taxRatePercent = _kDefaultTaxRatePercent;
  double _monthlyIncomeGoal = 0.0;
  String _taxTypeLabel = _kDefaultTaxTypeLabel;
  bool _includeInputCreditsInTaxPayable = false;
  bool _loaded = false;

  bool get includeInvoices => _includeInvoices;
  bool get includeQuotes => _includeQuotes;
  bool get includeReceipts => _includeReceipts;
  bool get includeExpenses => _includeExpenses;
  double get taxRatePercent => _taxRatePercent;
  double get monthlyIncomeGoal => _monthlyIncomeGoal;
  String get taxTypeLabel => _taxTypeLabel;
  bool get includeInputCreditsInTaxPayable => _includeInputCreditsInTaxPayable;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _includeInvoices = prefs.getBool(_kIncludeInvoicesKey) ?? true;
    _includeQuotes = prefs.getBool(_kIncludeQuotesKey) ?? true;
    _includeReceipts = prefs.getBool(_kIncludeReceiptsKey) ?? true;
    _includeExpenses = prefs.getBool(_kIncludeExpensesKey) ?? true;
    _taxRatePercent = prefs.getDouble(_kTaxRatePercentKey) ?? _kDefaultTaxRatePercent;
    _monthlyIncomeGoal = prefs.getDouble(_kMonthlyIncomeGoalKey) ?? 0.0;
    _taxTypeLabel = prefs.getString(_kTaxTypeLabelKey) ?? _kDefaultTaxTypeLabel;
    _includeInputCreditsInTaxPayable = prefs.getBool(_kIncludeInputCreditsKey) ?? false;
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

  Future<void> setMonthlyIncomeGoal(double value) async {
    final clamped = value.clamp(0.0, 100000000.0);
    _monthlyIncomeGoal = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMonthlyIncomeGoalKey, clamped);
  }

  // TAX PAYABLE PASS: free-text label for the tax type shown on
  // TaxPayableCard (e.g. 'GST', 'VAT', 'Sales Tax') — falls back to the
  // default rather than an empty string if someone clears the field
  // entirely, since a blank card title reads as broken.
  Future<void> setTaxTypeLabel(String value) async {
    final trimmed = value.trim();
    _taxTypeLabel = trimmed.isEmpty ? _kDefaultTaxTypeLabel : trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTaxTypeLabelKey, _taxTypeLabel);
  }

  // TAX PAYABLE PASS: whether TaxPayableCard nets output tax against
  // input tax credits from expenses (GST/VAT-style) or shows collected
  // tax only (simple sales-tax style, no credit system). Defaults false
  // so nothing changes for existing users until they deliberately opt in.
  Future<void> setIncludeInputCreditsInTaxPayable(bool value) async {
    _includeInputCreditsInTaxPayable = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIncludeInputCreditsKey, value);
  }
}
