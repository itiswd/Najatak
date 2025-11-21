import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/periodic_notification_worker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = true;

  // حالة كل نوع من الأذكار
  Map<String, AzkarNotificationStatus> azkarStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // تحميل حالة أذكار الصباح
      final morningEnabled = prefs.getBool('morning_notification') ?? false;
      final morningHour = prefs.getInt('morning_hour') ?? 6;
      final morningMinute = prefs.getInt('morning_minute') ?? 0;

      // تحميل حالة أذكار المساء
      final eveningEnabled = prefs.getBool('evening_notification') ?? false;
      final eveningHour = prefs.getInt('evening_hour') ?? 16;
      final eveningMinute = prefs.getInt('evening_minute') ?? 30;

      // تحميل حالة أذكار النوم
      final sleepEnabled = prefs.getBool('sleep_notification') ?? false;
      final sleepHour = prefs.getInt('sleep_hour') ?? 22;
      final sleepMinute = prefs.getInt('sleep_minute') ?? 0;

      // تحميل حالة الأذكار الدورية
      final periodicEnabled = prefs.getBool('periodic_enabled') ?? false;
      final periodicInterval = prefs.getInt('periodic_interval') ?? 30;

      setState(() {
        azkarStatus = {
          'morning': AzkarNotificationStatus(
            title: 'أذكار الصباح',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            isEnabled: morningEnabled,
            time: TimeOfDay(hour: morningHour, minute: morningMinute),
            notificationId: 100,
          ),
          'evening': AzkarNotificationStatus(
            title: 'أذكار المساء',
            icon: Icons.nights_stay,
            color: Colors.indigo,
            isEnabled: eveningEnabled,
            time: TimeOfDay(hour: eveningHour, minute: eveningMinute),
            notificationId: 101,
          ),
          'sleep': AzkarNotificationStatus(
            title: 'أذكار النوم',
            icon: Icons.bedtime,
            color: Colors.purple,
            isEnabled: sleepEnabled,
            time: TimeOfDay(hour: sleepHour, minute: sleepMinute),
            notificationId: 102,
          ),
          'periodic': AzkarNotificationStatus(
            title: 'الأذكار الدورية',
            icon: Icons.repeat,
            color: const Color(0xFF1B5E20),
            isEnabled: periodicEnabled,
            interval: periodicInterval,
            notificationId: 500,
          ),
        };
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الإعدادات: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _cancelAzkar(String type) async {
    final status = azkarStatus[type]!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(status.icon, color: status.color),
            const SizedBox(width: 12),
            const Text('تأكيد الإلغاء'),
          ],
        ),
        content: Text('هل تريد إلغاء "${status.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (type == 'periodic') {
        // إيقاف الأذكار الدورية
        await PeriodicAzkarWorker.stopPeriodicWorker();
        await prefs.setBool('periodic_enabled', false);
      } else {
        // إلغاء الإشعار اليومي
        await NotificationService.cancelNotification(status.notificationId);
        await prefs.setBool('${type}_notification', false);
      }

      await _loadSettings();

      if (mounted) {
        _showSnackBar('تم إلغاء "${status.title}" بنجاح', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('حدث خطأ أثناء الإلغاء', Colors.red);
      }
    }
  }

  Future<void> _cancelAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('تأكيد'),
          ],
        ),
        content: const Text(
          'هل تريد إلغاء جميع الإشعارات؟\n\nسيتم إلغاء جميع الأذكار المجدولة',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، إلغاء الكل'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await NotificationService.cancelAllNotifications();
      await PeriodicAzkarWorker.stopPeriodicWorker();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('morning_notification', false);
      await prefs.setBool('evening_notification', false);
      await prefs.setBool('sleep_notification', false);
      await prefs.setBool('periodic_enabled', false);

      await _loadSettings();

      if (mounted) {
        _showSnackBar('تم إلغاء جميع الإشعارات', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('حدث خطأ أثناء الإلغاء', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = azkarStatus.values.where((s) => s.isEnabled).length;

    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(activeCount),
                  const SizedBox(height: 24),
                  _buildSectionTitle('الإشعارات المجدولة'),
                  const SizedBox(height: 12),
                  ...azkarStatus.entries.map((entry) {
                    return _buildAzkarStatusCard(entry.key, entry.value);
                  }),
                  const SizedBox(height: 24),
                  if (activeCount > 0) ...[
                    _buildDangerZone(),
                    const SizedBox(height: 24),
                  ],
                  _buildHelpSection(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'إدارة الإشعارات',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      toolbarHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () async {
            await _loadSettings();
            if (mounted) _showSnackBar('تم تحديث الإعدادات', Colors.blue);
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int activeCount) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: activeCount > 0
                ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                : [Colors.grey[700]!, Colors.grey[600]!],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                activeCount > 0
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeCount > 0 ? 'الإشعارات نشطة' : 'لا توجد إشعارات',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    activeCount > 0
                        ? 'لديك $activeCount نوع مُفعّل'
                        : 'قم بتفعيل الأذكار من الصفحات المخصصة',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
        ),
      ),
    );
  }

  Widget _buildAzkarStatusCard(String type, AzkarNotificationStatus status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: status.isEnabled
            ? status.color.withAlpha(13)
            : Colors.grey.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.isEnabled
              ? status.color.withAlpha(51)
              : Colors.grey.withAlpha(51),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status.isEnabled
                    ? status.color.withAlpha(25)
                    : Colors.grey.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                status.icon,
                color: status.isEnabled ? status.color : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: status.isEnabled ? status.color : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(type, status),
                    style: TextStyle(
                      fontSize: 13,
                      color: status.isEnabled
                          ? Colors.grey[700]
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (status.isEnabled)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: () => _cancelAzkar(type),
                  tooltip: 'إلغاء',
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'معطل',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(String type, AzkarNotificationStatus status) {
    if (!status.isEnabled) {
      return 'غير مُفعّل';
    }

    if (type == 'periodic') {
      final interval = status.interval ?? 30;
      return 'كل $interval دقيقة';
    }

    final time = status.time!;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return 'يومياً الساعة $hour:$minute';
  }

  Widget _buildDangerZone() {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 12),
                const Text(
                  'منطقة الخطر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cancelAllNotifications,
              icon: const Icon(Icons.delete_forever),
              label: const Text('إلغاء جميع الإشعارات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'نصائح مهمة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.settings_outlined,
              text: 'يمكنك تفعيل/تعطيل كل نوع من الأذكار من صفحته الخاصة',
              color: Colors.blue,
            ),
            _buildInfoItem(
              icon: Icons.access_time,
              text: 'لتغيير أوقات الأذكار، انتقل إلى صفحة الأذكار المطلوبة',
              color: Colors.orange,
            ),
            _buildInfoItem(
              icon: Icons.battery_alert,
              text: 'تأكد من عدم تفعيل وضع توفير البطارية للتطبيق',
              color: Colors.red,
            ),
            _buildInfoItem(
              icon: Icons.refresh,
              text: 'اضغط على زر التحديث أعلى الصفحة لرؤية آخر التغييرات',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.5, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// نموذج البيانات
// ═══════════════════════════════════════════════════════════════

class AzkarNotificationStatus {
  final String title;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final TimeOfDay? time;
  final int? interval;
  final int notificationId;

  AzkarNotificationStatus({
    required this.title,
    required this.icon,
    required this.color,
    required this.isEnabled,
    this.time,
    this.interval,
    required this.notificationId,
  });
}
