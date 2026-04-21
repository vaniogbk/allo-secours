import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(fullName);

    final user = UserModel(
      id: cred.user!.uid,
      fullName: fullName,
      email: email,
      phone: phone,
      role: UserRole.client,
      isBlocked: false,
      createdAt: DateTime.now(),
    );

    await _db
        .collection('users')
        .doc(user.id)
        .set(user.toMap());
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = await getUser(cred.user!.uid);
    // Marquer l'utilisateur comme en ligne
    await _db.collection('users').doc(user.id).update({
      'isOnline': true,
    });
    return user;
  }

  Future<void> logout() async {
    final uid = currentUser?.uid;

    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // La deconnexion doit continuer meme si la synchro Firestore echoue.
      }
    }

    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserModel> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('Utilisateur introuvable');
    return UserModel.fromDoc(doc);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }
}
