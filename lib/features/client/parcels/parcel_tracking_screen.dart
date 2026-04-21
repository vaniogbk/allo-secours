import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/parcel_model.dart';
import '../../../providers/parcel_provider.dart';
import '../../../services/map_launcher_service.dart';

class ParcelTrackingScreen extends ConsumerWidget {
  final String parcelId;
  const ParcelTrackingScreen({super.key, required this.parcelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcelAsync = ref.watch(parcelStreamProvider(parcelId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suivi du colis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: parcelAsync.when(
        data: (parcel) {
          if (parcel == null) {
            return const Center(child: Text('Accès non autorisé ou colis introuvable'));
          }
          return _buildBody(context, ref, parcel);
        },
        loading: () => const LoadingWidget(),
        error: (e, _) =>
            Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ParcelModel parcel) {
    final canModify = ref.read(parcelServiceProvider).canModifyParcel(parcel);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getStatusColor(parcel.status.name),
                  AppColors.getStatusColor(parcel.status.name)
                      .withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(parcel.status),
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel.statusLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                      if (parcel.estimatedDelivery != null)
                        Text(
                          'Livraison estimée: ${AppDateUtils.formatDate(parcel.estimatedDelivery!)}',
                          style: TextStyle(
                              color:
                                  Colors.white.withOpacity(0.85),
                              fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tracking code + QR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Code de suivi',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            parcel.trackingCode,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: parcel.trackingCode));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                              content: Text('Code copié')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                QrImageView(
                  data: parcel.trackingCode,
                  version: QrVersions.auto,
                  size: 120,
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Route
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trajet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _RouteRow(
                  icon: Icons.radio_button_on_rounded,
                  color: AppColors.primary,
                  label: 'Départ',
                  value: parcel.senderAddress,
                  sub: parcel.senderName,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  height: 24,
                  width: 2,
                  color: AppColors.border,
                ),
                _RouteRow(
                  icon: Icons.location_on_rounded,
                  color: AppColors.error,
                  label: 'Destination',
                  value: parcel.recipientAddress,
                  sub:
                      '${parcel.recipientName} — ${parcel.recipientPhone}',
                ),
              ],
            ),
          ),
          if (parcel.senderLatitude != null && parcel.senderLongitude != null ||
              parcel.recipientLatitude != null && parcel.recipientLongitude != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
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
                      label: const Text('Enlevement'),
                    ),
                  if (parcel.recipientLatitude != null &&
                      parcel.recipientLongitude != null)
                    OutlinedButton.icon(
                      onPressed: () => MapLauncherService.openPoint(
                        latitude: parcel.recipientLatitude!,
                        longitude: parcel.recipientLongitude!,
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Livraison'),
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
                      label: const Text('Voir l\'itineraire'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Infos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Détails du colis',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _InfoTile(
                            label: 'Type',
                            value: parcel.typeLabel)),
                    Expanded(
                        child: _InfoTile(
                            label: 'Poids',
                            value: '${parcel.weight} kg')),
                    Expanded(
                        child: _InfoTile(
                            label: 'Tarif',
                            value: FormatUtils.formatPrice(
                                parcel.price))),
                  ],
                ),
                if (parcel.note != null &&
                    parcel.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Note: ${parcel.note}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!parcel.paymentVerified || canModify) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Actions',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (!parcel.paymentVerified)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/payment?ref_id=${parcel.id}&amount=${parcel.price}&item_name=${Uri.encodeComponent('Colis ${parcel.trackingCode}')}&type=parcel',
                        ),
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: const Text('Payer ce colis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  if (!parcel.paymentVerified && canModify)
                    const SizedBox(height: 10),
                  if (canModify)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/client/parcels/${parcel.id}/edit'),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Modifier les informations'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Contact d'urgence si pris en charge
          if (parcel.paymentVerified && parcel.emergencyContactNumber != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emergency_rounded,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Contact d\'urgence',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(parcel.emergencyContactNumber!,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'Appelez ce numéro si le colis est déjà pris en charge et que vous avez besoin d\'assistance.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timeline
          const Text('Historique',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: parcel.statusHistory.isEmpty
                ? const Center(
                    child: Text('Aucun historique',
                        style: TextStyle(
                            color: AppColors.textSecondary)))
                : Column(
                    children: parcel.statusHistory.reversed
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => _TimelineItem(
                              item: e.value,
                              isLast: e.key ==
                                  parcel.statusHistory.length - 1,
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  IconData _statusIcon(ParcelStatus s) {
    switch (s) {
      case ParcelStatus.pending: return Icons.schedule_rounded;
      case ParcelStatus.pickedUp: return Icons.inventory_rounded;
      case ParcelStatus.inTransit:
        return Icons.local_shipping_rounded;
      case ParcelStatus.delivered: return Icons.done_all_rounded;
      case ParcelStatus.cancelled: return Icons.cancel_rounded;
    }
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;
  const _RouteRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ParcelStatusHistory item;
  final bool isLast;
  const _TimelineItem(
      {required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  if (item.note != null)
                    Text(item.note!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                      AppDateUtils.formatDateTime(item.date),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
