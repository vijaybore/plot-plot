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
  final String? currentPlayerId; // whose turn it is, to pick out their token
  final VoidCallback? onTap;

  const PlotTileCard({
    super.key,
    required this.tile,
    required this.players,
    this.allPlayers = const [],
    this.width = 110,
    this.height = 130,
    this.isHighlighted = false,
    this.currentPlayerId,
    this.onTap,
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
    // Clamp text scaling within the tile so a user's system/browser
    // "large text" accessibility setting can't blow the fixed-size
    // card open and trigger a "RenderFlex overflowed" error.
    final clampedMediaQuery = MediaQuery.of(context).copyWith(
      textScaler: MediaQuery.of(context).textScaler.clamp(
            minScaleFactor: 0.8,
            maxScaleFactor: 1.1,
          ),
    );

    final bool showNeon = widget.isHighlighted || widget.players.isNotEmpty;

    return MediaQuery(
      data: clampedMediaQuery,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, _) => Container(
            width: widget.width,
            height: widget.height,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            decoration: BoxDecoration(
              color: widget.tile.isOwned ? null : _bgColor(),
              // Owned plots fade from the plot-type tint at the top down
              // into the owner's own color toward the bottom, so the card
              // visually "belongs" to whoever bought it — same idea as the
              // original SOLD-ribbon design's tinted look.
              gradient: widget.tile.isOwned
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.tile.plotTypeColor.withValues(alpha: 0.45),
                        _ownerColor().withValues(alpha: 0.85),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showNeon
                    ? AppColors.accent.withValues(alpha: _glowAnim.value * 0.8 + 0.2)
                    : (widget.tile.isOwned ? _ownerColor() : const Color(0xFFCCBB99)),
                width: showNeon ? 2.5 : (widget.tile.isOwned ? 2 : 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: showNeon
                      ? AppColors.accent.withValues(alpha: 0.6 * _glowAnim.value)
                      : (widget.tile.isOwned
                          ? _ownerColor().withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.15)),
                  blurRadius: showNeon ? 16 : 10,
                  spreadRadius: showNeon ? 3 : 0,
                  offset: showNeon ? Offset.zero : const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              // Player tokens are drawn as an overlay pinned to the
              // bottom of the card instead of a sibling flex child.
              // That way they never add extra height on top of the
              // card's fixed size — which was the cause of the
              // "BOTTOM OVERFLOWED" error on tiles with players on them.
              child: Stack(
                children: [
                  Column(
                    children: [
                      _topStrip(),
                      Expanded(child: _body()),
                    ],
                  ),
                  if (widget.players.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _playerTokens(),
                    ),
                  // Purely decorative corner ribbon — Positioned + IgnorePointer
                  // so it never participates in layout sizing (that's what
                  // caused the old overflow bug, not this ribbon itself).
                  if (widget.tile.isOwned) _soldOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Premium "SOLD" ribbon ─────────────────────────────────────────
  // Diagonal corner banner in the owner's color. Positioned + IgnorePointer
  // means it sits purely as a visual overlay and never affects the
  // Column's layout/sizing — so it can't reintroduce the old overflow bug.
  Widget _soldOverlay() {
    final ownerColor = _ownerColor();
    return Positioned(
      top: 8,
      right: -26,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: Container(
            width: 90,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  ownerColor.withValues(alpha: 0.95),
                  ownerColor.withValues(alpha: 0.75),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Text(
              'SOLD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
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

          // Row 3: name — shows the bank-listed name even before it's
          // owned, so the tile never displays a generic placeholder.
          Center(
            child: Text(
              t.displayName,
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

  // ── Player letter tokens, pinned as a bottom overlay ──────────────
  Widget _playerTokens() {
    // Tokens shrink a little once more than 3 players share a tile so
    // the row never needs more horizontal space than the card's width.
    final count = widget.players.take(4).length;
    final tokenSize = count > 3 ? 16.0 : 18.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.players.take(4).map((p) {
          final isCurrent = widget.currentPlayerId != null && p.id == widget.currentPlayerId;
          return Container(
          width: tokenSize,
          height: tokenSize,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: p.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? AppColors.accent : Colors.white,
              width: isCurrent ? 2.2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCurrent ? AppColors.accent : p.color).withValues(alpha: 0.6),
                blurRadius: isCurrent ? 6 : 4,
                spreadRadius: isCurrent ? 1 : 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              p.displayName.isNotEmpty
                  ? p.displayName.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: tokenSize > 17 ? 9 : 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
        }).toList(),
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
      case PlotType.corner:        return '📐';
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