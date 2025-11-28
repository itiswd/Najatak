import 'package:flutter/material.dart';

import '../services/quran_service.dart';
import 'surah_detail_screen.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  bool hasSearched = false;
  String _currentSearchMode = 'all'; // all, surah, verse

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

    // بحث غير متزامن مع debounce
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      List<Map<String, dynamic>> results;

      switch (_currentSearchMode) {
        case 'surah':
          results = QuranService.searchSurahNames(query);
          break;
        case 'verse':
          results = QuranService.searchQuran(
            query,
            limit: 50,
          ).where((r) => r['matchType'] == 'verse_text').toList();
          break;
        default:
          results = QuranService.searchQuran(query, limit: 50);
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

  void _navigateToAyah(int surahNumber, int ayahNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahDetailScreen(
          surahNumber: surahNumber,
          startAyahNumber: ayahNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSearchModeSelector(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'البحث في القرآن',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
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
          fillColor: Colors.grey.shade100,
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

  Widget _buildSearchModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildModeChip('الكل', 'all', Icons.search),
          const SizedBox(width: 8),
          _buildModeChip('السور', 'surah', Icons.book),
          const SizedBox(width: 8),
          _buildModeChip('الآيات', 'verse', Icons.format_quote),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, String mode, IconData icon) {
    final isSelected = _currentSearchMode == mode;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentSearchMode = mode);
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B5E20)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!hasSearched) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'ابحث في القرآن الكريم',
        subtitle: 'يمكنك البحث بدون تشكيل\nمثال: الفاتحه، الرحمن، بسم الله',
      );
    }

    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'لا توجد نتائج',
        subtitle: 'حاول البحث بكلمات مختلفة\nتذكر: يمكنك الكتابة بدون تشكيل',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final result = searchResults[index];

        // عرض بطاقة السورة أو الآية حسب نوع النتيجة
        if (result.containsKey('numberOfAyahs')) {
          return _buildSurahResultCard(result);
        } else {
          return _buildVerseResultCard(result);
        }
      },
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
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSurahResultCard(Map<String, dynamic> result) {
    final surahNumber = result['surahNumber'] as int;
    final surahName = result['surahName'] as String;
    final numberOfAyahs = result['numberOfAyahs'] as int;
    final revelationType = result['revelationType'] as String;
    final isMakki = revelationType == 'Makkah';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1B5E20).withAlpha(13), Colors.white],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF1B5E20).withAlpha(77),
          width: 2,
        ),
        boxShadow: [
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
          onTap: () => _navigateToAyah(surahNumber, 1),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.book, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surahName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isMakki
                                  ? Colors.amber.withAlpha(51)
                                  : Colors.green.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isMakki ? 'مكية' : 'مدنية',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isMakki
                                    ? Colors.amber[900]
                                    : Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$numberOfAyahs آية',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildVerseResultCard(Map<String, dynamic> result) {
    final surahNumber = result['surahNumber'] as int;
    final surahName = result['surahName'] as String;
    final ayahNumber = result['ayahNumber'] as int;
    final ayahText = result['ayahText'] as String;
    final juz = result['juz'] as int;
    final matchType = result['matchType'] as String;

    // تمييز النص المطابق
    final highlightedText = QuranService.highlightMatch(
      ayahText,
      _searchController.text,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: matchType == 'surah_name'
              ? const Color(0xFF1B5E20).withAlpha(102)
              : Colors.grey.shade200,
          width: matchType == 'surah_name' ? 2 : 1,
        ),
        boxShadow: [
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
          onTap: () => _navigateToAyah(surahNumber, ayahNumber),
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
                      child: Icon(
                        matchType == 'surah_name'
                            ? Icons.bookmark
                            : Icons.menu_book,
                        color: const Color(0xFF1B5E20),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surahName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الآية $ayahNumber • الجزء $juz',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (matchType == 'surah_name')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'من السورة',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
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
                  text: _buildHighlightedText(highlightedText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(String text) {
    final parts = text.split('**');
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: const TextStyle(
              fontSize: 18,
              height: 2,
              fontFamily: 'KFGQPC',
              color: Color(0xFF303030),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: parts[i],
            style: const TextStyle(
              fontSize: 18,
              height: 2,
              fontFamily: 'KFGQPC',
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.bold,
              backgroundColor: Color(0xFFE8F5E9),
            ),
          ),
        );
      }
    }

    return TextSpan(children: spans);
  }
}
