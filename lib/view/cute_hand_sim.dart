import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nail_glam/model/nail_care_tools.dart';

/// Shared manicure progress hand — toy mannequin dorsal shape for every guest.
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
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 26),
                  child: CustomPaint(
                    painter: CuteHandSimPainter(
                      snapshots: snapshots,
                      activeDigit: activeDigit,
                      darkSkin: darkSkin,
                    ),
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
    NailDigit.pinky => 14,
    NailDigit.ring => 30,
    NailDigit.middle => 46,
    NailDigit.pointer => 62,
    NailDigit.thumb => 78,
  };

  static double _hitTop(NailDigit digit) =>
      digit == NailDigit.thumb ? 72 : 12;

  static double _hitW(NailDigit digit) =>
      digit == NailDigit.thumb ? 36 : 24;

  static double _hitH(NailDigit digit) =>
      digit == NailDigit.thumb ? 38 : 62;
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

class _FingerSpec {
  const _FingerSpec({
    required this.digit,
    required this.base,
    required this.tip,
    required this.baseHalfW,
    required this.knuckleHalfW,
    required this.tipHalfW,
    required this.nailScale,
  });

  final NailDigit digit;
  final Offset base;
  final Offset tip;
  final double baseHalfW;
  final double knuckleHalfW;
  final double tipHalfW;
  final double nailScale;
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
  static const Color _cleanLight = Color(0xFFF6D7C8);
  static const Color _cleanDark = Color(0xFFE8C4B0);
  static const Color _fadeTint = Color(0xFFD4C4BC);

  Color get _skin =>
      darkSkin ? const Color(0xFF8B5A3C) : const Color(0xFFF0C4A8);
  Color get _skinShadow =>
      darkSkin ? const Color(0xFF6E422C) : const Color(0xFFE0A888);
  Color get _skinBlush =>
      darkSkin ? const Color(0xFF9A6448) : const Color(0xFFF5D0BC);
  Color get _clean => darkSkin ? _cleanDark : _cleanLight;

  double _vibrancy(NailDigit digit, DigitSimSnapshot snap) {
    if (snap.isPolished) return 1;
    if (activeDigit == digit) return 1;
    final work = snap.cleanProgress.clamp(0.0, 1.0) +
        snap.cutFrame.clamp(0, 3) / 3.0;
    if (work > 0) return 0.38 + work.clamp(0.0, 1.0) * 0.62;
    return 0.28;
  }

  Color _tint(Color c, double v) {
    if (v >= 0.995) return c;
    return Color.lerp(_fadeTint, c, v)!;
  }

  Color _plate(DigitSimSnapshot snap, double v) {
    final polish = snap.polishColor;
    if (polish != null && polish != 0) {
      return _tint(Color(polish), v);
    }
    return _tint(
      Color.lerp(_dirty, _clean, snap.cleanProgress.clamp(0.0, 1.0))!,
      v,
    );
  }

  Path _toyFingerOutline({
    required Offset base,
    required Offset tip,
    required double baseHalfW,
    required double knuckleHalfW,
    required double tipHalfW,
  }) {
    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final len = math.max(1.0, math.sqrt(dx * dx + dy * dy));
    final ux = dx / len;
    final uy = dy / len;
    final px = -uy;
    final py = ux;

    final knuckle = Offset(base.dx + ux * len * 0.24, base.dy + uy * len * 0.24);
    final mid = Offset(base.dx + ux * len * 0.58, base.dy + uy * len * 0.58);
    final tipL = Offset(tip.dx + px * tipHalfW * 0.62, tip.dy + py * tipHalfW * 0.62);
    final tipR = Offset(tip.dx - px * tipHalfW * 0.62, tip.dy - py * tipHalfW * 0.62);
    final tipCap = Offset(tip.dx + ux * tipHalfW * 0.55, tip.dy + uy * tipHalfW * 0.55);

    return Path()
      ..moveTo(base.dx + px * baseHalfW, base.dy + py * baseHalfW)
      ..cubicTo(
        knuckle.dx + px * knuckleHalfW * 1.08,
        knuckle.dy + py * knuckleHalfW * 1.08,
        mid.dx + px * tipHalfW * 0.92,
        mid.dy + py * tipHalfW * 0.92,
        tipL.dx,
        tipL.dy,
      )
      ..quadraticBezierTo(tipCap.dx, tipCap.dy, tipR.dx, tipR.dy)
      ..cubicTo(
        mid.dx - px * tipHalfW * 0.92,
        mid.dy - py * tipHalfW * 0.92,
        knuckle.dx - px * knuckleHalfW * 1.08,
        knuckle.dy - py * knuckleHalfW * 1.08,
        base.dx - px * baseHalfW,
        base.dy - py * baseHalfW,
      )
      ..close();
  }

