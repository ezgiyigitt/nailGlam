import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'package:nail_glam/view/arrival_complete_overlay.dart';
import 'package:nail_glam/view/arrival_controls_overlay.dart';
import 'package:nail_glam/view/care_target_choice_overlay.dart';
import 'package:nail_glam/view/customer_thought_bubble_overlay.dart';
import 'package:nail_glam/view/home_overlay.dart';
import 'package:nail_glam/view/nail_care_overlay.dart';
import 'package:nail_glam/controller/game_audio.dart';
import 'camera_director.dart';
import 'player_progress_controller.dart';
import 'package:nail_glam/view/components/salon_scene.dart';
import 'package:nail_glam/model/customer_roster.dart';
import 'package:nail_glam/model/game_config.dart';
import 'nail_care_controller.dart';

/// Stages of the Part 1 loop.
enum GamePhase {
  /// Title screen is up, the salon idles behind it and can be browsed.
  home,

  /// Customer walking in from the back of the room towards the desk.
  arriving,

  /// Sit animation is playing.
  seating,

  /// Seated idle loop, waiting for the camera to move in.
  seatedIdle,

  /// Hands rising onto the manicure table after dialogue.
  handsToTable,

  /// Camera has pushed in on the manicure table. Part 2 takes over here.
  workspace,
}

class NailGlamGame extends FlameGame with PanDetector {
  NailGlamGame._(World world)
    : super(
        world: world,
        camera: CameraComponent(
          world: world,
          viewport: FixedResolutionViewport(
            resolution: Vector2(GameConfig.viewWidth, GameConfig.viewHeight),
          ),
        ),
      );

  factory NailGlamGame() => NailGlamGame._(World());

  late final SalonScene scene;
  late final CameraDirector director;
  late final NailCareController nailCare;
  PlayerProgressController progress = PlayerProgressController.memory();
  CustomerProfile guest = CustomerRoster.customer1;
  /// Home Guests picker. Start always uses this guest.
  CustomerProfile preferredGuest = CustomerRoster.customer1;

  void selectPreferredGuest(CustomerProfile profile) {
    preferredGuest = profile;
  }

  GamePhase phase = GamePhase.home;

  TimerComponent? _pendingWorkspaceCue;
  Vector2 _viewportResolution = Vector2(
    GameConfig.viewWidth,
    GameConfig.viewHeight,
  );

  @override
  void onGameResize(Vector2 size) {
    if (size.x > 0 && size.y > 0) {
      final canvasAspect = size.x / size.y;
      final designAspect = GameConfig.viewWidth / GameConfig.viewHeight;

      final resolution = canvasAspect <= designAspect
          ? Vector2(GameConfig.viewWidth, GameConfig.viewWidth / canvasAspect)
          : Vector2(
              GameConfig.viewHeight * canvasAspect,
              GameConfig.viewHeight,
            );

      if ((_viewportResolution - resolution).length2 > 1) {
        _viewportResolution = resolution;
        camera.viewport = FixedResolutionViewport(resolution: resolution);
      }
    }
    super.onGameResize(size);
  }

  @override
  Future<void> onLoad() async {
    scene = SalonScene();
    await world.add(scene);

    director = CameraDirector();
    await add(director);

    scene.customer.onStartedSitting = _onCustomerStartedSitting;
    scene.customer.onSeated = _onCustomerSeated;
    scene.customer.onHandsOnTable = _onHandsOnTable;

    nailCare = NailCareController(
      workspace: scene.workspace,
      onRequestFingerZoom: _beginFingerPage,
      onRequestHandReveal: _beginHandRevealPage,
      onRequestFinish: _onNailCareFinished,
      progressOf: () => progress.wallet,
    );
    await add(nailCare);

    progress.addListener(_syncSalonFurniture);
    await scene.applyEquippedFurniture(progress.wallet);
  }

  void _syncSalonFurniture() {
    scene.applyEquippedFurniture(progress.wallet);
  }

  @override
  void onRemove() {
    progress.removeListener(_syncSalonFurniture);
    super.onRemove();
  }

  /// Runs the whole arrival beat from the top. Safe to call from any phase, so
  /// the loop can be replayed without restarting the app.
  void startArrival() {
    resumeEngine();
    _cancelWorkspaceCue();

    overlays.remove(HomeOverlay.id);
    overlays.remove(ArrivalCompleteOverlay.id);
    overlays.remove(CustomerThoughtBubbleOverlay.id);
    overlays.remove(NailCareOverlay.id);
    overlays.add(ArrivalControlsOverlay.id);

    scene.reset();
    nailCare.reset();
    director.snapTo(GameConfig.cameraStationFocus);

    guest = preferredGuest;
    scene.applyGuest(guest);
    nailCare.guestId = guest.id;

    phase = GamePhase.arriving;
    scene.customer.enterSalon();
    GameAudio.instance.arrive();
  }

  /// The salon can only be browsed while nothing scripted is playing.
  bool get canBrowseSalon => phase == GamePhase.home;

