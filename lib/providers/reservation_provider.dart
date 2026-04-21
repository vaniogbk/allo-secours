import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';
import 'auth_provider.dart';

final reservationServiceProvider =
    Provider<ReservationService>((ref) => ReservationService());

final myReservationsProvider =
    StreamProvider<List<ReservationModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(reservationServiceProvider)
      .getUserReservations(user.uid);
});

final allReservationsProvider =
    StreamProvider<List<ReservationModel>>((ref) {
  final userAsync = ref.watch(userStreamProvider);
  final user = userAsync.valueOrNull;
  if (user == null || !user.isAdmin) {
    return Stream.value([]);
  }
  return ref.watch(reservationServiceProvider).getAllReservations();
});
