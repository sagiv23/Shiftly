import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';
import '../screens/add_shift_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Function(String)? onActionReceived;

  static bool get _isSupported {
    if (kIsWeb) return false;
    // flutter_local_notifications supports Android, iOS, macOS, and Linux
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static Future<void> init() async {
    try {
      if (!_isSupported) return;

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
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
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
