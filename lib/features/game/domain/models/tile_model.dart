import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

// Keep luckyWheel so GameEvent enum in provider stays unchanged
enum TileType { start, property, farmZone, surprise, luckyWheel, tax, bank }

enum PlotType {
  residential,
  farm,
  commercial,
  industrial,
  corner,
  lakeView,
  premium,
  highwayFacing,
  garden,
  luxury,
}

class TileModel extends Equatable {
  final int index;           // flat position in movement array
  final TileType type;
  final String name;         // auto-generated base name (always present)
  final double? price;
  final double? baseRent;
  final String? ownerId;
  final int upgradeLevel;    // 1=empty … 7=luxury tower
  final String? customName;  // player-assigned brand name (can change)
  final int lane;            // 0 = main-road/start, 1..N = lane number
  final int positionInLane;  // 0-indexed slot within its lane
  final String plotNumber;   // "P-001" — permanent, never changes
  final PlotType plotType;

  const TileModel({
    required this.index,
    required this.type,
    required this.name,
    this.price,
    this.baseRent,
    this.ownerId,
    this.upgradeLevel = 1,
    this.customName,
    required this.lane,
    required this.positionInLane,
    required this.plotNumber,
    this.plotType = PlotType.residential,
  });

  bool get isOwned => ownerId != null;

  bool get isPurchasable =>
      (type == TileType.property || type == TileType.farmZone) &&
      price != null;

  String get displayName => customName ?? name;

  // ── Development ladder ──────────────────────────────────────────
  String get upgradeName {
    switch (upgradeLevel) {
      case 2: return 'Boundary Wall';
      case 3: return 'House';
      case 4: return 'Villa';
      case 5: return 'Apartment';
      case 6: return 'Commercial Complex';
      case 7: return 'Luxury Tower';
      default: return 'Empty Plot';
    }
  }

  String get upgradeEmoji {
    switch (upgradeLevel) {
      case 2: return '🧱';
      case 3: return '🏠';
      case 4: return '🏡';
      case 5: return '🏢';
      case 6: return '🏬';
      case 7: return '🏙️';
      default: return '🌱';
    }
  }

  bool get canUpgrade => isPurchasable && isOwned && upgradeLevel < 7;

  double get upgradeCost {
    if (price == null) return 0;
    return price! * (0.4 + upgradeLevel * 0.2);
  }

  double get currentRent {
    if (baseRent == null) return 0;
    return baseRent! * (1.0 + (upgradeLevel - 1) * 0.5);
  }

  double get currentValue {
    if (price == null) return 0;
    return price! * (1.0 + (upgradeLevel - 1) * 0.6);
  }

  // ── Plot type colors & labels ────────────────────────────────────
  Color get plotTypeColor {
    switch (plotType) {
      case PlotType.residential:   return const Color(0xFFB8E6B8);
      case PlotType.farm:          return const Color(0xFFD4E887);
      case PlotType.commercial:    return const Color(0xFFADD8F0);
      case PlotType.industrial:    return const Color(0xFFD4C5B0);
      case PlotType.corner:        return const Color(0xFFFFDDA0);
      case PlotType.lakeView:      return const Color(0xFFA0E8E8);
      case PlotType.premium:       return const Color(0xFFE8C8F0);
      case PlotType.highwayFacing: return const Color(0xFFFFBDBD);
      case PlotType.garden:        return const Color(0xFFA0D8C8);
      case PlotType.luxury:        return const Color(0xFFFFF0A0);
    }
  }

  String get plotTypeLabel {
    switch (plotType) {
      case PlotType.residential:   return 'RES';
      case PlotType.farm:          return 'FARM';
      case PlotType.commercial:    return 'COM';
      case PlotType.industrial:    return 'IND';
      case PlotType.corner:        return 'CRN';
      case PlotType.lakeView:      return 'LAKE';
      case PlotType.premium:       return 'PRM';
      case PlotType.highwayFacing: return 'HWY';
      case PlotType.garden:        return 'GDN';
      case PlotType.luxury:        return 'LUX';
    }
  }

  // Backward-compat: groupColor used in old tile widget
  Color get groupColor => plotTypeColor;

  TileModel copyWith({
    String? ownerId,
    int? upgradeLevel,
    String? customName,
    bool clearCustomName = false,
  }) {
    return TileModel(
      index: index,
      type: type,
      name: name,
      price: price,
      baseRent: baseRent,
      ownerId: ownerId ?? this.ownerId,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      customName: clearCustomName ? null : (customName ?? this.customName),
      lane: lane,
      positionInLane: positionInLane,
      plotNumber: plotNumber,
      plotType: plotType,
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
    'lane': lane,
    'positionInLane': positionInLane,
    'plotNumber': plotNumber,
    'plotType': plotType.name,
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
    lane: map['lane'] ?? 0,
    positionInLane: map['positionInLane'] ?? 0,
    plotNumber: map['plotNumber'] ?? 'P-000',
    plotType: PlotType.values.firstWhere(
      (t) => t.name == map['plotType'],
      orElse: () => PlotType.residential,
    ),
  );

  @override
  List<Object?> get props => [index, ownerId, upgradeLevel, customName];
}

// ── Lane Layout Calculator ───────────────────────────────────────────────────
class LaneLayout {
  final int lanes;
  final int plotsPerLane;

  const LaneLayout({required this.lanes, required this.plotsPerLane});

