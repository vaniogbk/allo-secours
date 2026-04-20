import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { reservation, parcel, system, payment }

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? refId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.refId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseType(map['type']),
      refId: map['refId'],
      isRead: map['isRead'] ?? false,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory NotificationModel.fromDoc(DocumentSnapshot doc) =>
      NotificationModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);

  static NotificationType _parseType(String? v) {
    switch (v) {
      case 'parcel': return NotificationType.parcel;
      case 'system': return NotificationType.system;
      case 'payment': return NotificationType.payment;
      default: return NotificationType.reservation;
    }
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'refId': refId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}