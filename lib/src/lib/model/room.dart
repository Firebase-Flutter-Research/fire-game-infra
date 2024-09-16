import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';

class GameHasNotStarted extends CheckResultFailure {
  const GameHasNotStarted() : super("Game has not been started");
}

class GameHasStarted extends CheckResultFailure {
  const GameHasStarted() : super("Game has already been started");
}

class NotEnoughPlayers extends CheckResultFailure {
  const NotEnoughPlayers() : super("Not enough players to start game");
}

class TooManyPlayers extends CheckResultFailure {
  const TooManyPlayers() : super("There are too many players in the room");
}

class RoomData {
  final Game game;
  final List<Player> players;
  final Player host;
  final List<Event> events;
  final Map<String, dynamic>? gameState;

  bool get gameStarted => gameState != null;
  bool get hasRequiredPlayers => players.length >= game.requiredPlayers;
  bool get isOvercapacity => players.length > game.playerLimit;

  const RoomData(
      {required this.game,
      required this.players,
      required this.host,
      required this.events,
      required this.gameState});
}

class Room {
  Game game;
  List<Player> players;
  Player host;
  List<Event> events;
  Map<String, dynamic>? gameState;

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
    players.remove(player);
  }

  CheckResult startGame(List<Player> players) {
    if (gameStarted) return const GameHasStarted();
    if (!hasRequiredPlayers) return const NotEnoughPlayers();
    if (isOvercapacity) return const TooManyPlayers();
    this.players = players;
    gameState = game.getInitialGameState(players: players, host: host);
    return const CheckResultSuccess();
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
        event: event, gameState: gameState!, players: players, host: host);
  }

  void onPlayerLeave(Player player, List<Player> updatedPlayers) {
    if (gameStarted) {
      game.onPlayerLeave(
          player: player, gameState: gameState!, players: players, host: host);
    }
  }

  Map<String, dynamic>? checkGameEnd() {
    if (!gameStarted) return null;
    return game.checkGameEnd(
        gameState: gameState!, players: players, host: host);
  }

  RoomData getRoomData() {
    return RoomData(
        game: game,
        players: players.toList(),
        host: host,
        events: events.toList(),
        gameState: gameStarted ? Map.from(gameState!) : null);
  }
}
