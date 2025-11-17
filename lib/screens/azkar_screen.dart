import 'package:flutter/material.dart';
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

        await NotificationService.scheduleDailyNotification(
          id: 100,
          title: 'أذكار الصباح',
          body: 'حان وقت أذكار الصباح 🌅',
          hour: picked.hour,
          minute: picked.minute,
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
          body: 'حان وقت أذكار المساء 🌙',
          hour: picked.hour,
          minute: picked.minute,
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
          body: 'لا تنسى أذكار النوم قبل أن تنام 🌟',
          hour: picked.hour,
          minute: picked.minute,
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
    String emoji;

    switch (type) {
      case 'morning':
        initialTime = morningTime;
        notificationId = 100;
        title = 'أذكار الصباح';
        body = 'حان وقت أذكار الصباح';
        emoji = '🌅';
        break;
      case 'evening':
        initialTime = eveningTime;
        notificationId = 101;
        title = 'أذكار المساء';
        body = 'حان وقت أذكار المساء';
        emoji = '🌙';
        break;
      case 'sleep':
        initialTime = sleepTime;
        notificationId = 102;
        title = 'أذكار النوم';
        body = 'لا تنسى أذكار النوم قبل أن تنام';
        emoji = '🌟';
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
        body: '$body $emoji',
        hour: picked.hour,
        minute: picked.minute,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الأذكار',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAzkarCategory(
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
          ),
          const SizedBox(height: 16),
          _buildAzkarCategory(
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
          ),
          const SizedBox(height: 16),
          _buildAzkarCategory(
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
          ),
          const SizedBox(height: 16),
          _buildAzkarCategory(
            title: 'أذكار بعد الصلاة',
            subtitle: 'أذكار وأدعية دبر الصلوات',
            icon: Icons.mosque,
            color: Colors.teal,
            gradient: const LinearGradient(
              colors: [Color(0xFF26A69A), Color(0xFF00695C)],
            ),
            azkarList: AzkarData.afterPrayerAzkar,
          ),
          const SizedBox(height: 16),
          _buildAzkarCategory(
            title: 'أذكار السفر',
            subtitle: 'دعاء السفر والرجوع',
            icon: Icons.flight_takeoff,
            color: Colors.blue,
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
            ),
            azkarList: AzkarData.travelAzkar,
          ),
          const SizedBox(height: 16),
          _buildAzkarCategory(
            title: 'أذكار الطعام',
            subtitle: 'أذكار قبل وبعد الطعام',
            icon: Icons.restaurant,
            color: Colors.brown,
            gradient: const LinearGradient(
              colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
            ),
            azkarList: AzkarData.eatingAzkar,
          ),
        ],
      ),
    );
  }

  Widget _buildAzkarCategory({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    required List<Azkar> azkarList,
    bool? notificationEnabled,
    Function(bool)? onNotificationToggle,
    TimeOfDay? currentTime,
    VoidCallback? onChangeTime,
  }) {
    return Hero(
      tag: title,
      child: Card(
        elevation: 8,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.white, color.withOpacity(0.05)],
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.only(bottom: 16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
              ),
              trailing: onNotificationToggle != null
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notificationEnabled!
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            notificationEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: notificationEnabled
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.expand_more, size: 20),
                        ],
                      ),
                    )
                  : null,
              children: [
                if (onNotificationToggle != null) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            'تفعيل التنبيه اليومي',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          subtitle: Text(
                            notificationEnabled!
                                ? 'سيصلك التنبيه يومياً الساعة ${currentTime!.format(context)}'
                                : 'قم بتفعيل التنبيه لاختيار الوقت',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          value: notificationEnabled,
                          onChanged: onNotificationToggle,
                          activeThumbColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        if (notificationEnabled && onChangeTime != null)
                          InkWell(
                            onTap: onChangeTime,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'تغيير وقت التنبيه',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                        Text(
                                          'الوقت الحالي: ${currentTime!.format(context)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.edit, color: color, size: 20),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_list_numbered,
                              color: color,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${azkarList.length} ذكر',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...azkarList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final azkar = entry.value;
                  return _buildAzkarItem(azkar, color, gradient, index);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAzkarItem(
    Azkar azkar,
    Color color,
    Gradient gradient,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showAzkarDetails(azkar, color, gradient),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      azkar.zekr,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (azkar.reference != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        azkar.reference!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  if (azkar.countInt > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${azkar.countInt}×',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              ),
            ],
          ),
        ),
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
}

class AzkarDetailsSheet extends StatefulWidget {
  final Azkar azkar;
  final Color color;
  final Gradient gradient;

  const AzkarDetailsSheet({
    super.key,
    required this.azkar,
    required this.color,
    required this.gradient,
  });

  @override
  State<AzkarDetailsSheet> createState() => _AzkarDetailsSheetState();
}

class _AzkarDetailsSheetState extends State<AzkarDetailsSheet>
    with SingleTickerProviderStateMixin {
  int currentCount = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _incrementCount() {
    if (currentCount < widget.azkar.countInt) {
      _controller.forward().then((_) => _controller.reverse());
      setState(() {
        currentCount++;
      });

      if (currentCount == widget.azkar.countInt) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showCompletionDialog();
          }
        });
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: widget.gradient,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'بارك الله فيك!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'أكملت الذكر بنجاح ✨',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    currentCount = 0;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'إعادة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.azkar.countInt > 1
        ? currentCount / widget.azkar.countInt
        : 1.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          // Header with Title and Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تفاصيل الذكر',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  color: widget.color,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Main Azkar Content (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Azkar Text
                  Text(
                    widget.azkar.zekr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 2.0,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF303030),
                      fontFamily:
                          'Cairo', // نفترض استخدام خط القاهرة كما في ThemeData
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reference and Description Container
                  if (widget.azkar.reference != null ||
                      widget.azkar.description != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.color.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.azkar.reference != null)
                            Text(
                              'المصدر: ${widget.azkar.reference!}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: widget.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          if (widget.azkar.reference != null &&
                              widget.azkar.description != null)
                            const Divider(height: 16, color: Colors.grey),
                          if (widget.azkar.description != null)
                            Text(
                              widget.azkar.description!,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 100), // مساحة إضافية
                ],
              ),
            ),
          ),

          // Progress Indicator
          if (widget.azkar.countInt > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: widget.color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
            ),

          // Tap Counter Button
          GestureDetector(
            onTap: currentCount < widget.azkar.countInt
                ? _incrementCount
                : () {
                    Navigator.pop(context);
                    // لإعادة فتح نافذة الإكمال بعد الإغلاق
                    _showCompletionDialog();
                  },
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  // تغيير التدرج اللوني عند الإكمال
                  gradient: currentCount < widget.azkar.countInt
                      ? widget.gradient
                      : const LinearGradient(
                          colors: [Colors.green, Color(0xFF1B5E20)],
                        ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (currentCount < widget.azkar.countInt
                                  ? widget.color
                                  : Colors.green)
                              .withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentCount < widget.azkar.countInt
                          ? 'انقر للتسبيح'
                          : 'تم الإكمال! انقر للإنهاء',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentCount / ${widget.azkar.countInt}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom padding to respect phone's safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
