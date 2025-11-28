import 'package:flutter/material.dart';
import 'package:najatak/widgets/azkar/azkar_handle_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        fontFamily: 'Amiri',
        height: 2,
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAzkarText(),
                const SizedBox(height: 24),
                _buildReferenceContainer(),
              ],
            ),
          ),

          Spacer(),
        ],
      ),
    );
  }
}
