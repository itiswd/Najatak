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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SurahInfo> allSurahs = [];
  List<AyahBookmark> bookmarks = [];
  ReadingProgress? lastProgress;
  Map<String, bool> khatmahProgress = {};
  int khatmahPercentage = 0;
  bool isDarkMode = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    // * Fetch data
    allSurahs = QuranService.getAllSurahs();
    bookmarks = await QuranService.getBookmarks();
    lastProgress = await QuranService.getLastProgress();
    khatmahProgress = await QuranService.getKhatmahProgress();
    khatmahPercentage = await QuranService.getKhatmahPercentage();
    isDarkMode = await QuranService.getDarkMode();

    setState(() => isLoading = false);
  }

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

  void _toggleDarkMode() async {
    setState(() => isDarkMode = !isDarkMode);
    await QuranService.setDarkMode(isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F5F5);
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF303030);

    return Theme(
      data: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bgColor,
        // يمكن إضافة المزيد من تخصيصات الثيم هنا
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahsList(cardColor, textColor),
                  _buildBookmarksList(cardColor, textColor),
                  _buildJuzList(cardColor, textColor), // تمرير الألوان
                  _buildKhatmahTab(cardColor, textColor),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('القرآن الكريم'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: _toggleDarkMode,
          tooltip: isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
        ),
        IconButton(
          icon: const Icon(Icons.search),
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
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.menu_book), text: 'السور'),
          Tab(icon: Icon(Icons.bookmark), text: 'الإشارات'),
          Tab(icon: Icon(Icons.library_books), text: 'الأجزاء'),
          Tab(icon: Icon(Icons.check_circle), text: 'الختمة'),
        ],
      ),
    );
  }

  Widget _buildSurahsList(Color cardColor, Color textColor) {
    return Column(
      children: [
        if (lastProgress != null)
          _buildContinueReadingCard(cardColor, textColor),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allSurahs.length,
            itemBuilder: (context, index) {
              final surah = allSurahs[index];
              final isRead = khatmahProgress['${surah.number}'] ?? false;
              return _buildSurahCard(surah, isRead, cardColor, textColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingCard(Color cardColor, Color textColor) {
    // التأكد من أن surahNumber ضمن النطاق
    final surah = allSurahs[lastProgress!.surahNumber - 1];

    return Container(
      margin: const EdgeInsets.all(16),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الآية ${lastProgress!.ayahNumber} • الجزء ${lastProgress!.juzNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahCard(
    SurahInfo surah,
    bool isRead,
    Color cardColor,
    Color textColor,
  ) {
    final isMakki = surah.revelationType == 'Makkah'; // تم حذف السطر المكرر هنا

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? (isDarkMode
                  ? const Color(0xFF1B5E20).withAlpha(50)
                  : Colors.green.withAlpha(25))
            : cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isRead
              ? Colors.green
              : (isDarkMode ? Colors.transparent : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.transparent : Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1B5E20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        surah.englishNameTranslation,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                        border: Border.all(
                          color: isMakki
                              ? Colors.amber.withAlpha(77)
                              : Colors.green.withAlpha(77),
                        ),
                      ),
                      child: Text(
                        isMakki ? 'مكية' : 'مدنية',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMakki
                              ? (isDarkMode
                                    ? Colors.amber.shade300
                                    : Colors.amber.shade900)
                              : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${surah.numberOfAyahs} آية',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withAlpha(179),
                      ),
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

  Widget _buildBookmarksList(Color cardColor, Color textColor) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشارات مرجعية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على الآية لإضافة إشارة',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return _buildBookmarkCard(bookmark, cardColor, textColor);
      },
    );
  }

  Widget _buildBookmarkCard(
    AyahBookmark bookmark,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDarkMode ? Colors.transparent : Colors.grey.shade200,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'الآية ${bookmark.ayahNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withAlpha(179),
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
                  textDirection:
                      TextDirection.rtl, // تحديد اتجاه النص للآيات القرآنية
                  style: TextStyle(
                    fontSize: 18,
                    height: 2,
                    fontFamily: 'AmiriQuran', // افتراض أن لديك هذا الخط
                    color: textColor,
                  ),
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

  // تم دمج هذه الدالة بشكل صحيح الآن
  Widget _buildJuzList(Color cardColor, Color textColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        return _buildJuzCard(juzNumber, cardColor, textColor); // تمرير الألوان
      },
    );
  }

  // تم تعديل الدالة لتقبل الألوان وتستخدمها
  Widget _buildJuzCard(int juzNumber, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // استخدام cardColor للون الخلفية الأساسي والتدرج للوضع الفاتح
        color: cardColor,
        gradient: isDarkMode
            ? null
            : LinearGradient(
                colors: [cardColor, const Color(0xFF1B5E20).withAlpha(13)],
              ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDarkMode ? Colors.transparent : Colors.grey.shade200,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to juz view
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('قريباً: الجزء $juzNumber'),
                backgroundColor: const Color(0xFF1B5E20),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      QuranService.toArabicNumbers(juzNumber),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الجزء $juzNumber',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor, // استخدام textColor
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اقرأ الجزء كاملاً',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withAlpha(179), // استخدام textColor
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF1B5E20),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKhatmahTab(Color cardColor, Color textColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKhatmahProgressCard(cardColor, textColor),
        const SizedBox(height: 20),
        ...allSurahs.map((surah) {
          final isRead = khatmahProgress['${surah.number}'] ?? false;
          return _buildKhatmahSurahCard(surah, isRead, cardColor, textColor);
        }),
      ],
    );
  }

  Widget _buildKhatmahProgressCard(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            '${khatmahProgress.values.where((v) => v).length} / 114 سورة',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          if (khatmahPercentage == 100) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                '🎉 مبروك! أتممت الختمة 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhatmahSurahCard(
    SurahInfo surah,
    bool isRead,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFF1B5E20).withAlpha(25) : cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isRead
              ? const Color(0xFF1B5E20)
              : (isDarkMode ? Colors.transparent : Colors.grey.shade200),
          width: isRead ? 2 : 1,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: CheckboxListTile(
        value: isRead,
        onChanged: (value) async {
          if (value == true) {
            await QuranService.markSurahAsRead(surah.number);
          } else {
            // منطق إلغاء تحديد السورة من الختمة
            final khatmah = await QuranService.getKhatmahProgress();
            khatmah.remove('${surah.number}');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('quran_khatmah', json.encode(khatmah));
          }
          _loadData();
        },
        title: Text(
          surah.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          '${surah.numberOfAyahs} آية',
          style: TextStyle(color: textColor.withAlpha(179)),
        ),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isRead
                ? const Color(0xFF1B5E20)
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${surah.number}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isRead
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black54),
              ),
            ),
          ),
        ),
        activeColor: const Color(0xFF1B5E20),
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
