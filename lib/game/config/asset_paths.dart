/// Central registry of every image the game loads.
///
/// Paths are relative to `assets/images/`, which is the prefix Flame's
/// [Images] cache uses by default.
abstract final class AssetPaths {
  static const String menuBackground = 'background.png';
  static const String menuLogo = 'nail_glam_logo.png';
  static const String menuButtons = 'play_how_to_play_spritesheet.png';

  static const String wall = 'salon_bg_wall.jpg';
  static const String floor = 'salon_bg_floor.jpg';
  static const String doorFrame = 'salon_door_frame.png';
  static const String doorLeaf = 'salon_door_leaf.png';
  static const String nailTable = 'salon_nail_table.png';
  static const String chair = 'salon_chair_customer.png';
  static const String plant = 'salon_fg_plant.png';

  static const String customerWalk = 'customer_01_walk.png';
  static const String customerSit = 'customer_01_sit.png';
  static const String customerSitIdle = 'customer_01_sit_idle.png';
  static const String customerHandsToTable = 'customer_01_hands_to_table.png';

  static const String workspaceTableSurface = 'workspace_table_surface.jpg';
  static const String workspaceHandCushion = 'workspace_hand_cushion.png';
  static const String hand01Reference = 'hand_01_reference.png';

  /// Everything that must be in the image cache before the salon is built.
  static const List<String> all = <String>[
    wall,
    floor,
    doorFrame,
    doorLeaf,
    nailTable,
    chair,
    plant,
    customerWalk,
    customerSit,
    customerSitIdle,
    customerHandsToTable,
    workspaceTableSurface,
    workspaceHandCushion,
    hand01Reference,
  ];
}
