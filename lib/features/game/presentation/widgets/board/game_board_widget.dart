import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/game/domain/models/tile_model.dart';
import '../../../../../features/game/domain/models/player_model.dart';
import 'board_tile_widget.dart';

class GameBoardWidget extends StatelessWidget {
  final List<TileModel> tiles;
  final List<PlayerModel> players;
  final Widget centerWidget;

  const GameBoardWidget({
    super.key,
    required this.tiles,
    required this.players,
    required this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth < constraints.maxHeight
          ? constraints.maxWidth
          : constraints.maxHeight;
      return SizedBox(width: size, height: size, child: _buildBoard(size));
    });
  }

  Widget _buildBoard(double size) {
    final boardSize = tiles.length;
    final perSide = boardSize ~/ 4;
    final cornerSize = size * 0.13;
    final tileH = size * 0.09;
    final innerSize = size - cornerSize * 2;
    final tileW = innerSize / (perSide - 1);

    final bottomTiles = tiles.where((t) => t.side == 0).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final leftTiles = tiles.where((t) => t.side == 1).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final topTiles = tiles.where((t) => t.side == 2).toList()
      ..sort((a, b) => b.index.compareTo(a.index));
    final rightTiles = tiles.where((t) => t.side == 3).toList()
      ..sort((a, b) => b.index.compareTo(a.index));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.boardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.boardBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(children: [
          // Bottom row (reads left → right normally)
          Positioned(
            bottom: 0, left: cornerSize, right: cornerSize, height: tileH,
            child: Row(
              children: bottomTiles.skip(1).map((t) => Expanded(
                child: BoardTileWidget(
                  tile: t,
                  players: _on(t.index),
                  direction: TileDirection.bottom,
                  tileWidth: tileW,
                ),
              )).toList(),
            ),
          ),
          // Top row — text reads normally too, NOT flipped
          Positioned(
            top: 0, left: cornerSize, right: cornerSize, height: tileH,
            child: Row(
              children: topTiles.map((t) => Expanded(
                child: BoardTileWidget(
                  tile: t,
                  players: _on(t.index),
                  direction: TileDirection.top,
                  tileWidth: tileW,
                ),
              )).toList(),
            ),
          ),
          // Left column
          Positioned(
            left: 0, top: cornerSize, bottom: cornerSize, width: tileH,
            child: Column(
              children: leftTiles.map((t) => Expanded(
                child: BoardTileWidget(
                  tile: t,
                  players: _on(t.index),
                  direction: TileDirection.left,
                  tileWidth: tileW,
                ),
              )).toList(),
            ),
          ),
          // Right column
          Positioned(
            right: 0, top: cornerSize, bottom: cornerSize, width: tileH,
            child: Column(
              children: rightTiles.map((t) => Expanded(
                child: BoardTileWidget(
                  tile: t,
                  players: _on(t.index),
                  direction: TileDirection.right,
                  tileWidth: tileW,
                ),
              )).toList(),
            ),
          ),
          // Corners
          Positioned(bottom: 0, left: 0, width: cornerSize, height: cornerSize,
            child: _Corner(label: 'GO', emoji: '🏠', color: const Color(0xFF00D4AA))),
          Positioned(top: 0, left: 0, width: cornerSize, height: cornerSize,
            child: _Corner(label: 'BANK', emoji: '🏦', color: const Color(0xFF1565C0))),
          Positioned(top: 0, right: 0, width: cornerSize, height: cornerSize,
            child: _Corner(label: 'TAX', emoji: '💰', color: const Color(0xFFE74C3C))),
          Positioned(bottom: 0, right: 0, width: cornerSize, height: cornerSize,
            child: _Corner(label: 'FREE', emoji: '🅿️', color: const Color(0xFF2E7D32))),
          // Center
          Positioned(
            top: tileH, left: tileH, right: tileH, bottom: tileH,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: centerWidget,
            ),
          ),
        ]),
      ),
    );
  }

  List<PlayerModel> _on(int idx) =>
      players.where((p) => p.position == idx).toList();
}

class _Corner extends StatelessWidget {
  final String label, emoji;
  final Color color;
  const _Corner({required this.label, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.08)],
        ),
        border: Border.all(color: const Color(0xFFCCBB99), width: 0.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 9,
            fontWeight: FontWeight.w900, letterSpacing: 0.5), textAlign: TextAlign.center),
      ]),
    );
  }
}