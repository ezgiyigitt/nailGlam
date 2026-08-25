import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'package:nail_glam/model/game_config.dart';

/// A contact shadow drawn entirely in code.
///
/// It is a horizontally stretched radial falloff rather than a filled oval:
/// the centre carries most of the darkness, the alpha ramps to zero before it
/// reaches the edge, and a blur pass removes any remaining hard boundary. That
/// keeps it reading as light occlusion instead of a black sticker, and means it
/// composites correctly over the wood floor without needing a matching asset.
class SoftShadowComponent extends PositionComponent {
  SoftShadowComponent({super.position, super.priority})
    : super(
        size: Vector2(GameConfig.shadowWidth, GameConfig.shadowHeight),
        anchor: Anchor.center,
      );

  /// Scales both the footprint and the darkness. Driven by the customer's
  /// perspective scale so the shadow tightens as she moves away from the lens.
  double strength = 1;

  Paint? _paint;
  Vector2? _paintedFor;
  double? _paintedStrength;

  @override
  void render(Canvas canvas) {
    // The gradient is built on a square and squashed by the canvas rather than
    // being created directly on a wide rectangle. RadialGradient derives its
    // radius from the shortest side, so painting straight into a flat ellipse
    // would confine the falloff to a small circle in the middle of it.
    final diameter = size.x;
    final rect = Rect.fromLTWH(0, 0, diameter, diameter);

    if (_paint == null || _paintedFor != size || _paintedStrength != strength) {
      final peak = (GameConfig.shadowOpacity * strength).clamp(0.0, 1.0);
      _paint = Paint()
        ..shader = RadialGradient(
          // Held near full strength out to two thirds of the radius before
          // ramping off. A steeper falloff collapses into a small dark dot
          // instead of the broad occlusion an overhead-lit room produces.
          colors: <Color>[
            Color.fromRGBO(0, 0, 0, peak),
            Color.fromRGBO(0, 0, 0, peak * 0.78),
            const Color(0x00000000),
          ],
          stops: const <double>[0.0, 0.62, 1.0],
        ).createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, diameter * 0.07);
      _paintedFor = size.clone();
      _paintedStrength = strength;
    }

    final squash = size.y / diameter;
    canvas.save();
    canvas.translate(0, size.y / 2);
    canvas.scale(1, squash);
    canvas.translate(0, -diameter / 2);
    canvas.drawOval(rect, _paint!);
    canvas.restore();
  }
}
