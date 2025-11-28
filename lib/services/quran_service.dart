// lib/services/quran_service.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:najatak/services/quran_tafseer_service.dart'; // تأكد من صحة المسار
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_model.dart'; // تأكد من صحة المسار

class QuranService {
  static const String _bookmarksKey = 'quran_bookmarks';
  static const String _progressKey = 'quran_progress';
  static const String _lastReadKey = 'last_read_surah';
  static const String _khatmahKey = 'quran_khatmah';
  static const String _themeKey = 'quran_dark_mode';

  // ═══════════════════════════════════════════════════════════════
  // البيانات الأساسية (Basic Getters)
  // ═══════════════════════════════════════════════════════════════

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
  // إدارة الإشارات المرجعية (Bookmarks)
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
  // إدارة سجل القراءة (Reading History)
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
  // إدارة الختمات (Khatmah)
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
  // وضع الليل (Theme)
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
  // 🔍 محرك البحث المحسّن (Advanced Search)
  // ═══════════════════════════════════════════════════════════════

  /// إزالة التشكيل من النص العربي لتوحيد البحث
  static String removeArabicDiacritics(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // التشكيل
        .replaceAll('ٱ', 'ا') // ألف وصل
        .replaceAll('ٰ', 'ا') // ألف خنجرية
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }

  /// البحث المحسّن في القرآن (يدعم التشكيل وبدونه)
  static List<Map<String, dynamic>> searchQuran(
    String query, {
    int limit = 50,
  }) {
    if (query.trim().isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final normalizedQuery = removeArabicDiacritics(query.toLowerCase());

    // 🔍 البحث في أسماء السور أولاً
    final surahResults = _searchInSurahNames(normalizedQuery);
    results.addAll(surahResults);

    if (results.length >= limit) {
      return results.take(limit).toList();
    }

    // 🔍 البحث في الآيات
    final verseResults = _searchInVerses(
      normalizedQuery,
      limit - results.length,
    );
    results.addAll(verseResults);

    return results;
  }

  /// Helper: البحث في أسماء السور
  static List<Map<String, dynamic>> _searchInSurahNames(String query) {
    final results = <Map<String, dynamic>>[];

    for (int surah = 1; surah <= 114; surah++) {
      final surahName = quran.getSurahNameArabic(surah);
      final normalizedName = removeArabicDiacritics(surahName.toLowerCase());

      if (normalizedName.contains(query)) {
        // إذا وجدنا السورة، نضيف أول 5 آيات منها
        final verseCount = quran.getVerseCount(surah);
        final maxVerses = verseCount < 5 ? verseCount : 5;

        for (int ayah = 1; ayah <= maxVerses; ayah++) {
          results.add({
            'surahNumber': surah,
            'surahName': surahName,
            'ayahNumber': ayah,
            'ayahText': quran.getVerse(surah, ayah),
            'juz': quran.getJuzNumber(surah, ayah),
            'page': quran.getPageNumber(surah, ayah),
            'matchType': 'surah_name', // 🏷️ نوع المطابقة
            'relevanceScore': 100, // أعلى نقاط للسور
          });
        }

        // نكتفي بسورة واحدة إذا كان البحث عن اسم سورة وتطابق تماماً
        if (normalizedName == query) {
          break;
        }
      }
    }

    return results;
  }

  /// Helper: البحث في الآيات
  static List<Map<String, dynamic>> _searchInVerses(String query, int limit) {
    final results = <Map<String, dynamic>>[];

    for (int surah = 1; surah <= 114; surah++) {
      if (results.length >= limit) break;

      final versesCount = quran.getVerseCount(surah);

      for (int ayah = 1; ayah <= versesCount; ayah++) {
        if (results.length >= limit) break;

        final verse = quran.getVerse(surah, ayah);
        final normalizedVerse = removeArabicDiacritics(verse.toLowerCase());

        if (normalizedVerse.contains(query)) {
          // حساب درجة الصلة (كلما كان التطابق أقرب للبداية = أعلى)
          final matchIndex = normalizedVerse.indexOf(query);
          final relevanceScore = 50 - (matchIndex / 10).round();

          results.add({
            'surahNumber': surah,
            'surahName': quran.getSurahNameArabic(surah),
            'ayahNumber': ayah,
            'ayahText': verse,
            'juz': quran.getJuzNumber(surah, ayah),
            'page': quran.getPageNumber(surah, ayah),
            'matchType': 'verse_text',
            'relevanceScore': relevanceScore,
          });
        }
      }
    }

    // ترتيب النتائج حسب درجة الصلة
    results.sort(
      (a, b) =>
          (b['relevanceScore'] as int).compareTo(a['relevanceScore'] as int),
    );

    return results;
  }

  /// بحث سريع في أسماء السور فقط (يستخدم للقوائم المنسدلة مثلاً)
  static List<Map<String, dynamic>> searchSurahNames(String query) {
    if (query.trim().isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final normalizedQuery = removeArabicDiacritics(query.toLowerCase());

    for (int surah = 1; surah <= 114; surah++) {
      final surahName = quran.getSurahNameArabic(surah);
      final normalizedName = removeArabicDiacritics(surahName.toLowerCase());

      if (normalizedName.contains(normalizedQuery)) {
        results.add({
          'surahNumber': surah,
          'surahName': surahName,
          'englishName': quran.getSurahName(surah),
          'numberOfAyahs': quran.getVerseCount(surah),
          'revelationType': quran.getPlaceOfRevelation(surah),
        });
      }
    }

    return results;
  }

  /// تمييز النص المطابق في نتيجة البحث (Highlighting)
  static String highlightMatch(String text, String query) {
    final normalizedText = removeArabicDiacritics(text.toLowerCase());
    final normalizedQuery = removeArabicDiacritics(query.toLowerCase());

    final startIndex = normalizedText.indexOf(normalizedQuery);
    if (startIndex == -1) return text;

    // نحتاج لإيجاد الموضع الحقيقي في النص الأصلي (لأن النص الأصلي يحتوي على تشكيل)
    int realIndex = 0;
    int normalizedIndex = 0;

    while (normalizedIndex < startIndex && realIndex < text.length) {
      if (removeArabicDiacritics(text[realIndex].toLowerCase()) != '') {
        normalizedIndex++;
      }
      realIndex++;
    }

    // حساب طول الكلمة المطابقة في النص الأصلي
    int matchLength = 0;
    int matchedChars = 0;

    while (matchedChars < normalizedQuery.length &&
        realIndex + matchLength < text.length) {
      final char = text[realIndex + matchLength];
      if (removeArabicDiacritics(char.toLowerCase()) != '') {
        matchedChars++;
      }
      matchLength++;
    }

    final before = text.substring(0, realIndex);
    final match = text.substring(realIndex, realIndex + matchLength);
    final after = text.substring(realIndex + matchLength);

    // يمكنك تغيير التنسيق هنا حسب ما يناسب الـ UI الخاص بك
    // مثلاً استخدام رموز خاصة لتمييز النص ثم معالجتها في الـ Widget
    return '$before**$match**$after';
  }

  // ═══════════════════════════════════════════════════════════════
  // التفسير المبسط (Tafseer)
  // ═══════════════════════════════════════════════════════════════

  static String getSimpleTafsir(int surahNumber, int ayahNumber) {
    return QuranTafsirService.getTafsir(surahNumber, ayahNumber);
  }

  // ═══════════════════════════════════════════════════════════════
  // وظائف مساعدة (Helpers)
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

  // روابط الصوت
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
