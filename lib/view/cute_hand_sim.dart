import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/nail_care_tools.dart';

/// Shared manicure progress hand — real dorsal art with per-digit polish overlays.
class CuteHandSimCard extends StatelessWidget {
  const CuteHandSimCard({
    required this.remaining,
    required this.total,
    required this.snapshots,
    required this.activeDigit,
    required this.darkSkin,
    this.onDigitTap,
    super.key,
  });

  final int remaining;
  final int total;
  final Map<NailDigit, DigitSimSnapshot> snapshots;
  final NailDigit? activeDigit;
  final bool darkSkin;
  final ValueChanged<NailDigit>? onDigitTap;

  static const List<NailDigit> _order = <NailDigit>[
    NailDigit.pinky,
    NailDigit.ring,
    NailDigit.middle,
    NailDigit.pointer,
    NailDigit.thumb,
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('nail-care-finger-sim'),
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          if (activeDigit != null) {
            onDigitTap?.call(activeDigit!);
          }
        },
        child: Ink(
          width: 132,
          height: 156,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFFFF8FB), Color(0xFFFFEEF4)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8A0B8), width: 2.2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.asset(
                        darkSkin
                            ? 'assets/images/${AssetPaths.finalHandDark}'
                            : 'assets/images/${AssetPaths.finalHandLight}',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.medium,
                      ),
                      CustomPaint(
                        painter: CuteHandSimPainter(
                          snapshots: snapshots,
                          activeDigit: activeDigit,
                          darkSkin: darkSkin,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 8,
                child: _RemainingBadge(remaining: remaining, total: total),
              ),
              for (final NailDigit digit in _order)
                Positioned(
                  left: _hitLeft(digit),
                  top: _hitTop(digit),
                  width: _hitW(digit),
                  height: _hitH(digit),
                  child: GestureDetector(
                    key: Key('nail-care-finger-sim-${digit.name}'),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onDigitTap?.call(digit);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static double _hitLeft(NailDigit digit) => switch (digit) {
    NailDigit.pinky => 8,
    NailDigit.ring => 24,
    NailDigit.middle => 40,
    NailDigit.pointer => 56,
    NailDigit.thumb => 72,
  };

  static double _hitTop(NailDigit digit) =>
      digit == NailDigit.thumb ? 58 : 8;

  static double _hitW(NailDigit digit) =>
      digit == NailDigit.thumb ? 40 : 28;

  static double _hitH(NailDigit digit) =>
      digit == NailDigit.thumb ? 44 : 68;
}

class _RemainingBadge extends StatelessWidget {
  const _RemainingBadge({required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('nail-care-remaining-box'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8A0B8)),
      ),
      child: Text(
        '$remaining left / $total',
        style: const TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8A4B63),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _NailLayout {
  const _NailLayout({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.fadeShift,
  });

  final Offset center;
  final double radiusX;
  final double radiusY;
  final Offset fadeShift;
}

class CuteHandSimPainter extends CustomPainter {
  const CuteHandSimPainter({
    required this.snapshots,
    required this.activeDigit,
    required this.darkSkin,
  });

  final Map<NailDigit, DigitSimSnapshot> snapshots;
  final NailDigit? activeDigit;
  final bool darkSkin;

  static const Color _dirty = Color(0xFFC4A05A);
  static const Color _clean = Color(0xFFF6D7C8);

  static const Map<NailDigit, _NailLayout> _lightNails = <NailDigit, _NailLayout>{
    NailDigit.pinky: _NailLayout(
      center: Offset(0.0619, 0.8008),
      radiusX: 0.0372,
      radiusY: 0.0270,
      fadeShift: Offset(0, 0.10),
    ),
    NailDigit.ring: _NailLayout(
      center: Offset(0.2540, 0.9141),
      radiusX: 0.0426,
      radiusY: 0.0328,
      fadeShift: Offset(0, 0.08),
    ),
    NailDigit.middle: _NailLayout(
      center: Offset(0.4979, 0.9561),
      radiusX: 0.0438,
      radiusY: 0.0322,
      fadeShift: Offset(0, 0.07),
    ),
    NailDigit.pointer: _NailLayout(
      center: Offset(0.7590, 0.9201),
      radiusX: 0.0426,
      radiusY: 0.0325,
      fadeShift: Offset(0, 0.08),
    ),
    NailDigit.thumb: _NailLayout(
      center: Offset(0.9386, 0.7071),
      radiusX: 0.0444,
      radiusY: 0.0332,
      fadeShift: Offset(-0.05, 0.06),
    ),
  };

  static const Map<NailDigit, _NailLayout> _darkNails = <NailDigit, _NailLayout>{
    NailDigit.pinky: _NailLayout(
      center: Offset(0.2530, 0.7071),
      radiusX: 0.0257,
      radiusY: 0.0586,
      fadeShift: Offset(0, -0.08),
    ),
    NailDigit.ring: _NailLayout(
      center: Offset(0.3738, 0.8726),
      radiusX: 0.0270,
      radiusY: 0.0737,
      fadeShift: Offset(0, -0.10),
    ),
    NailDigit.middle: _NailLayout(
      center: Offset(0.5182, 0.9217),
      radiusX: 0.0283,
      radiusY: 0.0708,
      fadeShift: Offset(0, -0.11),
    ),
    NailDigit.pointer: _NailLayout(
      center: Offset(0.6589, 0.8697),
      radiusX: 0.0309,
      radiusY: 0.0718,
      fadeShift: Offset(0, -0.10),
    ),
    NailDigit.thumb: _NailLayout(
      center: Offset(0.7556, 0.5476),
      radiusX: 0.0309,
      radiusY: 0.0674,
      fadeShift: Offset(-0.04, -0.06),
    ),
  };

  Map<NailDigit, _NailLayout> get _layouts =>
      darkSkin ? _darkNails : _lightNails;

  double _vibrancy(NailDigit digit, DigitSimSnapshot snap) {
    if (snap.isPolished) return 1;
    if (activeDigit == digit) return 1;
    final work = snap.cleanProgress.clamp(0.0, 1.0) +
        snap.cutFrame.clamp(0, 3) / 3.0;
    if (work > 0) return 0.35 + work.clamp(0.0, 1.0) * 0.65;
    return 0.22;
  }

  Rect _nailRect(Size size, _NailLayout layout, {double scale = 1}) {
    final cx = layout.center.dx * size.width;
    final cy = layout.center.dy * size.height;
    final rx = layout.radiusX * size.width * scale;
    final ry = layout.radiusY * size.height * scale;
    return Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
  }

  Path _fadePath(Size size, _NailLayout layout) {
    final nail = _nailRect(size, layout, scale: 1.05);
    final shift = Offset(
      layout.fadeShift.dx * size.width,
      layout.fadeShift.dy * size.height,
    );
    return Path()
      ..addOval(
        Rect.fromCenter(
          center: nail.center + shift,
          width: nail.width * 1.55,
          height: nail.height * 2.8,
        ),
      );
  }

  void _paintFadeZone(
    Canvas canvas,
    Size size,
    NailDigit digit,
    _NailLayout layout,
    double vibrancy,
  ) {
    if (vibrancy >= 0.98) return;
    final alpha = (0.52 * (1 - vibrancy)).clamp(0.0, 0.48);
    canvas.drawPath(
      _fadePath(size, layout),
      Paint()..color = Color(0xFFE8E0DC).withValues(alpha: alpha),
    );
  }

  void _paintNail(
    Canvas canvas,
    Size size,
    NailDigit digit,
    _NailLayout layout,
    DigitSimSnapshot snap,
    double vibrancy,
  ) {
    final rect = _nailRect(size, layout);
    final polish = snap.polishColor;
    final fill = polish != null && polish != 0
        ? Color(polish)
        : Color.lerp(_dirty, _clean, snap.cleanProgress.clamp(0.0, 1.0))!;

    if (polish != null && polish != 0) {
      canvas.drawOval(
        rect,
        Paint()..color = Color(polish).withValues(alpha: 0.94),
      );
      canvas.drawOval(
        rect.deflate(rect.shortestSide * 0.18),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.28),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.12),
            ],
            stops: const <double>[0, 0.45, 1],
          ).createShader(rect),
      );
      return;
    }

    if (snap.cleanProgress <= 0 && snap.cutFrame <= 0) {
      return;
    }

    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            fill.withValues(alpha: 0.55 * vibrancy + 0.15),
            fill.withValues(alpha: 0.35 * vibrancy + 0.10),
          ],
        ).createShader(rect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final MapEntry<NailDigit, _NailLayout> entry in _layouts.entries) {
      final digit = entry.key;
      final layout = entry.value;
      final snap = snapshots[digit] ?? const DigitSimSnapshot();
      final vibrancy = _vibrancy(digit, snap);
      _paintFadeZone(canvas, size, digit, layout, vibrancy);
    }

    for (final MapEntry<NailDigit, _NailLayout> entry in _layouts.entries) {
      final digit = entry.key;
      final layout = entry.value;
      final snap = snapshots[digit] ?? const DigitSimSnapshot();
      final vibrancy = _vibrancy(digit, snap);
      _paintNail(canvas, size, digit, layout, snap, vibrancy);

      if (activeDigit == digit) {
        final glow = _nailRect(size, layout, scale: 1.18);
        canvas.drawOval(
          glow,
          Paint()
            ..color = const Color(0x88E8A0B8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CuteHandSimPainter oldDelegate) {
    return oldDelegate.snapshots != snapshots ||
        oldDelegate.activeDigit != activeDigit ||
        oldDelegate.darkSkin != darkSkin;
  }
}
