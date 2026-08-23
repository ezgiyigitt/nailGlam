import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/game_config.dart';
import 'package:nail_glam/game/config/sprite_atlas.dart';

void main() {
  group('character sheets', () {
    final sheets = <String, (CharacterSheet, Vector2, int)>{
      'walk': (SpriteAtlas.customerWalk, Vector2(1544, 841), 4),
      'stop': (SpriteAtlas.customerStop, Vector2(271, 934), 1),
      'turn': (SpriteAtlas.customerTurn, Vector2(1120, 941), 4),
      'sit': (SpriteAtlas.customerSit, Vector2(1492, 879), 4),
      'look': (SpriteAtlas.customerLook, Vector2(1024, 1536), 1),
      'emotion': (SpriteAtlas.customerEmotion, Vector2(2350, 587), 5),
    };

    sheets.forEach((String name, (CharacterSheet, Vector2, int) spec) {
      final (sheet, imageSize, expectedFrames) = spec;

      test('$name has $expectedFrames frames', () {
        expect(sheet.frameCount, expectedFrames);
      });

      test('$name frames stay inside the source image', () {
        for (var i = 0; i < sheet.frameCount; i++) {
          final origin = sheet.framePositions[i];
          expect(origin.x, greaterThanOrEqualTo(0), reason: 'frame $i left');
          expect(origin.y, greaterThanOrEqualTo(0), reason: 'frame $i top');
          expect(
            origin.x + sheet.frameSize.x,
            lessThanOrEqualTo(imageSize.x + 0.5),
            reason: 'frame $i right edge',
          );
          expect(
            origin.y + sheet.frameSize.y,
            lessThanOrEqualTo(imageSize.y + 0.5),
            reason: 'frame $i bottom edge',
          );
        }
      });
    });

    test('walk playback reads the 4x1 pipeline walk sheet', () {
      final walk = SpriteAtlas.customerWalk;
      const cellW = 386.0;
      const cellH = 841.0;
      expect(walk.frameCount, 4);
      for (var i = 0; i < walk.frameCount; i++) {
        final origin = walk.framePositions[i];
        expect(origin.x, closeTo(i * cellW, 0.01));
        expect(origin.y, 0);
        expect(origin.x + walk.frameSize.x, lessThanOrEqualTo(4 * cellW + 0.5));
        expect(origin.y + walk.frameSize.y, lessThanOrEqualTo(cellH + 0.5));
      }
    });

    test('each frame has a non-negative measured foot padding', () {
      for (final sheet in sheets.values.map((spec) => spec.$1)) {
        expect(sheet.footPaddings, hasLength(sheet.frameCount));
        expect(sheet.footPaddings.every((padding) => padding >= 0), isTrue);
      }
    });

    test('hand wash sheet is four even cells', () {
      final sheet = SpriteAtlas.handWash;
      expect(sheet.frameCount, 4);
      expect(sheet.frameSize, Vector2(543, 724));
      for (var i = 0; i < sheet.frameCount; i++) {
        expect(sheet.framePositions[i].x, i * 543);
        expect(
          sheet.framePositions[i].x + sheet.frameSize.x,
          lessThanOrEqualTo(2172),
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

  test('seated layout keeps the customer behind the angled desk', () {
    expect(GameConfig.customerSeatX, lessThan(GameConfig.tableX));
    expect(GameConfig.chairX, GameConfig.customerSeatX);
    expect(GameConfig.chairGroundY, lessThan(GameConfig.tableGroundY));
    expect(GameConfig.priorityChair, lessThan(GameConfig.priorityCustomer));
    expect(GameConfig.priorityCustomer, lessThan(GameConfig.priorityTable));
  });
}
