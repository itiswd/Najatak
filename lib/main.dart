import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/azkar_screen.dart';
import 'screens/home_screen.dart';
import 'services/continuous_audio_handler.dart';
import 'services/notification_service.dart';
import 'services/periodic_notification_worker.dart';

// ✅ Global key للتنقل
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ متغير لحفظ payload الإشعار
String? initialNotificationPayload;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ التحقق من الإشعار الذي فتح التطبيق
  await _checkInitialNotification();

  // ✅ تهيئة خدمات الإشعارات
  await NotificationService.initialize();
  await PeriodicAzkarWorker.initialize();

  // ✅ الاستماع للإشعارات أثناء تشغيل التطبيق
  _listenToNotifications();

  // ✅ تهيئة معالج الصوت المستمر
  final audioHandler = ContinuousAudioHandler();
  await audioHandler.initialize();

  runApp(const Najatak());
}

// ✅ التحقق من الإشعار عند فتح التطبيق
Future<void> _checkInitialNotification() async {
  final NotificationAppLaunchDetails? details =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (details != null && details.didNotificationLaunchApp) {
    initialNotificationPayload = details.notificationResponse?.payload;
    debugPrint('🔔 التطبيق فُتح من إشعار: $initialNotificationPayload');
  }
}

// ✅ الاستماع للإشعارات أثناء عمل التطبيق
void _listenToNotifications() {
  // معالجة النقر على الإشعار عندما يكون التطبيق يعمل
  flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      _handleNotificationTap(response.payload);
    },
  );
}

// ✅ معالجة النقر على الإشعار
void _handleNotificationTap(String? payload) {
  if (payload == null) return;

  debugPrint('🔔 معالجة payload: $payload');

  // الانتظار قليلاً حتى يكون الـ Navigator جاهز
  Future.delayed(const Duration(milliseconds: 300), () {
    if (navigatorKey.currentContext != null) {
      // التنقل لصفحة الأذكار المناسبة
      Navigator.of(navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (context) => AzkarScreen(
            initialCategory: payload, // ✅ تمرير نوع الذكر
            openDirectly: true, // ✅ فتح الذكر مباشرة
          ),
        ),
      );
    }
  });
}

class Najatak extends StatefulWidget {
  const Najatak({super.key});

  @override
  State<Najatak> createState() => _NajatakState();
}

class _NajatakState extends State<Najatak> {
  @override
  void initState() {
    super.initState();
    // ✅ التحقق من payload الإشعار بعد بناء الـ widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialNotificationPayload != null) {
        _handleNotificationTap(initialNotificationPayload);
        initialNotificationPayload = null; // مسح بعد المعالجة
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ إضافة الـ key
      title: 'نَجَاتَك',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', ''), Locale('en', '')],
      locale: const Locale('ar', ''),
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
