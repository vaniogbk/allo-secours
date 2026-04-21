import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/reservation_model.dart';
import '../../../providers/reservation_provider.dart';

class AdminReservationsScreen extends ConsumerStatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  ConsumerState<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState
    extends ConsumerState<AdminReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resAsync = ref.watch(allReservationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Gestion des reservations'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'En attente'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminees'),
          ],
        ),
      ),
      body: resAsync.when(
        data: (list) {
          final all = list;
          final pending = list
              .where((r) => r.status == ReservationStatus.pending)
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
              _ResList(reservations: all),
              _ResList(reservations: pending),
              _ResList(reservations: active),
              _ResList(reservations: done),
            ],
          );
        },
        loading: () => const ShimmerList(count: 4, itemHeight: 140),
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
        title: 'Aucune reservation',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AdminResCard(res: reservations[i]),
    );
  }
}

class _AdminResCard extends ConsumerWidget {
  final ReservationModel res;
  const _AdminResCard({required this.res});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.carFullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      res.userName ?? 'Client inconnu',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.getStatusBgColor(res.status.name),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  res.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getStatusColor(res.status.name),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${AppDateUtils.formatDate(res.startDate)} -> ${AppDateUtils.formatDate(res.endDate)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                FormatUtils.formatPrice(res.totalPrice),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: res.paymentVerified
                      ? AppColors.successLight
                      : AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  res.paymentVerified
                      ? 'Paiement verifie'
                      : 'Paiement en attente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: res.paymentVerified
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
              if (res.noShow)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Non-presentation',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    switch (res.status) {
      case ReservationStatus.pending:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _update(context, ref, ReservationStatus.cancelled),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text(
                      'Refuser',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => res.paymentVerified
                        ? _update(context, ref, ReservationStatus.confirmed)
                        : _verifyAndConfirm(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      res.paymentVerified
                          ? 'Valider la location'
                          : 'Verifier et valider',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _deletePendingReservation(context, ref),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                label: const Text(
                  'Supprimer cette demande',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ],
        );
      case ReservationStatus.confirmed:
        return SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _update(context, ref, ReservationStatus.active),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                  child: const Text('Marquer En cours'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _markNoShow(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Non-presentation'),
                ),
              ),
            ],
          ),
        );
      case ReservationStatus.active:
        return SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _update(context, ref, ReservationStatus.completed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Marquer Terminee'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _markNoShow(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Non-presentation'),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    ReservationStatus status,
  ) async {
    await ref.read(reservationServiceProvider).updateStatus(res.id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statut mis a jour'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _verifyAndConfirm(BuildContext context, WidgetRef ref) async {
    await ref.read(reservationServiceProvider).verifyPaymentAndConfirm(res.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement verifie et location validee'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _markNoShow(BuildContext context, WidgetRef ref) async {
    await ref.read(reservationServiceProvider).markNoShow(res.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation marquee en non-presentation'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _deletePendingReservation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la demande ?'),
        content: const Text(
          'Cette demande de reservation sera supprimee definitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(reservationServiceProvider).deleteReservation(res.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande supprimee'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
