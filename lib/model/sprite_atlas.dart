import 'package:flame/components.dart';

/// Source rectangles for every sprite, measured from the delivered art.
///
/// The salon room, the manicure desk and the customer are whole images rather
/// than atlas windows, so replacement art of any size drops straight in.
abstract final class SpriteAtlas {
  /// 3916×1473, 4×1 even wash stages for Lila / Ezgi. Cells share one pose.
  static final CharacterSheet handWash = CharacterSheet.evenStrip(
    Vector2(979, 1473),
  );

  /// No per-frame shift: the C1/C2 wash strip is authored on a locked pivot.
  static final List<Vector2> handWashFrameAlign = <Vector2>[
    Vector2.zero(),
    Vector2.zero(),
    Vector2.zero(),
    Vector2.zero(),
  ];

  /// 3952×1358, 4×1 even wash stages for Zeynep.
  static final CharacterSheet handWashDark = CharacterSheet.evenStrip(
    Vector2(988, 1358),
  );

  /// 1856×1398, 4×1 dirty→clean pinky for Zeynep. Spray uses 0–1, wipe 2–3.
  static final CharacterSheet pinkyCleanDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// 1856×1398, 4×1 left→right clip on the same locked pose as [pinkyCleanDark].
  static final CharacterSheet pinkyShortDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// Clipped pinky plate inside the 464×1398 dark polish mask.
  static final SpriteRegion pinkyNailPlateDark = SpriteRegion(
    Vector2(100, 688),
    Vector2(256, 401),
  );

  /// 1856×1398, 4×1 dirty→clean ring for Zeynep.
  static final CharacterSheet ringCleanDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// 1856×1398, 4×1 left→right clip on the locked ring pose.
  static final CharacterSheet ringShortDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// Clipped ring plate — same approved pinky plate.
  static final SpriteRegion ringNailPlateDark = SpriteRegion(
    Vector2(100, 688),
    Vector2(256, 401),
  );

  /// 1856×1398, 4×1 dirty→clean middle for Zeynep.
  static final CharacterSheet middleCleanDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// 1856×1398, 4×1 left→right clip on the locked middle pose.
  static final CharacterSheet middleShortDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// Clipped middle plate — same approved pinky plate.
  static final SpriteRegion middleNailPlateDark = SpriteRegion(
    Vector2(100, 688),
    Vector2(256, 401),
  );

  /// 1856×1398, 4×1 dirty→clean index for Zeynep.
  static final CharacterSheet indexCleanDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// 1856×1398, 4×1 left→right clip on the locked index pose.
  static final CharacterSheet indexShortDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// Clipped index plate — same approved pinky plate.
  static final SpriteRegion indexNailPlateDark = SpriteRegion(
    Vector2(100, 688),
    Vector2(256, 401),
  );

  /// 1856×1398, 4×1 dirty→clean thumb for Zeynep.
  static final CharacterSheet thumbCleanDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// 1856×1398, 4×1 left→right clip on the locked thumb pose.
  static final CharacterSheet thumbShortDark = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  /// Clipped thumb plate inside the 464×1398 dark polish mask.
  static final SpriteRegion thumbNailPlateDark = SpriteRegion(
    Vector2(64, 688),
    Vector2(328, 401),
  );

  /// 1856×1398, 4×1 dirty→clean pinky for Lila / Ezgi.
  static final CharacterSheet pinkyCleanLight = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  static final CharacterSheet pinkyShortLight = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  static final SpriteRegion pinkyNailPlateLight = SpriteRegion(
    Vector2(117, 667),
    Vector2(230, 422),
  );

  static final CharacterSheet pinkyStilettoNail = CharacterSheet.evenStrip(
    Vector2(512, 1024),
  );

  static final SpriteRegion pinkyStilettoNailPlate = SpriteRegion(
    Vector2.zero(),
    Vector2(1024, 1536),
  );

  /// Shared by ring / middle / index on the light hand.
  static final CharacterSheet middleCleanLight = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  static final CharacterSheet middleShortLight = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  static final SpriteRegion middleNailPlateLight = SpriteRegion(
    Vector2(117, 667),
    Vector2(230, 422),
  );

