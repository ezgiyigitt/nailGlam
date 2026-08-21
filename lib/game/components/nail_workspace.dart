import 'dart:ui' as ui;
import 'dart:ui' show FilterQuality;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

import '../config/asset_paths.dart';
import '../config/game_config.dart';
import '../config/sprite_atlas.dart';
import 'soft_shadow_component.dart';

/// Close-up nail-care plate: table surface, hand cushion, and the reference
/// hand. The plate is fixed in world space; only the camera moves into it.
class NailWorkspace extends PositionComponent with HasGameReference<FlameGame> {
  NailWorkspace()
    : super(
        position: Vector2(
          GameConfig.tableX,
          GameConfig.workspacePlateCenterY,
        ),
        size: Vector2(
          GameConfig.workspacePlateWidth,
          GameConfig.workspacePlateHeight,
        ),
        anchor: Anchor.center,
        priority: GameConfig.priorityWorkspace,
      );

  late final SpriteComponent _surface;
  late final SpriteComponent _cushion;
  late final SpriteComponent _hand;
  late final _CushionFrontLip _cushionLip;
  late final SoftShadowComponent _handShadow;

  double _opacity = 0;
  double _revealElapsed = 0;
  bool _revealing = false;

  bool get isRevealed => _opacity >= 0.99;

  @override
  Future<void> onLoad() async {
    final surfaceImage = await game.images.load(
      AssetPaths.workspaceTableSurface,
    );
    final cushionImage = await game.images.load(
      AssetPaths.workspaceHandCushion,
    );
    final handImage = await game.images.load(AssetPaths.hand01Reference);

    _surface = SpriteComponent(
      sprite: Sprite(surfaceImage),
      size: size.clone(),
      anchor: Anchor.center,
      position: size / 2,
    )..paint.filterQuality = FilterQuality.high;

    final cushionScale =
        GameConfig.workspaceCushionWidth /
        SpriteAtlas.workspaceHandCushion.size.x;
    _cushion = SpriteComponent(
      sprite: Sprite(
        cushionImage,
        srcPosition: SpriteAtlas.workspaceHandCushion.position,
        srcSize: SpriteAtlas.workspaceHandCushion.size,
      ),
      size: SpriteAtlas.workspaceHandCushion.size * cushionScale,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, GameConfig.workspaceCushionCenterY),
    )..paint.filterQuality = FilterQuality.high;

    final handScale =
        GameConfig.workspaceHandWidth / SpriteAtlas.hand01Reference.size.x;
    _hand = _SoftWristHand(
      sprite: Sprite(
        handImage,
        srcPosition: SpriteAtlas.hand01Reference.position,
        srcSize: SpriteAtlas.hand01Reference.size,
      ),
      size: SpriteAtlas.hand01Reference.size * handScale,
      position: Vector2(
        GameConfig.workspaceHandCenterX,
        GameConfig.workspaceHandCenterY,
      ),
    );

    _handShadow = SoftShadowComponent()
      ..size.setValues(
        GameConfig.workspaceHandShadowWidth,
        GameConfig.workspaceHandShadowHeight,
      )
      ..position.setValues(
        GameConfig.workspaceHandCenterX,
        GameConfig.workspaceHandShadowCenterY,
      );

    // Same sprite as the cushion, clipped to its lower slice and drawn last so
    // the wrist crop is hidden behind the rest rather than floating above it.
    _cushionLip = _CushionFrontLip(
      sprite: _cushion.sprite,
      size: _cushion.size.clone(),
      position: _cushion.position.clone(),
    );

    await addAll(<Component>[
      _surface,
      _cushion,
      _handShadow,
      _hand,
      _cushionLip,
    ]);
    _applyOpacity(0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_revealing) {
      return;
    }
    _revealElapsed += dt;
    final t = (_revealElapsed / GameConfig.workspaceRevealDuration).clamp(
      0.0,
      1.0,
    );
    _applyOpacity(Curves.easeInOutCubic.transform(t));
    if (t >= 1) {
      _revealing = false;
    }
  }

  /// Softly brings the plate up while the camera dolly runs. Props never move.
  void reveal() {
    _revealing = true;
    _revealElapsed = 0;
  }

  void hideImmediate() {
    _revealing = false;
    _revealElapsed = 0;
    _applyOpacity(0);
  }

  void _applyOpacity(double value) {
    _opacity = value;
    _surface.opacity = value;
    _cushion.opacity = value;
    _hand.opacity = value;
    _cushionLip.opacity = value;
    _handShadow.strength = value * GameConfig.workspaceHandShadowStrength;
  }
}

/// The reference hand with its wrist crop dissolved instead of cut.
class _SoftWristHand extends SpriteComponent {
  _SoftWristHand({
    required super.sprite,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center) {
    paint.filterQuality = FilterQuality.high;
  }

  @override
  void render(ui.Canvas canvas) {
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);

    // The sprite is drawn opaque into its own layer so the mask below only eats
    // the wrist; layer alpha then carries the plate's reveal fade.
    canvas.saveLayer(
      rect,
      ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, opacity),
    );
    sprite?.render(
      canvas,
      size: size,
      overridePaint: ui.Paint()..filterQuality = FilterQuality.high,
    );
    canvas.drawRect(
      rect,
      ui.Paint()
        ..blendMode = ui.BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          ui.Offset(size.x / 2, 0),
          ui.Offset(size.x / 2, size.y),
          const <ui.Color>[
            ui.Color(0xFFFFFFFF),
            ui.Color(0xFFFFFFFF),
            ui.Color(0x00FFFFFF),
          ],
          <double>[0, GameConfig.workspaceHandWristFadeStart, 1],
        ),
    );
    canvas.restore();
  }
}

/// The front slice of the hand cushion, painted after the hand.
class _CushionFrontLip extends SpriteComponent {
  _CushionFrontLip({
    required super.sprite,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center) {
    paint.filterQuality = FilterQuality.high;
  }

  @override
  void render(ui.Canvas canvas) {
    final top = size.y * GameConfig.workspaceCushionLipFraction;
    canvas.save();
    canvas.clipRect(ui.Rect.fromLTWH(0, top, size.x, size.y - top));
    super.render(canvas);
    canvas.restore();
  }
}
