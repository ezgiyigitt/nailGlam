import 'dart:io' show Platform;

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'game/nail_glam_game.dart';
import 'ui/arrival_complete_overlay.dart';
import 'ui/arrival_controls_overlay.dart';
import 'ui/customer_thought_bubble_overlay.dart';
import 'ui/home_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait lock and full screen only make sense on handsets; on desktop the
  // same calls are either no-ops or throw, so they are skipped there.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();
  }

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
  Widget build(BuildContext context) {
    return GameWidget<NailGlamGame>(
      game: _game,
      backgroundBuilder: (BuildContext context) =>
          const ColoredBox(color: Color(0xFF2B1D22)),
      overlayBuilderMap: <String, Widget Function(BuildContext, NailGlamGame)>{
        HomeOverlay.id: (BuildContext context, NailGlamGame game) =>
            HomeOverlay(onPlay: game.startArrival),
        ArrivalCompleteOverlay.id: (BuildContext context, NailGlamGame game) =>
            ArrivalCompleteOverlay(onReplay: game.startArrival),
        ArrivalControlsOverlay.id: (BuildContext context, NailGlamGame game) =>
            ArrivalControlsOverlay(
              onTogglePause: game.togglePause,
              onHome: game.returnToHome,
            ),
        CustomerThoughtBubbleOverlay.id:
            (BuildContext context, NailGlamGame game) =>
                CustomerThoughtBubbleOverlay(
                  onComplete: game.completeCustomerDialogue,
                ),
      },
      initialActiveOverlays: const <String>[HomeOverlay.id],
    );
  }
}
