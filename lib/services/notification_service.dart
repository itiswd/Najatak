// lib/services/notification_service.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // ✅ إضافة معالج النقر على الإشعار
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _createNotificationChannels();

      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
    }
  }

  // ✅ معالج النقر على الإشعار
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 تم النقر على الإشعار: ${response.payload}');
    // سيتم التعامل مع التنقل في main.dart
  }

  static Future<void> _createNotificationChannels() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // قناة أذكار الصباح - HIGH PRIORITY
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'morning_azkar_channel',
          'أذكار الصباح',
          description: 'إشعارات أذكار الصباح',
          importance: Importance.max,
          playSound: true,
          enableVibration: false,
          enableLights: true,
          sound: const RawResourceAndroidNotificationSound('morning_sound'),
        ),
      );

      // قناة أذكار المساء - HIGH PRIORITY
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'evening_azkar_channel',
          'أذكار المساء',
          description: 'إشعارات أذكار المساء',
          importance: Importance.max,
          playSound: true,
          enableVibration: false,
          enableLights: true,
          sound: const RawResourceAndroidNotificationSound('evening_sound'),
        ),
      );

      // قناة أذكار النوم
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'sleep_azkar_channel',
          'أذكار النوم',
          description: 'إشعارات أذكار النوم',
          importance: Importance.max,
          playSound: true,
          enableVibration: false,
          sound: const RawResourceAndroidNotificationSound('sleep_sound'),
        ),
      );

      // قنوات الأذكار الدورية
      final periodicSounds = [
        'zekr_1',
        'zekr_2',
        'zekr_3',
        'zekr_4',
        'zekr_5',
        'zekr_6',
        'zekr_7',
        'zekr_8',
        'zekr_9',
        'zekr_10',
        'zekr_11',
        'zekr_12',
        'zekr_13',
        'zekr_14',
      ];

      for (int i = 0; i < periodicSounds.length; i++) {
        await androidImplementation.createNotificationChannel(
          AndroidNotificationChannel(
            'periodic_zekr_${i + 1}_channel',
            'ذكر دوري ${i + 1}',
            description: 'قناة للذكر الدوري رقم ${i + 1}',
            importance: Importance.high,
            playSound: true,
            enableVibration: false,
            sound: RawResourceAndroidNotificationSound(periodicSounds[i]),
          ),
        );
      }
    }
  }

  // ✅ جدولة إشعار يومي محسّن
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationType type,
  }) async {
    try {
      // إلغاء الإشعار القديم
      await _notifications.cancel(id);

      String channelId;
      String soundName;
      String payload;

      switch (type) {
        case NotificationType.morning:
          channelId = 'morning_azkar_channel';
          soundName = 'morning_sound';
          payload = 'morning_azkar';
          break;
        case NotificationType.evening:
          channelId = 'evening_azkar_channel';
          soundName = 'evening_sound';
          payload = 'evening_azkar';
          break;
        case NotificationType.sleep:
          channelId = 'sleep_azkar_channel';
          soundName = 'sleep_sound';
          payload = 'sleep_azkar';
          break;
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            _getChannelName(type),
            channelDescription: 'إشعارات ${_getChannelName(type)}',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(soundName),
            enableVibration: false,
            enableLights: true,
            icon: '@mipmap/launcher_icon',
            // ✅ جعل الإشعار يظهر حتى مع وضع عدم الإزعاج
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            // ✅ جعل الإشعار مستمر حتى يتم النقر عليه
            autoCancel: false,
            ongoing: false,
            // ✅ إضافة أزرار تفاعلية
            actions: [
              const AndroidNotificationAction(
                'open_azkar',
                'فتح الأذكار',
                showsUserInterface: true,
              ),
            ],
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledDate = _nextInstanceOfTime(hour, minute);

      // ✅ جدولة الإشعار
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      // ✅ جدولة إشعارات إضافية للأيام القادمة (ضمان عدم التوقف)
      for (int day = 1; day <= 7; day++) {
        final futureDate = scheduledDate.add(Duration(days: day));
        await _notifications.zonedSchedule(
          id + (day * 1000), // ID مختلف لكل يوم
          title,
          body,
          futureDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      }

      debugPrint('✅ جدولة إشعار يومي - ID: $id في $hour:$minute');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار اليومي: $e');
      rethrow;
    }
  }

  // 🚀 جدولة الأذكار الدورية
  static Future<void> schedulePeriodicAzkar({
    required List<Map<String, String>> azkarList,
    required int intervalMinutes,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 بدء جدولة ${azkarList.length} ذكر دوري');
      debugPrint('⏱️  الفاصل الزمني: $intervalMinutes دقيقة');

      final pending = await _notifications.pendingNotificationRequests();
      final periodicIds = pending
          .where((n) => n.id >= 500 && n.id < 15000)
          .map((n) => n.id)
          .toList();

      for (final id in periodicIds) {
        await _notifications.cancel(id);
      }
      debugPrint('🗑️ تم إلغاء ${periodicIds.length} إشعار قديم');

      final now = tz.TZDateTime.now(tz.local);
      int totalScheduled = 0;

      for (int azkarIndex = 0; azkarIndex < azkarList.length; azkarIndex++) {
        final zekr = azkarList[azkarIndex];
        final zekrText = zekr['text']!;
        final soundFileName = zekr['sound']!;

        int zekrNumber = azkarIndex + 1;
        final match = RegExp(r'zekr_(\d+)').firstMatch(soundFileName);
        if (match != null) {
          zekrNumber = int.parse(match.group(1)!);
        }

        final channelId = 'periodic_zekr_${zekrNumber}_channel';
        final firstDelayMinutes = 1 + (intervalMinutes * azkarIndex);

        debugPrint(
          '📌 جدولة ذكر ${azkarIndex + 1}: أول ظهور بعد $firstDelayMinutes دقيقة',
        );

        for (int i = 0; i < 50; i++) {
          try {
            final notificationId = 500 + (azkarIndex * 100) + i;
            final totalMinutes =
                firstDelayMinutes + (i * intervalMinutes * azkarList.length);
            final scheduledTime = now.add(Duration(minutes: totalMinutes));

            if (scheduledTime.isBefore(now)) {
              continue;
            }

            final AndroidNotificationDetails androidDetails =
                AndroidNotificationDetails(
                  channelId,
                  'ذكر دوري $zekrNumber',
                  importance: Importance.high,
                  priority: Priority.high,
                  playSound: true,
                  sound: RawResourceAndroidNotificationSound(soundFileName),
                  enableVibration: false,
                  icon: '@mipmap/launcher_icon',
                );

            await _notifications.zonedSchedule(
              notificationId,
              'أذكار دورية',
              zekrText,
              scheduledTime,
              NotificationDetails(android: androidDetails),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );

            totalScheduled++;

            if (i < 3) {
              debugPrint(
                '   ✅ إشعار ${i + 1}: ${scheduledTime.day}/${scheduledTime.month} ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
              );
            }
          } catch (e) {
            debugPrint('   ⚠️ خطأ في جدولة إشعار $i: $e');
          }
        }
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('✅ اكتمل! إجمالي الإشعارات: $totalScheduled');
      debugPrint('═══════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الأذكار الدورية: $e');
      rethrow;
    }
  }

  static String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.morning:
        return 'أذكار الصباح';
      case NotificationType.evening:
        return 'أذكار المساء';
      case NotificationType.sleep:
        return 'أذكار النوم';
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      // ✅ إلغاء الإشعارات المجدولة للأيام القادمة أيضاً
      for (int day = 1; day <= 7; day++) {
        await _notifications.cancel(id + (day * 1000));
      }
      debugPrint('🗑️ تم إلغاء الإشعار: $id');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الإشعار: $e');
    }
  }

  static Future<void> cancelAllPeriodicNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      final periodicIds = pending
          .where((n) => n.id >= 500 && n.id < 15000)
          .map((n) => n.id)
          .toList();

      for (final id in periodicIds) {
        await _notifications.cancel(id);
      }

      debugPrint('🗑️ تم إلغاء ${periodicIds.length} إشعار دوري');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الإشعارات الدورية: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('🗑️ تم إلغاء جميع الإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء جميع الإشعارات: $e');
    }
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      return pending;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإشعارات المجدولة: $e');
      return [];
    }
  }
}

enum NotificationType { morning, evening, sleep }
