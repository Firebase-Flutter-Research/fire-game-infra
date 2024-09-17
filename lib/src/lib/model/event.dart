import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fire_engine/model/player.dart';

enum EventType {
  gameEvent(key: "gameEvent"),
  playerJoin(key: "playerJoin"),
  playerLeave(key: "playerLeave"),
  gameStart(key: "gameStart"),
  gameStop(key: "gameStop"),
  hostReassigned(key: "hostReassigned"),
  other(key: "other");

  final String key;

  const EventType({required this.key});

  static EventType fromKey(String key) =>
      EventType.values.where((e) => e.key == key).first;
}

class GameEvent {
  final Timestamp timestamp;
  final Player author;
  final Map<String, dynamic> payload;

  const GameEvent(
      {required this.timestamp, required this.author, required this.payload});
}

class Event {
  final int id;
  final EventType type;
  final Timestamp timestamp;
  final Player author;
  final Map<String, dynamic>? payload;

  const Event(
      {required this.id,
      required this.type,
      required this.timestamp,
      required this.author,
      required this.payload});

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type.key,
        "timestamp": timestamp,
        "author": author.toJson(),
        "payload": payload,
      };

  static Event fromJson(Map<String, dynamic> json) => Event(
        id: json["id"],
        type: EventType.fromKey(json["type"]),
        timestamp: json["timestamp"],
        author: Player.fromJson(json["author"]),
        payload: json["payload"],
      );

  @override
  bool operator ==(Object other) {
    return other is Event && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
