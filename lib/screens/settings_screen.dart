import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<PendingNotificationRequest> pendingNotifications = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    setState(() => isLoading = true);
    final notifications = await NotificationService.getPendingNotifications();
    setState(() {
      pendingNotifications = notifications;
      isLoading = false;
    });
  }

  Future<void> _cancelNotification(int id) async {
    final notificationName = _getNotificationName(id);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الإلغاء'),
        content: Text('هل تريد إلغاء تنبيه "$notificationName"؟'),
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
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationService.cancelNotification(id);

      final prefs = await SharedPreferences.getInstance();
      if (id == 100) {
        await prefs.setBool('morning_notification', false);
      } else if (id == 101) {
        await prefs.setBool('evening_notification', false);
      } else if (id == 102) {
        await prefs.setBool('sleep_notification', false);
      }

      await _loadPendingNotifications();
      if (mounted) {
        _showSnackBar('تم إلغاء تنبيه "$notificationName"', Colors.green);
      }
    }
  }

  Future<void> _cancelAllNotifications() async {
    if (pendingNotifications.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد'),
        content: Text(
          'هل تريد إلغاء جميع الإشعارات؟\n\nسيتم إلغاء ${pendingNotifications.length} إشعار',
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

    if (confirm == true) {
      await NotificationService.cancelAllNotifications();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('morning_notification', false);
      await prefs.setBool('evening_notification', false);
      await prefs.setBool('sleep_notification', false);
      await prefs.setBool('periodic_azkar_enabled', false);

      await _loadPendingNotifications();
      if (mounted) {
        _showSnackBar('تم إلغاء جميع الإشعارات', Colors.green);
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
      ),
    );
  }

  String _getNotificationName(int id) {
    if (id == 100) return 'أذكار الصباح';
    if (id == 101) return 'أذكار المساء';
    if (id == 102) return 'أذكار النوم';
    if (id >= 500) return 'ذكر دوري';
    return 'إشعار';
  }

  IconData _getNotificationIcon(int id) {
    if (id == 100) return Icons.wb_sunny;
    if (id == 101) return Icons.nights_stay;
    if (id == 102) return Icons.bedtime;
    return Icons.repeat;
  }

  Color _getNotificationColor(int id) {
    if (id == 100) return Colors.orange;
    if (id == 101) return Colors.indigo;
    if (id == 102) return Colors.purple;
    return const Color(0xFF1B5E20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإشعارات'),
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
              await _loadPendingNotifications();
              if (mounted) _showSnackBar('تم تحديث القائمة', Colors.blue);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPendingNotifications,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatisticsCard(),
                  const SizedBox(height: 20),
                  _buildNotificationsSection(),
                  const SizedBox(height: 20),
                  if (pendingNotifications.isNotEmpty) ...[
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                  ],
                  _buildHelpSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withAlpha(204),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإشعارات النشطة',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pendingNotifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: pendingNotifications.isEmpty
                    ? Colors.red.withAlpha(179)
                    : Colors.green.withAlpha(179),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pendingNotifications.isEmpty ? 'معطل' : 'نشط',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
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
                  Icons.schedule_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'الإشعارات المجدولة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (pendingNotifications.isEmpty)
              _buildEmptyState()
            else
              ...pendingNotifications.take(10).map(_buildNotificationCard),
            if (pendingNotifications.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    'و ${pendingNotifications.length - 10} إشعار آخر',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات مجدولة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بتفعيل الإشعارات من صفحة الأذكار',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(PendingNotificationRequest notification) {
    final color = _getNotificationColor(notification.id);
    final icon = _getNotificationIcon(notification.id);
    final name = _getNotificationName(notification.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(
          notification.body ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _cancelNotification(notification.id),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'إجراءات خطرة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cancelAllNotifications,
                icon: const Icon(Icons.delete_forever),
                label: const Text('إلغاء جميع الإشعارات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
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
                  'معلومات مفيدة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.check_circle_outline,
              text: 'تعمل الإشعارات حتى لو كان التطبيق مغلقاً',
              color: Colors.green,
            ),
            _buildInfoItem(
              icon: Icons.repeat,
              text: 'يتم تكرار الإشعارات حسب الإعدادات المحددة',
              color: Colors.blue,
            ),
            _buildInfoItem(
              icon: Icons.battery_alert,
              text: 'تأكد من عدم تفعيل وضع توفير البطارية للتطبيق',
              color: Colors.red,
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
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }
}
