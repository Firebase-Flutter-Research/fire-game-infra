import 'package:cloud_firestore/cloud_firestore.dart';

import 'game.dart';
import 'player.dart';

class FirebaseRoomData {
  final Game game;
  final Player host;
  final int playerCount;
  final bool gameStarted;
  final Timestamp lastUpdateTimestamp;
  final String? password;
  final DocumentSnapshot<Map<String, dynamic>> document;

  const FirebaseRoomData(
      {required this.game,
      required this.host,
      required this.playerCount,
      required this.gameStarted,
      required this.lastUpdateTimestamp,
      required this.password,
      required this.document});

  static FirebaseRoomData fromDocument(
          DocumentSnapshot<Map<String, dynamic>> document, Game game) =>
      FirebaseRoomData(
          game: game,
          host: Player.fromJson(document["host"]),
          playerCount: document["playerCount"],
          gameStarted: document["gameStarted"],
          lastUpdateTimestamp:
              document["lastUpdateTimestamp"] ?? Timestamp.now(),
          password: document["password"],
          document: document);
}
