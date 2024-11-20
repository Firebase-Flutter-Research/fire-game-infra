import 'package:cloud_firestore/cloud_firestore.dart';

import 'game.dart';
import 'player.dart';

/// Representation of Firebase room document.
class FirebaseRoomData {
  /// Game being played.
  final Game game;

  /// Player that owns the room.
  final Player host;

  /// Number of players within the room.
  final int playerCount;

  /// Whether the game has begun or not.
  final bool gameStarted;

  /// Timestamp of the last event sent.
  final Timestamp lastUpdateTimestamp;

  /// Password to access the room.
  final String? password;

  /// Original Firebase document.
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
