import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/sprite_atlas.dart';

void main() {
  group('nail-care sheets', () {
    test('hand wash cells lock to the first pose', () {
      expect(SpriteAtlas.handWashFrameAlign, hasLength(4));
      expect(SpriteAtlas.handWashFrameAlign[0], Vector2.zero());
      expect(SpriteAtlas.handWashFrameAlign[1].x + 237, 245);
      expect(SpriteAtlas.handWashFrameAlign[2].x + 224, 245);
      expect(SpriteAtlas.handWashFrameAlign[3].x + 217, 245);
    });

    test('hand wash sheet is four even cells', () {
      final sheet = SpriteAtlas.handWash;
      expect(sheet.frameCount, 4);
      expect(sheet.frameSize, Vector2(512, 682));
      for (var i = 0; i < sheet.frameCount; i++) {
        expect(sheet.framePositions[i].x, i * 512);
        expect(
          sheet.framePositions[i].x + sheet.frameSize.x,
          lessThanOrEqualTo(2048),
        );
      }
    });

    test('pinky clean sheet windows stay inside the source image', () {
      final sheet = SpriteAtlas.fifthNailClean;
      expect(sheet.frameCount, 4);
      for (final origin in sheet.framePositions) {
        expect(origin.x + sheet.frameSize.x, lessThanOrEqualTo(1672));
        expect(origin.y + sheet.frameSize.y, lessThanOrEqualTo(941));
      }
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
      expect(SpriteAtlas.pinkNailPlate.position.x + SpriteAtlas.pinkNailPlate.size.x, lessThanOrEqualTo(384));
      expect(SpriteAtlas.pinkNailPlate.position.y + SpriteAtlas.pinkNailPlate.size.y, lessThanOrEqualTo(1024));
      expect(SpriteAtlas.ringNailPlate.position.x + SpriteAtlas.ringNailPlate.size.x, lessThanOrEqualTo(384));
      expect(SpriteAtlas.ringNailPlate.position.y + SpriteAtlas.ringNailPlate.size.y, lessThanOrEqualTo(1024));
      expect(SpriteAtlas.pinkNailPlate.size.x, greaterThan(170));
      expect(SpriteAtlas.ringNailPlate.size.x, greaterThan(170));
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
