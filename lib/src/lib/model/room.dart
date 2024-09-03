import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';

class RoomData {
  final List<Player> players;
  final Player host;
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> gameState;

  const RoomData(
      {required this.players, required this.host, required this.events, required this.gameState});
}

class Room {
  Game game;
  List<Player> players;
  Player host;
  List<Map<String, dynamic>> events;
  Map<String, dynamic> gameState;

  Room(
      {required this.game,
      required this.players,
      required this.host,
      required this.events,
      required this.gameState});

  static Room createRoom({required Player player, required Game game}) {
    final players = [player];
    return Room(
        game: game,
        players: players,
        host: player,
        events: [],
        gameState: game.getInitialGameState(players: players, host: player));
  }

  static Room joinRoom(
      {required Player player,
      required Game game,
      required List<Player> players,
      required Player host,
      required List<Map<String, dynamic>> events}) {
    return Room(
        game: game,
        players: players,
        host: host,
        events: events,
        gameState: getGameStateFromEvents(
            game: game, players: players, events: events, host: host));
  }

  static Map<String, dynamic> getGameStateFromEvents(
      {required Game game,
      required List<Player> players,
      required List<Map<String, dynamic>> events,
      required Player host}) {
    final gameState = game.getInitialGameState(players: players, host: host);
    for (final event in events) {
      game.processEvent(event: event, gameState: gameState, players: players, host: host);
    }
    return gameState;
  }

  bool leaveRoom(Player player) {
    if (!players.contains(player)) return false;
    players.remove(player);
    return true;
  }

  Map<String, dynamic>? checkPerformEvent(
      {required Map<String, dynamic> event, required Player player}) {
    return game.checkPerformEvent(
        event: event, player: player, gameState: gameState, players: players, host: host);
  }

  void processEvent(Map<String, dynamic> event) {
    return game.processEvent(
        event: event, gameState: gameState, players: players, host: host);
  }

  void onPlayerJoin(Player player) {
    return game.onPlayerJoin(
        player: player, gameState: gameState, players: players, host: host);
  }

  void onPlayerLeave(Player player) {
    return game.onPlayerLeave(
        player: player, gameState: gameState, players: players, host: host);
  }

  Map<String, dynamic>? checkGameEnd() {
    return game.checkGameEnd(gameState: gameState, players: players, host: host);
  }

  RoomData getRoomData() {
    return RoomData(
        players: players.toList(),
        host: host,
        events: events.toList(),
        gameState: Map.from(gameState));
  }
}
