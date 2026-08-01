// alert_prefs.dart
// lib/alerts/alert_prefs.dart
//
// Single on/off switch for the whole alerts feature (bell badge, home
// banner if you add one later, and the Alerts screen). Persisted the same
// way the rest of the app persists things — SharedPreferences — so it
// survives app restarts.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAlertsEnabledKey = 'alerts_enabled_v1';

class AlertPrefs extends ChangeNotifier {
  bool _alertsEnabled = true;
  bool _loaded = false;

  bool get alertsEnabled => _alertsEnabled;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _alertsEnabled = prefs.getBool(_kAlertsEnabledKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setAlertsEnabled(bool value) async {
    _alertsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAlertsEnabledKey, value);
  }
}
