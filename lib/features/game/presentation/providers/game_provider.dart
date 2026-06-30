import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_state_model.dart';
import '../../domain/models/tile_model.dart';

final gameProvider =
    StateNotifierProvider<GameNotifier, GameStateModel?>((ref) => GameNotifier());

final diceRollingProvider = StateProvider<bool>((ref) => false);

class GameNotifier extends StateNotifier<GameStateModel?> {
  final _rng = Random();
  GameNotifier() : super(null);

  void initGame(GameStateModel initialState) {
    state = initialState;
  }

  Future<void> rollDice(WidgetRef ref) async {
    if (state == null) return;
    final gs = state!;
    if (gs.phase != GamePhase.playing && gs.phase != GamePhase.finalRound) return;

    final currentPlayer = gs.currentPlayer;

    if (currentPlayer.skipNextTurn) {
      state = gs.copyWith(
        players: gs.players.map((p) {
          if (p.id == currentPlayer.id) return p.copyWith(skipNextTurn: false);
          return p;
        }).toList(),
        currentPlayerIndex: gs.nextPlayerIndex,
        eventMessage: '⏭️ ${currentPlayer.displayName} skipped their turn!',
        lastEvent: GameEvent.none,
      );
      return;
    }

    ref.read(diceRollingProvider.notifier).state = true;
    await Future.delayed(const Duration(milliseconds: 800));

    final diceValue = _rng.nextInt(6) + 1;
    final newPosition = (currentPlayer.position + diceValue) % gs.boardSize;
    final passedGo = newPosition < currentPlayer.position;
    final salaryBonus = passedGo ? _getSalary(gs.boardSize) : 0.0;

    final updatedPlayers = gs.players.map((p) {
      if (p.id == currentPlayer.id) {
        return p.copyWith(
          position: newPosition,
          money: p.money + salaryBonus,
        );
      }
      return p;
    }).toList();

    ref.read(diceRollingProvider.notifier).state = false;

    final landedTile = gs.tiles[newPosition];

    state = gs.copyWith(
      players: updatedPlayers,
      lastDiceValue: diceValue,
      lastEvent: _eventForTile(landedTile),
      eventMessage: passedGo
          ? '🏠 ${currentPlayer.displayName} passed GO! Collected ${_fmt(salaryBonus)}'
          : '🎲 ${currentPlayer.displayName} rolled $diceValue — landed on ${landedTile.displayName}',
    );

    await _handleTileLanding(landedTile);
  }

  Future<void> _handleTileLanding(TileModel tile) async {
    if (state == null) return;
    final gs = state!;
    final currentPlayer = gs.currentPlayer;

    switch (tile.type) {
      case TileType.tax:
        final taxAmount = (currentPlayer.money * 0.1).roundToDouble();
        state = gs.copyWith(
          players: gs.players.map((p) {
            if (p.id == currentPlayer.id) return p.copyWith(money: p.money - taxAmount);
            return p;
          }).toList(),
          eventMessage: '💰 ${currentPlayer.displayName} paid tax ${_fmt(taxAmount)}!',
          lastEvent: GameEvent.landedOnTax,
        );

      case TileType.surprise:
        await _handleSurprise();

      case TileType.property:
        if (tile.isOwned && tile.ownerId != currentPlayer.id) {
          await _collectRent(tile);
        }

      default:
        break;
    }
  }

  Future<void> _handleSurprise() async {
    if (state == null) return;
    final gs = state!;
    final p = gs.currentPlayer;
    final roll = _rng.nextInt(5);

    switch (roll) {
      case 0:
        state = gs.copyWith(
          players: gs.players.map((pl) =>
            pl.id == p.id ? pl.copyWith(money: pl.money + 50000) : pl).toList(),
          eventMessage: '🎉 Surprise! ${p.displayName} received ₹50,000 from the bank!',
          lastEvent: GameEvent.landedOnSurprise,
        );
      case 1:
        state = gs.copyWith(
          players: gs.players.map((pl) =>
            pl.id == p.id ? pl.copyWith(hasShield: true) : pl).toList(),
          eventMessage: '🛡️ Surprise! ${p.displayName} got a Shield!',
          lastEvent: GameEvent.landedOnSurprise,
        );
      case 2:
        final newPos = (p.position - 3 + gs.boardSize) % gs.boardSize;
        state = gs.copyWith(
          players: gs.players.map((pl) =>
            pl.id == p.id ? pl.copyWith(position: newPos) : pl).toList(),
          eventMessage: '😱 Surprise! ${p.displayName} moved back 3 spaces!',
          lastEvent: GameEvent.landedOnSurprise,
        );
      case 3:
        state = gs.copyWith(
          players: gs.players.map((pl) =>
            pl.id == p.id ? pl.copyWith(skipNextTurn: true) : pl).toList(),
          eventMessage: '⏭️ Surprise! ${p.displayName} will skip next turn!',
          lastEvent: GameEvent.landedOnSurprise,
        );
      default:
        state = gs.copyWith(
          players: gs.players.map((pl) =>
            pl.id == p.id ? pl.copyWith(money: pl.money + 25000) : pl).toList(),
          eventMessage: '✨ Surprise! ${p.displayName} found ₹25,000!',
          lastEvent: GameEvent.landedOnSurprise,
        );
    }
  }

