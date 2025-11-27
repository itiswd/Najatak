// تحديث lib/screens/mushaf_page_view_screen.dart
// استبدل الملف بالكود التالي:

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:najatak/screens/mushaf_search_screen.dart';
import 'package:najatak/widgets/mushaf/mushaf_app_bar.dart';
import 'package:najatak/widgets/mushaf/mushaf_page_content_optimized.dart';
import 'package:najatak/widgets/mushaf/mushaf_playback_indicator.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/continuous_audio_handler.dart';

class MushafPageViewScreen extends StatefulWidget {
  final int initialPage;
  final int? surahNumber;

  const MushafPageViewScreen({
    super.key,
    this.initialPage = 1,
    this.surahNumber,
  });

  @override
  State<MushafPageViewScreen> createState() => _MushafPageViewScreenState();
}

class _MushafPageViewScreenState extends State<MushafPageViewScreen> {
  late PageController _pageController;
  int currentPage = 1;
  double fontSize = 26.0;
  bool showPageNumber = true;
  bool _showUI = true;

  late ContinuousAudioHandler _audioHandler;
  bool isPlaying = false;
  bool isLoading = false;
  bool isContinuousMode = false;
  int? playingSurah;
  int? playingAyah;

  final Map<String, String> reciters = {
    'Husary_128kbps': 'محمود خليل الحصري',
    'Abdul_Basit_Murattal_192kbps': 'عبد الباسط عبد الصمد (مرتل)',
    'mahmoud_ali_al_banna_32kbps': 'محمود علي البنا',
    'Muhammad_Ayyoub_128kbps': 'محمد أيوب',
    'Yasser_Ad-Dussary_128kbps': 'ياسر الدوسري',
    'Nasser_Alqatami_128kbps': 'ناصر القطامي',
    'Alafasy_128kbps': 'مشاري راشد العفاسي',
    'MaherAlMuaiqly128kbps': 'ماهر المعيقلي',
    'Saood_ash-Shuraym_64kbps': 'سعود الشريم',
    'Ghamadi_40kbps': 'سعد الغامدي',
    'Fares_Abbad_64kbps': 'فارس عباد',
    'Muhammad_Jibreel_128kbps': 'محمد جبريل',
    'AbdulSamad_64kbps_QuranExplorer.Com': 'عبد الباسط عبد الصمد (مجود)',
    'Abdurrahmaan_As-Sudais_192kbps': 'عبد الرحمن السديس',
    'Ayman_Sowaid_64kbps': 'أيمن سويد',
    'Ahmed_ibn_Ali_al_Ajamy_128kbps_ketaballah.net': 'أحمد العجمي',
    'Husary_Muallim_128kbps': 'محمود خليل الحصري (معلم)',
    'Abu_Bakr_Ash-Shaatree_128kbps': 'أبو بكر الشاطري',
    'Abdullah_Basfar_192kbps': 'عبد الله بصفر',
    'Abdullaah_3awwaad_Al-Juhaynee_128kbps': 'عبد الله الجهني',
    'Muhsin_Al_Qasim_192kbps': 'محسن القاسم',
    'Salaah_AbdulRahman_Bukhatir_128kbps': 'صلاح بو خاطر',
    'Sahl_Yassin_128kbps': 'سهل ياسين',
    'aziz_alili_128kbps': 'عزيز عليلي',
  };

