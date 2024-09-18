import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';

class NotRoomHost extends CheckResultFailure {
  const NotRoomHost() : super("Player is not the room's host");
}

class FirebaseRoomCommunicator {
  static const _collectionPrefix = "Rooms";
  static const _eventsCollectionName = "Events";
  static const _eventLimit = 100;

  late Game game;
  late Player player;
  late DocumentReference<Map<String, dynamic>> roomReference;
  late Room room;

  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _eventStreamSubscription;
  late Completer<void> _joinRoomResponse;
  late StreamController<RoomData> _roomDataStreamController;
  bool _readingLiveEvents = false;
  int? _pendingEventId;

  void Function(Player)? _onPlayerJoin;
  void Function(Player)? _onPlayerLeave;
  void Function()? _onLeave;
  void Function(GameEvent)? _onGameEvent;
  void Function(CheckResultFailure)? _onGameEventFailure;
  void Function()? _onGameStart;
  void Function(CheckResultFailure)? _onGameStartFailure;
  void Function(Map<String, dynamic>?)? _onGameStop;
  void Function(Player, Player)? _onHostReassigned;
  void Function(Event)? _onOtherEvent;

  DocumentReference<Map<String, dynamic>>? _concatenatedEventReference;

  FirebaseRoomCommunicator(
      this.game, this.player, this.roomReference, this.room) {
    _joinRoomResponse = Completer();
    _roomDataStreamController = StreamController<RoomData>();

    _eventStreamSubscription = roomReference
        .collection(_eventsCollectionName)
        .snapshots(
            includeMetadataChanges: !game.ignoreSimultaneousEventOrdering)
        .listen((eventSnapshots) async {
      _updateConcatenatedEventReference(eventSnapshots.docs);

      final filteredDocs = eventSnapshots.docs.where((e) =>
          !e.metadata.hasPendingWrites || game.ignoreSimultaneousEventOrdering);
      final events =
          _fromConcatenatedEvents(filteredDocs.map((e) => e.data()).toList());
      final filteredEvents = events
          .toSet()
          .difference(room.events.toSet())
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (final event in filteredEvents) {
        _processEvent(event);
      }

      room.events.addAll(filteredEvents);
      _roomDataStreamController.add(room.getRoomData());
      _readingLiveEvents = true;
    });
  }

  static String getRoomCollectionName(Game game) =>
      "$_collectionPrefix:${game.name}";

  static Stream<QuerySnapshot<Map<String, dynamic>>> getRooms(Game game) {
    return FirebaseFirestore.instance
        .collection(getRoomCollectionName(game))
        .snapshots();
  }

  static Future<FirebaseRoomCommunicator> createRoom(
      {required Game game, required Player player}) async {
    final firebaseRoomCommunicator = FirebaseRoomCommunicator(
        game,
        player,
        await FirebaseFirestore.instance
            .collection(getRoomCollectionName(game))
            .add({
          "host": player.toJson(),
          "playerCount": 0,
          "gameStarted": false
        }),
        Room.createRoom(game: game, host: player));
    await firebaseRoomCommunicator
        ._sendEvent(EventType.playerJoin, {"player": player.toJson()});
    await firebaseRoomCommunicator.roomReference
        .update({"playerCount": FieldValue.increment(1)});
    await firebaseRoomCommunicator._joinRoomResponse.future;
    return firebaseRoomCommunicator;
  }

  static Future<FirebaseRoomCommunicator?> joinRoom(
      {required DocumentSnapshot<Map<String, dynamic>> roomSnapshot,
      required Game game,
      required Player player}) async {
    if (roomSnapshot["playerCount"] >= game.playerLimit ||
        roomSnapshot["gameStarted"] ||
        !roomSnapshot.exists) return null;
    final firebaseRoomCommunicator = FirebaseRoomCommunicator(
        game,
        player,
        roomSnapshot.reference,
        Room.createRoom(
            game: game, host: Player.fromJson(roomSnapshot["host"])));
    final docs =
        (await roomSnapshot.reference.collection(_eventsCollectionName).get())
            .docs;
    firebaseRoomCommunicator._updateConcatenatedEventReference(docs);
    await firebaseRoomCommunicator
        ._sendEvent(EventType.playerJoin, {"player": player.toJson()});
    await firebaseRoomCommunicator.roomReference
        .update({"playerCount": FieldValue.increment(1)});
    await firebaseRoomCommunicator._joinRoomResponse.future;
    return firebaseRoomCommunicator;
  }

