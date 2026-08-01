import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../features/game/domain/models/player_model.dart';
import '../../../../features/game/domain/models/tile_model.dart';
import '../../../../features/game/domain/models/game_state_model.dart';
import 'game_screen.dart';
import '../providers/game_provider.dart';
import '../../../multiplayer/presentation/providers/multiplayer_provider.dart';
import '../../../../core/services/multiplayer_service.dart';

class SetupGameScreen extends ConsumerStatefulWidget {
  final bool isOnline;
  const SetupGameScreen({super.key, required this.isOnline});

  @override
  ConsumerState<SetupGameScreen> createState() => _SetupGameScreenState();
}

class _SetupGameScreenState extends ConsumerState<SetupGameScreen> {
  int _boardSize = 25;
  int _playerCount = 2;
  int _endRounds = 15;
  bool _enableFarms = true;
  bool _enableSurprise = true;
  bool _enableLuckyWheel = true;
  bool _enableTax = true;

  final List<TextEditingController> _nameControllers =
      List.generate(7, (_) => TextEditingController());

  // Each player's chosen favourite colour, by index into
  // AppColors.playerColors. Defaults to a unique colour per player.
  final List<int> _colorIndices = List.generate(7, (i) => i);

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameControllers[0].text = user.displayName;
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startGame() async {
    final List<PlayerModel> players = [];
    final tiles = TileBuilder.buildTiles(_boardSize);
    
    // Add up total price of all purchasable plots and divide evenly
    final totalPlotValue = tiles.fold<double>(
        0.0,
        (sum, t) => sum + ((t.isPurchasable && t.price != null) ? t.price! : 0.0));
    final startMoney = (totalPlotValue / _playerCount).floorToDouble();

    for (int i = 0; i < _playerCount; i++) {
      final name = _nameControllers[i].text.trim().isEmpty
          ? 'Player ${i + 1}'
          : _nameControllers[i].text.trim();
      players.add(PlayerModel(
        id: 'player_$i',
        displayName: name,
        money: startMoney,
        colorIndex: _colorIndices[i],
      ));
    }

    var gameState = GameStateModel(
      gameId: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      players: players,
      tiles: tiles,
      boardSize: _boardSize,
      finalRoundsTotal: _endRounds,
      isOnline: widget.isOnline,
      phase: GamePhase.playing,
    );

    if (widget.isOnline) {
      // The device that configures the match is the host — it keeps
      // running the real game logic locally and broadcasts every change
      // to Firebase; every other device only ever renders what's synced.
      // Host defaults to controlling the first player slot.
      try {
        final roomCode = await MultiplayerService.instance.createRoom(
          initialState: gameState,
          hostId: players.first.id,
        );
        ref.read(multiplayerRoomProvider.notifier).setLocalPlayerId(players.first.id);
        ref.read(multiplayerRoomProvider.notifier).setRoom(roomCode: roomCode, isHost: true);
      } catch (e) {
        if (!mounted) return;
        // Show the real failure instead of guessing — this same catch
        // fires for an uninitialized Firebase app, a network error, and
        // database-rules permission-denied, and they need different fixes.
        final message = e.toString();
        final looksUnconfigured = message.contains('no-app') ||
            message.contains('DefaultFirebaseOptions') ||
            message.contains('has not been initialized');
        final looksPermissionDenied = message.toLowerCase().contains('permission') ||
            message.toLowerCase().contains('denied');
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              looksUnconfigured
                  ? 'Firebase not configured'
                  : looksPermissionDenied
                      ? 'Database permission denied'
                      : 'Could not create online room',
            ),
            content: Text(
              looksUnconfigured
                  ? "firebase_options.dart is missing or invalid. Run "
                    '`flutterfire configure` from the project root first.'
                  : looksPermissionDenied
                      ? 'The Realtime Database rules are rejecting this write '
                        '— check the rules in the Firebase console (test-mode '
                        'rules expire after 30 days).'
                      : 'Error: $message',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        return;
      }
    }

    ref.read(gameProvider.notifier).initGame(gameState);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GameScreen(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnline ? 'Online Room' : 'Offline Game'),
        backgroundColor: AppColors.appBg,
      ),
      backgroundColor: AppColors.appBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Board Size'),
            _buildBoardSizeSelector(),
            const SizedBox(height: 20),
            _sectionTitle('Number of Players'),
            _buildPlayerCountSelector(),
            const SizedBox(height: 20),
            _sectionTitle('Player Names'),
            _buildPlayerNameFields(),
            const SizedBox(height: 20),
            _sectionTitle('End Game After'),
            _buildEndRoundSelector(),
            const SizedBox(height: 20),
            _sectionTitle('Game Features'),
            _buildToggles(),
            const SizedBox(height: 32),
            _buildStartButton(),
            const SizedBox(height: 20),
          ],
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
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.appBorder,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$size',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'plots',
                    style: TextStyle(
                      color: selected ? Colors.white70 : AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerCountSelector() {
    return Row(
      children: List.generate(6, (i) {
        final count = i + 2;
        final selected = _playerCount == count;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _playerCount = count),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.appCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.appBorder,
                ),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPlayerNameFields() {
    return Column(
      children: List.generate(_playerCount, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.appBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameControllers[i],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Player ${i + 1} name',
                  prefixIcon: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.playerColors[_colorIndices[i]],
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
                child: Row(
                  children: [
                    const Text('Colour',
                        style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    ...List.generate(AppColors.playerColors.length, (c) {
                      final selected = _colorIndices[i] == c;
                      // A colour already chosen by another active player
                      // can't be picked again.
                      final takenByOther = _colorIndices
                          .asMap()
                          .entries
                          .any((e) =>
                              e.key != i && e.key < _playerCount && e.value == c);
                      return GestureDetector(
                        onTap: takenByOther
                            ? null
                            : () => setState(() => _colorIndices[i] = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: selected ? 30 : 24,
                          height: selected ? 30 : 24,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.playerColors[c]
                                .withValues(alpha: takenByOther ? 0.25 : 1.0),
                            shape: BoxShape.circle,
                            // A dark outer ring first, then a white inner
                            // ring — this "target" pattern reads clearly
                            // as selected no matter how light or dark the
                            // swatch colour itself is (a plain white ring
                            // used to disappear against pale colours like
                            // gold).
                            border: Border.all(
                              color: selected ? Colors.white : Colors.transparent,
                              width: selected ? 3 : 0,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0D0D1A),
                                      blurRadius: 0,
                                      spreadRadius: 1.5,
                                    ),
                                    BoxShadow(
                                      color: AppColors.playerColors[c]
                                          .withValues(alpha: 0.7),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : (takenByOther
                                  ? const Icon(Icons.close,
                                      size: 12, color: Colors.white54)
                                  : null),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
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
                border: Border.all(
                  color: selected ? AppColors.secondary : AppColors.appBorder,
                ),
              ),
              child: Center(
                child: Text(
                  '$r Rounds',
                  style: TextStyle(
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggles() {
    final toggles = [
      (
        'Farms & Businesses',
        _enableFarms,
        (bool v) => setState(() => _enableFarms = v)
      ),
      (
        'Surprise Tiles',
        _enableSurprise,
        (bool v) => setState(() => _enableSurprise = v)
      ),
      (
        'Lucky Wheel',
        _enableLuckyWheel,
        (bool v) => setState(() => _enableLuckyWheel = v)
      ),
      (
        'Tax Tiles',
        _enableTax,
        (bool v) => setState(() => _enableTax = v)
      ),
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
              Text(
                t.$1,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Switch(
                value: t.$2,
                onChanged: t.$3,
                activeThumbColor: Colors.white,   // fixed deprecation
                activeTrackColor: AppColors.secondary,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'START GAME',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Tile Builder ──
class TileBuilder {
  static List<TileModel> buildTiles(int boardSize) {
    return TileFactory.build(boardSize);
  }
}