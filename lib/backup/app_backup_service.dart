// app_backup_service.dart
// lib/backup/app_backup_service.dart
//
// Exports/imports all saved documents (invoices, quotes, receipts,
// expenses) as a single JSON file the user can save or share, and later
// restore from — e.g. after reinstalling the app or switching phones.
//
// DESIGN: rather than re-serializing through each model's toJson()/
// fromJson(), this reads/writes the EXACT raw JSON strings each provider
// already persists to SharedPreferences under its own key
// (InvoiceProvider's 'saved_invoices_v1', QuoteProvider's
// 'saved_quotes_v1', ReceiptProvider's 'saved_receipts',
// ExpenseProvider's 'expenses_v1'). That guarantees a byte-for-byte round
// trip — there is no intermediate re-encoding step that could drift from
// whatever shape those providers actually expect, now or after a future
// field gets added to one of the models. Restoring is just writing those
// same raw strings back to SharedPreferences under the same keys, then
// asking each already-loaded provider to reload from prefs — the exact
// same loadPersisted*() method each one already calls on app startup.
//
// SCOPE (by design, this pass): documents only — invoices, quotes,
// receipts, expenses. Deliberately excludes app settings (AlertPrefs,
// CardDisplayPrefs, SavedLayoutPrefs, ThemeProvider, language selection)
// — those are low-stakes to reconfigure and mixing differently-shaped
// preference data into the same backup format adds risk for something
// that isn't the actual disaster scenario (losing years of invoice
// records is; losing a dark-mode toggle isn't). Can be extended later if
// wanted.
//
// FILE FORMAT:
// {
//   "app": "Invoice & Quote Builder",
//   "backupVersion": 1,
//   "exportedAt": "<ISO8601 timestamp>",
//   "data": {
//     "saved_invoices_v1": "<raw JSON string, exactly as stored in prefs>",
//     "saved_quotes_v1":   "<raw JSON string>",
//     "saved_receipts":    "<raw JSON string>",
//     "expenses_v1":       "<raw JSON string>"
//   }
// }
//
// A key is simply omitted from "data" if that provider had nothing
// persisted yet (fresh install, or that document type was never used) —
// restore treats a missing key as "leave that provider's stored data
// untouched" rather than wiping it to empty, so restoring a backup that
// e.g. only has invoices/quotes never silently deletes existing receipts/
// expenses the phone already had.

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBackupService {
  AppBackupService._();
  static final AppBackupService instance = AppBackupService._();

  static const String _kInvoicesKey = 'saved_invoices_v1';
  static const String _kQuotesKey   = 'saved_quotes_v1';
  static const String _kReceiptsKey = 'saved_receipts';
  static const String _kExpensesKey = 'expenses_v1';

  static const List<String> _allKeys = [
    _kInvoicesKey,
    _kQuotesKey,
    _kReceiptsKey,
    _kExpensesKey,
  ];

  static const int _backupVersion = 1;

  /// Reads every provider's raw persisted JSON string straight out of
  /// SharedPreferences and returns the combined backup document as a
  /// pretty-printed JSON string, ready to write to a file.
  Future<String> buildBackupJson() async {
    final prefs = await SharedPreferences.getInstance();

    final data = <String, String>{};
    for (final key in _allKeys) {
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        data[key] = raw;
      }
    }

    final backup = {
      'app': 'Invoice & Quote Builder',
      'backupVersion': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backup);
  }

  /// Builds the backup JSON and writes it to a file in the app's temp/
  /// documents directory, returning the file. Caller (backup_screen.dart)
  /// is responsible for sharing/saving it from there (via share_plus or
  /// similar) — this method only produces the file on disk.
  Future<File> exportToFile({String? fileName}) async {
    final json = await buildBackupJson();
    final dir = await getApplicationDocumentsDirectory();
    final name = fileName ??
        'invoice_app_backup_${DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-')}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(json);
    return file;
  }

  /// Result of a restore attempt — counts of how many raw provider
  /// buckets were found and restored, or an error message if the file
  /// wasn't a valid backup at all.
  Future<BackupRestoreResult> restoreFromFile(File file) async {
    final String content;
    try {
      content = await file.readAsString();
    } catch (e) {
      return BackupRestoreResult.failure('Could not read the selected file: $e');
    }

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return BackupRestoreResult.failure('This file isn\'t valid JSON — it may be corrupted or not a backup file.');
    }

    final data = parsed['data'];
    if (data is! Map) {
      return BackupRestoreResult.failure('This file doesn\'t look like an app backup (missing "data" section).');
    }

    final prefs = await SharedPreferences.getInstance();
    int restoredCount = 0;
    final restoredKeys = <String>[];

    for (final key in _allKeys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        await prefs.setString(key, value);
        restoredCount++;
        restoredKeys.add(key);
      }
      // Key absent from the backup -> leave whatever's currently in
      // SharedPreferences for that key untouched (see file-format note
      // above — a partial backup should never wipe unrelated data).
    }

    if (restoredCount == 0) {
      return BackupRestoreResult.failure('This backup file doesn\'t contain any recognizable invoice, quote, receipt, or expense data.');
    }

    return BackupRestoreResult.success(restoredKeys: restoredKeys);
  }
}

class BackupRestoreResult {
  final bool ok;
  final String? errorMessage;
  final List<String> restoredKeys;

  const BackupRestoreResult._({
    required this.ok,
    this.errorMessage,
    this.restoredKeys = const [],
  });

  factory BackupRestoreResult.success({required List<String> restoredKeys}) =>
      BackupRestoreResult._(ok: true, restoredKeys: restoredKeys);

  factory BackupRestoreResult.failure(String message) =>
      BackupRestoreResult._(ok: false, errorMessage: message);
}
