import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/reservation_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/car_provider.dart';
import '../../../providers/parcel_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/reservation_provider.dart';
import '../../../providers/user_provider.dart';
import '../cars/admin_cars_screen.dart';
import '../clients/admin_clients_screen.dart';
import '../parcels/admin_parcels_screen.dart';
import '../reservations/admin_reservations_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  final int currentIndex;

  const AdminHomeScreen({
    super.key,
    this.currentIndex = 0,
  });

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/admin/home',
    ),
    _NavItem(
      icon: Icons.directions_car_rounded,
      label: 'Voitures',
      route: '/admin/cars',
    ),
    _NavItem(
      icon: Icons.calendar_today_rounded,
      label: 'Reservations',
      route: '/admin/reservations',
    ),
    _NavItem(
      icon: Icons.inventory_2_rounded,
      label: 'Colis',
      route: '/admin/parcels',
    ),
    _NavItem(
      icon: Icons.people_rounded,
      label: 'Clients',
      route: '/admin/clients',
    ),
  ];

  static const List<Widget> _pages = [
    _DashboardPage(),
    AdminCarsScreen(),
    AdminReservationsScreen(),
    AdminParcelsScreen(),
    AdminClientsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final selectedIndex = currentIndex.clamp(0, _pages.length - 1).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 240,
              color: Colors.white,
              child: Column(
                children: [
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'LogiTrack',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _navItems.length,
                      itemBuilder: (_, i) {
                        final item = _navItems[i];
                        final selected = selectedIndex == i;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.go(item.route),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryLight
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await ref.read(authServiceProvider).logout();
                        if (context.mounted) {
                          context.go('/auth/login');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Deconnexion',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _pages[selectedIndex]),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => context.go(_navItems[index].route),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textHint,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              elevation: 0,
              items: _navItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _DashboardPage extends ConsumerWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final carsAsync = ref.watch(allCarsStreamProvider);
    final resAsync = ref.watch(allReservationsProvider);
    final parcelsAsync = ref.watch(allParcelsProvider);
    final userAsync = ref.watch(userStreamProvider);
    final userStatsAsync = ref.watch(userStatsProvider);
    final revenueAsync = ref.watch(revenueSummaryProvider);

    final totalCars = carsAsync.valueOrNull?.length ?? 0;
    final availableCars =
        carsAsync.valueOrNull?.where((c) => c.isAvailable).length ?? 0;
    final totalRes = resAsync.valueOrNull?.length ?? 0;
    final activeRes = resAsync.valueOrNull
            ?.where(
              (r) => r.statusKey == 'active' || r.statusKey == 'confirmed',
            )
            .length ??
        0;
    final totalParcels = parcelsAsync.valueOrNull?.length ?? 0;
    final deliveredParcels = parcelsAsync.valueOrNull
            ?.where((p) => p.status.name == 'delivered')
            .length ??
        0;
    final usersOnline = userStatsAsync.valueOrNull?['online'] ?? 0;
    final usersOffline = userStatsAsync.valueOrNull?['offline'] ?? 0;
    final totalUsers = userStatsAsync.valueOrNull?['total'] ?? 0;
    final reservationRevenue = revenueAsync.valueOrNull?['reservation'] ?? 0.0;
    final parcelRevenue = revenueAsync.valueOrNull?['parcel'] ?? 0.0;
    final isTwoColumns = screenWidth > 950;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                          'Bonjour, ${userAsync.valueOrNull?.fullName ?? 'Admin'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          AppDateUtils.formatDate(DateTime.now()),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
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
                      ref.invalidate(userStatsProvider);
                      ref.invalidate(revenueSummaryProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: screenWidth > 1200
                    ? 4
                    : screenWidth > 650
                        ? 2
                        : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: screenWidth > 1200 ? 1.7 : 1.55,
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
                    title: 'Reservations',
                    value: '$totalRes',
                    sub: '$activeRes actives',
                    gradient: AppColors.secondaryGradient,
                  ),
                  _StatCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Colis',
                    value: '$totalParcels',
                    sub: '$deliveredParcels livres',
                    gradient: AppColors.accentGradient,
                  ),
                  _StatCard(
                    icon: Icons.people_rounded,
                    title: 'Clients actifs',
                    value: '$usersOnline',
                    sub: '$totalUsers inscrits',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF10B981)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isTwoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DomainCard(
                        title: 'Location de voitures',
                        countLabel: 'Reservations',
                        countValue: '$totalRes',
                        revenueLabel: 'Revenus',
                        revenueValue: FormatUtils.formatPrice(reservationRevenue),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DomainCard(
                        title: 'Envoi de colis',
                        countLabel: 'Colis',
                        countValue: '$totalParcels',
                        revenueLabel: 'Revenus',
                        revenueValue: FormatUtils.formatPrice(parcelRevenue),
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _DomainCard(
                      title: 'Location de voitures',
                      countLabel: 'Reservations',
                      countValue: '$totalRes',
                      revenueLabel: 'Revenus',
                      revenueValue: FormatUtils.formatPrice(reservationRevenue),
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    _DomainCard(
                      title: 'Envoi de colis',
                      countLabel: 'Colis',
                      countValue: '$totalParcels',
                      revenueLabel: 'Revenus',
                      revenueValue: FormatUtils.formatPrice(parcelRevenue),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vue d\'ensemble',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: ([
                                    totalRes,
                                    totalParcels,
                                    activeRes,
                                  ].reduce((a, b) => a > b ? a : b) +
                                  2)
                              .toDouble(),
                          barGroups: [
                            _barGroup(0, totalRes.toDouble(), AppColors.primary),
                            _barGroup(
                              1,
                              totalParcels.toDouble(),
                              AppColors.secondary,
                            ),
                            _barGroup(2, activeRes.toDouble(), AppColors.accent),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return const Text(
                                        'Reserv.',
                                        style: TextStyle(fontSize: 10),
                                      );
                                    case 1:
                                      return const Text(
                                        'Colis',
                                        style: TextStyle(fontSize: 10),
                                      );
                                    case 2:
                                      return const Text(
                                        'Actives',
                                        style: TextStyle(fontSize: 10),
                                      );
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _MiniInfo(
                      label: 'Clients en ligne',
                      value: '$usersOnline',
                      color: Colors.green,
                    ),
                    _MiniInfo(
                      label: 'Clients hors ligne',
                      value: '$usersOffline',
                      color: Colors.grey,
                    ),
                    _MiniInfo(
                      label: 'Total clients',
                      value: '$totalUsers',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dernieres reservations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              resAsync.when(
                data: (list) => list.isEmpty
                    ? const Center(child: Text('Aucune reservation'))
                    : Column(
                        children: list
                            .take(5)
                            .map((reservation) => _RecentResTile(res: reservation))
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  final String title;
  final String countLabel;
  final String countValue;
  final String revenueLabel;
  final String revenueValue;
  final Color color;

  const _DomainCard({
    required this.title,
    required this.countLabel,
    required this.countValue,
    required this.revenueLabel,
    required this.revenueValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _MetricRow(label: countLabel, value: countValue, color: color),
          const SizedBox(height: 10),
          _MetricRow(
            label: revenueLabel,
            value: revenueValue,
            color: color.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentResTile extends StatelessWidget {
  final ReservationModel res;

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
              color: AppColors.getStatusBgColor(res.statusKey),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_rounded,
              size: 16,
              color: AppColors.getStatusColor(res.statusKey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.carFullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  res.userName ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.getStatusBgColor(res.statusKey),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  res.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getStatusColor(res.statusKey),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                FormatUtils.formatPrice(res.totalPrice),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
