/// A player who has joined a room's waiting lobby, before the game has
/// actually started. Distinct from PlayerModel (which only exists once
/// the match is underway) — this just tracks who's present and what
/// colour they've picked while everyone waits for the host to start.
class LobbyPlayerModel {
  final String id;
  final String name;
  final int colorIndex;
  final int joinedAt;

  const LobbyPlayerModel({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'colorIndex': colorIndex,
        'joinedAt': joinedAt,
      };

  factory LobbyPlayerModel.fromMap(String id, Map<String, dynamic> map) {
    return LobbyPlayerModel(
      id: id,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'Player',
      colorIndex: (map['colorIndex'] as num?)?.toInt() ?? 0,
      joinedAt: (map['joinedAt'] as num?)?.toInt() ?? 0,
    );
  }
}