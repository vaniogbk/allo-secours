import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';

final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

final revenueSummaryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  return ref.read(paymentServiceProvider).getRevenueSummary();
});
