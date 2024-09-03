import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';

class GameManager {
  static const _collectionPrefix = "Rooms";
  static const _playersCollectionName = "Players";
  static const _eventsCollectionName = "Events";
  static const _timestampName = "timestamp";
  static final _gameManager =
      GameManager(player: Player(id: Random().nextInt(0x80000000)));

  final Player player;
  var _roomDataStreamController = StreamController<RoomData>();

  Game? _game;
  Room? _room;
  DocumentReference<Map<String, dynamic>>? _reference;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _playersStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _eventsStream;
  Timestamp? _lastProcessedTimestamp;
  void Function(Map<String, dynamic>)? _onGameEnd;

  GameManager({required this.player});

  static GameManager get instance => _gameManager;

  String get collectionName => "$_collectionPrefix:${_game?.name}";

  Stream<RoomData> get roomDataStream => _roomDataStreamController.stream;
  DocumentReference<Map<String, dynamic>>? get reference => _reference;

  void setGame(Game game) {
    _game = game;
  }

  bool hasGame() {
    return _game != null;
  }

  void setPlayerName(String name) {
    player.name = name;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getRooms() {
    if (_game == null) throw Exception("Game has not been set");
    return FirebaseFirestore.instance.collection(collectionName).snapshots();
  }

  void callPlayerEvents(List<Player> updatedPlayers) {
    final oldPlayersSet = _room!.players.toSet();
    final updatedPlayersSet = updatedPlayers.toSet();
    final deletedPlayers = oldPlayersSet.difference(updatedPlayersSet);
    final newPlayers = updatedPlayersSet.difference(oldPlayersSet);
    final host = _room!.host;
    for (final player in deletedPlayers) {
      _game!.onPlayerLeave(
          player: player,
          gameState: _room!.gameState,
          players: updatedPlayers,
          host: host);
    }
    for (final player in newPlayers) {
      _game!.onPlayerJoin(
          player: player,
          gameState: _room!.gameState,
          players: updatedPlayers,
          host: host);
    }
  }

  void updateRoomData() {
    if (_room == null) throw Exception("Room not assigned");
    _roomDataStreamController.add(_room!.getRoomData());
  }

  void setupStreams() {
    if (_reference == null || _room == null) {
      throw Exception("Room reference not set");
    }
    _playersStream = _reference!.collection(_playersCollectionName).snapshots();
    _eventsStream = _reference!.collection(_eventsCollectionName).snapshots();
    _playersStream!.listen((playersSnapshot) {
      if (_reference == null) return;
      final players =
          playersSnapshot.docs.map((p) => Player.fromJson(p.data())).toList();
      callPlayerEvents(players);
      _room!.players = players;
      updateRoomData();
    });
    _eventsStream!.listen((eventsSnapshot) {
      if (_reference == null) return;
      final events = eventsSnapshot.docs.map((e) => e.data()).toList()
        ..sort((a, b) => a[_timestampName].compareTo(b[_timestampName]));
      final filteredEvents = events.where((e) =>
          e[_timestampName].compareTo(_lastProcessedTimestamp ??
              Timestamp.fromMillisecondsSinceEpoch(0)) >
          0);
      for (final event in filteredEvents) {
        _room!.processEvent(event);
      }
      _lastProcessedTimestamp = events.lastOrNull?[_timestampName];
      _room!.events = events;
      updateRoomData();
      final log = _room!.checkGameEnd();
      if (log != null) {
        // TODO: Add any other game end logic.
        if (_onGameEnd != null) _onGameEnd!(log);
      }
    });
  }

  Future<bool> createRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_reference != null) return false;
    _room = Room.createRoom(game: _game!, player: player);
    _reference = await FirebaseFirestore.instance
        .collection(collectionName)
        .add({"host": player.toJson()});
    setupStreams();
    await _reference!.collection(_playersCollectionName).add(player.toJson());
    updateRoomData();
    return true;
  }

  Future<bool> joinRoom(
      DocumentReference<Map<String, dynamic>> reference) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_reference != null) return false;
    final players = (await reference.collection(_playersCollectionName).get())
        .docs
        .map((e) => Player.fromJson(e.data()))
        .toList();
    if (players.contains(player)) return false;
    final room = (await reference.get()).data();
    if (room == null) return false;

    _room = Room.joinRoom(
        player: player,
        game: _game!,
        players: players,
        host: Player.fromJson(room["host"]),
        events: (await reference.collection(_eventsCollectionName).get())
            .docs
            .map((e) => e.data())
            .toList());
    _reference = reference;
    setupStreams();
    await _reference!.collection(_playersCollectionName).add(player.toJson());
    updateRoomData();
    return true;
  }

  Future<bool> leaveRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _reference == null) return false;
    final left = _room!.leaveRoom(player);
    if (!left) return false;
    final playerReference = (await _reference
            ?.collection(_playersCollectionName)
            .where('id', isEqualTo: player.id)
            .get())
        ?.docs
        .firstOrNull
        ?.reference;
    await playerReference?.delete();
    if (_room!.players.isEmpty) await deleteRoom(_reference!);
    _reference = null;
    _room = null;
    _createAndDisposeStream();
    return true;
  }

  Future<void> deleteRoom(
      DocumentReference<Map<String, dynamic>> reference) async {
    await reference.delete();
  }

  Future<Map<String, dynamic>?> performEvent(Map<String, dynamic> event) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _reference == null) throw Exception("Room not set.");
    final log = _room?.checkPerformEvent(event: event, player: player);
    if (log != null) return log;
    await _reference!
        .collection(_eventsCollectionName)
        .add(event..addAll({_timestampName: Timestamp.now()}));
    return null;
  }

  void setOnGameEnd(void Function(Map<String, dynamic>) callback) {
    _onGameEnd = callback;
  }

  void _createAndDisposeStream() {
    _roomDataStreamController.close();
    _roomDataStreamController = StreamController();
  }
}
