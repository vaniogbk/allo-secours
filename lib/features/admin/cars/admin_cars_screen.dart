import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/car_model.dart';
import '../../../providers/car_provider.dart';

class AdminCarsScreen extends ConsumerStatefulWidget {
  const AdminCarsScreen({super.key});

  @override
  ConsumerState<AdminCarsScreen> createState() =>
      _AdminCarsScreenState();
}

class _AdminCarsScreenState extends ConsumerState<AdminCarsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(allCarsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Gestion des voitures'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.push('/admin/cars/add'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher une voiture...',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20),
                fillColor: AppColors.background,
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
          if (filtered.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.directions_car_outlined,
              title: 'Aucune voiture',
              subtitle: 'Ajoutez votre première voiture',
              actionLabel: 'Ajouter',
              onAction: () =>
                  context.push('/admin/cars/add'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _AdminCarTile(car: filtered[i]),
          );
        },
        loading: () =>
            const ShimmerList(count: 4, itemHeight: 100),
        error: (e, _) =>
            Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _AdminCarTile extends ConsumerWidget {
  final CarModel car;
  const _AdminCarTile({required this.car});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14)),
            child: car.mainPhoto != null
                ? Image.network(
                    car.mainPhoto!,
                    width: 110,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _placeholder(),
                  )
                : _placeholder(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(car.fullName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Switch(
                        value: car.isAvailable,
                        onChanged: (v) => ref
                            .read(carServiceProvider)
                            .setAvailability(car.id, v),
                        activeColor: AppColors.success,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  Text(
                    '${car.transmissionLabel} • ${car.seats} places',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${FormatUtils.formatPrice(car.pricePerDay)}/j',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                      const Spacer(),
                      _ActionBtn(
                        icon: Icons.edit_outlined,
                        color: AppColors.primary,
                        onTap: () => context.push(
                            '/admin/cars/${car.id}/edit'),
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.error,
                        onTap: () =>
                            _deleteDialog(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 110,
        height: 100,
        color: AppColors.primaryLight,
        child: const Icon(Icons.directions_car_rounded,
            size: 36, color: AppColors.primary),
      );

  void _deleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer cette voiture ?'),
        content:
            Text('${car.fullName} sera supprimée définitivement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(carServiceProvider)
                  .deleteCar(car.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voiture supprimée'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}