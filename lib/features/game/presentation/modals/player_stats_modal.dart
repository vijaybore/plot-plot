import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';

import '../../domain/models/game_state_model.dart';
import '../../domain/models/player_model.dart';
import '../../domain/models/tile_model.dart';

class PlayerStatsModal extends StatelessWidget {
  final PlayerModel player;
  final GameStateModel gs;

  const PlayerStatsModal({super.key, required this.player, required this.gs});

  static void show(BuildContext ctx, PlayerModel player, GameStateModel gs) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerStatsModal(player: player, gs: gs),
    );
  }

  List<TileModel> get _ownedTiles =>
      gs.tiles.where((t) => t.ownerId == player.id && t.isPurchasable).toList();

  List<TileModel> get _farms =>
      _ownedTiles.where((t) => t.type == TileType.farmZone).toList();

  List<TileModel> get _properties =>
      _ownedTiles.where((t) => t.type == TileType.property).toList();

  double get _totalPlotValue => _ownedTiles.fold(0, (s, t) => s + t.currentValue);

  @override
  Widget build(BuildContext context) {
    final initial = player.displayName.isNotEmpty
        ? player.displayName[0].toUpperCase()
        : '?';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.appBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: player.color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: player.color.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.appBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Player header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  player.color.withValues(alpha: 0.25),
                  player.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: player.color.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [player.color, player.color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: player.color.withValues(alpha: 0.5),
                        blurRadius: 12),
                  ],
                ),
                child: Center(child: Text(initial,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 24, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(player.displayName,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(children: [
                  if (player.hasShield)
                    const Text('🛡️ Shielded  ',
                        style: TextStyle(color: AppColors.secondary, fontSize: 11)),
                  if (player.skipNextTurn)
                    const Text('⏭️ Skipping',
                        style: TextStyle(color: AppColors.warning, fontSize: 11)),
                  if (!player.hasShield && !player.skipNextTurn)
                    Text('Position: ${player.position}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                ]),
              ])),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.textHint, size: 20),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // Stats grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StatsGrid(
              cash: player.money,
              netWorth: player.netWorth,
              plotValue: _totalPlotValue,
              loanAmount: player.loanAmount,
              propCount: _properties.length,
              farmCount: _farms.length,
              bizCount: player.businesses.length,
            ),
          ),
          const SizedBox(height: 12),
          // Property list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Text('OWNED PLOTS',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
              const Spacer(),
              Text('${_ownedTiles.length} total',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 6),
          // Property list
          Expanded(
            child: _ownedTiles.isEmpty
                ? const Center(
                    child: Text('No plots owned yet',
                        style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                  )
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _ownedTiles.length,
                    itemBuilder: (_, i) {
                      final tile = _ownedTiles[i];
                      return _TileRow(tile: tile, playerColor: player.color);
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final double cash, netWorth, plotValue, loanAmount;
  final int propCount, farmCount, bizCount;

  const _StatsGrid({
    required this.cash,
    required this.netWorth,
    required this.plotValue,
    required this.loanAmount,
    required this.propCount,
    required this.farmCount,
    required this.bizCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _StatCard(label: 'Liquid Cash', value: MoneyFormatter.format(cash),
            icon: '💵', color: AppColors.success),
        const SizedBox(width: 8),
        _StatCard(label: 'Net Worth', value: MoneyFormatter.format(netWorth),
            icon: '📈', color: AppColors.accent, highlight: true),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _StatCard(label: 'Plot Value', value: MoneyFormatter.format(plotValue),
            icon: '🏠', color: AppColors.primary),
        const SizedBox(width: 8),
        _StatCard(
            label: 'Loans',
            value: loanAmount > 0 ? MoneyFormatter.format(loanAmount) : 'None',
            icon: '🏦',
            color: loanAmount > 0 ? AppColors.danger : AppColors.textHint),
      ]),
      const SizedBox(height: 8),
      // Count chips row
      Row(children: [
        _CountChip(emoji: '🏠', label: 'Properties', count: propCount),
        const SizedBox(width: 8),
        _CountChip(emoji: '🌾', label: 'Farms', count: farmCount),
        const SizedBox(width: 8),
        _CountChip(emoji: '🏢', label: 'Businesses', count: bizCount),
      ]),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  final Color color;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight
              ? color.withValues(alpha: 0.12)
              : AppColors.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight
                ? color.withValues(alpha: 0.5)
                : AppColors.appBorder,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(color: AppColors.textHint,
                    fontSize: 9, fontWeight: FontWeight.w600)),
            Text(value,
                style: TextStyle(color: color, fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String emoji, label;
  final int count;
  const _CountChip({required this.emoji, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.appCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.appBorder),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text('$count',
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 14, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: AppColors.textHint,
                  fontSize: 9)),
        ]),
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  final TileModel tile;
  final Color playerColor;
  const _TileRow({required this.tile, required this.playerColor});

  @override
  Widget build(BuildContext context) {
    final isFarm = tile.type == TileType.farmZone;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.appCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.appBorder),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isFarm
                ? AppColors.boardGrass.withValues(alpha: 0.2)
                : playerColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFarm ? AppColors.boardGrass : playerColor,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(isFarm ? '🌾' : '🏠',
                style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tile.displayName,
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 13, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          Text(tile.plotNumber,
              style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(MoneyFormatter.format(tile.currentValue),
              style: const TextStyle(color: AppColors.accent,
                  fontSize: 12, fontWeight: FontWeight.w700)),
          Text('Rent: ${MoneyFormatter.format(tile.currentRent)}',
              style: const TextStyle(color: AppColors.textSecondary,
                  fontSize: 10)),
        ]),
      ]),
    );
  }
}