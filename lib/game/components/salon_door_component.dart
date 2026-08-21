import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../config/game_config.dart';
import '../config/sprite_atlas.dart';

/// The salon entrance: a fixed frame plus a leaf that opens and closes.
///
/// The leaf is anchored to its hinge edge and compressed horizontally rather
/// than rotated. A flat sprite rotating around a vertical edge would read as
/// the door falling over; compressing towards the hinge is what a door swinging
/// away from the camera actually looks like in projection.
class SalonDoorComponent extends PositionComponent {
  SalonDoorComponent({
    required Sprite frameSprite,
    required Sprite leafSprite,
    required Vector2 position,
  }) : super(position: position, priority: GameConfig.priorityDoorFrame) {
    final frameScale =
        GameConfig.doorFrameHeight / SpriteAtlas.doorFrame.size.y;
    final leafScale = GameConfig.doorLeafHeight / SpriteAtlas.doorLeaf.size.y;

    _leaf = SpriteComponent(
      sprite: leafSprite,
      size: SpriteAtlas.doorLeaf.size * leafScale,
      position: Vector2(GameConfig.doorLeafHingeOffsetX, 0),
      anchor: Anchor.bottomLeft,
      priority: GameConfig.priorityDoorLeaf,
    );

    _frame = SpriteComponent(
      sprite: frameSprite,
      size: SpriteAtlas.doorFrame.size * frameScale,
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityDoorFrame,
    );
  }

  late final SpriteComponent _leaf;
  late final SpriteComponent _frame;

  bool _isOpen = false;

  bool get isOpen => _isOpen;

  @override
  Future<void> onLoad() async {
    await addAll(<Component>[_leaf, _frame]);
  }

  void open({VoidCallback? onComplete}) {
    if (_isOpen) {
      onComplete?.call();
      return;
    }
    _isOpen = true;
    _animateLeafTo(
      GameConfig.doorOpenScaleX,
      GameConfig.doorOpenDuration,
      onComplete,
    );
  }

  void close({VoidCallback? onComplete}) {
    if (!_isOpen) {
      onComplete?.call();
      return;
    }
    _isOpen = false;
    _animateLeafTo(1, GameConfig.doorCloseDuration, onComplete);
  }

  /// Snaps the leaf shut without animating, for restarting the scene.
  void resetClosed() {
    _clearEffects();
    _isOpen = false;
    _leaf.scale.setValues(1, 1);
  }

  void _animateLeafTo(
    double targetScaleX,
    double duration,
    VoidCallback? onComplete,
  ) {
    _clearEffects();
    _leaf.add(
      ScaleEffect.to(
        Vector2(targetScaleX, 1),
        EffectController(duration: duration, curve: Curves.easeInOutCubic),
        onComplete: onComplete,
      ),
    );
  }

  void _clearEffects() {
    for (final effect in _leaf.children.whereType<Effect>().toList()) {
      effect.removeFromParent();
    }
  }
}
