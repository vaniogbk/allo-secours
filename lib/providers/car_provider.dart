import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';

final carServiceProvider =
    Provider<CarService>((ref) => CarService());

final carsStreamProvider = StreamProvider<List<CarModel>>((ref) {
  return ref.watch(carServiceProvider).getCars(availableOnly: true);
});

final allCarsStreamProvider = StreamProvider<List<CarModel>>((ref) {
  return ref.watch(carServiceProvider).getCars();
});

final carDetailProvider =
    StreamProvider.family<CarModel, String>((ref, id) {
  return ref.watch(carServiceProvider).carStream(id);
});