// lib/screens/mushaf_search_screen.dart
// ✅ مع تمرير الآية للتظليل

import 'package:flutter/material.dart';
import 'package:najatak/screens/mushaf_page_view_screen.dart';
import 'package:quran/quran.dart' as quran;

import '../services/quran_service.dart';

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
  String _currentSearchMode = 'all';

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

      List<Map<String, dynamic>> results;

      switch (_currentSearchMode) {
        case 'surah':
          results = QuranService.searchSurahNames(query);
          break;
        case 'verse':
          results = QuranService.searchQuran(
            query,
            limit: 100,
          ).where((r) => r['matchType'] == 'verse_text').toList();
          break;
        default:
          results = QuranService.searchQuran(query, limit: 100);
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

  // ✅ تحديث الدالة لتمرير الآية للتظليل
  void _navigateToPage(int surahNumber, int ayahNumber) {
    final pageNumber = quran.getPageNumber(surahNumber, ayahNumber);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MushafPageViewScreen(
          initialPage: pageNumber,
          surahNumber: surahNumber,
          highlightAyah: ayahNumber, // ✅ تمرير الآية للتظليل
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
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
      backgroundColor: Color(0xFF1B5E20),
      elevation: 0,
      title: const Text(
        'البحث في المصحف',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'ابحث عن سورة أو آية...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.search, color: Color(0xFF1B5E20)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF1B5E20)),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: const Color(0xFF1B5E20).withAlpha(77),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF5EFE0),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF5EFE0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFF1B5E20).withAlpha(77),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF1B5E20),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1B5E20),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
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
        title: 'ابحث في المصحف الشريف',
        subtitle: 'يمكنك البحث بدون تشكيل\nمثال: الفاتحة، الرحمن، بسم الله',
      );
    }

    if (isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1B5E20)),
            SizedBox(height: 16),
            Text(
              'جاري البحث...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'لا توجد نتائج',
        subtitle: 'حاول البحث بكلمات مختلفة\nيمكنك الكتابة بدون تشكيل',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final result = searchResults[index];

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
          Icon(icon, size: 80, color: const Color(0xFF1B5E20).withAlpha(102)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1B5E20).withAlpha(77),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPage(surahNumber, 1),
          borderRadius: BorderRadius.circular(20),
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
                  child: const Icon(Icons.book, color: Colors.white, size: 28),
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
                      const SizedBox(height: 6),
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
                                fontSize: 11,
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
                  size: 18,
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
    final pageNumber = result['page'] as int;

    final highlightedText = QuranService.highlightMatch(
      ayahText,
      _searchController.text,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1B5E20).withAlpha(51),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPage(surahNumber, ayahNumber),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: Color(0xFF1B5E20),
                        size: 22,
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الآية $ayahNumber • صفحة $pageNumber',
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
              color: Color(0xFF2C1810),
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
