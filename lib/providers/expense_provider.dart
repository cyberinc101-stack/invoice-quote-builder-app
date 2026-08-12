// expense_provider.dart
// lib/providers/expense_provider.dart
//
// REFERENCE NUMBER PASS (this update): addExpense() gained a
// referenceNumber param, passed straight into the new ExpenseEntry (see
// expense_data.dart). findByReferenceNumber() is a plain case-insensitive
// scan of the in-memory _expenses list — no database, no network call.
// It backs two things: ExpenseScreen's manual reference-number search box,
// and the "scan a QR back to its expense" flow in expense_screen.dart's
// scan FAB (via ScannedExpenseDraft.referenceNumber from qr_service.dart).
// updateExpense() already round-trips referenceNumber through the caller's
// copyWith() call, so no change was needed there.
//
// FOLDERS (earlier pass): folderNames getter + updateExpensesFolder() —
// mirrors the pattern InvoiceProvider/QuoteProvider/ReceiptProvider use
// for their own folder assignment (updateInvoiceFolder etc.), just
// batched to match how expense_screen.dart's "Move to Folder" sheet
// already calls it (one or many ids at once, same as the bulk
// exclude-from-reports method below it). Passing null/empty clears the
// folder — same contract every other "Move to Folder" sheet in the app
// already uses.
//
// addExpense() sets lastEditedAt equal to createdAt at creation time;
// updateExpense() bumps lastEditedAt to DateTime.now() on every save.
// Mirrors how InvoiceProvider/QuoteProvider/ReceiptProvider maintain
// their own lastEditedAt — see expense_data.dart for why this field
// exists (powers the "Edited 3h ago" line on the rich expense cards).
// updateExpenseExcludeFromReports() deliberately does NOT bump
// lastEditedAt — toggling the reports flag isn't "editing" the expense's
// content, same reasoning the doc providers use for their own
// excludeFromReports toggles. updateExpensesFolder() also does not bump
// lastEditedAt, for the same reason (and to match InvoiceProvider etc.,
// whose updateXFolder() calls don't touch lastEditedAt either).
//
// excludeFromReports support (earlier pass, kept): mirrors the pattern
// InvoiceProvider/QuoteProvider/ReceiptProvider already use for their
// saved documents (updateInvoiceExcludeFromReports etc.).
// updateExpenseExcludeFromReports() flips the flag on a single entry.
//
// totalForMonth/byCategoryForMonth/totalForRange/byCategoryForRange now
// route through _isExpenseReportable() before folding, so an excluded
// expense stops counting toward the Reports "Expenses" stat card and the
// category breakdown immediately.
//
// forMonth()/forRange() themselves stay UNFILTERED on purpose — the new
// Reports document-list UI (reports_item_list.dart) needs to keep
// *showing* excluded expenses (dimmed, with a long-press toggle), not
// hide them entirely. Only the totals gate.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_data.dart';

const String _kPrefsKey = 'expenses_v1';

bool _isExpenseReportable(ExpenseEntry e) => !e.excludeFromReports;

class ExpenseProvider extends ChangeNotifier {
  final List<ExpenseEntry> _expenses = [];

  List<ExpenseEntry> get expenses =>
      List.of(_expenses)..sort((a, b) => b.date.compareTo(a.date));

