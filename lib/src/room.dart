import 'dart:math';

import 'package:either_dart/either.dart';

import 'check_result.dart';
import 'event.dart';
import 'game.dart';
import 'game_event.dart';
import 'player.dart';
import 'room_data.dart';

class Room {
  Game game;
  List<Player> players;
  Player host;
  List<Event> events;
  GameState? gameState;
  late Random random;

  Room(
      {required this.game,
      required this.players,
      required this.host,
      required this.events,
      required this.gameState});

  bool get gameStarted => gameState != null;
  bool get hasRequiredPlayers => players.length >= game.requiredPlayers;
  bool get isOvercapacity => players.length > game.playerLimit;

  static Room createRoom({required Player host, required Game game}) {
    return Room(
        game: game, players: [], host: host, events: [], gameState: null);
  }

  void joinRoom(Player player) {
    if (players.contains(player)) return;
    players.add(player);
  }

  void leaveRoom(Player player) {
    if (!players.contains(player)) return;
    List<Player> oldPlayers = players.toList();
    players.remove(player);
    onPlayerLeave(player, oldPlayers);
  }

  CheckResult checkStartGame() {
    if (gameStarted) return const GameHasStarted();
    if (!hasRequiredPlayers) return const NotEnoughPlayers();
    if (isOvercapacity) return const TooManyPlayers();
    return const CheckResultSuccess();
  }

  CheckResult startGame(List<Player> players, int seed) {
    final checkResult = checkStartGame();
    if (checkResult is CheckResultFailure) return checkResult;
    this.players = players;
    random = Random(seed);
    gameState =
        game.getInitialGameState(players: players, host: host, random: random);
    return checkResult;
  }

  bool stopGame() {
    if (!gameStarted) return false;
    gameState = null;
    return true;
  }

  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event, required Player player}) {
    if (!gameStarted) return const GameHasNotStarted();
    return game.checkPerformEvent(
        event: event,
        player: player,
        gameState: gameState!,
        players: players,
        host: host);
  }

  void processEvent(GameEvent event) {
    if (!gameStarted) return;
    game.processEvent(
        event: event,
        gameState: gameState!,
        players: players,
        host: host,
        random: random);
  }

  void onPlayerLeave(Player player, List<Player> oldPlayers) {
    if (gameStarted) {
      game.onPlayerLeave(
          player: player,
          gameState: gameState!,
          players: players,
          oldPlayers: oldPlayers,
          host: host,
          random: random);
    }
  }

  Map<String, dynamic>? checkGameEnd() {
    if (!gameStarted) return null;
    return game.checkGameEnd(
        gameState: gameState!, players: players, host: host, random: random);
  }

  RoomData getRoomData() {
    if (gameStarted) {
      return RoomDataGameState(
          game: game,
          players: players.toList(),
          host: host,
          events: events.toList(),
          gameState: gameState!);
    }
    return RoomData(
        game: game,
        players: players.toList(),
        host: host,
        events: events.toList());
  }

  Either<CheckResultFailure, dynamic> getGameResponse(
      Map<String, dynamic> request, Player player) {
    if (!gameStarted) return const Left(GameHasNotStarted());
    return game.getGameResponse(
        request: request,
        player: player,
        gameState: gameState!,
        players: players,
        host: host);
  }
}
