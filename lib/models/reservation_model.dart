import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus { pending, confirmed, active, completed, cancelled }

class ReservationModel {
  final String id;
  final String userId;
  final String carId;
  final String? carBrand;
  final String? carModel;
  final String? carPhoto;
  final String? userName;
  final String? userPhone;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePerDay;
  final double deposit;
  final double totalPrice;
  final ReservationStatus status;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.carId,
    this.carBrand,
    this.carModel,
    this.carPhoto,
    this.userName,
    this.userPhone,
    required this.startDate,
    required this.endDate,
    required this.pricePerDay,
    required this.deposit,
    required this.totalPrice,
    required this.status,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
  });

  int get totalDays => endDate.difference(startDate).inDays;
  String get carFullName =>
      '${carBrand ?? ''} ${carModel ?? ''}'.trim();

  String get statusLabel {
    switch (status) {
      case ReservationStatus.pending: return 'En attente';
      case ReservationStatus.confirmed: return 'Confirmée';
      case ReservationStatus.active: return 'En cours';
      case ReservationStatus.completed: return 'Terminée';
      case ReservationStatus.cancelled: return 'Annulée';
    }
  }

  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    return ReservationModel(
      id: id,
      userId: map['userId'] ?? '',
      carId: map['carId'] ?? '',
      carBrand: map['carBrand'],
      carModel: map['carModel'],
      carPhoto: map['carPhoto'],
      userName: map['userName'],
      userPhone: map['userPhone'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      deposit: (map['deposit'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      cancellationReason: map['cancellationReason'],
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory ReservationModel.fromDoc(DocumentSnapshot doc) =>
      ReservationModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);

  static ReservationStatus _parseStatus(String? value) {
    switch (value) {
      case 'confirmed': return ReservationStatus.confirmed;
      case 'active': return ReservationStatus.active;
      case 'completed': return ReservationStatus.completed;
      case 'cancelled': return ReservationStatus.cancelled;
      default: return ReservationStatus.pending;
    }
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'carId': carId,
        'carBrand': carBrand,
        'carModel': carModel,
        'carPhoto': carPhoto,
        'userName': userName,
        'userPhone': userPhone,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'pricePerDay': pricePerDay,
        'deposit': deposit,
        'totalPrice': totalPrice,
        'status': status.name,
        'cancellationReason': cancellationReason,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  ReservationModel copyWith({
    ReservationStatus? status,
    String? cancellationReason,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id,
      userId: userId,
      carId: carId,
      carBrand: carBrand,
      carModel: carModel,
      carPhoto: carPhoto,
      userName: userName,
      userPhone: userPhone,
      startDate: startDate,
      endDate: endDate,
      pricePerDay: pricePerDay,
      deposit: deposit,
      totalPrice: totalPrice,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}