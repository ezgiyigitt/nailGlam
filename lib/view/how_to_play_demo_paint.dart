import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:nail_glam/model/sprite_atlas.dart';

/// Overlay FX only. Subjects and tools are real cropped sprites.
class HowToPlayDemoPainter extends CustomPainter {
  const HowToPlayDemoPainter({
    required this.scene,
    required this.localT,
  });

  /// 0 wash, 1 spray, 2 wipe, 3 clip, 4 polish.
  final int scene;
  final double localT;

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene) {
      case 0:
        _suds(canvas, size);
      case 1:
        _mist(canvas, size);
      case 2:
        _sheen(canvas, size);
      case 3:
        _snipFlash(canvas, size);
      default:
        _polishGloss(canvas, size);
    }
  }

  void _suds(Canvas canvas, Size size) {
    final palm = Offset(size.width * 0.48, size.height * 0.52);
    for (var i = 0; i < 10; i++) {
      final a = localT * math.pi * 2.4 + i * 0.7;
      final r = 54.0 + 18 * math.sin(localT * 6 + i);
      canvas.drawCircle(
        Offset(palm.dx + math.cos(a) * r, palm.dy + math.sin(a * 1.15) * r * 0.55),
        7 + 5 * math.sin(localT * 9 + i),
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.28 + 0.22 * localT),
      );
    }
  }

  void _mist(Canvas canvas, Size size) {
    final nozzle = Offset(size.width * 0.68, size.height * 0.34);
    final pulse = 0.5 + 0.5 * math.sin(localT * math.pi * 8);
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(
        Offset(
          nozzle.dx - 18 - i * 14.0,
          nozzle.dy + 10 + math.sin(localT * 14 + i) * 8,
        ),
        6.0 + i * 2.4,
        Paint()..color = Color.fromRGBO(210, 240, 255, 0.16 + 0.18 * pulse),
      );
    }
  }

  void _sheen(Canvas canvas, Size size) {
    final x = size.width * (0.28 + 0.44 * (0.5 + 0.5 * math.sin(localT * math.pi * 3)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, size.height * 0.42), width: 18, height: size.height * 0.38),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0x33FFFFFF),
    );
  }

  void _snipFlash(Canvas canvas, Size size) {
    final hits = <double>[0.18, 0.42, 0.66, 0.88];
    for (final hit in hits) {
      final d = (localT - hit).abs();
      if (d > 0.06) {
        continue;
      }
      final k = 1 - d / 0.06;
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.36),
        16 + 20 * k,
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 * k),
      );
    }
  }

  void _polishGloss(Canvas canvas, Size size) {
    final fill = Curves.easeInOut.transform(localT);
    final nail = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.34),
        width: size.width * 0.16,
        height: size.height * 0.22 * fill.clamp(0.12, 1.0),
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      nail,
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.14 + 0.18 * fill),
    );
    if (fill > 0.35) {
      final glossX = size.width * (0.42 + 0.16 * math.sin(localT * math.pi * 2));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(glossX, size.height * 0.30),
          width: 10,
          height: size.height * 0.12,
        ),
        Paint()..color = const Color(0x55FFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(HowToPlayDemoPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.localT != localT;
}

/// Finger close-up pinned to one dest so clip frames only shorten the tip.
class HowToPlayFingerPainter extends CustomPainter {
  const HowToPlayFingerPainter({
    required this.image,
    required this.sheet,
    required this.frame,
    this.nextFrame,
    this.fade = 0,
    this.polishFill = 0,
    this.polishColor = const Color(0xFFD0123A),
  });

  final ui.Image image;
  final CharacterSheet sheet;
  final int frame;
  final int? nextFrame;
  final double fade;
  final double polishFill;
  final Color polishColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final dest = _dest(size);
    canvas.saveLayer(dest.inflate(12), Paint());
    _blit(canvas, dest, frame, 1);
    final to = nextFrame;
    if (to != null && fade > 0.01 && to != frame) {
      _blit(canvas, dest, to, fade);
    }
    if (polishFill > 0.01) {
      _paintPolish(canvas, dest);
    }
    paintHowToPlayStumpFade(canvas, dest);
    canvas.restore();
  }

  void _paintPolish(Canvas canvas, Rect dest) {
    final fill = polishFill.clamp(0.0, 1.0);
    // Plate sits on the lower tip of the pinned finger art.
    final plate = Rect.fromCenter(
      center: Offset(
        dest.center.dx,
        dest.top + dest.height * 0.58,
      ),
      width: dest.width * 0.22,
      height: dest.height * 0.28,
    );
    final growing = Rect.fromLTWH(
      plate.left,
      plate.top,
      plate.width,
      plate.height * math.max(0.12, fill),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(growing, const Radius.circular(22)),
      Paint()..color = polishColor.withValues(alpha: 0.92),
    );
    if (fill > 0.45) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(plate.center.dx - plate.width * 0.12, plate.top + plate.height * 0.28),
          width: plate.width * 0.28,
          height: plate.height * 0.35,
        ),
        Paint()..color = const Color(0x55FFFFFF),
      );
    }
  }

  Rect _dest(Size size) {
    final slot = Size(
      SpriteAtlas.fifthNailClean.frameSize.x,
      SpriteAtlas.fifthNailClean.frameSize.y,
    );
    final fitted = applyBoxFit(BoxFit.contain, slot, size);
    return Alignment.bottomCenter.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
  }

  void _blit(Canvas canvas, Rect dest, int index, double opacity) {
    final i = index.clamp(0, sheet.frameCount - 1);
    final origin = sheet.framePositions[i];
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        origin.x,
        origin.y,
        sheet.frameSize.x,
        sheet.frameSize.y,
      ),
      dest,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  @override
  bool shouldRepaint(HowToPlayFingerPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.sheet != sheet ||
      oldDelegate.frame != frame ||
      oldDelegate.nextFrame != nextFrame ||
      oldDelegate.fade != fade ||
      oldDelegate.polishFill != polishFill ||
      oldDelegate.polishColor != polishColor;
}

/// Softens the cut edge of a hand or finger so it does not read as a hard crop.
void paintHowToPlayStumpFade(Canvas canvas, Rect dest) {
  canvas.drawRect(
    dest,
    Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = ui.Gradient.linear(
        Offset(dest.left, dest.top),
        Offset(dest.left, dest.top + dest.height * 0.08),
        const <Color>[
          Color(0x00FFFFFF),
          Color(0x99FFFFFF),
          Color(0xFFFFFFFF),
        ],
        const <double>[0, 0.45, 1],
      ),
  );
}
