import 'asset_paths.dart';

/// Discrete steps of the manicure minigame that follows the salon arrival.
enum NailDigit { pinky, ring, middle, pointer, thumb }

enum NailShape { square, almond, stiletto }

/// Which limb the guest asked to have cared for this visit.
enum CareTarget { hand, foot }

extension NailDigitFlow on NailDigit {
  String get label => switch (this) {
        NailDigit.pinky => 'pinky',
        NailDigit.ring => 'ring finger',
        NailDigit.middle => 'middle finger',
        NailDigit.pointer => 'index finger',
        NailDigit.thumb => 'thumb',
      };

  NailDigit? get next => switch (this) {
        NailDigit.pinky => NailDigit.ring,
        NailDigit.ring => NailDigit.middle,
        NailDigit.middle => NailDigit.pointer,
        NailDigit.pointer => NailDigit.thumb,
        NailDigit.thumb => null,
      };

  NailCareStage get focusStage => switch (this) {
        NailDigit.pinky => NailCareStage.pinkyFingerFocus,
        NailDigit.ring => NailCareStage.ringFingerFocus,
        NailDigit.middle => NailCareStage.middleFingerFocus,
        NailDigit.pointer => NailCareStage.indexFingerFocus,
        NailDigit.thumb => NailCareStage.thumbFingerFocus,
      };
}

/// HUD snapshot for one finger on the bottom simulation strip.
class DigitSimSnapshot {
  const DigitSimSnapshot({
    this.cleanProgress = 0,
    this.cutFrame = 0,
    this.polishColor,
    this.shape,
  });

  /// Spray + wipe, 0 dirty → 1 fully clean.
  final double cleanProgress;

  /// Clip frames, 0 long → 3 fully short.
  final int cutFrame;

  /// Painted lacquer, if this digit has been polished.
  final int? polishColor;

  final NailShape? shape;

  bool get isClean => cleanProgress >= 1;
  bool get isShort => cutFrame >= 3;
  bool get isPolished => polishColor != null;

  DigitSimSnapshot copyWith({
    double? cleanProgress,
    int? cutFrame,
    int? polishColor,
    NailShape? shape,
  }) {
    return DigitSimSnapshot(
      cleanProgress: cleanProgress ?? this.cleanProgress,
      cutFrame: cutFrame ?? this.cutFrame,
      polishColor: polishColor ?? this.polishColor,
      shape: shape ?? this.shape,
    );
  }
}

enum NailCareStage {
  inactive,
  handCleaning,
  handCleaningCompleted,
  pinkyFingerFocus,
  ringFingerFocus,
  middleFingerFocus,
  indexFingerFocus,
  thumbFingerFocus,
  nailSpraying,
  nailBuffering,
  nailBufferingCompleted,
  nailCutting,
  nailCuttingCompleted,
  nailPolishing,
  nailPolishingCompleted,
  /// All five nails done — zoom out to the finished hand.
  handReveal,

  /// Foot flow: whole-foot soap wash, mirrors [handCleaning].
  footCleaning,
  footCleaningCompleted,
  /// Foot flow: whole-foot toenail spray + wipe, mirrors [nailSpraying]/[nailBuffering].
  footNailSpraying,
  footNailBuffering,
  footNailBufferingCompleted,
  /// Foot flow: whole-foot toenail cutting, mirrors [nailCutting]. Every toe
  /// shortens together — no per-digit loop, no shape choice.
  footNailCutting,
  footNailCuttingCompleted,
  /// Foot flow: lacquer every toenail at once, mirrors [nailPolishing]. There
  /// is no per-toe loop, so one sweep paints all five.
  footNailPolishing,
  footNailPolishingCompleted,
  /// Foot flow finished — mirrors [handReveal].
  footReveal,
}

enum NailCareToolId { handSoap, nailSpray, nailBuffer, nailClips, nailPolish }

enum NailCareInteraction { dragOntoTarget }

/// One manicure tool. New tools are added here rather than hardcoded in UI.
class NailCareTool {
  const NailCareTool({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.hint,
    required this.requiredStage,
    required this.interaction,
    this.unlocked = true,
    this.unlockLevel = 1,
  });

