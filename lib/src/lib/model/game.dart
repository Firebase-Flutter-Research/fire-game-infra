import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/player.dart';

abstract class Game {
  // Game ID name
  String get name;

  // Return game state before moves are performed.
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players, required Player host});

  // Check if player can perform an event and return data.
  Map<String, dynamic>? checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host});

  // Process new event and return if it was successful.
  void processEvent(
      {required Event event,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host});

  // Handle when new player joins.
  void onPlayerJoin(
      {required Player player,
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
