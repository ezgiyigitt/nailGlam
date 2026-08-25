import 'package:flutter/material.dart';

/// Solid gold disc — no dollar, cent, or currency glyph.
class GoldCoin extends StatelessWidget {
  const GoldCoin({this.size = 22, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _GoldCoinPainter(),
    );
  }
}

class _GoldCoinPainter extends CustomPainter {
  const _GoldCoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center.translate(0, radius * 0.08),
      radius * 0.92,
      Paint()..color = const Color(0x66C47A10),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: <Color>[
            Color(0xFFFFF4B0),
            Color(0xFFFFD24A),
            Color(0xFFE8A318),
            Color(0xFFC47A10),
          ],
          stops: <double>[0, 0.35, 0.78, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()
        ..color = const Color(0xFFF3C43A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08,
    );
    canvas.drawCircle(
      center.translate(-radius * 0.28, -radius * 0.32),
      radius * 0.18,
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wallet pill used on home, shop, and the manicure HUD.
class GoldBalanceChip extends StatelessWidget {
  const GoldBalanceChip({
    required this.coins,
    this.bump = 0,
    super.key,
  });

  final int coins;
  final int bump;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(bump),
      tween: Tween<double>(begin: bump == 0 ? 1 : 1.16, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xF2FFF6EE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const GoldCoin(size: 20),
            const SizedBox(width: 6),
            Text(
              '$coins',
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B524C),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
