import 'package:flutter/material.dart';

import 'azkar_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التطبيق الإسلامي',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(
              context,
              title: 'الأذكار',
              icon: Icons.favorite,
              color: const Color(0xFF2E7D32),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AzkarScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              title: 'مواقيت الصلاة',
              icon: Icons.access_time,
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AzkarScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              title: 'اتجاه القبلة',
              icon: Icons.explore,
              color: const Color(0xFFD84315),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AzkarScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              title: 'القرآن الكريم',
              icon: Icons.menu_book,
              color: const Color(0xFF6A1B9A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AzkarScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
