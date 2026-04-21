import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/cloudinary_image.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/car_model.dart';
import '../../../providers/car_provider.dart';

class CarDetailScreen extends ConsumerStatefulWidget {
  final String carId;
  const CarDetailScreen({super.key, required this.carId});

  @override
  ConsumerState<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends ConsumerState<CarDetailScreen> {
  int _currentPhoto = 0;
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carAsync = ref.watch(carDetailProvider(widget.carId));
    return carAsync.when(
      data: (car) => _buildBody(car),
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildBody(CarModel car) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    size: 20, color: AppColors.textPrimary),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: car.photos.isEmpty
                  ? Container(
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(Icons.directions_car_rounded,
                            size: 80, color: AppColors.primary),
                      ),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageCtrl,
                          itemCount: car.photos.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPhoto = i),
                          itemBuilder: (_, i) => CloudinaryImage(
                            imageUrl: car.photos[i],
                            fit: BoxFit.cover,
                            optimizedWidth: 1400,
                            errorWidget: Container(
                              color: AppColors.primaryLight,
                              child: const Icon(
                                  Icons.directions_car_rounded,
                                  size: 80,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                        if (car.photos.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: List.generate(
                                car.photos.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: _currentPhoto == i ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentPhoto == i
                                        ? AppColors.primary
                                        : Colors.white
                                            .withOpacity(0.6),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          car.fullName,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: car.isAvailable
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          car.isAvailable
                              ? 'Disponible'
                              : 'Indisponible',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: car.isAvailable
                                  ? AppColors.success
                                  : AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _PriceBox(
                        label: 'Prix / jour',
                        value:
                            FormatUtils.formatPrice(car.pricePerDay),
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      _PriceBox(
                        label: 'Caution',
                        value: FormatUtils.formatPrice(car.deposit),
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Caractéristiques',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _FeatureItem(
                          icon: Icons.people_outline,
                          label: '${car.seats} places'),
                      _FeatureItem(
                          icon: Icons.settings_outlined,
                          label: car.transmissionLabel),
                      _FeatureItem(
                          icon: Icons.local_gas_station_outlined,
                          label: car.fuelLabel),
                      _FeatureItem(
                          icon: Icons.calendar_today_outlined,
                          label: '${car.year}'),
                    ],
                  ),
                  if (car.features.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: car.features
                          .map((f) => Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(f,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight:
                                            FontWeight.w500)),
                              ))
                          .toList(),
                    ),
                  ],
                  if (car.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(car.description,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6)),
                  ],
                  const SizedBox(height: 28),
                  if (car.isAvailable)
                    CustomButton(
                      label: 'Réserver cette voiture',
                      onPressed: () => context
                          .push('/client/cars/${car.id}/book'),
                      prefixIcon: Icons.calendar_month_rounded,
                    )
                  else
                    CustomButton(
                      label: 'Voiture indisponible',
                      onPressed: null,
                      variant: ButtonVariant.outline,
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PriceBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color)),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
