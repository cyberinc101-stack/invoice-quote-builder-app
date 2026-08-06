// expense_provider.dart
// lib/providers/expense_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_data.dart';

const String _kPrefsKey = 'expenses_v1';

class ExpenseProvider extends ChangeNotifier {
  final List<ExpenseEntry> _expenses = [];

  List<ExpenseEntry> get expenses =>
      List.of(_expenses)..sort((a, b) => b.date.compareTo(a.date));

  Future<void> loadPersistedExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _expenses
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // corrupt prefs entry — ignore, start empty
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPrefsKey,
      jsonEncode(_expenses.map((e) => e.toJson()).toList()),
    );
  }

  Future<ExpenseEntry> addExpense({
    required String vendor,
    required double amount,
    required String currency,
    required String categoryId,
    required DateTime date,
    String notes = '',
  }) async {
    final entry = ExpenseEntry(
      id: 'exp_${DateTime.now().microsecondsSinceEpoch}',
      vendor: vendor,
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      date: date,
      notes: notes,
      createdAt: DateTime.now(),
    );
    _expenses.add(entry);
    notifyListeners();
    await _persist();
    return entry;
  }

  Future<void> updateExpense(ExpenseEntry updated) async {
    final i = _expenses.indexWhere((e) => e.id == updated.id);
    if (i == -1) return;
    _expenses[i] = updated;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  // ── Month aggregation (used by ReportsScreen in single-month mode) ───────

  List<ExpenseEntry> forMonth(DateTime month) {
    return _expenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();
  }

  double totalForMonth(DateTime month) =>
      forMonth(month).fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> byCategoryForMonth(DateTime month) {
    final out = <String, double>{};
    for (final e in forMonth(month)) {
      out[e.categoryId] = (out[e.categoryId] ?? 0) + e.amount;
    }
    return out;
  }

  // ── Range aggregation (used by ReportsScreen when a custom start/end
  // date range is active instead of a single month) — computed directly
  // against the exact date bounds rather than summing whole months, so a
  // range that starts or ends mid-month doesn't over- or under-count. ────

  List<ExpenseEntry> forRange(DateTime start, DateTime end) {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEndExclusive = DateTime(end.year, end.month, end.day + 1);
    return _expenses
        .where((e) => !e.date.isBefore(rangeStart) && e.date.isBefore(rangeEndExclusive))
        .toList();
  }

  double totalForRange(DateTime start, DateTime end) =>
      forRange(start, end).fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> byCategoryForRange(DateTime start, DateTime end) {
    final out = <String, double>{};
    for (final e in forRange(start, end)) {
      out[e.categoryId] = (out[e.categoryId] ?? 0) + e.amount;
    }
    return out;
  }
}
