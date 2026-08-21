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
/// Her sprite only ever plays a cycle in place; every bit of travel, depth and
/// perspective scaling is driven here in world space. Keeping those two things
/// separate is what lets the same 8-frame walk read correctly at any speed.
class CustomerComponent extends SpriteAnimationComponent {
  CustomerComponent({
    required SpriteAnimation walkAnimation,
    required SpriteAnimation sitAnimation,
    required SpriteAnimation sitIdleAnimation,
    required SpriteAnimation handsToTableAnimation,
    required this.shadow,
  }) : _walk = walkAnimation,
       _sit = sitAnimation,
       _sitIdle = sitIdleAnimation,
       _handsToTable = handsToTableAnimation,
       super(
         anchor: Anchor.bottomCenter,
         priority: GameConfig.priorityCustomer,
       );

  final SpriteAnimation _walk;
  final SpriteAnimation _sit;
  final SpriteAnimation _sitIdle;
  final SpriteAnimation _handsToTable;

  final SoftShadowComponent shadow;

  /// Fired once she has cleared the doorway, so the door can swing shut.
  VoidCallback? onClearedDoorway;

  /// Fired when she reaches the chair and the sit animation starts.
  VoidCallback? onStartedSitting;

  /// Fired when the sit animation finishes and the idle loop takes over.
  VoidCallback? onSeated;

  /// Fired when the hands-to-table transition finishes on the final frame.
  VoidCallback? onHandsOnTable;

  CustomerPhase _phase = CustomerPhase.offstage;
  bool _doorwayCleared = false;
  CharacterSheet _activeSheet = SpriteAtlas.customerWalk;
  final Vector2 _lockedSeatPosition = Vector2.zero();

  CustomerPhase get phase => _phase;

  /// Perspective scale at her current position along the walk.
  double get depthScale => scale.x;

  /// World y of the floor directly beneath her feet.
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
    // Character art is enlarged in world space. High-quality sampling avoids
    // the blocky edges produced by the default low-cost texture filter.
    paint.filterQuality = FilterQuality.high;
    _applyAnimation(_walk, SpriteAtlas.customerWalk);
    resetToDoorway();
  }

  /// Places her back in the doorway, invisible, ready for a new arrival.
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
    _applyAnimation(_walk, SpriteAtlas.customerWalk);
    position.x = GameConfig.customerStartX;
    _applyPerspective();
    _syncShadow();
  }

  /// Starts her walking in, fading up so she does not pop into frame.
  void enterSalon() {
    if (_phase != CustomerPhase.offstage) {
      return;
    }
    _phase = CustomerPhase.walking;
    add(
      OpacityEffect.to(
        1,
        EffectController(duration: 0.45, curve: Curves.easeOut),
      ),
    );
  }

  /// Plays the one-shot raise onto the table. World position stays locked.
  ///
  /// Body priority stays behind the manicure table; a separate tabletop-clipped
  /// pass draws only the pixels that land on the work surface so hands rest on
  /// top without pulling her torso through the furniture.
  void playHandsToTable() {
    if (_phase != CustomerPhase.seatedIdle) {
      return;
    }
    _clearEffects();
    position.setFrom(_lockedSeatPosition);
    _phase = CustomerPhase.handsToTable;
    priority = GameConfig.priorityCustomer;
    _applyAnimation(_handsToTable, SpriteAtlas.customerHandsToTable);
    animationTicker?.onComplete = () {
      position.setFrom(_lockedSeatPosition);
      onHandsOnTable?.call();
    };
  }

  /// Foot padding applied while seated so callers can match the seated render.
  double get seatedFootOffset =>
      _phase == CustomerPhase.sitting ||
          _phase == CustomerPhase.seatedIdle ||
          _phase == CustomerPhase.handsToTable
      ? _footOffset
      : 0;

  /// Draws the current frame with the same seated foot compensation [render]
  /// uses. Used by the tabletop hand pass so body and hands share one sheet.
  void renderSeatedFrame(Canvas canvas) {
    canvas.save();
    canvas.translate(0, seatedFootOffset);
    final sprite = animationTicker?.getSprite();
    if (sprite != null) {
      sprite.render(canvas, size: size, overridePaint: paint);
    }
    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_phase == CustomerPhase.walking) {
      position.x = math.min(
        position.x + GameConfig.customerWalkSpeed * dt,
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
      // World movement and sprite animation are intentionally independent.
      // Re-applying the locked coordinate also prevents any future effect or
      // controller from drifting the seated customer.
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
    _applyAnimation(_sit, SpriteAtlas.customerSit);
    onStartedSitting?.call();
    animationTicker?.onComplete = () {
      position.setFrom(_lockedSeatPosition);
      _phase = CustomerPhase.seatedIdle;
      _applyAnimation(_sitIdle, SpriteAtlas.customerSitIdle);
      onSeated?.call();
    };
  }

  /// Swaps only the rendered sheet; it never modifies world position.
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
      // Frame whitespace is an art-layout detail, not world movement. Offset
      // only the pixels so every frame keeps its feet on the locked ground.
      canvas.save();
      canvas.translate(0, _footOffset);
      super.render(canvas);
      canvas.restore();
      return;
    }
    super.render(canvas);
  }

  /// Maps her horizontal progress onto a shallow diagonal and a size ramp, so
  /// walking towards the manicure table also reads as walking towards the lens.
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
    // Opacity is folded into strength so the shadow fades up with her instead
    // of being stamped on the floor before she is visible.
    shadow.strength = s * strengthFactor * opacity;
  }

  void _clearEffects() {
    for (final effect in children.whereType<Effect>().toList()) {
      effect.removeFromParent();
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
