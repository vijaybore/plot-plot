import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../domain/models/game_state_model.dart';
import '../../../domain/models/player_model.dart';
import '../../modals/player_stats_modal.dart';

class PlayerPanelWidget extends StatelessWidget {
  final List<PlayerModel> players;
  final int currentPlayerIndex;
  final GameStateModel gs;

  const PlayerPanelWidget({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    required this.gs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: players.length,
        itemBuilder: (ctx, i) => _Card(
          player: players[i],
          isActive: i == currentPlayerIndex,
          onTap: () => PlayerStatsModal.show(ctx, players[i], gs),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final PlayerModel player;
  final bool isActive;
  final VoidCallback onTap;

  const _Card({required this.player, required this.isActive, required this.onTap});

  String get _initial =>
      player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 138,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [player.color.withValues(alpha: 0.30), player.color.withValues(alpha: 0.08)])
              : null,
          color: isActive ? null : AppColors.appCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isActive ? player.color : AppColors.appBorder,
              width: isActive ? 2 : 1),
          boxShadow: isActive
              ? [BoxShadow(color: player.color.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            // Traffic light: green for the active player's turn, red otherwise.
            Container(
              width: 9, height: 9,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: isActive ? AppColors.success : AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
                boxShadow: [BoxShadow(
                    color: (isActive ? AppColors.success : AppColors.danger).withValues(alpha: 0.8),
                    blurRadius: isActive ? 6 : 2)],
              ),
            ),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [player.color, player.color.withValues(alpha: 0.65)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [BoxShadow(color: player.color.withValues(alpha: 0.55), blurRadius: 6)],
              ),
              child: Center(child: Text(_initial,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(player.displayName,
                style: TextStyle(
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
            if (isActive)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: player.color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: player.color.withValues(alpha: 0.7), blurRadius: 8)]),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 10)),
          ]),
          const SizedBox(height: 7),
          Text(MoneyFormatter.format(player.money),
              style: const TextStyle(color: AppColors.accent, fontSize: 15,
                  fontWeight: FontWeight.w900, letterSpacing: -0.3)),
          const SizedBox(height: 5),
          Row(children: [
            _chip('🏠', player.ownedPropertyIds.length),
            const SizedBox(width: 8),
            _chip('🌾', player.farms.length),
            if (player.hasShield) ...[const SizedBox(width: 6), const Text('🛡️', style: TextStyle(fontSize: 11))],
            if (player.skipNextTurn) ...[const SizedBox(width: 6), const Text('⏭️', style: TextStyle(fontSize: 11))],
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String emoji, int count) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(emoji, style: const TextStyle(fontSize: 10)),
    const SizedBox(width: 2),
    Text('$count', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
  ]);
}