import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/customer_roster.dart';
import 'package:nail_glam/model/guest_care_kit.dart';
import 'package:nail_glam/model/game_config.dart';
import 'package:nail_glam/model/salon_catalog.dart';
import 'package:nail_glam/model/placeholder_art.dart';
import 'package:nail_glam/model/player_progress.dart';
import 'customer_component.dart';
import 'nail_workspace.dart';

/// Builds and owns the salon: one wide room, the manicure desk that fills the
/// bottom of the frame, the customer behind it, and the nail-care page.
class SalonScene extends Component with HasGameReference<FlameGame> {
  late final CustomerComponent customer;
  late final NailWorkspace workspace;
  late final PositionComponent room;
  late final SpriteComponent chair;
  late final SpriteComponent table;
  late final SpriteComponent pillow;
  late final RectangleComponent tableApron;

  bool _sceneryHidden = false;

  final Map<String, ({SpriteAnimation walk, SpriteAnimation turn, SpriteAnimation sit})>
      _guestKits =
      <String, ({SpriteAnimation walk, SpriteAnimation turn, SpriteAnimation sit})>{};

  @override
  Future<void> onLoad() async {
    final roomImage = await _image(AssetPaths.salonRoom, PlaceholderArt.room);
    final tableImage = await _image(AssetPaths.nailTable, PlaceholderArt.table);
    final chairImage = await _image(AssetPaths.salonChair, PlaceholderArt.chair);
    final pillowImage = await _image(
      AssetPaths.manicurePillow,
      PlaceholderArt.manicurePillow,
    );

    room = _buildRoom(roomImage);
    table = _buildTable(tableImage);
    chair = _buildChair(chairImage);
    pillow = _buildPillow(pillowImage);
    tableApron = _buildTableApron();

    for (final guest in CustomerRoster.all) {
      _guestKits[guest.id] = await _loadGuestKit(guest);
    }
    final starter = _guestKits[CustomerRoster.customer1.id]!;
    customer = CustomerComponent(
      walk: starter.walk,
      turn: starter.turn,
      sit: starter.sit,
    );

    await addAll(<Component>[room, chair, customer, tableApron, table, pillow]);

    workspace = NailWorkspace();
    await add(workspace);
  }

  /// Swap arrival sprites and matching hand art before she walks in.
  void applyGuest(CustomerProfile guest) {
    final kit = _guestKits[guest.id] ?? _guestKits[CustomerRoster.customer1.id];
    if (kit == null) {
      return;
    }
    customer.useKit(
      walk: kit.walk,
      turn: kit.turn,
      sit: kit.sit,
      sitDropDuringTurn: guest.sitDropDuringTurn ?? 1.0,
      walkFrameAlign: guest.walkFrameAlign,
      turnFrameAlign: guest.turnFrameAlign,
      sitFrameAlign: guest.sitFrameAlign,
    );
    workspace.applyCareKit(GuestCareCatalog.forId(guest.id));
  }

  Future<({SpriteAnimation walk, SpriteAnimation turn, SpriteAnimation sit})>
      _loadGuestKit(CustomerProfile guest) async {
    final walkImage = await _image(guest.walkAsset, PlaceholderArt.customerWalk);
    final turnImage = await _image(guest.turnAsset, PlaceholderArt.customerTurn);
    final sitImage = await _image(guest.sitAsset, PlaceholderArt.customerSit);
    return (
      walk: _strip(
        walkImage,
        frames: PlaceholderArt.customerWalkFrames,
        stepTime: guest.walkFrameTime ?? GameConfig.customerWalkFrameTime,
      ),
      turn: _strip(
        turnImage,
        frames: PlaceholderArt.customerTurnFrames,
        stepTime: guest.turnFrameTime ?? GameConfig.customerTurnFrameTime,
        loop: false,
      ),
      sit: _strip(
        sitImage,
        frames: PlaceholderArt.customerSitFrames,
        stepTime: guest.sitFrameTime ?? GameConfig.customerSitFrameTime,
        stepTimes: guest.sitStepTimes,
        loop: false,
      ),
    );
  }

  /// Swaps the station chair and desk to whatever the player has equipped.
  Future<void> applyEquippedFurniture(PlayerProgress progress) async {
    final chairItem = SalonCatalog.byId(progress.equippedChairId);
    final tableItem = SalonCatalog.byId(progress.equippedTableId);
    final chairPath = chairItem.previewAsset ?? AssetPaths.salonChair;
    final tablePath = tableItem.previewAsset ?? AssetPaths.nailTable;
    final chairImage = await _image(chairPath, PlaceholderArt.chair);
    final tableImage = await _image(tablePath, PlaceholderArt.table);
    if (!isMounted) {
      return;
    }
    _fitChair(chairImage, chairItem);
    _fitTable(tableImage, tableItem);
    _snapPillowToTable(tableItem);
    await workspace.applyTableSurface(
      tableItem.surfaceAsset ?? AssetPaths.tableSurface,
    );
  }

  void _fitChair(ui.Image image, ShopItem item) {
    final height = item.chairHeight ?? GameConfig.chairHeight;
    final bottomY = item.chairBottomY ?? GameConfig.chairBottomY;
    final aspect = image.width / image.height;
    chair.sprite = Sprite(image);
    chair.size.setValues(height * aspect, height);
    chair.position.setValues(GameConfig.chairX, bottomY);
  }

