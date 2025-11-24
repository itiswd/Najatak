import 'package:flutter/material.dart';

class MushafAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentPage;
  final VoidCallback onReciterTap;
  final VoidCallback onFontSizeTap;
  final VoidCallback onGoToPageTap;

  const MushafAppBar({
    super.key,
    required this.currentPage,
    required this.onReciterTap,
    required this.onFontSizeTap,
    required this.onGoToPageTap,
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
    return AppBar(
      title: Text(
        'صفحة ${_toArabicNumbers(currentPage)}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
          fontFamily: 'Amiri',
        ),
      ),
      backgroundColor: const Color(0xFFF5EFE0),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1B5E20)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person, color: Color(0xFF1B5E20)),
          onPressed: onReciterTap,
        ),
        IconButton(
          icon: const Icon(Icons.format_size, color: Color(0xFF1B5E20)),
          onPressed: onFontSizeTap,
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
          onPressed: onGoToPageTap,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
