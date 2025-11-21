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

      debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
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
          'أذكار الصباح • نَجَاتَك',
          description: 'إشعارات أذكار الصباح',
          importance: Importance.max,
          playSound: true,
          enableVibration: false,
          sound: const RawResourceAndroidNotificationSound('morning_sound'),
        ),
      );

      // قناة أذكار المساء
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'evening_azkar_channel',
          'أذكار المساء • نَجَاتَك',
          description: 'إشعارات أذكار المساء',
          importance: Importance.max,
          playSound: true,
          enableVibration: false,
          sound: const RawResourceAndroidNotificationSound('evening_sound'),
        ),
      );

      // قناة أذكار النوم
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'sleep_azkar_channel',
          'أذكار النوم • نَجَاتَك',
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

      debugPrint('✅ جدولة إشعار يومي - ID: $id');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار اليومي: $e');
      rethrow;
    }
  }

  // 🚀 جدولة الأذكار الدورية - مع إصلاح مشكلة التاريخ
  static Future<void> schedulePeriodicAzkar({
    required List<Map<String, String>> azkarList,
    required int intervalMinutes,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 بدء جدولة ${azkarList.length} ذكر دوري');
      debugPrint('⏱️  الفاصل الزمني: $intervalMinutes دقيقة');

      // ✅ إلغاء سريع فقط للإشعارات الموجودة
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

      // ✅ جدولة 50 إشعار لكل ذكر (تكفي لأسبوعين تقريباً)
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

        // 🔥 الإصلاح: أول ذكر يبدأ بعد دقيقة واحدة على الأقل
        // ثم كل ذكر لاحق حسب ترتيبه
        final firstDelayMinutes = 1 + (intervalMinutes * azkarIndex);

        debugPrint(
          '📌 جدولة ذكر ${azkarIndex + 1}: أول ظهور بعد $firstDelayMinutes دقيقة',
        );

        // جدولة 50 إشعار لكل ذكر
        for (int i = 0; i < 50; i++) {
          try {
            final notificationId = 500 + (azkarIndex * 100) + i;

            // حساب وقت هذا الإشعار
            final totalMinutes =
                firstDelayMinutes + (i * intervalMinutes * azkarList.length);
            final scheduledTime = now.add(Duration(minutes: totalMinutes));

            // ✅ التحقق من أن التاريخ في المستقبل
            if (scheduledTime.isBefore(now)) {
              debugPrint('⚠️ تخطي إشعار في الماضي: $scheduledTime');
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

            // طباعة أول 3 إشعارات فقط
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
      debugPrint('📱 أول إشعار سيظهر بعد دقيقة واحدة');
      debugPrint('═══════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الأذكار الدورية: $e');
      rethrow;
    }
  }

  static String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.morning:
        return 'أذكار الصباح • نَجَاتَك';
      case NotificationType.evening:
        return 'أذكار المساء • نَجَاتَك';
      case NotificationType.sleep:
        return 'أذكار النوم • نَجَاتَك';
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
      debugPrint('🗑️ تم إلغاء الإشعار: $id');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الإشعار: $e');
    }
  }

  // ✅ إلغاء سريع للإشعارات الدورية
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
