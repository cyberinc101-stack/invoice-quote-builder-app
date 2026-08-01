// lib/providers/category_provider.dart
//
// Holds the merged list (defaults + user-created) of DocumentCategory.
// Persisted the same way the rest of the app already persists things
// (SharedPreferences + jsonEncode), matching invoice/quote/receipt providers'
// loadPersisted*() naming convention used in main.dart.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/document_category.dart';

const String _kPrefsKey = 'custom_categories_v1';

class CategoryProvider extends ChangeNotifier {
  final List<DocumentCategory> _custom = [];

  List<DocumentCategory> get all => [...kDefaultCategories, ..._custom];

  DocumentCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => kDefaultCategories.last);

  Future<void> loadPersistedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => DocumentCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      _custom
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // corrupt prefs entry — ignore, start with defaults only
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPrefsKey,
      jsonEncode(_custom.map((c) => c.toJson()).toList()),
    );
  }

  Future<DocumentCategory> addCategory({
    required String name,
    required int colorValue,
    required String iconKey,
  }) async {
    final category = DocumentCategory(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      colorValue: colorValue,
      iconKey: iconKey,
    );
    _custom.add(category);
    notifyListeners();
    await _persist();
    return category;
  }

  Future<void> deleteCategory(String id) async {
    _custom.removeWhere((c) => c.id == id);
    notifyListeners();
    await _persist();
  }
}
