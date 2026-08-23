import 'package:flame/components.dart';

/// Source rectangles for every sprite, measured from the delivered art.
abstract final class SpriteAtlas {
  /// 1544×841, 4×1 walk from pipeline (identity-locked, not old walk sheet).
  static final CharacterSheet customerWalk = CharacterSheet(
    frameSize: Vector2(386, 841),
    displayScale: 1.32,
    footPaddings: const <double>[24, 24, 24, 24],
    framePositions: <Vector2>[
      for (var i = 0; i < 4; i++) Vector2(i * 386.0, 0),
    ],
  );

  /// Balanced stand — first turn pose.
  static final CharacterSheet customerStop = CharacterSheet(
    frameSize: Vector2(271, 934),
    displayScale: 1.19,
    footPaddings: const <double>[24],
    framePositions: <Vector2>[Vector2.zero()],
  );

  /// 1120×941, 4×1 turn toward chair/camera.
  static final CharacterSheet customerTurn = CharacterSheet(
    frameSize: Vector2(280, 941),
    displayScale: 1.18,
    footPaddings: const <double>[22, 22, 22, 22],
    framePositions: <Vector2>[
      for (var i = 0; i < 4; i++) Vector2(i * 280.0, 0),
    ],
  );

  /// 1492×879, 4×1 sit-down. Chair is a separate world prop.
  static final CharacterSheet customerSit = CharacterSheet(
    frameSize: Vector2(373, 879),
    displayScale: 1.26,
    footPaddings: const <double>[22, 22, 22, 22],
    framePositions: <Vector2>[
      for (var i = 0; i < 4; i++) Vector2(i * 373.0, 0),
    ],
  );

  /// Single standing look / dirty-hands beat.
  static final CharacterSheet customerLook = CharacterSheet(
    frameSize: Vector2(612, 1519),
    displayScale: 0.52,
    footPaddings: const <double>[10],
    framePositions: <Vector2>[Vector2(221, 7)],
  );

  /// 2350×587, 5×1 face reactions. UI only. Even isolated cells.
  static final CharacterSheet customerEmotion = CharacterSheet(
    frameSize: Vector2(470, 587),
    displayScale: 1,
    footPaddings: const <double>[12, 12, 12, 12, 12],
    framePositions: <Vector2>[
      for (var i = 0; i < 5; i++) Vector2(i * 470.0, 0),
    ],
  );

  static final SpriteRegion wall = SpriteRegion(
    Vector2(0, 143),
    Vector2(1024, 360),
  );
  static final SpriteRegion floor = SpriteRegion(
    Vector2.zero(),
    Vector2(1024, 657),
  );
  static final SpriteRegion doorFrame = SpriteRegion(
    Vector2(1, 5),
    Vector2(1028, 1454),
  );
  static final SpriteRegion doorLeaf = SpriteRegion(
    Vector2(221, 17),
    Vector2(580, 1496),
  );
  static final SpriteRegion nailTable = SpriteRegion(
    Vector2.zero(),
    Vector2(1440, 1006),
  );
  static final SpriteRegion salonChair = SpriteRegion(
    Vector2.zero(),
    Vector2(894, 1186),
  );
  static final SpriteRegion plant = SpriteRegion(
    Vector2(55, 66),
    Vector2(449, 918),
  );

  /// 2172×724, 4×1 wash stages. Even cells so the hand does not slide.
  /// [contentCenterOffsets] lock dirty→clean dissolve to one pose.
  static final CharacterSheet handWash = CharacterSheet(
    frameSize: Vector2(543, 724),
    displayScale: 1,
    footPaddings: const <double>[0, 0, 0, 0],
    framePositions: <Vector2>[
      Vector2(0, 0),
      Vector2(543, 0),
      Vector2(1086, 0),
      Vector2(1629, 0),
    ],
    contentCenterOffsets: <Vector2>[
      Vector2(13.73, -23.21),
      Vector2(3.01, -23.83),
      Vector2(-10.52, -23.82),
      Vector2(-19.19, -22.94),
    ],
  );

  static final CharacterSheet fifthNailClean = CharacterSheet(
    frameSize: Vector2(355, 879),
    displayScale: 1,
    footPaddings: const <double>[0, 0, 0, 0],
    framePositions: <Vector2>[
      Vector2(15, 0),
      Vector2(448, 0),
      Vector2(883, 0),
      Vector2(1313, 0),
    ],
    contentCenterOffsets: <Vector2>[
      Vector2(-9.40, -65.17),
      Vector2(-8.93, -72.65),
      Vector2(-9.15, -75.08),
      Vector2(-10.21, -75.41),
    ],
  );

  /// 1536×1024, 4×1 left-to-right clip stages. Even cells; offsets lock pose.
  static final CharacterSheet shortNail = CharacterSheet(
    frameSize: Vector2(384, 1024),
    displayScale: 1,
    footPaddings: const <double>[0, 0, 0, 0],
    framePositions: <Vector2>[
      for (var i = 0; i < 4; i++) Vector2(i * 384.0, 0),
    ],
    contentCenterOffsets: <Vector2>[
      Vector2(-2.53, -159.27),
      Vector2(-3.39, -187.81),
      Vector2(-4.60, -207.17),
      Vector2(-4.97, -210.60),
    ],
  );

  static final SpriteRegion handSoap = SpriteRegion(
    Vector2(374, 59),
    Vector2(280, 453),
  );
  static final SpriteRegion nailBuffer = SpriteRegion(
    Vector2(272, 103),
    Vector2(480, 367),
  );
  static final SpriteRegion nailSpray = SpriteRegion(
    Vector2(220, 40),
    Vector2(580, 900),
  );
  static final SpriteRegion nailClips = SpriteRegion(
    Vector2(181, 14),
    Vector2(1293, 889),
  );
}

class SpriteRegion {
  const SpriteRegion(this.position, this.size);

  final Vector2 position;
  final Vector2 size;

  double get aspectRatio => size.x / size.y;
}

class CharacterSheet {
  CharacterSheet({
    required this.frameSize,
    required this.framePositions,
    required this.displayScale,
    required this.footPaddings,
    List<Vector2>? contentCenterOffsets,
  }) : contentCenterOffsets =
           contentCenterOffsets ??
           List<Vector2>.filled(framePositions.length, Vector2.zero()),
       assert(framePositions.length == footPaddings.length),
       assert(
         contentCenterOffsets == null ||
             contentCenterOffsets.length == framePositions.length,
       );

  final Vector2 frameSize;
  final List<Vector2> framePositions;
  final double displayScale;
  final List<double> footPaddings;

  /// Opaque-content centroid relative to each cell center. Used to lock pose
  /// when swapping frames that were not authored on a shared pivot.
  final List<Vector2> contentCenterOffsets;

  int get frameCount => framePositions.length;
}