  final NailCareToolId id;
  final String name;
  final String iconPath;
  final String hint;
  final NailCareStage requiredStage;
  final NailCareInteraction interaction;
  final bool unlocked;
  final int unlockLevel;
}

/// Catalog of tools that can appear on the nail-care interaction card.
abstract final class NailCareCatalog {
  static const List<NailCareTool> all = <NailCareTool>[
    NailCareTool(
      id: NailCareToolId.handSoap,
      name: 'Hand Soap',
      iconPath: AssetPaths.handSoap,
      hint: 'Drag onto hand',
      requiredStage: NailCareStage.handCleaning,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.nailSpray,
      name: 'Nail Spray',
      iconPath: AssetPaths.nailSpray,
      hint: 'Spray onto nail',
      requiredStage: NailCareStage.nailSpraying,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.nailBuffer,
      name: 'Nail Wipe',
      iconPath: AssetPaths.nailBuffer,
      hint: 'Drag onto nail',
      requiredStage: NailCareStage.nailBuffering,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.nailClips,
      name: 'Nail Clips',
      iconPath: AssetPaths.nailClips,
      hint: 'Clip the nail',
      requiredStage: NailCareStage.nailCutting,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.nailPolish,
      name: 'Nail Brush',
      iconPath: AssetPaths.polishBrush,
      hint: 'Paint the nail',
      requiredStage: NailCareStage.nailPolishing,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.handSoap,
      name: 'Foot Soap',
      iconPath: AssetPaths.handSoap,
      hint: 'Drag onto foot',
      requiredStage: NailCareStage.footCleaning,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.nailSpray,
      name: 'Nail Spray',
      iconPath: AssetPaths.nailSpray,
      hint: 'Spray onto toes',
      requiredStage: NailCareStage.footNailSpraying,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.nailBuffer,
      name: 'Nail Wipe',
      iconPath: AssetPaths.nailBuffer,
      hint: 'Drag onto toes',
      requiredStage: NailCareStage.footNailBuffering,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.nailClips,
      name: 'Nail Clips',
      iconPath: AssetPaths.nailClips,
      hint: 'Clip the toes',
      requiredStage: NailCareStage.footNailCutting,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
    NailCareTool(
      id: NailCareToolId.nailPolish,
      name: 'Nail Brush',
      iconPath: AssetPaths.polishBrush,
      hint: 'Paint the toes',
      requiredStage: NailCareStage.footNailPolishing,
      interaction: NailCareInteraction.dragOntoTarget,
    ),
  ];

  static NailCareTool? activeToolFor(NailCareStage stage) {
    for (final tool in all) {
      if (tool.requiredStage == stage && tool.unlocked) {
        return tool;
      }
    }
    return null;
  }

  static NailCareTool toolById(NailCareToolId id) {
    return all.firstWhere((NailCareTool tool) => tool.id == id);
  }
}

/// One slot in a tool kit. Swap [iconPath] later when unique art lands.
class NailCareInventoryItem {
  const NailCareInventoryItem({
    required this.id,
    required this.toolId,
    required this.name,
    required this.iconPath,
    required this.unlocked,
    this.unlockPrice = 0,
    this.polishColor = 0,
  });

