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
  final int roundsPlayed;
  final String? eventMessage;
  final bool isOnline;
  final List<String> activityLog;
  final String? adminId;
  final int? lastDiceValue;
  final bool isMoving;
  final double? customPriceMin; // custom-setup override for standard plots
  final double? customPriceMax;

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
    this.roundsPlayed = 0,
    this.eventMessage,
    this.isOnline = false,
    this.adminId,
    this.lastDiceValue,
    this.isMoving = false,
    this.activityLog = const [],
    this.customPriceMin,
    this.customPriceMax,
  });

  PlayerModel get currentPlayer => players[currentPlayerIndex];

  bool get allPropertiesOwned {
    final properties = tiles.where((t) => t.isPurchasable);
    if (properties.isEmpty) return false;
    return properties.every((t) => t.isOwned);
  }

  int get nextPlayerIndex {
    int next = (currentPlayerIndex + 1) % players.length;
    int loops = 0;
    while (players[next].isBankrupt && loops < players.length) {
      next = (next + 1) % players.length;
      loops++;
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
    List<String>? activityLog,
    List<TileModel>? tiles,
    int? currentPlayerIndex,
    GamePhase? phase,
    GameEvent? lastEvent,
    int? boardSize,
    int? finalRoundsTotal,
    int? finalRoundsCurrent,
    int? roundsPlayed,
    String? eventMessage,
    bool? isOnline,
    String? adminId,
    int? lastDiceValue,
    bool clearEventMessage = false,
    bool? isMoving,
    double? customPriceMin,
    double? customPriceMax,
  }) {
    return GameStateModel(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      tiles: tiles ?? this.tiles,
      activityLog: activityLog ?? this.activityLog,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      lastEvent: lastEvent ?? this.lastEvent,
      boardSize: boardSize ?? this.boardSize,
      finalRoundsTotal: finalRoundsTotal ?? this.finalRoundsTotal,
      finalRoundsCurrent: finalRoundsCurrent ?? this.finalRoundsCurrent,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      eventMessage: clearEventMessage ? null : (eventMessage ?? this.eventMessage),
      isOnline: isOnline ?? this.isOnline,
      adminId: adminId ?? this.adminId,
      lastDiceValue: lastDiceValue ?? this.lastDiceValue,
      isMoving: isMoving ?? this.isMoving,
      customPriceMin: customPriceMin ?? this.customPriceMin,
      customPriceMax: customPriceMax ?? this.customPriceMax,
      
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
    'roundsPlayed': roundsPlayed,
    'eventMessage': eventMessage,
    'isOnline': isOnline,
    'activityLog': activityLog,
    'adminId': adminId,
    'lastDiceValue': lastDiceValue,
    'isMoving': isMoving,
    'customPriceMin': customPriceMin,
    'customPriceMax': customPriceMax,
  };

  factory GameStateModel.fromMap(Map<String, dynamic> map) => GameStateModel(
    gameId: map['gameId'] ?? '',
    players: ((map['players'] as List?) ?? [])
        .map((p) => PlayerModel.fromMap(Map<String, dynamic>.from(p)))
        .toList(),
    tiles: ((map['tiles'] as List?) ?? [])
        .map((t) => TileModel.fromMap(Map<String, dynamic>.from(t)))
        .toList(),
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
    roundsPlayed: map['roundsPlayed'] ?? 0,
    eventMessage: map['eventMessage'],
    isOnline: map['isOnline'] ?? false,
    activityLog: List<String>.from(map['activityLog'] ?? []),
    adminId: map['adminId'],
    lastDiceValue: map['lastDiceValue'],
    isMoving: map['isMoving'] ?? false,
    customPriceMin: map['customPriceMin']?.toDouble(),
    customPriceMax: map['customPriceMax']?.toDouble(),
  );

  @override
  List<Object?> get props => [
        gameId,
        players,
        activityLog,
        tiles,
        currentPlayerIndex,
        phase,
        lastEvent,
        finalRoundsCurrent,
        isMoving,
      ];
}