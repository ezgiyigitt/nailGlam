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
  late final PositionComponent pillow;

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
    final apron = _buildTableApron();

    for (final guest in CustomerRoster.all) {
      _guestKits[guest.id] = await _loadGuestKit(guest);
    }
    final starter = _guestKits[CustomerRoster.customer1.id]!;
    customer = CustomerComponent(
      walk: starter.walk,
      turn: starter.turn,
      sit: starter.sit,
    );

    await addAll(<Component>[room, chair, customer, apron, table, pillow]);

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
        loop: false,
      ),
    );
  }

  /// Swaps the station chair and desk to whatever the player has equipped.
  Future<void> applyEquippedFurniture(PlayerProgress progress) async {
    final chairPath =
        SalonCatalog.byId(progress.equippedChairId).previewAsset ??
        AssetPaths.salonChair;
    final tablePath =
        SalonCatalog.byId(progress.equippedTableId).previewAsset ??
        AssetPaths.nailTable;
    final chairImage = await _image(chairPath, PlaceholderArt.chair);
    final tableImage = await _image(tablePath, PlaceholderArt.table);
    if (!isMounted) {
      return;
    }
    chair.sprite = Sprite(chairImage);
    final chairAspect = chairImage.width / chairImage.height;
    chair.size.setValues(
      GameConfig.chairHeight * chairAspect,
      GameConfig.chairHeight,
    );
    table.sprite = Sprite(tableImage);
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

  /// Solid wood slab behind the detailed desk, so a camera wider than the
  /// artwork never shows floor beside the corners.
  PositionComponent _buildTableApron() {
    return RectangleComponent(
      size: Vector2(
        GameConfig.worldWidth,
        GameConfig.viewHeight - GameConfig.tableWoodY,
      ),
      position: Vector2(0, GameConfig.tableWoodY),
      anchor: Anchor.topLeft,
      paint: ui.Paint()..color = const ui.Color(0xFFC45420),
      priority: GameConfig.priorityTable - 1,
    );
  }

  SpriteComponent _buildTable(ui.Image image) {
    return SpriteComponent(
      sprite: Sprite(image),
      size: Vector2(GameConfig.tableWidth, GameConfig.tableHeight),
      position: Vector2(GameConfig.stationX, GameConfig.tableBottomY),
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityTable,
    );
  }

  PositionComponent _buildPillow(ui.Image image) {
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
    bool loop = true,
  }) {
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: Vector2(image.width / frames, image.height.toDouble()),
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