  final String id;
  final NailCareToolId toolId;
  final String name;
  final String iconPath;
  final bool unlocked;
  final int unlockPrice;
  final int polishColor;
}

/// Soap and buffer kits shown as 8-slot drawers. Slot 0 is owned.
abstract final class NailCareInventory {
  static const List<NailCareInventoryItem> soaps = <NailCareInventoryItem>[
    NailCareInventoryItem(
      id: 'soap-0',
      toolId: NailCareToolId.handSoap,
      name: 'Basic Soap',
      iconPath: AssetPaths.toolSoap1,
      unlocked: true,
    ),
    NailCareInventoryItem(
      id: 'soap-1',
      toolId: NailCareToolId.handSoap,
      name: 'Silver Soap',
      iconPath: AssetPaths.toolSoap2,
      unlocked: false,
      unlockPrice: 150,
    ),
    NailCareInventoryItem(
      id: 'soap-2',
      toolId: NailCareToolId.handSoap,
      name: 'Rose Gold Soap',
      iconPath: AssetPaths.toolSoap3,
      unlocked: false,
      unlockPrice: 250,
    ),
    NailCareInventoryItem(
      id: 'soap-3',
      toolId: NailCareToolId.handSoap,
      name: 'Bow Soap',
      iconPath: AssetPaths.toolSoap4,
      unlocked: false,
      unlockPrice: 400,
    ),
    NailCareInventoryItem(
      id: 'soap-4',
      toolId: NailCareToolId.handSoap,
      name: 'Jewel Soap',
      iconPath: AssetPaths.toolSoap5,
      unlocked: false,
      unlockPrice: 600,
    ),
    NailCareInventoryItem(
      id: 'soap-5',
      toolId: NailCareToolId.handSoap,
      name: 'Crown Soap',
      iconPath: AssetPaths.toolSoap6,
      unlocked: false,
      unlockPrice: 800,
    ),
  ];

  static const NailCareInventoryItem spray = NailCareInventoryItem(
    id: 'spray-0',
    toolId: NailCareToolId.nailSpray,
    name: 'Nail Spray',
    iconPath: AssetPaths.toolSpray1,
    unlocked: true,
  );

  /// Six shop skins: slot 0 owned, 1–5 locked until bought with coins.
  static const List<NailCareInventoryItem> sprays = <NailCareInventoryItem>[
    spray,
    NailCareInventoryItem(
      id: 'spray-1',
      toolId: NailCareToolId.nailSpray,
      name: 'Cleanse Spray',
      iconPath: AssetPaths.toolSpray2,
      unlocked: false,
      unlockPrice: 100,
    ),
    NailCareInventoryItem(
      id: 'spray-2',
      toolId: NailCareToolId.nailSpray,
      name: 'Pink Mist',
      iconPath: AssetPaths.toolSpray3,
      unlocked: false,
      unlockPrice: 200,
    ),
    NailCareInventoryItem(
      id: 'spray-3',
      toolId: NailCareToolId.nailSpray,
      name: 'Bow Spray',
      iconPath: AssetPaths.toolSpray4,
      unlocked: false,
      unlockPrice: 350,
    ),
    NailCareInventoryItem(
      id: 'spray-4',
      toolId: NailCareToolId.nailSpray,
      name: 'Crystal Spray',
      iconPath: AssetPaths.toolSpray5,
      unlocked: false,
      unlockPrice: 500,
    ),
    NailCareInventoryItem(
      id: 'spray-5',
      toolId: NailCareToolId.nailSpray,
      name: 'Royal Spray',
      iconPath: AssetPaths.toolSpray6,
      unlocked: false,
      unlockPrice: 750,
    ),
  ];

  static const List<NailCareInventoryItem> buffers = <NailCareInventoryItem>[
    NailCareInventoryItem(
      id: 'buffer-0',
      toolId: NailCareToolId.nailBuffer,
      name: 'Nail Wipe',
      iconPath: AssetPaths.nailBuffer,
      unlocked: true,
    ),
    NailCareInventoryItem(
      id: 'buffer-1',
      toolId: NailCareToolId.nailBuffer,
      name: 'Soft Wipe',
      iconPath: AssetPaths.toolWipe1,
      unlocked: false,
      unlockPrice: 150,
    ),
    NailCareInventoryItem(
      id: 'buffer-2',
      toolId: NailCareToolId.nailBuffer,
      name: 'Ribbon Wipe',
      iconPath: AssetPaths.toolWipe2,
      unlocked: false,
      unlockPrice: 250,
    ),
    NailCareInventoryItem(
      id: 'buffer-3',
      toolId: NailCareToolId.nailBuffer,
      name: 'Quilt Wipe',
      iconPath: AssetPaths.toolWipe3,
      unlocked: false,
      unlockPrice: 400,
    ),
    NailCareInventoryItem(
      id: 'buffer-4',
      toolId: NailCareToolId.nailBuffer,
      name: 'Crystal Wipe',
      iconPath: AssetPaths.toolWipe5,
      unlocked: false,
      unlockPrice: 600,
    ),
    NailCareInventoryItem(
      id: 'buffer-5',
      toolId: NailCareToolId.nailBuffer,
      name: 'Royal Wipe',
      iconPath: AssetPaths.toolWipe6,
      unlocked: false,
      unlockPrice: 800,
    ),
  ];

