This is a Flutter package that simplifies the development of online multiplayer games using Firebase. It provides a robust infrastructure to manage game states, events, and player interactions, making it easier for developers to focus on game logic and design.

## Features

- Real-Time Multiplayer: Synchronize game state and events across multiple devices using Firebase.
- Customizable Game Logic: Define your game rules, states, and player interactions.
- Room Management: Create, join, and manage game rooms effortlessly.
- Stream Updates: Listen to live updates for game events, player actions, and room changes.
- Game State Handling: Seamlessly manage game states and transitions.

## Installation

Add the following line to your `pubspec.yaml` file:
```yaml 
dependencies:
  fire_game_infra: ^0.1.1
```
Run `flutter pub get` to fetch the package.

## Getting started

This package assumes that you have properly set up Firebase in your app.

## Usage

To create a game you must define a game and game state class.
```dart
class SomeGameState extends GameState {
  // Define your game state fields.
}

class SomeGame extends Game {
  // Override all of the necessary game rule functions.
}
```

Once you have your game implementation completed, you can create a room through the GameManager.
```dart
final gameManager = GameManager.instance;
final game = SomeGame();
await gameManager.createRoom(game);
```

Using the RoomsBuilder widget, you can create a UI list of available rooms for the game and join the specific one.
```dart
RoomsBuilder(
  game: game,
  builder: (context, roomDataList) => // Build rooms list using Firebase room data objects.
);
```
```dart
Future<void> _joinRoom(FirebaseRoomData roomData) async {
  await GameManager.instance.joinRoom(roomData);
}
```

You can also leave a room by calling the "leaveRoom" function.
```dart
await GameManager.instance.leaveRoom();
```

Once a room has been joined, its contents can be displayed using the GameBuilder widget.
```dart
GameBuilder<SomeGameState>(
  notStartedBuilder: (context, roomData, gameManager) => /*Display room data when game has not started.*/,
  gameStartedBuilder: (context, roomData, gameManager) => /*Display room data when game has started. This builder has access to the game state.*/,
);
```

You can start and manually stop a game.
```dart
final gameManager = GameManager.instance;
await gameManager.startGame();
await gameManager.stopGame();
```

Send events to update the shared game state via GameManager. Events sent will be processed by the "processEvent" rule within Game, and will automatically update the room data shown by GameBuilder.
```dart
await GameManager.instance.sendGameEvent({"field": "value"});
```

Define callbacks to react to certain situations, such as when a game event is received, when the game stops, etc.
```dart
final gameManager = GameManager.instance;

gameManager.setOnGameEvent<SomeGameState>((event, state) { /* Event reaction logic. */ });

// Log will be populated if game stop was triggered by the "checkGameEnd" rule within Game.
gameManager.setOnGameStop((log) { /* Game stop reaction logic. */ });
```

## Additional Resources

See https://github.com/Firebase-Flutter-Research/game-hub for more examples.
