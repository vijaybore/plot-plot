import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../domain/models/game_state_model.dart';
import 'dart:ui';
import '../../domain/models/player_model.dart';
import '../../domain/models/tile_model.dart';

class BankModal extends StatelessWidget {
  final GameStateModel gs;
  const BankModal({super.key, required this.gs});

  static void show(BuildContext context, GameStateModel gs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: BankModal(gs: gs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ranked = gs.rankedPlayers;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.appBg.withValues(alpha: 0.9), // slight transparency for blur
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.appBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bankTile.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bankTile),
                ),
                child: const Text('🏦', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BANK OVERVIEW', style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 18,
                    fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('${gs.players.length} players · Round ${gs.finalRoundsCurrent + 1}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.appCard,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                ),
              ),
            ]),
          ),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Expanded(flex: 3, child: Text('PLAYER',
                    style: TextStyle(color: AppColors.textHint, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1))),
                Expanded(flex: 2, child: Text('CASH',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1))),
                Expanded(flex: 2, child: Text('PLOTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1))),
                Expanded(flex: 2, child: Text('NET WORTH',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.textHint, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1))),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          // Player rows
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ranked.length,
              itemBuilder: (_, i) {
                final p = ranked[i];
                final ownedTiles = gs.tiles.where((t) =>
                    t.ownerId == p.id && t.isPurchasable).toList();
                final farms = ownedTiles
                    .where((t) => t.type == TileType.farmZone).length;
                final props = ownedTiles
                    .where((t) => t.type == TileType.property).length;
                final netWorth = gs.netWorthOf(p);
                return _PlayerRow(
                  rank: i + 1,
                  player: p,
                  netWorth: netWorth,
                  farmCount: farms,
                  propCount: props,
                  isLeader: i == 0,
                );
              },
            ),
          ),
          // Wealth chart bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: _WealthBar(entries: ranked.map((p) => (p, gs.netWorthOf(p))).toList()),
          ),
        ]),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final int rank;
  final PlayerModel player;
  final double netWorth;
  final int farmCount;
  final int propCount;
  final bool isLeader;

  const _PlayerRow({
    required this.rank,
    required this.player,
    required this.netWorth,
    required this.farmCount,
    required this.propCount,
    required this.isLeader,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLeader
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLeader ? AppColors.accent.withValues(alpha: 0.4) : AppColors.appBorder,
          width: isLeader ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Rank + avatar
        Expanded(flex: 3, child: Row(children: [
          Text(rank == 1 ? '👑' : '$rank',
              style: TextStyle(fontSize: rank == 1 ? 16 : 12,
                  color: AppColors.textHint)),
          const SizedBox(width: 8),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: player.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(child: Text(
              player.displayName.isNotEmpty
                  ? player.displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w800),
            )),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(player.displayName,
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
        ])),
        // Cash
        Expanded(flex: 2, child: Text(
          MoneyFormatter.format(player.money),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondary,
              fontSize: 12, fontWeight: FontWeight.w700),
        )),
        // Plots
        Expanded(flex: 2, child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🏠', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 2),
              Text('$propCount',
                  style: const TextStyle(color: AppColors.textPrimary,
                      fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              const Text('🌾', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 2),
              Text('$farmCount',
                  style: const TextStyle(color: AppColors.textPrimary,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ],
        )),
        // Net worth
        Expanded(flex: 2, child: Text(
          MoneyFormatter.format(netWorth),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: isLeader ? AppColors.accent : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        )),
      ]),
    );
  }
}

class _WealthBar extends StatelessWidget {
  final List<(PlayerModel, double)> entries;
  const _WealthBar({required this.entries});

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(
        0, (s, e) => s + (e.$2 > 0 ? e.$2 : 0));
    if (total == 0) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('WEALTH DISTRIBUTION',
          style: TextStyle(color: AppColors.textHint, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: entries.map((e) {
            final p = e.$1;
            final netWorth = e.$2;
            final share = netWorth > 0 ? netWorth / total : 0.0;
            return Flexible(
              flex: (share * 1000).toInt().clamp(1, 1000),
              child: Container(
                height: 24,
                color: p.color,
                alignment: Alignment.center,
                child: share > 0.12
                    ? Text(
                        p.displayName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: entries.map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: e.$1.color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(e.$1.displayName,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ])).toList(),
      ),
    ]);
  }
}