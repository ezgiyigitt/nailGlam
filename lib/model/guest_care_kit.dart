import 'dart:ui' show Offset;

import 'package:flame/components.dart';

import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/sprite_atlas.dart';

/// Clean / clip / polish art for one digit on a guest.
class GuestDigitCareArt {
  const GuestDigitCareArt({
    required this.cleanAsset,
    required this.cleanSheet,
    required this.shortAsset,
    required this.shortSheet,
    required this.polishMaskAsset,
    required this.polishPlate,
  });

  final String cleanAsset;
  final CharacterSheet cleanSheet;
  final String shortAsset;
  final CharacterSheet shortSheet;
  final String polishMaskAsset;
  final SpriteRegion polishPlate;
}

/// Clip + polish art for one digit in a non-default nail shape (stiletto).
/// The clean stages are shape-agnostic, so only the short sheet and its mask
/// differ from the digit's square art.
class GuestNailShapeArt {
  const GuestNailShapeArt({
    required this.shortAsset,
    required this.shortSheet,
    required this.polishMaskAsset,
    required this.polishPlate,
  });

  final String shortAsset;
  final CharacterSheet shortSheet;
  final String polishMaskAsset;
  final SpriteRegion polishPlate;
}

/// Per-guest wash / nail-clean / reveal art.
/// Art for the manicure-progress hand on the gameplay HUD
/// (`CuteHandSimCard`, bottom-left).
///
/// The card used to hardcode the light hand for every guest, so a dark-skinned
/// guest's progress was tracked on somebody else's hand. Each tone brings its
/// own still, its own per-nail masks and — because the two hands are posed
/// differently — its own nail positions.
class GuestHudHandArt {
  const GuestHudHandArt({
    required this.handAsset,
    required this.nailMasks,
    required this.aspect,
    required this.nailCenters,
  });

  /// Whole-hand still. Must be cropped to the hand itself: the card lays it
  /// out with `BoxFit.contain`, so padding inside the canvas shrinks the hand.
  final String handAsset;

  /// One mask per digit, on the same canvas as [handAsset] so the layers line
  /// up when both are laid out by `BoxFit.contain`.
  final Map<NailDigit, String> nailMasks;

  /// `width / height` of that canvas, used to place the tap targets over the
  /// laid-out image.
  final double aspect;

  /// Nail centres as a fraction of the art, measured from each mask's own
  /// opaque centroid — not eyeballed.
  final Map<NailDigit, Offset> nailCenters;

  /// Lila / Ezgi: 769x1024, fingers up, thumb on the left.
  static const GuestHudHandArt light = GuestHudHandArt(
    handAsset: AssetPaths.finalHandLight,
    aspect: 769 / 1024,
    nailMasks: <NailDigit, String>{
      NailDigit.pinky: AssetPaths.finalHandLightNailPinky,
      NailDigit.ring: AssetPaths.finalHandLightNailRing,
      NailDigit.middle: AssetPaths.finalHandLightNailMiddle,
      NailDigit.pointer: AssetPaths.finalHandLightNailPointer,
      NailDigit.thumb: AssetPaths.finalHandLightNailThumb,
    },
    nailCenters: <NailDigit, Offset>{
      NailDigit.pinky: Offset(0.953, 0.285),
      NailDigit.ring: Offset(0.740, 0.123),
      NailDigit.middle: Offset(0.588, 0.059),
      NailDigit.pointer: Offset(0.408, 0.119),
      NailDigit.thumb: Offset(0.153, 0.509),
    },
  );