  String selectedReciter = 'Alafasy_128kbps';

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
    _pageController = PageController(initialPage: currentPage - 1);
    _audioHandler = ContinuousAudioHandler();
    _loadSettings();
    _setupAudioListener();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fontSize = prefs.getDouble('mushaf_font_size') ?? 22.0;
      showPageNumber = prefs.getBool('mushaf_show_page_number') ?? true;
      selectedReciter =
          prefs.getString('selected_reciter') ?? 'Alafasy_128kbps';
    });
  }

  void _setupAudioListener() {
    _audioHandler.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = _audioHandler.isPlaying;
          isLoading =
              state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading;
          isContinuousMode = _audioHandler.isContinuousReading;
          playingSurah = _audioHandler.currentSurah;
          playingAyah = _audioHandler.currentAyah;
        });

        if (playingSurah != null && playingAyah != null) {
          final page = quran.getPageNumber(playingSurah!, playingAyah!);
          if (page != currentPage) {
            _pageController.animateToPage(
              page - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    });
  }

  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_font_size', size);
  }

  Future<void> _saveReciter(String reciter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_reciter', reciter);
  }

  void _showReciterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF1B5E20),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'اختر القارئ',
              style: TextStyle(color: Color(0xFF1B5E20)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: ListView(
            shrinkWrap: true,
            children: reciters.entries.map((entry) {
              final isSelected = selectedReciter == entry.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1B5E20).withAlpha(26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1B5E20)
                        : Colors.grey.withAlpha(51),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF1B5E20)
                          : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1B5E20)
                          : Colors.grey.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                  onTap: () {
                    setState(() => selectedReciter = entry.key);
                    _saveReciter(entry.key);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إغلاق',
              style: TextStyle(color: Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'حجم الخط',
          style: TextStyle(color: Color(0xFF1B5E20)),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(fontFamily: 'KFGQPC', fontSize: fontSize),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('صغير'),
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 22,
                        max: 34,
                        divisions: 8,
                        activeColor: const Color(0xFF1B5E20),
                        onChanged: (value) {
                          setDialogState(() => fontSize = value);
                          setState(() => fontSize = value);
                          _saveFontSize(value);
                        },
                      ),
                    ),
                    const Text('كبير'),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تم', style: TextStyle(color: Color(0xFF1B5E20))),
          ),
        ],
      ),
    );
  }

  // ✅ دالة البحث المحسّنة
  void _showSearchScreen() async {
    if (isPlaying) await _audioHandler.stopContinuousReading();

    final pageNumber = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => const MushafSearchScreen()),
    );

    if (pageNumber != null && pageNumber >= 1 && pageNumber <= 604) {
      _pageController.animateToPage(
        pageNumber - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // ✅ دالة محلية لجلب آيات الصفحة
  List<Map<String, dynamic>> _getPageVerses(int pageNumber) {
    final verses = <Map<String, dynamic>>[];

    for (int surah = 1; surah <= 114; surah++) {
      final verseCount = quran.getVerseCount(surah);
      for (int verse = 1; verse <= verseCount; verse++) {
        if (quran.getPageNumber(surah, verse) == pageNumber) {
          verses.add({
            'surah': surah,
            'verse': verse,
            'text': quran.getVerse(surah, verse),
            'surahName': quran.getSurahNameArabic(surah),
          });
        }
      }
    }

    verses.sort((a, b) {
      final surahCompare = (a['surah'] as int).compareTo(b['surah'] as int);
      if (surahCompare != 0) return surahCompare;
      return (a['verse'] as int).compareTo(b['verse'] as int);
    });

    return verses;
  }

  Future<void> _togglePlayback() async {
    if (isPlaying) {
      await _audioHandler.stopContinuousReading();
    } else {
      setState(() => isLoading = true);
      final verses = _getPageVerses(currentPage);
      if (verses.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final firstVerse = verses.first;
      final surahNumber = firstVerse['surah'] as int;
      final ayahNumber = firstVerse['verse'] as int;
      final verseCount = quran.getVerseCount(surahNumber);

      await _audioHandler.startContinuousReading(
        surahNumber: surahNumber,
        startAyah: ayahNumber,
        totalAyahs: verseCount,
        reciter: selectedReciter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
      appBar: _showUI
          ? MushafAppBar(
              currentPage: currentPage,
              onReciterTap: () async {
                if (isPlaying) await _audioHandler.stopContinuousReading();
                _showReciterDialog();
              },
              onFontSizeTap: _showFontSizeDialog,
              onGoToPageTap: _showSearchScreen, // ✅ زر البحث
            )
          : null,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _showUI = !_showUI),
          child: Stack(
            children: [
              // ✅ استخدام الصفحة المحسّنة
              PageView.builder(
                controller: _pageController,
                itemCount: 604,
                onPageChanged: (index) =>
                    setState(() => currentPage = index + 1),
                physics: const ClampingScrollPhysics(), // ✅ أداء أفضل
                itemBuilder: (context, index) => MushafPageContentOptimized(
                  pageNumber: index + 1,
                  fontSize: fontSize,
                  showPageNumber: showPageNumber && _showUI,
                  isContinuousMode: isContinuousMode,
                  playingSurah: playingSurah,
                  playingAyah: playingAyah,
                ),
              ),
              if (_showUI)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: MushafPlaybackIndicator(
                    currentPage: currentPage,
                    isPlaying: isPlaying,
                    isLoading: isLoading,
                    isContinuousMode: isContinuousMode,
                    playingSurah: playingSurah,
                    playingAyah: playingAyah,
                    selectedReciter: selectedReciter,
                    reciters: reciters,
                    onPlayTap: _togglePlayback,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
