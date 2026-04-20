import 'package:cloud_firestore/cloud_firestore.dart';

enum ParcelType { standard, express, fragile }
enum ParcelStatus { pending, pickedUp, inTransit, delivered, cancelled }

class ParcelStatusHistory {
  final ParcelStatus status;
  final String label;
  final DateTime date;
  final String? note;

  ParcelStatusHistory({
    required this.status,
    required this.label,
    required this.date,
    this.note,
  });

  factory ParcelStatusHistory.fromMap(Map<String, dynamic> map) {
    return ParcelStatusHistory(
      status: _parseStatus(map['status']),
      label: map['label'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'label': label,
        'date': Timestamp.fromDate(date),
        'note': note,
      };

  static ParcelStatus _parseStatus(String? v) {
    switch (v) {
      case 'pickedUp': return ParcelStatus.pickedUp;
      case 'inTransit': return ParcelStatus.inTransit;
      case 'delivered': return ParcelStatus.delivered;
      case 'cancelled': return ParcelStatus.cancelled;
      default: return ParcelStatus.pending;
    }
  }
}

class ParcelModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAddress;
  final String senderPhone;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final double weight;
  final String? dimensions;
  final ParcelType type;
  final double price;
  final String trackingCode;
  final ParcelStatus status;
  final List<ParcelStatusHistory> statusHistory;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDelivery;

  ParcelModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAddress,
    required this.senderPhone,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientAddress,
    required this.weight,
    this.dimensions,
    required this.type,
    required this.price,
    required this.trackingCode,
    required this.status,
    this.statusHistory = const [],
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDelivery,
  });

  String get typeLabel {
    switch (type) {
      case ParcelType.standard: return 'Standard';
      case ParcelType.express: return 'Express';
      case ParcelType.fragile: return 'Fragile';
    }
  }

  String get statusLabel {
    switch (status) {
      case ParcelStatus.pending: return 'En attente';
      case ParcelStatus.pickedUp: return 'Pris en charge';
      case ParcelStatus.inTransit: return 'En transit';
      case ParcelStatus.delivered: return 'Livré';
      case ParcelStatus.cancelled: return 'Annulé';
    }
  }

  factory ParcelModel.fromMap(Map<String, dynamic> map, String id) {
    return ParcelModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAddress: map['senderAddress'] ?? '',
      senderPhone: map['senderPhone'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientPhone: map['recipientPhone'] ?? '',
      recipientAddress: map['recipientAddress'] ?? '',
      weight: (map['weight'] ?? 0).toDouble(),
      dimensions: map['dimensions'],
      type: _parseType(map['type']),
      price: (map['price'] ?? 0).toDouble(),
      trackingCode: map['trackingCode'] ?? '',
      status: ParcelStatusHistory._parseStatus(map['status']),
      statusHistory: (map['statusHistory'] as List<dynamic>? ?? [])
          .map((e) =>
              ParcelStatusHistory.fromMap(e as Map<String, dynamic>))
          .toList(),
      note: map['note'],
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      estimatedDelivery:
          (map['estimatedDelivery'] as Timestamp?)?.toDate(),
    );
  }

  factory ParcelModel.fromDoc(DocumentSnapshot doc) =>
      ParcelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  static ParcelType _parseType(String? v) {
    switch (v) {
      case 'express': return ParcelType.express;
      case 'fragile': return ParcelType.fragile;
      default: return ParcelType.standard;
    }
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderAddress': senderAddress,
        'senderPhone': senderPhone,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'recipientAddress': recipientAddress,
        'weight': weight,
        'dimensions': dimensions,
        'type': type.name,
        'price': price,
        'trackingCode': trackingCode,
        'status': status.name,
        'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'estimatedDelivery': estimatedDelivery != null
            ? Timestamp.fromDate(estimatedDelivery!)
            : null,
      };

  ParcelModel copyWith({
    ParcelStatus? status,
    List<ParcelStatusHistory>? statusHistory,
    DateTime? updatedAt,
  }) {
    return ParcelModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAddress: senderAddress,
      senderPhone: senderPhone,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      recipientAddress: recipientAddress,
      weight: weight,
      dimensions: dimensions,
      type: type,
      price: price,
      trackingCode: trackingCode,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDelivery: estimatedDelivery,
    );
  }
}