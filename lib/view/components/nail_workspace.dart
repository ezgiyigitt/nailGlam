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
  late final ui.Image _stilettoNailImage;
  late final ui.Image _polishMask;
  late final ui.Image _stilettoPolishMask;
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
      width: 833,
      height: 1446,
    );
    _lightFinalDigitMasks[NailDigit.pinky] = await _loadOptional(
      AssetPaths.finalHandLightNailPinky,
      width: 833,
      height: 1446,
    );
    _lightFinalDigitMasks[NailDigit.ring] = await _loadOptional(
      AssetPaths.finalHandLightNailRing,
      width: 833,
      height: 1446,
    );
    _lightFinalDigitMasks[NailDigit.middle] = await _loadOptional(
      AssetPaths.finalHandLightNailMiddle,
      width: 833,
      height: 1446,
    );
    _lightFinalDigitMasks[NailDigit.pointer] = await _loadOptional(
      AssetPaths.finalHandLightNailPointer,
      width: 833,
      height: 1446,
    );
    _lightFinalDigitMasks[NailDigit.thumb] = await _loadOptional(
      AssetPaths.finalHandLightNailThumb,
      width: 833,
      height: 1446,
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
    _stilettoNailImage = await game.images.load(AssetPaths.pinkyStilettoNail);
    _stilettoPolishMask = await game.images.load(AssetPaths.nailMaskLightPinky);
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

  /// Finished manicure still from the active guest's reveal art.
  void showFinishedHand([Map<NailDigit, int>? polishByDigit]) {
    _showingPinky = false;
    _showingFinishedHand = true;
    final sheet = _kit.finalHandSheet;
    final scale = GameConfig.workspaceHandWidth / sheet.frameSize.x;
    _hand.frames = _finalFrames;
    _hand.frameAlign = sheet.frameAlign;
    _hand.size.setFrom(sheet.frameSize * scale);
    _hand.cleanliness = 1;
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
    _hand.polishByDigit = Map<NailDigit, int>.from(
      polishByDigit ?? const <NailDigit, int>{},
    );
    _hand.polishColor = _pinky.polishColor;
    _hand.polishFill = (dark || light) ? 1 : 0;
    hideSprayMist();
    _applyOpacity(_opacity);
  }

  void _showWashHand({required double cleanliness}) {
    _showingPinky = false;
    _showingFinishedHand = false;
    final wash = _kit.washSheet;
    final scale = GameConfig.workspaceHandWidth / wash.frameSize.x;
    _hand.frames = _washFrames;
    _hand.frameAlign = _kit.washFrameAlign;
    _hand.size.setFrom(wash.frameSize * scale);
    _hand.cleanliness = cleanliness;
    _hand.polishFill = 0;
    _hand.polishMask = null;
    _hand.digitPolishMasks = <NailDigit, ui.Image>{};
    _hand.polishByDigit = <NailDigit, int>{};
  }

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

  void setNailShape(NailShape shape) {
    if (shape == NailShape.stiletto) {
      _pinky.shortImage = _stilettoNailImage;
      _pinky.shortSheet = SpriteAtlas.pinkyStilettoNail;
      _pinky.polishMask = _stilettoPolishMask;
      _pinky.polishPlate = SpriteAtlas.pinkyStilettoNailPlate;
      _pinky.shortAlign = Vector2.zero();
    } else {
      _pinky.shortImage = _shortNailImage;
      _pinky.shortSheet = SpriteAtlas.shortNail;
      _pinky.polishMask = _polishMask;
      _pinky.polishPlate = SpriteAtlas.pinkNailPlate;
      _pinky.shortAlign = SpriteAtlas.shortNailAlign;
    }
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
  ui.Image? polishMask;
  Map<NailDigit, ui.Image> digitPolishMasks = <NailDigit, ui.Image>{};
  Map<NailDigit, int> polishByDigit = <NailDigit, int>{};
  int polishColor = 0xFFFF6BA8;
  double polishFill = 0;

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
    final wristEnd = polishFill > 0
        ? (GameConfig.workspaceHandWristFadeEnd * 1.55).clamp(0.2, 0.42)
        : GameConfig.workspaceHandWristFadeEnd;
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
    final coats = <MapEntry<ui.Image, int>>[];
    if (digitPolishMasks.isNotEmpty && polishByDigit.isNotEmpty) {
      for (final digit in NailDigit.values) {
        final digitMask = digitPolishMasks[digit];
        final color = polishByDigit[digit];
        if (digitMask == null || color == null || color == 0) {
          continue;
        }
        coats.add(MapEntry<ui.Image, int>(digitMask, color));
      }
    }
    if (coats.isEmpty && polishMask != null) {
      coats.add(MapEntry<ui.Image, int>(polishMask!, polishColor));
    }
    for (final coat in coats) {
      _paintLacquerCoat(canvas, local, src, coat.key, coat.value);
    }
    canvas.restore();
  }

  /// Glossy lacquer clipped strictly to the nail mask — never paints the hand
  /// bounding box (that caused the pink/dark square on the wood).
  void _paintLacquerCoat(
    ui.Canvas canvas,
    ui.Rect local,
    ui.Rect src,
    ui.Image mask,
    int coatColor,
  ) {
    final base = ui.Color(coatColor);
    final maskSrc = ui.Rect.fromLTWH(
      src.left,
      src.top,
      src.width,
      src.height,
    );
    final clip = ui.Paint()
      ..filterQuality = FilterQuality.high
      ..blendMode = ui.BlendMode.dstIn;
    final sample = ui.Paint()..filterQuality = FilterQuality.high;

    canvas.saveLayer(
      local,
      ui.Paint()..color = ui.Color.fromRGBO(255, 255, 255, polishFill),
    );

    // 1) Solid lacquer body from mask pixels only.
    canvas.drawImageRect(
      mask,
      maskSrc,
      local,
      ui.Paint()
        ..filterQuality = FilterQuality.high
        ..colorFilter = ui.ColorFilter.mode(base, ui.BlendMode.modulate),
    );

    // 2) Wet depth: darker at cuticle, lighter at free edge — mask-clipped.
    canvas.saveLayer(
      local,
      ui.Paint()..blendMode = ui.BlendMode.softLight,
    );
    canvas.drawRect(
      local,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(local.center.dx, local.top),
          ui.Offset(local.center.dx, local.bottom),
          <ui.Color>[
            ui.Color.fromRGBO(0, 0, 0, 0.45),
            ui.Color.fromRGBO(40, 20, 30, 0.08),
            ui.Color.fromRGBO(255, 255, 255, 0.35),
            ui.Color.fromRGBO(255, 240, 250, 0.12),
          ],
          const <double>[0.0, 0.38, 0.72, 1.0],
        ),
    );
    canvas.drawImageRect(mask, maskSrc, local, clip);
    canvas.restore();

    // 3) Diagonal studio specular across the hand; each nail keeps its slice.
    canvas.saveLayer(
      local,
      ui.Paint()..blendMode = ui.BlendMode.plus,
    );
    canvas.drawRect(
      local,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(local.left, local.top),
          ui.Offset(local.right, local.bottom),
          const <ui.Color>[
            ui.Color(0x00FFFFFF),
            ui.Color(0x00FFFFFF),
            ui.Color(0xCCFFFFFF),
            ui.Color(0x55FFFFFF),
            ui.Color(0x00FFFFFF),
            ui.Color(0x00FFFFFF),
          ],
          const <double>[0.0, 0.40, 0.47, 0.52, 0.60, 1.0],
        ),
    );
    canvas.drawImageRect(mask, maskSrc, local, clip);
    canvas.restore();

    // 4) Narrow secondary highlight for gel-polish punch.
    canvas.saveLayer(
      local,
      ui.Paint()..blendMode = ui.BlendMode.screen,
    );
    canvas.drawRect(
      local,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(local.left + local.width * 0.2, local.top),
          ui.Offset(local.left + local.width * 0.55, local.bottom),
          const <ui.Color>[
            ui.Color(0x00FFFFFF),
            ui.Color(0x88FFFFFF),
            ui.Color(0x00FFFFFF),
          ],
          const <double>[0.35, 0.5, 0.65],
        ),
    );
    canvas.drawImageRect(mask, maskSrc, local, clip);
    canvas.restore();

    // 5) Soft rim so polish meets skin without a black sticker edge.
    canvas.saveLayer(
      local,
      ui.Paint()
        ..blendMode = ui.BlendMode.srcATop
        ..color = const ui.Color(0x33FFFFFF),
    );
    canvas.drawImageRect(mask, maskSrc, local, sample);
    canvas.restore();

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
    final src = ui.Rect.fromLTWH(
      origin.x,
      origin.y,
      sheet.frameSize.x,
      sheet.frameSize.y,
    );
    // Pinky close-up slot. [frameAlign] keeps the stump on frame 0.
    final slot = SpriteAtlas.fifthNailClean.frameSize;
    final scaleX = size.x / slot.x;
    final scaleY = size.y / slot.y;
    var dest = pinToSlot
        ? ui.Rect.fromLTWH(0, 0, size.x, size.y)
        : ui.Rect.fromLTWH(
            _short ? shortAlign.x * scaleX : 0,
            _short ? shortAlign.y * scaleY : 0,
            (_short ? sheet.frameSize.x : slot.x) * scaleX,
            (_short ? sheet.frameSize.y : slot.y) * scaleY,
          );
    final align = sheet.frameAlign[_frame];
    dest = dest.shift(
      ui.Offset(
        align.x * dest.width / sheet.frameSize.x,
        align.y * dest.height / sheet.frameSize.y,
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
    final plate = ui.Rect.fromLTWH(
      dest.left + polishPlate.position.x / polishMask.width * dest.width,
      dest.top + polishPlate.position.y / polishMask.height * dest.height,
      polishPlate.size.x / polishMask.width * dest.width,
      polishPlate.size.y / polishMask.height * dest.height,
    );
    final base = ui.Color(polishColor);
    final maskPaint = ui.Paint()
      ..filterQuality = FilterQuality.high
      ..blendMode = ui.BlendMode.dstIn
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 0.6);

    canvas.saveLayer(dest, ui.Paint());

    // Lacquer body: tint the nail plate, keep its natural gloss (like the approval still).
    canvas.saveLayer(dest, ui.Paint()..blendMode = ui.BlendMode.color);
    canvas.drawRect(
      plate.inflate(1),
      ui.Paint()..color = base.withAlpha(238),
    );
    canvas.drawImageRect(
      polishMask,
      maskSrc,
      dest,
      maskPaint,
    );
    canvas.restore();

    // Soft depth: slightly richer at the cuticle, lighter toward the free edge.
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
    canvas.drawImageRect(
      polishMask,
      maskSrc,
      dest,
      maskPaint,
    );
    canvas.restore();

    // Wet center streak — follows the still's vertical highlight.
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
        ..shader = ui.Gradient.linear(
          ui.Offset(shine.center.dx, shine.top),
          ui.Offset(shine.center.dx, shine.bottom),
          const <ui.Color>[
            ui.Color(0x00FFFFFF),
            ui.Color(0xCCFFFFFF),
            ui.Color(0x66FFFFFF),
            ui.Color(0x00FFFFFF),
          ],
          const <double>[0, 0.18, 0.55, 1],
        ),
    );
    canvas.drawImageRect(
      polishMask,
      maskSrc,
      dest,
      maskPaint,
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
