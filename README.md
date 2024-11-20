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
  fire_game_infra: ^0.1.0
```
Run `flutter pub get` to fetch the package.

## Getting started

This package assumes that you have properly set up Firebase in your app.

## Usage

Example: Counter Game

The following example demonstrates how to build a simple counter-based multiplayer game.

Flutter Code:
```dart
import 'package:fire_game_example/counter_game.dart';
import 'package:fire_game_infra/fire_game_infra.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(/*Enter your Firebase credentials here*/));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RoomsPage(),
    );
  }
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = CounterGame();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Select"),
      ),
      body: RoomsBuilder(
          game: game,
          builder: (context, list) => SingleChildScrollView(
                child: Column(
                  children: list
                      .map((e) => ElevatedButton(
                          onPressed: () async {
                            if (await GameManager.instance.joinRoom(e)) {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const MyHomePage()));
                            }
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                  "${e.host.name}'s Room (${e.playerCount}/${e.game.playerLimit})"),
                            ),
                          )))
                      .toList(),
                ),
              )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await GameManager.instance.createRoom(game)) {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyHomePage()));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  void _incrementCounter() {
    // Empty event payload since action can only be an increment.
    GameManager.instance.sendGameEvent({});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (popped, value) async {
        if (popped) return;
        await GameManager.instance.leaveRoom();
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("In-Game"),
        ),
        body: GameBuilder<CounterGameState>(
          notStartedBuilder: (context, roomData, gameManager) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "Players (${roomData.players.length}/${roomData.game.playerLimit})"),
                if (roomData.hasRequiredPlayers &&
                    gameManager.player == roomData.host)
                  TextButton(
                      onPressed: gameManager.startGame,
                      child: const Text("Start Game")),
                if (roomData.hasRequiredPlayers &&
                    gameManager.player != roomData.host)
                  const Text("Waiting for host to start..."),
              ],
            ),
          ),
          gameStartedBuilder: (context, roomData, gameManager) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '${roomData.gameState.value}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

Game implementation:
```dart
import 'dart:math';

import 'package:fire_game_infra/fire_game_infra.dart';

class CounterGameState extends GameState {
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
    return const CheckResultSuccess();
  }

  @override
  void processEvent(
      {required GameEvent event,
      required covariant CounterGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    gameState.value++;
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required GameState gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {}

  @override
  Map<String, dynamic>? checkGameEnd(
      {required GameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    return null;
  }
}
```

## Additional Resources

See https://github.com/Firebase-Flutter-Research/game-hub for more examples.
