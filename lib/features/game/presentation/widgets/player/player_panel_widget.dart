import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../features/game/domain/models/player_model.dart';

class PlayerPanelWidget extends StatelessWidget {
  final List<PlayerModel> players;
  final int currentPlayerIndex;

  const PlayerPanelWidget({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: players.length,
        itemBuilder: (_, i) => _Card(
          player: players[i],
          isActive: i == currentPlayerIndex,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final PlayerModel player;
  final bool isActive;
  const _Card({required this.player, required this.isActive});

  String get _initial =>
      player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 132,
      margin: const EdgeInsets.only(right: 9),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  player.color.withValues(alpha: 0.28),
                  player.color.withValues(alpha: 0.08),
                ],
              )
            : null,
        color: isActive ? null : AppColors.appCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? player.color : AppColors.appBorder,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: player.color.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar — initial in colored circle
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [player.color, player.color.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: player.color.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              player.displayName,
              style: TextStyle(
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: player.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: player.color.withValues(alpha: 0.6), blurRadius: 6),
                ],
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 10),
            ),
        ]),
        const SizedBox(height: 7),
        Text(
          MoneyFormatter.format(player.money),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          _statChip('🏠', '${player.ownedPropertyIds.length}'),
          const SizedBox(width: 8),
          _statChip('🌾', '${player.farms.length}'),
          if (player.hasShield) ...[
            const SizedBox(width: 8),
            const Text('🛡️', style: TextStyle(fontSize: 11)),
          ],
        ]),
      ]),
    );
  }

  Widget _statChip(String emoji, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 2),
      Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
    ]);
  }
}