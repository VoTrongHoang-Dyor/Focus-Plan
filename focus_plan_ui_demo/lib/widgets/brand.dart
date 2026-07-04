import 'package:flutter/material.dart';

/// Logo thương hiệu Focus Plan. Dùng ở Splash / Sign In / Sign Up.
class BrandLogo extends StatelessWidget {
  final double height;

  const BrandLogo({super.key, this.height = 88});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.jpg',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Focus Plan',
    );
  }
}

/// Linh vật (mascot) Focus Plan — avatar bo góc, dùng ở Home + empty-state.
class Mascot extends StatelessWidget {
  final double size;

  const Mascot({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/images/mascot.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'Linh vật Focus Plan',
      ),
    );
  }
}
