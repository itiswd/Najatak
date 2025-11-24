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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      title: Text(
        'المصحف',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
          fontFamily: 'Cairo',
        ),
      ),
      backgroundColor: const Color(0xFFF5EFE0),
      elevation: 0,
      leading: Align(
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 6, 10, 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF1B5E20)),
          ),
        ),
      ),
      actions: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onReciterTap,
            child: const Icon(Icons.person, color: Color(0xFF1B5E20)),
          ),
        ),
        SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onFontSizeTap,
            child: Icon(Icons.format_size, color: Color(0xFF1B5E20)),
          ),
        ),
        SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onGoToPageTap,
            child: const Icon(Icons.search, color: Color(0xFF1B5E20)),
          ),
        ),
        SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
