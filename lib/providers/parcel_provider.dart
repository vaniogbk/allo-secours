import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parcel_model.dart';
import '../services/parcel_service.dart';
import 'auth_provider.dart';

final parcelServiceProvider =
    Provider<ParcelService>((ref) => ParcelService());

final myParcelsProvider =
    StreamProvider<List<ParcelModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(parcelServiceProvider)
      .getUserParcels(user.uid);
});

final allParcelsProvider =
    StreamProvider<List<ParcelModel>>((ref) {
  final userAsync = ref.watch(userStreamProvider);
  final user = userAsync.valueOrNull;
  if (user == null || user.role != 'admin') {
    return Stream.value([]);
  }
  return ref.watch(parcelServiceProvider).getAllParcels();
});

final parcelStreamProvider =
    StreamProvider.family<ParcelModel?, String>((ref, id) {
  final userAsync = ref.watch(userStreamProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return Stream.value(null);
  // Pour l'instant, permettre seulement si admin ou si c'est le sender (mais on ne sait pas sans lire)
  // Idéalement, lire d'abord et vérifier, mais pour simplifier, restreindre aux admins
  if (user.role != 'admin') return Stream.value(null);
  return ref.watch(parcelServiceProvider).parcelStream(id);
});