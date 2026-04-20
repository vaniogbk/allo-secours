import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/car_model.dart';
import '../../../providers/car_provider.dart';

class CarListScreen extends ConsumerStatefulWidget {
  const CarListScreen({super.key});

  @override
  ConsumerState<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends ConsumerState<CarListScreen> {
  String _search = '';
  String _filterTransmission = 'all';

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(carsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Voitures disponibles'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune_rounded),
            onSelected: (v) =>
                setState(() => _filterTransmission = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'all', child: Text('Toutes')),
              const PopupMenuItem(
                  value: 'automatic', child: Text('Automatique')),
              const PopupMenuItem(
                  value: 'manual', child: Text('Manuelle')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher une voiture...',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textSecondary),
                fillColor: Colors.white,
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: carsAsync.when(
        data: (cars) {
          var filtered = cars;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((c) =>
                    c.brand.toLowerCase().contains(q) ||
                    c.model.toLowerCase().contains(q))
                .toList();
          }
          if (_filterTransmission == 'automatic') {
            filtered = filtered
                .where((c) => c.transmission == Transmission.automatic)
                .toList();
          } else if (_filterTransmission == 'manual') {
            filtered = filtered
                .where((c) => c.transmission == Transmission.manual)
                .toList();
          }

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.directions_car_rounded,
              title: 'Aucune voiture trouvée',
              subtitle: 'Modifiez vos critères de recherche',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CarCard(car: filtered[i]),
          );
        },
        loading: () => const ShimmerList(count: 5, itemHeight: 180),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  final CarModel car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/cars/${car.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusL)),
                  child: car.mainPhoto != null
                      ? Image.network(
                          car.mainPhoto!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholder(),
                        )
                      : _placeholder(),
                ),
                if (!car.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(
                                AppDimensions.radiusL)),
                      ),
                      child: const Center(
                        child: Text(
                          'Indisponible',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      car.transmissionLabel,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.fullName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Tag(
                                icon: Icons.people_outline,
                                label: '${car.seats} places'),
                            const SizedBox(width: 10),
                            _Tag(
                                icon:
                                    Icons.local_gas_station_outlined,
                                label: car.fuelLabel),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        FormatUtils.formatPrice(car.pricePerDay),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                      const Text(
                        'par jour',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 180,
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.directions_car_rounded,
              size: 64, color: AppColors.primary),
        ),
      );
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}