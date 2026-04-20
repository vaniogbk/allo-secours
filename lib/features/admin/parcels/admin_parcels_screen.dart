import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/parcel_model.dart';
import '../../../providers/parcel_provider.dart';

class AdminParcelsScreen extends ConsumerStatefulWidget {
  const AdminParcelsScreen({super.key});

  @override
  ConsumerState<AdminParcelsScreen> createState() =>
      _AdminParcelsScreenState();
}

class _AdminParcelsScreenState
    extends ConsumerState<AdminParcelsScreen>
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
    final parcelsAsync = ref.watch(allParcelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Gestion des colis'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'En attente'),
            Tab(text: 'En transit'),
            Tab(text: 'Livrés'),
          ],
        ),
      ),
      body: parcelsAsync.when(
        data: (list) {
          final all = list;
          final pending = list
              .where((p) =>
                  p.status == ParcelStatus.pending)
              .toList();
          final transit = list
              .where((p) =>
                  p.status == ParcelStatus.pickedUp ||
                  p.status == ParcelStatus.inTransit)
              .toList();
          final done = list
              .where((p) =>
                  p.status == ParcelStatus.delivered)
              .toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _ParcelList(parcels: all),
              _ParcelList(parcels: pending),
              _ParcelList(parcels: transit),
              _ParcelList(parcels: done),
            ],
          );
        },
        loading: () =>
            const ShimmerList(count: 4, itemHeight: 120),
        error: (e, _) =>
            Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _ParcelList extends StatelessWidget {
  final List<ParcelModel> parcels;
  const _ParcelList({required this.parcels});

  @override
  Widget build(BuildContext context) {
    if (parcels.isEmpty) {
      return const EmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          title: 'Aucun colis dans cette catégorie');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: parcels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _AdminParcelCard(parcel: parcels[i]),
    );
  }
}

class _AdminParcelCard extends ConsumerWidget {
  final ParcelModel parcel;
  const _AdminParcelCard({required this.parcel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getStatusBgColor(
                      parcel.status.name),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2_rounded,
                    size: 18,
                    color: AppColors.getStatusColor(
                        parcel.status.name)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parcel.trackingCode,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text(
                        '${parcel.senderName} → ${parcel.recipientName}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getStatusBgColor(
                      parcel.status.name),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(parcel.statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getStatusColor(
                            parcel.status.name))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(
                  icon: Icons.scale_outlined,
                  label: '${parcel.weight} kg'),
              const SizedBox(width: 10),
              _Chip(
                  icon: Icons.local_shipping_outlined,
                  label: parcel.typeLabel),
              const Spacer(),
              Text(FormatUtils.formatPrice(parcel.price),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 13)),
            ],
          ),
          if (parcel.status != ParcelStatus.delivered &&
              parcel.status != ParcelStatus.cancelled) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _NextStatusButton(parcel: parcel),
          ],
        ],
      ),
    );
  }
}

class _NextStatusButton extends ConsumerWidget {
  final ParcelModel parcel;
  const _NextStatusButton({required this.parcel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ParcelStatus? next;
    String? label;
    String? historyLabel;

    switch (parcel.status) {
      case ParcelStatus.pending:
        next = ParcelStatus.pickedUp;
        label = 'Marquer Pris en charge';
        historyLabel = 'Colis pris en charge';
        break;
      case ParcelStatus.pickedUp:
        next = ParcelStatus.inTransit;
        label = 'Marquer En transit';
        historyLabel = 'Colis en transit';
        break;
      case ParcelStatus.inTransit:
        next = ParcelStatus.delivered;
        label = 'Marquer Livré';
        historyLabel = 'Colis livré avec succès';
        break;
      default:
        return const SizedBox();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await ref
              .read(parcelServiceProvider)
              .updateStatus(parcel.id, next!, historyLabel!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(historyLabel),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        icon: const Icon(Icons.check_rounded, size: 16),
        label: Text(label,
            style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}