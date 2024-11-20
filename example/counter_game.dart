import 'dart:math';

import 'package:fire_game_infra/fire_game_infra.dart';

class CounterGameState extends GameState {
  // Counter value
  int value = 0;
}

class CounterGame extends Game {
  @override
  String get name => "Counter";

  @override
  int get requiredPlayers => 1;

  @override
  int get playerLimit => 10;

  @override
  GameState getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    return CounterGameState();
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required GameState gameState,
      required List<Player> players,
      required Player host}) {
    // Always return success since no event can fail in this game.
    return const CheckResultSuccess();
  }

  @override
  void processEvent(
      {required GameEvent event,
      required covariant CounterGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    // Only possible event type is increment by 1.
    gameState.value++;
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required GameState gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {
    // No logic for handling players leaving.
  }

  @override
  Map<String, dynamic>? checkGameEnd(
      {required GameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    // Return null since game will never end.
    return null;
  }
}