  Path _toyPalm(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.44, h * 0.99)
      ..quadraticBezierTo(w * 0.36, h * 0.90, w * 0.24, h * 0.84)
      ..quadraticBezierTo(w * 0.04, h * 0.76, w * 0.08, h * 0.58)
      ..quadraticBezierTo(w * 0.10, h * 0.46, w * 0.24, h * 0.40)
      ..quadraticBezierTo(w * 0.42, h * 0.36, w * 0.58, h * 0.38)
      ..quadraticBezierTo(w * 0.76, h * 0.40, w * 0.88, h * 0.48)
      ..quadraticBezierTo(w * 0.98, h * 0.58, w * 0.94, h * 0.72)
      ..quadraticBezierTo(w * 0.88, h * 0.86, w * 0.70, h * 0.90)
      ..quadraticBezierTo(w * 0.56, h * 0.92, w * 0.44, h * 0.99)
      ..close();
  }

  Path _nailPath({
    required Offset base,
    required Offset tip,
    required double tipHalfW,
    required double nailScale,
    required bool isShort,
  }) {
    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final len = math.max(1.0, math.sqrt(dx * dx + dy * dy));
    final ux = dx / len;
    final uy = dy / len;
    final nailLen = tipHalfW * nailScale * (isShort ? 0.68 : 1.02);
    final center = Offset(
      tip.dx - ux * nailLen * 0.38,
      tip.dy - uy * nailLen * 0.38,
    );
    return Path()
      ..addRRect(
        RRect.fromRectXY(
          Rect.fromCenter(
            center: center,
            width: tipHalfW * 1.28,
            height: nailLen,
          ),
          tipHalfW * 0.42,
          tipHalfW * 0.42,
        ),
      );
  }

  void _paintNail(
    Canvas canvas,
    Path nailPath,
    DigitSimSnapshot snap,
    double v,
  ) {
    final polish = snap.polishColor;
    final fill = _plate(snap, v);
    canvas.drawPath(
      nailPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.15, -0.4),
          radius: 1.15,
          colors: polish != null && polish != 0
              ? <Color>[
                  _tint(Color(polish).withValues(alpha: 0.96), v),
                  _tint(Color(polish), v),
                  _tint(Color(polish).withValues(alpha: 0.86), v),
                ]
              : <Color>[fill, fill.withValues(alpha: 0.88 * v + 0.12)],
        ).createShader(nailPath.getBounds()),
    );
    canvas.drawPath(
      nailPath,
      Paint()
        ..color = Color(0x66FFFFFF).withValues(alpha: 0.35 + v * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  void _paintFinger(Canvas canvas, Size size, _FingerSpec spec) {
    final snap = snapshots[spec.digit] ?? const DigitSimSnapshot();
    final active = activeDigit == spec.digit;
    final v = _vibrancy(spec.digit, snap);
    final body = _toyFingerOutline(
      base: spec.base,
      tip: spec.tip,
      baseHalfW: spec.baseHalfW,
      knuckleHalfW: spec.knuckleHalfW,
      tipHalfW: spec.tipHalfW,
    );

    if (active) {
      canvas.drawPath(
        body,
        Paint()
          ..color = const Color(0x66E8A0B8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final skinL = _tint(_skinShadow, v);
    final skinM = _tint(_skin, v);
    final skinR = _tint(_skinBlush, v);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[skinL, skinM, skinR],
          stops: const <double>[0, 0.52, 1],
        ).createShader(body.getBounds()),
    );

    canvas.drawPath(
      body,
      Paint()
        ..color = _tint(_skinShadow, v * 0.7).withValues(alpha: 0.18 + v * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    final nailPath = _nailPath(
      base: spec.base,
      tip: spec.tip,
      tipHalfW: spec.tipHalfW,
      nailScale: spec.nailScale,
      isShort: snap.isShort,
    );
    _paintNail(canvas, nailPath, snap, v);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final palm = _toyPalm(size);

    canvas.drawPath(
      palm,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.5, 0.62),
          radius: 0.92,
          colors: <Color>[_tint(_skin, 0.72), _tint(_skinBlush, 0.68), _tint(_skinShadow, 0.65)],
          stops: const <double>[0.15, 0.58, 1],
        ).createShader(palm.getBounds()),
    );
    canvas.drawPath(
      palm,
      Paint()
        ..color = _tint(_skinShadow, 0.55).withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.66),
        width: w * 0.30,
        height: h * 0.13,
      ),
      Paint()..color = _tint(_skinShadow, 0.5).withValues(alpha: 0.10),
    );

    const specs = <_FingerSpec>[
      _FingerSpec(
        digit: NailDigit.pinky,
        base: Offset(0.22, 0.60),
        tip: Offset(0.14, 0.10),
        baseHalfW: 0.078,
        knuckleHalfW: 0.068,
        tipHalfW: 0.050,
        nailScale: 0.94,
      ),
      _FingerSpec(
        digit: NailDigit.ring,
        base: Offset(0.38, 0.56),
        tip: Offset(0.34, 0.04),
        baseHalfW: 0.084,
        knuckleHalfW: 0.074,
        tipHalfW: 0.054,
        nailScale: 1.0,
      ),
      _FingerSpec(
        digit: NailDigit.middle,
        base: Offset(0.54, 0.54),
        tip: Offset(0.52, 0.02),
        baseHalfW: 0.090,
        knuckleHalfW: 0.080,
        tipHalfW: 0.058,
        nailScale: 1.06,
      ),
      _FingerSpec(
        digit: NailDigit.pointer,
        base: Offset(0.70, 0.56),
        tip: Offset(0.72, 0.06),
        baseHalfW: 0.084,
        knuckleHalfW: 0.074,
        tipHalfW: 0.054,
        nailScale: 1.0,
      ),
      _FingerSpec(
        digit: NailDigit.thumb,
        base: Offset(0.86, 0.74),
        tip: Offset(0.94, 0.44),
        baseHalfW: 0.092,
        knuckleHalfW: 0.082,
        tipHalfW: 0.058,
        nailScale: 0.90,
      ),
    ];

    for (final _FingerSpec spec in specs) {
      _paintFinger(
        canvas,
        size,
        _FingerSpec(
          digit: spec.digit,
          base: Offset(spec.base.dx * w, spec.base.dy * h),
          tip: Offset(spec.tip.dx * w, spec.tip.dy * h),
          baseHalfW: spec.baseHalfW * w,
          knuckleHalfW: spec.knuckleHalfW * w,
          tipHalfW: spec.tipHalfW * w,
          nailScale: spec.nailScale,
        ),
      );
    }

    canvas.drawPath(
      palm,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.18, h * 0.42),
          Offset(w * 0.82, h * 0.72),
          <Color>[
            const Color(0x22FFFFFF),
            const Color(0x00FFFFFF),
            const Color(0x18FFFFFF),
          ],
          <double>[0, 0.55, 1],
        )
        ..blendMode = BlendMode.softLight,
    );
  }

  @override
  bool shouldRepaint(covariant CuteHandSimPainter oldDelegate) {
    return oldDelegate.snapshots != snapshots ||
        oldDelegate.activeDigit != activeDigit ||
        oldDelegate.darkSkin != darkSkin;
  }
}
