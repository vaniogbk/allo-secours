import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? refId,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'refId': refId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<NotificationModel>> getUserNotifications(
      String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => NotificationModel.fromDoc(d)).toList());
  }

  static Future<void> markAsRead(String id) => _db
      .collection('notifications')
      .doc(id)
      .update({'isRead': true});

  static Future<void> markAllAsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}