/// Result for game action.
abstract class CheckResult {
  final String? message;

  const CheckResult([this.message]);
}

/// Successful result.
class CheckResultSuccess extends CheckResult {
  const CheckResultSuccess([super.message]);
}

/// Failure result.
class CheckResultFailure extends CheckResult {
  const CheckResultFailure([super.message]);
}

class UndefinedGameResponse extends CheckResultFailure {
  const UndefinedGameResponse() : super("Undefined Game Response");
}

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

class NotRoomHost extends CheckResultFailure {
  const NotRoomHost() : super("Player is not the room's host");
}
