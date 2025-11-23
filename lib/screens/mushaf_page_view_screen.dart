// lib/screens/mushaf_page_view_screen.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

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

  // للصوت
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String selectedReciter = 'Alafasy_128kbps'; // القاري الافتراضي
  int? playingPage;

  // قائمة القراء المشهورين
  final Map<String, String> reciters = {
    'Alafasy_128kbps': 'مشاري العفاسي',
    'Husary_128kbps': 'محمود الحصري',
    'Abdul_Basit_Murattal_192kbps': 'عبد الباسط عبد الصمد',
    'Abdurrahmaan_As-Sudais_192kbps': 'عبد الرحمن السديس',
    'Sa3d_Al-Ghaamidi_128kbps': 'سعد الغامدي',
    'Ahmed_ibn_Ali_al-Ajamy_128kbps': 'أحمد العجمي',
    'Maher_AlMuaiqly_128kbps': 'ماهر المعيقلي',
  };

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
    _pageController = PageController(initialPage: currentPage - 1);
    _loadSettings();

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
          playingPage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(0xFFD4AF37).withAlpha(26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Color(0xFFD4AF37)
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
                      color: isSelected ? Color(0xFF8B6914) : Colors.black87,
                    ),
                  ),
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Color(0xFF8B6914),
                  ),
                  onTap: () {
                    setState(() {
                      selectedReciter = reciterKey;
                    });
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
        title: Text('حجم الخط', style: TextStyle(color: Color(0xFF8B6914))),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(fontSize: fontSize, fontFamily: 'KFGQPC'),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('صغير'),
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 18,
                        max: 32,
                        divisions: 14,
                        activeColor: Color(0xFF8B6914),
                        onChanged: (value) {
                          setDialogState(() => fontSize = value);
                          setState(() => fontSize = value);
                          _saveFontSize(value);
                        },
                      ),
                    ),
                    Text('كبير'),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تم', style: TextStyle(color: Color(0xFF8B6914))),
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
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFF8B6914),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _playPageAudio(int pageNumber) async {
    try {
      if (isPlaying && playingPage == pageNumber) {
        // إيقاف التشغيل
        await _audioPlayer.stop();
        setState(() {
          isPlaying = false;
          playingPage = null;
        });
        return;
      }

      setState(() {
        isPlaying = true;
        playingPage = pageNumber;
      });

      // الحصول على أول آية في الصفحة
      final verses = _getPageVerses(pageNumber);
      if (verses.isEmpty) return;

      final firstVerse = verses.first;
      final surahNumber = firstVerse['surah'] as int;
      final verseNumber = firstVerse['verse'] as int;

      final surahStr = surahNumber.toString().padLeft(3, '0');
      final verseStr = verseNumber.toString().padLeft(3, '0');

      final url =
          'https://everyayah.com/data/$selectedReciter/$surahStr$verseStr.mp3';

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      setState(() {
        isPlaying = false;
        playingPage = null;
      });
      _showSnackBar('حدث خطأ في تشغيل الصوت');
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
          title: Text(
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
                    borderSide: BorderSide(color: Color(0xFF8B6914)),
                  ),
                ),
                onChanged: (value) {
                  selectedPage = int.tryParse(value);
                },
              ),
              SizedBox(height: 16),
              Text(
                'الصفحة الحالية: $currentPage',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
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
                backgroundColor: Color(0xFF8B6914),
                foregroundColor: Colors.white,
              ),
              child: Text('انتقال'),
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
      backgroundColor: Color(0xFFF5EFE0),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: 604,
            onPageChanged: (index) {
              setState(() {
                currentPage = index + 1;
                if (isPlaying) {
                  _audioPlayer.stop();
                  isPlaying = false;
                  playingPage = null;
                }
              });
            },
            itemBuilder: (context, index) {
              return _buildMushafPage(index + 1);
            },
          ),

          // زر التشغيل العائم
          Positioned(bottom: 20, right: 20, child: _buildAudioButton()),
        ],
      ),
    );
  }

  Widget _buildAudioButton() {
    final isCurrentPagePlaying = playingPage == currentPage && isPlaying;

    return FloatingActionButton(
      onPressed: () => _playPageAudio(currentPage),
      backgroundColor: Color(0xFF8B6914),
      child: Icon(
        isCurrentPagePlaying ? Icons.stop : Icons.play_arrow,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'المصحف - صفحة $currentPage',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B6914),
        ),
      ),
      backgroundColor: Color(0xFFF5EFE0),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Color(0xFF8B6914)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.person, color: Color(0xFF8B6914)),
          onPressed: _showReciterDialog,
          tooltip: 'اختر القارئ',
        ),
        IconButton(
          icon: Icon(Icons.format_size, color: Color(0xFF8B6914)),
          onPressed: _showFontSizeDialog,
          tooltip: 'حجم الخط',
        ),
        IconButton(
          icon: Icon(Icons.search, color: Color(0xFF8B6914)),
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
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFD4AF37).withAlpha(77), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDecorativeHeader(juzNumber),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFD4AF37).withAlpha(51),
            Color(0xFFF5EFE0).withAlpha(26),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFD4AF37).withAlpha(77), width: 1),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOrnament(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'الجُزْءُ ${_toArabicNumbers(juzNumber)}',
              style: TextStyle(
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
            Color(0xFFD4AF37).withAlpha(128),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(List<Map<String, dynamic>> verses, int pageNumber) {
    if (verses.isEmpty) {
      return Center(
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
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFD4AF37).withAlpha(77), width: 1),
          bottom: BorderSide(color: Color(0xFFD4AF37).withAlpha(77), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSmallOrnament(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'سُورَةُ $surahName',
              textAlign: TextAlign.center,
              style: TextStyle(
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
            Color(0xFFD4AF37).withAlpha(128),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildBasmala() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 64, vertical: 12),
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
          color: Color(0xFF2C1810),
          fontWeight: FontWeight.bold,
          // letterSpacing: 0.3,
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
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFFD4AF37), width: 1.5),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4AF37).withAlpha(51),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD4AF37).withAlpha(26),
              ),
            ),
          ),
          Center(
            child: Text(
              _toArabicNumbers(verseNumber),
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8B6914),
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousText(List<InlineSpan> spans) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildDecorativeFooter(int pageNumber) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5EFE0).withAlpha(26),
            Color(0xFFD4AF37).withAlpha(51),
          ],
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFD4AF37).withAlpha(77), width: 1),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFD4AF37).withAlpha(128),
              width: 1,
            ),
          ),
          child: Text(
            _toArabicNumbers(pageNumber),
            style: TextStyle(
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
