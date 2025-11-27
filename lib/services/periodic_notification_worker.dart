// ═══════════════════════════════════════════════════════════════
// lib/services/periodic_notification_worker.dart - الحل النهائي
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

const String periodicAzkarTaskName = "periodicAzkarTask";
const String rescheduleTaskName = "rescheduleTask";

// ═══════════════════════════════════════════════════════════════
// نقطة الدخول للـ Background Tasks
// ═══════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("🔄 Worker: تنفيذ المهمة - $task");

      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('periodic_enabled') ?? false;

      if (!isEnabled) {
        debugPrint("⏹️ الأذكار متوقفة - خروج");
        return Future.value(true);
      }

      // إعادة جدولة الإشعارات
      await _rescheduleNotifications(prefs);

      debugPrint("✅ Worker: اكتمل التنفيذ");
      return Future.value(true);
    } catch (e) {
      debugPrint("❌ Worker خطأ: $e");
      return Future.value(false);
    }
  });
}

// ═══════════════════════════════════════════════════════════════
// إعادة جدولة الإشعارات
// ═══════════════════════════════════════════════════════════════
Future<void> _rescheduleNotifications(SharedPreferences prefs) async {
  try {
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      ),
    );

    final pending = await notifications.pendingNotificationRequests();
    final periodicCount = pending.where((n) => n.id >= 10000).length;

    debugPrint("📊 إشعارات مجدولة: $periodicCount");

    // إذا كانت أقل من 30، أعد الجدولة
    if (periodicCount < 30) {
      debugPrint("🔄 إعادة جدولة الإشعارات...");

      final intervalMinutes = prefs.getInt('periodic_interval') ?? 30;
      final savedAzkar = prefs.getString('periodic_selected');

      if (savedAzkar != null && savedAzkar.isNotEmpty) {
        final List<String> selectedIds = List<String>.from(
          json.decode(savedAzkar),
        );

        final azkarData = _getAzkarData();
        final selectedAzkar = selectedIds
            .map(
              (id) => azkarData.firstWhere(
                (z) => z['id'] == id,
                orElse: () => azkarData[0],
              ),
            )
            .toList();

        await _scheduleNextBatch(
          prefs,
          notifications,
          selectedAzkar,
          intervalMinutes,
        );
      }
    }
  } catch (e) {
    debugPrint("❌ خطأ في إعادة الجدولة: $e");
  }
}

