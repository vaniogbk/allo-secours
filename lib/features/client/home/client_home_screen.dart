import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/car_model.dart';
import '../../../models/parcel_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/car_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/parcel_provider.dart';
import '../../../providers/reservation_provider.dart';
import '../cars/car_list_screen.dart';
import '../parcels/parcel_list_screen.dart';
import '../reservations/my_reservations_screen.dart';
import '../profile/profile_screen.dart';

// ValueNotifier global pour changer d'onglet depuis n'importe où
final _tabIndexNotifier = ValueNotifier<int>(0);

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() =>
      _ClientHomeScreenState();
}

class _ClientHomeScreenState
    extends ConsumerState<ClientHomeScreen> {
  @override
  void initState() {
    super.initState();
    _tabIndexNotifier.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabIndexNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider);
    final currentIndex = _tabIndexNotifier.value;

    final pages = [
      const _HomePage(),
      const CarListScreen(),
      const ParcelListScreen(),
      const MyReservationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 12),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => _tabIndexNotifier.value = i,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car_rounded),
              label: 'Voitures',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Colis',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'Réservations',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.person_outline_rounded),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// HOME PAGE
// ════════════════════════════════════════════
class _HomePage extends ConsumerWidget {
  const _HomePage();

  // Méthode utilitaire pour changer d'onglet
  static void goToTab(int index) {
    _tabIndexNotifier.value = index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamProvider);
    final carsAsync = ref.watch(carsStreamProvider);
    final parcelsAsync = ref.watch(myParcelsProvider);
    final reservationsAsync = ref.watch(myReservationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(carsStreamProvider);
            ref.invalidate(myParcelsProvider);
            ref.invalidate(myReservationsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      20, 16, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          userAsync.when(
                            data: (user) => CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  Colors.white.withOpacity(0.3),
                              backgroundImage:
                                  user?.photoUrl != null
                                      ? NetworkImage(
                                          user!.photoUrl!)
                                      : null,
                              child: user?.photoUrl == null
                                  ? Text(
                                      user?.initials ?? '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            loading: () => const CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white24,
                            ),
                            error: (_, __) =>
                                const CircleAvatar(radius: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: userAsync.when(
                              data: (user) => Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bonjour,',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    user?.fullName ??
                                        'Utilisateur',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () => context.push(
                                    '/client/notifications'),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(3),
                                    decoration:
                                        const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.calendar_today_rounded,
                            label: 'Réservations',
                            value: reservationsAsync
                                    .valueOrNull?.length
                                    .toString() ??
                                '0',
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.inventory_2_rounded,
                            label: 'Colis envoyés',
                            value: parcelsAsync.valueOrNull?.length
                                    .toString() ??
                                '0',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── SERVICES RAPIDES ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Services rapides',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ServiceCard(
                              icon: Icons.directions_car_rounded,
                              label: 'Louer\nune voiture',
                              color: AppColors.primary,
                              onTap: () => goToTab(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ServiceCard(
                              icon: Icons.send_rounded,
                              label: 'Envoyer\nun colis',
                              color: AppColors.secondary,
                              onTap: () => context
                                  .push('/client/parcels/create'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ServiceCard(
                              icon: Icons.track_changes_rounded,
                              label: 'Suivre\nun colis',
                              color: AppColors.accent,
                              onTap: () => goToTab(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── VOITURES DISPONIBLES ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Voitures disponibles',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => goToTab(1),
                        child: const Text(
                          'Voir tout',
                          style:
                              TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                carsAsync.when(
                  data: (cars) => cars.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16),
                          child: Center(
                            child: Text(
                              'Aucune voiture disponible',
                              style: TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingL,
                            ),
                            itemCount:
                                cars.length > 6 ? 6 : cars.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) =>
                                _CarCardSmall(car: cars[i]),
                          ),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ShimmerCard(height: 220),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 28),

                // ── MES DERNIERS COLIS ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mes derniers colis',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => goToTab(2),
                        child: const Text(
                          'Voir tout',
                          style:
                              TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                parcelsAsync.when(
                  data: (parcels) => parcels.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Aucun colis envoyé',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w600),
                                      ),
                                      Text(
                                        'Envoyez votre premier colis',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push(
                                      '/client/parcels/create'),
                                  child: const Text('Envoyer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingL),
                          itemCount: parcels.length > 3
                              ? 3
                              : parcels.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _ParcelMiniCard(parcel: parcels[i]),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ShimmerCard(height: 80),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── STAT CARD ──
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── SERVICE CARD ──
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CAR CARD SMALL ──
class _CarCardSmall extends StatelessWidget {
  final CarModel car;

  const _CarCardSmall({required this.car});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/cars/${car.id}'),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: car.mainPhoto != null
                  ? Image.network(
                      car.mainPhoto!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${car.seats} places',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${FormatUtils.formatPrice(car.pricePerDay)}/j',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
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
        height: 110,
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(
            Icons.directions_car_rounded,
            size: 48,
            color: AppColors.primary,
          ),
        ),
      );
}

// ── PARCEL MINI CARD ──
class _ParcelMiniCard extends StatelessWidget {
  final ParcelModel parcel;

  const _ParcelMiniCard({required this.parcel});

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
            BoxShadow(color: AppColors.shadow, blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.getStatusBgColor(
                    parcel.status.name),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 18,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    parcel.trackingCode,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
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
                      parcel.status.name),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}