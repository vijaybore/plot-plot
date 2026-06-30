import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum TileType { start, property, surprise, luckyWheel, tax, bank }

class TileModel extends Equatable {
  final int index;
  final TileType type;
  final String name;
  final double? price;
  final double? baseRent;
  final String? ownerId;
  final int upgradeLevel;
  final String? customName;
  final Color? customColor;
  final bool isAuction;
  final int side; // 0=bottom 1=left 2=top 3=right

  const TileModel({
    required this.index,
    required this.type,
    required this.name,
    this.price,
    this.baseRent,
    this.ownerId,
    this.upgradeLevel = 1,
    this.customName,
    this.customColor,
    this.isAuction = false,
    required this.side,
  });

  bool get isOwned => ownerId != null;
  bool get isPurchasable => type == TileType.property && price != null;

  String get displayName => customName ?? name;

  double get currentRent {
    if (baseRent == null) return 0;
    switch (upgradeLevel) {
      case 2: return baseRent! * 1.5;
      case 3: return baseRent! * 2.0;
      default: return baseRent!;
    }
  }

  double get currentValue {
    if (price == null) return 0;
    switch (upgradeLevel) {
      case 2: return price! * 1.5;
      case 3: return price! * 2.0;
      default: return price!;
    }
  }

  Color get tileColor {
    if (customColor != null) return customColor!;
    switch (type) {
      case TileType.start:      return const Color(0xFF1A1A2E);
      case TileType.property:   return const Color(0xFFFFFDE7);
      case TileType.surprise:   return const Color(0xFFFF9800);
      case TileType.luckyWheel: return const Color(0xFFFFD700);
      case TileType.tax:        return const Color(0xFFE74C3C);
      case TileType.bank:       return const Color(0xFF1565C0);
    }
  }

  // Property group color (top strip color like Monopoly)
  Color get groupColor {
    if (type != TileType.property) return tileColor;
    final groups = [
      const Color(0xFF8B4513), // brown
      const Color(0xFF87CEEB), // light blue
      const Color(0xFFFF69B4), // pink
      const Color(0xFFFF8C00), // orange
      const Color(0xFFFF0000), // red
      const Color(0xFFFFFF00), // yellow
      const Color(0xFF228B22), // green
      const Color(0xFF00008B), // dark blue
    ];
    return groups[index % groups.length];
  }

  TileModel copyWith({
    String? ownerId,
    int? upgradeLevel,
    String? customName,
    Color? customColor,
    bool? isAuction,
  }) {
    return TileModel(
      index: index,
      type: type,
      name: name,
      price: price,
      baseRent: baseRent,
      ownerId: ownerId ?? this.ownerId,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      customName: customName ?? this.customName,
      customColor: customColor ?? this.customColor,
      isAuction: isAuction ?? this.isAuction,
      side: side,
    );
  }

  Map<String, dynamic> toMap() => {
        'index': index,
        'type': type.name,
        'name': name,
        'price': price,
        'baseRent': baseRent,
        'ownerId': ownerId,
        'upgradeLevel': upgradeLevel,
        'customName': customName,
        'isAuction': isAuction,
        'side': side,
      };

  factory TileModel.fromMap(Map<String, dynamic> map) => TileModel(
        index: map['index'] ?? 0,
        type: TileType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => TileType.property,
        ),
        name: map['name'] ?? '',
        price: map['price']?.toDouble(),
        baseRent: map['baseRent']?.toDouble(),
        ownerId: map['ownerId'],
        upgradeLevel: map['upgradeLevel'] ?? 1,
        customName: map['customName'],
        isAuction: map['isAuction'] ?? false,
        side: map['side'] ?? 0,
      );

  @override
  List<Object?> get props =>
      [index, ownerId, upgradeLevel, customName, isAuction];
}

// ── Tile Factory ─────────────────────────────────────
class TileFactory {
  static List<TileModel> build(int boardSize) {
    final List<TileModel> tiles = [];

    // Property names pool
    final names = [
      'Green View','Oak Street','Maple Drive','Sunset Blvd','Lake View',
      'Palm Avenue','Hill Top','Lake Zone','Cedar Road','Luxury Zone',
      'Pearl Street','Market Place','Golden Gate','Dream Villa','School Lane',
      'Park Street','West End','River Road','Blue Hill','Stone Ave',
      'Crown Plaza','Diamond St','Empire Ave','Garden Lane','Sunrise Blvd',
      'Valley Road','Forest Path','Cloud Nine','Star Avenue','Moon Street',
      'Ocean Drive','Beach Blvd','Harbor View','Cliff Road','Summit Peak',
      'Alpine Way','Glacier Rd','Desert Rose','Oasis Lane','Dune Street',
      'Coral Bay','Island Ave','Reef Road','Lagoon Dr','Bay View',
      'Port Lane','Dock Street','Marina Blvd','Wave Road','Tide Avenue',
    ];

    // Price progression
    double basePrice = 100000;

    // Side lengths for 25-tile board: 7 bottom, 6 left, 6 top, 6 right
    // For larger boards we scale proportionally
  
    int propIndex = 0;

    for (int i = 0; i < boardSize; i++) {
      final side = _getSide(i, boardSize);
      final double price = basePrice + (propIndex * 10000);
      final double rent = price * 0.10;

      TileType type;
      String name;

      if (i == 0) {
        type = TileType.start;
        name = 'GO';
      } else if (i == boardSize ~/ 4) {
        type = TileType.bank;
        name = 'BANK';
      } else if (i == boardSize ~/ 2) {
        type = TileType.tax;
        name = 'CITY TAX';
      } else if (i == (boardSize * 3) ~/ 4) {
        type = TileType.luckyWheel;
        name = 'LUCKY\nWHEEL';
      } else if (i % 7 == 3) {
        type = TileType.surprise;
        name = 'SURPRISE';
      } else {
        type = TileType.property;
        name = names[propIndex % names.length];
        propIndex++;
      }

      tiles.add(TileModel(
        index: i,
        type: type,
        name: name,
        price: type == TileType.property ? price : null,
        baseRent: type == TileType.property ? rent : null,
        side: side,
      ));
    }

    return tiles;
  }

  static int _getSide(int index, int boardSize) {
    final perSide = boardSize / 4;
    if (index < perSide) return 0;         // bottom
    if (index < perSide * 2) return 1;    // left
    if (index < perSide * 3) return 2;    // top
    return 3;                              // right
  }
}