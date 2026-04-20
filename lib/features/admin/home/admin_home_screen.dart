import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/car_provider.dart';
import '../../../providers/parcel_provider.dart';
import '../../../providers/reservation_provider.dart';
import '../cars/admin_cars_screen.dart';
import '../reservations/admin_reservations_screen.dart';
import '../parcels/admin_parcels_screen.dart';
import '../clients/admin_clients_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() =>
      _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.directions_car_rounded, label: 'Voitures'),
    _NavItem(
        icon: Icons.calendar_today_rounded,
        label: 'Réservations'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Colis'),
    _NavItem(icon: Icons.people_rounded, label: 'Clients'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    final pages = [
      const _DashboardPage(),
      const AdminCarsScreen(),
      const AdminReservationsScreen(),
      const AdminParcelsScreen(),
      const AdminClientsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // ── SIDEBAR WEB ──
          if (isWide)
            Container(
              width: 240,
              color: Colors.white,
              child: Column(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text('LogiTrack',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _navItems.length,
                      itemBuilder: (_, i) {
                        final item = _navItems[i];
                        final selected = _selectedIndex == i;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedIndex = i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryLight
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(item.icon,
                                    size: 20,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors
                                            .textSecondary),
                                const SizedBox(width: 12),
                                Text(item.label,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors
                                                .textSecondary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Logout
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: () async {
                        await ref
                            .read(authServiceProvider)
                            .logout();
                        if (context.mounted) {
                          context.go('/auth/login');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 20,
                                color: AppColors.error),
                            SizedBox(width: 12),
                            Text('Déconnexion',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ── CONTENT ──
          Expanded(
            child: pages[_selectedIndex],
          ),
        ],
      ),
      // ── BOTTOM NAV MOBILE ──
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) =>
                  setState(() => _selectedIndex = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textHint,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              elevation: 0,
              items: _navItems
                  .map((e) => BottomNavigationBarItem(
                        icon: Icon(e.icon),
                        label: e.label,
                      ))
                  .toList(),
            ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ══════════════════════════════════════════════
// DASHBOARD PAGE
// ══════════════════════════════════════════════
class _DashboardPage extends ConsumerWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carsAsync = ref.watch(allCarsStreamProvider);
    final resAsync = ref.watch(allReservationsProvider);
    final parcelsAsync = ref.watch(allParcelsProvider);
    final userAsync = ref.watch(userStreamProvider);

    final totalCars = carsAsync.valueOrNull?.length ?? 0;
    final availableCars = carsAsync.valueOrNull
            ?.where((c) => c.isAvailable)
            .length ??
        0;
    final totalRes = resAsync.valueOrNull?.length ?? 0;
    final activeRes = resAsync.valueOrNull
            ?.where((r) =>
                r.status.name == 'active' ||
                r.status.name == 'confirmed')
            .length ??
        0;
    final totalParcels = parcelsAsync.valueOrNull?.length ?? 0;
    final deliveredParcels = parcelsAsync.valueOrNull
            ?.where((p) => p.status.name == 'delivered')
            .length ??
        0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${userAsync.valueOrNull?.fullName ?? 'Admin'} 👋',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800),
                        ),
                        Text(
                          AppDateUtils.formatDate(
                              DateTime.now()),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      ref.invalidate(allCarsStreamProvider);
                      ref.invalidate(allReservationsProvider);
                      ref.invalidate(allParcelsProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats grid
              GridView.count(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600
                        ? 4
                        : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.directions_car_rounded,
                    title: 'Voitures',
                    value: '$totalCars',
                    sub: '$availableCars disponibles',
                    gradient: AppColors.primaryGradient,
                  ),
                  _StatCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Réservations',
                    value: '$totalRes',
                    sub: '$activeRes actives',
                    gradient: AppColors.secondaryGradient,
                  ),
                  _StatCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Colis',
                    value: '$totalParcels',
                    sub: '$deliveredParcels livrés',
                    gradient: AppColors.accentGradient,
                  ),
                  _StatCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Total ops',
                    value: '${totalRes + totalParcels}',
                    sub: 'Opérations',
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF6D28D9)
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vue d\'ensemble',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment:
                              BarChartAlignment.spaceAround,
                          maxY: ([
                                    totalRes,
                                    totalParcels,
                                    activeRes
                                  ].reduce((a, b) =>
                                          a > b ? a : b) +
                                  2)
                              .toDouble(),
                          barGroups: [
                            _barGroup(0, totalRes.toDouble(),
                                AppColors.primary),
                            _barGroup(
                                1,
                                totalParcels.toDouble(),
                                AppColors.secondary),
                            _barGroup(
                                2,
                                activeRes.toDouble(),
                                AppColors.accent),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  switch (v.toInt()) {
                                    case 0:
                                      return const Text(
                                          'Réserv.',
                                          style: TextStyle(
                                              fontSize: 10));
                                    case 1:
                                      return const Text(
                                          'Colis',
                                          style: TextStyle(
                                              fontSize: 10));
                                    case 2:
                                      return const Text(
                                          'Actives',
                                          style: TextStyle(
                                              fontSize: 10));
                                    default:
                                      return const SizedBox();
                                  }
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dernières réservations
              const Text('Dernières réservations',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              resAsync.when(
                data: (list) => list.isEmpty
                    ? const Center(
                        child: Text('Aucune réservation'))
                    : Column(
                        children: list
                            .take(5)
                            .map((r) =>
                                _RecentResTile(res: r))
                            .toList()),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: color,
        width: 28,
        borderRadius: BorderRadius.circular(6),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String sub;
  final LinearGradient gradient;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.sub,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: Colors.white.withOpacity(0.9), size: 26),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
          Text(title,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text(sub,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11)),
        ],
      ),
    );
  }
}

class _RecentResTile extends StatelessWidget {
  final res;
  const _RecentResTile({required this.res});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.getStatusBgColor(
                  res.status.name),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_car_rounded,
                size: 16,
                color: AppColors.getStatusColor(
                    res.status.name)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res.carFullName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(res.userName ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.getStatusBgColor(
                      res.status.name),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(res.statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getStatusColor(
                            res.status.name))),
              ),
              const SizedBox(height: 3),
              Text(
                FormatUtils.formatPrice(res.totalPrice),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}