import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/game/domain/models/tile_model.dart';
import '../../../../../features/game/domain/models/player_model.dart';
import 'board_tile_widget.dart';

class GameBoardWidget extends StatelessWidget {
  final List<TileModel> tiles;
  final List<PlayerModel> players;
  final Widget centerWidget;          // dice area shown in header
  final VoidCallback? onLogTap;
  final Set<int> highlightedTiles;    // positions being traversed (animation)

  const GameBoardWidget({
    super.key,
    required this.tiles,
    required this.players,
    
    required this.centerWidget,
    this.onLogTap,
    this.highlightedTiles = const {},
  });

  @override
  Widget build(BuildContext context) {
    final Map<int, List<TileModel>> byLane = {};
    for (final t in tiles) {
      (byLane[t.lane] ??= []).add(t);
    }
    for (final list in byLane.values) {
      list.sort((a, b) => a.positionInLane.compareTo(b.positionInLane));
    }
    final laneNums = byLane.keys.where((k) => k > 0).toList()..sort();

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
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _MainRoadHeader(
              startTilePlayers: _playersAt(0),
              diceWidget: centerWidget,
              onLogTap: onLogTap,
              allPlayers: players,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...laneNums.map((ln) => _LaneSection(
                      laneNumber: ln,
                      tiles: byLane[ln] ?? [],
                      allPlayers: players,
                      isLast: ln == laneNums.last,
                      highlightedTiles: highlightedTiles,
                    )),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PlayerModel> _playersAt(int idx) =>
      players.where((p) => p.position == idx).toList();
}

// ── Main Road Header ──────────────────────────────────────────────────────────
class _MainRoadHeader extends StatelessWidget {
  final List<PlayerModel> startTilePlayers;
  final List<PlayerModel> allPlayers;
  final Widget diceWidget;
  final VoidCallback? onLogTap;

  const _MainRoadHeader({
    required this.startTilePlayers,
    required this.allPlayers,
    required this.diceWidget,
    this.onLogTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFCCBB99), width: 1.5)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          // Township info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏘️  PLOT PLOT TOWNSHIP',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Row(children: [
                  Container(width: 30, height: 2, color: AppColors.secondary),
                  const SizedBox(width: 5),
                  const Text('MAIN ROAD',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(width: 5),
                  Container(width: 30, height: 2, color: AppColors.secondary),
                ]),
                // Player dots
                if (startTilePlayers.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: startTilePlayers.map((p) => Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Center(
                        child: Text(
                          p.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, fontSize: 7,
                            fontWeight: FontWeight.w900),
                        ),
                      ),
                    )).toList(),
                  ),
                ] else ...[
                  const SizedBox(height: 5),
                  Row(
                    children: allPlayers.take(4).map((p) => Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: p.color, width: 1),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),

          // GO tile
          _GoTile(),
          const SizedBox(width: 6),

          // Dice area (compact)
          SizedBox(
            width: 58,
            height: 58,
            child: diceWidget,
          ),
          const SizedBox(width: 6),

          // LOG button
          GestureDetector(
            onTap: onLogTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF00D4AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secondary, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📋', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 1),
                  Text('LOG',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _GoTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 56,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF00D4AA), Color(0xFF00897B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: AppColors.secondary, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🏠', style: TextStyle(fontSize: 20)),
        SizedBox(height: 1),
        Text('GO',
            style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
      ],
    ),
  );
}

// ── Lane Section ──────────────────────────────────────────────────────────────
class _LaneSection extends StatelessWidget {
  final int laneNumber;
  final List<TileModel> tiles;
  final List<PlayerModel> allPlayers;
  final bool isLast;
  final Set<int> highlightedTiles;

  const _LaneSection({
    required this.laneNumber,
    required this.tiles,
    required this.allPlayers,
    required this.isLast,
    required this.highlightedTiles,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(),
      _tileRow(),
      if (!isLast) _road(),
    ],
  );

  Widget _header() {
    final zoneLabel = _zoneLabel();
    final ownedCount = tiles.where((t) => t.isPurchasable || t.isOwned).length;
    final availCount = tiles.where((t) => t.isPurchasable && !t.isOwned).length;

    return Container(
      height: 22,
      color: AppColors.glassSurface,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                  color: _zoneColor(),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _zoneColor().withValues(alpha: 0.7), blurRadius: 4)])),
          const SizedBox(width: 5),
          Text('Lane $laneNumber',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          if (zoneLabel.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _zoneColor().withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _zoneColor(), width: 0.8),
              ),
              child: Text(zoneLabel,
                  style: TextStyle(
                      color: _zoneColor(), fontSize: 7.5,
                      fontWeight: FontWeight.w800)),
            ),
          ],
          // farm income indicator
          if (laneNumber % 3 == 0) ...[
            const SizedBox(width: 6),
            const Text('🌿 Income',
                style: TextStyle(color: AppColors.boardGrassLight, fontSize: 7.5)),
          ],
          const Spacer(),
          Text('$availCount/$ownedCount avail',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 7)),
        ],
      ),
    );
  }

  Widget _tileRow() => Container(
    color: AppColors.boardBg,
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tiles.map((tile) {
          final onTile = allPlayers
              .where((p) => p.position == tile.index)
              .toList();
          return PlotTileCard(
            tile: tile,
            players: onTile,
            allPlayers: allPlayers,
            isHighlighted: highlightedTiles.contains(tile.index),
            width: 110,
            height: 130,
          );
        }).toList(),
      ),
    ),
  );

  Widget _road() => Container(
    height: 24,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.boardRoad,
          AppColors.glowCyan.withValues(alpha: 0.15),
          AppColors.boardRoad,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(14, (i) => Container(
            width: 14, height: 2,
            decoration: BoxDecoration(
              color: AppColors.glowCyan.withValues(alpha: 0.5),
              boxShadow: [BoxShadow(color: AppColors.glowCyan.withValues(alpha: 0.4), blurRadius: 3)],
            ),
          )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.boardBg.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.glassBorder, width: 0.8),
          ),
          child: const Text(
            'INTERNAL ROAD',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
      ],
    ),
  );

  String _zoneLabel() {
    if (laneNumber % 4 == 0) return 'COMMERCIAL';
    if (laneNumber % 3 == 0) return 'FARM ZONE';
    if (laneNumber == 1)     return 'HIGHWAY FACING';
    return '';
  }

  Color _zoneColor() {
    if (laneNumber % 4 == 0) return const Color(0xFF1565C0);
    if (laneNumber % 3 == 0) return const Color(0xFF558B2F);
    if (laneNumber == 1)     return const Color(0xFFE65100);
    return const Color(0xFF5D4037);
  }
}