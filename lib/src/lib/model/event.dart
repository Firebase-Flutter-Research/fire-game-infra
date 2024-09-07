import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fire_engine/model/player.dart';

class Event {
  final Timestamp timestamp;
  final Player author;
  final Map<String, dynamic> payload;

  const Event(
      {required this.timestamp, required this.author, required this.payload});

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp,
        "author": author,
        "payload": payload,
      };

  static Event fromJson(Map<String, dynamic> json) => Event(
      timestamp: json["timestamp"],
      author: Player.fromJson(json["author"]),
      payload: json["payload"]);
}
