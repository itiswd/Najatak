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

  @override
  void initState() {
    super.initState();
    _loadSurahData();
    _listenToScroll();
    _listenToAudioPlayer();
  }

  @override
  void dispose() {
    AudioPlayerService.stop();
    super.dispose();
  }

  void _listenToAudioPlayer() {
    AudioPlayerService.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() => playingAyahNumber = null);
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

        // حفظ التقدم
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
    setState(() => isLoading = true);

    final allSurahs = QuranService.getAllSurahs();
    surahInfo = allSurahs[widget.surahNumber - 1];
    verses = QuranService.getSurahVerses(widget.surahNumber);
    isDarkMode = await QuranService.getDarkMode();

    final bookmarks = await QuranService.getBookmarks();
    bookmarkedAyahs = bookmarks
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

  void _showAyahOptions(int ayahNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'الآية $ayahNumber',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: playingAyahNumber == ayahNumber
                  ? Icons.stop
                  : Icons.play_arrow,
              title: playingAyahNumber == ayahNumber
                  ? 'إيقاف الصوت'
                  : 'تشغيل الصوت',
              onTap: () async {
                Navigator.pop(context);
                if (playingAyahNumber == ayahNumber) {
                  await AudioPlayerService.stop();
                  setState(() => playingAyahNumber = null);
                } else {
                  await AudioPlayerService.playAyah(
                    widget.surahNumber,
                    ayahNumber,
                  );
                  setState(() => playingAyahNumber = ayahNumber);
                }
              },
            ),
            _buildOptionTile(
              icon: bookmarkedAyahs.contains(ayahNumber)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              title: bookmarkedAyahs.contains(ayahNumber)
                  ? 'إزالة الإشارة المرجعية'
                  : 'إضافة إشارة مرجعية',
              onTap: () {
                Navigator.pop(context);
                _toggleBookmark(ayahNumber);
              },
            ),
            _buildOptionTile(
              icon: Icons.copy,
              title: 'نسخ الآية',
              onTap: () async {
                Navigator.pop(context);
                final formattedText = QuranService.formatAyahForSharing(
                  widget.surahNumber,
                  ayahNumber,
                  verses[ayahNumber - 1],
                );
                await Clipboard.setData(ClipboardData(text: formattedText));
                _showSnackBar('تم نسخ الآية', Icons.check_circle);
              },
            ),
            _buildOptionTile(
              icon: Icons.share,
              title: 'مشاركة الآية',
              onTap: () async {
                Navigator.pop(context);
                final formattedText = QuranService.formatAyahForSharing(
                  widget.surahNumber,
                  ayahNumber,
                  verses[ayahNumber - 1],
                );
                await Share.share(formattedText);
              },
            ),
            _buildOptionTile(
              icon: Icons.info_outline,
              title: 'التفسير',
              onTap: () {
                Navigator.pop(context);
                _showTafsirDialog(ayahNumber);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTafsirDialog(int ayahNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        title: Text(
          'تفسير الآية $ayahNumber',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: SingleChildScrollView(
          child: Text(
            QuranService.getSimpleTafsir(widget.surahNumber, ayahNumber),
            style: TextStyle(
              fontSize: 16,
              height: 1.8,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20).withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1B5E20)),
      ),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      title: Text(isLoading ? 'جاري التحميل...' : surahInfo.name),
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
          const SizedBox(height: 8),
          Text(
            surahInfo.englishNameTranslation,
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
          if (widget.surahNumber != 1 && widget.surahNumber != 9) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              QuranService.getBasmala(),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontFamily: 'AmiriQuran',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF303030);

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

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isBookmarked
                  ? const Color(0xFF1B5E20).withAlpha(25)
                  : cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isPlaying
                    ? Colors.amber
                    : isBookmarked
                    ? const Color(0xFF1B5E20)
                    : Colors.grey.shade200,
                width: isPlaying ? 3 : (isBookmarked ? 2 : 1),
              ),
              boxShadow: isPlaying
                  ? [
                      BoxShadow(
                        color: Colors.amber.withAlpha(102),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAyahOptions(ayahNumber),
                onLongPress: () => _toggleBookmark(ayahNumber),
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPlaying
                                    ? [Colors.amber, Colors.orange]
                                    : [
                                        const Color(0xFF2E7D32),
                                        const Color(0xFF1B5E20),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: isPlaying
                                  ? const Icon(
                                      Icons.volume_up,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Text(
                                      QuranService.toArabicNumbers(ayahNumber),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const Spacer(),
                          if (isBookmarked)
                            const Icon(
                              Icons.bookmark,
                              color: Color(0xFF1B5E20),
                              size: 20,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            'الجزء $juzNumber',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        verse,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 2,
                          fontFamily: 'AmiriQuran',
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
