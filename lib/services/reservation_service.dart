import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_model.dart';
import '../models/reservation_model.dart';
import '../models/user_model.dart';

class ReservationService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('reservations');

  Future<String> createReservation({
    required UserModel user,
    required CarModel car,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final days = endDate.difference(startDate).inDays;
    final total = days * car.pricePerDay + car.deposit;

    final ref = await _col.add({
      'userId': user.id,
      'carId': car.id,
      'carBrand': car.brand,
      'carModel': car.model,
      'carPhoto': car.mainPhoto,
      'userName': user.fullName,
      'userPhone': user.phone,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'pricePerDay': car.pricePerDay,
      'deposit': car.deposit,
      'totalPrice': total,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // Requête simple sur userId + createdAt
  Stream<List<ReservationModel>> getUserReservations(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ReservationModel.fromDoc(d)).toList());
  }

  // Requête simple sans filtre status pour éviter index composite
  Stream<List<ReservationModel>> getAllReservations() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ReservationModel.fromDoc(d)).toList());
  }

  Future<void> updateStatus(
    String id,
    ReservationStatus status, {
    String? reason,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reason != null) data['cancellationReason'] = reason;
    await _col.doc(id).update(data);
  }

  Future<bool> isCarAvailable(
      String carId, DateTime start, DateTime end) async {
    final snap = await _col
        .where('carId', isEqualTo: carId)
        .where('status',
            whereIn: ['pending', 'confirmed', 'active'])
        .get();

    for (final doc in snap.docs) {
      final r = ReservationModel.fromDoc(doc);
      if (start.isBefore(r.endDate) && end.isAfter(r.startDate)) {
        return false;
      }
    }
    return true;
  }

  Future<ReservationModel> getReservation(String id) async {
    final doc = await _col.doc(id).get();
    return ReservationModel.fromDoc(doc);
  }
}