import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_model.dart';

class QuranService {
  static const String _bookmarksKey = 'quran_bookmarks';
  static const String _progressKey = 'quran_progress';
  static const String _lastReadKey = 'last_read_surah';
  static const String _khatmahKey = 'quran_khatmah';
  static const String _themeKey = 'quran_dark_mode';

  // الحصول على جميع السور
  static List<SurahInfo> getAllSurahs() {
    return List.generate(114, (index) {
      final surahNumber = index + 1;
      return SurahInfo(
        number: surahNumber,
        name: quran.getSurahNameArabic(surahNumber),
        englishName: quran.getSurahName(surahNumber),
        englishNameTranslation: quran.getSurahNameEnglish(surahNumber),
        revelationType: quran.getPlaceOfRevelation(surahNumber),
        numberOfAyahs: quran.getVerseCount(surahNumber),
      );
    });
  }

  // الحصول على آية محددة
  static String getAyah(
    int surahNumber,
    int ayahNumber, {
    bool withBasmala = false,
  }) {
    try {
      String ayah = quran.getVerse(surahNumber, ayahNumber);

      if (withBasmala &&
          ayahNumber == 1 &&
          surahNumber != 1 &&
          surahNumber != 9) {
        ayah = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ﴿١﴾\n\n$ayah';
      }

      return ayah;
    } catch (e) {
      debugPrint('خطأ في الحصول على الآية: $e');
      return '';
    }
  }

  // الحصول على كل آيات سورة
  static List<String> getSurahVerses(int surahNumber) {
    final versesCount = quran.getVerseCount(surahNumber);
    return List.generate(
      versesCount,
      (index) => getAyah(surahNumber, index + 1),
    );
  }

  // الحصول على رقم الجزء
  static int getJuzNumber(int surahNumber, int ayahNumber) {
    return quran.getJuzNumber(surahNumber, ayahNumber);
  }

  // الحصول على رقم الصفحة
  static int getPageNumber(int surahNumber, int ayahNumber) {
    return quran.getPageNumber(surahNumber, ayahNumber);
  }

  // ═══════════════════════════════════════════════════════════════
  // إدارة الإشارات المرجعية
  // ═══════════════════════════════════════════════════════════════

