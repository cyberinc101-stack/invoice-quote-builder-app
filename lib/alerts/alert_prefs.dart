// alert_prefs.dart
// lib/alerts/alert_prefs.dart
//
// Master on/off switch for the whole alerts feature, plus four per-type
// toggles (Overdue Invoices / Expiring Quotes / Drafts / Reminders) so a
// user can silence just one category without losing the others. All five
// flags persist via SharedPreferences the same way the rest of the app
// persists settings.
//
// PER-TYPE TOGGLES (this pass): added overdueInvoicesEnabled /
// quotesExpiringEnabled / draftsEnabled / remindersEnabled, each defaulting
// to true so existing users see no behavior change until they actively
// turn one off. alert_engine.dart's buildAlerts() reads these same four
// flags (passed in by callers), so the bell badge, the Alerts screen, and
// Settings' AlertTypeTogglesList can never disagree about what's enabled.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAlertsEnabledKey = 'alerts_enabled_v1';
const String _kOverdueInvoicesEnabledKey = 'alerts_overdue_invoices_enabled_v1';
const String _kQuotesExpiringEnabledKey = 'alerts_quotes_expiring_enabled_v1';
const String _kDraftsEnabledKey = 'alerts_drafts_enabled_v1';
const String _kRemindersEnabledKey = 'alerts_reminders_enabled_v1';

class AlertPrefs extends ChangeNotifier {
  bool _alertsEnabled = true;
  bool _overdueInvoicesEnabled = true;
  bool _quotesExpiringEnabled = true;
  bool _draftsEnabled = true;
  bool _remindersEnabled = true;
  bool _loaded = false;

  bool get alertsEnabled => _alertsEnabled;
  bool get overdueInvoicesEnabled => _overdueInvoicesEnabled;
  bool get quotesExpiringEnabled => _quotesExpiringEnabled;
  bool get draftsEnabled => _draftsEnabled;
  bool get remindersEnabled => _remindersEnabled;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _alertsEnabled = prefs.getBool(_kAlertsEnabledKey) ?? true;
    _overdueInvoicesEnabled = prefs.getBool(_kOverdueInvoicesEnabledKey) ?? true;
    _quotesExpiringEnabled = prefs.getBool(_kQuotesExpiringEnabledKey) ?? true;
    _draftsEnabled = prefs.getBool(_kDraftsEnabledKey) ?? true;
    _remindersEnabled = prefs.getBool(_kRemindersEnabledKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setAlertsEnabled(bool value) async {
    _alertsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAlertsEnabledKey, value);
  }

  Future<void> setOverdueInvoicesEnabled(bool value) async {
    _overdueInvoicesEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOverdueInvoicesEnabledKey, value);
  }

  Future<void> setQuotesExpiringEnabled(bool value) async {
    _quotesExpiringEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kQuotesExpiringEnabledKey, value);
  }

  Future<void> setDraftsEnabled(bool value) async {
    _draftsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDraftsEnabledKey, value);
  }

  Future<void> setRemindersEnabled(bool value) async {
    _remindersEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRemindersEnabledKey, value);
  }
}
