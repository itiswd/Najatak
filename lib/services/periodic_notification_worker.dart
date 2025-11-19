import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// ══════════════════════════════════════════════════════════════
/// Worker للأذكار الدورية - يعمل في الخلفية بشكل دائم
/// ══════════════════════════════════════════════════════════════

const String periodicAzkarTaskName = "periodicAzkarTask";

/// نقطة الدخول للـ Background Tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("🔄 بدء تنفيذ مهمة الأذكار الدورية...");

      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('periodic_azkar_enabled') ?? false;

      if (!isEnabled) {
        debugPrint("⚠️ الأذكار الدورية معطلة - إيقاف المهمة");
        return Future.value(true);
      }

      // قراءة البيانات المحفوظة
      final intervalMinutes = prefs.getInt('periodic_azkar_interval') ?? 30;
      final savedAzkar = prefs.getString('periodic_selected_azkar');

      if (savedAzkar == null || savedAzkar.isEmpty) {
        debugPrint("⚠️ لا توجد أذكار محددة");
        return Future.value(true);
      }

      final List<String> selectedAzkarIds = List<String>.from(
        json.decode(savedAzkar),
      );

      // قراءة آخر مرة تم إرسال إشعار فيها
      final lastNotificationTime =
          prefs.getInt('last_periodic_notification') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // التحقق من مرور الوقت الكافي
      final minutesPassed = (now - lastNotificationTime) / 60000;

      if (minutesPassed < intervalMinutes) {
        debugPrint(
          "⏰ لم يحن الوقت بعد. مر ${minutesPassed.toStringAsFixed(1)} دقيقة من $intervalMinutes",
        );
        return Future.value(true);
      }

      // إرسال الإشعار التالي
      await _sendNextNotification(prefs, selectedAzkarIds, intervalMinutes);

      debugPrint("✅ تم إرسال الإشعار الدوري بنجاح");
      return Future.value(true);
    } catch (e) {
      debugPrint("❌ خطأ في Worker: $e");
      return Future.value(false);
    }
  });
}

/// إرسال الإشعار التالي في الدورة
Future<void> _sendNextNotification(
  SharedPreferences prefs,
  List<String> azkarIds,
  int intervalMinutes,
) async {
  // تهيئة Notifications
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    ),
  );

  // الحصول على الذكر الحالي
  final currentIndex = prefs.getInt('current_azkar_index') ?? 0;
  final azkarId = azkarIds[currentIndex % azkarIds.length];

  // بيانات الأذكار (نفس القائمة من التطبيق)
  final azkarData = _getAzkarData();
  final zekr = azkarData.firstWhere(
    (z) => z['id'] == azkarId,
    orElse: () => azkarData[0],
  );

  // استخراج رقم الذكر من sound
  int zekrNumber = 1;
  final match = RegExp(r'zekr_(\d+)').firstMatch(zekr['sound']!);
  if (match != null) {
    zekrNumber = int.parse(match.group(1)!);
  }

  final channelId = 'periodic_zekr_${zekrNumber}_channel';

  // إرسال الإشعار
  await notifications.show(
    5000 + Random().nextInt(1000), // ID عشوائي لتجنب التضارب
    'ذكر ${currentIndex + 1} من ${azkarIds.length}',
    zekr['text']!,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'ذكر دوري $zekrNumber',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(zekr['sound']!),
        enableVibration: false,
        icon: '@mipmap/launcher_icon',
      ),
    ),
  );

  // تحديث الفهرس والوقت
  await prefs.setInt('current_azkar_index', currentIndex + 1);
  await prefs.setInt(
    'last_periodic_notification',
    DateTime.now().millisecondsSinceEpoch,
  );

  debugPrint("📢 تم إرسال الذكر ${currentIndex + 1}: ${zekr['text']}");
}

/// قائمة الأذكار (مطابقة للتطبيق)
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
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
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
/// دالة تهيئة WorkManager في التطبيق الرئيسي
/// ══════════════════════════════════════════════════════════════

class PeriodicAzkarWorker {
  /// تهيئة WorkManager عند بدء التطبيق
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // غيرها لـ true للتجربة
    );
    debugPrint("✅ تم تهيئة WorkManager للأذكار الدورية");
  }

  /// تشغيل Worker للأذكار الدورية
  static Future<void> startPeriodicWorker(int intervalMinutes) async {
    // إلغاء أي مهام سابقة
    await Workmanager().cancelByUniqueName(periodicAzkarTaskName);

    // تشغيل مهمة دورية كل X دقيقة
    await Workmanager().registerPeriodicTask(
      periodicAzkarTaskName,
      periodicAzkarTaskName,
      frequency: Duration(
        minutes: max(15, intervalMinutes),
      ), // أقل قيمة 15 دقيقة
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {'interval': intervalMinutes},
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // حفظ وقت البدء
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_azkar_index', 0);
    await prefs.setInt(
      'last_periodic_notification',
      DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint("✅ تم تشغيل Worker - سيعمل كل $intervalMinutes دقيقة");
  }

  /// إيقاف Worker للأذكار الدورية
  static Future<void> stopPeriodicWorker() async {
    await Workmanager().cancelByUniqueName(periodicAzkarTaskName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_azkar_index');
    await prefs.remove('last_periodic_notification');

    debugPrint("🛑 تم إيقاف Worker للأذكار الدورية");
  }
}