  @override
  void onPanStart(DragStartInfo info) {
    if (!canBrowseSalon) {
      return;
    }
    director.beginPan();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!canBrowseSalon) {
      return;
    }
    director.panBy(_toWorldDx(info.delta.global.x));
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (!canBrowseSalon) {
      return;
    }
    director.endPan(_toWorldDx(info.velocity.x));
  }

  /// Screen pixels are not world units: the viewport letter-boxes the design
  /// resolution and the camera can be zoomed.
  double _toWorldDx(double screenDx) {
    if (size.x <= 0) {
      return 0;
    }
    final viewportScale = camera.viewport.virtualSize.x / size.x;
    return screenDx * viewportScale / camera.viewfinder.zoom;
  }

  /// Pauses only the Flame simulation. Flutter overlays remain interactive so
  /// the player can resume or return home.
  bool togglePause() {
    if (paused) {
      resumeEngine();
    } else {
      pauseEngine();
    }
    return paused;
  }

  /// Abandons the current arrival and restores the independent main menu.
  void returnToHome() {
    resumeEngine();
    _cancelWorkspaceCue();
    phase = GamePhase.home;

    overlays.remove(ArrivalControlsOverlay.id);
    overlays.remove(ArrivalCompleteOverlay.id);
    overlays.remove(CustomerThoughtBubbleOverlay.id);
    overlays.remove(NailCareOverlay.id);
    scene.reset();
    nailCare.reset();
    director.snapTo(GameConfig.cameraStationFocus);
    overlays.add(HomeOverlay.id);
  }

  void _onCustomerStartedSitting() {
    phase = GamePhase.seating;
    director.holdCurrentFrame();
  }

  void _onCustomerSeated() {
    phase = GamePhase.seatedIdle;
    _cancelWorkspaceCue();
    overlays.add(CustomerThoughtBubbleOverlay.id);
  }

  /// Called by the final thought bubble. Hands are already on the table in the
  /// seated idle art; the close-up plate takes over next.
  void completeCustomerDialogue() {
    overlays.remove(CustomerThoughtBubbleOverlay.id);
    _cancelWorkspaceCue();
    phase = GamePhase.handsToTable;
    scene.customer.playHandsToTable();
  }

  void _onHandsOnTable() {
    _cancelWorkspaceCue();
    _openWorkspacePage();
  }

  /// Hard cut to the manicure page. The salon stays off-screen.
  void _openWorkspacePage() {
    phase = GamePhase.workspace;
    director.snapTo(
      GameConfig.cameraNailcareFocus,
      zoom: GameConfig.cameraNailcareZoom,
    );
    scene.hideScenery();
    scene.workspace.revealImmediate();
    if (overlays.isActive(NailCareOverlay.id) ||
        overlays.isActive(CareTargetChoiceOverlay.id)) {
      return;
    }
    overlays.add(CareTargetChoiceOverlay.id);
  }

  void chooseHandCare() {
    overlays.remove(CareTargetChoiceOverlay.id);
    nailCare.beginHandCleaning();
    overlays.add(NailCareOverlay.id);
  }

  void chooseFootCare() {
    overlays.remove(CareTargetChoiceOverlay.id);
    nailCare.beginFootCleaning();
    overlays.add(NailCareOverlay.id);
  }

  void advanceNailCare() {
    nailCare.advanceFromNext();
  }

  void _beginFingerPage() {
    scene.workspace.showFinger(nailCare.digit);
    director.focusOn(
      GameConfig.cameraNailcareFocus,
      zoom: GameConfig.cameraNailcareZoom,
      speed: GameConfig.cameraPinkyZoomSpeed,
      onSettled: nailCare.beginNailBuffering,
    );
  }

  void _beginHandRevealPage() {
    director.snapTo(
      GameConfig.cameraNailcareFocus,
      zoom: GameConfig.cameraNailcareZoom,
    );
  }

  void _onNailCareFinished() {
    progress.rewardFinishedCustomer(nailCare.coins);
    overlays.remove(NailCareOverlay.id);
    // Rotate the appointment book so "Next customer" brings the next guest.
    final roster = CustomerRoster.all;
    final index = roster.indexWhere((CustomerProfile c) => c.id == guest.id);
    preferredGuest = roster[((index < 0 ? 0 : index) + 1) % roster.length];
    overlays.add(ArrivalCompleteOverlay.id);
  }

  /// Skips the arrival beat so tests can drive the manicure page directly.
  @visibleForTesting
  void debugOpenNailCare() {
    overlays.remove(HomeOverlay.id);
    overlays.remove(ArrivalCompleteOverlay.id);
    overlays.remove(CustomerThoughtBubbleOverlay.id);
    overlays.add(ArrivalControlsOverlay.id);
    if (!overlays.isActive(NailCareOverlay.id)) {
      overlays.add(NailCareOverlay.id);
    }
    phase = GamePhase.workspace;
    director.snapTo(
      GameConfig.cameraNailcareFocus,
      zoom: GameConfig.cameraNailcareZoom,
    );
    scene.hideScenery();
    scene.workspace.revealImmediate();
    guest = preferredGuest;
    scene.applyGuest(guest);
    nailCare.guestId = guest.id;
    nailCare.beginHandCleaning();
  }

  void _cancelWorkspaceCue() {
    _pendingWorkspaceCue?.removeFromParent();
    _pendingWorkspaceCue = null;
  }
}
