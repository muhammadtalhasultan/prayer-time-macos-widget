import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../features/prayertime/models/prayer_times.dart';

class PrayerNotificationService {
  PrayerNotificationService._();

  static final PrayerNotificationService instance = PrayerNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'prayerCategory',
          actions: [],
          options: {DarwinNotificationCategoryOption.allowInCarPlay},
        ),
      ],
    );

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    _initialized = true;
    log('PrayerNotificationService: Initialized');
  }

  Future<void> _createAndroidNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'prayer_times_channel',
      'Prayer Times',
      description: 'Notifications for prayer times',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationResponse(NotificationResponse response) {
    log('PrayerNotificationService: Notification tapped - ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isMacOS) {
      final macPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      final granted = await macPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    if (Platform.isIOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  String? _lastSyncKey;

  Future<void> sync({
    required bool notificationsEnabled,
    required PrayerTimes? prayer,
  }) async {
    // Build a key to avoid redundant syncs
    final syncKey = notificationsEnabled && prayer != null
        ? '${prayer.data.date.readable}_$notificationsEnabled'
        : 'disabled';

    if (_lastSyncKey == syncKey) {
      log('PrayerNotificationService: Skipping redundant sync (key: $syncKey)');
      return;
    }
    _lastSyncKey = syncKey;

    if (!notificationsEnabled || prayer == null) {
      await cancelAllNotifications();
      return;
    }

    await ensureInitialized();
    await _schedulePrayerNotifications(prayer);
  }

  Future<void> _schedulePrayerNotifications(PrayerTimes prayer) async {
    // Cancel only prayer notification IDs (0-4), not test notification (999)
    for (int i = 0; i < 5; i++) {
      await _plugin.cancel(i);
    }
    log('PrayerNotificationService: Cleared previous prayer notifications');

    final timings = prayer.data.timings;
    final now = DateTime.now();

    final prayerTimes = {
      'Fajr': _parseTimeToday(timings.fajr),
      'Dhuhr': _parseTimeToday(timings.dhuhr),
      'Asr': _parseTimeToday(timings.asr),
      'Maghrib': _parseTimeToday(timings.maghrib),
      'Isha': _parseTimeToday(timings.isha),
    };

    int scheduledCount = 0;

    for (final entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;

      if (prayerTime.isAfter(now)) {
        await _scheduleNotification(
          id: scheduledCount,
          title: '$prayerName Prayer',
          body: 'It\'s time for $prayerName prayer',
          scheduledTime: prayerTime,
          payload: prayerName,
        );
        log('PrayerNotificationService: Scheduled $prayerName at $prayerTime');
        scheduledCount++;
      } else {
        log('PrayerNotificationService: Skipped $prayerName (already passed: $prayerTime)');
      }
    }

    log('PrayerNotificationService: Total scheduled: $scheduledCount notifications');
  }

  DateTime _parseTimeToday(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1].split(' ')[0] : '0') ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'prayer_times_channel',
      'Prayer Times',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAllNotifications() async {
    // Cancel only prayer notification IDs (0-4)
    for (int i = 0; i < 5; i++) {
      await _plugin.cancel(i);
    }
    _lastSyncKey = null;
    log('PrayerNotificationService: Cancelled all prayer notifications');
  }

  /// Debug only: Schedules test notification in 1 minute
  Future<void> sendTestNotification() async {
    if (!kDebugMode) return;
    await ensureInitialized();

    final granted = await requestPermissions();
    log('PrayerNotificationService: Permission granted = $granted');
    if (!granted) {
      log('PrayerNotificationService: Permission denied');
      return;
    }

    // Cancel any previous test notification
    await _plugin.cancel(999);

    final testTime = DateTime.now().add(const Duration(minutes: 1));
    final tzTime = tz.TZDateTime.from(testTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'prayer_times_channel',
      'Prayer Times',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      999,
      'Test Notification',
      'Prayer notifications are working!',
      tzTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'test',
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    log('PrayerNotificationService: Test notification scheduled for $testTime (1 min)');
  }
}