  Future<void> _collectRent(TileModel tile) async {
    if (state == null) return;
    final gs = state!;
    final payer = gs.currentPlayer;
    final rent = tile.currentRent;

    if (payer.hasShield) {
      state = gs.copyWith(
        players: gs.players.map((p) =>
          p.id == payer.id ? p.copyWith(hasShield: false) : p).toList(),
        eventMessage: '🛡️ ${payer.displayName}\'s shield blocked the rent!',
        lastEvent: GameEvent.rentPaid,
      );
      return;
    }

    final owner = gs.players.firstWhere((p) => p.id == tile.ownerId,
        orElse: () => payer);

    state = gs.copyWith(
      players: gs.players.map((p) {
        if (p.id == payer.id) return p.copyWith(money: p.money - rent);
        if (p.id == tile.ownerId) return p.copyWith(money: p.money + rent);
        return p;
      }).toList(),
      eventMessage: '💸 ${payer.displayName} paid ${_fmt(rent)} rent to ${owner.displayName}!',
      lastEvent: GameEvent.rentPaid,
    );
  }

  void buyProperty(String playerId) {
    if (state == null) return;
    final gs = state!;
    final player = gs.players.firstWhere((p) => p.id == playerId);
    final tile = gs.tiles[player.position];

    if (!tile.isPurchasable || tile.isOwned) return;
    if (player.money < tile.price!) return;

    state = gs.copyWith(
      tiles: gs.tiles.map((t) =>
        t.index == tile.index ? t.copyWith(ownerId: playerId) : t).toList(),
      players: gs.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(
            money: p.money - tile.price!,
            ownedPropertyIds: [...p.ownedPropertyIds, tile.index.toString()],
          );
        }
        return p;
      }).toList(),
      eventMessage: '🏠 ${player.displayName} bought ${tile.displayName} for ${_fmt(tile.price!)}!',
      lastEvent: GameEvent.propertyBought,
    );
  }
void skipProperty() {
  if (state == null) return;
  state = state!.copyWith(lastEvent: GameEvent.none, clearEventMessage: true);
}
  void endTurn() {
    if (state == null) return;
    final gs = state!;

    if (gs.allPropertiesOwned && gs.phase == GamePhase.playing) {
      state = gs.copyWith(
        phase: GamePhase.finalRound,
        currentPlayerIndex: gs.nextPlayerIndex,
        eventMessage: '🏁 All properties owned! Final rounds begin!',
        lastEvent: GameEvent.none,
      );
      return;
    }

    if (gs.phase == GamePhase.finalRound) {
      if (gs.currentPlayerIndex == gs.players.length - 1) {
        final newRound = gs.finalRoundsCurrent + 1;
        if (newRound >= gs.finalRoundsTotal) {
          state = gs.copyWith(
            phase: GamePhase.ended,
            lastEvent: GameEvent.gameEnded,
            eventMessage: '🏆 Game Over! Calculating winner...',
          );
          return;
        }
        state = gs.copyWith(
          finalRoundsCurrent: newRound,
          currentPlayerIndex: gs.nextPlayerIndex,
          lastEvent: GameEvent.none,
          eventMessage: 'Final Round ${newRound + 1} of ${gs.finalRoundsTotal}',
        );
        return;
      }
    }

    state = gs.copyWith(
      currentPlayerIndex: gs.nextPlayerIndex,
      lastEvent: GameEvent.none,
      eventMessage: null,
    );
  }

  double _getSalary(int boardSize) {
    if (boardSize == 50) return 200000;
    if (boardSize == 100) return 400000;
    return 100000;
  }

  GameEvent _eventForTile(TileModel tile) {
    switch (tile.type) {
      case TileType.property:   return GameEvent.landedOnProperty;
      case TileType.surprise:   return GameEvent.landedOnSurprise;
      case TileType.luckyWheel: return GameEvent.landedOnLuckyWheel;
      case TileType.tax:        return GameEvent.landedOnTax;
      case TileType.bank:       return GameEvent.landedOnBank;
      case TileType.start:      return GameEvent.landedOnStart;
    }
  }

  String _fmt(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }
}