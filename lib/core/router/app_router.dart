import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/client/home/client_home_screen.dart';
import '../../features/client/cars/car_list_screen.dart';
import '../../features/client/cars/car_detail_screen.dart';
import '../../features/client/cars/car_booking_screen.dart';
import '../../features/client/parcels/parcel_list_screen.dart';
import '../../features/client/parcels/create_parcel_screen.dart';
import '../../features/client/parcels/parcel_tracking_screen.dart';
import '../../features/client/reservations/my_reservations_screen.dart';
import '../../features/client/notifications/notifications_screen.dart';
import '../../features/client/profile/profile_screen.dart';
import '../../features/client/profile/edit_profile_screen.dart';
import '../../features/client/support/support_screen.dart';
import '../../features/admin/home/admin_home_screen.dart';
import '../../features/admin/cars/admin_cars_screen.dart';
import '../../features/admin/cars/admin_add_car_screen.dart';
import '../../features/admin/reservations/admin_reservations_screen.dart';
import '../../features/admin/parcels/admin_parcels_screen.dart';
import '../../features/admin/clients/admin_clients_screen.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;

      // Splash toujours autorisé
      if (loc == '/splash') return null;

      // Non connecté → login
      final isAuthRoute = loc.startsWith('/auth/');
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';

      if (isLoggedIn) {
        UserModel? userData;
        try {
          userData = await ref
              .read(authServiceProvider)
              .getUser(user.uid);
        } catch (_) {
          // Si on ne peut pas lire le user, on déconnecte
          return '/auth/login';
        }

        final isAdmin = userData.role == UserRole.admin;

        // Connecté sur une route auth → rediriger selon rôle
        if (isAuthRoute) {
          return isAdmin ? '/admin/home' : '/client/home';
        }

        // ── SÉCURITÉ CRITIQUE ──
        // Un CLIENT qui essaie d'accéder à /admin → bloqué
        if (!isAdmin && loc.startsWith('/admin/')) {
          return '/client/home';
        }

        // Un ADMIN qui essaie d'accéder à /client → bloqué
        if (isAdmin && loc.startsWith('/client/')) {
          return '/admin/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── CLIENT ROUTES ──
      GoRoute(
        path: '/client/home',
        builder: (_, __) => const ClientHomeScreen(),
      ),
      GoRoute(
        path: '/client/cars',
        builder: (_, __) => const CarListScreen(),
      ),
      GoRoute(
        path: '/client/cars/:id',
        builder: (_, s) =>
            CarDetailScreen(carId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/client/cars/:id/book',
        builder: (_, s) =>
            CarBookingScreen(carId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/client/parcels/create',
        builder: (_, __) => const CreateParcelScreen(),
      ),
      GoRoute(
        path: '/client/parcels',
        builder: (_, __) => const ParcelListScreen(),
      ),
      GoRoute(
        path: '/client/parcels/:id/track',
        builder: (_, s) => ParcelTrackingScreen(
            parcelId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/client/reservations',
        builder: (_, __) => const MyReservationsScreen(),
      ),
      GoRoute(
        path: '/client/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/client/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/client/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/client/support',
        builder: (_, __) => const SupportScreen(),
      ),

      // ── ADMIN ROUTES ──
      GoRoute(
        path: '/admin/home',
        builder: (_, __) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/cars',
        builder: (_, __) => const AdminCarsScreen(),
      ),
      GoRoute(
        path: '/admin/cars/add',
        builder: (_, __) => const AdminAddCarScreen(),
      ),
      GoRoute(
        path: '/admin/cars/:id/edit',
        builder: (_, s) =>
            AdminAddCarScreen(carId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/reservations',
        builder: (_, __) => const AdminReservationsScreen(),
      ),
      GoRoute(
        path: '/admin/parcels',
        builder: (_, __) => const AdminParcelsScreen(),
      ),
      GoRoute(
        path: '/admin/clients',
        builder: (_, __) => const AdminClientsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Accès refusé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas accès à cette page.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _.go('/auth/login'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});