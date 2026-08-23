import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/sprite_atlas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('walk sheet is a 4x1 pipeline row', () async {
    final data = await rootBundle.load('assets/images/customer-walk-v1.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    expect(image.width, 1544);
    expect(image.height, 841);
    expect(SpriteAtlas.customerWalk.frameCount, 4);
  });
}
