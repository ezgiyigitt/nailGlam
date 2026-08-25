import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/nail_finger_treatment.dart';
import 'package:nail_glam/model/sprite_atlas.dart';

void main() {
  group('nail-care sheets', () {
    test('hand wash cells lock to the first pose', () {
      expect(SpriteAtlas.handWashFrameAlign, hasLength(4));
      for (final align in SpriteAtlas.handWashFrameAlign) {
        expect(align, Vector2.zero());
      }
    });

    test('hand wash sheet is four even cells', () {
      final sheet = SpriteAtlas.handWash;
      expect(sheet.frameCount, 4);
      expect(sheet.frameSize, Vector2(979, 1473));
      for (var i = 0; i < sheet.frameCount; i++) {
        expect(sheet.framePositions[i].x, i * 979);
        expect(
          sheet.framePositions[i].x + sheet.frameSize.x,
          lessThanOrEqualTo(3916),
        );
      }
    });

    test('finished hand is a single still, not a strip', () {
      final sheet = SpriteAtlas.finalHand;
      expect(sheet.frameCount, 1);
      expect(sheet.frameSize, Vector2(869, 1055));
      expect(sheet.framePositions.single, Vector2(288, 0));
      expect(
        sheet.framePositions.single.x + sheet.frameSize.x,
        lessThanOrEqualTo(1448),
      );
      expect(
        sheet.framePositions.single.y + sheet.frameSize.y,
        lessThanOrEqualTo(1086),
      );
    });

    test('pinky clean sheet windows stay inside the source image', () {
      final sheet = SpriteAtlas.fifthNailClean;
      expect(sheet.frameCount, 4);
      for (final origin in sheet.framePositions) {
        expect(origin.x + sheet.frameSize.x, lessThanOrEqualTo(1672));
        expect(origin.y + sheet.frameSize.y, lessThanOrEqualTo(941));
      }
    });

    test('pinky and ring spray/wipe sheets are four even cells', () {
      void expectSplit(CharacterSheet sheet, double width, double height) {
        expect(sheet.frameCount, 4);
        expect(sheet.frameSize, Vector2(width, height));
        for (var i = 0; i < sheet.frameCount; i++) {
          expect(sheet.framePositions[i], Vector2(i * width, 0));
          expect(
            sheet.framePositions[i].x + sheet.frameSize.x,
            lessThanOrEqualTo(width * 4 + 1),
          );
        }
      }

      expectSplit(SpriteAtlas.fifthNailSpray, 355, 879);
      expectSplit(SpriteAtlas.fifthNailWipe, 355, 879);
      expectSplit(SpriteAtlas.fourthNailSpray, 355, 758);
      expectSplit(SpriteAtlas.fourthNailWipe, 355, 758);
      expect(SpriteAtlas.fifthNailSpray.frameAlign[0], Vector2.zero());
      expect(SpriteAtlas.fifthNailWipe.frameAlign[0].x, closeTo(-4.29, 0.01));
    });

    test('Zeynep wash and pinky-clean sheets are four even cells', () {
      final wash = SpriteAtlas.handWashDark;
      expect(wash.frameCount, 4);
      expect(wash.frameSize, Vector2(988, 1358));
      for (var i = 0; i < wash.frameCount; i++) {
        expect(wash.framePositions[i], Vector2(i * 988, 0));
      }
      final pinky = SpriteAtlas.pinkyCleanDark;
      expect(pinky.frameCount, 4);
      expect(pinky.frameSize, Vector2(464, 1398));
      for (var i = 0; i < pinky.frameCount; i++) {
        expect(pinky.framePositions[i], Vector2(i * 464.0, 0));
      }
    });

    test('Zeynep finished hand is a single still window', () {
      final sheet = SpriteAtlas.finalHandDark;
      expect(sheet.frameCount, 1);
      expect(sheet.frameSize, Vector2(868, 1018));
      expect(sheet.framePositions.single, Vector2(344, 0));
      expect(
        sheet.framePositions.single.x + sheet.frameSize.x,
        lessThanOrEqualTo(1536),
      );
      expect(
        sheet.framePositions.single.y + sheet.frameSize.y,
        lessThanOrEqualTo(1024),
      );
    });

    test('split treatment catalog covers pinky and ring only', () {
      expect(NailFingerTreatmentCatalog.hasSplitSheets(NailDigit.pinky), isTrue);
      expect(NailFingerTreatmentCatalog.hasSplitSheets(NailDigit.ring), isTrue);
      expect(
        NailFingerTreatmentCatalog.hasSplitSheets(NailDigit.middle),
        isFalse,
      );
      expect(NailFingerTreatmentCatalog.pinky.splitSprayWipe, isTrue);
      expect(NailFingerTreatmentCatalog.ring.splitSprayWipe, isTrue);
    });

    test('short nail lock keeps the long tip on the last clean tip', () {
      expect(SpriteAtlas.shortNailAlign.x + 166, 113);
      expect(SpriteAtlas.shortNailAlign.y + 836, 866);
    });

    test('fourth nail clean windows stay inside the source image', () {
      final sheet = SpriteAtlas.fourthNail;
      expect(sheet.frameCount, 4);
      expect(sheet.frameSize, Vector2(355, 758));
      for (final origin in sheet.framePositions) {
        expect(origin.x + sheet.frameSize.x, lessThanOrEqualTo(1942));
        expect(origin.y + sheet.frameSize.y, lessThanOrEqualTo(809));
      }
      final short = SpriteAtlas.fourthShortNail;
      expect(short.frameCount, 4);
      expect(short.frameSize, Vector2(384, 1024));
      expect(SpriteAtlas.fourthShortNailAlign.x + 191.5, 133);
      expect(
        SpriteAtlas.fourthShortNailAlign.y + 974,
        closeTo(740 * 879 / 758, 0.02),
      );
    });

    test('polish plates sit on the clipped short cells', () {
      void expectPlate(SpriteRegion plate, double maxW, double maxH) {
        expect(plate.position.x + plate.size.x, lessThanOrEqualTo(maxW));
        expect(plate.position.y + plate.size.y, lessThanOrEqualTo(maxH));
        expect(plate.size.x, greaterThan(170));
        expect(plate.size.y, greaterThan(250));
      }

      expectPlate(SpriteAtlas.pinkNailPlate, 384, 1024);
      expectPlate(SpriteAtlas.pinkyNailPlateLight, 464, 1398);
      expectPlate(SpriteAtlas.pinkyNailPlateDark, 464, 1398);
      expectPlate(SpriteAtlas.ringNailPlate, 384, 1024);
      expectPlate(SpriteAtlas.thirdNailPlate, 384, 1024);
      expectPlate(SpriteAtlas.secondNailPlate, 444, 887);
      expectPlate(SpriteAtlas.firstNailPlate, 444, 887);
    });

    test('third, second, and first sheets are even cells', () {
      void expectEven(CharacterSheet sheet, double width, double height, double maxW) {
        expect(sheet.frameCount, 4);
        expect(sheet.frameSize, Vector2(width, height));
        expect(sheet.frameAlign[0], Vector2.zero());
        for (var i = 0; i < sheet.frameCount; i++) {
          expect(sheet.framePositions[i], Vector2(i * width, 0));
          expect(sheet.contentCenterOffsets[i], Vector2.zero());
          expect(
            sheet.framePositions[i].x + sheet.frameSize.x,
            lessThanOrEqualTo(maxW),
          );
        }
      }

      expectEven(SpriteAtlas.thirdNailClean, 443.5, 887, 1774);
      expectEven(SpriteAtlas.thirdNailShort, 384, 1024, 1536);
      expectEven(SpriteAtlas.secondNailClean, 443.5, 887, 1774);
      expectEven(SpriteAtlas.secondNailShort, 443.5, 887, 1774);
      expectEven(SpriteAtlas.firstNailClean, 443.5, 887, 1774);
      expectEven(SpriteAtlas.firstNailShort, 443.5, 887, 1774);
    });

    test('clip sheets lock the cuticle so only the tip shortens', () {
      void expectCuticleLock(CharacterSheet sheet) {
        expect(sheet.frameAlign, hasLength(sheet.frameCount));
        expect(sheet.frameAlign[0], Vector2.zero());
      }

      expectCuticleLock(SpriteAtlas.shortNail);
      expectCuticleLock(SpriteAtlas.fourthShortNail);
      expectCuticleLock(SpriteAtlas.thirdNailShort);
      expectCuticleLock(SpriteAtlas.secondNailShort);
      expectCuticleLock(SpriteAtlas.firstNailShort);

      // Ring short redraws the finger ~113px higher as the tip shortens.
      expect(SpriteAtlas.fourthShortNail.frameAlign[1].y, closeTo(113, 0.5));
      expect(SpriteAtlas.fourthShortNail.frameAlign[2].y, closeTo(114, 0.5));
      // Middle / index drift left in the sheet during the cut.
      expect(SpriteAtlas.thirdNailShort.frameAlign[2].x, closeTo(-35.5, 0.05));
      expect(SpriteAtlas.secondNailShort.frameAlign[3].x, closeTo(-30.5, 0.05));
      // Clean sheets stay stump-X only (Y = 0).
      expect(SpriteAtlas.fifthNailClean.frameAlign[2].x, closeTo(-7.73, 0.01));
      expect(SpriteAtlas.fifthNailClean.frameAlign[2].y, 0);
      expect(SpriteAtlas.fourthNail.frameAlign[2].y, 0);
      expect(SpriteAtlas.thirdNailClean.frameAlign[2].y, 0);
    });

    test('light shared finger plate matches pinky short mask', () {
      expect(
        SpriteAtlas.middleNailPlateLight.position,
        SpriteAtlas.pinkyNailPlateLight.position,
      );
      expect(
        SpriteAtlas.middleNailPlateLight.size,
        SpriteAtlas.pinkyNailPlateLight.size,
      );
      final plate = SpriteAtlas.middleNailPlateLight;
      expect(plate.position.x + plate.size.x, lessThanOrEqualTo(464));
      expect(plate.position.y + plate.size.y, lessThanOrEqualTo(1398));
    });

    test('light ring middle index sheets are four even cells', () {
      for (final sheet in <CharacterSheet>[
        SpriteAtlas.middleCleanLight,
        SpriteAtlas.middleShortLight,
      ]) {
        expect(sheet.frameCount, 4);
        expect(sheet.frameSize, Vector2(464, 1398));
        for (var i = 0; i < sheet.frameCount; i++) {
          expect(sheet.framePositions[i], Vector2(i * 464.0, 0));
        }
      }
    });

    test('short nail sheet is four even cells', () {
      final sheet = SpriteAtlas.shortNail;
      expect(sheet.frameCount, 4);
      expect(sheet.frameSize, Vector2(384, 1024));
      expect(sheet.contentCenterOffsets, hasLength(4));
      for (var i = 0; i < sheet.frameCount; i++) {
        expect(sheet.framePositions[i].x, i * 384);
        expect(
          sheet.framePositions[i].x + sheet.frameSize.x,
          lessThanOrEqualTo(1536),
        );
      }
    });
  });
}
