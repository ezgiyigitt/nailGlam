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
  /// Second pass of only the pixels that fall on the tabletop silhouette, so
  /// hands rest on the surface while the body stays behind the table.
  static const int priorityHandsOnTable = 55;
  static const int priorityForeground = 90;
  /// Full nail-care plate that takes over once the camera has pushed in.
  static const int priorityWorkspace = 100;

  // ---------------------------------------------------------------------
  // Scenery placement (x is the object's centre, y is where it meets the floor)
  // ---------------------------------------------------------------------

  static const double doorX = 430;
  static const double doorFrameHeight = 1150;
  static const double doorLeafHeight = 1080;

  /// Horizontal distance from the door's centre to the leaf's hinge, which is
  /// the left inner edge of the frame's opening.
  static const double doorLeafHingeOffsetX = -190;

  /// How far the leaf collapses when fully open. Swinging a flat sprite looks
  /// wrong in a 2.5D scene, so the leaf compresses towards its hinge instead,
  /// which reads as the door turning away from the camera.
  static const double doorOpenScaleX = 0.12;

  /// Doorway opening as a fraction of the frame sprite, measured against the
  /// art so the backdrop lands inside the moulding instead of over it.
  static const double doorOpeningWidthFactor = 0.60;
  static const double doorOpeningHeightFactor = 0.90;

  static const double chairX = 1880;
  static const double chairHeight = 600;

  /// Manicure table shares the seated customer's horizontal centre so she reads
  /// as sitting squarely behind it, not offset to either side.
  static const double tableX = 1880;
  static const double tableHeight = 470;

  /// The table stands nearer the lens than the seated customer, so it meets the
  /// floor lower in frame. Sharing her ground line put the tabletop across her
  /// chest, which hid her arms entirely and read as a missing limb.
  static const double tableGroundY = 1650;

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
  static const double customerFarGroundY = 1340;
  static const double customerNearGroundY = 1500;
  static const double customerFarScale = 0.84;
  static const double customerNearScale = 1.0;

  static const double customerStartX = doorX;
  static const double customerSeatX = tableX;
  static const double customerWalkSpeed = 300;

  /// Distance past the door after which the leaf swings shut behind her.
  static const double doorCloseTriggerDistance = 240;

  // ---------------------------------------------------------------------
  // Animation timing
  // ---------------------------------------------------------------------

  static const double walkFrameTime = 0.10;
  static const double sitFrameTime = 0.085;
  static const double sitIdleFrameTime = 0.22;
  static const double handsToTableFrameTime = 0.11;

  static const double doorOpenDuration = 0.85;
  static const double doorCloseDuration = 0.95;

  /// Beat between the customer settling into the chair and the camera pushing
  /// in on the workspace.
  static const double workspaceFocusDelay = 0.9;

  /// Hold after hands land before the dolly begins, so the place-down reads.
  static const double workspaceDollyLeadIn = 0.35;

  /// Soft reveal of the nail-care plate while the camera pushes in.
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

  /// Mid push-in on the salon table before the close-up plate fully takes over.
  static const double cameraWorkspaceZoom = 1.35;

  /// Final nail-care framing: plate fills the portrait viewport 1:1.
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

  /// First beat of the push-in: still in the salon, framed on the table and
  /// the customer's placed hands.
  static Vector2 get cameraWorkspaceFocus => Vector2(tableX, 1160);

  /// Final nail-care plate centre. Same x as the table so the dolly reads as a
  /// straight forward approach with no sideways slide.
  static Vector2 get cameraNailcareFocus =>
      Vector2(tableX, workspacePlateCenterY);

  // ---------------------------------------------------------------------
  // Nail-care workspace plate
  // ---------------------------------------------------------------------

  /// World size of the close-up plate. Matches the design viewport so zoom 1
  /// frames it edge-to-edge with no crop of the fingers.
  static const double workspacePlateWidth = viewWidth;
  static const double workspacePlateHeight = viewHeight;
  static const double workspacePlateCenterY = sceneCenterY;

  static const double workspaceCushionWidth = 780;
  static const double workspaceCushionCenterY = 1180;
  static const double workspaceHandWidth = 560;

  /// Nudged right of the plate centre so the wrist lands over the thick middle
  /// of the cushion rather than its thin left taper.
  static const double workspaceHandCenterX = 600;

  /// Raised until the wrist ends inside the cushion band. The reference hand is
  /// cropped at the wrist, so anything lower exposes that cut as a floating
  /// edge instead of an arm continuing off frame.
  static const double workspaceHandCenterY = 952;

  /// Lower slice of the cushion re-drawn above the hand. It covers the wrist
  /// crop so the hand reads as resting on the rest and continuing behind it.
  static const double workspaceCushionLipFraction = 0.52;

  /// Where the hand sprite starts fading out towards its bottom edge. The
  /// reference art ends in a hard circular cut at the wrist; fading it means no
  /// straight edge survives even where the cushion does not cover it.
  static const double workspaceHandWristFadeStart = 0.76;

  /// Contact shadow tying the hand to the cushion.
  static const double workspaceHandShadowWidth = 430;
  static const double workspaceHandShadowHeight = 86;
  static const double workspaceHandShadowCenterY = 1258;
  static const double workspaceHandShadowStrength = 0.6;

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
