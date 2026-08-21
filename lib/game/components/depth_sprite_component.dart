import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// A sprite that tracks the camera at its own rate to fake depth.
///
/// A layer with a factor below 1 lags behind the camera and reads as distant;
/// above 1 it outruns the camera and reads as being close to the lens. A factor
/// of exactly 1 is an ordinary world object and skips the per-frame work.
class DepthSpriteComponent extends SpriteComponent
    with HasGameReference<FlameGame> {
  DepthSpriteComponent({
    required this.parallaxFactor,
    required this.cameraAnchorX,
    super.sprite,
    super.size,
    super.position,
    super.anchor,
    super.priority,
  });

  /// Rate at which this layer follows camera movement.
  final double parallaxFactor;

  /// Camera x at which the layer sits exactly where it was authored.
  final double cameraAnchorX;

  late double _baseX;

  @override
  void onMount() {
    super.onMount();
    _baseX = position.x;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (parallaxFactor == 1.0) {
      return;
    }
    final cameraX = game.camera.viewfinder.position.x;
    position.x = _baseX + (cameraX - cameraAnchorX) * (1 - parallaxFactor);
  }
}
