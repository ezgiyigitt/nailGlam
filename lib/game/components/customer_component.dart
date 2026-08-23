import 'dart:math' as math;
import 'dart:ui' show Canvas, FilterQuality;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../config/game_config.dart';
import '../config/sprite_atlas.dart';
import 'soft_shadow_component.dart';

enum CustomerPhase { offstage, walking, sitting, seatedIdle, handsToTable }

/// The arriving customer.
///
/// Her sprite only ever plays a cycle in place; travel and perspective live
/// in world space so sheet swaps do not skate her across the floor.
class CustomerComponent extends SpriteAnimationComponent {
  CustomerComponent({
    required SpriteAnimation walkAnimation,
    required SpriteAnimation stopAnimation,
    required SpriteAnimation turnAnimation,
    required SpriteAnimation sitAnimation,
    required this.shadow,
  }) : _walk = walkAnimation,
       _stop = stopAnimation,
       _turn = turnAnimation,
       _sit = sitAnimation,
       super(
         anchor: Anchor.bottomCenter,
         priority: GameConfig.priorityCustomer,
       );

  final SpriteAnimation _walk;
  final SpriteAnimation _stop;
  final SpriteAnimation _turn;
  final SpriteAnimation _sit;

  final SoftShadowComponent shadow;

  VoidCallback? onClearedDoorway;
  VoidCallback? onStartedSitting;
  VoidCallback? onSeated;
  VoidCallback? onHandsOnTable;

  CustomerPhase _phase = CustomerPhase.offstage;
  bool _doorwayCleared = false;
  CharacterSheet _activeSheet = SpriteAtlas.customerWalk;
  final Vector2 _lockedSeatPosition = Vector2.zero();

  CustomerPhase get phase => _phase;

  double get depthScale => scale.x;

  double get groundY =>
      _phase == CustomerPhase.sitting ||
          _phase == CustomerPhase.seatedIdle ||
          _phase == CustomerPhase.handsToTable
      ? position.y
      : position.y - _footOffset;

  double get _footOffset {
    final index = (animationTicker?.currentIndex ?? 0).clamp(
      0,
      _activeSheet.footPaddings.length - 1,
    );
    return _activeSheet.footPaddings[index] *
        _activeSheet.displayScale *
        scale.y;
  }

  @override
  Future<void> onLoad() async {
    paint.filterQuality = FilterQuality.high;
    _applyAnimation(_walk, SpriteAtlas.customerWalk);
    resetToDoorway();
  }

  void resetToDoorway() {
    _clearEffects();
    _phase = CustomerPhase.offstage;
    _doorwayCleared = false;
    priority = GameConfig.priorityCustomer;
    _lockedSeatPosition.setValues(
      GameConfig.customerSeatX,
      GameConfig.customerNearGroundY,
    );
    opacity = 0;
    playing = true;
    _applyAnimation(_walk, SpriteAtlas.customerWalk);
    position.x = GameConfig.customerStartX;
    _applyPerspective();
    _syncShadow();
  }

  void enterSalon() {
    if (_phase != CustomerPhase.offstage) {
      return;
    }
    _phase = CustomerPhase.walking;
    playing = true;
    _applyAnimation(_walk, SpriteAtlas.customerWalk);
    add(
      OpacityEffect.to(
        1,
        EffectController(duration: 0.45, curve: Curves.easeOut),
      ),
    );
  }

