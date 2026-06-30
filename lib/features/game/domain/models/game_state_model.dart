import 'package:equatable/equatable.dart';
import 'player_model.dart';
import 'tile_model.dart';

enum GamePhase { waiting, playing, finalRound, ended }

enum GameEvent {
  none,
  rolledDice,
  landedOnProperty,
  landedOnSurprise,
  landedOnLuckyWheel,
  landedOnTax,
  landedOnBank,
  landedOnStart,
  propertyBought,
  rentPaid,
  playerBankrupt,
  gameEnded,
}

class GameStateModel extends Equatable {
  final String gameId;
  final List<PlayerModel> players;
  final List<TileModel> tiles;
  final int currentPlayerIndex;
  final GamePhase phase;
  final GameEvent lastEvent;
  final int boardSize;
  final int finalRoundsTotal;
  final int finalRoundsCurrent;
  final String? eventMessage;
  final bool isOnline;
  final String? adminId;
  final int? lastDiceValue;
  final double bankBalance;

  const GameStateModel({
    required this.gameId,
    required this.players,
    required this.tiles,
    this.currentPlayerIndex = 0,
    this.phase = GamePhase.waiting,
    this.lastEvent = GameEvent.none,
    required this.boardSize,
    this.finalRoundsTotal = 5,
    this.finalRoundsCurrent = 0,
    this.eventMessage,
    this.isOnline = false,
    this.adminId,
    this.lastDiceValue,
    this.bankBalance = double.infinity,
  });

  PlayerModel get currentPlayer => players[currentPlayerIndex];

  bool get allPropertiesOwned {
    final properties = tiles.where((t) => t.isPurchasable);
    return properties.every((t) => t.isOwned);
  }

  int get nextPlayerIndex {
    int next = (currentPlayerIndex + 1) % players.length;
    // Skip bankrupt players
    while (players[next].isBankrupt && next != currentPlayerIndex) {
      next = (next + 1) % players.length;
    }
    return next;
  }

  List<PlayerModel> get rankedPlayers {
    final sorted = [...players];
    sorted.sort((a, b) => b.netWorth.compareTo(a.netWorth));
    return sorted;
  }

  GameStateModel copyWith({
    String? gameId,
    List<PlayerModel>? players,
    List<TileModel>? tiles,
    int? currentPlayerIndex,
    GamePhase? phase,
    GameEvent? lastEvent,
    int? boardSize,
    int? finalRoundsTotal,
    int? finalRoundsCurrent,
    String? eventMessage,
    bool? isOnline,
    String? adminId,
    int? lastDiceValue,
    double? bankBalance,
  }) {
    return GameStateModel(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      tiles: tiles ?? this.tiles,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      lastEvent: lastEvent ?? this.lastEvent,
      boardSize: boardSize ?? this.boardSize,
      finalRoundsTotal: finalRoundsTotal ?? this.finalRoundsTotal,
      finalRoundsCurrent: finalRoundsCurrent ?? this.finalRoundsCurrent,
      eventMessage: eventMessage ?? this.eventMessage,
      isOnline: isOnline ?? this.isOnline,
      adminId: adminId ?? this.adminId,
      lastDiceValue: lastDiceValue ?? this.lastDiceValue,
      bankBalance: bankBalance ?? this.bankBalance,
    );
  }

  Map<String, dynamic> toMap() => {
    'gameId': gameId,
    'players': players.map((p) => p.toMap()).toList(),
    'tiles': tiles.map((t) => t.toMap()).toList(),
    'currentPlayerIndex': currentPlayerIndex,
    'phase': phase.name,
    'lastEvent': lastEvent.name,
    'boardSize': boardSize,
    'finalRoundsTotal': finalRoundsTotal,
    'finalRoundsCurrent': finalRoundsCurrent,
    'eventMessage': eventMessage,
    'isOnline': isOnline,
    'adminId': adminId,
    'lastDiceValue': lastDiceValue,
  };

  factory GameStateModel.fromMap(Map<String, dynamic> map) => GameStateModel(
    gameId: map['gameId'] ?? '',
    players:
        (map['players'] as List<dynamic>?)
            ?.map((p) => PlayerModel.fromMap(p))
            .toList() ??
        [],
    tiles:
        (map['tiles'] as List<dynamic>?)
            ?.map((t) => TileModel.fromMap(t))
            .toList() ??
        [],
    currentPlayerIndex: map['currentPlayerIndex'] ?? 0,
    phase: GamePhase.values.firstWhere(
      (p) => p.name == map['phase'],
      orElse: () => GamePhase.waiting,
    ),
    lastEvent: GameEvent.values.firstWhere(
      (e) => e.name == map['lastEvent'],
      orElse: () => GameEvent.none,
    ),
    boardSize: map['boardSize'] ?? 25,
    finalRoundsTotal: map['finalRoundsTotal'] ?? 5,
    finalRoundsCurrent: map['finalRoundsCurrent'] ?? 0,
    eventMessage: map['eventMessage'],
    isOnline: map['isOnline'] ?? false,
    adminId: map['adminId'],
    lastDiceValue: map['lastDiceValue'],
  );

  @override
  List<Object?> get props => [
    gameId,
    players,
    tiles,
    currentPlayerIndex,
    phase,
    lastEvent,
    finalRoundsCurrent,
  ];
}