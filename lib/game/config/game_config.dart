import 'package:flame/components.dart';

/// Every tunable number for the arrival scene lives here so that layout and
/// pacing can be adjusted without touching component logic.
abstract final class GameConfig {
  // ---------------------------------------------------------------------
  // Viewport and world
  // ---------------------------------------------------------------------

  /// Portrait design resolution. The camera renders exactly this many world
  /// units, letter-boxed to whatever the physical screen happens to be, so the
  /// composition is identical on every device.
  static const double viewWidth = 1080;
  static const double viewHeight = 1920;

  /// The salon is a single wide room. It is wider than the viewport so the
  /// player can swipe sideways to browse it and, in later levels, fill the
  /// extra space with furniture they have bought.
  static const double worldWidth = 3240;

  /// Matches the viewport exactly: the room never scrolls vertically.
  static const double worldHeight = viewHeight;

  /// Vertical composition centre of the original 1080×1920 artwork.
  static const double sceneCenterY = viewHeight / 2;

  // ---------------------------------------------------------------------
  // Render order
  // ---------------------------------------------------------------------

  static const int priorityRoom = 0;
  static const int priorityChair = 30;
  static const int priorityShadow = 35;
  static const int priorityCustomer = 40;

  /// The manicure desk is the nearest thing to the lens, so the customer's
  /// cropped waist and her forearms disappear behind it.
  static const int priorityTable = 50;

  /// Full nail-care plate that takes over once the camera has pushed in.
  static const int priorityWorkspace = 100;

  // ---------------------------------------------------------------------
  // Room
  // ---------------------------------------------------------------------

  /// Room art is stretched across the whole world and fills the viewport
  /// height, so a horizontal swipe reveals more room and never empty space.
  static const double roomWidth = worldWidth;
  static const double roomHeight = viewHeight;

  // ---------------------------------------------------------------------
  // Manicure station
  // ---------------------------------------------------------------------

  /// Centre of the working station: desk, customer and the nail-care close-up
  /// all line up here, so the camera move reads as a straight push in.
  static const double stationX = worldWidth / 2;

  /// Full salon width. The delivered desk is a free-standing object with
  /// visible corners; stretching it across the world is what keeps wood on
  /// every camera x, from the left edge of the frame to the right.
  static const double tableWidth = worldWidth;
  static const double tableHeight = 920;

  /// Bottom-anchored on the very bottom edge of the frame.
  static const double tableBottomY = viewHeight;
  static double get tableTopY => tableBottomY - tableHeight;

  /// World y of the wooden desktop in the delivered table art. Flowers sit
  /// above this; everything below is the desk. 380/1001 is the first solid
  /// wood row in `nail_table.png`.
  static const double tableWoodY = 1000 + 342;

  /// Pink quilted armrest sitting on the salon desktop, station centre.
  static const double salonPillowWidth = 720;
  static const double salonPillowHeight = 210;
  static const double salonPillowCenterY = tableWoodY + 96;

  // ---------------------------------------------------------------------
  // Chair
  // ---------------------------------------------------------------------

  /// The chair stands behind the customer at the station. Most of it is buried
  /// behind the desk; what reads on screen is a short padded back around her
  /// mid-torso, not a fan that towers over her head.
  static const double chairHeight = 940;
  static const double chairBottomY = 2140;
  static const double chairX = stationX - 20;

  // ---------------------------------------------------------------------
  // Customer
  // ---------------------------------------------------------------------

  /// Every pose is packed onto one cell with her head in the same place, so a
  /// single size and a single top edge drive walking, turning and sitting
  /// alike. Anchoring at the top is what keeps her head from bouncing when the
  /// sprite swaps.
  /// Tall enough that the waist crop reaches behind the wooden desktop. A
  /// shorter sprite left a gap between her blouse and the table.
  static const double customerHeight = 980;

  /// Head stays in the upper third of the station shot. Depth comes from
  /// [customerHeight], not from sliding her down the frame.
  static const double customerTopY = 620;

