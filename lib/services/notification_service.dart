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
      final granted = await androidImplementation
          .requestNotificationsPermission();
      print('صلاحية الإشعارات: $granted');

      // طلب صلاحية الإشعارات الدقيقة للأندرويد 12+
      final exactAlarmGranted = await androidImplementation
          .requestExactAlarmsPermission();
      print('صلاحية الإشعارات الدقيقة: $exactAlarmGranted');
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

    print('تم إرسال إشعار فوري - ID: $id');
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
    try {
      // إلغاء أي إشعار قديم بنفس ID
      await _notifications.cancel(id);
      print('تم إلغاء الإشعار القديم - ID: $id');

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

      print('═══════════════════════════════════════');
      print('📅 جدولة إشعار جديد:');
      print('   ID: $id');
      print('   العنوان: $title');
      print('   الوقت المطلوب: $hour:${minute.toString().padLeft(2, '0')}');
      print('   الوقت المجدول: ${scheduledDate.toString()}');
      print('   الوقت الحالي: ${tz.TZDateTime.now(tz.local).toString()}');
      print('═══════════════════════════════════════');

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

      print('✅ تم جدولة الإشعار بنجاح!');

      // التحقق من الإشعارات المجدولة
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 عدد الإشعارات المجدولة الآن: ${pending.length}');
      for (var p in pending) {
        print('   - ID: ${p.id}, العنوان: ${p.title}');
      }
    } catch (e) {
      print('❌ خطأ في جدولة الإشعار: $e');
    }
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
      print('⏭️ الوقت مضى اليوم، سيتم الجدولة للغد');
    } else {
      print('⏰ سيتم الجدولة لنفس اليوم');
    }

    return scheduledDate;
  }

  // إلغاء إشعار محدد
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ تم إلغاء الإشعار رقم: $id');
  }

  // إلغاء جميع الإشعارات
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ تم إلغاء جميع الإشعارات');
  }

  // الحصول على قائمة الإشعارات المجدولة
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    print('📋 عدد الإشعارات المجدولة: ${pending.length}');
    for (var notification in pending) {
      print('   - ID: ${notification.id}, العنوان: ${notification.title}');
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

  // دالة جديدة: اختبار إشعار مجدول بعد دقيقة واحدة
  static Future<void> testScheduledNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(minutes: 1));

    print('═══════════════════════════════════════');
    print('🧪 اختبار إشعار مجدول:');
    print('   الوقت الحالي: ${now.toString()}');
    print('   الوقت المجدول: ${scheduledTime.toString()}');
    print('═══════════════════════════════════════');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'islamic_app_channel',
          'الأذكار والصلاة',
          channelDescription: 'إشعارات الأذكار ومواقيت الصلاة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      998,
      'اختبار إشعار مجدول',
      'سيظهر هذا الإشعار بعد دقيقة واحدة',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('✅ تم جدولة إشعار تجريبي بعد دقيقة واحدة');
  }
}
