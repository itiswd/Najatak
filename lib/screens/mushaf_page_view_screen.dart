import 'package:flutter/material.dart';
import 'package:najatak/widgets/mushaf/mushaf_app_bar.dart';
import 'package:najatak/widgets/mushaf/mushaf_page_content.dart';
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
  bool isContinuousMode = false;
  int? playingSurah;
  int? playingAyah;

  // ✅ تصحيح أسماء القراء لتطابق السيرفر
  final Map<String, String> reciters = {
    'Alafasy_128kbps': 'مشاري العفاسي',
    'Husary_128kbps': 'محمود الحصري',
    'Abdul_Basit_Murattal_192kbps': 'عبد الباسط',
    'Abdurrahmaan_As-Sudais_192kbps': 'السديس',
    'Ghamadi_40kbps': 'سعد الغامدي', // ✅ مصحح
    'MaherAlMuaiqly128kbps': 'ماهر المعيقلي', // ✅ مصحح
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
        title: const Row(
          children: [
            Icon(Icons.person, color: Color(0xFF1B5E20)),
            SizedBox(width: 12),
            Text('اختر القارئ', style: TextStyle(color: Color(0xFF1B5E20))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reciters.length,
            itemBuilder: (context, index) {
              final reciterKey = reciters.keys.elementAt(index);
              final reciterName = reciters[reciterKey]!;
              final isSelected = selectedReciter == reciterKey;

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
                  ),
                ),
                child: ListTile(
                  title: Text(
                    reciterName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF1B5E20)
                          : Colors.black87,
                    ),
                  ),
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: const Color(0xFF1B5E20),
                  ),
                  onTap: () {
                    setState(() => selectedReciter = reciterKey);
                    _saveReciter(reciterKey);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
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

  void _goToPage() {
    showDialog(
      context: context,
      builder: (context) {
        int? selectedPage;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'الانتقال إلى صفحة',
            style: TextStyle(color: Color(0xFF1B5E20)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'رقم الصفحة (1-604)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
                onChanged: (value) => selectedPage = int.tryParse(value),
              ),
              const SizedBox(height: 16),
              Text(
                'الصفحة الحالية: $currentPage',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedPage != null &&
                    selectedPage! >= 1 &&
                    selectedPage! <= 604) {
                  _pageController.jumpToPage(selectedPage! - 1);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _togglePlayback() async {
    if (isPlaying) {
      await _audioHandler.stopContinuousReading();
    } else {
      final verses = MushafPageContent.getPageVerses(currentPage);
      if (verses.isEmpty) return;

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
                if (isPlaying) {
                  await _audioHandler.stopContinuousReading();
                }
                _showReciterDialog();
              },
              onFontSizeTap: _showFontSizeDialog,
              onGoToPageTap: _goToPage,
            )
          : null,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _showUI = !_showUI),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: 604,
                onPageChanged: (index) =>
                    setState(() => currentPage = index + 1),
                itemBuilder: (context, index) => MushafPageContent(
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
