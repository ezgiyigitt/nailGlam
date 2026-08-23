import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/sprite_atlas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('customer art vs atlas', () {
    final sheets = <String, _Spec>{
      'walk': _Spec(
        asset: 'assets/images/customer-walk-v1.png',
        sheet: SpriteAtlas.customerWalk,
        imageSize: const ui.Size(1544, 841),
      ),
      'stop': _Spec(
        asset: 'assets/images/customer1_stop.png',
        sheet: SpriteAtlas.customerStop,
        imageSize: const ui.Size(271, 934),
      ),
      'turn': _Spec(
        asset: 'assets/images/customer1_sit.png',
        sheet: SpriteAtlas.customerTurn,
        imageSize: const ui.Size(1120, 941),
      ),
      'sit': _Spec(
        asset: 'assets/images/customer1_wait.png',
        sheet: SpriteAtlas.customerSit,
        imageSize: const ui.Size(1492, 879),
      ),
      'look': _Spec(
        asset: 'assets/images/character_look.png',
        sheet: SpriteAtlas.customerLook,
        imageSize: const ui.Size(1024, 1536),
      ),
      'emotion': _Spec(
        asset: 'assets/images/customer_emotion.png',
        sheet: SpriteAtlas.customerEmotion,
        imageSize: const ui.Size(2350, 587),
      ),
    };

    sheets.forEach((name, spec) {
      test('$name windows contain opaque pixels', () async {
        final data = await rootBundle.load(spec.asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        final image = frame.image;

        expect(image.width, spec.imageSize.width, reason: '$name width');
        expect(image.height, spec.imageSize.height, reason: '$name height');

        for (var i = 0; i < spec.sheet.frameCount; i++) {
          final origin = spec.sheet.framePositions[i];
          final window = ui.Rect.fromLTWH(
            origin.x,
            origin.y,
            spec.sheet.frameSize.x,
            spec.sheet.frameSize.y,
          );
          expect(
            await _opaquePixelCount(image, window),
            greaterThan(100),
            reason: 'frame $i appears empty',
          );
        }
      });
    });
  });
}

class _Spec {
  const _Spec({
    required this.asset,
    required this.sheet,
    required this.imageSize,
  });

  final String asset;
  final CharacterSheet sheet;
  final ui.Size imageSize;
}

Future<int> _opaquePixelCount(ui.Image image, ui.Rect rect) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return 0;
  }
  final bytes = byteData.buffer.asUint8List();
  final stride = image.width * 4;

  var count = 0;
  final left = rect.left.floor().clamp(0, image.width - 1);
  final top = rect.top.floor().clamp(0, image.height - 1);
  final right = rect.right.ceil().clamp(0, image.width);
  final bottom = rect.bottom.ceil().clamp(0, image.height);

  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      final i = y * stride + x * 4;
      final a = bytes[i + 3];
      if (a < 16) {
        continue;
      }
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      if (a > 240 && r < 12 && g < 12 && b < 12) {
        continue;
      }
      count++;
    }
  }
  return count;
}
