import '../../domain/models/user_model.dart';

class AuthRepository {
  Stream<String?> get authStateChanges => Stream.value(null);

  Future<UserModel?> signInAsGuest(String name) async {
    return UserModel(
      uid: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      displayName: name,
    );
  }

  Future<UserModel?> signInWithGoogle() async {
    throw Exception('Google Sign-In requires Firebase (Phase 5).');
  }

  Future<void> signOut() async {}
}