// ═══════════════════════════════════════════════════════════════
// جدولة دفعة جديدة من الإشعارات
// ═══════════════════════════════════════════════════════════════
Future<void> _scheduleNextBatch(
  SharedPreferences prefs,
  FlutterLocalNotificationsPlugin notifications,
  List<Map<String, String>> azkarList,
  int intervalMinutes,
) async {
  try {
    // الحصول على آخر index
    int currentIndex = prefs.getInt('current_index') ?? 0;
    int baseId = prefs.getInt('base_notification_id') ?? 10000;

    final now = tz.TZDateTime.now(tz.local);
    int scheduled = 0;

    // جدولة 100 إشعار
    for (int i = 0; i < 100; i++) {
      final azkarIndex = (currentIndex + i) % azkarList.length;
      final zekr = azkarList[azkarIndex];

      int zekrNumber = azkarIndex + 1;
      final match = RegExp(r'zekr_(\d+)').firstMatch(zekr['sound']!);
      if (match != null) {
        zekrNumber = int.parse(match.group(1)!);
      }

      // ID فريد لكل إشعار
      final notificationId = baseId + i;

      // حساب وقت الإشعار
      final offsetMinutes = i * intervalMinutes;
      final scheduledTime = now.add(Duration(minutes: offsetMinutes));

      // التأكد أن التاريخ في المستقبل
      if (scheduledTime.isBefore(now.add(const Duration(seconds: 10)))) {
        continue;
      }

      try {
        await notifications.zonedSchedule(
          notificationId,
          'أذكار دورية • نَجَاتَك',
          zekr['text']!,
          scheduledTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'periodic_zekr_${zekrNumber}_channel',
              'ذكر دوري $zekrNumber',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound(zekr['sound']!),
              enableVibration: false,
              icon: '@mipmap/launcher_icon',
              // 🔥 إضافة هذه الخصائص للاستمرارية
              autoCancel: false,
              ongoing: false,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        scheduled++;
      } catch (e) {
        debugPrint("⚠️ خطأ في جدولة إشعار $i: $e");
      }
    }

    // تحديث الـ index والـ base ID
    await prefs.setInt('current_index', currentIndex + 100);
    await prefs.setInt('base_notification_id', baseId + 100);

    debugPrint("✅ تم جدولة $scheduled إشعار جديد");
  } catch (e) {
    debugPrint("❌ خطأ في الجدولة: $e");
  }
}

// ═══════════════════════════════════════════════════════════════
// بيانات الأذكار
// ═══════════════════════════════════════════════════════════════
List<Map<String, String>> _getAzkarData() {
  return [
    {'text': 'لَا إِلَهَ إِلَّا اللهُ', 'id': 'zekr1', 'sound': 'zekr_1'},
    {
      'text':
          'لَا إلَهَ إلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَئٍ قَدِيرُ',
      'id': 'zekr2',
      'sound': 'zekr_2',
    },
    {'text': 'أَسْتَغْفِرُ اللهَ العَظِيمَ', 'id': 'zekr3', 'sound': 'zekr_3'},
    {
      'text': 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّد',
      'id': 'zekr4',
      'sound': 'zekr_4',
    },
    {
      'text':
          'سُبْحَانَ اللهِ، وَالْحَمْدُ للهِ، وَلَا إلَهَ إلَّا اللهُ، وَاللهُ أَكْبَرُ',
      'id': 'zekr5',
      'sound': 'zekr_5',
    },
    {
      'text': 'لَا حَوْلَ وَلَا قُوَّةَ إلَّا بِاللهِ',
      'id': 'zekr6',
      'sound': 'zekr_6',
    },
    {
      'text':
          'حَسْبِيَ اللهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      'id': 'zekr7',
      'sound': 'zekr_7',
    },
    {
      'text': 'سُبْحَانَ اللهِ وَبِحَمْدِهِ سُبْحَانَ اللهِ العَظِيْمِ',
      'id': 'zekr8',
      'sound': 'zekr_8',
    },
    {
      'text':
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
      'id': 'zekr9',
      'sound': 'zekr_9',
    },
    {
      'text':
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      'id': 'zekr10',
      'sound': 'zekr_10',
    },
    {
      'text':
          'اللَّهُمَّ لَكَ الْحَمْدُ وَلَكَ الشُّكْرُ عَلَى نِعَمِكَ الَّتِي لَا تُعَدُّ وَلَا تُحْصَى',
      'id': 'zekr11',
      'sound': 'zekr_11',
    },
    {
      'text':
          'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      'id': 'zekr12',
      'sound': 'zekr_12',
    },
    {
      'text':
          'اللَّهُمَّ يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
      'id': 'zekr13',
      'sound': 'zekr_13',
    },
    {
      'text':
          'سُبْحَانَ اللهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      'id': 'zekr14',
      'sound': 'zekr_14',
    },
  ];
}

// ═══════════════════════════════════════════════════════════════
// واجهة التحكم في Worker
// ═══════════════════════════════════════════════════════════════

class PeriodicAzkarWorker {
  /// تهيئة WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    debugPrint("✅ تم تهيئة WorkManager");
  }

  /// تشغيل الأذكار الدورية
  static Future<void> startPeriodicWorker(
    List<Map<String, String>> azkarList,
    int intervalMinutes,
  ) async {
    try {
      debugPrint("═══════════════════════════════════════");
      debugPrint("🚀 بدء تشغيل الأذكار الدورية • نَجَاتَك");
      debugPrint("📝 عدد الأذكار: ${azkarList.length}");
      debugPrint("⏱️  الفاصل: $intervalMinutes دقيقة");

      // 1️⃣ إلغاء كل شيء قديم
      await Workmanager().cancelAll();
      final notifications = FlutterLocalNotificationsPlugin();
      await notifications.cancelAll();

      debugPrint("🗑️  تم مسح جميع الإشعارات القديمة");

      // 2️⃣ إعادة تعيين الـ counters
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_index', 0);
      await prefs.setInt('base_notification_id', 10000);

      // 3️⃣ جدولة أول 100 إشعار
      await _scheduleInitialNotifications(azkarList, intervalMinutes);

      // 4️⃣ تشغيل Worker للمراقبة المستمرة
      // 🔥 Worker يشتغل كل 15 دقيقة للتأكد من استمرار الإشعارات
      await Workmanager().registerPeriodicTask(
        rescheduleTaskName,
        rescheduleTaskName,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(minutes: 10),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

      // 5️⃣ حفظ الحالة
      await prefs.setBool('periodic_enabled', true);

      debugPrint("✅ تم التشغيل بنجاح!");
      debugPrint("📱 أول إشعار بعد $intervalMinutes دقيقة");
      debugPrint("🔄 Worker يفحص كل 15 دقيقة لضمان الاستمرارية");
      debugPrint("═══════════════════════════════════════");
    } catch (e) {
      debugPrint("❌ خطأ في التشغيل: $e");
      rethrow;
    }
  }

  /// جدولة الدفعة الأولى من الإشعارات
  static Future<void> _scheduleInitialNotifications(
    List<Map<String, String>> azkarList,
    int intervalMinutes,
  ) async {
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    int scheduled = 0;

    // جدولة 100 إشعار (تكفي لعدة أيام حسب الفاصل الزمني)
    for (int i = 0; i < 100; i++) {
      final azkarIndex = i % azkarList.length;
      final zekr = azkarList[azkarIndex];

      int zekrNumber = azkarIndex + 1;
      final match = RegExp(r'zekr_(\d+)').firstMatch(zekr['sound']!);
      if (match != null) {
        zekrNumber = int.parse(match.group(1)!);
      }

      final notificationId = 10000 + i;

      // حساب وقت الإشعار
      final offsetMinutes = i * intervalMinutes;
      final scheduledTime = now.add(Duration(minutes: offsetMinutes));

      try {
        await notifications.zonedSchedule(
          notificationId,
          'أذكار دورية • نَجَاتَك',
          zekr['text']!,
          scheduledTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'periodic_zekr_${zekrNumber}_channel',
              'ذكر دوري $zekrNumber',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound(zekr['sound']!),
              enableVibration: false,
              icon: '@mipmap/launcher_icon',
              autoCancel: false,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        scheduled++;

        if (i < 3) {
          debugPrint(
            "   ✅ إشعار ${i + 1}: ${scheduledTime.day}/${scheduledTime.month} "
            "${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}",
          );
        }
      } catch (e) {
        debugPrint("   ⚠️ خطأ في جدولة إشعار $i: $e");
      }
    }

    debugPrint("✅ تم جدولة $scheduled إشعار");
  }

  /// إيقاف الأذكار الدورية
  static Future<void> stopPeriodicWorker() async {
    try {
      debugPrint("🛑 إيقاف الأذكار الدورية...");

      // إيقاف Worker
      await Workmanager().cancelAll();

      // إلغاء جميع الإشعارات
      final notifications = FlutterLocalNotificationsPlugin();
      await notifications.cancelAll();

      // تحديث الحالة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('periodic_enabled', false);

      debugPrint("🛑 تم الإيقاف بنجاح");
    } catch (e) {
      debugPrint("❌ خطأ في الإيقاف: $e");
    }
  }

  /// الحصول على حالة النظام
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = FlutterLocalNotificationsPlugin();
      final pending = await notifications.pendingNotificationRequests();

      final periodicCount = pending.where((n) => n.id >= 10000).length;

      return {
        'isEnabled': prefs.getBool('periodic_enabled') ?? false,
        'intervalMinutes': prefs.getInt('periodic_interval') ?? 30,
        'selectedCount': (prefs.getString('periodic_selected') != null)
            ? json.decode(prefs.getString('periodic_selected')!).length
            : 0,
        'scheduledNotifications': periodicCount,
        'currentIndex': prefs.getInt('current_index') ?? 0,
      };
    } catch (e) {
      debugPrint("❌ خطأ في جلب الحالة: $e");
      return {};
    }
  }
}
