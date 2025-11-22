// lib/screens/quran_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_model.dart';
import '../services/quran_service.dart';
import 'quran_search_screen.dart';
import 'surah_detail_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with AutomaticKeepAliveClientMixin {
  List<SurahInfo>? allSurahs;
  List<AyahBookmark>? bookmarks;
  ReadingProgress? lastProgress;
  Map<String, bool>? khatmahProgress;
  int khatmahPercentage = 0;
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true; // ✅ حفظ الحالة

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    // ✅ تحميل البيانات فقط عند الحاجة
    allSurahs ??= await Future.microtask(
      () => QuranService.getAllSurahs(),
    ); // 🌟 استخدام Future.microtask لضمان عدم حظر الواجهة عند تحميل جميع السور

    // 1. استخدام compute أو فصل الـ await/setState
    final bookmarksFuture = QuranService.getBookmarks();
    final progressFuture = QuranService.getLastProgress();
    final khatmahFuture = QuranService.getKhatmahProgress();

    final results = await Future.wait([
      bookmarksFuture,
      progressFuture,
      khatmahFuture,
    ]);

    final Map<String, bool> khatmah = results[2] as Map<String, bool>;
    int percentage = 0;
    if (allSurahs != null && allSurahs!.isNotEmpty) {
      percentage = await Future.microtask(
        () => (khatmah.keys.length * 100) ~/ allSurahs!.length,
      ); // 🌟 حساب النسبة في خلفية
    }

    if (mounted) {
      setState(() {
        bookmarks = results[0] as List<AyahBookmark>;
        lastProgress = results[1] as ReadingProgress?;
        khatmahProgress = khatmah;
        khatmahPercentage = percentage;
        isLoading = false;
      });
    }
  }

  // ... (باقي الكلاس)
  void _navigateToSurah(int surahNumber, {int? startAyah}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahDetailScreen(
          surahNumber: surahNumber,
          startAyahNumber: startAyah,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ مطلوب لـ AutomaticKeepAliveClientMixin

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildSurahsList(),
                  _buildBookmarksList(),
                  _buildKhatmahTab(),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'القرآن الكريم',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.manage_search, size: 32),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuranSearchScreen()),
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
      bottom: const TabBar(
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: [
          Tab(icon: Icon(Icons.menu_book), text: 'السور'),
          Tab(icon: Icon(Icons.bookmark), text: 'الإشارات'),
          Tab(icon: Icon(Icons.check_circle), text: 'الختمة'),
        ],
      ),
    );
  }

  Widget _buildSurahsList() {
    return Column(
      children: [
        if (lastProgress != null) _buildContinueReadingCard(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allSurahs!.length,
            itemBuilder: (context, index) {
              final surah = allSurahs![index];
              final isRead = khatmahProgress?['${surah.number}'] ?? false;
              return _buildSurahCard(surah, isRead);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingCard() {
    final surah = allSurahs![lastProgress!.surahNumber - 1];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSurah(
            lastProgress!.surahNumber,
            startAyah: lastProgress!.ayahNumber,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تابع القراءة',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        surah.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الآية ${lastProgress!.ayahNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahCard(SurahInfo surah, bool isRead) {
    final isMakki = surah.revelationType == 'Makkah';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.green.withAlpha(25) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isRead ? Colors.green : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSurah(surah.number),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isRead ? Icons.check_circle : Icons.stars,
                      size: 50,
                      color: isRead
                          ? Colors.green
                          : const Color(0xFF1B5E20).withAlpha(51),
                    ),
                    if (!isRead)
                      Text(
                        '${surah.number}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        surah.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        surah.englishName,
                        style: TextStyle(fontSize: 13, color: Colors.grey[900]),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isMakki
                            ? Colors.amber.withAlpha(51)
                            : Colors.green.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isMakki ? 'مكية' : 'مدنية',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMakki ? Colors.amber[900] : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surah.numberOfAyahs} آية',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksList() {
    if (bookmarks == null || bookmarks!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشارات مرجعية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks!.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks![index];
        return _buildBookmarkCard(bookmark);
      },
    );
  }

  Widget _buildBookmarkCard(AyahBookmark bookmark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSurah(
            bookmark.surahNumber,
            startAyah: bookmark.ayahNumber,
          ),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        Icons.bookmark,
                        color: Color(0xFF1B5E20),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookmark.surahName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الآية ${bookmark.ayahNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await QuranService.removeBookmark(
                          bookmark.surahNumber,
                          bookmark.ayahNumber,
                        );
                        _loadData();
                      },
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  bookmark.ayahText,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 18, height: 2),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKhatmahTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKhatmahProgressCard(),
        const SizedBox(height: 20),
        ...allSurahs!.map((surah) {
          final isRead = khatmahProgress?['${surah.number}'] ?? false;
          return _buildKhatmahSurahCard(surah, isRead);
        }),
      ],
    );
  }

  Widget _buildKhatmahProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'تقدم الختمة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 15,
            percent: khatmahPercentage / 100,
            center: Text(
              '$khatmahPercentage%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white.withAlpha(77),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 20),
          Text(
            '${khatmahProgress?.values.where((v) => v).length ?? 0} / 114 سورة',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('إعادة تعيين الختمة'),
                  content: const Text('هل تريد بدء ختمة جديدة؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('لا'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('نعم'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await QuranService.resetKhatmah();
                _loadData();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('بدء ختمة جديدة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhatmahSurahCard(SurahInfo surah, bool isRead) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFF1B5E20).withAlpha(25) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isRead ? const Color(0xFF1B5E20) : Colors.grey.shade200,
          width: isRead ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isRead,
        onChanged: (value) async {
          if (value == true) {
            await QuranService.markSurahAsRead(surah.number);
          } else {
            final khatmah = await QuranService.getKhatmahProgress();
            khatmah.remove('${surah.number}');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('quran_khatmah', json.encode(khatmah));
          }
          _loadData();
        },
        title: Text(
          surah.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${surah.numberOfAyahs} آية'),
        activeColor: const Color(0xFF1B5E20),
      ),
    );
  }
}
