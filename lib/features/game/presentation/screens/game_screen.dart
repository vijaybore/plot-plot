import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/game_state_model.dart';
import '../../domain/models/tile_model.dart';
import '../../domain/models/player_model.dart';
import '../providers/game_provider.dart';
import 'package:flutter/material.dart';
import '../widgets/board/game_board_widget.dart';
import '../widgets/dice/dice_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final GameStateModel? initialState;
  const GameScreen({super.key, this.initialState});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  bool _showLog    = false;
  String? _toastMsg;
  late AnimationController _diceCtrl;
  late AnimationController _logCtrl;
  late AnimationController _toastCtrl;
  late Animation<double>   _diceAnim;
  late Animation<Offset>   _logSlide;
  late Animation<Offset>   _toastSlide;

  @override
  void initState() {
    super.initState();
    if (widget.initialState != null) {
      Future.microtask(() =>
          ref.read(gameProvider.notifier).initGame(widget.initialState!));
    }
    _diceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _toastCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _diceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2),  weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0),  weight: 25),
    ]).animate(CurvedAnimation(parent: _diceCtrl, curve: Curves.easeInOut));

    _logSlide = Tween<Offset>(
        begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _logCtrl, curve: Curves.easeOut));

    _toastSlide = Tween<Offset>(
        begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _toastCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _diceCtrl.dispose();
    _logCtrl.dispose();
    _toastCtrl.dispose();
    super.dispose();
  }

  // ── Toast notification ────────────────────────────────────────────
  void _showToast(String msg) async {
    setState(() => _toastMsg = msg);
    _toastCtrl.forward(from: 0);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _toastCtrl.reverse();
  }

  // ── Log panel ─────────────────────────────────────────────────────
  void _toggleLog() {
    setState(() => _showLog = !_showLog);
    _showLog ? _logCtrl.forward() : _logCtrl.reverse();
  }

  // ── Dice roll ────────────────────────────────────────────────────
  Future<void> _rollDice() async {
    final gs = ref.read(gameProvider);
    if (gs == null) return;
    _diceCtrl.forward(from: 0);

    // rollDice() now writes the player's real position into game state one
    // tile at a time, so simply awaiting it is enough — the board rebuilds
    // on every hop via ref.watch and the token visibly moves step by step,
    // exactly like a Ludo piece, instead of teleporting to the final tile.
    await ref.read(gameProvider.notifier).rollDice(ref);

    // NOTE: gs.eventMessage is already surfaced persistently by _EventBanner
    // (and, for Surprise / Lucky Wheel, by the detail modal too). Firing the
    // toast here as well used to double- and triple-render the exact same
    // string on screen at once. The toast is now reserved for one-off
    // confirmations (e.g. purchase success) that don't already have a
    // persistent banner of their own.
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameProvider);
    final isRolling = ref.watch(diceRollingProvider);

    // Whenever a player freshly lands on Surprise / Lucky Wheel, pop up a
    // full detail card automatically — landing on the tile used to just
    // flash a one-line banner with no way to see what actually happened,
    // which is why it felt "stuck". This also gives a single clear
    // "Continue" action that ends the turn, instead of hunting for END.
    ref.listen<GameStateModel?>(gameProvider, (prev, next) {
      if (next == null) return;
      final justResolved = next.eventMessage != null &&
          !next.isMoving &&
          (next.lastEvent == GameEvent.landedOnSurprise ||
              next.lastEvent == GameEvent.landedOnLuckyWheel) &&
          (prev?.eventMessage != next.eventMessage ||
              prev?.lastEvent != next.lastEvent);
      if (justResolved) {
        _showSurpriseDetail(next.eventMessage!);
      }
    });

    if (gs == null) {
      return const Scaffold(
        backgroundColor: AppColors.appBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (gs.phase == GamePhase.ended) return _EndScreen(gs: gs);

    final cur = gs.currentPlayer;
    final landedTile = (gs.lastEvent != GameEvent.none && !gs.isMoving)
        ? gs.tiles[cur.position]
        : null;

    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            _AppBar(gs: gs, onLogTap: _toggleLog),
            _TurnBanner(player: cur),
            if (gs.eventMessage != null) _EventBanner(msg: gs.eventMessage!),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                child: GameBoardWidget(
                  tiles: gs.tiles,
                  players: gs.players,
                  currentPlayerId: cur.id,
                  centerWidget: _DiceArea(
                    gs: gs,
                    isRolling: isRolling,
                    diceAnim: _diceAnim,
                    onRoll: _rollDice,
                    landedTile: landedTile,
                    onBuy: () => _showBuySheet(gs, landedTile!),
                    onSkip: () {
                      ref.read(gameProvider.notifier).skipProperty();
                      ref.read(gameProvider.notifier).endTurn();
                    },
                    onEndTurn: () => ref.read(gameProvider.notifier).endTurn(),
                    onRename: () => _showRenameSheet(gs, landedTile!),
                  ),
                  onLogTap: _toggleLog,
                  highlightedTiles: gs.isMoving ? {cur.position} : const {},
                  onTileTap: (tile) {
                    // Tapping the Bank tile directly on the board opens
                    // the same Bank Details sheet as tapping a player
                    // card — one consistent entry point either way.
                    if (tile.type == TileType.bank) _showBankSheet(gs);
                  },
                ),
              ),
            ),
            _PlayerStrip(gs: gs, onBankTap: _showBankSheet),
            const SizedBox(height: 4),
          ]),

          // Toast
          if (_toastMsg != null)
            Positioned(
              top: 80, left: 16, right: 16,
              child: SlideTransition(
                position: _toastSlide,
                child: _Toast(msg: _toastMsg!),
              ),
            ),

          // Log backdrop
          if (_showLog)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleLog,
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
          // Log panel
          Positioned(
            top: 0, right: 0, bottom: 0,
            width: MediaQuery.of(context).size.width * 0.80,
            child: SlideTransition(
              position: _logSlide,
              child: _LogPanel(gs: gs, onClose: _toggleLog),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Surprise / Lucky Wheel detail popup ─────────────────────────────
  void _showSurpriseDetail(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventDetailModal(
        message: message,
        onContinue: () {
          Navigator.pop(context);
          final gs = ref.read(gameProvider);
          // The player has now seen the detail — advance the turn for them
          // instead of making them also find and tap a separate END button.
          if (gs != null && !gs.isMoving && gs.lastEvent != GameEvent.none) {
            ref.read(gameProvider.notifier).endTurn();
          }
        },
      ),
    );
  }

  // ── Sheets ────────────────────────────────────────────────────────
  void _showBuySheet(GameStateModel gs, TileModel tile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuySheet(
        gs: gs,
        tile: tile,
        onBuy: (name, price, emoji) {
          ref.read(gameProvider.notifier).buyProperty(
            gs.currentPlayer.id,
            customName: name,
            price: price,
            customEmoji: emoji,
          );
          ref.read(gameProvider.notifier).endTurn();
          _showToast('🏠 "$name" purchased for ${_f(price)}!');
        },
        onSkip: () {
          ref.read(gameProvider.notifier).skipProperty();
          ref.read(gameProvider.notifier).endTurn();
        },
      ),
    );
  }

  void _showRenameSheet(GameStateModel gs, TileModel tile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RenameSheet(
        tile: tile,
        onSave: (name, emoji) {
          ref.read(gameProvider.notifier).renamePlot(
              gs.currentPlayer.id, tile.index, name, newEmoji: emoji);
          ref.read(gameProvider.notifier).endTurn();
          _showToast('✏️ Plot renamed to "$name"');
        },
      ),
    );
  }

  void _showBankSheet(GameStateModel gs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BankSheet(
        playerId: gs.currentPlayer.id,
        onDeposit: (id, amt) =>
            ref.read(gameProvider.notifier).depositToBank(id, amt),
        onWithdraw: (id, amt) =>
            ref.read(gameProvider.notifier).withdrawFromBank(id, amt),
        onLoan: (id, amt) =>
            ref.read(gameProvider.notifier).takeLoan(id, amt),
        onRepay: (id, amt) =>
            ref.read(gameProvider.notifier).repayLoan(id, amt),
        onTransfer: (from, to, amt) =>
            ref.read(gameProvider.notifier).transferMoney(from, to, amt),
      ),
    );
  }

  // ignore: unused_element
  void _showTownshipOverview(GameStateModel gs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TownshipOverview(gs: gs),
    );
  }

  String _f(double v) {
    if (v >= 10000000) return '₹${(v/10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '₹${(v/100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '₹${(v/1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final GameStateModel gs;
  final VoidCallback onLogTap;
  const _AppBar({required this.gs, required this.onLogTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.appBg,
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18),
          onPressed: () => _confirmExit(context),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 2),
        RichText(text: const TextSpan(children: [
          TextSpan(text: 'PLOT ', style: TextStyle(color: AppColors.textPrimary,
              fontSize: 18, fontWeight: FontWeight.w900)),
          TextSpan(text: 'PLOT', style: TextStyle(color: AppColors.accent,
              fontSize: 18, fontWeight: FontWeight.w900)),
        ])),
        const Spacer(),
        // Rules
        _iconBtn('📖', () => _showRules(context)),
        const SizedBox(width: 4),
        // Bank
        _iconBtn('🏦', () {
          // handled by player strip
        }),
        const SizedBox(width: 4),
        // Log — teal gradient with high-contrast white text/icon so it
        // stays legible against both light and dark board backgrounds.
        GestureDetector(
          onTap: onLogTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF00D4AA)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00D4AA).withValues(alpha: 0.35),
                    blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(children: const [
              Text('📋', style: TextStyle(fontSize: 13)),
              SizedBox(width: 5),
              Text('Log', style: TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _iconBtn(String emoji, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.appCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.appBorder),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 15)),
    ),
  );

  void _confirmExit(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: AppColors.appCard,
      title: const Text('Exit Game?', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Progress will be lost.', style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.popUntil(ctx, (r) => r.isFirst);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Exit'),
        ),
      ],
    ));
  }

  void _showRules(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RulesSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Turn Banner
// ─────────────────────────────────────────────────────────────────────────────
class _TurnBanner extends StatelessWidget {
  final PlayerModel player;
  const _TurnBanner({required this.player});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        player.color.withValues(alpha: 0.18),
        player.color.withValues(alpha: 0.06),
      ]),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: player.color.withValues(alpha: 0.45)),
    ),
    child: Row(children: [
      _dot(player),
      const SizedBox(width: 10),
      Text("${player.displayName}'s Turn",
          style: const TextStyle(color: AppColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w700)),
      const Spacer(),
      if (player.hasShield) const Text('🛡️', style: TextStyle(fontSize: 15)),
      if (player.skipNextTurn) const Text('⏭️', style: TextStyle(fontSize: 15)),
    ]),
  );

  Widget _dot(PlayerModel p) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
    child: Center(child: Text(
      p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Event Banner
// ─────────────────────────────────────────────────────────────────────────────
class _EventBanner extends StatelessWidget {
  final String msg;
  const _EventBanner({required this.msg});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.appCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.appBorder),
    ),
    child: Text(msg,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12,
          fontWeight: FontWeight.w600),
      textAlign: TextAlign.center,
      maxLines: 2, overflow: TextOverflow.ellipsis),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast
