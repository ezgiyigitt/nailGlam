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

  /// The salon is wider than the viewport so the camera has room to travel
  /// from the entrance to the manicure table.
  /// Extra world space lets tall phones and wider tablets reveal more of the
  /// salon instead of showing letterbox bars around a fixed 9:16 canvas.
  static const double worldWidth = 3600;
  static const double worldHeight = 2400;

  /// Vertical composition centre of the original 1080×1920 artwork.
  static const double sceneCenterY = viewHeight / 2;

  /// Where the back wall meets the floor.
  static const double horizonY = 980;

  // ---------------------------------------------------------------------
  // Depth layers
  // ---------------------------------------------------------------------

  /// How strongly a layer tracks the camera. 1.0 is locked to the world,
  /// below 1.0 drifts behind (looks distant), above 1.0 races ahead (looks
  /// close to the lens). Kept gentle on purpose: this should read as depth,
  /// not as a scrolling shooter.
  static const double wallParallax = 0.82;
  static const double floorParallax = 0.94;
  static const double sceneryParallax = 1.0;
  static const double foregroundParallax = 1.16;
  static const double foregroundFarParallax = 1.09;

  static const double wallWidth = 4000;
  static const double wallBottomY = 1000;
  static const double floorTopY = 960;
  static const double floorWidth = 4000;

  // ---------------------------------------------------------------------
  // Render order
  // ---------------------------------------------------------------------

  static const int priorityWall = 0;
  /// Fills the doorway opening so an open door never reads as a hole in the
  /// scene. Replaced by real exterior art when that asset lands.
  static const int priorityDoorBackdrop = 5;
  static const int priorityFloor = 10;
  static const int priorityDoorLeaf = 18;
  static const int priorityDoorFrame = 20;
  static const int priorityChair = 30;
  static const int priorityShadow = 35;
  static const int priorityCustomer = 40;
  /// Full table body (legs, apron, drawers) sits in front of the customer so she
  /// reads as seated behind the manicure table instead of clipped through it.
  static const int priorityTableBase = 45;
  /// Perspective tabletop pass drawn above the body for a clean work surface.
  static const int priorityTable = 50;
  static const int priorityForeground = 90;
  /// Full nail-care plate that takes over once the camera has pushed in.
  static const int priorityWorkspace = 100;

  // ---------------------------------------------------------------------
  // Scenery placement (x is the object's centre, y is where it meets the floor)
  // ---------------------------------------------------------------------

  static const double doorX = 500;
  static const double doorFrameHeight = 1280;
  static const double doorLeafHeight = 1020;

  /// Left inner jamb of the arch, where the new door's gold hinges sit.
  static const double doorLeafHingeOffsetX = -208;

  /// Leaf lifts slightly so it sits in the arch, not on the planter pots.
  static const double doorLeafLiftY = 42;

  /// How far the leaf collapses when fully open. Swinging a flat sprite looks
  /// wrong in a 2.5D scene, so the leaf compresses towards the hinge instead.
  static const double doorOpenScaleX = 0.14;

  /// Doorway opening as a fraction of the frame sprite, measured against the
  /// art so the backdrop lands inside the moulding instead of over it.
  static const double doorOpeningWidthFactor = 0.49;
  static const double doorOpeningHeightFactor = 0.80;

  /// Empty manicure chair, already in the salon behind the desk.
  static const double chairX = customerSeatX;
  static const double chairHeight = 620;
  static const double chairArtOffsetX = -78;

  /// Slightly further from the lens than the desk so she sits behind it.
  static const double chairGroundY = customerNearGroundY - 8;

  /// 3/4 desk. Open (near) side is left; the top recedes to the right.
  static const double tableX = 1940;
  static const double tableHeight = 640;

  /// Closer to the camera than the chair, so the desk reads in front.
  static const double tableGroundY = customerNearGroundY + 72;

  static const double plantNearX = 260;
  static const double plantNearHeight = 1423;

  /// Pulled up inside the 1920-tall viewport. At 1985 the planter base and its
  /// shadow fell below the bottom edge, so the plant read as hovering simply
  /// because the point where it met the floor was never on screen.
  static const double plantNearBottomY = 1860;

  /// Contact shadows for the planters. Without them a bottom-anchored sprite on
  /// a flat floor reads as hovering, however correct its placement is.
  static const double plantNearShadowWidth = 470;
  static const double plantNearShadowHeight = 112;
  static const double plantFarShadowWidth = 240;
  static const double plantFarShadowHeight = 58;
  static const double plantShadowStrength = 0.72;

  /// Sits just off the right edge of the workspace framing so it adds a hint of
  /// foreground depth without growing into the shot the camera pushes in on.
  static const double plantFarX = 2580;
  static const double plantFarHeight = 700;
  static const double plantFarBottomY = 1790;

  // ---------------------------------------------------------------------
  // Customer
  // ---------------------------------------------------------------------

  /// The customer walks along a shallow diagonal: she starts further back near
  /// the door and ends closer to the lens at the chair. Combined with the
  /// scale ramp below this is what sells the depth without a 3D camera.
  static const double customerFarGroundY = 1270;
  static const double customerNearGroundY = 1660;
  static const double customerFarScale = 0.74;
  static const double customerNearScale = 1.0;

  static const double customerStartX = doorX;

  /// Open (near-left) side of the angled desk, over the waiting chair.
  static const double customerSeatOffsetX = -200;
  static const double customerSeatX = tableX + customerSeatOffsetX;

  /// Cruise speed. She eases down as the remaining distance shrinks.
  static const double customerWalkSpeed = 200;
  static const double customerWalkEndSpeed = 78;
  static const double walkSlowdownDistance = 340;

  /// Distance past the door after which the leaf swings shut behind her.
  static const double doorCloseTriggerDistance = 240;

  // ---------------------------------------------------------------------
  // Animation timing
  // ---------------------------------------------------------------------

  /// 4-frame walk cycle ≈ 0.56s.
  static const double walkFrameTime = 0.14;
  static const double stopFrameTime = 0.28;
  static const double turnFrameTime = 0.11;
  static const double sitFrameTime = 0.10;
  static const double lookFrameTime = 0.70;
  static const double sitIdleFrameTime = sitFrameTime;
  static const double handsToTableFrameTime = sitIdleFrameTime;

  static const double doorOpenDuration = 0.85;
  static const double doorCloseDuration = 0.95;

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

  /// Resting camera x at the start of the scene, and the reference point the
  /// parallax layers are authored against.
  static const double cameraHomeX = viewWidth / 2;

  /// The camera leads slightly ahead of the customer so she is never pinned to
  /// the centre of frame while walking.
  static const double cameraLeadX = 90;

  /// Top-down plate centre. Same x as the table so the move reads as a
  /// straight approach with no sideways slide.
  static Vector2 get cameraNailcareFocus =>
      Vector2(tableX, workspacePlateCenterY);

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
  static const double workspacePadWidth = 920;
  static const double workspacePadHeight = 520;
  static const double workspacePadCenterY = 780;

  // ---------------------------------------------------------------------
  // Nail-care gameplay
  // ---------------------------------------------------------------------

  static const double nailCareHandWashFrameTime = 0.85;
  static const int nailCareHandWashFrameCount = 4;
  static const double nailCareSprayHoldDuration = 1.1;
  static const double nailCareBufferHoldDuration = 1.1;
  static const double nailCareCutHoldDuration = 1.35;
  static const double nailCareWashDuration =
      nailCareHandWashFrameTime * nailCareHandWashFrameCount;

  static const int nailCareInventorySlotCount = 8;
  static const int nailCareWashCoinReward = 25;
  static const int nailCareBufferCoinReward = 40;
  static const int nailCareCutCoinReward = 35;
  static const int nailCareAdMultiplier = 2;

  /// Local plate position of the pinky close-up sprite.
  static const double pinkySpriteCenterX = workspacePlateWidth / 2;
  static const double pinkySpriteCenterY = workspacePlateHeight * 0.46;
  static const double pinkySpriteHeight = 1320;

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
