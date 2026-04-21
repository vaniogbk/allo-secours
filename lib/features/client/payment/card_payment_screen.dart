import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/payment_provider.dart';
import '../../../models/payment_model.dart';

class CardPaymentScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final double amount;
  final String redirectTo;

  const CardPaymentScreen({
    super.key,
    required this.paymentId,
    required this.amount,
    required this.redirectTo,
  });

  @override
  ConsumerState<CardPaymentScreen> createState() =>
      _CardPaymentScreenState();
}

class _CardPaymentScreenState extends ConsumerState<CardPaymentScreen> {
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _cardholderCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cardholderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paiement par carte'),
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
                        'Montant',
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

            // Formulaire de carte
            const Text(
              'Informations de la carte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Numéro de carte
            CustomTextField(
              label: 'Numéro de carte',
              hint: '0000 0000 0000 0000',
              controller: _cardNumberCtrl,
              keyboardType: TextInputType.number,
              maxLength: 19,
              prefixIcon: Icons.credit_card_rounded,
              validator: _validateCardNumber,
            ),
            const SizedBox(height: 14),

            // Nom du titulaire
            CustomTextField(
              label: 'Nom du titulaire',
              hint: 'Jean Dupont',
              controller: _cardholderCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 14),

            // Expiration et CVV
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Expiration',
                    hint: 'MM/YY',
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    validator: _validateExpiry,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'CVV',
                    hint: '000',
                    controller: _cvvCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    validator: _validateCvv,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Avis de sécurité
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chiffrement SSL 256-bit\nVos données bancaires sont sécurisées',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Termes et conditions
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: null,
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'J\'accepte les ',
                          style: TextStyle(fontSize: 12),
                        ),
                        TextSpan(
                          text: 'conditions de paiement',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bouton de paiement
            CustomButton(
              label: 'Payer ${widget.amount.toStringAsFixed(0)} FCFA',
              onPressed: _loading ? null : _processPayment,
              isLoading: _loading,
              prefixIcon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numéro de carte requis';
    }
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Numéro de carte invalide';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date requise';
    }
    if (!value.contains('/')) {
      return 'Format: MM/YY';
    }
    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Format: MM/YY';
    }
    final month = int.tryParse(parts[0]);
    if (month == null || month < 1 || month > 12) {
      return 'Mois invalide';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV requis';
    }
    if (value.length < 3 || value.length > 4) {
      return 'CVV invalide';
    }
    return null;
  }

  Future<void> _processPayment() async {
    // Valider les champs
    final cardError = _validateCardNumber(_cardNumberCtrl.text);
    final cardholderError = _cardholderCtrl.text.isEmpty ? 'Champ obligatoire' : null;
    final expiryError = _validateExpiry(_expiryCtrl.text);
    final cvvError = _validateCvv(_cvvCtrl.text);

    if (cardError != null || cardholderError != null || expiryError != null || cvvError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cardError ?? cardholderError ?? expiryError ?? cvvError ?? 'Erreur de validation',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final paymentService = ref.read(paymentServiceProvider);

      // EN PRODUCTION: Utiliser un vrai processeur de paiement (Stripe, Square, etc.)
      // Pour cette démo, nous simulons un paiement réussi
      print('💳 Simulation paiement par carte');
      print('💰 Montant: ${widget.amount} FCFA');
      print('🏷️ Titulaire: ${_cardholderCtrl.text}');

      await Future.delayed(const Duration(seconds: 2));

      // Mettre à jour le statut du paiement
      await paymentService.updatePaymentStatus(
        widget.paymentId,
        PaymentStatus.success,
        transactionRef: 'CARD_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement effectué avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        // Retourner à la réservation
        context.go(widget.redirectTo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de paiement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

