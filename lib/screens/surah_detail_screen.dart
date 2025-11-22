import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quran_model.dart';
import '../services/audio_player_service.dart';
import '../services/quran_service.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final int? startAyahNumber;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    this.startAyahNumber,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late SurahInfo surahInfo;
  List<String> verses = [];
  Set<int> bookmarkedAyahs = {};
  bool isLoading = true;
  bool isDarkMode = false;
  double fontSize = 24.0;
  int? playingAyahNumber;
  bool showTranslation = false;
  bool showTafsir = false;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadSurahData();
    _listenToScroll();
    _listenToAudioPlayer();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    AudioPlayerService.stop();
    super.dispose();
  }

  void _listenToAudioPlayer() {
    _playerStateSubscription = AudioPlayerService.player.playerStateStream
        .listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) {
              setState(() => playingAyahNumber = null);
            }
          } else if (state.processingState == ProcessingState.ready &&
              state.playing) {
            // التأكد من تحديث الحالة عند بدء التشغيل فعلياً
            if (mounted) {
              setState(() {});
            }
          }
        });
  }

  void _listenToScroll() {
    itemPositionsListener.itemPositions.addListener(() {
      final positions = itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final firstVisible = positions
            .where((position) => position.itemTrailingEdge > 0)
            .reduce((a, b) => a.index < b.index ? a : b);

        final ayahNumber = firstVisible.index + 1;
        final juzNumber = QuranService.getJuzNumber(
          widget.surahNumber,
          ayahNumber,
        );

        QuranService.saveProgress(
          ReadingProgress(
            surahNumber: widget.surahNumber,
            ayahNumber: ayahNumber,
            juzNumber: juzNumber,
            lastRead: DateTime.now(),
          ),
        );
      }
    });
  }

  Future<void> _loadSurahData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final surahInfoResult = await Future.microtask(
      () => QuranService.getAllSurahs()[widget.surahNumber - 1],
    );
    final versesResult = await Future.microtask(
      () => QuranService.getSurahVerses(widget.surahNumber),
    );
    final isDarkModeResult = await QuranService.getDarkMode();
    final bookmarksResult = await QuranService.getBookmarks();

    if (mounted) {
      surahInfo = surahInfoResult;
      verses = versesResult;
      isDarkMode = isDarkModeResult;

      bookmarkedAyahs = bookmarksResult
          .where((b) => b.surahNumber == widget.surahNumber)
          .map((b) => b.ayahNumber)
          .toSet();

      setState(() => isLoading = false);

      if (widget.startAyahNumber != null && widget.startAyahNumber! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          itemScrollController.jumpTo(index: widget.startAyahNumber! - 1);
        });
      }
    }
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    if (bookmarkedAyahs.contains(ayahNumber)) {
      await QuranService.removeBookmark(widget.surahNumber, ayahNumber);
      setState(() => bookmarkedAyahs.remove(ayahNumber));
      _showSnackBar('تم إزالة الإشارة المرجعية', Icons.bookmark_border);
    } else {
      final bookmark = AyahBookmark(
        surahNumber: widget.surahNumber,
        ayahNumber: ayahNumber,
        surahName: surahInfo.name,
        ayahText: verses[ayahNumber - 1],
        timestamp: DateTime.now(),
      );

      await QuranService.addBookmark(bookmark);
      setState(() => bookmarkedAyahs.add(ayahNumber));
      _showSnackBar('تمت إضافة الإشارة المرجعية', Icons.bookmark);
    }
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                        min: 18,
                        max: 36,
                        divisions: 18,
                        activeColor: const Color(0xFF1B5E20),
                        onChanged: (value) {
                          setDialogState(() => fontSize = value);
                          setState(() => fontSize = value);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSurahHeader(),
                Expanded(child: _buildVersesList()),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        isLoading ? 'جاري التحميل...' : surahInfo.name,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      toolbarHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          QuranService.saveLastReadSurah(widget.surahNumber);
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.format_size),
          onPressed: _showFontSizeDialog,
          tooltip: 'حجم الخط',
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withAlpha(204),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahHeader() {
    final isMakki = surahInfo.revelationType == 'Makkah';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B5E20),
            const Color(0xFF1B5E20).withAlpha(204),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(77),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            surahInfo.name,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            surahInfo.englishName,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                isMakki ? 'مكية' : 'مدنية',
                isMakki ? Icons.mosque : Icons.brightness_3,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                '${surahInfo.numberOfAyahs} آية',
                Icons.format_list_numbered,
              ),
            ],
          ),
          if (widget.surahNumber != 1 && widget.surahNumber != 9) ...[
            const SizedBox(height: 4),
            const Divider(color: Colors.white38, thickness: 0.5),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
              child: Image.asset(
                'assets/images/البسملة.png',
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersesList() {
    final bgColor = isDarkMode
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F5F5);

    return Container(
      color: bgColor,
      child: ScrollablePositionedList.builder(
        itemCount: verses.length,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final ayahNumber = index + 1;
          final verse = verses[index];
          final isBookmarked = bookmarkedAyahs.contains(ayahNumber);
          final isPlaying = playingAyahNumber == ayahNumber;
          final juzNumber = QuranService.getJuzNumber(
            widget.surahNumber,
            ayahNumber,
          );

          return _buildAyahCard(
            ayahNumber,
            verse,
            isBookmarked,
            isPlaying,
            juzNumber,
          );
        },
      ),
    );
  }

  Widget _buildAyahCard(
    int ayahNumber,
    String verse,
    bool isBookmarked,
    bool isPlaying,
    int juzNumber,
  ) {
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF303030);

    // ألوان مريحة للعين
    Color borderColor;
    Color backgroundColor;
    List<BoxShadow> shadows;

    if (isPlaying) {
      // حالة التشغيل - لون كهرماني ناعم
      borderColor = const Color(0xFFFFB74D);
      backgroundColor = isDarkMode
          ? const Color(0xFFFFB74D).withAlpha(15)
          : const Color(0xFFFFF3E0);
      shadows = [
        BoxShadow(
          color: const Color(0xFFFFB74D).withAlpha(60),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (isBookmarked) {
      // حالة الإشارة المرجعية - أزرق هادئ
      borderColor = const Color(0xFF42A5F5);
      backgroundColor = isDarkMode
          ? const Color(0xFF42A5F5).withAlpha(20)
          : const Color(0xFFE3F2FD);
      shadows = [
        BoxShadow(
          color: const Color(0xFF42A5F5).withAlpha(40),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
      ];
    } else {
      // الحالة العادية
      borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200;
      backgroundColor = cardColor;
      shadows = [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: isPlaying ? 2.5 : (isBookmarked ? 2 : 1),
        ),
        boxShadow: shadows,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// ============================================================
            ///   رأس الآية (رقم الآية + معلومات الجزء + الإشارة)
            /// ============================================================
            Row(
              children: [
                // رقم الآية داخل صندوق أنيق
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withAlpha(70),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isPlaying
                        ? const Icon(Icons.pause, color: Colors.white, size: 20)
                        : Text(
                            QuranService.toArabicNumbers(ayahNumber),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 8),

                // العناوين
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الآية ${QuranService.toArabicNumbers(ayahNumber)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'الجزء ${QuranService.toArabicNumbers(juzNumber)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  spacing: 8,
                  children: [
                    if (isBookmarked)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _toggleBookmark(ayahNumber),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(
                              Icons.bookmark,
                              color: Color(0xFF42A5F5),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    // ─── زر التشغيل ───
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? const Color(0xFFFFB74D).withAlpha(30)
                            : const Color(0xFF1B5E20).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () async {
                          if (playingAyahNumber == ayahNumber) {
                            await AudioPlayerService.stop();
                            setState(() => playingAyahNumber = null);
                          } else {
                            try {
                              // إيقاف أي صوت قيد التشغيل أولاً
                              await AudioPlayerService.stop();
                              setState(() => playingAyahNumber = ayahNumber);

                              // بدء التشغيل
                              await AudioPlayerService.playAyah(
                                widget.surahNumber,
                                ayahNumber,
                              );
                            } catch (e) {
                              setState(() => playingAyahNumber = null);
                              _showSnackBar('تعذر تشغيل الصوت', Icons.error);
                            }
                          }
                        },
                        child: Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          color: isPlaying
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFF1B5E20),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// ============================================================
            /// نص الآية
            /// ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withAlpha(8)
                    : const Color(0xFF1B5E20).withAlpha(8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                verse,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 2.1,
                  fontFamily: 'AmiriQuran',
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// ============================================================
            /// التفسير
            /// ============================================================
            _buildTafsirSection(ayahNumber, textColor),

            const SizedBox(height: 16),

            /// ============================================================
            /// أزرار الإجراءات
            /// ============================================================
            _buildActionButtons(ayahNumber, verse),
          ],
        ),
      ),
    );
  }

  Widget _buildTafsirSection(int ayahNumber, Color textColor) {
    final tafsir = QuranService.getSimpleTafsir(widget.surahNumber, ayahNumber);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withAlpha(8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF1B5E20).withAlpha(25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1B5E20),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'التفسير الميسر',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tafsir,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 13,
              height: 1.8,
              color: textColor.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int ayahNumber, String verse) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        // ─── زر الإشارة المرجعية ───
        _buildActionButton(
          icon: bookmarkedAyahs.contains(ayahNumber)
              ? Icons.bookmark
              : Icons.bookmark_border,
          label: bookmarkedAyahs.contains(ayahNumber) ? 'محفوظة' : 'حفظ',
          color: bookmarkedAyahs.contains(ayahNumber)
              ? Colors.blue
              : Colors.grey,
          onTap: () => _toggleBookmark(ayahNumber),
        ),

        // ─── زر النسخ ───
        _buildActionButton(
          icon: Icons.copy,
          label: 'نسخ',
          color: Colors.purple,
          onTap: () async {
            final formattedText = QuranService.formatAyahForSharing(
              widget.surahNumber,
              ayahNumber,
              verse,
            );
            await Clipboard.setData(ClipboardData(text: formattedText));
            _showSnackBar('تم نسخ الآية', Icons.check_circle);
          },
        ),

        // ─── زر المشاركة ───
        _buildActionButton(
          icon: Icons.share,
          label: 'مشاركة',
          color: Colors.green,
          onTap: () async {
            final formattedText = QuranService.formatAyahForSharing(
              widget.surahNumber,
              ayahNumber,
              verse,
            );
            await SharePlus.instance.share(ShareParams(text: formattedText));
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
