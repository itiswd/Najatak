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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('تم الضغط على الإشعار: ${response.payload}');

        // التحقق من إشعارات إعادة الجدولة التلقائية
        if (response.payload != null &&
            response.payload!.startsWith('renewal:')) {
          await handleAutoRenewal(response.payload!);
        }
      },
    );

    // التحقق من الإشعارات عند بدء التطبيق
    await _checkAndHandleRenewalNotifications();

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
          enableVibration: false,
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
          enableVibration: false,
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
          enableVibration: false,
          enableLights: true,
          ledColor: Color(0xFF9C27B0),
          sound: RawResourceAndroidNotificationSound('sleep_sound'),
        ),
      );

      // إنشاء قنوات منفصلة لكل ذكر دوري بصوته الخاص
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
            enableLights: true,
            ledColor: Color(0xFF1B5E20),
            sound: RawResourceAndroidNotificationSound(periodicSounds[i]),
          ),
        );
      }

      // قناة التجديد التلقائي
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'renewal_channel',
          'تجديد تلقائي',
          description: 'قناة لتجديد الأذكار الدورية تلقائياً',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          enableLights: false,
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
          enableVibration: false,
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
      String soundName;

      switch (type) {
        case NotificationType.morning:
          channelId = 'morning_azkar_channel';
          color = const Color(0xFFFFA726);
          soundName = 'morning_sound';
          body = 'حان وقت أذكار الصباح 🌅';
          break;
        case NotificationType.evening:
          channelId = 'evening_azkar_channel';
          color = const Color(0xFF5C6BC0);
          soundName = 'evening_sound';
          body = 'حان وقت أذكار المساء 🌙';
          break;
        case NotificationType.sleep:
          channelId = 'sleep_azkar_channel';
          color = const Color(0xFF9C27B0);
          soundName = 'sleep_sound';
          body = 'لا تنسى أذكار النوم 🌟';
          break;
        case NotificationType.periodic:
          channelId = 'periodic_azkar_channel';
          color = const Color(0xFF1B5E20);
          soundName = 'default_sound';
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
            styleInformation: BigTextStyleInformation(
              body,
              htmlFormatBigText: true,
              contentTitle: 'نَجَاتَك',
              htmlFormatContentTitle: true,
              summaryText: _getChannelName(type),
            ),
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
      debugPrint('   العنوان: نَجَاتَك');
      debugPrint('   الوقت: $hour:${minute.toString().padLeft(2, '0')}');
      debugPrint('═══════════════════════════════════════');

      await _notifications.zonedSchedule(
        id,
        'نَجَاتَك',
        body,
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
    required String soundFileName,
    required int delayMinutes,
    required int intervalMinutes,
    String? payload,
  }) async {
    try {
      // إلغاء جميع النسخ القديمة
      for (int i = 0; i < 2000; i++) {
        await _notifications.cancel(id + i * 1000);
      }

      // استخراج رقم الذكر من اسم الملف الصوتي (مثل: zekr_1 -> 1)
      int zekrNumber = 1;
      final match = RegExp(r'zekr_(\d+)').firstMatch(soundFileName);
      if (match != null) {
        zekrNumber = int.parse(match.group(1)!);
      }

      // استخدام قناة مخصصة لهذا الذكر
      final channelId = 'periodic_zekr_${zekrNumber}_channel';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            'ذكر دوري $zekrNumber',
            channelDescription: 'قناة للذكر الدوري رقم $zekrNumber',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(soundFileName),
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
              summaryText: 'أذكار دورية',
            ),
          );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // حساب وقت أول إشعار
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = now.add(Duration(minutes: delayMinutes));

      debugPrint('═══════════════════════════════════════');
      debugPrint('📅 جدولة إشعار دوري:');
      debugPrint('   ID: $id');
      debugPrint('   العنوان: $title');
      debugPrint('   الذكر: $body');
      debugPrint('   الصوت: $soundFileName (قناة: $channelId)');
      debugPrint('   التأخير: $delayMinutes دقيقة');
      debugPrint('   التكرار: كل $intervalMinutes دقيقة');
      debugPrint(
        '   أول ظهور: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
      );
      debugPrint('═══════════════════════════════════════');

      // جدولة جميع النسخ المستقبلية (7 أيام = 10080 دقيقة)
      int notificationCount = 0;
      final endTime = now.add(Duration(days: 7)); // جدولة لمدة أسبوع كامل

      while (scheduledDate.isBefore(endTime)) {
        await _notifications.zonedSchedule(
          id + notificationCount * 1000, // ID فريد لكل إشعار
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );

        if (notificationCount < 10) {
          // طباعة أول 10 فقط
          debugPrint(
            '   ✅ نسخة #${notificationCount + 1}: ${scheduledDate.day}/${scheduledDate.month} ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
          );
        }

        scheduledDate = scheduledDate.add(Duration(minutes: intervalMinutes));
        notificationCount++;
      }

      debugPrint('✅ تم جدولة $notificationCount إشعار دوري لمدة 7 أيام!');

      // جدولة إشعار إعادة الجدولة التلقائية (قبل يوم من انتهاء المدة)
      final renewalTime = now.add(Duration(days: 6));
      await _scheduleAutoRenewal(
        id: id + 999000, // ID خاص بإشعار التجديد
        originalId: id,
        title: title,
        body: body,
        soundFileName: soundFileName,
        delayMinutes: delayMinutes,
        intervalMinutes: intervalMinutes,
        renewalTime: renewalTime,
        payload: payload,
      );

      debugPrint(
        '📅 تم جدولة إعادة الجدولة التلقائية في: ${renewalTime.day}/${renewalTime.month} ${renewalTime.hour}:${renewalTime.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار الدوري: $e');
    }
  }

  // جدولة إعادة الجدولة التلقائية
  static Future<void> _scheduleAutoRenewal({
    required int id,
    required int originalId,
    required String title,
    required String body,
    required String soundFileName,
    required int delayMinutes,
    required int intervalMinutes,
    required tz.TZDateTime renewalTime,
    String? payload,
  }) async {
    try {
      // إنشاء إشعار خفي لإعادة الجدولة
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'renewal_channel',
            'تجديد تلقائي',
            channelDescription: 'قناة لتجديد الأذكار الدورية تلقائياً',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
            enableLights: false,
            ongoing: false,
            autoCancel: true,
            visibility: NotificationVisibility.secret, // إخفاء الإشعار
          );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.zonedSchedule(
        id,
        'تجديد الأذكار',
        'جاري تجديد الأذكار الدورية...',
        renewalTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload:
            'renewal:$originalId:$title:$body:$soundFileName:$delayMinutes:$intervalMinutes',
      );

      debugPrint('✅ تم جدولة إعادة الجدولة التلقائية - ID: $id');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة إعادة الجدولة: $e');
    }
  }

  // معالجة إعادة الجدولة التلقائية
  static Future<void> handleAutoRenewal(String payload) async {
    try {
      final parts = payload.split(':');
      if (parts[0] != 'renewal' || parts.length < 7) return;

      final originalId = int.parse(parts[1]);
      final title = parts[2];
      final body = parts[3];
      final soundFileName = parts[4];
      final delayMinutes = int.parse(parts[5]);
      final intervalMinutes = int.parse(parts[6]);

      debugPrint('🔄 بدء إعادة الجدولة التلقائية للذكر ID: $originalId');

      // إعادة جدولة الإشعارات لمدة 7 أيام جديدة
      await scheduleSequentialNotification(
        id: originalId,
        title: title,
        body: body,
        soundFileName: soundFileName,
        delayMinutes: 5, // بدون تأخير لأنه تجديد
        intervalMinutes: intervalMinutes,
        payload: parts.sublist(7).join(':'), // باقي البيانات
      );

      debugPrint('✅ تم إعادة الجدولة التلقائية بنجاح!');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة إعادة الجدولة: $e');
    }
  }

  // التحقق من إشعارات التجديد المعلقة عند بدء التطبيق
  static Future<void> _checkAndHandleRenewalNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();

      for (var notification in pending) {
        if (notification.payload != null &&
            notification.payload!.startsWith('renewal:')) {
          // التحقق إذا كان وقت التجديد قد حان
          final now = tz.TZDateTime.now(tz.local);
          // إذا كان الإشعار في الماضي أو خلال الساعة القادمة
          debugPrint('🔍 تم العثور على إشعار تجديد معلق: ${notification.id}');
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من إشعارات التجديد: $e');
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
    // إلغاء الإشعار الأساسي وجميع النسخ المتكررة
    for (int i = 0; i < 100; i++) {
      await _notifications.cancel(id + i * 1000);
    }
    debugPrint('🗑️ تم إلغاء الإشعار رقم: $id وجميع نسخه');
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
