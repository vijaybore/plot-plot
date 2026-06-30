import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

enum PlayerRole { admin, editor, player }

class PlayerModel extends Equatable {
  final String id;
  final String displayName;
  final String? photoUrl;
  final double money;
  final int position;
  final List<String> ownedPropertyIds;
  final List<FarmModel> farms;
  final List<BusinessModel> businesses;
  final double loanAmount;
  final bool hasShield;
  final bool skipNextTurn;
  final bool isOnline;
  final bool isBankrupt;
  final PlayerRole role;
  final int colorIndex;
  final int rank;

  const PlayerModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.money,
    this.position = 0,
    this.ownedPropertyIds = const [],
    this.farms = const [],
    this.businesses = const [],
    this.loanAmount = 0,
    this.hasShield = false,
    this.skipNextTurn = false,
    this.isOnline = true,
    this.isBankrupt = false,
    this.role = PlayerRole.player,
    required this.colorIndex,
    this.rank = 0,
  });

  Color get color => AppColors.playerColors[colorIndex % 7];

  double get netWorth {
    double total = money - loanAmount;
    for (final farm in farms) {
      total += farm.value;
    }
    for (final business in businesses) {
      total += business.value;
    }
    return total;
  }

  PlayerModel copyWith({
    String? id,
    String? displayName,
    String? photoUrl,
    double? money,
    int? position,
    List<String>? ownedPropertyIds,
    List<FarmModel>? farms,
    List<BusinessModel>? businesses,
    double? loanAmount,
    bool? hasShield,
    bool? skipNextTurn,
    bool? isOnline,
    bool? isBankrupt,
    PlayerRole? role,
    int? colorIndex,
    int? rank,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      money: money ?? this.money,
      position: position ?? this.position,
      ownedPropertyIds: ownedPropertyIds ?? this.ownedPropertyIds,
      farms: farms ?? this.farms,
      businesses: businesses ?? this.businesses,
      loanAmount: loanAmount ?? this.loanAmount,
      hasShield: hasShield ?? this.hasShield,
      skipNextTurn: skipNextTurn ?? this.skipNextTurn,
      isOnline: isOnline ?? this.isOnline,
      isBankrupt: isBankrupt ?? this.isBankrupt,
      role: role ?? this.role,
      colorIndex: colorIndex ?? this.colorIndex,
      rank: rank ?? this.rank,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'money': money,
        'position': position,
        'ownedPropertyIds': ownedPropertyIds,
        'farms': farms.map((f) => f.toMap()).toList(),
        'businesses': businesses.map((b) => b.toMap()).toList(),
        'loanAmount': loanAmount,
        'hasShield': hasShield,
        'skipNextTurn': skipNextTurn,
        'isOnline': isOnline,
        'isBankrupt': isBankrupt,
        'role': role.name,
        'colorIndex': colorIndex,
        'rank': rank,
      };

  factory PlayerModel.fromMap(Map<String, dynamic> map) => PlayerModel(
        id: map['id'] ?? '',
        displayName: map['displayName'] ?? '',
        photoUrl: map['photoUrl'],
        money: (map['money'] ?? 0).toDouble(),
        position: map['position'] ?? 0,
        ownedPropertyIds: List<String>.from(map['ownedPropertyIds'] ?? []),
        farms: (map['farms'] as List<dynamic>?)
                ?.map((f) => FarmModel.fromMap(f))
                .toList() ??
            [],
        businesses: (map['businesses'] as List<dynamic>?)
                ?.map((b) => BusinessModel.fromMap(b))
                .toList() ??
            [],
        loanAmount: (map['loanAmount'] ?? 0).toDouble(),
        hasShield: map['hasShield'] ?? false,
        skipNextTurn: map['skipNextTurn'] ?? false,
        isOnline: map['isOnline'] ?? true,
        isBankrupt: map['isBankrupt'] ?? false,
        role: PlayerRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => PlayerRole.player,
        ),
        colorIndex: map['colorIndex'] ?? 0,
        rank: map['rank'] ?? 0,
      );

  @override
  List<Object?> get props => [
        id,
        money,
        position,
        ownedPropertyIds,
        loanAmount,
        hasShield,
        skipNextTurn,
        isBankrupt,
        rank,
      ];
}

// ── Farm Model ──────────────────────────────────────
class FarmModel extends Equatable {
  final String id;
  final int level;
  final bool isMortgaged;

  const FarmModel({
    required this.id,
    this.level = 1,
    this.isMortgaged = false,
  });

  double get income => AppConstants.farmIncome[level] ?? 50000;
  double get value => income * 3;

  FarmModel copyWith({int? level, bool? isMortgaged}) => FarmModel(
        id: id,
        level: level ?? this.level,
        isMortgaged: isMortgaged ?? this.isMortgaged,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'level': level,
        'isMortgaged': isMortgaged,
      };

  factory FarmModel.fromMap(Map<String, dynamic> map) => FarmModel(
        id: map['id'] ?? '',
        level: map['level'] ?? 1,
        isMortgaged: map['isMortgaged'] ?? false,
      );

  @override
  List<Object?> get props => [id, level, isMortgaged];
}

// ── Business Model ───────────────────────────────────
enum BusinessType { shop, warehouse, hotel }

class BusinessModel extends Equatable {
  final String id;
  final String propertyId;
  final BusinessType type;
  final int level;

  const BusinessModel({
    required this.id,
    required this.propertyId,
    required this.type,
    this.level = 1,
  });

  double get value {
  switch (type) {
    case BusinessType.shop:
      return 300000.0 * level;
    case BusinessType.warehouse:
      return 500000.0 * level;
    case BusinessType.hotel:
      return 800000.0 * level;
  }
}

  double get passiveIncome => value * 0.05;

  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'type': type.name,
        'level': level,
      };

  factory BusinessModel.fromMap(Map<String, dynamic> map) => BusinessModel(
        id: map['id'] ?? '',
        propertyId: map['propertyId'] ?? '',
        type: BusinessType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => BusinessType.shop,
        ),
        level: map['level'] ?? 1,
      );

  @override
  List<Object?> get props => [id, propertyId, type, level];
}