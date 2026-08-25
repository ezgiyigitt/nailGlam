import 'package:flutter/foundation.dart';

import 'package:nail_glam/controller/nail_glam_game.dart';
import 'package:nail_glam/model/customer_roster.dart';
import 'package:nail_glam/controller/player_progress_controller.dart';

/// MVC controller for the home menu overlay.
class HomeController {
  HomeController({
    required this.progress,
    required this.onStart,
    CustomerProfile? selectedGuest,
    this.onGuestChanged,
  }) : selectedGuest = selectedGuest ?? CustomerRoster.all.first;

  factory HomeController.fromGame(NailGlamGame game) => HomeController(
        progress: game.progress,
        onStart: game.startArrival,
        selectedGuest: game.preferredGuest,
        onGuestChanged: game.selectPreferredGuest,
      );

  /// Lightweight wiring for widget tests that only need Start.
  factory HomeController.testing({required VoidCallback onStart}) =>
      HomeController(
        progress: PlayerProgressController.memory(),
        onStart: onStart,
      );

  final PlayerProgressController progress;
  final VoidCallback onStart;
  CustomerProfile selectedGuest;
  final void Function(CustomerProfile guest)? onGuestChanged;

  bool get shouldPromptDailyLogin => progress.shouldPromptDailyLogin;

  void selectGuest(CustomerProfile guest) {
    selectedGuest = guest;
    onGuestChanged?.call(guest);
  }
}
