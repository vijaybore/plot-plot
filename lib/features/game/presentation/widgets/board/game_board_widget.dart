import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/game/domain/models/tile_model.dart';
import '../../../../../features/game/domain/models/player_model.dart';
import 'board_tile_widget.dart';

class GameBoardWidget extends StatefulWidget {
  final List<TileModel> tiles;
  final List<PlayerModel> players;
  final Widget centerWidget;          // dice area shown in header
  final VoidCallback? onLogTap;
  final VoidCallback? onGoTap;        // tapping the GO / home tile
  final Set<int> highlightedTiles;    // positions being traversed (animation)
  final String? currentPlayerId;      // whose turn it is — for traffic light
  final void Function(TileModel)? onTileTap;

  const GameBoardWidget({
    super.key,
    required this.tiles,
    required this.players,
    
    required this.centerWidget,
    this.onLogTap,
    this.onGoTap,
    this.highlightedTiles = const {},
    this.currentPlayerId,
    this.onTileTap,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget> {
  final GlobalKey _activeTileKey = GlobalKey();
  int? _lastCenteredPosition;

  // Automatic camera pan: whenever the active player's board position
  // changes (their turn starts / they move), smoothly scroll both the
  // lane's horizontal strip and the board's vertical list so their tile
  // is brought into view without the user having to hunt for it.
  void _panToActiveTileIfNeeded(int? position) {
    if (position == null || position == _lastCenteredPosition) return;
    _lastCenteredPosition = position;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeTileKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tiles = widget.tiles;
    final players = widget.players;
    final centerWidget = widget.centerWidget;
    final onLogTap = widget.onLogTap;
    final highlightedTiles = widget.highlightedTiles;
    final currentPlayerId = widget.currentPlayerId;

    int? currentPosition;
    if (currentPlayerId != null) {
      final matches = players.where((p) => p.id == currentPlayerId);
      currentPosition = matches.isEmpty ? null : matches.first.position;
    }
    _panToActiveTileIfNeeded(currentPosition);

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
              onGoTap: widget.onGoTap,
              allPlayers: players,
              currentPlayerId: currentPlayerId,
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
                      currentPlayerId: currentPlayerId,
                      activeTileKey: _activeTileKey,
                      activeTilePosition: currentPosition,
                      onTileTap: widget.onTileTap,
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
      widget.players.where((p) => p.position == idx).toList();
}

// ── Main Road Header ──────────────────────────────────────────────────────────
class _MainRoadHeader extends StatelessWidget {
  final List<PlayerModel> startTilePlayers;
  final List<PlayerModel> allPlayers;
  final Widget diceWidget;
  final VoidCallback? onLogTap;
  final VoidCallback? onGoTap;
  final String? currentPlayerId;

  const _MainRoadHeader({
    required this.startTilePlayers,
    required this.allPlayers,
    required this.diceWidget,
    this.onLogTap,
    this.onGoTap,
    this.currentPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 5),
                // Each seated player gets a dot in their own chosen
                // colour; whoever's turn it is right now gets a gold
                // glowing ring. Wrap so it never overflows however many
                // players are at the table.
                SizedBox(
                  height: 18,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: allPlayers.map((p) =>
                        _TrafficDot(player: p, isActive: p.id == currentPlayerId)
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),

          // GO tile
          GestureDetector(
            onTap: onGoTap,
            child: const _GoTile(),
          ),
          const SizedBox(width: 8),

          // Dice area — wide enough for either the single dice icon OR,
          // once a player lands and BUY/SKIP (or RENAME/END) appear, a
          // proper side-by-side button row instead of a cramped vertical
          // stack. Was 58px wide, which could only ever fit one button
          // per line; 132px gives two real tap targets room to breathe.
          SizedBox(
            width: 132,
            height: 76,
            child: diceWidget,
          ),
          const SizedBox(width: 10),
          // NOTE: the LOG button used to be duplicated here AND in the
          // top app bar. There is now exactly one Log button — the
          // high-contrast teal one in the top-right app header.
        ],
      ),
    );
  }
}

// ── Header dot: always the player's own colour, with a gold glowing
// ring around whoever's turn it is right now ────────────────────────
class _TrafficDot extends StatelessWidget {
  final PlayerModel player;
  final bool isActive;
  const _TrafficDot({required this.player, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: player.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.accent : Colors.white,
          width: isActive ? 2.2 : 1.2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.85),
                  blurRadius: 8,
                  spreadRadius: 1.5,
                ),
              ]
            : [
                BoxShadow(
                  color: player.color.withValues(alpha: 0.4),
                  blurRadius: 2,
                ),
              ],
      ),
      child: Center(
        child: Text(
          player.displayName.isNotEmpty ? player.displayName.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white, fontSize: 7,
            fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _GoTile extends StatelessWidget {
  const _GoTile();

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
  final String? currentPlayerId;
  final GlobalKey? activeTileKey;
  final int? activeTilePosition;
  final void Function(TileModel)? onTileTap;

  const _LaneSection({
    required this.laneNumber,
    required this.tiles,
    required this.allPlayers,
    required this.isLast,
    required this.highlightedTiles,
    this.currentPlayerId,
    this.activeTileKey,
    this.activeTilePosition,
    this.onTileTap,
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
      color: const Color(0xFFE8E0D0),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                  color: _zoneColor(), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('Lane $laneNumber',
              style: const TextStyle(
                  color: Color(0xFF5D4037), fontSize: 9,
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
                style: TextStyle(color: Color(0xFF558B2F), fontSize: 7.5)),
          ],
          const Spacer(),
          Text('$availCount/$ownedCount avail',
              style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 7)),
        ],
      ),
    );
  }

