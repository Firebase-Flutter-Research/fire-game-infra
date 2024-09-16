import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/firebase_room_communicator.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';

class GameManager {
  static final _gameManager =
      GameManager(player: Player(id: Random().nextInt(0xFFFFFFFF)));

  final Player player;

  Game? _game;
  FirebaseRoomCommunicator? _firebaseRoomCommunicator;
  bool _joiningRoom = false;

  GameManager({required this.player});

  // Get global device GameManager instance.
  static GameManager get instance => _gameManager;

  // Get stream to read RoomData changes.
  Stream<RoomData> get roomDataStream {
    if (_firebaseRoomCommunicator == null) {
      throw Exception("A room has not been joined.");
    }
    return _firebaseRoomCommunicator!.roomDataStream;
  }

  // Get currently assigned game.
  Game? get game => _game;

  // Assign game.
  void setGame(Game game) {
    _game = game;
  }

  // Check if a game has been assigned.
  bool hasGame() {
    return _game != null;
  }

  // Set player's name.
  void setPlayerName(String name) {
    player.name = name;
  }

  // Get stream of rooms from Firebase.
  Stream<QuerySnapshot<Map<String, dynamic>>> getRooms() {
    if (_game == null) throw Exception("Game has not been set");
    return FirebaseRoomCommunicator.getRooms(_game!);
  }

  // Create a new room and join it.
  Future<bool> createRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_firebaseRoomCommunicator != null || _joiningRoom) return false;
    _joiningRoom = true;
    _firebaseRoomCommunicator =
        await FirebaseRoomCommunicator.createRoom(game: game!, player: player);
    _joiningRoom = false;
    return true;
  }

  // Join a room from a Firebase document snapshot.
  Future<bool> joinRoom(
      DocumentSnapshot<Map<String, dynamic>> roomSnapshot) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_firebaseRoomCommunicator != null || _joiningRoom) return false;
    _joiningRoom = true;
    _firebaseRoomCommunicator = await FirebaseRoomCommunicator.joinRoom(
        roomSnapshot: roomSnapshot, game: game!, player: player);
    _joiningRoom = false;
    return _firebaseRoomCommunicator != null;
  }

  // Leave current room.
  Future<void> leaveRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_firebaseRoomCommunicator == null) return;
    final firebaseCommunicator = _firebaseRoomCommunicator!;
    _firebaseRoomCommunicator = null;
    await firebaseCommunicator
        .leaveRoom(); // Use copy in case onLeave function specified by developer is faulty
  }

  // Send event to be processed by the game rules. Takes a payload json as input and returns a result.
  Future<CheckResult> sendGameEvent(Map<String, dynamic> event) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_firebaseRoomCommunicator == null) {
      throw Exception("A room has not been joined.");
    }
    return await _firebaseRoomCommunicator!.sendGameEvent(event);
  }

  // Start a game. Can only be called by the host. Returns a result.
  Future<CheckResult> startGame() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_firebaseRoomCommunicator == null) {
      throw Exception("A room has not been joined.");
    }
    return await _firebaseRoomCommunicator!.startGame();
  }

  // Stop the current game. Can only be called by the host.
  Future<void> stopGame([Map<String, dynamic>? log]) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_firebaseRoomCommunicator == null) return;
    await _firebaseRoomCommunicator!.stopGame(log);
  }

  // Pass event function to be called when a player joins.
  void setOnPlayerJoin(void Function(Player) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnPlayerJoin(callback);
  }

  // Pass event function to be called when a player leaves.
  void setOnPlayerLeave(void Function(Player) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnPlayerLeave(callback);
  }

  // Pass event function to be called when you leave.
  void setOnLeave(void Function() callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnLeave(callback);
  }

  // Pass event function to be called when a game event has been received.
  void setOnGameEvent(void Function(GameEvent) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameEvent(callback);
  }

  // Pass event function to be called when an event fails.
  void setOnGameEventFailure(void Function(CheckResultFailure) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameEventFailure(callback);
  }

  // Pass event function to be called when the game starts.
  void setOnGameStart(void Function() callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameStart(callback);
  }

  // Pass event function to be called when the game cannot be started.
  void setOnGameStartFailure(void Function(CheckResultFailure) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameStartFailure(callback);
  }

  // Pass event function to be called when the game is stopped.
  void setOnGameStop(void Function(Map<String, dynamic>?) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameStop(callback);
  }

  // Pass event function to be called when the host is reassigned.
  void setOnHostReassigned(void Function(Player, Player) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnHostReassigned(callback);
  }
}