  static final CharacterSheet thumbCleanLight = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  static final CharacterSheet thumbShortLight = CharacterSheet.evenStrip(
    Vector2(464, 1398),
  );

  static final SpriteRegion thumbNailPlateLight = SpriteRegion(
    Vector2(95, 559),
    Vector2(193, 324),
  );

  /// 833×1446 cartoon finished hand for Lila / Ezgi.
  static final CharacterSheet finalHandLight = CharacterSheet(
    frameSize: Vector2(833, 1446),
    displayScale: 1,
    footPaddings: const <double>[0],
    framePositions: <Vector2>[Vector2.zero()],
  );

  /// 1448×1086 still of the finished hand (not a strip). Window is the
  /// opaque silhouette so it scales like the wash hand on the plate.
  static final CharacterSheet finalHand = CharacterSheet(
    frameSize: Vector2(869, 1055),
    displayScale: 1,
    footPaddings: const <double>[0],
    framePositions: <Vector2>[Vector2(288, 0)],
  );

  /// 1536×1024 still of Zeynep's finished hand. Opaque window only.
  static final CharacterSheet finalHandDark = CharacterSheet(
    frameSize: Vector2(868, 1018),
    displayScale: 1,
    footPaddings: const <double>[0],
    framePositions: <Vector2>[Vector2(344, 0)],
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
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(-4.29, 0),
      Vector2(-7.73, 0),
      Vector2(-5.53, 0),
    ],
  );

  /// 1420×879, 4×1 spray stages (dirty → treated). Split from [fifthNailClean].
  static final CharacterSheet fifthNailSpray = CharacterSheet.evenStrip(
    Vector2(355, 879),
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2.zero(),
      Vector2(-4.29, 0),
      Vector2(-4.29, 0),
    ],
  );

  /// 1420×879, 4×1 wipe stages (treated → clean). Frame 0 matches spray frame 3.
  static final CharacterSheet fifthNailWipe = CharacterSheet.evenStrip(
    Vector2(355, 879),
    frameAlign: <Vector2>[
      Vector2(-4.29, 0),
      Vector2(-7.73, 0),
      Vector2(-7.73, 0),
      Vector2(-5.53, 0),
    ],
  );

  /// Shift applied to [shortNail] after it is drawn at the clean-sheet scale,
  /// so the long tip of frame 0 sits on [fifthNailClean] frame 3's tip.
  /// Source pixels: clean tip (113, 866) − short tip (166, 836).
  static final Vector2 shortNailAlign = Vector2(-53, 30);

  /// 1536×1024, 4×1 left-to-right clip stages.
  /// [frameAlign] locks the cuticle so only the tip shortens.
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
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(0.50, 0),
      Vector2(1.00, -5),
      Vector2(0.50, -5),
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
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(-0.91, 0),
      Vector2(-9.52, 0),
      Vector2(-0.73, 0),
    ],
  );

  /// 1420×758, 4×1 spray stages. Split from [fourthNail].
  static final CharacterSheet fourthNailSpray = CharacterSheet.evenStrip(
    Vector2(355, 758),
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2.zero(),
      Vector2(-0.91, 0),
      Vector2(-0.91, 0),
    ],
  );

  /// 1420×758, 4×1 wipe stages. Frame 0 matches spray frame 3.
  static final CharacterSheet fourthNailWipe = CharacterSheet.evenStrip(
    Vector2(355, 758),
    frameAlign: <Vector2>[
      Vector2(-0.91, 0),
      Vector2(-9.52, 0),
      Vector2(-9.52, 0),
      Vector2(-0.73, 0),
    ],
  );

  /// Source pixels in the pinky slot (355×879): stretched fourth-nail
  /// frame 3 tip (133, 740/758×879) − fourth short tip (191.5, 974).
  static final Vector2 fourthShortNailAlign = Vector2(
    -58.5,
    740.0 * 879 / 758 - 974,
  );

  /// 1536×1024, 4×1 even ring-finger clip stages.
  /// Cuticle lock: sheet redraws the finger ~113px higher as the tip shortens.
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
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(2.50, 113),
      Vector2(0.50, 114),
      Vector2(1.00, 115),
    ],
  );

  /// 1774×887, 4 even dirty→clean stages. Drawn into the pinky slot.
  /// [frameAlign] locks the stump (top 10% centroid) to frame 0.
  static final CharacterSheet thirdNailClean = CharacterSheet.evenStrip(
    Vector2(443.5, 887),
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(1.96, 0),
      Vector2(-9.08, 0),
      Vector2(-3.17, 0),
    ],
  );

  /// 1536×1024, 4 even clip stages. Cuticle lock (sheet drifts left + tip-up).
  static final CharacterSheet thirdNailShort = CharacterSheet.evenStrip(
    Vector2(384, 1024),
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(-25.00, 5),
      Vector2(-35.50, -2),
      Vector2(-34.00, 21),
    ],
  );

  static final CharacterSheet secondNailClean = CharacterSheet.evenStrip(
    Vector2(443.5, 887),
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(2.91, 0),
      Vector2(-2.46, 0),
      Vector2(-3.46, 0),
    ],
  );

  static final CharacterSheet secondNailShort = CharacterSheet.evenStrip(
    Vector2(443.5, 887),
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(-20.50, 22),
      Vector2(-27.00, 15),
      Vector2(-30.50, 28),
    ],
  );

  static final CharacterSheet firstNailClean = CharacterSheet.evenStrip(
    Vector2(443.5, 887),
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(0.79, 0),
      Vector2(15.33, 0),
      Vector2(19.40, 0),
    ],
  );

  static final CharacterSheet firstNailShort = CharacterSheet.evenStrip(
    Vector2(443.5, 887),
    frameAlign: <Vector2>[
      Vector2.zero(),
      Vector2(-33.50, -31),
      Vector2(-35.00, -35),
      Vector2(-34.50, -28),
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
    Vector2(91, 315),
    Vector2(183, 310),
  );

  /// Clipped ring plate inside the 384×1024 polish mask.
  static final SpriteRegion ringNailPlate = SpriteRegion(
    Vector2(99, 311),
    Vector2(188, 323),
  );

  static final SpriteRegion thirdNailPlate = SpriteRegion(
    Vector2(120, 334),
    Vector2(200, 285),
  );

  static final SpriteRegion secondNailPlate = SpriteRegion(
    Vector2(145, 233),
    Vector2(224, 358),
  );

  static final SpriteRegion firstNailPlate = SpriteRegion(
    Vector2(130, 283),
    Vector2(230, 357),
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
    List<Vector2>? frameAlign,
  }) : contentCenterOffsets =
           contentCenterOffsets ??
           List<Vector2>.filled(framePositions.length, Vector2.zero()),
       frameAlign =
           frameAlign ??
           List<Vector2>.filled(framePositions.length, Vector2.zero()),
       assert(framePositions.length == footPaddings.length),
       assert(
         contentCenterOffsets == null ||
             contentCenterOffsets.length == framePositions.length,
       ),
       assert(
         frameAlign == null || frameAlign.length == framePositions.length,
       );

  factory CharacterSheet.evenStrip(
    Vector2 frameSize, {
    int frames = 4,
    List<Vector2>? frameAlign,
  }) {
    return CharacterSheet(
      frameSize: frameSize,
      displayScale: 1,
      footPaddings: List<double>.filled(frames, 0),
      framePositions: <Vector2>[
        for (var i = 0; i < frames; i++) Vector2(i * frameSize.x, 0),
      ],
      contentCenterOffsets: List<Vector2>.filled(frames, Vector2.zero()),
      frameAlign: frameAlign,
    );
  }

  final Vector2 frameSize;
  final List<Vector2> framePositions;
  final double displayScale;
  final List<double> footPaddings;

  /// Opaque-content centroid relative to each cell center. Unused by the
  /// finger close-up; stump lock uses [frameAlign] instead.
  final List<Vector2> contentCenterOffsets;

  /// Source-pixel shift that locks each cell's cuticle to frame 0 so clip
  /// stages only shorten the tip. Needed because short sheets are not
  /// authored on a shared finger pivot.
  final List<Vector2> frameAlign;

  int get frameCount => framePositions.length;
}
