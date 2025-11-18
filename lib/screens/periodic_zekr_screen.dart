import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class PeriodicAzkarScreen extends StatefulWidget {
  const PeriodicAzkarScreen({super.key});

  @override
  State<PeriodicAzkarScreen> createState() => _PeriodicAzkarScreenState();
}

class _PeriodicAzkarScreenState extends State<PeriodicAzkarScreen> {
  // قائمة الأذكار المتاحة
  final List<Map<String, String>> availableAzkar = [
    {'text': 'سُبْحَانَ اللهِ وَبِحَمْدِهِ', 'id': 'zekr1'},
    {'text': 'لَا إلَهَ إلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ', 'id': 'zekr2'},
    {'text': 'أَسْتَغْفِرُ اللهَ العَظِيمَ', 'id': 'zekr3'},
    {
      'text': 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّد',
      'id': 'zekr4',
    },
    {
      'text':
          'سُبْحَانَ اللهِ، وَالْحَمْدُ للهِ، وَلَا إلَهَ إلَّا اللهُ، وَاللهُ أَكْبَرُ',
      'id': 'zekr5',
    },
    {'text': 'لَا حَوْلَ وَلَا قُوَّةَ إلَّا بِاللهِ', 'id': 'zekr6'},
    {
      'text': 'حَسْبِيَ اللهُ لَا إلَهَ إلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ',
      'id': 'zekr7',
    },
    {
      'text':
          'رَضِيتُ بِاللهِ رَبًّا، وَبِالإسْلَامِ دِينًا، وَبِمُحَمَّدٍ نَبِيًّا',
      'id': 'zekr8',
    },
    {
      'text': 'اللَّهُمَّ إنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
      'id': 'zekr9',
    },
    {'text': 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ', 'id': 'zekr10'},
    {'text': 'اللَّهُمَّ أَنْتَ رَبِّي لَا إلَهَ إلَّا أَنْتَ', 'id': 'zekr11'},
    {
      'text': 'بِسْمِ اللهِ الذي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ',
      'id': 'zekr12',
    },
    {
      'text':
          'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي',
      'id': 'zekr13',
    },
    {
      'text': 'أَعُوذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      'id': 'zekr14',
    },
    {
      'text':
          'اللَّهُمَّ إنَّا نَعُوذُ بِكَ مِنْ أَنْ نُشْرِكَ بِكَ شَيْئًا نَعْلَمُهُ',
      'id': 'zekr15',
    },
  ];

  List<String> selectedAzkar = []; // تغيير من Set إلى List للحفاظ على الترتيب
  int intervalMinutes = 30; // القيمة الافتراضية: 30 دقيقة
  bool isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnabled = prefs.getBool('periodic_azkar_enabled') ?? false;
      intervalMinutes = prefs.getInt('periodic_azkar_interval') ?? 30;

      final savedAzkar = prefs.getString('periodic_selected_azkar');
      if (savedAzkar != null) {
        selectedAzkar = List<String>.from(json.decode(savedAzkar));
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('periodic_azkar_enabled', isEnabled);
    await prefs.setInt('periodic_azkar_interval', intervalMinutes);
    await prefs.setString(
      'periodic_selected_azkar',
      json.encode(selectedAzkar),
    );
  }

  void _toggleAzkar(String id) {
    setState(() {
      if (selectedAzkar.contains(id)) {
        selectedAzkar.remove(id);
      } else {
        selectedAzkar.add(id); // يضاف في النهاية حسب الترتيب
      }
    });
    _saveSettings();
  }

  void _selectAll() {
    setState(() {
      selectedAzkar = availableAzkar.map((e) => e['id']!).toList();
    });
    _saveSettings();
  }

  void _deselectAll() {
    setState(() {
      selectedAzkar.clear();
    });
    _saveSettings();
  }

  void _moveUp(String id) {
    setState(() {
      final index = selectedAzkar.indexOf(id);
      if (index > 0) {
        final temp = selectedAzkar[index];
        selectedAzkar[index] = selectedAzkar[index - 1];
        selectedAzkar[index - 1] = temp;
        _saveSettings();
      }
    });
  }

  void _moveDown(String id) {
    setState(() {
      final index = selectedAzkar.indexOf(id);
      if (index < selectedAzkar.length - 1) {
        final temp = selectedAzkar[index];
        selectedAzkar[index] = selectedAzkar[index + 1];
        selectedAzkar[index + 1] = temp;
        _saveSettings();
      }
    });
  }

  Future<void> _togglePeriodicNotifications(bool value) async {
    if (value && selectedAzkar.isEmpty) {
      _showErrorSnackBar('يرجى اختيار ذكر واحد على الأقل');
      return;
    }

    setState(() {
      isEnabled = value;
    });

    if (value) {
      // إلغاء الإشعارات القديمة
      for (int i = 0; i < 15; i++) {
        await NotificationService.cancelNotification(500 + i);
      }

      // جدولة إشعارات جديدة للأذكار المختارة بالترتيب
      for (int i = 0; i < selectedAzkar.length; i++) {
        final zekrId = selectedAzkar[i];
        final zekr = availableAzkar.firstWhere((e) => e['id'] == zekrId);

        // كل ذكر يُجدول بعد المدة المحددة × رقمه في الترتيب
        final delayMinutes = intervalMinutes * i;

        await NotificationService.scheduleSequentialNotification(
          id: 500 + i,
          title: 'ذكر ${i + 1} من ${selectedAzkar.length}',
          body: zekr['text']!,
          delayMinutes: delayMinutes,
          intervalMinutes:
              intervalMinutes * selectedAzkar.length, // يتكرر بعد كل الأذكار
        );
      }

      final totalCycleTime = intervalMinutes * selectedAzkar.length;
      final hours = totalCycleTime >= 60 ? totalCycleTime ~/ 60 : 0;
      final mins = totalCycleTime % 60;
      String cycleLabel = hours > 0
          ? (mins > 0
                ? '$hours ساعة و $mins دقيقة'
                : '$hours ${hours == 1 ? 'ساعة' : 'ساعات'}')
          : '$mins دقيقة';

      _showSuccessSnackBar(
        'تم تفعيل ${selectedAzkar.length} ذكر\nالذكر كل $intervalMinutes دقيقة\nدورة كاملة كل $cycleLabel',
      );
    } else {
      // إلغاء جميع الإشعارات الدورية
      for (int i = 0; i < 15; i++) {
        await NotificationService.cancelNotification(500 + i);
      }
      _showInfoSnackBar('تم إيقاف الأذكار الدورية');
    }

    await _saveSettings();
  }

  Future<void> _showIntervalPicker() async {
    final intervals = [5, 10, 15, 20, 30, 45, 60, 90, 120, 180];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر الفاصل الزمني بين كل ذكر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: intervals.map((minutes) {
              final hours = minutes >= 60 ? minutes ~/ 60 : 0;
              final remainingMinutes = minutes % 60;
              String label;

              if (hours > 0 && remainingMinutes > 0) {
                label = '$hours ساعة و $remainingMinutes دقيقة';
              } else if (hours > 0) {
                label = '$hours ${hours == 1 ? 'ساعة' : 'ساعات'}';
              } else {
                label = '$minutes دقيقة';
              }

              return RadioListTile<int>(
                title: Text(label),
                value: minutes,
                groupValue: intervalMinutes,
                onChanged: (value) {
                  setState(() {
                    intervalMinutes = value!;
                  });
                  Navigator.pop(context);
                  _saveSettings();

                  // إعادة جدولة الإشعارات إذا كانت مفعلة
                  if (isEnabled) {
                    _togglePeriodicNotifications(false).then((_) {
                      _togglePeriodicNotifications(true);
                    });
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
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
        duration: const Duration(seconds: 4),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = intervalMinutes >= 60 ? intervalMinutes ~/ 60 : 0;
    final remainingMinutes = intervalMinutes % 60;
    String intervalLabel;

    if (hours > 0 && remainingMinutes > 0) {
      intervalLabel = '$hours ساعة و $remainingMinutes دقيقة';
    } else if (hours > 0) {
      intervalLabel = '$hours ${hours == 1 ? 'ساعة' : 'ساعات'}';
    } else {
      intervalLabel = '$intervalMinutes دقيقة';
    }

    // حساب وقت الدورة الكاملة
    final totalCycleTime = selectedAzkar.isNotEmpty
        ? intervalMinutes * selectedAzkar.length
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الأذكار الدورية',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1B5E20),
                const Color(0xFF1B5E20).withAlpha(204),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة التحكم الرئيسية
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B5E20),
                    const Color(0xFF1B5E20).withAlpha(204),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.repeat,
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
                              'الأذكار الدورية',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEnabled
                                  ? 'مفعل - ذكر كل $intervalLabel'
                                  : 'غير مفعل',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isEnabled,
                        onChanged: _togglePeriodicNotifications,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.white.withAlpha(128),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // بطاقة معلومات الدورة
          if (selectedAzkar.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        'معلومات الدورة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.format_list_numbered,
                    'عدد الأذكار',
                    '${selectedAzkar.length} ذكر',
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    Icons.timer,
                    'الفاصل بين كل ذكر',
                    intervalLabel,
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    Icons.loop,
                    'وقت الدورة الكاملة',
                    _formatTime(totalCycleTime),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // بطاقة الفاصل الزمني
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: _showIntervalPicker,
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.timer,
                        color: Color(0xFF1B5E20),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الفاصل الزمني بين كل ذكر',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            intervalLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, color: Color(0xFF1B5E20)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // أزرار التحديد السريع
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.check_box),
                  label: const Text('تحديد الكل'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.check_box_outline_blank),
                  label: const Text('إلغاء الكل'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // عداد الأذكار المحددة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withAlpha(25),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.format_list_numbered,
                  color: Color(0xFF1B5E20),
                ),
                const SizedBox(width: 8),
                Text(
                  'تم اختيار ${selectedAzkar.length} من ${availableAzkar.length} ذكر',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // قائمة الأذكار
          ...availableAzkar.map((zekr) {
            final isSelected = selectedAzkar.contains(zekr['id']);
            final selectedIndex = selectedAzkar.indexOf(zekr['id']!);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1B5E20).withAlpha(25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: Text(
                      zekr['text']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        height: 1.8,
                      ),
                    ),
                    subtitle: isSelected
                        ? Text(
                            'ترتيب الإرسال: ${selectedIndex + 1}',
                            style: TextStyle(
                              color: const Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    value: isSelected,
                    onChanged: (_) => _toggleAzkar(zekr['id']!),
                    activeColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  // أزرار تغيير الترتيب
                  if (isSelected && selectedAzkar.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'تغيير الترتيب:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 20),
                            onPressed: selectedIndex > 0
                                ? () => _moveUp(zekr['id']!)
                                : null,
                            tooltip: 'تحريك لأعلى',
                            color: const Color(0xFF1B5E20),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 20),
                            onPressed: selectedIndex < selectedAzkar.length - 1
                                ? () => _moveDown(zekr['id']!)
                                : null,
                            tooltip: 'تحريك لأسفل',
                            color: const Color(0xFF1B5E20),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  String _formatTime(int minutes) {
    final hours = minutes >= 60 ? minutes ~/ 60 : 0;
    final mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return '$hours ساعة و $mins دقيقة';
    } else if (hours > 0) {
      return '$hours ${hours == 1 ? 'ساعة' : 'ساعات'}';
    } else {
      return '$mins دقيقة';
    }
  }
}
