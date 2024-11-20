import 'package:cloud_firestore/cloud_firestore.dart';

import 'player.dart';

/// Game event info.
class GameEvent {
  /// Timestamp of when the event was received.
  final Timestamp timestamp;

  /// Player that sent the event.
  final Player author;

  /// Data contained within the event.
  final Map<String, dynamic> payload;

  const GameEvent(
      {required this.timestamp, required this.author, required this.payload});

  dynamic operator [](String key) {
    return payload[key];
  }
}
