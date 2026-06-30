import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
  final String? customColor;
  final String? customIcon;
  final bool isAuction;
  final int side; // 0=bottom, 1=left, 2=top, 3=right

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
    this.customIcon,
    this.isAuction = false,
    required this.side,
  });

  bool get isOwned => ownerId != null;
  bool get isPurchasable => type == TileType.property && price != null;

  double get currentRent {
    if (baseRent == null) return 0;
    return baseRent! * (upgradeLevel == 1 ? 1.0 : upgradeLevel == 2 ? 1.5 : 2.0);
  }

  double get currentValue {
    if (price == null) return 0;
    return price! * (upgradeLevel == 1 ? 1.0 : upgradeLevel == 2 ? 1.5 : 2.0);
  }

  Color get defaultTileColor {
    switch (type) {
      case TileType.start:
        return const Color(0xFF00D4AA);
      case TileType.property:
        return const Color(0xFF2C3E50);
      case TileType.surprise:
        return const Color(0xFF9B59B6);
      case TileType.luckyWheel:
        return const Color(0xFFFFD700);
      case TileType.tax:
        return const Color(0xFFE74C3C);
      case TileType.bank:
        return const Color(0xFF2ECC71);
    }
  }

  Color get ownerColor {
    if (customColor != null) {
      return Color(
        int.parse(customColor!.replaceFirst('#', '0xFF')),
      );
    }
    return defaultTileColor;
  }

  TileModel copyWith({
    String? ownerId,
    int? upgradeLevel,
    String? customName,
    String? customColor,
    String? customIcon,
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
      customIcon: customIcon ?? this.customIcon,
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
    'customColor': customColor,
    'customIcon': customIcon,
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
    customColor: map['customColor'],
    customIcon: map['customIcon'],
    isAuction: map['isAuction'] ?? false,
    side: map['side'] ?? 0,
  );

  @override
  List<Object?> get props => [index, ownerId, upgradeLevel, customName, isAuction];
}