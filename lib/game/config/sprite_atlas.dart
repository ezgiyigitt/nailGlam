import 'package:flame/components.dart';

/// Source rectangles for every sprite, measured from the delivered art.
///
/// The salon room, the manicure desk and the customer are whole images rather
/// than atlas windows, so replacement art of any size drops straight in.
abstract final class SpriteAtlas {
  /// 2048×682, 4×1 even wash stages. Consecutive cells crossfade in game.
  static final CharacterSheet handWash = CharacterSheet(
    frameSize: Vector2(512, 682),
    displayScale: 1,
    footPaddings: const <double>[0, 0, 0, 0],
    framePositions: <Vector2>[
      for (var i = 0; i < 4; i++) Vector2(i * 512.0, 0),
    ],
    contentCenterOffsets: <Vector2>[
      Vector2.zero(),
      Vector2.zero(),
      Vector2.zero(),
      Vector2.zero(),
    ],
  );

  /// Pixel shift applied when drawing each wash cell so the hand stays on
  /// cell 0. Measured from the middle fingertip (cell 0 at x=245).
  static final List<Vector2> handWashFrameAlign = <Vector2>[
    Vector2.zero(),
    Vector2(8, 0),
    Vector2(21, 0),
    Vector2(28, 0),
  ];

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

  /// Shift applied to [shortNail] after it is drawn at the clean-sheet scale,
  /// so the long tip of frame 0 sits on [fifthNailClean] frame 3's tip.
  /// Source pixels: clean tip (113, 866) − short tip (166, 836).
  static final Vector2 shortNailAlign = Vector2(-53, 30);

  /// 1536×1024, 4×1 left-to-right clip stages. Even cells; the art is already
  /// registered on the cuticle, so frames are not centroid-shifted in game.
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

  /// 1942×809, 4 dirty→clean stages. Windows start on each finger's
  /// opaque left edge; height is the tallest fingertip (frame 0).
  static final CharacterSheet fourthNail = CharacterSheet(
    frameSize: Vector2(355, 758),
    displayScale: 1,
    footPaddings: const <double>[0, 0, 0, 0],
    framePositions: <Vector2>[
      Vector2(55, 0),
      Vector2(565, 0),
      Vector2(1045, 0),
      Vector2(1549, 0),
    ],
    contentCenterOffsets: <Vector2>[
      Vector2.zero(),
      Vector2.zero(),
      Vector2.zero(),
      Vector2.zero(),
    ],
  );

  /// Source pixels in the pinky slot (355×879): stretched fourth-nail
  /// frame 3 tip (133, 740/758×879) − fourth short tip (191.5, 974).
  static final Vector2 fourthShortNailAlign = Vector2(
    -58.5,
    740.0 * 879 / 758 - 974,
  );

  /// 1536×1024, 4×1 even ring-finger clip stages.
  static final CharacterSheet fourthShortNail = CharacterSheet(
    frameSize: Vector2(384, 1024),
    displayScale: 1,
    footPaddings: const <double>[0, 0, 0, 0],
    framePositions: <Vector2>[
      for (var i = 0; i < 4; i++) Vector2(i * 384.0, 0),
    ],
    contentCenterOffsets: <Vector2>[
      Vector2.zero(),
      Vector2.zero(),
      Vector2.zero(),
      Vector2.zero(),
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
  /// Brush head and ferrule only — the full stick is 1300px tall.
  static final SpriteRegion polishBrush = SpriteRegion(
    Vector2(0, 0),
    Vector2(139, 300),
  );

  /// Clipped pinky plate inside the 384×1024 polish mask.
  static final SpriteRegion pinkNailPlate = SpriteRegion(
    Vector2(87, 311),
    Vector2(191, 318),
  );

  /// Clipped ring plate inside the 384×1024 polish mask.
  static final SpriteRegion ringNailPlate = SpriteRegion(
    Vector2(95, 307),
    Vector2(196, 331),
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