  Stream<RoomData> get roomDataStream => _roomDataStreamController.stream;

  Future<void> leaveRoom() async {
    room.leaveRoom(player);

    if ((await roomReference.get()).exists) {
      await _sendEvent(EventType.playerLeave);
      await roomReference.update({"playerCount": FieldValue.increment(-1)});

      if (room.players.isNotEmpty) {
        if (room.host == player) {
          await _sendEvent(EventType.hostReassigned,
              {"player": room.players.first.toJson()});
          await roomReference.update({"host": room.players.first.toJson()});
        }
      } else {
        await _deleteRoom(roomReference);
      }
    }

    if (_onLeave != null && _readingLiveEvents) _onLeave!();

    _eventStreamSubscription.cancel();
  }

  Future<void> _deleteRoom(
      DocumentReference<Map<String, dynamic>> reference) async {
    final events = await reference.collection(_eventsCollectionName).get();
    for (var event in events.docs) {
      await event.reference.delete();
    }
    await reference.delete();
  }

  Future<CheckResult> sendGameEvent(Map<String, dynamic> event) async {
    final checkResult = room.checkPerformEvent(event: event, player: player);
    if (checkResult is CheckResultFailure) {
      if (_onGameEventFailure != null && _readingLiveEvents) {
        _onGameEventFailure!(checkResult);
      }
      return checkResult;
    }
    await _sendEvent(EventType.gameEvent, event);
    return checkResult;
  }

  Future<CheckResult> startGame() async {
    if (player != room.host) return const NotRoomHost();
    final checkResult = room.startGame(room.players);
    if (checkResult is CheckResultFailure) {
      if (_onGameStartFailure != null && _readingLiveEvents) {
        _onGameStartFailure!(checkResult);
      }
      return checkResult;
    }
    await _sendEvent(EventType.gameStart,
        {"players": room.players.map((p) => p.toJson()).toList()});
    return checkResult;
  }

  Future<void> stopGame([Map<String, dynamic>? log]) async {
    if (player != room.host) return;
    if (!room.gameStarted) return;
    await _sendEvent(EventType.gameStop, log);
  }

  Future<void> sendOtherEvent(Map<String, dynamic> payload) async {
    await _sendEvent(EventType.other, payload);
  }

  Future<DocumentReference<Map<String, dynamic>>>
      _createConcatenatedEvent() async {
    return roomReference.collection(_eventsCollectionName).add({"events": []});
  }

  List<Event> _fromConcatenatedEvents(
      List<Map<String, dynamic>> concatenatedEvents) {
    return concatenatedEvents
        .expand((concatEvent) =>
            List<Map<String, dynamic>>.from(concatEvent["events"])
                .map((event) => Event.fromJson(event)))
        .toList();
  }

  DocumentReference<Map<String, dynamic>>? _findCurrentConcatenation(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    for (var doc in docs) {
      if (doc.data()["events"].length < _eventLimit) {
        return doc.reference;
      }
    }
    return null;
  }

  void _updateConcatenatedEventReference(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    _concatenatedEventReference = _findCurrentConcatenation(docs);
  }

  Future<void> _sendEvent(EventType type,
      [Map<String, dynamic>? payload]) async {
    if (_pendingEventId != null) return;
    _pendingEventId = Random().nextInt(0xFFFFFFFF);
    _concatenatedEventReference ??= await _createConcatenatedEvent();
    await _concatenatedEventReference!.update({
      "events": FieldValue.arrayUnion([
        Event(
                id: _pendingEventId!,
                type: type,
                timestamp: Timestamp.now(),
                author: player,
                payload: payload)
            .toJson()
      ])
    });
  }

