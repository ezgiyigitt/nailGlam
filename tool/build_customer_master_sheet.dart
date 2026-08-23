// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;

/// Stitches the customer animation PNGs into one master spritesheet and
/// writes frame-offset metadata.
///
/// Run from project root:
///   dart run tool/build_customer_master_sheet.dart
Future<void> main() async {
  final blocks = <_Block>[
    _Block('walk', 'assets/images/customer_01_walk.png', 4, 4, 1),
    _Block('sit', 'assets/images/customer_01_sit.png', 5, 5, 1),
    _Block('handsToTable', 'assets/images/customer_01_hands_to_table.png', 4, 4, 1),
  ];

  final decoded = <_DecodedBlock>[];
  for (final block in blocks) {
    final file = File(block.path);
    if (!file.existsSync()) {
      throw StateError('Missing ${block.path}');
    }
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    decoded.add(_DecodedBlock(block: block, image: frame.image));
  }

  final masterWidth = decoded
      .map((d) => d.image.width)
      .reduce((a, b) => a > b ? a : b);
  var masterHeight = 0;
  for (final d in decoded) {
    masterHeight += d.image.height;
  }

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  var yOffset = 0;

  print('Master sheet: ${masterWidth}x$masterHeight');
  print('');

  for (final d in decoded) {
    final image = d.image;
    final xPad = (masterWidth - image.width) / 2;
    canvas.drawImage(image, ui.Offset(xPad, yOffset.toDouble()), ui.Paint());

    print('// ${d.block.name} @ y=$yOffset (xPad=${xPad.toStringAsFixed(0)})');
    await _printBlockFrames(
      image: image,
      yBase: yOffset,
      xBase: xPad,
      columns: d.block.columns,
      rows: d.block.rows,
      frames: d.block.frames,
    );

    yOffset += image.height;
  }

  final picture = recorder.endRecording();
  final masterImage = await picture.toImage(masterWidth, masterHeight);
  final pngBytes = await masterImage.toByteData(format: ui.ImageByteFormat.png);
  if (pngBytes == null) {
    throw StateError('Failed to encode master PNG');
  }

  final outPath = 'assets/images/customer_01_master.png';
  await File(outPath).writeAsBytes(pngBytes.buffer.asUint8List());
  print('\nWrote $outPath');
}

Future<void> _printBlockFrames({
  required ui.Image image,
  required int yBase,
  required double xBase,
  required int columns,
  required int rows,
  required int frames,
}) async {
  final cellW = image.width / columns;
  final cellH = image.height / rows;

  final origins = <String>[];
  final footPaddings = <String>[];
  var maxW = 0.0;
  var maxH = 0.0;

  for (var i = 0; i < frames; i++) {
    final col = i % columns;
    final row = i ~/ columns;
    final cellLeft = col * cellW;
    final cellTop = row * cellH;

    final bounds = await _opaqueBoundsInRect(
      image,
      cellLeft.floor(),
      cellTop.floor(),
      cellW.ceil(),
      cellH.ceil(),
    );
    if (bounds == null) {
      continue;
    }

    final ox = xBase + bounds.left;
    final oy = yBase + bounds.top;
    origins.add(
      'Vector2(${ox.toStringAsFixed(0)}, ${oy.toStringAsFixed(0)})',
    );
    footPaddings.add(
      ((cellTop + cellH) - bounds.bottom).clamp(0, cellH).toStringAsFixed(0),
    );
    if (bounds.width > maxW) maxW = bounds.width.toDouble();
    if (bounds.height > maxH) maxH = bounds.height.toDouble();
  }

  print('frameSize: Vector2(${maxW.toStringAsFixed(0)}, ${maxH.toStringAsFixed(0)}),');
  print('framePositions: <Vector2>[${origins.join(', ')}],');
  print('footPaddings: <double>[${footPaddings.join(', ')}],');
  print('');
}

Future<({int left, int top, int right, int bottom, int width, int height})?>
_opaqueBoundsInRect(ui.Image image, int left, int top, int width, int height) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return null;
  }

  final bytes = byteData.buffer.asUint8List();
  final stride = image.width * 4;

  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;

  final right = left + width;
  final bottom = top + height;

  for (var y = top; y < bottom && y < image.height; y++) {
    for (var x = left; x < right && x < image.width; x++) {
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

      final lx = x - left;
      final ly = y - top;
      if (lx < minX) minX = lx;
      if (ly < minY) minY = ly;
      if (lx > maxX) maxX = lx;
      if (ly > maxY) maxY = ly;
    }
  }

  if (maxX < 0) {
    return null;
  }

  return (
    left: left + minX,
    top: top + minY,
    right: left + maxX,
    bottom: top + maxY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

class _Block {
  const _Block(
    this.name,
    this.path,
    this.frames,
    this.columns,
    this.rows,
  );

  final String name;
  final String path;
  final int frames;
  final int columns;
  final int rows;
}

class _DecodedBlock {
  const _DecodedBlock({required this.block, required this.image});

  final _Block block;
  final ui.Image image;
}