// ─────────────────────────────────────────────────────────────────────────────
class _Toast extends StatelessWidget {
  final String msg;
  const _Toast({required this.msg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.appSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)],
    ),
    child: Text(msg, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dice Area (inside board header)
// ─────────────────────────────────────────────────────────────────────────────
class _DiceArea extends StatelessWidget {
  final GameStateModel gs;
  final bool isRolling;
  final Animation<double> diceAnim;
  final VoidCallback onRoll;
  final TileModel? landedTile;
  final VoidCallback onBuy;
  final VoidCallback onSkip;
  final VoidCallback onEndTurn;
  final VoidCallback onRename;

  const _DiceArea({
    required this.gs, required this.isRolling, required this.diceAnim,
    required this.onRoll, required this.landedTile,
    required this.onBuy, required this.onSkip,
    required this.onEndTurn, required this.onRename,
  });

  bool get _canRoll => !isRolling && !gs.isMoving &&
      gs.lastEvent == GameEvent.none && gs.phase != GamePhase.ended;

  bool get _showBuy => landedTile != null &&
      (landedTile!.type == TileType.property || landedTile!.type == TileType.farmZone) &&
      !landedTile!.isOwned && gs.lastEvent == GameEvent.landedOnProperty;

  bool get _showRename => landedTile != null && landedTile!.isOwned &&
      landedTile!.ownerId == gs.currentPlayer.id &&
      gs.lastEvent == GameEvent.landedOnProperty;

  bool get _needsEnd => !gs.isMoving && gs.lastEvent != GameEvent.none &&
      gs.lastEvent != GameEvent.landedOnProperty;

  @override
  Widget build(BuildContext context) {
    if (_showBuy || _showRename) return _actionRow();

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(
        animation: diceAnim,
        builder: (_, child) => Transform.rotate(angle: diceAnim.value, child: child),
        child: GestureDetector(
          onTap: _canRoll ? onRoll : null,
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _canRoll
                  ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                  : [const Color(0xFF444444), const Color(0xFF333333)]),
              shape: BoxShape.circle,
              border: Border.all(color: _canRoll
                  ? const Color(0xFF42A5F5) : Colors.grey, width: 2),
              boxShadow: _canRoll ? [BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.6),
                blurRadius: 12)] : [],
            ),
            child: Center(child: isRolling
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_diceEmoji(gs.lastDiceValue ?? 1),
                    style: const TextStyle(fontSize: 22))),
          ),
        ),
      ),
      const SizedBox(height: 3),
      if (_needsEnd)
        GestureDetector(
          onTap: onEndTurn,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('END', style: TextStyle(color: Colors.white,
                fontSize: 8, fontWeight: FontWeight.w900)),
          ),
        )
      else
        const Text('Dice', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 8)),
    ]);
  }

  Widget _actionRow() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (_showBuy) ...[
        Expanded(child: _btn('BUY', AppColors.success, onBuy)),
        const SizedBox(width: 6),
        Expanded(child: _btn('SKIP', AppColors.appCard, onSkip, txtColor: AppColors.textSecondary)),
      ] else if (_showRename) ...[
        Expanded(child: _btn('RENAME', AppColors.accent, onRename, txtColor: Colors.black)),
        const SizedBox(width: 6),
        Expanded(child: _btn('END', AppColors.primary, onEndTurn)),
      ],
    ],
  );

  Widget _btn(String label, Color color, VoidCallback fn,
      {Color txtColor = Colors.white}) =>
    GestureDetector(
      onTap: fn,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
        ),
        child: Text(label, style: TextStyle(color: txtColor,
            fontSize: 9, fontWeight: FontWeight.w900)),
      ),
    );

  String _diceEmoji(int v) => ['⚀','⚁','⚂','⚃','⚄','⚅'][(v-1).clamp(0,5)];
}

