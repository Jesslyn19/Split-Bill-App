import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInAnonymously(String displayName) async {
    final credential = await _auth.signInAnonymously();
    if (credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
      final appUser = AppUser(
        uid: credential.user!.uid,
        displayName: displayName,
        email: '',
      );
      await _firestoreService.saveUserProfile(appUser);
    }
    return credential;
  }

  Future<UserCredential> signInWithEmailPassword(String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
      final appUser = AppUser(
        uid: credential.user!.uid,
        displayName: displayName,
        email: email,
      );
      await _firestoreService.saveUserProfile(appUser);
    }
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
