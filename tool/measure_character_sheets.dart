// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;

/// Measures opaque pixel bounds for each frame window in a character sheet.
///
/// Run from project root:
///   dart run tool/measure_character_sheets.dart
Future<void> main() async {
  final specs = <_SheetSpec>[
    _SheetSpec(
      name: 'walk',
      path: 'assets/images/customer-walk-v1.png',
      frames: 4,
      columns: 4,
      rows: 1,
    ),
    _SheetSpec(
      name: 'sit',
      path: 'assets/images/customer1_sit.png',
      frames: 4,
      columns: 4,
      rows: 1,
    ),
    _SheetSpec(
      name: 'wait',
      path: 'assets/images/customer1_wait.png',
      frames: 4,
      columns: 4,
      rows: 1,
    ),
    _SheetSpec(
      name: 'emotion',
      path: 'assets/images/customer_emotion.png',
      frames: 5,
      columns: 5,
      rows: 1,
    ),
  ];

  for (final spec in specs) {
    await _analyzeSheet(spec);
  }
}

Future<void> _analyzeSheet(_SheetSpec spec) async {
  final file = File(spec.path);
  if (!file.existsSync()) {
    print('MISSING ${spec.path}');
    return;
  }

  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  print('\n=== ${spec.name} (${image.width}x${image.height}) ===');

  final cellW = image.width / spec.columns;
  final cellH = image.height / spec.rows;

  for (var i = 0; i < spec.frames; i++) {
    final col = i % spec.columns;
    final row = i ~/ spec.columns;
    print('frame $i cell origin=(${col * cellW}, ${row * cellH})');
  }
}

class _SheetSpec {
  const _SheetSpec({
    required this.name,
    required this.path,
    required this.frames,
    required this.columns,
    required this.rows,
  });

  final String name;
  final String path;
  final int frames;
  final int columns;
  final int rows;
}