  static const List<NailCareInventoryItem> clips = <NailCareInventoryItem>[
    NailCareInventoryItem(
      id: 'clips-0',
      toolId: NailCareToolId.nailClips,
      name: 'Basic Clips',
      iconPath: AssetPaths.toolClips1,
      unlocked: true,
    ),
    NailCareInventoryItem(
      id: 'clips-1',
      toolId: NailCareToolId.nailClips,
      name: 'Silver Clips',
      iconPath: AssetPaths.toolClips2,
      unlocked: false,
      unlockPrice: 150,
    ),
    NailCareInventoryItem(
      id: 'clips-2',
      toolId: NailCareToolId.nailClips,
      name: 'Rose Gold Clips',
      iconPath: AssetPaths.toolClips3,
      unlocked: false,
      unlockPrice: 250,
    ),
    NailCareInventoryItem(
      id: 'clips-3',
      toolId: NailCareToolId.nailClips,
      name: 'Bow Clips',
      iconPath: AssetPaths.toolClips4,
      unlocked: false,
      unlockPrice: 400,
    ),
    NailCareInventoryItem(
      id: 'clips-4',
      toolId: NailCareToolId.nailClips,
      name: 'Jewel Clips',
      iconPath: AssetPaths.toolClips5,
      unlocked: false,
      unlockPrice: 600,
    ),
    NailCareInventoryItem(
      id: 'clips-5',
      toolId: NailCareToolId.nailClips,
      name: 'Crown Clips',
      iconPath: AssetPaths.toolClips6,
      unlocked: false,
      unlockPrice: 800,
    ),
  ];

  /// Spray and wipe are two separate drawers on the nail page — never one
  /// merged list, or the panel opens showing both tools in the same box.
  /// [sprays] and [buffers] are those drawers; see [splitSprayAndWipe].

  static const List<NailCareInventoryItem> polishes = <NailCareInventoryItem>[
    NailCareInventoryItem(
      id: 'polish-blush',
      toolId: NailCareToolId.nailPolish,
      name: 'Blush Pink',
      iconPath: AssetPaths.polishBlush,
      unlocked: true,
      polishColor: 0xFFFF6BA8,
    ),
    NailCareInventoryItem(
      id: 'polish-red',
      toolId: NailCareToolId.nailPolish,
      name: 'Cherry Red',
      iconPath: AssetPaths.polishRed,
      unlocked: true,
      polishColor: 0xFFD0123A,
    ),
    NailCareInventoryItem(
      id: 'polish-nude',
      toolId: NailCareToolId.nailPolish,
      name: 'French Nude',
      iconPath: AssetPaths.polishNude,
      unlocked: true,
      polishColor: 0xFFE6B8A2,
    ),
    NailCareInventoryItem(
      id: 'polish-pearl',
      toolId: NailCareToolId.nailPolish,
      name: 'Pearl',
      iconPath: AssetPaths.polishPearl,
      unlocked: true,
      polishColor: 0xFFF4E4EC,
    ),
    NailCareInventoryItem(
      id: 'polish-gold',
      toolId: NailCareToolId.nailPolish,
      name: 'Gold Glitter',
      iconPath: AssetPaths.polishGold,
      unlocked: true,
      polishColor: 0xFFD4A017,
    ),
  ];

