import 'package:flutter/material.dart';

import 'package:nail_glam/model/customer_roster.dart';
import 'package:nail_glam/model/game_config.dart';

const String _uiFont = 'Baloo2';

/// Compact premium dialogue bubble shown while the customer is seated idle.
class CustomerThoughtBubbleOverlay extends StatefulWidget {
  const CustomerThoughtBubbleOverlay({
    required this.onComplete,
    this.guest = CustomerRoster.customer1,
    super.key,
  });

  static const String id = 'customerThoughtBubble';

  final VoidCallback onComplete;
  final CustomerProfile guest;

  @override
  State<CustomerThoughtBubbleOverlay> createState() =>
      _CustomerThoughtBubbleOverlayState();
}

class _CustomerThoughtBubbleOverlayState
    extends State<CustomerThoughtBubbleOverlay>
    with SingleTickerProviderStateMixin {
  late final List<String> _dialogue = widget.guest.fullDialogue;

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
    return Stack(
      children: <Widget>[
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: GameConfig.hudTopControlsReserve,
              ),
              child: FadeTransition(
                opacity: _fade,
                child: AnimatedOpacity(
                  opacity: _finishing ? 0 : 1,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: _GuestNameplate(name: widget.guest.name),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
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
                            behavior: HitTestBehavior.translucent,
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
                                        color: const Color(0xFF7A3D5C),
                                        fontSize: compact ? 17 : 19,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                        decoration: TextDecoration.none,
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
        ),
      ],
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

/// Salon appointment plaque shown while she is seated.
class _GuestNameplate extends StatelessWidget {
  const _GuestNameplate({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        key: const Key('guest-nameplate'),
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
        decoration: BoxDecoration(
          color: const Color(0xF2FFFBF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF4B6C8), width: 1.6),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x22000000),
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'GUEST',
              style: TextStyle(
                fontFamily: _uiFont,
                fontSize: 10,
                height: 1,
                letterSpacing: 2.8,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC47A96),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(
                fontFamily: _uiFont,
                fontSize: 22,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7A3D5C),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft rounded speech bubble with a small downward tail.
class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter();

  static Path _shape(Size size) {
    const radius = 18.0;
    const tailWidth = 16.0;
    const tailHeight = 11.0;
    final bodyHeight = size.height - tailHeight;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bodyHeight),
      const Radius.circular(radius),
    );
    final tipX = size.width * 0.68;
    final tail = Path()
      ..moveTo(tipX - tailWidth / 2, bodyHeight - 1)
      ..lineTo(tipX, size.height)
      ..lineTo(tipX + tailWidth / 2, bodyHeight - 1)
      ..close();
    return Path()
      ..addRRect(body)
      ..addPath(tail, Offset.zero);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);

    // Solid offset only — a blur mask reads as a yellow smear on Flutter web.
    canvas.drawPath(
      shape.shift(const Offset(0, 4)),
      Paint()..color = const Color(0x22000000),
    );
    canvas.drawPath(shape, Paint()..color = const Color(0xFFFFFBFE));
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFF4B6C8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
