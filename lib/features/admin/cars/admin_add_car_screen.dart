import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/car_model.dart';
import '../../../providers/car_provider.dart';
import '../../../services/storage_service.dart';

class AdminAddCarScreen extends ConsumerStatefulWidget {
  final String? carId;
  const AdminAddCarScreen({super.key, this.carId});

  @override
  ConsumerState<AdminAddCarScreen> createState() => _AdminAddCarScreenState();
}

class _AdminAddCarScreenState extends ConsumerState<AdminAddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _featuresCtrl = TextEditingController();

  Transmission _transmission = Transmission.automatic;
  FuelType _fuel = FuelType.essence;
  bool _isAvailable = true;
  final List<XFile> _newPhotos = [];
  List<String> _existingPhotos = [];
  bool _loading = false;
  bool _initialized = false;

  bool get isEdit => widget.carId != null;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _seatsCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();
    _descCtrl.dispose();
    _featuresCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final files = await StorageService().pickMultipleImages();
    if (files.isNotEmpty) {
      setState(() => _newPhotos.addAll(files));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPhotos.isEmpty && _existingPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une photo'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Upload les nouvelles photos vers Cloudinary
      List<String> allPhotos = [..._existingPhotos];
      if (_newPhotos.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload des photos en cours...'),
            duration: Duration(seconds: 10),
          ),
        );
        final uploadedUrls =
            await StorageService().uploadMultiple(_newPhotos, 'cars');
        allPhotos.addAll(uploadedUrls);
      }

      final features = _featuresCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (isEdit) {
        await ref.read(carServiceProvider).updateCar(widget.carId!, {
          'brand': _brandCtrl.text.trim(),
          'model': _modelCtrl.text.trim(),
          'year': int.parse(_yearCtrl.text),
          'seats': int.parse(_seatsCtrl.text),
          'transmission': _transmission.name,
          'fuelType': _fuel.name,
          'pricePerDay': double.parse(_priceCtrl.text.replaceAll(',', '.')),
          'deposit': double.parse(_depositCtrl.text.replaceAll(',', '.')),
          'description': _descCtrl.text.trim(),
          'photos': allPhotos,
          'isAvailable': _isAvailable,
          'features': features,
        });
      } else {
        final car = CarModel(
          id: '',
          brand: _brandCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          year: int.parse(_yearCtrl.text),
          seats: int.parse(_seatsCtrl.text),
          transmission: _transmission,
          fuelType: _fuel,
          pricePerDay: double.parse(_priceCtrl.text.replaceAll(',', '.')),
          deposit: double.parse(_depositCtrl.text.replaceAll(',', '.')),
          description: _descCtrl.text.trim(),
          photos: allPhotos,
          isAvailable: _isAvailable,
          features: features,
          createdAt: DateTime.now(),
        );
        await ref.read(carServiceProvider).addCar(car);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Voiture modifiée avec succès'
                : 'Voiture ajoutée avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  @override
  Widget build(BuildContext context) {
    if (isEdit) {
      final carAsync = ref.watch(carDetailProvider(widget.carId!));
      return carAsync.when(
        data: (car) {
          if (!_initialized) {
            _brandCtrl.text = car.brand;
            _modelCtrl.text = car.model;
            _yearCtrl.text = car.year.toString();
            _seatsCtrl.text = car.seats.toString();
            _priceCtrl.text = car.pricePerDay.toString();
            _depositCtrl.text = car.deposit.toString();
            _descCtrl.text = car.description;
            _featuresCtrl.text = car.features.join(', ');
            _transmission = car.transmission;
            _fuel = car.fuelType;
            _isAvailable = car.isAvailable;
            _existingPhotos = List.from(car.photos);
            _initialized = true;
          }
          return _buildScaffold();
        },
        loading: () => const Scaffold(body: LoadingWidget()),
        error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      );
    }
    return _buildScaffold();
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier la voiture' : 'Ajouter une voiture'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos
              const Text('Photos du véhicule',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: _pickPhotos,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: AppColors.primary, size: 28),
                            SizedBox(height: 4),
                            Text('Ajouter',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    ..._existingPhotos.map((url) => Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(url, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _existingPhotos.remove(url)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                    ..._newPhotos.map((file) => Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FutureBuilder<Uint8List>(
                                  future: file.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState !=
                                        ConnectionState.done) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.hasData) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 32,
                                          color: AppColors.textSecondary,
                                        ),
                                      );
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _newPhotos.remove(file)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Informations',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Marque',
                    hint: 'Toyota',
                    controller: _brandCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, 'La marque'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Modèle',
                    hint: 'Corolla',
                    controller: _modelCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, 'Le modèle'),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Année',
                    hint: '2022',
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Places',
                    hint: '5',
                    controller: _seatsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveNumber,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Prix/jour (FCFA)',
                    hint: '25000',
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Caution (FCFA)',
                    hint: '50000',
                    controller: _depositCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveNumber,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const Text('Transmission',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: Transmission.values.map((t) {
                  final sel = _transmission == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _transmission = t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  sel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          t == Transmission.automatic
                              ? 'Automatique'
                              : 'Manuelle',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Carburant',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FuelType.values.map((f) {
                  final sel = _fuel == f;
                  return GestureDetector(
                    onTap: () => setState(() => _fuel = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(_fuelLabel(f),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Disponible à la location',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Switch(
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    activeThumbColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Description',
                hint: 'Décrivez le véhicule...',
                controller: _descCtrl,
                maxLines: 3,
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Équipements (séparés par virgules)',
                hint: 'Climatisation, GPS, Bluetooth...',
                controller: _featuresCtrl,
                prefixIcon: Icons.star_outline_rounded,
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: isEdit
                    ? 'Enregistrer les modifications'
                    : 'Ajouter la voiture',
                onPressed: _save,
                isLoading: _loading,
                prefixIcon: isEdit ? Icons.save_outlined : Icons.add_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _fuelLabel(FuelType f) {
    switch (f) {
      case FuelType.essence:
        return 'Essence';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.electric:
        return 'Electrique';
      case FuelType.hybrid:
        return 'Hybride';
    }
  }
}
