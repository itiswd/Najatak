import 'package:flutter/material.dart';

class AzkarTapButton extends StatelessWidget {
  final int currentCount;
  final int totalCount;
  final Color color;
  final Gradient gradient;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;
  final VoidCallback onCompleted;

  const AzkarTapButton({
    super.key,
    required this.currentCount,
    required this.totalCount,
    required this.color,
    required this.gradient,
    required this.scaleAnimation,
    required this.onTap,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = currentCount >= totalCount;
    final Color buttonColor = isCompleted ? Colors.green : color;

    return GestureDetector(
      onTap: isCompleted
          ? () {
              Navigator.pop(context); // إغلاق الـ Bottom Sheet
              onCompleted(); // استدعاء دالة عرض نافذة الإكمال
            }
          : onTap,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isCompleted
                ? const LinearGradient(
                    colors: [Colors.green, Color(0xFF1B5E20)],
                  )
                : gradient,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withAlpha(102),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isCompleted ? 'تم الإكمال! انقر للإنهاء' : 'انقر للتسبيح',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$currentCount / $totalCount',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
