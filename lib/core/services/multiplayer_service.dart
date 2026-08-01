import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../../features/game/domain/models/game_state_model.dart';
import '../../features/multiplayer/domain/models/chat_message_model.dart';
import '../../features/multiplayer/domain/models/lobby_player_model.dart';
import '../utils/room_code_generator.dart';

/// Firebase Realtime Database tree:
///
///   /rooms/{code}/meta      -> { hostId, createdAt, status }
///   /rooms/{code}/lobby/{playerId} -> { name, colorIndex, joinedAt }
///   /rooms/{code}/state     -> full GameStateModel.toMap()
///   /rooms/{code}/chat/{id} -> ChatMessageModel.toMap()
///   /rooms/{code}/intents/{id} -> { action, playerId, args, timestamp }
///
/// meta/status is 'waiting' from the moment the host creates the room —
/// before /state exists at all — through however long it takes players to
/// join via /lobby. The host flips it to 'active' (and writes /state) only
/// once they tap Start; every waiting guest is watching that field and
/// transitions into the game the instant it changes.
///
/// Architecture: host-authoritative. One device (the host) runs the real
/// game logic (GameNotifier, unchanged) and pushes the resulting state here
/// after every change. Every other device only ever reads /state and
/// renders it — they never mutate game rules locally. When a non-host
/// player taps something (roll dice, buy, bank action…), that's written as
/// an "intent" instead; the host listens for intents, applies them through
/// the normal GameNotifier methods, and the resulting state broadcast is
/// what every device (including the host's own screen) actually renders.
/// This means the entire existing rules engine (game_provider.dart) needed
/// zero changes to go multiplayer.
class MultiplayerService {
  MultiplayerService._();
  static final MultiplayerService instance = MultiplayerService._();

  DatabaseReference get _root => FirebaseDatabase.instance.ref('rooms');

  // ── Room lifecycle ─────────────────────────────────────────────────
  /// Creates a new room with a fresh, unused code and writes the initial
  /// game state. Returns the room code players will share to join.
  Future<String> createRoom({
    required GameStateModel initialState,
    required String hostId,
  }) async {
    String code = RoomCodeGenerator.generate();
    // Extremely unlikely to collide (32^6 possibilities), but guard anyway.
    while ((await _root.child(code).get()).exists) {
      code = RoomCodeGenerator.generate();
    }
    await _root.child(code).set({
      'meta': {
        'hostId': hostId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'status': 'waiting',
      },
      'state': initialState.toMap(),
    });
    return code;
  }

