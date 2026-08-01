import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/multiplayer_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../domain/models/lobby_player_model.dart';
import '../providers/multiplayer_provider.dart';
import 'waiting_room_screen.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() { _loading = true; _error = null; });

    final exists = await MultiplayerService.instance.roomExists(code);
    if (!exists) {
      setState(() { _loading = false; _error = 'No room found with that code.'; });
      return;
    }

    // Pick the next free colour based on how many are already in the lobby.
    final currentLobby = await MultiplayerService.instance.watchLobby(code).first;
    final colorIndex = currentLobby.length % AppColors.playerColors.length;

    try {
      await MultiplayerService.instance.joinLobby(
        code,
        LobbyPlayerModel(
          id: user.uid,
          name: user.displayName,
          colorIndex: colorIndex,
          joinedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      ref.read(multiplayerRoomProvider.notifier).setLocalPlayerId(user.uid);
      ref.read(multiplayerRoomProvider.notifier).setRoom(roomCode: code, isHost: false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(roomCode: code, isHost: false),
        ),
      );
    } catch (e) {
      setState(() { _loading = false; _error = 'Could not join room: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(title: const Text('Join Room'), backgroundColor: AppColors.appBg),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w900, letterSpacing: 4),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'ROOM CODE',
                hintStyle: TextStyle(letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _joinRoom,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Join Room'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }
}