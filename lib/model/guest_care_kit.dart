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

/// Per-guest wash / nail-clean / reveal art.
class GuestCareKit {
  const GuestCareKit({
    required this.washAsset,
    required this.washSheet,
    required this.washFrameAlign,
    required this.nailCleanAsset,
    required this.nailCleanSheet,
    required this.finalHandAsset,
    required this.finalHandSheet,
    this.unifiedNailClean = false,
    this.skipsCutAndPolish = false,
    this.cutPolishDigits,
    this.digitArt = const <NailDigit, GuestDigitCareArt>{},
    this.shortNailAsset,
    this.shortNailSheet,
    this.polishMaskAsset,
    this.polishPlate,
  });

  final String washAsset;
  final CharacterSheet washSheet;
  final List<Vector2> washFrameAlign;
  final String nailCleanAsset;
  final CharacterSheet nailCleanSheet;
  final String finalHandAsset;
  final CharacterSheet finalHandSheet;

  /// One 4-frame clean strip for every digit (spray 0–1, wipe 2–3).
  final bool unifiedNailClean;

  /// Cut and polish art is not ready for this guest yet.
  final bool skipsCutAndPolish;

  /// When set, only these digits get clip + polish; others skip after wipe.
  final Set<NailDigit>? cutPolishDigits;

  /// Per-digit dark (or guest-specific) manicure sheets.
  final Map<NailDigit, GuestDigitCareArt> digitArt;

  /// Legacy single-digit short/mask (pinky) when [digitArt] is empty.
  final String? shortNailAsset;
  final CharacterSheet? shortNailSheet;
  final String? polishMaskAsset;
  final SpriteRegion? polishPlate;

  GuestDigitCareArt? artFor(NailDigit digit) => digitArt[digit];

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
        cleanAsset: AssetPaths.thumbCleanDark,
        cleanSheet: SpriteAtlas.thumbCleanDark,
        shortAsset: AssetPaths.thumbShortDark,
        shortSheet: SpriteAtlas.thumbShortDark,
        polishMaskAsset: AssetPaths.thumbNailMaskDark,
        polishPlate: SpriteAtlas.thumbNailPlateDark,
      ),
    },
    shortNailAsset: AssetPaths.pinkyShortDark,
    shortNailSheet: SpriteAtlas.pinkyShortDark,
    polishMaskAsset: AssetPaths.pinkyNailMaskDark,
    polishPlate: SpriteAtlas.pinkyNailPlateDark,
  );
}
