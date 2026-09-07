import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show FilterQuality;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/game_config.dart';
import 'package:nail_glam/model/guest_care_kit.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/nail_finger_treatment.dart';
import 'package:nail_glam/model/sprite_atlas.dart';

import 'soft_shadow_component.dart';

/// Paints one coat of glossy lacquer clipped to [mask], with the tint,
/// wet-depth gradient and center shine all keyed to [plate] — the nail's own
/// bounding rect inside [dest] — rather than to [dest] itself. Shared by the
/// live per-digit paint ([_LockedFingerCloseup._paintPolish]) and the
/// finished-hand reveal paint ([_WashingHand._paintLacquerCoat]) so the two
/// read as the exact same polish. Before this was shared, the finished coat
/// keyed its depth/shine gradients off the whole-hand rect instead of the
/// nail plate: a nail sitting outside the gradient's narrow transition band
/// came out flat and pastel next to the vivid live coat.
void _paintNailLacquerCoat(
  ui.Canvas canvas,
  ui.Rect dest,
  ui.Rect plate,
  ui.Image mask,
  ui.Rect maskSrc,
  int coatColor,
) {
  final base = ui.Color(coatColor);
  final maskPaint = ui.Paint()
    ..filterQuality = FilterQuality.high
    ..blendMode = ui.BlendMode.dstIn
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 0.6);

  // 1) Lacquer body: tint the nail, keep its natural gloss/shading.
  canvas.saveLayer(dest, ui.Paint()..blendMode = ui.BlendMode.color);
  canvas.drawRect(plate.inflate(1), ui.Paint()..color = base.withAlpha(238));
  canvas.drawImageRect(mask, maskSrc, dest, maskPaint);
  canvas.restore();

  // 2) Wet depth: slightly richer at the cuticle, lighter toward the free edge.
  canvas.saveLayer(dest, ui.Paint());
  canvas.drawRect(
    plate,
    ui.Paint()
      ..blendMode = ui.BlendMode.softLight
      ..shader = ui.Gradient.linear(
        ui.Offset(plate.center.dx, plate.top),
        ui.Offset(plate.center.dx, plate.bottom),
        const <ui.Color>[
          ui.Color(0x33000000),
          ui.Color(0x00000000),
          ui.Color(0x44FFFFFF),
        ],
        const <double>[0, 0.55, 1],
      ),
  );
  canvas.drawImageRect(mask, maskSrc, dest, maskPaint);
  canvas.restore();

  // 3) Wet center streak — follows the still's vertical highlight.
  //
  // The gradient only varies *vertically*, so the band's left and right edges
  // are hard: at hand scale that passes for a gloss line, but on a toenail —
  // a few dozen pixels wide — it reads as a white stripe painted down the
  // middle of the nail. A blur sized from the band's own width gives it a
  // horizontal falloff too, so one streak works at both scales.
  final shine = ui.Rect.fromCenter(
    center: ui.Offset(
      plate.center.dx - plate.width * 0.06,
      plate.center.dy - plate.height * 0.02,
    ),
    width: plate.width * 0.2,
    height: plate.height * 0.86,
  );
  canvas.saveLayer(dest, ui.Paint());
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(shine, ui.Radius.circular(shine.width * 0.5)),
    ui.Paint()
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        math.max(1.2, shine.width * 0.42),
      )
      ..shader = ui.Gradient.linear(
        ui.Offset(shine.center.dx, shine.top),
        ui.Offset(shine.center.dx, shine.bottom),
        const <ui.Color>[
          ui.Color(0x00FFFFFF),
          ui.Color(0x9EFFFFFF),
          ui.Color(0x4DFFFFFF),
          ui.Color(0x00FFFFFF),
        ],
        const <double>[0, 0.18, 0.55, 1],
      ),
  );
  canvas.drawImageRect(mask, maskSrc, dest, maskPaint);
  canvas.restore();
}

