// lib/widgets/mushaf/mushaf_page_content_optimized.dart
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class MushafPageContentOptimized extends StatefulWidget {
  final int pageNumber;
  final double fontSize;
  final bool showPageNumber;
  final bool isContinuousMode;
  final int? playingSurah;
  final int? playingAyah;

  const MushafPageContentOptimized({
    super.key,
    required this.pageNumber,
    required this.fontSize,
    required this.showPageNumber,
    required this.isContinuousMode,
    this.playingSurah,
    this.playingAyah,
  });

  @override
  State<MushafPageContentOptimized> createState() =>
      _MushafPageContentOptimizedState();
}

class _MushafPageContentOptimizedState extends State<MushafPageContentOptimized>
    with AutomaticKeepAliveClientMixin {
  // ✅ Cache للآيات - يتم بناؤها مرة واحدة فقط
  List<Map<String, dynamic>>? _cachedVerses;

  @override
  bool get wantKeepAlive => true; // ✅ حفظ الحالة

  @override
  void initState() {
    super.initState();
    // ✅ تحميل الآيات مرة واحدة فقط
    _cachedVerses = _getPageVerses(widget.pageNumber);
  }

  // ✅ دالة محسّنة لجلب آيات الصفحة (تُستدعى مرة واحدة فقط)
  static List<Map<String, dynamic>> _getPageVerses(int pageNumber) {
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

    // ترتيب الآيات
    verses.sort((a, b) {
      final surahCompare = (a['surah'] as int).compareTo(b['surah'] as int);
      if (surahCompare != 0) return surahCompare;
      return (a['verse'] as int).compareTo(b['verse'] as int);
    });

    return verses;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ ضروري لـ AutomaticKeepAliveClientMixin

    final isRightPage = widget.pageNumber % 2 == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          topLeft: Radius.circular(12),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        border: Border(
          left: isRightPage
              ? const BorderSide(color: Color(0xFF1B5E20), width: 2)
              : BorderSide.none,
          right: isRightPage
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF1B5E20), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              physics: const ClampingScrollPhysics(), // ✅ أداء أفضل
              child: _buildPageContent(),
            ),
          ),
          _buildPageNumber(),
        ],
      ),
    );
  }

  // ✅ بناء محتوى الصفحة بطريقة محسّنة
  Widget _buildPageContent() {
    if (_cachedVerses == null || _cachedVerses!.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد آيات',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    String currentSurah = '';
    int currentSurahNumber = 0;
    final widgets = <Widget>[];
    final textSpans = <InlineSpan>[];

    for (final verse in _cachedVerses!) {
      final surahName = verse['surahName'] as String;
      final verseNumber = verse['verse'] as int;
      final surahNumber = verse['surah'] as int;

      // اكتشاف بداية سورة جديدة
      if (currentSurah != surahName) {
        // حفظ النص السابق
        if (textSpans.isNotEmpty) {
          widgets.add(_buildContinuousText(textSpans));
          textSpans.clear();
        }

        currentSurah = surahName;
        currentSurahNumber = surahNumber;

        // عرض اسم السورة
        if (verseNumber == 1) {
          widgets.add(_buildSurahHeader(surahName));
        }

        // البسملة
        if (verseNumber == 1 && surahNumber != 1 && surahNumber != 9) {
          widgets.add(_buildBasmala());
        }
      }

      // إضافة الآية
      textSpans.addAll(_buildVerseSpans(verse));
    }

    // حفظ آخر نص
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
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withAlpha(38),
            const Color(0xFFD4AF37).withAlpha(13),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withAlpha(102),
            width: 1.5,
          ),
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withAlpha(102),
            width: 1.5,
          ),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'سُورَةُ $surahName',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Amiri',
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBasmala() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 4),
      child: Image.asset(
        'assets/images/البسملة.png',
        height: 48,
        fit: BoxFit.contain,
      ),
    );
  }

  List<InlineSpan> _buildVerseSpans(Map<String, dynamic> verse) {
    final text = verse['text'] as String;
    final verseNumber = verse['verse'] as int;
    final surahNumber = verse['surah'] as int;

    final isCurrentlyPlaying =
        widget.isContinuousMode &&
        widget.playingSurah == surahNumber &&
        widget.playingAyah == verseNumber;

    return [
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontFamily: 'KFGQPC',
          color: isCurrentlyPlaying
              ? const Color(0xFF1B5E20)
              : const Color(0xFF2C1810),
          fontWeight: FontWeight.bold,
          height: 2.0,
          backgroundColor: isCurrentlyPlaying
              ? const Color(0xFF1B5E20).withAlpha(38)
              : Colors.transparent,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _buildVerseNumberCircle(verseNumber),
      ),
    ];
  }

  Widget _buildVerseNumberCircle(int verseNumber) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: SizedBox(
        width: widget.fontSize + 10,
        height: widget.fontSize + 10,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "assets/images/aya_icon.png",
              width: widget.fontSize + 10,
              height: widget.fontSize + 10,
              fit: BoxFit.contain,
            ),
            Text(
              _toArabicNumbers(verseNumber),
              style: TextStyle(
                fontSize: verseNumber > 99
                    ? widget.fontSize * 0.4
                    : widget.fontSize * 0.5,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinuousText(List<InlineSpan> spans) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildPageNumber() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withAlpha(25),
            const Color(0xFFD4AF37).withAlpha(13),
          ],
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Center(
        child: Text(
          _toArabicNumbers(widget.pageNumber),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
            fontFamily: 'Amiri',
            letterSpacing: 1,
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
