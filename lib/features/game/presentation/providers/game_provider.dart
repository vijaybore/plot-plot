import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/game_state_model.dart';
import '../../domain/models/player_model.dart';
import '../../domain/models/tile_model.dart';
import 'dart:math';

final gameProvider =
    StateNotifierProvider<GameNotifier, GameStateModel?>((ref) => GameNotifier());

final diceRollingProvider = StateProvider<bool>((ref) => false);

class GameNotifier extends StateNotifier<GameStateModel?> {
  final _rng = Random();
  GameNotifier() : super(null);

  // ── Init ─────────────────────────────────────────────────────────
  void initGame(GameStateModel initialState) => state = initialState;

  // ── Dice ─────────────────────────────────────────────────────────
  Future<void> rollDice(WidgetRef ref) async {
    if (state == null) return;
    final gs = state!;
    if (gs.phase != GamePhase.playing && gs.phase != GamePhase.finalRound) return;

    final cur = gs.currentPlayer;

    if (cur.skipNextTurn) {
      _log('⏭️ ${cur.displayName} skipped their turn');
      state = gs.copyWith(
        players: gs.players.map((p) =>
            p.id == cur.id ? p.copyWith(skipNextTurn: false) : p).toList(),
        currentPlayerIndex: gs.nextPlayerIndex,
        eventMessage: '⏭️ ${cur.displayName} skipped their turn!',
        lastEvent: GameEvent.none,
      );
      return;
    }

    ref.read(diceRollingProvider.notifier).state = true;
    await Future.delayed(const Duration(milliseconds: 700));

    final dice  = _rng.nextInt(6) + 1;
    final total = gs.tiles.isNotEmpty ? gs.tiles.length : gs.boardSize;

    ref.read(diceRollingProvider.notifier).state = false;

    // Enter "moving" mode — buy/rent prompts stay hidden until the token
    // has actually finished hopping across the board.
    state = state!.copyWith(
      lastDiceValue: dice,
      isMoving: true,
      lastEvent: GameEvent.none,
      clearEventMessage: true,
    );

    // Hop ONE tile at a time — same mechanic as a Ludo token — writing the
    // real position into game state on every hop so the board (which reads
    // position directly) visibly moves step by step instead of teleporting.
    int stepPos = cur.position;
    bool passedGo = false;
    for (int step = 0; step < dice; step++) {
      if (state == null) return;
      stepPos = (stepPos + 1) % total;
      if (stepPos == 0) passedGo = true;
      final gsNow = state!;
      state = gsNow.copyWith(
        players: gsNow.players.map((p) =>
            p.id == cur.id ? p.copyWith(position: stepPos) : p).toList(),
      );
      await Future.delayed(const Duration(milliseconds: 220));
    }

    if (state == null) return;
    final gs2 = state!;
    final salary = passedGo
        ? (AppConstants.salaryByBoardSize[gs2.boardSize] ?? AppConstants.defaultSalary)
        : 0.0;

    final landedTile = gs2.tiles[stepPos];
    String msg;
    if (passedGo) {
      msg = '🏠 ${cur.displayName} passed GO! Collected ${_f(salary)}';
    } else {
      msg = '🎲 ${cur.displayName} rolled $dice → landed on ${landedTile.displayName}';
    }
    _log(msg);

    state = gs2.copyWith(
      players: gs2.players.map((p) => p.id == cur.id
          ? p.copyWith(money: p.money + salary)
          : p).toList(),
      isMoving: false,
      lastEvent: _eventFor(landedTile),
      eventMessage: msg,
    );

    await _handleTileLanding(landedTile);
  }

