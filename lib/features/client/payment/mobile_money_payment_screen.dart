import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/payment_provider.dart';
import '../../../services/secure_url_launcher.dart';
import '../../../models/payment_model.dart';

enum MobileProvider { mtn, orange, moov }

class MobileMoneyPaymentScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final double amount;

  const MobileMoneyPaymentScreen({
    super.key,
    required this.paymentId,
    required this.amount,
  });

  @override
  ConsumerState<MobileMoneyPaymentScreen> createState() =>
      _MobileMoneyPaymentScreenState();
}

class _MobileMoneyPaymentScreenState
    extends ConsumerState<MobileMoneyPaymentScreen> {
  MobileProvider _selectedProvider = MobileProvider.mtn;
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paiement Mobile Money'),
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
            // Résumé du montant
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Montant à payer',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.amount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sélection du fournisseur
            const Text(
              'Choisir un fournisseur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            _ProviderButton(
              provider: MobileProvider.mtn,
              name: 'MTN Mobile Money',
              icon: '📱',
              isSelected: _selectedProvider == MobileProvider.mtn,
              onTap: () => setState(
                () => _selectedProvider = MobileProvider.mtn,
              ),
            ),
            const SizedBox(height: 12),

            _ProviderButton(
              provider: MobileProvider.orange,
              name: 'Orange Money',
              icon: '🟠',
              isSelected: _selectedProvider == MobileProvider.orange,
              onTap: () => setState(
                () => _selectedProvider = MobileProvider.orange,
              ),
            ),
            const SizedBox(height: 12),

            _ProviderButton(
              provider: MobileProvider.moov,
              name: 'Moov Benin',
              icon: '📞',
              isSelected: _selectedProvider == MobileProvider.moov,
              onTap: () => setState(
                () => _selectedProvider = MobileProvider.moov,
              ),
            ),
            const SizedBox(height: 24),

            // Numéro de téléphone
            const Text(
              'Numéro de téléphone',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              label: 'Numéro de téléphone',
              hint: '+229 9X XX XX XX',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_rounded,
              validator: _validatePhone,
            ),
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Comment ça marche?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Confirmez votre numéro\n2. Vous recevrez une demande de confirmation\n3. Entrez votre code secret pour confirmer',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.8),
                      height: 1.5,
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
              prefixIcon: Icons.send_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numéro requis';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 8) {
      return 'Numéro invalide';
    }
    return null;
  }

  Future<void> _processPayment() async {
    if (_phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre numéro'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paiement Mobile Money non pris en charge sur le web. Utilisez un appareil mobile.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final paymentService = ref.read(paymentServiceProvider);

      // Créer l'URL de paiement de manière SÉCURISÉE
      final paymentUrl = SecureUrlLauncher.createPaymentUrl(
        baseUrl: _getProviderApiUrl(),
        paymentId: widget.paymentId,
        amount: widget.amount,
        currency: 'XOF',
        returnUrl: 'https://logitrack.bj/payment/callback',
      );

      // Vérifier que l'URL a été créée correctement
      if (paymentUrl == null) {
        throw Exception('Impossible de générer l\'URL de paiement');
      }

      // Lancer l'URL de manière sécurisée
      final success = await SecureUrlLauncher.launchUrl(
        paymentUrl,
        externalApplication: true,
      );

      if (!success) {
        throw Exception(
            'Impossible de lancer le paiement. Vérifiez votre connexion.');
      }

      // Mettre à jour le statut du paiement
      await paymentService.updatePaymentStatus(
        widget.paymentId,
        PaymentStatus.pending,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vérification en cours... Veuillez confirmer'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Attendre quelques secondes puis retourner
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getProviderApiUrl() {
    // EN PRODUCTION: Utiliser les vraies URLs des APIs des fournisseurs
    // Ceci sont des exemples fictifs
    switch (_selectedProvider) {
      case MobileProvider.mtn:
        return 'https://api.mtn.bj/payment/initiate';
      case MobileProvider.orange:
        return 'https://api.orange.bj/payment/initiate';
      case MobileProvider.moov:
        return 'https://api.moov.bj/payment/initiate';
    }
  }
}

class _ProviderButton extends StatelessWidget {
  final MobileProvider provider;
  final String name;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderButton({
    required this.provider,
    required this.name,
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
            Text(
              icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: AppColors.border,
              ),
          ],
        ),
      ),
    );
  }
}
