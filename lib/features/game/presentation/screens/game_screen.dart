import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/models/game_state_model.dart';
import '../../domain/models/tile_model.dart';
import '../providers/game_provider.dart';
import '../widgets/board/game_board_widget.dart';
import '../widgets/dice/dice_widget.dart';
import '../widgets/player/player_panel_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final GameStateModel initialState;
  const GameScreen({super.key, required this.initialState});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    final tiles = TileFactory.build(widget.initialState.boardSize);
    final stateWithTiles = widget.initialState.copyWith(tiles: tiles);
    Future.microtask(() {
      ref.read(gameProvider.notifier).initGame(stateWithTiles);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameProvider);
    final isRolling = ref.watch(diceRollingProvider);

    if (gs == null) {
      return const Scaffold(
        backgroundColor: AppColors.appBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (gs.phase == GamePhase.ended) return _resultScreen(gs);

    final currentPlayer = gs.currentPlayer;
    final landedTile = gs.tiles.isNotEmpty ? gs.tiles[currentPlayer.position] : null;
    final showBuy = landedTile != null &&
        landedTile.isPurchasable &&
        !landedTile.isOwned &&
        gs.lastEvent == GameEvent.landedOnProperty;
    final showRename = landedTile != null &&
        landedTile.isOwned &&
        landedTile.ownerId == currentPlayer.id &&
        gs.lastEvent == GameEvent.landedOnProperty;

    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(
        child: Column(children: [
          _topBar(context, gs),
          if (gs.eventMessage != null) _banner(gs.eventMessage!),
          // Board — lane-based township layout
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: GameBoardWidget(
                tiles: gs.tiles,
                players: gs.players,
                centerWidget: _center(gs, isRolling),
              ),
            ),
          ),
          // Player cards
          SizedBox(
            height: 88,
            child: PlayerPanelWidget(
              players: gs.players,
              currentPlayerIndex: gs.currentPlayerIndex,
            ),
          ),
          const SizedBox(height: 4),
          // Action buttons
          _actions(gs, isRolling, showBuy, showRename, landedTile),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

 Widget _topBar(BuildContext context, GameStateModel gs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.15)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: const Border(bottom: BorderSide(color: AppColors.appBorder, width: 1)),
      ),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => _exit(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.appCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 14),
            ),
          ),
          const SizedBox(width: 10),
          RichText(text: const TextSpan(children: [
            TextSpan(text: 'PLOT ', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            TextSpan(text: 'PLOT', style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 15)),
          ])),
          const Spacer(),
          if (gs.phase == GamePhase.finalRound)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent),
              ),
              child: Text('Final ${gs.finalRoundsCurrent + 1}/${gs.finalRoundsTotal}',
                style: const TextStyle(color: AppColors.accent,
                    fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          // Bank indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bankTile.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.bankTile),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🏦', style: TextStyle(fontSize: 12)),
              SizedBox(width: 4),
              Text('Bank', style: TextStyle(
                  color: Color(0xFF64B5F6), fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        // Current turn strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: gs.currentPlayer.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gs.currentPlayer.color.withValues(alpha: 0.6)),
          ),
          child: Row(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: gs.currentPlayer.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: Text(
                  gs.currentPlayer.displayName.isNotEmpty
                      ? gs.currentPlayer.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "${gs.currentPlayer.displayName}'s Turn",
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (gs.currentPlayer.hasShield)
              const Text('🛡️ Shielded', style: TextStyle(color: AppColors.secondary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _banner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.appSurface,
      child: Text(msg, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 12),
        textAlign: TextAlign.center, maxLines: 2,
        overflow: TextOverflow.ellipsis),
    );
  }

  Widget _center(GameStateModel gs, bool isRolling) {
    final canRoll = gs.lastEvent == GameEvent.none ||
        gs.lastEvent == GameEvent.landedOnStart;
    return Center(
      child: DiceWidget(
        value: gs.lastDiceValue ?? 1,
        isRolling: isRolling,
        canRoll: canRoll && !isRolling,
        onRoll: () => ref.read(gameProvider.notifier).rollDice(ref),
      ),
    );
  }

  Widget _actions(GameStateModel gs, bool isRolling, bool showBuy,
      bool showRename, TileModel? landedTile) {
    if (showBuy) {
      final tile = gs.tiles[gs.currentPlayer.position];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(children: [
          Text('🏠 ${tile.displayName}  ·  ${MoneyFormatter.format(tile.price!)}',
            style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: () => _promptPlotName(tile, gs),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.w900)),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(
              onPressed: () {
                ref.read(gameProvider.notifier).skipProperty();
                ref.read(gameProvider.notifier).endTurn();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.appBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SKIP'),
            )),
          ]),
        ]),
      );
    }

    if (showRename && landedTile != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(children: [
          Text('🏡 ${landedTile.displayName}  ·  Your plot',
            style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => _promptRenamePlot(landedTile, gs),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('✏️ RENAME'),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => ref.read(gameProvider.notifier).endTurn(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('END TURN', style: TextStyle(fontWeight: FontWeight.w900)),
            )),
          ]),
        ]),
      );
    }

    final needsEnd = gs.lastEvent != GameEvent.none &&
        gs.lastEvent != GameEvent.landedOnProperty && !isRolling;

    if (needsEnd) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => ref.read(gameProvider.notifier).endTurn(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('END TURN', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      );
    }
    return const SizedBox(height: 4);
  }

  Widget _resultScreen(GameStateModel gs) {
    final ranked = gs.rankedPlayers;
    final medals = ['🥇', '🥈', '🥉'];
    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(child: Column(children: [
        const SizedBox(height: 24),
        const Text('🏆', style: TextStyle(fontSize: 64)),
        const Text('GAME OVER', style: TextStyle(
            color: AppColors.accent, fontSize: 26,
            fontWeight: FontWeight.w900, letterSpacing: 3)),
        const SizedBox(height: 4),
        Text('${ranked.first.displayName} WINS!',
          style: const TextStyle(color: AppColors.textPrimary,
              fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: ranked.length,
          itemBuilder: (_, i) {
            final p = ranked[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: i == 0
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.appCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: i == 0 ? AppColors.accent : AppColors.appBorder),
              ),
              child: Row(children: [
                Text(i < 3 ? medals[i] : '${i + 1}',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                CircleAvatar(radius: 14, backgroundColor: p.color,
                  child: Text('${p.colorIndex + 1}',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 11))),
                const SizedBox(width: 10),
                Expanded(child: Text(p.displayName, style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14,
                    fontWeight: FontWeight.w700))),
                Text(MoneyFormatter.format(p.netWorth),
                  style: const TextStyle(color: AppColors.accent,
                      fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
            );
          },
        )),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('PLAY AGAIN', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900)),
            )),
        ),
      ])),
    );
  }

  void _promptPlotName(TileModel tile, GameStateModel gs) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.appCard,
        title: const Text('Name Your Plot 🏷️',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Give "${tile.name}" a custom name (or leave blank to keep the default).',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 24,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: tile.name,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.appSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameProvider.notifier).buyProperty(gs.currentPlayer.id);
              ref.read(gameProvider.notifier).endTurn();
            },
            child: const Text('Skip Naming',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameProvider.notifier).buyProperty(
                    gs.currentPlayer.id,
                    customName: controller.text,
                  );
              ref.read(gameProvider.notifier).endTurn();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _promptRenamePlot(TileModel tile, GameStateModel gs) {
    final controller = TextEditingController(text: tile.displayName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.appCard,
        title: const Text('Rename Plot ✏️',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.appSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameProvider.notifier).renamePlot(
                    gs.currentPlayer.id,
                    tile.index,
                    controller.text,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _exit(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.appCard,
      title: const Text('Exit Game?',
          style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Progress will be lost.',
          style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Continue',
              style: TextStyle(color: AppColors.primary))),
        TextButton(onPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
        }, child: const Text('Exit',
            style: TextStyle(color: AppColors.danger))),
      ],
    ));
  }
}