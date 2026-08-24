import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flutter/painting.dart';

import 'config/asset_paths.dart';

/// Stand-in art so the salon runs before the real 3D renders land.
///
/// Every piece is drawn at the proportions the final art should have, and each
/// one is a whole image: swapping in a PNG of a different size changes nothing
/// in code.
abstract final class PlaceholderArt {
  static const double roomWidth = 2160;
  static const double roomHeight = 1280;

  static const double tableWidth = 1200;
  static const double tableHeight = 760;

  static const double customerWidth = 640;
  static const double customerHeight = 860;

  static const double chairWidth = 620;
  static const double chairHeight = 850;

  /// Frame counts of the delivered customer strips. The placeholders draw the
  /// same number of cells so animation timing is identical either way.
  static const int customerWalkFrames = 4;
  static const int customerTurnFrames = 4;
  static const int customerSitFrames = 4;

  /// Fills [images] so the salon can be built without waiting on disk I/O.
  ///
  /// Real art always wins; a placeholder is only drawn for keys that are
  /// missing, which keeps tests rendering whatever is actually shipped.
  static Future<void> primeCache(Images images) async {
    await _prime(images, AssetPaths.salonRoom, room);
    await _prime(images, AssetPaths.nailTable, table);
    await _prime(images, AssetPaths.salonChair, chair);
    await _prime(images, AssetPaths.customerWalk, customerWalk);
    await _prime(images, AssetPaths.customerTurn, customerTurn);
    await _prime(images, AssetPaths.customerSit, customerSit);
    await _prime(images, AssetPaths.manicurePillow, manicurePillow);
    await _prime(images, AssetPaths.manicurePillowTop, manicurePillowTop);
  }

  static Future<void> _prime(
    Images images,
    String path,
    Future<ui.Image> Function() fallback,
  ) async {
    if (images.containsKey(path)) {
      return;
    }
    try {
      await images.load(path);
    } catch (_) {
      images.clear(path);
      images.add(path, await fallback());
    }
  }

