import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
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

    await _notifications.initialize(initSettings);
    await _createNotificationChannels();

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> _createNotificationChannels() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // قناة أذكار الصباح
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'morning_azkar_channel',
          'أذكار الصباح',
          description: 'إشعارات أذكار الصباح',
          importance: Importance.max,
          playSound: true,
          enableVibration: false,
          sound: RawResourceAndroidNotificationSound('morning_sound'),
        ),
      );

      // قناة أذكار المساء
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'evening_azkar_channel',
          'أذكار المساء',
          description: 'إشعارات أذكار المساء',
          importance: Importance.max,
          playSound: true,
          enableVibration: false,
          sound: RawResourceAndroidNotificationSound('evening_sound'),
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
          sound: RawResourceAndroidNotificationSound('sleep_sound'),
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

    debugPrint('✅ تم إنشاء قنوات الإشعارات بنجاح');
  }

  // جدولة إشعار يومي
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationType type,
  }) async {
    try {
      await _notifications.cancel(id);

      String channelId;
      String soundName;

      switch (type) {
        case NotificationType.morning:
          channelId = 'morning_azkar_channel';
          soundName = 'morning_sound';
          break;
        case NotificationType.evening:
          channelId = 'evening_azkar_channel';
          soundName = 'evening_sound';
          break;
        case NotificationType.sleep:
          channelId = 'sleep_azkar_channel';
          soundName = 'sleep_sound';
          break;
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            _getChannelName(type),
            channelDescription: 'إشعارات ${_getChannelName(type)}',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(soundName),
            enableVibration: false,
            icon: '@mipmap/launcher_icon',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledDate = _nextInstanceOfTime(hour, minute);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ تم جدولة إشعار يومي - ID: $id');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار: $e');
    }
  }

  // جدولة الأذكار الدورية
  static Future<void> schedulePeriodicAzkar({
    required List<Map<String, String>> azkarList,
    required int intervalMinutes,
  }) async {
    try {
      // إلغاء جميع الإشعارات الدورية القديمة
      await cancelAllPeriodicNotifications();

      final now = tz.TZDateTime.now(tz.local);

      // جدولة كل ذكر لمدة 30 يوم (لضمان استمرارية طويلة)
      for (int azkarIndex = 0; azkarIndex < azkarList.length; azkarIndex++) {
        final zekr = azkarList[azkarIndex];
        // final zekrId = zekr['id']!;
        final zekrText = zekr['text']!;
        final soundFileName = zekr['sound']!;

        // استخراج رقم الذكر من اسم الملف الصوتي
        int zekrNumber = azkarIndex + 1;
        final match = RegExp(r'zekr_(\d+)').firstMatch(soundFileName);
        if (match != null) {
          zekrNumber = int.parse(match.group(1)!);
        }

        final channelId = 'periodic_zekr_${zekrNumber}_channel';

        // أول ظهور لهذا الذكر بعد (intervalMinutes × ترتيبه)
        final firstDelay = intervalMinutes * azkarIndex;

        // جدولة 500 إشعار لكل ذكر (تكفي لشهر كامل تقريباً)
        for (int i = 0; i < 500; i++) {
          final notificationId = 500 + (azkarIndex * 1000) + i;

          // حساب وقت هذا الإشعار
          final totalMinutes =
              firstDelay + (i * intervalMinutes * azkarList.length);
          final scheduledTime = now.add(Duration(minutes: totalMinutes));

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

          final NotificationDetails notificationDetails = NotificationDetails(
            android: androidDetails,
          );

          await _notifications.zonedSchedule(
            notificationId,
            'ذكر ${azkarIndex + 1} من ${azkarList.length}',
            zekrText,
            scheduledTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );

          // طباعة أول 5 إشعارات لكل ذكر للمراجعة
          if (i < 5) {
            debugPrint(
              '   ✅ ذكر ${azkarIndex + 1} - إشعار ${i + 1}: ${scheduledTime.day}/${scheduledTime.month} ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
            );
          }
        }
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('✅ تم جدولة ${azkarList.length} ذكر دوري بنجاح');
      debugPrint('   الفاصل: $intervalMinutes دقيقة');
      debugPrint('   إجمالي الإشعارات: ${azkarList.length * 500}');
      debugPrint('═══════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الأذكار الدورية: $e');
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
    await _notifications.cancel(id);
    debugPrint('🗑️ تم إلغاء الإشعار: $id');
  }

  static Future<void> cancelAllPeriodicNotifications() async {
    // إلغاء جميع الإشعارات الدورية (IDs من 500 إلى 14500)
    for (int i = 0; i < 14000; i++) {
      await _notifications.cancel(500 + i);
    }
    debugPrint('🗑️ تم إلغاء جميع الإشعارات الدورية');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ تم إلغاء جميع الإشعارات');
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('📋 عدد الإشعارات المجدولة: ${pending.length}');
    return pending;
  }
}

enum NotificationType { morning, evening, sleep }
