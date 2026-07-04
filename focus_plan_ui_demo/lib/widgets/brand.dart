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

/// Linh vật (mascot) Focus Plan — có animation nhẹ (vẫy tay + ngó nghiêng +
/// nhún) cho sinh động. Ghép 2 layer: thân (mascot_body) + 1 tay xoay quanh
/// khớp vai (mascot_arm). API giữ nguyên `Mascot({size})` cho mọi call-site.
class Mascot extends StatefulWidget {
  final double size;

  const Mascot({super.key, this.size = 48});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  // Tỉ lệ ảnh layer (mascot_body/arm.png cùng canvas 189x341).
  static const double _artAspect = 189 / 341;
  // Pivot = khớp vai (toạ độ full-canvas 151,118) quy về Alignment.
  static const Alignment _armPivot = Alignment(0.598, -0.308);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  // Dựng ảnh một lần, tái dùng qua các frame (không rebuild ảnh mỗi frame).
  late final Widget _body = Image.asset(
    'assets/images/mascot_body.png',
    fit: BoxFit.fill,
    semanticLabel: 'Linh vật Focus Plan',
  );
  late final Widget _arm = Image.asset(
    'assets/images/mascot_arm.png',
    fit: BoxFit.fill,
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
      builder: (context, _) {
        final v = _t.value; // 0..1 dao động qua lại (reverse)
        final tilt = (v - 0.5) * 0.26; // ± ~7.5° ngó nghiêng toàn thân
        final dy = -math.sin(v * math.pi) * 3; // nhún nhẹ trục Y
        final armAngle = -0.07 + v * 0.27; // vẫy nhẹ: ~ -4° .. +11° (ít lộ khe vai)
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: tilt,
            child: SizedBox(
              height: widget.size,
              child: AspectRatio(
                aspectRatio: _artAspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _body,
                    Transform.rotate(
                      angle: armAngle,
                      alignment: _armPivot,
                      child: _arm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
