import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/game/domain/models/tile_model.dart';
import '../../../../../features/game/domain/models/player_model.dart';

class PlotTileCard extends StatelessWidget {
  final TileModel tile;
  final List<PlayerModel> players;
  final double width;
  final double height;

  const PlotTileCard({
    super.key,
    required this.tile,
    required this.players,
    this.width = 72,
    this.height = 88,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tile.isOwned ? _ownerColor() : const Color(0xFFCCBB99),
          width: tile.isOwned ? 2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3, offset: const Offset(0, 1),
          ),
          if (tile.isOwned)
            BoxShadow(
              color: _ownerColor().withValues(alpha: 0.3),
              blurRadius: 6, spreadRadius: 0,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _ownerStrip(),
            Expanded(child: _body()),
            if (players.isNotEmpty) _playerDots(),
          ],
        ),
      ),
    );
  }

  Widget _ownerStrip() => Container(
    height: 5,
    color: tile.isOwned
        ? _ownerColor()
        : tile.plotTypeColor.withValues(alpha: 0.7),
  );

  Widget _body() {
    if (tile.type == TileType.start) return _startBody();
    if (!tile.isPurchasable) return _specialBody();
    return _plotBody();
  }

  Widget _plotBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tile.plotNumber,
                style: const TextStyle(
                  color: Color(0xFF555555), fontSize: 6,
                  fontWeight: FontWeight.w700, letterSpacing: 0.2,
                )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                decoration: BoxDecoration(
                  color: tile.plotTypeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(tile.plotTypeLabel,
                  style: const TextStyle(
                    color: Color(0xFF333333), fontSize: 5, fontWeight: FontWeight.w800,
                  )),
              ),
            ],
          ),
          const Spacer(),
          Center(child: Text(tile.upgradeEmoji, style: const TextStyle(fontSize: 14))),
          const SizedBox(height: 2),
          Center(
            child: Text(
              tile.displayName,
              style: TextStyle(
                color: tile.isOwned ? const Color(0xFF1A1A2E) : const Color(0xFF333333),
                fontSize: 6.5,
                fontWeight: tile.isOwned ? FontWeight.w800 : FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 1),
          if (tile.price != null)
            Center(
              child: Text(_fmt(tile.price!),
                style: TextStyle(
                  color: tile.isOwned ? Colors.black54 : const Color(0xFF1565C0),
                  fontSize: 6, fontWeight: FontWeight.w700,
                )),
            ),
          if (tile.upgradeLevel > 1) ...[
            const SizedBox(height: 1),
            Center(
              child: Text(tile.upgradeName,
                style: const TextStyle(
                  color: Color(0xFF2E7D32), fontSize: 5.5, fontWeight: FontWeight.w700,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _specialBody() {
    Color color;
    String emoji, label;
    switch (tile.type) {
      case TileType.surprise:
        emoji = '🎁'; label = 'SURPRISE'; color = const Color(0xFFFF9800);
      case TileType.luckyWheel:
        emoji = '🎡'; label = 'LUCKY'; color = const Color(0xFFFFD700);
      case TileType.tax:
        emoji = '💰'; label = 'CITY TAX'; color = const Color(0xFFE74C3C);
      case TileType.bank:
        emoji = '🏦'; label = 'BANK'; color = const Color(0xFF1565C0);
      default:
        emoji = '⭐'; label = 'SPECIAL'; color = Colors.grey;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
          style: TextStyle(color: color, fontSize: 6,
              fontWeight: FontWeight.w900, letterSpacing: 0.3),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _startBody() => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('🏘️', style: TextStyle(fontSize: 16)),
      SizedBox(height: 2),
      Text('GO',
        style: TextStyle(color: Color(0xFF00D4AA),
            fontSize: 7, fontWeight: FontWeight.w900)),
    ],
  );

  Widget _playerDots() => Container(
    height: 10,
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: players.take(4).map((p) => Container(
        width: 8, height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 0.5),
        decoration: BoxDecoration(
          color: p.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 0.8),
          boxShadow: [BoxShadow(color: p.color.withValues(alpha: 0.6), blurRadius: 2)],
        ),
        child: Center(
          child: Text('${p.colorIndex + 1}',
            style: const TextStyle(color: Colors.white,
                fontSize: 4, fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    ),
  );

  Color _bgColor() {
    if (tile.type == TileType.start)      return const Color(0xFF1A1A2E);
    if (tile.type == TileType.surprise)   return const Color(0xFFFFF3E0);
    if (tile.type == TileType.luckyWheel) return const Color(0xFFFFFDE7);
    if (tile.type == TileType.tax)        return const Color(0xFFFFEBEE);
    if (tile.type == TileType.bank)       return const Color(0xFFE3F2FD);
    if (tile.isOwned) return tile.plotTypeColor.withValues(alpha: 0.9);
    return tile.plotTypeColor.withValues(alpha: 0.35);
  }

  Color _ownerColor() {
    if (!tile.isOwned) return AppColors.boardBorder;
    final owner = players.where((p) => p.id == tile.ownerId).firstOrNull;
    if (owner != null) return owner.color;
    final idx = (tile.ownerId?.hashCode ?? 0).abs() % AppColors.playerColors.length;
    return AppColors.playerColors[idx];
  }

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// Legacy aliases so any other imports don't immediately break
typedef BoardTileWidget = PlotTileCard;
enum TileDirection { top, bottom, left, right }