  /// Front/sit art is cropped shorter under the head than the walk profile.
  /// This extra drop lines her blouse hem up with the desktop.
  static const double customerSitDrop = 70;

  /// Bottom of the sprite cell. The art is cropped at the waist, so this is a
  /// composition line rather than a foot position.
  static const double customerBottomY = customerTopY + customerHeight;

  /// She enters in profile from off the left edge of the station shot and
  /// walks right until she is behind the desk.
  static const double customerSeatX = stationX - 20;
  static const double customerEntryX = stationX - 960;

  /// World units per second along the floor.
  static const double customerWalkSpeed = 430;

  static const double customerWalkFrameTime = 0.15;
  static const double customerTurnFrameTime = 0.14;
  static const double customerSitFrameTime = 0.12;

  /// Gentle vertical bob layered on top of the walk cycle.
  static const double customerBobAmplitude = 9;
  static const double customerBobSpeed = 7.5;

  // ---------------------------------------------------------------------
  // Animation timing
  // ---------------------------------------------------------------------

  /// How long she takes to settle after arriving at the desk.
  static const double customerSettleDuration = 0.5;

  /// Beat between the customer settling into the chair and the camera pushing
  /// in on the workspace.
  static const double workspaceFocusDelay = 0.9;

  /// Hold after hands land before the manicure page opens.
  static const double workspaceDollyLeadIn = 0.35;

  /// Legacy fade length; the table page now cuts in immediately.
  static const double workspaceRevealDuration = 1.35;

  // ---------------------------------------------------------------------
  // Camera
  // ---------------------------------------------------------------------

  /// Exponential smoothing rates. Higher is snappier.
  static const double cameraFollowSpeed = 3.2;
  static const double cameraTransitionSpeed = 1.5;

  /// Controlled dolly into the nail-care close-up — slower than salon moves.
  static const double cameraWorkspaceDollySpeed = 0.85;

  static const double cameraDefaultZoom = 1.0;

  /// Final nail-care framing: the top-down plate fills the portrait viewport.
  static const double cameraNailcareZoom = 1.0;

  /// How close position/zoom must be before the dolly is considered settled.
  static const double cameraSettlePositionEpsilon = 2.5;
  static const double cameraSettleZoomEpsilon = 0.008;

  /// Resting camera x: the station is always the shot the scene opens on.
  static const double cameraHomeX = stationX;

  /// A swipe should feel pinned to the finger, so it eases far harder than a
  /// scripted camera move.
  static const double cameraPanFollowSpeed = 26;

  /// How quickly a flung swipe bleeds off, as a fraction kept per second.
  static const double cameraPanDamping = 0.06;

  /// Below this the residual swipe velocity is treated as a full stop.
  static const double cameraPanMinVelocity = 12;

  /// Top-down plate centre. Same x as the table so the move reads as a
  /// straight approach with no sideways slide.
  static Vector2 get cameraNailcareFocus =>
      Vector2(stationX, workspacePlateCenterY);

  /// Framing the salon rests at between customers.
  static Vector2 get cameraStationFocus => Vector2(stationX, sceneCenterY);

  // ---------------------------------------------------------------------
  // Nail-care workspace plate
  // ---------------------------------------------------------------------

  /// World size of the close-up plate. Matches the design viewport so zoom 1
  /// frames it edge-to-edge.
  static const double workspacePlateWidth = viewWidth;
  static const double workspacePlateHeight = viewHeight;
  static const double workspacePlateCenterY = sceneCenterY;

  /// Hand-wash sprite width on the plate (first frame of [AssetPaths.handWash]).
  static const double workspaceHandWidth = 820;
  static const double workspaceHandCenterX = workspacePlateWidth / 2;

