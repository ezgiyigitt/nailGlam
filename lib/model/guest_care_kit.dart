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
class GuestCareKit {
  GuestCareKit({
    required this.washAsset,
    required this.washSheet,
    required this.washFrameAlign,
    required this.nailCleanAsset,
    required this.nailCleanSheet,
    required this.finalHandAsset,
    required this.finalHandSheet,
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
    shortNailAsset: AssetPaths.pinkyShortDark,
    shortNailSheet: SpriteAtlas.pinkyShortDark,
    polishMaskAsset: AssetPaths.pinkyNailMaskDark,
    polishPlate: SpriteAtlas.pinkyNailPlateDark,
  );
}
