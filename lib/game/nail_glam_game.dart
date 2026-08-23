import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../ui/arrival_complete_overlay.dart';
import '../ui/arrival_controls_overlay.dart';
import '../ui/customer_thought_bubble_overlay.dart';
import '../ui/home_overlay.dart';
import '../ui/nail_care_overlay.dart';
import 'camera_director.dart';
import 'components/salon_scene.dart';
import 'config/game_config.dart';
import 'nail_care_controller.dart';

/// Stages of the Part 1 loop.
enum GamePhase {
  /// Title screen is up, the salon idles behind it.
  home,

  /// Door opening and customer walking to the chair.
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

class NailGlamGame extends FlameGame {
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

    scene.customer.onClearedDoorway = _onCustomerClearedDoorway;
    scene.customer.onStartedSitting = _onCustomerStartedSitting;
    scene.customer.onSeated = _onCustomerSeated;
    scene.customer.onHandsOnTable = _onHandsOnTable;

    nailCare = NailCareController(
      workspace: scene.workspace,
      onRequestPinkyZoom: _beginPinkyPage,
      onRequestFinish: _onNailCareFinished,
    );
    await add(nailCare);
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
    director.snapTo(Vector2(GameConfig.cameraHomeX, GameConfig.sceneCenterY));

    phase = GamePhase.arriving;
    director.follow(scene.customer);
    scene.door.open(onComplete: scene.customer.enterSalon);
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
    director.snapTo(Vector2(GameConfig.cameraHomeX, GameConfig.sceneCenterY));
    overlays.add(HomeOverlay.id);
  }

  void _onCustomerClearedDoorway() {
    scene.door.close();
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
    if (overlays.isActive(NailCareOverlay.id)) {
      return;
    }
    nailCare.beginHandCleaning();
    overlays.add(NailCareOverlay.id);
  }

  void advanceNailCare() {
    nailCare.advanceFromNext();
  }

  void _beginPinkyPage() {
    scene.workspace.showPinkyNail();
    director.focusOn(
      GameConfig.cameraNailcareFocus,
      zoom: GameConfig.cameraNailcareZoom,
      speed: GameConfig.cameraPinkyZoomSpeed,
      onSettled: nailCare.beginNailBuffering,
    );
  }

  void _onNailCareFinished() {
    overlays.remove(NailCareOverlay.id);
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
    nailCare.beginHandCleaning();
  }

  void _cancelWorkspaceCue() {
    _pendingWorkspaceCue?.removeFromParent();
    _pendingWorkspaceCue = null;
  }
}
