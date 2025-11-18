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
  final List<Map<String, String>> availableAzkar = [
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
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
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

  List<String> selectedAzkar = [];
  int intervalMinutes = 30;
  bool isEnabled = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

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
    if (!mounted) return;

    setState(() {
      if (selectedAzkar.contains(id)) {
        selectedAzkar.remove(id);
      } else {
        selectedAzkar.add(id);
      }
    });
    _saveSettings();
  }

  Future<void> _togglePeriodicNotifications(bool value) async {
    if (value && selectedAzkar.isEmpty) {
      if (mounted) {
        _showSnackBar('يرجى اختيار ذكر واحد على الأقل', Colors.orange);
      }
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      if (value) {
        // بناء قائمة الأذكار المختارة بالترتيب
        final List<Map<String, String>> orderedAzkar = selectedAzkar
            .map((id) => availableAzkar.firstWhere((e) => e['id'] == id))
            .toList();

        await NotificationService.schedulePeriodicAzkar(
          azkarList: orderedAzkar,
          intervalMinutes: intervalMinutes,
        );

        if (!mounted) return;
        setState(() => isEnabled = true);
        await _saveSettings();

        if (mounted) {
          final total = intervalMinutes * selectedAzkar.length;
          _showSnackBar(
            'تم تفعيل ${selectedAzkar.length} ذكر\nالذكر كل $intervalMinutes دقيقة\nدورة كاملة: ${_formatTime(total)}',
            Colors.green,
          );
        }
      } else {
        await NotificationService.cancelAllPeriodicNotifications();

        if (!mounted) return;
        setState(() => isEnabled = false);
        await _saveSettings();

        if (mounted) {
          _showSnackBar('تم إيقاف الأذكار الدورية', Colors.blue);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('حدث خطأ: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showIntervalPicker() async {
    if (!mounted) return;

    final intervals = [5, 10, 15, 20, 30, 45, 60, 90, 120, 180];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('الفاصل الزمني بين كل ذكر'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: intervals.length,
            itemBuilder: (context, index) {
              final minutes = intervals[index];
              return ListTile(
                title: Text(_formatTime(minutes)),
                trailing: intervalMinutes == minutes
                    ? const Icon(Icons.check_circle, color: Color(0xFF1B5E20))
                    : null,
                onTap: () {
                  if (!mounted) return;
                  setState(() => intervalMinutes = minutes);
                  Navigator.pop(context);
                  _saveSettings();
                  if (isEnabled) {
                    _togglePeriodicNotifications(false).then((_) {
                      if (mounted) {
                        _togglePeriodicNotifications(true);
                      }
                    });
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

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

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '$hours ساعة و $mins دقيقة';
    if (hours > 0) return '$hours ساعة';
    return '$mins دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار الدورية'),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildControlCard(),
                const SizedBox(height: 16),
                if (selectedAzkar.isNotEmpty) _buildInfoCard(),
                if (selectedAzkar.isNotEmpty) const SizedBox(height: 16),
                _buildIntervalCard(),
                const SizedBox(height: 16),
                _buildAzkarCounter(),
                const SizedBox(height: 16),
                ...availableAzkar.map(_buildAzkarItem),
              ],
            ),
    );
  }

  Widget _buildControlCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.repeat, color: Colors.white, size: 32),
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
                    isEnabled ? 'مفعّل' : 'غير مفعّل',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
      ),
    );
  }

  Widget _buildInfoCard() {
    final total = intervalMinutes * selectedAzkar.length;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.format_list_numbered,
              'عدد الأذكار',
              '${selectedAzkar.length} ذكر',
            ),
            const Divider(height: 16),
            _buildInfoRow(
              Icons.timer,
              'الفاصل بين كل ذكر',
              _formatTime(intervalMinutes),
            ),
            const Divider(height: 16),
            _buildInfoRow(Icons.loop, 'وقت الدورة الكاملة', _formatTime(total)),
          ],
        ),
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

  Widget _buildIntervalCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      'الفاصل الزمني',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(intervalMinutes),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit, color: Color(0xFF1B5E20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAzkarCounter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withAlpha(25),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.format_list_numbered, color: Color(0xFF1B5E20)),
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
    );
  }

  Widget _buildAzkarItem(Map<String, String> zekr) {
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
          color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          zekr['text']!,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            height: 1.8,
          ),
        ),
        subtitle: isSelected
            ? Text(
                'ترتيب الظهور: ${selectedIndex + 1}',
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              )
            : null,
        value: isSelected,
        onChanged: (_) => _toggleAzkar(zekr['id']!),
        activeColor: const Color(0xFF1B5E20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
