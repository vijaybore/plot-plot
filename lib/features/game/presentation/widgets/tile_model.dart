import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

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
  final int index;
  final TileType type;
  final String name;          // auto-generated base name
  final double? price;        // player-set on purchase; null = unpurchased
  final String? ownerId;
  final int upgradeLevel;     // 1=empty … 7=luxury tower
  final String? customName;   // player brand name
  final String? customEmoji;  // player-chosen emoji or image key
  final int lane;
  final int positionInLane;
  final String plotNumber;    // "P-001" — permanent
  final PlotType plotType;
  final Map<String, int> visits;        // playerId -> times landed here
  final Map<String, double> rentPaid;   // playerId (payer) -> total rent paid here

  const TileModel({
    required this.index,
    required this.type,
    required this.name,
    this.price,
    this.ownerId,
    this.upgradeLevel = 1,
    this.customName,
    this.customEmoji,
    required this.lane,
    required this.positionInLane,
    required this.plotNumber,
    this.plotType = PlotType.residential,
    this.visits = const {},
    this.rentPaid = const {},
  });

  int get totalVisits => visits.values.fold(0, (a, b) => a + b);
  double get totalRentCollected => rentPaid.values.fold(0.0, (a, b) => a + b);

  // Record that [playerId] landed on this tile — used for the plot
  // details view ("who visited here, how many times").
  TileModel recordVisit(String playerId) {
    final updated = Map<String, int>.from(visits);
    updated[playerId] = (updated[playerId] ?? 0) + 1;
    return copyWith(visits: updated);
  }

  // Record that [playerId] paid [amount] rent while visiting this tile.
  TileModel recordRentPaid(String playerId, double amount) {
    final updated = Map<String, double>.from(rentPaid);
    updated[playerId] = (updated[playerId] ?? 0) + amount;
    return copyWith(rentPaid: updated);
  }

  bool get isOwned => ownerId != null;

  bool get isPurchasable =>
      (type == TileType.property || type == TileType.farmZone) &&
      ownerId == null;

  String get displayName => customName ?? name;

  String get displayEmoji => customEmoji ?? _defaultEmoji();

  String _defaultEmoji() {
    if (type == TileType.farmZone || plotType == PlotType.farm) {
      const farmLevels = ['🌾', '💧', '🌿', '🏡', '🏭'];
      return farmLevels[(upgradeLevel - 1).clamp(0, farmLevels.length - 1)];
    }
    const levels = ['🌱', '🧱', '🏠', '🏡', '🏢', '🏬', '🏙️'];
    switch (plotType) {
      case PlotType.commercial:
        const com = ['🌱', '🧱', '🏪', '🏬', '🏢', '🏙️', '🌆'];
        return com[(upgradeLevel - 1).clamp(0, com.length - 1)];
      case PlotType.luxury:
        const lux = ['🌱', '🧱', '🏠', '🏰', '🏯', '👑', '💎'];
        return lux[(upgradeLevel - 1).clamp(0, lux.length - 1)];
      case PlotType.industrial:
        const ind = ['🌱', '🧱', '🏗️', '🏭', '🏗️', '🏭', '⚙️'];
        return ind[(upgradeLevel - 1).clamp(0, ind.length - 1)];
      default:
        return levels[(upgradeLevel - 1).clamp(0, levels.length - 1)];
    }
  }

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

  bool get canUpgrade => isOwned && upgradeLevel < 7 && price != null;

  double get upgradeCost {
    if (price == null) return 0;
    return price! * (0.4 + upgradeLevel * 0.2);
  }

  // Rent is half of the plot's price, growing a little with development
  // (capped so a fully-upgraded plot never charges more than the price
  // itself). Base (unimproved) plot: rent = 50% of price, exactly as
  // requested — this is a flat, easy-to-check number for manual payment.
  double get currentRent {
    if (price == null) return 0;
    final multiplier = (0.5 + (upgradeLevel - 1) * 0.1).clamp(0.5, 1.0);
    return price! * multiplier;
  }

  double get currentValue {
    if (price == null) return 0;
    return price! * (1.0 + (upgradeLevel - 1) * 0.6);
  }

  // ── Suggested emojis per plot type (for buy dialog picker) ──────
  static List<String> suggestedEmojis(PlotType type) {
    switch (type) {
      case PlotType.farm:
        return ['🌾', '🚜', '🌿', '🌻', '🐄', '🍅', '🥬', '🌽'];
      case PlotType.commercial:
        return ['🏪', '🏬', '🏢', '💼', '🏦', '🛒', '☕', '🍕'];
      case PlotType.industrial:
        return ['🏭', '⚙️', '🔧', '🏗️', '🔩', '🚧', '🔨', '⚒️'];
      case PlotType.lakeView:
        return ['🌊', '⛵', '🐟', '🦆', '🏄', '🌅', '🌙', '🪷'];
      case PlotType.luxury:
        return ['🏰', '👑', '💎', '🌟', '🏯', '✨', '🥂', '🎭'];
      case PlotType.premium:
        return ['🌟', '🏡', '🌴', '🌺', '🏔️', '🌄', '💫', '🦋'];
      case PlotType.garden:
        return ['🌳', '🌷', '🌸', '🍀', '🌲', '🌻', '🦜', '🌿'];
      case PlotType.highwayFacing:
        return ['🛣️', '🚗', '⛽', '🏨', '🍔', '🏪', '🚦', '🛤️'];
      case PlotType.corner:
        return ['🏠', '🏡', '🌳', '🏘️', '🌄', '🌠', '⭐', '🏆'];
      default:
        return ['🏠', '🏡', '🏘️', '🌳', '🏗️', '🌄', '🏞️', '🏠'];
    }
  }

  // ── Suggested price range (kept for reference / legacy boards) ───
  static (double min, double max) priceRange(PlotType type) {
    switch (type) {
      case PlotType.farm:         return (300000, 1500000);
      case PlotType.garden:       return (500000, 2000000);
      case PlotType.residential:  return (800000, 3000000);
      case PlotType.industrial:   return (1000000, 4000000);
      case PlotType.corner:       return (1200000, 5000000);
      case PlotType.commercial:   return (1500000, 6000000);
      case PlotType.highwayFacing:return (1800000, 7000000);
      case PlotType.lakeView:     return (2000000, 8000000);
      case PlotType.premium:      return (2500000, 10000000);
      case PlotType.luxury:       return (4000000, 20000000);
    }
  }

  // ── Fixed listing price ──────────────────────────────────────────
  // Every plot has one non-negotiable bank-set price based on its type.
  // No more "player types in any number" — the board is a real price list,
  // like Ludo squares are fixed positions with fixed rules.
  // Kept in the ₹5L–₹15L range so early-game plots are affordable and
  // rent (half of price) stays easy to track and pay by hand.
  static double fixedPrice(PlotType type) {
    switch (type) {
      case PlotType.farm:         return 500000;   // 5L  — cheapest, income plot
      case PlotType.residential:  return 700000;   // 7L
      case PlotType.garden:       return 800000;   // 8L
      case PlotType.corner:       return 900000;   // 9L — corner premium
      case PlotType.industrial:   return 1000000;  // 10L
      case PlotType.highwayFacing:return 1100000;  // 11L
      case PlotType.commercial:   return 1200000;  // 12L
      case PlotType.lakeView:     return 1300000;  // 13L
      case PlotType.premium:      return 1400000;  // 14L
      case PlotType.luxury:       return 1500000;  // 15L
    }
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

  Color get groupColor => plotTypeColor;

  TileModel copyWith({
    String? ownerId,
    double? price,
    int? upgradeLevel,
    String? customName,
    String? customEmoji,
    bool clearCustomName = false,
    Map<String, int>? visits,
    Map<String, double>? rentPaid,
  }) {
    return TileModel(
      index: index,
      type: type,
      name: name,
      price: price ?? this.price,
      ownerId: ownerId ?? this.ownerId,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      customName: clearCustomName ? null : (customName ?? this.customName),
      customEmoji: customEmoji ?? this.customEmoji,
      lane: lane,
      positionInLane: positionInLane,
      plotNumber: plotNumber,
      plotType: plotType,
      visits: visits ?? this.visits,
      rentPaid: rentPaid ?? this.rentPaid,
    );
  }

  Map<String, dynamic> toMap() => {
    'index': index,
    'type': type.name,
    'name': name,
    'price': price,
    'ownerId': ownerId,
    'upgradeLevel': upgradeLevel,
    'customName': customName,
    'customEmoji': customEmoji,
    'lane': lane,
    'positionInLane': positionInLane,
    'plotNumber': plotNumber,
    'plotType': plotType.name,
    'visits': visits,
    'rentPaid': rentPaid,
  };

  factory TileModel.fromMap(Map<String, dynamic> map) => TileModel(
    index: map['index'] ?? 0,
    type: TileType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => TileType.property,
    ),
    name: map['name'] ?? '',
    price: map['price']?.toDouble(),
    ownerId: map['ownerId'],
    upgradeLevel: map['upgradeLevel'] ?? 1,
    customName: map['customName'],
    customEmoji: map['customEmoji'],
    lane: map['lane'] ?? 0,
    positionInLane: map['positionInLane'] ?? 0,
    plotNumber: map['plotNumber'] ?? 'P-000',
    plotType: PlotType.values.firstWhere(
      (t) => t.name == map['plotType'],
      orElse: () => PlotType.residential,
    ),
    visits: (map['visits'] as Map?)?.map(
        (k, v) => MapEntry(k as String, (v as num).toInt())) ?? const {},
    rentPaid: (map['rentPaid'] as Map?)?.map(
        (k, v) => MapEntry(k as String, (v as num).toDouble())) ?? const {},
  );

  @override
  List<Object?> get props =>
      [index, ownerId, upgradeLevel, customName, price, visits, rentPaid];
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

    // [0] Main Road / Start
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
      final isFarmLane   = laneNum % 3 == 0;
      final isCommercial = laneNum % 4 == 0;
      final isHighway    = laneNum == 1;

      for (int pos = 0; pos < layout.plotsPerLane; pos++) {
        if (plotCounter >= totalPlots) { break; }
        plotCounter++;

        final plotNum  = 'P-${plotCounter.toString().padLeft(3, '0')}';
        final plotType = _assignType(laneNum, pos, layout.plotsPerLane,
            isFarmLane, isCommercial, isHighway);
        final tileType = (isFarmLane && pos % 3 == 1)
            ? TileType.farmZone
            : TileType.property;

        tiles.add(TileModel(
          index: flatIndex++,
          type: tileType,
          // price is fixed by the bank at creation — same price for every
          // player, every game. Only the owner's chosen name/emoji is custom.
          price: TileModel.fixedPrice(plotType),
          name: _nameFor(plotType, plotCounter),
          lane: laneNum,
          positionInLane: pos,
          plotNumber: plotNum,
          plotType: plotType,
        ));
      }

      // Special tile at end of each lane
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
      bool isFarm, bool isCommercial, bool isHighway) {
    if (pos == 0 || pos == ppl - 1) { return PlotType.corner; }
    if (isFarm) { return PlotType.farm; }
    if (isCommercial) { return PlotType.commercial; }
    if (isHighway) { return PlotType.highwayFacing; }
    if (pos % 7 == 6) { return PlotType.luxury; }
    if (pos % 6 == 5) { return PlotType.premium; }
    if (pos % 5 == 4) { return PlotType.lakeView; }
    if (pos % 4 == 3) { return PlotType.garden; }
    return PlotType.residential;
  }

  static String _nameFor(PlotType type, int counter) {
    final i = counter - 1;
    switch (type) {
      case PlotType.farm:        return _farmNames[i % _farmNames.length];
      case PlotType.commercial:  return _comNames[i % _comNames.length];
      case PlotType.premium:
      case PlotType.luxury:      return _premiumNames[i % _premiumNames.length];
      default:                   return _resNames[i % _resNames.length];
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
}

// Alias for backward compat
class TileBuilder {
  static List<TileModel> buildTiles(int n) => TileFactory.build(n);
}