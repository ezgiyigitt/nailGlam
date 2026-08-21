import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'config/game_config.dart';

/// Owns all camera movement.
///
/// Every move is exponential smoothing towards a target rather than a fixed
/// duration tween, which keeps the motion continuous when the target changes
/// mid-move — the camera never stutters when the customer starts or stops
/// walking. The target is clamped so the viewport can never show past the
/// edges of the salon, at any zoom level.
class CameraDirector extends Component with HasGameReference<FlameGame> {
  Vector2 _target = Vector2(GameConfig.cameraHomeX, GameConfig.sceneCenterY);
  double _targetZoom = GameConfig.cameraDefaultZoom;
  double _speed = GameConfig.cameraFollowSpeed;

  PositionComponent? _followTarget;
  VoidCallback? _onSettled;
  bool _settleArmed = false;

  /// Tracks a component horizontally, holding the framing height steady.
  void follow(PositionComponent target) {
    _followTarget = target;
    _speed = GameConfig.cameraFollowSpeed;
    _targetZoom = GameConfig.cameraDefaultZoom;
    _clearSettle();
  }

  /// Stops following without introducing a final catch-up movement.
  void holdCurrentFrame() {
    _followTarget = null;
    final viewfinder = game.camera.viewfinder;
    _target = viewfinder.position.clone();
    _targetZoom = viewfinder.zoom;
    _clearSettle();
  }

  /// Releases any follow and eases towards a fixed point and zoom.
  void focusOn(
    Vector2 point, {
    required double zoom,
    double? speed,
    VoidCallback? onSettled,
  }) {
    _followTarget = null;
    _target = point.clone();
    _targetZoom = zoom;
    _speed = speed ?? GameConfig.cameraTransitionSpeed;
    _onSettled = onSettled;
    _settleArmed = onSettled != null;
  }

  @override
  void onMount() {
    super.onMount();
    final viewfinder = game.camera.viewfinder;
    viewfinder.zoom = _targetZoom;
    viewfinder.position = _clampToWorld(_target, _targetZoom);
  }

  /// Jumps immediately, used when (re)starting the scene.
  void snapTo(Vector2 point, {double zoom = GameConfig.cameraDefaultZoom}) {
    _followTarget = null;
    _target = point.clone();
    _targetZoom = zoom;
    _speed = GameConfig.cameraFollowSpeed;
    _clearSettle();

    final viewfinder = game.camera.viewfinder;
    viewfinder.zoom = zoom;
    viewfinder.position = _clampToWorld(_target, zoom);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final viewfinder = game.camera.viewfinder;

    final followed = _followTarget;
    if (followed != null) {
      _target = Vector2(
        followed.position.x + GameConfig.cameraLeadX,
        GameConfig.sceneCenterY,
      );
    }

    // Frame-rate independent smoothing: the fraction covered per second is
    // constant regardless of how long dt happens to be.
    final t = 1 - math.exp(-_speed * dt);

    final zoom = viewfinder.zoom + (_targetZoom - viewfinder.zoom) * t;
    viewfinder.zoom = zoom;

    final destination = _clampToWorld(_target, zoom);
    viewfinder.position =
        viewfinder.position + (destination - viewfinder.position) * t;

    if (_settleArmed && _isSettled(viewfinder.position, zoom)) {
      _settleArmed = false;
      final callback = _onSettled;
      _onSettled = null;
      callback?.call();
    }
  }

  bool _isSettled(Vector2 position, double zoom) {
    final destination = _clampToWorld(_target, _targetZoom);
    return (position - destination).length <=
            GameConfig.cameraSettlePositionEpsilon &&
        (zoom - _targetZoom).abs() <= GameConfig.cameraSettleZoomEpsilon;
  }

  void _clearSettle() {
    _settleArmed = false;
    _onSettled = null;
  }

  Vector2 _clampToWorld(Vector2 point, double zoom) {
    final virtualSize = game.camera.viewport.virtualSize;
    final halfWidth = virtualSize.x / (2 * zoom);
    final halfHeight = virtualSize.y / (2 * zoom);

    final x = GameConfig.worldWidth <= halfWidth * 2
        ? GameConfig.worldWidth / 2
        : point.x.clamp(halfWidth, GameConfig.worldWidth - halfWidth);

    final y = GameConfig.worldHeight <= halfHeight * 2
        ? GameConfig.worldHeight / 2
        : point.y.clamp(halfHeight, GameConfig.worldHeight - halfHeight);

    return Vector2(x.toDouble(), y.toDouble());
  }
}
