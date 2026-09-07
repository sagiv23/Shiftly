import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shiftly/main.dart';
import 'package:shiftly/screens/add_shift_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Function(String)? onActionReceived;

  static bool get _isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static Future<void> init() async {
    try {
      if (!_isSupported) return;

      tz.initializeTimeZones();
      // Attempt to set local timezone.
      // Default to Asia/Jerusalem for this Hebrew app as a fallback
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
      } catch (e) {
        debugPrint(
          'Could not set Asia/Jerusalem timezone, falling back to UTC',
        );
      }

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
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
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
        },
      );

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlugin?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  static Future<void> scheduleShiftReminder({
    required int id,
    required String shiftName,
    required DateTime startTime,
    required double reminderDurationHours,
  }) async {
    if (!_isSupported) return;

    final reminderTime = startTime.subtract(
      Duration(minutes: (reminderDurationHours * 60).toInt()),
    );
    if (reminderTime.isBefore(DateTime.now())) return;

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'shift_reminder_channel',
      'תזכורות משמרת',
      channelDescription: 'תזכורת לפני תחילת משמרת',
      importance: Importance.high,
      priority: Priority.high,
    );

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final notificationDetails = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
    );

    String timeText = reminderDurationHours >= 1
        ? '${reminderDurationHours.toStringAsFixed(0)} שעות'
        : '${(reminderDurationHours * 60).toInt()} דקות';

    await _notificationsPlugin.zonedSchedule(
      id,
      'תזכורת למשמרת',
      'המשמרת שלך ($shiftName) מתחילה בעוד $timeText!',
      tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showTimerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime startTime,
    bool isOnBreak = false,
  }) async {
    if (!_isSupported) return;

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
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'timer_action',
    );
  }

  static Future<void> cancelNotification(int id) async {
    if (!_isSupported) return;
    await _notificationsPlugin.cancel(id);
  }
}
