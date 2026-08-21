import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../config/asset_paths.dart';
import '../config/game_config.dart';
import '../config/sprite_atlas.dart';
import 'customer_component.dart';
import 'depth_sprite_component.dart';
import 'nail_workspace.dart';
import 'salon_door_component.dart';
import 'soft_shadow_component.dart';

/// Builds and owns the salon: three depth layers of scenery, the entrance, the
/// customer and her contact shadow.
class SalonScene extends Component with HasGameReference<FlameGame> {
  late final SalonDoorComponent door;
  late final CustomerComponent customer;
  late final SoftShadowComponent shadow;
  late final NailWorkspace workspace;
  late final PositionComponent tableBase;
  late final PositionComponent tableTop;

  @override
  Future<void> onLoad() async {
    final wallImage = await game.images.load(AssetPaths.wall);
    final floorImage = await game.images.load(AssetPaths.floor);
    final doorFrameImage = await game.images.load(AssetPaths.doorFrame);
    final doorLeafImage = await game.images.load(AssetPaths.doorLeaf);
    final chairImage = await game.images.load(AssetPaths.chair);
    final tableImage = await game.images.load(AssetPaths.nailTable);
    final plantImage = await game.images.load(AssetPaths.plant);
    final walkImage = await game.images.load(AssetPaths.customerWalk);
    final sitImage = await game.images.load(AssetPaths.customerSit);
    final sitIdleImage = await game.images.load(AssetPaths.customerSitIdle);
    final handsToTableImage = await game.images.load(
      AssetPaths.customerHandsToTable,
    );

    tableBase = _buildTableBase(tableImage);
    tableTop = _buildTableTop(tableImage);

    final nearPlant = _buildNearPlant(plantImage);
    final farPlant = _buildFarPlant(plantImage);

    await addAll(<Component>[
      _buildWall(wallImage),
      _buildDoorwayBackdrop(),
      _buildFloor(floorImage),
      _buildChair(chairImage),
      tableBase,
      tableTop,
      _PropContactShadow(
        target: nearPlant,
        groundY: GameConfig.plantNearBottomY,
        footprint: Vector2(
          GameConfig.plantNearShadowWidth,
          GameConfig.plantNearShadowHeight,
        ),
      ),
      nearPlant,
      _PropContactShadow(
        target: farPlant,
        groundY: GameConfig.plantFarBottomY,
        footprint: Vector2(
          GameConfig.plantFarShadowWidth,
          GameConfig.plantFarShadowHeight,
        ),
      ),
      farPlant,
    ]);

    door = SalonDoorComponent(
      frameSprite: _region(doorFrameImage, SpriteAtlas.doorFrame),
      leafSprite: _region(doorLeafImage, SpriteAtlas.doorLeaf),
      position: Vector2(GameConfig.doorX, GameConfig.customerFarGroundY),
    );

    shadow = SoftShadowComponent(priority: GameConfig.priorityShadow);

    customer = CustomerComponent(
      walkAnimation: _animation(
        walkImage,
        SpriteAtlas.customerWalk,
        GameConfig.walkFrameTime,
      ),
      sitAnimation: _animation(
        sitImage,
        SpriteAtlas.customerSit,
        GameConfig.sitFrameTime,
        loop: false,
      ),
      sitIdleAnimation: _animation(
        sitIdleImage,
        SpriteAtlas.customerSitIdle,
        GameConfig.sitIdleFrameTime,
        loop: false,
      ),
      handsToTableAnimation: _animation(
        handsToTableImage,
        SpriteAtlas.customerHandsToTable,
        GameConfig.handsToTableFrameTime,
        loop: false,
      ),
      shadow: shadow,
    );

    await addAll(<Component>[
      door,
      shadow,
      customer,
      _HandsOnTabletopPass(customer: customer, tableTop: tableTop),
    ]);

    workspace = NailWorkspace();
    await add(workspace);
  }

  /// Returns the scene to its pre-arrival state.
  void reset() {
    door.resetClosed();
    customer.resetToDoorway();
    workspace.hideImmediate();
  }

  // -------------------------------------------------------------------------
  // Scenery
  // -------------------------------------------------------------------------

  Component _buildWall(ui.Image image) {
    return DepthSpriteComponent(
      parallaxFactor: GameConfig.wallParallax,
      cameraAnchorX: GameConfig.cameraHomeX,
      sprite: _region(image, SpriteAtlas.wall),
      size: Vector2(GameConfig.wallWidth, GameConfig.wallBottomY),
      position: Vector2(GameConfig.worldWidth / 2, GameConfig.wallBottomY),
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityWall,
    );
  }

