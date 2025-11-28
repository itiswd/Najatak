// lib/widgets/mushaf/mushaf_page_content.dart
// ✅ مع دعم التظليل للآيات

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class MushafPageContent extends StatelessWidget {
  final int pageNumber;
  final double fontSize;
  final bool showPageNumber;
  final bool isContinuousMode;
  final int? playingSurah;
  final int? playingAyah;
  final int? highlightedSurah; // ✅ الآية المراد تظليلها
  final int? highlightedAyah;

  const MushafPageContent({
    super.key,
    required this.pageNumber,
    required this.fontSize,
    required this.showPageNumber,
    required this.isContinuousMode,
    this.playingSurah,
    this.playingAyah,
    this.highlightedSurah,
    this.highlightedAyah,
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
    final isRightPage = pageNumber % 2 == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          topLeft: Radius.circular(12),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        border: Border(
          left: isRightPage
              ? BorderSide(color: Color(0xFF1B5E20), width: 2)
              : BorderSide.none,
          right: isRightPage
              ? BorderSide.none
              : BorderSide(color: Color(0xFF1B5E20), width: 2),
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
              child: _buildPageContent(verses),
            ),
          ),
          _buildPageNumber(),
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
    int currentSurahNumber = 0;
    List<InlineSpan> textSpans = [];
    List<Widget> widgets = [];
    bool isFirstVerseOfNewSurah = false;

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
        currentSurahNumber = surahNumber;
        isFirstVerseOfNewSurah = true;

        if (verseNumber == 1) {
          widgets.add(_buildSurahHeader(surahName));
        }

        if (verseNumber == 1 && surahNumber != 1 && surahNumber != 9) {
          widgets.add(_buildBasmala());
        }
      } else {
        isFirstVerseOfNewSurah = false;
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
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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

    // ✅ التحقق من الآية قيد التشغيل
    final isCurrentlyPlaying =
        isContinuousMode &&
        playingSurah == surahNumber &&
        playingAyah == verseNumber;

    // ✅ التحقق من الآية المظللة (من البحث)
    final isHighlighted =
        !isContinuousMode &&
        highlightedSurah == surahNumber &&
        highlightedAyah == verseNumber;

    // ✅ اختيار اللون والخلفية المناسبة
    Color textColor;
    Color backgroundColor;

    if (isCurrentlyPlaying) {
      // الآية قيد التشغيل - لون أخضر
      textColor = const Color(0xFF1B5E20);
      backgroundColor = const Color(0xFF1B5E20).withAlpha(38);
    } else if (isHighlighted) {
      // الآية المظللة من البحث - لون برتقالي/ذهبي
      textColor = const Color(0xFFD84315);
      backgroundColor = const Color(0xFFFFE0B2);
    } else {
      // آية عادية
      textColor = const Color(0xFF2C1810);
      backgroundColor = Colors.transparent;
    }

    return [
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'KFGQPC',
          color: textColor,
          fontWeight: FontWeight.bold,
          height: 2.0,
          backgroundColor: backgroundColor,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _buildVerseNumberCircle(
          verseNumber,
          isCurrentlyPlaying || isHighlighted,
        ),
      ),
    ];
  }

  Widget _buildVerseNumberCircle(int verseNumber, [bool isSpecial = false]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: SizedBox(
        width: fontSize + 10,
        height: fontSize + 10,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✅ إضافة توهج للآية المميزة
            if (isSpecial)
              Container(
                width: fontSize + 10,
                height: fontSize + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD84315).withAlpha(128),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            Image.asset(
              "assets/images/aya_icon.png",
              width: fontSize + 10,
              height: fontSize + 10,
              fit: BoxFit.contain,
            ),
            Text(
              _toArabicNumbers(verseNumber),
              style: TextStyle(
                fontSize: verseNumber > 99 ? fontSize * 0.4 : fontSize * 0.5,
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
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withAlpha(128),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Center(
        child: Text(
          _toArabicNumbers(pageNumber),
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