  static LaneLayout forPlots(int totalPlots) {
    final int lanes;
   if (totalPlots <= 20) {
  lanes = 4;
} else if (totalPlots <= 40) {
  lanes = 5;
} else if (totalPlots <= 60) {
  lanes = 6;
} else {
  lanes = 10;
}
    final ppl = (totalPlots / lanes).ceil();
    return LaneLayout(lanes: lanes, plotsPerLane: ppl);
  }
}

// ── Tile Factory ─────────────────────────────────────────────────────────────
class TileFactory {
  static const _resNames = [
    'Green View', 'Oak Lane', 'Maple Drive', 'Sunrise Blvd', 'Cedar Road',
    'Palm Avenue', 'Hill Top', 'Pearl Street', 'River Road', 'Blue Hill',
    'Stone Ave', 'West End', 'Park Street', 'Crown Plaza', 'Empire Ave',
    'Garden Lane', 'Valley Road', 'Forest Path', 'Star Avenue', 'Moon Street',
  ];
  static const _farmNames = [
    'Harvest Fields', 'Green Acres', 'Sunflower Farm', 'Valley Farm',
    'Golden Crop', 'Nature\'s Bounty', 'Meadow Fields', 'Rich Soil Farm',
  ];
  static const _comNames = [
    'Business Hub', 'Market Square', 'Trade Centre', 'Commerce Plaza',
    'Tech Park', 'Retail Square', 'City Mall', 'Enterprise Zone',
  ];
  static const _premiumNames = [
    'Royal Heights', 'Prestige Park', 'Elite Zone', 'Crown Estate',
    'Diamond Court', 'Platinum Ridge', 'Sovereign Heights', 'Grand Estate',
  ];

  static List<TileModel> build(int totalPlots) {
    final layout = LaneLayout.forPlots(totalPlots);
    final tiles = <TileModel>[];
    int flatIndex = 0;
    int plotCounter = 0;

    // ── [0] Main Road / Start ──
    tiles.add(const TileModel(
      index: 0,
      type: TileType.start,
      name: 'MAIN ROAD',
      lane: 0,
      positionInLane: 0,
      plotNumber: 'P-000',
    ));
    flatIndex = 1;

    for (int laneNum = 1; laneNum <= layout.lanes; laneNum++) {
      final isFarmLane    = laneNum % 3 == 0;
      final isCommercial  = laneNum % 4 == 0;
      final isHighway     = laneNum == 1;

      // ── Plot tiles ──
      for (int pos = 0; pos < layout.plotsPerLane; pos++) {
        if (plotCounter >= totalPlots) break;
        plotCounter++;

        final plotNum  = 'P-${plotCounter.toString().padLeft(3, '0')}';
        final plotType = _assignType(laneNum, pos, layout.plotsPerLane,
            isFarmLane, isCommercial, isHighway, plotCounter);
        final basePrice = _priceFor(plotType, plotCounter);
        final tileType  = (isFarmLane && pos % 3 == 1)
            ? TileType.farmZone
            : TileType.property;

        tiles.add(TileModel(
          index: flatIndex++,
          type: tileType,
          name: _nameFor(plotType, plotCounter),
          price: basePrice,
          baseRent: basePrice * 0.10,
          lane: laneNum,
          positionInLane: pos,
          plotNumber: plotNum,
          plotType: plotType,
        ));
      }

      // ── Special tile at end of each lane ──
      final special = _specialForLane(laneNum);
      tiles.add(TileModel(
        index: flatIndex++,
        type: special,
        name: _specialName(special),
        lane: laneNum,
        positionInLane: layout.plotsPerLane,
        plotNumber: 'S-${laneNum.toString().padLeft(2, '0')}',
      ));
    }

    return tiles;
  }

  static PlotType _assignType(int lane, int pos, int ppl,
      bool isFarm, bool isCommercial, bool isHighway, int plotNum) {
    // First/last plot in lane = corner
    if (pos == 0 || pos == ppl - 1) return PlotType.corner;
    if (isFarm)       return PlotType.farm;
    if (isCommercial) return PlotType.commercial;
    if (isHighway)    return PlotType.highwayFacing;
    if (pos % 7 == 6) return PlotType.luxury;
    if (pos % 6 == 5) return PlotType.premium;
    if (pos % 5 == 4) return PlotType.lakeView;
    if (pos % 4 == 3) return PlotType.garden;
    return PlotType.residential;
  }

  static double _priceFor(PlotType type, int counter) {
    final base = 80000.0 + counter * 7500.0;
    switch (type) {
      case PlotType.luxury:        return base * 3.0;
      case PlotType.premium:       return base * 2.5;
      case PlotType.lakeView:      return base * 2.2;
      case PlotType.commercial:    return base * 2.0;
      case PlotType.highwayFacing: return base * 1.8;
      case PlotType.corner:        return base * 1.5;
      case PlotType.industrial:    return base * 1.4;
      case PlotType.garden:        return base * 1.3;
      case PlotType.farm:          return base * 0.8;
      case PlotType.residential:   return base;
    }
  }

  static String _nameFor(PlotType type, int counter) {
  final i = counter - 1;

  switch (type) {
    case PlotType.farm:
      return _farmNames[i % _farmNames.length];

    case PlotType.commercial:
      return _comNames[i % _comNames.length];

    case PlotType.premium:
    case PlotType.luxury:
      return _premiumNames[i % _premiumNames.length];

    default:
      return _resNames[i % _resNames.length];
  }
}

  static TileType _specialForLane(int lane) {
    switch (lane % 3) {
      case 1: return TileType.surprise;
      case 2: return TileType.bank;
      default: return TileType.tax;
    }
  }

  static String _specialName(TileType type) {
    switch (type) {
      case TileType.surprise: return 'SURPRISE';
      case TileType.bank:     return 'BANK';
      case TileType.tax:      return 'CITY TAX';
      default:                return 'SPECIAL';
    }
  }

  // Kept for backward compat (setup_game_screen calls TileFactory.build)
}

// Alias kept so setup_game_screen.dart compile doesn't break
class TileBuilder {
  static List<TileModel> buildTiles(int n) => TileFactory.build(n);
}