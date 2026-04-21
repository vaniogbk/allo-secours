import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/parcel_model.dart';
import '../../../providers/parcel_provider.dart';
import '../../../services/map_launcher_service.dart';

class AdminParcelsScreen extends ConsumerStatefulWidget {
  const AdminParcelsScreen({super.key});

  @override
  ConsumerState<AdminParcelsScreen> createState() =>
      _AdminParcelsScreenState();
}

class _AdminParcelsScreenState extends ConsumerState<AdminParcelsScreen>
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
            Tab(text: 'Livres'),
          ],
        ),
      ),
      body: parcelsAsync.when(
        data: (list) {
          final all = list;
          final pending = list
              .where((p) => p.status == ParcelStatus.pending)
              .toList();
          final transit = list
              .where((p) =>
                  p.status == ParcelStatus.pickedUp ||
                  p.status == ParcelStatus.inTransit)
              .toList();
          final done = list
              .where((p) => p.status == ParcelStatus.delivered)
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
        loading: () => const ShimmerList(count: 4, itemHeight: 120),
        error: (e, _) => Center(child: Text('Erreur: $e')),
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
        title: 'Aucun colis dans cette categorie',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: parcels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AdminParcelCard(parcel: parcels[i]),
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
          BoxShadow(color: AppColors.shadow, blurRadius: 6),
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
                  color: AppColors.getStatusBgColor(parcel.status.name),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 18,
                  color: AppColors.getStatusColor(parcel.status.name),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.trackingCode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${parcel.senderName} -> ${parcel.recipientName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getStatusBgColor(parcel.status.name),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  parcel.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getStatusColor(parcel.status.name),
                  ),
                ),
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
                label: '${parcel.weight} kg',
              ),
              const SizedBox(width: 10),
              _Chip(
                icon: Icons.local_shipping_outlined,
                label: parcel.typeLabel,
              ),
              const Spacer(),
              Text(
                FormatUtils.formatPrice(parcel.price),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (parcel.senderLatitude != null && parcel.senderLongitude != null ||
              parcel.recipientLatitude != null && parcel.recipientLongitude != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (parcel.senderLatitude != null && parcel.senderLongitude != null)
                  OutlinedButton.icon(
                    onPressed: () => MapLauncherService.openPoint(
                      latitude: parcel.senderLatitude!,
                      longitude: parcel.senderLongitude!,
                    ),
                    icon: const Icon(Icons.place_outlined, size: 16),
                    label: const Text('Depart'),
                  ),
                if (parcel.recipientLatitude != null &&
                    parcel.recipientLongitude != null)
                  OutlinedButton.icon(
                    onPressed: () => MapLauncherService.openPoint(
                      latitude: parcel.recipientLatitude!,
                      longitude: parcel.recipientLongitude!,
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('Destination'),
                  ),
                if (parcel.senderLatitude != null &&
                    parcel.senderLongitude != null &&
                    parcel.recipientLatitude != null &&
                    parcel.recipientLongitude != null)
                  ElevatedButton.icon(
                    onPressed: () => MapLauncherService.openDirections(
                      fromLat: parcel.senderLatitude!,
                      fromLng: parcel.senderLongitude!,
                      toLat: parcel.recipientLatitude!,
                      toLng: parcel.recipientLongitude!,
                    ),
                    icon: const Icon(Icons.alt_route_rounded, size: 16),
                    label: const Text('Itineraire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                    ),
                  ),
              ],
            ),
          ],
          if (parcel.status == ParcelStatus.pending) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _deletePendingParcel(context, ref),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                label: const Text(
                  'Supprimer la demande',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ],
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

  Future<void> _deletePendingParcel(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la demande ?'),
        content: const Text(
          'Cette demande d\'envoi sera supprimee definitivement.',
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

    await ref.read(parcelServiceProvider).deleteParcel(parcel.id);
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

class _NextStatusButton extends ConsumerWidget {
  final ParcelModel parcel;
  const _NextStatusButton({required this.parcel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (parcel.status == ParcelStatus.pending && !parcel.paymentVerified) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _verifyAndPickup(context, ref),
          icon: const Icon(Icons.verified_rounded, size: 16),
          label: const Text(
            'Verifier paiement et prendre en charge',
            style: TextStyle(fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
      );
    }

    if (parcel.status == ParcelStatus.pending && parcel.paymentVerified) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _pickupPaidParcel(context, ref),
          icon: const Icon(Icons.local_shipping_rounded, size: 16),
          label: const Text(
            'Prendre en charge le colis',
            style: TextStyle(fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
      );
    }

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
        label = 'Marquer Livre';
        historyLabel = 'Colis livre avec succes';
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
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  Future<void> _verifyAndPickup(BuildContext context, WidgetRef ref) async {
    final controller =
        TextEditingController(text: parcel.emergencyContactNumber ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verifier le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajoutez le numero du service d\'urgence avant la prise en charge du colis.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact d\'urgence',
                hintText: '+229 ...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    await ref.read(parcelServiceProvider).verifyPaymentAndPickup(
          parcel.id,
          emergencyContact:
              controller.text.trim().isEmpty ? null : controller.text.trim(),
        );
    controller.dispose();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement verifie et colis pris en charge'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _pickupPaidParcel(BuildContext context, WidgetRef ref) async {
    final controller =
        TextEditingController(text: parcel.emergencyContactNumber ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Prendre en charge le colis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Renseignez le contact d\'urgence a communiquer au client avant la prise en charge.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact d\'urgence',
                hintText: '+229 ...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    await ref.read(parcelServiceProvider).verifyPaymentAndPickup(
          parcel.id,
          emergencyContact:
              controller.text.trim().isEmpty ? null : controller.text.trim(),
        );
    controller.dispose();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colis pris en charge'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