  /// Stand-in for what lies past the entrance. Without it the transparent
  /// centre of the door frame shows whatever is behind the world, which reads as
  /// a hole in the salon once the leaf swings open.
  Component _buildDoorwayBackdrop() {
    final frameScale =
        GameConfig.doorFrameHeight / SpriteAtlas.doorFrame.size.y;
    final frameWidth = SpriteAtlas.doorFrame.size.x * frameScale;
    return _DoorwayBackdrop(
      size: Vector2(
        frameWidth * GameConfig.doorOpeningWidthFactor,
        GameConfig.doorFrameHeight * GameConfig.doorOpeningHeightFactor,
      ),
      position: Vector2(GameConfig.doorX, GameConfig.customerFarGroundY),
    );
  }

  Component _buildFloor(ui.Image image) {
    return DepthSpriteComponent(
      parallaxFactor: GameConfig.floorParallax,
      cameraAnchorX: GameConfig.cameraHomeX,
      sprite: _region(image, SpriteAtlas.floor),
      size: Vector2(
        GameConfig.floorWidth,
        GameConfig.worldHeight - GameConfig.floorTopY,
      ),
      position: Vector2(GameConfig.worldWidth / 2, GameConfig.floorTopY),
      anchor: Anchor.topCenter,
      priority: GameConfig.priorityFloor,
    );
  }

  Component _buildChair(ui.Image image) {
    final scale = GameConfig.chairHeight / SpriteAtlas.chair.size.y;
    return SpriteComponent(
      sprite: _region(image, SpriteAtlas.chair),
      size: SpriteAtlas.chair.size * scale,
      position: Vector2(GameConfig.chairX, GameConfig.customerNearGroundY),
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityChair,
    );
  }

  PositionComponent _buildTableBase(ui.Image image) {
    final scale = GameConfig.tableHeight / SpriteAtlas.nailTable.size.y;
    return SpriteComponent(
      sprite: _region(image, SpriteAtlas.nailTable),
      size: SpriteAtlas.nailTable.size * scale,
      position: Vector2(GameConfig.tableX, GameConfig.tableGroundY),
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityTableBase,
    );
  }

  PositionComponent _buildTableTop(ui.Image image) {
    final scale = GameConfig.tableHeight / SpriteAtlas.nailTable.size.y;
    return _TabletopOccluder(
      sprite: _region(image, SpriteAtlas.nailTable),
      size: SpriteAtlas.nailTable.size * scale,
      position: Vector2(GameConfig.tableX, GameConfig.tableGroundY),
      priority: GameConfig.priorityTable,
    );
  }

  DepthSpriteComponent _buildNearPlant(ui.Image image) {
    final scale = GameConfig.plantNearHeight / SpriteAtlas.plant.size.y;
    return DepthSpriteComponent(
      parallaxFactor: GameConfig.foregroundParallax,
      cameraAnchorX: GameConfig.cameraHomeX,
      sprite: _region(image, SpriteAtlas.plant),
      size: SpriteAtlas.plant.size * scale,
      position: Vector2(GameConfig.plantNearX, GameConfig.plantNearBottomY),
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityForeground,
    );
  }

  DepthSpriteComponent _buildFarPlant(ui.Image image) {
    final scale = GameConfig.plantFarHeight / SpriteAtlas.plant.size.y;
    final plant = DepthSpriteComponent(
      parallaxFactor: GameConfig.foregroundFarParallax,
      cameraAnchorX: GameConfig.cameraHomeX,
      sprite: _region(image, SpriteAtlas.plant),
      size: SpriteAtlas.plant.size * scale,
      position: Vector2(GameConfig.plantFarX, GameConfig.plantFarBottomY),
      anchor: Anchor.bottomCenter,
      priority: GameConfig.priorityForeground,
    )..flipHorizontally();
    return plant;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Sprite _region(ui.Image image, SpriteRegion region) {
    return Sprite(image, srcPosition: region.position, srcSize: region.size);
  }

  SpriteAnimation _animation(
    ui.Image image,
    CharacterSheet sheet,
    double stepTime, {
    bool loop = true,
  }) {
    final frames = <Sprite>[
      for (final origin in sheet.framePositions)
        Sprite(image, srcPosition: origin, srcSize: sheet.frameSize),
    ];
    return SpriteAnimation.spriteList(frames, stepTime: stepTime, loop: loop);
  }
}

/// Perspective tabletop silhouette shared by the occluder and the hand pass.
ui.Path manicureTabletopPath(Vector2 size) {
  return ui.Path()
    ..moveTo(size.x * 0.002, size.y * 0.171)
    ..lineTo(size.x * 0.732, 0)
    ..lineTo(size.x * 0.997, size.y * 0.106)
    ..lineTo(size.x * 0.994, size.y * 0.157)
    ..lineTo(size.x * 0.213, size.y * 0.351)
    ..lineTo(0, size.y * 0.215)
    ..close();
}

/// Front render pass for only the perspective tabletop silhouette.
///
/// Layer order is: chair → customer → full table body → this tabletop.
/// The customer never jumps above the table; hands that land on the surface are
/// re-drawn by [_HandsOnTabletopPass] after this pass.
class _TabletopOccluder extends SpriteComponent {
  _TabletopOccluder({
    required super.sprite,
    required super.size,
    required super.position,
    required super.priority,
  }) : super(anchor: Anchor.bottomCenter);

