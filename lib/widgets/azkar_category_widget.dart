import 'package:flutter/material.dart';

import '../../models/azkar_model.dart';
import 'azkar_item_widget.dart'; // استيراد ويدجت العنصر

typedef AzkarItemTapCallback =
    void Function(Azkar azkar, Color color, Gradient gradient);

class AzkarCategoryWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final List<Azkar> azkarList;
  final bool? notificationEnabled;
  final Function(bool)? onNotificationToggle;
  final TimeOfDay? currentTime;
  final VoidCallback? onChangeTime;
  final AzkarItemTapCallback onAzkarItemTap; // دالة تمرير لفتح تفاصيل الذكر

  const AzkarCategoryWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.azkarList,
    this.notificationEnabled,
    this.onNotificationToggle,
    this.currentTime,
    this.onChangeTime,
    required this.onAzkarItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: title,
      child: Card(
        elevation: 8,
        shadowColor: color.withAlpha(77),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.white, color.withAlpha(13)],
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
                      color: color.withAlpha(77),
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
                            ? Colors.green.withAlpha(25)
                            : Colors.grey.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            notificationEnabled!
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: notificationEnabled!
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
                if (onNotificationToggle != null)
                  _buildNotificationSettings(context),

                const SizedBox(height: 8),

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
                          color: color.withAlpha(25),
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
                  return AzkarItemWidget(
                    azkar: azkar,
                    color: color,
                    gradient: gradient,
                    index: index,
                    onTap: () => onAzkarItemTap(azkar, color, gradient),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'تفعيل التنبيه اليومي',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            subtitle: Text(
              notificationEnabled!
                  ? 'سيصلك التنبيه يومياً الساعة ${currentTime!.format(context)}'
                  : 'قم بتفعيل التنبيه لاختيار الوقت',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: notificationEnabled!,
            onChanged: onNotificationToggle,
            activeThumbColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          if (notificationEnabled! && onChangeTime != null)
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
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.access_time, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
