import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/sprite_atlas.dart';

/// Spray vs wipe treatment sheets for one finger.
enum NailTreatmentPhase { spray, wipe }

/// Sprite definitions for nail clean stages on a single digit.
class NailFingerTreatmentArt {
  const NailFingerTreatmentArt({
    required this.sprayAsset,
    required this.wipeAsset,
    required this.spraySheet,
    required this.wipeSheet,
    required this.legacyCleanAsset,
    required this.legacyCleanSheet,
    this.splitSprayWipe = false,
  });

  final String sprayAsset;
  final String wipeAsset;
  final CharacterSheet spraySheet;
  final CharacterSheet wipeSheet;
  final String legacyCleanAsset;
  final CharacterSheet legacyCleanSheet;

  /// When true, spray and wipe are separate 4-frame strips.
  final bool splitSprayWipe;
}

/// Maps each digit to its treatment art. Pinky and ring use split sheets.
abstract final class NailFingerTreatmentCatalog {
  static bool hasSplitSheets(NailDigit digit) =>
      digit == NailDigit.pinky || digit == NailDigit.ring;

  static NailFingerTreatmentArt artFor(NailDigit digit) => switch (digit) {
        NailDigit.pinky => pinky,
        NailDigit.ring => ring,
        NailDigit.middle => _legacy(
          AssetPaths.thirdNailClean,
          SpriteAtlas.thirdNailClean,
        ),
        NailDigit.pointer => _legacy(
          AssetPaths.secondNailClean,
          SpriteAtlas.secondNailClean,
        ),
        NailDigit.thumb => _legacy(
          AssetPaths.firstNailClean,
          SpriteAtlas.firstNailClean,
        ),
      };

  static final NailFingerTreatmentArt pinky = NailFingerTreatmentArt(
    sprayAsset: AssetPaths.fifthNailSpray,
    wipeAsset: AssetPaths.fifthNailWipe,
    spraySheet: SpriteAtlas.fifthNailSpray,
    wipeSheet: SpriteAtlas.fifthNailWipe,
    legacyCleanAsset: AssetPaths.fifthNailClean,
    legacyCleanSheet: SpriteAtlas.fifthNailClean,
    splitSprayWipe: true,
  );

  static final NailFingerTreatmentArt ring = NailFingerTreatmentArt(
    sprayAsset: AssetPaths.fourthNailSpray,
    wipeAsset: AssetPaths.fourthNailWipe,
    spraySheet: SpriteAtlas.fourthNailSpray,
    wipeSheet: SpriteAtlas.fourthNailWipe,
    legacyCleanAsset: AssetPaths.fourthNail,
    legacyCleanSheet: SpriteAtlas.fourthNail,
    splitSprayWipe: true,
  );

  static NailFingerTreatmentArt _legacy(
    String asset,
    CharacterSheet sheet,
  ) =>
      NailFingerTreatmentArt(
        sprayAsset: asset,
        wipeAsset: asset,
        spraySheet: sheet,
        wipeSheet: sheet,
        legacyCleanAsset: asset,
        legacyCleanSheet: sheet,
      );
}
