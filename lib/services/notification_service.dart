import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    // إعدادات Android مع تصميم احترافي
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('تم الضغط على الإشعار: ${response.payload}');
      },
    );

    // إنشاء قنوات الإشعارات بأصوات مخصصة
    await _createNotificationChannels();

    // طلب الصلاحيات للأندرويد 13+
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // إنشاء قنوات مخصصة لكل نوع من الأذكار
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
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFFA726), // لون برتقالي
          vibrationPattern: Int64List.fromList([
            0,
            500,
            200,
            500,
          ]), // نمط اهتزاز مميز
          sound: RawResourceAndroidNotificationSound(
            'morning_sound',
          ), // صوت مخصص
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
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF5C6BC0), // لون أزرق
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
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
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF9C27B0), // لون بنفسجي
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          sound: RawResourceAndroidNotificationSound('sleep_sound'),
        ),
      );
    }

    debugPrint('✅ تم إنشاء قنوات الإشعارات بنجاح');
  }

  // إرسال إشعار فوري بتصميم احترافي
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'islamic_app_channel',
    Color? color,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          'الأذكار والصلاة',
          channelDescription: 'إشعارات الأذكار ومواقيت الصلاة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          color: color ?? const Color(0xFF1B5E20),
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ongoing: false,
          autoCancel: true,
          fullScreenIntent: true,
          // تصميم Big Text Style للنصوص الطويلة
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: true,
            contentTitle: title,
            htmlFormatContentTitle: true,
            summaryText: 'نَجَاتَك',
            htmlFormatSummaryText: true,
          ),
          // أزرار الإجراءات
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'open_app',
              'فتح التطبيق',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'dismiss',
              'تجاهل',
              cancelNotification: true,
            ),
          ],
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

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('تم إرسال إشعار فوري - ID: $id');
  }

  // جدولة إشعار يومي بتصميم احترافي
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    required NotificationType type,
  }) async {
    try {
      await _notifications.cancel(id);

      // اختيار القناة والإعدادات حسب نوع الذكر
      String channelId;
      Color color;
      String emoji;

      switch (type) {
        case NotificationType.morning:
          channelId = 'morning_azkar_channel';
          color = const Color(0xFFFFA726);
          emoji = '🌅';
          break;
        case NotificationType.evening:
          channelId = 'evening_azkar_channel';
          color = const Color(0xFF5C6BC0);
          emoji = '🌙';
          break;
        case NotificationType.sleep:
          channelId = 'sleep_azkar_channel';
          color = const Color(0xFF9C27B0);
          emoji = '🌟';
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
            enableVibration: true,
            enableLights: true,
            color: color,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            ongoing: false,
            autoCancel: true,
            fullScreenIntent: true,
            channelShowBadge: true,
            showWhen: true,
            // تصميم Big Text مع الرموز التعبيرية
            styleInformation: BigTextStyleInformation(
              '$emoji $body',
              htmlFormatBigText: true,
              contentTitle: '$emoji $title',
              htmlFormatContentTitle: true,
              summaryText: 'نَجَاتَك - تطبيق الأذكار',
              htmlFormatSummaryText: true,
            ),
            // أزرار الإجراءات
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'open_azkar',
                'عرض الأذكار',
                icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'dismiss',
                'حسناً',
                cancelNotification: true,
              ),
            ],
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

      debugPrint('═══════════════════════════════════════');
      debugPrint('📅 جدولة إشعار جديد:');
      debugPrint('   النوع: ${_getChannelName(type)}');
      debugPrint('   ID: $id');
      debugPrint('   العنوان: $title');
      debugPrint('   الوقت: $hour:${minute.toString().padLeft(2, '0')}');
      debugPrint('═══════════════════════════════════════');

      await _notifications.zonedSchedule(
        id,
        '$emoji $title',
        '$emoji $body',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      debugPrint('✅ تم جدولة الإشعار بنجاح!');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار: $e');
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
    debugPrint('🗑️ تم إلغاء الإشعار رقم: $id');
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

  static Future<void> testNotification() async {
    await showNotification(
      id: 999,
      title: 'إشعار تجريبي',
      body: 'الإشعارات تعمل بشكل صحيح! ✓',
      color: const Color(0xFF1B5E20),
    );
  }

  static Future<void> testScheduledNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(minutes: 1));

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'morning_azkar_channel',
          'أذكار الصباح',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: Color(0xFFFFA726),
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            '⏰ سيظهر هذا الإشعار بعد دقيقة واحدة',
            contentTitle: '🧪 اختبار إشعار مجدول',
            summaryText: 'نَجَاتَك',
          ),
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      998,
      '🧪 اختبار إشعار مجدول',
      '⏰ سيظهر هذا الإشعار بعد دقيقة واحدة',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('✅ تم جدولة إشعار تجريبي بعد دقيقة واحدة');
  }
}

// نوع الإشعار (Enum)
enum NotificationType { morning, evening, sleep }
