import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class MushafPageContent extends StatelessWidget {
  final int pageNumber;
  final double fontSize;
  final bool showPageNumber;
  final bool isContinuousMode;
  final int? playingSurah;
  final int? playingAyah;

  const MushafPageContent({
    super.key,
    required this.pageNumber,
    required this.fontSize,
    required this.showPageNumber,
    required this.isContinuousMode,
    this.playingSurah,
    this.playingAyah,
  });

  static List<Map<String, dynamic>> getPageVerses(int pageNumber) {
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

    verses.sort((a, b) {
      int surahCompare = (a['surah'] as int).compareTo(b['surah'] as int);
      if (surahCompare != 0) return surahCompare;
      return (a['verse'] as int).compareTo(b['verse'] as int);
    });

    return verses;
  }

  @override
  Widget build(BuildContext context) {
    final verses = getPageVerses(pageNumber);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1B5E20).withAlpha(51),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _buildPageContent(verses),
            ),
          ),
          if (showPageNumber)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF7),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF1B5E20).withAlpha(51),
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  _toArabicNumbers(pageNumber),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageContent(List<Map<String, dynamic>> verses) {
    if (verses.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد آيات',
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

        // إضافة البسملة - تصحيح للفاتحة
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF1B5E20).withAlpha(51),
            width: 1,
          ),
          bottom: BorderSide(
            color: const Color(0xFF1B5E20).withAlpha(51),
            width: 1,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'سُورَةُ $surahName',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'Amiri',
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
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
    final surahNumber = verse['surah'] as int;

    final isCurrentlyPlaying =
        isContinuousMode &&
        playingSurah == surahNumber &&
        playingAyah == verseNumber;

    return [
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'KFGQPC',
          color: isCurrentlyPlaying
              ? const Color(0xFF1B5E20)
              : const Color(0xFF2C1810),
          fontWeight: FontWeight.bold,
          backgroundColor: isCurrentlyPlaying
              ? const Color(0xFF1B5E20).withAlpha(77)
              : Colors.transparent,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _buildVerseNumberCircle(verseNumber, isCurrentlyPlaying),
      ),
    ];
  }

  Widget _buildVerseNumberCircle(int verseNumber, [bool isPlaying = false]) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          children: [
            Image.asset("assets/images/aya_icon.png"),
            Center(
              child: Text(
                _toArabicNumbers(verseNumber),
                style: TextStyle(
                  fontSize: verseNumber > 99 ? 12 : 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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

  String _toArabicNumbers(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join();
  }
}
