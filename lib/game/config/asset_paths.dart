/// Central registry of every image the game loads.
///
/// Paths are relative to `assets/images/`, which is the prefix Flame's
/// [Images] cache uses by default.
abstract final class AssetPaths {
  static const String menuBackground = 'background.png';
  static const String menuLogo = 'nail_glam_logo.png';

  static const String wall = 'salon_bg_wall.jpg';
  static const String floor = 'salon_bg_floor.jpg';
  static const String doorFrame = 'door_frame.png';
  static const String doorLeaf = 'door.png';
  static const String nailTable = 'table.png';
  static const String salonChair = 'salon_chair.png';
  static const String plant = 'salon_fg_plant.png';

  static const String customerWalk = 'customer-walk-v1.png';
  static const String customerStop = 'customer1_stop.png';
  static const String customerTurn = 'customer1_sit.png';
  static const String customerSit = 'customer1_wait.png';
  static const String customerLook = 'character_look.png';
  static const String customerEmotion = 'customer_emotion.png';

  static const String tableSurface = 'table_surface.png';

  static const String handSoap = 'hand_soap.png';
  static const String handWash = 'hand_wash.png';
  static const String fifthNailClean = 'fifth_nail_clean.png';
  static const String shortNail = 'short_nail.png';
  static const String nailSpray = 'spray.png';
  static const String nailBuffer = 'nail_buffer.png';
  static const String nailClips = 'clips.png';

  /// Everything that must be in the image cache before the salon is built.
  static const List<String> all = <String>[
    wall,
    floor,
    doorFrame,
    doorLeaf,
    nailTable,
    salonChair,
    plant,
    customerWalk,
    customerStop,
    customerTurn,
    customerSit,
    customerLook,
    customerEmotion,
    tableSurface,
    handSoap,
    handWash,
    fifthNailClean,
    shortNail,
    nailSpray,
    nailBuffer,
    nailClips,
  ];
}
