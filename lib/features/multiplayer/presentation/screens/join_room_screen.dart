import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/multiplayer_service.dart';
import '../../../game/domain/models/game_state_model.dart';
import '../../../game/presentation/providers/game_provider.dart';
import '../../../game/presentation/screens/game_screen.dart';
import '../providers/multiplayer_provider.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  GameStateModel? _foundState;
  String? _foundCode;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupRoom() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _loading = true; _error = null; });

    final exists = await MultiplayerService.instance.roomExists(code);
    if (!exists) {
      setState(() { _loading = false; _error = 'No room found with that code.'; });
      return;
    }
    // One-time read of the current state to show the player-slot picker.
    final state = await MultiplayerService.instance.watchState(code).first;
    setState(() {
      _loading = false;
      _foundCode = code;
      _foundState = state;
      if (state == null) _error = "Room exists but hasn't started yet — try again shortly.";
    });
  }

  void _joinAsPlayer(String playerId) {
    ref.read(multiplayerRoomProvider.notifier)
        .setLocalPlayerId(playerId);
    ref.read(multiplayerRoomProvider.notifier)
        .setRoom(roomCode: _foundCode!, isHost: false);
    ref.read(gameProvider.notifier).initGame(_foundState!);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
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
                onPressed: _loading ? null : _lookupRoom,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Find Room'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            if (_foundState != null) ...[
              const SizedBox(height: 24),
              const Text('Who are you at the table?',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ..._foundState!.players.map((p) => Card(
                color: AppColors.appCard,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: p.color,
                      child: Text(p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white))),
                  title: Text(p.displayName, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  onTap: () => _joinAsPlayer(p.id),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}