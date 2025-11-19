import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

/// ══════════════════════════════════════════════════════════════
/// نظام هجين: WorkManager + Scheduled Notifications
/// يضمن دقة عالية وعمل دائم حتى مع الفواصل القصيرة
/// ══════════════════════════════════════════════════════════════

const String periodicAzkarTaskName = "periodicAzkarTask";
const String periodicAzkarCheckTask = "periodicAzkarCheckTask";

/// نقطة الدخول للـ Background Tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("🔄 Worker: بدء المهمة - $task");

      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('periodic_azkar_enabled') ?? false;

      if (!isEnabled) {
        debugPrint("⚠️ الأذكار الدورية معطلة");
        return Future.value(true);
      }

      // إعادة جدولة الإشعارات إذا لزم الأمر
      await _recheckAndReschedule(prefs);

      debugPrint("✅ Worker: اكتمل التنفيذ");
      return Future.value(true);
    } catch (e) {
      debugPrint("❌ Worker خطأ: $e");
      return Future.value(false);
    }
  });
}

/// التحقق وإعادة جدولة الإشعارات إذا لزم الأمر
Future<void> _recheckAndReschedule(SharedPreferences prefs) async {
  try {
    final notifications = FlutterLocalNotificationsPlugin();
    final pending = await notifications.pendingNotificationRequests();

    // عدد الإشعارات الدورية المجدولة
    final periodicCount = pending.where((n) => n.id >= 6000).length;

    debugPrint("📊 Worker: إشعارات دورية مجدولة: $periodicCount");

    // إذا كانت أقل من 10، أعد الجدولة
    if (periodicCount < 10) {
      debugPrint("⚠️ Worker: إعادة جدولة الإشعارات...");

      final intervalMinutes = prefs.getInt('periodic_azkar_interval') ?? 30;
      final savedAzkar = prefs.getString('periodic_selected_azkar');

      if (savedAzkar != null && savedAzkar.isNotEmpty) {
        final List<String> selectedIds = List<String>.from(
          json.decode(savedAzkar),
        );
        final azkarData = _getAzkarData();

        final azkarList = selectedIds
            .map(
              (id) => azkarData.firstWhere(
                (z) => z['id'] == id,
                orElse: () => azkarData[0],
              ),
            )
            .toList();

        await _scheduleNextBatch(prefs, azkarList, intervalMinutes);
      }
    }
  } catch (e) {
    debugPrint("❌ خطأ في _recheckAndReschedule: $e");
  }
}

