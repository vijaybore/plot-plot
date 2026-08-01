import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/multiplayer_service.dart';
import '../../../game/domain/models/player_model.dart';
import '../../../game/domain/models/game_state_model.dart';
import '../../../game/presentation/providers/game_provider.dart';
import '../../../game/presentation/screens/game_screen.dart';
import '../../../game/presentation/screens/setup_game_screen.dart' show TileBuilder;
import '../../domain/models/lobby_player_model.dart';
import '../providers/multiplayer_provider.dart';

/// Shown to everyone from the moment a room is created until the host taps
/// Start. The host sees live-updating player names as people join plus the
/// match config controls; guests just watch the same player list and wait
/// for the host to start — no manual name entry or slot-claiming needed.
class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final bool isHost;
  const WaitingRoomScreen({super.key, required this.roomCode, required this.isHost});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  int _boardSize = 25;
  int _endRounds = 5;
  bool _enableFarms = true;
  bool _enableSurprise = true;
  bool _enableLuckyWheel = true;
  bool _enableTax = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isHost) _watchForStart();
  }

  /// Guests don't have a Start button — they just wait for meta/status to
  /// flip to 'active', then read the state the host just wrote and jump in.
  void _watchForStart() {
    MultiplayerService.instance.watchStatus(widget.roomCode).listen((status) async {
      if (status != 'active' || !mounted) return;
      final state = await MultiplayerService.instance.watchState(widget.roomCode).first;
      if (state == null || !mounted) return;
      final localId = ref.read(multiplayerRoomProvider).localPlayerId;
      ref.read(gameProvider.notifier).initGame(state);
      ref.read(multiplayerRoomProvider.notifier).setLocalPlayerId(localId);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    });
  }

  Future<void> _startGame(List<LobbyPlayerModel> lobbyPlayers) async {
    setState(() => _starting = true);
    final tiles = TileBuilder.buildTiles(_boardSize);
    final totalPlotValue = tiles.fold<double>(
        0.0, (sum, t) => sum + ((t.isPurchasable && t.price != null) ? t.price! : 0.0));
    final startMoney = (totalPlotValue / lobbyPlayers.length).floorToDouble();

    final players = lobbyPlayers
        .map((lp) => PlayerModel(
              id: lp.id,
              displayName: lp.name,
              money: startMoney,
              colorIndex: lp.colorIndex,
            ))
        .toList();

    final gameState = GameStateModel(
      gameId: 'online_${DateTime.now().millisecondsSinceEpoch}',
      players: players,
      tiles: tiles,
      boardSize: _boardSize,
      finalRoundsTotal: _endRounds,
      isOnline: true,
      phase: GamePhase.playing,
    );

    try {
      await MultiplayerService.instance.startGameFromLobby(widget.roomCode, gameState);
      ref.read(gameProvider.notifier).initGame(gameState);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    } catch (e) {
      setState(() => _starting = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Could not start game'),
          content: Text('Error: $e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
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
      body: StreamBuilder<List<LobbyPlayerModel>>(
        stream: MultiplayerService.instance.watchLobby(widget.roomCode),
        builder: (context, snapshot) {
          final lobbyPlayers = snapshot.data ?? const <LobbyPlayerModel>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomCodeCard(),
                const SizedBox(height: 24),
                _sectionTitle('Players (${lobbyPlayers.length})'),
                _buildPlayerList(lobbyPlayers),
                if (widget.isHost) ...[
                  const SizedBox(height: 20),
                  _sectionTitle('Board Size'),
                  _buildBoardSizeSelector(),
                  const SizedBox(height: 20),
                  _sectionTitle('End Game After'),
                  _buildEndRoundSelector(),
                  const SizedBox(height: 20),
                  _sectionTitle('Game Features'),
                  _buildToggles(),
                  const SizedBox(height: 32),
                  _buildStartButton(lobbyPlayers),
                ] else ...[
                  const SizedBox(height: 32),
                  _buildWaitingForHost(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('Room Code',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.roomCode,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.secondary, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.roomCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room code copied')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Share this code with friends to join',
              style: TextStyle(color: AppColors.textHint, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List<LobbyPlayerModel> players) {
    if (players.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Waiting for players to join…',
            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      );
    }
    return Column(
      children: players.map((p) {
        final color = AppColors.playerColors[p.colorIndex % AppColors.playerColors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.appBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(p.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWaitingForHost() {
    return Column(
      children: const [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.secondary),
        ),
        SizedBox(height: 14),
        Text('Waiting for the host to start the game…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildStartButton(List<LobbyPlayerModel> lobbyPlayers) {
    final canStart = lobbyPlayers.length >= 2 && !_starting;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canStart ? () => _startGame(lobbyPlayers) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _starting
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                lobbyPlayers.length >= 2 ? 'START GAME' : 'Waiting for another player…',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _buildBoardSizeSelector() {
    return Row(
      children: [25, 40, 60, 100].map((size) {
        final selected = _boardSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _boardSize = size),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.appCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppColors.primary : AppColors.appBorder),
              ),
              child: Column(
                children: [
                  Text('$size',
                      style: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text('plots',
                      style: TextStyle(color: selected ? Colors.white70 : AppColors.textHint, fontSize: 11)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEndRoundSelector() {
    return Row(
      children: [3, 5, 10].map((r) {
        final selected = _endRounds == r;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _endRounds = r),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.secondary : AppColors.appCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppColors.secondary : AppColors.appBorder),
              ),
              child: Center(
                child: Text('$r Rounds',
                    style: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggles() {
    final toggles = [
      ('Farms & Businesses', _enableFarms, (bool v) => setState(() => _enableFarms = v)),
      ('Surprise Tiles', _enableSurprise, (bool v) => setState(() => _enableSurprise = v)),
      ('Lucky Wheel', _enableLuckyWheel, (bool v) => setState(() => _enableLuckyWheel = v)),
      ('Tax Tiles', _enableTax, (bool v) => setState(() => _enableTax = v)),
    ];
    return Column(
      children: toggles.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.appBorder),
          ),
          child: Row(
            children: [
              Text(t.$1, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              const Spacer(),
              Switch(
                value: t.$2,
                onChanged: t.$3,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.secondary,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}