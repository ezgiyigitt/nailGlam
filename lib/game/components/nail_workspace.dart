import 'dart:ui' as ui;
import 'dart:ui' show FilterQuality;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../config/asset_paths.dart';
import '../config/game_config.dart';
import '../config/sprite_atlas.dart';
import 'soft_shadow_component.dart';

/// Full-screen manicure page: a 3D tabletop with a locked-pose washing hand.
///
/// This is a new page, not a zoom of the salon. While revealed it covers the
/// camera so wall/floor/customer cannot show through.
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

  late final _TableSurfaceFill _fill;
  late final PositionComponent _content;
  late final _LockedCleaningHand _hand;
  late final _LockedFingerCloseup _pinky;
  late final SoftShadowComponent _handShadow;
  late final _SprayMist _sprayMist;

  late final Sprite _dirtyHand;
  late final Sprite _cleanHand;
  late final ui.Image _pinkyImage;
  late final ui.Image _shortNailImage;

  double _opacity = 0;
  bool _showingPinky = false;

  bool get isRevealed => _opacity >= 0.99;

  @override
  Future<void> onLoad() async {
    final washImage = await game.images.load(AssetPaths.handWash);
    final tableImage = await game.images.load(AssetPaths.tableSurface);
    _pinkyImage = await game.images.load(AssetPaths.fifthNailClean);
    _shortNailImage = await game.images.load(AssetPaths.shortNail);
    await game.images.loadAll(<String>[
      AssetPaths.handSoap,
      AssetPaths.nailBuffer,
      AssetPaths.nailSpray,
      AssetPaths.nailClips,
    ]);

    final wash = SpriteAtlas.handWash;
    _dirtyHand = Sprite(
      washImage,
      srcPosition: wash.framePositions.first,
      srcSize: wash.frameSize,
    );
    _cleanHand = Sprite(
      washImage,
      srcPosition: wash.framePositions.last,
      srcSize: wash.frameSize,
    );

    _fill = _TableSurfaceFill(tableImage)
      ..anchor = Anchor.center
      ..position = Vector2(
        GameConfig.workspacePlateWidth / 2,
        GameConfig.workspacePlateHeight / 2,
      )
      ..size = Vector2(
        GameConfig.workspacePlateWidth,
        GameConfig.workspacePlateHeight,
      );

    _content = PositionComponent(
      size: Vector2(
        GameConfig.workspacePlateWidth,
        GameConfig.workspacePlateHeight,
      ),
      position: Vector2(
        GameConfig.workspacePlateWidth / 2,
        GameConfig.workspacePlateHeight / 2,
      ),
      anchor: Anchor.center,
    );

    final handScale = GameConfig.workspaceHandWidth / wash.frameSize.x;
    _hand = _LockedCleaningHand(
      dirty: _dirtyHand,
      clean: _cleanHand,
      dirtyOffset: wash.contentCenterOffsets.first,
      cleanOffset: wash.contentCenterOffsets.last,
      size: wash.frameSize * handScale,
      position: Vector2(
        GameConfig.workspaceHandCenterX,
        GameConfig.workspaceHandCenterY,
      ),
    );

    final pinkyScale =
        GameConfig.pinkySpriteHeight / SpriteAtlas.fifthNailClean.frameSize.y;
    _pinky = _LockedFingerCloseup(
      cleanImage: _pinkyImage,
      shortImage: _shortNailImage,
      cleanSheet: SpriteAtlas.fifthNailClean,
      shortSheet: SpriteAtlas.shortNail,
      cleanOffsets: SpriteAtlas.fifthNailClean.contentCenterOffsets,
      shortOffsets: SpriteAtlas.shortNail.contentCenterOffsets,
      size: SpriteAtlas.fifthNailClean.frameSize * pinkyScale,
      position: Vector2(
        GameConfig.pinkySpriteCenterX,
        GameConfig.pinkySpriteCenterY,
      ),
    )..opacity = 0;

    _handShadow = SoftShadowComponent()
      ..size.setValues(
        GameConfig.workspaceHandShadowWidth,
        GameConfig.workspaceHandShadowHeight,
      )
      ..position.setValues(
        GameConfig.workspaceHandCenterX,
        GameConfig.workspaceHandShadowCenterY,
      );

    _sprayMist = _SprayMist()
      ..position.setValues(
        GameConfig.pinkySpriteCenterX + 90,
        GameConfig.pinkySpriteCenterY - 80,
      )
      ..size.setValues(220, 180);

    await addAll(<Component>[_fill, _content]);
    await _content.addAll(<Component>[_handShadow, _hand, _pinky, _sprayMist]);
    _applyOpacity(0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_opacity > 0) {
      _coverVisibleWorld();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_opacity <= 0) {
      return;
    }
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint()..color = ui.Color.fromRGBO(46, 30, 20, _opacity),
    );
  }

  void reveal() => revealImmediate();

  void revealImmediate() {
    _applyOpacity(1);
    _coverVisibleWorld();
  }

  void hideImmediate() {
    resetCare();
    _applyOpacity(0);
  }

  void resetCare() {
    _showingPinky = false;
    _hand.cleanliness = 0;
    _pinky.useCleanSheet();
    _pinky.setFrame(0);
    hideSprayMist();
    _applyOpacity(_opacity);
  }

  void showSprayMist() {
    _sprayMist.playing = true;
  }

  void hideSprayMist() {
    _sprayMist.playing = false;
  }

  /// Dirt lifts in place. Hand world position never changes.
  void setWashProgress(double progress) {
    _showingPinky = false;
    final t = progress.clamp(0.0, 1.0);
    // Smooth ease so dirt dissolves instead of popping between misaligned cells.
    _hand.cleanliness = t * t * (3 - 2 * t);
    _applyOpacity(_opacity);
  }

  void showPinkyNail({int frame = 0}) {
    _showingPinky = true;
    _pinky.useCleanSheet();
    _pinky.setFrame(frame);
    _applyOpacity(_opacity);
  }

  void setPinkyFrame(int index) {
    _pinky.setFrame(index);
  }

  void showShortNail({int frame = 0}) {
    _showingPinky = true;
    _pinky.useShortSheet();
    _pinky.setFrame(frame);
    _applyOpacity(_opacity);
  }

  void setShortNailFrame(int index) {
    _pinky.useShortSheet();
    _pinky.setFrame(index);
  }

  void _coverVisibleWorld() {
    if (!isMounted) {
      return;
    }
    final view = game.camera.visibleWorldRect;
    if (view.width < 2 || view.height < 2) {
      return;
    }
    size.setValues(view.width, view.height);
    position.setValues(view.center.dx, view.center.dy);
    _fill.size.setFrom(size);
    _fill.position.setValues(size.x / 2, size.y / 2);
    _content.position.setValues(size.x / 2, size.y / 2);
  }

  void _applyOpacity(double value) {
    _opacity = value;
    _fill.opacity = value;
    if (_showingPinky) {
      _hand.opacity = 0;
      _pinky.opacity = value;
      _handShadow.strength = 0;
    } else {
      _hand.opacity = value;
      _pinky.opacity = 0;
      _handShadow.strength = value * GameConfig.workspaceHandShadowStrength;
    }
  }
}

