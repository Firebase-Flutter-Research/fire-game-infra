import 'package:fire_game_infra/fire_game_infra.dart';
import 'package:flutter/material.dart';

import 'counter_game.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

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
