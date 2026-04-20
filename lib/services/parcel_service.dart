import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parcel_model.dart';
import '../models/user_model.dart';
import '../core/utils/format_utils.dart';

class ParcelService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('parcels');

  double calculatePrice(double weight, ParcelType type) {
    double base = weight * 500;
    switch (type) {
      case ParcelType.express: return base * 1.8;
      case ParcelType.fragile: return base * 1.5;
      default: return base;
    }
  }

  Future<String> createParcel({
    required UserModel sender,
    required String recipientName,
    required String recipientPhone,
    required String recipientAddress,
    required String senderAddress,
    required double weight,
    String? dimensions,
    required ParcelType type,
    String? note,
  }) async {
    final price = calculatePrice(weight, type);
    final trackingCode = FormatUtils.generateTrackingCode();
    final now = DateTime.now();

    final ref = await _col.add({
      'senderId': sender.id,
      'senderName': sender.fullName,
      'senderAddress': senderAddress,
      'senderPhone': sender.phone,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'recipientAddress': recipientAddress,
      'weight': weight,
      'dimensions': dimensions,
      'type': type.name,
      'price': price,
      'trackingCode': trackingCode,
      'status': ParcelStatus.pending.name,
      'statusHistory': [
        {
          'status': ParcelStatus.pending.name,
          'label': 'Envoi créé',
          'date': Timestamp.fromDate(now),
          'note': 'Votre colis a été enregistré',
        }
      ],
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
      'estimatedDelivery': Timestamp.fromDate(
        now.add(Duration(
            days: type == ParcelType.express ? 1 : 3)),
      ),
    });
    return ref.id;
  }

  // Requête simple senderId + createdAt
  Stream<List<ParcelModel>> getUserParcels(String userId) {
    return _col
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ParcelModel.fromDoc(d)).toList());
  }

  // Requête simple sans filtre status
  Stream<List<ParcelModel>> getAllParcels() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ParcelModel.fromDoc(d)).toList());
  }

  Future<ParcelModel?> getParcelByTracking(String code) async {
    final snap = await _col
        .where('trackingCode', isEqualTo: code)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ParcelModel.fromDoc(snap.docs.first);
  }

  Stream<ParcelModel> parcelStream(String id) =>
      _col.doc(id).snapshots().map((d) => ParcelModel.fromDoc(d));

  Future<void> updateStatus(
    String id,
    ParcelStatus status,
    String label, {
    String? note,
  }) async {
    final entry = {
      'status': status.name,
      'label': label,
      'date': Timestamp.fromDate(DateTime.now()),
      'note': note,
    };
    await _col.doc(id).update({
      'status': status.name,
      'statusHistory': FieldValue.arrayUnion([entry]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}