// lib/screens/mushaf_page_view_screen.dart - مع القراءة المستمرة
import 'package:flutter/material.dart';
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
  double fontSize = 22.0;
  bool showPageNumber = true;

  // معالج الصوت المستمر
  late ContinuousAudioHandler _audioHandler;
  bool isPlaying = false;
  bool isContinuousMode = false;
  int? playingSurah;
  int? playingAyah;

  // القراء المتاحون
  final Map<String, String> reciters = {
    'Alafasy_128kbps': 'مشاري العفاسي',
    'Husary_128kbps': 'محمود الحصري',
    'Abdul_Basit_Murattal_192kbps': 'عبد الباسط',
    'Abdurrahmaan_As-Sudais_192kbps': 'السديس',
    'Sa3d_Al-Ghaamidi_128kbps': 'سعد الغامدي',
    'Ahmed_ibn_Ali_al-Ajamy_128kbps': 'أحمد العجمي',
    'Maher_AlMuaiqly_128kbps': 'ماهر المعيقلي',
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

        // الانتقال تلقائياً للصفحة التي تحتوي على الآية الحالية
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
            Icon(Icons.person, color: Color(0xFF8B6914)),
            SizedBox(width: 12),
            Text('اختر القارئ', style: TextStyle(color: Color(0xFF8B6914))),
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
                      ? const Color(0xFFD4AF37).withAlpha(26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
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
                          ? const Color(0xFF8B6914)
                          : Colors.black87,
                    ),
                  ),
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: const Color(0xFF8B6914),
                  ),
                  onTap: () {
                    setState(() => selectedReciter = reciterKey);
                    _saveReciter(reciterKey);
                    Navigator.pop(context);
                    _showSnackBar('تم اختيار $reciterName');
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
          style: TextStyle(color: Color(0xFF8B6914)),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(fontFamily: 'KFGQPC'),
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
                        min: 18,
                        max: 32,
                        divisions: 14,
                        activeColor: const Color(0xFF8B6914),
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
            child: const Text('تم', style: TextStyle(color: Color(0xFF8B6914))),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF8B6914),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _togglePlayback() async {
    if (isPlaying) {
      // إيقاف التشغيل
      await _audioHandler.stopContinuousReading();
      _showSnackBar('تم إيقاف القراءة');
    } else {
      // بدء التشغيل من الصفحة الحالية
      final verses = _getPageVerses(currentPage);
      if (verses.isEmpty) {
        _showSnackBar('لا توجد آيات في هذه الصفحة');
        return;
      }

      final firstVerse = verses.first;
      final surahNumber = firstVerse['surah'] as int;
      final ayahNumber = firstVerse['verse'] as int;
      final verseCount = quran.getVerseCount(surahNumber);

      final success = await _audioHandler.startContinuousReading(
        surahNumber: surahNumber,
        startAyah: ayahNumber,
        totalAyahs: verseCount,
        reciter: selectedReciter,
      );

      if (success) {
        _showSnackBar('بدأت القراءة المستمرة');
      } else {
        _showSnackBar('حدث خطأ في بدء القراءة');
      }
    }
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
            style: TextStyle(color: Color(0xFF8B6914)),
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
                    borderSide: const BorderSide(color: Color(0xFF8B6914)),
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
                } else {
                  _showSnackBar('الرجاء إدخال رقم صفحة صحيح (1-604)');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6914),
                foregroundColor: Colors.white,
              ),
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getPageVerses(int pageNumber) {
    List<Map<String, dynamic>> verses = [];

    for (int surah = 1; surah <= 114; surah++) {
      int verseCount = quran.getVerseCount(surah);
      for (int verse = 1; verse <= verseCount; verse++) {
        int versePage = quran.getPageNumber(surah, verse);
        if (versePage == pageNumber) {
          verses.add({
            'surah': surah,
            'verse': verse,
            'text': quran.getVerse(surah, verse),
            'surahName': quran.getSurahNameArabic(surah),
          });
        }
      }
    }

    return verses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: 604,
            onPageChanged: (index) {
              setState(() => currentPage = index + 1);
            },
            itemBuilder: (context, index) {
              return _buildMushafPage(index + 1);
            },
          ),

          // شريط معلومات التشغيل
          if (isContinuousMode) _buildPlaybackBar(),

          // أزرار التحكم العائمة
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر التشغيل/الإيقاف
                FloatingActionButton(
                  heroTag: 'play_button',
                  onPressed: _togglePlayback,
                  backgroundColor: const Color(0xFF8B6914),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                // زر القارئ (يظهر عند التشغيل)
                if (isContinuousMode)
                  FloatingActionButton(
                    heroTag: 'reciter_button',
                    mini: true,
                    onPressed: _showReciterDialog,
                    backgroundColor: const Color(0xFFD4AF37),
                    child: const Icon(Icons.person, size: 20),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B6914), Color(0xFFD4AF37)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'القراءة المستمرة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (playingSurah != null && playingAyah != null)
                      Text(
                        'سورة ${quran.getSurahNameArabic(playingSurah!)} - آية $playingAyah',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                reciters[selectedReciter] ?? 'القارئ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'المصحف - صفحة $currentPage',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B6914),
        ),
      ),
      backgroundColor: const Color(0xFFF5EFE0),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8B6914)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person, color: Color(0xFF8B6914)),
          onPressed: _showReciterDialog,
          tooltip: 'اختر القارئ',
        ),
        IconButton(
          icon: const Icon(Icons.format_size, color: Color(0xFF8B6914)),
          onPressed: _showFontSizeDialog,
          tooltip: 'حجم الخط',
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF8B6914)),
          onPressed: _goToPage,
          tooltip: 'الانتقال لصفحة',
        ),
      ],
    );
  }

  Widget _buildMushafPage(int pageNumber) {
    final verses = _getPageVerses(pageNumber);
    final juzNumber = verses.isNotEmpty
        ? quran.getJuzNumber(verses.first['surah'], verses.first['verse'])
        : 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withAlpha(77),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDecorativeHeader(juzNumber),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildPageContent(verses, pageNumber),
            ),
          ),
          if (showPageNumber) _buildDecorativeFooter(pageNumber),
        ],
      ),
    );
  }

  Widget _buildDecorativeHeader(int juzNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withAlpha(51),
            const Color(0xFFF5EFE0).withAlpha(26),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withAlpha(77),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOrnament(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'الجُزْءُ ${_toArabicNumbers(juzNumber)}',
              style: const TextStyle(
                color: Color(0xFF8B6914),
                fontSize: 17,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
          ),
          _buildOrnament(),
        ],
      ),
    );
  }

  Widget _buildOrnament() {
    return Container(
      width: 40,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFD4AF37).withAlpha(128),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(List<Map<String, dynamic>> verses, int pageNumber) {
    if (verses.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد آيات في هذه الصفحة',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    String currentSurah = '';
    List<InlineSpan> textSpans = [];
    List<Widget> widgets = [];

    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];
      final surahName = verse['surahName'] as String;
      final verseNumber = verse['verse'] as int;
      final surahNumber = verse['surah'] as int;

      if (currentSurah != surahName) {
        if (textSpans.isNotEmpty) {
          widgets.add(_buildContinuousText(textSpans));
          textSpans = [];
        }

        currentSurah = surahName;
        widgets.add(_buildSurahHeader(surahName));

        if (verseNumber == 1 && surahNumber != 1 && surahNumber != 9) {
          widgets.add(_buildBasmala());
        }
      }

      textSpans.addAll(_buildVerseSpans(verse));
    }

    if (textSpans.isNotEmpty) {
      widgets.add(_buildContinuousText(textSpans));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildSurahHeader(String surahName) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withAlpha(77),
            width: 1,
          ),
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withAlpha(77),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSmallOrnament(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'سُورَةُ $surahName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontFamily: 'Amiri',
                color: Color(0xFF8B6914),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSmallOrnament(),
        ],
      ),
    );
  }

  Widget _buildSmallOrnament() {
    return Container(
      width: 30,
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFD4AF37).withAlpha(128),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildBasmala() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 12),
      child: Image.asset('assets/images/البسملة.png'),
    );
  }

  List<InlineSpan> _buildVerseSpans(Map<String, dynamic> verse) {
    final text = verse['text'] as String;
    final verseNumber = verse['verse'] as int;

    return [
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'KFGQPC',
          color: const Color(0xFF2C1810),
          fontWeight: FontWeight.bold,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _buildVerseNumberCircle(verseNumber),
      ),
    ];
  }

  Widget _buildVerseNumberCircle(int verseNumber) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _toArabicNumbers(verseNumber),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8B6914),
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContinuousText(List<InlineSpan> spans) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildDecorativeFooter(int pageNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF5EFE0).withAlpha(26),
            const Color(0xFFD4AF37).withAlpha(51),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withAlpha(77),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD4AF37).withAlpha(128),
              width: 1,
            ),
          ),
          child: Text(
            _toArabicNumbers(pageNumber),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B6914),
              fontFamily: 'Amiri',
            ),
          ),
        ),
      ),
    );
  }

  String _toArabicNumbers(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join();
  }
}
