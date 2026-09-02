// lib/providers/history_provider.dart
//
// LOAD-AWAIT WIRING (this update): added loadHistory() — a public
// awaitable for main.dart's startup Future.wait, mirroring
// invoiceProvider.loadPersistedInvoices() etc. The constructor already
// called the private _load() to populate history on startup; the
// initial load's Future is now stored (_initialLoad) and loadHistory()
// simply returns it, rather than triggering a second, redundant load.
// This fixes the two build errors from main.dart's HISTORY PROVIDER
// WIRING pass — `historyProvider.loadHistory()` was calling a method
// that didn't exist, which also made Dart infer the surrounding
// Future.wait([...]) list as List<dynamic> instead of
// List<Future<dynamic>>.
//
// Running activity log of what's happened to saved documents — created,
// shared, downloaded, sent, printed, deleted — so HistoryScreen can show
// "here's what you've done" instead of just another view of the documents
// themselves.
//
// Persistence: event metadata is JSON-encoded through StorageService's
// generic save()/load() (the same SharedPreferences-backed store
// saveInvoice()/loadInvoices() already use), under _kHistoryKey. Files
// attached to shared/downloaded/sent events are copied into a dedicated
// app-storage folder (see _persistFile) rather than left in whatever temp
// dir the export service originally wrote to, since OS temp dirs get
// cleared and would silently break "send again". That folder is pruned as
// old events fall off the end of the list (_maxEvents) or get deleted.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/history_event.dart';
import '../services/storage_service.dart';

const _kHistoryKey = 'history_events_v1';
const _maxEvents = 300;

class HistoryProvider extends ChangeNotifier {
  final StorageService _storage;
  List<HistoryEvent> _events = [];
  bool _loaded = false;

  // LOAD-AWAIT WIRING: the Future from the constructor's initial _load()
  // call, kept so loadHistory() below can return that same in-flight/
  // completed future instead of re-triggering a second load.
  late final Future<void> _initialLoad;

  HistoryProvider({StorageService? storageService})
      : _storage = storageService ?? StorageService() {
    _initialLoad = _load();
  }

  /// Awaits the initial load from persisted storage. Call this from
  /// main.dart's startup Future.wait alongside the other providers'
  /// load*() methods (invoiceProvider.loadPersistedInvoices(), etc.) so
  /// history is populated before the first frame. Safe to call more than
  /// once or from multiple places — always resolves to the same
  /// constructor-triggered load rather than re-reading storage.
  Future<void> loadHistory() => _initialLoad;

  List<HistoryEvent> get events => List.unmodifiable(_events);
  bool get isLoaded => _loaded;

  List<HistoryEvent> eventsOfType(HistoryEventType? type) {
    if (type == null) return events;
    return _events.where((e) => e.type == type).toList();
  }

