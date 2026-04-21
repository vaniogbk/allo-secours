import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/parcel_model.dart';
import '../../../providers/parcel_provider.dart';
import '../../../services/location_service.dart';

class EditParcelScreen extends ConsumerStatefulWidget {
  final String parcelId;
  const EditParcelScreen({super.key, required this.parcelId});

  @override
  ConsumerState<EditParcelScreen> createState() => _EditParcelScreenState();
}

class _EditParcelScreenState extends ConsumerState<EditParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderAddressCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _recipientAddressCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _dimensionsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  ParcelType _type = ParcelType.standard;
  bool _loading = false;
  bool _initialized = false;
  final _locationService = LocationService();

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

  void _init(ParcelModel parcel) {
    if (_initialized) return;
    _senderAddressCtrl.text = parcel.senderAddress;
    _recipientNameCtrl.text = parcel.recipientName;
    _recipientPhoneCtrl.text = parcel.recipientPhone;
    _recipientAddressCtrl.text = parcel.recipientAddress;
    _weightCtrl.text = parcel.weight.toString();
    _dimensionsCtrl.text = parcel.dimensions ?? '';
    _noteCtrl.text = parcel.note ?? '';
    _type = parcel.type;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final parcelAsync = ref.watch(parcelStreamProvider(widget.parcelId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier le colis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: parcelAsync.when(
        data: (parcel) {
          if (parcel == null) {
            return const Center(
              child: Text('Colis introuvable ou accès refusé'),
            );
          }

          final canModify =
              ref.read(parcelServiceProvider).canModifyParcel(parcel);
          if (!canModify) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ce colis ne peut plus être modifié car il a déjà été pris en charge ou son paiement a été validé.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          _init(parcel);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Vous pouvez corriger les informations tant que le colis est encore en attente.',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: 'Adresse de départ',
                    controller: _senderAddressCtrl,
                    validator: (v) => Validators.required(v, 'L\'adresse'),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Nom du destinataire',
                    controller: _recipientNameCtrl,
                    validator: (v) =>
                        Validators.required(v, 'Le nom du destinataire'),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Téléphone du destinataire',
                    controller: _recipientPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Adresse du destinataire',
                    controller: _recipientAddressCtrl,
                    validator: (v) =>
                        Validators.required(v, 'L\'adresse du destinataire'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Poids (kg)',
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) => Validators.positiveNumber(v, 'Le poids'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ParcelType>(
                          value: _type,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          items: ParcelType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    switch (type) {
                                      ParcelType.standard => 'Standard',
                                      ParcelType.express => 'Express',
                                      ParcelType.fragile => 'Fragile',
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _type = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Dimensions',
                    controller: _dimensionsCtrl,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Note',
                    controller: _noteCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Enregistrer les modifications',
                    onPressed: _loading ? null : () => _submit(parcel),
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Future<void> _submit(ParcelModel parcel) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final senderGeo =
          await _locationService.geocodeAddress(_senderAddressCtrl.text.trim());
      final recipientGeo = await _locationService.geocodeAddress(
        _recipientAddressCtrl.text.trim(),
      );

      await ref.read(parcelServiceProvider).updateParcel(
            parcel.id,
            recipientName: _recipientNameCtrl.text.trim(),
            recipientPhone: _recipientPhoneCtrl.text.trim(),
            recipientAddress: _recipientAddressCtrl.text.trim(),
            senderAddress: _senderAddressCtrl.text.trim(),
            senderLatitude: senderGeo?.latitude ?? parcel.senderLatitude,
            senderLongitude: senderGeo?.longitude ?? parcel.senderLongitude,
            recipientLatitude:
                recipientGeo?.latitude ?? parcel.recipientLatitude,
            recipientLongitude:
                recipientGeo?.longitude ?? parcel.recipientLongitude,
            weight: double.parse(_weightCtrl.text.replaceAll(',', '.')),
            dimensions: _dimensionsCtrl.text.trim().isEmpty
                ? null
                : _dimensionsCtrl.text.trim(),
            type: _type,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colis modifié avec succès'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/client/parcels/${parcel.id}/track');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
