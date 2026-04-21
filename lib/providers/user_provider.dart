import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final userStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await UserService.getUserStats();
});

final allClientsProvider = StreamProvider<List<UserModel>>((ref) {
  return UserService.getAllClients();
});
