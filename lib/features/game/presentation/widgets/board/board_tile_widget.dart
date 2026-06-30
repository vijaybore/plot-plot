import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/game/domain/models/tile_model.dart';
import '../../../../../features/game/domain/models/player_model.dart';

enum TileDirection { top, bottom, left, right }

class BoardTileWidget extends StatelessWidget {
  final TileModel tile;
  final List<PlayerModel> players;
  final TileDirection direction;
  final double tileWidth;

  const BoardTileWidget({
    super.key,
    required this.tile,
    required this.players,
    required this.direction,
    required this.tileWidth,
  });

  bool get _isVertical =>
      direction == TileDirection.left || direction == TileDirection.right;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg(),
        border: Border.all(color: AppColors.boardBorder, width: 0.5),
        boxShadow: tile.isOwned
            ? [
                BoxShadow(
                  color: _ownerColor()!.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Stack(children: [
        _isVertical ? _vertical() : _horizontal(),
        if (players.isNotEmpty) _dots(),
      ]),
    );
  }

  Color? _ownerColor() {
    if (!tile.isOwned) return null;
    return AppColors.playerColors[0]; // placeholder, real owner color passed via players list ideally
  }

  Color _bg() {
    switch (tile.type) {
      case TileType.surprise:
        return const Color(0xFFFF9800).withValues(alpha: 0.15);
      case TileType.luckyWheel:
        return const Color(0xFFFFD700).withValues(alpha: 0.15);
      case TileType.tax:
        return const Color(0xFFE74C3C).withValues(alpha: 0.12);
      case TileType.bank:
        return const Color(0xFF1565C0).withValues(alpha: 0.12);
      default:
        return AppColors.tileWhite;
    }
  }

  // No rotation at all on TOP/BOTTOM rows; text just reads horizontally always.
  // Only LEFT/RIGHT columns rotate the column-content 90°, but using a
  // direction-correct quarterTurn so text isn't flipped upside down.
  Widget _horizontal() {
    return Column(children: [
      if (direction == TileDirection.bottom && tile.type == TileType.property)
        _strip(horiz: true),
      Expanded(child: Center(child: _content())),
      if (direction == TileDirection.top && tile.type == TileType.property)
        _strip(horiz: true),
    ]);
  }

  Widget _vertical() {
    return Row(children: [
      if (direction == TileDirection.right && tile.type == TileType.property)
        _strip(horiz: false),
      Expanded(
        child: Center(
          child: RotatedBox(
            // LEFT column: rotate +90° (reads bottom-to-top)
            // RIGHT column: rotate -90° (reads top-to-bottom)
            quarterTurns: direction == TileDirection.left ? 1 : 3,
            child: _content(),
          ),
        ),
      ),
      if (direction == TileDirection.left && tile.type == TileType.property)
        _strip(horiz: false),
    ]);
  }

  Widget _strip({required bool horiz}) {
    final strip = Container(color: tile.groupColor);
    return horiz
        ? SizedBox(height: 5, child: strip)
        : SizedBox(width: 5, child: strip);
  }

  Widget _content() {
    switch (tile.type) {
      case TileType.surprise:
        return const Text('?',
            style: TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 14,
                fontWeight: FontWeight.w900));
      case TileType.luckyWheel:
        return const Text('🎡', style: TextStyle(fontSize: 12));
      case TileType.tax:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💰', style: TextStyle(fontSize: 11)),
            Text('TAX',
                style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 6,
                    fontWeight: FontWeight.w900)),
          ],
        );
      case TileType.bank:
        return const Text('🏦', style: TextStyle(fontSize: 12));
      case TileType.start:
        return const SizedBox.shrink();
      case TileType.property:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            tile.displayName,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 6,
                fontWeight: FontWeight.w700,
                height: 1.1),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (tile.price != null)
            Text(_fmt(tile.price!),
                style: const TextStyle(
                    color: Color(0xFF555555), fontSize: 5)),
        ]);
    }
  }

  Widget _dots() {
    return Positioned(
      bottom: 1,
      left: 0,
      right: 0,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: players
            .map((p) => Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.all(0.5),
                  decoration: BoxDecoration(
                    color: p.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 0.6),
                    boxShadow: [
                      BoxShadow(
                          color: p.color.withValues(alpha: 0.6),
                          blurRadius: 2),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _fmt(double price) {
    if (price >= 100000) return '₹${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '₹${(price / 1000).toStringAsFixed(0)}K';
    return '₹${price.toStringAsFixed(0)}';
  }
}