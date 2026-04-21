import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/cloudinary_image.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/reservation_model.dart';
import '../../../providers/reservation_provider.dart';

class MyReservationsScreen extends ConsumerStatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  ConsumerState<MyReservationsScreen> createState() =>
      _MyReservationsScreenState();
}

class _MyReservationsScreenState
    extends ConsumerState<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resAsync = ref.watch(myReservationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mes réservations'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
          ],
        ),
      ),
      body: resAsync.when(
        data: (list) {
          final pending = list
              .where((r) =>
                  r.status == ReservationStatus.pending)
              .toList();
          final active = list
              .where((r) =>
                  r.status == ReservationStatus.active ||
                  r.status == ReservationStatus.confirmed)
              .toList();
          final done = list
              .where((r) =>
                  r.status == ReservationStatus.completed ||
                  r.status == ReservationStatus.cancelled)
              .toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _ResList(reservations: pending),
              _ResList(reservations: active),
              _ResList(reservations: done),
            ],
          );
        },
        loading: () =>
            const ShimmerList(count: 3, itemHeight: 150),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _ResList extends StatelessWidget {
  final List<ReservationModel> reservations;
  const _ResList({required this.reservations});

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.calendar_today_outlined,
        title: 'Aucune réservation',
        subtitle: 'Pas de réservation dans cette catégorie',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) =>
          _ReservationCard(res: reservations[i]),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  final ReservationModel res;
  const _ReservationCard({required this.res});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: res.carPhoto != null
                    ? CloudinaryImage(
                        imageUrl: res.carPhoto!,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        optimizedWidth: 900,
                        errorWidget: _placeholder(),
                      )
                    : _placeholder(),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.getStatusBgColor(
                        res.status.name),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    res.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getStatusColor(
                            res.status.name)),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res.carFullName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${AppDateUtils.formatDate(res.startDate)} → ${AppDateUtils.formatDate(res.endDate)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 14,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('${res.totalDays} jour(s)',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(
                      FormatUtils.formatPrice(res.totalPrice),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ],
                ),
                if (res.status == ReservationStatus.pending) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (!res.paymentVerified) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/payment?ref_id=${res.id}&amount=${res.totalPrice}&item_name=${Uri.encodeComponent(res.carFullName)}&type=reservation',
                        ),
                        icon: const Icon(Icons.payments_outlined, size: 16),
                        label: const Text('Payer maintenant'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _cancelDialog(context, ref),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: AppColors.error),
                      label: const Text(
                          'Annuler la réservation',
                          style: TextStyle(
                              color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
                if (res.noShow) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Non-présentation enregistrée. La réservation est clôturée sans remboursement.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
                if (res.paymentVerified &&
                    res.status == ReservationStatus.pending) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Paiement reçu. La réservation reste en attente de validation par l\'admin.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (res.refundAmount != null && res.refundAmount! > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Remboursement prévu: ${FormatUtils.formatPrice(res.refundAmount!)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 130,
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.directions_car_rounded,
              size: 48, color: AppColors.primary),
        ),
      );

  void _cancelDialog(BuildContext context, WidgetRef ref) {
    final resService = ref.read(reservationServiceProvider);
    final canRefund = resService.canRefund(res);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Annuler la réservation ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canRefund) ...[
              const Text(
                  'Remboursement intégral disponible pour une annulation effectuée dans les 7 jours suivant la réservation.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Montant remboursé: ${FormatUtils.formatPrice(res.totalPrice)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ),
            ] else ...[
              const Text(
                  'Le délai de remboursement de 7 jours est dépassé. Aucun remboursement ne sera effectué.'),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final refund = await resService.cancelWithRefund(
                  res.id,
                  'Annulé par le client',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: refund > 0
                          ? Text(
                              'Réservation annulée. Remboursement: ${FormatUtils.formatPrice(refund)}')
                          : const Text(
                              'Réservation annulée. Pas de remboursement (délai dépassé)'),
                      backgroundColor: refund > 0
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );
  }
}
