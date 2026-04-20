import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/payment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String reservationId;
  final double amount;
  final String itemName;
  final PaymentType paymentType;

  const PaymentScreen({
    super.key,
    required this.reservationId,
    required this.amount,
    required this.itemName,
    required this.paymentType,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé du paiement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Montant à payer',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.amount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Objet',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        widget.itemName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Méthodes de paiement
            const Text(
              'Choisir une méthode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Carte bancaire
            _PaymentMethodCard(
              method: PaymentMethod.card,
              title: 'Carte bancaire',
              subtitle: 'Visa, MasterCard, American Express',
              icon: Icons.credit_card_rounded,
              isSelected: _selectedMethod == PaymentMethod.card,
              onTap: () => setState(() => _selectedMethod = PaymentMethod.card),
            ),
            const SizedBox(height: 12),

            // Mobile Money
            _PaymentMethodCard(
              method: PaymentMethod.mobileMoney,
              title: 'Mobile Money',
              subtitle: 'MTN, Orange, Moov',
              icon: Icons.phone_android_rounded,
              isSelected: _selectedMethod == PaymentMethod.mobileMoney,
              onTap: () =>
                  setState(() => _selectedMethod = PaymentMethod.mobileMoney),
            ),
            const SizedBox(height: 12),

            // Espèces
            _PaymentMethodCard(
              method: PaymentMethod.cash,
              title: 'Paiement à la livraison',
              subtitle: 'Payer en espèces au livreur',
              icon: Icons.money_rounded,
              isSelected: _selectedMethod == PaymentMethod.cash,
              onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
            ),
            const SizedBox(height: 28),

            // Avis de sécurité
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vos données sont sécurisées avec le chiffrement SSL 256-bit',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de paiement
            CustomButton(
              label: 'Procéder au paiement',
              onPressed: _loading ? null : _processPayment,
              isLoading: _loading,
              prefixIcon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 12),

            // Bouton Annuler
            CustomButton(
              label: 'Annuler',
              variant: ButtonVariant.outline,
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _loading = true);
    try {
      final paymentService = ref.read(paymentServiceProvider);
      
      // Obtenir l'utilisateur actuel
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer le paiement dans Firestore
      final paymentId = await paymentService.createPayment(
        userId: user.uid,
        userName: null, // Peut être obtenu plus tard si nécessaire
        type: widget.paymentType,
        refId: widget.reservationId,
        amount: widget.amount,
        method: _selectedMethod,
      );

      if (!mounted) return;

      // Selon la méthode sélectionnée
      switch (_selectedMethod) {
        case PaymentMethod.card:
          // Rediriger vers le paiement par carte
          if (mounted) {
            context.push(
              '/payment/card/$paymentId',
              extra: {'amount': widget.amount},
            );
          }
          break;

        case PaymentMethod.mobileMoney:
          // Rediriger vers le paiement Mobile Money
          if (mounted) {
            context.push(
              '/payment/mobile-money/$paymentId',
              extra: {'amount': widget.amount},
            );
          }
          break;

        case PaymentMethod.cash:
          // Confirmer le paiement en attente
          await paymentService.updatePaymentStatus(
            paymentId,
            PaymentStatus.pending,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paiement à la livraison confirmé'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 24,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: AppColors.border,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