// ─────────────────────────────────────────────────────────────────────────────
// Player Strip (bottom)
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerStrip extends StatelessWidget {
  final GameStateModel gs;
  final void Function(GameStateModel) onBankTap;
  const _PlayerStrip({required this.gs, required this.onBankTap});

  @override
  Widget build(BuildContext context) {
    final cards = gs.players.map((p) => _PlayerCard(
      player: p,
      isActive: p.id == gs.currentPlayer.id,
      ownedTiles: gs.tiles.where((t) => t.ownerId == p.id).toList(),
      onBankTap: () => onBankTap(gs),
      width: null, // fills whatever parent gives it (Expanded or SizedBox)
    )).toList();

    return Container(
      height: 122, // was 118 — bumped to match _PlayerCard's new 106px height
      decoration: const BoxDecoration(
        // Dark bottom control bar
        color: Color(0xFF14141F),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: gs.players.length == 2
          // 2-player layout: token box — 3D dice — token box, dice centered
          // in the middle of the bottom bar as its own focal element.
          ? Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 8),
              BottomBarDice(color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(child: cards[1]),
            ])
          : ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(width: 155, child: cards[0]),
                const SizedBox(width: 8),
                BottomBarDice(color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                for (final c in cards.skip(1))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(width: 155, child: c),
                  ),
              ],
            ),
    );
  }
}

