import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shiftly/main.dart';
import 'package:shiftly/screens/add_shift_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Function(String)? onActionReceived;
  static bool _initialized = false;

  static bool get _isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Maps any Dart hash/id into a positive 31-bit int safe for iOS UNNotification.
  static int toNotificationId(int rawId) => rawId & 0x7FFFFFFF;

  static Future<void> init() async {
    try {
      if (!_isSupported) return;

      // Must run before any TZDateTime / tz.local usage.
      await _configureLocalTimeZone();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(defaultActionName: 'Open');

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux,
          );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          try {
            if (details.actionId != null) {
              onActionReceived?.call(details.actionId!);

              if (details.actionId == 'stop_shift') {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => const AddShiftScreen(initialTabIndex: 0),
                  ),
                );
              }
            } else {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => const AddShiftScreen(initialTabIndex: 0),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error handling notification response: $e');
          }
        },
      );

      await requestPermissions();
      _initialized = true;
    } catch (e) {
      debugPrint('Error in NotificationService.init: $e');
    }
  }

  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();

    try {
      final TimezoneInfo timeZoneInfo =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      debugPrint('Local timezone set to ${timeZoneInfo.identifier}');
    } catch (e) {
      debugPrint('Failed to resolve device timezone: $e');
      // App locale is he_IL; Asia/Jerusalem is a safe fallback if lookup fails.
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  /// Explicit permission request for iOS/macOS/Android. Safe to call multiple times.
  static Future<bool> requestPermissions() async {
    if (!_isSupported) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final granted = await macPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  static Future<void> scheduleShiftReminder({
    required int id,
    required String shiftName,
    required DateTime startTime,
    required double reminderDurationHours,
  }) async {
    if (!_isSupported) return;

    try {
      if (!_initialized) {
        debugPrint('NotificationService not initialized; skipping schedule.');
        return;
      }

      final reminderTime = startTime.subtract(
        Duration(minutes: (reminderDurationHours * 60).toInt()),
      );

      final now = DateTime.now();

      // Skip if reminder is in the past or within the next 5 minutes
      if (reminderTime.isBefore(now.add(const Duration(minutes: 5)))) {
        debugPrint(
          'Reminder too close or in past, skipping for battery saving.',
        );
        return;
      }

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'shift_reminder_channel',
        'תזכורות משמרת',
        channelDescription: 'תזכורת לפני תחילת משמרת',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails darwinPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      final notificationDetails = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: darwinPlatformChannelSpecifics,
        macOS: darwinPlatformChannelSpecifics,
      );

      final String timeText = reminderDurationHours >= 1
          ? '${reminderDurationHours.toStringAsFixed(0)} שעות'
          : '${(reminderDurationHours * 60).toInt()} דקות';

      // Convert wall-clock DateTime into the configured local TZ location.
      // (uiLocalNotificationDateInterpretation was removed in plugin v18+;
      // iOS 10+ UserNotifications uses the TZDateTime absolute instant.)
      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
      final notificationId = toNotificationId(id);

      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'תזכורת למשמרת',
        body: 'המשמרת שלך ($shiftName) מתחילה בעוד $timeText!',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      debugPrint(
        'Scheduled reminder id=$notificationId for $shiftName at $scheduledDate',
      );
    } catch (e) {
      debugPrint('Error scheduling shift reminder: $e');
    }
  }

  static Future<void> showTimerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime startTime,
    bool isOnBreak = false,
  }) async {
    if (!_isSupported) return;

    try {
      final List<AndroidNotificationAction> androidActions = [];
      if (isOnBreak) {
        androidActions.add(
          const AndroidNotificationAction(
            'end_break',
            'חזור לעבודה',
            showsUserInterface: true,
          ),
        );
      } else {
        androidActions.add(
          const AndroidNotificationAction(
            'start_paid_break',
            'הפסקה בתשלום',
            showsUserInterface: true,
          ),
        );
        androidActions.add(
          const AndroidNotificationAction(
            'start_unpaid_break',
            'הפסקה לא בתשלום',
            showsUserInterface: true,
          ),
        );
      }
      androidActions.add(
        const AndroidNotificationAction(
          'stop_shift',
          'סיום',
          showsUserInterface: true,
        ),
      );

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'timer_channel',
            'משמרת פעילה',
            channelDescription: 'מציג את זמן המשמרת הנוכחית',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            showWhen: true,
            usesChronometer: !isOnBreak,
            when: startTime.millisecondsSinceEpoch,
            actions: androidActions,
          );

      const DarwinNotificationDetails darwinPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const LinuxNotificationDetails linuxPlatformChannelSpecifics =
          LinuxNotificationDetails();

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: darwinPlatformChannelSpecifics,
        macOS: darwinPlatformChannelSpecifics,
        linux: linuxPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        id: toNotificationId(id),
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: 'timer_action',
      );
    } catch (e) {
      debugPrint('Error showing timer notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    if (!_isSupported) return;
    try {
      await _notificationsPlugin.cancel(id: toNotificationId(id));
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
}
