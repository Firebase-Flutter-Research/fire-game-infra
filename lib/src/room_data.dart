import 'game.dart';
import 'player.dart';
import 'event.dart';

/// Contains relevant room data.
class RoomData {
  /// Game being played.
  final Game game;

  /// All players in the room.
  final List<Player> players;

  /// Player that owns the room.
  final Player host;

  /// Event trace.
  final List<Event> events;

  /// Get if the game session has started.
  bool get gameStarted => this is RoomDataGameState;

  /// Get if the room has the required player count.
  bool get hasRequiredPlayers => players.length >= game.requiredPlayers;

  /// Get if the room is over the game player capacity.
  bool get isOvercapacity => players.length > game.playerLimit;

  const RoomData(
      {required this.game,
      required this.players,
      required this.host,
      required this.events});
}

/// Contains relevant room data and the game state.
class RoomDataGameState<T extends GameState> extends RoomData {
  /// Current state of the game.
  final T gameState;

  const RoomDataGameState(
      {required super.game,
      required super.players,
      required super.host,
      required super.events,
      required this.gameState});

  /// Change game state type.
  RoomDataGameState<U> cast<U extends GameState>() {
    return RoomDataGameState<U>(
      game: game,
      players: players,
      host: host,
      events: events,
      gameState: gameState as U,
    );
  }
}