class _PlayerCard extends StatefulWidget {
  final PlayerModel player;
  final bool isActive;
  final List<TileModel> ownedTiles;
  final VoidCallback onBankTap;
  final double? width; // null = fill parent (used inside Expanded)

  const _PlayerCard({required this.player, required this.isActive,
    required this.ownedTiles, required this.onBankTap, this.width = 155});

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  late final Animation<double> _pulse =
      Tween<double>(begin: 0.35, end: 1.0)
          .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final isActive = widget.isActive;
    final ownedTiles = widget.ownedTiles;
    final width = widget.width;
    final farmCount = ownedTiles.where((t) =>
        t.plotType == PlotType.farm || t.type == TileType.farmZone).length;
    final plotCount = ownedTiles.length - farmCount;

    return GestureDetector(
      onTap: widget.onBankTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          width: width,
          // Fixed, generous height with tight internal spacing — the old
          // layout relied on a Spacer() inside a too-short box, which is
          // exactly what produced "BOTTOM OVERFLOWED" in debug builds
          // whenever the optional Loan row appeared. Giving every row a
          // fixed slot (no Spacer) guarantees it always fits. Bumped from
          // 102 → 106: the pulsing-border version added slightly heavier
          // shadow/border painting that was tipping this over by 1px on
          // some players (the "BOTTOM OVERFLOWED BY 1.00 PIXELS" strip).
          height: 106,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            // Uniform dark navy background whether resting or active —
            // active turn is now communicated purely by the pulsing
            // border glow below, not by a solid color fill.
            color: AppColors.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? player.color.withValues(alpha: _pulse.value)
                  : AppColors.appBorder,
              width: isActive ? 2.5 : 1,
            ),
            boxShadow: isActive ? [BoxShadow(
              color: player.color.withValues(alpha: 0.45 * _pulse.value),
              blurRadius: 14,
              spreadRadius: 1,
            )] : [],
          ),
          child: child,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(width: 24, height: 24,
                decoration: BoxDecoration(color: player.color, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
                child: Center(child: Text(
                  player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w900)))),
              const SizedBox(width: 6),
              Expanded(child: Text(player.displayName,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 10,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
              if (isActive)
                const Icon(Icons.play_arrow, color: AppColors.success, size: 13),
            ]),
            const SizedBox(height: 3),
            _row('Net Worth', _f(player.netWorth), AppColors.textPrimary, bold: true),
            _row('Cash',      _f(player.money),    AppColors.success),
            // Bank + Loan share one row so the card height never depends
            // on whether the player currently has a loan.
            Row(children: [
              Expanded(child: _row('Bank', _f(player.bankBalance), AppColors.info)),
              if (player.loanAmount > 0)
                Expanded(child: _row('Loan', _f(player.loanAmount), AppColors.danger)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              const Text('🏠', style: TextStyle(fontSize: 9)),
              Text(' $plotCount  ', style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 8)),
              const Text('🌾', style: TextStyle(fontSize: 9)),
              Text(' $farmCount', style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 8)),
              const Spacer(),
              if (player.hasShield)
                const Text('🛡️', style: TextStyle(fontSize: 10)),
              if (player.skipNextTurn) ...[
                const SizedBox(width: 3),
                const Text('⏭️', style: TextStyle(fontSize: 10)),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color vColor, {bool bold = false}) =>
    Row(children: [
      Text('$label: ', style: const TextStyle(color: AppColors.textHint, fontSize: 7.5)),
      Flexible(
        child: Text(value, style: TextStyle(color: vColor, fontSize: bold ? 11.5 : 8.5,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ),
    ]);

  String _f(double v) {
    if (v >= 10000000) return '₹${(v/10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '₹${(v/100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '₹${(v/1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOG Panel
// ─────────────────────────────────────────────────────────────────────────────
class _LogPanel extends StatelessWidget {
  final GameStateModel gs;
  final VoidCallback onClose;
  const _LogPanel({required this.gs, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.appCard,
      boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
    ),
    child: SafeArea(child: Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.appSurface,
        child: Row(children: [
          const Text('📋  Activity Log', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(onTap: onClose,
            child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20)),
        ]),
      ),
      // Entries
      Expanded(
        child: gs.activityLog.isEmpty
            ? const Center(child: Text('No activity yet',
                style: TextStyle(color: AppColors.textHint, fontSize: 13)))
            : ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(10),
                itemCount: gs.activityLog.length,
                itemBuilder: (_, i) {
                  final entry = gs.activityLog[gs.activityLog.length - 1 - i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.appSurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(entry, style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11, height: 1.4)),
                  );
                }),
      ),
    ])),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Township Overview (GO button)
// ─────────────────────────────────────────────────────────────────────────────
class _TownshipOverview extends StatelessWidget {
  final GameStateModel gs;
  const _TownshipOverview({required this.gs});

  @override
  Widget build(BuildContext context) {
    final purchasable = gs.tiles.where((t) => t.isPurchasable || t.isOwned).toList();
    final owned       = purchasable.where((t) => t.isOwned).toList();
    final available   = purchasable.where((t) => !t.isOwned).toList();
    final totalValue  = owned.fold<double>(0, (s, t) => s + t.currentValue);
    final richest     = gs.rankedPlayers.first;
    final completion  = purchasable.isEmpty ? 0.0 : owned.length / purchasable.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.appCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(color: AppColors.appBorder,
                borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              const Text('🏘️  Township Overview', style: TextStyle(
                color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
              const Spacer(),
              GestureDetector(onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.textSecondary)),
            ]),
          ),
          Expanded(child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Completion bar
              const SizedBox(height: 4),
              Row(children: [
                const Text('Completion', style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
                const Spacer(),
                Text('${(completion * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.accent,
                      fontSize: 13, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: completion,
                  minHeight: 8,
                  backgroundColor: AppColors.appSurface,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              // Stats grid
              _StatGrid(stats: [
                ('Total Plots', '${purchasable.length}', AppColors.textPrimary),
                ('Sold', '${owned.length}', AppColors.success),
                ('Available', '${available.length}', AppColors.accent),
                ('Township Value', _f(totalValue), AppColors.info),
                ('Richest Player', richest.displayName, richest.color),
                ('Turn #', '${gs.finalRoundsCurrent + 1}', AppColors.textSecondary),
              ]),
              const SizedBox(height: 16),
              // Player rankings
              const Text('Player Rankings', style: TextStyle(
                color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...gs.rankedPlayers.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final medals = ['🥇','🥈','🥉'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.appSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: i == 0
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : AppColors.appBorder),
                  ),
                  child: Row(children: [
                    Text(i < 3 ? medals[i] : '${i+1}.',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Container(width: 28, height: 28,
                      decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                      child: Center(child: Text(
                        p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w900)))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.displayName,
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontSize: 12, fontWeight: FontWeight.w700))),
                    Text(_f(p.netWorth),
                      style: const TextStyle(color: AppColors.success,
                          fontSize: 12, fontWeight: FontWeight.w800)),
                  ]),
                );
              }),
              const SizedBox(height: 20),
            ],
          )),
        ]),
      ),
    );
  }

  String _f(double v) {
    if (v >= 10000000) return '₹${(v/10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '₹${(v/100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '₹${(v/1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _StatGrid extends StatelessWidget {
  final List<(String, String, Color)> stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    childAspectRatio: 2.8,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: stats.map((s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.appSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(s.$1, style: const TextStyle(color: AppColors.textHint, fontSize: 9)),
          Text(s.$2, style: TextStyle(color: s.$3, fontSize: 13,
              fontWeight: FontWeight.w800)),
        ]),
    )).toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bank Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BankSheet extends ConsumerStatefulWidget {
  final String playerId;
  final void Function(String, double) onDeposit;
  final void Function(String, double) onWithdraw;
  final void Function(String, double) onLoan;
  final void Function(String, double) onRepay;
  final void Function(String, String, double) onTransfer;

  const _BankSheet({required this.playerId, required this.onDeposit,
    required this.onWithdraw, required this.onLoan,
    required this.onRepay, required this.onTransfer});

  @override
  ConsumerState<_BankSheet> createState() => _BankSheetState();
}

class _BankSheetState extends ConsumerState<_BankSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _amtCtrl = TextEditingController();
  String? _selectedTransferTarget;
  String? _error;

  // Live game state — re-read every time this sheet rebuilds (via
  // ref.watch inside build(), see below) so balances always reflect the
  // latest player data, even if it changes while the sheet stays open.
  // This is what fixed the "Bank modal shows stale Cash" bug: the old
  // version captured a GameStateModel once at the moment the sheet was
  // opened and never looked at the provider again.
  late GameStateModel _gs;
  PlayerModel get _me =>
      _gs.players.firstWhere((p) => p.id == widget.playerId,
          orElse: () => _gs.currentPlayer);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  double get _amt => double.tryParse(_amtCtrl.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    _gs = ref.watch(gameProvider)!;
    return DraggableScrollableSheet(
    initialChildSize: 0.72,
    maxChildSize: 0.92,
    builder: (_, ctrl) => Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            const Text('🏦  PLOT PLOT BANK', style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const Spacer(),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white70)),
          ]),
        ),
        // Balance bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _bal('Cash',  _f(_me.money),        Colors.greenAccent),
            _vdiv(),
            _bal('Bank',  _f(_me.bankBalance),  Colors.lightBlueAccent),
            _vdiv(),
            _bal('Loan',  _f(_me.loanAmount),   Colors.redAccent),
            _vdiv(),
            _bal('Net Worth', _f(_me.netWorth), Colors.amberAccent),
          ]),
        ),
        // Tabs
        TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '⬆ Deposit'),
            Tab(text: '⬇ Withdraw'),
            Tab(text: '💳 Loan'),
            Tab(text: '✅ Repay'),
            Tab(text: '↔ Transfer'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _amtView('Deposit cash to bank', 'Amount to deposit',
                  'DEPOSIT', _me.money, () {
                if (_amt <= 0 || _amt > _me.money) {
                  setState(() => _error = 'Insufficient cash');
                  return;
                }
                widget.onDeposit(_me.id, _amt);
                Navigator.pop(context);
              }),
              _amtView('Withdraw from bank to cash', 'Amount to withdraw',
                  'WITHDRAW', _me.bankBalance, () {
                if (_amt <= 0 || _amt > _me.bankBalance) {
                  setState(() => _error = 'Insufficient bank balance');
                  return;
                }
                widget.onWithdraw(_me.id, _amt);
                Navigator.pop(context);
              }),
              _loanView(),
              _amtView('Repay your loan', 'Amount to repay',
                  'REPAY LOAN', _me.loanAmount, () {
                if (_amt <= 0 || _me.money < _amt) {
                  setState(() => _error = 'Insufficient cash');
                  return;
                }
                widget.onRepay(_me.id, _amt);
                Navigator.pop(context);
              }),
              _transferView(),
            ],
          ),
        ),
      ]),
    ),
  );
  }

  Widget _bal(String label, String value, Color c) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w800)),
    ],
  );

  Widget _vdiv() => Container(width: 1, height: 28,
      color: Colors.white.withValues(alpha: 0.2));

  Widget _amtView(String title, String hint, String btnLabel,
      double max, VoidCallback onConfirm) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      Text('Available: ${_f(max)}',
          style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 12),
      TextField(
        controller: _amtCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixText: '₹ ',
          prefixStyle: const TextStyle(color: Colors.amberAccent,
              fontSize: 20, fontWeight: FontWeight.w700),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white)),
        ),
        onChanged: (_) => setState(() => _error = null),
      ),
      if (_error != null) ...[
        const SizedBox(height: 6),
        Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      ],
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1565C0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(btnLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      ),
    ]);
  }

  Widget _loanView() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Take a Bank Loan', style: TextStyle(color: Colors.white70, fontSize: 13)),
    Text('Interest: ${(AppConstants.loanInterestRate * 100).toStringAsFixed(0)}%  |  Current Loan: ${_f(_me.loanAmount)}',
        style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 14),
    ...([AppConstants.smallLoan, AppConstants.mediumLoan, AppConstants.largeLoan]
        .map((amt) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: _me.money > 0 ? () {
          widget.onLoan(_me.id, amt);
          Navigator.pop(context);
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const SizedBox(width: 10),
          Text(_f(amt), style: const TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w800)),
          Text('Repay ${_f(amt * (1 + AppConstants.loanInterestRate))}',
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(width: 10),
        ]),
      ),
    ))),
  ]);

  Widget _transferView() {
    final others = _gs.players.where((p) => p.id != _me.id).toList();
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Transfer Cash to Player', style: TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 12),
      ...others.map((p) => GestureDetector(
        onTap: () => setState(() => _selectedTransferTarget = p.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _selectedTransferTarget == p.id
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _selectedTransferTarget == p.id
                ? Colors.white : Colors.white24),
          ),
          child: Row(children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
              child: Center(child: Text(
                p.displayName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w900)))),
            const SizedBox(width: 10),
            Text(p.displayName, style: const TextStyle(color: Colors.white, fontSize: 13)),
            const Spacer(),
            if (_selectedTransferTarget == p.id)
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          ]),
        ),
      )),
      if (_selectedTransferTarget != null) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _amtCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w800),
          decoration: const InputDecoration(
            hintText: 'Amount',
            hintStyle: TextStyle(color: Colors.white38),
            prefixText: '₹ ',
            prefixStyle: TextStyle(color: Colors.amberAccent, fontSize: 18),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white38)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: () {
            if (_amt <= 0 || _me.money < _amt) {
              setState(() => _error = 'Insufficient cash');
              return;
            }
            widget.onTransfer(_me.id, _selectedTransferTarget!, _amt);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('TRANSFER', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900)),
        ),
      ],
    ]);
  }

  String _f(double v) {
    if (v >= 10000000) return '₹${(v/10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '₹${(v/100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '₹${(v/1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buy Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BuySheet extends StatefulWidget {
  final GameStateModel gs;
  final TileModel tile;
  final void Function(String, double, String?) onBuy;
  final VoidCallback onSkip;
  const _BuySheet({required this.gs, required this.tile,
    required this.onBuy, required this.onSkip});

  @override
  State<_BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends State<_BuySheet> {
  final _nameCtrl  = TextEditingController();
  String _emoji    = '';
  String? _error;
  late double _price;
  late double _minPrice;
  late double _maxPrice;

  @override
  void initState() {
    super.initState();
    _emoji = TileModel.suggestedEmojis(widget.tile.plotType).first;
    final range = TileModel.priceRange(widget.tile.plotType);
    _minPrice = range.$1;
    _maxPrice = range.$2;
    // Start at the old fixed-price point within the range — familiar
    // anchor, but now fully adjustable by the player.
    _price = TileModel.fixedPrice(widget.tile.plotType)
        .clamp(_minPrice, _maxPrice).toDouble();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.gs.currentPlayer.money;
    final canAfford = balance >= _price;

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.appCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(color: AppColors.appBorder,
                borderRadius: BorderRadius.circular(2))),
          // Header strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.tile.plotTypeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.tile.plotTypeColor),
            ),
            child: Row(children: [
              Text(_emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.tile.plotTypeColor,
                      borderRadius: BorderRadius.circular(4)),
                    child: Text(widget.tile.plotTypeLabel,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                          color: Color(0xFF333333)))),
                  const SizedBox(width: 6),
                  Text(widget.tile.plotNumber,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
                const SizedBox(height: 3),
                const Text('PURCHASE PLOT', style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                Text('Price range: ${_f(_minPrice)} – ${_f(_maxPrice)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10,
                      fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
          Expanded(
            child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              // Emoji picker
              const Text('Plot Icon', style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8,
                children: TileModel.suggestedEmojis(widget.tile.plotType).map((e) =>
                  GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _emoji == e
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.appSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _emoji == e ? AppColors.primary : AppColors.appBorder,
                          width: _emoji == e ? 2 : 1,
                        ),
                      ),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                    ),
                  )).toList(),
              ),
              const SizedBox(height: 16),
              // Name
              const Text('Plot Name', style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                maxLength: 24,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Vijay\'s Villa, Green Acres…',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                  counterStyle: const TextStyle(color: AppColors.textHint),
                  prefixText: '$_emoji  ',
                  prefixStyle: const TextStyle(fontSize: 18),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              // Player-driven price negotiation — pick anywhere in the
              // plot's allowed range instead of a single locked price.
              // Buying lower protects cash for future plots; buying
              // higher raises this plot's resale/rent value faster.
              Row(children: [
                const Text('Your Offer (₹)', style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Your cash: ${_f(balance)}',
                  style: TextStyle(
                    color: canAfford ? AppColors.success : AppColors.danger,
                    fontSize: 11)),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: canAfford ? AppColors.appBorder : AppColors.danger),
                ),
                child: Column(children: [
                  Text(_f(_price), style: TextStyle(
                    color: canAfford ? AppColors.accent : AppColors.danger,
                    fontSize: 26, fontWeight: FontWeight.w900)),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.appBorder,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withValues(alpha: 0.2),
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: _price,
                      min: _minPrice,
                      max: _maxPrice,
                      divisions: 20,
                      onChanged: (v) => setState(() => _price = v),
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Low: ${_f(_minPrice)}', style: const TextStyle(
                        color: AppColors.textHint, fontSize: 10)),
                    Text('High: ${_f(_maxPrice)}', style: const TextStyle(
                        color: AppColors.textHint, fontSize: 10)),
                  ]),
                ]),
              ),
              if (!canAfford) ...[
                const SizedBox(height: 8),
                const Text('❌ Slide left — this offer is above your cash on hand',
                  style: TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !canAfford ? null : () {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) {
                      setState(() => _error = 'Please enter a plot name');
                      return;
                    }
                    Navigator.pop(context);
                    widget.onBuy(name, _price, _emoji);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: AppColors.appBorder,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(canAfford ? 'CONFIRM PURCHASE' : 'CAN\'T AFFORD',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSkip();
                },
                child: const Text('Skip this plot',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              const SizedBox(height: 10),
            ]),
          ),
        ]),
      ),
    );
  }

  String _f(double v) {
    if (v >= 10000000) return '₹${(v/10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '₹${(v/100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '₹${(v/1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rename Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _RenameSheet extends StatefulWidget {
  final TileModel tile;
  final void Function(String, String?) onSave;
  const _RenameSheet({required this.tile, required this.onSave});

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late TextEditingController _ctrl;
  late String _emoji;

  @override
  void initState() {
    super.initState();
    _ctrl  = TextEditingController(text: widget.tile.displayName);
    _emoji = widget.tile.displayEmoji;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.appCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('✏️ Rename ${widget.tile.plotNumber}', style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8,
            children: TileModel.suggestedEmojis(widget.tile.plotType).map((e) =>
              GestureDetector(
                onTap: () => setState(() => _emoji = e),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _emoji == e
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.appSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _emoji == e ? AppColors.primary : AppColors.appBorder,
                      width: _emoji == e ? 2 : 1),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                ),
              )).toList()),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLength: 24,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'New plot name'),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSave(_ctrl.text, _emoji);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
            )),
          ]),
        ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Surprise / Lucky Wheel Event Detail Modal
