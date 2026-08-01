import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';

class AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  Stream<String?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid);

  /// google_sign_in v7 requires a one-time initialize() before authenticate()
  /// can be called on non-web platforms — guarded so repeated sign-in
  /// attempts don't re-initialize.
  ///
  /// serverClientId is the "Web client (auto created by Google Service)"
  /// OAuth 2.0 Client ID — copy it from Firebase Console → Authentication →
  /// Sign-in method → Google → Web SDK configuration, after enabling the
  /// Google provider there. Required for Android; harmless elsewhere.
  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) return;
    await _googleSignIn.initialize(
      serverClientId: '201302142598-95jbp1ic43bnl3ubpge7jiprmtpln9an.apps.googleusercontent.com',
    );
    _googleSignInReady = true;
  }

  Future<UserModel?> signInAsGuest(String name) async {
    return UserModel(
      uid: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      displayName: name,
    );
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      fb_auth.UserCredential userCred;

      if (kIsWeb) {
        final provider = fb_auth.GoogleAuthProvider();
        userCred = await _firebaseAuth.signInWithPopup(provider);
      } else {
        await _ensureGoogleSignInReady();

        // v7: authenticate() throws GoogleSignInException on cancel/failure
        // instead of returning null, so we catch the cancellation case
        // explicitly to preserve the old "return null on cancel" behavior.
        final GoogleSignInAccount account;
        try {
          account = await _googleSignIn.authenticate();
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) return null;
          rethrow;
        }

        final idToken = account.authentication.idToken;
        final authClient = account.authorizationClient;
        final authorization = await authClient.authorizationForScopes(['email']) ??
            await authClient.authorizeScopes(['email']);

        final credential = fb_auth.GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: authorization.accessToken,
        );
        userCred = await _firebaseAuth.signInWithCredential(credential);
      }

      final user = userCred.user;
      if (user == null) return null;
      return UserModel(
        uid: user.uid,
        displayName: user.displayName ?? 'Player',
        email: user.email,
        photoUrl: user.photoURL,
      );
    } catch (e) {
      if (kDebugMode) {
        // Provide a fallback for local development if Firebase isn't set up yet
        print('Google Sign-In failed: $e. Falling back to dev mock user.');
        return UserModel(
          uid: 'dev_google_${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'Google Player (Dev)',
          email: 'dev@example.com',
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}