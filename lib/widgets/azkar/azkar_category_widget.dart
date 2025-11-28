import 'package:flutter/material.dart';
import 'package:najatak/models/azkar_model.dart';

import 'azkar_item_widget.dart';

typedef AzkarItemTapCallback =
    void Function(Azkar azkar, Color color, Gradient gradient);

class AzkarCategoryWidget extends StatefulWidget {
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
  final AzkarItemTapCallback onAzkarItemTap;

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
  State<AzkarCategoryWidget> createState() => _AzkarCategoryWidgetState();
}

class _AzkarCategoryWidgetState extends State<AzkarCategoryWidget> {
  late List<Azkar> displayedAzkar;

  @override
  void initState() {
    super.initState();
    displayedAzkar = List.from(widget.azkarList);
  }

  void _deleteAzkar(Azkar azkar, int originalIndex) {
    setState(() {
      displayedAzkar.remove(azkar);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.title,
      child: Card(
        elevation: 8,
        shadowColor: widget.color.withAlpha(77),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.white, widget.color.withAlpha(13)],
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
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              title: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                ),
              ),
              trailing: widget.onNotificationToggle != null
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.notificationEnabled!
                            ? Colors.green.withAlpha(25)
                            : Colors.grey.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.notificationEnabled!
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: widget.notificationEnabled!
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
                if (widget.onNotificationToggle != null)
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
                          color: widget.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_list_numbered,
                              color: widget.color,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${displayedAzkar.length} ذكر',
                              style: TextStyle(
                                color: widget.color,
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
                if (displayedAzkar.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.delete_sweep,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد أذكار',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...displayedAzkar.asMap().entries.map((entry) {
                    final index = entry.key;
                    final azkar = entry.value;
                    return Dismissible(
                      key: ValueKey(azkar.hashCode),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        _deleteAzkar(azkar, index);
                      },
                      background: const SizedBox(),
                      secondaryBackground: const SizedBox(),
                      child: AzkarItemWidget(
                        azkar: azkar,
                        color: widget.color,
                        gradient: widget.gradient,
                        index: index,
                        onTap: () => widget.onAzkarItemTap(
                          azkar,
                          widget.color,
                          widget.gradient,
                        ),
                      ),
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
        color: widget.color.withAlpha(13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.color.withAlpha(51)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'تفعيل التنبيه اليومي',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
            subtitle: Text(
              widget.notificationEnabled!
                  ? 'سيصلك التنبيه يومياً الساعة ${widget.currentTime!.format(context)}'
                  : 'قم بتفعيل التنبيه لاختيار الوقت',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: widget.notificationEnabled!,
            onChanged: widget.onNotificationToggle,
            activeThumbColor: widget.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          if (widget.notificationEnabled! && widget.onChangeTime != null)
            InkWell(
              onTap: widget.onChangeTime,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time,
                        color: widget.color,
                        size: 20,
                      ),
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
                              color: widget.color,
                            ),
                          ),
                          Text(
                            'الوقت الحالي: ${widget.currentTime!.format(context)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit, color: widget.color, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