  /// Lowered so the hand sits on the painted work pad instead of floating in
  /// empty cream space above the Clean bar.
  static const double workspaceHandCenterY = 720;
  static const double workspaceHandWristFadeEnd = 0.22;
  static const double workspaceHandShadowWidth = 280;
  static const double workspaceHandShadowHeight = 48;
  static const double workspaceHandShadowCenterY = 980;
  static const double workspaceHandShadowStrength = 0.48;

  /// Soft velvet pad under the hand, world-local to the plate.
  static const double workspacePadWidth = 900;
  static const double workspacePadHeight = 260;
  static const double workspacePadCenterY = 820;

  /// Top-down cushion that hides the knuckle crop on the finger close-up.
  static const double pinkyPillowWidth = 880;
  static const double pinkyPillowHeight = 280;
  static const double pinkyPillowCenterY = 560;
  static const double pinkyStumpFadeEnd = 0.05;

  // ---------------------------------------------------------------------
  // Nail-care gameplay
  // ---------------------------------------------------------------------

  static const double nailCareHandWashFrameTime = 0.85;
  static const int nailCareHandWashFrameCount = 4;
  static const double nailCareSprayHoldDuration = 1.1;
  static const double nailCareBufferHoldDuration = 1.1;
  static const double nailCareCutHoldDuration = 1.35;
  static const double nailCarePolishHoldDuration = 1.2;
  static const double nailCareWashDuration =
      nailCareHandWashFrameTime * nailCareHandWashFrameCount;

  static const int nailCareInventorySlotCount = 8;
  static const int nailCareWashCoinReward = 25;
  static const int nailCareBufferCoinReward = 40;
  static const int nailCareCutCoinReward = 35;
  static const int nailCarePolishCoinReward = 45;
  static const int nailCareAdMultiplier = 2;

  /// Local plate position of the pinky close-up sprite.
  static const double pinkySpriteCenterX = workspacePlateWidth / 2;
  static const double pinkySpriteCenterY = workspacePlateHeight * 0.40;
  static const double pinkySpriteHeight = 1500;

  /// Nail page stays at the same framing as the hand plate so the salon never
  /// peeks around a zoomed crop. Transition is a new full-bleed layout.
  static const double cameraPinkyZoom = cameraNailcareZoom;
  static const double cameraPinkyZoomSpeed = 2.4;

  static Vector2 get cameraPinkyFocus => cameraNailcareFocus;

  /// Overlay drop-targets as fractions of the Flutter overlay size.
  static const double nailCareHandTargetLeft = 0.08;
  static const double nailCareHandTargetTop = 0.18;
  static const double nailCareHandTargetWidth = 0.70;
  static const double nailCareHandTargetHeight = 0.52;

  static const double nailCareNailTargetLeft = 0.18;
  static const double nailCareNailTargetTop = 0.16;
  static const double nailCareNailTargetWidth = 0.48;
  static const double nailCareNailTargetHeight = 0.56;

  static const double nailCareToolCardWidth = 168;
  static const double nailCareToolCardMaxWidthFactor = 0.28;

  /// Shared overlay padding so pause/home and the clean bar never collide.
  static const double hudPad = 16;
  static const double hudButtonWidth = 54;
  static const double hudButtonHeight = 59;
  static const double hudButtonGap = 12;
  static const double hudTopControlsWidth =
      hudButtonWidth * 2 + hudButtonGap;
  static const double hudTopControlsReserve =
      hudTopControlsWidth + hudButtonGap;

  // ---------------------------------------------------------------------
  // Contact shadow
  // ---------------------------------------------------------------------

  static const double shadowWidth = 380;
  static const double shadowHeight = 96;
  static const double shadowOpacity = 0.38;

  /// Once she is in the chair the shadow spreads under the whole seat and
  /// lightens, so it reads as occlusion rather than a spot beneath her shoes.
  static const double shadowSeatedWidthFactor = 1.7;
  static const double shadowSeatedHeightFactor = 0.9;
  static const double shadowSeatedStrengthFactor = 0.5;
  static const double shadowSeatedOffsetX = -20;
}