// ─────────────────────────────────────────────────────────────────────────────
class _EventDetailModal extends StatelessWidget {
  final String message;
  final VoidCallback onContinue;
  const _EventDetailModal({required this.message, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    // Messages are authored as "<emoji(s)> <rest of sentence>" — split the
    // leading icon off so it can be shown big, and the rest as body copy.
    final trimmed = message.trim();
    final spaceIdx = trimmed.indexOf(' ');
    final icon = spaceIdx > 0 ? trimmed.substring(0, spaceIdx) : '🎁';
    final body = spaceIdx > 0 ? trimmed.substring(spaceIdx + 1) : trimmed;
    final isGood = trimmed.contains('🎉') || trimmed.contains('🏛️') ||
        trimmed.contains('🌾') || trimmed.contains('💰') && !trimmed.contains('paid') ||
        trimmed.contains('🛡️') || trimmed.contains('🔄');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 32, spreadRadius: 2),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: isGood
                    ? [const Color(0xFFFFF3B0), const Color(0xFFFF9800)]
                    : [const Color(0xFFFFC1B0), const Color(0xFFE74C3C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isGood ? const Color(0xFFFF9800) : const Color(0xFFE74C3C))
                      .withValues(alpha: 0.5),
                  blurRadius: 20, spreadRadius: 2,
                ),
              ],
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 16),
          Text(isGood ? 'LUCKY BREAK!' : 'SURPRISE EVENT',
              style: TextStyle(
                  color: isGood ? const Color(0xFFFFD54F) : const Color(0xFFFF8A80),
                  fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w600, height: 1.45)),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('CONTINUE',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900,
                      fontSize: 14, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rules Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _RulesSheet extends StatelessWidget {
  const _RulesSheet();

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (_, ctrl) => Container(
      decoration: const BoxDecoration(
        color: AppColors.appCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(color: AppColors.appBorder,
              borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            const Text('📖  How to Play', style: TextStyle(
              color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
            const Spacer(),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: AppColors.textSecondary)),
          ]),
        ),
        Expanded(child: ListView(controller: ctrl,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: const [
            _RuleSection('🎯 Goal',
              'Buy plots, grow their value, and end the game with the most money. Money = your cash + bank savings + everything your plots are worth, minus any loans.'),
            _RuleSection('🎲 Your Turn',
              'Tap the dice to roll. Your token moves forward that many spaces. Whatever you land on decides what happens next — buy it, pay rent, or trigger a surprise.'),
            _RuleSection('🏠 Buying a Plot',
              'Land on an empty plot and you can buy it:\n• Give it a name\n• Pick an icon\n• Drag the slider to set your price — anywhere in the plot\'s price range\n• Tap Confirm\n\nLower price = more cash left for your next plot. Higher price = this plot is worth more later. Not enough cash and the Confirm button won\'t let you through.'),
            _RuleSection('💰 Rent',
              'Land on someone else\'s plot and you pay them 8% of what they paid for it.'),
            _RuleSection('📈 Prices Go Up Over Time',
              'After every full round, all owned plots quietly gain value:\n• Farms: +1%\n• Homes: +2%\n• Shops: +4%\n• Highway & premium plots: +5–6%\n\nHang onto plots and they grow — that\'s free money over time.'),
            _RuleSection('🌾 Farm Income',
              'Own a farm? It pays you ₹2L every round, automatically. More farms = more steady income.'),
            _RuleSection('🎁 Surprise Tiles',
              'Land on a Surprise or Lucky tile and something random happens — a detail card pops up showing exactly what:\n✅ Good: cash bonus, grant, harvest payout\n❌ Bad: tax hit, storm damage, repair bill\n⚡ Other: a Shield, an extra turn, or getting moved back'),
            _RuleSection('🎲6️⃣ Roll a 6, Land on Surprise',
              'This one\'s guaranteed, not random: roll exactly a 6 and land on Surprise, and you skip your next turn.\n\nSince turns go in order, this means your opponent plays their normal turn — then plays again right away, because yours got skipped. So in a 2-player game, they effectively get two turns in a row before it\'s your turn again.'),
            _RuleSection('🏦 The Bank',
              'Tap the Bank tile on the board, or tap any player\'s card, to open it. From there you can:\n• Deposit cash to keep it safe\n• Withdraw cash back out\n• Take a loan for instant cash (pay it back with 5% interest)\n• Send money to another player'),
            _RuleSection('🛡️ Shield',
              'A Shield saves you from paying rent one time. The very next time you\'d owe rent, you pay nothing — then the Shield is used up.'),
            _RuleSection('🏆 How the Game Ends',
              'Once every plot on the board has been bought, the game is over. Whoever has the highest total money — cash, bank savings, and plot values combined, minus loans — wins.'),
          ],
        )),
      ]),
    ),
  );
}