  Future<void> _handleTileLanding(TileModel tile) async {
    if (state == null) return;
    final gs = state!;
    final cur = gs.currentPlayer;

    switch (tile.type) {
      case TileType.tax:
        final tax = (cur.money * 0.08).clamp(0, cur.money).roundToDouble();
        final msg = '💰 ${cur.displayName} paid city tax ${_f(tax)}';
        _log(msg);
        state = gs.copyWith(
          players: gs.players.map((p) => p.id == cur.id
              ? p.copyWith(money: p.money - tax) : p).toList(),
          eventMessage: '$msg!',
          lastEvent: GameEvent.landedOnTax,
        );

      case TileType.surprise:
      case TileType.luckyWheel:
        // Special rule: rolling exactly a 6 to land on Surprise always
        // triggers the "Skip Next Turn" event (guaranteed, not random).
        // Because turns are round-robin, this means the OTHER player(s)
        // effectively get to play through this player's next turn before
        // it comes back around to them (in a 2-player game that means the
        // opponent plays twice in a row before this player rolls again).
        if (gs.lastDiceValue == 6) {
          await _handleLuckySixSkip();
        } else {
          await _handleSurprise();
        }

      case TileType.bank:
        // Just trigger the bank event — UI opens bank panel
        state = state!.copyWith(
          eventMessage: '🏦 ${cur.displayName} landed on Bank!',
          lastEvent: GameEvent.landedOnBank,
        );

      case TileType.property:
      case TileType.farmZone:
        if (tile.isOwned && tile.ownerId != cur.id) {
          await _collectRent(tile);
        }
        // else: own plot or unowned → BUY/SKIP handled by UI

      default:
        break;
    }
  }

  // ── Lucky Six → guaranteed Skip Turn ────────────────────────────────
  Future<void> _handleLuckySixSkip() async {
    if (state == null) return;
    final gs = state!;
    final p  = gs.currentPlayer;
    final msg = '🎲6️⃣🎁 Lucky Six! ${p.displayName} landed on Surprise and '
        'will skip their next turn!';
    _log(msg);
    state = gs.copyWith(
      players: gs.players.map((pl) =>
          pl.id == p.id ? pl.copyWith(skipNextTurn: true) : pl).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: msg,
      lastEvent: GameEvent.landedOnSurprise,
    );
  }

  // ── Surprise / Lucky Wheel ────────────────────────────────────────
  Future<void> _handleSurprise() async {
    if (state == null) return;
    final gs = state!;
    final p  = gs.currentPlayer;
    final roll = _rng.nextInt(12);
    String msg;
    List<PlayerModel> players = List.from(gs.players);

    switch (roll) {
      case 0:  // Lottery Win
        const bonus = 1000000.0;
        msg = '🎉 Lottery Win! ${p.displayName} won ${_f(bonus)}!';
        players = _updateMoney(players, p.id, bonus);
      case 1:  // Government Grant
        const grant = 1500000.0;
        msg = '🏛️ Government Grant! ${p.displayName} received ${_f(grant)}!';
        players = _updateMoney(players, p.id, grant);
      case 2:  // Farm Harvest
        const harvest = 500000.0;
        msg = '🌾 Farm Harvest! ${p.displayName} earned ${_f(harvest)}!';
        players = _updateMoney(players, p.id, harvest);
      case 3:  // Bonus Income
        const income = 800000.0;
        msg = '💰 Bonus Income! ${p.displayName} received ${_f(income)}!';
        players = _updateMoney(players, p.id, income);
      case 4:  // Shield
        msg = '🛡️ ${p.displayName} got a Shield — next rent blocked!';
        players = players.map((pl) =>
            pl.id == p.id ? pl.copyWith(hasShield: true) : pl).toList();
      case 5:  // Extra Turn
        msg = '🔄 Extra Turn! ${p.displayName} rolls again!';
        // Extra turn: don't advance player index on endTurn
        players = players.map((pl) =>
            pl.id == p.id ? pl.copyWith(skipNextTurn: false) : pl).toList();
      case 6:  // Tax Audit
        final fine = (p.money * 0.1).clamp(0, p.money).roundToDouble();
        msg = '🚨 Tax Audit! ${p.displayName} paid ${_f(fine)}';
        players = _updateMoney(players, p.id, -fine);
      case 7:  // Storm Damage
        final damage = (p.money * 0.07).clamp(0, p.money).roundToDouble();
        msg = '⛈️ Storm Damage! ${p.displayName} lost ${_f(damage)}';
        players = _updateMoney(players, p.id, -damage);
      case 8:  // Maintenance
        const cost = 300000.0;
        msg = '🔧 Maintenance Cost! ${p.displayName} paid ${_f(cost)}';
        players = _updateMoney(players, p.id, -cost);
      case 9:  // Market Crash — all owned properties -5%
        msg = '📉 Market Crash! All property values dropped 5%';
        // applied to tiles below
      case 10: // Move Back
        final newPos = (p.position - 3 + (state!.tiles.isNotEmpty
            ? state!.tiles.length : state!.boardSize)) %
            (state!.tiles.isNotEmpty ? state!.tiles.length : state!.boardSize);
        msg = '😱 Move Back 3! ${p.displayName} moved back';
        players = players.map((pl) =>
            pl.id == p.id ? pl.copyWith(position: newPos) : pl).toList();
      default: // Skip next turn
        msg = '⏭️ Skip! ${p.displayName} will skip next turn';
        players = players.map((pl) =>
            pl.id == p.id ? pl.copyWith(skipNextTurn: true) : pl).toList();
    }

    _log(msg);

    // Apply market crash to tiles
    List<TileModel> tiles = state!.tiles;
    if (roll == 9) {
      tiles = tiles.map((t) {
        if (t.isOwned && t.price != null) {
          return t.copyWith(price: t.price! * 0.95);
        }
        return t;
      }).toList();
    }

    state = state!.copyWith(
      players: players,
      tiles: tiles,
      activityLog: [...state!.activityLog, msg],
      eventMessage: msg,
      lastEvent: GameEvent.landedOnSurprise,
    );
  }

