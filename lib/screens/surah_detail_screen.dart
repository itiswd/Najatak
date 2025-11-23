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
  bool isPlayingContinuous = false;
  int? continuousPlayEndAyah;
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
            if (mounted && isPlayingContinuous) {
              _playNextAyah();
            } else if (mounted) {
              setState(() => playingAyahNumber = null);
            }
          }
        });
  }

  void _listenToScroll() {
    itemPositionsListener.itemPositions.addListener(() {
      final positions = itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final visibleAyahs = positions
            .where(
              (position) => position.itemTrailingEdge > 0 && position.index > 0,
            )
            .toList();

        if (visibleAyahs.isEmpty) return;

        final firstVisible = visibleAyahs.reduce(
          (a, b) => a.index < b.index ? a : b,
        );
        final ayahNumber = firstVisible.index;

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
          itemScrollController.jumpTo(index: widget.startAyahNumber!);
        });
      }
    }
  }

  Future<void> _playNextAyah() async {
    if (!mounted) return;

    int nextAyah = (playingAyahNumber ?? 0) + 1;

    if (nextAyah > verses.length) {
      setState(() {
        isPlayingContinuous = false;
        playingAyahNumber = null;
      });
      return;
    }

    if (continuousPlayEndAyah != null && nextAyah > continuousPlayEndAyah!) {
      setState(() {
        isPlayingContinuous = false;
        playingAyahNumber = null;
      });
      return;
    }

    setState(() => playingAyahNumber = nextAyah);

    await itemScrollController.scrollTo(
      index: nextAyah,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    try {
      await AudioPlayerService.playAyah(widget.surahNumber, nextAyah);
    } catch (e) {
      if (mounted) {
        setState(() {
          isPlayingContinuous = false;
          playingAyahNumber = null;
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

  void _showPlaybackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر طريقة التشغيل'),
        content: const Text('كم عدد الآيات التي تريد قراءتها؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startContinuousPlayback(null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            child: const Text('كل السورة'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startContinuousPlayback(playingAyahNumber! + 5);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('5 آيات'),
          ),
        ],
      ),
    );
  }

  Future<void> _startContinuousPlayback(int? endAyah) async {
    final startAyah = playingAyahNumber ?? 1;

    setState(() {
      isPlayingContinuous = true;
      continuousPlayEndAyah = endAyah ?? verses.length;
      playingAyahNumber = startAyah;
    });

    try {
      await AudioPlayerService.playAyah(widget.surahNumber, startAyah);
    } catch (e) {
      if (mounted) {
        setState(() {
          isPlayingContinuous = false;
          playingAyahNumber = null;
        });
        _showSnackBar('خطأ في التشغيل', Icons.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildVersesList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        isLoading ? 'جاري التحميل...' : surahInfo.name,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          QuranService.saveLastReadSurah(widget.surahNumber);
          Navigator.pop(context);
        },
      ),
      actions: [
        if (isPlayingContinuous)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${playingAyahNumber ?? 0}/${continuousPlayEndAyah ?? verses.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
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
        itemCount: verses.length + 1,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        padding: const EdgeInsets.only(bottom: 16),
        itemBuilder: (context, index) {
          if (index == 0) return _buildSurahHeader();

          final ayahNumber = index;
          final verse = verses[index - 1];
          final isBookmarked = bookmarkedAyahs.contains(ayahNumber);
          final isPlaying = playingAyahNumber == ayahNumber;

          return _buildAyahCard(ayahNumber, verse, isBookmarked, isPlaying);
        },
      ),
    );
  }

  Widget _buildAyahCard(
    int ayahNumber,
    String verse,
    bool isBookmarked,
    bool isPlaying,
  ) {
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF303030);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPlaying
            ? const Color(0xFFFFB74D).withAlpha(25)
            : (isBookmarked
                  ? const Color(0xFF42A5F5).withAlpha(15)
                  : cardColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? const Color(0xFFFFB74D)
              : (isBookmarked ? const Color(0xFF42A5F5) : Colors.grey.shade200),
          width: isPlaying ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Center(
                    child: Text(
                      QuranService.toArabicNumbers(ayahNumber),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الآية ${QuranService.toArabicNumbers(ayahNumber)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'الجزء ${QuranService.toArabicNumbers(QuranService.getJuzNumber(widget.surahNumber, ayahNumber))}',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBookmarked)
                  Icon(Icons.bookmark, color: Colors.blue.shade400, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              verse,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                height: 2.0,
                fontFamily: 'KFGQPC',
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: 'حفظ',
                  onTap: () => _toggleBookmark(ayahNumber),
                  color: isBookmarked ? Colors.blue : Colors.grey,
                ),
                _buildActionButton(
                  icon: isPlaying ? Icons.stop : Icons.play_arrow,
                  label: isPlaying ? 'إيقاف' : 'تشغيل',
                  onTap: () async {
                    if (isPlaying) {
                      await AudioPlayerService.stop();
                      setState(() {
                        isPlayingContinuous = false;
                        playingAyahNumber = null;
                      });
                    } else {
                      setState(() => playingAyahNumber = ayahNumber);
                      _showPlaybackDialog();
                    }
                  },
                  color: isPlaying ? Colors.orange : const Color(0xFF1B5E20),
                ),
                _buildActionButton(
                  icon: Icons.copy,
                  label: 'نسخ',
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: QuranService.formatAyahForSharing(
                          widget.surahNumber,
                          ayahNumber,
                          verse,
                        ),
                      ),
                    );
                    _showSnackBar('تم نسخ الآية', Icons.check_circle);
                  },
                  color: Colors.purple,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'مشاركة',
                  onTap: () async {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: QuranService.formatAyahForSharing(
                          widget.surahNumber,
                          ayahNumber,
                          verse,
                        ),
                      ),
                    );
                  },
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
