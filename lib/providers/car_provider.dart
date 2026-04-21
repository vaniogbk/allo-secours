import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import 'auth_provider.dart';

final carServiceProvider =
    Provider<CarService>((ref) => CarService());

final carsStreamProvider = StreamProvider<List<CarModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(carServiceProvider).getCars(availableOnly: true);
});

final allCarsStreamProvider = StreamProvider<List<CarModel>>((ref) {
  final userAsync = ref.watch(userStreamProvider);
  final user = userAsync.valueOrNull;
  if (user == null || !user.isAdmin) {
    return Stream.value([]);
  }
  return ref.watch(carServiceProvider).getCars();
});

final carDetailProvider =
    StreamProvider.family<CarModel, String>((ref, id) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return const Stream<CarModel>.empty();
  }
  return ref.watch(carServiceProvider).carStream(id);
});
