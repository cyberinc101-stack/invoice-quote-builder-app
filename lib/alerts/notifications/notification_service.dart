// notification_service.dart
// lib/alerts/notifications/notification_service.dart
//
// Wraps flutter_local_notifications + timezone for scheduling custom
// reminders, document alerts (overdue invoice / quote expiring / draft
// nudge, via DocumentAlertScheduler), AND the weekly digest (via
// WeeklyDigestScheduler) as real push notifications.
//
// WEEKLY DIGEST PASS (this update): added scheduleWeeklyDigest(), which
// uses zonedSchedule's matchDateTimeComponents:
// DateTimeComponents.dayOfWeekAndTime — this tells the OS "fire every
// week on this weekday at this time," so it's a true recurring
// notification scheduled ONCE and never needs to be re-scheduled on every
// app open the way document alerts do. Deliberately generic body text
// ("Your weekly summary is ready") rather than embedding actual numbers —
// a notification scheduled ahead of time has no way to know next Monday's
// real income/expense totals, so faking dynamic content in would mean
// showing stale or wrong figures. The notification's job is just to pull
// the user back into the app; Reports renders the real, live numbers once
// they're actually there.
//
// Payload routing gets a third branch alongside the existing "doc:" (a
// document alert) and bare-reminder-id (legacy/custom reminder) cases:
// payloads starting with "digest:" route through the new
// onDigestTapped callback, set by main.dart to push straight to
// ReportsScreen. Falls back to the same _pendingLaunchPayload stash used
// by the other two paths if the Navigator isn't wired up yet (cold start
// via notification tap).
//
// Everything else below (init/permissions/reminder scheduling/tap
// routing for doc: and reminder payloads) is UNCHANGED from the previous
// pass — see prior header comments, preserved below.
//
// TAP-THROUGH: notifications carry a payload, and the plugin's
// onDidReceiveNotificationResponse callback routes taps back into the
// app. Two paths are covered: (1) the app is already running
// (foreground/background) — the plugin's callback fires directly; (2) the
// app was fully terminated and got launched BY tapping the notification —
// getNotificationAppLaunchDetails() catches that on the next init() and
// the payload is stashed until flushPendingLaunchTap() is called once the
// Navigator exists (main.dart does this in a post-frame callback right
// after runApp()).
//
// PAYLOAD ROUTING: DocumentAlertScheduler schedules notifications using
// payloads shaped "doc:<category>:<docId>" (e.g.
// "doc:overdueInvoice:abc123"). _handleTap branches on the "doc:" prefix:
// reminder payloads go through onReminderTapped(reminderId) exactly as
// before, doc payloads go through onDocumentAlertTapped(category, docId),
// and (this pass) digest payloads go through onDigestTapped(). If the
// relevant callback isn't set, a tap is a silent no-op rather than
// crashing or being misrouted.
//
// PERMISSION VISIBILITY: added notificationsEnabled, so the Add Reminder
// sheet can warn the user up front if push notifications are blocked at
// the OS level, instead of silently scheduling something that will never
// fire.
//
// TIMEZONE FIX: DateTime.now().timeZoneName returns a platform
// abbreviation like "NZST" or "PST", not an IANA identifier — passing
// that straight into tz.getLocation() throws on virtually every real
// device, which was silently caught and fell back to UTC every single
// time. Fixed by using the flutter_timezone package to get the device's
// real IANA timezone (e.g. "Pacific/Auckland") instead of guessing from
// timeZoneName.
//
// Requires: flutter pub add flutter_timezone

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Set by main.dart once the root Navigator exists. Called with the
  /// tapped notification's payload for a CUSTOM REMINDER (the reminder's
  /// id).
  void Function(String reminderId)? onReminderTapped;

  /// Set by main.dart once the root Navigator exists. Called when a
  /// DOCUMENT ALERT notification (overdue invoice / quote expiring /
  /// draft nudge) is tapped. [category] is the raw DocAlertCategory.name
  /// string (e.g. "overdueInvoice", "quoteExpiring", "draftInvoice"),
  /// [docId] is the invoice/quote/receipt id — use these to push the
  /// right detail screen.
  void Function(String category, String docId)? onDocumentAlertTapped;

  /// Set by main.dart once the root Navigator exists. Called when the
  /// WEEKLY DIGEST notification is tapped — no id/category payload, since
  /// there's only ever one of these; main.dart should just push
  /// ReportsScreen.
  void Function()? onDigestTapped;

  String? _pendingLaunchPayload;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      // Real IANA timezone (e.g. "Pacific/Auckland", "America/New_York").
      // This is what tz.getLocation() actually expects — timeZoneName
      // (e.g. "NZST") is NOT a valid input and throws every time.
      // flutter_timezone 5.x returns a TimezoneInfo object, not a plain
      // String — the IANA identifier is on its .identifier field.
      final TimezoneInfo currentTimeZone =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
    } catch (_) {
      // Falls back to UTC — scheduling still works, it just won't
      // auto-adjust display for the device's local offset. Should only
      // hit this on a device with a genuinely unrecognized timezone id.
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleTap(payload);
        }
      },
    );
    _initialized = true;

    // Cold-start case: the app was fully terminated and this very launch
    // was caused by tapping a notification. The callback above only fires
    // for taps while the plugin instance is already alive, so this is the
    // only way to catch that first tap.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _pendingLaunchPayload = payload;
      }
    }

    if (kDebugMode) {
      debugPrint('NotificationService: initialized.');
    }
  }

  /// Parses a raw payload and routes it. Doc alerts are shaped
  /// "doc:<category>:<docId>"; the digest is shaped "digest:weekly";
  /// anything else is treated as a legacy bare reminder id.
  void _handleTap(String payload) {
    if (payload.startsWith('doc:')) {
      final parts = payload.split(':');
      if (parts.length < 3) return; // malformed, ignore rather than crash
      final category = parts[1];
      final docId = parts.sublist(2).join(':'); // docId itself could theoretically contain ':'
      if (onDocumentAlertTapped != null) {
        onDocumentAlertTapped!(category, docId);
      } else {
        _pendingLaunchPayload = payload;
      }
      return;
    }

    if (payload.startsWith('digest:')) {
      if (onDigestTapped != null) {
        onDigestTapped!();
      } else {
        _pendingLaunchPayload = payload;
      }
      return;
    }

    // Legacy path: bare reminder id.
    if (onReminderTapped != null) {
      onReminderTapped!(payload);
    } else {
      // Navigator isn't wired up yet — stash it for flushPendingLaunchTap().
      _pendingLaunchPayload = payload;
    }
  }

  /// Delivers a tap that arrived before the Navigator existed. main.dart
  /// calls this once, in a post-frame callback right after runApp().
  void flushPendingLaunchTap() {
    final payload = _pendingLaunchPayload;
    if (payload == null) return;
    _pendingLaunchPayload = null;
    _handleTap(payload);
  }

  Future<void> requestPermissions() async {
    if (!_initialized) await init();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Whether the OS will actually show notifications from this app right
  /// now. Android only for the moment — iOS permission state isn't exposed
  /// by this plugin version, so it optimistically returns true there
  /// (requestPermissions already prompted at launch).
  Future<bool> get notificationsEnabled async {
    if (!_initialized) await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await init();
    if (scheduledDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Custom reminders and document alerts you get from the app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: failed to schedule "$title" — $e');
      }
    }
  }

  /// Schedules a TRUE recurring weekly notification — fires every week on
  /// [weekday] (1 = Monday ... 7 = Sunday, matching DateTime's own
  /// weekday convention) at [hour]:[minute] local time, indefinitely,
  /// without ever needing to be re-scheduled. Uses
  /// matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, which
  /// tells the OS itself to repeat the notification on that weekly
  /// cadence — unlike scheduleReminder() above (a single one-shot future
  /// DateTime), this is set once and keeps firing on its own.
  ///
  /// Calling this again with the same [id] replaces the existing
  /// schedule (the plugin overwrites by id), so callers don't need to
  /// cancel first when just re-confirming the same schedule — e.g.
  /// WeeklyDigestScheduler.sync() calls this on every app launch as a
  /// cheap idempotent "make sure it's still scheduled" step.
  Future<void> scheduleWeeklyDigest({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) await init();

    // First future occurrence of the target weekday/time — the OS then
    // takes over repeating it weekly from there via
    // matchDateTimeComponents, so this only needs to be "some point in
    // the future on the right weekday," not recomputed each week.
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'digest_channel',
      'Weekly Summary',
      channelDescription: 'A weekly summary of your invoicing activity',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: failed to schedule weekly digest — $e');
      }
    }
  }

  Future<void> cancelReminder(int id) async {
    if (!_initialized) await init();
    await _plugin.cancel(id);
  }
}
