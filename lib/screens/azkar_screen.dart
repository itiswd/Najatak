import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/azkar_model.dart';
import '../services/notification_service.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  bool morningNotificationEnabled = false;
  bool eveningNotificationEnabled = false;
  bool sleepNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      morningNotificationEnabled =
          prefs.getBool('morning_notification') ?? false;
      eveningNotificationEnabled =
          prefs.getBool('evening_notification') ?? false;
      sleepNotificationEnabled = prefs.getBool('sleep_notification') ?? false;
    });
  }

  Future<void> _toggleMorningNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('morning_notification', value);

    if (value) {
      // جدولة إشعار أذكار الصباح (الساعة 7 صباحاً)
      await NotificationService.scheduleDailyNotification(
        id: 100,
        title: 'أذكار الصباح',
        body: 'حان وقت أذكار الصباح 🌅',
        hour: 7,
        minute: 0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل تنبيه أذكار الصباح الساعة 7:00 ص'),
          ),
        );
      }
    } else {
      await NotificationService.cancelNotification(100);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء تنبيه أذكار الصباح')),
        );
      }
    }

    setState(() {
      morningNotificationEnabled = value;
    });
  }

  Future<void> _toggleEveningNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('evening_notification', value);

    if (value) {
      // جدولة إشعار أذكار المساء (الساعة 5 مساءً)
      await NotificationService.scheduleDailyNotification(
        id: 101,
        title: 'أذكار المساء',
        body: 'حان وقت أذكار المساء 🌙',
        hour: 17,
        minute: 0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل تنبيه أذكار المساء الساعة 5:00 م'),
          ),
        );
      }
    } else {
      await NotificationService.cancelNotification(101);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء تنبيه أذكار المساء')),
        );
      }
    }

    setState(() {
      eveningNotificationEnabled = value;
    });
  }

  Future<void> _toggleSleepNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sleep_notification', value);

    if (value) {
      // جدولة إشعار أذكار النوم (الساعة 10 مساءً)
      await NotificationService.scheduleDailyNotification(
        id: 102,
        title: 'أذكار النوم',
        body: 'لا تنسى أذكار النوم قبل أن تنام 🌟',
        hour: 22,
        minute: 0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل تنبيه أذكار النوم الساعة 10:00 م'),
          ),
        );
      }
    } else {
      await NotificationService.cancelNotification(102);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء تنبيه أذكار النوم')),
        );
      }
    }

    setState(() {
      sleepNotificationEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAzkarCategory(
            title: 'أذكار الصباح',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            azkarList: AzkarData.morningAzkar,
            notificationEnabled: morningNotificationEnabled,
            onNotificationToggle: _toggleMorningNotification,
          ),
          const SizedBox(height: 16),
          _buildAzkarCategory(
            title: 'أذكار المساء',
            icon: Icons.nights_stay,
            color: Colors.indigo,
            azkarList: AzkarData.eveningAzkar,
            notificationEnabled: eveningNotificationEnabled,
            onNotificationToggle: _toggleEveningNotification,
          ),
          const SizedBox(height: 16),
          _buildAzkarCategory(
            title: 'أذكار النوم',
            icon: Icons.bedtime,
            color: Colors.purple,
            azkarList: AzkarData.sleepAzkar,
            notificationEnabled: sleepNotificationEnabled,
            onNotificationToggle: _toggleSleepNotification,
          ),
          const SizedBox(height: 16),
          _buildAzkarCategory(
            title: 'أذكار بعد الصلاة',
            icon: Icons.mosque,
            color: Colors.teal,
            azkarList: AzkarData.afterPrayerAzkar,
          ),
        ],
      ),
    );
  }

  Widget _buildAzkarCategory({
    required String title,
    required IconData icon,
    required Color color,
    required List<Azkar> azkarList,
    bool? notificationEnabled,
    Function(bool)? onNotificationToggle,
  }) {
    return Card(
      elevation: 4,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          trailing: onNotificationToggle != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      notificationEnabled!
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: notificationEnabled ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more),
                  ],
                )
              : null,
          children: [
            if (onNotificationToggle != null)
              SwitchListTile(
                title: const Text('تفعيل التنبيه اليومي'),
                subtitle: Text(_getNotificationTime(title)),
                value: notificationEnabled!,
                onChanged: onNotificationToggle,
                activeThumbColor: color,
              ),
            const Divider(),
            ...azkarList.map((azkar) => _buildAzkarItem(azkar, color)),
          ],
        ),
      ),
    );
  }

  String _getNotificationTime(String category) {
    switch (category) {
      case 'أذكار الصباح':
        return 'سيصلك التنبيه يومياً الساعة 7:00 صباحاً';
      case 'أذكار المساء':
        return 'سيصلك التنبيه يومياً الساعة 5:00 مساءً';
      case 'أذكار النوم':
        return 'سيصلك التنبيه يومياً الساعة 10:00 مساءً';
      default:
        return '';
    }
  }

  Widget _buildAzkarItem(Azkar azkar, Color color) {
    return InkWell(
      onTap: () => _showAzkarDetails(azkar, color),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    azkar.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    azkar.content,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (azkar.repeatCount > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${azkar.repeatCount}×',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAzkarDetails(Azkar azkar, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AzkarDetailsSheet(azkar: azkar, color: color),
    );
  }
}

class AzkarDetailsSheet extends StatefulWidget {
  final Azkar azkar;
  final Color color;

  const AzkarDetailsSheet({
    super.key,
    required this.azkar,
    required this.color,
  });

  @override
  State<AzkarDetailsSheet> createState() => _AzkarDetailsSheetState();
}

class _AzkarDetailsSheetState extends State<AzkarDetailsSheet> {
  int currentCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.azkar.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                widget.azkar.content,
                style: const TextStyle(fontSize: 20, height: 2),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (widget.azkar.repeatCount > 1) ...[
            Text(
              '$currentCount / ${widget.azkar.repeatCount}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: currentCount < widget.azkar.repeatCount
                  ? () {
                      setState(() {
                        currentCount++;
                      });
                      if (currentCount == widget.azkar.repeatCount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('بارك الله فيك! أكملت الذكر ✨'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                currentCount < widget.azkar.repeatCount ? 'سبّح' : 'اكتمل ✓',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            if (currentCount > 0)
              TextButton(
                onPressed: () {
                  setState(() {
                    currentCount = 0;
                  });
                },
                child: const Text('إعادة العداد'),
              ),
          ],
        ],
      ),
    );
  }
}
