// alert_prefs.dart
// lib/alerts/alert_prefs.dart
//
// Master on/off switch for the whole alerts feature, plus per-type
// toggles (Overdue Invoices / Expiring Quotes / Drafts / Reminders /
// Weekly Summary) so a user can silence just one category without losing
// the others. All flags persist via SharedPreferences the same way the
// rest of the app persists settings.
//
// COMMENT FIX (this pass): this class is a pure state holder — it never
// calls into DocumentAlertScheduler/NotificationService/ReminderProvider
// itself. Applying a flag change to the actual push-notification
// schedule is done by whoever changes the flag: alert_type_toggles.dart's
// four switches and settings_screen.dart's master Alerts switch each
// call the matching provider's applyXEnabled() method (InvoiceProvider.
// applyOverdueAlertsEnabled/applyDraftAlertsEnabled, QuoteProvider.
// applyExpiringAlertsEnabled/applyDraftAlertsEnabled, ReceiptProvider.
// applyDraftAlertsEnabled, ReminderProvider.applyRemindersPushEnabled)
// right alongside the setXEnabled() call below. A previous version of
// this comment incorrectly claimed settings_screen.dart "already"
// resynced document alerts off the master switch — it didn't; that's
// what this pass actually wires up.
//
// WEEKLY DIGEST TOGGLE (earlier pass): added weeklyDigestEnabled,
// defaulting to true so existing users get the new weekly summary
// notification without needing to opt in — consistent with how the four
// existing per-type toggles were introduced. Deliberately NOT part of
// the alertsEnabled-gated push wiring described above — the weekly
// digest isn't part of buildAlerts()'s live in-app alert list (it's a
// standalone OS-scheduled notification, see WeeklyDigestScheduler), so
// it's controlled purely by this one flag. settings_screen.dart calls
// WeeklyDigestScheduler.instance.sync(value) directly whenever this flag
// changes.
//
// PER-TYPE TOGGLES (earlier pass): added overdueInvoicesEnabled /
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
const String _kWeeklyDigestEnabledKey = 'alerts_weekly_digest_enabled_v1';

class AlertPrefs extends ChangeNotifier {
  bool _alertsEnabled = true;
  bool _overdueInvoicesEnabled = true;
  bool _quotesExpiringEnabled = true;
  bool _draftsEnabled = true;
  bool _remindersEnabled = true;
  bool _weeklyDigestEnabled = true;
  bool _loaded = false;

  bool get alertsEnabled => _alertsEnabled;
  bool get overdueInvoicesEnabled => _overdueInvoicesEnabled;
  bool get quotesExpiringEnabled => _quotesExpiringEnabled;
  bool get draftsEnabled => _draftsEnabled;
  bool get remindersEnabled => _remindersEnabled;
  bool get weeklyDigestEnabled => _weeklyDigestEnabled;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _alertsEnabled = prefs.getBool(_kAlertsEnabledKey) ?? true;
    _overdueInvoicesEnabled = prefs.getBool(_kOverdueInvoicesEnabledKey) ?? true;
    _quotesExpiringEnabled = prefs.getBool(_kQuotesExpiringEnabledKey) ?? true;
    _draftsEnabled = prefs.getBool(_kDraftsEnabledKey) ?? true;
    _remindersEnabled = prefs.getBool(_kRemindersEnabledKey) ?? true;
    _weeklyDigestEnabled = prefs.getBool(_kWeeklyDigestEnabledKey) ?? true;
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

  Future<void> setWeeklyDigestEnabled(bool value) async {
    _weeklyDigestEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWeeklyDigestEnabledKey, value);
  }
}
