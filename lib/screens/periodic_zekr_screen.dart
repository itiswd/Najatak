// ═══════════════════════════════════════════════════════════════
// lib/screens/periodic_zekr_screen.dart - النسخة المحسّنة
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/periodic_notification_worker.dart';

class PeriodicAzkarScreen extends StatefulWidget {
  const PeriodicAzkarScreen({super.key});

  @override
  State<PeriodicAzkarScreen> createState() => _PeriodicAzkarScreenState();
}

class _PeriodicAzkarScreenState extends State<PeriodicAzkarScreen> {
  // البيانات الأساسية
  final List<AzkarItem> _allAzkar = [
    AzkarItem(id: 'zekr1', text: 'لَا إِلَهَ إِلَّا اللهُ', sound: 'zekr_1'),
    AzkarItem(
      id: 'zekr2',
      text:
          'لَا إلَهَ إلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَئٍ قَدِيرُ',
      sound: 'zekr_2',
    ),
    AzkarItem(
      id: 'zekr3',
      text: 'أَسْتَغْفِرُ اللهَ العَظِيمَ',
      sound: 'zekr_3',
    ),
    AzkarItem(
      id: 'zekr4',
      text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّد',
      sound: 'zekr_4',
    ),
    AzkarItem(
      id: 'zekr5',
      text:
          'سُبْحَانَ اللهِ، وَالْحَمْدُ للهِ، وَلَا إلَهَ إلَّا اللهُ، وَاللهُ أَكْبَرُ',
      sound: 'zekr_5',
    ),
    AzkarItem(
      id: 'zekr6',
      text: 'لَا حَوْلَ وَلَا قُوَّةَ إلَّا بِاللهِ',
      sound: 'zekr_6',
    ),
    AzkarItem(
      id: 'zekr7',
      text:
          'حَسْبِيَ اللهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      sound: 'zekr_7',
    ),
    AzkarItem(
      id: 'zekr8',
      text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ سُبْحَانَ اللهِ العَظِيْمِ',
      sound: 'zekr_8',
    ),
    AzkarItem(
      id: 'zekr9',
      text:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
      sound: 'zekr_9',
    ),
    AzkarItem(
      id: 'zekr10',
      text:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      sound: 'zekr_10',
    ),
    AzkarItem(
      id: 'zekr11',
      text:
          'اللَّهُمَّ لَكَ الْحَمْدُ وَلَكَ الشُّكْرُ عَلَى نِعَمِكَ الَّتِي لَا تُعَدُّ وَلَا تُحْصَى',
      sound: 'zekr_11',
    ),
    AzkarItem(
      id: 'zekr12',
      text:
          'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      sound: 'zekr_12',
    ),
    AzkarItem(
      id: 'zekr13',
      text: 'اللَّهُمَّ يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
      sound: 'zekr_13',
    ),
    AzkarItem(
      id: 'zekr14',
      text:
          'سُبْحَانَ اللهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      sound: 'zekr_14',
    ),
  ];

  // الحالة
  List<String> _selectedIds = [];
  int _intervalMinutes = 30;
  bool _isEnabled = false;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل الإعدادات المحفوظة
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isEnabled = prefs.getBool('periodic_enabled') ?? false;
      _intervalMinutes = prefs.getInt('periodic_interval') ?? 30;

