// lib/screens/mushaf_page_view_screen.dart
import 'package:flutter/material.dart';
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
  double fontSize = 20.0;
  bool showPageNumber = true;

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
    _pageController = PageController(initialPage: currentPage - 1);
    _loadSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fontSize = prefs.getDouble('mushaf_font_size') ?? 20.0;
      showPageNumber = prefs.getBool('mushaf_show_page_number') ?? true;
    });
  }

  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_font_size', size);
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حجم الخط'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontFamily: 'AmiriQuran',
                  ),
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
                        min: 16,
                        max: 28,
                        divisions: 12,
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
            child: const Text('تم'),
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
          title: const Text('الانتقال إلى صفحة'),
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
                ),
                onChanged: (value) {
                  selectedPage = int.tryParse(value);
                },
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الرجاء إدخال رقم صفحة صحيح (1-604)'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6914),
              ),
              child: const Text(
                'انتقال',
                style: TextStyle(color: Colors.white),
              ),
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: 604,
        onPageChanged: (index) {
          setState(() {
            currentPage = index + 1;
          });
        },
        itemBuilder: (context, index) {
          return _buildMushafPage(index + 1);
        },
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
        borderRadius: BorderRadius.circular(8),
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
          // الهيدر المزخرف
          _buildDecorativeHeader(juzNumber),

          // الآيات
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildPageContent(verses, pageNumber),
            ),
          ),

          // الفوتر (رقم الصفحة)
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'AmiriQuran',
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

      // إضافة عنوان السورة عند التغيير
      if (currentSurah != surahName) {
        // إضافة النص المتراكم قبل العنوان الجديد
        if (textSpans.isNotEmpty) {
          widgets.add(_buildContinuousText(textSpans));
          textSpans = [];
        }

        currentSurah = surahName;
        widgets.add(_buildSurahHeader(surahName));

        // البسملة (ما عدا التوبة والفاتحة في بداية الصفحة)
        if (verseNumber == 1 && surahNumber != 1 && surahNumber != 9) {
          widgets.add(_buildBasmala());
        }
      }

      // إضافة الآية إلى النص المتصل
      textSpans.addAll(_buildVerseSpans(verse));
    }

    // إضافة النص المتبقي
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
                fontSize: 18,
                fontFamily: 'AmiriQuran',
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
      padding: const EdgeInsets.symmetric(horizontal: 64),
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
          height: 2.0,
          fontFamily: 'AmiriQuran',
          color: const Color(0xFF2C1810),
          fontWeight: FontWeight.w600,
        ),
      ),
      const TextSpan(text: ' '),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _buildVerseNumberCircle(verseNumber),
      ),
      const TextSpan(text: ' '),
    ];
  }

  Widget _buildVerseNumberCircle(int verseNumber) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
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
      child: Stack(
        children: [
          // الزخرفة الداخلية
          Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withAlpha(26),
              ),
            ),
          ),
          // الرقم
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: Text(
                _toArabicNumbers(verseNumber),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B6914),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  height: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
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