  static const List<NailCareInventoryItem> brushes = <NailCareInventoryItem>[
    NailCareInventoryItem(
      id: 'brush-0',
      toolId: NailCareToolId.nailPolish,
      name: 'Nail Brush',
      iconPath: AssetPaths.polishBrush,
      unlocked: true,
    ),
    NailCareInventoryItem(
      id: 'brush-1',
      toolId: NailCareToolId.nailPolish,
      name: 'Brush 2',
      iconPath: AssetPaths.polishBrush,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'brush-2',
      toolId: NailCareToolId.nailPolish,
      name: 'Brush 3',
      iconPath: AssetPaths.polishBrush,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'brush-3',
      toolId: NailCareToolId.nailPolish,
      name: 'Brush 4',
      iconPath: AssetPaths.polishBrush,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'brush-4',
      toolId: NailCareToolId.nailPolish,
      name: 'Brush 5',
      iconPath: AssetPaths.polishBrush,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'brush-5',
      toolId: NailCareToolId.nailPolish,
      name: 'Brush 6',
      iconPath: AssetPaths.polishBrush,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'brush-6',
      toolId: NailCareToolId.nailPolish,
      name: 'Brush 7',
      iconPath: AssetPaths.polishBrush,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'brush-7',
      toolId: NailCareToolId.nailPolish,
      name: 'Brush 8',
      iconPath: AssetPaths.polishBrush,
      unlocked: false,
    ),
  ];

  /// Spray and wipe each get their own HUD box during nail-clean stages —
  /// on the foot as well as the hand.
  static bool splitSprayAndWipe(NailCareStage stage) =>
      stage == NailCareStage.nailSpraying ||
      stage == NailCareStage.nailBuffering ||
      stage == NailCareStage.footNailSpraying ||
      stage == NailCareStage.footNailBuffering;

  static List<NailCareInventoryItem> itemsFor(NailCareStage stage) {
    switch (stage) {
      case NailCareStage.handCleaning:
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.footCleaning:
      case NailCareStage.footCleaningCompleted:
        return soaps;
      // The drawer that opens by default is the one for the tool this stage
      // actually wants; the other sits beside it as its own box.
      case NailCareStage.nailSpraying:
      case NailCareStage.footNailSpraying:
        return sprays;
      case NailCareStage.nailBuffering:
      case NailCareStage.nailBufferingCompleted:
      case NailCareStage.footNailBuffering:
      case NailCareStage.footNailBufferingCompleted:
        return buffers;
      case NailCareStage.nailCutting:
      case NailCareStage.nailCuttingCompleted:
      case NailCareStage.footNailCutting:
      case NailCareStage.footNailCuttingCompleted:
        return clips;
      case NailCareStage.nailPolishing:
      case NailCareStage.nailPolishingCompleted:
      case NailCareStage.footNailPolishing:
      case NailCareStage.footNailPolishingCompleted:
        return polishes;
      case NailCareStage.inactive:
      case NailCareStage.pinkyFingerFocus:
      case NailCareStage.ringFingerFocus:
      case NailCareStage.middleFingerFocus:
      case NailCareStage.indexFingerFocus:
      case NailCareStage.thumbFingerFocus:
      case NailCareStage.handReveal:
      case NailCareStage.footReveal:
        return const <NailCareInventoryItem>[];
    }
  }

  static String kitLabelFor(NailCareStage stage) {
    switch (stage) {
      case NailCareStage.handCleaning:
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.footCleaning:
      case NailCareStage.footCleaningCompleted:
        return 'Soaps';
      case NailCareStage.nailSpraying:
      case NailCareStage.nailBuffering:
      case NailCareStage.nailBufferingCompleted:
      case NailCareStage.footNailSpraying:
      case NailCareStage.footNailBuffering:
      case NailCareStage.footNailBufferingCompleted:
        return 'Tools';
      case NailCareStage.nailCutting:
      case NailCareStage.nailCuttingCompleted:
      case NailCareStage.footNailCutting:
      case NailCareStage.footNailCuttingCompleted:
        return 'Clips';
      case NailCareStage.nailPolishing:
      case NailCareStage.nailPolishingCompleted:
      case NailCareStage.footNailPolishing:
      case NailCareStage.footNailPolishingCompleted:
        return 'Polishes';
      case NailCareStage.inactive:
      case NailCareStage.pinkyFingerFocus:
      case NailCareStage.ringFingerFocus:
      case NailCareStage.middleFingerFocus:
      case NailCareStage.indexFingerFocus:
      case NailCareStage.thumbFingerFocus:
      case NailCareStage.handReveal:
      case NailCareStage.footReveal:
        return '';
    }
  }
}
