import 'asset_paths.dart';

/// Discrete steps of the manicure minigame that follows the salon arrival.
enum NailCareStage {
  inactive,
  handCleaning,
  handCleaningCompleted,
  pinkyFingerFocus,
  nailSpraying,
  nailBuffering,
  nailBufferingCompleted,
  nailCutting,
  nailCuttingCompleted,
}

enum NailCareToolId { handSoap, nailSpray, nailBuffer, nailClips }

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
      name: 'Nail Buffer',
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
  });

  final String id;
  final NailCareToolId toolId;
  final String name;
  final String iconPath;
  final bool unlocked;
}

/// Soap and buffer kits shown as 8-slot drawers. Slot 0 is owned.
abstract final class NailCareInventory {
  static const List<NailCareInventoryItem> soaps = <NailCareInventoryItem>[
    NailCareInventoryItem(
      id: 'soap-0',
      toolId: NailCareToolId.handSoap,
      name: 'Hand Soap',
      iconPath: AssetPaths.handSoap,
      unlocked: true,
    ),
    NailCareInventoryItem(
      id: 'soap-1',
      toolId: NailCareToolId.handSoap,
      name: 'Soap 2',
      iconPath: AssetPaths.handSoap,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'soap-2',
      toolId: NailCareToolId.handSoap,
      name: 'Soap 3',
      iconPath: AssetPaths.handSoap,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'soap-3',
      toolId: NailCareToolId.handSoap,
      name: 'Soap 4',
      iconPath: AssetPaths.handSoap,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'soap-4',
      toolId: NailCareToolId.handSoap,
      name: 'Soap 5',
      iconPath: AssetPaths.handSoap,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'soap-5',
      toolId: NailCareToolId.handSoap,
      name: 'Soap 6',
      iconPath: AssetPaths.handSoap,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'soap-6',
      toolId: NailCareToolId.handSoap,
      name: 'Soap 7',
      iconPath: AssetPaths.handSoap,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'soap-7',
      toolId: NailCareToolId.handSoap,
      name: 'Soap 8',
      iconPath: AssetPaths.handSoap,
      unlocked: false,
    ),
  ];

  static const NailCareInventoryItem spray = NailCareInventoryItem(
    id: 'spray-0',
    toolId: NailCareToolId.nailSpray,
    name: 'Nail Spray',
    iconPath: AssetPaths.nailSpray,
    unlocked: true,
  );

  static const List<NailCareInventoryItem> buffers = <NailCareInventoryItem>[
    NailCareInventoryItem(
      id: 'buffer-0',
      toolId: NailCareToolId.nailBuffer,
      name: 'Nail Buffer',
      iconPath: AssetPaths.nailBuffer,
      unlocked: true,
    ),
    NailCareInventoryItem(
      id: 'buffer-1',
      toolId: NailCareToolId.nailBuffer,
      name: 'Buffer 2',
      iconPath: AssetPaths.nailBuffer,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'buffer-2',
      toolId: NailCareToolId.nailBuffer,
      name: 'Buffer 3',
      iconPath: AssetPaths.nailBuffer,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'buffer-3',
      toolId: NailCareToolId.nailBuffer,
      name: 'Buffer 4',
      iconPath: AssetPaths.nailBuffer,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'buffer-4',
      toolId: NailCareToolId.nailBuffer,
      name: 'Buffer 5',
      iconPath: AssetPaths.nailBuffer,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'buffer-5',
      toolId: NailCareToolId.nailBuffer,
      name: 'Buffer 6',
      iconPath: AssetPaths.nailBuffer,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'buffer-6',
      toolId: NailCareToolId.nailBuffer,
      name: 'Buffer 7',
      iconPath: AssetPaths.nailBuffer,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'buffer-7',
      toolId: NailCareToolId.nailBuffer,
      name: 'Buffer 8',
      iconPath: AssetPaths.nailBuffer,
      unlocked: false,
    ),
  ];

  static const List<NailCareInventoryItem> clips = <NailCareInventoryItem>[
    NailCareInventoryItem(
      id: 'clips-0',
      toolId: NailCareToolId.nailClips,
      name: 'Nail Clips',
      iconPath: AssetPaths.nailClips,
      unlocked: true,
    ),
    NailCareInventoryItem(
      id: 'clips-1',
      toolId: NailCareToolId.nailClips,
      name: 'Clips 2',
      iconPath: AssetPaths.nailClips,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'clips-2',
      toolId: NailCareToolId.nailClips,
      name: 'Clips 3',
      iconPath: AssetPaths.nailClips,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'clips-3',
      toolId: NailCareToolId.nailClips,
      name: 'Clips 4',
      iconPath: AssetPaths.nailClips,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'clips-4',
      toolId: NailCareToolId.nailClips,
      name: 'Clips 5',
      iconPath: AssetPaths.nailClips,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'clips-5',
      toolId: NailCareToolId.nailClips,
      name: 'Clips 6',
      iconPath: AssetPaths.nailClips,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'clips-6',
      toolId: NailCareToolId.nailClips,
      name: 'Clips 7',
      iconPath: AssetPaths.nailClips,
      unlocked: false,
    ),
    NailCareInventoryItem(
      id: 'clips-7',
      toolId: NailCareToolId.nailClips,
      name: 'Clips 8',
      iconPath: AssetPaths.nailClips,
      unlocked: false,
    ),
  ];

  /// Spray sits on top of the owned buffer in the nail-page drawer.
  static const List<NailCareInventoryItem> nailFinish = <NailCareInventoryItem>[
    spray,
    ...buffers,
  ];

  static List<NailCareInventoryItem> itemsFor(NailCareStage stage) {
    switch (stage) {
      case NailCareStage.handCleaning:
      case NailCareStage.handCleaningCompleted:
        return soaps;
      case NailCareStage.nailSpraying:
      case NailCareStage.nailBuffering:
      case NailCareStage.nailBufferingCompleted:
        return nailFinish;
      case NailCareStage.nailCutting:
      case NailCareStage.nailCuttingCompleted:
        return clips;
      case NailCareStage.inactive:
      case NailCareStage.pinkyFingerFocus:
        return const <NailCareInventoryItem>[];
    }
  }

  static String kitLabelFor(NailCareStage stage) {
    switch (stage) {
      case NailCareStage.handCleaning:
      case NailCareStage.handCleaningCompleted:
        return 'Soaps';
      case NailCareStage.nailSpraying:
      case NailCareStage.nailBuffering:
      case NailCareStage.nailBufferingCompleted:
        return 'Tools';
      case NailCareStage.nailCutting:
      case NailCareStage.nailCuttingCompleted:
        return 'Clips';
      case NailCareStage.inactive:
      case NailCareStage.pinkyFingerFocus:
        return '';
    }
  }
}
