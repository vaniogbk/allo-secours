import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/notification_model.dart';
import '../../../models/parcel_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parcel_provider.dart';
import '../../../services/notification_service.dart';

class CreateParcelScreen extends ConsumerStatefulWidget {
  const CreateParcelScreen({super.key});

  @override
  ConsumerState<CreateParcelScreen> createState() =>
      _CreateParcelScreenState();
}

class _CreateParcelScreenState
    extends ConsumerState<CreateParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderAddressCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _recipientAddressCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _dimensionsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  ParcelType _type = ParcelType.standard;
  int _step = 0;
  bool _loading = false;

  @override
  void dispose() {
    _senderAddressCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _recipientAddressCtrl.dispose();
    _weightCtrl.dispose();
    _dimensionsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _estimatedPrice {
    final w = double.tryParse(
            _weightCtrl.text.replaceAll(',', '.')) ??
        0;
    return ref
        .read(parcelServiceProvider)
        .calculatePrice(w, _type);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await ref.read(userStreamProvider.future);
      if (user == null) throw Exception('Utilisateur introuvable');

      final id = await ref
          .read(parcelServiceProvider)
          .createParcel(
            sender: user,
            recipientName: _recipientNameCtrl.text.trim(),
            recipientPhone: _recipientPhoneCtrl.text.trim(),
            recipientAddress: _recipientAddressCtrl.text.trim(),
            senderAddress: _senderAddressCtrl.text.trim(),
            weight: double.parse(
                _weightCtrl.text.replaceAll(',', '.')),
            dimensions:
                _dimensionsCtrl.text.trim().isEmpty
                    ? null
                    : _dimensionsCtrl.text.trim(),
            type: _type,
            note: _noteCtrl.text.trim().isEmpty
                ? null
                : _noteCtrl.text.trim(),
          );

      await NotificationService.saveNotification(
        userId: user.id,
        title: 'Colis enregistré',
        body:
            'Votre envoi vers ${_recipientNameCtrl.text.trim()} a été créé avec succès.',
        type: NotificationType.parcel,
        refId: id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colis créé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/client/parcels');
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

  bool _validateCurrentStep() {
    return _formKey.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Envoyer un colis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Stepper
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _StepDot(
                      index: 0,
                      current: _step,
                      label: 'Expéditeur'),
                  _StepLine(active: _step >= 1),
                  _StepDot(
                      index: 1,
                      current: _step,
                      label: 'Destinataire'),
                  _StepLine(active: _step >= 2),
                  _StepDot(
                      index: 2,
                      current: _step,
                      label: 'Colis'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(AppDimensions.paddingM),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == 0
                      ? _buildStep0()
                      : _step == 1
                          ? _buildStep1()
                          : _buildStep2(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12)
                ],
              ),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: CustomButton(
                        label: 'Précédent',
                        variant: ButtonVariant.outline,
                        onPressed: () =>
                            setState(() => _step--),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _step < 2
                        ? CustomButton(
                            label: 'Suivant',
                            onPressed: () {
                              if (_validateCurrentStep()) {
                                setState(() => _step++);
                              }
                            },
                            suffixIcon:
                                Icons.arrow_forward_rounded,
                          )
                        : CustomButton(
                            label: 'Confirmer l\'envoi',
                            onPressed: _submit,
                            isLoading: _loading,
                            prefixIcon: Icons.send_rounded,
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

  Widget _buildStep0() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Adresse de départ',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
            'L\'adresse où votre colis sera récupéré.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Adresse d\'enlèvement',
          hint: 'Rue, Quartier, Ville',
          controller: _senderAddressCtrl,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) =>
              Validators.required(v, 'L\'adresse'),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations du destinataire',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Nom du destinataire',
          hint: 'Nom complet',
          controller: _recipientNameCtrl,
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          validator: (v) => Validators.required(v, 'Le nom'),
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Téléphone du destinataire',
          hint: '+229 XX XX XX XX',
          controller: _recipientPhoneCtrl,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          validator: Validators.phone,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Adresse de livraison',
          hint: 'Rue, Quartier, Ville',
          controller: _recipientAddressCtrl,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) =>
              Validators.required(v, 'L\'adresse'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations du colis',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Poids (kg)',
          hint: 'Ex: 2.5',
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true),
          prefixIcon: Icons.scale_outlined,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'[\d,.]'))
          ],
          onChanged: (_) => setState(() {}),
          validator: Validators.positiveNumber,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Dimensions (optionnel)',
          hint: 'Ex: 30x20x15 cm',
          controller: _dimensionsCtrl,
          prefixIcon: Icons.straighten_outlined,
        ),
        const SizedBox(height: 20),
        const Text('Type d\'envoi',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: ParcelType.values.map((t) {
            final selected = _type == t;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _type = t),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryLight
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Column(
                    children: [
                      Icon(_typeIcon(t),
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22),
                      const SizedBox(height: 4),
                      Text(_typeLabel(t),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors
                                      .textSecondary)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (_weightCtrl.text.isNotEmpty &&
            _estimatedPrice > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text('Coût estimé',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12)),
                    Text(
                      FormatUtils.formatPrice(
                          _estimatedPrice),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Note (optionnel)',
          hint: 'Instructions particulières...',
          controller: _noteCtrl,
          maxLines: 3,
          prefixIcon: Icons.note_outlined,
        ),
      ],
    );
  }

  IconData _typeIcon(ParcelType t) {
    switch (t) {
      case ParcelType.standard:
        return Icons.inventory_2_outlined;
      case ParcelType.express:
        return Icons.bolt_rounded;
      case ParcelType.fragile:
        return Icons.warning_amber_rounded;
    }
  }

  String _typeLabel(ParcelType t) {
    switch (t) {
      case ParcelType.standard: return 'Standard';
      case ParcelType.express: return 'Express';
      case ParcelType.fragile: return 'Fragile';
    }
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final String label;
  const _StepDot(
      {required this.index,
      required this.current,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final done = current > index;
    final active = current == index;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: done || active
                ? AppColors.primary
                : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white)
                : Text('${index + 1}',
                    style: TextStyle(
                        color: active
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: active
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.w400)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: active ? AppColors.primary : AppColors.border,
      ),
    );
  }
}