import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wrapper leggero attorno a `FirebaseAuth` che centralizza tutte le
/// operazioni di autenticazione dell'app (login/registrazione via e-mail
/// e password, login con Google, logout, stato di verifica dell'e-mail).
///
/// Le pagine UI (es. `login_register.dart`, `AuthGate` in `main.dart`)
/// dipendono da questa classe invece che parlare direttamente con
/// `firebase_auth`, così l'eventuale logica di autenticazione resta in
/// un solo punto.
class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Utente Firebase attualmente autenticato, `null` se nessuno ha fatto login.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream che emette un nuovo valore ogni volta che lo stato di
  /// autenticazione cambia (login, logout, refresh del token).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Indica se l'e-mail dell'utente corrente risulta verificata.
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Effettua il login con e-mail e password e ricarica i dati
  /// dell'utente (utile per avere subito lo stato di verifica aggiornato).
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

  /// Registra un nuovo utente con e-mail e password.
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Avvia il flusso di login con Google (popup/scelta account) e
  /// autentica l'utente su Firebase con le credenziali ottenute.
  ///
  /// Restituisce `null` se l'utente annulla la selezione dell'account.
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // utente ha annullato

    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Ricarica i dati dell'utente corrente da Firebase (es. dopo l'invio
  /// dell'e-mail di verifica, per controllare se è stata confermata).
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  /// Effettua il logout sia da Google Sign-In sia da Firebase Auth.
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
  }
}