  // ── Rent collection ───────────────────────────────────────────────
  Future<void> _collectRent(TileModel tile) async {
    if (state == null) return;
    final gs    = state!;
    final payer = gs.currentPlayer;
    final rent  = tile.currentRent;

    if (payer.hasShield) {
      final msg = '🛡️ ${payer.displayName}\'s shield blocked ₹${_f(rent)} rent!';
      _log(msg);
      state = gs.copyWith(
        players: gs.players.map((p) =>
            p.id == payer.id ? p.copyWith(hasShield: false) : p).toList(),
        activityLog: [...gs.activityLog, msg],
        eventMessage: msg,
        lastEvent: GameEvent.rentPaid,
      );
      return;
    }

    final owner = gs.players.firstWhere((p) => p.id == tile.ownerId,
        orElse: () => payer);

    final msg = '💸 ${payer.displayName} paid ${_f(rent)} rent to ${owner.displayName}';
    _log(msg);

    state = gs.copyWith(
      players: gs.players.map((p) {
        if (p.id == payer.id) return p.copyWith(money: (p.money - rent).clamp(0, double.infinity));
        if (p.id == tile.ownerId) return p.copyWith(money: p.money + rent);
        return p;
      }).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: '$msg!',
      lastEvent: GameEvent.rentPaid,
    );
  }