  /// Zeynep: 868x1018 crop of the dark reveal art, fingers down, thumb right.
  static const GuestHudHandArt dark = GuestHudHandArt(
    handAsset: AssetPaths.finalHandDarkHud,
    aspect: 868 / 1018,
    nailMasks: <NailDigit, String>{
      NailDigit.pinky: AssetPaths.finalHandDarkHudNailPinky,
      NailDigit.ring: AssetPaths.finalHandDarkHudNailRing,
      NailDigit.middle: AssetPaths.finalHandDarkHudNailMiddle,
      NailDigit.pointer: AssetPaths.finalHandDarkHudNailPointer,
      NailDigit.thumb: AssetPaths.finalHandDarkHudNailThumb,
    },
    nailCenters: <NailDigit, Offset>{
      NailDigit.pinky: Offset(0.051, 0.711),
      NailDigit.ring: Offset(0.265, 0.878),
      NailDigit.middle: Offset(0.521, 0.927),
      NailDigit.pointer: Offset(0.770, 0.875),
      NailDigit.thumb: Offset(0.941, 0.551),
    },
  );
}

class GuestCareKit {
  GuestCareKit({
    required this.washAsset,
    required this.washSheet,
    required this.washFrameAlign,
    required this.nailCleanAsset,
    required this.nailCleanSheet,
    required this.finalHandAsset,
    required this.finalHandSheet,
    this.hudHand = GuestHudHandArt.light,
    this.footWashAsset = AssetPaths.footCleanLight,
    CharacterSheet? footWashSheet,
    this.footNailCleanAsset = AssetPaths.footNailCleanLight,
    CharacterSheet? footNailCleanSheet,
    this.footNailCutAsset = AssetPaths.footNailCutStrip,
    CharacterSheet? footNailCutSheet,
    this.footNailPolishMaskAsset = AssetPaths.footNailPolishMaskLight,
    this.footNailCutVerticalOffset = 124.5,
    this.unifiedNailClean = false,
    this.skipsCutAndPolish = false,
    this.cutPolishDigits,
    this.digitArt = const <NailDigit, GuestDigitCareArt>{},
    this.stilettoArt = const <NailDigit, GuestNailShapeArt>{},
    this.stilettoFinalHandAsset,
    this.stilettoFinalHandSheet,
    this.stilettoFinalHandMaskAsset,
    this.stilettoFinalHandWristFadeEnd = 0.0,
    this.stilettoFinalHandDisplayHeight,
    this.stilettoFinalHandCenterY,
    this.shortNailAsset,
    this.shortNailSheet,
    this.polishMaskAsset,
    this.polishPlate,
  }) : footWashSheet = footWashSheet ?? SpriteAtlas.footWash,
       footNailCleanSheet = footNailCleanSheet ?? SpriteAtlas.footNailClean,
       footNailCutSheet = footNailCutSheet ?? SpriteAtlas.footNailCut;

  final String washAsset;
  final CharacterSheet washSheet;
  final List<Vector2> washFrameAlign;
  final String nailCleanAsset;
  final CharacterSheet nailCleanSheet;
  final String finalHandAsset;
  final CharacterSheet finalHandSheet;

  /// Hand drawn on the HUD progress card. Defaults to the light art, so a kit
  /// only names this when its guest is a different tone.
  final GuestHudHandArt hudHand;

  /// Whole-foot wash/toenail art matching this guest's skin tone.
  final String footWashAsset;
  final CharacterSheet footWashSheet;
  final String footNailCleanAsset;
  final CharacterSheet footNailCleanSheet;
  final String footNailCutAsset;
  final CharacterSheet footNailCutSheet;

  /// Toenail mask registered to [footNailCutAsset]'s canvas — the pedicure
  /// paints lacquer through this, the way the hand reveal does.
  final String footNailPolishMaskAsset;

  /// Nudges the foot plate down during cutting/polishing so the toes land at
  /// the same screen position as during wash/clean.
  ///
  /// [footNailCutAsset] is a different, tighter-cropped photoshoot (2172×724
  /// vs. the wash/clean sheets' 1536×1024): its content fills a taller
  /// fraction of a shorter canvas. Both sheets scale to the same fixed
  /// [GameConfig.workspaceFootWidth] and share one anchor-center position, so
  /// the cut sheet's shorter rendered height pulls the toes up toward that
  /// center — without this offset the foot visibly jumps the moment cutting
  /// starts. Value is measured per kit from each sheet's alpha silhouette,
  /// not derived at runtime, because that measurement lives in the source
  /// art, not in [CharacterSheet].
  final double footNailCutVerticalOffset;