  static Future<List<AyahBookmark>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey);

      if (bookmarksJson == null) return [];

      final List<dynamic> decoded = json.decode(bookmarksJson);
      return decoded
          .map((item) => AyahBookmark.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('خطأ في تحميل الإشارات: $e');
      return [];
    }
  }

  static Future<bool> addBookmark(AyahBookmark bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarks();

      final exists = bookmarks.any(
        (b) =>
            b.surahNumber == bookmark.surahNumber &&
            b.ayahNumber == bookmark.ayahNumber,
      );

      if (exists) return false;

      bookmarks.add(bookmark);
      final encoded = json.encode(bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString(_bookmarksKey, encoded);

      return true;
    } catch (e) {
      debugPrint('خطأ في إضافة الإشارة: $e');
      return false;
    }
  }

  static Future<bool> removeBookmark(int surahNumber, int ayahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarks();

      bookmarks.removeWhere(
        (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
      );

      final encoded = json.encode(bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString(_bookmarksKey, encoded);

      return true;
    } catch (e) {
      debugPrint('خطأ في حذف الإشارة: $e');
      return false;
    }
  }

  static Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any(
      (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // إدارة سجل القراءة
  // ═══════════════════════════════════════════════════════════════

  static Future<ReadingProgress?> getLastProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);

      if (progressJson == null) return null;

      return ReadingProgress.fromJson(
        json.decode(progressJson) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('خطأ في تحميل السجل: $e');
      return null;
    }
  }

  static Future<void> saveProgress(ReadingProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(progress.toJson());
      await prefs.setString(_progressKey, encoded);
    } catch (e) {
      debugPrint('خطأ في حفظ السجل: $e');
    }
  }

  static Future<void> saveLastReadSurah(int surahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastReadKey, surahNumber);
    } catch (e) {
      debugPrint('خطأ في حفظ آخر سورة: $e');
    }
  }

  static Future<int?> getLastReadSurah() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastReadKey);
    } catch (e) {
      debugPrint('خطأ في تحميل آخر سورة: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // إدارة الختمات
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, bool>> getKhatmahProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final khatmahJson = prefs.getString(_khatmahKey);

      if (khatmahJson == null) return {};

      return Map<String, bool>.from(json.decode(khatmahJson));
    } catch (e) {
      debugPrint('خطأ في تحميل الختمة: $e');
      return {};
    }
  }

  static Future<void> markSurahAsRead(int surahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final khatmah = await getKhatmahProgress();

      khatmah['$surahNumber'] = true;
      await prefs.setString(_khatmahKey, json.encode(khatmah));
    } catch (e) {
      debugPrint('خطأ في حفظ الختمة: $e');
    }
  }

  static Future<void> resetKhatmah() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_khatmahKey);
    } catch (e) {
      debugPrint('خطأ في إعادة تعيين الختمة: $e');
    }
  }

  static Future<int> getKhatmahPercentage() async {
    final khatmah = await getKhatmahProgress();
    final completedCount = khatmah.values.where((v) => v).length;
    return ((completedCount / 114) * 100).round();
  }

  // ═══════════════════════════════════════════════════════════════
  // وضع الليل
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_themeKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, value);
    } catch (e) {
      debugPrint('خطأ في حفظ الوضع: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // بحث في القرآن
  // ═══════════════════════════════════════════════════════════════

  static List<Map<String, dynamic>> searchQuran(String query) {
    if (query.trim().isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase().trim();

    for (int surah = 1; surah <= 114; surah++) {
      final versesCount = quran.getVerseCount(surah);

      for (int ayah = 1; ayah <= versesCount; ayah++) {
        final verse = getAyah(surah, ayah);

        if (verse.toLowerCase().contains(lowerQuery)) {
          results.add({
            'surahNumber': surah,
            'surahName': quran.getSurahNameArabic(surah),
            'ayahNumber': ayah,
            'ayahText': verse,
            'juz': getJuzNumber(surah, ayah),
            'page': getPageNumber(surah, ayah),
          });

          if (results.length >= 50) return results;
        }
      }
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════════
  // التفسير المبسط
  // ═══════════════════════════════════════════════════════════════

  static String getSimpleTafsir(int surahNumber, int ayahNumber) {
    // يمكن تحسين هذا بإضافة API للتفسير
    // هنا نموذج بسيط
    return 'التفسير المبسط للآية $ayahNumber من سورة ${quran.getSurahNameArabic(surahNumber)}.\n\nيمكن إضافة تفسير من API خارجي أو قاعدة بيانات محلية.';
  }

  // ═══════════════════════════════════════════════════════════════
  // وظائف مساعدة
  // ═══════════════════════════════════════════════════════════════

  static String getBasmala() {
    return 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
  }

  static String formatSurahInfo(SurahInfo surah) {
    final type = surah.revelationType == 'Makkah' ? 'مكية' : 'مدنية';
    return '${surah.name} • $type • ${surah.numberOfAyahs} آية';
  }

  static String toArabicNumbers(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join();
  }

  // روابط الصوت (مثال من موقع everyayah.com)
  static String getAudioUrl(
    int surahNumber,
    int ayahNumber, {
    String reciter = 'Alafasy_128kbps',
  }) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final ayahStr = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciter/$surahStr$ayahStr.mp3';
  }

  // تنسيق الآية للمشاركة
  static String formatAyahForSharing(
    int surahNumber,
    int ayahNumber,
    String ayahText,
  ) {
    final surahName = quran.getSurahNameArabic(surahNumber);
    return '''
$ayahText

﴿ سورة $surahName - الآية $ayahNumber ﴾

تطبيق نَجَاتَك 🌙
    '''
        .trim();
  }
}