/// Photoreal tabletop photo, cover-fit, with a light lacquer streak and edge AO.
class _TableSurfaceFill extends PositionComponent {
  _TableSurfaceFill(this._image);

  final ui.Image _image;
  double opacity = 0;

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0) {
      return;
    }
    final dest = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    final src = ui.Rect.fromLTWH(
      0,
      0,
      _image.width.toDouble(),
      _image.height.toDouble(),
    );
    final imageScale = (size.x / src.width > size.y / src.height)
        ? size.x / src.width
        : size.y / src.height;
    final draw = ui.Rect.fromCenter(
      center: dest.center,
      width: src.width * imageScale,
      height: src.height * imageScale,
    );

    canvas.drawRect(
      dest,
      ui.Paint()..color = ui.Color.fromRGBO(58, 38, 24, opacity),
    );
    canvas.saveLayer(
      dest,
      ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, opacity),
    );
    canvas.drawImageRect(
      _image,
      src,
      draw,
      ui.Paint()..filterQuality = FilterQuality.high,
    );
    canvas.drawRect(
      dest,
      ui.Paint()
        ..blendMode = ui.BlendMode.softLight
        ..shader = ui.Gradient.linear(
          ui.Offset(size.x * 0.18, size.y * 0.06),
          ui.Offset(size.x * 0.82, size.y * 0.52),
          const <ui.Color>[
            ui.Color(0x00FFFFFF),
            ui.Color(0x55FFF3DC),
            ui.Color(0x00FFFFFF),
          ],
          const <double>[0.22, 0.46, 0.82],
        ),
    );
    canvas.drawRect(
      dest,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          ui.Offset(size.x * 0.5, size.y * 0.4),
          size.y * 0.8,
          const <ui.Color>[
            ui.Color(0x00000000),
            ui.Color(0x590C0806),
          ],
          const <double>[0.64, 1],
        ),
    );
    canvas.restore();
  }
}