      final saved = prefs.getString('periodic_selected');
      if (saved != null && saved.isNotEmpty) {
        try {
          _selectedIds = List<String>.from(json.decode(saved));
        } catch (_) {
          _selectedIds = [];
        }
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // حفظ الإعدادات
  // ═══════════════════════════════════════════════════════════════
  Future<void> _saveSettings() async {
    if (_selectedIds.isEmpty) {
      _showMessage('⚠️ يجب اختيار ذكر واحد على الأقل', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // حفظ الإعدادات
      await prefs.setString('periodic_selected', json.encode(_selectedIds));
      await prefs.setInt('periodic_interval', _intervalMinutes);
      await prefs.setBool('periodic_enabled', true);

      // تطبيق الإعدادات
      final selectedAzkar = _allAzkar
          .where((a) => _selectedIds.contains(a.id))
          .map((a) => a.toMap())
          .toList();

      await PeriodicAzkarWorker.startPeriodicWorker(
        selectedAzkar,
        _intervalMinutes,
      );

      setState(() {
        _isEnabled = true;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        _showMessage(
          '✅ تم حفظ الإعدادات بنجاح\n📱 سيظهر أول إشعار بعد $_intervalMinutes دقيقة',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('❌ حدث خطأ: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // تشغيل/إيقاف مع الحفاظ على الإعدادات
  // ═══════════════════════════════════════════════════════════════
  Future<void> _toggleService(bool enable) async {
    if (enable && _selectedIds.isEmpty) {
      _showMessage('⚠️ يجب اختيار أذكار أولاً', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      if (enable) {
        // تشغيل بنفس الإعدادات المحفوظة
        final selectedAzkar = _allAzkar
            .where((a) => _selectedIds.contains(a.id))
            .map((a) => a.toMap())
            .toList();

        await PeriodicAzkarWorker.startPeriodicWorker(
          selectedAzkar,
          _intervalMinutes,
        );
        await prefs.setBool('periodic_enabled', true);

        if (mounted) {
          _showMessage('✅ تم تشغيل الأذكار الدورية', Colors.green);
        }
      } else {
        // إيقاف مع الحفاظ على الإعدادات
        await PeriodicAzkarWorker.stopPeriodicWorker();
        await prefs.setBool('periodic_enabled', false);

        if (mounted) {
          _showMessage(
            '⏸️ تم إيقاف الأذكار الدورية\nالإعدادات محفوظة',
            Colors.blue,
          );
        }
      }

      setState(() => _isEnabled = enable);
    } catch (e) {
      if (mounted) {
        _showMessage('❌ خطأ: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار/إلغاء اختيار ذكر
  // ═══════════════════════════════════════════════════════════════
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _hasUnsavedChanges = true;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار الفاصل الزمني
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showIntervalPicker() async {
    final intervals = [
      IntervalOption(1, 'دقيقة واحدة', Icons.timer),
      IntervalOption(5, '٥ دقائق', Icons.timer),
      IntervalOption(10, '١٠ دقائق', Icons.timer),
      IntervalOption(15, '١٥ دقيقة', Icons.timer),
      IntervalOption(30, '٣٠ دقيقة', Icons.timer),
      IntervalOption(45, '٤٥ دقيقة', Icons.timer),
      IntervalOption(60, 'ساعة', Icons.timer),
      IntervalOption(90, 'ساعة ونصف', Icons.timer),
      IntervalOption(120, 'ساعتان', Icons.timer),
      IntervalOption(180, '٣ ساعات', Icons.timer),
      IntervalOption(240, '٤ ساعات', Icons.timer),
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'اختر الفاصل الزمني',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: intervals.length,
                itemBuilder: (context, index) {
                  final interval = intervals[index];
                  final isSelected = _intervalMinutes == interval.minutes;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1B5E20).withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1B5E20)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          interval.icon,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        interval.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF1B5E20),
                              size: 28,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _intervalMinutes = interval.minutes;
                          _hasUnsavedChanges = true;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 15)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بناء الواجهة
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStatusCard(),
              _buildIntervalCard(),
              const Divider(height: 1),
              _buildAzkarCounter(),
              Expanded(child: _buildAzkarList()),
            ],
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 80,
      title: const Text(
        'الأذكار الدورية',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isEnabled
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [Colors.grey[700]!, Colors.grey[600]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isEnabled ? const Color(0xFF1B5E20) : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _isEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEnabled ? 'الأذكار مُفعّلة' : 'الأذكار متوقفة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEnabled
                      ? 'تعمل تلقائياً في الخلفية'
                      : 'اضغط "حفظ وتشغيل" للبدء',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            onChanged: _isLoading ? null : _toggleService,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        elevation: 2,
        child: InkWell(
          onTap: _isLoading ? null : _showIntervalPicker,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.1),
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
                        _formatInterval(_intervalMinutes),
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
      ),
    );
  }

  Widget _buildAzkarCounter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1B5E20).withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF1B5E20)),
          const SizedBox(width: 8),
          Text(
            'تم اختيار ${_selectedIds.length} من ${_allAzkar.length} ذكر',
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

  Widget _buildAzkarList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allAzkar.length,
      itemBuilder: (context, index) {
        final azkar = _allAzkar[index];
        final isSelected = _selectedIds.contains(azkar.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1B5E20).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: _isLoading ? null : (_) => _toggleSelection(azkar.id),
            activeColor: const Color(0xFF1B5E20),
            title: Text(
              azkar.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                height: 1.8,
              ),
            ),
            subtitle: isSelected
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✓ محدد - ترتيب: ${_selectedIds.indexOf(azkar.id) + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasUnsavedChanges)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'لديك تغييرات غير محفوظة',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _selectedIds.isEmpty)
                        ? null
                        : _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'حفظ وتشغيل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'جاري الحفظ...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatInterval(int minutes) {
    if (minutes < 60) return '$minutes دقيقة';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return hours == 1 ? 'ساعة' : '$hours ساعات';
    return '$hours:${mins.toString().padLeft(2, '0')} ساعة';
  }
}

// ═══════════════════════════════════════════════════════════════
// نماذج البيانات
// ═══════════════════════════════════════════════════════════════

class AzkarItem {
  final String id;
  final String text;
  final String sound;

  AzkarItem({required this.id, required this.text, required this.sound});

  Map<String, String> toMap() => {'id': id, 'text': text, 'sound': sound};
}

class IntervalOption {
  final int minutes;
  final String label;
  final IconData icon;

  IntervalOption(this.minutes, this.label, this.icon);
}
