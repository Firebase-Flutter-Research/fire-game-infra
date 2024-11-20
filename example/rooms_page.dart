import 'package:fire_game_infra/fire_game_infra.dart';
import 'package:flutter/material.dart';

import 'counter_game.dart';
import 'counter_page.dart';

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
                                  builder: (context) => const CounterPage()));
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
                MaterialPageRoute(builder: (context) => const CounterPage()));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