class _RuleSection extends StatelessWidget {
  final String title;
  final String body;
  const _RuleSection(this.title, this.body);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.appSurface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.appBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.accent,
          fontSize: 13, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(body, style: const TextStyle(color: AppColors.textSecondary,
          fontSize: 12, height: 1.5)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// End Screen
// ─────────────────────────────────────────────────────────────────────────────
class _EndScreen extends StatelessWidget {
  final GameStateModel gs;
  const _EndScreen({required this.gs});

  @override
  Widget build(BuildContext context) {
    final ranked = gs.rankedPlayers;
    final winner = ranked.first;
    final medals = ['🥇','🥈','🥉'];

    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(child: Column(children: [
        const SizedBox(height: 20),
        // Winner celebration
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              winner.color.withValues(alpha: 0.3),
              winner.color.withValues(alpha: 0.08),
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(children: [
            const Text('🏆 TOWNSHIP FULLY DEVELOPED!', style: TextStyle(
              color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.w900,
              letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Container(width: 60, height: 60,
              decoration: BoxDecoration(color: winner.color, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3)),
              child: Center(child: Text(
                winner.displayName.isNotEmpty
                    ? winner.displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w900)))),
            const SizedBox(height: 8),
            Text(winner.displayName, style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
            Text('🏆 Winner • Net Worth: ${_f(winner.netWorth)}',
              style: const TextStyle(color: AppColors.success, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('Final Leaderboard', style: TextStyle(
              color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ranked.length,
            itemBuilder: (_, i) {
              final p = ranked[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: i == 0
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.appCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: i == 0
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : AppColors.appBorder),
                ),
                child: Row(children: [
                  Text(i < 3 ? medals[i] : '${i+1}.',
                    style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                    child: Center(child: Text(
                      p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w900)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.displayName, style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14,
                        fontWeight: FontWeight.w700)),
                      Text('Cash: ${_f(p.money)}  Bank: ${_f(p.bankBalance)}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                    ])),
                  Text(_f(p.netWorth), style: const TextStyle(
                    color: AppColors.success, fontSize: 15,
                    fontWeight: FontWeight.w900)),
                ]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('PLAY AGAIN', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
      ])),
    );
  }

  String _f(double v) {
    if (v >= 10000000) return '₹${(v/10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '₹${(v/100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '₹${(v/1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}
