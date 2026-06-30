class UserModel {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        displayName: map['displayName'] ?? 'Player',
        email: map['email'],
        photoUrl: map['photoUrl'],
      );
}
