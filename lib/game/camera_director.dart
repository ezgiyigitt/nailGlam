import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'config/game_config.dart';

/// Owns all camera movement.
///
/// Every move is exponential smoothing towards a target rather than a fixed
/// duration tween, which keeps the motion continuous when the target changes
/// mid-move. The target is clamped so the viewport can never show past the
/// edges of the salon, at any zoom level.
class CameraDirector extends Component with HasGameReference<FlameGame> {
  Vector2 _target = GameConfig.cameraStationFocus;
  double _targetZoom = GameConfig.cameraDefaultZoom;
  double _speed = GameConfig.cameraFollowSpeed;

  VoidCallback? _onSettled;
  bool _settleArmed = false;

  /// Horizontal world units per second left over from a flung swipe.
  double _panVelocity = 0;

  /// Stops any easing and parks the camera where it currently is.
  void holdCurrentFrame() {
    final viewfinder = game.camera.viewfinder;
    _target = viewfinder.position.clone();
    _targetZoom = viewfinder.zoom;
    _panVelocity = 0;
    _clearSettle();
  }

  /// Eases towards a fixed point and zoom.
  void focusOn(
    Vector2 point, {
    required double zoom,
    double? speed,
    VoidCallback? onSettled,
  }) {
    _target = point.clone();
    _targetZoom = zoom;
    _speed = speed ?? GameConfig.cameraTransitionSpeed;
    _panVelocity = 0;
    _onSettled = onSettled;
    _settleArmed = onSettled != null;
  }

  /// Jumps immediately, used when (re)starting the scene.
  void snapTo(Vector2 point, {double zoom = GameConfig.cameraDefaultZoom}) {
    _target = point.clone();
    _targetZoom = zoom;
    _speed = GameConfig.cameraFollowSpeed;
    _panVelocity = 0;
    _clearSettle();

    final viewfinder = game.camera.viewfinder;
    viewfinder.zoom = zoom;
    viewfinder.position = _clampToWorld(_target, zoom);
  }

  // -------------------------------------------------------------------------
  // Swipe browsing
  // -------------------------------------------------------------------------

  /// Takes hold of the camera at the start of a swipe.
  void beginPan() {
    _panVelocity = 0;
    _clearSettle();
    _target = game.camera.viewfinder.position.clone();
    _speed = GameConfig.cameraPanFollowSpeed;
  }

  /// Drags the room under the finger: content follows the swipe direction, so
  /// the camera moves the opposite way.
  void panBy(double worldDx) {
    _target.x -= worldDx;
    _target = _clampToWorld(_target, game.camera.viewfinder.zoom);
  }

  /// Lets the room keep gliding after the finger lifts.
  void endPan(double worldVelocityX) {
    _panVelocity = -worldVelocityX;
  }

  bool get isPanning => _panVelocity.abs() > GameConfig.cameraPanMinVelocity;

  @override
  void onMount() {
    super.onMount();
    final viewfinder = game.camera.viewfinder;
    viewfinder.zoom = _targetZoom;
    viewfinder.position = _clampToWorld(_target, _targetZoom);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final viewfinder = game.camera.viewfinder;

    if (_panVelocity != 0) {
      _target.x += _panVelocity * dt;
      _target = _clampToWorld(_target, viewfinder.zoom);
      _panVelocity *= math.pow(GameConfig.cameraPanDamping, dt).toDouble();
      if (_panVelocity.abs() < GameConfig.cameraPanMinVelocity) {
        _panVelocity = 0;
      }
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