  void _processEvent(Event event) {
    if (_pendingEventId == event.id) {
      _pendingEventId = null;
    }
    switch (event.type) {
      case EventType.gameEvent:
        return _processGameEvent(GameEvent(
            timestamp: event.timestamp,
            author: event.author,
            payload: event.payload!));
      case EventType.playerJoin:
        return _processPlayerJoinEvent(event.author);
      case EventType.playerLeave:
        return _processPlayerLeaveEvent(event.author);
      case EventType.gameStart:
        return _processGameStartEvent(event.payload!["players"]
            .map((p) => Player.fromJson(p))
            .toList()
            .cast<Player>());
      case EventType.gameStop:
        return _processGameStopEvent(event.payload);
      case EventType.hostReassigned:
        return _processHostReassignedEvent(
            Player.fromJson(event.payload!["player"]), event.author);
      case EventType.other:
        return _processOtherEvent(event);
    }
  }

  void _processGameEvent(GameEvent event) async {
    room.processEvent(event);
    if (_onGameEvent != null && _readingLiveEvents) {
      _onGameEvent!(event);
    }
    final log = room.checkGameEnd();
    if (log != null) {
      await stopGame(log);
    }
  }

  void _processPlayerJoinEvent(Player player) async {
    room.joinRoom(player);
    if (_onPlayerJoin != null && this.player != player && _readingLiveEvents) {
      _onPlayerJoin!(player);
    }
    if (this.player == player && !_joinRoomResponse.isCompleted) {
      _joinRoomResponse.complete();
    }
  }

  void _processPlayerLeaveEvent(Player player) async {
    room.leaveRoom(player);
    if (_readingLiveEvents && this.player != player) {
      if (_onPlayerLeave != null) _onPlayerLeave!(player);
    }
    if (room.gameStarted && (!room.hasRequiredPlayers || room.isOvercapacity)) {
      await stopGame();
    }
  }

  void _processGameStartEvent(List<Player> players) async {
    if (room.startGame(players) is CheckResultSuccess) {
      if (_onGameStart != null && _readingLiveEvents) _onGameStart!();
    }
  }

  void _processGameStopEvent(Map<String, dynamic>? log) async {
    if (room.stopGame()) {
      if (_onGameStop != null && _readingLiveEvents) _onGameStop!(log);
    }
  }

  void _processHostReassignedEvent(Player newHost, Player oldHost) async {
    room.host = newHost;
    if (player != oldHost && _onHostReassigned != null && _readingLiveEvents) {
      _onHostReassigned!(newHost, oldHost);
    }
  }

  void _processOtherEvent(Event event) async {
    if (_readingLiveEvents && _onOtherEvent != null) _onOtherEvent!(event);
  }

  void setOnPlayerJoin(void Function(Player) callback) {
    _onPlayerJoin = callback;
  }

  void setOnPlayerLeave(void Function(Player) callback) {
    _onPlayerLeave = callback;
  }

  void setOnLeave(void Function() callback) {
    _onLeave = callback;
  }

  void setOnGameEvent(void Function(GameEvent) callback) {
    _onGameEvent = callback;
  }

  void setOnGameEventFailure(void Function(CheckResultFailure) callback) {
    _onGameEventFailure = callback;
  }

  void setOnGameStart(void Function() callback) {
    _onGameStart = callback;
  }

  void setOnGameStartFailure(void Function(CheckResultFailure) callback) {
    _onGameStartFailure = callback;
  }

  void setOnGameStop(void Function(Map<String, dynamic>?) callback) {
    _onGameStop = callback;
  }

  void setOnHostReassigned(void Function(Player, Player) callback) {
    _onHostReassigned = callback;
  }

  void setOnOtherEvent(void Function(Event) callback) {
    _onOtherEvent = callback;
  }
}
