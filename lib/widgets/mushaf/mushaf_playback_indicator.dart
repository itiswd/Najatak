import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class MushafPlaybackIndicator extends StatelessWidget {
  final int currentPage;
  final bool isPlaying;
  final bool isContinuousMode;
  final int? playingSurah;
  final int? playingAyah;
  final String selectedReciter;
  final Map<String, String> reciters;
  final VoidCallback onPlayTap;

  const MushafPlaybackIndicator({
    super.key,
    required this.currentPage,
    required this.isPlaying,
    required this.isContinuousMode,
    this.playingSurah,
    this.playingAyah,
    required this.selectedReciter,
    required this.reciters,
    required this.onPlayTap,
  });

  String _toArabicNumbers(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;
    String surahInfo = '';
    String ayahInfo = '';

    if (isContinuousMode && playingSurah != null && playingAyah != null) {
      final totalAyahs = quran.getVerseCount(playingSurah!);
      progress = playingAyah! / totalAyahs;
      surahInfo = quran.getSurahNameArabic(playingSurah!);
      ayahInfo =
          '${_toArabicNumbers(playingAyah!)} / ${_toArabicNumbers(totalAyahs)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1B5E20).withAlpha(77),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط التقدم
            if (isContinuousMode && progress > 0)
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withAlpha(32),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withAlpha(51),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1B5E20),
                              Color(0xFF2E7D32),
                              Color(0xFF43A047),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withAlpha(128),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // محتوى المؤشر
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFFF5EFE0).withAlpha(128),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // زر التشغيل
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withAlpha(77),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: onPlayTap,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // المعلومات
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isContinuousMode && surahInfo.isNotEmpty
                              ? 'سُورَةُ $surahInfo'
                              : 'صفحة ${_toArabicNumbers(currentPage)}',
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Amiri',
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              isContinuousMode
                                  ? Icons.radio_button_checked
                                  : Icons.pages,
                              size: 10,
                              color: const Color(0xFF1B5E20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isContinuousMode && ayahInfo.isNotEmpty
                                  ? 'آية $ayahInfo'
                                  : 'من ${_toArabicNumbers(604)} صفحة',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontFamily: 'Amiri',
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // معلومات القارئ
                  if (isContinuousMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B5E20).withAlpha(26),
                            const Color(0xFF1B5E20).withAlpha(51),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF1B5E20).withAlpha(102),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withAlpha(38),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B5E20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reciters[selectedReciter] ?? 'القارئ',
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