  /// One 4-frame clean strip for every digit (spray 0–1, wipe 2–3).
  final bool unifiedNailClean;

  /// Cut and polish art is not ready for this guest yet.
  final bool skipsCutAndPolish;

  /// When set, only these digits get clip + polish; others skip after wipe.
  final Set<NailDigit>? cutPolishDigits;

  /// Per-digit dark (or guest-specific) manicure sheets.
  final Map<NailDigit, GuestDigitCareArt> digitArt;

  /// Per-digit stiletto clip art. Empty when the guest has no stiletto set,
  /// in which case the shape picker falls back to her square art.
  final Map<NailDigit, GuestNailShapeArt> stilettoArt;

  /// Finished-hand still shown when every cut nail came out stiletto.
  final String? stilettoFinalHandAsset;
  final CharacterSheet? stilettoFinalHandSheet;
  final String? stilettoFinalHandMaskAsset;

  /// Fraction of the stiletto reveal sprite's height that the top wrist-fade
  /// eats. It is per-canvas, not a global constant: the light stiletto photo
  /// points its fingers *up* and feathers its own wrist, so it needs none,
  /// while the dark stiletto's wrist is cut flat against the very top row of
  /// its canvas and needs just enough to stop that edge stamping a hard line
  /// on the table. The old shared 0.34 fraction faded roughly the top third
  /// of the dark hand away — the "only half the hand shows" bug.
  final double stilettoFinalHandWristFadeEnd;

  /// On-screen height budget for the stiletto reveal, in world units. Null
  /// keeps the shared rule — scale by width so the sprite is
  /// [GameConfig.workspaceHandWidth] across.
  ///
  /// Width alone cannot frame every reveal. A stiletto hand is mostly nail:
  /// the light one is 828×1467 in its own art, so scaling it to the shared
  /// 820 width makes it ~1450 tall and the nail tips run off the top of a
  /// 1920 play area. Fitting by height instead keeps the whole hand on
  /// screen, at the cost of a slightly narrower hand — which is the right
  /// trade, and the one the earlier "just crop the palm off" fix got
  /// backwards.
  final double? stilettoFinalHandDisplayHeight;

  /// Where the stiletto reveal's centre sits vertically. Null keeps
  /// [GameConfig.workspaceHandCenterY].
  ///
  /// Paired with the height above: a taller sprite centred on the shared
  /// line hangs lower than the square reveal's wrist, so this puts the wrist
  /// back on roughly the same seat.
  final double? stilettoFinalHandCenterY;

  /// Legacy single-digit short/mask (pinky) when [digitArt] is empty.
  final String? shortNailAsset;
  final CharacterSheet? shortNailSheet;
  final String? polishMaskAsset;
  final SpriteRegion? polishPlate;

  GuestDigitCareArt? artFor(NailDigit digit) => digitArt[digit];

  /// Stiletto clip art for [digit], or null when this guest has none — the
  /// caller then keeps her square art rather than borrowing another guest's.
  GuestNailShapeArt? stilettoArtFor(NailDigit digit) => stilettoArt[digit];

  bool allowsCutAndPolish(NailDigit digit) {
    if (skipsCutAndPolish) {
      return false;
    }
    final limited = cutPolishDigits;
    if (limited == null) {
      return true;
    }
    return limited.contains(digit);
  }
}

/// Maps a roster id to the hands that match her skin tone.
abstract final class GuestCareCatalog {
  static GuestCareKit forId(String id) {
    if (id == 'customer3') {
      return zeynep;
    }
    return light;
  }