  void _fitTable(ui.Image image, [ShopItem? item]) {
    final aspect = image.width / image.height;
    final width = (GameConfig.tableHeight * aspect)
        .clamp(GameConfig.tableMinWidth, GameConfig.worldWidth)
        .toDouble();
    table.sprite = Sprite(image);
    table.size.setValues(width, GameConfig.tableHeight);
    // Chairs already had per-item vertical overrides; desks did not, so every
    // desk was pinned to the starter's placement no matter where its own art
    // put the slab. A desk whose slab sits higher then covered more of the
    // seated guest — she read as sitting inside the table.
    table.position.setValues(
      GameConfig.stationX,
      GameConfig.tableBottomY + (item?.deskDropY ?? 0),
    );
    final apronColor = item?.apronColor ?? SalonCatalog.starterTable.apronColor;
    tableApron.paint.color = ui.Color(apronColor);
  }

  void _snapPillowToTable(ShopItem tableItem) {
    // The armrest rides the slab, so it moves with the desk's drop. Both
    // numbers come from the same measurement of that desk's art, which is why
    // every desk ends up putting the armrest back on the canonical line.
    final y =
        (tableItem.pillowCenterY ?? GameConfig.salonPillowCenterY) +
        tableItem.deskDropY;
    pillow.position.setValues(
      GameConfig.stationX + tableItem.pillowOffsetX,
      y,
    );
  }

  /// Returns the scene to its pre-arrival state.
  void reset() {
    showScenery();
    customer.resetOffstage();
    workspace.hideImmediate();
  }

  /// Nail-care is a new page; the salon must not render behind it.
  void hideScenery() => _sceneryHidden = true;

  void showScenery() => _sceneryHidden = false;

  @override
  void renderTree(ui.Canvas canvas) {
    if (!_sceneryHidden) {
      super.renderTree(canvas);
      return;
    }
    workspace.renderTree(canvas);
  }

  // -------------------------------------------------------------------------
  // Scenery
  // -------------------------------------------------------------------------

  PositionComponent _buildRoom(ui.Image image) {
    return SpriteComponent(
      sprite: Sprite(image),
      size: Vector2(GameConfig.roomWidth, GameConfig.roomHeight),
      position: Vector2(GameConfig.worldWidth / 2, 0),
      anchor: Anchor.topCenter,
      priority: GameConfig.priorityRoom,
    );
  }

  SpriteComponent _buildChair(ui.Image image) {
    final aspect = image.width / image.height;
    return SpriteComponent(
      sprite: Sprite(image),
      size: Vector2(GameConfig.chairHeight * aspect, GameConfig.chairHeight),
      position: Vector2(GameConfig.chairX, GameConfig.chairBottomY),
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityChair,
    );
  }

  RectangleComponent _buildTableApron() {
    return RectangleComponent(
      size: Vector2(
        GameConfig.worldWidth,
        GameConfig.viewHeight - GameConfig.tableWoodY,
      ),
      position: Vector2(0, GameConfig.tableWoodY),
      anchor: Anchor.topLeft,
      paint: ui.Paint()
        ..color = ui.Color(SalonCatalog.starterTable.apronColor),
      priority: GameConfig.priorityTable - 1,
    );
  }

  SpriteComponent _buildTable(ui.Image image) {
    final aspect = image.width / image.height;
    final width = (GameConfig.tableHeight * aspect)
        .clamp(GameConfig.tableMinWidth, GameConfig.worldWidth)
        .toDouble();
    return SpriteComponent(
      sprite: Sprite(image),
      size: Vector2(width, GameConfig.tableHeight),
      position: Vector2(GameConfig.stationX, GameConfig.tableBottomY),
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityTable,
    );
  }

  SpriteComponent _buildPillow(ui.Image image) {
    return SpriteComponent(
      sprite: Sprite(image),
      size: Vector2(GameConfig.salonPillowWidth, GameConfig.salonPillowHeight),
      position: Vector2(GameConfig.stationX, GameConfig.salonPillowCenterY),
      anchor: Anchor.center,
      priority: GameConfig.priorityTable + 1,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Reads an evenly divided horizontal strip as an animation.
  SpriteAnimation _strip(
    ui.Image image, {
    required int frames,
    required double stepTime,
    List<double>? stepTimes,
    bool loop = true,
  }) {
    final textureSize = Vector2(
      image.width / frames,
      image.height.toDouble(),
    );
    if (stepTimes != null && stepTimes.length == frames) {
      return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.variable(
          amount: frames,
          stepTimes: stepTimes,
          textureSize: textureSize,
          loop: loop,
        ),
      );
    }
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: textureSize,
        loop: loop,
      ),
    );
  }

  /// Real art wins; a generated placeholder fills in while it is missing.
  Future<ui.Image> _image(
    String path,
    Future<ui.Image> Function() fallback,
  ) async {
    if (game.images.containsKey(path)) {
      return game.images.fromCache(path);
    }
    try {
      return await game.images.load(path);
    } catch (_) {
      game.images.clear(path);
      return game.images.fetchOrGenerate(path, fallback);
    }
  }
}
