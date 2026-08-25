import 'dart:math' as math;
import 'dart:ui' show FilterQuality, Canvas;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import 'package:nail_glam/model/game_config.dart';

enum CustomerPhase {
  offstage,
  walking,
  turning,
  sitting,
  seatedIdle,
  handsToTable,
}

/// The arriving customer, drawn from the waist up.
///
/// She walks in from off the left edge in side profile, stops at the chair,
/// pivots to face the desk and settles into her seat. Everything below her
/// waist is cropped out of the art, so no matter where she is placed the
/// player only ever sees her upper body above the manicure desk.
class CustomerComponent extends SpriteAnimationComponent {
  CustomerComponent({
    required this.walk,
    required this.turn,
    required this.sit,
    this.walkFrameAlign,
    this.turnFrameAlign,
    this.sitFrameAlign,
  }) : super(anchor: Anchor.topCenter, priority: GameConfig.priorityCustomer);

  SpriteAnimation walk;
  SpriteAnimation turn;
  SpriteAnimation sit;
  
  List<Vector2>? walkFrameAlign;
  List<Vector2>? turnFrameAlign;
  List<Vector2>? sitFrameAlign;

  VoidCallback? onStartedSitting;
  VoidCallback? onSeated;
  VoidCallback? onHandsOnTable;

  CustomerPhase _phase = CustomerPhase.offstage;

  double _bobClock = 0;

  CustomerPhase get phase => _phase;

  bool get isSeated =>
      _phase == CustomerPhase.seatedIdle ||
      _phase == CustomerPhase.handsToTable;

  /// Swap arrival art for the next guest without remounting the component.
  void useKit({
    required SpriteAnimation walk,
    required SpriteAnimation turn,
    required SpriteAnimation sit,
    List<Vector2>? walkFrameAlign,
    List<Vector2>? turnFrameAlign,
    List<Vector2>? sitFrameAlign,
  }) {
    this.walk = walk;
    this.turn = turn;
    this.sit = sit;
    this.walkFrameAlign = walkFrameAlign;
    this.turnFrameAlign = turnFrameAlign;
    this.sitFrameAlign = sitFrameAlign;
    if (_phase == CustomerPhase.offstage || _phase == CustomerPhase.walking) {
      _play(this.walk);
    } else if (_phase == CustomerPhase.turning) {
      _play(this.turn);
    } else {
      _play(this.sit);
    }
  }

  /// Bottom edge of the sprite cell, kept for composition checks.
  double get baseY => position.y + size.y;

  double get _topY {
    switch (_phase) {
      case CustomerPhase.sitting:
      case CustomerPhase.seatedIdle:
      case CustomerPhase.handsToTable:
        return GameConfig.customerTopY + GameConfig.customerSitDrop;
      case CustomerPhase.turning:
        final ticker = animationTicker;
        final total = ticker?.totalDuration() ?? 0;
        final t = total <= 0 ? 1.0 : ((ticker?.clock ?? 0) / total).clamp(0.0, 1.0);
        return GameConfig.customerTopY + GameConfig.customerSitDrop * t;
      case CustomerPhase.walking:
      case CustomerPhase.offstage:
        return GameConfig.customerTopY;
    }
  }

  @override
  Future<void> onLoad() async {
    paint.filterQuality = FilterQuality.medium;
    resetOffstage();
  }

  void resetOffstage() {
    _clearEffects();
    _phase = CustomerPhase.offstage;
    _bobClock = 0;
    priority = GameConfig.priorityCustomer;
    opacity = 0;
    _play(walk);
    position.setValues(GameConfig.customerEntryX, _topY);
  }

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

  void playHandsToTable() {
    if (!isSeated) {
      return;
    }
    _clearEffects();
    _phase = CustomerPhase.handsToTable;
    _snapToSeat();
    onHandsOnTable?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (_phase) {
      case CustomerPhase.walking:
        _bobClock += dt;
        final travelled =
            position.x + GameConfig.customerWalkSpeed * dt;
        if (travelled >= GameConfig.customerSeatX) {
          _beginTurning();
        } else {
          position.setValues(travelled, _topY + _bob());
        }
      case CustomerPhase.turning:
        _snapToSeat();
        if (animationTicker?.done() ?? true) {
          _beginSitting();
        }
      case CustomerPhase.sitting:
        _snapToSeat();
        if (animationTicker?.done() ?? true) {
          _phase = CustomerPhase.seatedIdle;
          onSeated?.call();
        }
      case CustomerPhase.seatedIdle:
      case CustomerPhase.handsToTable:
        _snapToSeat();
      case CustomerPhase.offstage:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    final align = _currentFrameAlign();
    if (align != null && align != Vector2.zero()) {
      canvas.save();
      canvas.translate(align.x, align.y);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  Vector2? _currentFrameAlign() {
    final idx = animationTicker?.currentIndex ?? 0;
    if (_phase == CustomerPhase.walking || _phase == CustomerPhase.offstage) {
      if (walkFrameAlign != null && idx < walkFrameAlign!.length) return walkFrameAlign![idx];
    } else if (_phase == CustomerPhase.turning) {
      if (turnFrameAlign != null && idx < turnFrameAlign!.length) return turnFrameAlign![idx];
    } else {
      if (sitFrameAlign != null && idx < sitFrameAlign!.length) return sitFrameAlign![idx];
    }
    return null;
  }

  /// Fades the bob out over the last stride so the turn has nothing to cancel.
  double _bob() {
    final remaining = GameConfig.customerSeatX - position.x;
    final settling = math.min(1, remaining / 140);
    return math.sin(_bobClock * GameConfig.customerBobSpeed) *
        GameConfig.customerBobAmplitude *
        settling;
  }

  void _beginTurning() {
    _phase = CustomerPhase.turning;
    _play(turn);
    _snapToSeat();
  }

  void _beginSitting() {
    _clearEffects();
    _phase = CustomerPhase.sitting;
    _play(sit);
    _snapToSeat();
    onStartedSitting?.call();
  }

  void _snapToSeat() {
    position.setValues(GameConfig.customerSeatX, _topY);
  }

  void _play(SpriteAnimation value) {
    animation = value;
    animationTicker?.reset();
    final frame = value.frames.first.sprite.srcSize;
    size.setValues(
      GameConfig.customerHeight * frame.x / frame.y,
      GameConfig.customerHeight,
    );
  }

  void _clearEffects() {
    for (final effect in children.whereType<Effect>().toList()) {
      effect.removeFromParent();
    }
  }
}
