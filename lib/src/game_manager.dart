import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:either_dart/either.dart';

import 'check_result.dart';
import 'event.dart';
import 'firebase_room_communicator.dart';
import 'firebase_room_data.dart';
import 'game.dart';
import 'game_event.dart';
import 'player.dart';
import 'room_data.dart';

/// Interface used to send events and read updates to the room and game state.
class GameManager {
  static final _gameManager =
      GameManager(player: Player(id: Random().nextInt(0xFFFFFFFF)));

  /// Device's player.
  final Player player;

  FirebaseRoomCommunicator? _firebaseRoomCommunicator;
  bool _joiningRoom = false;

  GameManager({required this.player});

  /// Get global device GameManager instance.
  static GameManager get instance => _gameManager;

  /// Get stream to read RoomData changes.
  Stream<RoomData> get roomDataStream {
    if (_firebaseRoomCommunicator == null) {
      throw Exception("A room has not been joined.");
    }
    return _firebaseRoomCommunicator!.roomDataStream;
  }

  /// Get currently assigned room's game.
  Game? get game => _firebaseRoomCommunicator?.room.game;

  /// Check if a room has been assigned.
  bool hasRoom() {
    return _firebaseRoomCommunicator != null;
  }

  /// Set player's name.
  void setPlayerName(String name) {
    player.name = name;
  }

  /// Get stream of rooms from Firebase.
  Stream<QuerySnapshot<Map<String, dynamic>>> getRooms(Game game) {
    return FirebaseRoomCommunicator.getRooms(game);
  }

  /// Create a new room and join it.
  Future<bool> createRoom(Game game, [String? password]) async {
    if (_firebaseRoomCommunicator != null || _joiningRoom) return false;
    _joiningRoom = true;
    _firebaseRoomCommunicator = await FirebaseRoomCommunicator.createRoom(
        game: game, player: player, password: password);
    _joiningRoom = false;
    return true;
  }

  /// Join a room from a Firebase room data object.
  Future<bool> joinRoom(FirebaseRoomData roomData, [String? password]) async {
    if (_firebaseRoomCommunicator != null || _joiningRoom) return false;
    _joiningRoom = true;
    _firebaseRoomCommunicator = await FirebaseRoomCommunicator.joinRoom(
        roomSnapshot: roomData.document,
        game: roomData.game,
        player: player,
        password: password);
    _joiningRoom = false;
    return _firebaseRoomCommunicator != null;
  }

  /// Leave current room.
  Future<void> leaveRoom() async {
    if (_firebaseRoomCommunicator == null) return;
    final firebaseCommunicator = _firebaseRoomCommunicator!;
    _firebaseRoomCommunicator = null;
    await firebaseCommunicator
        .leaveRoom(); // Use copy in case onLeave function specified by developer is faulty
  }

  /// Send event to be processed by the game rules. Takes a payload json as input and returns a result.
  Future<CheckResult> sendGameEvent(Map<String, dynamic> event) async {
    if (_firebaseRoomCommunicator == null) {
      throw Exception("A room has not been joined.");
    }
    return await _firebaseRoomCommunicator!.sendGameEvent(event);
  }

  /// Start a game. Can only be called by the host. Returns a result.
  Future<CheckResult> startGame() async {
    if (_firebaseRoomCommunicator == null) {
      throw Exception("A room has not been joined.");
    }
    return await _firebaseRoomCommunicator!.startGame();
  }

  /// Stop the current game. Can only be called by the host.
  Future<void> stopGame([Map<String, dynamic>? log]) async {
    if (_firebaseRoomCommunicator == null) return;
    await _firebaseRoomCommunicator!.stopGame(log);
  }

  Future<void> sendOtherEvent(Map<String, dynamic> payload) async {
    if (_firebaseRoomCommunicator == null) return;
    await _firebaseRoomCommunicator!.sendOtherEvent(payload);
  }

  /// Pass event function to be called when a player joins.
  void setOnPlayerJoin(void Function(Player) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnPlayerJoin(callback);
  }

  /// Pass event function to be called when a player leaves.
  void setOnPlayerLeave(void Function(Player) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnPlayerLeave(callback);
  }

  /// Pass event function to be called when you leave.
  void setOnLeave(void Function() callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnLeave(callback);
  }

  /// Pass event function to be called when a game event has been received.
  void setOnGameEvent<T extends GameState>(
      void Function(GameEvent, T) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameEvent(callback);
  }

  /// Pass event function to be called when an event fails.
  void setOnGameEventFailure(void Function(CheckResultFailure) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameEventFailure(callback);
  }

  /// Pass event function to be called when the game starts.
  void setOnGameStart<T extends GameState>(void Function(T) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameStart(callback);
  }

  /// Pass event function to be called when the game cannot be started.
  void setOnGameStartFailure(void Function(CheckResultFailure) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameStartFailure(callback);
  }

  /// Pass event function to be called when the game is stopped.
  void setOnGameStop(void Function(Map<String, dynamic>?) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameStop(callback);
  }

  /// Pass event function to be called when the host is reassigned.
  void setOnHostReassigned(void Function(Player, Player) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnHostReassigned(callback);
  }

  /// Pass event function to be called when an other event is received.
  void setOnOtherEvent(void Function(Event) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnOtherEvent(callback);
  }

  /// Return either a value or failure based on the given request.
  Either<CheckResultFailure, dynamic> getGameResponse(
      Map<String, dynamic> request) {
    if (_firebaseRoomCommunicator == null) {
      throw Exception("A room has not been joined.");
    }
    return _firebaseRoomCommunicator!.getGameResponse(request);
  }

  /// Pass event function to be called when get game response fails.
  void setOnGameResponseFailure(void Function(CheckResultFailure) callback) {
    if (_firebaseRoomCommunicator == null) return;
    _firebaseRoomCommunicator!.setOnGameResponseFailure(callback);
  }
}
