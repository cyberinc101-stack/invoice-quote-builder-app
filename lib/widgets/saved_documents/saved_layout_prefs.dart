// saved_layout_prefs.dart
// lib/widgets/saved_documents/saved_layout_prefs.dart
//
// Persisted, app-wide "card shape" choice — List / Grid / Compact Grid /
// Compact — shared between the Saved Documents section on Home and the
// "Documents in this period" section on Reports, so picking Grid on one
// screen shows Grid on the other too, and the choice survives an app
// restart (same pattern as CardDisplayPrefs). Deliberately public (not
// `part of` saved_documents_section.dart like DocLayoutMode) so
// reports_document_list.dart can read the same value without needing
// access to that library's private types.
//
// Home's DocLayoutMode has a fifth option, Kanban, with no Reports
// equivalent (Reports has no per-status pipeline view). Selecting Kanban
// on Home is a LOCAL-only choice — it does not overwrite this shared
// preference, so Reports keeps showing whichever of the four shared
// layouts was last chosen on either screen. Picking any of the other four
// on either screen updates this preference and is reflected on both.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SharedDocLayout { list, grid, compactGrid, compact }

class SavedLayoutPrefs extends ChangeNotifier {
  static const String _kKey = 'saved_doc_layout_v1';

  SharedDocLayout layout = SharedDocLayout.list;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw != null) {
        layout = SharedDocLayout.values.firstWhere(
          (l) => l.name == raw,
          orElse: () => SharedDocLayout.list,
        );
      }
    } catch (e) {
      debugPrint('[SavedLayoutPrefs] load error: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setLayout(SharedDocLayout value) async {
    if (layout == value) return;
    layout = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, value.name);
    } catch (e) {
      debugPrint('[SavedLayoutPrefs] setLayout error: $e');
    }
  }
}
