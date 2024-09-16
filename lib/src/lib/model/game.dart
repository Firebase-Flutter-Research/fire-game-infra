import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/player.dart';

class CheckResult {
  final String? message;

  const CheckResult([this.message]);
}

class CheckResultSuccess extends CheckResult {
  const CheckResultSuccess([super.message]);
}

class CheckResultFailure extends CheckResult {
  const CheckResultFailure([super.message]);
}

abstract class Game {
  // Game ID name
  String get name;

  // Count of required players to play
  int get requiredPlayers;

  // Number of max allowed players
  int get playerLimit;

  // Return game state before moves are performed.
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players, required Player host});

  // Check if player can perform an event and return the result.
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host});

  // Process new event and return if it was successful.
  void processEvent(
      {required GameEvent event,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host});

  // Handle when player leaves room.
  void onPlayerLeave(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host});

  // Determine when the game has ended and return game end data.
  Map<String, dynamic>? checkGameEnd(
      {required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host});
}
