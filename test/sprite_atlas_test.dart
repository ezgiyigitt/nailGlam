import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/sprite_atlas.dart';

/// The character frame windows are hand-measured from the source art, so these
/// tests guard the two things that silently break the animation if a number is
/// wrong: a window falling outside its sheet (clipped frames) and the sheets
/// disagreeing on frame count.
void main() {
  group('character sheets', () {
    final sheets = <String, (CharacterSheet, Vector2, int)>{
      'walk': (SpriteAtlas.customerWalk, Vector2(1024, 890), 8),
      'sit': (SpriteAtlas.customerSit, Vector2(1536, 1024), 8),
      'sitIdle': (SpriteAtlas.customerSitIdle, Vector2(1997, 788), 4),
      'handsToTable': (
        SpriteAtlas.customerHandsToTable,
        Vector2(2173, 724),
        6,
      ),
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
            lessThanOrEqualTo(imageSize.x),
            reason: 'frame $i right edge',
          );
          expect(
            origin.y + sheet.frameSize.y,
            lessThanOrEqualTo(imageSize.y),
            reason: 'frame $i bottom edge',
          );
        }
      });
    });

    test('each frame has a non-negative measured foot padding', () {
      for (final sheet in sheets.values.map((spec) => spec.$1)) {
        expect(sheet.footPaddings, hasLength(sheet.frameCount));
        expect(sheet.footPaddings.every((padding) => padding >= 0), isTrue);
      }
    });
  });
}