  // ── Waiting lobby (before the game actually starts) ────────────────
  /// Creates a room in the 'waiting' state with no /state yet — just the
  /// host present in /lobby. Returns the room code to share.
  Future<String> createLobby({
    required String hostId,
    required String hostName,
    required int hostColorIndex,
  }) async {
    String code = RoomCodeGenerator.generate();
    while ((await _root.child(code).get()).exists) {
      code = RoomCodeGenerator.generate();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await _root.child(code).set({
      'meta': {
        'hostId': hostId,
        'createdAt': now,
        'status': 'waiting',
      },
      'lobby': {
        hostId: {'name': hostName, 'colorIndex': hostColorIndex, 'joinedAt': now},
      },
    });
    return code;
  }

  /// A guest joins an existing waiting-room lobby.
  Future<void> joinLobby(String code, LobbyPlayerModel player) =>
      _root.child(code.toUpperCase()).child('lobby').child(player.id).set(player.toMap());

  /// A player leaves the lobby before the game has started (e.g. backs out).
  Future<void> leaveLobby(String code, String playerId) =>
      _root.child(code.toUpperCase()).child('lobby/$playerId').remove();

  /// Live list of everyone currently in the waiting room, oldest join first.
  Stream<List<LobbyPlayerModel>> watchLobby(String code) {
    return _root.child(code.toUpperCase()).child('lobby').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <LobbyPlayerModel>[];
      final map = _deepMap(raw);
      final players = map.entries
          .map((e) => LobbyPlayerModel.fromMap(e.key, _deepMap(e.value)))
          .toList();
      players.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
      return players;
    });
  }

  /// 'waiting' while the lobby is filling, 'active' once the host starts.
  /// Guests watch this to know the instant they should jump into the game.
  Stream<String?> watchStatus(String code) {
    return _root.child(code.toUpperCase()).child('meta/status').onValue.map(
          (event) => event.snapshot.value as String?,
        );
  }

  /// Host-only: writes the real game state built from the joined lobby
  /// players and flips status to 'active', releasing every waiting guest.
  Future<void> startGameFromLobby(String code, GameStateModel state) async {
    final ref = _root.child(code.toUpperCase());
    await ref.child('state').set(state.toMap());
    await ref.child('meta/status').set('active');
  }

  Future<bool> roomExists(String code) async {
    final snap = await _root.child(code.toUpperCase()).child('meta').get();
    return snap.exists;
  }

  Future<String?> hostIdOf(String code) async {
    final snap = await _root.child(code.toUpperCase()).child('meta/hostId').get();
    return snap.value as String?;
  }

  /// Deletes the room entirely — call when the host ends/exits the match.
  Future<void> closeRoom(String code) => _root.child(code.toUpperCase()).remove();

  // ── Game state sync ──────────────────────────────────────────────
  Future<void> pushState(String code, GameStateModel state) =>
      _root.child(code.toUpperCase()).child('state').set(state.toMap());

  Stream<GameStateModel?> watchState(String code) {
    return _root.child(code.toUpperCase()).child('state').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return null;
      return GameStateModel.fromMap(_deepMap(raw));
    });
  }

  // ── Chat ──────────────────────────────────────────────────────────
  Future<void> sendChatMessage(String code, ChatMessageModel msg) =>
      _root.child(code.toUpperCase()).child('chat').push().set(msg.toMap());

  Stream<List<ChatMessageModel>> watchChat(String code) {
    return _root.child(code.toUpperCase()).child('chat').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <ChatMessageModel>[];
      final map = _deepMap(raw);
      final messages = map.values
          .map((v) => ChatMessageModel.fromMap(_deepMap(v)))
          .toList();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // ── Player intents (non-host actions) ───────────────────────────
  /// A non-host player calls this instead of touching the game notifier
  /// directly. [action] matches a GameNotifier method name (e.g.
  /// 'rollDice', 'buyProperty', 'endTurn', 'depositToBank'…) and [args]
  /// carries whatever that method needs.
  Future<void> sendIntent(
    String code,
    String action,
    String playerId,
    Map<String, dynamic> args,
  ) =>
      _root.child(code.toUpperCase()).child('intents').push().set({
        'action': action,
        'playerId': playerId,
        'args': args,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

  /// Host-side only: listens for new intents as they arrive. The host
  /// removes each intent immediately after handling it so it's never
  /// re-applied on reconnect.
  StreamSubscription<DatabaseEvent> listenForIntents(
    String code,
    void Function(String action, String playerId, Map<String, dynamic> args) onIntent,
  ) {
    final ref = _root.child(code.toUpperCase()).child('intents');
    return ref.onChildAdded.listen((event) {
      final raw = event.snapshot.value;
      if (raw == null) return;
      final map = _deepMap(raw);
      onIntent(
        map['action'] as String? ?? '',
        map['playerId'] as String? ?? '',
        _deepMap(map['args'] ?? {}),
      );
      // Consumed — remove so it isn't replayed.
      event.snapshot.ref.remove();
    });
  }

  // Firebase RTDB returns nested LinkedHashMap<Object?, Object?> (not
  // Map<String, dynamic>), so every level needs recursive re-keying before
  // it can be handed to the model .fromMap() constructors.
  Map<String, dynamic> _deepMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), _deepValue(v)));
    }
    return <String, dynamic>{};
  }

  dynamic _deepValue(dynamic v) {
    if (v is Map) return _deepMap(v);
    if (v is List) return v.map(_deepValue).toList();
    return v;
  }
}