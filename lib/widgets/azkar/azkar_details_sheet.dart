import 'package:flutter/material.dart';
import 'package:najatak/widgets/azkar/azkar_handle_widget.dart';
import 'package:najatak/widgets/azkar/azkar_tap_button.dart';

import '../../models/azkar_model.dart';

class AzkarDetailsSheet extends StatefulWidget {
  final Azkar azkar;
  final Color color;
  final Gradient gradient;

  const AzkarDetailsSheet({
    super.key,
    required this.azkar,
    required this.color,
    required this.gradient,
  });

  @override
  State<AzkarDetailsSheet> createState() => _AzkarDetailsSheetState();
}

class _AzkarDetailsSheetState extends State<AzkarDetailsSheet>
    with SingleTickerProviderStateMixin {
  int currentCount = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _incrementCount() {
    if (currentCount < widget.azkar.countInt) {
      _controller.forward().then((_) => _controller.reverse());
      setState(() {
        currentCount++;
      });

      if (currentCount == widget.azkar.countInt) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showCompletionDialog();
          }
        });
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: widget.gradient,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(77),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'بارك الله فيك!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'أكملت الذكر بنجاح ✨',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    currentCount = 0;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'إعادة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // بناء الويدجت الداخلية (تم دمج بعضها نظراً لصغرها)
  // ------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'تفاصيل الذكر',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            color: widget.color,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAzkarText() {
    return Text(
      widget.azkar.zekr,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF303030),
      ),
    );
  }

  Widget _buildReferenceContainer() {
    if (widget.azkar.reference == null && widget.azkar.description == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.color.withAlpha(13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.color.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.azkar.reference != null)
            Text(
              'المصدر: ${widget.azkar.reference!}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          if (widget.azkar.reference != null &&
              widget.azkar.description != null)
            const Divider(height: 16, color: Colors.grey, thickness: 0.5),
          if (widget.azkar.description != null)
            Text(
              widget.azkar.description!,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (widget.azkar.countInt <= 1) return const SizedBox.shrink();

    final progress = currentCount / widget.azkar.countInt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          backgroundColor: widget.color.withAlpha(25),
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
        ),
      ),
    );
  }

  // دالة Build الرئيسية (استدعاء الدوال المنقحة)
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AzkarHandleWidget(),
          _buildHeader(context),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAzkarText(),
                const SizedBox(height: 24),
                _buildReferenceContainer(),
                const SizedBox(height: 12),
              ],
            ),
          ),

          _buildProgressIndicator(),
          AzkarTapButton(
            currentCount: currentCount,
            totalCount: widget.azkar.countInt,
            color: widget.color,
            gradient: widget.gradient,
            scaleAnimation: _scaleAnimation,
            onTap: _incrementCount,
            onCompleted: _showCompletionDialog,
          ),
          Spacer(),
        ],
      ),
    );
  }
}
