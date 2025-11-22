// ═══════════════════════════════════════════════════════════════
// lib/screens/periodic_zekr_screen.dart - النسخة الاحترافية
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
  List<String> _originalSelectedIds = [];
  int _intervalMinutes = 30;
  int _originalInterval = 30;
  bool _isEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  bool get _hasUnsavedChanges {
    return _selectedIds.toString() != _originalSelectedIds.toString() ||
        _intervalMinutes != _originalInterval;
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل الإعدادات
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isEnabled = prefs.getBool('periodic_enabled') ?? false;
      _intervalMinutes = prefs.getInt('periodic_interval') ?? 30;
      _originalInterval = _intervalMinutes;

      final saved = prefs.getString('periodic_selected');
      if (saved != null && saved.isNotEmpty) {
        try {
          _selectedIds = List<String>.from(json.decode(saved));
          _originalSelectedIds = List<String>.from(_selectedIds);
        } catch (_) {
          _selectedIds = [];
          _originalSelectedIds = [];
        }
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // حفظ وتطبيق الإعدادات
  // ═══════════════════════════════════════════════════════════════
  Future<void> _saveAndApply() async {
    if (_selectedIds.isEmpty) {
      _showMessage('⚠️ يجب اختيار ذكر واحد على الأقل', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('periodic_selected', json.encode(_selectedIds));
      await prefs.setInt('periodic_interval', _intervalMinutes);
      await prefs.setBool('periodic_enabled', true);

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
        _originalSelectedIds = List<String>.from(_selectedIds);
        _originalInterval = _intervalMinutes;
      });

      if (mounted) {
        _showMessage(
          '✅ تم الحفظ بنجاح\n📱 سيظهر أول إشعار بعد $_intervalMinutes دقيقة',
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
  // تبديل حالة التشغيل
  // ═══════════════════════════════════════════════════════════════
  Future<void> _toggleEnabled(bool value) async {
    if (value && _selectedIds.isEmpty) {
      _showMessage('⚠️ يجب اختيار أذكار أولاً', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      if (value) {
        final selectedAzkar = _allAzkar
            .where((a) => _selectedIds.contains(a.id))
            .map((a) => a.toMap())
            .toList();

        await PeriodicAzkarWorker.startPeriodicWorker(
          selectedAzkar,
          _intervalMinutes,
        );
        await prefs.setBool('periodic_enabled', true);
        if (mounted) _showMessage('✅ تم التشغيل', Colors.green);
      } else {
        await PeriodicAzkarWorker.stopPeriodicWorker();
        await prefs.setBool('periodic_enabled', false);
        if (mounted) _showMessage('⏸️ تم الإيقاف', Colors.blue);
      }

      setState(() => _isEnabled = value);
    } catch (e) {
      if (mounted) _showMessage('❌ خطأ: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار الفاصل الزمني - منبثق
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showIntervalSheet() async {
    final intervals = [
      IntervalOption(1, 'دقيقة واحدة'),
      IntervalOption(5, '٥ دقائق'),
      IntervalOption(10, '١٠ دقائق'),
      IntervalOption(15, '١٥ دقيقة'),
      IntervalOption(30, '٣٠ دقيقة'),
      IntervalOption(45, '٤٥ دقيقة'),
      IntervalOption(60, 'ساعة'),
      IntervalOption(90, 'ساعة ونصف'),
      IntervalOption(120, 'ساعتان'),
      IntervalOption(180, '٣ ساعات'),
      IntervalOption(240, '٤ ساعات'),
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // العنوان
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withAlpha(26),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFF1B5E20),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'اختر الفاصل الزمني',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // القائمة
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: intervals.length,
                itemBuilder: (context, index) {
                  final interval = intervals[index];
                  final isSelected = _intervalMinutes == interval.minutes;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1B5E20).withAlpha(77),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _intervalMinutes = interval.minutes);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  interval.label,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(77),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار الأذكار - منبثق
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showAzkarSheet() async {
    final tempSelected = List<String>.from(_selectedIds);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // العنوان
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withAlpha(26),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
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
                            'اختر الأذكار',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            '${tempSelected.length} محدد من ${_allAzkar.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tempSelected.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setModalState(() => tempSelected.clear());
                        },
                        child: const Text(
                          'مسح الكل',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // القائمة
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _allAzkar.length,
                  itemBuilder: (context, index) {
                    final azkar = _allAzkar[index];
                    final isSelected = tempSelected.contains(azkar.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF1B5E20).withAlpha(26),
                                  const Color(0xFF2E7D32).withAlpha(13),
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                tempSelected.remove(azkar.id);
                              } else {
                                tempSelected.add(azkar.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1B5E20)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1B5E20)
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    azkar.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF1B5E20)
                                          : Colors.black87,
                                      height: 1.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // زر التأكيد
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedIds = tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          'تأكيد (${tempSelected.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1️⃣ خانة حالة الإشعارات
                      _buildStatusCard(),
                      const SizedBox(height: 16),

                      // 2️⃣ خانة الفاصل الزمني (منبثقة)
                      _buildIntervalCard(),
                      const SizedBox(height: 16),

                      // 3️⃣ خانة الأذكار (منبثقة)
                      _buildAzkarCard(),
                    ],
                  ),
                ),
              ),

              // زر الحفظ (يظهر عند وجود تغييرات فقط)
              if (_hasUnsavedChanges) _buildSaveButton(),
            ],
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 70,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'الأذكار الدورية',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 1️⃣ خانة حالة الإشعارات
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isEnabled
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [Colors.grey[700]!, Colors.grey[600]!],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (_isEnabled ? const Color(0xFF1B5E20) : Colors.grey)
                .withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
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
                      _isEnabled ? 'الأذكار مُفعَّلة' : 'الأذكار متوقفة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      _isEnabled
                          ? 'تعمل تلقائياً في الخلفية'
                          : 'قم بتشغيل الأذكار للبدء',
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1,
                child: Switch(
                  value: _isEnabled,
                  onChanged: _isLoading ? null : _toggleEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white.withAlpha(128),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white.withAlpha(77),
                ),
              ),
            ],
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusInfo(
                    Icons.schedule_rounded,
                    'الفاصل',
                    _formatInterval(_intervalMinutes),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withAlpha(77),
                  ),
                  _buildStatusInfo(
                    Icons.format_list_numbered_rounded,
                    'الأذكار',
                    '${_selectedIds.length} ذكر',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 2️⃣ خانة الفاصل الزمني (منبثقة)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildIntervalCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _showIntervalSheet,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B5E20).withAlpha(26),
                        const Color(0xFF2E7D32).withAlpha(13),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: Color(0xFF1B5E20),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الفاصل الزمني',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      Text(
                        _formatInterval(_intervalMinutes),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF1B5E20),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 3️⃣ خانة الأذكار (منبثقة)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAzkarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _showAzkarSheet,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B5E20).withAlpha(26),
                            const Color(0xFF2E7D32).withAlpha(13),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF1B5E20),
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الأذكار المحددة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          Text(
                            _selectedIds.isEmpty
                                ? 'لم يتم اختيار أذكار'
                                : '${_selectedIds.length} من ${_allAzkar.length} ذكر',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedIds.isEmpty
                                  ? Colors.grey[600]
                                  : const Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF1B5E20),
                        size: 18,
                      ),
                    ),
                  ],
                ),
                if (_selectedIds.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withAlpha(13),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF1B5E20).withAlpha(26),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFF1B5E20),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'معاينة الأذكار المحددة',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(
                          _selectedIds.length > 3 ? 3 : _selectedIds.length,
                          (index) {
                            final azkar = _allAzkar.firstWhere(
                              (a) => a.id == _selectedIds[index],
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B5E20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      azkar.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (_selectedIds.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'و ${_selectedIds.length - 3} أذكار أخرى...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // زر الحفظ (يظهر فقط عند وجود تغييرات)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[50]!, Colors.orange[100]!],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange[300]!, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_notifications_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'لديك تغييرات غير محفوظة',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || _selectedIds.isEmpty)
                    ? null
                    : _saveAndApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF1B5E20).withAlpha(102),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'حفظ وتطبيق التغييرات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'جاري المعالجة...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
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
    return '$hours س $mins د';
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

  IntervalOption(this.minutes, this.label);
}
