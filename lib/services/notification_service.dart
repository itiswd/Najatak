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
      // قناة أذكار الصباح (بدون اهتزاز)
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'morning_azkar_channel',
          'أذكار الصباح',
          description: 'إشعارات أذكار الصباح',
          importance: Importance.max,
          playSound: true,
          enableVibration: false, // إلغاء الاهتزاز
          enableLights: true,
          ledColor: Color(0xFFFFA726),
          sound: RawResourceAndroidNotificationSound('morning_sound'),
        ),
      );

      // قناة أذكار المساء (بدون اهتزاز)
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'evening_azkar_channel',
          'أذكار المساء',
          description: 'إشعارات أذكار المساء',
          importance: Importance.max,
          playSound: true,
          enableVibration: false, // إلغاء الاهتزاز
          enableLights: true,
          ledColor: Color(0xFF5C6BC0),
          sound: RawResourceAndroidNotificationSound('evening_sound'),
        ),
      );

      // قناة أذكار النوم (بدون اهتزاز)
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'sleep_azkar_channel',
          'أذكار النوم',
          description: 'إشعارات أذكار النوم',
          importance: Importance.max,
          playSound: true,
          enableVibration: false, // إلغاء الاهتزاز
          enableLights: true,
          ledColor: Color(0xFF9C27B0),
          sound: RawResourceAndroidNotificationSound('sleep_sound'),
        ),
      );

      // قناة الأذكار الدورية (بدون اهتزاز)
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'periodic_azkar_channel',
          'الأذكار الدورية',
          description: 'إشعارات الأذكار الدورية المخصصة',
          importance: Importance.high,
          playSound: true,
          enableVibration: false, // إلغاء الاهتزاز
          enableLights: true,
          ledColor: Color(0xFF1B5E20),
          sound: RawResourceAndroidNotificationSound('default_sound'),
        ),
      );
    }

    debugPrint('✅ تم إنشاء قنوات الإشعارات بنجاح');
  }

  // إرسال إشعار فوري بتصميم احترافي (بدون اهتزاز)
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
          enableVibration: false, // إلغاء الاهتزاز
          enableLights: true,
          color: color ?? const Color(0xFF1B5E20),
          icon: '@mipmap/launcher_icon',
          largeIcon: const DrawableResourceAndroidBitmap(
            '@mipmap/launcher_icon',
          ),
          ongoing: false,
          autoCancel: true,
          fullScreenIntent: true,
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: true,
            contentTitle: title,
            htmlFormatContentTitle: true,
            summaryText: 'نَجَاتَك',
            htmlFormatSummaryText: true,
          ),
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'open_app',
              'فتح التطبيق',
              icon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
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

  // جدولة إشعار يومي بتصميم احترافي (بدون اهتزاز)
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
        case NotificationType.periodic:
          channelId = 'periodic_azkar_channel';
          color = const Color(0xFF1B5E20);
          emoji = '📿';
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
            enableVibration: false, // إلغاء الاهتزاز
            enableLights: true,
            color: color,
            icon: '@mipmap/launcher_icon',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/launcher_icon',
            ),
            ongoing: false,
            autoCancel: true,
            fullScreenIntent: false,
            channelShowBadge: true,
            showWhen: true,
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
        '$title $emoji',
        '$body $emoji',
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

  // جدولة إشعار متسلسل (يظهر بعد وقت محدد ويتكرر)
  static Future<void> scheduleSequentialNotification({
    required int id,
    required String title,
    required String body,
    required int delayMinutes, // التأخير قبل أول ظهور
    required int intervalMinutes, // الفاصل بين التكرار
    String? payload,
  }) async {
    try {
      await _notifications.cancel(id);

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'periodic_azkar_channel',
        'الأذكار الدورية',
        channelDescription: 'إشعارات الأذكار الدورية المخصصة',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: false,
        enableLights: true,
        color: Color(0xFF1B5E20),
        icon: '@mipmap/launcher_icon',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        ongoing: false,
        autoCancel: true,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: 'نَجَاتَك',
        ),
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // حساب وقت أول إشعار
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(Duration(minutes: delayMinutes));

      // جدولة الإشعار مع التكرار
      await _notifications.zonedSchedule(
        id,
        '$title 📿',
        '$body 📿',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('═══════════════════════════════════════');
      debugPrint('📅 جدولة إشعار متسلسل:');
      debugPrint('   ID: $id');
      debugPrint('   العنوان: $title');
      debugPrint('   التأخير: $delayMinutes دقيقة');
      debugPrint('   التكرار: كل $intervalMinutes دقيقة');
      debugPrint(
        '   أول ظهور: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
      );
      debugPrint('═══════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار المتسلسل: $e');
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
      case NotificationType.periodic:
        return 'الأذكار الدورية';
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
}

// نوع الإشعار (Enum)
enum NotificationType { morning, evening, sleep, periodic }