  Widget _tileRow() => Container(
    color: const Color(0xFFF0EBE0),
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tiles.map((tile) {
          final onTile = allPlayers
              .where((p) => p.position == tile.index)
              .toList();
          final card = PlotTileCard(
            // An explicit, content-derived key (not just list position)
            // forces Flutter to treat this as a brand-new widget whenever
            // the tile's owner/occupants/highlight state actually changes,
            // instead of trying to reuse the same Element/RenderObject in
            // place. Without this, a hot-reload across a layout rewrite
            // (like Column -> Stack+FittedBox) can leave a stale, already-
            // painted overflow banner stuck on screen until a full app
            // restart — this key makes that class of staleness impossible.
            key: ValueKey(
              'tile-${tile.index}-${tile.ownerId}-${tile.upgradeLevel}-'
              '${onTile.map((p) => p.id).join(",")}-'
              '${highlightedTiles.contains(tile.index)}',
            ),
            tile: tile,
            players: onTile,
            allPlayers: allPlayers,
            isHighlighted: highlightedTiles.contains(tile.index),
            width: 110,
            height: 130,
            currentPlayerId: currentPlayerId,
            onTap: onTileTap == null ? null : () => onTileTap!(tile),
          );
          // Tag the active player's current tile so the board can
          // auto-scroll (both lanes + horizontal strip) to bring it
          // into view the moment their turn starts.
          if (activeTilePosition != null && tile.index == activeTilePosition) {
            return KeyedSubtree(key: activeTileKey, child: card);
          }
          return card;
        }).toList(),
      ),
    ),
  );

  // A real constructed-road look: dark asphalt body with a subtle depth
  // gradient, painted kerb lines top and bottom, a proper dashed yellow
  // centre line (not just faint white ticks), and a road-sign-style name
  // plate instead of a plain translucent label box.
  Widget _road() => Container(
    height: 30,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF44454A), Color(0xFF2C2D30), Color(0xFF3A3B3F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.55, 1.0],
      ),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Kerb / edge lines — the pale strip a real road has where the
        // asphalt meets the shoulder.
        Positioned(
          top: 3, left: 0, right: 0,
          child: Container(height: 1.4, color: Colors.white.withValues(alpha: 0.22)),
        ),
        Positioned(
          bottom: 3, left: 0, right: 0,
          child: Container(height: 1.4, color: Colors.white.withValues(alpha: 0.22)),
        ),
        // Dashed yellow centre line — a real lane marking, not faint ticks.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(20, (i) => Container(
            width: 12, height: 2.6,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(1.2),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFC107).withValues(alpha: 0.4), blurRadius: 2),
              ],
            ),
          )),
        ),
        // Road name plate — a small dark sign instead of a translucent box.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.55), width: 0.8),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
          child: const Text(
            'INTERNAL ROAD',
            style: TextStyle(
              color: Color(0xFFF5F0E6),
              fontSize: 7,
              fontWeight: FontWeight.w800,
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
    if (laneNumber == 2)     return 'INTERNAL COMMERCE';
    return '';
  }

  Color _zoneColor() {
    if (laneNumber % 4 == 0) return const Color(0xFF1565C0);
    if (laneNumber % 3 == 0) return const Color(0xFF558B2F);
    if (laneNumber == 1)     return const Color(0xFFE65100);
    if (laneNumber == 2)     return const Color(0xFF6A1B9A);
    return const Color(0xFF5D4037);
  }
}