  static final GuestCareKit light = GuestCareKit(
    washAsset: AssetPaths.handWash,
    washSheet: SpriteAtlas.handWash,
    washFrameAlign: SpriteAtlas.handWashFrameAlign,
    nailCleanAsset: AssetPaths.pinkyCleanLight,
    nailCleanSheet: SpriteAtlas.pinkyCleanLight,
    finalHandAsset: AssetPaths.finalHandLight,
    finalHandSheet: SpriteAtlas.finalHandLight,
    unifiedNailClean: true,
    cutPolishDigits: <NailDigit>{
      NailDigit.pinky,
      NailDigit.ring,
      NailDigit.middle,
      NailDigit.pointer,
      NailDigit.thumb,
    },
    digitArt: <NailDigit, GuestDigitCareArt>{
      NailDigit.pinky: GuestDigitCareArt(
        cleanAsset: AssetPaths.pinkyCleanLight,
        cleanSheet: SpriteAtlas.pinkyCleanLight,
        shortAsset: AssetPaths.pinkyShortLight,
        shortSheet: SpriteAtlas.pinkyShortLight,
        polishMaskAsset: AssetPaths.pinkyNailMaskLight,
        polishPlate: SpriteAtlas.pinkyNailPlateLight,
      ),
      NailDigit.ring: GuestDigitCareArt(
        cleanAsset: AssetPaths.middleCleanLight,
        cleanSheet: SpriteAtlas.middleCleanLight,
        shortAsset: AssetPaths.middleShortLight,
        shortSheet: SpriteAtlas.middleShortLight,
        polishMaskAsset: AssetPaths.middleNailMaskLight,
        polishPlate: SpriteAtlas.middleNailPlateLight,
      ),
      NailDigit.middle: GuestDigitCareArt(
        cleanAsset: AssetPaths.middleCleanLight,
        cleanSheet: SpriteAtlas.middleCleanLight,
        shortAsset: AssetPaths.middleShortLight,
        shortSheet: SpriteAtlas.middleShortLight,
        polishMaskAsset: AssetPaths.middleNailMaskLight,
        polishPlate: SpriteAtlas.middleNailPlateLight,
      ),
      NailDigit.pointer: GuestDigitCareArt(
        cleanAsset: AssetPaths.middleCleanLight,
        cleanSheet: SpriteAtlas.middleCleanLight,
        shortAsset: AssetPaths.middleShortLight,
        shortSheet: SpriteAtlas.middleShortLight,
        polishMaskAsset: AssetPaths.middleNailMaskLight,
        polishPlate: SpriteAtlas.middleNailPlateLight,
      ),
      NailDigit.thumb: GuestDigitCareArt(
        cleanAsset: AssetPaths.thumbCleanLight,
        cleanSheet: SpriteAtlas.thumbCleanLight,
        shortAsset: AssetPaths.thumbShortLight,
        shortSheet: SpriteAtlas.thumbShortLight,
        polishMaskAsset: AssetPaths.thumbNailMaskLight,
        polishPlate: SpriteAtlas.thumbNailPlateLight,
      ),
    },
    stilettoArt: <NailDigit, GuestNailShapeArt>{
      NailDigit.pinky: GuestNailShapeArt(
        shortAsset: AssetPaths.pinkyStilettoNailLight,
        shortSheet: SpriteAtlas.pinkyStilettoLight,
        polishMaskAsset: AssetPaths.pinkyStilettoPolishMask,
        polishPlate: SpriteAtlas.pinkyStilettoLightPlate,
      ),
      // Ring, middle and pointer all reuse the pinky's stiletto set — it's
      // the only light-hand stiletto art that fits correctly; the dedicated
      // middle-finger stiletto set was misaligned on these digits.
      NailDigit.ring: GuestNailShapeArt(
        shortAsset: AssetPaths.pinkyStilettoNailLight,
        shortSheet: SpriteAtlas.pinkyStilettoLight,
        polishMaskAsset: AssetPaths.pinkyStilettoPolishMask,
        polishPlate: SpriteAtlas.pinkyStilettoLightPlate,
      ),
      NailDigit.middle: GuestNailShapeArt(
        shortAsset: AssetPaths.pinkyStilettoNailLight,
        shortSheet: SpriteAtlas.pinkyStilettoLight,
        polishMaskAsset: AssetPaths.pinkyStilettoPolishMask,
        polishPlate: SpriteAtlas.pinkyStilettoLightPlate,
      ),
      NailDigit.pointer: GuestNailShapeArt(
        shortAsset: AssetPaths.pinkyStilettoNailLight,
        shortSheet: SpriteAtlas.pinkyStilettoLight,
        polishMaskAsset: AssetPaths.pinkyStilettoPolishMask,
        polishPlate: SpriteAtlas.pinkyStilettoLightPlate,
      ),
      NailDigit.thumb: GuestNailShapeArt(
        shortAsset: AssetPaths.thumbNailStilettoLight,
        shortSheet: SpriteAtlas.thumbStilettoLight,
        polishMaskAsset: AssetPaths.thumbStilettoPolishMask,
        polishPlate: SpriteAtlas.thumbStilettoLightPlate,
      ),
    },
    stilettoFinalHandAsset: AssetPaths.finalHandStiletto,
    stilettoFinalHandSheet: SpriteAtlas.finalHandStiletto,
    stilettoFinalHandMaskAsset: AssetPaths.finalHandStilettoMask,
    // Fit by height: the full-hand art is 828×1467, so the shared
    // width-820 rule would draw it ~1450 tall and push the nail tips off the
    // top. 1150 puts the hand in roughly the same vertical band as the
    // square reveal (which occupies ~1092), and the centre lands the wrist
    // on the same seat rather than below it. Both numbers are eyeball-tuned
    // — nudge them together (centre = wristLine − height / 2) if the hand
    // sits high or low against the pad.
    stilettoFinalHandDisplayHeight: 1150,
    stilettoFinalHandCenterY: 691,
    shortNailAsset: AssetPaths.pinkyShortLight,
    shortNailSheet: SpriteAtlas.pinkyShortLight,
    polishMaskAsset: AssetPaths.pinkyNailMaskLight,
    polishPlate: SpriteAtlas.pinkyNailPlateLight,
  );