  // ── Folders ────────────────────────────────────────────────────────────
  // Every distinct, non-empty folder name currently assigned to at least
  // one expense — same shape as collectFolderNames() in filter_logic.dart
  // for invoices/quotes/receipts, just scoped to this provider so callers
  // like expense_screen.dart's "Move to Folder" sheet don't need to reach
  // into filter_logic.dart for a single-provider list.
  Set<String> get folderNames {
    final names = <String>{};
    for (final e in _expenses) {
      final f = e.folderName;
      if (f != null && f.trim().isNotEmpty) names.add(f);
    }
    return names;
  }

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
    String? logoPath,
    double logoOffsetDx = 0.0,
    double logoOffsetDy = 0.0,
    double logoScale = 1.0,
    String logoShape = 'roundedSquare',
    String? folderName,
    String? referenceNumber,
  }) async {
    final now = DateTime.now();
    final entry = ExpenseEntry(
      id: 'exp_${now.microsecondsSinceEpoch}',
      vendor: vendor,
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      date: date,
      notes: notes,
      createdAt: now,
      lastEditedAt: now,
      logoPath: logoPath,
      logoOffsetDx: logoOffsetDx,
      logoOffsetDy: logoOffsetDy,
      logoScale: logoScale,
      logoShape: logoShape,
      folderName: folderName,
      referenceNumber: referenceNumber,
    );
    _expenses.add(entry);
    notifyListeners();
    await _persist();
    return entry;
  }

  Future<void> updateExpense(ExpenseEntry updated) async {
    final i = _expenses.indexWhere((e) => e.id == updated.id);
    if (i == -1) return;
    _expenses[i] = updated.copyWith(lastEditedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  /// Deletes several expenses at once — used by the expense screen's
  /// selection-mode bulk delete action.
  Future<void> deleteExpenses(Iterable<String> ids) async {
    final idSet = ids.toSet();
    _expenses.removeWhere((e) => idSet.contains(e.id));
    notifyListeners();
    await _persist();
  }

  ExpenseEntry? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Reference number lookup ───────────────────────────────────────────
  // Plain local scan of the in-memory list — no database, no network call.
  // Matches case-insensitively, trimmed. Used by:
  //   - ExpenseScreen's manual reference-number search box.
  //   - The scan FAB: after decoding a QR (or typing a number), this is
  //     how the app decides "open the existing expense" vs "prefill a new
  //     one" — see expense_screen.dart's scan handler.
  ExpenseEntry? findByReferenceNumber(String? reference) {
    final trimmed = reference?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final target = trimmed.toLowerCase();
    try {
      return _expenses.firstWhere(
        (e) => (e.referenceNumber?.trim().toLowerCase() ?? '') == target,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Reports exclusion ─────────────────────────────────────────────────
  // Same pattern as InvoiceProvider.updateInvoiceExcludeFromReports /
  // QuoteProvider.updateQuoteExcludeFromReports /
  // ReceiptProvider.updateReceiptExcludeFromReports.

  Future<void> updateExpenseExcludeFromReports(String id, bool exclude) async {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _expenses[i] = _expenses[i].copyWith(excludeFromReports: exclude);
    notifyListeners();
    await _persist();
  }

  /// Sets excludeFromReports for several expenses at once — used by the
  /// expense screen's selection-mode bulk "Exclude/Include" action.
  Future<void> updateExpensesExcludeFromReports(Iterable<String> ids, bool exclude) async {
    final idSet = ids.toSet();
    for (var i = 0; i < _expenses.length; i++) {
      if (idSet.contains(_expenses[i].id)) {
        _expenses[i] = _expenses[i].copyWith(excludeFromReports: exclude);
      }
    }
    notifyListeners();
    await _persist();
  }

  // ── Folder assignment ─────────────────────────────────────────────────
  // Sets folderName for one or many expenses at once — used by
  // expense_screen.dart's openExpenseFolderSheet() (single expense from
  // its item menu, or a bulk selection), and by SavedDocumentsSection's
  // inline expense-card menu on Home. Passing null (or an empty/blank
  // string) clears the folder, same contract every other "Move to
  // Folder" sheet in the app already uses.
  Future<void> updateExpensesFolder(Iterable<String> ids, String? folderName) async {
    final idSet = ids.toSet();
    final trimmed = folderName?.trim();
    final finalFolder = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    for (var i = 0; i < _expenses.length; i++) {
      if (idSet.contains(_expenses[i].id)) {
        _expenses[i] = _expenses[i].copyWith(
          folderName: finalFolder,
          clearFolder: finalFolder == null,
        );
      }
    }
    notifyListeners();
    await _persist();
  }

  // ── Month aggregation (used by ReportsScreen in single-month mode) ───────

  List<ExpenseEntry> forMonth(DateTime month) {
    return _expenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();
  }

  double totalForMonth(DateTime month) => forMonth(month)
      .where(_isExpenseReportable)
      .fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> byCategoryForMonth(DateTime month) {
    final out = <String, double>{};
    for (final e in forMonth(month).where(_isExpenseReportable)) {
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

  double totalForRange(DateTime start, DateTime end) => forRange(start, end)
      .where(_isExpenseReportable)
      .fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> byCategoryForRange(DateTime start, DateTime end) {
    final out = <String, double>{};
    for (final e in forRange(start, end).where(_isExpenseReportable)) {
      out[e.categoryId] = (out[e.categoryId] ?? 0) + e.amount;
    }
    return out;
  }
}
