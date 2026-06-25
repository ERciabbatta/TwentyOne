import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _firebaseAuth.currentUser?.reload();
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    final completer = Completer<GoogleSignInAccount?>();
    late StreamSubscription sub;
    sub = googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        sub.cancel();
        completer.complete(event.user);
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        sub.cancel();
        completer.complete(null);
      }
    });

    try {
      await googleSignIn.authenticate();
    } catch (e) {
      sub.cancel();
      rethrow;
    }

    final googleUser = await completer.future;
    if (googleUser == null) return null;

    final idToken = googleUser.authentication.idToken;
    final clientAuth = await googleUser.authorizationClient
        .authorizeScopes(['email', 'profile']);

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: clientAuth.accessToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }
}