import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();

    // تعيين المنطقة الزمنية المحلية (القاهرة لمصر)
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

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
        print('تم الضغط على الإشعار: ${response.payload}');
      },
    );

    // طلب الصلاحيات للأندرويد 13+
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();

      // طلب صلاحية الإشعارات الدقيقة للأندرويد 12+
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // إرسال إشعار فوري
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'islamic_app_channel',
          'الأذكار والصلاة',
          channelDescription: 'إشعارات الأذكار ومواقيت الصلاة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          color: Color(0xFF1B5E20),
          icon: '@mipmap/ic_launcher',
          ongoing: false,
          autoCancel: true,
          fullScreenIntent: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
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
  }

  // جدولة إشعار في وقت محدد
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'islamic_app_channel',
          'الأذكار والصلاة',
          channelDescription: 'إشعارات الأذكار ومواقيت الصلاة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          color: Color(0xFF1B5E20),
          icon: '@mipmap/ic_launcher',
          ongoing: false,
          autoCancel: true,
          fullScreenIntent: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // جدولة إشعار يومي (هذه الدالة الأساسية للأذكار)
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'islamic_app_channel',
          'الأذكار والصلاة',
          channelDescription: 'إشعارات الأذكار ومواقيت الصلاة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          color: Color(0xFF1B5E20),
          icon: '@mipmap/ic_launcher',
          ongoing: false,
          autoCancel: true,
          fullScreenIntent: true,
          channelShowBadge: true,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // حساب الوقت التالي للإشعار
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    print('جدولة إشعار: $title في ${scheduledDate.toString()}');

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
  }

  // حساب الوقت التالي للإشعار
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

    // إذا كان الوقت قد مضى اليوم، جدول للغد
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // إلغاء إشعار محدد
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('تم إلغاء الإشعار رقم: $id');
  }

  // إلغاء جميع الإشعارات
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('تم إلغاء جميع الإشعارات');
  }

  // الحصول على قائمة الإشعارات المجدولة
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    print('عدد الإشعارات المجدولة: ${pending.length}');
    for (var notification in pending) {
      print('إشعار ID: ${notification.id}, العنوان: ${notification.title}');
    }
    return pending;
  }

  // دالة اختبار لإرسال إشعار فوري
  static Future<void> testNotification() async {
    await showNotification(
      id: 999,
      title: 'إشعار تجريبي',
      body: 'الإشعارات تعمل بشكل صحيح! ✓',
    );
  }
}
