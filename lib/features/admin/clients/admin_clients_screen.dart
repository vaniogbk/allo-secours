import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

final allClientsProvider = StreamProvider<List<UserModel>>((ref) {
  final userAsync = ref.watch(userStreamProvider);
  final user = userAsync.valueOrNull;
  if (user == null || user.role != 'admin') {
    return Stream.value([]);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'client')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => UserModel.fromDoc(d)).toList());
});

class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() =>
      _AdminClientsScreenState();
}

class _AdminClientsScreenState
    extends ConsumerState<AdminClientsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Gestion des clients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
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
      body: clientsAsync.when(
        data: (clients) {
          var filtered = clients;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((c) =>
                    c.fullName.toLowerCase().contains(q) ||
                    c.email.toLowerCase().contains(q) ||
                    c.phone.contains(q))
                .toList();
          }

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: 'Aucun client trouvé',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _ClientCard(client: filtered[i]),
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

class _ClientCard extends ConsumerWidget {
  final UserModel client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: client.isBlocked
            ? AppColors.errorLight
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: client.isBlocked
                ? AppColors.error.withOpacity(0.2)
                : AppColors.primaryLight,
            backgroundImage: client.photoUrl != null
                ? NetworkImage(client.photoUrl!)
                : null,
            child: client.photoUrl == null
                ? Text(client.initials,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: client.isBlocked
                            ? AppColors.error
                            : AppColors.primary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(client.fullName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (client.isBlocked) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: const Text('Bloqué',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(client.email,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                Text(client.phone,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary),
            onSelected: (v) =>
                _handleAction(context, ref, v),
            itemBuilder: (_) => [
              PopupMenuItem(
                value:
                    client.isBlocked ? 'unblock' : 'block',
                child: Row(
                  children: [
                    Icon(
                      client.isBlocked
                          ? Icons.check_circle_outline
                          : Icons.block_rounded,
                      size: 18,
                      color: client.isBlocked
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(client.isBlocked
                        ? 'Débloquer'
                        : 'Bloquer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    final block = action == 'block';
    await ref
        .read(authServiceProvider)
        .updateUser(client.id, {'isBlocked': block});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(block ? 'Client bloqué' : 'Client débloqué'),
          backgroundColor:
              block ? AppColors.error : AppColors.success,
        ),
      );
    }
  }
}