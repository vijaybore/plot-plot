import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Google Sign In ──
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);
      final User? user = result.user;
      if (user == null) return null;

      return UserModel(
        uid: user.uid,
        displayName: user.displayName ?? 'Player',
        email: user.email,
        photoUrl: user.photoURL,
      );
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // ── Guest / Offline play (anonymous) ──
  Future<UserModel?> signInAsGuest(String name) async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      final User? user = result.user;
      if (user == null) return null;

      await user.updateDisplayName(name);

      return UserModel(
        uid: user.uid,
        displayName: name,
        email: null,
        photoUrl: null,
      );
    } catch (e) {
      // Fully offline fallback — no Firebase needed
      return UserModel(
        uid: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        displayName: name,
      );
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}