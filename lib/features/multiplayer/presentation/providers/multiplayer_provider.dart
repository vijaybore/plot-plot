import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/multiplayer_service.dart';
import '../../domain/models/chat_message_model.dart';

class MultiplayerRoomInfo {
  final String? roomCode;
  final bool isHost;
  final String localPlayerId;

  const MultiplayerRoomInfo({
    this.roomCode,
    this.isHost = false,
    required this.localPlayerId,
  });

  bool get isOnline => roomCode != null;

  MultiplayerRoomInfo copyWith({String? roomCode, bool? isHost, String? localPlayerId}) =>
      MultiplayerRoomInfo(
        roomCode: roomCode ?? this.roomCode,
        isHost: isHost ?? this.isHost,
        localPlayerId: localPlayerId ?? this.localPlayerId,
      );
}

class MultiplayerRoomNotifier extends StateNotifier<MultiplayerRoomInfo> {
  MultiplayerRoomNotifier() : super(const MultiplayerRoomInfo(localPlayerId: ''));

  void setLocalPlayerId(String id) => state = state.copyWith(localPlayerId: id);

  void setRoom({required String roomCode, required bool isHost}) =>
      state = state.copyWith(roomCode: roomCode, isHost: isHost);

  void leaveRoom() =>
      state = MultiplayerRoomInfo(localPlayerId: state.localPlayerId);
}

final multiplayerRoomProvider =
    StateNotifierProvider<MultiplayerRoomNotifier, MultiplayerRoomInfo>(
        (ref) => MultiplayerRoomNotifier());

/// Live chat stream for the current room. Empty stream when not in a room.
final chatMessagesProvider = StreamProvider<List<ChatMessageModel>>((ref) {
  final room = ref.watch(multiplayerRoomProvider);
  if (room.roomCode == null) return const Stream<List<ChatMessageModel>>.empty();
  return MultiplayerService.instance.watchChat(room.roomCode!);
});