/// جدولة دفعة جديدة من الإشعارات
Future<void> _scheduleNextBatch(
  SharedPreferences prefs,
  List<Map<String, String>> azkarList,
  int intervalMinutes,
) async {
  try {
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    int currentIndex = prefs.getInt('current_periodic_index') ?? 0;

    // جدولة 50 إشعار قادم
    for (int i = 0; i < 50; i++) {
      final azkarIndex = currentIndex % azkarList.length;
      final zekr = azkarList[azkarIndex];

      int zekrNumber = azkarIndex + 1;
      final match = RegExp(r'zekr_(\d+)').firstMatch(zekr['sound']!);
      if (match != null) {
        zekrNumber = int.parse(match.group(1)!);
      }

      final notificationId = 6000 + i;
      final scheduledTime = now.add(
        Duration(minutes: intervalMinutes * (i + 1)),
      );

      await notifications.zonedSchedule(
        notificationId,
        'أذكار دورية',
        zekr['text']!,
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'periodic_zekr_${zekrNumber}_channel',
            'ذكر دوري $zekrNumber',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(zekr['sound']!),
            enableVibration: false,
            icon: '@mipmap/launcher_icon',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      currentIndex++;

      if (i < 3) {
        debugPrint(
          "   ✅ جدولة: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}",
        );
      }
    }

    await prefs.setInt('current_periodic_index', currentIndex);
    debugPrint("✅ تم جدولة 50 إشعار قادم");
  } catch (e) {
    debugPrint("❌ خطأ في _scheduleNextBatch: $e");
  }
}

/// قائمة الأذكار
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

/// ══════════════════════════════════════════════════════════════
/// واجهة التحكم في Worker
/// ══════════════════════════════════════════════════════════════

class PeriodicAzkarWorker {
  /// تهيئة WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    debugPrint("✅ تم تهيئة WorkManager");
  }

  /// تشغيل الأذكار الدورية (النظام الهجين)
  static Future<void> startPeriodicWorker(int intervalMinutes) async {
    try {
      debugPrint("═══════════════════════════════════════");
      debugPrint("🚀 بدء تشغيل الأذكار الدورية");
      debugPrint("⏱️  الفاصل: $intervalMinutes دقيقة");

      final prefs = await SharedPreferences.getInstance();
      final savedAzkar = prefs.getString('periodic_selected_azkar');

      if (savedAzkar == null || savedAzkar.isEmpty) {
        debugPrint("❌ لا توجد أذكار محددة");
        return;
      }

      final List<String> selectedIds = List<String>.from(
        json.decode(savedAzkar),
      );
      final azkarData = _getAzkarData();

      final azkarList = selectedIds
          .map(
            (id) => azkarData.firstWhere(
              (z) => z['id'] == id,
              orElse: () => azkarData[0],
            ),
          )
          .toList();

      // 1️⃣ إلغاء كل شيء قديم
      await Workmanager().cancelAll();
      final notifications = FlutterLocalNotificationsPlugin();
      final pending = await notifications.pendingNotificationRequests();
      final periodicIds = pending
          .where((n) => n.id >= 6000)
          .map((n) => n.id)
          .toList();
      for (final id in periodicIds) {
        await notifications.cancel(id);
      }
      debugPrint("🗑️  تم إلغاء ${periodicIds.length} إشعار قديم");

      // 2️⃣ جدولة أول دفعة من الإشعارات (100 إشعار)
      await _scheduleInitialNotifications(prefs, azkarList, intervalMinutes);

      // 3️⃣ تشغيل Worker للمراقبة والتجديد التلقائي
      await Workmanager().registerPeriodicTask(
        periodicAzkarCheckTask,
        periodicAzkarCheckTask,
        frequency: Duration(minutes: 15), // كل 15 دقيقة يفحص ويجدد
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      await prefs.setInt('current_periodic_index', 0);

      debugPrint("✅ تم تشغيل النظام الهجين بنجاح!");
      debugPrint("📱 أول إشعار بعد $intervalMinutes دقيقة");
      debugPrint("🔄 Worker يفحص كل 15 دقيقة");
      debugPrint("═══════════════════════════════════════");
    } catch (e) {
      debugPrint("❌ خطأ في startPeriodicWorker: $e");
      rethrow;
    }
  }

  /// جدولة الدفعة الأولى من الإشعارات
  static Future<void> _scheduleInitialNotifications(
    SharedPreferences prefs,
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

    // جدولة 100 إشعار (تكفي لأيام)
    for (int i = 0; i < 100; i++) {
      final azkarIndex = i % azkarList.length;
      final zekr = azkarList[azkarIndex];

      int zekrNumber = azkarIndex + 1;
      final match = RegExp(r'zekr_(\d+)').firstMatch(zekr['sound']!);
      if (match != null) {
        zekrNumber = int.parse(match.group(1)!);
      }

      final notificationId = 6000 + i;
      final scheduledTime = now.add(
        Duration(minutes: intervalMinutes * (i + 1)),
      );

      try {
        await notifications.zonedSchedule(
          notificationId,
          'أذكار دورية',
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
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        scheduled++;

        if (i < 5) {
          debugPrint(
            "   ✅ إشعار ${i + 1}: ${scheduledTime.day}/${scheduledTime.month} ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}",
          );
        }
      } catch (e) {
        debugPrint("   ⚠️ خطأ في جدولة إشعار $i: $e");
      }
    }

    debugPrint("✅ تم جدولة $scheduled إشعار بنجاح");
  }

  /// إيقاف الأذكار الدورية
  static Future<void> stopPeriodicWorker() async {
    try {
      // إيقاف Worker
      await Workmanager().cancelAll();

      // إلغاء جميع الإشعارات الدورية
      final notifications = FlutterLocalNotificationsPlugin();
      final pending = await notifications.pendingNotificationRequests();
      final periodicIds = pending
          .where((n) => n.id >= 6000)
          .map((n) => n.id)
          .toList();

      for (final id in periodicIds) {
        await notifications.cancel(id);
      }

      // تنظيف SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_periodic_index');

      debugPrint(
        "🛑 تم إيقاف الأذكار الدورية - ألغيت ${periodicIds.length} إشعار",
      );
    } catch (e) {
      debugPrint("❌ خطأ في stopPeriodicWorker: $e");
    }
  }
}
