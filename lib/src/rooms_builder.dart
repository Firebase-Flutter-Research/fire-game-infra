import 'package:flutter/material.dart';

import 'firebase_room_communicator.dart';
import 'firebase_room_data.dart';
import 'game.dart';

/// Receive live updates of the list of rooms for the specified game from Firebase.
class RoomsBuilder extends StatelessWidget {
  /// Game to find rooms for.
  final Game game;

  /// Build widget that accesses the list of rooms.
  final Widget Function(BuildContext, List<FirebaseRoomData>) builder;

  /// Build widget when there is no data.
  final Widget Function(BuildContext)? loadingBuilder;

  /// Build widget when there is an error.
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const RoomsBuilder(
      {super.key,
      required this.game,
      required this.builder,
      this.loadingBuilder,
      this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseRoomCommunicator.getRooms(game),
        builder: (context, snapshot) {
          const placeholder = SizedBox.shrink();
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
          return builder(
              context,
              snapshot.data!.docs
                  .map((document) =>
                      FirebaseRoomData.fromDocument(document, game))
                  .toList());
        });
  }
}