  @override
  void render(ui.Canvas canvas) {
    canvas.save();
    canvas.clipPath(manicureTabletopPath(size), doAntiAlias: true);
    super.render(canvas);
    canvas.restore();
  }
}

/// Re-draws the seated customer clipped to the tabletop silhouette.
///
/// Body stays at [GameConfig.priorityCustomer] behind the table. Only the
/// pixels that fall on the work surface (the raised hands) are painted again
/// above the tabletop, so she never reads as buried inside the furniture.
class _HandsOnTabletopPass extends PositionComponent {
  _HandsOnTabletopPass({required this.customer, required this.tableTop})
    : super(priority: GameConfig.priorityHandsOnTable);

  final CustomerComponent customer;
  final PositionComponent tableTop;

  @override
  void update(double dt) {
    super.update(dt);
    position.setFrom(customer.position);
    size.setFrom(customer.size);
    scale.setFrom(customer.scale);
    anchor = customer.anchor;
  }

  @override
  void render(ui.Canvas canvas) {
    if (customer.phase != CustomerPhase.handsToTable) {
      return;
    }

    final clip = _tabletopPathInCustomerSpace();
    canvas.save();
    canvas.clipPath(clip, doAntiAlias: true);
    customer.renderSeatedFrame(canvas);
    canvas.restore();
  }

  /// Maps the tabletop polygon from table-local into this component's local
  /// space. Both boxes are bottom-centred, so the offset is the difference
  /// between their anchor points plus the difference in box size. The table no
  /// longer shares the customer's ground line, so this cannot assume zero.
  ui.Path _tabletopPathInCustomerSpace() {
    final dx =
        (tableTop.position.x - position.x) +
        (size.x - tableTop.size.x) / 2;
    final dy =
        (tableTop.position.y - position.y) + size.y - tableTop.size.y;
    return manicureTabletopPath(
      tableTop.size,
    ).shift(ui.Offset(dx, dy));
  }
}

/// Soft daylight wash sitting inside the doorway opening.
///
/// Placeholder for the exterior art: it only has to stop the open door from
/// showing empty space, so it is a vertical gradient rather than a scene.
class _DoorwayBackdrop extends PositionComponent {
  _DoorwayBackdrop({required Vector2 size, required Vector2 position})
    : super(
        size: size,
        position: position,
        anchor: Anchor.bottomCenter,
        priority: GameConfig.priorityDoorBackdrop,
      );

  @override
  void render(ui.Canvas canvas) {
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(size.x / 2, 0),
          ui.Offset(size.x / 2, size.y),
          const <ui.Color>[
            ui.Color(0xFFF6ECE0),
            ui.Color(0xFFE6D6C6),
            ui.Color(0xFFC9B4A2),
          ],
          const <double>[0, 0.55, 1],
        ),
    );
  }
}

/// Contact shadow that tracks a parallax prop.
///
/// The prop drifts with the camera, so a shadow parked at the authored x would
/// separate from it as soon as the camera moves.
class _PropContactShadow extends SoftShadowComponent {
  _PropContactShadow({
    required this.target,
    required this.groundY,
    required Vector2 footprint,
  }) : super(priority: GameConfig.priorityForeground) {
    size.setFrom(footprint);
    strength = GameConfig.plantShadowStrength;
  }

  final PositionComponent target;
  final double groundY;

  @override
  void update(double dt) {
    super.update(dt);
    position.setValues(target.position.x, groundY);
  }
}