/// Dirty and clean frames stacked in the same rect with registration offsets
/// so the hand stays locked while dirt dissolves.
class _LockedCleaningHand extends PositionComponent {
  _LockedCleaningHand({
    required this.dirty,
    required this.clean,
    required this.dirtyOffset,
    required this.cleanOffset,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center);

  final Sprite dirty;
  final Sprite clean;
  final Vector2 dirtyOffset;
  final Vector2 cleanOffset;
  double cleanliness = 0;
  double opacity = 0;

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0) {
      return;
    }
    // Lock to the dirty pose so tips stay inside the rect. Absolute content
    // offsets used to translate the whole hand downward and clip the middle
    // fingernail against the saveLayer edge.
    final lock = dirtyOffset;
    final dirtyRel = Vector2.zero();
    final cleanRel = cleanOffset - lock;
    final scaleX = size.x / dirty.srcSize.x;
    final scaleY = size.y / dirty.srcSize.y;
    final padX =
        (dirtyRel.x.abs() > cleanRel.x.abs() ? dirtyRel.x : cleanRel.x).abs() *
            scaleX +
        2;
    final padY =
        (dirtyRel.y.abs() > cleanRel.y.abs() ? dirtyRel.y : cleanRel.y).abs() *
            scaleY +
        2;
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    final layer = ui.Rect.fromLTWH(-padX, -padY, size.x + padX * 2, size.y + padY * 2);
    final sample = ui.Paint()..filterQuality = FilterQuality.high;
    canvas.saveLayer(
      layer,
      ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, opacity),
    );
    _drawRegistered(canvas, dirty, dirtyRel, sample);
    if (cleanliness > 0.001) {
      _drawRegistered(
        canvas,
        clean,
        cleanRel,
        ui.Paint()
          ..filterQuality = FilterQuality.high
          ..color = ui.Color.fromRGBO(255, 255, 255, cleanliness),
      );
    }
    canvas.drawRect(
      rect,
      ui.Paint()
        ..blendMode = ui.BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          ui.Offset(size.x / 2, 0),
          ui.Offset(size.x / 2, size.y * GameConfig.workspaceHandWristFadeEnd),
          const <ui.Color>[
            ui.Color(0x00FFFFFF),
            ui.Color(0xFFFFFFFF),
          ],
        ),
    );
    canvas.restore();
  }

  void _drawRegistered(
    ui.Canvas canvas,
    Sprite sprite,
    Vector2 contentOffset,
    ui.Paint paint,
  ) {
    final scaleX = size.x / sprite.srcSize.x;
    final scaleY = size.y / sprite.srcSize.y;
    canvas.save();
    canvas.translate(-contentOffset.x * scaleX, -contentOffset.y * scaleY);
    sprite.render(canvas, size: size, overridePaint: paint);
    canvas.restore();
  }
}

/// Finger close-up with locked registration across clean / short sheets.
class _LockedFingerCloseup extends PositionComponent {
  _LockedFingerCloseup({
    required this.cleanImage,
    required this.shortImage,
    required this.cleanSheet,
    required this.shortSheet,
    required this.cleanOffsets,
    required this.shortOffsets,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center);

  final ui.Image cleanImage;
  final ui.Image shortImage;
  final CharacterSheet cleanSheet;
  final CharacterSheet shortSheet;
  final List<Vector2> cleanOffsets;
  final List<Vector2> shortOffsets;

  double opacity = 0;
  bool _short = false;
  int _frame = 0;

  void useCleanSheet() => _short = false;

  void useShortSheet() => _short = true;

  void setFrame(int index) {
    final count = (_short ? shortSheet : cleanSheet).frameCount;
    _frame = index.clamp(0, count - 1);
  }

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0) {
      return;
    }
    final sheet = _short ? shortSheet : cleanSheet;
    final image = _short ? shortImage : cleanImage;
    final offsets = _short ? shortOffsets : cleanOffsets;
    final origin = sheet.framePositions[_frame];
    // Relative to frame 0 so the first pose sits in-box; later frames only
    // nudge by the delta (avoids pushing nail tips out of the clip rect).
    final lock = offsets.first;
    final rel = offsets[_frame] - lock;
    final src = ui.Rect.fromLTWH(
      origin.x,
      origin.y,
      sheet.frameSize.x,
      sheet.frameSize.y,
    );
    final scaleX = size.x / sheet.frameSize.x;
    final scaleY = size.y / sheet.frameSize.y;
    final padX = rel.x.abs() * scaleX + 2;
    final padY = rel.y.abs() * scaleY + 2;
    final dest = ui.Rect.fromLTWH(
      -rel.x * scaleX,
      -rel.y * scaleY,
      size.x,
      size.y,
    );
    canvas.saveLayer(
      ui.Rect.fromLTWH(-padX, -padY, size.x + padX * 2, size.y + padY * 2),
      ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, opacity),
    );
    canvas.drawImageRect(
      image,
      src,
      dest,
      ui.Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }
}

/// Two-beat mist puffs while the spray is held on the nail.
class _SprayMist extends PositionComponent {
  bool playing = false;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!playing) {
      _elapsed = 0;
      return;
    }
    _elapsed += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    if (!playing) {
      return;
    }
    final beat = (_elapsed / 0.28) % 2;
    final first = beat < 1;
    _puff(canvas, ui.Offset(size.x * 0.28, size.y * 0.55), first ? 1 : 0.35);
    _puff(canvas, ui.Offset(size.x * 0.62, size.y * 0.32), first ? 0.35 : 1);
    _puff(canvas, ui.Offset(size.x * 0.78, size.y * 0.62), first ? 0.7 : 0.2);
  }

  void _puff(ui.Canvas canvas, ui.Offset center, double strength) {
    final radius = 22 + 16 * strength;
    canvas.drawCircle(
      center,
      radius,
      ui.Paint()
        ..color = ui.Color.fromRGBO(230, 248, 255, 0.22 + 0.38 * strength)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center.translate(radius * 0.35, -radius * 0.2),
      radius * 0.55,
      ui.Paint()
        ..color = ui.Color.fromRGBO(255, 255, 255, 0.18 + 0.28 * strength),
    );
  }
}