  Future<void> _load() async {
    final raw = await _storage.load(_kHistoryKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _events = list
            .map((e) => HistoryEvent.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } catch (_) {
        _events = [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.save(
      _kHistoryKey,
      jsonEncode(_events.map((e) => e.toJson()).toList()),
    );
  }

  /// Logs a new event. Pass [sourceFile] for shared/downloaded/sent events
  /// where "do it again" should work later — it gets copied into
  /// persistent app storage and that copy's path is what's stored.
  Future<HistoryEvent> logEvent({
    required HistoryEventType type,
    required HistoryDocType docType,
    required String docId,
    required String docNumber,
    String? clientName,
    double? amount,
    String? currency,
    File? sourceFile,
    String? note,
  }) async {
    String? storedPath;
    if (sourceFile != null) {
      try {
        if (await sourceFile.exists()) {
          storedPath = await _persistFile(sourceFile, docId, type);
        }
      } catch (_) {
        storedPath = null;
      }
    }

    final event = HistoryEvent(
      id: '${DateTime.now().microsecondsSinceEpoch}_$docId',
      type: type,
      docType: docType,
      docId: docId,
      docNumber: docNumber,
      clientName: clientName,
      amount: amount,
      currency: currency,
      timestamp: DateTime.now(),
      filePath: storedPath,
      note: note,
    );

    _events.insert(0, event);
    await _trimIfNeeded();
    await _persist();
    notifyListeners();
    return event;
  }

  // Convenience wrappers — same params as logEvent, named for whichever
  // call site is clearest at the point of use.

  Future<HistoryEvent> logCreated({
    required HistoryDocType docType,
    required String docId,
    required String docNumber,
    String? clientName,
    double? amount,
    String? currency,
  }) =>
      logEvent(
        type: HistoryEventType.created,
        docType: docType,
        docId: docId,
        docNumber: docNumber,
        clientName: clientName,
        amount: amount,
        currency: currency,
      );

  Future<HistoryEvent> logShared({
    required HistoryDocType docType,
    required String docId,
    required String docNumber,
    String? clientName,
    double? amount,
    String? currency,
    File? sourceFile,
  }) =>
      logEvent(
        type: HistoryEventType.shared,
        docType: docType,
        docId: docId,
        docNumber: docNumber,
        clientName: clientName,
        amount: amount,
        currency: currency,
        sourceFile: sourceFile,
      );

  Future<HistoryEvent> logDownloaded({
    required HistoryDocType docType,
    required String docId,
    required String docNumber,
    String? clientName,
    double? amount,
    String? currency,
    File? sourceFile,
  }) =>
      logEvent(
        type: HistoryEventType.downloaded,
        docType: docType,
        docId: docId,
        docNumber: docNumber,
        clientName: clientName,
        amount: amount,
        currency: currency,
        sourceFile: sourceFile,
      );

  Future<HistoryEvent> logSent({
    required HistoryDocType docType,
    required String docId,
    required String docNumber,
    String? clientName,
    double? amount,
    String? currency,
    File? sourceFile,
  }) =>
      logEvent(
        type: HistoryEventType.sent,
        docType: docType,
        docId: docId,
        docNumber: docNumber,
        clientName: clientName,
        amount: amount,
        currency: currency,
        sourceFile: sourceFile,
      );

  Future<HistoryEvent> logPrinted({
    required HistoryDocType docType,
    required String docId,
    required String docNumber,
    String? clientName,
    double? amount,
    String? currency,
  }) =>
      logEvent(
        type: HistoryEventType.printed,
        docType: docType,
        docId: docId,
        docNumber: docNumber,
        clientName: clientName,
        amount: amount,
        currency: currency,
      );

  Future<HistoryEvent> logDeleted({
    required HistoryDocType docType,
    required String docId,
    required String docNumber,
    String? clientName,
  }) =>
      logEvent(
        type: HistoryEventType.deleted,
        docType: docType,
        docId: docId,
        docNumber: docNumber,
        clientName: clientName,
      );

  Future<void> deleteEvent(String id) async {
    final idx = _events.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final event = _events.removeAt(idx);
    if (event.filePath != null) {
      try {
        final f = File(event.filePath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    for (final e in _events) {
      if (e.filePath != null) {
        try {
          final f = File(e.filePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
    _events = [];
    await _persist();
    notifyListeners();
  }

  Future<void> _trimIfNeeded() async {
    if (_events.length <= _maxEvents) return;
    final overflow = _events.sublist(_maxEvents);
    _events = _events.sublist(0, _maxEvents);
    for (final e in overflow) {
      if (e.filePath != null) {
        try {
          final f = File(e.filePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  Future<String> _persistFile(
      File source, String docId, HistoryEventType type) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final histDir = Directory('${docsDir.path}/history_files');
    if (!await histDir.exists()) {
      await histDir.create(recursive: true);
    }
    final ext = source.path.contains('.') ? source.path.split('.').last : 'dat';
    final destPath =
        '${histDir.path}/${docId}_${type.name}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final dest = await source.copy(destPath);
    return dest.path;
  }
}