  void playHandsToTable() {
    if (_phase != CustomerPhase.seatedIdle &&
        _phase != CustomerPhase.handsToTable) {
      return;
    }
    _clearEffects();
    position.setFrom(_lockedSeatPosition);
    _phase = CustomerPhase.handsToTable;
    priority = GameConfig.priorityCustomer;
    playing = false;
    onHandsOnTable?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_phase == CustomerPhase.walking) {
      final remaining = GameConfig.customerSeatX - position.x;
      var speed = GameConfig.customerWalkSpeed;
      if (remaining <= GameConfig.walkSlowdownDistance) {
        final t = (1.0 - remaining / GameConfig.walkSlowdownDistance).clamp(
          0.0,
          1.0,
        );
        speed = _lerp(
          GameConfig.customerWalkSpeed,
          GameConfig.customerWalkEndSpeed,
          t * t,
        );
      }

      position.x = math.min(
        position.x + speed * dt,
        GameConfig.customerSeatX,
      );
      _applyPerspective();

      if (!_doorwayCleared &&
          position.x - GameConfig.customerStartX >=
              GameConfig.doorCloseTriggerDistance) {
        _doorwayCleared = true;
        onClearedDoorway?.call();
      }

      if (position.x >= GameConfig.customerSeatX) {
        _beginSitting();
      }
    } else if (_phase == CustomerPhase.sitting ||
        _phase == CustomerPhase.seatedIdle ||
        _phase == CustomerPhase.handsToTable) {
      position.setFrom(_lockedSeatPosition);
    }

    _syncShadow();
  }

  void _beginSitting() {
    _clearEffects();
    _lockedSeatPosition.setValues(
      GameConfig.customerSeatX,
      GameConfig.customerNearGroundY,
    );
    position.setFrom(_lockedSeatPosition);
    _phase = CustomerPhase.sitting;
    scale.setValues(GameConfig.customerNearScale, GameConfig.customerNearScale);
    onStartedSitting?.call();
    _playSheet(_stop, SpriteAtlas.customerStop, _playTurn);
  }

  void _playTurn() {
    _playSheet(_turn, SpriteAtlas.customerTurn, _playSit);
  }

  void _playSit() {
    _playSheet(_sit, SpriteAtlas.customerSit, () {
      playing = false;
      _phase = CustomerPhase.seatedIdle;
      onSeated?.call();
    });
  }

  void _playSheet(
    SpriteAnimation animation,
    CharacterSheet sheet,
    VoidCallback onComplete,
  ) {
    position.setFrom(_lockedSeatPosition);
    playing = true;
    _applyAnimation(animation, sheet);
    animationTicker?.onComplete = () {
      position.setFrom(_lockedSeatPosition);
      onComplete();
    };
  }

  void _applyAnimation(SpriteAnimation newAnimation, CharacterSheet sheet) {
    animation = newAnimation;
    animationTicker?.reset();
    _activeSheet = sheet;
    size = sheet.frameSize * sheet.displayScale;
  }

  @override
  void render(Canvas canvas) {
    if (_phase == CustomerPhase.sitting ||
        _phase == CustomerPhase.seatedIdle ||
        _phase == CustomerPhase.handsToTable) {
      canvas.save();
      canvas.translate(0, _footOffset);
      super.render(canvas);
      canvas.restore();
      return;
    }
    super.render(canvas);
  }

  void _applyPerspective() {
    final travel = GameConfig.customerSeatX - GameConfig.customerStartX;
    final t = travel == 0
        ? 1.0
        : ((position.x - GameConfig.customerStartX) / travel).clamp(0.0, 1.0);

    final perspectiveScale = _lerp(
      GameConfig.customerFarScale,
      GameConfig.customerNearScale,
      t,
    );
    scale.setValues(perspectiveScale, perspectiveScale);

    final ground = _lerp(
      GameConfig.customerFarGroundY,
      GameConfig.customerNearGroundY,
      t,
    );
    position.y = ground + _footOffset;
  }

  void _syncShadow() {
    final s = scale.x;
    final seated = _phase != CustomerPhase.walking;

    final widthFactor = seated ? GameConfig.shadowSeatedWidthFactor : 1.0;
    final heightFactor = seated ? GameConfig.shadowSeatedHeightFactor : 1.0;
    final strengthFactor = seated ? GameConfig.shadowSeatedStrengthFactor : 1.0;
    final offsetX = seated ? GameConfig.shadowSeatedOffsetX : 0.0;

    shadow.position.setValues(position.x + offsetX * s, groundY);
    shadow.size.setValues(
      GameConfig.shadowWidth * s * widthFactor,
      GameConfig.shadowHeight * s * heightFactor,
    );
    shadow.strength = s * strengthFactor * opacity;
  }

  void _clearEffects() {
    for (final effect in children.whereType<Effect>().toList()) {
      effect.removeFromParent();
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
