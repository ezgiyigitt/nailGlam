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

  /// Slot 0 of the soap drawer: the starter soap every player owns.
  static const String toolSoap1 = 'soap.png';

  /// Sliced from the delivered `soaps_all.png` sheet (see
  /// tool/slice_soap_bottles.py) — replaces the older tool_soap_*.png art.
  static const String soapBottle1 = 'soap_bottle_1.png';
  static const String toolSoap2 = 'soap_bottle_2.png';
  static const String toolSoap3 = 'soap_bottle_3.png';
  static const String toolSoap4 = 'soap_bottle_4.png';
  static const String toolSoap5 = 'soap_bottle_5.png';
  static const String toolSoap6 = 'soap_bottle_6.png';
  static const String toolSpray1 = 'tool_spray_1.png';
  static const String toolSpray2 = 'tool_spray_2.png';
  static const String toolSpray3 = 'tool_spray_3.png';
  static const String toolSpray4 = 'tool_spray_4.png';
  static const String toolSpray5 = 'tool_spray_5.png';
  static const String toolSpray6 = 'tool_spray_6.png';
  // All six re-sliced from the delivered new_wipe.png sheet by
  // tool/slice_new_wipes.py, so the shelf is one art set in tier order. It
  // used to be two: 1–3 were cut from premiumWipe's unrelated four-box strip
  // and 4–6 were bad crops of another sheet, which is why the drawer looked
  // like it changed its mind halfway along. Re-run that script if the sheet
  // is ever redelivered — it asserts the tin count rather than assuming a
  // fixed cell width, because the tins are not evenly spaced.
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

  /// HUD copies of the dark reveal hand and its per-nail masks, cropped to
  /// [SpriteAtlas.finalHandDark]'s own window (344,0)-(1212,1018).
  ///
  /// The gameplay art lives on a 1536x1024 canvas with the hand windowed in
  /// the middle; the HUD card draws whole images with BoxFit.contain, so
  /// handing it the uncropped canvas would shrink the hand and float it off
  /// centre. Cropping once here keeps the card free of per-guest layout maths.
  static const String finalHandDarkHud = 'final_hand_dark_hud.png';
  static const String finalHandDarkHudNailPinky =
      'final_hand_dark_hud_nail_pinky.png';
  static const String finalHandDarkHudNailRing =
      'final_hand_dark_hud_nail_ring.png';
  static const String finalHandDarkHudNailMiddle =
      'final_hand_dark_hud_nail_middle.png';
  static const String finalHandDarkHudNailPointer =
      'final_hand_dark_hud_nail_pointer.png';
  static const String finalHandDarkHudNailThumb =
      'final_hand_dark_hud_nail_thumb.png';
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
  static const String nailMaskLightPinky = 'nail_mask_light_pinky.png';
  static const String pinkyStilettoNailLight = 'pinky_stiletto_nail_light.png';
  static const String middleNailStilettoLight = 'middle_nail_stiletto_light.png';
  static const String thumbNailStilettoLight = 'thumb_nail_stiletto_light.png';
  static const String pinkyStilettoPolishMask = 'pinky_stiletto_mask.png';
  static const String middleStilettoPolishMask = 'middle_nail_mask_light (2).png';
  static const String thumbStilettoPolishMask = 'thumb_nail_light_mask.png';
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

  /// Finished-hand still for a manicure where every cut nail was stiletto
  /// shaped. [finalHandStilettoMask] is the aggregate fallback mask; the 5
  /// per-digit masks below let each nail carry its own colour + gradient
  /// (see [finalHandStilettoNailPinky] etc.) the same way the square reveal
  /// already works — a shared whole-hand mask/plate stretched the gradient
  /// and shine streak across all 5 nails, washing out whichever finger sat
  /// nearest the plate's horizontal center.
  static const String finalHandStiletto = 'final_hand_stiletto.png';
  static const String finalHandStilettoMask = 'final_hand_stiletto_mask.png';
  static const String finalHandStilettoNailPinky =
      'final_hand_stiletto_nail_pinky.png';
  static const String finalHandStilettoNailRing =
      'final_hand_stiletto_nail_ring.png';
  static const String finalHandStilettoNailMiddle =
      'final_hand_stiletto_nail_middle.png';
  static const String finalHandStilettoNailPointer =
      'final_hand_stiletto_nail_pointer.png';
  static const String finalHandStilettoNailThumb =
      'final_hand_stiletto_nail_thumb.png';

  /// 1448×1086 dark-skin counterpart of [finalHandStiletto], with the same
  /// single unified 5-nail mask.
  static const String finalHandDarkStiletto = 'final_hand_dark_stiletto.png';
  static const String finalHandDarkStilettoMask =
      'final_hand_dark_stiletto_mask.png';

  /// Per-nail split of [finalHandDarkStilettoMask], same reasoning as the
  /// light stiletto split: one whole-hand mask meant a single plate drove the
  /// wet-depth gradient and shine streak for all five nails at once, so the
  /// polish never sat on any individual nail's own axis.
  static const String finalHandDarkStilettoNailPinky =
      'final_hand_dark_stiletto_nail_pinky.png';
  static const String finalHandDarkStilettoNailRing =
      'final_hand_dark_stiletto_nail_ring.png';
  static const String finalHandDarkStilettoNailMiddle =
      'final_hand_dark_stiletto_nail_middle.png';
  static const String finalHandDarkStilettoNailPointer =
      'final_hand_dark_stiletto_nail_pointer.png';
  static const String finalHandDarkStilettoNailThumb =
      'final_hand_dark_stiletto_nail_thumb.png';

  /// 1536×1024, 4×1 dirty→clean foot wash stages, locked pose (whole foot).
  static const String footCleanLight = 'foot_clean_light.png';

  /// 1536×1024, 4×1 dirty→clean toenail stages, locked pose (whole foot).
  static const String footNailCleanLight = 'foot_nail_clean_light.png';

  /// 1536×1024, 4×1 stiletto cutting strip for the dark-skin pinky/ring/
  /// middle/pointer (shared, mirrors the light-skin pinky sharing pattern).
  static const String pinkyStilettoNailDark = 'pinky_nail_stiletto_dark.png';
  static const String pinkyStilettoMaskDark = 'pinky_stiletto_mask_dark.png';

  /// 1536×1024, 4×1 stiletto cutting strip for the dark-skin thumb.
  static const String thumbStilettoNailDark = 'thumb_nail_dark_stiletto.png';
  static const String thumbStilettoMaskDark = 'thumb_stiletto_mask_dark.png';

  /// 2103×748, 4×1 dirty→clean thumb strip for the dark-skin clean/spray/
  /// wipe stage. Replaces the earlier stopgap that reused
  /// [thumbStilettoNailDark]'s first frame. No polish mask is needed here:
  /// this sheet only backs [NailCareStage.nailSpraying]/[nailBuffering] —
  /// the polish mask is only sampled off the short/cut sheet during
  /// [NailCareStage.nailPolishing] (see [thumbNailMaskDark]).
  static const String thumbNailDarkWipe = 'thumb_nail_dark_wipe.png';

  /// 2172x724, 6x1 whole-foot toenail cutting strip (all toes at once).
  static const String footNailCutStrip = 'toe_nail_cutting_light.png';

  static const String footCleanDark = 'toe_cleaning_dark.png';
  static const String footNailCleanDark = 'toe_nail_cleaning_dark.png';
  static const String footNailCutStripDark = 'toe_cutting_dark.png';

  /// Toenail silhouettes traced from the cutting strips, one set of five per
  /// cell, on the strip's own canvas. Generated by tool/build_toenail_mask.py.
  ///
  /// `footNailPolishMaskLight` is now sourced from the manually-authored
  /// `light_toe_mask.png` which was painted directly over the last frame of
  /// `toe_nail_cutting_light.png` (2172×724 canvas). This replaces the earlier
  /// auto-generated mask for pixel-perfect toenail alignment on the light skin.
  static const String footNailPolishMaskLight = 'light_toe_mask.png';
  static const String footNailPolishMaskDark = 'toe_nail_polish_mask_dark.png';

  /// Per-toe split of [footNailPolishMaskLight], same reasoning as the
  /// stiletto hand's per-digit masks: one shared mask/plate stretched a
  /// single gradient + shine streak across all 5 toes, washing out whichever
  /// toe sat nearest the shared plate's centre. Each file is the full
  /// 2172×724 canvas with only that toe's blob opaque, isolated by
  /// connected-component split of the original mask, lightly smoothed.
  static const String finalToeLightNailThumb = 'final_toe_light_nail_thumb.png';
  static const String finalToeLightNailPointer =
      'final_toe_light_nail_pointer.png';
  static const String finalToeLightNailMiddle =
      'final_toe_light_nail_middle.png';
  static const String finalToeLightNailRing = 'final_toe_light_nail_ring.png';
  static const String finalToeLightNailPinky =
      'final_toe_light_nail_pinky.png';

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
    toolWipe5,
    toolWipe6,
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
    nailMaskLightPinky,
    pinkyStilettoNailLight,
    middleNailStilettoLight,
    thumbNailStilettoLight,
    pinkyStilettoPolishMask,
    middleStilettoPolishMask,
    thumbStilettoPolishMask,
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
    finalHandStiletto,
    finalHandStilettoMask,
    finalHandStilettoNailPinky,
    finalHandStilettoNailRing,
    finalHandStilettoNailMiddle,
    finalHandStilettoNailPointer,
    finalHandStilettoNailThumb,
    finalHandDarkStilettoNailPinky,
    finalHandDarkStilettoNailRing,
    finalHandDarkStilettoNailMiddle,
    finalHandDarkStilettoNailPointer,
    finalHandDarkStilettoNailThumb,
    footCleanLight,
    footNailCleanLight,
    pinkyStilettoNailDark,
    pinkyStilettoMaskDark,
    thumbStilettoNailDark,
    thumbStilettoMaskDark,
    thumbNailDarkWipe,
    footNailCutStrip,
    footCleanDark,
    footNailCleanDark,
    footNailCutStripDark,
    finalHandDarkStiletto,
    finalHandDarkStilettoMask,
    footNailPolishMaskLight,
    footNailPolishMaskDark,
    finalToeLightNailThumb,
    finalToeLightNailPointer,
    finalToeLightNailMiddle,
    finalToeLightNailRing,
    finalToeLightNailPinky,
  ];
}
