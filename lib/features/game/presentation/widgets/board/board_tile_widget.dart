import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/game/domain/models/tile_model.dart';
import '../../../../../features/game/domain/models/player_model.dart';

class PlotTileCard extends StatefulWidget {
  final TileModel tile;
  final List<PlayerModel> players;   // players currently ON this tile
  final List<PlayerModel> allPlayers; // all players (for owner color lookup)
  final double width;
  final double height;
  final bool isHighlighted; // for movement animation

  const PlotTileCard({
    super.key,
    required this.tile,
    required this.players,
    this.allPlayers = const [],
    this.width = 110,
    this.height = 130,
    this.isHighlighted = false,
  });

  @override
  State<PlotTileCard> createState() => _PlotTileCardState();
}

class _PlotTileCardState extends State<PlotTileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _glow, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        decoration: BoxDecoration(
          color: _bgColor(),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isHighlighted
                ? AppColors.accent.withValues(alpha: _glowAnim.value)
                : (widget.tile.isOwned ? _ownerColor() : const Color(0xFFCCBB99)),
            width: widget.isHighlighted ? 2.5 : (widget.tile.isOwned ? 2 : 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isHighlighted
                  ? AppColors.accent.withValues(alpha: 0.5 * _glowAnim.value)
                  : (widget.tile.isOwned
                      ? _ownerColor().withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.08)),
              blurRadius: widget.isHighlighted ? 12 : 4,
              spreadRadius: widget.isHighlighted ? 2 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Column(
            children: [
              _topStrip(),
              Expanded(child: _body()),
              if (widget.players.isNotEmpty) _playerTokens(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top colour strip (owner colour or plot-type colour) ──────────
  Widget _topStrip() => Container(
    height: 6,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        widget.tile.isOwned
            ? _ownerColor()
            : widget.tile.plotTypeColor.withValues(alpha: 0.8),
        widget.tile.isOwned
            ? _ownerColor().withValues(alpha: 0.6)
            : widget.tile.plotTypeColor.withValues(alpha: 0.4),
      ]),
    ),
  );

  // ── Body ─────────────────────────────────────────────────────────
  Widget _body() {
    if (widget.tile.type == TileType.start) return _startBody();
    if (!widget.tile.isPurchasable && !widget.tile.isOwned) {
      return _specialBody();
    }
    return _plotBody();
  }

  Widget _plotBody() {
    final t = widget.tile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: plot number + type badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.plotNumber,
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: t.plotTypeColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                      color: t.plotTypeColor.withValues(alpha: 0.6), width: 0.5),
                ),
                child: Text(
                  t.plotTypeLabel,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Row 2: big emoji / building image
          Expanded(
            child: Center(
              child: Text(
                t.isOwned ? t.displayEmoji : _unownedEmoji(),
                style: TextStyle(
                  fontSize: t.isOwned ? 28 : 22,
                ),
              ),
            ),
          ),

          const SizedBox(height: 3),

          // Row 3: name (hidden until bought)
          Center(
            child: Text(
              t.isOwned ? t.displayName : 'Empty Plot',
              style: TextStyle(
                color: t.isOwned
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFF888888),
                fontSize: 8,
                fontWeight:
                    t.isOwned ? FontWeight.w800 : FontWeight.w500,
                fontStyle:
                    t.isOwned ? FontStyle.normal : FontStyle.italic,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 2),

          // Row 4: price or dev level
          if (t.isOwned)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  t.upgradeLevel > 1 ? t.upgradeName : 'Owned',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 6.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            Center(
              child: Text(
                '— Available —',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 6.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _specialBody() {
    Color color;
    String emoji, label;
    switch (widget.tile.type) {
      case TileType.surprise:
        emoji = '🎁'; label = 'SURPRISE'; color = const Color(0xFFFF9800);
      case TileType.luckyWheel:
        emoji = '🎡'; label = 'LUCKY SPIN'; color = const Color(0xFFFFD700);
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
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _startBody() => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('🏘️', style: TextStyle(fontSize: 26)),
      SizedBox(height: 4),
      Text('GO',
          style: TextStyle(
              color: Color(0xFF00D4AA),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1)),
    ],
  );

  // ── Player tokens at bottom — a small stylized "standing figure" pin ─
  // (head + body silhouette) with the player's initial on the head,
  // rather than a plain flat dot.
  Widget _playerTokens() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 3, right: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.players.take(4).map((p) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: _PlayerPin(color: p.color, initial: p.displayName.isNotEmpty
              ? p.displayName.substring(0, 1).toUpperCase() : '?'),
        )).toList(),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  String _unownedEmoji() {
    switch (widget.tile.plotType) {
      case PlotType.farm:          return '🌾';
      case PlotType.commercial:    return '🏪';
      case PlotType.industrial:    return '🏗️';
      case PlotType.lakeView:      return '🌊';
      case PlotType.luxury:        return '🏰';
      case PlotType.premium:       return '🌟';
      case PlotType.garden:        return '🌳';
      case PlotType.highwayFacing: return '🛣️';
      // Corner plots now share the Bank's clean cyan look — no icon clutter.
      case PlotType.corner:        return '';
      default:                     return '🏡';
    }
  }

  Color _bgColor() {
    if (widget.tile.type == TileType.start)      return const Color(0xFF1A1A2E);
    if (widget.tile.type == TileType.surprise)   return const Color(0xFFFFF3E0);
    if (widget.tile.type == TileType.luckyWheel) return const Color(0xFFFFFDE7);
    if (widget.tile.type == TileType.tax)        return const Color(0xFFFFEBEE);
    if (widget.tile.type == TileType.bank)       return const Color(0xFFE3F2FD);
    if (widget.tile.isOwned) {
      return widget.tile.plotTypeColor.withValues(alpha: 0.88);
    }
    return widget.tile.plotTypeColor.withValues(alpha: 0.28);
  }

  Color _ownerColor() {
    final owner = widget.allPlayers
        .where((p) => p.id == widget.tile.ownerId)
        .firstOrNull;
    if (owner != null) return owner.color;
    final idx = (widget.tile.ownerId?.hashCode ?? 0).abs() %
        AppColors.playerColors.length;
    return AppColors.playerColors[idx];
  }
}

// Legacy alias
typedef BoardTileWidget = PlotTileCard;
enum TileDirection { top, bottom, left, right }

// ─────────────────────────────────────────────────────────────────────────────
// Player Pin — a compact "standing figure" marker: a round head with the
// player's initial, standing on a small rounded body/base, instead of a
// flat single dot. Kept simple/vector so it stays crisp at any size.
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerPin extends StatelessWidget {
  final Color color;
  final String initial;
  const _PlayerPin({required this.color, required this.initial});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 21,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Head
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 3),
              ],
            ),
            child: Center(
              child: Text(initial, style: const TextStyle(
                  color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
            ),
          ),
          // Body / base
          Container(
            width: 12, height: 6,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5), bottom: Radius.circular(2)),
              border: Border.all(color: Colors.white, width: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}