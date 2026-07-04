import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo thương hiệu Focus Plan. Dùng ở Splash / Sign In / Sign Up.
class BrandLogo extends StatelessWidget {
  final double height;

  const BrandLogo({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Focus Plan',
    );
  }
}

/// Linh vật (mascot) Focus Plan — có animation nhẹ (ngó nghiêng + nhún) cho
/// sinh động. Dùng ở Home + các empty-state. API giữ nguyên `Mascot({size})`.
class Mascot extends StatefulWidget {
  final double size;

  const Mascot({super.key, this.size = 48});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final v = _t.value; // 0..1 (dao động qua lại do reverse)
        final angle = (v - 0.5) * 0.26; // ± ~7.5° ngó nghiêng
        final dy = -math.sin(v * math.pi) * 3; // nhún nhẹ trục Y
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(angle: angle, child: child),
        );
      },
      child: Image.asset(
        'assets/images/mascot.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        semanticLabel: 'Linh vật Focus Plan',
      ),
    );
  }
}
