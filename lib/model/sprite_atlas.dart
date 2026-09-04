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

  /// 1536×1024, 4×1 dirty→clean foot stages. Locked pose: no per-frame shift.
  static final CharacterSheet footWash = CharacterSheet.evenStrip(
    Vector2(384, 1024),
  );

  /// 1536×1024, 4×1 dirty→clean toenail stages. Locked pose, same as [footWash].
  static final CharacterSheet footNailClean = CharacterSheet.evenStrip(
    Vector2(384, 1024),
  );

  /// Shared zero-shift alignment for the locked-pose foot strips.
  static final List<Vector2> footFrameAlignZero = <Vector2>[
    Vector2.zero(),
    Vector2.zero(),
    Vector2.zero(),
    Vector2.zero(),
    Vector2.zero(),
    Vector2.zero(),
  ];

  /// 2048×768, 4×1 even wash stages for Zeynep.
  static final CharacterSheet handWashDark = CharacterSheet.evenStrip(
    Vector2(512, 768),
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

  /// 1536×1024, 4×1 stiletto cutting strip for the light-skin pinky.
  static final CharacterSheet pinkyStilettoLight = CharacterSheet.evenStrip(
    Vector2(384, 1024),
  );

  /// Nail bed inside [AssetPaths.pinkyStilettoPolishMask], measured as the
  /// mask's opaque bounding box. `_paintPolish` normalises this rect by the
  /// mask's own width/height, so it must be in mask pixels — and it must be
  /// the *nail*, not the whole cell: the depth gradient, the gloss streak and
  /// the fill sweep are all derived from it.
  static final SpriteRegion pinkyStilettoLightPlate = SpriteRegion(
    Vector2(102, 447),
    Vector2(180, 499),
  );

  /// 1536×1024, 4×1 stiletto cutting strip for the light-skin middle finger.
  static final CharacterSheet middleStilettoLight = CharacterSheet.evenStrip(
    Vector2(384, 1024),
  );

  /// Nail bed inside [AssetPaths.middleStilettoPolishMask].
  static final SpriteRegion middleStilettoLightPlate = SpriteRegion(
    Vector2(104, 458),
    Vector2(179, 478),
  );

  /// 1536×1024, 4×1 stiletto cutting strip for the light-skin thumb.
  static final CharacterSheet thumbStilettoLight = CharacterSheet.evenStrip(
    Vector2(384, 1024),
  );

  /// Nail bed inside [AssetPaths.thumbStilettoPolishMask], re-measured as that
  /// mask's own opaque alpha bounding box. The previous rect sat 28px left of
  /// the mask and was 47px wider, so the flat tint ran out before the nail's
  /// right edge and the wet/shine gradients were keyed off an axis the nail
  /// does not sit on.
  static final SpriteRegion thumbStilettoLightPlate = SpriteRegion(
    Vector2(130, 438),
    Vector2(181, 471),
  );

  /// 1536×1024, 4×1 stiletto cutting strip shared by the dark-skin pinky,
  /// ring, middle and pointer fingers.
  static final CharacterSheet pinkyStilettoDark = CharacterSheet.evenStrip(
    Vector2(384, 1024),
  );

  /// Nail bed inside [AssetPaths.pinkyStilettoMaskDark]. Measured from the
  /// mask's own opaque bounding box (113,469)-(297,977) — the previous rect
  /// stopped ~20px short of the mask's bottom, so the tint fill never
  /// reached the sharp stiletto tip and left it uncovered.
  static final SpriteRegion pinkyStilettoDarkPlate = SpriteRegion(
    Vector2(113, 469),
    Vector2(184, 508),
  );

  /// 1536×1024, 4×1 stiletto cutting strip for the dark-skin thumb.
  static final CharacterSheet thumbStilettoDark = CharacterSheet.evenStrip(
    Vector2(384, 1024),
  );

  /// Nail bed inside [AssetPaths.thumbStilettoMaskDark]. Measured from the
  /// mask's own opaque bounding box (79,464)-(286,983) — the previous rect
  /// stopped ~25px short of the mask's bottom, so the tint fill never
  /// reached the sharp stiletto tip and left it uncovered.
  static final SpriteRegion thumbStilettoDarkPlate = SpriteRegion(
    Vector2(79, 464),
    Vector2(207, 519),
  );

  /// 2103×748, 4×1 dirty→clean strip for [AssetPaths.thumbNailDarkWipe].
  static final CharacterSheet thumbCleanDarkWipe = CharacterSheet.evenStrip(
    Vector2(525.75, 748),
  );

  /// 2172x724, 6x1 whole-foot toenail cutting strip (all toes at once).
  static final CharacterSheet footNailCut = CharacterSheet.evenStrip(
    Vector2(362, 724),
    frames: 6,
  );

  static final CharacterSheet footWashDark = CharacterSheet.evenStrip(
    Vector2(384, 1024),
    frames: 4,
  );

  static final CharacterSheet footNailCleanDark = CharacterSheet.evenStrip(
    Vector2(384, 1024),
    frames: 4,
  );

  static final CharacterSheet footNailCutDark = CharacterSheet.evenStrip(
    Vector2(362, 724),
    frames: 6,
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

  /// Nail bed inside [AssetPaths.thumbNailMaskLight], measured as the mask's
  /// own opaque alpha bounding box (100,557)-(283,884) after the mask was
  /// re-derived from scratch by colour-segmenting `thumb_short_light.png`
  /// frame 3 (the fully-shortened state shown during
  /// [NailCareStage.nailPolishing]) rather than smoothing the old mask.
  static final SpriteRegion thumbNailPlateLight = SpriteRegion(
    Vector2(100, 557),
    Vector2(183, 327),
  );

  /// 769×1024 finished hand for Lila / Ezgi — the hand half of the
  /// manually-authored `final_hand_withmask_lightsquare.png` reference
  /// (hand on the left, its 5 nail masks laid out on the right in the same
  /// pinky→thumb order as the fingers).
  static final CharacterSheet finalHandLight = CharacterSheet(
    frameSize: Vector2(769, 1024),
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

  /// Window into the 1067×1474 `final_hand_stiletto.png`, starting at the
  /// opaque silhouette's origin (139,10) and 820 wide so
  /// [GameConfig.workspaceHandWidth] scales it 1:1. Height is 1000 (not the
  /// full canvas) so the displayed hand is ~980–1000px tall, matching
  /// [finalHandDarkStiletto]'s scaled height — the previous 1360 window made
  /// this hand ~39% taller on screen than every other reveal, pushing the
  /// nail tips off the top of the visible play area. The art's wrist is
  /// alpha-feathered just above this cut, so the window's bottom edge never
  /// stamps a hard line on the table.
  ///
  /// `final_hand_stiletto_mask.png` shares this exact 1067×1474 canvas —
  /// [_paintLacquerCoat] samples the mask with the art's own src rect, so the
  /// two must live in the same coordinate space.
  static final CharacterSheet finalHandStiletto = CharacterSheet(
    frameSize: Vector2(820, 1000),
    displayScale: 1,
    footPaddings: const <double>[0],
    framePositions: <Vector2>[Vector2(139, 10)],
  );

  /// 1448×1086 dark-skin stiletto reveal. Window measured from the alpha
  /// silhouette after the black backdrop was cut out.
  static final CharacterSheet finalHandDarkStiletto = CharacterSheet(
    frameSize: Vector2(908, 1079),
    displayScale: 1,
    footPaddings: const <double>[0],
    framePositions: <Vector2>[Vector2(267, 0)],
  );

  /// 1536×1024 still of Zeynep's finished hand. Opaque window only.
  static final CharacterSheet finalHandDark = CharacterSheet(
    frameSize: Vector2(868, 1018),
    displayScale: 1,
    footPaddings: const <double>[0],
    framePositions: <Vector2>[Vector2(344, 0)],
  );

  /// Per-nail plate rects for the finished-hand lacquer coat, measured from
  /// each digit mask's own opaque bounding box on its full canvas (same
  /// canvas the corresponding `final_hand_*` art and [finalHandLight] /
  /// [finalHandDark] windows are authored on). `_paintLacquerCoat` keys its
  /// wet-depth gradient and center shine off these — previously it used the
  /// whole-hand window rect instead of the nail itself, so a nail sitting
  /// outside the gradient's narrow transition band came out flat/pastel next
  /// to the live per-digit paint (which has always been plate-relative).
  /// Re-derived from scratch for round 4: each rect is the corresponding
  /// `final_hand_light_nail_*.png` mask's own opaque alpha bounding box,
  /// after the mask itself was rebuilt by colour/luminance-segmenting the
  /// actual painted nail blob in `final_hand_light.png` per digit (a local
  /// luminance plateau distinguishes the flat-fill nail from the gradient
  /// skin), rather than fitting a uniformly-scaled ellipse to a detected
  /// center as the previous round did.
  static final SpriteRegion finalHandLightNailPlatePinky = SpriteRegion(
    Vector2(707, 251),
    Vector2(53, 84),
  );
  static final SpriteRegion finalHandLightNailPlateRing = SpriteRegion(
    Vector2(542, 82),
    Vector2(55, 91),
  );
  static final SpriteRegion finalHandLightNailPlateMiddle = SpriteRegion(
    Vector2(422, 13),
    Vector2(60, 96),
  );
  static final SpriteRegion finalHandLightNailPlatePointer = SpriteRegion(
    Vector2(287, 80),
    Vector2(56, 86),
  );
  static final SpriteRegion finalHandLightNailPlateThumb = SpriteRegion(
    Vector2(84, 478),
    Vector2(67, 91),
  );

  static final SpriteRegion finalHandDarkNailPlatePinky = SpriteRegion(
    Vector2(346, 661),
    Vector2(84, 125),
  );
  static final SpriteRegion finalHandDarkNailPlateRing = SpriteRegion(
    Vector2(530, 815),
    Vector2(88, 156),
  );
  static final SpriteRegion finalHandDarkNailPlateMiddle = SpriteRegion(
    Vector2(751, 868),
    Vector2(92, 150),
  );
  static final SpriteRegion finalHandDarkNailPlatePointer = SpriteRegion(
    Vector2(963, 814),
    Vector2(100, 152),
  );
  static final SpriteRegion finalHandDarkNailPlateThumb = SpriteRegion(
    Vector2(1111, 490),
    Vector2(100, 143),
  );

  /// Fallback plate for [AssetPaths.finalHandStilettoMask] (the aggregate
  /// 5-nail mask) — the union of the five nail blobs, measured as that
  /// mask's own opaque bounding box on the shared 1067×1474 canvas. Live
  /// rendering uses the per-digit plates below instead, same as the square
  /// reveal, so each nail gets its own gradient/shine rather than one
  /// stretched across the whole hand.
  static final SpriteRegion finalHandStilettoNailPlate = SpriteRegion(
    Vector2(160, 17),
    Vector2(786, 817),
  );

  /// Round 5: the light stiletto reveal masks sat ~10-13px inside the painted
  /// nail's real outline, so the art's own pale nail rim stayed unpainted and
  /// read as a light halo around every finished nail. Each mask was regrown
  /// out to the nail's actual boundary (dark cuticle groove + skin-chroma
  /// barrier, convex-hull smoothed) and these plates re-measured as the
  /// rebuilt mask's own opaque bounding box.
  static final SpriteRegion finalHandStilettoNailPlatePinky = SpriteRegion(
    Vector2(869, 603),
    Vector2(77, 231),
  );
  static final SpriteRegion finalHandStilettoNailPlateRing = SpriteRegion(
    Vector2(675, 124),
    Vector2(71, 215),
  );
  static final SpriteRegion finalHandStilettoNailPlateMiddle = SpriteRegion(
    Vector2(493, 17),
    Vector2(80, 222),
  );
  static final SpriteRegion finalHandStilettoNailPlatePointer = SpriteRegion(
    Vector2(330, 113),
    Vector2(73, 220),
  );
  static final SpriteRegion finalHandStilettoNailPlateThumb = SpriteRegion(
    Vector2(160, 346),
    Vector2(58, 192),
  );
  static final SpriteRegion finalHandDarkStilettoNailPlate = SpriteRegion(
    Vector2(271, 477),
    Vector2(901, 600),
  );

  /// Per-nail plates for the dark stiletto reveal, each measured as that
  /// nail's own blob in `final_hand_dark_stiletto_mask.png`. The aggregate
  /// rect above spans all five nails, so it kept the gradient and shine on
  /// the hand's axis instead of each nail's.
  static final SpriteRegion finalHandDarkStilettoNailPlatePinky = SpriteRegion(
    Vector2(271, 667),
    Vector2(81, 168),
  );
  static final SpriteRegion finalHandDarkStilettoNailPlateRing = SpriteRegion(
    Vector2(456, 827),
    Vector2(78, 186),
  );
  static final SpriteRegion finalHandDarkStilettoNailPlateMiddle = SpriteRegion(
    Vector2(682, 894),
    Vector2(80, 183),
  );
  static final SpriteRegion finalHandDarkStilettoNailPlatePointer =
      SpriteRegion(Vector2(909, 834), Vector2(84, 192));
  static final SpriteRegion finalHandDarkStilettoNailPlateThumb = SpriteRegion(
    Vector2(1071, 477),
    Vector2(101, 187),
  );

  /// Fallback plate for the rare case the per-digit reveal masks/colours
  /// aren't populated and the aggregate 5-nail mask is used instead — same
  /// "mask's own bbox" measurement as the per-digit plates above.
  /// Re-derived for round 4 as the fresh `final_hand_light_nail_mask.png`
  /// aggregate's own opaque bounding box (the union of the 5 rebuilt
  /// per-digit masks above).
  static final SpriteRegion finalHandLightNailPlate = SpriteRegion(
    Vector2(84, 13),
    Vector2(676, 556),
  );
  static final SpriteRegion finalHandDarkNailPlate = SpriteRegion(
    Vector2(346, 490),
    Vector2(864, 527),
  );

  /// Toe plate for [AssetPaths.footNailPolishMaskLight] / `...Dark`, measured
  /// from the mask's own opaque bbox within the *last* (fully-cut) cell of
  /// the 6-cell 2172×724 strip — the only cell the pedicure polish stage
  /// ever samples (see `showFootPolish`). All five toes share one blob, the
  /// same limitation the stiletto hand plates have.
  ///
  /// `footNailPolishPlateLight` is re-derived from the manually-authored
  /// `light_toe_mask.png` (opaque bbox on the 2172×724 canvas).
  static final SpriteRegion footNailPolishPlateLight = SpriteRegion(
    Vector2(1844, 548),
    Vector2(287, 127),
  );
  static final SpriteRegion footNailPolishPlateDark = SpriteRegion(
    Vector2(1871, 564),
    Vector2(275, 120),
  );

  /// Per-toe plates for the [AssetPaths.finalToeLightNailThumb] etc. split —
  /// each measured as that toe's own mask opaque bbox on the shared
  /// 2172×724 canvas. Re-derived together with the masks themselves, which
  /// were rebuilt by luminance/saturation-segmenting the actual toenail in
  /// the last frame of `toe_nail_cutting_light.png`. The previous masks were
  /// traced by eye and sat wider than the nails, so the polish spilled onto
  /// the skin — worst on the big toe and the two next to it.
  static final SpriteRegion footNailPolishPlateLightThumb = SpriteRegion(
    Vector2(1850, 611),
    Vector2(56, 56),
  );
  static final SpriteRegion footNailPolishPlateLightPointer = SpriteRegion(
    Vector2(1946, 638),
    Vector2(36, 38),
  );
  static final SpriteRegion footNailPolishPlateLightMiddle = SpriteRegion(
    Vector2(2005, 621),
    Vector2(32, 34),
  );
  static final SpriteRegion footNailPolishPlateLightRing = SpriteRegion(
    Vector2(2055, 591),
    Vector2(26, 30),
  );
  static final SpriteRegion footNailPolishPlateLightPinky = SpriteRegion(
    Vector2(2094, 556),
    Vector2(24, 29),
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

  /// 2172×724, 6×1 wipe animation strip. Each frame is 362×724.
  static final CharacterSheet wipeFrames = CharacterSheet.evenStrip(
    Vector2(362, 724),
    frames: 6,
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
