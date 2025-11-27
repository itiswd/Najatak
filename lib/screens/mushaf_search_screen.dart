// lib/screens/mushaf_search_screen.dart
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class MushafSearchScreen extends StatefulWidget {
  const MushafSearchScreen({super.key});

  @override
  State<MushafSearchScreen> createState() => _MushafSearchScreenState();
}

class _MushafSearchScreenState extends State<MushafSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  bool hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        hasSearched = false;
      });
      return;
    }

    setState(() => isSearching = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final results = <Map<String, dynamic>>[];
      final lowerQuery = query.toLowerCase().trim();

      // 🔍 البحث في أسماء السور أولاً
      for (int surah = 1; surah <= 114; surah++) {
        final surahName = quran.getSurahNameArabic(surah).toLowerCase();
        final surahNameEn = quran.getSurahName(surah).toLowerCase();

        if (surahName.contains(lowerQuery) ||
            surahNameEn.contains(lowerQuery)) {
          results.add({
            'type': 'surah',
            'surahNumber': surah,
            'surahName': quran.getSurahNameArabic(surah),
            'pageNumber': quran.getPageNumber(surah, 1),
          });
        }
      }

      // 🔍 البحث في الآيات (أول 50 نتيجة)
      if (results.length < 50) {
        for (int surah = 1; surah <= 114; surah++) {
          if (results.length >= 50) break;

          final versesCount = quran.getVerseCount(surah);
          for (int ayah = 1; ayah <= versesCount; ayah++) {
            if (results.length >= 50) break;

            final verse = quran.getVerse(surah, ayah);
            if (verse.toLowerCase().contains(lowerQuery)) {
              results.add({
                'type': 'ayah',
                'surahNumber': surah,
                'surahName': quran.getSurahNameArabic(surah),
                'ayahNumber': ayah,
                'ayahText': verse,
                'pageNumber': quran.getPageNumber(surah, ayah),
              });
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          searchResults = results;
          isSearching = false;
          hasSearched = true;
        });
      }
    });
  }

  void _navigateToPage(int pageNumber) {
    Navigator.pop(context, pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
      appBar: AppBar(
        title: const Text('البحث في المصحف'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'ابحث عن سورة أو آية...',
          prefixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5EFE0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          _performSearch(value);
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!hasSearched) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'ابحث في المصحف',
        subtitle: 'أدخل اسم سورة أو كلمة من آية',
      );
    }

    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'لا توجد نتائج',
        subtitle: 'حاول البحث بكلمات مختلفة',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final result = searchResults[index];
        if (result['type'] == 'surah') {
          return _buildSurahCard(result);
        } else {
          return _buildAyahCard(result);
        }
      },
    );
  }

  Widget _buildSurahCard(Map<String, dynamic> result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPage(result['pageNumber']),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['surahName'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'صفحة ${_toArabicNumbers(result['pageNumber'])}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAyahCard(Map<String, dynamic> result) {
    final query = _searchController.text.toLowerCase();
    final ayahText = result['ayahText'] as String;
    final lowerText = ayahText.toLowerCase();
    final startIndex = lowerText.indexOf(query);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1B5E20).withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPage(result['pageNumber']),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        Icons.format_quote,
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
                            result['surahName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الآية ${_toArabicNumbers(result['ayahNumber'])} • صفحة ${_toArabicNumbers(result['pageNumber'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF1B5E20),
                    ),
                  ],
                ),
                const Divider(height: 20),
                RichText(
                  textAlign: TextAlign.justify,
                  text: _buildHighlightedText(
                    ayahText,
                    startIndex,
                    query.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(String text, int startIndex, int queryLength) {
    if (startIndex == -1) {
      return TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 18,
          height: 2,
          fontFamily: 'KFGQPC',
          color: Color(0xFF303030),
        ),
      );
    }

    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, startIndex)),
        TextSpan(
          text: text.substring(startIndex, startIndex + queryLength),
          style: const TextStyle(
            backgroundColor: Color(0xFFE8F5E9),
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: text.substring(startIndex + queryLength)),
      ],
      style: const TextStyle(
        fontSize: 18,
        height: 2,
        fontFamily: 'KFGQPC',
        color: Color(0xFF303030),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
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
