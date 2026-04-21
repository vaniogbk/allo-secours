import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  /// Mettre à jour le statut en ligne de l'utilisateur
  static Future<void> setOnlineStatus(String userId, bool isOnline) async {
    await _db.collection('users').doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
    });
  }

  /// Marquer l'utilisateur comme en ligne
  static Future<void> markOnline(String userId) async {
    await setOnlineStatus(userId, true);
  }

  /// Marquer l'utilisateur comme hors ligne
  static Future<void> markOffline(String userId) async {
    await setOnlineStatus(userId, false);
  }

  /// Obtenir tous les utilisateurs (clients)
  static Stream<List<UserModel>> getAllClients() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((s) {
          final clients = s.docs.map((d) => UserModel.fromDoc(d)).toList();
          clients.sort((a, b) {
            final aSeen = a.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bSeen = b.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bSeen.compareTo(aSeen);
          });
          return clients;
        });
  }

  /// Obtenir les statistiques des utilisateurs
  static Future<Map<String, int>> getUserStats() async {
    final snap = await _db.collection('users').where('role', isEqualTo: 'client').get();
    int online = 0, offline = 0;
    for (final doc in snap.docs) {
      final user = UserModel.fromDoc(doc);
      if (user.isOnline) online++;
      else offline++;
    }
    return {'online': online, 'offline': offline, 'total': online + offline};
  }

  /// Bloquer/débloquer un utilisateur
  static Future<void> setBlockStatus(String userId, bool isBlocked) async {
    await _db.collection('users').doc(userId).update({
      'isBlocked': isBlocked,
    });
  }
}
