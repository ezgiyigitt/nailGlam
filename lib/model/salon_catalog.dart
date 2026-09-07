enum ShopSlot { sofa, chair, table, plant, lamp }

/// One thing the player can buy and place in the salon.
class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.price,
    this.starter = false,
    this.previewAsset,
    this.surfaceAsset,
    this.pillowCenterY,
    this.pillowOffsetX = 0,
    this.chairHeight,
    this.chairBottomY,
    this.deskDropY = 0,
    this.apronColor = 0xFFC45420,
  });

  final String id;
  final String name;
  final ShopSlot slot;
  final int price;
  final bool starter;

  /// Optional image under `assets/images/`. Locked pieces stay silhouettes
  /// until their art is approved.
  final String? previewAsset;

  /// Nail-care close-up tabletop texture for this desk. Tables only.
  final String? surfaceAsset;

  /// World Y for the salon pink armrest on this desk. Null = default.
  final double? pillowCenterY;

  /// Horizontal nudge for the armrest relative to station centre.
  final double pillowOffsetX;

  /// Optional chair scale overrides (shop chairs with taller backs).
  final double? chairHeight;
  final double? chairBottomY;

  /// How far this desk's art must slide down for its desktop line to land where
  /// the seated guest is drawn.
  ///
  /// Every desk is painted into the same rectangle, so a desk whose slab sits
  /// higher inside its own image starts covering the customer higher up — she
  /// reads as sunk into the table. The starter desk defines zero, since
  /// [GameConfig.tableWoodY] was measured on its art.
  final double deskDropY;

  /// Apron fill behind desk edges when the camera pans past the art.
  final int apronColor;
}

/// The upgrade tree. Starter pieces are already owned; everything else is a
/// goal the player saves coins toward.
abstract final class SalonCatalog {
  static const ShopItem blushSofa = ShopItem(
    id: 'sofa_blush',
    name: 'Blush sofa',
    slot: ShopSlot.sofa,
    price: 800,
  );
  static const ShopItem velvetSofa = ShopItem(
    id: 'sofa_velvet',
    name: 'Velvet sofa',
    slot: ShopSlot.sofa,
    price: 1800,
  );

  static const ShopItem starterChair = ShopItem(
    id: 'chair_starter',
    name: 'Starter chair',
    slot: ShopSlot.chair,
    price: 0,
    starter: true,
    previewAsset: 'salon_chair.png',
  );
  static const ShopItem pinkChair = ShopItem(
    id: 'chair_pink',
    name: 'Pink luxury chair',
    slot: ShopSlot.chair,
    price: 500,
    previewAsset: 'shop_chair_pink.png',
    // Tall fan back — keep the crest above the desk line.
    chairHeight: 1380,
    chairBottomY: 2080,
  );
  static const ShopItem goldChair = ShopItem(
    id: 'chair_gold',
    name: 'Gold-trim chair',
    slot: ShopSlot.chair,
    price: 1500,
    previewAsset: 'shop_chair_gold.png',
    chairHeight: 1360,
    chairBottomY: 2070,
  );

  static const ShopItem starterTable = ShopItem(
    id: 'table_starter',
    name: 'Starter table',
    slot: ShopSlot.table,
    price: 0,
    starter: true,
    previewAsset: 'nail_table.png',
    surfaceAsset: 'table_surface.png',
    // Champagne frame + blush apron behind desk edges when the camera pans.
    apronColor: 0xFFE8C4B8,
  );
  static const ShopItem marbleTable = ShopItem(
    id: 'table_marble',
    name: 'Marble nail table',
    slot: ShopSlot.table,
    price: 1000,
    previewAsset: 'shop_table_marble.png',
    surfaceAsset: 'table_surface_marble.png',
    // Marble desktop sits higher in the art; keep the armrest on the slab.
    pillowCenterY: 1384,
    // …and drop the desk by the same amount, or that higher slab swallows the
    // guest's waist. 1438 (default armrest) − 1384 = 54.
    deskDropY: 54,
    apronColor: 0xFFF2B8C8,
  );
  static const ShopItem premiumTable = ShopItem(
    id: 'table_premium',
    name: 'Premium table',
    slot: ShopSlot.table,
    price: 3000,
    previewAsset: 'shop_table_premium.png',
    surfaceAsset: 'table_surface_premium.png',
    pillowCenterY: 1419,
    // 1438 − 1419 = 19.
    deskDropY: 19,
    apronColor: 0xFFE8A0B4,
  );

  static const ShopItem smallPlant = ShopItem(
    id: 'plant_small',
    name: 'Small plant',
    slot: ShopSlot.plant,
    price: 300,
  );
  static const ShopItem largePlant = ShopItem(
    id: 'plant_large',
    name: 'Decorative plant',
    slot: ShopSlot.plant,
    price: 800,
  );

  static const ShopItem lamp = ShopItem(
    id: 'lamp_chic',
    name: 'Chic lamp',
    slot: ShopSlot.lamp,
    price: 700,
  );
  static const ShopItem crystalLamp = ShopItem(
    id: 'lamp_crystal',
    name: 'Crystal lamp',
    slot: ShopSlot.lamp,
    price: 2000,
  );

  static const List<ShopItem> all = <ShopItem>[
    blushSofa,
    velvetSofa,
    starterChair,
    pinkChair,
    goldChair,
    starterTable,
    marbleTable,
    premiumTable,
    smallPlant,
    largePlant,
    lamp,
    crystalLamp,
  ];

  static const List<int> dailyLoginCoins = <int>[
    100,
    150,
    200,
    300,
    400,
    600,
    1000,
  ];

  /// Extra coins after the first finished customer of the day.
  static const int dailyPlayBonus = 150;

  static ShopItem byId(String id) =>
      all.firstWhere((ShopItem item) => item.id == id);
}
