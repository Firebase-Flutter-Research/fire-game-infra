import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/firebase_room_communicator.dart';
import 'package:flutter_fire_engine/model/firebase_room_data.dart';
import 'package:flutter_fire_engine/model/game.dart';

class RoomsBuilder extends StatelessWidget {
  final Game game;
  final Widget Function(BuildContext, List<FirebaseRoomData>) builder;
  final Widget Function(BuildContext)? loadingBuilder;
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
