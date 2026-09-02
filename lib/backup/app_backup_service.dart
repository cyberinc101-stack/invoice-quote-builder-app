// app_backup_service.dart
// lib/backup/app_backup_service.dart
//
// AUTO-BACKUP TO DOWNLOADS (this update): added autoBackupToDownloads() —
// silently writes the current backup JSON to the public Downloads folder
// (same directory receipt_pdf_service.dart already downloads PDFs to),
// NOT the app's internal storage. This matters because SharedPreferences
// (what every provider actually persists to) lives in app-internal
// storage, which gets WIPED if the app is ever uninstalled — including a
// silent uninstall+reinstall Android performs automatically when a
// rebuilt APK is signed with a different debug certificate than what's
// already installed (a real gotcha after `flutter clean` if the debug
// keystore gets regenerated). The public Downloads folder is untouched
// by an app uninstall, so a file sitting there survives exactly the
// scenario that just cost data. This method is called after every save
// (see the providers) and once on every app launch, overwriting the same
// fixed filename each time — always-current, no pileup of dated files.
// Fire-and-forget by design: failures are swallowed, this must never
// block or crash whatever save action triggered it.
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

  // Fixed filename for the silent auto-backup — always overwritten in
  // place rather than timestamped, so Downloads doesn't accumulate a new
  // file on every save. The manual "Export Backup" flow in
  // backup_screen.dart still produces its own timestamped file separately
  // via exportToFile(), for when the user wants a deliberate point-in-time
  // copy (e.g. before a risky restore) they can keep alongside this one.
  static const String _autoBackupFileName = 'invoice_app_autobackup.json';

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

  /// Silently writes the current backup JSON to the PUBLIC Downloads
  /// folder — not app-internal storage — using the same directory
  /// receipt_pdf_service.dart already writes PDFs to. Unlike
  /// SharedPreferences (which is wiped if the app is ever uninstalled,
  /// including an automatic silent uninstall+reinstall Android performs
  /// when a rebuilt debug APK's signature doesn't match what's already
  /// installed), the public Downloads folder survives an uninstall. This
  /// is the actual safety net for the "flutter clean wiped my data"
  /// scenario — call it after every save so there's never more than one
  /// save's worth of data at risk.
  ///
  /// Fire-and-forget by design: wrap calls in `unawaited(...)` at the
  /// call site. Failures are swallowed here — a failed auto-backup must
  /// never block or crash whatever save action triggered it.
  Future<void> autoBackupToDownloads() async {
    try {
      final json = await buildBackupJson();
      final dir = await _downloadsDir();
      final file = File('${dir.path}/$_autoBackupFileName');
      await file.writeAsString(json);
    } catch (_) {
      // Best-effort. If Downloads isn't writable for some reason (unusual
      // permission state, restricted platform, etc), silently skip — the
      // manual Export Backup flow is still available as a fallback, and
      // this should never surface an error for a background safety net.
    }
  }

  static Future<Directory> _downloadsDir() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    final docs = await getApplicationDocumentsDirectory();
    return docs;
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