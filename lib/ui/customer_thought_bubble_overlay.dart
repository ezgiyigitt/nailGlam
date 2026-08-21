import 'package:flutter/material.dart';

/// Compact premium dialogue bubble shown while the customer is seated idle.
class CustomerThoughtBubbleOverlay extends StatefulWidget {
  const CustomerThoughtBubbleOverlay({required this.onComplete, super.key});

  static const String id = 'customerThoughtBubble';

  final VoidCallback onComplete;

  @override
  State<CustomerThoughtBubbleOverlay> createState() =>
      _CustomerThoughtBubbleOverlayState();
}

class _CustomerThoughtBubbleOverlayState
    extends State<CustomerThoughtBubbleOverlay>
    with SingleTickerProviderStateMixin {
  static const List<String> _dialogue = <String>[
    "Hi! I'm ready for some glam! 💕",
    "First, let's clean my nails!",
    "Now let's smooth and shape them!",
    'Time for some beautiful color! ✨',
    "Let's make them fabulous! 💅",
  ];

  static const String _uiFont = 'DMSans';

  int _index = 0;
  bool _finishing = false;
  late final AnimationController _appear;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _appear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fade = CurvedAnimation(parent: _appear, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(parent: _appear, curve: Curves.easeOutCubic));
    _appear.forward();
  }

  @override
  void dispose() {
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxHeight < 700;
          final width = (constraints.maxWidth * 0.72).clamp(250.0, 340.0);

          return Align(
            alignment: const Alignment(0.42, -0.58),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: const Alignment(0.35, 1),
                child: AnimatedOpacity(
                  opacity: _finishing ? 0 : 1,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: _finishing ? 0.95 : 1,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    alignment: const Alignment(0.35, 1),
                    child: Semantics(
                      button: true,
                      label: 'Customer dialogue. Tap to continue.',
                      child: GestureDetector(
                        key: const Key('customer-thought-bubble'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _advance,
                        child: CustomPaint(
                          painter: const _SpeechBubblePainter(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: width * 0.85,
                              maxWidth: width,
                              minHeight: compact ? 78 : 86,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                18,
                                compact ? 14 : 16,
                                18,
                                compact ? 24 : 28,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 140),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                child: Text(
                                  _dialogue[_index],
                                  key: ValueKey<int>(_index),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: _uiFont,
                                    color: const Color(0xFF6B524C),
                                    fontSize: compact ? 14.5 : 15.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _advance() {
    if (_finishing) {
      return;
    }
    if (_index < _dialogue.length - 1) {
      setState(() => _index++);
      return;
    }

    setState(() => _finishing = true);
    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }
}

/// Soft rounded speech bubble with a small downward tail.
class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 18.0;
    const tailWidth = 14.0;
    const tailHeight = 10.0;
    final bodyHeight = size.height - tailHeight;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bodyHeight),
      const Radius.circular(radius),
    );

    // Tail sits slightly right of center so the bubble can sit beside her head.
    final tipX = size.width * 0.68;
    final tail = Path()
      ..moveTo(tipX - tailWidth / 2, bodyHeight - 1)
      ..lineTo(tipX, size.height)
      ..lineTo(tipX + tailWidth / 2, bodyHeight - 1)
      ..close();

    final shape = Path()
      ..addRRect(body)
      ..addPath(tail, Offset.zero);

    canvas.drawPath(
      shape.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x1A6B524C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(shape, Paint()..color = const Color(0xFFFFF8F2));

    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFE8D0C4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
