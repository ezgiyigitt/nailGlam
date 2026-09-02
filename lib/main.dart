import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'controller/game_audio.dart';
import 'controller/home_controller.dart';
import 'controller/nail_glam_game.dart';
import 'model/player_progress.dart';
import 'view/arrival_complete_overlay.dart';
import 'view/arrival_controls_overlay.dart';
import 'view/care_target_choice_overlay.dart';
import 'view/customer_thought_bubble_overlay.dart';
import 'view/home_overlay.dart';
import 'view/nail_care_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait lock and full screen only make sense on handsets; on desktop the
  // same calls are either no-ops or throw, so they are skipped there.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();
  }

  // Never await the audio plugin here: on Chrome it can stall before the first
  // frame, which leaves a white tab that never opens.
  unawaited(GameAudio.instance.start());
  runApp(const NailGlamApp());
}

class NailGlamApp extends StatelessWidget {
  const NailGlamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nail Glam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD2708A)),
        scaffoldBackgroundColor: const Color(0xFF2B1D22),
      ),
      home: const GameHost(),
    );
  }
}

class GameHost extends StatefulWidget {
  const GameHost({super.key});

  @override
  State<GameHost> createState() => _GameHostState();
}

class _GameHostState extends State<GameHost> {
  late final NailGlamGame _game = NailGlamGame();

  @override
  void initState() {
    super.initState();
    PlayerProgress.load()
        .then((PlayerProgress progress) {
          _game.progress.attachModel(progress);
          if (mounted) {
            setState(() {});
          }
        })
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<NailGlamGame>(
      game: _game,
      backgroundBuilder: (BuildContext context) =>
          const ColoredBox(color: Color(0xFFFFE4C8)),
      loadingBuilder: (BuildContext context) => const ColoredBox(
        color: Color(0xFFFFE4C8),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE56B97)),
        ),
      ),
      errorBuilder: (BuildContext context, Object error) => ColoredBox(
        color: const Color(0xFFFFE4C8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B524C)),
            ),
          ),
        ),
      ),
      overlayBuilderMap: <String, Widget Function(BuildContext, NailGlamGame)>{
        HomeOverlay.id: (BuildContext context, NailGlamGame game) =>
            HomeOverlay(controller: HomeController.fromGame(game)),
        ArrivalCompleteOverlay.id: (BuildContext context, NailGlamGame game) =>
            ArrivalCompleteOverlay(
              onReplay: game.startArrival,
              guestName: game.guest.name,
            ),
        ArrivalControlsOverlay.id: (BuildContext context, NailGlamGame game) =>
            ArrivalControlsOverlay(
              onTogglePause: game.togglePause,
              onHome: game.returnToHome,
            ),
        CustomerThoughtBubbleOverlay.id:
            (BuildContext context, NailGlamGame game) =>
                CustomerThoughtBubbleOverlay(
                  onComplete: game.completeCustomerDialogue,
                  guest: game.guest,
                ),
        NailCareOverlay.id: (BuildContext context, NailGlamGame game) =>
            NailCareOverlay(game: game),
        CareTargetChoiceOverlay.id: (BuildContext context, NailGlamGame game) =>
            CareTargetChoiceOverlay(
              onChooseHand: game.chooseHandCare,
              onChooseFoot: game.chooseFootCare,
            ),
      },
      initialActiveOverlays: const <String>[HomeOverlay.id],
    );
  }
}
