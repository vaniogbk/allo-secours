import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/parcel_model.dart';
import '../../../providers/parcel_provider.dart';
class ParcelListScreen extends ConsumerStatefulWidget {
  const ParcelListScreen({super.key});

  @override
  ConsumerState<ParcelListScreen> createState() =>
      _ParcelListScreenState();
}

class _ParcelListScreenState extends ConsumerState<ParcelListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mes colis'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Mes envois'),
            Tab(text: 'Suivre un colis'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/client/parcels/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Envoyer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MyParcelsTab(),
          _TrackParcelTab(),
        ],
      ),
    );
  }
}

class _MyParcelsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcelsAsync = ref.watch(myParcelsProvider);
    return parcelsAsync.when(
      data: (parcels) {
        if (parcels.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: 'Aucun colis envoyé',
            subtitle: 'Créez votre premier envoi',
            actionLabel: 'Envoyer un colis',
            onAction: () => context.push('/client/parcels/create'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: parcels.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ParcelCard(parcel: parcels[i]),
        );
      },
      loading: () => const ShimmerList(count: 4, itemHeight: 110),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _TrackParcelTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TrackParcelTab> createState() =>
      _TrackParcelTabState();
}

class _TrackParcelTabState extends ConsumerState<_TrackParcelTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  ParcelModel? _found;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _found = null;
      _error = null;
    });
    try {
      final parcel = await ref
          .read(parcelServiceProvider)
          .getParcelByTracking(
              _ctrl.text.trim().toUpperCase());
      setState(() {
        _found = parcel;
        _error = parcel == null
            ? 'Aucun colis trouvé avec ce code'
            : null;
      });
    } catch (_) {
      setState(() => _error = 'Erreur de recherche');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ex: LGT2024XXXXXX',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _loading ? null : _search,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.search_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Text(_error!,
                      style:
                          const TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          if (_found != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context
                  .push('/client/parcels/${_found!.id}/track'),
              child: _ParcelCard(parcel: _found!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParcelCard extends StatelessWidget {
  final ParcelModel parcel;
  const _ParcelCard({required this.parcel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('/client/parcels/${parcel.id}/track'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 8)
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.getStatusBgColor(
                        parcel.status.name),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(parcel.status),
                    size: 22,
                    color: AppColors.getStatusColor(
                        parcel.status.name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vers ${parcel.recipientName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        parcel.trackingCode,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.getStatusBgColor(
                            parcel.status.name),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        parcel.statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getStatusColor(
                                parcel.status.name)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.timeAgo(parcel.createdAt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
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
                Text(
                  FormatUtils.formatPrice(parcel.price),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(ParcelStatus s) {
    switch (s) {
      case ParcelStatus.pending:
        return Icons.schedule_rounded;
      case ParcelStatus.pickedUp:
        return Icons.inventory_rounded;
      case ParcelStatus.inTransit:
        return Icons.local_shipping_rounded;
      case ParcelStatus.delivered:
        return Icons.done_all_rounded;
      case ParcelStatus.cancelled:
        return Icons.cancel_outlined;
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
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}