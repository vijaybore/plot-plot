import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../../features/game/domain/models/game_state_model.dart';
import '../../features/multiplayer/domain/models/chat_message_model.dart';
import '../utils/room_code_generator.dart';

/// Firebase Realtime Database tree:
///
///   /rooms/{code}/meta      -> { hostId, createdAt, status }
///   /rooms/{code}/state     -> full GameStateModel.toMap()
///   /rooms/{code}/chat/{id} -> ChatMessageModel.toMap()
///   /rooms/{code}/intents/{id} -> { action, playerId, args, timestamp }
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