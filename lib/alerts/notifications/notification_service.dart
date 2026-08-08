// notification_service.dart
// lib/alerts/notifications/notification_service.dart
//
// Wraps flutter_local_notifications + timezone for scheduling custom
// reminders as real push notifications.
//
// TAP-THROUGH (earlier pass): notifications now carry the reminder's id as
// their payload, and the plugin's onDidReceiveNotificationResponse callback
// routes taps back into the app via onReminderTapped — set once by
// main.dart with a callback that pushes RemindersScreen(highlightReminderId:
// ...). Two paths are covered: (1) the app is already running (foreground/
// background) — the plugin's callback fires directly; (2) the app was
// fully terminated and got launched BY tapping the notification —
// getNotificationAppLaunchDetails() catches that on the next init() and the
// payload is stashed until flushPendingLaunchTap() is called once the
// Navigator exists (main.dart does this in a post-frame callback right
// after runApp()).
//
// PERMISSION VISIBILITY (earlier pass): added notificationsEnabled, so the
// Add Reminder sheet can warn the user up front if push notifications are
// blocked at the OS level, instead of silently scheduling something that
// will never fire.
//
// TIMEZONE FIX (this pass): DateTime.now().timeZoneName returns a platform
// abbreviation like "NZST" or "PST", not an IANA identifier — passing that
// straight into tz.getLocation() throws on virtually every real device,
// which was silently caught and fell back to UTC every single time. That
// meant every scheduled reminder fired at the wrong wall-clock time for
// any user not in UTC (e.g. a "3pm" reminder actually firing at 3pm UTC,
// which is the middle of the night in NZ). Fixed by using the
// flutter_timezone package to get the device's real IANA timezone
// (e.g. "Pacific/Auckland") instead of guessing from timeZoneName.
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
  /// tapped notification's payload (the reminder's id).
  void Function(String reminderId)? onReminderTapped;

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

  void _handleTap(String reminderId) {
    if (onReminderTapped != null) {
      onReminderTapped!(reminderId);
    } else {
      // Navigator isn't wired up yet — stash it for flushPendingLaunchTap().
      _pendingLaunchPayload = reminderId;
    }
  }

  /// Delivers a tap that arrived before the Navigator existed. main.dart
  /// calls this once, in a post-frame callback right after runApp().
  void flushPendingLaunchTap() {
    final payload = _pendingLaunchPayload;
    if (payload != null && onReminderTapped != null) {
      _pendingLaunchPayload = null;
      onReminderTapped!(payload);
    }
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
      channelDescription: 'Custom reminders you set in the app',
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

  Future<void> cancelReminder(int id) async {
    if (!_initialized) await init();
    await _plugin.cancel(id);
  }
}