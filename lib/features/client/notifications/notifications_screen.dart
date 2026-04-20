import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: user != null
                ? () =>
                    NotificationService.markAllAsRead(user.uid)
                : null,
            child: const Text('Tout lire',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification',
              subtitle: 'Vous n\'avez pas de notification',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: notifs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _NotifCard(notif: notifs[i]),
          );
        },
        loading: () =>
            const ShimmerList(count: 5, itemHeight: 80),
        error: (e, _) =>
            Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => NotificationService.markAsRead(notif.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.white
              : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    _typeColor(notif.type).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcon(notif.type),
                  size: 20, color: _typeColor(notif.type)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notif.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    AppDateUtils.timeAgo(notif.createdAt),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(NotificationType t) {
    switch (t) {
      case NotificationType.reservation:
        return Icons.directions_car_rounded;
      case NotificationType.parcel:
        return Icons.inventory_2_rounded;
      case NotificationType.payment:
        return Icons.payment_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }

  Color _typeColor(NotificationType t) {
    switch (t) {
      case NotificationType.reservation:
        return AppColors.primary;
      case NotificationType.parcel:
        return AppColors.secondary;
      case NotificationType.payment:
        return AppColors.accent;
      case NotificationType.system:
        return AppColors.info;
    }
  }
}