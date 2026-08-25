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
  });

  final String id;
  final String name;
  final ShopSlot slot;
  final int price;
  final bool starter;

  /// Optional image under `assets/images/`. Locked pieces stay silhouettes
  /// until their art is approved.
  final String? previewAsset;
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
  );
  static const ShopItem goldChair = ShopItem(
    id: 'chair_gold',
    name: 'Gold-trim chair',
    slot: ShopSlot.chair,
    price: 1500,
    previewAsset: 'shop_chair_gold.png',
  );

  static const ShopItem starterTable = ShopItem(
    id: 'table_starter',
    name: 'Starter table',
    slot: ShopSlot.table,
    price: 0,
    starter: true,
    previewAsset: 'nail_table.png',
  );
  static const ShopItem marbleTable = ShopItem(
    id: 'table_marble',
    name: 'Marble nail table',
    slot: ShopSlot.table,
    price: 1000,
    previewAsset: 'shop_table_marble.png',
  );
  static const ShopItem premiumTable = ShopItem(
    id: 'table_premium',
    name: 'Premium table',
    slot: ShopSlot.table,
    price: 3000,
    previewAsset: 'shop_table_premium.png',
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
