import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/game/domain/models/tile_model.dart';
import '../../../../../features/game/domain/models/player_model.dart';
import 'board_tile_widget.dart';

class GameBoardWidget extends StatelessWidget {
  final List<TileModel> tiles;
  final List<PlayerModel> players;
  /// Dice + roll button — displayed inside the Main Road header.
  final Widget centerWidget;

  const GameBoardWidget({
    super.key,
    required this.tiles,
    required this.players,
    required this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Group tiles by lane, sorted by positionInLane
    final Map<int, List<TileModel>> byLane = {};
    for (final t in tiles) {
      (byLane[t.lane] ??= []).add(t);
    }
    for (final list in byLane.values) {
      list.sort((a, b) => a.positionInLane.compareTo(b.positionInLane));
    }

    final startTile = byLane[0]?.firstOrNull;
    final laneNums  = byLane.keys.where((k) => k > 0).toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.boardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.boardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MainRoadBar(
                startTile: startTile,
                players: _on(0),
                diceWidget: centerWidget,
              ),
              ...laneNums.map((ln) => _LaneSection(
                laneNumber: ln,
                tiles: byLane[ln] ?? [],
                players: players,
                isLast: ln == laneNums.last,
              )),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  List<PlayerModel> _on(int idx) =>
      players.where((p) => p.position == idx).toList();
}

// ── Main Road / Start Header ──────────────────────────────────────────────────
class _MainRoadBar extends StatelessWidget {
  final TileModel? startTile;
  final List<PlayerModel> players;
  final Widget diceWidget;

  const _MainRoadBar({
    required this.startTile,
    required this.players,
    required this.diceWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFCCBB99), width: 2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Township name
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏘️  PLOT PLOT TOWNSHIP',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                )),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  width: 40,
                  height: 2,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                const Text('MAIN ROAD',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  )),
                const SizedBox(width: 4),
                Container(
                  width: 40,
                  height: 2,
                  color: AppColors.secondary,
                ),
              ]),
              if (players.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: players.map((p) => Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: p.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
          const Spacer(),
          // GO tile
          Container(
            width: 52,
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.secondary, width: 1.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🏠', style: TextStyle(fontSize: 18)),
                SizedBox(height: 2),
                Text('GO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Dice widget (compact area)
          SizedBox(
            width: 64,
            height: 64,
            child: diceWidget,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Single Lane Row ────────────────────────────────────────────────────────────
class _LaneSection extends StatelessWidget {
  final int laneNumber;
  final List<TileModel> tiles;
  final List<PlayerModel> players;
  final bool isLast;

  const _LaneSection({
    required this.laneNumber,
    required this.tiles,
    required this.players,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _laneHeader(),
        _tileRow(context),
        if (!isLast) _internalRoad(),
      ],
    );
  }

  Widget _laneHeader() {
    final laneType = _laneTypeLabel();
    return Container(
      height: 18,
      color: const Color(0xFFE8E0D0),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF8D6E63), shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Lane $laneNumber',
            style: const TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          if (laneType.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _laneColor().withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _laneColor(), width: 0.5),
              ),
              child: Text(laneType,
                style: TextStyle(
                  color: _laneColor(),
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                )),
            ),
          ],
          const Spacer(),
          Text('${tiles.where((t) => t.isPurchasable && !t.isOwned).length} available',
            style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 6.5)),
        ],
      ),
    );
  }

  Widget _tileRow(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F0E8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tiles.map((tile) {
            final onTile = players.where((p) => p.position == tile.index).toList();
            return PlotTileCard(
              tile: tile,
              players: onTile,
              width: 74,
              height: 90,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _internalRoad() {
    return Container(
      height: 20,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4C9B0), Color(0xFFC5B99A), Color(0xFFD4C9B0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Road markings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(12, (i) => Container(
              width: 12, height: 2,
              color: Colors.white.withValues(alpha: 0.5),
            )),
          ),
          // Road label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'INTERNAL ROAD',
              style: TextStyle(
                color: Color(0xFF6D5B3B),
                fontSize: 6,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _laneTypeLabel() {
    if (laneNumber % 3 == 0) return 'FARM ZONE';
    if (laneNumber % 4 == 0) return 'COMMERCIAL';
    if (laneNumber == 1)     return 'HIGHWAY FACING';
    return '';
  }

  Color _laneColor() {
    if (laneNumber % 3 == 0) return const Color(0xFF558B2F);
    if (laneNumber % 4 == 0) return const Color(0xFF1565C0);
    if (laneNumber == 1)     return const Color(0xFFE65100);
    return const Color(0xFF5D4037);
  }
}