  static final GuestCareKit zeynep = GuestCareKit(
    washAsset: AssetPaths.handWashDark,
    washSheet: SpriteAtlas.handWashDark,
    washFrameAlign: SpriteAtlas.handWashDark.frameAlign,
    nailCleanAsset: AssetPaths.pinkyCleanDark,
    nailCleanSheet: SpriteAtlas.pinkyCleanDark,
    finalHandAsset: AssetPaths.finalHandDark,
    finalHandSheet: SpriteAtlas.finalHandDark,
    hudHand: GuestHudHandArt.dark,
    footWashAsset: AssetPaths.footCleanDark,
    footWashSheet: SpriteAtlas.footWashDark,
    footNailCleanAsset: AssetPaths.footNailCleanDark,
    footNailCleanSheet: SpriteAtlas.footNailCleanDark,
    footNailCutAsset: AssetPaths.footNailCutStripDark,
    footNailCutSheet: SpriteAtlas.footNailCutDark,
    footNailPolishMaskAsset: AssetPaths.footNailPolishMaskDark,
    footNailCutVerticalOffset: 110.7,
    unifiedNailClean: true,
    cutPolishDigits: <NailDigit>{
      NailDigit.pinky,
      NailDigit.ring,
      NailDigit.middle,
      NailDigit.pointer,
      NailDigit.thumb,
    },
    digitArt: <NailDigit, GuestDigitCareArt>{
      NailDigit.pinky: GuestDigitCareArt(
        cleanAsset: AssetPaths.pinkyCleanDark,
        cleanSheet: SpriteAtlas.pinkyCleanDark,
        shortAsset: AssetPaths.pinkyShortDark,
        shortSheet: SpriteAtlas.pinkyShortDark,
        polishMaskAsset: AssetPaths.pinkyNailMaskDark,
        polishPlate: SpriteAtlas.pinkyNailPlateDark,
      ),
      NailDigit.ring: GuestDigitCareArt(
        cleanAsset: AssetPaths.ringCleanDark,
        cleanSheet: SpriteAtlas.ringCleanDark,
        shortAsset: AssetPaths.ringShortDark,
        shortSheet: SpriteAtlas.ringShortDark,
        polishMaskAsset: AssetPaths.ringNailMaskDark,
        polishPlate: SpriteAtlas.ringNailPlateDark,
      ),
      NailDigit.middle: GuestDigitCareArt(
        cleanAsset: AssetPaths.middleCleanDark,
        cleanSheet: SpriteAtlas.middleCleanDark,
        shortAsset: AssetPaths.middleShortDark,
        shortSheet: SpriteAtlas.middleShortDark,
        polishMaskAsset: AssetPaths.middleNailMaskDark,
        polishPlate: SpriteAtlas.middleNailPlateDark,
      ),
      NailDigit.pointer: GuestDigitCareArt(
        cleanAsset: AssetPaths.indexCleanDark,
        cleanSheet: SpriteAtlas.indexCleanDark,
        shortAsset: AssetPaths.indexShortDark,
        shortSheet: SpriteAtlas.indexShortDark,
        polishMaskAsset: AssetPaths.indexNailMaskDark,
        polishPlate: SpriteAtlas.indexNailPlateDark,
      ),
      NailDigit.thumb: GuestDigitCareArt(
        // Dedicated dirty->clean thumb photo for the spray/wipe stage. This
        // replaces the earlier stopgap that reused the stiletto strip's
        // first frame. The short/cut sheet + polish mask below are
        // unaffected — they only apply once nail cutting/polishing starts.
        cleanAsset: AssetPaths.thumbNailDarkWipe,
        cleanSheet: SpriteAtlas.thumbCleanDarkWipe,
        shortAsset: AssetPaths.thumbShortDark,
        shortSheet: SpriteAtlas.thumbShortDark,
        polishMaskAsset: AssetPaths.thumbNailMaskDark,
        polishPlate: SpriteAtlas.thumbNailPlateDark,
      ),
    },
    stilettoArt: <NailDigit, GuestNailShapeArt>{
      // Pinky, ring, middle and pointer share one dark stiletto strip; only
      // the thumb has its own.
      for (final NailDigit d in <NailDigit>[
        NailDigit.pinky,
        NailDigit.ring,
        NailDigit.middle,
        NailDigit.pointer,
      ])
        d: GuestNailShapeArt(
          shortAsset: AssetPaths.pinkyStilettoNailDark,
          shortSheet: SpriteAtlas.pinkyStilettoDark,
          polishMaskAsset: AssetPaths.pinkyStilettoMaskDark,
          polishPlate: SpriteAtlas.pinkyStilettoDarkPlate,
        ),
      NailDigit.thumb: GuestNailShapeArt(
        shortAsset: AssetPaths.thumbStilettoNailDark,
        shortSheet: SpriteAtlas.thumbStilettoDark,
        polishMaskAsset: AssetPaths.thumbStilettoMaskDark,
        polishPlate: SpriteAtlas.thumbStilettoDarkPlate,
      ),
    },
    stilettoFinalHandAsset: AssetPaths.finalHandDarkStiletto,
    stilettoFinalHandSheet: SpriteAtlas.finalHandDarkStiletto,
    stilettoFinalHandMaskAsset: AssetPaths.finalHandDarkStilettoMask,
    stilettoFinalHandWristFadeEnd: 0.10,
    shortNailAsset: AssetPaths.pinkyShortDark,
    shortNailSheet: SpriteAtlas.pinkyShortDark,
    polishMaskAsset: AssetPaths.pinkyNailMaskDark,
    polishPlate: SpriteAtlas.pinkyNailPlateDark,
  );
}
