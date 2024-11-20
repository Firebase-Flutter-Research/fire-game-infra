import 'package:flutter/material.dart';

import 'game.dart';
import 'game_manager.dart';
import 'room_data.dart';

/// Receive live updates from the connected room from Firebase.
class GameBuilder<T extends GameState> extends StatelessWidget {
  /// Game manager to interact with.
  final GameManager? gameManager;

  /// Build widget when game has started.
  final Widget Function(BuildContext, RoomDataGameState<T>, GameManager)
      gameStartedBuilder;

  /// Build widget when game has not started.
  final Widget Function(BuildContext, RoomData, GameManager) notStartedBuilder;

  /// Build widget when there is no data.
  final Widget Function(BuildContext)? loadingBuilder;

  /// Build widget when there is an error.
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const GameBuilder(
      {super.key,
      this.gameManager,
      required this.notStartedBuilder,
      required this.gameStartedBuilder,
      this.loadingBuilder,
      this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    GameManager gameManager = this.gameManager ?? GameManager.instance;
    return StreamBuilder(
        stream: gameManager.roomDataStream,
        builder: (context, snapshot) {
          const placeholder = SizedBox.shrink();
          if (!gameManager.hasRoom()) {
            if (loadingBuilder != null) {
              return loadingBuilder!(context);
            }
            return placeholder;
          }
          if (snapshot.hasError) {
            if (errorBuilder != null) {
              return errorBuilder!(
                  context, snapshot.error!, snapshot.stackTrace);
            }
            return placeholder;
          }
          if (!snapshot.hasData) {
            if (loadingBuilder != null) {
              return loadingBuilder!(context);
            }
            return placeholder;
          }
          final roomData = snapshot.data!;
          if (roomData.gameStarted) {
            return gameStartedBuilder(context,
                (roomData as RoomDataGameState).cast<T>(), gameManager);
          }
          return notStartedBuilder(context, roomData, gameManager);
        });
  }
}
