import 'dart:ui' as ui;
import 'dart:ui' show FilterQuality;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

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
          GameConfig.stationX,
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
  late final _WashingHand _hand;
  late final _LockedFingerCloseup _pinky;
  late final SpriteComponent _pinkyPillow;
  late final SoftShadowComponent _handShadow;
  late final _SprayMist _sprayMist;

  late final List<Sprite> _washFrames;
  late final ui.Image _pinkyImage;
  late final ui.Image _shortNailImage;
  late final ui.Image _polishMask;
  late final ui.Image _ringCleanImage;
  late final ui.Image _ringShortImage;
  late final ui.Image _ringPolishMask;

  double _opacity = 0;
  bool _showingPinky = false;

  bool get isRevealed => _opacity >= 0.99;

  @override
  Future<void> onLoad() async {
    final washImage = await game.images.load(AssetPaths.handWash);
    final tableImage = await game.images.load(AssetPaths.tableSurface);
    _pinkyImage = await game.images.load(AssetPaths.fifthNailClean);
    _shortNailImage = await game.images.load(AssetPaths.shortNail);
    _polishMask = await _loadOptional(
      AssetPaths.pinkNailMask,
      width: 384,
      height: 1024,
    );
    _ringCleanImage = await game.images.load(AssetPaths.fourthNail);
    _ringShortImage = await game.images.load(AssetPaths.fourthShortNail);
    _ringPolishMask = await _loadOptional(
      AssetPaths.ringNailMask,
      width: 384,
      height: 1024,
    );
    await game.images.loadAll(<String>[
      AssetPaths.handSoap,
      AssetPaths.nailBuffer,
      AssetPaths.nailSpray,
      AssetPaths.nailClips,
      AssetPaths.manicurePillowTop,
    ]);
    try {
      await game.images.load(AssetPaths.polishBrush);
    } catch (_) {}

    final wash = SpriteAtlas.handWash;
    _washFrames = <Sprite>[
      for (final origin in wash.framePositions)
        Sprite(
          washImage,
          srcPosition: origin,
          srcSize: wash.frameSize,
        ),
    ];

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
    _hand = _WashingHand(
      frames: _washFrames,
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
      polishMask: _polishMask,
      polishPlate: SpriteAtlas.pinkNailPlate,
      cleanSheet: SpriteAtlas.fifthNailClean,
      shortSheet: SpriteAtlas.shortNail,
      shortAlign: SpriteAtlas.shortNailAlign,
      size: SpriteAtlas.fifthNailClean.frameSize * pinkyScale,
      position: Vector2(
        GameConfig.pinkySpriteCenterX,
        GameConfig.pinkySpriteCenterY,
      ),
    )..opacity = 0;

    _pinkyPillow = SpriteComponent(
      sprite: Sprite(game.images.fromCache(AssetPaths.manicurePillowTop)),
      size: Vector2(
        GameConfig.workspacePadWidth,
        GameConfig.workspacePadHeight,
      ),
      position: Vector2(
        GameConfig.workspaceHandCenterX,
        GameConfig.workspacePadCenterY,
      ),
      anchor: Anchor.center,
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
    await _content.addAll(<Component>[
      _handShadow,
      _pinkyPillow,
      _hand,
      _pinky,
      _sprayMist,
    ]);
    _applyOpacity(0);
  }

  Future<ui.Image> _loadOptional(
    String path, {
    required int width,
    required int height,
  }) async {
    try {
      return await game.images.load(path);
    } catch (_) {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder);
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      picture.dispose();
      if (!game.images.containsKey(path)) {
        game.images.add(path, image);
      }
      return image;
    }
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
      ui.Paint()..color = ui.Color.fromRGBO(196, 84, 32, _opacity),
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
    _bindFinger(
      cleanImage: _pinkyImage,
      shortImage: _shortNailImage,
      polishMask: _polishMask,
      polishPlate: SpriteAtlas.pinkNailPlate,
      cleanSheet: SpriteAtlas.fifthNailClean,
      shortSheet: SpriteAtlas.shortNail,
      shortAlign: SpriteAtlas.shortNailAlign,
    );
    _pinky.useCleanSheet();
    _pinky.setFrame(0);
    _pinky.clearPolish();
    hideSprayMist();
    _applyOpacity(_opacity);
  }

  void showSprayMist() {
    _sprayMist.playing = true;
  }

  void hideSprayMist() {
    _sprayMist.playing = false;
  }

  /// Dirt lifts across the four wash cells. Hand world position never changes.
  void setWashProgress(double progress) {
    _showingPinky = false;
    final t = progress.clamp(0.0, 1.0);
    _hand.cleanliness = t * t * (3 - 2 * t);
    _applyOpacity(_opacity);
  }

  void showPinkyNail({int frame = 0}) {
    _bindFinger(
      cleanImage: _pinkyImage,
      shortImage: _shortNailImage,
      polishMask: _polishMask,
      polishPlate: SpriteAtlas.pinkNailPlate,
      cleanSheet: SpriteAtlas.fifthNailClean,
      shortSheet: SpriteAtlas.shortNail,
      shortAlign: SpriteAtlas.shortNailAlign,
    );
    _showingPinky = true;
    _pinky.useCleanSheet();
    _pinky.setFrame(frame);
    _pinky.clearPolish();
    _applyOpacity(_opacity);
  }

  void showRingNail({int frame = 0}) {
    _bindFinger(
      cleanImage: _ringCleanImage,
      shortImage: _ringShortImage,
      polishMask: _ringPolishMask,
      polishPlate: SpriteAtlas.ringNailPlate,
      cleanSheet: SpriteAtlas.fourthNail,
      shortSheet: SpriteAtlas.fourthShortNail,
      shortAlign: SpriteAtlas.fourthShortNailAlign,
    );
    _showingPinky = true;
    _pinky.useCleanSheet();
    _pinky.setFrame(frame);
    _pinky.clearPolish();
    _applyOpacity(_opacity);
  }

  void _bindFinger({
    required ui.Image cleanImage,
    required ui.Image shortImage,
    required ui.Image polishMask,
    required SpriteRegion polishPlate,
    required CharacterSheet cleanSheet,
    required CharacterSheet shortSheet,
    required Vector2 shortAlign,
  }) {
    _pinky.cleanImage = cleanImage;
    _pinky.shortImage = shortImage;
    _pinky.polishMask = polishMask;
    _pinky.polishPlate = polishPlate;
    _pinky.cleanSheet = cleanSheet;
    _pinky.shortSheet = shortSheet;
    _pinky.shortAlign = shortAlign;
    final scale =
        GameConfig.pinkySpriteHeight / SpriteAtlas.fifthNailClean.frameSize.y;
    _pinky.size.setFrom(SpriteAtlas.fifthNailClean.frameSize * scale);
    _pinky.position.setValues(
      GameConfig.pinkySpriteCenterX,
      GameConfig.pinkySpriteCenterY,
    );
  }

  void setPinkyFrame(int index) {
    _pinky.setFrame(index);
  }

  void showShortNail({int frame = 0}) {
    _showingPinky = true;
    _pinky.useShortSheet();
    _pinky.setFrame(frame);
    _pinky.clearPolish();
    _applyOpacity(_opacity);
  }

  void setShortNailFrame(int index) {
    _pinky.useShortSheet();
    _pinky.setFrame(index);
  }

  void setPolishColor(int color) {
    _pinky.polishColor = color;
  }

  void setPolishFill(double fill) {
    _pinky.polishFill = fill.clamp(0.0, 1.0);
  }

  void _placePillow({required bool pinky}) {
    if (pinky) {
      _pinkyPillow.position.setValues(
        GameConfig.pinkySpriteCenterX,
        GameConfig.pinkyPillowCenterY,
      );
      _pinkyPillow.size.setValues(
        GameConfig.pinkyPillowWidth,
        GameConfig.pinkyPillowHeight,
      );
    } else {
      _pinkyPillow.position.setValues(
        GameConfig.workspaceHandCenterX,
        GameConfig.workspacePadCenterY,
      );
      _pinkyPillow.size.setValues(
        GameConfig.workspacePadWidth,
        GameConfig.workspacePadHeight,
      );
    }
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
    _pinkyPillow.opacity = value;
    _placePillow(pinky: _showingPinky);
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

/// Wood tabletop photo, cover-fit, with a warm lacquer streak and edge AO.
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
      ui.Paint()..color = ui.Color.fromRGBO(196, 84, 32, opacity),
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
            ui.Color(0x28FF9A4A),
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

/// Four wash cells. Progress 0–1 crossfades 0→1→2→3 so dirt lifts smoothly.
class _WashingHand extends PositionComponent {
  _WashingHand({
    required this.frames,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center);

  final List<Sprite> frames;
  double cleanliness = 0;
  double opacity = 0;

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0 || frames.isEmpty) {
      return;
    }
    final last = frames.length - 1;
    final pos = cleanliness.clamp(0.0, 1.0) * last;
    final from = pos.floor().clamp(0, last);
    final to = (from + 1).clamp(0, last);
    final t = pos - from;
    final fade = t * t * (3 - 2 * t);
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    final aligns = SpriteAtlas.handWashFrameAlign;
    final fromAlign = aligns[from];
    final toAlign = aligns[to];
    final scaleX = size.x / frames[from].srcSize.x;
    final scaleY = size.y / frames[from].srcSize.y;
    final padX =
        (fromAlign.x.abs() > toAlign.x.abs() ? fromAlign.x : toAlign.x).abs() *
            scaleX +
        2;
    final padY =
        (fromAlign.y.abs() > toAlign.y.abs() ? fromAlign.y : toAlign.y).abs() *
            scaleY +
        2;
    canvas.saveLayer(
      ui.Rect.fromLTWH(-padX, -padY, size.x + padX * 2, size.y + padY * 2),
      ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, opacity),
    );
    final sample = ui.Paint()..filterQuality = FilterQuality.high;
    _drawAligned(canvas, frames[from], fromAlign, sample);
    if (to != from && fade > 0.001) {
      _drawAligned(
        canvas,
        frames[to],
        toAlign,
        ui.Paint()
          ..filterQuality = FilterQuality.high
          ..color = ui.Color.fromRGBO(255, 255, 255, fade),
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

  void _drawAligned(
    ui.Canvas canvas,
    Sprite sprite,
    Vector2 align,
    ui.Paint paint,
  ) {
    final scaleX = size.x / sprite.srcSize.x;
    final scaleY = size.y / sprite.srcSize.y;
    canvas.save();
    canvas.translate(align.x * scaleX, align.y * scaleY);
    sprite.render(canvas, size: size, overridePaint: paint);
    canvas.restore();
  }
}

/// Finger close-up with locked registration across clean / short sheets.
class _LockedFingerCloseup extends PositionComponent {
  _LockedFingerCloseup({
    required this.cleanImage,
    required this.shortImage,
    required this.polishMask,
    required this.polishPlate,
    required this.cleanSheet,
    required this.shortSheet,
    required this.shortAlign,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center);

  ui.Image cleanImage;
  ui.Image shortImage;
  ui.Image polishMask;
  SpriteRegion polishPlate;
  CharacterSheet cleanSheet;
  CharacterSheet shortSheet;
  Vector2 shortAlign;

  double opacity = 0;
  bool _short = false;
  int _frame = 0;
  int polishColor = 0xFFFF6BA8;
  double polishFill = 0;

  void useCleanSheet() => _short = false;

  void useShortSheet() => _short = true;

  void setFrame(int index) {
    final count = (_short ? shortSheet : cleanSheet).frameCount;
    _frame = index.clamp(0, count - 1);
  }

  void clearPolish() {
    polishFill = 0;
  }

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0) {
      return;
    }
    final sheet = _short ? shortSheet : cleanSheet;
    final image = _short ? shortImage : cleanImage;
    final origin = sheet.framePositions[_frame];
    final src = ui.Rect.fromLTWH(
      origin.x,
      origin.y,
      sheet.frameSize.x,
      sheet.frameSize.y,
    );
    // Both fingers draw into the pinky close-up slot so size and position
    // stay put when swapping sheets.
    final slot = SpriteAtlas.fifthNailClean.frameSize;
    final scaleX = size.x / slot.x;
    final scaleY = size.y / slot.y;
    final dest = ui.Rect.fromLTWH(
      _short ? shortAlign.x * scaleX : 0,
      _short ? shortAlign.y * scaleY : 0,
      (_short ? sheet.frameSize.x : slot.x) * scaleX,
      (_short ? sheet.frameSize.y : slot.y) * scaleY,
    );
    final padX = dest.left.abs() + 2;
    final padY = dest.top.abs() + 2;
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
    canvas.drawRect(
      dest,
      ui.Paint()
        ..blendMode = ui.BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          ui.Offset(dest.left, dest.top),
          ui.Offset(dest.left, dest.top + dest.height * GameConfig.pinkyStumpFadeEnd),
          const <ui.Color>[
            ui.Color(0x00FFFFFF),
            ui.Color(0xFFFFFFFF),
          ],
        ),
    );
    _paintPolish(canvas, dest, src);
    canvas.restore();
  }

  void _paintPolish(ui.Canvas canvas, ui.Rect dest, ui.Rect nailSrc) {
    if (!_short || polishFill <= 0) {
      return;
    }
    final maskSrc = ui.Rect.fromLTWH(
      0,
      0,
      polishMask.width.toDouble(),
      polishMask.height.toDouble(),
    );
    final plate = ui.Rect.fromLTWH(
      dest.left + polishPlate.position.x / polishMask.width * dest.width,
      dest.top + polishPlate.position.y / polishMask.height * dest.height,
      polishPlate.size.x / polishMask.width * dest.width,
      polishPlate.size.y / polishMask.height * dest.height,
    );
    canvas.saveLayer(dest, ui.Paint());
    canvas.drawImageRect(
      polishMask,
      maskSrc,
      dest,
      ui.Paint()
        ..filterQuality = FilterQuality.high
        ..colorFilter = ui.ColorFilter.mode(
          ui.Color(polishColor),
          ui.BlendMode.srcIn,
        ),
    );
    canvas.drawImageRect(
      shortImage,
      nailSrc,
      dest,
      ui.Paint()
        ..filterQuality = FilterQuality.high
        ..blendMode = ui.BlendMode.overlay,
    );
    canvas.drawImageRect(
      polishMask,
      maskSrc,
      dest,
      ui.Paint()
        ..filterQuality = FilterQuality.high
        ..blendMode = ui.BlendMode.dstIn,
    );
    final shine = ui.Rect.fromCenter(
      center: ui.Offset(
        plate.center.dx - plate.width * 0.06,
        plate.center.dy - plate.height * 0.04,
      ),
      width: plate.width * 0.34,
      height: plate.height * 0.78,
    );
    canvas.saveLayer(dest, ui.Paint());
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(shine, ui.Radius.circular(shine.width * 0.5)),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(shine.center.dx, shine.top),
          ui.Offset(shine.center.dx, shine.bottom),
          const <ui.Color>[
            ui.Color(0x00FFFFFF),
            ui.Color(0xA8FFFFFF),
            ui.Color(0x66FFFFFF),
            ui.Color(0x00FFFFFF),
          ],
          const <double>[0, 0.22, 0.58, 1],
        ),
    );
    canvas.drawImageRect(
      polishMask,
      maskSrc,
      dest,
      ui.Paint()
        ..filterQuality = FilterQuality.high
        ..blendMode = ui.BlendMode.dstIn,
    );
    canvas.restore();
    if (polishFill < 0.999) {
      final revealed = plate.height * polishFill;
      canvas.drawRect(
        ui.Rect.fromLTRB(
          dest.left,
          plate.bottom - revealed,
          dest.right,
          dest.bottom + 2,
        ),
        ui.Paint()
          ..blendMode = ui.BlendMode.dstIn
          ..color = const ui.Color(0xFFFFFFFF),
      );
    }
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
