import 'dart:math';

import 'package:either_dart/either.dart';

import 'check_result.dart';
import 'game_event.dart';
import 'player.dart';

/// Define the game's structure.
abstract class GameState {}

/// Define the rules for the game.
abstract class Game {
  /// Game ID name
  String get name;

  /// Count of required players to play
  int get requiredPlayers;

  /// Number of max allowed players
  int get playerLimit;

  /// Return game state before moves are performed.
  GameState getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random});

  /// Check if player can perform an event and return the result.
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required GameState gameState,
      required List<Player> players,
      required Player host});

  /// Process new event and return if it was successful.
  void processEvent(
      {required GameEvent event,
      required GameState gameState,
      required List<Player> players,
      required Player host,
      required Random random});

  /// Handle when player leaves room.
  void onPlayerLeave(
      {required Player player,
      required GameState gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random});

  /// Determine when the game has ended and return game end data.
  Map<String, dynamic>? checkGameEnd(
      {required GameState gameState,
      required List<Player> players,
      required Player host,
      required Random random});

  /// Return either a value or failure based on the given request.
  Either<CheckResultFailure, dynamic> getGameResponse(
      {required Map<String, dynamic> request,
      required Player player,
      required GameState gameState,
      required List<Player> players,
      required Player host}) {
    return const Left(UndefinedGameResponse());
  }
}
