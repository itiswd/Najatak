import 'package:flutter/material.dart';
import 'package:najatak/widgets/azkar_category_widget.dart';
import 'package:najatak/widgets/azkar_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/azkar_model.dart';
import '../services/notification_service.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  bool morningNotificationEnabled = false;
  bool eveningNotificationEnabled = false;
  bool sleepNotificationEnabled = false;

  TimeOfDay morningTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay eveningTime = const TimeOfDay(hour: 16, minute: 30);
  TimeOfDay sleepTime = const TimeOfDay(hour: 22, minute: 0);

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      morningNotificationEnabled =
          prefs.getBool('morning_notification') ?? false;
      eveningNotificationEnabled =
          prefs.getBool('evening_notification') ?? false;
      sleepNotificationEnabled = prefs.getBool('sleep_notification') ?? false;

      morningTime = TimeOfDay(
        hour: prefs.getInt('morning_hour') ?? 6,
        minute: prefs.getInt('morning_minute') ?? 0,
      );
      eveningTime = TimeOfDay(
        hour: prefs.getInt('evening_hour') ?? 16,
        minute: prefs.getInt('evening_minute') ?? 30,
      );
      sleepTime = TimeOfDay(
        hour: prefs.getInt('sleep_hour') ?? 22,
        minute: prefs.getInt('sleep_minute') ?? 0,
      );
    });
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  Future<void> _toggleMorningNotification(bool value) async {
    if (value) {
      await _selectTime(context, morningTime, (picked) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('morning_notification', true);
        await prefs.setInt('morning_hour', picked.hour);
        await prefs.setInt('morning_minute', picked.minute);

        // استخدام NotificationType.morning
        await NotificationService.scheduleDailyNotification(
          id: 100,
          title: 'أذكار الصباح',
          body: 'حان وقت أذكار الصباح',
          hour: picked.hour,
          minute: picked.minute,
          type: NotificationType.morning,
        );

        setState(() {
          morningTime = picked;
          morningNotificationEnabled = true;
        });

        if (mounted) {
          _showSuccessSnackBar(
            'تم تفعيل تنبيه أذكار الصباح الساعة ${picked.format(context)}',
          );
        }
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('morning_notification', false);
      await NotificationService.cancelNotification(100);

      setState(() {
        morningNotificationEnabled = false;
      });

      if (mounted) {
        _showInfoSnackBar('تم إلغاء تنبيه أذكار الصباح');
      }
    }
  }

  Future<void> _toggleEveningNotification(bool value) async {
    if (value) {
      await _selectTime(context, eveningTime, (picked) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('evening_notification', true);
        await prefs.setInt('evening_hour', picked.hour);
        await prefs.setInt('evening_minute', picked.minute);

        await NotificationService.scheduleDailyNotification(
          id: 101,
          title: 'أذكار المساء',
          body: 'حان وقت أذكار المساء',
          hour: picked.hour,
          minute: picked.minute,
          type: NotificationType.evening,
        );

        setState(() {
          eveningTime = picked;
          eveningNotificationEnabled = true;
        });

        if (mounted) {
          _showSuccessSnackBar(
            'تم تفعيل تنبيه أذكار المساء الساعة ${picked.format(context)}',
          );
        }
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('evening_notification', false);
      await NotificationService.cancelNotification(101);

      setState(() {
        eveningNotificationEnabled = false;
      });

      if (mounted) {
        _showInfoSnackBar('تم إلغاء تنبيه أذكار المساء');
      }
    }
  }

  Future<void> _toggleSleepNotification(bool value) async {
    if (value) {
      await _selectTime(context, sleepTime, (picked) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sleep_notification', true);
        await prefs.setInt('sleep_hour', picked.hour);
        await prefs.setInt('sleep_minute', picked.minute);

        await NotificationService.scheduleDailyNotification(
          id: 102,
          title: 'أذكار النوم',
          body: 'لا تنسى أذكار النوم قبل أن تنام',
          hour: picked.hour,
          minute: picked.minute,
          type: NotificationType.sleep,
        );

        setState(() {
          sleepTime = picked;
          sleepNotificationEnabled = true;
        });

        if (mounted) {
          _showSuccessSnackBar(
            'تم تفعيل تنبيه أذكار النوم الساعة ${picked.format(context)}',
          );
        }
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sleep_notification', false);
      await NotificationService.cancelNotification(102);

      setState(() {
        sleepNotificationEnabled = false;
      });

      if (mounted) {
        _showInfoSnackBar('تم إلغاء تنبيه أذكار النوم');
      }
    }
  }

  Future<void> _changeTime(String type) async {
    TimeOfDay initialTime;
    int notificationId;
    String title;
    String body;
    NotificationType notifType;

    switch (type) {
      case 'morning':
        initialTime = morningTime;
        notificationId = 100;
        title = 'أذكار الصباح';
        body = 'حان وقت أذكار الصباح';
        notifType = NotificationType.morning;
        break;
      case 'evening':
        initialTime = eveningTime;
        notificationId = 101;
        title = 'أذكار المساء';
        body = 'حان وقت أذكار المساء';
        notifType = NotificationType.evening;
        break;
      case 'sleep':
        initialTime = sleepTime;
        notificationId = 102;
        title = 'أذكار النوم';
        body = 'لا تنسى أذكار النوم قبل أن تنام';
        notifType = NotificationType.sleep;
        break;
      default:
        return;
    }

    await _selectTime(context, initialTime, (picked) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${type}_hour', picked.hour);
      await prefs.setInt('${type}_minute', picked.minute);

      await NotificationService.cancelNotification(notificationId);
      await NotificationService.scheduleDailyNotification(
        id: notificationId,
        title: title,
        body: body,
        hour: picked.hour,
        minute: picked.minute,
        type: notifType,
      );

      setState(() {
        switch (type) {
          case 'morning':
            morningTime = picked;
            break;
          case 'evening':
            eveningTime = picked;
            break;
          case 'sleep':
            sleepTime = picked;
            break;
        }
      });

      if (mounted) {
        _showSuccessSnackBar('تم تغيير الوقت إلى ${picked.format(context)}');
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAzkarDetails(Azkar azkar, Color color, Gradient gradient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AzkarDetailsSheet(azkar: azkar, color: color, gradient: gradient),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'الأذكار',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      leading: InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.arrow_back_ios),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withAlpha(204),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AzkarCategoryWidget(
            title: 'أذكار الصباح',
            subtitle: 'ابدأ يومك بالذكر والدعاء',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFFF6F00)],
            ),
            azkarList: AzkarData.morningAzkar,
            notificationEnabled: morningNotificationEnabled,
            onNotificationToggle: _toggleMorningNotification,
            currentTime: morningTime,
            onChangeTime: () => _changeTime('morning'),
            onAzkarItemTap: _showAzkarDetails,
          ),
          const SizedBox(height: 16),
          AzkarCategoryWidget(
            title: 'أذكار المساء',
            subtitle: 'اختم نهارك بذكر الله',
            icon: Icons.nights_stay,
            color: Colors.indigo,
            gradient: const LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFF283593)],
            ),
            azkarList: AzkarData.eveningAzkar,
            notificationEnabled: eveningNotificationEnabled,
            onNotificationToggle: _toggleEveningNotification,
            currentTime: eveningTime,
            onChangeTime: () => _changeTime('evening'),
            onAzkarItemTap: _showAzkarDetails,
          ),
          const SizedBox(height: 16),
          AzkarCategoryWidget(
            title: 'أذكار النوم',
            subtitle: 'استعد لنوم هادئ مطمئن',
            icon: Icons.bedtime,
            color: Colors.purple,
            gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF4A148C)],
            ),
            azkarList: AzkarData.sleepAzkar,
            notificationEnabled: sleepNotificationEnabled,
            onNotificationToggle: _toggleSleepNotification,
            currentTime: sleepTime,
            onChangeTime: () => _changeTime('sleep'),
            onAzkarItemTap: _showAzkarDetails,
          ),
          const SizedBox(height: 16),
          AzkarCategoryWidget(
            title: 'أذكار بعد الصلاة',
            subtitle: 'أذكار وأدعية دبر الصلوات',
            icon: Icons.mosque,
            color: Colors.teal,
            gradient: const LinearGradient(
              colors: [Color(0xFF26A69A), Color(0xFF00695C)],
            ),
            azkarList: AzkarData.afterPrayerAzkar,
            onAzkarItemTap: _showAzkarDetails,
          ),
          const SizedBox(height: 16),
          AzkarCategoryWidget(
            title: 'أذكار السفر',
            subtitle: 'دعاء السفر والرجوع',
            icon: Icons.flight_takeoff,
            color: Colors.blue,
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
            ),
            azkarList: AzkarData.travelAzkar,
            onAzkarItemTap: _showAzkarDetails,
          ),
          const SizedBox(height: 16),
          AzkarCategoryWidget(
            title: 'أذكار الطعام',
            subtitle: 'أذكار قبل وبعد الطعام',
            icon: Icons.restaurant,
            color: Colors.brown,
            gradient: const LinearGradient(
              colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
            ),
            azkarList: AzkarData.eatingAzkar,
            onAzkarItemTap: _showAzkarDetails,
          ),
        ],
      ),
    );
  }
}
