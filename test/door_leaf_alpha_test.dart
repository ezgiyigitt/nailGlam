import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('door leaf has no Photoshop transparency grid', () async {
    final data = await rootBundle.load('assets/images/door.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final px = bytes.buffer.asUint8List();

    var checker = 0;
    var visible = 0;
    for (var i = 0; i < px.length; i += 4) {
      final r = px[i];
      final g = px[i + 1];
      final b = px[i + 2];
      final a = px[i + 3];
      if (a < 16 || (r < 12 && g < 12 && b < 12)) {
        continue;
      }
      visible++;
      final maxc = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minc = r < g ? (r < b ? r : b) : (g < b ? g : b);
      if (maxc - minc <= 22 && b >= r - 2 && maxc >= 70 && maxc <= 230) {
        checker++;
      }
    }

    expect(visible, greaterThan(1000));
    expect(checker, 0, reason: 'baked transparency grid still in the door leaf');
  });
}
