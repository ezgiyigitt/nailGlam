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
  static const String menuLogo = 'nail_glam_logo_entry.png';
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

  /// Customer 1 (Lila), waist-up, side profile walking right. 4×1 strip.
  static const String customerWalk = 'customer_walk.png';

  /// Customer 1 pivoting from profile to facing the desk. 4×1 strip.
  static const String customerTurn = 'customer_turn.png';

  /// Customer 1 sitting down at the desk. 4×1 one-shot strip.
  static const String customerSit = 'customer_sit.png';

  /// Customer 1 face strip, 5×1 sad → delighted.
  static const String customerEmotion = 'customer_emotion.png';

  /// Customer 2 (Ezgi) arrival strips — same cell size as Lila.
  static const String customer2Walk = 'customer2_walk.png';
  static const String customer2Turn = 'customer2_turn.png';
  static const String customer2Sit = 'customer2_sit.png';
  static const String customer2Emotion = 'customer2_emotion.png';

  /// Customer 3 (Zeynep) arrival strips — same cell size as Lila.
  static const String customer3Walk = 'customer3_walk.png';
  static const String customer3Turn = 'customer3_turn.png';
  static const String customer3Sit = 'customer3_sit.png';
  static const String customer3Emotion = 'customer3_emotion.png';

  static const String tableSurface = 'table_surface.png';
  static const String tableSurfaceMarble = 'table_surface_marble.png';
  static const String tableSurfacePremium = 'table_surface_premium.png';

  /// Pink quilted armrest on the salon desk, player-facing.
  static const String manicurePillow = 'manicure_pillow.png';

  /// Same cushion from above, used under the finger close-up.
  static const String manicurePillowTop = 'manicure_pillow_top.png';

  static const String handSoap = 'hand_soap.png';
  static const String premiumSoap = 'premium_soap.png';
  static const String premiumSpray = 'premium_spray.png';
  static const String premiumWipe = 'premium_wipe.png';

  static const String toolSoap1 = 'tool_soap_1.png';
  static const String toolSoap2 = 'tool_soap_2.png';
  static const String toolSoap3 = 'tool_soap_3.png';
  static const String toolSoap4 = 'tool_soap_4.png';
  static const String toolSoap5 = 'tool_soap_5.png';
  static const String toolSoap6 = 'tool_soap_6.png';
  static const String toolSpray1 = 'tool_spray_1.png';
  static const String toolSpray2 = 'tool_spray_2.png';
  static const String toolSpray3 = 'tool_spray_3.png';
  static const String toolSpray4 = 'tool_spray_4.png';
  static const String toolSpray5 = 'tool_spray_5.png';
  static const String toolSpray6 = 'tool_spray_6.png';
  static const String toolWipe1 = 'tool_wipe_1.png';
  static const String toolWipe2 = 'tool_wipe_2.png';
  static const String toolWipe3 = 'tool_wipe_3.png';
  static const String toolWipe4 = 'tool_wipe_4.png';
  static const String toolWipe5 = 'tool_wipe_5.png';
  static const String toolWipe6 = 'tool_wipe_6.png';
  static const String toolClips1 = 'tool_clips_1.png';
  static const String toolClips2 = 'tool_clips_2.png';
  static const String toolClips3 = 'tool_clips_3.png';
  static const String toolClips4 = 'tool_clips_4.png';
  static const String toolClips5 = 'tool_clips_5.png';
  static const String toolClips6 = 'tool_clips_6.png';
  static const String lock = 'lock.png';

  static const String handWash = 'hand_wash.png';
  static const String handWashDark = 'hand_wash_dark.png';

  /// Clean finished hand shown after all five nails are painted. One still.
  static const String finalHand = 'final_hand_01.png';
  static const String finalHandDark = 'final_hand_dark.png';
  static const String finalHandDarkNailMask = 'final_hand_dark_nail_mask.png';
  static const String finalHandDarkNailPinky = 'final_hand_dark_nail_pinky.png';
  static const String finalHandDarkNailRing = 'final_hand_dark_nail_ring.png';
  static const String finalHandDarkNailMiddle = 'final_hand_dark_nail_middle.png';
  static const String finalHandDarkNailPointer = 'final_hand_dark_nail_pointer.png';
  static const String finalHandDarkNailThumb = 'final_hand_dark_nail_thumb.png';
  static const String pinkyCleanDark = 'pinky_clean_dark.png';
  static const String pinkyShortDark = 'pinky_short_dark.png';
  static const String pinkyNailMaskDark = 'pinky_nail_mask_dark.png';
  static const String ringCleanDark = 'ring_clean_dark.png';
  static const String ringShortDark = 'ring_short_dark.png';
  static const String ringNailMaskDark = 'ring_nail_mask_dark.png';
  static const String middleCleanDark = 'middle_clean_dark.png';
  static const String middleShortDark = 'middle_short_dark.png';
  static const String middleNailMaskDark = 'middle_nail_mask_dark.png';
  static const String indexCleanDark = 'index_clean_dark.png';
  static const String indexShortDark = 'index_short_dark.png';
  static const String indexNailMaskDark = 'index_nail_mask_dark.png';
  static const String thumbCleanDark = 'thumb_clean_dark.png';
  static const String thumbShortDark = 'thumb_short_dark.png';
  static const String thumbNailMaskDark = 'thumb_nail_mask_dark.png';
  static const String fifthNailClean = 'fifth_nail_clean.png';
  static const String fifthNailSpray = 'fifth_nail_spray.png';
  static const String fifthNailWipe = 'fifth_nail_wipe.png';
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
  static const String fourthNailSpray = 'fourth_nail_spray.png';
  static const String fourthNailWipe = 'fourth_nail_wipe.png';
  static const String fourthShortNail = 'fourth_short_nail.png';
  static const String thirdNailClean = 'third_nail_clean.png';
  static const String thirdNailShort = 'third_nail_short.png';
  static const String secondNailClean = 'second_nail_clean.png';
  static const String secondNailShort = 'second_nail_short.png';
  static const String firstNailClean = 'first_nail_clean.png';
  static const String firstNailShort = 'first_nail_short.png';
  static const String ringNailMask = 'ring_nail_mask.png';
  static const String thirdNailMask = 'third_nail_mask.png';
  static const String secondNailMask = 'second_nail_mask.png';
  static const String firstNailMask = 'first_nail_mask.png';

  static const String pinkyCleanLight = 'pinky_clean_light.png';
  static const String pinkyShortLight = 'pinky_short_light.png';
  static const String pinkyNailMaskLight = 'pinky_nail_mask_light.png';
  static const String pinkyStilettoNail = 'pinky_stiletto_nail.png';
  static const String nailMaskLightPinky = 'nail_mask_light_pinky.png';
  static const String middleCleanLight = 'middle_clean_light.png';
  static const String middleShortLight = 'middle_short_light.png';
  static const String middleNailMaskLight = 'middle_nail_mask_light.png';
  static const String thumbCleanLight = 'thumb_clean_light.png';
  static const String thumbShortLight = 'thumb_short_light.png';
  static const String thumbNailMaskLight = 'thumb_nail_mask_light.png';
  static const String finalHandLight = 'final_hand_light.png';
  static const String finalHandLightNailMask = 'final_hand_light_nail_mask.png';
  static const String finalHandLightNailPinky = 'final_hand_light_nail_pinky.png';
  static const String finalHandLightNailRing = 'final_hand_light_nail_ring.png';
  static const String finalHandLightNailMiddle = 'final_hand_light_nail_middle.png';
  static const String finalHandLightNailPointer = 'final_hand_light_nail_pointer.png';
  static const String finalHandLightNailThumb = 'final_hand_light_nail_thumb.png';

  /// Files that must exist on disk before the salon is built. The arrival art
  /// is deliberately absent: it falls back to generated placeholders.
  static const List<String> all = <String>[
    tableSurface,
    tableSurfaceMarble,
    tableSurfacePremium,
    manicurePillow,
    manicurePillowTop,
    customerEmotion,
    customer2Walk,
    customer2Turn,
    customer2Sit,
    customer2Emotion,
    customer3Walk,
    customer3Turn,
    customer3Sit,
    customer3Emotion,
    handSoap,
    premiumSoap,
    premiumSpray,
    premiumWipe,
    toolSoap1,
    toolSoap2,
    toolSoap3,
    toolSoap4,
    toolSoap5,
    toolSoap6,
    toolSpray1,
    toolSpray2,
    toolSpray3,
    toolSpray4,
    toolSpray5,
    toolSpray6,
    toolWipe1,
    toolWipe2,
    toolWipe3,
    toolWipe4,
    toolClips1,
    toolClips2,
    toolClips3,
    toolClips4,
    toolClips5,
    toolClips6,
    lock,
    handWash,
    handWashDark,
    finalHand,
    finalHandDark,
    finalHandDarkNailMask,
    finalHandDarkNailPinky,
    finalHandDarkNailRing,
    finalHandDarkNailMiddle,
    finalHandDarkNailPointer,
    finalHandDarkNailThumb,
    pinkyCleanDark,
    pinkyShortDark,
    pinkyNailMaskDark,
    ringCleanDark,
    ringShortDark,
    ringNailMaskDark,
    middleCleanDark,
    middleShortDark,
    middleNailMaskDark,
    indexCleanDark,
    indexShortDark,
    indexNailMaskDark,
    thumbCleanDark,
    thumbShortDark,
    thumbNailMaskDark,
    fifthNailClean,
    fifthNailSpray,
    fifthNailWipe,
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
    fourthNailSpray,
    fourthNailWipe,
    fourthShortNail,
    thirdNailClean,
    thirdNailShort,
    secondNailClean,
    secondNailShort,
    firstNailClean,
    firstNailShort,
    ringNailMask,
    thirdNailMask,
    secondNailMask,
    firstNailMask,
    pinkyCleanLight,
    pinkyShortLight,
    pinkyNailMaskLight,
    pinkyStilettoNail,
    nailMaskLightPinky,
    middleCleanLight,
    middleShortLight,
    middleNailMaskLight,
    thumbCleanLight,
    thumbShortLight,
    thumbNailMaskLight,
    finalHandLight,
    finalHandLightNailMask,
    finalHandLightNailPinky,
    finalHandLightNailRing,
    finalHandLightNailMiddle,
    finalHandLightNailPointer,
    finalHandLightNailThumb,
  ];
}
