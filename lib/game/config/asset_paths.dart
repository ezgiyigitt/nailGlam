/// Central registry of every image the game loads.
///
/// Paths are relative to `assets/images/`, which is the prefix Flame's
/// [Images] cache uses by default.
///
/// The room, the desk and the customer are placeholder-generated until art
/// with these exact names is dropped into `assets/images/`. Each one is drawn
/// as a whole image, so the delivered pixel size does not have to match
/// anything in code.
abstract final class AssetPaths {
  static const String menuBackground = 'background.png';
  static const String menuLogo = 'nail_glam_logo.png';
  static const String menuStart = 'btn_start.png';
  static const String menuHowToPlay = 'btn_how_to_play.png';

  /// Wide salon interior. Must be scrollable: no furniture, no characters.
  static const String salonRoom = 'salon_room.png';

  /// Manicure desk seen from the player's side, filling the bottom of frame.
  static const String nailTable = 'nail_table.png';

  /// Client chair, seen from the front. She sits with her back to it.
  static const String salonChair = 'salon_chair.png';
  static const String shopChairPink = 'shop_chair_pink.png';
  static const String shopChairGold = 'shop_chair_gold.png';
  static const String shopTableMarble = 'shop_table_marble.png';
  static const String shopTablePremium = 'shop_table_premium.png';

  /// Customer, waist-up, side profile walking right. 4×1 strip.
  static const String customerWalk = 'customer_walk.png';

  /// Customer pivoting from profile to facing the desk. 4×1 strip.
  static const String customerTurn = 'customer_turn.png';

  /// Customer sitting down at the desk. 4×1 one-shot strip on the same cell as
  /// walk/turn, so the head stays put while she settles once.
  static const String customerSit = 'customer_sit.png';

  static const String tableSurface = 'table_surface.png';

  /// Pink quilted armrest on the salon desk, player-facing.
  static const String manicurePillow = 'manicure_pillow.png';

  /// Same cushion from above, used under the finger close-up.
  static const String manicurePillowTop = 'manicure_pillow_top.png';

  /// Current customer, face only. 5×1 strip, sad → delighted.
  static const String customerEmotion = 'customer_emotion.png';

  static const String handSoap = 'hand_soap.png';
  static const String handWash = 'hand_wash.png';
  static const String fifthNailClean = 'fifth_nail_clean.png';
  static const String shortNail = 'short_nail.png';
  static const String nailSpray = 'spray.png';
  static const String nailBuffer = 'nail_buffer.png';
  static const String nailClips = 'clips.png';
  static const String polishBrush = 'polish_brush.png';
  static const String polishBlush = 'polish_blush.png';
  static const String polishRed = 'polish_red.png';
  static const String polishNude = 'polish_nude.png';
  static const String polishPearl = 'polish_pearl.png';
  static const String polishGold = 'polish_gold.png';
  static const String pinkNailMask = 'Pink_nail_mask.png';
  static const String fourthNail = 'fourth_nail.png';
  static const String fourthShortNail = 'fourth_short_nail.png';
  static const String ringNailMask = 'ring_nail_mask.png';

  /// Files that must exist on disk before the salon is built. The arrival art
  /// is deliberately absent: it falls back to generated placeholders.
  static const List<String> all = <String>[
    tableSurface,
    manicurePillow,
    manicurePillowTop,
    customerEmotion,
    handSoap,
    handWash,
    fifthNailClean,
    shortNail,
    nailSpray,
    nailBuffer,
    nailClips,
    polishBrush,
    polishBlush,
    polishRed,
    polishNude,
    polishPearl,
    polishGold,
    pinkNailMask,
    fourthNail,
    fourthShortNail,
    ringNailMask,
  ];
}
