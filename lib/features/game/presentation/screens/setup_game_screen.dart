import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../features/game/domain/models/player_model.dart';
import '../../../../features/game/domain/models/tile_model.dart';
import '../../../../features/game/domain/models/game_state_model.dart';
import 'game_screen.dart';
import '../providers/game_provider.dart';

class SetupGameScreen extends ConsumerStatefulWidget {
  final bool isOnline;
  const SetupGameScreen({super.key, required this.isOnline});

  @override
  ConsumerState<SetupGameScreen> createState() => _SetupGameScreenState();
}

class _SetupGameScreenState extends ConsumerState<SetupGameScreen> {
  int _boardSize = 20;
  int _playerCount = 2;
  int _endRounds = 5;
  bool _enableFarms = true;
  bool _enableSurprise = true;
  bool _enableLuckyWheel = true;
  bool _enableTax = true;

  final List<TextEditingController> _nameControllers =
      List.generate(7, (_) => TextEditingController());

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

  void _startGame() {
    final List<PlayerModel> players = [];
    final startMoney =
        AppConstants.startingMoneyByPlayers[_playerCount] ??
        AppConstants.startingMoneyByPlayers[4]!;

    for (int i = 0; i < _playerCount; i++) {
      final name = _nameControllers[i].text.trim().isEmpty
          ? 'Player ${i + 1}'
          : _nameControllers[i].text.trim();
      players.add(PlayerModel(
        id: 'player_$i',
        displayName: name,
        money: startMoney,
        colorIndex: i,
      ));
    }

    final tiles = TileBuilder.buildTiles(_boardSize);

    final gameState = GameStateModel(
      gameId: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      players: players,
      tiles: tiles,
      boardSize: _boardSize,
      finalRoundsTotal: _endRounds,
      isOnline: widget.isOnline,
      phase: GamePhase.playing,
    );
ref.read(gameProvider.notifier).initGame(gameState);

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
      children: [20, 40, 60, 100].map((size) {
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _nameControllers[i],
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Player ${i + 1} name',
              prefixIcon: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.playerColors[i],
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