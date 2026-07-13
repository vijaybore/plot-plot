import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
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
      serverClientId: 'REPLACE_WITH_YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
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
    fb_auth.UserCredential userCred;

    if (kIsWeb) {
      // On web, Firebase's own popup flow handles the entire OAuth
      // exchange — simpler and more reliable here than driving it through
      // google_sign_in's browser support.
      final provider = fb_auth.GoogleAuthProvider();
      userCred = await _firebaseAuth.signInWithPopup(provider);
    } else {
      await _ensureGoogleSignInReady();

      // Step 1: authentication — who the user is. Shows the account
      // picker / Credential Manager sheet.
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      // Step 2: authorization — what the app is allowed to access. v7
      // splits this out from authentication, so the access token has to
      // be requested separately via the authorization client.
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
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}
