import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/multiplayer_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../providers/multiplayer_provider.dart';
import 'waiting_room_screen.dart';
import 'join_room_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _creating = false;

  Future<void> _createRoom() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _creating = true);
    try {
      final code = await MultiplayerService.instance.createLobby(
        hostId: user.uid,
        hostName: user.displayName,
        hostColorIndex: 0,
      );
      ref.read(multiplayerRoomProvider.notifier).setLocalPlayerId(user.uid);
      ref.read(multiplayerRoomProvider.notifier).setRoom(roomCode: code, isHost: true);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(roomCode: code, isHost: true),
        ),
      );
    } catch (e) {
      setState(() => _creating = false);
      if (!mounted) return;
      final message = e.toString();
      final looksPermissionDenied =
          message.toLowerCase().contains('permission') || message.toLowerCase().contains('denied');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(looksPermissionDenied ? 'Database permission denied' : 'Could not create room'),
          content: Text(
            looksPermissionDenied
                ? 'The Realtime Database rules are rejecting this write — '
                  'make sure you are signed in.'
                : 'Error: $message',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        title: const Text('Online Room'),
        backgroundColor: AppColors.appBg,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌐', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('Play With Friends',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Create a room and share the code, or join a room someone '
              'already started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _creating ? null : _createRoom,
                child: _creating
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Create Room',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinRoomScreen()),
                ),
                child: const Text('Join Room',
                    style: TextStyle(color: AppColors.secondary, fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}