import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One-shot confetti layer. Bump [generation] to fire another burst.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({required this.generation, super.key});

  final int generation;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const int _count = 42;
  static const List<Color> _colors = <Color>[
    Color(0xFFFF7EB3),
    Color(0xFFFFC2E2),
    Color(0xFFFFD56A),
    Color(0xFFFFF1A8),
    Color(0xFFB388FF),
    Color(0xFFFFFFFF),
    Color(0xFFFF9A7B),
  ];

  late final AnimationController _controller;
  List<_Piece> _pieces = const <_Piece>[];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    if (widget.generation > 0) {
      _burst(widget.generation);
    }
  }

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation && widget.generation > 0) {
      _burst(widget.generation);
    }
  }

  void _burst(int seed) {
    final random = math.Random(seed * 9176);
    _pieces = <_Piece>[
      for (var i = 0; i < _count; i++)
        _Piece(
          x: random.nextDouble(),
          originY: -0.08 - random.nextDouble() * 0.12,
          size: 6 + random.nextDouble() * 10,
          drift: (random.nextDouble() - 0.5) * 0.55,
          spin: (random.nextDouble() - 0.5) * 8,
          color: _colors[random.nextInt(_colors.length)],
          delay: random.nextDouble() * 0.18,
        ),
    ];
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.generation <= 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _ConfettiPainter(
              pieces: _pieces,
              t: Curves.easeOut.transform(_controller.value),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.originY,
    required this.size,
    required this.drift,
    required this.spin,
    required this.color,
    required this.delay,
  });

  final double x;
  final double originY;
  final double size;
  final double drift;
  final double spin;
  final Color color;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.pieces, required this.t});

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final local = ((t - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (local <= 0) {
        continue;
      }
      final dx = (piece.x + piece.drift * local) * size.width;
      final dy = (piece.originY + local * 1.15) * size.height;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(piece.spin * local);
      final paint = Paint()
        ..color = piece.color.withValues(alpha: 1 - local * 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.55,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.pieces != pieces;
}
