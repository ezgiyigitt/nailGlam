import 'package:flame/components.dart';

/// Source rectangles for every sprite, measured directly from the alpha
/// channel of the delivered art rather than assumed from a nominal grid.
///
/// The character sheets were generated as loose rows of figures, so their
/// frames are not evenly spaced: the two rows sit at different heights and
/// each figure is horizontally offset by up to 22px. Slicing them with a
/// naive grid makes the customer bob and slide across the floor.
///
/// Each sheet also stores its own display scale and measured foot padding.
/// Rendering with [Anchor.bottomCenter] and compensating for that padding keeps
/// replacement sheets grounded even when their source resolutions differ.
abstract final class SpriteAtlas {
  static final CharacterSheet customerWalk = CharacterSheet(
    frameSize: Vector2(172, 380),
    displayScale: 2.34,
    footPaddings: const <double>[6, 6, 6, 6, 6, 6, 6, 6],
    framePositions: <Vector2>[
      Vector2(55, 71),
      Vector2(304, 72),
      Vector2(558, 72),
      Vector2(803, 70),
      Vector2(57, 470),
      Vector2(305, 474),
      Vector2(557, 474),
      Vector2(803, 470),
    ],
  );

  static final CharacterSheet customerSit = CharacterSheet(
    frameSize: Vector2(360, 512),
    displayScale: 1.74,
    footPaddings: const <double>[1, 1, 2, 1, 25, 29, 27, 28],
    framePositions: <Vector2>[
      Vector2(9, 0),
      Vector2(397, 0),
      Vector2(791, 0),
      Vector2(1176, 0),
      Vector2(0, 512),
      Vector2(401, 512),
      Vector2(799, 512),
      Vector2(1176, 512),
    ],
  );

  static final CharacterSheet customerSitIdle = CharacterSheet(
    frameSize: Vector2(360, 560),
    displayScale: 1.53,
    footPaddings: const <double>[8, 8, 8, 8],
    framePositions: <Vector2>[
      Vector2(51, 98),
      Vector2(529, 98),
      Vector2(1013, 98),
      Vector2(1490, 101),
    ],
  );

  /// Horizontal 6-frame raise: lap → hands resting on the table.
  /// Sheet is 2173×724. Windows are content-measured and bottom-aligned;
  /// [displayScale] matches sit-idle content height so the seat does not jump.
  static final CharacterSheet customerHandsToTable = CharacterSheet(
    frameSize: Vector2(285, 506),
    displayScale: 1.62,
    footPaddings: const <double>[0, 0, 0, 0, 0, 0],
    framePositions: <Vector2>[
      Vector2(43, 107),
      Vector2(410, 107),
      Vector2(785, 107),
      Vector2(1138, 108),
      Vector2(1493, 110),
      Vector2(1833, 110),
    ],
  );

  /// Opaque content bounds of the scenery art. All of the prop PNGs ship with
  /// a wide transparent margin; cropping to these rectangles means a component's
  /// declared size is the size of the visible object.
  static final SpriteRegion wall = SpriteRegion(
    Vector2(0, 143),
    Vector2(1024, 360),
  );
  static final SpriteRegion floor = SpriteRegion(
    Vector2.zero(),
    Vector2(1024, 657),
  );
  static final SpriteRegion doorFrame = SpriteRegion(
    Vector2(123, 78),
    Vector2(447, 867),
  );
  static final SpriteRegion doorLeaf = SpriteRegion(
    Vector2(77, 74),
    Vector2(351, 889),
  );
  static final SpriteRegion chair = SpriteRegion(
    Vector2(148, 158),
    Vector2(506, 786),
  );
  static final SpriteRegion nailTable = SpriteRegion(
    Vector2(207, 102),
    Vector2(623, 479),
  );
  static final SpriteRegion plant = SpriteRegion(
    Vector2(55, 66),
    Vector2(449, 918),
  );

  /// Opaque content of the nail-care close-up props. Measured from alpha so
  /// the cushion and hand sit on their visible silhouette, not the full PNG.
  static final SpriteRegion workspaceHandCushion = SpriteRegion(
    Vector2(16, 31),
    Vector2(993, 389),
  );
  static final SpriteRegion hand01Reference = SpriteRegion(
    Vector2(143, 122),
    Vector2(686, 843),
  );
}

/// A rectangular window into a source image.
class SpriteRegion {
  const SpriteRegion(this.position, this.size);

  final Vector2 position;
  final Vector2 size;

  double get aspectRatio => size.x / size.y;
}

/// Uniform frame windows for one character animation.
class CharacterSheet {
  CharacterSheet({
    required this.frameSize,
    required this.framePositions,
    required this.displayScale,
    required this.footPaddings,
  }) : assert(framePositions.length == footPaddings.length);

  final Vector2 frameSize;
  final List<Vector2> framePositions;
  final double displayScale;
  final List<double> footPaddings;

  int get frameCount => framePositions.length;
}