/// Maps a mask-pixel-space [plate] into [dest]'s coordinate space, through
/// whatever [maskSrc] crop window the mask is being sampled through (mirrors
/// how the mask image itself gets drawn — see [_paintNailLacquerCoat]
/// callers). For an uncropped mask (`maskSrc` spans the whole image, as in
/// [_LockedFingerCloseup._paintPolish]) this reduces to the plain
/// width/height normalisation that method has always used. Falls back to the
/// full [dest] rect when no plate is registered for this mask (better than
/// crashing; only affects assets nobody has measured a plate for yet).
ui.Rect _mapLacquerPlate(SpriteRegion? plate, ui.Rect maskSrc, ui.Rect dest) {
  if (plate == null) {
    return dest;
  }
  final scaleX = dest.width / maskSrc.width;
  final scaleY = dest.height / maskSrc.height;
  return ui.Rect.fromLTWH(
    dest.left + (plate.position.x - maskSrc.left) * scaleX,
    dest.top + (plate.position.y - maskSrc.top) * scaleY,
    plate.size.x * scaleX,
    plate.size.y * scaleY,
  );
}

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

  late List<Sprite> _washFrames;
  late List<Sprite> _finalFrames;
  late ui.Image _pinkyImage;
  late ui.Image _darkWashImage;
  late ui.Image _darkFinalImage;
  late ui.Image _darkFinalPolishMask;
  late final Map<NailDigit, ui.Image> _darkFinalDigitMasks =
      <NailDigit, ui.Image>{};
  late ui.Image _lightFinalPolishMask;
  late final Map<NailDigit, ui.Image> _lightFinalDigitMasks =
      <NailDigit, ui.Image>{};
  late final Map<NailDigit, ui.Image> _lightStilettoFinalDigitMasks =
      <NailDigit, ui.Image>{};
  late final Map<NailDigit, ui.Image> _darkStilettoFinalDigitMasks =
      <NailDigit, ui.Image>{};
  late final Map<NailDigit, ui.Image> _lightToeDigitMasks =
      <NailDigit, ui.Image>{};
  late ui.Image _darkCleanImage;
  late ui.Image _darkShortImage;
  late ui.Image _darkPolishMask;
  late ui.Image _ringDarkCleanImage;
  late ui.Image _ringDarkShortImage;
  late ui.Image _ringDarkPolishMask;
  late ui.Image _middleDarkCleanImage;
  late ui.Image _middleDarkShortImage;
  late ui.Image _middleDarkPolishMask;
  late ui.Image _indexDarkCleanImage;
  late ui.Image _indexDarkShortImage;
  late ui.Image _indexDarkPolishMask;
  late ui.Image _thumbDarkCleanImage;
  late ui.Image _thumbDarkShortImage;
  late ui.Image _thumbDarkPolishMask;
  late final ui.Image _pinkySprayImage;
  late final ui.Image _pinkyWipeImage;
  late final ui.Image _ringSprayImage;
  late final ui.Image _ringWipeImage;
  late final ui.Image _shortNailImage;
  late final ui.Image _polishMask;
  late final ui.Image _ringCleanImage;
  late final ui.Image _ringShortImage;
  late final ui.Image _ringPolishMask;
  late final ui.Image _middleCleanImage;
  late final ui.Image _middleShortImage;
  late final ui.Image _middlePolishMask;
  late final ui.Image _indexCleanImage;
  late final ui.Image _indexShortImage;
  late final ui.Image _indexPolishMask;
  late final ui.Image _thumbCleanImage;
  late final ui.Image _thumbShortImage;
  late final ui.Image _thumbPolishMask;
  late List<Sprite> _footWashFrames;
  late List<Sprite> _footNailCleanFrames;
  late List<Sprite> _footNailCutFrames;

  GuestCareKit _kit = GuestCareCatalog.light;

  double _opacity = 0;
  bool _showingPinky = false;
  bool _showingFinishedHand = false;

  bool get isRevealed => _opacity >= 0.99;

  /// True while the post-manicure [AssetPaths.finalHand] sheet is on the plate.
  bool get showingFinishedHand => _showingFinishedHand && !_showingPinky;

  @override
  Future<void> onLoad() async {
    final washImage = await game.images.load(AssetPaths.handWash);
    final finalImage = await game.images.load(AssetPaths.finalHand);
    _darkWashImage = await game.images.load(AssetPaths.handWashDark);
    _darkFinalImage = await game.images.load(AssetPaths.finalHandDark);
    _darkFinalPolishMask = await _loadOptional(
      AssetPaths.finalHandDarkNailMask,
      width: 1536,
      height: 1024,
    );
    _darkFinalDigitMasks[NailDigit.pinky] = await _loadOptional(
      AssetPaths.finalHandDarkNailPinky,
      width: 1536,
      height: 1024,
    );
    _darkFinalDigitMasks[NailDigit.ring] = await _loadOptional(
      AssetPaths.finalHandDarkNailRing,
      width: 1536,
      height: 1024,
    );
    _darkFinalDigitMasks[NailDigit.middle] = await _loadOptional(
      AssetPaths.finalHandDarkNailMiddle,
      width: 1536,
      height: 1024,
    );
    _darkFinalDigitMasks[NailDigit.pointer] = await _loadOptional(
      AssetPaths.finalHandDarkNailPointer,
      width: 1536,
      height: 1024,
    );
    _darkFinalDigitMasks[NailDigit.thumb] = await _loadOptional(
      AssetPaths.finalHandDarkNailThumb,
      width: 1536,
      height: 1024,
    );
    await game.images.loadAll(<String>[
      AssetPaths.pinkyCleanLight,
      AssetPaths.pinkyShortLight,
      AssetPaths.pinkyNailMaskLight,
      AssetPaths.middleCleanLight,
      AssetPaths.middleShortLight,
      AssetPaths.middleNailMaskLight,
      AssetPaths.thumbCleanLight,
      AssetPaths.thumbShortLight,
      AssetPaths.thumbNailMaskLight,
      AssetPaths.finalHandLight,
    ]);
    _lightFinalPolishMask = await _loadOptional(
      AssetPaths.finalHandLightNailMask,
      width: 769,
      height: 1024,
    );
    _lightFinalDigitMasks[NailDigit.pinky] = await _loadOptional(
      AssetPaths.finalHandLightNailPinky,
      width: 769,
      height: 1024,
    );
    _lightFinalDigitMasks[NailDigit.ring] = await _loadOptional(
      AssetPaths.finalHandLightNailRing,
      width: 769,
      height: 1024,
    );
    _lightFinalDigitMasks[NailDigit.middle] = await _loadOptional(
      AssetPaths.finalHandLightNailMiddle,
      width: 769,
      height: 1024,
    );
    _lightFinalDigitMasks[NailDigit.pointer] = await _loadOptional(
      AssetPaths.finalHandLightNailPointer,
      width: 769,
      height: 1024,
    );
    _lightFinalDigitMasks[NailDigit.thumb] = await _loadOptional(
      AssetPaths.finalHandLightNailThumb,
      width: 769,
      height: 1024,
    );
    _darkCleanImage = await game.images.load(AssetPaths.pinkyCleanDark);
    _darkShortImage = await game.images.load(AssetPaths.pinkyShortDark);
    _darkPolishMask = await _loadOptional(
      AssetPaths.pinkyNailMaskDark,
      width: 464,
      height: 1398,
    );
    _ringDarkCleanImage = await game.images.load(AssetPaths.ringCleanDark);
    _ringDarkShortImage = await game.images.load(AssetPaths.ringShortDark);
    _ringDarkPolishMask = await _loadOptional(
      AssetPaths.ringNailMaskDark,
      width: 464,
      height: 1398,
    );
    _middleDarkCleanImage = await game.images.load(AssetPaths.middleCleanDark);
    _middleDarkShortImage = await game.images.load(AssetPaths.middleShortDark);
    _middleDarkPolishMask = await _loadOptional(
      AssetPaths.middleNailMaskDark,
      width: 464,
      height: 1398,
    );
    _indexDarkCleanImage = await game.images.load(AssetPaths.indexCleanDark);
    _indexDarkShortImage = await game.images.load(AssetPaths.indexShortDark);
    _indexDarkPolishMask = await _loadOptional(
      AssetPaths.indexNailMaskDark,
      width: 464,
      height: 1398,
    );
    _thumbDarkCleanImage = await game.images.load(AssetPaths.thumbCleanDark);
    _thumbDarkShortImage = await game.images.load(AssetPaths.thumbShortDark);
    _thumbDarkPolishMask = await _loadOptional(
      AssetPaths.thumbNailMaskDark,
      width: 464,
      height: 1398,
    );
    final tableImage = await game.images.load(AssetPaths.tableSurface);
    _pinkyImage = await game.images.load(AssetPaths.fifthNailClean);
    _pinkySprayImage = await game.images.load(AssetPaths.fifthNailSpray);
    _pinkyWipeImage = await game.images.load(AssetPaths.fifthNailWipe);
    _shortNailImage = await game.images.load(AssetPaths.shortNail);
    // Stiletto clip art + masks are addressed by asset path through the kit
    // (see [setNailShape]); warming the cache is all this needs to do.
    await game.images.loadAll(<String>[
      AssetPaths.pinkyStilettoNailLight,
      AssetPaths.middleNailStilettoLight,
      AssetPaths.thumbNailStilettoLight,
      AssetPaths.pinkyStilettoNailDark,
      AssetPaths.thumbStilettoNailDark,
      AssetPaths.thumbNailDarkWipe,
    ]);
    for (final String mask in <String>[
      AssetPaths.pinkyStilettoPolishMask,
      AssetPaths.middleStilettoPolishMask,
      AssetPaths.thumbStilettoPolishMask,
      AssetPaths.pinkyStilettoMaskDark,
      AssetPaths.thumbStilettoMaskDark,
    ]) {
      await _loadOptional(mask, width: 384, height: 1024);
    }
    _polishMask = await _loadOptional(
      AssetPaths.pinkNailMask,
      width: 384,
      height: 1024,
    );
    _ringCleanImage = await game.images.load(AssetPaths.fourthNail);
    _ringSprayImage = await game.images.load(AssetPaths.fourthNailSpray);
    _ringWipeImage = await game.images.load(AssetPaths.fourthNailWipe);
    _ringShortImage = await game.images.load(AssetPaths.fourthShortNail);
    _ringPolishMask = await _loadOptional(
      AssetPaths.ringNailMask,
      width: 384,
      height: 1024,
    );
    _middleCleanImage = await game.images.load(AssetPaths.thirdNailClean);
    _middleShortImage = await game.images.load(AssetPaths.thirdNailShort);
    _middlePolishMask = await _loadOptional(
      AssetPaths.thirdNailMask,
      width: 384,
      height: 1024,
    );
    _indexCleanImage = await game.images.load(AssetPaths.secondNailClean);
    _indexShortImage = await game.images.load(AssetPaths.secondNailShort);
    _indexPolishMask = await _loadOptional(
      AssetPaths.secondNailMask,
      width: 444,
      height: 887,
    );
    _thumbCleanImage = await game.images.load(AssetPaths.firstNailClean);
    _thumbShortImage = await game.images.load(AssetPaths.firstNailShort);
    _thumbPolishMask = await _loadOptional(
      AssetPaths.firstNailMask,
      width: 444,
      height: 887,
    );
    await game.images.loadAll(<String>[
      AssetPaths.handSoap,
      AssetPaths.nailBuffer,
      AssetPaths.nailSpray,
      AssetPaths.nailClips,
      AssetPaths.manicurePillowTop,
    ]);
    await game.images.loadAll(<String>[
      AssetPaths.footCleanLight,
      AssetPaths.footNailCleanLight,
      AssetPaths.footCleanDark,
      AssetPaths.footNailCleanDark,
      AssetPaths.footNailCutStripDark,
      AssetPaths.footNailPolishMaskLight,
      AssetPaths.footNailPolishMaskDark,
      AssetPaths.finalToeLightNailThumb,
      AssetPaths.finalToeLightNailPointer,
      AssetPaths.finalToeLightNailMiddle,
      AssetPaths.finalToeLightNailRing,
      AssetPaths.finalToeLightNailPinky,
    ]);
    _lightToeDigitMasks[NailDigit.thumb] = game.images.fromCache(
      AssetPaths.finalToeLightNailThumb,
    );
    _lightToeDigitMasks[NailDigit.pointer] = game.images.fromCache(
      AssetPaths.finalToeLightNailPointer,
    );
    _lightToeDigitMasks[NailDigit.middle] = game.images.fromCache(
      AssetPaths.finalToeLightNailMiddle,
    );
    _lightToeDigitMasks[NailDigit.ring] = game.images.fromCache(
      AssetPaths.finalToeLightNailRing,
    );
    _lightToeDigitMasks[NailDigit.pinky] = game.images.fromCache(
      AssetPaths.finalToeLightNailPinky,
    );
    _footWashFrames = _spritesFor(
      game.images.fromCache(_kit.footWashAsset),
      _kit.footWashSheet,
    );
    _footNailCleanFrames = _spritesFor(
      game.images.fromCache(_kit.footNailCleanAsset),
      _kit.footNailCleanSheet,
    );
    await game.images.loadAll(<String>[
      AssetPaths.finalHandStiletto,
      AssetPaths.finalHandDarkStiletto,
    ]);
    // Full 1067×1474 canvas, not the 820×1360 window — the mask is sampled
    // with the same src rect as the nail art (see _paintLacquerCoat), so it
    // must share the art's un-cropped coordinate space.
    await _loadOptional(
      AssetPaths.finalHandStilettoMask,
      width: 1067,
      height: 1474,
    );
    for (final entry in <NailDigit, String>{
      NailDigit.pinky: AssetPaths.finalHandStilettoNailPinky,
      NailDigit.ring: AssetPaths.finalHandStilettoNailRing,
      NailDigit.middle: AssetPaths.finalHandStilettoNailMiddle,
      NailDigit.pointer: AssetPaths.finalHandStilettoNailPointer,
      NailDigit.thumb: AssetPaths.finalHandStilettoNailThumb,
    }.entries) {
      _lightStilettoFinalDigitMasks[entry.key] = await _loadOptional(
        entry.value,
        width: 1067,
        height: 1474,
      );
    }
    await _loadOptional(
      AssetPaths.finalHandDarkStilettoMask,
      width: 1448,
      height: 1086,
    );
    for (final entry in <NailDigit, String>{
      NailDigit.pinky: AssetPaths.finalHandDarkStilettoNailPinky,
      NailDigit.ring: AssetPaths.finalHandDarkStilettoNailRing,
      NailDigit.middle: AssetPaths.finalHandDarkStilettoNailMiddle,
      NailDigit.pointer: AssetPaths.finalHandDarkStilettoNailPointer,
      NailDigit.thumb: AssetPaths.finalHandDarkStilettoNailThumb,
    }.entries) {
      _darkStilettoFinalDigitMasks[entry.key] = await _loadOptional(
        entry.value,
        width: 1448,
        height: 1086,
      );
    }
    await game.images.load(AssetPaths.footNailCutStrip);
    _footNailCutFrames = _spritesFor(
      game.images.fromCache(_kit.footNailCutAsset),
      _kit.footNailCutSheet,
    );
    try {
      await game.images.load(AssetPaths.polishBrush);
    } catch (_) {}

    final wash = SpriteAtlas.handWash;
    _washFrames = _spritesFor(washImage, wash);
    _finalFrames = _spritesFor(finalImage, SpriteAtlas.finalHand);
    _kit = GuestCareCatalog.light;

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
      frameAlign: SpriteAtlas.handWashFrameAlign,
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
      pinToSlot: false,
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

  List<Sprite> _spritesFor(ui.Image image, CharacterSheet sheet) {
    return <Sprite>[
      for (final origin in sheet.framePositions)
        Sprite(image, srcPosition: origin, srcSize: sheet.frameSize),
    ];
  }

  /// Swap wash / nail-clean / reveal art to match the seated guest.
  void applyCareKit(GuestCareKit kit) {
    _kit = kit;
    final washImage = game.images.fromCache(kit.washAsset);
    final finalImage = game.images.fromCache(kit.finalHandAsset);
    _washFrames = _spritesFor(washImage, kit.washSheet);
    _finalFrames = _spritesFor(finalImage, kit.finalHandSheet);
    _footWashFrames = _spritesFor(
      game.images.fromCache(kit.footWashAsset),
      kit.footWashSheet,
    );
    _footNailCleanFrames = _spritesFor(
      game.images.fromCache(kit.footNailCleanAsset),
      kit.footNailCleanSheet,
    );
    _footNailCutFrames = _spritesFor(
      game.images.fromCache(kit.footNailCutAsset),
      kit.footNailCutSheet,
    );
    resetCare();
  }

  /// Match the nail-care plate wood/marble/pink to the equipped salon desk.
  Future<void> applyTableSurface(String assetPath) async {
    final path = assetPath.isEmpty ? AssetPaths.tableSurface : assetPath;
    final image = game.images.containsKey(path)
        ? game.images.fromCache(path)
        : await game.images.load(path);
    _fill.setImage(image);
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
    _showWashHand(cleanliness: 0);
    if (_kit.unifiedNailClean) {
      _bindUnifiedNail();
    } else {
      _bindFinger(
        cleanImage: _pinkyImage,
        shortImage: _shortNailImage,
        polishMask: _polishMask,
        polishPlate: SpriteAtlas.pinkNailPlate,
        cleanSheet: SpriteAtlas.fifthNailClean,
        shortSheet: SpriteAtlas.shortNail,
        shortAlign: SpriteAtlas.shortNailAlign,
        pinToSlot: false,
      );
      _bindTreatmentArt(
        NailFingerTreatmentCatalog.pinky,
        sprayImage: _pinkySprayImage,
        wipeImage: _pinkyWipeImage,
      );
    }
    _pinky.useSpraySheet();
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
    final t = progress.clamp(0.0, 1.0);
    _showWashHand(cleanliness: t * t * (3 - 2 * t));
    _applyOpacity(_opacity);
  }

  /// Finished manicure still from the active guest's reveal art. When
  /// [useStiletto] is true (every cut nail was stiletto shaped), the
  /// stiletto-specific hand still and its single unified mask replace the
  /// guest's normal square-nail reveal art.
  void showFinishedHand([
    Map<NailDigit, int>? polishByDigit,
    bool useStiletto = false,
  ]) {
    _showingPinky = false;
    _showingFinishedHand = true;
    hideSprayMist();
    _hand.position.y = GameConfig.workspaceHandCenterY;
    final stilettoAsset = _kit.stilettoFinalHandAsset;
    final stilettoSheet = _kit.stilettoFinalHandSheet;
    if (useStiletto && stilettoAsset != null && stilettoSheet != null) {
      final scale = GameConfig.workspaceHandWidth / stilettoSheet.frameSize.x;
      final maskAsset = _kit.stilettoFinalHandMaskAsset;
      _hand.frames = _spritesFor(
        game.images.fromCache(stilettoAsset),
        stilettoSheet,
      );
      _hand.frameAlign = <Vector2>[Vector2.zero()];
      _hand.size.setFrom(stilettoSheet.frameSize * scale);
      _hand.cleanliness = 1;
      _hand.hardCut = false;
      _hand.polishMask = maskAsset == null
          ? null
          : game.images.fromCache(maskAsset);
      _hand.polishPlate = maskAsset == AssetPaths.finalHandDarkStilettoMask
          ? SpriteAtlas.finalHandDarkStilettoNailPlate
          : maskAsset == AssetPaths.finalHandStilettoMask
          ? SpriteAtlas.finalHandStilettoNailPlate
          : null;
      if (maskAsset == AssetPaths.finalHandStilettoMask) {
        // Per-digit masks + plates, same as the square reveal: each nail
        // gets its own gradient/shine instead of one stretched across a
        // plate spanning the whole hand (which washed out whichever finger
        // sat nearest that plate's horizontal centre — usually the middle
        // finger).
        _hand.digitPolishMasks = Map<NailDigit, ui.Image>.from(
          _lightStilettoFinalDigitMasks,
        );
        _hand.digitPolishPlates = _stilettoFinalDigitPlates;
        _hand.polishByDigit = Map<NailDigit, int>.from(
          polishByDigit ?? const <NailDigit, int>{},
        );
        _hand.polishColor = _pinky.polishColor;
      } else if (maskAsset == AssetPaths.finalHandDarkStilettoMask &&
          _darkStilettoFinalDigitMasks.isNotEmpty) {
        // Dark stiletto now carries the same per-digit split, so each nail
        // keeps its own colour and its own gradient axis instead of sharing
        // one plate stretched across the whole hand.
        _hand.digitPolishMasks = Map<NailDigit, ui.Image>.from(
          _darkStilettoFinalDigitMasks,
        );
        _hand.digitPolishPlates = _darkStilettoFinalDigitPlates;
        _hand.polishByDigit = Map<NailDigit, int>.from(
          polishByDigit ?? const <NailDigit, int>{},
        );
        _hand.polishColor = _pinky.polishColor;
      } else {
        // No split available for this art — one colour for the whole hand.
        _hand.digitPolishMasks = <NailDigit, ui.Image>{};
        _hand.digitPolishPlates = <NailDigit, SpriteRegion>{};
        _hand.polishByDigit = <NailDigit, int>{};
        _hand.polishColor =
            (polishByDigit != null && polishByDigit.isNotEmpty)
            ? polishByDigit.values.last
            : _pinky.polishColor;
      }
      _hand.polishFill = 1;
      // The wrist fade is per-canvas, so it comes from the kit rather than the
      // shared 0.34 fraction: the light stiletto points its fingers *up* and
      // feathers its own wrist (0), the dark one is cut flat at the top row
      // and needs only a hairline (0.10). The shared fraction used to eat the
      // top third of the dark hand.
      _hand.wristFadeEndOverride = _kit.stilettoFinalHandWristFadeEnd;
      _applyOpacity(_opacity);
      return;
    }
    final sheet = _kit.finalHandSheet;
    final scale = GameConfig.workspaceHandWidth / sheet.frameSize.x;
    _hand.frames = _finalFrames;
    _hand.frameAlign = sheet.frameAlign;
    _hand.size.setFrom(sheet.frameSize * scale);
    _hand.cleanliness = 1;
    _hand.hardCut = false;
    final dark = _kit.finalHandAsset == AssetPaths.finalHandDark;
    final light = _kit.finalHandAsset == AssetPaths.finalHandLight;
    _hand.polishMask = dark
        ? _darkFinalPolishMask
        : light
        ? _lightFinalPolishMask
        : null;
    _hand.digitPolishMasks = dark
        ? Map<NailDigit, ui.Image>.from(_darkFinalDigitMasks)
        : light
        ? Map<NailDigit, ui.Image>.from(_lightFinalDigitMasks)
        : <NailDigit, ui.Image>{};
    _hand.digitPolishPlates = dark
        ? _darkFinalDigitPlates
        : light
        ? _lightFinalDigitPlates
        : <NailDigit, SpriteRegion>{};
    _hand.polishPlate = dark
        ? SpriteAtlas.finalHandDarkNailPlate
        : light
        ? SpriteAtlas.finalHandLightNailPlate
        : null;
    _hand.polishByDigit = Map<NailDigit, int>.from(
      polishByDigit ?? const <NailDigit, int>{},
    );
    _hand.polishColor = _pinky.polishColor;
    _hand.polishFill = (dark || light) ? 1 : 0;
    // [finalHandLight]'s real-photo canvas has fingertips almost at y=0 —
    // the normal wrist-fade fraction (tuned for the old tall cartoon
    // canvas) faded out most of the polish on every finger but the thumb.
    // The photo already feathers its own edges, so it barely needs one.
    _hand.wristFadeEndOverride = light ? 0.0 : null;
    _applyOpacity(_opacity);
  }

  static final Map<NailDigit, SpriteRegion> _lightFinalDigitPlates =
      <NailDigit, SpriteRegion>{
        NailDigit.pinky: SpriteAtlas.finalHandLightNailPlatePinky,
        NailDigit.ring: SpriteAtlas.finalHandLightNailPlateRing,
        NailDigit.middle: SpriteAtlas.finalHandLightNailPlateMiddle,
        NailDigit.pointer: SpriteAtlas.finalHandLightNailPlatePointer,
        NailDigit.thumb: SpriteAtlas.finalHandLightNailPlateThumb,
      };

  static final Map<NailDigit, SpriteRegion> _darkFinalDigitPlates =
      <NailDigit, SpriteRegion>{
        NailDigit.pinky: SpriteAtlas.finalHandDarkNailPlatePinky,
        NailDigit.ring: SpriteAtlas.finalHandDarkNailPlateRing,
        NailDigit.middle: SpriteAtlas.finalHandDarkNailPlateMiddle,
        NailDigit.pointer: SpriteAtlas.finalHandDarkNailPlatePointer,
        NailDigit.thumb: SpriteAtlas.finalHandDarkNailPlateThumb,
      };

  static final Map<NailDigit, SpriteRegion> _stilettoFinalDigitPlates =
      <NailDigit, SpriteRegion>{
        NailDigit.pinky: SpriteAtlas.finalHandStilettoNailPlatePinky,
        NailDigit.ring: SpriteAtlas.finalHandStilettoNailPlateRing,
        NailDigit.middle: SpriteAtlas.finalHandStilettoNailPlateMiddle,
        NailDigit.pointer: SpriteAtlas.finalHandStilettoNailPlatePointer,
        NailDigit.thumb: SpriteAtlas.finalHandStilettoNailPlateThumb,
      };

  static final Map<NailDigit, SpriteRegion> _darkStilettoFinalDigitPlates =
      <NailDigit, SpriteRegion>{
        NailDigit.pinky: SpriteAtlas.finalHandDarkStilettoNailPlatePinky,
        NailDigit.ring: SpriteAtlas.finalHandDarkStilettoNailPlateRing,
        NailDigit.middle: SpriteAtlas.finalHandDarkStilettoNailPlateMiddle,
        NailDigit.pointer: SpriteAtlas.finalHandDarkStilettoNailPlatePointer,
        NailDigit.thumb: SpriteAtlas.finalHandDarkStilettoNailPlateThumb,
      };

  void _showWashHand({required double cleanliness}) {
    _showingPinky = false;
    _showingFinishedHand = false;
    _hand.position.y = GameConfig.workspaceHandCenterY;
    final wash = _kit.washSheet;
    final scale = GameConfig.workspaceHandWidth / wash.frameSize.x;
    _hand.frames = _washFrames;
    _hand.frameAlign = _kit.washFrameAlign;
    _hand.size.setFrom(wash.frameSize * scale);
    _hand.cleanliness = cleanliness;
    _hand.hardCut = false;
    _hand.polishFill = 0;
    _hand.polishMask = null;
    _hand.digitPolishMasks = <NailDigit, ui.Image>{};
    _hand.polishByDigit = <NailDigit, int>{};
  }

  /// Whole-foot soap wash, mirrors [_showWashHand] but on the foot art.
  void showFootWashHand({double cleanliness = 0}) {
    _showingPinky = false;
    _showingFinishedHand = false;
    _hand.position.y = GameConfig.workspaceHandCenterY;
    final scale = GameConfig.workspaceFootWidth / _kit.footWashSheet.frameSize.x;
    _hand.frames = _footWashFrames;
    _hand.frameAlign = SpriteAtlas.footFrameAlignZero;
    _hand.size.setFrom(_kit.footWashSheet.frameSize * scale);
    _hand.cleanliness = cleanliness;
    // The 4 source photos aren't on a locked pivot (each shifts/zooms
    // slightly), so cross-dissolving between them doubles-exposes two foot
    // positions at once. Hard-cut instead of blending.
    _hand.hardCut = true;
    _hand.polishFill = 0;
    _hand.polishMask = null;
    _hand.digitPolishMasks = <NailDigit, ui.Image>{};
    _hand.polishByDigit = <NailDigit, int>{};
  }

  /// Dirt lifts across the four foot-wash cells, same easing as [setWashProgress].
  void setFootWashProgress(double progress) {
    final t = progress.clamp(0.0, 1.0);
    showFootWashHand(cleanliness: t * t * (3 - 2 * t));
    _applyOpacity(_opacity);
  }

  /// Whole-foot toenail spray/wipe stages, driven by combined 0–1 progress.
  void showFootNailCleanHand({double cleanliness = 0}) {
    _showingPinky = false;
    _showingFinishedHand = false;
    _hand.position.y = GameConfig.workspaceHandCenterY;
    final scale =
        GameConfig.workspaceFootWidth / _kit.footNailCleanSheet.frameSize.x;
    _hand.frames = _footNailCleanFrames;
    _hand.frameAlign = SpriteAtlas.footFrameAlignZero;
    _hand.size.setFrom(_kit.footNailCleanSheet.frameSize * scale);
    _hand.cleanliness = cleanliness;
    _hand.hardCut = true;
    _hand.polishFill = 0;
    _hand.polishMask = null;
    _hand.digitPolishMasks = <NailDigit, ui.Image>{};
    _hand.polishByDigit = <NailDigit, int>{};
  }

  void setFootNailCleanProgress(double progress) {
    showFootNailCleanHand(cleanliness: progress.clamp(0.0, 1.0));
    _applyOpacity(_opacity);
  }

  /// Whole-foot toenail cutting strip — one clip snip steps to the next of
  /// the 4 frames, all toes shortening together (mirrors [setShortNailFrame]
  /// but for the foot card).
  void showFootNailCutFrame(int frame) {
    _showingPinky = false;
    _showingFinishedHand = false;
    // The cut sheet is a different, tighter-cropped photoshoot than
    // wash/clean (see [GuestCareKit.footNailCutVerticalOffset]) — without
    // this nudge the toes jump the moment cutting starts.
    _hand.position.y =
        GameConfig.workspaceHandCenterY + _kit.footNailCutVerticalOffset;
    final sheet = _kit.footNailCutSheet;
    final scale = GameConfig.workspaceFootWidth / sheet.frameSize.x;
    _hand.frames = _footNailCutFrames;
    _hand.frameAlign = SpriteAtlas.footFrameAlignZero;
    _hand.size.setFrom(sheet.frameSize * scale);
    final last = sheet.frameCount - 1;
    _hand.cleanliness = last <= 0 ? 0 : frame.clamp(0, last) / last;
    _hand.hardCut = true;
    _hand.polishFill = 0;
    _hand.polishMask = null;
    _hand.digitPolishMasks = <NailDigit, ui.Image>{};
    _hand.polishByDigit = <NailDigit, int>{};
    _applyOpacity(_opacity);
  }

  /// Lacquer every toenail on the finished cut frame. [fill] sweeps 0→1 the
  /// way [setPolishFill] does for a single finger, and the colour comes from
  /// the same picker, so a pedicure reads like the manicure it mirrors.
  void showFootPolish({required int color, double fill = 0}) {
    _showingPinky = false;
    _showingFinishedHand = false;
    // Same sheet as the cut stage, same nudge — see [showFootNailCutFrame].
    _hand.position.y =
        GameConfig.workspaceHandCenterY + _kit.footNailCutVerticalOffset;
    final sheet = _kit.footNailCutSheet;
    final scale = GameConfig.workspaceFootWidth / sheet.frameSize.x;
    _hand.frames = _footNailCutFrames;
    _hand.frameAlign = SpriteAtlas.footFrameAlignZero;
    _hand.size.setFrom(sheet.frameSize * scale);
    // Hold the fully clipped toes; only the lacquer animates from here.
    _hand.cleanliness = 1;
    _hand.hardCut = true;
    final dark = _kit.footNailPolishMaskAsset == AssetPaths.footNailPolishMaskDark;
    _hand.polishMask = game.images.fromCache(_kit.footNailPolishMaskAsset);
    _hand.polishPlate = dark
        ? SpriteAtlas.footNailPolishPlateDark
        : SpriteAtlas.footNailPolishPlateLight;
    if (dark) {
      // Dark foot still has only the single unified mask.
      _hand.digitPolishMasks = <NailDigit, ui.Image>{};
      _hand.digitPolishPlates = <NailDigit, SpriteRegion>{};
      _hand.polishByDigit = <NailDigit, int>{};
    } else {
      // Per-toe masks + plates, same fix as the stiletto hand: each toe
      // gets its own gradient/shine instead of one stretched across a
      // plate spanning the whole foot (which washed out whichever toe sat
      // nearest that plate's centre). All 5 toes still take the same
      // colour — [polishByDigit] here exists only to key the per-digit
      // paint loop, not to track distinct choices per toe.
      _hand.digitPolishMasks = Map<NailDigit, ui.Image>.from(
        _lightToeDigitMasks,
      );
      _hand.digitPolishPlates = _toeDigitPlates;
      _hand.polishByDigit = <NailDigit, int>{
        for (final digit in _toeDigitPlates.keys) digit: color,
      };
    }
    _hand.polishColor = color;
    _hand.polishFill = fill.clamp(0.0, 1.0);
    _applyOpacity(_opacity);
  }

  static final Map<NailDigit, SpriteRegion> _toeDigitPlates =
      <NailDigit, SpriteRegion>{
        NailDigit.thumb: SpriteAtlas.footNailPolishPlateLightThumb,
        NailDigit.pointer: SpriteAtlas.footNailPolishPlateLightPointer,
        NailDigit.middle: SpriteAtlas.footNailPolishPlateLightMiddle,
        NailDigit.ring: SpriteAtlas.footNailPolishPlateLightRing,
        NailDigit.pinky: SpriteAtlas.footNailPolishPlateLightPinky,
      };

  void beginSprayTreatment(NailDigit digit, {int frame = 0}) {
    showFinger(digit, frame: frame);
    _pinky.useSpraySheet();
    _pinky.setFrame(frame);
    hideSprayMist();
    _applyOpacity(_opacity);
  }

  void beginWipeTreatment(NailDigit digit, {int frame = 0}) {
    _pinky.useWipeSheet();
    _pinky.setFrame(frame);
    hideSprayMist();
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
      pinToSlot: false,
    );
    _bindTreatmentArt(
      NailFingerTreatmentCatalog.pinky,
      sprayImage: _pinkySprayImage,
      wipeImage: _pinkyWipeImage,
    );
    _showingPinky = true;
    _pinky.useSpraySheet();
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
      pinToSlot: false,
    );
    _bindTreatmentArt(
      NailFingerTreatmentCatalog.ring,
      sprayImage: _ringSprayImage,
      wipeImage: _ringWipeImage,
    );
    _showingPinky = true;
    _pinky.useSpraySheet();
    _pinky.setFrame(frame);
    _pinky.clearPolish();
    _applyOpacity(_opacity);
  }

  void showFinger(NailDigit digit, {int frame = 0}) {
    final digitArt = _kit.artFor(digit);
    if (digitArt != null) {
      _bindGuestDigit(digit, digitArt);
      _showingPinky = true;
      _pinky.useCleanSheet();
      _pinky.setFrame(frame);
      _pinky.clearPolish();
      _applyOpacity(_opacity);
      return;
    }
    if (_kit.unifiedNailClean) {
      _bindUnifiedNail();
      _showingPinky = true;
      _pinky.useCleanSheet();
      _pinky.setFrame(frame);
      _pinky.clearPolish();
      _applyOpacity(_opacity);
      return;
    }
    switch (digit) {
      case NailDigit.pinky:
        showPinkyNail(frame: frame);
      case NailDigit.ring:
        showRingNail(frame: frame);
      case NailDigit.middle:
        _bindFinger(
          cleanImage: _middleCleanImage,
          shortImage: _middleShortImage,
          polishMask: _middlePolishMask,
          polishPlate: SpriteAtlas.thirdNailPlate,
          cleanSheet: SpriteAtlas.thirdNailClean,
          shortSheet: SpriteAtlas.thirdNailShort,
          shortAlign: Vector2.zero(),
          pinToSlot: true,
        );
        _bindTreatmentArt(
          NailFingerTreatmentCatalog.artFor(NailDigit.middle),
          sprayImage: _middleCleanImage,
          wipeImage: _middleCleanImage,
        );
        _showingPinky = true;
        _pinky.useCleanSheet();
        _pinky.setFrame(frame);
        _pinky.clearPolish();
        _applyOpacity(_opacity);
      case NailDigit.pointer:
        _bindFinger(
          cleanImage: _indexCleanImage,
          shortImage: _indexShortImage,
          polishMask: _indexPolishMask,
          polishPlate: SpriteAtlas.secondNailPlate,
          cleanSheet: SpriteAtlas.secondNailClean,
          shortSheet: SpriteAtlas.secondNailShort,
          shortAlign: Vector2.zero(),
          pinToSlot: true,
        );
        _bindTreatmentArt(
          NailFingerTreatmentCatalog.artFor(NailDigit.pointer),
          sprayImage: _indexCleanImage,
          wipeImage: _indexCleanImage,
        );
        _showingPinky = true;
        _pinky.useCleanSheet();
        _pinky.setFrame(frame);
        _pinky.clearPolish();
        _applyOpacity(_opacity);
      case NailDigit.thumb:
        _bindFinger(
          cleanImage: _thumbCleanImage,
          shortImage: _thumbShortImage,
          polishMask: _thumbPolishMask,
          polishPlate: SpriteAtlas.firstNailPlate,
          cleanSheet: SpriteAtlas.firstNailClean,
          shortSheet: SpriteAtlas.firstNailShort,
          shortAlign: Vector2.zero(),
          pinToSlot: true,
        );
        _bindTreatmentArt(
          NailFingerTreatmentCatalog.artFor(NailDigit.thumb),
          sprayImage: _thumbCleanImage,
          wipeImage: _thumbCleanImage,
        );
        _showingPinky = true;
        _pinky.useCleanSheet();
        _pinky.setFrame(frame);
        _pinky.clearPolish();
        _applyOpacity(_opacity);
    }
  }

  void _bindGuestDigit(NailDigit digit, GuestDigitCareArt art) {
    final cleanImage = game.images.fromCache(art.cleanAsset);
    final shortImage = game.images.fromCache(art.shortAsset);
    final polishMask = game.images.fromCache(art.polishMaskAsset);
    _bindFinger(
      cleanImage: cleanImage,
      shortImage: shortImage,
      polishMask: polishMask,
      polishPlate: art.polishPlate,
      cleanSheet: art.cleanSheet,
      shortSheet: art.shortSheet,
      shortAlign: Vector2.zero(),
      pinToSlot: true,
    );
    _bindTreatmentArt(
      NailFingerTreatmentArt(
        sprayAsset: art.cleanAsset,
        wipeAsset: art.cleanAsset,
        spraySheet: art.cleanSheet,
        wipeSheet: art.cleanSheet,
        legacyCleanAsset: art.cleanAsset,
        legacyCleanSheet: art.cleanSheet,
      ),
      sprayImage: cleanImage,
      wipeImage: cleanImage,
    );
  }

  void _bindUnifiedNail() {
    final shortAsset = _kit.shortNailAsset ?? AssetPaths.shortNail;
    final maskAsset = _kit.polishMaskAsset ?? AssetPaths.pinkNailMask;
    final polishPlate = _kit.polishPlate ?? SpriteAtlas.pinkNailPlate;
    final shortSheet = _kit.shortNailSheet ?? SpriteAtlas.shortNail;
    _bindFinger(
      cleanImage: game.images.fromCache(_kit.nailCleanAsset),
      shortImage: game.images.fromCache(shortAsset),
      polishMask: game.images.fromCache(maskAsset),
      polishPlate: polishPlate,
      cleanSheet: _kit.nailCleanSheet,
      shortSheet: shortSheet,
      shortAlign: Vector2.zero(),
      pinToSlot: true,
    );
    _bindTreatmentArt(
      NailFingerTreatmentArt(
        sprayAsset: _kit.nailCleanAsset,
        wipeAsset: _kit.nailCleanAsset,
        spraySheet: _kit.nailCleanSheet,
        wipeSheet: _kit.nailCleanSheet,
        legacyCleanAsset: _kit.nailCleanAsset,
        legacyCleanSheet: _kit.nailCleanSheet,
      ),
      sprayImage: game.images.fromCache(_kit.nailCleanAsset),
      wipeImage: game.images.fromCache(_kit.nailCleanAsset),
    );
  }

  void _bindFinger({
    required ui.Image cleanImage,
    required ui.Image shortImage,
    required ui.Image polishMask,
    required SpriteRegion polishPlate,
    required CharacterSheet cleanSheet,
    required CharacterSheet shortSheet,
    required Vector2 shortAlign,
    required bool pinToSlot,
  }) {
    _pinky.cleanImage = cleanImage;
    _pinky.shortImage = shortImage;
    _pinky.polishMask = polishMask;
    _pinky.polishPlate = polishPlate;
    _pinky.cleanSheet = cleanSheet;
    _pinky.shortSheet = shortSheet;
    _pinky.shortAlign = shortAlign;
    _pinky.pinToSlot = pinToSlot;
    final scale =
        GameConfig.pinkySpriteHeight / SpriteAtlas.fifthNailClean.frameSize.y;
    _pinky.size.setFrom(SpriteAtlas.fifthNailClean.frameSize * scale);
    _pinky.position.setValues(
      GameConfig.pinkySpriteCenterX,
      GameConfig.pinkySpriteCenterY,
    );
  }

  void _bindTreatmentArt(
    NailFingerTreatmentArt art, {
    required ui.Image sprayImage,
    required ui.Image wipeImage,
  }) {
    _pinky.splitSprayWipe = art.splitSprayWipe;
    _pinky.spraySheet = art.spraySheet;
    _pinky.wipeSheet = art.wipeSheet;
    _pinky.sprayImage = sprayImage;
    _pinky.wipeImage = wipeImage;
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

  /// Swap the clip sheet + polish mask for the chosen shape, always staying on
  /// the seated guest's own art.
  ///
  /// Both branches must come from [_kit]: borrowing the legacy cartoon short
  /// sheet here is what used to jitter the nail between clip frames (its
  /// [CharacterSheet.frameAlign] carries a per-frame shift) and paint the
  /// cartoon mask onto a photographic hand.
  void setNailShape(NailShape shape, {NailDigit digit = NailDigit.pinky}) {
    // Every mask below is registered to its own art, so no nudge is needed.
    _pinky.polishMaskRotation = 0;
    _pinky.polishMaskPivot = const ui.Offset(0.5, 0.5);

    if (shape == NailShape.stiletto) {
      final stiletto = _kit.stilettoArtFor(digit);
      if (stiletto != null) {
        _pinky.shortImage = game.images.fromCache(stiletto.shortAsset);
        _pinky.shortSheet = stiletto.shortSheet;
        _pinky.polishMask = game.images.fromCache(stiletto.polishMaskAsset);
        _pinky.polishPlate = stiletto.polishPlate;
        _pinky.shortAlign = Vector2.zero();
        _pinky.useShortSheet();
        return;
      }
      // No stiletto set for this guest — fall through to her square art
      // rather than borrowing another guest's hand.
    }

    final art = _kit.artFor(digit);
    if (art != null) {
      _pinky.shortImage = game.images.fromCache(art.shortAsset);
      _pinky.shortSheet = art.shortSheet;
      _pinky.polishMask = game.images.fromCache(art.polishMaskAsset);
      _pinky.polishPlate = art.polishPlate;
      _pinky.shortAlign = Vector2.zero();
      _pinky.useShortSheet();
      return;
    }

    final kitShort = _kit.shortNailAsset;
    final kitMask = _kit.polishMaskAsset;
    final kitPlate = _kit.polishPlate;
    final kitSheet = _kit.shortNailSheet;
    if (kitShort != null &&
        kitMask != null &&
        kitPlate != null &&
        kitSheet != null) {
      _pinky.shortImage = game.images.fromCache(kitShort);
      _pinky.shortSheet = kitSheet;
      _pinky.polishMask = game.images.fromCache(kitMask);
      _pinky.polishPlate = kitPlate;
      _pinky.shortAlign = Vector2.zero();
      _pinky.useShortSheet();
      return;
    }

    // Last resort: the original cartoon pinky, for guests with no art at all.
    _pinky.shortImage = _shortNailImage;
    _pinky.shortSheet = SpriteAtlas.shortNail;
    _pinky.polishMask = _polishMask;
    _pinky.polishPlate = SpriteAtlas.pinkNailPlate;
    _pinky.shortAlign = SpriteAtlas.shortNailAlign;
    _pinky.useShortSheet();
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

  ui.Image _image;
  double opacity = 0;

  void setImage(ui.Image image) {
    _image = image;
  }

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
          const <ui.Color>[ui.Color(0x00000000), ui.Color(0x590C0806)],
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
    required this.frameAlign,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center);

  List<Sprite> frames;
  List<Vector2> frameAlign;
  double cleanliness = 0;
  double opacity = 0;
  /// When true, snap to the nearest frame instead of cross-dissolving. Needed
  /// for sequences whose source photos aren't on a locked pivot — blending
  /// two different foot positions doubles-exposes both at once.
  bool hardCut = false;
  ui.Image? polishMask;
  Map<NailDigit, ui.Image> digitPolishMasks = <NailDigit, ui.Image>{};
  Map<NailDigit, int> polishByDigit = <NailDigit, int>{};
  int polishColor = 0xFFFF6BA8;
  double polishFill = 0;

  /// Nail plate rect for [polishMask], in that mask's own pixel space — the
  /// finished-hand counterpart of [_LockedFingerCloseup.polishPlate].
  SpriteRegion? polishPlate;

  /// Per-digit plate rects for [digitPolishMasks], keyed the same way.
  Map<NailDigit, SpriteRegion> digitPolishPlates = <NailDigit, SpriteRegion>{};

  /// Overrides the computed wrist-fade fraction in [render] when set
  /// (null keeps the normal computation). The default fade assumes the old
  /// tall 833×1446 cartoon canvas, where fingertips sit well below the top
  /// edge; [AssetPaths.finalHandLight]'s real-photo canvas is much
  /// squatter (769×1024) with nails starting almost at y=0, so the same
  /// fraction faded out most of the polish on every finger except the
  /// thumb. The photo's own alpha already feathers its edges, so this
  /// asset barely needs a synthetic fade at all.
  double? wristFadeEndOverride;

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0 || frames.isEmpty) {
      return;
    }
    final last = frames.length - 1;
    final pos = cleanliness.clamp(0.0, 1.0) * last;
    final int from;
    final int to;
    final double fade;
    if (hardCut) {
      from = pos.round().clamp(0, last);
      to = from;
      fade = 0;
    } else {
      from = pos.floor().clamp(0, last);
      to = (from + 1).clamp(0, last);
      final t = pos - from;
      fade = t * t * (3 - 2 * t);
    }
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    final aligns = frameAlign;
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
    _paintFinishedPolish(canvas, frames[from], fromAlign);
    // Soft wrist falloff so the silhouette doesn't stamp a hard rectangle
    // onto the tabletop. Finished hands need a longer fade than wash frames.
    final wristEnd = wristFadeEndOverride ??
        (polishFill > 0
            ? (GameConfig.workspaceHandWristFadeEnd * 1.55).clamp(0.2, 0.42)
            : GameConfig.workspaceHandWristFadeEnd);
    // A zero-height gradient (wristEnd <= 0, i.e. the fade is disabled for
    // this asset) has coincident start/end points, which Gradient.linear
    // rejects — skip the fade draw entirely rather than pass one.
    if (wristEnd > 0) {
      canvas.drawRect(
        rect,
        ui.Paint()
          ..blendMode = ui.BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            ui.Offset(size.x / 2, 0),
            ui.Offset(size.x / 2, size.y * wristEnd),
            const <ui.Color>[ui.Color(0x00FFFFFF), ui.Color(0xFFFFFFFF)],
          ),
      );
    }
    canvas.restore();
  }

  void _paintFinishedPolish(ui.Canvas canvas, Sprite sprite, Vector2 align) {
    if (polishFill <= 0) {
      return;
    }
    final scaleX = size.x / sprite.srcSize.x;
    final scaleY = size.y / sprite.srcSize.y;
    canvas.save();
    canvas.translate(align.x * scaleX, align.y * scaleY);
    final local = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    final src = ui.Rect.fromLTWH(
      sprite.srcPosition.x,
      sprite.srcPosition.y,
      sprite.srcSize.x,
      sprite.srcSize.y,
    );
    final coats = <({ui.Image mask, int color, SpriteRegion? plate})>[];
    if (digitPolishMasks.isNotEmpty && polishByDigit.isNotEmpty) {
      for (final digit in NailDigit.values) {
        final digitMask = digitPolishMasks[digit];
        final color = polishByDigit[digit];
        if (digitMask == null || color == null || color == 0) {
          continue;
        }
        coats.add((
          mask: digitMask,
          color: color,
          plate: digitPolishPlates[digit],
        ));
      }
    }
    if (coats.isEmpty && polishMask != null) {
      coats.add((mask: polishMask!, color: polishColor, plate: polishPlate));
    }
    for (final coat in coats) {
      _paintLacquerCoat(canvas, local, src, coat.plate, coat.mask, coat.color);
    }
    canvas.restore();
  }

  /// Glossy lacquer clipped strictly to the nail mask — never paints the hand
  /// bounding box (that caused the pink/dark square on the wood). Delegates
  /// the actual tint/depth/shine painting to [_paintNailLacquerCoat], the
  /// same routine the live per-digit paint uses, so the finished reveal
  /// reads as the same polish instead of a separately-tuned pastel copy.
  void _paintLacquerCoat(
    ui.Canvas canvas,
    ui.Rect local,
    ui.Rect src,
    SpriteRegion? plateRegion,
    ui.Image mask,
    int coatColor,
  ) {
    final maskSrc = ui.Rect.fromLTWH(
      src.left,
      src.top,
      src.width,
      src.height,
    );
    final plate = _mapLacquerPlate(plateRegion, maskSrc, local);

    canvas.saveLayer(
      local,
      ui.Paint()..color = ui.Color.fromRGBO(255, 255, 255, polishFill),
    );
    _paintNailLacquerCoat(canvas, local, plate, mask, maskSrc, coatColor);
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
    required this.pinToSlot,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center);

  ui.Image cleanImage;
  ui.Image shortImage;
  ui.Image polishMask;
  SpriteRegion polishPlate;
  CharacterSheet cleanSheet;
  CharacterSheet shortSheet;
  CharacterSheet? spraySheet;
  CharacterSheet? wipeSheet;
  ui.Image? sprayImage;
  ui.Image? wipeImage;
  bool splitSprayWipe = false;
  Vector2 shortAlign;
  bool pinToSlot;

  double opacity = 0;
  bool _short = false;
  NailTreatmentPhase _treatmentPhase = NailTreatmentPhase.spray;
  int _frame = 0;
  int polishColor = 0xFFFF6BA8;
  double polishFill = 0;

  /// Small clockwise correction (radians) for a polish mask whose tip is
  /// traced a hair off-angle from the nail art it's meant to clip. Applied
  /// around [polishMaskPivot] (fraction of dest). Zero for masks that are
  /// already registered correctly.
  double polishMaskRotation = 0;
  ui.Offset polishMaskPivot = const ui.Offset(0.5, 0.5);

  CharacterSheet get _activeCleanSheet => !splitSprayWipe
      ? cleanSheet
      : _treatmentPhase == NailTreatmentPhase.spray
      ? spraySheet!
      : wipeSheet!;

  ui.Image get _activeCleanImage => !splitSprayWipe
      ? cleanImage
      : _treatmentPhase == NailTreatmentPhase.spray
      ? sprayImage!
      : wipeImage!;

  void useCleanSheet() {
    _short = false;
    _treatmentPhase = NailTreatmentPhase.spray;
  }

  void useSpraySheet() {
    _short = false;
    _treatmentPhase = NailTreatmentPhase.spray;
  }

  void useWipeSheet() {
    _short = false;
    _treatmentPhase = NailTreatmentPhase.wipe;
  }

  void useShortSheet() => _short = true;

  void setFrame(int index) {
    final count = (_short ? shortSheet : _activeCleanSheet).frameCount;
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
    final sheet = _short ? shortSheet : _activeCleanSheet;
    final image = _short ? shortImage : _activeCleanImage;
    final origin = sheet.framePositions[_frame];
    // Pinky close-up slot. [frameAlign] keeps the stump on frame 0.
    final slot = SpriteAtlas.fifthNailClean.frameSize;
    // `drawImageRect` below stretches whatever frame rect we hand it
    // straight into the box, aspect mismatch or not — every close-up sheet
    // in the game (both the 355×879 "fifth nail" convention and the
    // 464×1398 real-photo convention the other digits use) is tuned to
    // look right stretched that way, so cropping by aspect here as a
    // general rule would fight that tuning. The sole known exception is
    // [SpriteAtlas.thumbCleanDarkWipe] (2103×748 photo strip, much wider
    // than either convention): stretched into the tall/narrow box it
    // visibly squashes the finger sideways and elongates it. Crop that one
    // sheet to the box aspect, centered on the frame, instead of stretching.
    var srcX = origin.x;
    var srcY = origin.y;
    var srcW = sheet.frameSize.x;
    var srcH = sheet.frameSize.y;
    if (identical(sheet, SpriteAtlas.thumbCleanDarkWipe)) {
      final boxAspect = slot.x / slot.y;
      final wantedW = srcH * boxAspect;
      srcX += (srcW - wantedW) / 2;
      srcW = wantedW;
    }
    final src = ui.Rect.fromLTWH(srcX, srcY, srcW, srcH);
    final scaleX = size.x / slot.x;
    final scaleY = size.y / slot.y;
    // Both the clean/spray/wipe frames and the cut frames are mapped through
    // the *source frame's own* size, so a sheet that is not authored on the
    // 355×879 slot convention keeps its aspect instead of being squeezed into
    // the slot. The thumb is the digit this matters for: its photo sheets are
    // 464×1398 (0.332) against the slot's 0.404, so the old `slot`-based
    // clean branch stretched it ~22% wider than its own cut frames — the
    // finger appeared to grow a cut-off right edge during spray and then jump
    // the moment cutting swapped in the short sheet. Same rect for both
    // branches, so nothing moves between stages.
    var dest = pinToSlot
        ? ui.Rect.fromLTWH(0, 0, size.x, size.y)
        : ui.Rect.fromLTWH(
            _short ? shortAlign.x * scaleX : 0,
            _short ? shortAlign.y * scaleY : 0,
            srcW * scaleX,
            srcH * scaleY,
          );
    final align = sheet.frameAlign[_frame];
    dest = dest.shift(
      ui.Offset(
        align.x * dest.width / srcW,
        align.y * dest.height / srcH,
      ),
    );
    final padX =
        math.max(dest.left.abs(), math.max(0.0, dest.right - size.x)) + 2;
    final padY =
        math.max(dest.top.abs(), math.max(0.0, dest.bottom - size.y)) + 2;
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
          ui.Offset(
            dest.left,
            dest.top + dest.height * GameConfig.pinkyStumpFadeEnd,
          ),
          const <ui.Color>[ui.Color(0x00FFFFFF), ui.Color(0xFFFFFFFF)],
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
    final plate = _mapLacquerPlate(polishPlate, maskSrc, dest);

    final needsRotation = polishMaskRotation != 0;
    if (needsRotation) {
      final pivot = ui.Offset(
        dest.left + polishMaskPivot.dx * dest.width,
        dest.top + polishMaskPivot.dy * dest.height,
      );
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(polishMaskRotation);
      canvas.translate(-pivot.dx, -pivot.dy);
    }

    canvas.saveLayer(dest, ui.Paint());
    _paintNailLacquerCoat(canvas, dest, plate, polishMask, maskSrc, polishColor);

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
    if (needsRotation) {
      canvas.restore();
    }
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