  static Future<ui.Image> room() {
    return _raster(roomWidth, roomHeight, (Canvas canvas) {
      const w = roomWidth;
      const h = roomHeight;
      const floorTop = h * 0.58;

      canvas.drawRect(
        const Rect.fromLTWH(0, 0, w, floorTop),
        Paint()..color = const Color(0xFFF6B08A),
      );
      canvas.drawRect(
        const Rect.fromLTWH(0, floorTop - 18, w, 18),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, floorTop, w, h - floorTop),
        Paint()..color = const Color(0xFFF7CFD2),
      );

      final grout = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x33C98F92);
      for (var x = 0.0; x <= w; x += 180) {
        canvas.drawLine(Offset(x, floorTop), Offset(x, h), grout);
      }
      for (var y = floorTop; y <= h; y += 90) {
        canvas.drawLine(Offset(0, y), Offset(w, y), grout);
      }

      for (final centerX in <double>[w * 0.22, w * 0.5, w * 0.78]) {
        _window(canvas, Offset(centerX, floorTop * 0.52));
      }
    });
  }

  static void _window(Canvas canvas, Offset center) {
    final outer = Rect.fromCenter(center: center, width: 420, height: 260);
    canvas.drawRect(outer, Paint()..color = const Color(0xFFFFFFFF));
    final inner = outer.deflate(16);
    canvas.drawRect(inner, Paint()..color = const Color(0xFFDCEFF7));
    canvas.drawRect(
      Rect.fromLTWH(
        inner.left,
        inner.bottom - inner.height * 0.42,
        inner.width,
        inner.height * 0.42,
      ),
      Paint()..color = const Color(0xFF9BD08A),
    );
  }

  static Future<ui.Image> table() {
    return _raster(tableWidth, tableHeight, (Canvas canvas) {
      const w = tableWidth;
      const h = tableHeight;

      final top = Path()
        ..moveTo(w * 0.10, h * 0.20)
        ..lineTo(w * 0.90, h * 0.20)
        ..lineTo(w, h * 0.44)
        ..lineTo(0, h * 0.44)
        ..close();
      canvas.drawPath(top, Paint()..color = const Color(0xFFD9662F));
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.44, w, h * 0.10),
        Paint()..color = const Color(0xFFB44E22),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.54, w, h * 0.46),
        Paint()..color = const Color(0xFFC1541F),
      );

      _vase(canvas, Offset(w * 0.16, h * 0.22));
      _toolCup(canvas, Offset(w * 0.82, h * 0.22));
    });
  }

  static void _vase(Canvas canvas, Offset base) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 34, base.dy - 120, 68, 120),
        const Radius.circular(20),
      ),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      Offset(base.dx, base.dy - 156),
      52,
      Paint()..color = const Color(0xFFE9679B),
    );
  }

  static void _toolCup(Canvas canvas, Offset base) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 46, base.dy - 104, 92, 104),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFE1712F),
    );
    final tool = Paint()
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8E9AA6);
    canvas.drawLine(
      Offset(base.dx - 18, base.dy - 100),
      Offset(base.dx - 26, base.dy - 168),
      tool,
    );
    canvas.drawLine(
      Offset(base.dx + 16, base.dy - 100),
      Offset(base.dx + 28, base.dy - 158),
      tool,
    );
  }

  static Future<ui.Image> chair() {
    return _raster(chairWidth, chairHeight, (Canvas canvas) {
      const w = chairWidth;
      const h = chairHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(w * 0.16, 0, w * 0.68, h * 0.72),
          const Radius.circular(120),
        ),
        Paint()..color = const Color(0xFFF3C0C4),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, h * 0.44, w, h * 0.22),
          const Radius.circular(48),
        ),
        Paint()..color = const Color(0xFFF7DCD2),
      );
      canvas.drawRect(
        const Rect.fromLTWH(w * 0.10, h * 0.66, w * 0.80, h * 0.12),
        Paint()..color = const Color(0xFFE0B27A),
      );
    });
  }

  /// Side profile walk cycle. The pose barely changes: the placeholder only
  /// has to prove the frames advance and stay registered.
  static Future<ui.Image> customerWalk() {
    return _strip(customerWalkFrames, (Canvas canvas, int frame) {
      final swing = <double>[38, 0, -38, 0][frame];
      _woman(canvas, profile: true, armSwing: swing);
    });
  }

  static Future<ui.Image> customerTurn() {
    return _strip(customerTurnFrames, (Canvas canvas, int frame) {
      _woman(canvas, profile: frame < 2, armSwing: 0);
    });
  }

  static Future<ui.Image> customerSit() {
    return _strip(customerSitFrames, (Canvas canvas, int frame) {
      _woman(canvas, profile: false, hands: frame > 0, armSwing: 0);
    });
  }

  static Future<ui.Image> _strip(
    int frames,
    void Function(Canvas canvas, int frame) paint,
  ) {
    return _raster(customerWidth * frames, customerHeight, (Canvas canvas) {
      for (var frame = 0; frame < frames; frame++) {
        canvas.save();
        canvas.translate(customerWidth * frame, 0);
        paint(canvas, frame);
        canvas.restore();
      }
    });
  }

  /// Waist-up only: the sprite is cropped at the bottom edge on purpose, so it
  /// can never show legs no matter where it is placed.
  static void _woman(
    Canvas canvas, {
    required bool profile,
    double armSwing = 0,
    bool hands = false,
  }) {
    const w = customerWidth;
    const h = customerHeight;
    const cx = w / 2;

    final hair = Paint()..color = const Color(0xFFB98244);
    final skin = Paint()..color = const Color(0xFFF3C6AB);
    final blouse = Paint()..color = const Color(0xFFEDC7C4);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(cx, 250), width: 300, height: 400),
      hair,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + (profile ? 34 : 0), 232),
        width: profile ? 168 : 208,
        height: 268,
      ),
      skin,
    );

    final eye = Paint()..color = const Color(0xFF3F7A4B);
    if (profile) {
      canvas.drawCircle(const Offset(cx + 72, 232), 18, eye);
    } else {
      canvas.drawCircle(const Offset(cx - 44, 232), 20, eye);
      canvas.drawCircle(const Offset(cx + 44, 232), 20, eye);
    }

    final torso = Path()
      ..moveTo(cx - 120, 400)
      ..quadraticBezierTo(cx, 352, cx + 120, 400)
      ..lineTo(cx + 168, h)
      ..lineTo(cx - 168, h)
      ..close();
    canvas.drawPath(torso, blouse);

    final arm = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 54
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFEDC7C4);

    if (hands) {
      canvas.drawLine(
        const Offset(cx - 130, 470),
        const Offset(cx - 90, 780),
        arm,
      );
      canvas.drawLine(
        const Offset(cx + 130, 470),
        const Offset(cx + 90, 780),
        arm,
      );
      canvas.drawCircle(const Offset(cx - 88, 800), 42, skin);
      canvas.drawCircle(const Offset(cx + 88, 800), 42, skin);
      return;
    }

    canvas.drawLine(
      const Offset(cx, 470),
      Offset(cx + armSwing, 760),
      arm,
    );
  }

  static Future<ui.Image> manicurePillow() {
    return _raster(720, 210, (Canvas canvas) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(20, 40, 680, 140),
          const Radius.circular(70),
        ),
        Paint()..color = const Color(0xFFD4A017),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 20, 640, 130),
          const Radius.circular(64),
        ),
        Paint()..color = const Color(0xFFF48FB1),
      );
    });
  }

  static Future<ui.Image> manicurePillowTop() {
    return _raster(880, 280, (Canvas canvas) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 70, 820, 160),
          const Radius.circular(80),
        ),
        Paint()..color = const Color(0xFFD4A017),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(50, 40, 780, 150),
          const Radius.circular(74),
        ),
        Paint()..color = const Color(0xFFF48FB1),
      );
    });
  }

  static Future<ui.Image> _raster(
    double width,
    double height,
    void Function(Canvas canvas) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder));
    final picture = recorder.endRecording();
    return picture.toImage(width.round(), height.round());
  }
}
