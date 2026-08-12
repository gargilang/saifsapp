import 'package:flutter/material.dart';

/// Logo monogram "S&I" — rounded square gradient emas. Dipakai di login,
/// app bar, launcher icon, splash, dan header PDF (lewat aset PNG yang
/// di-generate dari painter yang sama, lihat tool/brand_assets_test.dart).
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: const BrandLogoPainter(),
      );
}

class BrandLogoPainter extends CustomPainter {
  /// Proporsi logo terhadap canvas (1.0 = penuh). Dipakai < 1.0 untuk
  /// safe-zone adaptive icon Android.
  final double scale;
  const BrandLogoPainter({this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide * scale;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCenter(center: center, width: s, height: s);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.24));
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5B942), Color(0xFFD89B2B)],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);

    final tp = TextPainter(
      text: TextSpan(
        text: 'S&I',
        style: TextStyle(
          fontFamily: 'InterBrand',
          fontSize: s * 0.34,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1C1600),
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(BrandLogoPainter oldDelegate) => oldDelegate.scale != scale;
}
