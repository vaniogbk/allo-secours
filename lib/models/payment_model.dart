import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { reservation, parcel }
enum PaymentStatus { pending, success, failed }
enum PaymentMethod { cash, mobileMoney, card }

class PaymentModel {
  final String id;
  final String userId;
  final String? userName;
  final PaymentType type;
  final String refId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? transactionRef;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.type,
    required this.refId,
    required this.amount,
    required this.status,
    required this.method,
    this.transactionRef,
    required this.createdAt,
  });

  String get typeLabel =>
      type == PaymentType.reservation ? 'Location' : 'Colis';

  String get statusLabel {
    switch (status) {
      case PaymentStatus.pending: return 'En attente';
      case PaymentStatus.success: return 'Succès';
      case PaymentStatus.failed: return 'Echoué';
    }
  }

  String get methodLabel {
    switch (method) {
      case PaymentMethod.cash: return 'Espèces';
      case PaymentMethod.mobileMoney: return 'Mobile Money';
      case PaymentMethod.card: return 'Carte bancaire';
    }
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'],
      type: map['type'] == 'parcel'
          ? PaymentType.parcel
          : PaymentType.reservation,
      refId: map['refId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      method: _parseMethod(map['method']),
      transactionRef: map['transactionRef'],
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PaymentModel.fromDoc(DocumentSnapshot doc) =>
      PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  static PaymentStatus _parseStatus(String? v) {
    switch (v) {
      case 'success': return PaymentStatus.success;
      case 'failed': return PaymentStatus.failed;
      default: return PaymentStatus.pending;
    }
  }

  static PaymentMethod _parseMethod(String? v) {
    switch (v) {
      case 'mobileMoney': return PaymentMethod.mobileMoney;
      case 'card': return PaymentMethod.card;
      default: return PaymentMethod.cash;
    }
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'type': type.name,
        'refId': refId,
        'amount': amount,
        'status': status.name,
        'method': method.name,
        'transactionRef': transactionRef,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}