  // ── Buy property ─────────────────────────────────────────────────
  void buyProperty(String playerId, {
    required String customName,
    required double price,
    String? customEmoji,
  }) {
    if (state == null) return;
    final gs     = state!;
    final player = gs.players.firstWhere((p) => p.id == playerId);
    final tile   = gs.tiles[player.position];

    if (tile.ownerId != null) return;
    if (!tile.isPurchasable && tile.type != TileType.farmZone) return;
    if (player.money < price) return;

    final name = customName.trim().isEmpty ? tile.name : customName.trim();
    // Include the plot number (e.g. "P-001") alongside the custom name.
    // Without it, a plot renamed to something like "v" reads as "A bought
    // 'v'" — indistinguishable from "A bought player V" in the activity
    // feed. The plot number disambiguates it from any player name.
    final msg  = '🏠 ${player.displayName} purchased "$name" '
        '(${tile.plotNumber}) for ${_f(price)}';
    _log(msg);

    state = gs.copyWith(
      tiles: gs.tiles.map((t) => t.index == tile.index
          ? t.copyWith(ownerId: playerId, price: price,
              customName: name, customEmoji: customEmoji)
          : t).toList(),
      players: gs.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(
            money: p.money - price,
            ownedPropertyIds: [...p.ownedPropertyIds, tile.index.toString()],
          );
        }
        return p;
      }).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: '$msg!',
      lastEvent: GameEvent.propertyBought,
    );
  }

  // ── Rename ────────────────────────────────────────────────────────
  void renamePlot(String playerId, int tileIndex, String newName,
      {String? newEmoji}) {
    if (state == null) return;
    final gs   = state!;
    final tile = gs.tiles[tileIndex];
    if (tile.ownerId != playerId) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final msg = '✏️ ${gs.currentPlayer.displayName} renamed plot to "$trimmed"';
    _log(msg);
    state = gs.copyWith(
      tiles: gs.tiles.map((t) => t.index == tileIndex
          ? t.copyWith(customName: trimmed, customEmoji: newEmoji) : t).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: msg,
    );
  }

  void skipProperty() {
    if (state == null) return;
    state = state!.copyWith(lastEvent: GameEvent.none, clearEventMessage: true);
  }

  // ── End turn ─────────────────────────────────────────────────────
  void endTurn() {
    if (state == null) return;
    final gs = state!;

    // Apply appreciation if a full round just completed (last player ended)
    final isRoundEnd = gs.currentPlayerIndex == gs.players.length - 1;
    List<TileModel> tiles = gs.tiles;
    List<String> log = List.from(gs.activityLog);
    int roundsPlayed = gs.roundsPlayed;

    if (isRoundEnd) {
      tiles = _applyAppreciation(tiles);
      _applyFarmIncome(gs, log);
      roundsPlayed += 1;
      log.add('📈 Round $roundsPlayed complete — properties appreciated!');

      // Game ends once the agreed number of rounds is reached — win goes to
      // the highest net worth. This doesn't require every plot to be sold;
      // with only 2 players and real plot prices that could take forever.
      // Selling out early is still allowed and simply means more rent income
      // for whoever bought, not an instant end.
      if (roundsPlayed >= gs.finalRoundsTotal) {
        log.add('🏆 Game Over! Winner: ${gs.rankedPlayers.first.displayName}');
        state = gs.copyWith(
          tiles: tiles,
          activityLog: log,
          roundsPlayed: roundsPlayed,
          phase: GamePhase.ended,
          lastEvent: GameEvent.gameEnded,
          eventMessage: '🏆 Game Over! ${gs.rankedPlayers.first.displayName} wins!',
        );
        return;
      }
    }

    state = gs.copyWith(
      tiles: tiles,
      activityLog: log,
      roundsPlayed: roundsPlayed,
      currentPlayerIndex: gs.nextPlayerIndex,
      lastEvent: GameEvent.none,
      eventMessage: null,
    );
  }

  // ── Banking ───────────────────────────────────────────────────────
  void depositToBank(String playerId, double amount) {
    if (state == null) return;
    final gs = state!;
    final p  = gs.players.firstWhere((pl) => pl.id == playerId);
    if (amount <= 0 || p.money < amount) return;

    final msg = '🏦 ${p.displayName} deposited ${_f(amount)} to bank';
    _log(msg);
    state = gs.copyWith(
      players: gs.players.map((pl) => pl.id == playerId
          ? pl.copyWith(money: pl.money - amount, bankBalance: pl.bankBalance + amount)
          : pl).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: msg,
    );
  }

  void withdrawFromBank(String playerId, double amount) {
    if (state == null) return;
    final gs = state!;
    final p  = gs.players.firstWhere((pl) => pl.id == playerId);
    if (amount <= 0 || p.bankBalance < amount) return;

    final msg = '🏦 ${p.displayName} withdrew ${_f(amount)} from bank';
    _log(msg);
    state = gs.copyWith(
      players: gs.players.map((pl) => pl.id == playerId
          ? pl.copyWith(money: pl.money + amount, bankBalance: pl.bankBalance - amount)
          : pl).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: msg,
    );
  }

  void takeLoan(String playerId, double amount) {
    if (state == null) return;
    final gs = state!;
    final p  = gs.players.firstWhere((pl) => pl.id == playerId);
    if (amount <= 0) return;
    final maxLoan = p.netWorth * AppConstants.maxLoanMultiplier;
    if (p.loanAmount + amount > maxLoan && maxLoan > 0) return;

    final msg = '💳 ${p.displayName} took a loan of ${_f(amount)}';
    _log(msg);
    state = gs.copyWith(
      players: gs.players.map((pl) => pl.id == playerId
          ? pl.copyWith(money: pl.money + amount, loanAmount: pl.loanAmount + amount)
          : pl).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: msg,
    );
  }

  void repayLoan(String playerId, double amount) {
    if (state == null) return;
    final gs = state!;
    final p  = gs.players.firstWhere((pl) => pl.id == playerId);
   final double repay =
    amount.clamp(0.0, p.loanAmount).toDouble();
    if (repay <= 0 || p.money < repay) return;

    final msg = '💳 ${p.displayName} repaid ${_f(repay)} of loan';
    _log(msg);
    state = gs.copyWith(
      players: gs.players.map((pl) => pl.id == playerId
          ? pl.copyWith(money: pl.money - repay, loanAmount: pl.loanAmount - repay)
          : pl).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: msg,
    );
  }

  void transferMoney(String fromId, String toId, double amount) {
    if (state == null) return;
    final gs   = state!;
    final from = gs.players.firstWhere((p) => p.id == fromId);
    final to   = gs.players.firstWhere((p) => p.id == toId);
    if (amount <= 0 || from.money < amount) return;

    final msg = '💸 ${from.displayName} transferred ${_f(amount)} to ${to.displayName}';
    _log(msg);
    state = gs.copyWith(
      players: gs.players.map((p) {
        if (p.id == fromId) return p.copyWith(money: p.money - amount);
        if (p.id == toId)   return p.copyWith(money: p.money + amount);
        return p;
      }).toList(),
      activityLog: [...gs.activityLog, msg],
      eventMessage: msg,
    );
  }

  // ── Appreciation ─────────────────────────────────────────────────
  List<TileModel> _applyAppreciation(List<TileModel> tiles) {
    return tiles.map((t) {
      if (!t.isOwned || t.price == null) return t;
      final key = t.plotType.name;
      final rate = AppConstants.appreciationRate[key] ?? 0.02;
      return t.copyWith(price: t.price! * (1 + rate));
    }).toList();
  }

  void _applyFarmIncome(GameStateModel gs, List<String> log) {
    // Farm income distributed at end of round
    final newPlayers = gs.players.map((p) {
      final farmTiles = gs.tiles.where((t) =>
          t.ownerId == p.id &&
          (t.plotType == PlotType.farm || t.type == TileType.farmZone));
      if (farmTiles.isEmpty) return p;
      double income = 0;
      for (final _ in farmTiles) {
        income += AppConstants.farmIncome[1] ?? 200000;
      }
      log.add('🌾 ${p.displayName} earned ${_f(income)} farm income');
      return p.copyWith(money: p.money + income);
    }).toList();
    // Apply — we mutate state directly here
    if (state != null) {
      state = state!.copyWith(players: newPlayers);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────
  List<PlayerModel> _updateMoney(List<PlayerModel> list, String id, double delta) =>
      list.map((p) => p.id == id
          ? p.copyWith(money: (p.money + delta).clamp(0, double.infinity))
          : p).toList();

  void _log(String msg) {
    // Append to activity log (no state mutation — caller handles it)
    // Used purely as a side-channel; state updates include activityLog
  }

  GameEvent _eventFor(TileModel tile) {
    switch (tile.type) {
      case TileType.property:    return GameEvent.landedOnProperty;
      case TileType.farmZone:    return GameEvent.landedOnProperty;
      case TileType.surprise:    return GameEvent.landedOnSurprise;
      case TileType.luckyWheel:  return GameEvent.landedOnLuckyWheel;
      case TileType.tax:         return GameEvent.landedOnTax;
      case TileType.bank:        return GameEvent.landedOnBank;
      case TileType.start:       return GameEvent.landedOnStart;
    }
  }

  String _f(double v) {
    if (v >= 10000000) return '₹${(v/10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '₹${(v/100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '₹${(v/1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}
